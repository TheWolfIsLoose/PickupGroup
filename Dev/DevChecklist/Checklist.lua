-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 19 (0.7.1-alpha3)"
local R, S, O, P = "PickupGroup: Raid leading", "PickupGroup: Searching", "PickupGroup: Sidecar", "PickupGroup: Party / later"
DevChecklist_Items = {
    { R, "List a raid: our panel covers Blizzard's applicants. Under the top bar: Target  T [2] H [4] D [14] and buttons 10 20 25 30 (20 shows on: mint with a bar).", "SS" },
    { R, "Click 10, then 30: the boxes and the Needs line follow. Type your own numbers: no preset shows on. /reload: your target is kept.", "say done" },
    { R, "With applicants: columns Name / iLvl / Prog / Adds. Prog reads like 6/8 H (Raider.IO, this raid); hover says it in words.", "SS" },
    { R, "Adds name raid buffs your group lacks (Int, Stam, AP, Vers, Skyfury, Bronze, Brand, Touch, Mark) plus Lust / Rez; hover lists them in full.", "SS + say done (log)" },
    { R, "List a key again: columns are Name / iLvl / Score / <dungeon> / Adds as before; an untimed best run reads e.g. +17x in amber.", "SS" },
    { S, "Groups with friends and guildmates: the friend mark is a person, the guild mark a little banner (with Colour names off).", "SS" },
    { S, "Hover a group with a friend or guildmate in it: the tooltip names them (Friend: / Guildmate:), not just a count.", "SS" },
    { S, "Apply-as role icons in the header sit a bit further apart; each still toggles.", "say done" },
    { O, "Filter tab (Dungeons): on dungeons and regions show a mint bar along their bottom; off ones don't. Checkboxes sit a little further apart; clicking just above / below a label still ticks it.", "SS" },
    { O, "Options tab: everything fits, the Sign-up history button isn't cut off at the bottom.", "SS" },
    { O, "Raids filter: boss rows sit further apart; My lockout shows a bar while it's applied.", "SS" },
    { P, "Full 5/5 party: no Teleport button while that dungeon's teleport is on cooldown; after a successful teleport it doesn't come back (also after zoning or the group changing).", "say done (log)" },
    { P, "Friend test (friend on v0.7.0+): you list a key; they search for it (our list, then Use Blizzard's). Send their PickupGroup.lua if they can't see it.", "their file" },
}
