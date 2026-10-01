-- Rewritten by Claude each test round: { addon, what to do and expect, what to send }.
DevChecklist_Round = "PickupGroup dev, round 8"
DevChecklist_Items = {
    { "PickupGroup", "Group tooltip: name; dungeon + time listed; leader + score; spec icons in a row; friends/guild and the description if any. No labels, no realm, no hints.", "SS" },
    { "PickupGroup", "Apply button tooltip: click / shift-click hint and the right-click line.", "SS" },
    { "PickupGroup", "Dungeon buttons read e.g. AOF +19 (your best timed key); hover says so.", "SS" },
    { "PickupGroup", "Has Bloodlust on (you're not a lust class): groups without lust still show when a healer or damage seat stays open after you join; groups whose only other open seat is tank are hidden.", "SS" },
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
