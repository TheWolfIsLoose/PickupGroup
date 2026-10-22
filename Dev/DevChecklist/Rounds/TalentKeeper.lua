-- TalentKeeper's test round. Only rewritten while working on TalentKeeper; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["TalentKeeper"] = {
    round = "controls at the top + suite style pass",
    items = {
        { "deck", "Open talents: your spec big at top left with its name, the others small at the right, Save current / Import under the name; the selected build (or No build selected) with Apply / Tags... / More... under that; the list runs to the bottom.", "screenshot" },
        { "deck", "Click a small spec icon: it fills from the bottom while the change casts; when it lands the two trade places smoothly and the name fades to the new spec. Then change back.", "say yes / no" },
        { "deck", "Places tab: the deck and build buttons stay put above it.", "say yes / no" },
        { "style", "Pane header: white tree icon, Talent white / Keeper gray, 'dev 871e447' in yellow. Where the gear was: three light-gray bars, white on hover, tooltip Settings & Activity; click shows the options (bars stay white), click again goes back.", "screenshot" },
        { "style", "No mint left: the selected build's wash and the live build's text and edge bar are white; tabs, checkbox squares and the slider thumb while dragging are white; a saved or tagged build shimmers white. Outdated reads yellow.", "screenshot" },
        { "style", "Chat: load line and /tk in white + gray; the zone-in bar and ready check strip show build names in white. Then /reload so I can read the log.", "say yes / no" },
    },
}
