--[[
    PickupGroup - Filters.lua
    Saved filters: named sets of search rules, shown as tabs. Account-wide
    in PickupGroupDB.filters; the active one per kind in
    PickupGroupDB.activeFilter. Kind is "keys" (Dungeons) or "raid"
    (Raids - current). Rules run on our copy of the results only.

    keys: room, lust, brez, minScore, atLeastMine, dungeons (nil = all,
          else set of dungeon names)
    raid: room, difficulties (set of N/H/M),
          bosses[raid name][boss name] = "alive" | "dead" (absent = either)
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

-- Match my lockout: for one raid, bosses the player has killed this week
-- become Dead and the rest Alive. The lockout is the one for the difficulty
-- the filter looks for, the highest if it allows several. Returns a line
-- saying what it did.
local DIFF_ID, RANK = { [14] = "N", [15] = "H", [16] = "M" }, { N = 1, H = 2, M = 3 }
local DIFF_WORD = { N = "Normal", H = "Heroic", M = "Mythic" }
function Filters.MatchLockout(f, raidName)
    local best, bestDiff
    for i = 1, GetNumSavedInstances() do
        local name, _, _, diffID, locked, _, _, isRaid = GetSavedInstanceInfo(i)
        local d = DIFF_ID[diffID]
        if isRaid and locked and name == raidName and d and (not f.difficulties or f.difficulties[d])
                and (not bestDiff or RANK[d] > RANK[bestDiff]) then
            best, bestDiff = i, d
        end
    end
    -- Mythic lockouts are whole: a saved player can only rejoin that one
    -- raid (and no listing says which it is); an unsaved one can take any
    -- group's lockout.
    local mythicOnly = f.difficulties and f.difficulties.M and not f.difficulties.H and not f.difficulties.N
    if bestDiff == "M" or (mythicOnly and not best) then
        f.bosses = f.bosses or {}
        local text
        if best then
            text = "You're saved to a Mythic lockout: only the group on that same lockout can take you, "
                .. "and listings don't say which that is. Bosses left as they were."
        else
            f.bosses[raidName] = nil
            text = "Not saved on Mythic: any group can take you (you'd accept their lockout). Every boss set to Either."
        end
        ns.Log.Emit("filter", { action = "match lockout", name = f.name .. ", " .. raidName .. ": " .. text })
        return text
    end
    local killed, n = {}, 0
    if best then
        local _, _, _, _, _, _, _, _, _, _, count = GetSavedInstanceInfo(best)
        for j = 1, count or 0 do
            local boss, _, isKilled = GetSavedInstanceEncounterInfo(best, j)
            if boss and isKilled then killed[boss] = true; n = n + 1 end
        end
    end
    f.bosses = f.bosses or {}
    f.bosses[raidName] = {}
    for _, raid in ipairs(ns.Groups.Raids()) do
        if raid.name == raidName then
            for _, boss in ipairs(raid.bosses) do f.bosses[raidName][boss] = killed[boss] and "dead" or "alive" end
        end
    end
    local text = best
        and ("Matched your %s lockout: %d killed set to Dead, the rest Alive."):format(DIFF_WORD[bestDiff], n)
        or "No lockout for this raid this week: every boss set to Alive."
    ns.Log.Emit("filter", { action = "match lockout", name = f.name .. ", " .. raidName .. ": " .. text })
    return text
end

-- Does a row pass the active filter of its kind?
function Filters.Pass(row)
    local f = Filters.Active(row.isRaid and "raid" or "keys")
    if not f then return true end
    if f.room and not row.fits then return false end
    if row.isRaid then
        if f.difficulties and row.difficulty and not f.difficulties[row.difficulty] then return false end
        -- Raids aren't cleared in order, so each boss can be asked for alive
        -- or dead in the listing.
        for boss, want in pairs(f.bosses and f.bosses[row.activity] or {}) do
            local dead = row.killed and row.killed[boss]
            if (want == "alive" and dead) or (want == "dead" and not dead) then return false end
        end
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
