# PickupGroup — Roadmap

Forward plan and design spec. Dev-only (`Dev/` never ships). Shipped
work moves to `Dev/HISTORY.md` (which also holds the full roadmap as it
stood before the 2026-10-03 clean-up); the player-facing summary goes in
`CHANGELOG.md` when a version is cut (see `Dev/RELEASING.md`).

Status key: **Decided**, **Default** (recommended; change it if you
disagree), **Open** (needs an answer before build).

**PickupGroup is a working name** (pinned 2026-09-28): it may change
before v1.0.0. Keep the name in as few places as possible (TOC title,
slash commands, saved-variables name, the header mark) so a rename is
cheap.

---

## Next session: start here

**2026-10-23: v1.2.2 released** (new groups get a white left edge instead of a blue name). v1.2.1 the same day (green sign-ups, motion, failed sign-up record fix); v1.2.0 2026-10-22 (suite style pass). Notes in `Dev/HISTORY.md`. Nothing unreleased on `dev` (only test round files).

Open, in rough priority:
1. **Group tooltip placement (the GUI overhaul, parked 2026-10-19; the player has more ideas that need real concepting).** The tooltip opens to the row's right and covers the sidecar and the score panel. Ideas: open it to the Group Finder's left (over the category buttons), a modifier key to expand member lists, our own detail panel in a fixed spot. Not wanted: moving the score panel to ride beside the tooltip. Nothing decided. (A listing carries no key level, so no filter by the key's own level.)
2. **Confirm passively:** a sign-up the game refuses at once keeps its leader and dungeon (shipped v1.2.1; check the next "failed" entry in the log). Bailed (vote to abandon) not yet seen.
3. **Later:** a read-only member view of a forming group (what it still needs, who's applying; today PickupGroup steps aside while `C_LFGList.HasActiveEntryInfo()`); choosing the fill chime from SharedMedia; see Later below.
4. **Housekeeping:** retake the CurseForge gallery shots (they show the old mint look); paste the updated `Dev/CURSEFORGE.md`.

Dropped 2026-10-22: the raid chime (no merit).

## What PickupGroup is

A premade-groups tool that lives inside Blizzard's Group Finder:
enhancements on top of Blizzard's search, not a replacement (Decided
2026-10-01). It passes its filter through to Blizzard's own filter, shows
what Blizzard gives in a compact table, and adds what Blizzard lacks:
clean-up, sign-up notes, friends first, an application log, and a leader
view for reviewing applicants. Scope rule (player): an all-in-one LFG tool
that replaces one-off addons, but every feature earns its space and
nothing is shown that the player can't use. Blizzard's own UI stays as
untouched as possible.

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
  (Expressway via LibSharedMedia, else the bundled Barlow Semi Condensed).
- No mention of other addons in shipped code or text, except where
  PickupGroup must detect one for compatibility (Raider.IO's panel and
  progress, EllesmereUI's note options).

## Glossary

- **Pane**: the main frame, laid over the Group Finder's results area,
  below Blizzard's search row.
- **Filter**: the search rules for a content type (one for keys, one for
  raids), summarised in the pane's top bar.
- **Sidecar**: the panel on the Group Finder's right edge: Filter, Notes,
  Options.
- **Comp**: the group's make-up; **tiles** for dungeons, **counts** for
  raids.
- **Sign-up**: an application the player has out; pinned rows above the
  results.
- **Action button**: the one button at the end of each row.
- **Clean-up**: the switches that hide rows (stale, advert, carry,
  blacklist), each with its reason in the tooltip.
- **Application log**: the saved record of every sign-up and how it
  ended (Options > Sign-up history).
- **Row states**: white left edge (plus one shimmer) = new to your list since the last search (a filter change marks only newly listed groups); never a blue name, which reads as Blizzard's friend blue. Left edge on sign-ups = how it's going: green waiting / invited, yellow declined / failed (or that leader declined you this session), grey other endings. Leaver mark on members who left groups early lately (search and leader view).
- **Leader view**: our frame over Blizzard's applicant list while the
  player leads a key or raid listing.
- **Target comp**: the raid leader's wanted tanks / healers / damage.

---

## Design (current)

**Searching (Decided):**
- Pane over Blizzard's results on Premade Groups > Dungeons and Raids -
  current; Blizzard's search row (search text, refresh, Filter button)
  stays visible above it. A 1px white line across the top shrinks over the
  ~3 s search cooldown.
- One filter per content type. Keys: dungeons, room for my role
  (party-aware), has Bloodlust, has battle rez, no other of my class,
  leader score floor / at least mine, leader's realm region. Raids: realm
  region, bosses that must be alive, My lockout (toggles).
- Our keys filter drives Blizzard's advanced filter (server-side
  narrowing, 100-result cap); Bloodlust / battle rez / region stay local.
  "Use Blizzard's group list instead" hands Blizzard's filter back clear.
- Columns: Name (state colour, friend / guild marks), Dungeon / Raid (+
  difficulty letter), Comp, Score / Bosses, action button. Friends and
  guildmates' groups always show (Blizzard's search still applies) and
  sort first.
- Apply: click = sign up at once; shift-click = Blizzard's sign-up window
  with up to 5 saved notes under it to copy (the game won't let an addon
  fill the note). Reapply after an ending takes a second click. Swap
  (opt-in) withdraws the oldest when all five sign-ups are out.
- Clean-up replaces a separate spam-filter addon: stale, advert (no score
  + voice filled in), carry, blacklist (report = blacklist), hide until
  reload; "N hidden" in the top bar shows what it hid.
- Realm regions: Oceanic, Brazil and Latin America realms by name (our own
  table), everything else North America; other game regions never appear.
- Teleport button while the party is 5/5 for a known dungeon, not inside,
  and the spell isn't on cooldown.

**Leading (Decided 2026-10-02):** cues point at what an applicant adds,
never at who they are: **no class or spec filters** (blind spots, toxic
behaviour). Nothing is hidden; non-fits are dimmed with the reason in the
tooltip.
- Keys: needs bar (seats, Bloodlust, battle rez), rows per member (spec,
  name, ilvl, score, best run in the listed dungeon), "Lust" / "Rez" adds,
  blue row edge = fills an open seat from 3 in the group.
- Raids (first cut, 0.7.1-alpha3): target comp per character (presets 10 /
  20 / 25 / 30 or typed T / H / D); needs bar against it (seats, Bloodlust,
  up to 2 battle rez); Prog column = the applicant's best Raider.IO
  progress in the listed raid, any difficulty ("6/8 H"; "-" without
  Raider.IO: optional, never required); adds = raid buffs the group lacks
  (Int, Stam, AP, Vers, Skyfury, Bronze, Brand, Touch, Mark), Lust, Rez.

**Leading filter (Decided 2026-10-04):** one per kind (`lead_keys`,
`lead_raid` in `db.filters`), set up in the sidecar from the slider icon in
the leader view's top bar: applicant's realm region, score floor (keys) /
item level floor (raids). It only dims, with the reason on hover. The
leader view no longer borrows the search filters' regions.

**Friends bundle (player, 2026-10-04): tested organically, over time.**
Hard to stage on demand, so these stay off the checklist and get checked
when the situation happens: friend / guild marks (person / banner) and
coloured names, friends first in results, tooltip names
(GetSearchResultFriends), the friend who couldn't see the player's listing
(his saved file), the tester's missing friend cue. Report any of them when
seen; read the log then.

**Scrolling (Decided 2026-10-04):** no scroll bars in the pane or the leader
view: the wheel scrolls, and a "more below" chevron (Kit.More) pulses three
times then holds while rows are below the fold. Log and history windows keep
Blizzard's scroll bars.

**Constraints (Decided):** no dependencies on other addons (pass-through
only); no internet data; listing names and notes are protected (shown,
never read); search text and the sign-up note can't be set by an addon.

**Cut (player):** leader success rates / play history; acceptance odds;
"best group" sort (no key level in the API); "keys that beat my best"
(same reason); multiple filters per kind and a filter picker.

**Accessibility (WCAG 2.2, project doc
`claude/style-guide-accessibility-addendum.md`):** grey rest rings on
controls (3.3:1); toggles show "on" with a bar as well as colour; friend /
guild marks differ in shape; untimed keys carry an x; checkboxes and
toggles are 24px targets on 24px rows; header role buttons 24px apart;
18px action buttons in 24px rows pass by spacing. Accepted exception
(player, 2026-10-04): header role buttons 17px apart (24 looked too far).
Still open: role icon off-state contrast (atlas art, unmeasured).

**Known limits:** this season's raids come from the Adventure Guide's newest tier
(no list to keep up); the raid buff table is per class (check each
season); an open sign-up at /reload is re-attached by leader + activity.

---

## v1.0.0 — released 2026-10-04

- Name: PickupGroup (decided 2026-10-04).
- Debug (trace) logging defaults to off (schema 6).
- StockClerk gets its own ponytail + WCAG session (same style language:
  grey rest rings, toggle bar).

## Later (unscheduled)

- Filter help window (player idea, 2026-10-22, optional): an Options button opening a window with the full rules and examples (boss boxes ANDed, My lockout's hide/sort, skip groups). Not built: the one-line tooltips cover it for now; revisit if players ask how filtering works.

- Share a filter as an import/export string (parked by the player).
- Quick-create for keystone listings, designed from scratch.

---

## Working method

**Testing (player's preference):** the player tests in game, `/reload`s
and says "done"; Claude reads the log and checklist ticks from the saved
variables, never asks for a paste. Screenshots for layout. Small alphas,
installed and verified each time. The tester plays
casually: his reports are leads; spike issues ourselves.

**In-game test list:** `Dev/DevChecklist/` is a dev-only addon installed
as `Interface\AddOns\DevChecklist` (never shipped). Each round, rewrite
`Rounds/PickupGroup.lua` (one round file per addon, so rounds never
overwrite each other; round name; items { area, what to do / expect, what
to send }) grouped by area, and install it. Clear a round only once it's
all ticked. Ticks are saved per item text in
`WTF\Account\<account>\SavedVariables\DevChecklist.lua`.

**Session setup:**
- Repo: `TheWolfIsLoose/PickupGroup` (public). Work on `dev`; merge to
  `main` only to release (a new CHANGELOG version on `main` publishes).
- Install: copy changed files into `Interface\AddOns\PickupGroup` in the
  player's `_retail_` folder through the device bridge; a new file in the
  TOC needs a game restart. Stage each build under a fresh folder
  (`/mnt/user-data/outputs/pg-<version>/`) and compare checksums after.
- Logs: `WTF\Account\<account>\SavedVariables\PickupGroup.lua`.
- Check before every build: `lua5.1 Dev/check.lua *.lua UI/*.lua`.
  No package manager has Lua here: `git clone --depth 1 -b v5.1
  https://github.com/lua/lua`, then `gcc -O2 -DLUA_USE_POSIX -o
  /usr/local/bin/lua5.1 $(ls *.c | grep -v 'luac.c\|print.c') -lm`.
- Style: StockClerk's `Dev/STYLE.md`; StockClerk code may be reused.
- Push: `git push origin dev` / `main` (retry once if it drops); tag
  pushes are refused by the session proxy, CI tags instead.
