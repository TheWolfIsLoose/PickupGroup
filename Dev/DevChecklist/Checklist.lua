-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 26 (0.9.0-alpha9)"
local P, H = "PickupGroup: Party / later", "PickupGroup: History"
DevChecklist_Items = {
    { "UI sweep", "PickupGroup: off toggles and unfilled role icons a touch darker grey, nothing else changed. StockClerk (update.bat dev): chat name mint like PickupGroup's, /clerk in mint, amber / red warnings all one shade each.", "screenshot if anything looks off" },
    { P, "Whenever it happens: a dungeon group you signed up to reaches 5/5: The Cyclist plays once (not with the chime unticked).", "say done (log)" },
    { P, "Whenever it happens: a key you joined through a sign-up ends with a passed vote to abandon: its history row reads Bailed with the level.", "say done (log)" },
}
