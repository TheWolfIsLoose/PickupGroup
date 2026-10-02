-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 16 (0.6.2-alpha12)"
local P = "PickupGroup: Party / later"
DevChecklist_Items = {
    { P, "Friend test (friend on this build): you list a key; they search for it (our list, then Use Blizzard's). Send their PickupGroup.lua if they can't see it.", "their file" },
    { P, "In a full 5/5 party from a listing: Teleport button appears, casts the right teleport, gone once inside.", "SS + say done (log)" },
    { P, "Run a key with the Group Finder open at some point.", "say done (log)" },
}
