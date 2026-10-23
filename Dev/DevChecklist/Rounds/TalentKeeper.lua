-- TalentKeeper's test round. Only rewritten while working on TalentKeeper; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["TalentKeeper"] = {
    round = "More... menu fixes, motion",
    items = {
        { "more menu", "Header reads dev 47094c6. A build's More... > Group...: the list switches to Move <build> to, with your groups; pick one and the build moves there.", "say yes / no" },
        { "more menu", "A build's More... > Delete: it reads Sure? Click again in red and flashes three times; after 3 s it goes back to Delete (don't click twice unless you mean it). Same on a group heading's Delete it and its builds.", "say yes / no" },
        { "options", "Settings & Activity: Animate what changed sits under Ask in delves (on by default). The prompt's button and the ready check Switch pulse on their own the next time they come up in play. Then /reload so I can read the log.", "say yes / no" },
    },
}
