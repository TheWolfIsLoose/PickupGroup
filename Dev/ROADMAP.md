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

2026-09-28: Phase 0 built as v0.1.0-alpha1 and installed (awaiting the
player's first load: `/pug`, `/pug log`, `/pug debug`). Read "What
PickupGroup is", "Originality rules" and "Design" before anything else.

1. **Phase 0**: confirm the alpha1 load in game (log shows "installed",
   no errors), then cut v0.1.0.
2. **Phase 1**: three in-game spikes, each a throwaway test read back
   from the debug log.
3. Settle the **Open** items in Design with the player before Phase 2.

Session setup (keeps usage down):
- Repo: `TheWolfIsLoose/PickupGroup` (private); attach with add_repo
  (push access) and clone.
- Install: write changed files straight into
  `Interface\AddOns\PickupGroup` in the player's `_retail_` folder
  through the device bridge. A new file in the TOC needs a game
  restart, not a `/reload`.
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
- **Sort**: by leader score, and a "best group" order that weighs
  leader score, the player's possible score gain if the key is timed
  (an estimate), and more. Weights **Open**.
- **Keys that beat my best**: a filter option for keys that would
  improve the player's best for that dungeon; the tooltip shows the
  player's best there.
- **Swap a sign-up** (opt-in, Options, off by default): with all five
  in use, Apply offers to replace the weakest or oldest.
- **Clean-up** (each an Options switch, on by default): spam and boost
  filter, blacklist, declined groups. A switch only hides or marks the
  row and says why in the tooltip.
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

**Open:**
- Sidecar attached to the Group Finder vs filter setup inside the pane
  (player leans sidecar).
- "Best group" sort weights.
- Raid rows' score column (leader score means little for raids; item
  level?).
- Apply-as roles: Default in the action column's header.

---

## v0.1.0 — Phase 0: foundation (built as v0.1.0-alpha1, 2026-09-28)

- `PickupGroup.toc`, core namespace, saved variables `PickupGroupDB`
  with a `schema` number from day one.
- Slash `/pug` (and `/pickupgroup`): `log`, `log clear`, `debug`.
- Debug log (Default: StockClerk's `Log.lua` design: activity for
  players, detail for support, trace behind `/pug debug`).
- Syntax check tooling (`Dev/check.lua`).

## Phase 1 — spikes (throwaway, in game)

1a. **Overlay**: our frame over the results area; Blizzard's list and
    search row untouched underneath; Sign Up, the sign-up dialog and
    invites still work; no taint in the log.
1b. **Shift-click**: can our click open Blizzard's sign-up dialog for a
    result and still have Blizzard's Sign Up go through? If not, the
    note path needs its own design.
1c. **Refresh throttle**: the shortest search interval the client
    accepts (search failures logged against time since the last
    search).

## Phase 2 — the pane (first playable)

Pane over the results area, top bar (tabs, Refresh, sidecar button),
table (columns and Comp above), action button (Apply / Cancel),
pinned sign-ups, row tooltip, "Use Blizzard LFG instead" and the way
back, teleport button, application log (data only).

## Phase 3 — filters and the sidecar

Filter setup (keys and raid), save / delete / new tab, Options tab,
clean-up switches, re-apply friction, blacklist entry.

## Phase 4 — the extras

New mark, best-group sort, keys that beat my best, swap a sign-up
(opt-in), lockout-aware raids.

## v1.0.0 — first release-worthy build

- **Open**: final name.
- **Decided:** debug (trace) logging defaults to off.
- **Open:** whether to publish, and where.

## Later (unscheduled)

- Share a filter as an import/export string (parked by the player).
- Leading: listing a group and reviewing applicants, if it earns a
  place. A quick-create for keystone listings is an idea to design
  from scratch then.
- Release CI (StockClerk's workflow) once publishing is decided.
