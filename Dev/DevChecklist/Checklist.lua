-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 18 (0.7.1-alpha2)"
local S, P = "PickupGroup: Searching", "PickupGroup: Party / later"
DevChecklist_Items = {
    { S, "Hover a group with a friend or guildmate in it: the tooltip names them (Friend: / Guildmate:), not just a count.", "SS" },
    { P, "Full 5/5 party: no Teleport button while that dungeon's teleport is on cooldown; after a successful teleport it doesn't come back (also after zoning or the group changing).", "say done (log)" },
    { P, "Friend test (friend on v0.7.0+): you list a key; they search for it (our list, then Use Blizzard's). Send their PickupGroup.lua if they can't see it.", "their file" },
}
