-- PickupGroup's test round. Only rewritten while working on PickupGroup; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["PickupGroup"] = {
    round = "AES look + filter panel (with AES, then AES disabled)",
    items = {
        { "load", "Login with AES: a PickupGroup notice says settings moved to AES; Open Settings lands on our tab.", "screenshot" },
        { "AES tabs", "Keys & Group Finder shows PickupGroup, Sign-Up Notes, Sign-Up History tabs after AES's four.", "screenshot" },
        { "quick access", "Open the Group Finder: panel on the right with affixes, five category buttons, This Week.", "screenshot" },
        { "quick access", "Click Mythic+ then Raids: each opens that search. Hover Runs and Lockouts: tooltips fill.", "yes / no" },
        { "dungeons", "Dungeons search: Filters panel, 2x4 dungeon grid with art and best run, nothing overflows.", "screenshot" },
        { "dungeons", "Toggle a few filters and drag Min Score: list and summary line follow, Reset clears.", "yes / no" },
        { "raids", "Raids search: tickboxes and fold headers; opening one raid folds the other.", "screenshot" },
        { "results", "Click Key, Comp, Score headings: list re-sorts, active heading in the accent with an arrow.", "yes / no" },
        { "results", "Comp tiles: class bar under each member, crown on the leader, dimmed role art in empty seats.", "screenshot" },
        { "results", "Your sign-ups pinned green, time left ticks every second; Shift-click Apply opens the dialog.", "yes / no" },
        { "menu", "Three-bar menu: Settings and Sign-Up Notes open AES's tabs (alone: the panel's views, Done returns).", "yes / no" },
        { "history", "Runs or Sign-Up History opens history (AES tab; alone: its own window, wheel scrolls).", "screenshot" },
        { "standalone", "Disable AES, reload: same layout in white accent, no errors. Then /reload so I can read the log.", "screenshot" },
    },
}
