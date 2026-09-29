# PickupGroup — Releasing

Dev-only (`Dev/` never ships). Private repo; CI publishes
(`.github/workflows/release.yml`, packaging rules in `.pkgmeta`).

Version: `vMAJOR.MINOR.PATCH`, below 1.0 while private and settling.
Patch = fixes, minor = a phase or a feature, major = saved data or a
redesign breaks. `-alphaN` / `-betaN` only for builds that need an
in-game test first. Once CurseForge is live, every version before 1.0
carries `-alphaN` so it lands there as an Alpha (the packager takes the
file type from the tag).

Cutting a version, in one commit:
1. `## Version` in `PickupGroup.toc` and the `## vX.Y.Z` heading in
   `CHANGELOG.md` (only the version being cut; short, player-facing).
2. Detailed notes in `Dev/HISTORY.md`; planned work stays in
   `Dev/ROADMAP.md`.
3. `lua5.1 Dev/check.lua *.lua UI/*.lua` passes.
4. Commit and push `main`. The workflow tags the CHANGELOG version,
   packages it and publishes (GitHub Release; CurseForge once live).
   Don't tag by hand. A push whose version is already tagged publishes
   nothing, so roadmap-only commits are safe.

CurseForge goes live when the final name is settled: register the
project, add `## X-Curse-Project-ID: <id>` to the TOC, and add a
CurseForge API token (curseforge.com/account/api-tokens) as the repo
secret `CF_API_KEY`. Nothing else changes.

Saved data carries its own `schema` number; bump it and add one
migration step when the saved shape changes. Never tie a migration to
the addon version.

Work goes on `dev` once a phase needs testing before it lands; `main` is
known-good. At v1.0.0: debug logging defaults off, and the final name
replaces the working name.
