# VM test grid — swizzin fork

What "fresh install that succeeds" tests do not see. Drawn from the 32 checklists of the `swizzin-critic` agent (`.claude/agent-memory/swizzin-critic/`); the source of each line is in brackets.

**Do not run everything every time.** Pick the families according to what the change touches:

| The change touches… | Families to run |
|---|---|
| an app `install` / `upgrade` script | 1, 2, 3, 6 |
| an `update` script (migration, repair) | 1, 3, 6 |
| permissions, ACLs, sudoers, user folders | 1, 4, 6 |
| passwords, accounts | 3, 4 |
| nginx, listen address, proxy | 5, 6 |
| apt sources, keys, OS versions | 2, 3, 6 |

## 1. Starting state of the server

- [ ] **Old server updated** (installed with an earlier version of the fork, then `box update`), not only a fresh install. Typical leftovers: old systemd files with `%I`, `adoptopenjdk` Java, uninstalled packages in "rc" state. [systemd_template, first_run_wizard, new_jvm_app, deb_to_tarball]
- [ ] **At least two users**, one of them not the master. Check that the other user was not restarted or reconfigured for no reason. [update_repair_blocks]
- [ ] **`box update` run twice in a row**: the second pass changes nothing and shows no warning. [vendored_plugin_migration, acl_migration]
- [ ] **Interrupted migration** (Ctrl+C halfway, then rerun): the server picks up from an intermediate state without breaking. [bash_installer, ownership_migration]

## 2. OS versions and architectures

- [ ] **The oldest supported** (Ubuntu 20.04 focal, Debian 11 bullseye): old git, kernel < 5.10, cgroup v1. [bash_installer, nginx_disable_symlinks, php_pool_split]
- [ ] **Debian 13 trixie**: `/tmp` in RAM (large files), SHA1 apt keys refused, `/etc/sysctl.conf` ignored at boot → **reboot the VM** and check again. [app_swap_install, os_support, sysctl_revert]
- [ ] **Ubuntu 26.04 resolute**: `test` and `sudo` rewritten in Rust (wrong permission checks, chatty `visudo -q`). [rust_coreutils, sudoers_acl]
- [ ] **ARM (arm64/armhf)**: package missing for the architecture, slow app start. [new_jvm_app, app_swap_install]

## 3. Failures to provoke

- [ ] **Failed download** during an upgrade (cut the network or block `github.com`): the old version must stay in place and work. [bash_installer, app_swap_install]
- [ ] **Broken apt source** (invalid key, dead repository): `box update` must not stop at the first script. [deb_to_tarball, apt_source_disable, bash_installer]
- [ ] **Full disk** during a config rewrite: the config must not end up empty. [config_rewrite]
- [ ] **`acl` package missing or disk without ACLs**: the user must not lose access (no nginx 500 error). [sudoers_acl, shared_profile_perm_walks]
- [ ] **No terminal**: `ssh server 'box …'`, cron job, unattended install (`setup.sh --env`, see `unattended.example.env`): the error message must stay readable. [password_plumbing]
- [ ] **`lsof` missing** on a fresh server + `apt` running (apt-daily): waiting for the lock still works. [apt_lock_wait]
- [ ] **The script fails**: `echo $?` after `box install|update` must be non-zero. [apt_lock_wait, first_run_wizard]

## 4. Booby-trapped data

- [ ] **Passwords** with a space, `'`, `"`, `\`, an accent, and starting with `-`: login OK in each app touched. [password_plumbing, new_jvm_app, bash_installer]
- [ ] **User names** with a `-`, and ending with `u`. [systemd_template, php_pool_split]
- [ ] **Symbolic links planted by a non-master user** where root writes or runs `chown` (e.g. `~/.config/<app>/settings.json -> /etc/shadow`): after the script, `/etc/shadow` still belongs to root. [root_ops_in_user_homes, apparmor_override, shared_profile_perm_walks]
- [ ] **FIFO planted** instead of a file root reads (`mkfifo`): the script does not hang. [root_ops_in_user_homes, root_helper_polling]
- [ ] **Odd value** in an app's config (port `8080; return 200`): it does not end up in the nginx conf. [loopback_bind_migration, root_ops_in_user_homes]

## 5. Network

- [ ] **Port other than 443** or NAT forwarding: login to the web interface OK. [reverse_proxy_host]
- [ ] **Docker container** (*arr) reaching an app on the host: still reachable if it moves to `127.0.0.1`. [config_rewrite]
- [ ] **Listen address chosen by hand** (LAN/VPN IP, `::`): kept after an update. [config_rewrite, loopback_bind_migration]

## 6. Full lifecycle

- [ ] **Install → upgrade → remove → reinstall.** After the removal, nothing is left:
  - [ ] no renamed apt source (`*.list.disabled` or similar) [apt_source_disable]
  - [ ] no orphan systemd unit or nginx conf [bash_installer]
  - [ ] `apt autoremove` did not remove a library used by another app [deb_to_tarball, new_jvm_app]
  - [ ] no ACL entry for the UID of a deleted user [named_acl_grant, php_pool_split]
- [ ] **`box remove nginx` afterwards**: apps moved to `127.0.0.1` become reachable again. [config_rewrite, loopback_bind_migration, web_terminal_restart]
- [ ] **Change started from the web terminal** (port 4200): the session is not cut off halfway. [web_terminal_restart]

## Checks at the end of each test

- [ ] `nginx -t` and `visudo -cq` (the global one, not file by file) [sudoers_acl]
- [ ] `getfacl <folder>` on the folders touched: permissions read back, not assumed [acl_migration]
- [ ] No password in `/root/logs/*.log` or in `ps aux` while it runs [log_scrub, bash_installer]
- [ ] `/var/log/auth.log` does not fill up at each automatic check [root_helper_polling]
- [ ] `systemctl --failed` empty
