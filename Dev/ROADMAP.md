# PickupGroup — Roadmap

Forward plan and design spec. Dev-only (`Dev/` never ships). Shipped
work moves to `Dev/HISTORY.md`; the player-facing summary goes in
`CHANGELOG.md` when a version is cut (see `Dev/RELEASING.md`).

Status key: **Decided**, **Default** (recommended; change it if you
disagree), **Open** (needs an answer before build).

**PickupGroup is a working name** (pinned 2026-09-28): it may change
before v1.0.0. Keep the name in as few places as possible (TOC title,
slash commands, saved-variables name, the header mark) so a rename is
cheap.

---

## Next session: start here

**State, 2026-09-29 00:05 ET: v0.3.3 installed and confirmed in game (log
clean: no errors, nothing blocked).** Phases 0-3 done. Read "What
PickupGroup is", "Originality rules" and "Design" first; HISTORY.md has
every build's detail.

Testing method (player's preference): the player tests in game,
`/reload`s and says "done"; Claude reads the log from the saved variables
file (Session setup), never asks for a paste. Screenshots for layout.
Iterate in small alphas: one fix or feature per build, installed and
verified (checksums) each time.

Next, in order:
1. **Party-aware room** (player): "Room for my role" must mean "room for
   my group" in a party: the group's open seats fit every party member's
   assigned role (UnitGroupRolesAssigned on party units; the leader's
   sign-up carries the party) and members + party <= 5. The mint ring on
   empty seats follows the same rule. Needs a party test (friends).
2. **Untested in game**: the row right-click menu (Report and hide,
   Blacklist, Hide until reload) and auto-blacklist on Blizzard's report
   form. Check the log for a blocked action from LFGList_ReportListing.
3. **Search text** (last Phase 3 item): Blizzard's server-side search;
   takes effect only on Enter or Refresh, waits out the countdown.
4. **Phase 4**: new mark (rows new since the last refresh), best-group
   sort (show our work in its tooltip), keys that beat my best, swap a
   sign-up (opt-in). Lockout-aware raids already shipped (My lockout).
5. **Region filter (player, 2026-09-29; must ship before v1.0.0):** let
   players filter by the realm region of the people involved. Searching:
   a filter option on the leader's realm region (e.g. US East, US West,
   Oceanic, Brazil, Latin America; per the player's region), shown as
   toggles like dungeons, with the region in the row tooltip. Leading:
   the same idea for applicants, designed with the leader side. The game
   has no call for another realm's region: it needs realm data, either
   a bundled third-party realm library (kept with its license and
   credit) or our own realm table. Decide which before building.
6. Later: teleport button (needs a party to test), filter sharing,
   leading (on hold), final name before 1.0.

Known limits (by design, noted to the player): boss rules apply to every
difficulty in a filter (amber hint shown; one difficulty per filter);
past-season raids are a named list in Groups.lua (update each season);
an open sign-up at /reload stays "pending" in the application log.

Session setup (keeps usage down):
- Repo: `TheWolfIsLoose/PickupGroup` (private); attach with add_repo
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
- Syntax check before every build: `lua5.1 Dev/check.lua *.lua UI/*.lua`.
  No package manager reaches Lua here: `git clone --depth 1 -b v5.1
  https://github.com/lua/lua`, then `gcc -O2 -o lua51 -DLUA_USE_POSIX
  $(ls *.c | grep -v ltests.c) -lm`.
- Style: StockClerk's `Dev/STYLE.md` (player's AddOns folder or the
  StockClerk repo). StockClerk is the player's own addon; its code and
  patterns may be reused freely.
- Push: `git push origin main` (a first attempt can drop; retry once).
  Tag pushes are refused by the session proxy; don't loop on them.

---

## What PickupGroup is

A premade-groups tool that lives inside Blizzard's Group Finder. It
finds groups to join: saved search filters, a compact results table,
and signing up. Scope rule (player): an all-in-one LFG tool that
replaces one-off addons, but every feature earns its space and nothing
is shown that the player can't use. Blizzard's own UI stays as
untouched as possible: leaner, and less prone to break.

## Originality rules (Decided, 2026-09-28)

PickupGroup is an original design and an original codebase.
- No code, assets or text from any other addon. Code is written from
  this spec and Blizzard's API; StockClerk (the player's own) is the
  only source code may be reused from.
- Use Blizzard's API as documented; which API calls exist is common
  ground, how we build on them is ours.
- Our own names for our own parts (Glossary below). Don't borrow
  another addon's terms for its features.
- Assets: drawn glyphs in StockClerk's style, fonts per StockClerk
  (Expressway via LibSharedMedia, else a bundled open-license face).
  Third-party libraries keep their own licenses and credits.
- No mention of other addons in shipped code or text, except where
  PickupGroup must detect one for compatibility.

## Glossary

- **Pane**: PickupGroup's main frame, laid over the Group Finder's
  results area.
- **Filter**: a saved, named set of search parameters, shown as a
  **tab** across the pane's top bar.
- **Sidecar**: the panel attached to the Group Finder's right edge for
  filter setup and options.
- **Comp**: the group's make-up; **tiles** for dungeons, **counts** for
  raids.
- **Sign-up**: an application the player has out; pinned rows above
  the results.
- **Action button**: the one button at the end of each row.
- **Clean-up**: the switches that hide or mark rows (spam, blacklist,
  declined).
- **Application log**: the saved record of every sign-up and how it
  ended.
- **New mark**: the sign that a row wasn't in the previous results.

---

## Design (set 2026-09-28)

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

## v0.1.0 — Phase 0: foundation (done 2026-09-28)

- `PickupGroup.toc`, core namespace, saved variables `PickupGroupDB`
  with a `schema` number from day one.
- Slash `/pug` (and `/pickupgroup`): `log`, `log clear`, `debug`.
- Debug log (Default: StockClerk's `Log.lua` design: activity for
  players, detail for support, trace behind `/pug debug`).
- Syntax check tooling (`Dev/check.lua`).

## Phase 1 — spikes (done 2026-09-28)

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

## Phase 2 — the pane (done: v0.2.0, 2026-09-28)

Pane over the results area, top bar (tabs, Refresh, sidecar button),
table (columns and Comp above), action button (Apply / Cancel),
pinned sign-ups, row tooltip, "Use Blizzard LFG instead" and the way
back, application log (data only). (Teleport moved to Later.)

## Phase 3 — filters and the sidecar (done: v0.3.0, 2026-09-28)

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
  out (named list in Groups.lua; March on Quel'Danas, S1). Update it each
  season.
- Hint when a raid filter mixes difficulties with boss rules (results
  can't be accurate across lockouts); one difficulty per filter.
- The sidecar hangs off the Group Finder's right edge and covers
  Raider.IO's panel while open (Raider.IO's frame is never moved).

Filter setup (keys and raid), save / delete / new tab, Options tab,
clean-up switches, re-apply friction, blacklist entry.

## Phase 4 — the extras

New mark, best-group sort, keys that beat my best, swap a sign-up
(opt-in), lockout-aware raids.

## v1.0.0 — first release-worthy build

- **Must have:** the region filter (see Next session, item 5).
- **Open**: final name.
- **Decided:** debug (trace) logging defaults to off.
- **Open:** whether to publish, and where.

## Later (unscheduled)

- **Teleport button** (moved out of Phase 2 by the player, 2026-09-28): a
  flourish that costs group testing time; build it when friends can help
  test (party fills to 5/5, button shows, casts the dungeon's teleport,
  hides inside). Everything it needs is already read (activity, members).

- Share a filter as an import/export string (parked by the player).
- Leading: listing a group and reviewing applicants, if it earns a
  place. A quick-create for keystone listings is an idea to design
  from scratch then.
- Release CI (StockClerk's workflow) once publishing is decided.
