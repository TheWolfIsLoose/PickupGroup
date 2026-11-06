DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["AES Group Finder"] = {
    round = "restocking parity",
    items = {
        { "restocking", "Utilities > Restocking: tick Show Only Items You're Short On; only short rows stay.", "screenshot" },
        { "restocking", "Same on the Warband List; untick brings every row back.", "yes / no" },
        { "restocking", "/aes restock debug prints on, then run one AH restock. Then /reload.", "log" },
    },
}
