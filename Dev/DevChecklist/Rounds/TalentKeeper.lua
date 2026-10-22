-- TalentKeeper's test round. Only rewritten while working on TalentKeeper; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["TalentKeeper"] = {
    round = "controls at the top",
    items = {
        { "deck", "Open talents: your spec big at top left with its name, the others small at the right, Save current / Import under the name; the selected build (or No build selected) with Apply / Tags... / More... under that; the list runs to the bottom.", "screenshot" },
        { "deck", "Click a small spec icon: it fills from the bottom while the change casts; when it lands the two trade places smoothly and the name fades to the new spec. Then change back.", "say yes / no" },
        { "deck", "Places tab: the deck and build buttons stay put above it. Then /reload so I can read the log.", "say yes / no" },
    },
}
