-- PickupGroup's test round. Only rewritten while working on PickupGroup; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["PickupGroup"] = {
    round = "session stats, refresh icon",
    items = {
        { "leader view", "List a group: the refresh icon top right is a smooth circular arrow, gray at rest, white on hover, the same weight as the filter icon beside it.", "screenshot" },
        { "search pane", "Groups new since your last search: a white left edge (and one shimmer on a short list), name stays white; a group with a friend in it still shows the friend mark / blue name, so the two no longer look alike.", "screenshot" },
        { "search pane", "Your sign-ups (pinned at the top) read green: name, dungeon and the left edge, until they end (declined goes yellow, filled / delisted gray, joined stays green).", "screenshot" },
        { "sign-up history", "Header reads dev a83ee16. Sign-up history: the stats now open with This session: N sign-ups, N nos, N got in, then Today. Sign up to a group or two; the session count goes up with Today.", "screenshot" },
        { "sign-up history", "/reload and reopen it: This session keeps its count (only a fresh login restarts it). /pug stats starts with the same line. Then /reload so I can read the log.", "say yes / no" },
    },
}
