-- Rewritten by Claude each test round: { addon, what to do and expect, what to send }.
DevChecklist_Round = "PickupGroup dev, round 7"
DevChecklist_Items = {
    { "PickupGroup", "Right-click a group: Whisper leader opens a whisper to them.", "" },
    { "PickupGroup", "Raids: search \"<raid> (Heroic)\". Boss list = one checkbox per boss (ticked = must be alive); button reads My lockout (H). Click it: bosses you haven't killed on Heroic get ticked; message says which lockout. Old Alive picks carried over, Dead ones cleared.", "SS" },
    { "PickupGroup", "Same with (Normal): My lockout (N) uses your Normal lockout, not Heroic.", "SS" },
    { "PickupGroup", "Raid sign-up: click Apply, note 1 selected under Blizzard's window; click Apply on another raid group with the window still open: notes still there and selected.", "SS + say done (log)" },
    { "PickupGroup", "Options > Sign-up history: table of your sign-ups, newest first, tally line on top; All characters adds a Character column.", "SS" },
    { "PickupGroup", "Type /pug tp: each dungeon lists a spell ID (teleports you know) or no teleport known.", "SS of chat" },
    { "PickupGroup", "Later, in a full 5/5 party from a listing: Teleport button appears, casts the right teleport, gone once inside.", "SS + say done (log)" },
    { "PickupGroup", "Greyed-out Apply tooltip: no seat for your role.", "SS" },
    { "PickupGroup", "Run a key with the Group Finder open at some point.", "say done (log)" },
}
