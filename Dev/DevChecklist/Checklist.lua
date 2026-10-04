-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 27 (0.9.0-alpha10)"
local P, H = "PickupGroup: Party / later", "PickupGroup: History"
DevChecklist_Items = {
    { "Copy pass", "Options reads \"Color names for friends / guild\"; /pug help uses long dashes. Stock Clerk (copied in): chat name reads \"Stock Clerk\"; side panel says Auto-open at bank, Express restock at Auction House / at bank, Recent activity.", "screenshot if anything reads wrong" },
    { P, "Whenever it happens: a dungeon group you signed up to reaches 5/5: The Cyclist plays once (not with the chime unticked).", "say done (log)" },
    { P, "Whenever it happens: a key you joined through a sign-up ends with a passed vote to abandon: its history row reads Bailed with the level.", "say done (log)" },
}
