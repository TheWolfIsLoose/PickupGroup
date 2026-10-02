-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 13 (0.6.2-alpha6)"
local A, E, D, S, P = "PickupGroup: Apply (new clicks)", "PickupGroup: EllesmereUI clash", "PickupGroup: Leading a key", "PickupGroup: Searching", "PickupGroup: Party / later"
DevChecklist_Items = {
    { A, "Click Apply: signs up at once, no window. Hover: tooltip says click = at once, shift-click = with a note.", "" },
    { A, "Shift-click Apply: Blizzard's window opens with your notes under it; click note 2: only note 2 shows a selection.", "SS" },
    { A, "Withdraw one, then Reapply: click once = Sure?, again = signed up; shift-click = the window with notes.", "say done (log)" },
    { E, "EllesmereUI Quick Signup ON: shift-click Apply: the window stays open (EllesmereUI doesn't press Sign Up), notes under it.", "SS" },
    { E, "EllesmereUI Persistent Signup Note ON: PickupGroup's alert pops up (once); Options shows the amber \"Off: ...\" line; Notes tab shows the amber notice; shift-click Apply shows only EllesmereUI's helper.", "SS (alert, Options)" },
    { E, "Turn Persistent Signup Note OFF again: shift-click Apply shows our notes again (no reload).", "say done (log)" },
    { D, "Two players applying together: the second row is indented under the first, joined by a thin line.", "SS if seen" },
    { D, "More applicants than fit: a grey thumb on the right shows where you are and moves as you scroll.", "SS" },
    { S, "Groups with a friend or guildmate in them sort to the top of the list.", "SS if seen" },
    { P, "Friend test (friend on this build): they click Apply on your listed group; send their PickupGroup.lua.", "their file" },
    { P, "In a full 5/5 party from a listing: Teleport button appears, casts the right teleport, gone once inside.", "SS + say done (log)" },
    { P, "Run a key with the Group Finder open at some point.", "say done (log)" },
}
