-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup 1.0.5 candidate: no-match note"
local D = "PickupGroup: dungeon view"
DevChecklist_Items = {
    { D, "Search with a filter that hides every listed group (e.g. 18-19, only KR + TOS): the list says 'No groups fit your filter' and how many are listed.", "screenshot" },
    { D, "Loosen the filter until a group fits: the note goes away and rows show.", "say done" },
    { D, "Search for something nobody has listed: Blizzard's Start a Group shows, with no PickupGroup note on top.", "screenshot" },
}
