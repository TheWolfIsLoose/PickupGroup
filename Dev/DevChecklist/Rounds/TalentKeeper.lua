-- TalentKeeper's test round. Only rewritten while working on TalentKeeper; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["TalentKeeper"] = {
    round = "tree marks",
    items = {
        { "talent window", "Header reads dev a2ea7d3. Select a build on the other hero tree (e.g. HC ST while on SH AOE): the marks sit on the right talents and the hero emblem, with the green hero tree name above the game's.", "screenshot" },
        { "talent window", "Apply it, open and close the hero tree picker, then close the talent window: no BugSack errors (anchor family / Line:SetStartPoint). Then /reload so I can read the log.", "say yes / no" },
    },
}
