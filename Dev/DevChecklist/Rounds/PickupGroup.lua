-- PickupGroup's test round. Only rewritten while working on PickupGroup; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["PickupGroup"] = {
    round = "suite style pass: confirm",
    items = {
        { "sidecar", "Click Reset once: the label reads Sure? in red with a red ring and flashes three times, then goes back to Reset after 3 s. Click twice quickly: it resets. Same on Clear (settings).", "say yes / no" },
        { "clash", "Only if EllesmereUI is installed: turn on its Group Finder. Expect one chat line; PickupGroup's list steps aside; reopen the Group Finder: the sidecar shows 'Turn off EllesmereUI's Group Finder?' with a ticked row, Reload now / Later. Untick, then Later. Skip if not installed.", "screenshot of the prompt, or say skipped" },
        { "search pane", "A finished sign-up's Reapply: first click reads Sure? in red. Then /reload so I can read the log.", "say yes / no" },
    },
}
