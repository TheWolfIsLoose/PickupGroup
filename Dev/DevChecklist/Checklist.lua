-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 11 (0.6.2-alpha1)"
local D, R, P = "PickupGroup: Leading a key", "PickupGroup: Leading a raid", "PickupGroup: Party / later"
DevChecklist_Items = {
    { D, "List a key (any level) and let a few applicants come in; type /pug applicants once. Then delist.", "say done (log)" },
    { R, "List a raid group and let a few applicants come in; type /pug applicants once. Then delist.", "say done (log)" },
    { P, "In a full 5/5 party from a listing: Teleport button appears, casts the right teleport, gone once inside.", "SS + say done (log)" },
    { P, "Run a key with the Group Finder open at some point.", "say done (log)" },
}
