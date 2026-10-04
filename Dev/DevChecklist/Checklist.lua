-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 23 (0.9.0-alpha6)"
local S, P, O, H = "PickupGroup: Searching", "PickupGroup: Party / later", "PickupGroup: Options", "PickupGroup: History"
DevChecklist_Items = {
    { S, "Open Premade Groups > Dungeons: the sidecar opens on its own. Close it, switch to Raids and back: it stays shut until you leave and come back (or reopen the Group Finder).", "say done" },
    { O, "Hovering \"Use Blizzard's group list instead\" shows the hint tooltip.", "say done" },
    { H, "Options > Sign-up history: big declines number, a quip, a Today / fastest no / dry spell line, witty endings. Tick All characters: numbers change.", "screenshot" },
    { H, "Type /pug stats: one brag line in chat.", "screenshot" },
    { P, "Whenever it happens: a dungeon group you signed up to reaches 5/5: The Cyclist plays once (not with the chime unticked).", "say done (log)" },
}
