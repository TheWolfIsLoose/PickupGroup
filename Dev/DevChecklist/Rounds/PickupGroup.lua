-- PickupGroup's test round. Only rewritten while working on PickupGroup; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["PickupGroup"] = {
    round = "pre-release tidy check",
    items = {
        { "sidecar", "Header reads dev 8d55011; Reset: Sure? red, ring red, flashes 3 times; the more-below chevron in a long list still pulses 3 times.", "say yes / no" },
    },
}
