-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "StockClerk 1.3.1 candidate (accessibility + style guide)"
local W, S = "StockClerk: main window", "StockClerk: side panel"
DevChecklist_Items = {
    { W, "/clerk: the Item ID and Target boxes, the Need / Cap cells and the Restock button have a gray outline and light fill at rest; hover lightens the outline; typing in a box (or editing a cell) turns it mint.", "screenshot" },
    { W, "Mine / Warband at the top: the list on screen has a bar under it; switch lists and the bar follows.", "say done" },
    { S, "Open the side panel: checkboxes have gray outlines, rows evenly spaced, nothing overlapping Add common consumables or Recent activity.", "screenshot" },
    { "PickupGroup", "Whenever it happens: a dungeon group you signed up to reaches 5/5: The Cyclist plays once.", "say done (log)" },
}
