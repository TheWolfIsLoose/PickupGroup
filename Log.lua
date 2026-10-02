--[[
    PickupGroup - Log.lua
    Account-wide log: what happened, in plain words, for players and for
    support (/pug log copies it into a report).

    Ring buffer of MAX entries in PickupGroupDB.log. Entry shape:
      { ts, kind, char, payload = { per-kind fields } }

    Every kind has a level:
      activity  what a player cares about
      detail    what support needs
      trace     step-by-step internals, recorded only while PickupGroupDB.trace
                is on (/pug debug; on by default until v1.0.0)

    Add a kind: one KINDS entry, { level, format(payload) -> sentence }.
--]]

local _, ns = ...

local Log = {}
ns.Log = Log

local MAX = 2000

local function Plain(text)
    return (tostring(text or "?"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local KINDS = {
    error   = { "activity", function(p) return "Something went wrong: " .. Plain(p.msg) end },
    version = { "detail", function(p)
        if not p.from then return "PickupGroup " .. Plain(p.to) .. " installed" end
        return ("PickupGroup updated from %s to %s"):format(Plain(p.from), Plain(p.to))
    end },
    setting = { "detail", function(p) return ("Setting: %s %s"):format(Plain(p.key), p.on and "on" or "off") end },
    blocked = { "activity", function(p) return ("Blizzard blocked an action: %s"):format(Plain(p.func)) end },
    apply   = { "activity", function(p) return ("Signed up: %s, led by %s"):format(Plain(p.code), Plain(p.leader)) end },
    cancel  = { "activity", function(p) return ("Cancelled sign-up: %s, led by %s"):format(Plain(p.code), Plain(p.leader)) end },
    search_failed = { "detail", function(p) return "Search refused: " .. Plain(p.reason) end },
    app_end = { "activity", function(p)
        local words = { declined = "declined", filled = "group filled up", delisted = "group delisted",
            withdrawn = "withdrawn", timedout = "timed out", invitedeclined = "invite declined",
            failed = "failed", joined = "joined", timed = "timed", depleted = "depleted" }
        return ("Sign-up %s: %s, led by %s%s"):format(words[p.result] or Plain(p.result), Plain(p.code),
            Plain(p.leader), p.level and (" (+" .. p.level .. ")") or "")
    end },
    filter  = { "detail", function(p) return ("Filter %s: %s"):format(Plain(p.action), Plain(p.name)) end },
    blacklist = { "activity", function(p) return ("Blacklist: %s (%s)"):format(Plain(p.name), Plain(p.why)) end },
    hide    = { "activity", function(p) return ("Hidden: %s (%s)"):format(Plain(p.name), Plain(p.why)) end },
    lead    = { "activity", function(p) return ("Leading: %s %s"):format(Plain(p.action), Plain(p.name)) end },
    report  = { "activity", function(p) return ("Report: %s (%s)"):format(Plain(p.name), Plain(p.why)) end },
    trace   = { "trace", function(p) return ("[%s] %s"):format(Plain(p.tag), Plain(p.text)) end },
}

function Log.Emit(kind, payload)
    local k = KINDS[kind]
    if not k then return ns.Trace("log", "unknown kind", kind) end
    if k[1] == "trace" and not ns.db.trace then return end
    local buf = ns.db.log
    buf[#buf + 1] = { ts = time(), kind = kind, char = UnitName("player"), payload = payload or {} }
    -- ponytail: table.remove(t, 1) shifts the whole buffer; fine at 2000 entries.
    while #buf > MAX do table.remove(buf, 1) end
end

-- ns.Trace("search", "sent", categoryID): a trace step, args joined by spaces.
function ns.Trace(tag, ...)
    if not (ns.db and ns.db.trace) then return end
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    Log.Emit("trace", { tag = tag, text = table.concat(parts, " ") })
end

function Log.Clear()
    wipe(ns.db.log)
end

function Log.Format(e)
    local k = KINDS[e.kind]
    return k and k[2](e.payload or {}) or tostring(e.kind)
end

-- Addons that also touch the Group Finder: worth knowing when something
-- misbehaves (compatibility only).
local WATCHED = {
    "RaiderIO", "PremadeGroupsFilter", "PremadeGroupBoard", "LFGSpamFilter",
    "ElvUI", "EllesmereUI", "atrocityUI", "atrocityEssentials",
}

-- Environment header, then every entry newest first, plain text.
function Log.Report()
    local wow, build = GetBuildInfo()
    local loaded, count = {}, 0
    for i = 1, C_AddOns.GetNumAddOns() do
        if C_AddOns.IsAddOnLoaded(i) then count = count + 1 end
    end
    for _, name in ipairs(WATCHED) do
        if C_AddOns.IsAddOnLoaded(name) then loaded[#loaded + 1] = name end
    end
    local lines = {
        "PickupGroup report, " .. date("%Y-%m-%d %H:%M"),
        ("PickupGroup %s | WoW %s (build %s) | %s"):format(ns.Version(), tostring(wow), tostring(build), GetLocale()),
        ("Character: %s-%s"):format(UnitName("player"), GetRealmName()),
        ("Addons loaded: %d. Relevant: %s"):format(count, #loaded > 0 and table.concat(loaded, ", ") or "none"),
        "Detailed recording (/pug debug): " .. (ns.db.trace and "on" or "off"),
        "Lines marked . are details, > are recorded steps. Newest first.",
    }
    local PREFIX = { activity = "  ", detail = ". ", trace = "> " }
    local me, day = UnitName("player"), nil
    local buf = ns.db.log
    for i = #buf, 1, -1 do
        local e = buf[i]
        local d = date("%a %Y-%m-%d", e.ts or 0)
        if d ~= day then
            day = d
            lines[#lines + 1] = ""
            lines[#lines + 1] = "-- " .. d .. " --"
        end
        local who = (e.char and e.char ~= me) and (" (" .. e.char .. ")") or ""
        local stack = (e.kind == "error" and e.payload.stack) and ("\n             " .. e.payload.stack) or ""
        local level = KINDS[e.kind] and KINDS[e.kind][1]
        lines[#lines + 1] = ("[%s] %s%s%s%s"):format(date("%H:%M:%S", e.ts or 0),
            PREFIX[level] or "  ", Log.Format(e), who, stack)
    end
    return table.concat(lines, "\n")
end
