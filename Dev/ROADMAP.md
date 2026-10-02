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
- **Filter**: the saved search rules for a content type (one for keys,
  one for raids), summarised in the pane's top bar.
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

## Phase 4 — the extras

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
