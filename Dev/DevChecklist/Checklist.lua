-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup 1.0.5 candidate: no-match note, history rates, export"
local D = "PickupGroup: dungeon view"
local H = "PickupGroup: sign-up history"
DevChecklist_Items = {
    { D, "Search for something nobody has listed: Blizzard's Start a Group shows, with no PickupGroup note on top.", "screenshot" },
    { H, "Options > Sign-up history: the When column shows the year (mm/dd/yy) and isn't cut off.", "screenshot" },
    { H, "A mint line under the records shows Acceptance rate and Success rate; tick All characters and both change to the account totals.", "screenshot of each" },
    { H, "/pug stats in chat includes both rates.", "say done" },
    { H, "History > Export: a box opens with everything selected; Ctrl+C, paste into a spreadsheet: a totals table, a blank row, then your sign-ups.", "screenshot of the sheet" },
    { H, "Tick All characters, Export again: every character's totals row and sign-ups are in it.", "say done" },
}
