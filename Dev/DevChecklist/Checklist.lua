-- Rewritten by Claude each test round: { heading, what to do and expect, what to send }.
-- Grouped by area: the heading ("Addon: area") prints once per run of items.
DevChecklist_Round = "PickupGroup dev, round 20 (0.7.1-alpha6)"
local L, S, P = "PickupGroup: Leading", "PickupGroup: Searching", "PickupGroup: Party / later"
DevChecklist_Items = {
    { L, "List a raid (20 target): the top line reads e.g. Needs 2 tanks, 4 healers, 13 damage, ... and fits; if it can't, it shortens to 2 T, 4 H, 13 D, Lust, 2 rez.", "SS" },
    { L, "Top bar: a slider icon left of refresh. Click it: the sidecar opens on Leading a raid (Applicant's realm, Item level at least).", "SS" },
    { L, "Set an item level above an applicant's: that row dims; hover says item level under N. Turn a realm off: matching applicants dim.", "SS" },
    { L, "List a key: the slider opens Leading a key with Score at least; a score above an applicant's dims them. Your Dungeons search filter's regions no longer dim applicants.", "SS" },
    { L, "Delist: the sidecar closes. Go to the search list with the sidecar open on a search filter, list a group: the sidecar on the search filter closes, not stuck.", "say done" },
    { S, "More groups than fit: a small down chevron at the bottom centre pulses three times, then stays; scroll to the end: it goes. Scroll back up: it pulses again.", "SS" },
    { L, "More applicants than fit: the same chevron instead of the grey scroll thumb; rows now reach the right edge.", "SS" },
    { S, "Apply-as role icons in the header are back to their old, closer spacing.", "say done" },
    { P, "Join a party some other way than your own sign-up (whispered invite) after joining a different key through a sign-up: Teleport names the party's listed key, or doesn't show; never the earlier key.", "say done (log)" },
}
