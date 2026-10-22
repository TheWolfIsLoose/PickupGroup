-- TalentKeeper's test round. Only rewritten while working on TalentKeeper; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["TalentKeeper"] = {
    round = "Miscellaneous places",
    items = {
        { "tag config", "Tag Config tab: the first heading is Miscellaneous, with Delves and Open world under it (no more Delves over Delves). Open world shows the same specs' builds as Delves (they kept the old shared tag).", "screenshot" },
        { "tags menu", "A build's Tags...: Miscellaneous heading over Delves and Open world; tick Open world on another build: chat says it moved, and Tag Config shows it there while Delves stays put.", "say yes / no" },
        { "open world", "Out in the world, the pane's Now line and the build list read normally (nothing about delves). Then /reload so I can read the log.", "say yes / no" },
    },
}
