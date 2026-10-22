-- Self-check for the keys filter's playstyle and "leader timed it at my level"
-- rules, and the playstyle part of Filters.Sync: lua5.1 Dev/test_keys.lua from the repo root.
Enum = { LFGEntryGeneralPlaystyle = { Learning = 1, FunRelaxed = 2, FunSerious = 3, Expert = 4 },
         LFGListFilter = { CurrentSeason = 1, PvE = 2 } }
GetTime = function() return 0 end
bit = { bor = function(a, b) return a + b end }  -- the flags here never overlap
C_ChallengeMode = { GetMapTable = function() return { 1, 2 } end,
    GetMapUIInfo = function(id) return id == 1 and "Murder Row" or "Kings' Rest" end,
    GetOverallDungeonScore = function() return 0 end }
C_MythicPlus = { GetSeasonBestForMap = function(id) return id == 1 and { level = 15 } or nil end }
local adv = { activities = { 11, 12 }, generalPlaystyle1 = false, generalPlaystyle2 = false,
              generalPlaystyle3 = false, generalPlaystyle4 = true }
local saves = 0
C_LFGList = { GetAdvancedFilter = function() return adv end, SaveAdvancedFilter = function() saves = saves + 1 end,
    GetAvailableActivityGroups = function() return { 11, 12 } end,
    GetActivityGroupInfo = function(id) return id == 11 and "Murder Row" or "Kings' Rest" end }
UnitClass = function() return "Warlock", "WARLOCK" end
CopyTable = function(t) local o = {} for k, v in pairs(t) do o[k] = v end return o end
local filter = { kind = "keys", name = "Dungeons" }
local ns = { db = { filters = { filter } }, Log = { Emit = function() end },
    Groups = { Code = function(n) return n:sub(1, 2) end, SoleRole = function() return nil end } }
loadfile("Filters.lua")("PickupGroup", ns)
local F = ns.Filters
local function check(name, cond) assert(cond, name) print("ok", name) end
local function row(dungeon, style, best) return { activity = dungeon, playstyle = style, leaderBest = best } end
local L, R, C = 1, 2, 3

check("no rules: passes", F.Pass(row("Murder Row", R)))
filter.styles = { C = true }
check("Competitive only: keeps Competitive", F.Pass(row("Murder Row", C)))
check("Competitive only: drops Relaxed", not F.Pass(row("Murder Row", R)))
check("Competitive only: drops a carry", not F.Pass(row("Murder Row", 4)))
F.Sync()
check("Sync writes playstyle 3 only, carry off", adv.generalPlaystyle3 and not adv.generalPlaystyle1
    and not adv.generalPlaystyle2 and adv.generalPlaystyle4 == false and saves == 1)
F.Sync()
check("Sync leaves an unchanged filter alone", saves == 1)
filter.styles = nil
F.Sync()
check("all playstyles: none ticked (Blizzard's all)", not (adv.generalPlaystyle1 or adv.generalPlaystyle2
    or adv.generalPlaystyle3 or adv.generalPlaystyle4) and saves == 2)

filter.leaderMyLevel = true
check("my +15 MR: leader timed +15 passes", F.Pass(row("Murder Row", R, { level = 15, timed = true })))
check("my +15 MR: leader timed +14 drops", not F.Pass(row("Murder Row", R, { level = 14, timed = true })))
check("my +15 MR: leader's +16 not timed drops", not F.Pass(row("Murder Row", R, { level = 16, timed = false })))
check("my +15 MR: leader with no run drops", not F.Pass(row("Murder Row", R)))
check("no timed key of mine in KR: not judged", F.Pass(row("Kings' Rest", R)))
check("summary names the rule", F.Summary(filter):find("leader timed my level"))
