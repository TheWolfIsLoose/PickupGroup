-- TalentKeeper's test round. Only rewritten while working on TalentKeeper; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["TalentKeeper"] = {
    round = "Tag Overview tree lines and folding",
    items = {
        { "tag overview", "The tab reads Tag Overview; each heading has a thin gray line down its left with a short branch to each place, ending at the last one (no tail into the next heading).", "screenshot" },
        { "tag overview", "Headings read - Name; click one: it turns to + Name and its places fold away (the summary line still counts them); click again to open. Fold one, /reload: it stays folded.", "say yes / no" },
    },
}
