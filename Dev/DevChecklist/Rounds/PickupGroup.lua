-- PickupGroup's test round. Only rewritten while working on PickupGroup; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["PickupGroup"] = {
    round = "suite style pass: confirm",
    items = {
        { "sidecar", "Click Reset once: the label reads Sure? in red with a red ring and flashes three times, then goes back to Reset after 3 s. Click twice quickly: it resets. Same on Clear (settings).", "say yes / no" },
        { "search pane", "A finished sign-up's Reapply: first click reads Sure? in red. Then /reload so I can read the log.", "say yes / no" },
    },
}
