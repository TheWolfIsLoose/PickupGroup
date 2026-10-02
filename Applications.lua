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
            happened while the game was closed); then for a finished key:
            timed / depleted.
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
    return e
end

ns.On("LFG_LIST_APPLICATION_STATUS_UPDATED", function(id, new, old)
    -- A sign-up the game refuses at once goes straight to "failed".
    if not open[id] and (new == "applied" or ENDING[new]) then Start(id) end
    local e, result = open[id], ENDING[new]
    if not (e and result) then return end
    e.result, e.ended = result, time()
    open[id] = nil
    if ended then ended[Key(e.leader, e.activityID)] = e end
    ns.Log.Emit("app_end", { code = e.code, leader = e.leader, result = result })
end)

-- A finished key closes the last joined sign-up (secret values in the
-- completion info are skipped rather than stored).
ns.On("CHALLENGE_MODE_COMPLETED", function()
    local ok, info = pcall(C_ChallengeMode.GetChallengeCompletionInfo)
    if not (ok and type(info) == "table") then return end
    local list = List()
    for i = #list, 1, -1 do
        local e = list[i]
        if e.result == "joined" and time() - (e.ended or 0) < JOIN_WINDOW then
            local okTime, onTime = pcall(function() return info.onTime == true end)
            local okLevel, level = pcall(function() return tonumber(info.level) end)
            e.onTime = okTime and onTime or nil
            e.level = okLevel and level or nil
            if okTime then e.result = onTime and "timed" or "depleted" end
            ns.Log.Emit("app_end", { code = e.code, leader = e.leader, result = e.result, level = e.level })
            return
        end
        if time() - (e.ts or 0) > JOIN_WINDOW then return end
    end
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
-- JOIN_WINDOW), as its activity name; nil if none.
function Applications.LastJoined()
    local list = List()
    for i = #list, 1, -1 do
        local e = list[i]
        if e.result == "joined" and not e.isRaid and time() - (e.ended or 0) < JOIN_WINDOW then return e.activity end
        if time() - (e.ts or 0) > JOIN_WINDOW then return nil end
    end
end

-- ---------------------------------------------------------------------------
-- Leader-side probe (dev, temporary): what the game and Raider.IO let us read
-- about applicants, so the leader view is designed on facts. Logs each new
-- applicant once while leading a listing; `/pug applicants` logs them all.
-- ---------------------------------------------------------------------------
local function S(v)
    if issecretvalue and issecretvalue(v) then return "<secret>" end
    return tostring(v)
end
local probed = {}
local MEMBER = { "name", "class", "lclass", "level", "ilvl", "honor", "tank", "healer", "dps", "assigned",
    "relationship", "score", "pvpIlvl", "faction", "race", "spec" }

function Applications.ProbeApplicants(all)
    local entry = C_LFGList.GetActiveEntryInfo()
    if not entry then return ns.Print("Not leading a listing.") end
    local act = entry.activityIDs and entry.activityIDs[1] or entry.activityID
    local info = act and C_LFGList.GetActivityInfoTable(act) or {}
    local kind = info.isMythicPlusActivity and "keys" or (info.categoryID == 3 and "raid" or tostring(info.categoryID))
    local n = 0
    for _, id in ipairs(C_LFGList.GetApplicants() or {}) do
        if all or not probed[id] then
            probed[id] = true
            n = n + 1
            local ok, err = pcall(function()
                local a = C_LFGList.GetApplicantInfo(id) or {}
                local fields = {}
                for k, v in pairs(a) do fields[#fields + 1] = k .. "=" .. S(v) end
                ns.Trace("probe", "applicant", id, kind, S(info.fullName), table.concat(fields, " "))
                for m = 1, a.numMembers or 0 do
                    local v, parts = { C_LFGList.GetApplicantMemberInfo(id, m) }, {}
                    for i = 1, math.max(#v, #MEMBER) do parts[#parts + 1] = (MEMBER[i] or ("f" .. i)) .. "=" .. S(v[i]) end
                    ns.Trace("probe", "member", id, m, table.concat(parts, " "))
                    for _, call in ipairs({ "GetApplicantDungeonScoreForListing", "GetApplicantBestDungeonScore" }) do
                        if C_LFGList[call] then
                            local r = C_LFGList[call](id, m, act)
                            local rp = {}
                            if type(r) == "table" then for k, x in pairs(r) do rp[#rp + 1] = k .. "=" .. S(x) end else rp[1] = S(r) end
                            ns.Trace("probe", call, id, m, table.concat(rp, " "))
                        end
                    end
                    local name = v[1]
                    if RaiderIO and RaiderIO.GetProfile and type(name) == "string" and not issecretvalue(name) then
                        local p = RaiderIO.GetProfile(name)
                        local keys = {}
                        for k, x in pairs(p or {}) do keys[#keys + 1] = k .. ":" .. type(x) end
                        ns.Trace("probe", "raiderio", id, m, p and table.concat(keys, " ") or "no profile")
                        local mp = p and p.mythicKeystoneProfile
                        if type(mp) == "table" then
                            local f = {}
                            for k, x in pairs(mp) do if type(x) ~= "table" then f[#f + 1] = k .. "=" .. S(x) end end
                            ns.Trace("probe", "raiderio keys", id, m, table.concat(f, " "))
                        end
                        local rp = p and p.raidProfile
                        if type(rp) == "table" then
                            local f = {}
                            for k, x in pairs(rp) do f[#f + 1] = k .. ":" .. type(x) end
                            ns.Trace("probe", "raiderio raid", id, m, table.concat(f, " "))
                        end
                    end
                end
            end)
            if not ok then ns.LogError(err) end
        end
    end
    if all then ns.Print("Logged " .. n .. " applicants.") end
end
ns.On("LFG_LIST_APPLICANT_LIST_UPDATED", function() Applications.ProbeApplicants(false) end)
