-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 24 (0.9.0-alpha7)"
local P, H = "PickupGroup: Party / later", "PickupGroup: History"
DevChecklist_Items = {
    { H, "Sign-up history: the big number now counts Too slow / Vanished / Ghosted (\"times turned away\"); sign-ups withdrawn the moment you got in read \"Moved on\", not Cold feet; the tally line no longer runs into the column headings.", "screenshot" },
    { P, "Whenever it happens: a dungeon group you signed up to reaches 5/5: The Cyclist plays once (not with the chime unticked).", "say done (log)" },
    { P, "Whenever it happens: a key you joined through a sign-up ends with a passed vote to abandon: its history row reads Bailed with the level.", "say done (log)" },
}
