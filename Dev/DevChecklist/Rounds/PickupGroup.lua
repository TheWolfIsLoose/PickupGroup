-- PickupGroup's test round. Only rewritten while working on PickupGroup; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["PickupGroup"] = {
    round = "suite style pass",
    items = {
        { "chat", "Load line: PickupGroup in white + gray, /pug in white, version 'dev 980c54f'. No mint anywhere.", "say yes / no" },
        { "search pane", "Premade Groups > Dungeons: no mint left (top line, hover, pinned edges are white); groups new since the last search have a blue name; a short list shimmers white. The three-bar icon's tooltip says Settings & Activity.", "screenshot" },
        { "sidecar", "Header: white icon, PickupGroup, version on the left; three-bar and close on the right. Under it Filter / Notes tabs with Reset at the right (Filter tab only). Three-bar opens the settings view; Filter brings the filter back.", "screenshot of the filter, then of settings" },
        { "sidecar", "Buttons (Reset, Clear, Sign-up history) are 20px with the small font; Reset's Sure? still works.", "say yes / no" },
        { "quick list", "Dungeons listing form: name and version now in the header at the top; Quick list on the left under it, Lists as <playstyle> on the right.", "screenshot" },
        { "clash", "Only if EllesmereUI is installed: turn on its Group Finder. Expect one chat line; PickupGroup's list steps aside; reopen the Group Finder: the sidecar shows 'Turn off EllesmereUI's Group Finder?' with a ticked row, Reload now / Later. Untick, then Later. Skip if not installed.", "screenshot of the prompt, or say skipped" },
        { "addon list", "Game menu > AddOns: PickupGroup's icon is the white swirl. Then /reload so I can read the log.", "say yes / no" },
    },
}
