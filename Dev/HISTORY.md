# PickupGroup — History

Detailed notes per version, newest first. Dev-only (`Dev/` never ships).

## v0.5.0 (2026-10-01)

Design pause ended (player decisions, see ROADMAP). Verified in game in five
checklist rounds unless noted.
- One filter per kind (schema 2 keeps the active one per kind; tabs, names,
  New and Delete gone); `Filters.Summary` line in the top bar opens setup.
- Apply flipped: click = Blizzard's sign-up dialog, shift-click = instant.
  Up to five notes (`db.notes` by slot; the dev `db.note` moves to slot 1),
  Notes tab in the sidecar; strip under Blizzard's dialog, a note selected
  on the next frame (selecting on focus didn't stick).
- Region filter: own 20-realm table (Oceanic 12, Brazil 5, Latin America 3;
  the rest North America), realm names squeezed for matching; `f.regions`.
- Lust / brez single "has" switches, `noMyClass` (local + Blizzard's
  needsMyClass); schema 3 migrates (has -> true, needs dropped, stale
  `text` field removed).
- `Filters.Sync` compares with Blizzard's current advanced filter and
  rewrites on any drift (reset button, its menu), replacing the cached key.
- Raid filter: N/H/M buttons removed; My lockout uses the highest
  Normal/Heroic save; Sporefall joins the past-raid list. Tooltip lists
  each boss Dead / Alive in journal order.
- Pane frame level = Blizzard's AutoCompleteFrame - 5 (it covered the
  search suggestions); logged levels: panel 2, list 3, pane 15, suggestions 20.
- Swap (opt-in, `db.swap`): full sign-ups -> button "Swap" withdraws the
  sign-up with the least time left; then Apply (the game wants a click per
  sign-up).
- Applications: `Reattach` after PLAYER_ENTERING_WORLD (+5 s) picks open
  sign-ups back up; pending entries older than 10 min with nothing out
  become "unknown". Verified: "reattached 2", both endings logged.
- Kit.Edit: SetScript ran after HookScript and dropped the focus-ring
  hooks; scripts set first now.
- Secret listings skipped in a running key are traced (first, every 100th).
- New mark: 5px round dot, names shifted 5px.
- Not verified yet: greyed-out Apply tooltips; the key-run trace.
- Seen: a quick double Apply logged "failed" then "applied" for the same
  listing (two log entries); harmless.

## v0.4.1 (2026-10-01)

From the tester and the player's own checks (verified in game unless noted):
- Fix: `Groups.List` sort wasn't a consistent order when a raid search
  returned a non-raid row (raid rows compared by bosses, others by score):
  table.sort errored ("attempt to index local 'b'"). Raids now sort first.
  Reproduced and checked with 2000 random mixed sorts (old: 843 failures).
- Party members who aren't leader: Apply disabled, label "Leader"; the
  game silently ignores their `ApplyToGroup` (no status event, nothing
  blocked: the tester's log). Re-renders on GROUP_ROSTER_UPDATE /
  PARTY_LEADER_CHANGED.
- `Eligible()` is false while `C_LFGList.HasActiveEntryInfo()`: the pane
  steps aside so Blizzard's listing view shows (leader and members);
  LFG_LIST_ACTIVE_ENTRY_UPDATE re-evaluates.
- Action button `SetMotionScriptsWhileDisabled(true)`: disabled buttons'
  tooltips (Leader, no seat, sign-ups full) never showed before.
- Visibility pass (player: an accessibility win): Kit palette `well`
  (white 8%) for text boxes and checkboxes, checkbox mark 8px, `ringHover`
  grey on hover and mint while typing, `btnRest` 4.5% -> 7%, off toggles
  solid grey; row stripes 2% -> 5%.
- Dev/check.lua also flags a top-level local used above its definition
  (a hover helper defined below Kit.Check errored in game before release).
- Not included: the sign-up note helper (dev only).

## v0.4.0 (2026-09-30): first stable release (CurseForge review)

The three fixes below on top of v0.4.0-alpha2, cherry-picked from `dev`
(plus `Kit.Hint`). The sign-up note helper stays on `dev` (untested).

- Bloodlust / battle rez: the Either / Has / Missing toggle confused the
  player; now paired checkboxes "Group has / needs Bloodlust" and "Group
  has / needs battle rez" (player chose two checkboxes each). Ticking one
  clears its pair; saved values unchanged ("has" / "missing").
- Fix (tester): inside a running key, listings are secret values;
  `Groups.Read` tested `info.isDelisted` and errored once per listing
  (SafeRead's pcall caught it, but LogError forwards every error to
  Blizzard's handler: count 56). `Groups.Read` now returns nil when
  `issecretvalue(info.isDelisted)`, covering every caller.
- Text boxes (Kit.Edit): light fill (white 8%) instead of black 55%; the
  score box vanished on the panel (tester). Score box shows "Any" when
  empty; its label is white like the other filter labels.

## v0.4.0-alpha2 (2026-09-29)

- Friends / guild mark: drawn "people" glyph (Kit.Glyph) at the right
  end of the name column; Battle.net blue for friends (Battle.net +
  character), guild chat green (ChatTypeInfo.GUILD) for guildmates; both
  when both (player). Not on pinned sign-ups (player). Tooltip gives
  both counts in those colours. `row.friends` no longer includes
  guildmates; `row.guild` added.
- Options: "Colour names for friends / guild" (`db.nameColors`):
  Blizzard-style name colour (green if a guildmate, else blue) replaces
  the marks (player).
- Checked visually with a temporary fake-marks command (removed).

## v0.4.0-alpha1 (2026-09-29)

- Phase 4 starts. New mark: a 3px mint dot at the row's left edge for
  listings (leader + activity) not in the previous search's results,
  until the next search. None on a category's first search; not on
  pinned sign-ups. Works in game; the dot's look to be revisited.

## v0.3.5-alpha1 (2026-09-29)

- `Filters.Sync`: the active keys filter writes Blizzard's advanced
  filter (`SaveAdvancedFilter`): activities from our dungeons (name ->
  activity group ID via `GetAvailableActivityGroups` / 
  `GetActivityGroupInfo`, current season; any unmapped dungeon = no
  narrowing, logged), needs<role> when Room for my role and exactly one
  role is picked, minimumRating = max(score floor, my score if "at least
  mine"). Other fields kept. Written only when those change (from
  `Pane.Render` / `Pane.Update`, so before Blizzard's search on a
  category change). Verified: all 8 dungeons map, nothing blocked.
- Log: `hide` and `report` kinds (they were dropped as unknown).
- Leftover probe data cleared from saved variables.

## v0.3.4-alpha1 (2026-09-29)

- Search text: Blizzard's search box refuses `SetText` from addons, so
  per-filter saved text was dropped (tried, reverted). The pane now
  starts below Blizzard's whole search row; the player types there.
  Tried and rejected on looks: covering Blizzard's refresh/Filter, and a
  four-piece pane around the box.
- Our Refresh button removed; Blizzard's refresh searches. A 1px mint
  line across the pane's top shrinks over the 3 s search cooldown
  (started by any search or a failed one).
- Probe (temporary, removed): listings carry no key level; titles are
  protected. Readable fields noted in ROADMAP item 3.
- First CurseForge build (project 1718475, Automatic Packaging from the
  public repo).

## v0.3.3 (2026-09-28)

- Empty seats' role icons are always grey; the mint ring alone marks the
  player's open seats (player).

## v0.3.2 (2026-09-28)

- Open seats for the player's role get a 1px mint ring on the tile (the
  mint-tinted role icon alone was almost unnoticeable; player).

## v0.3.1 (2026-09-28)

- "All · None" was one toggle; now two words, All and None (player).
- "Needs Bloodlust / battle rez" checkboxes became "Bloodlust / Battle rez
  in the group": Either / Has / Missing (player asked for "Has"; Missing
  keeps the old meaning). Saved `true` reads as Missing.

## v0.3.0 (2026-09-28): Phase 3 done (alpha1-alpha8 below)

- The PickupGroup button on Blizzard's panel sat far right over another
  addon's icon: the category name's frame is wider than its text, so the
  button now sits just after the text.
- Player test of alpha8: everything else fine.

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
