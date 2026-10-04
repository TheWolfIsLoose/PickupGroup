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

local function Build()
    local f = Window("PickupGroupLogPopup", 520, 420, "|cff98ff98Pickup|rGroup log")
    local hint = f:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    hint:SetPoint("TOPLEFT", 12, -28)
    hint:SetText("|cff888888Everything is selected: press Ctrl+C and paste it into your bug report.|r")

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

    local clear = CreateFrame("Button", nil, f)
    clear:SetSize(80, 22)
    clear:SetPoint("BOTTOMRIGHT", -8, 8)
    Kit.Button(clear)
    clear:SetText("Clear log")

    local function Fill()
        edit:SetText(ns.Log.Report())
        scroll:SetVerticalScroll(0)
        edit:SetFocus()
        edit:HighlightText()
    end
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

local MINT, AMBER, GREY = Kit.Palette.brand, { 1, 0.72, 0.3 }, { 0.6, 0.6, 0.6 }
local LOOK = {
    pending = { "Pending", GREY }, declined = { "Declined", AMBER }, filled = { "Filled", GREY },
    delisted = { "Delisted", GREY }, withdrawn = { "Withdrawn", GREY }, timedout = { "Expired", GREY },
    invitedeclined = { "Passed", GREY }, failed = { "Failed", AMBER }, joined = { "Joined", MINT },
    unknown = { "Unknown", GREY }, timed = { "Timed", MINT }, depleted = { "Depleted", AMBER },
}
local SHOW = 300  -- ponytail: newest 300 drawn; page or pool rows if anyone wants more
local COLS = { { "When", 74 }, { "Character", 90 }, { "Where", 90 }, { "Leader", 130 }, { "Ended", 70 } }
local ROW = 18

local hist, allChars

local function Entries()
    local out, mine = {}, UnitName("player") .. "-" .. GetRealmName()
    for key, c in pairs(ns.db.chars or {}) do
        if allChars or key == mine then
            for _, e in ipairs(c.apps or {}) do out[#out + 1] = { e = e, who = key:match("^[^%-]+") } end
        end
    end
    table.sort(out, function(a, b) return (a.e.ts or 0) > (b.e.ts or 0) end)
    return out
end

local function Tally(list)
    local n = {}
    for _, x in ipairs(list) do n[x.e.result or "pending"] = (n[x.e.result or "pending"] or 0) + 1 end
    local joined = (n.joined or 0) + (n.timed or 0) + (n.depleted or 0)
    local parts = { #list .. " sign-ups", joined .. " joined" }
    if (n.timed or 0) + (n.depleted or 0) > 0 then
        parts[#parts] = parts[#parts] .. (" (%d timed, %d depleted)"):format(n.timed or 0, n.depleted or 0)
    end
    for _, k in ipairs({ "declined", "filled", "delisted", "withdrawn", "timedout", "failed" }) do
        if (n[k] or 0) > 0 then parts[#parts + 1] = n[k] .. " " .. LOOK[k][1]:lower() end
    end
    return table.concat(parts, ", ")
end

local function BuildHistory()
    local f = Window("PickupGroupHistory", 500, 420, "Sign-up history")
    local who = Kit.Check(f, "All characters", function(on) allChars = on; f.Fill() end)
    who:SetPoint("TOPRIGHT", -30, -10)
    f.tally = f:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    f.tally:SetPoint("TOPLEFT", 12, -30)
    f.tally:SetPoint("RIGHT", -12, 0)
    f.tally:SetJustifyH("LEFT")
    f.tally:SetTextColor(0.74, 0.74, 0.74)

    local x = 12
    f.heads = {}
    for i, c in ipairs(COLS) do
        local h = f:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
        h:SetPoint("TOPLEFT", x, -50)
        h:SetText(c[1])
        h:SetTextColor(0.55, 0.55, 0.55)
        f.heads[i] = h
        x = x + c[2]
    end

    local scroll = CreateFrame("ScrollFrame", "PickupGroupHistoryScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -66)
    scroll:SetPoint("BOTTOMRIGHT", -28, 10)
    local body = CreateFrame("Frame", nil, scroll)
    body:SetSize(460, 1)
    scroll:SetScrollChild(body)
    local rows = {}

    function f.Fill()
        local list = Entries()
        f.tally:SetText(#list > 0 and Tally(list) or "No sign-ups recorded yet.")
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
            r.cells[1]:SetText(date("%m/%d %H:%M", e.ts or 0))
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
