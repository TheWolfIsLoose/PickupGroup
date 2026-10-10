--[[
    PickupGroup - Filters.lua
    One filter per kind, account-wide in PickupGroupDB.filters. Kind is
    "keys" (Dungeons) or "raid" (Raids - current). Rules run on our copy of
    the results; the keys filter also narrows Blizzard's search (Sync).

    keys: room, lust / brez (true = the group has it), noMyClass, minScore,
          atLeastMine, dungeons (nil = all,
          else set of dungeon names)
    raid: room (difficulty comes from Blizzard's search: the raid suggestion
          picked in its search box carries it),
          bosses[raid name][boss name] = true (must be alive; absent = either),
          lockout[raid name] = true (My lockout: hide groups with no loot left
          for me, sort the rest by how far past my kills they are)
    lead_keys / lead_raid: regions, minScore / minIlvl (the leader view dims
          applicants who miss them)
--]]

local _, ns = ...

local Filters = {}
ns.Filters = Filters

local DEFAULT = {
    keys = { id = "keys", name = "Dungeons", kind = "keys", room = true },
    raid = { id = "raid", name = "Raids", kind = "raid" },
    -- Leading: dims applicants in the leader view (never hides them).
    lead_keys = { id = "lead_keys", name = "Leading: keys", kind = "lead_keys" },
    lead_raid = { id = "lead_raid", name = "Leading: raids", kind = "lead_raid" },
}

-- Classes that bring Bloodlust / a battle rez: class file -> the roles it can fill (seats it could take).
local T, H, D = "TANK", "HEALER", "DAMAGER"
local function Roles(...) local o = {} for _, r in ipairs({ ... }) do o[r] = true end return o end
local LUST = { SHAMAN = Roles(H, D), MAGE = Roles(D), HUNTER = Roles(D), EVOKER = Roles(H, D) }
local BREZ = { DRUID = Roles(T, H, D), DEATHKNIGHT = Roles(T, D), WARLOCK = Roles(D), PALADIN = Roles(T, H, D) }
Filters.LUST, Filters.BREZ = LUST, BREZ  -- the leader view reads them too

local function All()
    ns.db.filters = ns.db.filters or {}
    return ns.db.filters
end

function Filters.Kind()
    local p = LFGListFrame and LFGListFrame.SearchPanel
    return (p and p.categoryID == 3) and "raid" or "keys"
end

-- The filter of a kind (the one in view by default), made on first use.
function Filters.Active(kind)
    kind = kind or Filters.Kind()
    for _, f in ipairs(All()) do if f.kind == kind then return f end end
    local f = CopyTable(DEFAULT[kind])
    table.insert(All(), f)
    return f
end

-- Back to its starting rules.
function Filters.Reset(f)
    local base = DEFAULT[f.kind] or DEFAULT.keys
    wipe(f)
    for k, v in pairs(CopyTable(base)) do f[k] = v end
    ns.Log.Emit("filter", { action = "reset", name = f.name })
end

-- A short line saying what the filter does, for the pane's top bar.
function Filters.Summary(f)
    local out = {}
    if f.kind == "raid" then
        local rules = 0
        for _, bosses in pairs(f.bosses or {}) do for _ in pairs(bosses) do rules = rules + 1 end end
        if rules > 0 then out[#out + 1] = rules .. (rules == 1 and " boss alive" or " bosses alive") end
        if next(f.lockout or {}) then out[#out + 1] = "loot left for me" end
    else
        local n = 0
        for _, on in pairs(f.dungeons or {}) do if on then n = n + 1 end end
        if f.dungeons and n < #Filters.Dungeons() then out[#out + 1] = n .. (n == 1 and " dungeon" or " dungeons") end
        if f.room then out[#out + 1] = "room for me" end
        if f.lust then out[#out + 1] = "has Bloodlust" end
        if f.brez then out[#out + 1] = "has battle rez" end
        if f.noMyClass then out[#out + 1] = "no other " .. (UnitClass("player") or "of my class") end
        if f.atLeastMine then out[#out + 1] = "score at least mine"
        elseif (f.minScore or 0) > 0 then out[#out + 1] = "score " .. f.minScore .. "+" end
    end
    if f.regions and ns.Groups.SUBREGIONS then
        local r = {}
        for _, code in ipairs(ns.Groups.REGIONS) do if f.regions[code] then r[#r + 1] = code end end
        out[#out + 1] = "realms " .. (#r > 0 and table.concat(r, " ") or "none")
    end
    return #out > 0 and table.concat(out, ", ") or "No rules"
end

-- This season's dungeons, as { name, code, best }, from the game.
function Filters.Dungeons()
    local out = {}
    for _, mapID in ipairs(C_ChallengeMode.GetMapTable() or {}) do
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        if name then
            -- The player's best in-time key there this season, if any.
            local timed = C_MythicPlus.GetSeasonBestForMap(mapID)
            out[#out + 1] = { name = name, code = ns.Groups.Code(name), best = timed and timed.level }
        end
    end
    table.sort(out, function(a, b) return a.code < b.code end)
    return out
end

-- My lockout (live, per raid): judged against each group at the group's
-- own difficulty, re-read every list. Hides groups with nothing left this
-- character can loot (every boss it hasn't killed is dead there); the rest
-- sort by how many of its kills the group has done too (Groups.List). A
-- group behind that may be skipping ahead, so behind only sorts lower.
local DIFF_ID = { [14] = "N", [15] = "H", [16] = "M" }

-- Bosses this character killed in a raid at a difficulty this week (names).
local function MyKills(raidName, diff)
    local killed = {}
    for i = 1, GetNumSavedInstances() do
        local name, _, _, diffID, locked, _, _, isRaid, _, _, count = GetSavedInstanceInfo(i)
        if isRaid and locked and name == raidName and DIFF_ID[diffID] == diff then
            for j = 1, count or 0 do
                local boss, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
                if boss and isKilled then killed[boss] = true end
            end
        end
    end
    return killed
end

-- Names the journal's boss list lacks would quietly break the match: log each once.
local unknown = {}
local function Unmatched(known, names, from)
    for boss in pairs(names) do
        if not known[boss] and not unknown[boss] then
            unknown[boss] = true
            ns.Trace("raid", from, "boss not in the journal list:", boss)
        end
    end
end

-- With My lockout on for the row's raid: how many of my kills the group has
-- also done, and whether a boss I can loot is still alive there. nil when
-- off (or the journal hasn't given the raid's bosses yet).
function Filters.Lockout(row)
    local f = Filters.Active("raid")
    if not (f.lockout and f.lockout[row.activity]) or #(row.bosses or {}) == 0 then return nil end
    local mine, known = MyKills(row.activity, row.difficulty), {}
    local caught, left = 0, false
    for _, boss in ipairs(row.bosses) do
        known[boss] = true
        if mine[boss] then
            if row.killed[boss] then caught = caught + 1 end
        elseif not row.killed[boss] then
            left = true
        end
    end
    Unmatched(known, mine, "lockout")
    Unmatched(known, row.killed, "listing")
    return caught, left
end

-- Blizzard's advanced filter narrows the search on the server (a search
-- returns at most 100 groups, so narrowing there matters). The active keys
-- filter drives it: dungeons, room for my role (only with one role picked),
-- score floor, no other of my class. Rewritten whenever Blizzard's differs
-- (its menu or its reset button), so ours wins. Bloodlust / battle rez have
-- no server field: local only.
local groupIDs  -- dungeon name -> activity group ID (current season)
local function GroupIDs()
    if groupIDs then return groupIDs end
    local out, n = {}, 0
    local flags = bit.bor(Enum.LFGListFilter.CurrentSeason, Enum.LFGListFilter.PvE)
    for _, id in ipairs(C_LFGList.GetAvailableActivityGroups(2, flags) or {}) do
        local name = C_LFGList.GetActivityGroupInfo(id)
        if name then out[name] = id; n = n + 1 end
    end
    if n > 0 then groupIDs = out end  -- not ready yet at login: try again later
    return out
end

local function SameSet(a, b)
    if #a ~= #b then return false end
    local seen = {}
    for _, v in ipairs(a) do seen[v] = true end
    for _, v in ipairs(b) do if not seen[v] then return false end end
    return true
end

function Filters.Sync()
    if Filters.Kind() ~= "keys" or not C_LFGList.SaveAdvancedFilter then return end
    local f = Filters.Active("keys")
    local ids, acts, all, missing = GroupIDs(), {}, {}, nil
    for _, d in ipairs(Filters.Dungeons()) do
        local id = ids[d.name]
        if id then all[#all + 1] = id else missing = d.name end
        if id and (not f.dungeons or f.dungeons[d.name]) then acts[#acts + 1] = id end
    end
    -- A dungeon we can't map would be dropped by the server: don't narrow.
    if missing then acts = all end
    local need
    if f.room then
        local r, n = ns.Groups.MyRoles(), 0
        for role, on in pairs(r) do if on then need, n = role, n + 1 end end
        if n ~= 1 then need = nil end
    end
    local rating = math.max(f.minScore or 0, f.atLeastMine and C_ChallengeMode.GetOverallDungeonScore() or 0)
    local mine = f.noMyClass == true
    local adv = C_LFGList.GetAdvancedFilter()
    if not adv then return end
    if SameSet(adv.activities or {}, acts) and adv.needsTank == (need == "TANK")
        and adv.needsHealer == (need == "HEALER") and adv.needsDamage == (need == "DAMAGER")
        and (adv.minimumRating or 0) == rating and (adv.needsMyClass == true) == mine then return end
    adv.activities = acts
    adv.needsTank, adv.needsHealer, adv.needsDamage = need == "TANK", need == "HEALER", need == "DAMAGER"
    adv.minimumRating = rating
    adv.needsMyClass = mine
    C_LFGList.SaveAdvancedFilter(adv)
    local key = table.concat(acts, ",") .. "|" .. tostring(need) .. "|" .. rating .. (mine and "|no other mine" or "")
    ns.Log.Emit("filter", { action = "blizzard filter", name = f.name .. ": " .. key
        .. (missing and (" (unmapped: " .. missing .. ")") or "") })
end

-- "Use Blizzard's group list instead": hand Blizzard's filter back clear of
-- what we wrote (every dungeon, no role / class / score narrowing), so
-- Blizzard's list isn't quietly narrowed by our filter. Its other settings
-- (playstyle, difficulty) were never ours and stay.
function Filters.RestoreBlizzard()
    local adv = C_LFGList.SaveAdvancedFilter and C_LFGList.GetAdvancedFilter()
    if not adv then return end
    local acts = {}
    for _, id in pairs(GroupIDs()) do acts[#acts + 1] = id end
    adv.activities = acts
    adv.needsTank, adv.needsHealer, adv.needsDamage, adv.needsMyClass = false, false, false, false
    adv.minimumRating = 0
    C_LFGList.SaveAdvancedFilter(adv)
    ns.Log.Emit("filter", { action = "blizzard filter cleared", name = #acts .. " dungeons" })
end

-- Does a row pass the active filter of its kind?
function Filters.Pass(row)
    local f = Filters.Active(row.isRaid and "raid" or "keys")
    if f.regions and row.region and not f.regions[row.region] then return false end
    -- Full raids delist themselves, so "room" only means something for keys.
    if f.room and not row.fits and not row.isRaid then return false end
    if row.isRaid then
        -- Raids aren't cleared in order: each ticked boss must be alive.
        for boss, on in pairs(f.bosses and f.bosses[row.activity] or {}) do
            if on and row.killed and row.killed[boss] then return false end
        end
        local caught, left = Filters.Lockout(row)
        return not caught or left
    end
    if f.dungeons and not f.dungeons[row.activity] then return false end
    if f.lust and not ns.Groups.CanHave(row, LUST) then return false end
    if f.brez and not ns.Groups.CanHave(row, BREZ) then return false end
    if f.noMyClass and row.classes and row.classes[select(2, UnitClass("player"))] then return false end
    local score = row.score or 0
    if (f.minScore or 0) > 0 and score < f.minScore then return false end
    if f.atLeastMine and score < (C_ChallengeMode.GetOverallDungeonScore() or 0) then return false end
    return true
end
