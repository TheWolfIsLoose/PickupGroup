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

**Context (player, 2026-10-05): the member's view of a forming group.** When the player is in a listed group but isn't the leader, Blizzard shows the listing header (key, dungeon, filled role icons) over the applicant list, grayed out under "Your group is currently forming." Members see each applicant's name (class color), role, item level and rating, but can't act on them. PickupGroup steps aside here today (`Eligible()` is false while `C_LFGList.HasActiveEntryInfo()`), and the leader view only shows for the leader. Possible later: a read-only member view (what the group still needs, who's applying), no actions.

**v1.0.0 released 2026-10-04.** Still open after 1.0:
- CurseForge: paste `Dev/CURSEFORGE.md`, upload `.assets/logo.png` and the six gallery shots (screenshots are in the repo, 2026-10-04).
- Organic checks: fill chime, Bailed (vote to abandon), teleport party check.
- StockClerk's WCAG + ponytail session; WoW: Forever compatibility check for all three addons.

**Fill chime (player, 2026-10-04): 0.9.0-alpha11 on dev.** A sign-up's
dungeon party reaching 5/5 plays The Cyclist (bundled, no SharedMedia
hook); Options toggle, on by default. **Later:** choosing the sound from
SharedMedia (a novel feature, not now).

**Raid chime (Open):** a joiner has no "full" to hear: raid listings carry
no target size and leaders stay listed past it. The one real signal is
the leader's own target comp (raid leader view): chime the leader (and
assistants?) when the raid's size reaches the target total. Player's call.

**Leader mark (player, 2026-10-04, settled):** searching, the leader's seat
gets a 0.7 grey ring one pixel outside its black ring (crown and gold tried:
gold blended into warm spec icons); the tooltip's leader line has Blizzard's
crown and the class colour. Released in **v0.8.1** (2026-10-04).

**v0.8.0 (stable) released 2026-10-04** with everything below.

**2026-10-04 (round 20, player): all pass** (leading filters dim by score /
ilvl / realm, short needs line, sidecar closes per side, role spacing, the
"more below" chevron in both lists). Left: the teleport party check
(organic). dev at 0.7.1-alpha6 is release-ready when the player calls it.

**2026-10-04 (round 19, player): all non-friend items pass**: raid leader
view works (Prog 4/8 H from Raider.IO, Skyfury / Lust / Rez / Brand adds),
targets save, sidecar fits after the 24px spacing. Calls: role buttons back
to 17px apart (24 was too far); leading gets its own filter (below); every
friend / guild feature moves to the Friends bundle (below). alpha5 builds
these; round 20.

**State, 2026-10-03 night: 0.7.1-alpha3 on dev, installed.** Since v0.7.0:
- alpha1: group tooltip names friends / guildmates (GetSearchResultFriends).
- alpha2: teleport button hides while its spell is on cooldown.
- alpha3: **raid leader view** (first cut), the **ponytail sweep**, the
  **WCAG 2.2 pass** and this roadmap clean-up (the 1.0 bundle; the player
  asked for it ahead of a 1.0 call). DevChecklist round 19 is installed.

**Next session, in order:**
1. Read the saved log + DevChecklist ticks (stage `PickupGroup.lua` and
   `DevChecklist.lua` from SavedVariables; never ask for a paste).
2. Round 19 results: raid leader view (needs a raid listing with
   applicants), the WCAG changes (layout of the sidecar's Options after
   24px spacing), and round 18's carried items (friend names in the
   tooltip, teleport on cooldown, the friend who couldn't see the
   player's listing).
3. Raid leader view, second cut from the player's feedback. Open: whether
   the raid "fills a seat" edge from half the target comp is right; whether
   raids want a region dim (the raid filter has regions only once the
   player sets them); Raider.IO's raid name match (trace "no Raider.IO
   match for" if names differ).
4. v1.0.0 items below.

---

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
- **New mark**: the dot on a row that wasn't in the previous results.
- **Leader view**: our frame over Blizzard's applicant list while the
  player leads a key or raid listing.
- **Target comp**: the raid leader's wanted tanks / healers / damage.

---

## Design (current)

**Searching (Decided):**
- Pane over Blizzard's results on Premade Groups > Dungeons and Raids -
  current; Blizzard's search row (search text, refresh, Filter button)
  stays visible above it. A 1px mint line across the top shrinks over the
  ~3 s search cooldown.
- One filter per content type. Keys: dungeons, room for my role
  (party-aware), has Bloodlust, has battle rez, no other of my class,
  leader score floor / at least mine, leader's realm region. Raids: realm
  region, bosses that must be alive, My lockout (toggles).
- Our keys filter drives Blizzard's advanced filter (server-side
  narrowing, 100-result cap); Bloodlust / battle rez / region stay local.
  "Use Blizzard's group list instead" hands Blizzard's filter back clear.
- Columns: Name (new mark, friend / guild marks), Dungeon / Raid (+
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
  mint row edge = fills an open seat from 3 in the group.
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

**Known limits:** past-season raids are a named list in Groups.lua
(update each season); the raid buff table is per class (check each
season); an open sign-up at /reload is re-attached by leader + activity.

---

## v1.0.0 — released 2026-10-04

- Name: PickupGroup (decided 2026-10-04).
- Debug (trace) logging defaults to off (schema 6).
- StockClerk gets its own ponytail + WCAG session (same style language:
  grey rest rings, toggle bar).

## Later (unscheduled)

- Share a filter as an import/export string (parked by the player).
- Quick-create for keystone listings, designed from scratch.

---

## Working method

**Testing (player's preference):** the player tests in game, `/reload`s
and says "done"; Claude reads the log and checklist ticks from the saved
variables, never asks for a paste. Screenshots for layout. Small alphas,
installed and verified each time. The tester (Tyler / Tripoloski) plays
casually: his reports are leads; spike issues ourselves.

**In-game test list:** `Dev/DevChecklist/` is a dev-only addon installed
as `Interface\AddOns\DevChecklist` (never shipped). Each round, rewrite
`Checklist.lua` (round name; items { area, what to do / expect, what to
send }) grouped by area, and install it. Ticks are saved per item text in
`WTF\Account\SAVAGEFEARLESS\SavedVariables\DevChecklist.lua`.

**Session setup:**
- Repo: `TheWolfIsLoose/PickupGroup` (public). Work on `dev`; merge to
  `main` only to release (a new CHANGELOG version on `main` publishes).
- Install: copy changed files into `Interface\AddOns\PickupGroup` in the
  player's `_retail_` folder through the device bridge; a new file in the
  TOC needs a game restart. Stage each build under a fresh folder
  (`/mnt/user-data/outputs/pg-<version>/`) and compare checksums after.
- Logs: `WTF\Account\SAVAGEFEARLESS\SavedVariables\PickupGroup.lua`.
- Check before every build: `lua5.1 Dev/check.lua *.lua UI/*.lua`.
  No package manager has Lua here: `git clone --depth 1 -b v5.1
  https://github.com/lua/lua`, then `gcc -O2 -DLUA_USE_POSIX -o
  /usr/local/bin/lua5.1 $(ls *.c | grep -v 'luac.c\|print.c') -lm`.
- Style: StockClerk's `Dev/STYLE.md`; StockClerk code may be reused.
- Push: `git push origin dev` / `main` (retry once if it drops); tag
  pushes are refused by the session proxy, CI tags instead.
