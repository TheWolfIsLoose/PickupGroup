-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup 1.0.6 candidate: My lockout (loot left for me)"
local R = "PickupGroup: raid view (on the Rogue)"
DevChecklist_Items = {
    { R, "Sidecar: untick any VA boss checkboxes left over from the old My lockout (they still mean 'must be alive', all of them).", "say done" },
    { R, "Search The Venomous Abyss (Heroic). Click My lockout on the VA heading: it goes mint, the summary says 'loot left for me'.", "screenshot" },
    { R, "6/8 and 7/8 groups (if any) are at the top; 0/8-5/8 below them. No group whose bosses 7 and 8 are both dead shows.", "screenshot of the list" },
    { R, "Click My lockout again: off, and the list goes back to fewest bosses down first.", "say done" },
    { R, "Search VA on Normal with it on: groups sort by your Normal lockout (or plain order if you have none there).", "say done (then /reload so I can read the log)" },
}
