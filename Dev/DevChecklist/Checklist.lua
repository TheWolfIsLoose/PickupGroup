-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup 1.0.2 candidate: raid boss lists"
local R = "PickupGroup: raid search"
DevChecklist_Items = {
    { R, "Open the Adventure Guide on any raid or dungeon, close it, then search Raids - Midnight. Filter tab: Venomous Abyss lists its 8 bosses, Tidebound Grotto its 1 (Nymrissa Wavecaller); the Bosses column reads x/8 and x/1.", "screenshot" },
    { R, "Hover a raid row's Bosses cell: the tooltip names that raid's own bosses.", "say done" },
    { R, "/reload when finished so Claude can read the log.", "say done" },
}
