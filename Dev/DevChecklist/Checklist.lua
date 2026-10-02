-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 17 (0.7.1-alpha1)"
local S, P = "PickupGroup: Searching", "PickupGroup: Party / later"
DevChecklist_Items = {
    { S, "Hover a group with a friend or guildmate in it: the tooltip names them (Friend: / Guildmate:), not just a count.", "SS" },
    { P, "Friend test (friend on v0.7.0+): you list a key; they search for it (our list, then Use Blizzard's). Send their PickupGroup.lua if they can't see it.", "their file" },
    { P, "Full 5/5 party from a listing: click Teleport; the button goes away as soon as the teleport lands (not only once inside).", "say done (log)" },
    { P, "Run a key with the Group Finder open at some point.", "say done (log)" },
}
