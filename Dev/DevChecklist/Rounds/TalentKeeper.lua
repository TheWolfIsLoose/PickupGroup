-- TalentKeeper's test round. Only rewritten while working on TalentKeeper; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["TalentKeeper"] = {
    round = "gear sets (and v0.5.1 leftovers)",
    items = {
        { "gear sets", "Header reads dev d8ef5ee. More... on a build has Gear set...: it lists None and your Equipment Manager sets (with icons). Pick one; hover the build: Gear set: <name>.", "say yes / no" },
        { "gear sets", "Put on different gear, then apply that build (or double-click it): the set goes on after the talents land. Apply it again: no swap (already worn).", "say yes / no" },
        { "more menu", "A build's More... > Group...: the list switches to Move <build> to, with your groups; pick one and the build moves there.", "say yes / no" },
        { "more menu", "A build's More... > Delete: it reads Sure? Click again in red and flashes three times; after 3 s it goes back to Delete (don't click twice unless you mean it).", "say yes / no" },
        { "options", "Settings & Activity: Animate what changed sits under Ask in delves (on by default). Then /reload so I can read the log.", "say yes / no" },
    },
}
