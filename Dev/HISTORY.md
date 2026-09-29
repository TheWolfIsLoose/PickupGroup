# PickupGroup — History

Detailed notes per version, newest first. Dev-only (`Dev/` never ships).

## v0.2.0-alpha1 (2026-09-28): Phase 2, first playable pane

- `Groups.lua`: results as rows (name, instance code, difficulty, spec
  tiles for dungeons, role counts and bosses down for raids, leader
  score, application status). Dungeons listed only with an open seat for
  a role the player signs up as; raids only with room.
- `UI/Pane.lua`: our frame over Blizzard's search panel (Blizzard's Back
  / Sign Up row left uncovered) on Dungeons and Raids - current. Top bar:
  one "All groups" tab (saved filters are Phase 3), count, Refresh with a
  3 s countdown (any search restarts it), switch to Blizzard's list (a
  PickupGroup button on Blizzard's panel switches back). Header: apply-as
  roles (Blizzard's own role choice). Rows: sign-ups pinned first,
  action button (Apply, shift-click Blizzard's dialog; time left, click
  cancels; Reapply confirms on a second click), tooltip, wheel scroll.
- Log: sign-up, cancel, refused search.
- Not yet: teleport button, application log (alpha2).

## v0.1.1 (2026-09-28): Phase 1 done

Spike answers are in the roadmap (Phase 1). The harness is removed;
blocked-action logging stays.

## v0.1.1-alpha1 (2026-09-28): Phase 1 test harness

- `Dev/Spike.lua` (throwaway, `/pug spike`): Cover (1a), Dialog (1b),
  Direct (1b'), Search (1c); every search logged with the gap since the
  previous one, search failures, application status changes.
- Core logs `ADDON_ACTION_BLOCKED` / `FORBIDDEN` for PickupGroup (kept
  after the spikes).

## v0.1.0 (2026-09-28): Phase 0, foundation

Built as v0.1.0-alpha1; first load confirmed in game (install line, no
errors, `/pug debug` toggles).

- `PickupGroup.toc`; private namespace (no globals but `PickupGroupDB` and
  the slash command); saved data with `schema = 1`, per-character data
  under `chars["Name-Realm"]`.
- One event frame; handler errors go to the log, then to the normal error
  handler.
- Log (StockClerk's design): activity / detail / trace, 2000-entry ring,
  report with an environment header and the Group Finder addons that are
  loaded. Trace on by default until v1.0.0 (`/pug debug` toggles, saved).
- UI kit (fonts with Expressway via LibSharedMedia else bundled Barlow Semi
  Condensed, palette, fill, border, button, drawn glyphs, header icon) and
  the `/pug log` window.
