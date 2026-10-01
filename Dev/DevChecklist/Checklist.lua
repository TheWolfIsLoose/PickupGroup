-- Rewritten by Claude each test round: { addon, what to do and expect, what to send }.
DevChecklist_Round = "PickupGroup dev, round 5"
DevChecklist_Items = {
    { "PickupGroup", "Filter (Dungeons): \"Group has Bloodlust\", \"Group has battle rez\", \"No other <your class> in the group\" are single checkboxes; each narrows the list (hover rows to check). Your old has/needs picks: has carried over, needs cleared.", "SS" },
    { "PickupGroup", "Tick \"No other <class>\": open Blizzard's Filter menu, its matching option is on too.", "SS" },
    { "PickupGroup", "Click the X next to Blizzard's Filter button (reset): after the next refresh, Blizzard's filter matches ours again (open its menu).", "SS" },
    { "PickupGroup", "Options: tick Swap. Sign up to 5 groups: other rows read Swap; hover says which is oldest; click Swap withdraws it, button turns to Apply.", "SS + say done (log)" },
    { "PickupGroup", "With a sign-up out, /reload, then wait for it to end (or Cancel it).", "say done (log)" },
    { "PickupGroup", "Greyed-out Apply tooltips: in a party not as leader; no seat for your role.", "SS" },
    { "PickupGroup", "Run a key with the Group Finder open at some point.", "say done (log)" },
}
