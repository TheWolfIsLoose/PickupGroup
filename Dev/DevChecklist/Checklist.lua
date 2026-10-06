-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup 1.0.3 candidate: teleport after the key"
local T = "PickupGroup: teleport (organic)"
DevChecklist_Items = {
    { T, "Next key from a sign-up: the Teleport button shows once the group is 5/5, before you go in.", "say done" },
    { T, "After the key, still grouped and back in town: no Teleport button.", "say done (screenshot if it shows)" },
}
