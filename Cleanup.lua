--[[
    PickupGroup - Cleanup.lua
    Clean-up: rules that hide listings, each an Options switch (on by
    default). Listing names can't be read, so every rule uses readable
    listing data. Our table filters its own copy; Blizzard's list is never
    rewritten.

      stale      listed longer than staleHours
      advert     dungeons: leader has no Mythic+ score and voice chat is filled in
      carry      the listing's playstyle offers a carry
      blacklist  the leader is on the blacklist (account-wide, name-realm),
                 or hidden for this session

    Blacklist entries remember when the leader was last seen in results;
    ones not seen for a year drop off.
--]]

local _, ns = ...

local Cleanup = {}
ns.Cleanup = Cleanup

local YEAR = 365 * 24 * 3600
local session = {}  -- leaders hidden until /reload

local function Settings() return ns.db.cleanup end

-- "Name" for a same-realm leader becomes "Name-Realm".
local function Full(name)
    if not name then return nil end
    if name:find("-", 1, true) then return name end
    local realm = GetNormalizedRealmName()
    return realm and (name .. "-" .. realm) or name
end

-- Why clean-up hides this row, or nil.
function Cleanup.Reason(row)
    local s = Settings()
    local leader = Full(row.leader)
    if leader and session[leader] then return "hidden for this session" end
    if s.blacklist and leader and ns.db.blacklist[leader] then
        ns.db.blacklist[leader] = time()  -- last seen
        return "leader is on your blacklist"
    end
    if s.stale and (row.age or 0) > (s.staleHours or 3) * 3600 then return "listed a long time" end
    if s.carry and row.playstyle == (Enum.LFGEntryGeneralPlaystyle and Enum.LFGEntryGeneralPlaystyle.Expert) then
        return "offers a carry"
    end
    if s.advert and not row.isRaid and (row.score or 0) == 0 and (row.voice or "") ~= "" then
        return "looks like an advert (no leader score, voice chat filled in)"
    end
end

function Cleanup.Blacklist(name, why)
    name = Full(name)
    if not name or ns.db.blacklist[name] then return end
    ns.db.blacklist[name] = time()
    ns.Log.Emit("blacklist", { name = name, why = why or "by hand" })
end

function Cleanup.HideForSession(name)
    name = Full(name)
    if name then session[name] = true end
end

function Cleanup.Count()
    local n = 0
    for _ in pairs(ns.db.blacklist) do n = n + 1 end
    return n
end

function Cleanup.Clear()
    wipe(ns.db.blacklist)
    ns.Log.Emit("blacklist", { name = "everyone", why = "cleared" })
end

-- Reporting a listing through Blizzard's own report form blacklists its leader.
if C_ReportSystem and C_ReportSystem.SendReport then
    hooksecurefunc(C_ReportSystem, "SendReport", function(info)
        local id = info and info.groupFinderSearchResultID
        if not id then return end
        local listing = C_LFGList.GetSearchResultInfo(id)
        if listing and listing.leaderName then Cleanup.Blacklist(listing.leaderName, "reported") end
        if ns.Pane then ns.Pane.Render() end
    end)
end

-- Housekeeping: drop leaders not seen for a year.
ns.On("PLAYER_LOGIN", function()
    local now = time()
    for name, seen in pairs(ns.db.blacklist) do
        if now - seen > YEAR then ns.db.blacklist[name] = nil end
    end
end)
