-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup 1.1.0 additions: playstyle, leader's level, tooltip names, hide decliners"
local F = "PickupGroup: keys filter"
local T = "PickupGroup: group tooltip"
local O = "PickupGroup: options"
DevChecklist_Items = {
    { F, "Search Dungeons. The sidecar's Filter tab has a Playstyle row (Learning / Relaxed / Competitive) under the dungeon buttons, and 'Leader timed it at my level' under 'Leader at least my score'. Everything fits above Reset.", "screenshot of the sidecar" },
    { F, "Turn Learning and Relaxed off (only Competitive on). The list keeps only Competitive groups; the top bar says 'Competitive'. Open Blizzard's Filters menu: only Competitive is ticked under playstyle.", "screenshot of the list, and say yes / no for Blizzard's menu" },
    { F, "Turn them all back on. Blizzard's Filters menu shows no playstyle ticked (its 'all'), and the list fills back up.", "say done" },
    { F, "Tick 'Leader timed it at my level'. Hover a few groups: each one's 'Leader's best here' is timed and at least the +N on that dungeon's button. The top bar says 'leader timed my level'.", "screenshot of one tooltip" },
    { T, "Hover a dungeon group: under the leader, 'Leader's best here' (+N timed, or amber +N not timed, or 'none'), the spec icons, then everyone's names in class colours, leader first.", "screenshot; say if names are missing" },
    { O, "Options tab: 'Hide groups that declined me' is there and everything fits. Turn it on. If a leader declines you this session, their groups move under the hidden count with 'declined your sign-up' in the tooltip.", "screenshot of Options; say yes if a decline happened and hid (or 'no decline yet'), then /reload so I can read the log" },
}
