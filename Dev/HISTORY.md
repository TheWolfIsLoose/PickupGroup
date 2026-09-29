# PickupGroup — History

Detailed notes per version, newest first. Dev-only (`Dev/` never ships).

## v0.3.0-alpha8 (2026-09-28): Options and clean-up

- Sidecar header tabs: Filter / Options. The top bar's list icon now
  opens Options.
- Options: "Use Blizzard's group list instead" (moved from the top bar);
  clean-up switches, all on by default: listed longer than N hours
  (default 3), looks like an advert (no leader score + voice chat filled
  in, dungeons only), offers a carry (playstyle), blacklisted leader.
  Blacklist count and Clear (second click confirms).
- `Cleanup.lua`: the rules, the account-wide blacklist (name-realm, last
  seen; a year unseen drops off), hide-for-session; reporting a listing
  through Blizzard's report form blacklists its leader.
- Pane: "N hidden" in the top bar; click shows only the hidden rows, each
  with its reason in the tooltip, and back. Right-click a row: report
  and hide, blacklist the leader, hide until reload.
- "Room in the raid" removed (full raids delist themselves); raid
  compositions are left to the community (player).

## v0.3.0-alpha7 (2026-09-28)

- Sidecar toggles (dungeons, difficulty, boss rules): "on" is now the
  choice's colour as text plus a 1px ring of it on the neutral fill;
  mint-on-green and amber-on-green were hard to tell apart (player).
- Reset button beside Delete: the filter back to its starting rules
  (shipped ones as shipped, others clean), name kept; second click
  confirms (player).

## v0.3.0-alpha6 (2026-09-28)

- A raid filter with more than one difficulty on and any boss rules set
  shows an amber hint in place of the boss-list heading: rules apply to
  every difficulty while lockouts differ, so keep one difficulty per
  filter (player).
- March on Quel'Danas (a Season 1 raid, still listed under Midnight) is
  left out of results and the boss list (player); a named list of past
  raids in Groups.lua, edited each season.

## v0.3.0-alpha5 (2026-09-28)

- Match my lockout gave different answers for the same raid as the
  difficulty toggles changed: with Heroic and Mythic both on it took the
  highest lockout, so a Mythic save hid the Heroic one ("left as they
  were"). Now Normal/Heroic lockouts drive the boss rules whenever the
  filter looks for them; the Mythic save only decides a Mythic-only
  filter, and adds a note otherwise.

## v0.3.0-alpha4 (2026-09-28)

- Match my lockout on Mythic (player: Mythic lockouts are whole, shared
  by the 20 present at the first kill; unsaved players accept the
  group's): saved = only that one raid can take you and listings don't
  say which, so bosses are left alone and it says so; unsaved = every
  boss Either (any group works).

## v0.3.0-alpha3 (2026-09-28)

- Match my lockout (player): a button on each raid heading sets bosses
  the player killed this week to Dead and the rest to Alive, from the
  lockout for the difficulty the filter looks for (the highest if
  several); no lockout = every boss Alive. Says what it did in a tooltip
  and the log.
- Raid headings fold (click): open by default are raids with rules set,
  else the one with the most bosses; a folded heading shows how many
  rules it holds. Player agency over which raids show, without a
  separate selector; also keeps the list clear of Delete.

## v0.3.0-alpha2 (2026-09-28)

From the alpha1 test (log: no errors; filter edits sent no searches):
- Raid filters: each boss can be set Either / Alive / Dead, since raids
  aren't cleared in order (player). Boss names come from the journal
  for every raid seen in the results; a listing's killed bosses come
  from its lockout info. "Bosses down at most" is gone (replaced).
- The sidecar closes when the pane goes (leaving the search) and follows
  the category when it stays.
- The sidecar is opaque and sits above Raider.IO's panel (its text
  showed through).

## v0.3.0-alpha1 (2026-09-28): Phase 3, saved filters + sidecar

- `Filters.lua`: account-wide saved filters per kind (keys / raid),
  active one remembered per kind. Shipped: Weekly keys, Push keys
  (leader at least my score), Raid. Rules on our copy of the results:
  room for my role, dungeons, needs Bloodlust / battle rez (by classes in
  the group), leader score floor, leader at least my score; raid:
  difficulty, bosses down at most, room.
- Pane: one tab per filter (left-click switches, right-click sets it up),
  + for a new filter, a setup icon in the top bar.
- `UI/Sidecar.lua`: the Filter tab on the Group Finder's right edge
  (covers Raider.IO while open); edits apply at once; Delete keeps one
  filter per kind.
- Kit: checkbox and text box.

## v0.2.0 (2026-09-28): Phase 2 done (alpha1-alpha9 below)

## v0.2.0-alpha9 (2026-09-28)

From the alpha8 log and screenshots:
- A group you were declined from, withdrew from, or passed on kept its
  dimmed Reapply only until the next search: a search gives the listing
  a new result ID and WoW forgets the sign-up. Endings are now
  remembered by leader and activity for an hour.
- A sign-up WoW refused at once ("failed", never "applied") left no
  trace: it now shows its outcome for 5 s and enters the application log.
- Action column 48 -> 56 px: "Withdrawn" overflowed the button.

## v0.2.0-alpha8 (2026-09-28)

- A 1px line under the pinned sign-ups separates them from the scrolling
  results (player).

## v0.2.0-alpha7 (2026-09-28)

- A sign-up that ends stays pinned for 5 s with how it ended on its
  button (Declined amber; Filled, Delisted, Withdrawn, Expired, Passed
  grey; Joined mint), then drops off (player).
- Row tooltip back to the right of the row (down-left covered the pane).
- alpha6 log confirmed: application log endings recorded correctly
  (withdrawn, invite passed, delisted, filled).

## v0.2.0-alpha6 (2026-09-28)

- Application log (`Applications.lua`): each sign-up saved per character
  with instance, leader, roles, and its ending (declined, filled,
  delisted, withdrawn, timed out, invite declined, failed, joined; a
  finished key after joining becomes timed / depleted with its level).
  Activity line in the log for each ending.
- Several modules can now listen to the same game event.
- Row tooltip opens down and to the left (player).
- Teleport button moved to Later (player).

## v0.2.0-alpha5 (2026-09-28)

- World boss listings (map 0) count as one boss: 0/1 or 1/1 (player).

## v0.2.0-alpha4 (2026-09-28)

- Fix: alpha3's journal select threw on a world boss listing (map 0,
  journal instance 1206), which blanked the whole raid list. Map 0 is
  skipped, the select is guarded, and any listing that errors is now
  left out and logged once instead of emptying the list.

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
