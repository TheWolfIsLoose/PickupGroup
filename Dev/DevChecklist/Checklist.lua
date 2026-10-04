-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 22b (0.9.0-alpha3)"
local S, P, O = "PickupGroup: Searching", "PickupGroup: Party / later", "PickupGroup: Options"
DevChecklist_Items = {
    { O, "Chat shows \"PickupGroup: v0.9.0-alpha3 loaded\". Open Options: the Blizzard-list hint is one line (\"Switch back from Blizzard's panel.\"), the new \"Chime when my group fills\" box is ticked, and the Sign-up history button sits fully inside the sidecar.", "screenshot if not" },
    { P, "Sign up to a dungeon group that isn't full; when it reaches 5/5 (you or the last player joining), The Cyclist plays once.", "say done (log)" },
    { P, "Untick the chime, repeat: no sound.", "say done" },
    { P, "Whenever it happens: join a party some other way than your own sign-up (whispered invite) after joining a different key through a sign-up: Teleport names the party's listed key, or doesn't show; never the earlier key.", "say done (log)" },
}
