--[[
    PickupGroup - Core.lua
    Namespace, saved data, one event frame that routes game events to the
    modules (handler errors go to the log), and the /pug slash command.
    Modules attach to the private namespace `ns`; nothing is global except
    the saved variables and the slash command.
--]]

local addonName, ns = ...

-- ---------------------------------------------------------------------------
-- Saved data. PickupGroupDB is account-wide; per-character data lives under
-- chars["Name-Realm"]. `schema` is the saved shape's version: bump it and add
-- one step to MIGRATIONS when the shape changes (never tied to the addon
-- version). New fields just go in DEFAULTS.
-- ---------------------------------------------------------------------------
local SCHEMA = 1
local DEFAULTS = {
    schema = SCHEMA,
    trace  = true,   -- record trace steps; on by default until v1.0.0
    log    = {},
    chars  = {},
    cleanup   = { stale = true, staleHours = 3, advert = true, carry = true, blacklist = true },
    blacklist = {},  -- "Name-Realm" -> last seen in results (time())
}
local MIGRATIONS = {}  -- [n] = function(db) upgrades schema n-1 to n

local function ApplyDefaults(saved, defaults)
    for k, v in pairs(defaults) do
        if saved[k] == nil then
            saved[k] = type(v) == "table" and CopyTable(v) or v
        elseif type(v) == "table" and type(saved[k]) == "table" then
            ApplyDefaults(saved[k], v)
        end
    end
end

local function InitDB()
    PickupGroupDB = PickupGroupDB or {}
    local db = PickupGroupDB
    for n = (db.schema or SCHEMA) + 1, SCHEMA do MIGRATIONS[n](db) end
    ApplyDefaults(db, DEFAULTS)
    db.schema = SCHEMA
    ns.db = db
end

-- This character's saved table, created on first use.
function ns.CharDB()
    local key = UnitName("player") .. "-" .. GetRealmName()
    ns.db.chars[key] = ns.db.chars[key] or {}
    return ns.db.chars[key]
end

function ns.Version()
    return C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
end

function ns.Print(msg)
    print("|cff98ff98PickupGroup|r: " .. tostring(msg))
end

-- ---------------------------------------------------------------------------
-- Events. ns.On(event, fn) registers one handler per event.
-- ---------------------------------------------------------------------------
local function LogError(err)
    if ns.db then
        local stack = debugstack(2, 3, 0):gsub("\n", " | "):sub(1, 400)
        ns.Log.Emit("error", { msg = tostring(err), stack = stack })
    end
    geterrorhandler()(err)
end
ns.LogError = LogError

-- Several modules may listen to one event; each handler runs on its own, so
-- one error doesn't stop the others.
local handlers = {}
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    local args, n = { ... }, select("#", ...)
    for _, fn in ipairs(handlers[event]) do
        xpcall(function() fn(unpack(args, 1, n)) end, LogError)
    end
end)
function ns.On(event, fn)
    handlers[event] = handlers[event] or {}
    table.insert(handlers[event], fn)
    eventFrame:RegisterEvent(event)
end

ns.On("ADDON_LOADED", function(name)
    if name ~= addonName then return end
    eventFrame:UnregisterEvent("ADDON_LOADED")
    InitDB()

    -- One line per version change, so a report shows when an update landed.
    local version = ns.Version()
    if ns.db.lastVersion ~= version then
        ns.Log.Emit("version", { from = ns.db.lastVersion, to = version })
        ns.db.lastVersion = version
    end

    SLASH_PICKUPGROUP1, SLASH_PICKUPGROUP2 = "/pug", "/pickupgroup"
    SlashCmdList.PICKUPGROUP = function(msg) ns.OnSlash(msg) end
end)

-- A protected call our code made that the game refused (taint).
local function Blocked(who, func)
    if who == addonName then ns.Log.Emit("blocked", { func = func }) end
end
ns.On("ADDON_ACTION_BLOCKED", Blocked)
ns.On("ADDON_ACTION_FORBIDDEN", Blocked)

-- ---------------------------------------------------------------------------
-- /pug
-- ---------------------------------------------------------------------------
local HELP = {
    "commands:",
    "  /pug log |cff888888- open the log to copy into a bug report|r",
    "  /pug log clear |cff888888- empty the log|r",
    "  /pug debug |cff888888- switch detailed recording on or off|r",
}

function ns.OnSlash(msg)
    local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd, rest = cmd:lower(), rest:lower()
    if cmd == "log" and rest == "clear" then
        ns.Log.Clear()
        ns.Print("Log cleared.")
    elseif cmd == "log" then
        ns.LogPopup.Toggle()
    elseif cmd == "probe" then
        -- Temporary (dev only): every readable field of the first listings,
        -- to look for a key level. Remove once read.
        local function S(v) local ok, r = pcall(tostring, v); return ok and r or "<unreadable>" end
        local out = {}
        local _, ids = C_LFGList.GetSearchResults()
        for i = 1, math.min(#(ids or {}), 8) do
            local lines = {}
            local ok, err = pcall(function()
                local info = C_LFGList.GetSearchResultInfo(ids[i]) or {}
                for k, v in pairs(info) do
                    if type(v) == "table" then
                        for k2, v2 in pairs(v) do lines[#lines + 1] = S(k) .. "." .. S(k2) .. " = " .. S(v2) end
                    else lines[#lines + 1] = S(k) .. " = " .. S(v) end
                end
                local act = info.activityIDs and info.activityIDs[1] or info.activityID
                for k, v in pairs(act and C_LFGList.GetActivityInfoTable(act) or {}) do
                    lines[#lines + 1] = "activity." .. S(k) .. " = " .. S(v)
                end
            end)
            if not ok then lines[#lines + 1] = "error: " .. S(err) end
            table.sort(lines)
            out[i] = lines
        end
        ns.db.probe = out
        ns.Print(("Probe: %d listings saved. /reload and say done."):format(#out))
    elseif cmd == "debug" then
        ns.db.trace = not ns.db.trace
        ns.Log.Emit("setting", { key = "trace", on = ns.db.trace })
        ns.Print("Detailed recording " .. (ns.db.trace and "|cff98ff98on|r." or "off."))
    else
        for _, line in ipairs(HELP) do ns.Print(line) end
    end
end
