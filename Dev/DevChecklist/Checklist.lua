-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup: leaver mark and row states"
local S = "PickupGroup: dungeon search"
local R = "PickupGroup: raid search"
local O = "PickupGroup: options"
DevChecklist_Items = {
    { S, "Refresh a few times: new groups have a mint name and NO edge. Edges only on your sign-ups: mint while waiting, amber if declined, grey if filled / delisted / withdrawn. Sign up for one and withdraw it to see the grey edge.", "screenshot after a refresh with a sign-up showing" },
    { S, "With a narrow filter (fewer than 20 groups listed), refresh until a new group appears: one soft mint band sweeps across its row once (under a second), the name stays mint. Wide list (20+): no sweep, mint name only.", "say how it looks: too strong / too faint / good" },
    { S, "Turn a playstyle off, refresh, then back on and refresh: the groups that come back are NOT mint (only ones listed in between are). Then refresh twice with no change: mint marks only what's new since the search before.", "say yes / no" },
    { S, "Scroll for a spec icon with Blizzard's leaver mark (small icon on its top-right corner). Hover the group: the mark sits after that member's name, with an amber line under the names. None after a few searches? Say 'none seen'.", "screenshot of the tooltip, or 'none seen'" },
    { S, "Turn on Options > Color names for friends / guild, check a friend or guild group still shows its colour, then turn it back the way you like it.", "say done" },
    { O, "Options: 'Alert: Shimmer on new groups' sits under the chime switch and everything still fits above the footer.", "screenshot of Options" },
    { R, "Search Raids: new groups get the mint name and edge too. Hover a raid group: under the role counts, a line per role (tank, healer, damage icons) with every member's name in class colours, then the bosses. Big groups make a long tooltip for now (the 1.2 GUI pass handles it). Then /reload so I can read the log.", "screenshot of a raid tooltip" },
}
