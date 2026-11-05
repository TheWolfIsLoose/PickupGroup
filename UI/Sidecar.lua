--[[
    PickupGroup - UI/Sidecar.lua
    The filter panel: 170px, docked on the Group Finder's right edge while
    Dungeons & Raids is open, in the look shared with atrocityEssentials.
    Edits apply as they are made (no Save step). What it shows follows the
    Group Finder:
      quick   on opening, and anywhere our list isn't: this week's affixes,
              category searches, This Week (runs + vault, raid lockouts) and
              Sign-Up History
      keys    Dungeons: the dungeon grid (best run in each), the filters,
              playstyle, leader's realm, Min Score; Reset, affixes, runs
      raid    Raids: difficulty, realm, My Lockout, raid ticks with fold
              headers (one open at a time) and their bosses
      lead    leading a listing: who gets dimmed in the leader view
    plus, from the pane's menu: settings and notes, and the clash prompt.
--]]

local _, ns = ...

local Sidecar = {}
ns.Sidecar = Sidecar

local Kit, Filters, Week = ns.Kit, ns.Filters, ns.Week
local W, PAD, BTN, GAP, COL = 170, 10, 26, 5, 4
local INNER = W - 2 * PAD
local ON = Kit.Palette.on
local MUTED = Kit.Palette.muted

local frame, editing, override, mode
local views = {}
local prompt, asking, BuildPrompt, PaintPrompt  -- the clash prompt (defined with the clashes below)
local openRaid  -- the raid unfolded: a name, false (all folded by hand), nil (pick one)

local function Changed()
    ns.Pane.Render()
    ns.Leader.Render()
end

local function Leading(f) return f ~= nil and f.kind:find("^lead_") ~= nil end

local function Label(parent, text, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "PickupGroupFontSmall")
    fs:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    fs:SetText(text)
    return fs
end

-- A view's title: 14px in the accent, centred (AES's "Quick Access" / "Filters").
local function Title(v, text)
    local t = v:CreateFontString(nil, "OVERLAY", "PickupGroupFontLarge")
    t:SetPoint("TOP")
    t:SetHeight(18)
    local a = Kit.Accent()
    t:SetTextColor(a[1], a[2], a[3])
    t:SetText(text)
    v.title = t
    return -18 - GAP
end

-- Width of one of n buttons across the panel.
local function Cell(n) return (INNER - (n - 1) * COL) / n end

local function Place(b, v, y, i, n)
    b:SetPoint("TOPLEFT", v, "TOPLEFT", (i - 1) * (Cell(n) + COL), y)
end

local function Button(parent, text, w, onClick, h)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h or BTN)
    Kit.Button(b)
    b:SetText(text)
    local fs = b:GetFontString()
    if fs then fs:SetWordWrap(false) end
    if onClick then b:SetScript("OnClick", onClick) end
    return b
end

-- Settings and notes open in the panel; history in its own window.
function ns.OpenView(which)
    if which == "history" then return ns.History.Toggle() end
    Sidecar.Open(nil, which)
end

-- Text then role / class icons, centred on a button as one line.
local function IconLabel(b, text, icons)
    local holder = CreateFrame("Frame", nil, b)
    holder:SetHeight(14)
    local fs = holder:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    fs:SetPoint("LEFT")
    fs:SetText(text or "")
    local x = (text and text ~= "") and (fs:GetStringWidth() + 3) or 0
    for i, icon in ipairs(icons) do
        if icon == "/" then
            local s = holder:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
            s:SetText("/")
            s:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
            s:SetPoint("LEFT", x, 0)
            x = x + s:GetStringWidth() + 2
        else
            local t = holder:CreateTexture(nil, "OVERLAY")
            t:SetSize(12, 12)
            t:SetPoint("LEFT", x, 0)
            if ns.Kit.ROLE_ATLAS[icon] then Kit.RoleIcon(t, icon) else t:SetAtlas(icon) end
            x = x + 12 + (i < #icons and 2 or 0)
        end
    end
    holder:SetWidth(math.max(1, x))
    holder:SetPoint("CENTER")
    return holder
end

-- A drawn lock (killed this week).
local function Lock(parent, grey)
    local l = CreateFrame("Frame", nil, parent)
    l:SetSize(7, 9)
    local c = grey and 0.44 or 1
    local function Bit(w, h, x, y)
        local t = l:CreateTexture(nil, "ARTWORK")
        t:SetColorTexture(c, c, c, 1)
        t:SetSize(w, h)
        t:SetPoint("BOTTOMLEFT", x, y)
    end
    Bit(7, 5, 0, 0); Bit(1, 3, 1, 5); Bit(1, 3, 5, 5); Bit(5, 1, 1, 8)
    return l
end

-- ---------------------------------------------------------------------------
-- Toggles over the filter being edited
-- ---------------------------------------------------------------------------
local toggles = {}  -- every filter toggle: b:Sync() repaints it from `editing`

-- A boolean in the filter (true / nil). others: keys this one turns off when it goes on.
local function Flag(v, label, key, tip, others, icons)
    local b = Kit.Toggle(v, icons and "" or label, 1, function(self)
        editing[key] = not editing[key] or nil
        if editing[key] then for _, k in ipairs(others or {}) do editing[k] = nil end end
        Sidecar.Paint(); Changed()
    end)
    if icons then IconLabel(b, label, icons) end
    function b:Sync() self:Paint(editing[key] == true) end
    Kit.Tip(b, type(tip) == "table" and tip[1] or label, type(tip) == "table" and tip[2] or tip)
    toggles[#toggles + 1] = b
    return b
end

-- One code in a set (f[key]: nil = all on, else the set still on).
local function SetMember(v, label, key, code, codes, tipTitle, tip)
    local b = Kit.Toggle(v, label, 1, function()
        if not editing[key] then
            editing[key] = {}
            for _, c in ipairs(codes) do editing[key][c] = true end
        end
        editing[key][code] = not editing[key][code] or nil
        local all = true
        for _, c in ipairs(codes) do if not editing[key][c] then all = false end end
        if all then editing[key] = nil end
        Sidecar.Paint(); Changed()
    end)
    function b:Sync() self:Paint(not editing[key] or editing[key][code] == true) end
    Kit.Tip(b, tipTitle or label, tip)
    toggles[#toggles + 1] = b
    return b
end

-- A row of n toggles over a set, across the panel. Returns the next y.
local function SetRow(v, y, key, codes, names, tip)
    for i, code in ipairs(codes) do
        local b = SetMember(v, names and names[code] or code, key, code, codes,
            names and names[code] or ns.Groups.REGION_NAME[code], tip)
        b:SetSize(Cell(#codes), BTN)
        Place(b, v, y, i, #codes)
    end
    return y - BTN - GAP
end

-- Leader's realm region: four toggles (Americas only).
local function RegionRow(v, y, whose)
    if not ns.Groups.SUBREGIONS then return y end
    return SetRow(v, y, "regions", ns.Groups.REGIONS, nil, "Groups whose " .. (whose or "leader") .. " plays on a realm in this region.")
end

local function SyncToggles(v)
    for _, b in ipairs(toggles) do if b:GetParent() == v then b:Sync() end end
end

-- Reset (two clicks) for the filter in view.
local function ResetButton(v, w)
    local b = Button(v, "Reset", w)
    Kit.Confirm(b, "Reset", function() Filters.Reset(editing); Sidecar.Paint(); Changed() end)
    Kit.Tip(b, "Reset", "This filter back to how it starts. Click twice.")
    return b
end

-- Sign-Up History (its own window alone, AES's tab with AES).
local function HistoryButton(v, w)
    local b = Button(v, "Sign-Up History", w, function() ns.OpenView("history") end)
    return b
end

-- ---------------------------------------------------------------------------
-- Quick Access (on opening)
-- ---------------------------------------------------------------------------
-- Blizzard's own path to a category's search, from the click (a search must
-- come from one). The active-panel record is only written when it has to
-- change: a write from addon code taints it for the session.
local CATEGORIES = {
    { "Mythic+", 2 },
    { "Raids", 3, function() return Enum.LFGListFilter.Recommended end },
    { "Delves", 121 }, { "Quest", 1 }, { "Custom", 6 },
}
local function QuickSearch(categoryID, filters)
    if PVEFrame_ShowFrame and not (GroupFinderFrame and GroupFinderFrame:IsVisible()) then PVEFrame_ShowFrame("GroupFinderFrame") end
    local lfg = LFGListFrame
    if not lfg or not GroupFinderFrame then return end
    local sp = lfg.SearchPanel
    if not (sp and sp:IsVisible()) and GroupFinderFrame.selection ~= LFGListPVEStub then
        local premade = (PVEFrame.ScenariosEnabled and PVEFrame:ScenariosEnabled() and GroupFinderFrame.groupButton4)
            or GroupFinderFrame.groupButton3
        if premade and GroupFinderFrameGroupButton_OnClick then GroupFinderFrameGroupButton_OnClick(premade) end
    end
    if not sp then return end
    LFGListSearchPanel_Clear(sp)
    LFGListSearchPanel_SetCategory(sp, categoryID, filters or 0, lfg.baseFilters or 0)
    LFGListSearchPanel_DoSearch(sp)
    if lfg.activePanel ~= sp then LFGListFrame_SetActivePanel(lfg, sp) end
    ns.Log.Emit("filter", { action = "quick search", name = tostring(categoryID) })
end

local function RunsButton(v, w)
    local b = Button(v, "0 Runs", w, function() ns.OpenView("history") end)
    b:HookScript("OnEnter", Week.RunsTooltip)
    b:HookScript("OnLeave", GameTooltip_Hide)
    function b:Sync() self:SetText(Week.RunsLabel()) end
    return b
end

local function BuildQuick()
    local v = CreateFrame("Frame", nil, frame)
    -- This week's affixes, a row of five (only here: above +12 they no longer
    -- rotate, so the dungeon view keeps them behind one icon).
    v.affixes = {}
    for i = 1, 5 do
        local a = CreateFrame("Frame", nil, v)
        a:SetSize(24, 24)
        Kit.Fill(a, Kit.Palette.bgMedium)
        Kit.Border(a)
        a.icon = a:CreateTexture(nil, "ARTWORK")
        a.icon:SetPoint("TOPLEFT", 1, -1)
        a.icon:SetPoint("BOTTOMRIGHT", -1, 1)
        a.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)
        a:EnableMouse(true)
        a:SetScript("OnEnter", function(self)
            if not self.affix then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(self.affix.name, 1, 1, 1)
            if self.affix.desc then GameTooltip:AddLine(self.affix.desc, 0.74, 0.74, 0.74, true) end
            GameTooltip:Show()
        end)
        a:SetScript("OnLeave", GameTooltip_Hide)
        v.affixes[i] = a
    end
    local y = -24 - 8
    v.title = v:CreateFontString(nil, "OVERLAY", "PickupGroupFontLarge")
    v.title:SetPoint("TOP", 0, y)
    v.title:SetText("Quick Access")
    y = y - 18 - GAP
    for _, c in ipairs(CATEGORIES) do
        local b = Button(v, c[1], INNER, function() QuickSearch(c[2], c[3] and c[3]()) end)
        b:SetPoint("TOPLEFT", 0, y)
        y = y - BTN - GAP
    end
    y = y - 6
    v.week = v:CreateFontString(nil, "OVERLAY", "PickupGroupFont")
    v.week:SetPoint("TOP", 0, y)
    v.week:SetText("This Week")
    y = y - 16 - GAP
    v.runs = RunsButton(v, Cell(2))
    Place(v.runs, v, y, 1, 2)
    local lock = Button(v, "Lockouts", Cell(2))
    Place(lock, v, y, 2, 2)
    lock:HookScript("OnEnter", Week.LockoutsTooltip)
    lock:HookScript("OnLeave", GameTooltip_Hide)
    y = y - BTN - GAP
    HistoryButton(v, INNER):SetPoint("TOPLEFT", 0, y)
    function v:Paint()
        local a = Kit.Accent()
        self.title:SetTextColor(a[1], a[2], a[3])
        self.week:SetTextColor(a[1], a[2], a[3])
        local list = Week.Affixes()
        local n = math.min(#list, 5)
        local total = n * 24 + math.max(0, n - 1) * 4
        for i, f in ipairs(self.affixes) do
            f.affix = list[i]
            f:SetShown(i <= n)
            if i <= n then
                f.icon:SetTexture(list[i].icon)
                f:ClearAllPoints()
                f:SetPoint("TOPLEFT", self, "TOP", -total / 2 + (i - 1) * 28, 0)
            end
        end
        self.runs:Sync()
    end
    return v
end

-- ---------------------------------------------------------------------------
-- Dungeons
-- ---------------------------------------------------------------------------
local dungeonButtons = {}

local function BuildKeys()
    local v = CreateFrame("Frame", nil, frame)
    local y = Title(v, "Filters")
    -- 2 x 4: map art, code, my best timed key on the right; engaged = shown.
    for i, d in ipairs(Filters.Dungeons()) do
        local b = Kit.Toggle(v, "", Cell(2), function(self)
            -- nil means every dungeon: turning one off lists the rest.
            if not editing.dungeons then
                editing.dungeons = {}
                for _, o in ipairs(dungeonButtons) do editing.dungeons[o.dungeon] = true end
            end
            editing.dungeons[self.dungeon] = not editing.dungeons[self.dungeon] or nil
            Sidecar.Paint(); Changed()
        end, BTN)
        b.dungeon = d.name
        Place(b, v, y - math.floor((i - 1) / 2) * (BTN + COL), (i - 1) % 2 + 1, 2)
        local edge = b:CreateTexture(nil, "ARTWORK")
        edge:SetColorTexture(0, 0, 0, 1)
        edge:SetSize(18, 18)
        edge:SetPoint("LEFT", 3, 0)
        local art = b:CreateTexture(nil, "ARTWORK", nil, 1)
        art:SetSize(16, 16)
        art:SetPoint("CENTER", edge)
        art:SetTexture(select(4, C_ChallengeMode.GetMapUIInfo(d.mapID)))
        art:SetTexCoord(0.075, 0.925, 0.075, 0.925)
        local code = b:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
        code:SetPoint("LEFT", edge, "RIGHT", 4, 0)
        code:SetText(d.code)
        b.best = b:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
        b.best:SetPoint("RIGHT", -4, 0)
        b.best:SetTextColor(0.74, 0.74, 0.74)
        b:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.dungeon, 1, 1, 1)
            GameTooltip:AddLine(self.bestLevel and ("Your best timed key this season: +" .. self.bestLevel)
                or "No timed key here this season.", 0.74, 0.74, 0.74)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", GameTooltip_Hide)
        dungeonButtons[#dungeonButtons + 1] = b
    end
    y = y - math.ceil(#dungeonButtons / 2) * (BTN + COL) + COL - GAP
    local rule = Kit.Rule(v)
    rule:SetPoint("TOPLEFT", 0, y - 2)
    rule:SetPoint("TOPRIGHT", 0, y - 2)
    y = y - 5 - GAP
    local class = select(2, UnitClass("player")) or ""
    local className = UnitClass("player") or "your class"
    local grid = {
        Flag(v, "Room for Me", "room", { "Room for Me", "Keeps groups with an open seat for a role you sign up as. In a party: seats for everyone's roles." }),
        Flag(v, "No Other", "noMyClass", { "No Other " .. className, "Hides groups that already have a " .. className .. "." }, nil, { "classicon-" .. class:lower() }),
        Flag(v, "Battle Rez", "brez", { "Battle Rez", "Keeps groups that have one, or will: you or your party bring it, or a seat still open after you join can take a battle rez class." }),
        Flag(v, "Bloodlust", "lust", { "Bloodlust", "Keeps groups that have it, or will: you or your party bring it, or a seat still open after you join can take a Bloodlust class." }),
        Flag(v, "My Score+", "atLeastMine", { "At Least My Score", "Keeps groups whose leader's Mythic+ score is at least yours." }),
        Flag(v, "Leader Timed", "leaderMyLevel", { "Leader Timed", "Keeps groups whose leader has timed this dungeon at your best timed key there (the number on its button) or higher. Dungeons you haven't timed aren't judged." }),
    }
    for i, b in ipairs(grid) do
        b:SetSize(Cell(2), BTN)
        Place(b, v, y - math.floor((i - 1) / 2) * (BTN + COL), (i - 1) % 2 + 1, 2)
    end
    y = y - 3 * (BTN + COL) + COL - GAP
    local has = {
        Flag(v, "Has", "hasTank", { "Has Tank", "Keeps groups that already have a tank." }, { "hasEither" }, { "TANK" }),
        Flag(v, "Has", "hasHealer", { "Has Healer", "Keeps groups that already have a healer." }, { "hasEither" }, { "HEALER" }),
        Flag(v, "", "hasEither", { "Has Tank or Healer", "Keeps groups that already have a tank or a healer: hides groups of only damage dealers." }, { "hasTank", "hasHealer" }, { "TANK", "/", "HEALER" }),
    }
    for i, b in ipairs(has) do b:SetSize(Cell(3), BTN); Place(b, v, y, i, 3) end
    y = y - BTN - GAP
    -- Playstyle: each button as wide as its word needs, the rest shared out.
    local style = {}
    local words = { L = "Learn", R = "Relax", C = "Compete" }
    local tips = { L = "Groups listed as Learning.", R = "Groups listed as Relaxed.", C = "Groups listed as Competitive." }
    local need = 0
    for i, code in ipairs(Filters.STYLES) do
        local b = SetMember(v, words[code], "styles", code, Filters.STYLES, Filters.STYLE_NAME[code], tips[code])
        style[i] = b
        need = need + b:GetFontString():GetStringWidth()
    end
    local spare = (INNER - (#style - 1) * COL - need) / #style
    local x = 0
    for _, b in ipairs(style) do
        local w = b:GetFontString():GetStringWidth() + spare
        b:SetSize(w, BTN)
        b:SetPoint("TOPLEFT", x, y)
        x = x + w + COL
    end
    y = y - BTN - GAP
    y = RegionRow(v, y)
    -- A drag runs the list once per short pause, not on every step.
    local queued
    v.score = Kit.Slider(v, INNER, 4000, 50, "Min Score", function(n)
        editing.minScore = n > 0 and n or nil
        if queued then return end
        queued = true
        C_Timer.After(0.15, function() queued = false; Changed() end)
    end)
    v.score:SetPoint("TOPLEFT", 0, y)
    Kit.Tip(v.score, "Min Score", "Hides groups whose leader's Mythic+ score is below this. Friends' and guildmates' groups always show.")
    -- Footer: Reset, this week's affixes behind one icon, the runs.
    local reset = ResetButton(v, 52)
    reset:SetPoint("BOTTOMLEFT")
    local aff = CreateFrame("Button", nil, v)
    aff:SetSize(BTN, BTN)
    Kit.Button(aff)
    aff:SetPoint("LEFT", reset, "RIGHT", COL, 0)
    aff.icon = aff:CreateTexture(nil, "ARTWORK")
    aff.icon:SetSize(16, 16)
    aff.icon:SetPoint("CENTER")
    aff.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)
    aff:HookScript("OnEnter", Week.AffixTooltip)
    aff:HookScript("OnLeave", GameTooltip_Hide)
    v.aff = aff
    v.runs = RunsButton(v, INNER - 52 - BTN - 2 * COL)
    v.runs:SetPoint("LEFT", aff, "RIGHT", COL, 0)
    function v:Paint()
        local a = Kit.Accent()
        self.title:SetTextColor(a[1], a[2], a[3])
        local best = {}
        for _, d in ipairs(Filters.Dungeons()) do best[d.name] = d.best end
        for _, b in ipairs(dungeonButtons) do
            b.bestLevel = best[b.dungeon]
            b.best:SetText(b.bestLevel and ("+" .. b.bestLevel) or "\226\128\148")
            b:Paint(not editing.dungeons or editing.dungeons[b.dungeon] == true)
        end
        SyncToggles(self)
        self.score:SetValue(editing.minScore or 0)
        local first = Week.Affixes()[1]
        self.aff.icon:SetTexture(first and first.icon or 134400)
        self.runs:Sync()
    end
    return v
end

-- ---------------------------------------------------------------------------
-- Raids
-- ---------------------------------------------------------------------------
local LINE_H = 18

local function BuildRaid()
    local v = CreateFrame("Frame", nil, frame)
    local y = Title(v, "Filters")
    y = SetRow(v, y, "diffs", { "N", "H", "M" }, { N = "Normal", H = "Heroic", M = "Mythic" }, "Groups at this difficulty.")
    y = RegionRow(v, y)
    -- My Lockout: one switch for every raid (Filters.Lockout).
    local mine = Kit.Toggle(v, "", INNER, function()
        local was = editing.lockout == true or (type(editing.lockout) == "table" and next(editing.lockout) ~= nil)
        editing.lockout = (not was) or nil
        ns.Log.Emit("filter", { action = "my lockout", name = editing.lockout and "on" or "off" })
        Sidecar.Paint(); Changed()
    end, BTN)
    mine:SetPoint("TOPLEFT", 0, y)
    local label = IconLabel(mine, "My Lockout", {})
    local lk = Lock(label)
    lk:SetPoint("LEFT", label, "RIGHT", 4, 0)
    label:SetPoint("CENTER", -5, 0)
    Kit.Tip(mine, "My Lockout", "Hides groups with no loot left for you this week. Groups behind you still show (they may be skipping). Your kills are dimmed with a lock.")
    function mine:Sync() self:Paint(editing.lockout == true or (type(editing.lockout) == "table" and next(editing.lockout) ~= nil)) end
    toggles[#toggles + 1] = mine
    y = y - BTN - GAP
    local rule = Kit.Rule(v)
    rule:SetPoint("TOPLEFT", 0, y - 2)
    rule:SetPoint("TOPRIGHT", 0, y - 2)
    y = y - 5 - GAP
    -- The raid list scrolls (wheel) down to the footer; a chevron says there's more.
    local scroll = CreateFrame("ScrollFrame", nil, v)
    scroll:SetPoint("TOPLEFT", 0, y)
    scroll:SetPoint("BOTTOMRIGHT", 0, BTN + GAP)
    local box = CreateFrame("Frame", nil, scroll)
    box:SetSize(INNER, 1)
    scroll:SetScrollChild(box)
    scroll.more = Kit.More(scroll)
    function scroll:Clamp(to)
        local most = math.max(0, box:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.min(math.max(0, to), most))
        self.more:Set(self:GetVerticalScroll() < most - 1)
    end
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta) self:Clamp(self:GetVerticalScroll() - delta * 36) end)
    v.box, v.scroll, v.lines = box, scroll, {}

    local foot = ResetButton(v, Cell(3))
    foot:SetPoint("BOTTOMLEFT")
    HistoryButton(v, INNER - Cell(3) - COL):SetPoint("BOTTOMRIGHT")
    return v
end

-- Pooled lines: a raid (tickbox + fold header), or a boss (indented tickbox).
local function RaidLine(v, n)
    local l = v.lines[n]
    if l then return l end
    l = CreateFrame("Frame", nil, v.box)
    l:SetHeight(LINE_H)
    l.check = Kit.Check(l, "", function(on)
        if l.raid then  -- a raid: show its groups or not
            editing.raidsOff = editing.raidsOff or {}
            editing.raidsOff[l.raid] = not on or nil
            if not next(editing.raidsOff) then editing.raidsOff = nil end
        else
            editing.bosses = editing.bosses or {}
            editing.bosses[l.bossRaid] = editing.bosses[l.bossRaid] or {}
            editing.bosses[l.bossRaid][l.boss] = on or nil
        end
        Sidecar.Paint(); Changed()
    end)
    l.check:SetPoint("LEFT")
    Kit.Tip(l.check, function() return l.raid or l.boss end, function()
        if l.raid then return "Show this raid's groups." end
        return "Only groups with this boss still alive."
    end)
    -- The fold header: arrow and name, it only folds (one raid open at a time).
    l.fold = CreateFrame("Button", nil, l)
    l.fold:SetPoint("LEFT", l.check.well, "RIGHT", 4, 0)
    l.fold:SetPoint("RIGHT")
    l.fold:SetHeight(LINE_H)
    l.arrow = Kit.Arrow(l.fold, 10)
    l.arrow:SetPoint("LEFT")
    l.name = l.fold:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    l.name:SetPoint("LEFT", 14, 0)
    l.name:SetPoint("RIGHT")
    l.name:SetJustifyH("LEFT")
    l.name:SetWordWrap(false)
    l.fold:SetScript("OnClick", function()
        openRaid = (openRaid == l.raid) and false or l.raid
        Sidecar.Paint()
    end)
    l.lock = Lock(l, true)
    l.lock:SetPoint("RIGHT", -2, 0)
    v.lines[n] = l
    return l
end

local function PaintRaid(v)
    local raids = ns.Groups.Raids()
    if openRaid == nil then
        -- First look: the raid with boss rules set, else the one with the most bosses.
        local pick
        for _, raid in ipairs(raids) do
            local rules = editing.bosses and editing.bosses[raid.name]
            if rules and next(rules) then pick = raid; break end
            if not pick or #raid.bosses > #pick.bosses then pick = raid end
        end
        if pick then openRaid = pick.name end
    end
    local lockOn = editing.lockout == true or type(editing.lockout) == "table"
    local a = Kit.Accent()
    local y, n = 0, 0
    for _, raid in ipairs(raids) do
        n = n + 1
        local h = RaidLine(v, n)
        local single = #raid.bosses == 1  -- one boss: the raid tick is the boss tick
        if single and editing.bosses then editing.bosses[raid.name] = nil end
        local open = openRaid == raid.name and not single
        h.raid, h.boss = raid.name, nil
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", 0, y)
        h:SetPoint("RIGHT")
        h.check:ClearAllPoints()
        h.check:SetPoint("LEFT")
        h.check:SetLabel("")
        h.check:Set(not (editing.raidsOff and editing.raidsOff[raid.name]))
        h.fold:Show()
        h.arrow:SetShown(not single)
        h.arrow:SetRotation(open and 0 or math.pi / 2)
        h.name:SetText(raid.name)
        local c = open and a or { 0.44, 0.44, 0.44 }
        h.name:SetTextColor(c[1], c[2], c[3])
        h.arrow:SetVertexColor(c[1], c[2], c[3])
        local mine = lockOn and select(2, Filters.ShownLockout(raid.name, editing.diffs))
        h.lock:SetShown(single and mine and mine[raid.bosses[1]] == true or false)
        -- The name stops short of the lock (truncating), never under it.
        h.name:SetPoint("RIGHT", h.fold, "RIGHT", h.lock:IsShown() and -12 or 0, 0)
        h:Show()
        y = y - LINE_H - 2
        for _, boss in ipairs(open and raid.bosses or {}) do
            n = n + 1
            local l = RaidLine(v, n)
            l.raid, l.bossRaid, l.boss = nil, raid.name, boss
            l:ClearAllPoints()
            l:SetPoint("TOPLEFT", 10, y)
            l:SetPoint("RIGHT")
            l.fold:Hide()
            l.check:SetLabel(boss)
            local rules = editing.bosses and editing.bosses[raid.name]
            l.check:Set(rules and rules[boss])
            local killed = mine and mine[boss] == true
            local g = killed and 0.44 or 1
            l.check.label:SetTextColor(g, g, g)
            l.lock:SetShown(killed or false)
            l:Show()
            y = y - LINE_H - 2
        end
    end
    for i = n + 1, #v.lines do v.lines[i]:Hide() end
    if n == 0 then
        v.empty = v.empty or Label(v.box, "Raids show here once they're in the results.")
        v.empty:SetPoint("TOPLEFT")
        v.empty:SetPoint("RIGHT")
        v.empty:SetJustifyH("LEFT")
        v.empty:SetWordWrap(true)
    end
    if v.empty then v.empty:SetShown(n == 0) end
    v.box:SetHeight(math.max(1, -y))
    v.scroll:Clamp(v.scroll:GetVerticalScroll())
end

-- ---------------------------------------------------------------------------
-- Leading: applicants who miss these are dimmed, with the reason on hover.
-- ---------------------------------------------------------------------------
local function BuildLead()
    local v = CreateFrame("Frame", nil, frame)
    local y = Title(v, "Leading")
    y = RegionRow(v, y, "applicant")
    v.floorLabel = Label(v, "")
    v.floorLabel:SetTextColor(1, 1, 1)
    v.floorLabel:SetPoint("TOPLEFT", 0, y - 4)
    v.floor = Kit.Edit(v, 56, function(text)
        local n = tonumber(text)
        local key = editing.kind == "lead_keys" and "minScore" or "minIlvl"
        editing[key] = (n and n > 0) and n or nil
        Changed()
    end, true)
    Kit.Hint(v.floor, "Any")
    v.floor:SetPoint("TOPRIGHT", 0, y)
    local note = Label(v, "Applicants who don't match are dimmed, with the reason on hover. Nobody is hidden.")
    note:SetPoint("TOPLEFT", 0, y - 30)
    note:SetPoint("RIGHT")
    note:SetJustifyH("LEFT")
    note:SetWordWrap(true)
    ResetButton(v, INNER):SetPoint("BOTTOMLEFT")
    function v:Paint()
        local keys = editing.kind == "lead_keys"
        local a = Kit.Accent()
        self.title:SetTextColor(a[1], a[2], a[3])
        self.title:SetText(keys and "Leading a Key" or "Leading a Raid")
        self.floorLabel:SetText(keys and "Score at least" or "Item level at least")
        local n = keys and editing.minScore or editing.minIlvl
        self.floor:SetText((n or 0) > 0 and tostring(n) or "")
        SyncToggles(self)
    end
    return v
end

-- ---------------------------------------------------------------------------
-- Settings and notes (standalone; with AES they're tabs in its settings)
-- ---------------------------------------------------------------------------
-- { key, label, tooltip, get(), set(on) }; every change is logged. The AES
-- tab builds from the same list.
Sidecar.OPTIONS = {
    { "noChime", "Chime When Group Fills", "Plays a short tone when a dungeon group you joined through a sign-up reaches five.",
      function() return not ns.db.noChime end, function(on) ns.db.noChime = (not on) or nil end },
    { "noShimmer", "Shimmer What's New", "One quick shimmer across a row that's news: a group new to your list (with fewer than 20 listed), a sign-up whose status just changed, a new applicant when you lead. New groups keep their white edge either way.",
      function() return not ns.db.noShimmer end, function(on) ns.db.noShimmer = (not on) or nil end },
    { "nameColors", "Color Names", "Like Blizzard's list: group names turn blue with a friend in, green with a guildmate (blue wins when both). Replaces the marks.",
      function() return ns.db.nameColors end, function(on) ns.db.nameColors = on or nil; ns.Pane.Render() end },
    { "hideDecliners", "Hide Decliners", "Once a leader turns down your sign-up, their groups are hidden (under the hidden count) until you /reload. Full or delisted groups don't count.",
      function() return ns.db.hideDecliners end, function(on) ns.db.hideDecliners = on or nil; ns.Pane.Render() end },
    { "swap", "Swap When Full", "With all five sign-ups in use, a group's button reads Swap: click it to withdraw your oldest sign-up, then Apply.",
      function() return ns.db.swap end, function(on) ns.db.swap = on or nil; ns.Pane.Render() end },
    { "noteStrip", "Notes Under Sign-Up", "Your sign-up notes, ready to copy, under Blizzard's sign-up window.",
      function() return ns.Notes.StripOn() end, function(on) ns.db.noteStrip = (not on) and false or nil end },
    { "cleanup", "Clean Up the List", "Hides listings that are listed longer than 3 hours, look like adverts (no leader score and the voice chat field filled in), offer a carry, or are led by a blacklisted player. Right-click a row to report, blacklist or hide its leader.",
      function() local c = ns.db.cleanup; return c.stale or c.advert or c.carry or c.blacklist end,
      function(on) for _, k in ipairs({ "stale", "advert", "carry", "blacklist" }) do ns.db.cleanup[k] = on end; ns.Pane.Render() end },
    { "noHints", "Hide Hint Tooltips", "Hides the tooltips that explain how a control works. Tooltips with information always show.",
      function() return ns.db.noHints end, function(on) ns.db.noHints = on or nil end },
    { "useBlizzard", "Use Blizzard's List", "Blizzard's own group list instead of PickupGroup's. A PickupGroup button on Blizzard's panel brings it back.",
      function() return ns.db.useBlizzard end,
      function(on) ns.db.useBlizzard = on; if on then ns.Filters.RestoreBlizzard() end; ns.Pane.Update() end },
}

function Sidecar.SetOption(o, on)
    o[5](on)
    ns.Log.Emit("setting", { key = o[1], on = on })
end

local function DoneButton(v)
    local b = Button(v, "Done", INNER, function() Sidecar.Open(nil, nil) end)
    b:SetPoint("BOTTOMLEFT")
    return b
end

local function BuildSettings()
    local v = CreateFrame("Frame", nil, frame)
    local y = Title(v, "Settings")
    v.switches = {}
    for _, o in ipairs(Sidecar.OPTIONS) do
        local cb = Kit.Check(v, o[2], function(on) Sidecar.SetOption(o, on) end)
        cb:SetPoint("TOPLEFT", 0, y)
        Kit.Tip(cb, o[2], o[3])
        cb.get = o[4]
        v.switches[#v.switches + 1] = cb
        y = y - 22
    end
    y = y - 4
    v.count = Label(v, "")
    v.count:SetPoint("TOPLEFT", 0, y - 5)
    local clear = Button(v, "Clear", 52, nil, 20)
    clear:SetPoint("TOPRIGHT", 0, y)
    Kit.Confirm(clear, "Clear", function() ns.Cleanup.Clear(); v:Paint(); ns.Pane.Render() end)
    Kit.Tip(clear, "Clear", "Empties the blacklist. Click twice.")
    y = y - 26
    v.why = Label(v, "")
    v.why:SetPoint("TOPLEFT", 0, y)
    v.why:SetPoint("RIGHT")
    v.why:SetJustifyH("LEFT")
    v.why:SetWordWrap(true)
    local w = Kit.Palette.warn
    v.why:SetTextColor(w[1], w[2], w[3])
    DoneButton(v)
    function v:Paint()
        local a = Kit.Accent()
        self.title:SetTextColor(a[1], a[2], a[3])
        for _, cb in ipairs(self.switches) do cb:Set(cb.get()) end
        local n = ns.Cleanup.Count()
        self.count:SetText(("Blacklist: %d leader%s"):format(n, n == 1 and "" or "s"))
        local why = ns.Notes.Conflict()
        self.why:SetText(why and ("Notes under sign-up are off: " .. why .. ".") or "")
        Sidecar.CheckConflict()
    end
    return v
end

local function BuildNotes()
    local v = CreateFrame("Frame", nil, frame)
    local y = Title(v, "Sign-Up Notes")
    local intro = Label(v, "Shift-click Apply to sign up with a note: these are offered to copy under Blizzard's sign-up window. A plain click signs up at once.")
    intro:SetPoint("TOPLEFT", 0, y)
    intro:SetPoint("RIGHT")
    intro:SetJustifyH("LEFT")
    intro:SetWordWrap(true)
    v.why = Label(v, "")
    v.why:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -6)
    v.why:SetPoint("RIGHT")
    v.why:SetJustifyH("LEFT")
    v.why:SetWordWrap(true)
    local w = Kit.Palette.warn
    v.why:SetTextColor(w[1], w[2], w[3])
    v.boxes = {}
    local prev = v.why
    for i = 1, ns.Notes.MAX do
        local e = Kit.Edit(v, INNER, function(text) ns.Notes.Set(i, text) end)
        e:SetMaxLetters(255)
        e:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, i == 1 and -10 or -6)
        Kit.Hint(e, "Note " .. i)
        v.boxes[i] = e
        prev = e
    end
    DoneButton(v)
    function v:Paint()
        local a = Kit.Accent()
        self.title:SetTextColor(a[1], a[2], a[3])
        local why = ns.Notes.Conflict()
        self.why:SetText(why and ("Not shown under Blizzard's window: " .. why .. ".") or "")
        local list = ns.Notes.All()
        for i, e in ipairs(self.boxes) do e:SetText(list[i] or "") end
    end
    return v
end

-- ---------------------------------------------------------------------------
-- The panel
-- ---------------------------------------------------------------------------
local function Build()
    Kit.ApplyFontFace()
    frame = CreateFrame("Frame", "PickupGroupSidecar", PVEFrame)
    frame:SetWidth(W)
    frame:EnableMouse(true)
    Kit.Fill(frame, Kit.Palette.panelBg)
    Kit.Border(frame)
    local function Fit(v)
        v:SetPoint("TOPLEFT", PAD, -PAD)
        v:SetPoint("BOTTOMRIGHT", -PAD, PAD)
        v:Hide()
        return v
    end
    views.quick = Fit(BuildQuick())
    views.keys = Fit(BuildKeys())
    local raid = Fit(BuildRaid())
    function raid:Paint()
        local a = Kit.Accent()
        self.title:SetTextColor(a[1], a[2], a[3])
        SyncToggles(self)
        PaintRaid(self)
    end
    views.raid = raid
    views.lead = Fit(BuildLead())
    views.options = Fit(BuildSettings())
    views.notes = Fit(BuildNotes())
    prompt = BuildPrompt(frame)
    prompt:SetPoint("TOPLEFT", PAD, -PAD)
    prompt:SetPoint("BOTTOMRIGHT", -PAD, 44)
    function prompt:Paint() PaintPrompt() end
    views.clash = prompt
    -- Raider.IO's profile panel (when loaded) moves over to the panel's
    -- right edge while it's open, and back when it closes.
    frame:HookScript("OnShow", Sidecar.MoveRaiderIO)
    frame:HookScript("OnHide", Sidecar.MoveRaiderIO)
    frame:Hide()
end

-- What the panel shows now: a view picked from the menu, else what the Group Finder is on.
local function Pick()
    if override and views[override] then return override end
    local lead = ns.Leader.Kind and ns.Leader.Kind()
    if lead then editing = Filters.Active("lead_" .. lead); return "lead" end
    if ns.Pane.Shown and ns.Pane.Shown() then
        local kind = Filters.Kind()
        editing = Filters.Active(kind)
        return kind
    end
    return "quick"
end

-- Where it docks: the Group Finder's right edge, or past AES's own panel
-- while that one is still on (the clash prompt offers to turn it off).
local function Dock()
    local aes = _G.AE_GroupFinderPanel
    local to = (aes and aes:IsShown()) and aes or PVEFrame
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", to, "TOPRIGHT", 2, 0)
    frame:SetPoint("BOTTOMLEFT", to, "BOTTOMRIGHT", 2, 0)
end

-- Shown with Dungeons & Raids, except on Blizzard's listing form (the quick list docks there).
local function Wanted()
    if ns.SteppedAside() then return false end
    if not (PVEFrame and PVEFrame:IsShown() and GroupFinderFrame and GroupFinderFrame:IsVisible()) then return false end
    local ec = LFGListFrame and LFGListFrame.EntryCreation
    return not (ec and ec:IsVisible())
end

function Sidecar.Update()
    if not Wanted() then
        if frame then frame:Hide() end
        override = nil
        return
    end
    if not frame then Build() end
    Dock()
    local was = mode
    mode = Pick()
    if mode ~= was then openRaid = nil end
    for name, v in pairs(views) do v:SetShown(name == mode) end
    if mode == "raid" then RequestRaidInfo() end  -- lockouts for My Lockout
    frame:Show()
    Sidecar.Paint()
end

function Sidecar.Paint()
    if not (frame and frame:IsShown() and mode) then return end
    local v = views[mode]
    if (mode == "keys" or mode == "raid" or mode == "lead") and not editing then return end
    if v and v.Paint then v:Paint() end
end

-- Open a view from the menu ("options", "notes", "clash"); nil goes back to
-- the filters. Opening the one already open goes back too.
function Sidecar.Open(f, which)
    if which == "filter" then which = nil end
    if which and override == which then which = nil end
    override = which
    if f then editing = f end
    Sidecar.Update()
end
-- Put a view up without toggling (the clash prompt, Later).
function Sidecar.Show(which)
    override = (which ~= "filter") and which or nil
    Sidecar.Update()
end

-- Raider.IO places its profile panel by anchoring a small frame to the
-- Group Finder's right edge (and re-places it whenever it updates). While
-- one of our docked panels is open (this one, or the quick list beside
-- Blizzard's listing form) that anchor follows the panel instead; only an
-- anchor on the Group Finder or one of our panels is touched (a
-- user-placed panel stays put).
local rioHooked, moving
local RIO_GAP = 2  -- a little air between our panel and Raider.IO's
function Sidecar.MoveRaiderIO()
    local a = _G.RaiderIO_ProfileTooltipAnchor
    if not a then return end
    if not rioHooked then
        rioHooked = true
        hooksecurefunc(a, "SetPoint", function(_, _, rel) if not moving and rel == PVEFrame then Sidecar.MoveRaiderIO() end end)
    end
    local p, rel, rp, x, y = a:GetPoint()
    local ql = ns.QuickList and ns.QuickList.Panel()
    local dock = (frame and frame:IsShown() and frame) or (ql and ql:IsShown() and ql) or PVEFrame
    if rel == dock or not (rel == PVEFrame or rel == frame or (ql and rel == ql)) then return end
    moving = true
    a:ClearAllPoints()
    a:SetPoint(p, dock, rp, x + (rel == PVEFrame and RIO_GAP or 0) - (dock == PVEFrame and RIO_GAP or 0), y)
    moving = false
end

-- New results can bring raids the list hasn't shown yet.
function Sidecar.RefreshBosses()
    if frame and frame:IsShown() and mode == "raid" then Sidecar.Paint() end
end

ns.On("UPDATE_INSTANCE_INFO", function() Sidecar.RefreshBosses() end)  -- lockouts arrived
ns.On("CHALLENGE_MODE_MAPS_UPDATE", function() Sidecar.Paint() end)
ns.On("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE", function() Sidecar.Paint() end)

-- The pane and the leader view call these when they appear or go.
function Sidecar.Close() Sidecar.Update() end
function Sidecar.Follow() Sidecar.Update() end

EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder", function()
    PVEFrame:HookScript("OnShow", Sidecar.Update)
    PVEFrame:HookScript("OnHide", Sidecar.Update)
    if GroupFinderFrame then
        GroupFinderFrame:HookScript("OnShow", Sidecar.Update)
        GroupFinderFrame:HookScript("OnHide", Sidecar.Update)
    end
    local lfg = LFGListFrame
    for _, key in ipairs({ "CategorySelection", "SearchPanel", "EntryCreation", "ApplicationViewer" }) do
        local f = lfg and lfg[key]
        if f then f:HookScript("OnShow", Sidecar.Update); f:HookScript("OnHide", Sidecar.Update) end
    end
    if C_MythicPlus.RequestMapInfo then C_MythicPlus.RequestMapInfo() end
    if C_MythicPlus.RequestCurrentAffixes then C_MythicPlus.RequestCurrentAffixes() end
end)

-- ---------------------------------------------------------------------------
-- Clashes: another addon doing the same job on the same Blizzard frame.
-- While one stands, PickupGroup's part is off (AES's own Group Finder panel:
-- ours docks past it). The choice waits in the panel (the clash prompt): ticked = theirs stays on; untick to turn
-- theirs off from the next reload (we write that one setting in its saved
-- settings). One chat line says so at login or when a clash starts.
-- ---------------------------------------------------------------------------
-- { why(), db key, log line, their feature, our part, set(on) on theirs }
local function EUISet(k, on) if type(EllesmereUIDB) == "table" then EllesmereUIDB[k] = on end end
local CLASHES = {
    { function() return ns.Notes.Conflict() end, "noteConflict", "notes under Blizzard's window",
      "EllesmereUI's Persistent Signup Note", "sign-up notes",
      function(on) EUISet("persistSignupNote", on) end },
    -- Already on Blizzard's list: nothing overlaps.
    { function() return not ns.db.useBlizzard and ns.FinderClash() or nil end, "finderConflict", "group finder overlap",
      "EllesmereUI's Group Finder", "group list",
      function(on) local gf = type(EllesmereUIDB) == "table" and EllesmereUIDB.groupFinder; if type(gf) == "table" then gf.enabled = on end end },
    { function() return ns.QuickList and ns.QuickList.Clash() end, "quickConflict", "quick list",
      "atrocityEssentials' LFG Quick Create", "quick list",
      function(on)
          local ae = _G.atrocityEssentials
          if type(ae) ~= "table" or not ae.GetModule then return end
          local ok, qc = pcall(ae.GetModule, ae, "LFGQuickCreate", true)
          if ok and type(qc) == "table" and type(qc.db) == "table" then qc.db.QuickCreate = on end
      end },
    { function() return ns.AES.PanelClash() end, "aesPanelConflict", "aes group finder panel",
      "atrocityEssentials' Group Finder Panel", "filter panel",
      function(on) ns.AES.SetPanel(on) end },
}
-- asking = the prompt opens with the Group Finder (until Later).
local function Standing()
    local list = {}
    for _, c in ipairs(CLASHES) do if c[1]() then list[#list + 1] = c end end
    return list
end

function BuildPrompt(parent)
    local v = CreateFrame("Frame", nil, parent)
    v.title = v:CreateFontString(nil, "OVERLAY", "PickupGroupFontLarge")
    v.title:SetPoint("TOPLEFT")
    v.title:SetPoint("RIGHT")
    v.title:SetJustifyH("LEFT")
    v.title:SetWordWrap(true)
    v.note = Label(v, "")
    v.note:SetPoint("TOPLEFT", v.title, "BOTTOMLEFT", 0, -6)
    v.note:SetPoint("RIGHT")
    v.note:SetJustifyH("LEFT")
    v.note:SetWordWrap(true)
    v.note:SetTextColor(Kit.Palette.soft[1], Kit.Palette.soft[2], Kit.Palette.soft[3])
    v.rows = {}
    for i, c in ipairs(CLASHES) do
        local cb = Kit.Check(v, c[4], function(on)
            c[6](on)
            ns.clashHold[c[2]] = (not on) and (c.why or (c[4] .. " is on")) or nil  -- ours stays off until the reload
            ns.Log.Emit("setting", { key = c[4] .. " from next reload", on = on })
        end)
        Kit.Tip(cb, c[4], "Ticked: on. Untick to turn it off from your next reload; PickupGroup's " .. c[5] .. " come back then.")
        v.rows[i] = cb
    end
    -- Footer band: the actions, the main one first from the right.
    local foot = Kit.Strip(parent, "BOTTOM", 36)
    local reload = CreateFrame("Button", nil, foot)
    reload:SetSize(84, 20)
    reload:SetPoint("RIGHT", -PAD, 0)
    Kit.Button(reload)
    reload:SetText("Reload now")
    reload:SetScript("OnClick", function() ns.Log.Emit("setting", { key = "clash: reload", on = true }); C_UI.Reload() end)
    local later = CreateFrame("Button", nil, foot)
    later:SetSize(60, 20)
    later:SetPoint("RIGHT", reload, "LEFT", -8, 0)
    Kit.Button(later)
    later:SetText("Later")
    later:SetScript("OnClick", function()
        asking = nil
        ns.Log.Emit("setting", { key = "clash: later", on = false })
        Sidecar.Show("filter")
    end)
    v.foot = foot
    v:SetScript("OnShow", function() foot:Show() end)
    v:SetScript("OnHide", function() foot:Hide() end)
    v:Hide()
    return v
end

function PaintPrompt()
    local v, list = prompt, Standing()
    v.title:SetText(#list == 1 and ("Turn off " .. list[1][4] .. "?") or "Turn off the overlapping features?")
    local parts = {}
    for _, c in ipairs(list) do parts[#parts + 1] = c[4] .. " does the job of PickupGroup's " .. c[5] .. "." end
    v.note:SetText(table.concat(parts, " ") .. " While " .. (#list == 1 and "it's" or "they're")
        .. " on, PickupGroup's part is off. Untick to turn " .. (#list == 1 and "it" or "them") .. " off from your next reload.")
    local y = -(v.title:GetStringHeight() + 6 + v.note:GetStringHeight() + 12)
    for i, c in ipairs(CLASHES) do
        local cb = v.rows[i]
        cb:SetShown(c[1]() ~= nil or ns.clashHold[c[2]] ~= nil)
        if cb:IsShown() then
            cb:ClearAllPoints()
            cb:SetPoint("TOPLEFT", 0, y)
            cb:Set(ns.clashHold[c[2]] == nil)
            y = y - 24
        end
    end
end

-- atLoad (login / reload): every clash still on is said again. Otherwise
-- only one that just started (an option switched on mid-session). One chat
-- line; the prompt waits in the sidecar.
function Sidecar.CheckConflict(atLoad)
    local parts = {}
    for _, c in ipairs(CLASHES) do
        local why, key, logKey = c[1](), c[2], c[3]
        c.why = why or c.why
        if why and (atLoad or ns.db[key] ~= why) then
            if ns.db[key] ~= why then ns.Log.Emit("setting", { key = logKey .. " (" .. why .. ")", on = false }) end
            ns.db[key] = why
            parts[#parts + 1] = c
        elseif not why and ns.db[key] then
            ns.db[key] = nil
            ns.Log.Emit("setting", { key = logKey .. " (clash gone)", on = true })
        end
    end
    if #parts == 0 then return end
    asking = true
    local names = {}
    for i, c in ipairs(parts) do names[i] = c[4] end
    ns.Print(table.concat(names, " and ") .. (#parts == 1 and " overlaps" or " overlap")
        .. " PickupGroup, so PickupGroup's part is off. Open the Group Finder to choose.")
    if frame and frame:IsShown() then Sidecar.Show("clash") end
end

-- The prompt opens with the Group Finder while a clash is waiting for a choice.
EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder", function()
    PVEFrame:HookScript("OnShow", function()
        if asking and #Standing() > 0 then Sidecar.Show("clash") end
    end)
end)

-- Mid-session: another addon's option switched on (or off) without a reload.
-- Checked every 2 s (a few table reads); a change re-runs the check, which
-- alerts on a new clash, and the quick list steps aside or comes back.
ns.On("PLAYER_LOGIN", function()
    local last
    C_Timer.NewTicker(2, function()
        -- (Each returns nothing when there's no clash, so "or".)
        local now = (ns.Notes.Conflict() or "") .. "|" .. (ns.FinderClash() or "") .. "|" .. (ns.QuickList.Clash() or "")
            .. "|" .. (ns.AES.PanelClash() or "") .. "|" .. tostring(ns.SteppedAside())
        if now == last then return end
        local first = last == nil
        last = now
        if not first then Sidecar.CheckConflict(); ns.QuickList.Update(); ns.Pane.Update(); Sidecar.Update() end
    end)
end)

-- As soon as the UI is up on login or reload (not on every loading screen).
ns.On("PLAYER_ENTERING_WORLD", function(login, reload)
    if login or reload then C_Timer.After(0, function() Sidecar.CheckConflict(true) end) end
end)

-- The notes, ready to copy, under Blizzard's sign-up dialog while it's open:
-- click one to select it, then Ctrl+C and Ctrl+V into Blizzard's note box.
EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder", function()
    local dialog = LFGListApplicationDialog
    if not dialog then return end
    local strip
    local function Refresh()
        local notes = ns.Notes.List()
        Sidecar.CheckConflict()
        if #notes == 0 or not ns.Notes.StripOn() then if strip then strip:Hide() end return end
        if not strip then
            Kit.ApplyFontFace()
            strip = CreateFrame("Frame", nil, dialog)
            strip:SetPoint("TOPLEFT", dialog, "BOTTOMLEFT", 0, -2)
            strip:SetPoint("TOPRIGHT", dialog, "BOTTOMRIGHT", 0, -2)
            Kit.Fill(strip, Kit.Palette.panelBg)
            Kit.Border(strip)
            local l = Label(strip, "Notes: click one, Ctrl+C, then Ctrl+V above")
            l:SetPoint("TOPLEFT", PAD, -6)
            l:SetPoint("RIGHT", -PAD, 0)
            l:SetJustifyH("LEFT")
            l:SetWordWrap(false)
            strip.boxes = {}
            for i = 1, ns.Notes.MAX do
                local e = Kit.Edit(strip, 10, function() end)
                e:SetPoint("TOPLEFT", PAD, -20 - (i - 1) * 24)
                e:SetPoint("RIGHT", -PAD, 0)
                -- Keep the text as saved and selected, whatever gets typed.
                e:HookScript("OnTextChanged", function(self, user)
                    if user then self:SetText(self.note or ""); self:HighlightText() end
                end)
                -- Select on the next frame: a selection made while the box is
                -- still taking focus doesn't stick.
                e:HookScript("OnEditFocusGained", function(self)
                    C_Timer.After(0, function() if self:HasFocus() then self:HighlightText() end end)
                end)
                -- Only the box you're in shows a selection.
                e:HookScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
                strip.boxes[i] = e
            end
        end
        for i, e in ipairs(strip.boxes) do
            e.note = notes[i]
            e:SetText(notes[i] or "")
            if not e:HasFocus() then e:HighlightText(0, 0) end
            e:SetShown(notes[i] ~= nil)
        end
        strip:SetHeight(26 + #notes * 24)
        strip:Show()
        -- Next frame: the dialog may still be taking focus when it opens.
        C_Timer.After(0, function() if strip:IsVisible() then strip.boxes[1]:SetFocus() end end)
    end
    dialog:HookScript("OnShow", Refresh)
    -- Apply on another group while the dialog is open re-uses it (no OnShow).
    hooksecurefunc("LFGListApplicationDialog_Show", function() if dialog:IsShown() then Refresh() end end)
    dialog:HookScript("OnHide", function() if strip then strip:Hide() end end)
end)
