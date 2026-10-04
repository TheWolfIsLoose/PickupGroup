# PickupGroup — History

Detailed notes per version, newest first. Dev-only (`Dev/` never ships).

## 0.9.0 alphas (dev)

- alpha10 (copy pass, 2026-10-04): README rewritten in the suite format (tagline, Features, Commands, Install, Credits, License) and `Dev/CURSEFORGE.md` for the CurseForge description; TOC Notes match the CurseForge summary; American spelling (Color names, recognize); `/pug` help uses em dashes like Stock Clerk's. Name stays PickupGroup (player, 2026-10-04).
- alpha9 (UI/UX sweep, 2026-10-04): suite style guide written (project doc "Suite style guide", replaces the accessibility addendum); `Kit.Palette` gains `soft`, `muted`, `warn`, `bad`; stray greys onto tokens (0.6 off states / role tint -> 0.55 muted, 0.84 -> 0.85, chat help 888888 -> 8C8C8C). `Dev/STYLE.md` points to the guide.
- alpha8 (player): history Reset (two clicks; this character, or all with All characters) wipes sign-ups + counts and restarts the count; `chars[..].since` (oldest kept sign-up, or the reset time) shows as "times turned away since <date>" and in /pug stats. Header lines (records, tally) wrap freely; the table follows them down (alpha7's records line ran into the tally).
- alpha7 (player's log, 2026-10-04): 60 sign-ups, zero "declined" ever: the game reports a leader's decline as Filled / Delisted, so the headline counts every "no" the applicant sees (declined, filled, delisted, timed out) as "times turned away". 31 "cold feet" were mostly the game withdrawing other sign-ups when the player got in (same second as the join): now "Moved on" (live, plus schema 5 re-labels old entries within 5 s of a join and re-seeds the lifetime counts). Vote to abandon (INSTANCE_ABANDON_VOTE_FINISHED, passed, inside a key) ends the joined sign-up as "abandoned" ("Bailed"), with the key level; whether the owner's key dropped (resilience) isn't visible to us. History header gives the tally two lines.
- alpha6 (player, 2026-10-04): **decline counter**, the history's fun corner (self-deprecating, never mean). Lifetime counts per character (`chars[..].tally`: applied, each ending, joined, timed, depleted), seeded once from the list at PLAYER_LOGIN, never trimmed. Sign-up history: big amber lifetime-declines number + quip by tier, a records line (today's sign-ups / nos / got in, fastest no, longest dry spell = most sign-ups in a row without getting in), witty ending words (Nope, Too slow, Vanished, Cold feet, Ghosted, Got in!). `/pug stats` prints the same for chat. `Dev/test_history.lua` checks seed + records.
- alpha6: the sidecar opens by itself on its filter each time the search pane appears (Dungeons / current Raids, PickupGroup on); closing it holds until the next time. Eligibility uses the panel's visibility, so closing the Group Finder counts as leaving.
- alpha5: the Blizzard-list hint moves into that checkbox's tooltip (hint tooltip, hidden by "Hide hint tooltips"), like every other explainer on Options (player); frees its row.
- alpha4: the Blizzard-list hint indents 18 to line up with its checkbox's text, like the clash line (player: left-aligned looked jarring).
- alpha3: login / reload prints "PickupGroup: vX loaded. Type /pug for commands." so the player can see which build is running (alpha2's install didn't land; player asked, like StockClerk's line).
- alpha2: the Blizzard-list hint wrapped onto the next checkbox; now "Switch back from Blizzard's panel." (one line). Options otherwise fit (player screenshot).
- alpha1 (player, 2026-10-04): fill chime. When the party a sign-up got the player into reaches 5 (roster goes from under 5 to 5, then Applications.LastJoined() a second later), plays Media/TheCyclist.ogg (The Cyclist, copied from the player's SharedMedia: Tones) on the Master channel. Options: "Chime when my group fills", on by default (opt-out, saved as noChime). Dungeons only (raids: see ROADMAP). Options rows: the Blizzard-list hint is one line and two gaps shrank so the new row fits; checkboxes stay 24 apart.

## v0.8.1 (2026-10-04)

The 0.8.1 alphas below (leader mark settled by the player).

## 0.8.1 alphas (dev)

- alpha5: leader ring dimmed to 0.7 grey (3.0:1+ on the window; player + tester look).
- alpha4: leader ring moved outside the black ring and made light grey (0.9): gold blended into Holy Paladin and other warm icons (player).
- alpha3: the leader seat gets a soft gold 1px ring (LEADER_RING) instead of the crown (player); the tooltip keeps the crown.
- alpha2: crown 2px lower, overlapping its own seat (player: it crowded the row above).
- alpha1 (player, 2026-10-04): leader shown when searching: Blizzard's leader crown (atlas groupfinder-icon-leader) over the leader's comp tile (GetSearchResultPlayerInfo .isLeader; row.leaderClass); tooltip leader line gets the crown and the class colour (raids: scanned among the members on hover). Trace once if no member is flagged.

## v0.8.0 (2026-10-04)

All 0.7.1 alphas below (rounds 17-20 pass; the teleport party check after alpha4 is untested, organic).

## 0.7.1 alphas (dev, 2026-10-02 to 2026-10-04)

- alpha1: group tooltip names friends / guildmates (C_LFGList.GetSearchResultFriends), counts as fallback.
- alpha2: teleport button hides while its spell is on cooldown (C_Spell.GetSpellCooldown > 2 s; replaces hide-on-cast, which reset on zone / group changes). Key run with the Group Finder open: secret-listing guard held (600+ skipped, no errors).
- alpha6 (player, 2026-10-04): no scroll bars in our lists: Kit.More, a "more below" chevron at the bottom centre that pulses 3 x 1.5 s then holds (WCAG 2.2.2: stops within 5 s), in the pane and the leader view (replaces the leader's thumb track; rows widen to the edge). Log and history windows keep Blizzard's scroll bars (long text you drag through).
- alpha5 (round 19 calls, 2026-10-04): leading filters (lead_keys / lead_raid: regions, score / ilvl floor; dims only) in the sidecar from a slider icon in the leader top bar; Sidecar.Close(leading) so the pane and leader view each close only their side; needs line plurals ("4 healers") and short form (T / H / D, Lust, rez) when it doesn't fit, wider (to the applicant count); role buttons back to 17px; teleport trace reads "none" when no dungeon; Kit.SLIDERS shared. Friend / guild features moved to an organic-testing bundle (ROADMAP).
- alpha4 (tester bug, 2026-10-03): Tyler joined a party not through a sign-up; its leader's key listing (VSA 19) came down when it filled, so Teleport fell back to his last joined sign-up (AOF) from earlier. LastJoined now needs that sign-up's leader still in the party (UnitInParty); the party's own listing is remembered after it delists until the group breaks up; trace "party dungeon ... (source)".
- alpha3 (one build, 2026-10-03):
  - Raid leader view (UI/Leader.lua): Listing() returns keys / raid (maxNumPlayers > 5); target comp bar (Kit.Toggle presets 10/20/25/30, T/H/D boxes; ns.CharDB().raidTarget, default 2/4/14); Roster() reads the raid; brez wanted up to 2; raid buff adds table (BUFF); Prog column from RaiderIO.GetProfile(name).raidProfile.progress (best difficulty with kills in the listed raid, cached per name; trace when Raider.IO names the raid differently); Score column hidden for raids; header columns chained so widths change per kind; raid "fills a seat" edge from half the target comp.
  - Ponytail sweep: leader probe and /pug applicants, /pug tp, db.probe / db.note leftovers, the Apply-click tester diagnostics, two dev traces in the notes strip, fallback anchors for SearchBox / BackButton, never-nil guards in Filters, Groups' Application() wrapper; LogPopup + History share one Window builder (-155 / +31 lines).
  - WCAG 2.2: Kit.Toggle (moved from Sidecar) shows "on" with a 2px bar too (1.4.1); guild mark is a banner glyph, friends a person (1.4.1); untimed best key "+18x" (1.4.1); Kit.Check hit area 24px, sidecar check / boss / dungeon rows 24px apart, None / All 24px tall (2.5.8); header role buttons 24px apart (2.5.8 spacing).
  - Roadmap cut to the current plan; the old one is archived at the end of this file.

## v0.7.0 (2026-10-02)

0.6.2-alpha1..13 (rounds 11-16). Teleport confirmed by testers; the hide-on-
cast change and a key run are untested.
- Leader view, keys (UI/Leader.lua, new file): frame over
  LFGListFrame.ApplicationViewer from the Name column header to the viewer's
  right edge, up to the refresh corner; own refresh (C_LFGList.RefreshApplicants)
  and scroll track; shown while leading a Mythic+ listing as leader or solo.
  Rows per applicant member: spec icon, name, ilvl, score, best run in the
  listed dungeon (GetApplicantDungeonScoreForListing; white timed / amber not),
  "Lust" / "Rez" adds (Filters.LUST / BREZ), note line (protected text, shown
  only). Needs bar counts invited applicants as seated. Dimmed: no seat for the
  role, realm region off in the keys filter, blacklisted (Cleanup.IsBlacklisted).
  Mint 2px row edge = fills an open seat, from 3 in the group (RING_FROM), open
  applicants only. Invite / Decline from our buttons work (not blocked). Duo
  rows indented + joined. Scroll clamps at the last applicant. "lead" log kind.
- Apply flipped: click = ApplyToGroup at once; shift-click = Blizzard's dialog
  (our notes). Reapply: click twice / shift-click.
- EllesmereUI (compat, reads EllesmereUIDB live): quickSignup is fine with
  shift-click (it skips auto Sign Up while Shift is held); persistSignupNote
  -> Notes.Conflict(): our strip off, one alert per onset (db.noteConflict),
  amber notices in Options and the Notes tab. Option db.noteStrip.
- Friends / guild: always shown (skip our rules and clean-up) and sorted first.
- Use Blizzard's list: Filters.RestoreBlizzard clears our narrowing (every
  dungeon, no role / class / score); switching back is logged.
- Teleport hides on UNIT_SPELLCAST_SUCCEEDED of its spell (secret guard).
- Mint rings removed from empty comp seats; note boxes clear selection on
  focus loss; Reapply tooltip; `/pug applicants` probe on demand only.

## v0.6.1 (2026-10-02)

Code jam (alpha1-4), rounds 8-10 tested in game except teleport in a 5/5
and a key run (player: don't hold the release for them).
- Kit palette `ringRest` 0.4 grey on buttons, text boxes, checkbox wells
  and off toggles (3.3:1 against the panel, WCAG 1.4.11); `ringHover` 0.7;
  window edges and comp tiles stay black. Checkbox hit rect +2px top and
  bottom (20px; 24px needs 24px rows).
- `ns.Hints()` / `db.noHints`: Options "Hide hint tooltips" hides how-to
  tooltips (Apply hint, checkbox / region / role / header icon / hidden
  count / My lockout / Filter button / teleport move line); information
  tooltips stay.
- `Pane.RaidDifficulty`: the searched text "<raid> (Normal|Heroic|Mythic)"
  (PLAYER_DIFFICULTY1/2/6) first, listings second.
- My lockout toggles: session-only undo of the raid's boss rules; mint
  while applied; a hand edit or Reset drops it.
- Blizzard's Filter button tooltip line (keys only).
- Friends mark on pinned rows; coloured names: friend blue wins.
- Trace lines "levels", "update: category" and empty "reattached" dropped.

## v0.6.0 (2026-10-02)

Player asked for a quick release of the day's work; DevChecklist round 8
was still open, so items below marked (untested) shipped on code review.
- Party-aware room: `Groups.Party` (assigned role, else spec via
  GetInspectSpecialization, else any seat); verified with a 2-DPS party.
- `Groups.CanHave` (lust / brez): group has it; or with room, the party
  brings it, or a seat a buff class can fill stays open after the party
  sits (unknown roles take other seats first). Self-check:
  `Dev/test_canhave.lua` (10 cases). (untested in game)
- Dungeon buttons: best timed key (`C_MythicPlus.GetSeasonBestForMap`),
  "AOF (+19)", key white while on, "(—)" for none. Verified (screenshot).
- Raid boss rules "must be alive" (schema 4); My lockout reads the saved
  instance for the difficulty most listed groups for that raid are on
  (`Pane.RaidDifficulty`). (untested)
- Tooltip trimmed; hints on the Apply tooltip; Whisper leader
  (`ChatFrameUtil.SendTell`, as Blizzard's menu). (untested)
- Sign-up history popup (in LogPopup.lua; newest 300). (untested)
- Teleport: secure button, Hero's Path flyout spell matched by its
  description; `/pug tp` dev check. (untested)
- Raider.IO: `RaiderIO_ProfileTooltipAnchor` re-pointed to the sidecar
  (2px gap) while open, via a SetPoint hook. Verified (screenshot, 4px).
- Notes strip: refreshes on `LFGListApplicationDialog_Show` too; focus on
  the next frame. (raid case untested)
- Comp tiles 17px, 3px gaps, icons zoomed ~10%. (untested)

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

## Archive: the roadmap before the 2026-10-03 clean-up

Moved verbatim from ROADMAP.md (decisions superseded since are marked
there by later notes; the current plan is ROADMAP.md).

### Session logs and plans, 2026-09-28 to 2026-10-03

**State, 2026-10-02 16:40 ET: v0.7.0 (stable) released** (keys leader
view, Apply click / shift-click flip, EllesmereUI note clash handling,
friends first, Use Blizzard clears our filter, teleport hides on cast).
Installed in the player's AddOns; main and dev both at v0.7.0. DevChecklist
round 16 is installed with the three open items below.

**0.7.1-alpha1 on dev (2026-10-02, installed, untested):** group tooltip names
the friends / guildmates in a listing (C_LFGList.GetSearchResultFriends:
Battle.net friends, character friends, guildmates), as Blizzard's tooltip
does; falls back to counts. Checklist round 17.

**2026-10-02 night (player, v0.7.1-alpha1):** key run with the Group Finder
open: the secret-listing guard held (600+ listings skipped, no errors);
+18 DON timed logged. Teleport: showed again after a successful cast and
while on cooldown (the hide-on-cast state reset when the group / zone
changed). alpha2 replaces it: the button hides whenever its spell is on
cooldown (C_Spell.GetSpellCooldown, > 2 s, refreshed on
SPELL_UPDATE_COOLDOWN); a successful cast starts that cooldown. Round 18.

**Next session, in order:**
1. Read the saved log + DevChecklist ticks (stage `PickupGroup.lua` and
   `DevChecklist.lua` from SavedVariables; never ask for a paste).
2. Open items (organic, need a group): teleport hides once the cast lands
   (alpha13, untested); a key run with the Group Finder open (secret-listing
   guard); the friend who couldn't see the player's listing, even in
   Blizzard's list (his PickupGroup.lua from a retry on v0.7.0).
3. **Raid leader view** (player's next feature): design on the probe facts
   below (`/pug applicants` while leading a raid; drill into Raider.IO's
   raidProfile.progress / sortedProgress for progress). Target comp per
   listing (2/4/14, 2/3/10, ...), seats left per role, raid buffs / utility
   an applicant adds (per-class table, checked in game), same region /
   blacklist dimming, mint edge + dim as on keys. No class / spec filters.
4. Parked until the player calls a 1.0 release candidate: the ponytail +
   WCAG 2.2 + roadmap clean-up bundle (below); final name.

Session log of 2026-10-02 (rounds 8-16) follows; the newest notes are at
the top of each block.

**State, 2026-10-02 01:10 ET: v0.6.0 (stable) released** with everything
below (player's call, before the round-8 checks; see HISTORY for what
shipped untested). Built 2026-10-01 (all installed in the
player's AddOns; the player works through the DevChecklist, round 8, by
area, tonight / tomorrow):
- Party-aware room for my role (**works**, player + Tripolos).
- Whisper leader in the row menu.
- Raid boss rules = "must be alive" checkboxes; My lockout reads the
  lockout of the difficulty in view (Pane.RaidDifficulty), button shows
  it, e.g. "My lockout (H)"; schema 4.
- Notes strip refreshes when Blizzard's dialog is reused (raid sign-up
  bug; cause not confirmed, trace "strip shown ... focused").
- Sign-up history view (Options > Sign-up history; newest 300).
- Teleport button (5/5 party, not inside; untested; `/pug tp` dev check).
- Group tooltip trimmed (no labels / realm / hints; spec icons); hints on
  the Apply tooltip.
- Dungeon buttons show the best timed key, "AOF (+18)", key white while
  on, "(—)" for none (measured: fits with 3-letter codes).
- Has Bloodlust / battle rez: the group has it, the party brings it, or a
  seat that such a class can fill stays open after the party joins
  (Groups.CanHave; self-check `lua5.1 Dev/test_canhave.lua`).
- Raider.IO's profile panel moves to the sidecar's right edge (2px gap)
  while it's open.

**0.6.1-alpha1 on dev (2026-10-02, installed, untested; checks added to
round 8):** grey rest rings on controls (Kit `ringRest` 0.4, 3.3:1; hover
0.7; window edges and comp tiles stay black: player chose grey);
checkbox click area 20px (`SetHitRectInsets`; 24px needs 24px rows);
Blizzard's Filter button tooltip says our keys filter sets it; trace
lines "levels", "update: category" and empty "reattached" dropped.
StockClerk gets the same grey rings in its own pass.

**Round 8 (2026-10-02, player): all pass** except Normal lockout (button
read "My lockout" with no Normal groups listed), teleport in a 5/5 and a key
run (both carried to round 9). **0.6.1-alpha2:** My lockout's difficulty
comes from the searched text "<raid> (Normal)" first (`Pane.RaidDifficulty`,
PLAYER_DIFFICULTY1/2/6), listings second; Options "Hide hint tooltips"
(`db.noHints`, `ns.Hints()`; player: veterans want the how-to tooltips gone;
information tooltips — rows, reasons, results, dungeon best keys — stay).
Noted: the notes strip traces twice per open (OnShow + the _Show hook), harmless.

**Round 9 (2026-10-02, player): all pass** — Normal lockout label with no
groups, My lockout toggle (alpha3: second click restores the earlier boss
picks, mint while applied; a hand edit or Reset drops the undo), Hide hint
tooltips on/off. Still open: teleport in a 5/5, key run (need a group).

**Friends mark settled (player, 2026-10-02; 0.6.1-alpha4):** mixed group =
two marks (blue + green); "Colour names" goes friend blue when both (as
Blizzard's list); pinned sign-ups get the marks / name colour too.

**v0.6.1 (stable) released 2026-10-02** with all of the 0.6.1 alphas.

**Parked until the player calls a 1.0 release candidate (2026-10-02):** one
bundled task = ponytail sweep + WCAG 2.2 pass + roadmap clean-up (prune dead
items: best-group sort, keys that beat my best, filter picker, release CI,
"whether to publish"). Left for WCAG: focus cues, 24px targets (18px action
buttons, 12px checkboxes), friend/guild marks differ by colour only;
StockClerk's grey rings in its own pass.

**Leader view (player, 2026-10-02): now in design, split into dungeon and
raid tracks.** 0.6.2-alpha1 adds a temporary probe: each new applicant to
your listing is traced once (tag "probe": applicant fields, member fields,
GetApplicantDungeonScoreForListing / GetApplicantBestDungeonScore, Raider.IO
profile keys); `/pug applicants` logs all. Remove the probe once designed.

**Probe results (2026-10-02, player led a KR key and VA H / M raids):**
nothing secret out of combat. Per applicant: applicantID, numMembers
(premades of 2+ seen), isNew, status; note = protected string (`|Kv|k`:
shown, never read or filtered). Per member: Name-Realm (realm suffix always
present, so the region filter works), class, specID, offered roles + assigned
role, ilvl, M+ score. `GetApplicantDungeonScoreForListing(id, m, activityID)`:
best run in the listed dungeon (bestRunLevel, finishedSuccess = timed,
duration, mapScore); `GetApplicantBestDungeonScore`: overall best run. Raid
applicants: score 0, keys fields empty. Raider.IO (when loaded):
`RaiderIO.GetProfile(name)` -> mythicKeystoneProfile (currentScore,
maxDungeonLevel, milestones...), raidProfile (progress, sortedProgress,
mainProgress tables: drill into these for raid progress).

**Keys leader view, first cut (0.6.2-alpha2, untested; new file
UI/Leader.lua, game restart):** our frame over Blizzard's ApplicationViewer
(Name column header to ScrollBox bottom) while leading a key and leader or
solo; top bar "Needs <seats>, Bloodlust, battle rez" (invited applicants count
as seated); rows per applicant member (spec icon, mint ring = fills an open
seat; name; ilvl; score; best run in the listed dungeon, white timed / amber
not; "Lust" / "Rez" adds); note line under the applicant (protected text,
shown only); dimmed = no seat for the role, region off in the keys filter,
blacklisted; Invite / Decline buttons (C_LFGList.InviteApplicant /
DeclineApplicant from our click: spike whether blocked). WCAG note: timed
vs not is colour only (tooltip says it) — fix in the 1.0 pass.

**Round 12 (player): keys leader view works.** Invite / Decline from our
buttons went through, nothing blocked (an invitee joined). Fixed in alpha3:
"lead" log kind was missing (entries dropped as "unknown kind"); a duo's
second member is indented and joined by a line; Blizzard's scroll bar is
covered by our own track + thumb.
**Tester reports (Tripoloski's saved file, 0.6.1):** (1) applying to the
player's group showed no friend cue (his nameColors is on, so it'd be a blue
name) and it didn't sort to the top: alpha3 sorts friends, then guild, first
(as Blizzard); the cue itself is unexplained, so alpha3 traces each Apply
click with the listing's numBNetFriends / numCharFriends / numGuildMates.
(2) a plain click signed up with no dialog: his log shows our direct-apply
path ran (13:30:59, 13:35:29, 13:35:40) while other clicks opened the
dialog, alternating; cause unknown (shift held? another addon?): the same
trace logs mouse button, shift state and whether Blizzard's dialog function
exists. Needs his file after another try on dev.

**EllesmereUI (player, 2026-10-02):** its "Quick Signup" and "Persistent
Signup Note" clash with our notes (likely behind the tester's no-dialog
sign-ups). alpha4: Options "My notes under Blizzard's sign-up window" (on by
default, `db.noteStrip = false` turns it off); trace whether EllesmereUI is
loaded. Also fixed: a note box kept its selection after losing focus.

**Apply flipped back + EllesmereUI clash handled (player, 2026-10-02;
0.6.2-alpha6):** click Apply = sign up at once (no note); shift-click =
Blizzard's sign-up window with our notes (deliberate). Reapply: click twice
= at once; shift-click = the window. EllesmereUI (QoL module, read from
`EllesmereUIDB`, compatibility only): `quickSignup` auto-presses Sign Up
when the window shows unless Shift is held, so our shift-click (Shift held
as the window opens) keeps it open: no clash. `persistSignupNote` replaces
LFGListApplicationDialog_Show and adds its own copy helper: clash, so
`Notes.Conflict()` turns our strip off (`Notes.StripOn()`), an alert window
says why and how to change it (once per onset: `db.noteConflict`, checked
at login and on every sign-up window / Options paint), Options shows an
amber "Off: ..." line, the Notes tab an amber notice.

**Round 13 (player, 2026-10-02):** new clicks pass (log: shift true ->
dialog, false -> direct); EllesmereUI detection follows its toggles live (log
14:29:05 clash on, 14:31:39 gone, no reload): we read its in-memory
`EllesmereUIDB`, which its option toggles write at once. Issues ->
0.6.2-alpha7: leader scroll ran past the last applicant (now stops when the
last one is in view); "Use Blizzard's list instead" left our narrowing in
Blizzard's filter (now cleared: every dungeon, no role / class / score;
`Filters.RestoreBlizzard`); friends / guild groups always show (our rules and
clean-up skip them; Blizzard's search still applies) and sort first. **Open:**
a BNet friend's listed group showed no cue and didn't sort first: our read
gave 0 friends (traces: bnet 0 char 0 guild 0 on every click). `/pug friends`
probe dumps listing fields + GetSearchResultFriends. Friend couldn't see the
player's listing even in Blizzard's list: unexplained, his file from that
attempt needed. Mint border on sign-ups "a bit much" (player): revisit.

**Mint rings trimmed (player, 2026-10-02; 0.6.2-alpha8):** search comp tiles
no longer ring your role's empty seat in mint (an empty seat already reads as
open; the layout is consistent and scans well). Leader view: the spec icon's
mint "fills a seat" ring only from 3 in the group (`RING_FROM`); at 1-2 comp
is wide open and the ring cluttered the spec icon, a primary decision cue.

**Round 14 (player, 2026-10-02): all pass** but party items. A BNet friend's
group (Twompy, MR) sorted to the top with the friend mark and "1 friend in the
group" in its tooltip, so the friend counts do come through (the earlier
zero is unexplained; /pug friends probe removed in alpha9). Use Blizzard's
list cleared our narrowing (menu screenshot); the PickupGroup button that
switches back now logs the setting too. Leader: duo rows joined, scroll stops
at the end, no rings solo. Still open: the friend who couldn't see the
player's listing (needs his file), teleport, key run.

**Leader "fills a seat" cue (player, 2026-10-02; alpha10):** mint stays, moved
from a ring on the spec icon to a 2px mint edge on the row's left (from 3
in the group); with the dimming of non-fits, that pair is the cue.

**Round 15 (player, 2026-10-02): pass.** Leader panel is one piece (header
to the viewer's right edge, up to the refresh corner) with our refresh; mint
edges from 3 in the group. Checklist pruned to round 16: only the friend
test, teleport and key run remain.

**Teleport (testers, 2026-10-02): works** (shows on a full group, casts);
it stayed until inside the instance. alpha13 hides it once the cast
succeeds (UNIT_SPELLCAST_SUCCEEDED for its spell); it comes back for the
next full group.

Leader view design notes (player, 2026-10-02):
- **Target comp** the leader sets per listing kind: raid sizes like
  2/4/14 or 2/3/10 (tanks / healers / damage), dungeons fixed 1/1/3.
  Applicant rows get contextual cues against it: fills an open seat,
  over target for that role (dimmed, never hidden), plus the filter logic
  we already have (score floor, realm region, blacklist).
- **Rounding out the comp:** contextual highlights / nods when an applicant
  brings something the group lacks: Bloodlust, battle rez, and (raids)
  class-provided raid buffs or utility not yet covered. A highlight on the
  applicant, phrased as what they'd add ("adds Bloodlust"), never as what
  someone lacks. The buff/utility table is per class, checked in game each
  season.
- **No class / spec filters for leaders (player, Decided):** they create
  blind spots and gaps and invite toxic behaviour. Cues only point at what
  an applicant adds; nothing hides or ranks people by class or spec.
- Tracks: dungeon (keys) and raid, designed and built separately.

**v0.7.0 (stable) released 2026-10-02** with all 0.6.2 alphas. Next: raid
leader view (target comp, seats per role, raid buffs an applicant adds,
Raider.IO progress); open: friend couldn't see the player's listing (his
file), key run, teleport hide-on-cast check.

**Next session:** read the saved log + DevChecklist ticks (no paste:
stage `PickupGroup.lua` and `DevChecklist.lua` from SavedVariables), fix
what fails, then a v0.6.x patch for anything that fails. Still
parked: greyed-out Apply tooltip "no seat"; key-run trace; teleport in a
real 5/5. After that: accessibility + ponytail pass (player decides grey
vs black rest outlines first), final name before 1.0.

**Testing note (player, 2026-10-01):** the tester plays casually and doesn't
take notes, so his reports are leads, not repro steps. To answer an issue
for real, spike it ourselves (temporary `/pug` probe, reproduce, read the
log). Open lead: the tester's client showed sign-ups as pending for hours
(likely from the non-leader Apply clicks); unconfirmed.

**Visibility (player, 2026-10-01):** the light text-box well was a noted
accessibility win ("you can actually tell there's a field"). Keep inputs
and controls visibly distinct from the panel everywhere (Kit palette:
`well`, `ringHover`, brighter `btnRest`).
Reference (player, 2026-10-01): WCAG 2.2, https://www.w3.org/TR/WCAG22/ .
The criteria that apply to an addon UI: 1.4.1 Use of Color (A: never colour
alone), 1.4.3 Contrast Minimum (AA: text 4.5:1, large text 3:1; disabled
controls exempt), 1.4.11 Non-text Contrast (AA: control boundaries and
meaningful graphics 3:1 against what's next to them), 2.4.7 / 2.4.13 Focus
Visible / Appearance (a clear focus cue, 3:1), 2.5.8 Target Size Minimum
(AA: about 24x24 px), 3.3.2 Labels or Instructions (A), 3.2.4 Consistent
Identification (AA).
Baseline measured 2026-10-01 (v0.4.1 palette over the panel / window):
text white 19:1, grey labels .55 5.7:1, mint 15.6:1, score orange 7.9:1,
off toggles 5.8:1 (all pass); disabled text 4.2:1 (exempt); hover ring
5.7:1 and mint focus ring 15.6:1 (pass). **Fails 1.4.11 at rest:** text-box
/ checkbox well 1.2:1, button face 1.2:1, black 1px ring 1.1:1 against the
panel. Candidate fix: a rest ring of about 0.4 grey on inputs and buttons
(3.3:1) instead of black; that departs from StockClerk's black-line style,
so the player decides (parked: see item 6). Checkbox 12px and action buttons 18px tall are
under 2.5.8's 24px (the label widens the checkbox's click area).

**Resume here:**
1. Re-ideate scope with the player: what PickupGroup is for, given the
   walls above. Start from the notes-per-search-type idea (liked) and the
   "less friction + memory" reframe; no code. Decide: one filter per
   category vs several; what a "search type" is (it carries the note);
   whether a plain Apply opens Blizzard's dialog when a note exists.
   **Decided 2026-10-01 (player), the design pause ends:**
   - **What it is:** enhancements on top of Blizzard's search. Pass our
     filter through to Blizzard's filter; otherwise take what Blizzard
     gives and show it better. Preserve and work with Blizzard's own
     pieces rather than replace them.
   - **One filter per content type** (keys, raid): the player types search
     text in Blizzard's box anyway, and listings can't be filtered by
     name, so several filters add little. Tabs go; the filter picker (3c)
     is moot. **Built on dev 2026-10-01** (schema 2 keeps the filter that
     was active per kind; the top bar shows a one-line summary of the
     filter, click to set it up; name box and Delete gone).
   - **Raids:** players type the raid's name and pick Blizzard's
     suggestion, which is one line per raid and difficulty (e.g. "<raid>
     Heroic"). Work with that, don't replace it. **Done on dev
     2026-10-01 (player's screenshot):** the raid filter's N/H/M buttons
     are gone (the suggestion carries the difficulty; rows keep their
     difficulty letter); "My lockout" uses the highest Normal/Heroic save,
     a Mythic save adds a note.
   - **Notes:** up to 5 pre-made notes (a list, not tied to a filter).
     **Click Apply** opens Blizzard's sign-up dialog with the notes
     offered to copy (the game won't let an addon fill the note);
     **shift-click Apply** signs up at once with no note. (The reverse of
     today: a modified click suits our one button better than a double
     click.)
   - **Realm regions:** NA is its own game region (EU, CN, KR, TW are
     separate licences and never in its results), so only US-region
     realms matter: our own table of the 20 Oceanic, Brazil and Latin
     America realms, everything else North America; no library.
     Leader names are "Name-Realm" with the realm's apostrophes kept and
     its spaces as shown in game (player); compare with spaces stripped
     to be safe. A same-realm leader may have no "-Realm": use the
     player's own realm.
2. Optional probe the player said he'd revisit: `/pug` command logging
   `RaiderIO.GetProfile` / `ArchonTooltip.GetProfile` for the target and a
   live applicant (decides the leader-side applicant pane).
3. Plan from here (one change per alpha, all on dev until tested):
   a. One filter per kind (built, untested).
   b. Apply flip: click = Blizzard's dialog with notes to copy,
      shift-click = instant sign-up; re-apply friction kept for shift.
      **Built on dev 2026-10-01, untested.**
   c. Up to 5 notes (sidecar's new Notes tab, `db.notes` by slot; the
      early single `db.note` moves to slot 1); the strip under Blizzard's
      dialog lists them, the first focused and selected, click another
      to select it for Ctrl+C. **Built on dev 2026-10-01, untested.**
   d. Region filter from the 20-realm table. **Built on dev 2026-10-01,
      untested:** "Leader's realm" toggles NA / OCE / BR / LAT in both
      filters (`f.regions`, nil = all), region in the row tooltip and the
      filter summary; realm names compared squeezed (no spaces, hyphens
      or apostrophes, lower case); no realm suffix = the player's realm.
      Local only (no server field).
   e. Verified 2026-10-01 (player screenshot): Blizzard's search
      suggestions show over the pane (pane at suggestions' level - 5);
      the raid filter without difficulty buttons; region toggles render.
      Raid browsing: no errors (player). v0.4.0 crash fix: a trace line
      "secret listing skipped" (first, then every 100th) shows the guard
      working in real play; check the log after a key run with the Group
      Finder open (no spike: secret values can't be simulated).
      Round 1 (player, checklist + log): summary, shift-click Apply,
      boss-by-name tooltip (out-of-order kills right), region filter and
      tooltip, text-box ring, realm row / Sporefall all pass. Levels:
      panel 2, list 3, pane 15, suggestions 20. One shift-click failed at
      once (AOF, likely delisted). Fixed: summary said "8 dungeons" with all
      on; a note's selection didn't stick (now selected on the next frame).
      Round 3: click Apply -> note selected -> pasted -> Blizzard's Sign Up
      went through (log: applied, then our Cancel). **Notes flow verified.**
      Left: greyed-out Apply tooltips; a key run (secret-listing trace).
   Then the accessibility + ponytail pass, then v1.0 items.
4. Untested, any time: text boxes return to the grey ring after typing
   (dev, 2026-10-01: Kit.Edit's SetScript ran after its HookScripts and
   dropped them, so the mint focus ring stayed after leaving a box);
   disabled-button tooltip ("Leader", no seat,
   sign-ups full); v0.4.0's crash fix (start a key with the Group Finder
   open); raid sort fix (browse Raids - current).
5. Open lead: tester's sign-ups stuck "pending" for hours (likely the
   non-leader Apply clicks); spike it ourselves if it recurs.
6. Parked: accessibility pass with the ponytail sweep, both addons
   (project doc `claude/style-guide-accessibility-addendum.md`); region
   filter before 1.0; party-aware room (needs friends); filter picker
   (moot if filters collapse); final name before 1.0.

**In-game test list (player, 2026-10-01):** `Dev/DevChecklist/` is a
dev-only addon installed as `Interface\AddOns\DevChecklist` (never
shipped; works for StockClerk too). Each test round, rewrite
`Checklist.lua` (round name; items as { addon, what to do / expect, what to
send: SS, log, ... }) and install it; a `/reload` picks it up. Group the
items by area (dungeon view, raid view, notes / sign-ups, options, party,
...): player, 2026-10-01; keep each area's items together in the list. It shows at
login while anything is unticked; `/dc` toggles it. Ticks are saved per
item text in `WTF\Account\SAVAGEFEARLESS\SavedVariables\DevChecklist.lua`:
read them with the log.

Testing method (player's preference): the player tests in game,
`/reload`s and says "done"; Claude reads the log from the saved variables
file (Session setup), never asks for a paste. Screenshots for layout.
Iterate in small alphas: one fix or feature per build, installed and
verified (checksums) each time.

Next, in order:
0. **CurseForge (2026-09-29): live.** Project 1718475 (in the TOC),
   repo made public, CurseForge's Automatic Packaging pulls each new tag
   (StockClerk's setup). Before 1.0 every version is `-alphaN`. Still
   open: the final name (display name can change, the slug can't); the
   zlib credit if the realm library ships.
1. **Party-aware room** (player; **built on dev 2026-10-01, works**): "Room for my role" must mean "room for
   my group" in a party: the group's open seats fit every party member's
   assigned role (UnitGroupRolesAssigned on party units; the leader's
   sign-up carries the party) and members + party <= 5. The mint ring on
   empty seats follows the same rule. Needs a party test (friends).
2. **Row menu: verified 2026-09-29** (Blacklist logged; Report opens
   Blizzard's form; Hide until reload hides; nothing blocked).
   Auto-blacklist on a submitted report is untested by choice (the
   player won't file a false report): taken on faith, watch the log for
   `blacklist ... why = reported` from real use.
3. **Search text** (last Phase 3 item). **Found 2026-09-29:** Blizzard's
   search box refuses `SetText` from addons ("Call is illegal when
   disabled by security settings"), so saved per-filter text can't be
   sent: only text the player types works (v0.3.4-alpha1 tried it;
   reverted). Probe of 8 M+ listings: no key level field at all; titles
   are protected (`|Kt..|k`). Readable: requiredDungeonScore,
   leaderBestDungeonScoreInfo (leader's best run), leaderOverallDungeonScore,
   generalPlaystyle, comment (the listing's description, empty in all 8:
   check if spam filtering could use it), age, numMembers. So key level
   = Blizzard text search only. **Done v0.3.4-alpha1:** pane starts
   below Blizzard's search row (the player types there, not per filter);
   Blizzard's refresh searches; a mint line shows the cooldown.
3b. **Blizzard's Filter button (player, 2026-09-29). Built v0.3.5-alpha1:
   our filter drives it (third option below). Tooltip line / pane note
   still worth a try if players get confused.** it stays visible
   above the pane (the search row can't be covered cleanly). Its settings
   narrow the server's search before our filters run, so the player
   should understand how the two relate. Try in game, compare:
   - a line added to its tooltip (HookScript, never SetScript);
   - a quiet note in the pane when Blizzard's filter is narrowing
     results (`C_LFGList.GetAdvancedFilter()`), naming what it limits;
   - one source of truth: our filter's dungeons / needs (tank, healer,
     Bloodlust, battle rez) / score written into Blizzard's advanced
     filter (`C_LFGList.SaveAdvancedFilter`), so both agree and the
     server narrows too. **Spike 2026-09-29: works.**
     `SaveAdvancedFilter` from our code saved (read back 1234), restore
     ok, nothing blocked. Fields: activities (activity group IDs),
     difficultyNormal/Heroic/Mythic/MythicPlus, generalPlaystyle1-4,
     needsTank/Healer/Damage, needsMyClass, hasTank/hasHealer,
     minimumRating. The search returns at most 100 results, so narrowing
     on the server matters: with local-only filters a busy hour can push
     matching groups past the cap. Maps: dungeons -> activities; room for
     my role -> needs<my role>; score floor / at least mine ->
     minimumRating. No server field for Bloodlust / battle rez (stay
     local).
3c. **Filter picker (player, 2026-09-29, revisit):** saved filters may
   work better as a drop-down selector than as tabs across the top bar
   (room, many filters, long names). Decide with the player; keep
   right-click/setup and "+ new" reachable either way.
4. **Phase 4**: new mark (**built v0.4.0-alpha1; the dot works but its
   look needs another pass, player**), best-group
   sort (**parked 2026-09-29: no key level in the API**), keys that beat my best, swap a
   sign-up (opt-in), friends mark (**built v0.4.0-alpha2**), saved sign-up note. Lockout-aware raids already shipped
   (My lockout).
5. **Region filter (player, 2026-09-29; must ship before v1.0.0):** let
   players filter by the realm region of the people involved. Searching:
   a filter option on the leader's realm region (e.g. US East, US West,
   Oceanic, Brazil, Latin America; per the player's region), shown as
   toggles like dungeons, with the region in the row tooltip. Leading:
   the same idea for applicants, designed with the leader side. The game
   has no call for another realm's region: it needs realm data, either
   a bundled third-party realm library (kept with its license and
   credit) or our own realm table. Decide which before building.
   **Research 2026-10-01 (Claude; player decides):** LibRealmInfo's
   data is stale in both copies: phanx-wow (last data 2019) points to
   github.com/janekjl/LibRealmInfo (v17, last data Nov 2020, adds Classic
   realms). Both list the same 246 retail US realms, but they disagree on
   the US timezone tag for dozens of them (e.g. Laughing Skull CST vs EST,
   Blackrock PST vs MST) and the fork has typos in its Brazil rows, so
   "US East / US West" from the tags is not trustworthy (and NA realms
   share one data centre, as far as known, so it says little about
   latency). What is solid for a US player: Oceanic (12 realms), Brazil
   (5), Latin America (3), everything else North America. **Lighter
   option:** no library at all, our own 20-name table for those three
   groups (realm names are facts, no licence or credit needed), every
   other realm counted as North America. EU (split by language) would
   need a full EU table: build it only if an EU player wants it.
   To check in game before building: how `leaderName` spells realms with
   an apostrophe or space (e.g. Aman'Thul, Jubei'Thos), and that a
   same-realm leader has no realm suffix.
   Earlier leaning (2026-09-29): LibRealmInfo by Phanx (zlib;
   github.com/phanx-wow/LibRealmInfo; region, locale and US timezone tags
   PST/MST/CST/EST/AEST/BRT...). Last release Jan 2021, so realms added
   since are missing: bundle it fresh from its GitHub (not the archived
   fork's copy), add our own small override table, and log any leader
   realm it can't place so gaps get filled.
6. **Ponytail sweep** (player: Claude's call on timing): after Phase 4
   lands and before v1.0.0, in a session with plenty of usage; whole
   codebase, one pass, then a test build.
   **Accessibility pass alongside it (player, 2026-10-01, parked):** WCAG 2.2
   for both PickupGroup and StockClerk together (they share the style
   language, so a change like grey rest rings lands in both). Start from
   the baseline under "Visibility" above.
7. Later: teleport button (needs a party to test), filter sharing,
   leading (on hold), final name before 1.0.

Known limits (by design, noted to the player): boss rules apply to every
difficulty in a filter (amber hint shown; one difficulty per filter);
past-season raids are a named list in Groups.lua (update each season);
an open sign-up at /reload stays "pending" in the application log.

Session setup (keeps usage down):
- Repo: `TheWolfIsLoose/PickupGroup` (public); attach with add_repo
  (push access) and clone.
- Install: write changed files straight into
  `Interface\AddOns\PickupGroup` in the player's `_retail_` folder
  through the device bridge. A new file in the TOC needs a game
  restart, not a `/reload`.
  Stage every build under a fresh folder (`/mnt/user-data/outputs/pg-<version>/`):
  re-committing from a path used before can write a stale copy (it did
  for 0.1.1 and 0.2.0-alpha2). After a commit, re-stage the installed
  files and compare sizes or checksums with the repo.
- Logs: after a `/reload`, read
  `WTF\Account\SAVAGEFEARLESS\SavedVariables\PickupGroup.lua`.
- Check before every build: `lua5.1 Dev/check.lua *.lua UI/*.lua` (syntax, plus a
  local used above its definition: it passed syntax and broke in game once).
  No package manager reaches Lua here: `git clone --depth 1 -b v5.1
  https://github.com/lua/lua`, then `gcc -O2 -o lua51 -DLUA_USE_POSIX
  $(ls *.c | grep -v ltests.c) -lm`.
- Style: StockClerk's `Dev/STYLE.md` (player's AddOns folder or the
  StockClerk repo). StockClerk is the player's own addon; its code and
  patterns may be reused freely.
- Branches: work on `dev` (push freely); merge to `main` only to
  release (any new CHANGELOG version on `main` publishes). The clone is
  shallow single-branch: add `+refs/heads/dev:refs/remotes/origin/dev`
  to `remote.origin.fetch` so `origin/dev` exists locally.
- Push: `git push origin main` (a first attempt can drop; retry once).
  Tag pushes are refused by the session proxy; don't loop on them.

### Design (set 2026-09-28)

The design canvas "Pickup dock mockup" in the player's artifacts is the
visual reference: page "Searching" is current; "Explored" and
"Leading" are set aside. Its names predate this repo; the Glossary
wins.

**Decided (player):**
- **Searching comes first.** Leading (listing a group, reviewing
  applicants) is on hold: whether PickupGroup has a role there needs
  its own scrutiny.
- **Placement**: the pane sits inside the Group Finder's footprint,
  over Blizzard's results area (about 363 x 386 at 100%), shown only on
  Premade Groups > Dungeons and Raids. It is our own opaque frame laid
  over Blizzard's list and search row; Blizzard's frames are never
  hidden, moved or written. Raider.IO's profile stays at the Group
  Finder's edge. Sized for a 4K player: small and tight.
- **"Use Blizzard LFG instead"** (Options) takes the pane away; a small
  PickupGroup button in Blizzard's search row brings it back.
  Remembered per account.
- **Own table**, not marks on Blizzard's list: PickupGroup controls how
  groups are shown.
- **Filters are the core.** Tabs across the top bar (e.g. Weekly keys,
  Push keys, Raid; + adds one). Each is a full set of search
  parameters, and any typed search text lives in its setup, so
  PickupGroup owns the search entry.
  - Keys filters: dungeons, room for my role (party fit), needs
    Bloodlust, needs battle rez, leader score floor.
  - Raid filters: difficulty, each boss alive / dead / either, more as
    needed.
- **Refresh** button in the top bar. An automatic timed refresh isn't
  possible (a search must come from a click or keypress), so Refresh
  counts down until the client will take the next search; a keybind
  also searches.
- **Columns**: Name, Instance (Dungeon / Raid, short code; full name in
  the tooltip), Comp, Leader score, action button (Apply; time left and
  Cancel on a sign-up; "-" when you can't apply, reason in its tooltip).
- **Comp, dungeons**: five square tiles, always tank, healer, three
  damage. A filled tile is the member's spec icon; an empty tile shows
  the missing role, mint when it is the player's role.
- **Comp, raids**: WoW gives counts by role only, so raids show counts
  with role glyphs; breakdown in the tooltip.
- **Sign-ups** are pinned above the results: name, instance, time left
  on the action button (hover: Cancel). No status bar, no footer;
  feedback goes in the action button's tooltip.
- **Sidecar** for filter setup and options (Filter / Options tabs),
  attached to the Group Finder's right edge. See Open.
- **Look**: StockClerk's visual language (`Dev/STYLE.md` there), mint
  accent shared with StockClerk.
- **Teleport** button, standalone, only while the party is full (5/5)
  for that dungeon, until inside.
- **Debug log** on by default until v1.0.0 (activity, detail, trace,
  errors; a `/pug log` view and clear).

**Features (Decided):**
- **Application log**: every sign-up, per character and per account:
  instance, key level, and how it ended (timed, depleted, declined,
  filled; "group full" and "group delisted" kept apart; withdrawn and
  timed out too). For historical cross-sections later; no UI in the
  first build.
- **New mark**: rows not in the previous results get a subtle mark
  (Default: a small mint dot before the name, until the next refresh).
- **Sort**: by leader score, and a "best group" order. Starting weights
  (to tune later): leader score first, then the player's possible score
  gain if the key is timed (an estimate), then a small bonus when the
  player's role is the only one missing. **Show our work publicly**: the
  sort's tooltip and the public description say exactly how it ranks.
- **Keys that beat my best**: a filter option for keys that would
  improve the player's best for that dungeon; the tooltip shows the
  player's best there.
- **Swap a sign-up** (opt-in, Options, off by default): with all five
  in use, Apply offers to replace the weakest or oldest.
- **Clean-up** (each an Options switch, on by default; a switch only
  hides or marks the row and says why in the tooltip). Aim: replace the
  player's separate spam-filter addon. Listing names are unreadable
  (Phase 1), so every rule uses readable listing data:
  - **Stale**: hide listings older than a set age (Default 3 h, editable).
  - **Looks like an advert** (dungeons only): leader has no Mythic+ score
    and the voice-chat field is filled in.
  - **Carry offered**: hide listings whose playstyle offers a carry.
  - **Blacklist** (account-wide, by leader name-realm): "Report and hide"
    in a row's menu opens Blizzard's own report dialog and blacklists
    the leader; reporting a listing through Blizzard's UI also adds the
    leader. "Hide for this session" keeps it off until /reload.
    Housekeeping: entries not seen for a year drop off.
  - **Declined groups**: see re-applying below.
  - **Show hidden**: the top bar's count shows how many rows clean-up
    hid; clicking it shows only those, to review or undo.
  Our table filters its own copy of the results; Blizzard's results
  list is never rewritten.
- **Re-applying is never blocked**: declined or withdrawn groups can be
  applied to again, with friction, and without reopening the Group
  Finder. Default: the row stays, dimmed, marked "Declined"; the
  action button reads "Reapply" and takes a second click.
- **Lockout-aware raids**: bosses the player is saved to are marked in
  the tooltip, and the boss filter reads against the lockout.
- **Click Apply** signs up at once (the note sent is whatever is in
  Blizzard's note box); **shift-click** opens Blizzard's own sign-up
  dialog to add a note (pending spike 1b).

**Cut (player):** leader success rates or any "record with this
leader"; play-history analytics (Raider.IO covers it); a per-player
"acceptance odds" cue.

**Settled 2026-09-28:**
- Sidecar attached to the Group Finder's right edge (Decided).
- Apply-as roles in the action column's header (Decided, until a case
  shows it doesn't work).
- Raid rows show the group's progress in place of leader score: bosses
  down in that listing (e.g. 3/8 H), from WoW's own listing data
  (Decided).
- **No dependencies (Decided):** PickupGroup never needs another addon.
  Information another addon provides (e.g. the leader's own raid
  progression from Raider.IO) may pass through into rows or tooltips
  when that addon is loaded: nice to have, never required.

**Blizzard's own rows, for reference** (player screenshots 2026-09-28):
three lines per group (title, activity with difficulty, playstyle in
colour); dungeons show role icons tinted by class, raids show counts per
role; roughly 5-6 groups visible. Ours is one 24 px line per group.

---

### v0.1.0 — Phase 0: foundation (done 2026-09-28)

- `PickupGroup.toc`, core namespace, saved variables `PickupGroupDB`
  with a `schema` number from day one.
- Slash `/pug` (and `/pickupgroup`): `log`, `log clear`, `debug`.
- Debug log (Default: StockClerk's `Log.lua` design: activity for
  players, detail for support, trace behind `/pug debug`).
- Syntax check tooling (`Dev/check.lua`).

### Phase 1 — spikes (done 2026-09-28)

1a. **Overlay**: our frame over the results area; Blizzard's list and
    search row untouched underneath; Sign Up, the sign-up dialog and
    invites still work; no taint in the log.
1b. **Shift-click**: can our click open Blizzard's sign-up dialog for a
    result and still have Blizzard's Sign Up go through? If not, the
    note path needs its own design.
1c. **Refresh throttle**: the shortest search interval the client
    accepts (search failures logged against time since the last
    search).

**Round 1 results (2026-09-28, from the saved log):**
- 1a: cover on and off over the search panel: nothing blocked. **Works.**
- 1b: our click opened Blizzard's sign-up dialog, Blizzard's Sign Up
  went through (none -> applied), nothing blocked. **Shift-click to add a
  note works with Blizzard's own dialog; no note-box workaround needed.**
- 1b': sign-up straight from our click (ApplyToGroup): applied, nothing
  blocked. **Click Apply works.**
- 1c: only Blizzard's refresh was used. A burst of refreshes fails with
  "throttled"; 3 s after a throttled attempt still failed; 7.6 s and
  10.1 s later went through. The window is somewhere between ~4 and ~8 s
  after the last search. Every search fires the results event twice.

**Round 2 results (2026-09-28):** our own Search button, searching through
Blizzard's search function from our click: works, nothing blocked. Gaps
of 4.2, 2.6, 3.3, 3.2, 4.3, 3.3 s all went through; 1.6 s was throttled.
**Refresh: allow a search about 3 s after the last one** (Default:
Refresh counts down 3 s; after a "throttled" failure, wait the full 3 s
again, since round 1 saw a retry 3 s after a failure refused too). The
20 s the player expected is not needed.

**Phase 1 done**: the harness (`Dev/Spike.lua`) is deleted.
- **Found**: a listing's name comes back as a protected string (it shows
  in the log as `|Kv1|k`): it can be displayed but not read. So a spam
  filter can't match words in titles, and "search text" can only be
  Blizzard's server-side search text, not our own matching. Design
  impact on Clean-up: spam filtering has to use what is readable
  (leader, activity, members, age...), to be checked.

### Phase 2 — the pane (done: v0.2.0, 2026-09-28)

Pane over the results area, top bar (tabs, Refresh, sidecar button),
table (columns and Comp above), action button (Apply / Cancel),
pinned sign-ups, row tooltip, "Use Blizzard LFG instead" and the way
back, application log (data only). (Teleport moved to Later.)

### Phase 3 — filters and the sidecar (done: v0.3.0, 2026-09-28)

Plan (2026-09-28): alpha1 = saved filters as tabs + the sidecar's Filter
tab; alpha2 = Options tab ("Use Blizzard LFG instead", clean-up switches,
show hidden, blacklist); alpha3 = per-boss raid rules, search text.
- Filters are account-wide, per category (keys / raid); the active one is
  remembered per category. Shipped: Weekly keys (room for my role), Push
  keys (room for my role, leader score at least mine), Raid (room).
- Keys options: dungeons (this season's, from the game), room for my
  role, needs Bloodlust (no Shaman/Mage/Hunter/Evoker in the group),
  needs battle rez (no Druid/Death Knight/Warlock/Paladin), leader score
  floor, leader at least my score. Raid: difficulty, bosses down at most,
  room, each boss alive / dead / either (alpha2). Edits apply as you make
  them (no Save step): the rules run on results already in hand and never
  send a search. **Rule for search text (alpha3):** it's Blizzard's
  server-side search, so it only takes effect on Enter or Refresh, never
  on each keystroke, and it waits out the Refresh countdown (player). Delete keeps at
  least one filter per category.
- Past-season raids still listed under the current expansion are left
  out (named list in Groups.lua; March on Quel'Danas, S1; Sporefall, player 2026-10-01). Update it each
  season.
- Hint when a raid filter mixes difficulties with boss rules (results
  can't be accurate across lockouts); one difficulty per filter.
- The sidecar hangs off the Group Finder's right edge. **Changed
  2026-10-01 (player):** Raider.IO's profile panel moves to the sidecar's
  right edge while it's open (its anchor frame
  `RaiderIO_ProfileTooltipAnchor` is re-pointed from PVEFrame to the
  sidecar, hooked on its SetPoint since Raider.IO re-places it on updates;
  a user-placed panel is left alone).

Filter setup (keys and raid), save / delete / new tab, Options tab,
clean-up switches, re-apply friction, blacklist entry.

### Phase 4 — the extras

New mark, best-group sort, keys that beat my best, swap a sign-up
(opt-in), lockout-aware raids.

**Friends mark (player, 2026-09-29):** show which listed groups have
people the player knows. Today the count exists (`row.friends` in
Groups.lua; split it back into friends vs guildmates) but only appears in
the tooltip. Blizzard's cue is the group name's colour: Battle.net blue
for friends, guild-chat green for guildmates. PickupGroup doesn't have to
colour names, but the cue must fit the style guide: colour is never the
only cue, marks are drawn (no font glyphs), mint is taken (new, my role),
detail lives in the tooltip.
Default: one small drawn "people" mark at the end of the name (the new
dot keeps the leading slot), tinted with the colours players already know:
blue for friends, green for guildmates. The shape says "someone you
know"; the tooltip names them and says friend or guild
(`C_LFGList.GetSearchResultFriends`). Open: mixed groups (one mark, which
colour wins, or two marks); pinned sign-ups too; whether a
Blizzard-matching name colour is an Options toggle.

**Saved sign-up note (player, 2026-09-29): blocked by the game.** Spike
2026-09-29: Blizzard's sign-up note box refuses `SetText` from addons
("Call is illegal when disabled by security settings"), like the search
box, and C_LFGList has no call to set a note (ApplyToGroup takes roles
only; ClearApplicationTextFields exists). A note can only be typed by the
player. Parked unless the player wants a copy-ready helper (their saved
note selected in a box for Ctrl+C, then Ctrl+V into Blizzard's).

### v1.0.0 — first release-worthy build

- **Must have:** the region filter (see Next session, item 5).
- **Open**: final name.
- **Decided:** debug (trace) logging defaults to off.
- **Open:** whether to publish, and where.

### Later (unscheduled)

- **Teleport button** (moved out of Phase 2 by the player, 2026-09-28): a
  flourish that costs group testing time; build it when friends can help
  test (party fills to 5/5, button shows, casts the dungeon's teleport,
  hides inside). Everything it needs is already read (activity, members).

- Share a filter as an import/export string (parked by the player).
- Leading: listing a group and reviewing applicants, if it earns a
  place. A quick-create for keystone listings is an idea to design
  from scratch then.
- Release CI (StockClerk's workflow) once publishing is decided.
