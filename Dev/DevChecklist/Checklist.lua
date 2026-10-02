-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 8 (0.6.1-alpha1)"
local F = "PickupGroup: Sidecar"
local D, R, S, P = "PickupGroup: Dungeon view", "PickupGroup: Raid view", "PickupGroup: Sign-ups & options", "PickupGroup: Party / later"
DevChecklist_Items = {
    { F, "Open the sidecar: Raider.IO's profile panel moves to the sidecar's right edge (no overlap); close it: the panel goes back next to the Group Finder.", "SS (both)" },
    { F, "Text boxes, checkboxes and buttons (sidecar and Apply) have a grey outline at rest, not black; lighter grey on hover; mint while typing. Off toggles (dungeons, regions) grey too.", "SS" },
    { F, "Click just above or below a checkbox's label: it still toggles (the click area is taller).", "" },
    { D, "Dungeon buttons read e.g. AOF (+19), the key in white while on; (—) where you have no timed key; hover says so.", "SS" },
    { D, "Has Bloodlust on (you're not a lust class): groups without lust still show when a healer or damage seat stays open after you join; groups whose only other open seat is tank are hidden.", "SS" },
    { D, "Group tooltip: name; dungeon + time listed; leader + score; spec icons in a row; friends/guild and the description if any. No labels, no realm, no hints.", "SS" },
    { D, "Right-click a group: Whisper leader opens a whisper to them.", "" },
    { D, "Hover Blizzard's Filter button: its tooltip says PickupGroup's filter sets it. On Raids: no such line.", "SS" },
    { R, "Search \"<raid> (Heroic)\". Boss list = one checkbox per boss (ticked = must be alive); button reads My lockout (H). Click it: bosses you haven't killed on Heroic get ticked; message says which lockout. Old Alive picks carried over, Dead ones cleared.", "SS" },
    { R, "Same with (Normal): My lockout (N) uses your Normal lockout, not Heroic.", "SS" },
    { S, "Apply button tooltip: click / shift-click hint and the right-click line.", "SS" },
    { S, "Greyed-out Apply tooltip: no seat for your role.", "SS" },
    { S, "Raid sign-up: click Apply, note 1 selected under Blizzard's window; click Apply on another raid group with the window still open: notes still there and selected.", "SS + say done (log)" },
    { S, "Options > Sign-up history: table of your sign-ups, newest first, tally line on top; All characters adds a Character column.", "SS" },
    { P, "Type /pug tp: each dungeon lists a spell ID (teleports you know) or no teleport known.", "SS of chat" },
    { P, "In a full 5/5 party from a listing: Teleport button appears, casts the right teleport, gone once inside.", "SS + say done (log)" },
    { P, "Run a key with the Group Finder open at some point.", "say done (log)" },
}
