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

local SEAT_ORDER = { "TANK", "HEALER", "DAMAGER", "DAMAGER", "DAMAGER" }
local DIFFICULTY = { [14] = "N", [15] = "H", [16] = "M", [17] = "LFR" }

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
local codes = {}
local function Code(name)
    if not codes[name] then
        local c = name:gsub("^[Tt]he%s+", ""):gsub("(%S)%S*%s*", "%1"):upper()
        codes[name] = c
    end
    return codes[name]
end

-- Bosses in a raid instance, from the Encounter Journal (no journal state
-- is changed: the instance is passed, never selected). Cached by map.
local bossCount, traced = {}, {}
local function TotalBosses(mapID)
    if not mapID then return nil end
    if mapID == 0 then return 1 end  -- world boss listings (map 0): one boss
    if bossCount[mapID] == nil then
        local n = 0
        local instance = C_EncounterJournal and C_EncounterJournal.GetInstanceForGameMap
            and C_EncounterJournal.GetInstanceForGameMap(mapID)
        if not (instance and instance > 0) and EJ_GetInstanceForMap then instance = EJ_GetInstanceForMap(mapID) end
        if instance and instance > 0 then
            while EJ_GetEncounterInfoByIndex(n + 1, instance) do n = n + 1 end
            -- Without the instance selected the journal answers nothing. Select
            -- it, count, and put the journal back (never while it's open).
            if n == 0 and not (EncounterJournal and EncounterJournal:IsShown()) then
                local before = EJ_GetCurrentInstance and EJ_GetCurrentInstance()
                -- Some instances the journal refuses to select (it throws).
                if pcall(EJ_SelectInstance, instance) then
                    while EJ_GetEncounterInfoByIndex(n + 1) do n = n + 1 end
                end
                if before and before > 0 then pcall(EJ_SelectInstance, before) end
            end
        end
        bossCount[mapID] = n > 0 and n or false
        ns.Trace("raid", "map", mapID, "journal instance", tostring(instance), "bosses", n)
    end
    return bossCount[mapID] or nil
end

-- The roles the player signs up as (Blizzard's own role choice).
function Groups.MyRoles()
    local _, tank, healer, dps = GetLFGRoles()
    return { TANK = tank, HEALER = healer, DAMAGER = dps }
end

local function Application(id)
    local _, status, pending, remaining = C_LFGList.GetApplicationInfo(id)
    return status, pending, remaining
end

function Groups.Read(id)
    local info = C_LFGList.GetSearchResultInfo(id)
    if not info or info.isDelisted then return nil end
    local activityID = info.activityIDs and info.activityIDs[1] or info.activityID
    local activity = activityID and C_LFGList.GetActivityInfoTable(activityID) or {}
    local isRaid = (activity.maxNumPlayers or 5) > 5
    local name = BaseName(activity.fullName)
    local counts = C_LFGList.GetSearchResultMemberCounts(id) or {}
    local mine = Groups.MyRoles()

    -- A raid only has to have room; a dungeon needs an open seat for a role
    -- the player signs up as.
    local fits = false
    if isRaid then
        fits = (info.numMembers or 0) < (activity.maxNumPlayers or 30)
    else
        for role, on in pairs(mine) do
            if on and (counts[role .. "_REMAINING"] or 0) > 0 then fits = true end
        end
    end

    local row = {
        id = id, name = info.name, leader = info.leaderName, comment = info.comment,
        score = info.leaderOverallDungeonScore, activity = name, code = Code(name),
        difficulty = DIFFICULTY[activity.difficultyID], isRaid = isRaid,
        age = info.age, members = info.numMembers, voice = info.voiceChat,
        friends = (info.numBNetFriends or 0) + (info.numCharFriends or 0) + (info.numGuildMates or 0),
        fits = fits,
    }
    row.status, row.pending, row.remaining = Application(id)
    if row.status == "none" then row.status = nil end

    if isRaid then
        row.counts = { TANK = counts.TANK or 0, HEALER = counts.HEALER or 0, DAMAGER = counts.DAMAGER or 0 }
        local killed = C_LFGList.GetSearchResultEncounterInfo(id)
        row.down, row.total = killed and #killed or 0, TotalBosses(activity.mapID)
        if not traced[id] then traced[id] = true; ns.Trace("raid", "result", id, "killed", killed and #killed or "nil") end
    else
        -- Seats in tank, healer, damage order; each member takes the first
        -- free seat of their role.
        local tiles = {}
        for i, role in ipairs(SEAT_ORDER) do tiles[i] = { role = role, mine = mine[role] } end
        row.specs = {}
        for m = 1, info.numMembers or 0 do
            local p = C_LFGList.GetSearchResultPlayerInfo(id, m)
            if p then
                for _, t in ipairs(tiles) do
                    if t.role == p.assignedRole and not t.filled then
                        t.filled, t.icon = true, SpecIcon(p.classFilename, p.specName)
                        break
                    end
                end
                row.specs[#row.specs + 1] = { spec = p.specName, class = p.className, file = p.classFilename }
            end
        end
        row.tiles = tiles
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

function Groups.List()
    local pinned, rows = {}, {}
    local _, results = C_LFGList.GetSearchResults()
    local seen = {}
    for _, id in ipairs(C_LFGList.GetApplications() or {}) do
        local row = SafeRead(id)
        if row and OUT[row.status] then pinned[#pinned + 1] = row; seen[id] = true end
    end
    for _, id in ipairs(results or {}) do
        if not seen[id] then
            local row = SafeRead(id)
            if row and (row.fits or row.status) then rows[#rows + 1] = row end
        end
    end
    table.sort(rows, function(a, b)
        if a.isRaid then
            if (a.down or 0) ~= (b.down or 0) then return (a.down or 0) < (b.down or 0) end
            return (a.age or 0) < (b.age or 0)
        end
        return (a.score or 0) > (b.score or 0)
    end)
    return pinned, rows
end
