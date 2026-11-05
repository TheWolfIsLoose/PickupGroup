-- PickupGroup's test round. Only rewritten while working on PickupGroup; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["PickupGroup"] = {
    round = "new look + filter panel",
    items = {
        { "quick access", "Open the Group Finder: panel on the right with affixes, five category buttons, This Week.", "screenshot" },
        { "quick access", "Click Mythic+ then Raids: each opens that search. Hover Runs and Lockouts: tooltips fill.", "yes / no" },
        { "dungeons", "Dungeons search: Filters panel, 2x4 dungeon grid with art and best run, nothing overflows.", "screenshot" },
        { "dungeons", "Toggle a few filters and drag Min Score: list and summary line follow, Reset clears.", "yes / no" },
        { "raids", "Raids search: tickboxes and fold headers; opening one raid folds the other.", "screenshot" },
        { "results", "Click Key, Comp, Score headings: list re-sorts, active heading in the accent with an arrow.", "yes / no" },
        { "results", "Comp tiles: class bar under each member, crown on the leader, dimmed role art in empty seats.", "screenshot" },
        { "results", "Your sign-ups pinned green, time left ticks every second; Shift-click Apply opens the dialog.", "yes / no" },
        { "menu", "Three-bar menu: Settings and Sign-Up Notes open in the panel; Done returns to the filters.", "yes / no" },
        { "history", "Runs or Sign-Up History opens the history window; the wheel scrolls it.", "screenshot" },
        { "look", "Accent is white now (no AES blue), nothing else changed. Then /reload so I can read the log.", "screenshot" },
    },
}
