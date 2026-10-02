-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 10 (0.6.1-alpha4)"
local S, P = "PickupGroup: Sign-ups", "PickupGroup: Party / later"
DevChecklist_Items = {
    { S, "Sign up to a group with a friend or guildmate in it (when you see one): the pinned sign-up keeps the blue / green mark at the end of its name.", "SS" },
    { S, "Options > Colour names on: a group with a friend AND a guildmate shows its name blue (rare; tick if never seen).", "SS if seen" },
    { P, "In a full 5/5 party from a listing: Teleport button appears, casts the right teleport, gone once inside.", "SS + say done (log)" },
    { P, "Run a key with the Group Finder open at some point.", "say done (log)" },
}
