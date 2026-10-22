-- StockClerk's test round. Only rewritten while working on StockClerk; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["StockClerk"] = {
    round = "pre-release tidy check",
    items = {
        { "window", "Header reads dev b4bee12; Have and Cap white when fine, red when short / over; activity feed errors red.", "say yes / no" },
    },
}
