--[[
    PickupGroup - Applications.lua
    The application log: every sign-up this character sends, and how it
    ended. Data only for now (history views come later). Stored per
    character in PickupGroupDB.chars["Name-Realm"].apps, so the account view
    is every character's list together.

    Entry: { ts, code, activity, activityID, leader, isRaid, difficulty,
             roles ("T", "H", "D" joined), result, ended, level, onTime }
    result: pending, declined, filled (group full), delisted, withdrawn,
            timedout, invitedeclined, failed, joined; then for a finished
            key: timed / depleted.
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

-- ponytail: open sign-ups live only for the session; one still out at a
-- /reload stays "pending". Rebuild from C_LFGList.GetApplications() at login
-- if the log shows many stuck pending.
local open = {}  -- result ID -> entry

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
