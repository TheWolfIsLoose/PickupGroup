-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 21 (0.8.1-alpha2)"
local S, P = "PickupGroup: Searching", "PickupGroup: Party / later"
DevChecklist_Items = {
    { S, "Dungeons: each row's comp has a small crown over the leader's seat (one per row), now sitting on the seat's top edge, clear of the row above.", "SS" },
    { S, "Hover a dungeon row and a raid row: the leader line has a crown and the leader's name in their class colour.", "SS + say done (log)" },
    { P, "Whenever it happens: join a party some other way than your own sign-up (whispered invite) after joining a different key through a sign-up: Teleport names the party's listed key, or doesn't show; never the earlier key.", "say done (log)" },
}
