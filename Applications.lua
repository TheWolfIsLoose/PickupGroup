--[[
    PickupGroup - Applications.lua
    The application log: every sign-up this character sends, and how it
    ended. Data only for now (history views come later). Stored per
    character in PickupGroupDB.chars["Name-Realm"].apps, so the account view
    is every character's list together.

    Entry: { ts, code, activity, activityID, leader, isRaid, difficulty,
             roles ("T", "H", "D" joined), result, ended, level, onTime }
    result: pending, declined, filled (group full), delisted, withdrawn,
            timedout, invitedeclined, failed, joined, unknown (the ending
            happened while the game was closed), movedon (withdrawn by the game
            because the player got into another group); then for a key:
            timed / depleted / abandoned (vote to abandon passed).
--]]

local _, ns = ...

local Applications = {}
ns.Applications = Applications

local MAX = 1000
local JOIN_WINDOW = 3 * 3600  -- a finished key belongs to the last group joined within this

-- WoW's status words to ours; statuses not listed are not an ending.
local ENDING = {
    declined = "declined", declined_full = "filled", declined_delisted = "delisted",
    cancelled = "withdrawn", timedout = "timedout", invitedeclined = "invitedeclined",
    failed = "failed", inviteaccepted = "joined",
}

local open = {}  -- result ID -> entry (rebuilt after a /reload, see Reattach)

-- A group is known by leader and activity: a new search gives the same
-- listing a new result ID, and WoW then forgets the sign-up's ending.
local ended   -- key -> latest ended entry (built from the saved list once)
local function Key(leader, activityID) return tostring(leader) .. "|" .. tostring(activityID) end
local REMEMBER = 3600
local BACK_TO_WOW = {
    declined = "declined", filled = "declined_full", delisted = "declined_delisted", withdrawn = "cancelled",
    timedout = "timedout", invitedeclined = "invitedeclined", failed = "failed",
}

local function List()
    local c = ns.CharDB()
    c.apps = c.apps or {}
    return c.apps
end

-- How this player's last sign-up to the group ended, as WoW's status word,
-- if it ended within the hour; nil otherwise.
function Applications.LastEnding(leader, activityID)
    if not ended then
        ended = {}
        for _, e in ipairs(List()) do
            if e.ended then ended[Key(e.leader, e.activityID)] = e end
        end
    end
    local e = ended[Key(leader, activityID)]
    if e and time() - e.ended < REMEMBER then return BACK_TO_WOW[e.result] end
end

local function RoleText()
    local r, out = ns.Groups.MyRoles(), {}
    if r.TANK then out[#out + 1] = "T" end
    if r.HEALER then out[#out + 1] = "H" end
    if r.DAMAGER then out[#out + 1] = "D" end
    return table.concat(out)
end

-- Lifetime counts per character (c.tally): never trimmed, unlike the
-- 1000-entry list, so "declined 2,417 times" stays true. Seeded once from
-- the list. Keys: applied, joined, timed, depleted and each ending word.
local function Seed(c)
    local t = { applied = #(c.apps or {}) }
    for _, e in ipairs(c.apps or {}) do
        local r = e.result
        if r == "timed" or r == "depleted" or r == "abandoned" then t.joined = (t.joined or 0) + 1 end
        if r and r ~= "pending" then t[r] = (t[r] or 0) + 1 end
    end
    return t
end

function Applications.Lifetime(c)
    c = c or ns.CharDB()
    c.tally = c.tally or Seed(c)
    return c.tally
end

local function Bump(key)
    local t = Applications.Lifetime()
    t[key] = (t[key] or 0) + 1
end
-- Seed before any sign-up event can count twice.
ns.On("PLAYER_LOGIN", function() Applications.Lifetime() end)

local function Start(id)
    local row = ns.Groups.Read(id)
    local info = C_LFGList.GetSearchResultInfo(id)
    local e = {
        ts = time(), result = "pending", roles = RoleText(),
        code = row and row.code, activity = row and row.activity, leader = row and row.leader,
        isRaid = row and row.isRaid, difficulty = row and row.difficulty,
        activityID = info and (info.activityIDs and info.activityIDs[1] or info.activityID),
    }
    local list = List()
    list[#list + 1] = e
    -- ponytail: table.remove(t, 1) shifts the list; fine at 1000 entries.
    while #list > MAX do table.remove(list, 1) end
    open[id] = e
    Bump("applied")
    return e
end

-- Getting into a group makes the game withdraw every other sign-up, in the
-- same second or so, before or after the join: those "moved on", they
-- weren't cold feet.
local MOVED = 5
local lastJoin = 0
local function MovedOn(e)
    local t = Applications.Lifetime()
    t.withdrawn = math.max(0, (t.withdrawn or 1) - 1)
    t.movedon = (t.movedon or 0) + 1
    e.result = "movedon"
end

ns.On("LFG_LIST_APPLICATION_STATUS_UPDATED", function(id, new, old)
    -- A sign-up the game refuses at once goes straight to "failed".
    if not open[id] and (new == "applied" or ENDING[new]) then Start(id) end
    local e, result = open[id], ENDING[new]
    if not (e and result) then return end
    local now = time()
    if result == "withdrawn" and now - lastJoin <= MOVED then result = "movedon" end
    e.result, e.ended = result, now
    open[id] = nil
    Bump(result)
    if result == "joined" then
        lastJoin = now
        local list = List()
        for i = #list, math.max(1, #list - 10), -1 do
            local x = list[i]
            if x.result == "withdrawn" and x.ended and now - x.ended <= MOVED then MovedOn(x) end
        end
    end
    if ended then ended[Key(e.leader, e.activityID)] = e end
    ns.Log.Emit("app_end", { code = e.code, leader = e.leader, result = result })
end)

-- The sign-up that got the player into the current group, if recent.
local function JoinedEntry()
    local list = List()
    for i = #list, 1, -1 do
        local e = list[i]
        if e.result == "joined" and time() - (e.ended or 0) < JOIN_WINDOW then return e end
        if time() - (e.ts or 0) > JOIN_WINDOW then return end
    end
end

local function KeyEnded(e, result, level)
    e.result, e.level = result, level or e.level
    Bump(result)
    ns.Log.Emit("app_end", { code = e.code, leader = e.leader, result = result, level = e.level })
end

-- A finished key closes the last joined sign-up (secret values in the
-- completion info are skipped rather than stored).
ns.On("CHALLENGE_MODE_COMPLETED", function()
    local ok, info = pcall(C_ChallengeMode.GetChallengeCompletionInfo)
    if not (ok and type(info) == "table") then return end
    local e = JoinedEntry()
    if not e then return end
    local okTime, onTime = pcall(function() return info.onTime == true end)
    local okLevel, level = pcall(function() return tonumber(info.level) end)
    e.onTime = okTime and onTime or nil
    if okTime then KeyEnded(e, onTime and "timed" or "depleted", okLevel and level or nil) end
end)

-- A passed vote to abandon ends the key without a deplete (the owner's key
-- only drops when it isn't resilient at that level, which we can't see).
ns.On("INSTANCE_ABANDON_VOTE_FINISHED", function(passed)
    if not passed then return end
    local ok, level = pcall(function() return (C_ChallengeMode.GetActiveKeystoneInfo()) end)
    level = ok and tonumber(level) or 0
    local e = level > 0 and JoinedEntry()
    if e then KeyEnded(e, "abandoned", level) end
end)

-- After a login or /reload: sign-ups still out pick their entries back up
-- (by leader and activity), so their endings get logged; pending entries
-- with no sign-up left ended unseen. Sign-ups expire within minutes, so
-- only entries older than STALE are closed.
local STALE = 600
local function Reattach()
    local out = {}
    for _, id in ipairs(C_LFGList.GetApplications() or {}) do
        local _, status = C_LFGList.GetApplicationInfo(id)
        local info = C_LFGList.GetSearchResultInfo(id)
        if info and not issecretvalue(info.leaderName) and (status == "applied" or status == "invited") then
            out[Key(info.leaderName, info.activityIDs and info.activityIDs[1] or info.activityID)] = id
        end
    end
    local n, closed = 0, 0
    for _, e in ipairs(List()) do
        if e.result == "pending" then
            local id = out[Key(e.leader, e.activityID)]
            if id and not open[id] then open[id] = e; n = n + 1
            elseif not id and time() - (e.ts or 0) > STALE then e.result, e.ended = "unknown", time(); closed = closed + 1 end
        end
    end
    if n + closed > 0 then ns.Trace("apply", "reattached", n, "closed unseen", closed) end
end

-- Also fires entering instances, where listings can be secret: errors are logged.
ns.On("PLAYER_ENTERING_WORLD", function()
    C_Timer.After(5, function()
        local ok, err = pcall(Reattach)
        if not ok then ns.LogError(err) end
    end)
end)

-- The dungeon of the group most recently joined through a sign-up (within
-- JOIN_WINDOW), as its activity name, while its leader is still in the
-- player's group; nil otherwise (tester: a party joined another way got the
-- earlier sign-up's teleport).
function Applications.LastJoined()
    local list = List()
    for i = #list, 1, -1 do
        local e = list[i]
        if e.result == "joined" and not e.isRaid and time() - (e.ended or 0) < JOIN_WINDOW then
            return e.leader and UnitInParty(Ambiguate(e.leader, "none")) and e.activity or nil
        end
        if time() - (e.ts or 0) > JOIN_WINDOW then return nil end
    end
end

-- Fill chime: the party a sign-up got the player into reaches five. On unless
-- Options turns it off. Checked a beat later, as the join's status can land
-- after the roster. Raids have no "full" to hear (see ROADMAP).
local CHIME = "Interface\\AddOns\\PickupGroup\\Media\\TheCyclist.ogg"
local lastCount  -- nil until the first roster after login, so a /reload in a full party stays quiet
ns.On("GROUP_ROSTER_UPDATE", function()
    local n = IsInRaid() and 0 or GetNumGroupMembers()
    local filled = lastCount and lastCount < 5 and n == 5
    lastCount = n
    if not filled or ns.db.noChime then return end
    C_Timer.After(1, function()
        local dungeon = GetNumGroupMembers() == 5 and not IsInRaid() and Applications.LastJoined()
        if not dungeon then return end
        PlaySoundFile(CHIME, "Master")
        ns.Trace("chime", "group filled", dungeon)
    end)
end)
