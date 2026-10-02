-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 9 (0.6.1-alpha2)"
local R, O, P = "PickupGroup: Raid view", "PickupGroup: Options", "PickupGroup: Party / later"
DevChecklist_Items = {
    { R, "Search \"<raid> (Normal)\" when no groups are listed: the button reads My lockout (N); hover says Normal; click it: message names your Normal lockout.", "SS" },
    { O, "Tick \"Hide hint tooltips\": no tooltip on Apply (a greyed one still says why), the filter checkboxes, regions, role icons, header icons, the hidden count, My lockout, Blizzard's Filter button. Group rows and dungeon buttons still show theirs.", "SS of one row tooltip" },
    { O, "Untick it: the hints come back.", "" },
    { P, "In a full 5/5 party from a listing: Teleport button appears, casts the right teleport, gone once inside.", "SS + say done (log)" },
    { P, "Run a key with the Group Finder open at some point.", "say done (log)" },
}
