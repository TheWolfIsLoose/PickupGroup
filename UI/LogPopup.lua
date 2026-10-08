--[[
    PickupGroup - UI/LogPopup.lua
    /pug log: the report (Log.Report) in a copyable text box, pre-selected so
    Ctrl+C works at once. A snapshot taken on open, so a selection survives
    while copying. Also the sign-up history window (Options > Sign-up history).
--]]

local _, ns = ...

local LogPopup = {}
ns.LogPopup = LogPopup

local Kit = ns.Kit
local frame

-- A movable window with a title and a close glyph; Escape closes it.
local function Window(name, w, h, title)
    Kit.ApplyFontFace()
    local f = CreateFrame("Frame", name, UIParent)
    f:SetSize(w, h)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    tinsert(UISpecialFrames, name)
    Kit.Fill(f, Kit.Palette.panelBg)
    Kit.Border(f)
    local t = f:CreateFontString(nil, "OVERLAY", "PickupGroupFont")
    t:SetPoint("TOPLEFT", 12, -10)
    t:SetText(title)
    Kit.HeaderIcon(f, Kit.CLOSE, "Close", function() f:Hide() end):SetPoint("TOPRIGHT", -4, -4)
    return f
end

-- A window with a pre-selected text box: f.Fill(text) puts text in and selects it.
local function CopyWindow(name, title, hint)
    local f = Window(name, 520, 420, title)
    local h = f:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    h:SetPoint("TOPLEFT", 12, -28)
    h:SetText("|cff8c8c8c" .. hint .. "|r")

    local well = f:CreateTexture(nil, "BACKGROUND")
    well:SetColorTexture(unpack(Kit.Palette.bgDark))
    well:SetPoint("TOPLEFT", 8, -50)
    well:SetPoint("BOTTOMRIGHT", -8, 38)
    local scroll = CreateFrame("ScrollFrame", "PickupGroupLogPopupScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -52)
    scroll:SetPoint("BOTTOMRIGHT", -28, 40)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontSmall")
    edit:SetWidth(scroll:GetWidth() - 4)
    edit:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(edit)
    -- A hidden focused box swallows every key game-wide.
    f:SetScript("OnHide", function() edit:ClearFocus() end)
    function f.Fill(text)
        edit:SetText(text)
        scroll:SetVerticalScroll(0)
        edit:SetFocus()
        edit:HighlightText()
    end
    return f
end

local function Build()
    local f = CopyWindow("PickupGroupLogPopup", "|cff98ff98Pickup|rGroup log",
        "Everything is selected: press Ctrl+C and paste it into your bug report.")
    local clear = CreateFrame("Button", nil, f)
    clear:SetSize(80, 22)
    clear:SetPoint("BOTTOMRIGHT", -8, 8)
    Kit.Button(clear)
    clear:SetText("Clear log")

    local function Fill() f.Fill(ns.Log.Report()) end
    clear:SetScript("OnClick", function() ns.Log.Clear(); Fill() end)
    f:SetScript("OnShow", Fill)
    return f
end

function LogPopup.Toggle()
    frame = frame or Build()
    frame:SetShown(not frame:IsShown())
end

-- ---------------------------------------------------------------------------
-- Sign-up history: the application log as a table, this character or all
-- characters on the account, newest first, with a one-line tally.
-- ---------------------------------------------------------------------------
local History = {}
ns.History = History

local MINT, AMBER, GREY = Kit.Palette.brand, { 1, 0.72, 0.3 }, { 0.55, 0.55, 0.55 }
-- History is the fun corner: self-deprecating, never mean (player, 2026-10-04).
local LOOK = {
    pending = { "Waiting...", GREY }, declined = { "Nope", AMBER }, filled = { "Too slow", GREY },
    delisted = { "Vanished", GREY }, withdrawn = { "Cold feet", GREY }, timedout = { "Ghosted", GREY },
    invitedeclined = { "You said no", GREY }, failed = { "Game said no", AMBER }, joined = { "Got in!", MINT },
    unknown = { "Who knows", GREY }, timed = { "Timed", MINT }, depleted = { "Depleted", AMBER },
    movedon = { "Moved on", GREY }, abandoned = { "Bailed", AMBER },
}
-- A "no", as far as the applicant can tell: the game softens a leader's
-- decline into Filled or Delisted, so those count; ignored ones too.
local NO = { declined = true, filled = true, delisted = true, timedout = true }
local GOT = { joined = true, timed = true, depleted = true, abandoned = true }
-- One line under the decline count, by how many there are.
local QUIPS = {
    { 0, "Not a single no. A legend, or you haven't signed up yet." },
    { 1, "A few polite no-thank-yous. Character-building, apparently." },
    { 10, "Rejection is just a cooldown. A long one." },
    { 50, "Leaders are starting to recognize your name." },
    { 150, "Declined by more groups than most people have joined." },
    { 500, "At this point it's a relationship. A one-sided one." },
    { 1000, "Four digits of no. Frame it." },
}
local function Quip(n)
    local pick = QUIPS[1][2]
    for _, q in ipairs(QUIPS) do if n >= q[1] then pick = q[2] end end
    return pick
end

local function Ago(sec)
    if sec < 60 then return sec .. " s" end
    return ("%d m %d s"):format(math.floor(sec / 60), sec % 60)
end

local SHOW = 300  -- ponytail: newest 300 drawn; page or pool rows if anyone wants more
local COLS = { { "When", 86 }, { "Character", 90 }, { "Where", 90 }, { "Leader", 118 }, { "Ended", 70 } }
local ROW = 18

local hist, allChars, exportWin

local function Entries()
    local out, mine = {}, UnitName("player") .. "-" .. GetRealmName()
    for key, c in pairs(ns.db.chars or {}) do
        if allChars or key == mine then
            for _, e in ipairs(c.apps or {}) do out[#out + 1] = { e = e, key = key, who = key:match("^[^%-]+") } end
        end
    end
    table.sort(out, function(a, b) return (a.e.ts or 0) > (b.e.ts or 0) end)
    return out
end

-- Lifetime declines for the scope (this character, or every character).
local function Nos(t)
    local n = 0
    for k in pairs(NO) do n = n + (t[k] or 0) end
    return n
end
-- When the shown counts start: the earliest "since" in scope.
local function Since()
    local mine, first = UnitName("player") .. "-" .. GetRealmName(), nil
    for key, c in pairs(ns.db.chars or {}) do
        if allChars or key == mine then
            ns.Applications.Lifetime(c)
            first = math.min(first or c.since, c.since)
        end
    end
    return first or time()
end

-- Lifetime counts for the scope, summed over characters with All characters.
local function Counts()
    if not allChars then return ns.Applications.Lifetime() end
    local sum = {}
    for _, c in pairs(ns.db.chars or {}) do
        for k, v in pairs(ns.Applications.Lifetime(c)) do sum[k] = (sum[k] or 0) + v end
    end
    return sum
end
local function LifetimeDeclines() return Nos(Counts()) end

-- Acceptance: leaders who said yes (an invite counts, even one you turned
-- down) out of every sign-up a leader answered. Success: keys timed out of
-- keys run (raids have no timer, so they sit this one out).
local function Pct(a, b)
    if b == 0 then return "nothing to judge yet" end
    return ("%d%% (%d of %d)"):format(math.floor(a * 100 / b + 0.5), a, b)
end
-- yes, answered, timed, keys run
local function Rates(t)
    local yes = (t.joined or 0) + (t.invitedeclined or 0)
    return yes, yes + Nos(t), t.timed or 0, (t.timed or 0) + (t.depleted or 0) + (t.abandoned or 0)
end
local function RatesLine(t)
    local yes, asked, _, keys = Rates(t)
    return ("Acceptance rate: %s. Success rate: %s."):format(Pct(yes, asked),
        keys > 0 and Pct(t.timed or 0, keys):gsub("%)$", " keys timed)") or Pct(0, 0))
end

-- Today, the fastest no, and the longest run of sign-ups that never got in.
local function Records(list)
    local today, todayN, todayNo, todayIn = date("%x"), 0, 0, 0
    local fastest, run, dry = nil, 0, 0
    for i = #list, 1, -1 do  -- oldest first
        local e = list[i].e
        local r = e.result
        local got = GOT[r]
        if e.ts and date("%x", e.ts) == today then
            todayN = todayN + 1
            if NO[r] then todayNo = todayNo + 1 end
            if got then todayIn = todayIn + 1 end
        end
        if NO[r] and e.ts and e.ended and e.ended >= e.ts then
            fastest = math.min(fastest or math.huge, e.ended - e.ts)
        end
        if got then run = 0 elseif r ~= "pending" and r ~= "movedon" then run = run + 1; dry = math.max(dry, run) end
    end
    return { n = todayN, no = todayNo, got = todayIn, fastest = fastest, dry = dry }
end

local function RecordsLine(rec)
    local parts = { ("Today: %d sign-up%s, %d no%s, %d got in."):format(rec.n, rec.n == 1 and "" or "s",
        rec.no, rec.no == 1 and "" or "s", rec.got) }
    if rec.fastest then
        parts[#parts + 1] = "Fastest no: " .. Ago(rec.fastest) .. (rec.fastest <= 10 and " (they didn't read the note)." or ".")
    end
    if rec.dry > 1 then parts[#parts + 1] = ("Longest dry spell: %d sign-ups."):format(rec.dry) end
    return table.concat(parts, " ")
end

-- /pug stats: one line for chat, this character.
function History.StatsLine()
    local was = allChars
    allChars = false
    local n = LifetimeDeclines()
    local line = RecordsLine(Records(Entries())) .. " " .. RatesLine(Counts()) .. (" Since %s: turned away %s time%s. %s"):format(
        date("%b %d, %Y", Since()), BreakUpLargeNumbers(n), n == 1 and "" or "s", Quip(n))
    allChars = was
    return line
end

-- Export: CSV for a spreadsheet, for the scope in view. Two tables, a blank
-- line apart: lifetime totals per character (never trimmed), then every
-- sign-up kept, newest first. Result words are the saved ones (see
-- Applications.lua), so they stay stable for formulas.
local function Csv(v)
    v = v == nil and "" or tostring(v)
    if v:find('[,"\n]') then v = '"' .. v:gsub('"', '""') .. '"' end
    return v
end
local function CsvRow(t)
    local out = {}
    for i = 1, #t do out[i] = Csv(t[i] == false and "" or t[i]) end
    return table.concat(out, ",")
end
local function Share(a, b) return b > 0 and math.floor(a * 100 / b + 0.5) or false end
local TOTALS = { "joined", "timed", "depleted", "abandoned", "declined", "filled", "delisted", "timedout",
                 "withdrawn", "movedon", "invitedeclined", "failed" }
function History.Export()
    local mine, keys = UnitName("player") .. "-" .. GetRealmName(), {}
    for key in pairs(ns.db.chars or {}) do if allChars or key == mine then keys[#keys + 1] = key end end
    table.sort(keys)
    local lines = { CsvRow({ "character", "counting since", "sign-ups", "got in", "timed", "depleted", "abandoned",
        "declined", "too slow", "vanished", "ghosted", "withdrawn", "moved on", "invite declined", "game said no",
        "acceptance %", "success %" }) }
    for _, key in ipairs(keys) do
        local c = ns.db.chars[key]
        local t = ns.Applications.Lifetime(c)
        local row = { key, date("%Y-%m-%d", c.since), t.applied or 0 }
        for _, k in ipairs(TOTALS) do row[#row + 1] = t[k] or 0 end
        local yes, asked, timed, run = Rates(t)
        row[#row + 1] = Share(yes, asked)
        row[#row + 1] = Share(timed, run)
        lines[#lines + 1] = CsvRow(row)
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = CsvRow({ "character", "signed up", "code", "activity", "difficulty", "key level", "leader",
        "roles", "result", "answered in (s)" })
    for _, x in ipairs(Entries()) do
        local e = x.e
        lines[#lines + 1] = CsvRow({ x.key, e.ts and date("%Y-%m-%d %H:%M", e.ts) or false, e.code or false,
            e.activity or false, e.difficulty or false, e.level or false, e.leader or false, e.roles or false,
            e.result or "pending", (e.ts and e.ended and e.ended >= e.ts) and (e.ended - e.ts) or false })
    end
    return table.concat(lines, "\n")
end

local TALLY = { declined = "nopes", filled = "too slow", delisted = "vanished", withdrawn = "cold feet",
                timedout = "ghosted", failed = "game said no", movedon = "moved on", abandoned = "bailed" }
local function Tally(list)
    local n = {}
    for _, x in ipairs(list) do n[x.e.result or "pending"] = (n[x.e.result or "pending"] or 0) + 1 end
    local joined = (n.joined or 0) + (n.timed or 0) + (n.depleted or 0) + (n.abandoned or 0)
    local parts = { #list .. " sign-ups", joined .. " got in" }
    if (n.timed or 0) + (n.depleted or 0) + (n.abandoned or 0) > 0 then
        parts[#parts] = parts[#parts] .. (" (%d timed, %d depleted, %d bailed)"):format(n.timed or 0, n.depleted or 0, n.abandoned or 0)
    end
    for _, k in ipairs({ "declined", "filled", "delisted", "timedout", "withdrawn", "movedon", "failed" }) do
        if (n[k] or 0) > 0 then parts[#parts + 1] = n[k] .. " " .. TALLY[k] end
    end
    return table.concat(parts, ", ")
end

local function BuildHistory()
    local f = Window("PickupGroupHistory", 500, 492, "Sign-up history")
    local who = Kit.Check(f, "All characters", function(on) allChars = on; f.Fill() end)
    who:SetPoint("TOPRIGHT", -30, -10)
    -- The headline: lifetime declines, big, with a quip.
    f.big = f:CreateFontString(nil, "OVERLAY", "PickupGroupFontLarge")
    f.big:SetPoint("TOPLEFT", 12, -34)
    f.big:SetTextColor(AMBER[1], AMBER[2], AMBER[3])
    f.bigLabel = f:CreateFontString(nil, "OVERLAY", "PickupGroupFont")
    f.bigLabel:SetPoint("BOTTOMLEFT", f.big, "BOTTOMRIGHT", 6, 1)
    f.quip = f:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    f.quip:SetPoint("TOPLEFT", 12, -56)
    f.quip:SetTextColor(MINT[1], MINT[2], MINT[3])
    -- Start over (two clicks, like Clear): this character, or every one with All characters.
    local reset = CreateFrame("Button", nil, f)
    reset:SetSize(60, 20)
    reset:SetPoint("TOPRIGHT", -12, -34)
    Kit.Button(reset)
    reset:SetNormalFontObject("PickupGroupFontSmall")
    reset:SetText("Reset")
    reset:SetScript("OnClick", function(self)
        if not self.armed then
            self.armed = true; self:SetText("Sure?")
            C_Timer.After(3, function() self.armed = nil; self:SetText("Reset") end)
            return
        end
        self.armed = nil; self:SetText("Reset")
        local mine = UnitName("player") .. "-" .. GetRealmName()
        for key, c in pairs(ns.db.chars or {}) do
            if allChars or key == mine then ns.Applications.Reset(c) end
        end
        f.Fill()
    end)
    reset:HookScript("OnEnter", function(self)
        if not ns.Hints() then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Reset")
        GameTooltip:AddLine("Wipes this character's sign-ups and counts (every character's with All characters ticked) and starts counting again. Click twice. A clean slate; the groups won't remember either.", 0.74, 0.74, 0.74, true)
        GameTooltip:Show()
    end)
    reset:HookScript("OnLeave", function() GameTooltip:Hide() end)
    -- Export what's in view (this character, or every one with All characters).
    local export = CreateFrame("Button", nil, f)
    export:SetSize(60, 20)
    export:SetPoint("RIGHT", reset, "LEFT", -6, 0)
    Kit.Button(export)
    export:SetNormalFontObject("PickupGroupFontSmall")
    export:SetText("Export")
    export:SetScript("OnClick", function()
        exportWin = exportWin or CopyWindow("PickupGroupExport", "Sign-up history export",
            "Everything is selected: press Ctrl+C and paste it into a spreadsheet.")
        exportWin:Show()
        exportWin.Fill(History.Export())
    end)
    export:HookScript("OnEnter", function(self)
        if not ns.Hints() then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Export")
        GameTooltip:AddLine("This character's sign-ups and lifetime counts as spreadsheet text (every character's with All characters ticked). Your rejections, now in spreadsheet form.", 0.74, 0.74, 0.74, true)
        GameTooltip:Show()
    end)
    export:HookScript("OnLeave", function() GameTooltip:Hide() end)
    -- Records and tally wrap as they like; the table follows them down.
    f.records = f:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    f.records:SetPoint("TOPLEFT", 12, -74)
    f.records:SetPoint("RIGHT", -12, 0)
    f.records:SetJustifyH("LEFT")
    f.rates = f:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    f.rates:SetPoint("TOPLEFT", f.records, "BOTTOMLEFT", 0, -4)
    f.rates:SetPoint("RIGHT", -12, 0)
    f.rates:SetJustifyH("LEFT")
    f.rates:SetTextColor(MINT[1], MINT[2], MINT[3])
    f.tally = f:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    f.tally:SetPoint("TOPLEFT", f.rates, "BOTTOMLEFT", 0, -4)
    f.tally:SetPoint("RIGHT", -12, 0)
    f.tally:SetJustifyH("LEFT")
    f.tally:SetTextColor(0.74, 0.74, 0.74)

    local x = 12
    f.heads = {}
    for i, c in ipairs(COLS) do
        local h = f:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
        h:SetPoint("TOPLEFT", f.tally, "BOTTOMLEFT", x - 12, -10)
        h:SetText(c[1])
        h:SetTextColor(0.55, 0.55, 0.55)
        f.heads[i] = h
        x = x + c[2]
    end

    local scroll = CreateFrame("ScrollFrame", "PickupGroupHistoryScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", f.tally, "BOTTOMLEFT", -4, -26)
    scroll:SetPoint("BOTTOMRIGHT", -28, 10)
    local body = CreateFrame("Frame", nil, scroll)
    body:SetSize(460, 1)
    scroll:SetScrollChild(body)
    local rows = {}

    function f.Fill()
        local list = Entries()
        local no = LifetimeDeclines()
        f.big:SetText(BreakUpLargeNumbers(no))
        f.bigLabel:SetText((no == 1 and "time" or "times") .. " turned away since " .. date("%b %d, %Y", Since()))
        f.quip:SetText(Quip(no))
        f.records:SetText(RecordsLine(Records(list)))
        f.rates:SetText(RatesLine(Counts()))
        f.tally:SetText(#list > 0 and Tally(list) or "Nothing here yet. Go get rejected; it builds character.")
        -- The Character column only when showing every character.
        local hideWho = not allChars
        f.heads[2]:SetShown(not hideWho)
        for i = 1, math.min(#list, SHOW) do
            local r = rows[i]
            if not r then
                r = CreateFrame("Frame", nil, body)
                r:SetHeight(ROW)
                r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW)
                r:SetPoint("RIGHT")
                r.stripe = r:CreateTexture(nil, "BACKGROUND")
                r.stripe:SetAllPoints()
                r.stripe:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.05 or 0)
                r.cells = {}
                local cx = 4
                for c, col in ipairs(COLS) do
                    local fs = r:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
                    fs:SetPoint("LEFT", cx, 0)
                    fs:SetWidth(col[2] - 6)
                    fs:SetJustifyH("LEFT")
                    fs:SetWordWrap(false)
                    r.cells[c] = fs
                    cx = cx + col[2]
                end
                rows[i] = r
            end
            local e = list[i].e
            local look = LOOK[e.result or "pending"] or { e.result or "?", GREY }
            local where = (e.code or e.activity or "?") .. (e.difficulty and (" " .. e.difficulty) or "")
                .. (e.level and (" +" .. e.level) or "")
            r.cells[1]:SetText(date("%m/%d/%y %H:%M", e.ts or 0))
            r.cells[2]:SetText(list[i].who or "")
            r.cells[2]:SetShown(not hideWho)
            r.cells[3]:SetText(where)
            r.cells[4]:SetText(e.leader or "?")
            r.cells[5]:SetText(look[1])
            r.cells[5]:SetTextColor(look[2][1], look[2][2], look[2][3])
            r:Show()
        end
        for i = math.min(#list, SHOW) + 1, #rows do rows[i]:Hide() end
        body:SetHeight(math.max(1, math.min(#list, SHOW) * ROW))
        scroll:SetVerticalScroll(0)
    end
    f:SetScript("OnShow", f.Fill)
    return f
end

function History.Toggle()
    hist = hist or BuildHistory()
    hist:SetShown(not hist:IsShown())
end
