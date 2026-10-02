-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 12 (0.6.2-alpha2)"
local D, P = "PickupGroup: Leading a key", "PickupGroup: Party / later"
DevChecklist_Items = {
    { D, "List a key: our applicant list covers Blizzard's (top bar: Needs ..., count; columns Name / iLvl / Score / <dungeon code> / Adds).", "SS" },
    { D, "Rows: spec icon (mint ring = fills an open seat), name, ilvl, score, best run in this dungeon (white timed, amber not), Lust / Rez where they'd add it.", "SS" },
    { D, "Hover a row: spec, ilvl, score, best here with time, realm region, adds / fills, why dimmed, the note.", "SS" },
    { D, "An applicant with a note: a grey line under their row shows it.", "SS if seen" },
    { D, "Click Invite on one (they leave or join), Decline (X) on another. Nothing blocked.", "say done (log)" },
    { D, "Dimmed rows: a role whose seats are full, an OCE / BR / LAT realm with that region off in the Dungeons filter.", "SS if seen" },
    { P, "In a full 5/5 party from a listing: Teleport button appears, casts the right teleport, gone once inside.", "SS + say done (log)" },
    { P, "Run a key with the Group Finder open at some point.", "say done (log)" },
}
