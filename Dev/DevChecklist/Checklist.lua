-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup: leaver mark and row states"
local S = "PickupGroup: dungeon search"
local R = "PickupGroup: raid search"
DevChecklist_Items = {
    { S, "Search Dungeons, wait a minute, refresh. No dots on any row; groups new since the last search have a mint name and a thin mint edge on the left. Hover one: the second tooltip line says 'New since your last search'. Your sign-ups keep their mint edge with white names.", "screenshot of the list" },
    { S, "Scroll for a spec icon with Blizzard's leaver mark (small icon on its top-right corner). Hover the group: the mark sits after that member's name, with an amber line under the names. None after a few searches? Say 'none seen'.", "screenshot of the tooltip, or 'none seen'" },
    { S, "Turn on Options > Color names for friends / guild, check a friend or guild group still shows its colour, then turn it back the way you like it.", "say done" },
    { R, "Search Raids: names still read normally; new groups get the mint name and edge too, then /reload so I can read the log.", "say done" },
}
