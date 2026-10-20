-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup: row states, leftovers"
local S = "PickupGroup: dungeon search"
local O = "PickupGroup: options"
local R = "PickupGroup: raid search"
DevChecklist_Items = {
    { S, "Tick 'Leader at least my score', refresh, untick it, refresh: only a few groups go mint (ones listed in between), not most of the list.", "say yes / no" },
    { S, "Sign up for a group (mint edge while waiting), then withdraw it: its edge turns grey and the row fades. New groups never get an edge.", "screenshot after withdrawing" },
    { O, "Options: 'Alert: Shimmer on new groups' sits under the chime switch and everything still fits above the footer.", "screenshot of Options" },
    { R, "Hover a raid group: under the role counts, one line per role with every member's name in class colours, then the bosses. Then /reload so I can read the log.", "screenshot of a raid tooltip" },
}
