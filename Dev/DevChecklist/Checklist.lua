-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup 1.0.2 candidate: raid boss lists + raid row layout"
local R, D = "PickupGroup: raid search", "PickupGroup: dungeon search"
DevChecklist_Items = {
    { R, "Raids - Midnight: Filter tab lists Venomous Abyss's 8 bosses and Tidebound Grotto's 1.", "say done" },
    { R, "Rows read Name | M VA 0/8 (count dimmed) | role counts | Apply; no Bosses column; names show noticeably more text. Headers Raid and Comp line up with their cells.", "screenshot" },
    { R, "Find a group with 10+ in a role: the counts don't touch each other.", "screenshot if they do" },
    { D, "Dungeons: unchanged (Dungeon, five spec tiles, Score).", "screenshot" },
}
