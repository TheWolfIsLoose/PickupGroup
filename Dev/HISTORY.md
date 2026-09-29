# PickupGroup — History

Detailed notes per version, newest first. Dev-only (`Dev/` never ships).

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
