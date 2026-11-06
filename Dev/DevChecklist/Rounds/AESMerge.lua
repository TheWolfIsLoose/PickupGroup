DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["AESMerge"] = {
    round = "slash commands: logs and debugging only",
    items = {
        { "slash", "/aes talents, /aes restock, /aes gf: each prints its commands.", "yes / no" },
        { "slash", "/aes talents log, /aes restock log, /aes gf log: each opens its log.", "yes / no" },
        { "tab", "Utilities › Talent Builds: no Open Log button, no slash note.", "screenshot" },
        { "readycheck", "At a ready check, Shift-drag the card: it moves and stays.", "yes / no" },
    },
}
