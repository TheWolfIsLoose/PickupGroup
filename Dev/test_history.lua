-- Logic check for the decline counter: texlua/lua5.1 Dev/test_history.lua  (Dev/ never ships)
local now = os.time()
local apps = {
    { ts = now - 300, ended = now - 297, result = "declined" },   -- fastest no: 3 s
    { ts = now - 250, ended = now - 200, result = "declined" },
    { ts = now - 200, ended = now - 100, result = "filled" },
    { ts = now - 100, ended = now - 50, result = "timed" },       -- got in: ends the dry spell of 3
    { ts = now - 90, ended = now - 48, result = "withdrawn" },    -- withdrawn by the game at the join: migration 5 -> movedon
    { ts = now - 40, result = "pending" },
}
local db = { chars = { ["Me-Realm"] = { apps = apps } } }
local ns = { db = db, Kit = { Palette = { brand = { 0, 1, 0 } } } }
local handlers = {}
function ns.On(ev, fn) handlers[ev] = fn end
function ns.CharDB() return db.chars["Me-Realm"] end
function ns.Trace() end
UnitName = function() return "Me" end
GetRealmName = function() return "Realm" end
BreakUpLargeNumbers = function(n) return tostring(n) end
UISpecialFrames = {}
date = os.date
time = os.time
-- Migration 5 straight from Core.lua.
local src = io.open("Core.lua"):read("*a")
local a = src:find("%[5%] = function%(db%)"); local b = src:find("\n    end,\n", a)
local m5 = assert(loadstring("return function(db) " .. src:sub(src:find("\n", a) + 1, b) .. " end"))()
m5(db)
assert(apps[5].result == "movedon", "migration 5")
assert(loadfile("Applications.lua"))("PickupGroup", ns)
assert(loadfile("UI/LogPopup.lua"))("PickupGroup", ns)

handlers.PLAYER_LOGIN()
local t = ns.Applications.Lifetime()
assert(t.applied == 6 and t.declined == 2 and t.timed == 1 and t.joined == 1 and t.filled == 1 and t.movedon == 1, "seed")

local line = ns.History.StatsLine()
print(line)
assert(line:find("Today: 6 sign%-ups, 3 nos, 1 got in%."), "today")
assert(line:find("Fastest no: 3 s %(they didn't read the note%)"), "fastest")
assert(line:find("Longest dry spell: 3 sign%-ups"), "dry spell")
-- 1 got in (the timed key) of 4 answered (2 declined, 1 filled); 1 of 1 keys timed.
assert(line:find("Acceptance rate: 25%% %(1 of 4%)%."), "acceptance")
assert(line:find("Success rate: 100%% %(1 of 1 keys timed%)%."), "success")
assert(line:find("turned away 3 times%. A few polite"), "lifetime + quip")
local csv = ns.History.Export()
print(csv)
assert(csv:find("^character,counting since,sign%-ups,got in,"), "totals header")
assert(csv:find("\nMe%-Realm,%d+%-%d+%-%d+,6,1,1,0,0,2,1,0,0,0,1,0,0,25,100\n"), "totals row")
assert(csv:find("\n\ncharacter,signed up,"), "sign-ups header")
assert(csv:find(",declined,3$"), "fastest no answered in 3 s")
assert(select(2, csv:gsub("\n", "")) == 9, "10 lines: 2 totals, blank, header, 6 sign-ups")
print("history OK")
