# PickupGroup — History

Detailed notes per version, newest first. Dev-only (`Dev/` never ships).

## v0.2.0-alpha3 (2026-09-28)

- The switch back from Blizzard's list moved to the panel's header,
  after the category name (it crowded Back / Sign Up).
- The pane ends just above Blizzard's Back button (a sliver of the list
  showed below the last row).
- Raid boss totals: the journal instance is found (log), but its
  bosses only answer with the instance selected; select, count, restore.
- Note: raids sort fewest bosses down first, so a screen of 0s is fresh
  runs, not a bug (the log shows kills of 1-8 on other listings).

## v0.2.0-alpha2 (2026-09-28): first-look fixes

From the player's screenshots of alpha1:
- The pane starts below Blizzard's window title band (the tab clashed
  with "Dungeons & Raids" and the switch icon sat on the close button).
- Opaque fill: Blizzard's list no longer shows through.
- Raids: difficulty in its own column before the raid code, in loot
  colours (N green, H blue, M orange; purple skipped for readability).
- WoW reports "none" for no sign-up; it counted as a status, so groups
  without a seat for the player showed with "-". They're now left out.
- Raid boss totals: tries the journal lookup by game map, then by map;
  traced to the log (alpha1 showed no totals).

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
