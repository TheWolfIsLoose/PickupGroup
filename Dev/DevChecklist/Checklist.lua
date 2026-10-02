-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 15 (0.6.2-alpha11)"
local S, O, D, P = "PickupGroup: Searching", "PickupGroup: Options", "PickupGroup: Leading a key", "PickupGroup: Party / later"
DevChecklist_Items = {
    { S, "With a friend's or guildmate's group listed: type /pug friends once while it's in your results.", "say done (log) + SS" },
    { S, "Comp tiles: empty seats have plain dark rings (no mint on your role's seat).", "SS" },
    { O, "Tick \"Use Blizzard's group list instead\", open Blizzard's Filter menu: every dungeon on, no role / class / score set. Untick it again.", "SS of the menu" },
    { D, "With 3+ in the group: applicants who fill an open seat get a mint edge on the row's left (no ring on the spec icon); the rest are dimmed. Solo / 2: no edges.", "SS" },
    { D, "Our panel is one piece across the scroll bar and up to the top of the refresh corner; our refresh icon (top right, mint on hover) refreshes the applicant list.", "SS" },
    { D, "More applicants than fit: scrolling stops once the last applicant is in view (no empty space below); the thumb reaches the bottom.", "SS" },
    { D, "Two players applying together: the second row is indented under the first, joined by a thin line.", "SS if seen" },
    { P, "Friend test (friend on this build): you list a key; they search it (our list, then Use Blizzard's) and /pug friends; send their PickupGroup.lua.", "their file" },
    { P, "In a full 5/5 party from a listing: Teleport button appears, casts the right teleport, gone once inside.", "SS + say done (log)" },
    { P, "Run a key with the Group Finder open at some point.", "say done (log)" },
}
