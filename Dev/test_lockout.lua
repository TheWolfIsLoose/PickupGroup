-- Self-check for Filters.Lockout (My lockout): lua5.1 Dev/test_lockout.lua from the repo root.
local saved  -- { name, diffID, killed = { boss = true } }
local BOSSES = { "B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8" }
GetNumSavedInstances = function() return saved and 1 or 0 end
local function list() return saved.list or BOSSES end
GetSavedInstanceInfo = function() return saved.name, 0, 0, saved.diffID, true, false, 0, true, 0, "", #list() end
GetSavedInstanceEncounterInfo = function(_, j) local b = list()[j]; return b, nil, saved.killed[b] == true end
local traced = {}
local ns = { Trace = function(...) traced[#traced + 1] = table.concat({ ... }, " ") end }
local filter = { kind = "raid", lockout = { VA = true } }
ns.db = { filters = { filter } }
loadfile("Filters.lua")("PickupGroup", ns)
local F = ns.Filters
local function row(diff, ...)
    local k = {} for _, b in ipairs({ ... }) do k[b] = true end
    return { isRaid = true, activity = "VA", difficulty = diff, bosses = BOSSES, killed = k }
end
local function check(name, cond) assert(cond, name) print("ok", name) end
saved = { name = "VA", diffID = 15, killed = { B1 = true, B2 = true, B3 = true, B4 = true, B5 = true, B6 = true } }
local c, left = F.Lockout(row("H"))
check("0/8 heroic: loot left, caught 0", c == 0 and left)
c, left = F.Lockout(row("H", "B1", "B2", "B3", "B4", "B5", "B6"))
check("6/8 heroic: caught 6, loot left", c == 6 and left)
c, left = F.Lockout(row("H", "B1", "B2", "B3", "B4", "B5", "B6", "B7"))
check("7/8 heroic: last boss still lootable", c == 6 and left)
c, left = F.Lockout(row("H", "B1", "B7", "B8"))
check("skip group with 7+8 dead: nothing left", c == 1 and not left)
check("Pass hides it", F.Pass(row("H", "B1", "B7", "B8")) == false)
check("Pass keeps 1/8 skip candidate", F.Pass(row("H", "B1")) == true)
c, left = F.Lockout(row("N", "B1", "B2"))
check("normal: heroic lockout doesn't count", c == 0 and left)
filter.lockout = nil
check("off: nil", F.Lockout(row("H")) == nil)
filter.lockout = { VA = true }
saved.killed.Typo = true
saved.list = { "B1", "B2", "B3", "B4", "B5", "B6", "B7", "Typo" }
F.Lockout(row("H"))
check("unmatched lockout name logged", traced[1] and traced[1]:find("Typo"))
