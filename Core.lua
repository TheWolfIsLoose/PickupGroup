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
local SCHEMA = 6
local DEFAULTS = {
    schema = SCHEMA,
    trace  = false,  -- detailed trace steps; /pug debug switches them on
    log    = {},
    chars  = {},
    cleanup   = { stale = true, staleHours = 3, advert = true, carry = true, blacklist = true },
    blacklist = {},  -- "Name-Realm" -> last seen in results (time())
}
local MIGRATIONS = {  -- [n] = function(db) upgrades schema n-1 to n
    -- 2: one filter per kind; keep the one that was active.
    [2] = function(db)
        if not db.filters then return end
        local keep, active = {}, db.activeFilter or {}
        for _, kind in ipairs({ "keys", "raid" }) do
            local pick
            for _, f in ipairs(db.filters) do
                if f.kind == kind and (f.id == active[kind] or not pick) then pick = f end
            end
            if pick then keep[#keep + 1] = pick end
        end
        db.filters, db.activeFilter = keep, nil
    end,
    -- 3: Bloodlust / battle rez are one "has it" switch each.
    [3] = function(db)
        for _, f in ipairs(db.filters or {}) do
            f.lust = f.lust == "has" or nil
            f.brez = f.brez == "has" or nil
            f.text = nil  -- leftover from 0.3.4's saved search text
        end
    end,
    -- 6: v1.0.0: detailed recording starts off for everyone (it was on by
    -- default while testing); /pug debug turns it back on.
    [6] = function(db) db.trace = false end,
    -- 5: sign-ups the game withdrew because the player got in elsewhere
    -- (within 5 s of a join) are "movedon"; lifetime counts re-seed.
    [5] = function(db)
        for _, c in pairs(db.chars or {}) do
            local joins = {}
            for _, e in ipairs(c.apps or {}) do
                if (e.result == "joined" or e.result == "timed" or e.result == "depleted") and e.ended then joins[#joins + 1] = e.ended end
            end
            for _, e in ipairs(c.apps or {}) do
                if e.result == "withdrawn" and e.ended then
                    for _, j in ipairs(joins) do
                        if math.abs(e.ended - j) <= 5 then e.result = "movedon"; break end
                    end
                end
            end
            c.tally = nil
        end
    end,
    -- 4: boss rules are "must be alive" (true) or nothing.
    [4] = function(db)
        for _, f in ipairs(db.filters or {}) do
            for _, bosses in pairs(f.bosses or {}) do
                for boss, want in pairs(bosses) do bosses[boss] = (want == "alive") or nil end
            end
        end
    end,
}

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

-- Sign-up notes: up to MAX, account-wide, by slot (empty slots are nil).
local Notes = { MAX = 5 }
ns.Notes = Notes

function Notes.All()
    ns.db.notes = ns.db.notes or {}
    return ns.db.notes
end

function Notes.Set(i, text)
    text = strtrim(text or "")
    Notes.All()[i] = text ~= "" and text or nil
end

-- Another addon's sign-up note tool on Blizzard's window clashes with ours:
-- a sentence saying which, or nil. Read from its saved settings, so a change
-- there counts at once. (Its auto-sign-up doesn't clash: our shift-click
-- holds Shift while the window opens, and it leaves the window open then.)
function Notes.Conflict()
    if C_AddOns.IsAddOnLoaded("EllesmereUIQoL") and type(EllesmereUIDB) == "table" and EllesmereUIDB.persistSignupNote then
        return "EllesmereUI's Persistent Signup Note is on"
    end
end

-- Our notes under Blizzard's window: the player's choice, unless something clashes.
function Notes.StripOn() return ns.db.noteStrip ~= false and not Notes.Conflict() end

-- The notes in slot order, gaps closed.
function Notes.List()
    local out, all = {}, Notes.All()
    for i = 1, Notes.MAX do if all[i] then out[#out + 1] = all[i] end end
    return out
end

-- Tooltips that explain how a control works; Options can hide them all.
-- Tooltips with information (groups, reasons, results) always show.
function ns.Hints() return not ns.db.noHints end

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
    ns.Print("v" .. version .. " loaded. Type |cff98ff98/pug|r for commands.")
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
    "  /pug log |cff8c8c8c— open the log to copy into a bug report|r",
    "  /pug log clear |cff8c8c8c— empty the log|r",
    "  /pug stats |cff8c8c8c— your rejection record, ready to brag about|r",
    "  /pug debug |cff8c8c8c— switch detailed recording on or off|r",
}

function ns.OnSlash(msg)
    local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd, rest = cmd:lower(), rest:lower()
    if cmd == "log" and rest == "clear" then
        ns.Log.Clear()
        ns.Print("Log cleared.")
    elseif cmd == "log" then
        ns.LogPopup.Toggle()
    elseif cmd == "stats" then
        ns.Print(ns.History.StatsLine())
    elseif cmd == "debug" then
        ns.db.trace = not ns.db.trace
        ns.Log.Emit("setting", { key = "trace", on = ns.db.trace })
        ns.Print("Detailed recording " .. (ns.db.trace and "|cff98ff98on|r." or "off."))
    else
        for _, line in ipairs(HELP) do ns.Print(line) end
    end
end
