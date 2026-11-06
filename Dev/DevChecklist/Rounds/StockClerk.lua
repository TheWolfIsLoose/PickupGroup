-- StockClerk's test round. Only rewritten while working on StockClerk; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["StockClerk"] = {
    round = "step aside for AES",
    items = {
        { "login", "With AES Restocking on: StockClerk prompts to turn itself off. Click Not Now.", "yes / no" },
        { "login", "No StockClerk minimap icon, and AH/bank/vendor opens no StockClerk window.", "yes / no" },
        { "slash", "/clerk prints that AES Restocking has it covered.", "yes / no" },
    },
}
