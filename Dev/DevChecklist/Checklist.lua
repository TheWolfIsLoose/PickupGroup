-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 21 (0.8.1-alpha4)"
local S, P = "PickupGroup: Searching", "PickupGroup: Party / later"
DevChecklist_Items = {
    { S, "Dungeons: each row's comp has the leader's seat has a light ring just outside its black edge (one per row); check it on a Holy Paladin leader. Hover the 14 MR kind of row if one looks crown/border-less: who does the tooltip name?", "SS" },
    { S, "Hover a dungeon row and a raid row: the leader line has a crown and the leader's name in their class colour.", "SS + say done (log)" },
    { P, "Whenever it happens: join a party some other way than your own sign-up (whispered invite) after joining a different key through a sign-up: Teleport names the party's listed key, or doesn't show; never the earlier key.", "say done (log)" },
}
