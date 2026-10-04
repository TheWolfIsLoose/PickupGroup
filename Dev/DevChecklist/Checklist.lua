-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 25 (0.9.0-alpha8)"
local P, H = "PickupGroup: Party / later", "PickupGroup: History"
DevChecklist_Items = {
    { H, "Sign-up history: \"times turned away since <date>\"; the Today line and the tally don't overlap each other or the headings.", "screenshot" },
    { H, "Reset: first click reads Sure?, second wipes this character (count 0, since today). Tick All characters first only if you mean it.", "say done" },
    { P, "Whenever it happens: a dungeon group you signed up to reaches 5/5: The Cyclist plays once (not with the chime unticked).", "say done (log)" },
    { P, "Whenever it happens: a key you joined through a sign-up ends with a passed vote to abandon: its history row reads Bailed with the level.", "say done (log)" },
}
