DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["AES Group Finder"] = {
    round = "PickupGroup folded in",
    items = {
        { "load", "Login: a prompt offers to turn PickupGroup off. Click Not Now for this round.", "screenshot" },
        { "load", "Chat says Group Finder brought in your PickupGroup data (first login only).", "yes / no" },
        { "settings", "AES > Keys & Group Finder > Group Finder: switch on, our settings, blacklist, Sign-Up Notes.", "screenshot" },
        { "settings", "Your PickupGroup notes and filters show up here (imported).", "yes / no" },
        { "panel", "Open the Group Finder: our panel in AES blue, his old panel gone, nothing doubled.", "screenshot" },
        { "panel", "Dungeons and Raids searches: filters work as in PickupGroup, list follows.", "yes / no" },
        { "list", "Menu > Settings and Sign-Up Notes open the AES Group Finder tab.", "yes / no" },
        { "history", "Runs or Sign-Up History opens the Sign-Up History tab with your records.", "screenshot" },
        { "slash", "/aes groupfinder log opens the log. Then /reload so I can read the logs.", "yes / no" },
    },
}
