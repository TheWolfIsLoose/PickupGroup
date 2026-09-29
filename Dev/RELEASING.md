# PickupGroup — Releasing

Dev-only (`Dev/` never ships). Private repo, no CI: a version is a tag.

Version: `vMAJOR.MINOR.PATCH`, below 1.0 while private and settling.
Patch = fixes, minor = a phase or a feature, major = saved data or a
redesign breaks. `-alphaN` / `-betaN` only for builds that need an
in-game test first.

Cutting a version, in one commit:
1. `## Version` in `PickupGroup.toc` and the `## vX.Y.Z` heading in
   `CHANGELOG.md` (only the version being cut; short, player-facing).
2. Detailed notes in `Dev/HISTORY.md`; planned work stays in
   `Dev/ROADMAP.md`.
3. `lua5.1 Dev/check.lua *.lua` passes.
4. Commit, tag `vX.Y.Z` on `main`, push the branch (tags don't push
   through the session proxy; recreate them locally if needed).

Saved data carries its own `schema` number; bump it and add one
migration step when the saved shape changes. Never tie a migration to
the addon version.

Work goes on `dev` once a phase needs testing before it lands; `main` is
known-good. At v1.0.0: debug logging defaults off, and the final name
replaces the working name.
