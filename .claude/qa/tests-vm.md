# Grille de tests sur VM — fork swizzin

Ce que les tests « installation neuve qui réussit » ne voient pas. Tiré des 32 checklists de l'agent `swizzin-critic` (`.claude/agent-memory/swizzin-critic/`) ; la source de chaque ligne est entre crochets.

**Ne pas tout jouer à chaque fois.** Choisir les familles selon ce que touche le changement :

| Le changement touche… | Familles à jouer |
|---|---|
| un script `install` / `upgrade` d'appli | 1, 2, 3, 6 |
| un script `update` (migration, réparation) | 1, 3, 6 |
| droits, ACL, sudoers, dossiers des utilisateurs | 1, 4, 6 |
| mots de passe, comptes | 3, 4 |
| nginx, adresse d'écoute, proxy | 5, 6 |
| sources apt, clés, versions d'OS | 2, 3, 6 |

## 1. État du serveur au départ

- [ ] **Serveur ancien mis à jour** (installé avec une version précédente du fork, puis `box update`), pas seulement une installation neuve. Restes typiques : anciens fichiers systemd avec `%I`, Java `adoptopenjdk`, paquets désinstallés en état « rc ». [systemd_template, first_run_wizard, new_jvm_app, deb_to_tarball]
- [ ] **Deux utilisateurs au moins**, dont un non-master. Vérifier que l'autre utilisateur n'a pas été redémarré ni reconfiguré sans raison. [update_repair_blocks]
- [ ] **`box update` lancé deux fois de suite** : le second passage ne change rien et n'affiche pas d'avertissement. [vendored_plugin_migration, acl_migration]
- [ ] **Migration interrompue** (Ctrl+C au milieu, puis relance) : le serveur repart d'un état intermédiaire sans casser. [bash_installer, ownership_migration]

## 2. Versions d'OS et architectures

- [ ] **La plus ancienne supportée** (Ubuntu 20.04 focal, Debian 11 bullseye) : vieux git, noyau < 5.10, cgroup v1. [bash_installer, nginx_disable_symlinks, php_pool_split]
- [ ] **Debian 13 trixie** : `/tmp` en RAM (gros fichiers), clés apt SHA1 refusées, `/etc/sysctl.conf` ignoré au redémarrage → **redémarrer la VM** et revérifier. [app_swap_install, os_support, sysctl_revert]
- [ ] **Ubuntu 26.04 resolute** : `test` et `sudo` réécrits en Rust (contrôles de droits faux, `visudo -q` bavard). [rust_coreutils, sudoers_acl]
- [ ] **ARM (arm64/armhf)** : paquet absent pour l'architecture, démarrage lent de l'appli. [new_jvm_app, app_swap_install]

## 3. Pannes à provoquer

- [ ] **Téléchargement en échec** pendant une mise à jour (couper le réseau ou bloquer `github.com`) : l'ancienne version doit rester en place et fonctionner. [bash_installer, app_swap_install]
- [ ] **Source apt cassée** (clé invalide, dépôt mort) : `box update` ne doit pas s'arrêter au premier script. [deb_to_tarball, apt_source_disable, bash_installer]
- [ ] **Disque plein** pendant une réécriture de config : la config ne doit pas finir vide. [config_rewrite]
- [ ] **Paquet `acl` absent ou disque sans ACL** : l'utilisateur ne doit pas perdre l'accès (pas d'erreur 500 nginx). [sudoers_acl, shared_profile_perm_walks]
- [ ] **Sans terminal** : `ssh serveur 'box …'`, tâche cron, installation automatique (`setup.sh --env`, voir `unattended.example.env`) : le message d'erreur doit rester lisible. [password_plumbing]
- [ ] **`lsof` absent** sur serveur neuf + `apt` en cours (apt-daily) : l'attente du verrou fonctionne quand même. [apt_lock_wait]
- [ ] **Le script échoue** : `echo $?` après `box install|update` doit être non nul. [apt_lock_wait, first_run_wizard]

## 4. Données piégées

- [ ] **Mots de passe** avec espace, `'`, `"`, `\`, accent, et commençant par `-` : connexion OK dans chaque appli touchée. [password_plumbing, new_jvm_app, bash_installer]
- [ ] **Noms d'utilisateur** avec un `-`, et finissant par `u`. [systemd_template, php_pool_split]
- [ ] **Liens symboliques posés par un utilisateur** non-master, là où root écrit ou fait `chown` (ex. `~/.config/<appli>/settings.json -> /etc/shadow`) : après le script, `/etc/shadow` est toujours à root. [root_ops_in_user_homes, apparmor_override, shared_profile_perm_walks]
- [ ] **FIFO posé** à la place d'un fichier que root lit (`mkfifo`) : le script ne reste pas bloqué. [root_ops_in_user_homes, root_helper_polling]
- [ ] **Valeur bizarre** dans la config d'une appli (port `8080; return 200`) : elle ne se retrouve pas dans la conf nginx. [loopback_bind_migration, root_ops_in_user_homes]

## 5. Réseau

- [ ] **Port autre que 443** ou redirection NAT : connexion à l'interface web OK. [reverse_proxy_host]
- [ ] **Conteneur Docker** (*arr) qui joint une appli de l'hôte : toujours joignable si elle passe en `127.0.0.1`. [config_rewrite]
- [ ] **Adresse d'écoute choisie à la main** (IP LAN/VPN, `::`) : conservée après mise à jour. [config_rewrite, loopback_bind_migration]

## 6. Cycle de vie complet

- [ ] **Installer → mettre à jour → désinstaller → réinstaller.** Après la désinstallation, rien ne reste :
  - [ ] pas de source apt renommée (`*.list.disabled` ou équivalent) [apt_source_disable]
  - [ ] pas d'unité systemd ni de conf nginx orpheline [bash_installer]
  - [ ] `apt autoremove` n'a pas retiré une bibliothèque utilisée par une autre appli [deb_to_tarball, new_jvm_app]
  - [ ] pas d'entrée ACL à l'UID d'un utilisateur supprimé [named_acl_grant, php_pool_split]
- [ ] **`box remove nginx` après coup** : les applis passées en `127.0.0.1` redeviennent joignables. [config_rewrite, loopback_bind_migration, web_terminal_restart]
- [ ] **Changement lancé depuis le terminal web** (port 4200) : la session n'est pas coupée en plein milieu. [web_terminal_restart]

## Contrôles à faire à la fin de chaque test

- [ ] `nginx -t` et `visudo -cq` (le global, pas fichier par fichier) [sudoers_acl]
- [ ] `getfacl <dossier>` sur les dossiers touchés : droits relus, pas supposés [acl_migration]
- [ ] Aucun mot de passe dans `/root/logs/*.log` ni dans `ps aux` pendant l'exécution [log_scrub, bash_installer]
- [ ] `/var/log/auth.log` ne se remplit pas à chaque contrôle automatique [root_helper_polling]
- [ ] `systemctl --failed` vide
