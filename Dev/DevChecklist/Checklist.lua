-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "StockClerk 1.3.1 candidate + PickupGroup 1.0 follow-ups"
local W, S, P, C = "StockClerk: main window", "StockClerk: side panel", "PickupGroup: in groups (organic)", "PickupGroup: CurseForge"
DevChecklist_Items = {
    { W, "/clerk: the Item ID and Target boxes, the Need / Cap cells and the Restock button have a gray outline and light fill at rest; hover lightens the outline; typing in a box (or editing a cell) turns it mint.", "screenshot" },
    { W, "Mine / Warband at the top: the list on screen has a bar under it; switch lists and the bar follows.", "say done" },
    { S, "Open the side panel: checkboxes have gray outlines, rows evenly spaced, nothing overlapping Add common consumables or Recent activity.", "screenshot" },
    { P, "Whenever it happens: a dungeon group you signed up to reaches 5/5: The Cyclist plays once.", "say done (log)" },
    { P, "Whenever it happens: a key you joined through a sign-up ends with a passed vote to abandon: its history row reads Bailed with the level.", "say done (log)" },
    { P, "Whenever it happens: join a party some other way than your own sign-up: Teleport names the party's listed key, or doesn't show.", "say done (log)" },
    { C, "Paste Dev/CURSEFORGE.md into the description, upload .assets/logo.png as the logo, add screenshots to the gallery (tell Claude which shots).", "when ready" },
}
