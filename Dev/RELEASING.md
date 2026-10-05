# PickupGroup — Releasing

Dev-only (`Dev/` never ships). Public repo; CI tags and publishes
(`.github/workflows/release.yml`, packaging rules in `.pkgmeta`).

Version: `vMAJOR.MINOR.PATCH`, below 1.0 while settling.
Patch = fixes, minor = a phase or a feature, major = saved data or a
redesign breaks. `-alphaN` / `-betaN` only for builds that need an
in-game test first. Stable 0.x releases are fine (CurseForge's review
needs a Release file; v0.4.0 was the first).

Cutting a version, in one commit:
1. `## Version` in `PickupGroup.toc` and the `## vX.Y.Z` heading in
   `CHANGELOG.md` (only the version being cut; short, player-facing).
2. Detailed notes in `Dev/HISTORY.md`; planned work stays in
   `Dev/ROADMAP.md`.
3. `lua5.1 Dev/check.lua *.lua UI/*.lua` passes.
4. Commit and push `main`. The workflow tags the CHANGELOG version,
   packages it and makes the GitHub Release; CurseForge follows the tag.
   Don't tag by hand. A push whose version is already tagged publishes
   nothing, so roadmap-only commits are safe.

CurseForge (project 1718475) packages each new tag itself: the repo has
CurseForge's webhook (GitHub Settings > Webhooks, push events; same as
StockClerk's, with this project's ID) and Automatic Packaging is on in
CurseForge's Source tab. The workflow makes the GitHub Release.

Saved data carries its own `schema` number; bump it and add one
migration step when the saved shape changes. Never tie a migration to
the addon version.

Work goes on `dev` once a phase needs testing before it lands; `main` is
known-good. At v1.0.0: debug logging defaults off, and the final name
replaces the working name.

## Patch day: Retail TOC bump

Every Retail patch, check the live interface number and bump `## Interface`
in the TOC if it changed (keep older numbers in a comma list only where the
addon still supports them; Tones also lists Classic flavors).

Cross-reference at least two of:
- Warcraft Wiki, Public client builds (Interface column):
  https://warcraft.wiki.gg/wiki/Public_client_builds
- Blizzard's UI source mirror, `live` branch (the latest commit message names
  the patch, e.g. "12.1.0 (69933)" = 120100):
  https://github.com/Gethe/wow-ui-source/tree/live
- In game: `/dump select(4, GetBuildInfo())`

A TOC-only bump is a patch release (vX.Y.Z+1) with a one-line CHANGELOG
("Up to date for patch 12.x.y."). Last checked: 2026-10-05, 12.1.0 = 120100.
