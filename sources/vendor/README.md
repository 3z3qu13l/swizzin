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
