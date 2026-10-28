-- PickupGroup's test round. Only rewritten while working on PickupGroup; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["PickupGroup"] = {
    round = "session stats, refresh icon, quick list, countdown, mixed sign-ups",
    items = {
        { "raid view", "Sign up to a couple of keys, then switch to Raids: the pinned key rows show role counts (shield / cross / sword numbers) like the raid rows, nothing running over the time-left button.", "screenshot" },
        { "search pane", "Sign up to a few groups: each pinned row's time left ticks down one second at a time, every second (no stalls, no 2-second jumps), all rows together.", "say yes / no" },
        { "quick list", "In a party where two keys share a dungeon (e.g. Kings' Rest +20 and +17): that dungeon has a row for each key, highest first. Type +17 in the title and click the +17 row: it lists.", "screenshot" },
        { "leader view", "List a group: the refresh icon top right is a smooth circular arrow, gray at rest, white on hover, the same weight as the filter icon beside it.", "screenshot" },
        { "search pane", "Groups new since your last search: a white left edge (and one shimmer on a short list), name stays white; a group with a friend in it still shows the friend mark / blue name, so the two no longer look alike.", "screenshot" },
        { "search pane", "Your sign-ups (pinned at the top) read green: name, dungeon and the left edge, until they end (declined goes yellow, filled / delisted gray, joined stays green).", "screenshot" },
        { "sign-up history", "Header reads dev 9a30d04. Sign-up history: the stats now open with This session: N sign-ups, N nos, N got in, then Today. Sign up to a group or two; the session count goes up with Today.", "screenshot" },
        { "sign-up history", "/reload and reopen it: This session keeps its count (only a fresh login restarts it). /pug stats starts with the same line. Then /reload so I can read the log.", "say yes / no" },
    },
}
