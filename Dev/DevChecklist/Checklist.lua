-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup v1.0.0 (released)"
local P, H = "PickupGroup: Party / later", "PickupGroup: History"
DevChecklist_Items = {
    { "Reminder", "PickupGroup CurseForge: add screenshots to the gallery and the description (tell Claude which shots).", "when ready" },
    { "Release", "Chat shows \"PickupGroup: v1.0.0 loaded\"; /pug debug says detailed recording is off until you switch it on.", "say done" },
    { P, "Whenever it happens: a dungeon group you signed up to reaches 5/5: The Cyclist plays once (not with the chime unticked).", "say done (log)" },
    { P, "Whenever it happens: a key you joined through a sign-up ends with a passed vote to abandon: its history row reads Bailed with the level.", "say done (log)" },
}
