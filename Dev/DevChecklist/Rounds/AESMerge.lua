DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["AESMerge"] = {
    round = "cleanup pass: logs, export, shared look",
    items = {
        { "slash", "/aes talents, /aes restock, /aes gf: each prints its commands.", "yes / no" },
        { "logs", "/aes talents log, restock log, gf log: each opens in the copy window, own title.", "yes / no" },
        { "tab", "Utilities › Talent Builds: no Open Log button, no slash note.", "yes / no" },
        { "history", "Sign-Up History tab › Export: opens in the copy window.", "yes / no" },
        { "talents", "Open the talent window: pane looks unchanged (fonts, buttons, icons).", "screenshot" },
        { "group finder", "Sign up to a group: its timer still counts down on the row.", "yes / no" },
    },
}
