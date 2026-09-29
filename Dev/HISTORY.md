# PickupGroup — History

Detailed notes per version, newest first. Dev-only (`Dev/` never ships).

## v0.1.0-alpha1 (2026-09-28): Phase 0, foundation

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
