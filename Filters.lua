--[[
    PickupGroup - Filters.lua
    Saved filters: named sets of search rules, shown as tabs. Account-wide
    in PickupGroupDB.filters; the active one per kind in
    PickupGroupDB.activeFilter. Kind is "keys" (Dungeons) or "raid"
    (Raids - current). Rules run on our copy of the results only.

    keys: room, lust, brez, minScore, atLeastMine, dungeons (nil = all,
          else set of dungeon names)
    raid: room, difficulties (set of N/H/M), maxDown (nil = any)
--]]

local _, ns = ...

local Filters = {}
ns.Filters = Filters

local SHIPPED = {
    { id = "weekly", name = "Weekly keys", kind = "keys", room = true },
    { id = "push", name = "Push keys", kind = "keys", room = true, atLeastMine = true },
    { id = "raid", name = "Raid", kind = "raid", room = true, difficulties = { N = true, H = true, M = true } },
}

-- Classes that bring Bloodlust / a battle rez.
local LUST = { SHAMAN = true, MAGE = true, HUNTER = true, EVOKER = true }
local BREZ = { DRUID = true, DEATHKNIGHT = true, WARLOCK = true, PALADIN = true }

local function All()
    if not ns.db.filters then ns.db.filters = CopyTable(SHIPPED) end
    ns.db.activeFilter = ns.db.activeFilter or {}
    return ns.db.filters
end

function Filters.Kind()
    local p = LFGListFrame and LFGListFrame.SearchPanel
    return (p and p.categoryID == 3) and "raid" or "keys"
end

function Filters.List(kind)
    local out = {}
    for _, f in ipairs(All()) do if f.kind == kind then out[#out + 1] = f end end
    return out
end

function Filters.Active(kind)
    kind = kind or Filters.Kind()
    local list = Filters.List(kind)
    local id = ns.db.activeFilter and ns.db.activeFilter[kind]
    for _, f in ipairs(list) do if f.id == id then return f end end
    return list[1]
end

function Filters.SetActive(f)
    All()
    ns.db.activeFilter[f.kind] = f.id
end

function Filters.New(kind)
    local base = Filters.Active(kind)
    local f = base and CopyTable(base) or { kind = kind, room = true }
    f.id, f.name = "f" .. time() .. math.random(1000), "New filter"
    table.insert(All(), f)
    Filters.SetActive(f)
    ns.Log.Emit("filter", { action = "new", name = f.name })
    return f
end

-- Never the last filter of its kind.
function Filters.Delete(f)
    if #Filters.List(f.kind) <= 1 then return false end
    local all = All()
    for i, g in ipairs(all) do if g == f then table.remove(all, i) break end end
    ns.Log.Emit("filter", { action = "delete", name = f.name })
    return true
end

-- This season's dungeons, as { name, code }, from the game.
function Filters.Dungeons()
    local out = {}
    for _, mapID in ipairs(C_ChallengeMode.GetMapTable() or {}) do
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        if name then out[#out + 1] = { name = name, code = ns.Groups.Code(name) } end
    end
    table.sort(out, function(a, b) return a.code < b.code end)
    return out
end

local function Brings(classes, set)
    for file in pairs(classes or {}) do if set[file] then return true end end
    return false
end

-- Does a row pass the active filter of its kind?
function Filters.Pass(row)
    local f = Filters.Active(row.isRaid and "raid" or "keys")
    if not f then return true end
    if f.room and not row.fits then return false end
    if row.isRaid then
        if f.difficulties and row.difficulty and not f.difficulties[row.difficulty] then return false end
        if f.maxDown and (row.down or 0) > f.maxDown then return false end
        return true
    end
    if f.dungeons and not f.dungeons[row.activity] then return false end
    if f.lust and Brings(row.classes, LUST) then return false end
    if f.brez and Brings(row.classes, BREZ) then return false end
    local score = row.score or 0
    if (f.minScore or 0) > 0 and score < f.minScore then return false end
    if f.atLeastMine and score < (C_ChallengeMode.GetOverallDungeonScore() or 0) then return false end
    return true
end
