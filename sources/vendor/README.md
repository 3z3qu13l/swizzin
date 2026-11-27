# Vendored copies

Local copies of third-party web assets, kept in case their GitHub repository becomes private or is deleted. They are kept byte for byte (see `.gitattributes`).

`club-QuickBox/` is installed by swizzin when GitHub cannot provide the theme (`rutorrent_club_quickbox` in `sources/functions/rutorrent`).

| Folder | Source | Version | License |
|---|---|---|---|
| `club-QuickBox/` | https://github.com/QuickBox/club-QuickBox, branch `latest` | commit `e24bfbd38cf7710f3bd38e97d06e6099c07a1c1f` (2026-11-18), theme 2.7.2 | Unlicense |

`club-QuickBox/` holds the runtime files only (the repository's `bin/`, `docs/`, `.github/`, `changelogs/`, README and TRANSLATING are left out).

## Refreshing the copy

```
git clone --depth 1 -b latest https://github.com/QuickBox/club-QuickBox.git
```

Copy `css images js lang init.js plugin.info plugins.css stable.css style.css LICENSE CHANGELOG.md` into `club-QuickBox/`, then update the table above.

## filemanager-share

The file manager's share plugin (public download links), corrected by swizzin: the upstream release does not work with ruTorrent 5.3. `box rtx` installs this copy (`rutorrent_fm_share_install` in `sources/functions/rutorrent`), and `box update` replaces an installed copy that differs from it.

| Folder | Source | Version | License |
|---|---|---|---|
| `filemanager-share/` | https://github.com/nelu/rutorrent-filemanager-share | tag `v1.5.0`, commit `48f728f62794381b96b56f066223c46db4d2d461` (2025-01-21) | none stated upstream (no LICENSE file) |

Left out: `.dockerignore`, `.github/`, `Dockerfile`, `README.md`, `js/tests.js`. Tested with ruTorrent 5.3.25 and the file manager at commit `b88cf1faad2a10203ca916cab2004e50beabdbc8`, which swizzin installs since (a server installed earlier keeps the file manager it got then; the plugin needs file manager 1.4 or later, January 2025). `box update` leaves `conf.php` alone once installed.

Changes from upstream, every other file is byte for byte:

- `conf.php`, rewritten. Upstream fills `$conf[...]`, which ruTorrent 5 already holds as a string: getplugins.php and fsh.php stopped with "Cannot access offset of type string on string". The limits are now in `$fmShareLimits` (24 hours at most, as swizzin had), the endpoint is `https://<host>/fancyindex/share.php`, and the encryption key is read from `/install/.rutorrent.share.key`, a random key swizzin writes readable by ruTorrent's PHP account only (upstream reads it from `$_ENV`, empty here, and the plugin then turns itself off).
- `src/FileManagerShare.php`, one line in `__construct`: the share folder was found by asking ruTorrent's cache for the file named `''`, which ruTorrent 5.3 refuses: shares were saved but never listed. It now asks for `_` and drops that name.
- `share.php`, rewritten. Upstream sets the user named by the link after ruTorrent has loaded, and ruTorrent keeps the anonymous user, profile and settings from its first call: every link answered "not found" (upstream issue #12). The link is now decoded first, with `src/Crypt.php` alone, its user must be a ruTorrent user (`conf/users/<user>`) and its token 32 letters or digits (what the plugin creates: no path), then ruTorrent loads as that user. A link is refused while the key is empty. A refused link answers 404. In swizzin's ruTorrent pool, it then confines the request to that user's files (`swizzin_rutorrent_confine`, `_rutorrent_php_prepend` in `sources/functions/rutorrent`).
