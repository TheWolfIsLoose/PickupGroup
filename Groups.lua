--[[
    PickupGroup - Groups.lua
    The search results as plain rows for the pane. Reads WoW's Group Finder
    data; draws nothing.

    Row: { id, name (protected string: display only), leader, score,
           activity (full name), code (short), difficulty, isRaid,
           tiles (dungeons: 5 x { icon? , role, mine }),
           counts (raids: { TANK, HEALER, DAMAGER }), down, total,
           age, fits, status, pending, remaining }
--]]

local _, ns = ...

local Groups = {}
ns.Groups = Groups

-- Raids Blizzard still lists under the current expansion but that belong to
-- a past season: left out of results and the boss list.
-- ponytail: a named list to edit each season; derive it from the journal if
-- that grows tedious.
local PAST_RAIDS = { ["March on Quel'Danas"] = true, ["Sporefall"] = true }

local SEAT_ORDER = { "TANK", "HEALER", "DAMAGER", "DAMAGER", "DAMAGER" }
local DIFFICULTY = { [14] = "N", [15] = "H", [16] = "M", [17] = "LFR" }

-- Realm regions within the Americas game region: every realm is North
-- America except these. Keys are realm names squeezed (no spaces, hyphens or
-- apostrophes, lower case) so any spelling of the name matches.
Groups.REGIONS = { "NA", "OCE", "BR", "LAT" }
Groups.REGION_NAME = { NA = "North America", OCE = "Oceanic", BR = "Brazil", LAT = "Latin America" }
local REALM_REGION = {}
for region, realms in pairs({
    OCE = { "Aman'Thul", "Barthilas", "Caelestrasz", "Dath'Remar", "Dreadmaul", "Frostmourne",
            "Gundrak", "Jubei'Thos", "Khaz'goroth", "Nagrand", "Saurfang", "Thaurissan" },
    BR = { "Azralon", "Gallywix", "Goldrinn", "Nemesis", "Tol Barad" },
    LAT = { "Drakkari", "Quel'Thalas", "Ragnaros" },
}) do
    for _, r in ipairs(realms) do REALM_REGION[r:gsub("[%s%-']", ""):lower()] = region end
end

-- A leader's realm region from "Name-Realm" (no realm: the player's own).
function Groups.Region(leader)
    if type(leader) ~= "string" then return nil end
    local realm = leader:match("^[^%-]+%-(.+)$") or GetRealmName() or ""
    return REALM_REGION[realm:gsub("[%s%-']", ""):lower()] or "NA"
end

-- Spec icons by class file and (localized) spec name, built once.
local specIcons
local function SpecIcon(classFile, specName)
    if not specIcons then
        specIcons = {}
        for classID = 1, GetNumClasses() do
            local _, file = GetClassInfo(classID)
            if file then
                specIcons[file] = {}
                for i = 1, GetNumSpecializationsForClassID(classID) do
                    local _, name, _, icon = GetSpecializationInfoForClassID(classID, i)
                    if name then specIcons[file][name] = icon end
                end
            end
        end
    end
    return classFile and specName and specIcons[classFile] and specIcons[classFile][specName]
end

-- "Altar of Fangs (Mythic Keystone)" -> "Altar of Fangs"; code "AOF".
-- A leading "The" is dropped from the code ("The Venomous Abyss" -> "VA").
local function BaseName(full)
    return (full or "?"):gsub("%s*%(.-%)%s*$", "")
end
Groups.BaseName = BaseName
local codes = {}
local function Code(name)
    if not codes[name] then
        local c = name:gsub("^[Tt]he%s+", ""):gsub("(%S)%S*%s*", "%1"):upper()
        codes[name] = c
    end
    return codes[name]
end
Groups.Code = Code

-- Bosses in a raid instance, from the Encounter Journal, cached by map.
-- bossNames[map] lists them in journal order; raids[raid name] = map for
-- every raid seen in results (the sidecar's per-boss rules list these).
local bossCount, bossNames, raids = {}, {}, {}
local function TotalBosses(mapID)
    if not mapID then return nil end
    if mapID == 0 then return 1 end  -- world boss listings (map 0): one boss
    if bossCount[mapID] == nil then
        local n, names = 0, {}
        local instance = C_EncounterJournal and C_EncounterJournal.GetInstanceForGameMap
            and C_EncounterJournal.GetInstanceForGameMap(mapID)
        if not (instance and instance > 0) and EJ_GetInstanceForMap then instance = EJ_GetInstanceForMap(mapID) end
        if instance and instance > 0 then
            while true do
                local name = EJ_GetEncounterInfoByIndex(n + 1, instance)
                if not name then break end
                n = n + 1; names[n] = name
            end
            -- Without the instance selected the journal answers nothing. Select
            -- it, count, and put the journal back (never while it's open).
            if n == 0 and not (EncounterJournal and EncounterJournal:IsShown()) then
                local before = EJ_GetCurrentInstance and EJ_GetCurrentInstance()
                -- Some instances the journal refuses to select (it throws).
                if pcall(EJ_SelectInstance, instance) then
                    while true do
                        local name = EJ_GetEncounterInfoByIndex(n + 1)
                        if not name then break end
                        n = n + 1; names[n] = name
                    end
                end
                if before and before > 0 then pcall(EJ_SelectInstance, before) end
            end
        end
        bossCount[mapID], bossNames[mapID] = n > 0 and n or false, names
        ns.Trace("raid", "map", mapID, "journal instance", tostring(instance), "bosses", n)
    end
    return bossCount[mapID] or nil
end

-- Raids seen in results, each { name, bosses = { names in journal order } }.
function Groups.Raids()
    local out = {}
    for name, mapID in pairs(raids) do
        if bossNames[mapID] and #bossNames[mapID] > 0 then out[#out + 1] = { name = name, bosses = bossNames[mapID] } end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- The roles the player signs up as (Blizzard's own role choice).
function Groups.MyRoles()
    local _, tank, healer, dps = GetLFGRoles()
    return { TANK = tank, HEALER = healer, DAMAGER = dps }
end

-- In a party (not a raid): seats needed per role, from each member's
-- assigned role, else their spec's role, else unknown (any seat); the
-- player falls back to a single role picked in Blizzard's role choice.
-- nil when solo.
local lastParty
function Groups.Party()
    if not IsInGroup() or IsInRaid() then return nil end
    local need = { TANK = 0, HEALER = 0, DAMAGER = 0, size = 0, classes = {} }
    local seen = {}
    for _, unit in ipairs({ "player", "party1", "party2", "party3", "party4" }) do
        if UnitExists(unit) then
            need.size = need.size + 1
            need.classes[select(2, UnitClass(unit)) or "?"] = true
            local role = UnitGroupRolesAssigned(unit)
            if role == "NONE" and unit ~= "player" then
                local spec = GetInspectSpecialization(unit)
                role = spec and spec > 0 and GetSpecializationRoleByID(spec) or "NONE"
            elseif role == "NONE" then
                local r, n = Groups.MyRoles(), 0
                for k, on in pairs(r) do if on then role, n = k, n + 1 end end
                if n ~= 1 then role = "NONE" end
            end
            if need[role] then need[role] = need[role] + 1 end
            seen[#seen + 1] = unit .. "=" .. role
        end
    end
    local key = table.concat(seen, " ")
    if key ~= lastParty then lastParty = key; ns.Trace("groups", "party roles:", key) end
    return need
end

-- Seats the player (or the party) takes: per known role, plus "flex" for
-- members whose role is unknown (or a solo player with several roles).
function Groups.Need()
    local need = Groups.Party()
    if not need then
        need = { TANK = 0, HEALER = 0, DAMAGER = 0, size = 1, classes = { [select(2, UnitClass("player"))] = true } }
        local r, n, role = Groups.MyRoles(), 0, nil
        for k, on in pairs(r) do if on then role, n = k, n + 1 end end
        if n == 1 then need[role] = 1 end
    end
    need.flex = need.size - need.TANK - need.HEALER - need.DAMAGER
    return need
end

-- Can the group end up with a class from `set` (class file -> roles it can
-- fill)? Yes if (1) the group has one; or, with room for the player's party,
-- (2) the party brings one, or (3) after the party sits down a seat is left
-- that such a class can fill (unknown roles take the other seats first).
function Groups.CanHave(row, set)
    for file in pairs(row.classes or {}) do if set[file] then return true end end
    if not row.fits or not row.left then return false end
    local need = Groups.Need()
    for file in pairs(need.classes) do if set[file] then return true end end
    local buffRoles = {}
    for _, roles in pairs(set) do for r in pairs(roles) do buffRoles[r] = true end end
    local buffSeats, otherSeats = 0, 0
    for _, r in ipairs({ "TANK", "HEALER", "DAMAGER" }) do
        local left = math.max(0, row.left[r] - need[r])
        if buffRoles[r] then buffSeats = buffSeats + left else otherSeats = otherSeats + left end
    end
    return buffSeats - math.max(0, need.flex - otherSeats) >= 1
end

local function Application(id)
    local _, status, pending, remaining = C_LFGList.GetApplicationInfo(id)
    return status, pending, remaining
end

function Groups.Read(id)
    local info = C_LFGList.GetSearchResultInfo(id)
    -- In a running key (and other restricted content) listings are secret:
    -- untestable, so skip them rather than error once per listing.
    if not info then return nil end
    if issecretvalue(info.isDelisted) then
        -- In a running key: count it, so the log shows the guard at work.
        Groups.secretSkips = (Groups.secretSkips or 0) + 1
        if Groups.secretSkips == 1 or Groups.secretSkips % 100 == 0 then
            ns.Trace("groups", "secret listing skipped (restricted content), total", Groups.secretSkips)
        end
        return nil
    end
    if info.isDelisted then return nil end
    local activityID = info.activityIDs and info.activityIDs[1] or info.activityID
    local activity = activityID and C_LFGList.GetActivityInfoTable(activityID) or {}
    local isRaid = (activity.maxNumPlayers or 5) > 5
    local name = BaseName(activity.fullName)
    if isRaid and PAST_RAIDS[name] then return nil end
    local counts = C_LFGList.GetSearchResultMemberCounts(id) or {}
    local mine = Groups.MyRoles()

    -- A raid only has to have room; a dungeon needs an open seat for a role
    -- the player signs up as.
    local fits = false
    if isRaid then
        fits = (info.numMembers or 0) < (activity.maxNumPlayers or 30)
    else
        local party = Groups.Party()
        if party then
            -- Room for the whole party: every known role has its seats, and
            -- enough seats are open for everyone.
            local open = 0
            fits = true
            for _, role in ipairs({ "TANK", "HEALER", "DAMAGER" }) do
                local left = counts[role .. "_REMAINING"] or 0
                open = open + left
                if party[role] > left then fits = false end
            end
            if open < party.size then fits = false end
        else
            for role, on in pairs(mine) do
                if on and (counts[role .. "_REMAINING"] or 0) > 0 then fits = true end
            end
        end
    end

    local row = {
        id = id, name = info.name, leader = info.leaderName, comment = info.comment,
        region = Groups.Region(info.leaderName),
        score = info.leaderOverallDungeonScore, activity = name, code = Code(name),
        difficulty = DIFFICULTY[activity.difficultyID], isRaid = isRaid,
        age = info.age, members = info.numMembers, voice = info.voiceChat, playstyle = info.generalPlaystyle,
        friends = (info.numBNetFriends or 0) + (info.numCharFriends or 0), guild = info.numGuildMates or 0,
        fits = fits,
    }
    row.status, row.pending, row.remaining = Application(id)
    if row.status == "none" then
        -- WoW forgets an ended sign-up once a search re-issues the listing.
        row.status = ns.Applications and ns.Applications.LastEnding(info.leaderName, activityID) or nil
    end

    if isRaid then
        row.counts = { TANK = counts.TANK or 0, HEALER = counts.HEALER or 0, DAMAGER = counts.DAMAGER or 0 }
        local killed = C_LFGList.GetSearchResultEncounterInfo(id)
        row.down, row.total = killed and #killed or 0, TotalBosses(activity.mapID)
        row.bosses = bossNames[activity.mapID] or {}  -- journal order, for the tooltip
        row.killed = {}
        for _, boss in ipairs(killed or {}) do row.killed[boss] = true end
        if activity.mapID and activity.mapID ~= 0 then raids[name] = activity.mapID end
    else
        -- Seats in tank, healer, damage order; each member takes the first
        -- free seat of their role.
        local tiles = {}
        for i, role in ipairs(SEAT_ORDER) do tiles[i] = { role = role, mine = mine[role] } end
        row.specs, row.classes = {}, {}
        for m = 1, info.numMembers or 0 do
            local p = C_LFGList.GetSearchResultPlayerInfo(id, m)
            if p then
                for _, t in ipairs(tiles) do
                    if t.role == p.assignedRole and not t.filled then
                        t.filled, t.icon = true, SpecIcon(p.classFilename, p.specName)
                        break
                    end
                end
                row.specs[#row.specs + 1] = { spec = p.specName, class = p.className, file = p.classFilename,
                    icon = SpecIcon(p.classFilename, p.specName) }
                if p.classFilename then row.classes[p.classFilename] = true end
            end
        end
        row.tiles = tiles
        row.left = { TANK = counts.TANK_REMAINING or 0, HEALER = counts.HEALER_REMAINING or 0,
                     DAMAGER = counts.DAMAGER_REMAINING or 0 }
    end
    return row
end

-- Status words WoW uses for an application that is still out.
local OUT = { applied = true, invited = true }
Groups.OUT = OUT

-- pinned: the player's sign-ups; rows: everything else that passes, by
-- leader score (raids: bosses down, then age).
-- A listing that errors is left out and logged once, never the whole list.
local failed = {}
local function SafeRead(id)
    local ok, row = pcall(Groups.Read, id)
    if ok then return row end
    if not failed[id] then failed[id] = true; ns.LogError(row) end
end

-- showHidden: only the rows clean-up hid (with row.hidden = why).
-- Returns pinned, rows, and how many rows clean-up hid.
function Groups.List(showHidden)
    local pinned, rows, hidden = {}, {}, 0
    local _, results = C_LFGList.GetSearchResults()
    local seen = {}
    for _, id in ipairs(C_LFGList.GetApplications() or {}) do
        local row = SafeRead(id)
        if row and OUT[row.status] then pinned[#pinned + 1] = row; seen[id] = true end
    end
    for _, id in ipairs(results or {}) do
        if not seen[id] then
            local row = SafeRead(id)
            if row and (row.status or ns.Filters.Pass(row)) then
                row.hidden = ns.Cleanup.Reason(row)
                if row.hidden then hidden = hidden + 1 end
                if (row.hidden ~= nil) == (showHidden == true) then rows[#rows + 1] = row end
            end
        end
    end
    table.sort(rows, function(a, b)
        -- Must agree whichever row comes first, or table.sort breaks: a
        -- raid category can return a non-raid listing. Raids go first.
        if a.isRaid ~= b.isRaid then return a.isRaid == true end
        if a.isRaid then
            if (a.down or 0) ~= (b.down or 0) then return (a.down or 0) < (b.down or 0) end
            return (a.age or 0) < (b.age or 0)
        end
        return (a.score or 0) > (b.score or 0)
    end)
    return pinned, rows, hidden
end
