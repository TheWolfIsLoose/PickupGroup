<!-- Paste below this line into the CurseForge description (Markdown). Dev-only.
     Gallery (upload in this order, search first as the featured image):
     .assets/screenshots/search.png, group-tooltip.png, raids.png,
     leading-a-key.png, leading-a-raid.png, sign-up-history.png -->

**A faster premade-groups list that lives inside Blizzard's Group Finder.**

Open Premade Groups and PickupGroup is already there: one compact list that shows each group's comp at a glance, a saved filter for dungeons and one for raids, and one click to sign up. Blizzard's search bar, refresh and filter keep working underneath; PickupGroup just shows you more, faster.

![PickupGroup inside the Group Finder](https://raw.githubusercontent.com/TheWolfIsLoose/PickupGroup/main/.assets/screenshots/search.png)

### Features

- **Comps at a glance.** Every group's spec icons in a row, empty seats showing the role they need, and the leader marked. Raids show role counts and bosses down.
- **One filter per content type.** Room for my role, has Bloodlust, has battle rez, no other of my class, playstyle, leader score floor, leader has timed the dungeon at your level, realm regions (NA, Oceanic, Brazil, Latin America; Americas realms only) and, for raids, the difficulty, which raids to show and which bosses must still be alive. **My lockout** dims the bosses you've already killed this week, with a lock. It sets Blizzard's own filter too, so the two always agree. The filter panel opens with the list, ready to tweak.
- **One-click sign-ups.** Click **Apply** to sign up at once. Shift-click to pick one of up to five saved notes first. Your sign-ups stay pinned at the top, with the time each has left, and survive a `/reload`. Hover a group for every member's name and the leader's best run in that dungeon.
- **Friends first.** Groups with a friend or guildmate in them go to the top of the list, marked.
- **Clean-up built in.** Hides listings that have been up for hours, adverts, carry offers and leaders you've blacklisted (and, if you like, groups that declined you). Right-click any row to whisper, report, blacklist or hide its leader.
- **Quick list.** Beside Blizzard's listing window, one click lists your key as Mythic+ with your last playstyle. For a party member's key, type its level in the title first; it reminds you.
- **Leading a group.** Applicants show spec, item level, score and their best run in your key, with anyone below your bar dimmed (never hidden). Raid leaders set a target comp and see who rounds it out.
- **Plays nice with your other addons.** If another addon already does one of PickupGroup's jobs (sign-up notes, the group list, the quick list), PickupGroup steps aside instead of doubling up, and asks in its side panel whether you'd rather turn the other one off. No pop-ups.
- **Ready when you are.** A chime when your dungeon group fills, and a teleport button for the dungeon once the party is complete.
- **A record of every rejection.** Sign-up history counts every time you've been turned away, this session's tally, your fastest "no" and your longest dry spell. `/pug stats` puts it in chat, for bragging rights.

![Hovering a group](https://raw.githubusercontent.com/TheWolfIsLoose/PickupGroup/main/.assets/screenshots/group-tooltip.png) ![Raids](https://raw.githubusercontent.com/TheWolfIsLoose/PickupGroup/main/.assets/screenshots/raids.png)

![Leading a key](https://raw.githubusercontent.com/TheWolfIsLoose/PickupGroup/main/.assets/screenshots/leading-a-key.png) ![Leading a raid](https://raw.githubusercontent.com/TheWolfIsLoose/PickupGroup/main/.assets/screenshots/leading-a-raid.png)

![Sign-up history](https://raw.githubusercontent.com/TheWolfIsLoose/PickupGroup/main/.assets/screenshots/sign-up-history.png)

### Commands

| Command | What it does |
| --- | --- |
| `/pug` (or `/pickupgroup`) | List commands |
| `/pug stats` | Your rejection record, ready to brag about |
| `/pug log` | Open the log (paste it into a bug report) |
| `/pug log clear` | Empty the log |
| `/pug debug` | Record extra detail in the log |

### Install

Retail (Midnight) only. No other addons required; with Raider.IO installed, leaders also see applicants' raid progress.

Install from [CurseForge](https://www.curseforge.com/wow/addons/pickupgroup), or unzip a [release](https://github.com/TheWolfIsLoose/PickupGroup/releases) into `Interface/AddOns/`. Found a bug? Open an [issue](https://github.com/TheWolfIsLoose/PickupGroup/issues) with your `/pug log`.

### Credits

The fill chime is The Cyclist from [SharedMedia: Tones](https://www.curseforge.com/wow/addons/sharedmedia-tones). Font: Barlow Semi Condensed (SIL Open Font License).

Source and issues: [GitHub](https://github.com/TheWolfIsLoose/PickupGroup) 