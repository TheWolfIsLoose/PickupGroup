-- PickupGroup's test round. Only rewritten while working on PickupGroup; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["PickupGroup"] = {
    round = "motion",
    items = {
        { "search pane", "Header reads dev e595f68. Sign up to a group: when it changes (invited, declined, filled, delisted), its pinned row shimmers once.", "say yes / no" },
        { "settings", "Settings & Activity: the shimmer option reads Alert: Shimmer what's new; turning it off stops the shimmers. Then /reload so I can read the log.", "say yes / no" },
    },
}
