-- StockClerk's test round. Only rewritten while working on StockClerk; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["StockClerk"] = {
    round = "motion",
    items = {
        { "window", "Header reads dev 8947f89. The left strip on each row is red when short and gray when stocked (no green).", "screenshot" },
        { "auction house", "Next AH or bank visit with something short (Express restock off): the Restock button pulses three times as the window opens.", "say yes / no" },
        { "window", "Use up a consumable, then reopen StockClerk: the row that just went short shimmers once. Settings has Animate what changed (on); off stops both. Then /reload so I can read the log.", "say yes / no" },
    },
}
