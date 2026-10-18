-- Self-check for the quick list's key and activity picks: lua5.1 Dev/test_quicklist.lua from the repo root.
local ns = { Filters = {}, db = {} }
ns.On = function() end
EventUtil = { ContinueOnAddOnLoaded = function() end }
Enum = { LFGEntryGeneralPlaystyle = { FunRelaxed = 2 }, LFGEntryPlaystyle = { None = 0 } }
-- Altar (map 501) has activities 900 (Mythic), 912 (+12), 915 (+15).
ns.Filters.GroupIDs = function() return { ["Altar of Fangs"] = 7 } end
local levels = { [900] = 0, [912] = 12, [915] = 15 }
C_LFGList = {
    GetAvailableActivities = function(cat, group) assert(cat == 2 and group == 7); return { 900, 912, 915 } end,
    GetKeystoneForActivity = function(id) return levels[id] end,
    GetActivityInfoTable = function(id) return { isMythicPlusActivity = id ~= 900 } end,
}
local own = { level = 10, map = 501 }
C_MythicPlus = { GetOwnedKeystoneLevel = function() return own.level end, GetOwnedKeystoneChallengeMapID = function() return own.map end }
UnitName = function() return "Me" end
local inParty = { Mitt = true }
UnitInParty = function(n) return inParty[n] end
local f = assert(loadfile("UI/QuickList.lua"))
f("PickupGroup", ns)
local Q = ns.QuickList
local function check(name, want, got) assert(want == got, name .. ": got " .. tostring(got)) print("ok", name) end

check("+12 picks its own activity", 912, Q.Activity("Altar of Fangs", 12))
check("+15 picks its own activity", 915, Q.Activity("Altar of Fangs", 15))
check("no level match falls back to a Mythic+ one, never plain Mythic", 912, Q.Activity("Altar of Fangs", 20))
check("unknown dungeon", nil, Q.Activity("Nowhere", 12))
check("own key shows", 10, Q.Keys()[501].level)
