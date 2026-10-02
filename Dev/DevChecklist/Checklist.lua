-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 13 (0.6.2-alpha3)"
local D, S, P = "PickupGroup: Leading a key", "PickupGroup: Searching", "PickupGroup: Party / later"
DevChecklist_Items = {
    { D, "Two players applying together: the second row is indented under the first, joined by a thin line; Invite / X only on the first.", "SS if seen" },
    { D, "Blizzard's scroll bar is covered; with more applicants than fit, a grey thumb on the right shows where you are and moves as you scroll.", "SS" },
    { D, "Invite one, decline one.", "say done (log)" },
    { S, "Groups with a friend or guildmate in them sort to the top of the list.", "SS if seen" },
    { P, "Friend test (with a friend on 0.6.2 dev or later): they click Apply on your listed group (no shift); send their PickupGroup.lua.", "their file" },
    { P, "In a full 5/5 party from a listing: Teleport button appears, casts the right teleport, gone once inside.", "SS + say done (log)" },
    { P, "Run a key with the Group Finder open at some point.", "say done (log)" },
}
