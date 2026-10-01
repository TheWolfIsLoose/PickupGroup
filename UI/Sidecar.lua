--[[
    PickupGroup - UI/Sidecar.lua
    The sidecar: a panel on the Group Finder's right edge for setting up a
    filter. Edits apply as they are made (no Save step). It covers
    Raider.IO's panel while open; that frame is never moved.

    Filter tab: the one filter of the kind in view
      keys  dungeons (this season), room for my role, has / needs Bloodlust,
            has / needs battle rez, leader at least my score, leader score floor
      raid  leader's realm, each boss alive / dead / either
    Notes tab: up to five sign-up notes, offered to copy under Blizzard's
    sign-up dialog.
--]]

local _, ns = ...

local Sidecar = {}
ns.Sidecar = Sidecar

local Kit, Filters = ns.Kit, ns.Filters
local W, PAD = 220, 8
local MINT = Kit.Palette.brand

local frame, editing
local keysBox, raidBox
local dungeonButtons, checks = {}, {}
local scoreBox, bossBox
local bossLines = {}
local bossLabel
local classToggles = {}
local filterView, optionsView, notesView, view = nil, nil, nil, "filter"
local headTabs = {}
local open = {}  -- raid name -> heading unfolded (this session)

local function Changed()
    ns.Pane.Render()
end

local function Label(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    fs:SetTextColor(0.55, 0.55, 0.55)
    fs:SetText(text)
    return fs
end

-- A flat toggle: mint fill when on.
local function Toggle(parent, text, w, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, 20)
    Kit.Button(b)
    b:SetNormalFontObject("PickupGroupFontSmall")
    b:SetHighlightFontObject("PickupGroupFontSmall")
    b:SetText(text)
    -- On: the choice's colour as text and a 1px ring on a neutral fill, so
    -- every colour reads (no colour-on-green). Off: grey, black ring.
    function b:Paint(on, color)
        local c = on and (color or MINT) or { 0.6, 0.6, 0.6 }
        self:GetFontString():SetTextColor(c[1], c[2], c[3], 1)
        local ring = on and c or Kit.Palette.border
        for _, t in ipairs(self._border) do t:SetColorTexture(ring[1], ring[2], ring[3], 1) end
    end
    b:SetScript("OnClick", onClick)
    return b
end

-- Leader's realm region: four toggles, all on by default (regions = nil).
local regionButtons = {}
local function RegionRow(box, y)
    local l = Label(box, "Leader's realm")
    l:SetPoint("TOPLEFT", 0, y)
    local codes = ns.Groups.REGIONS
    local cellW = (W - 2 * PAD - 3 * (#codes - 1)) / #codes
    for i, code in ipairs(codes) do
        local b = Toggle(box, code, cellW, function(self)
            if not editing.regions then
                editing.regions = {}
                for _, c in ipairs(codes) do editing.regions[c] = true end
            end
            editing.regions[self.region] = not editing.regions[self.region] or nil
            local all = true
            for _, c in ipairs(codes) do if not editing.regions[c] then all = false end end
            if all then editing.regions = nil end
            Sidecar.Paint(); Changed()
        end)
        b.region = code
        b:SetPoint("TOPLEFT", (i - 1) * (cellW + 3), y - 16)
        b:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(ns.Groups.REGION_NAME[self.region])
            GameTooltip:AddLine("Groups whose leader plays on a realm in this region.", 0.74, 0.74, 0.74, true)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", function() GameTooltip:Hide() end)
        regionButtons[#regionButtons + 1] = b
    end
    return y - 16 - 23
end

local function PaintRegions(f)
    for _, b in ipairs(regionButtons) do b:Paint(not f.regions or f.regions[b.region] == true) end
end

local function PaintKeys(f)
    for _, b in ipairs(dungeonButtons) do b:Paint(not f.dungeons or f.dungeons[b.dungeon] == true) end
    for key, c in pairs(checks) do c:Set(f[key]) end
    for _, cb in ipairs(classToggles) do
        cb:Set((f[cb.key] == true and "missing" or f[cb.key]) == cb.want)
    end
    scoreBox:SetText((f.minScore or 0) > 0 and tostring(f.minScore) or "")
    PaintRegions(f)
end

-- Each boss cycles Either -> Alive -> Dead: raids aren't cleared in order.
local WANT_NEXT = { [false] = "alive", alive = "dead", dead = false }
local WANT_LOOK = { [false] = { "Either", { 0.55, 0.55, 0.55 } }, alive = { "Alive", MINT }, dead = { "Dead", { 1, 0.72, 0.3 } } }

local function PaintRaid(f)
    PaintRegions(f)
    bossLabel:SetText("Bosses in the group's lockout")
    -- Boss rows, pooled: a raid heading, then one row per boss.
    local y, n = 0, 0
    local function Line()
        n = n + 1
        local l = bossLines[n]
        if not l then
            l = CreateFrame("Button", nil, bossBox)
            l:SetHeight(18)
            -- A raid heading folds its bosses away.
            l:SetScript("OnClick", function(self)
                if self.raid then open[self.raid] = not open[self.raid]; PaintRaid(editing) end
            end)
            l.text = l:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
            l.text:SetPoint("LEFT")
            l.text:SetPoint("RIGHT", -60, 0)
            l.text:SetJustifyH("LEFT")
            l.text:SetWordWrap(false)
            l.want = Toggle(l, "", 56, function(self)
                if self.lockout then
                    local text = Filters.MatchLockout(editing, self.raid)
                    open[self.raid] = true
                    Sidecar.Paint(); Changed()
                    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(text, 1, 1, 1, 1, true); GameTooltip:Show()
                    return
                end
                local rules = editing.bosses or {}
                editing.bosses = rules
                rules[self.raid] = rules[self.raid] or {}
                rules[self.raid][self.boss] = WANT_NEXT[rules[self.raid][self.boss] or false] or nil
                Sidecar.Paint(); Changed()
            end)
            l.want:SetHeight(16)
            l.want:SetPoint("RIGHT")
            l.want:HookScript("OnEnter", function(self)
                if not self.lockout then return end
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText("Match my lockout", 1, 1, 1)
                GameTooltip:AddLine("Bosses you've killed this week: Dead. Bosses you still need: Alive. "
                    .. "Uses your highest Normal or Heroic lockout. "
                    .. "Mythic lockouts are whole: saved on Mythic, only your own lockout's group can take you.", 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)
            l.want:HookScript("OnLeave", function() GameTooltip:Hide() end)
            bossLines[n] = l
        end
        l:ClearAllPoints()
        l:SetPoint("TOPLEFT", 0, y)
        l:SetPoint("RIGHT")
        l:Show()
        y = y - 18
        return l
    end
    local raids = ns.Groups.Raids()
    -- Open by default: raids with rules set, else the one with the most bosses.
    local biggest
    for _, raid in ipairs(raids) do
        if not biggest or #raid.bosses > #biggest.bosses then biggest = raid end
    end
    for _, raid in ipairs(raids) do
        local rules = editing.bosses and editing.bosses[raid.name]
        local set = 0
        for _ in pairs(rules or {}) do set = set + 1 end
        if open[raid.name] == nil then open[raid.name] = set > 0 or raid == biggest end
        local h = Line()
        h.raid = raid.name
        h.text:SetText((open[raid.name] and "- " or "+ ") .. raid.name
            .. ((not open[raid.name] and set > 0) and ("  (" .. set .. " set)") or ""))
        h.text:SetTextColor(0.7, 0.7, 0.7)
        h.want.lockout, h.want.raid, h.want.boss = true, raid.name, nil
        h.want:SetText("My lockout")
        h.want:Paint(false)
        h.want:Show()
        for _, boss in ipairs(open[raid.name] and raid.bosses or {}) do
            local l = Line()
            l.raid = nil
            l.want.lockout = nil
            l.text:SetText(boss)
            l.text:SetTextColor(1, 1, 1)
            local want = editing.bosses and editing.bosses[raid.name] and editing.bosses[raid.name][boss] or false
            l.want.raid, l.want.boss = raid.name, boss
            l.want:SetText(WANT_LOOK[want][1])
            l.want:Paint(want ~= false, WANT_LOOK[want][2])
            l.want:Show()
        end
        y = y - 4
    end
    for i = n + 1, #bossLines do bossLines[i]:Hide() end
    if n == 0 then
        local l = Line()
        l.raid = nil
        l.text:SetText("Bosses show here once raids are in the results.")
        l.text:SetTextColor(0.55, 0.55, 0.55)
        l.want:Hide()
    end
end

function Sidecar.Paint()
    if not (frame and editing) then return end
    keysBox:SetShown(editing.kind == "keys")
    raidBox:SetShown(editing.kind == "raid")
    if editing.kind == "keys" then PaintKeys(editing) else PaintRaid(editing) end
end

local function BuildKeys(parent)
    local box = CreateFrame("Frame", nil, parent)
    local y = 0
    local head = Label(box, "Dungeons")
    head:SetPoint("TOPLEFT", 0, y)
    -- Two separate words: All turns every dungeon on, None turns them off.
    local prevWord
    for _, w in ipairs({ { "None", function() editing.dungeons = {} end }, { "All", function() editing.dungeons = nil end } }) do
        local b = CreateFrame("Button", nil, box)
        b:SetHeight(12)
        local t = Label(b, w[1])
        t:SetPoint("RIGHT")
        b:SetWidth(t:GetStringWidth())
        if prevWord then b:SetPoint("RIGHT", prevWord, "LEFT", -8, 0) else b:SetPoint("TOPRIGHT", 0, y) end
        b:SetScript("OnClick", function() w[2](); Sidecar.Paint(); Changed() end)
        b:SetScript("OnEnter", function() t:SetTextColor(MINT[1], MINT[2], MINT[3]) end)
        b:SetScript("OnLeave", function() t:SetTextColor(0.55, 0.55, 0.55) end)
        prevWord = b
    end
    y = y - 16
    local cellW = (W - 2 * PAD - 3 * 3) / 4
    for i, d in ipairs(Filters.Dungeons()) do
        local b = Toggle(box, d.code, cellW, function(self)
            -- nil means every dungeon: turning one off lists the rest.
            if not editing.dungeons then
                editing.dungeons = {}
                for _, o in ipairs(dungeonButtons) do editing.dungeons[o.dungeon] = true end
            end
            editing.dungeons[self.dungeon] = not editing.dungeons[self.dungeon] or nil
            Sidecar.Paint(); Changed()
        end)
        b.dungeon = d.name
        b:SetPoint("TOPLEFT", ((i - 1) % 4) * (cellW + 3), y - math.floor((i - 1) / 4) * 23)
        b:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(self.dungeon); GameTooltip:Show()
        end)
        b:HookScript("OnLeave", function() GameTooltip:Hide() end)
        dungeonButtons[#dungeonButtons + 1] = b
    end
    y = y - math.ceil(#dungeonButtons / 4) * 23 - 8

    for _, c in ipairs({
        { "room", "Room for my role" }, { "atLeastMine", "Leader at least my score" },
    }) do
        local key = c[1]
        local cb = Kit.Check(box, c[2], function(on) editing[key] = on or nil; Changed() end)
        cb:SetPoint("TOPLEFT", 0, y)
        checks[key] = cb
        y = y - 20
    end
    -- Bloodlust / battle rez: "has" (the group brings it) or "needs" (it
    -- doesn't, so yours fills the gap). Ticking one clears its pair.
    for _, c in ipairs({
        { "lust", "has", "Group has Bloodlust" }, { "lust", "missing", "Group needs Bloodlust" },
        { "brez", "has", "Group has battle rez" }, { "brez", "missing", "Group needs battle rez" },
    }) do
        local key, want = c[1], c[2]
        local cb = Kit.Check(box, c[3], function(on)
            editing[key] = on and want or nil
            Sidecar.Paint(); Changed()
        end)
        cb.key, cb.want = key, want
        cb:SetPoint("TOPLEFT", 0, y)
        classToggles[#classToggles + 1] = cb
        y = y - 20
    end
    y = y - 4
    local l = Label(box, "Leader score at least")
    l:SetTextColor(1, 1, 1)
    l:SetPoint("TOPLEFT", 0, y - 4)
    scoreBox = Kit.Edit(box, 56, function(text)
        local n = tonumber(text)
        editing.minScore = (n and n > 0) and n or nil
        Changed()
    end, true)
    Kit.Hint(scoreBox, "Any")
    scoreBox:SetPoint("TOPRIGHT", 0, y)
    y = RegionRow(box, y - 30)
    box:SetHeight(-y + 4)
    return box
end

local function BuildRaid(parent)
    local box = CreateFrame("Frame", nil, parent)
    bossLabel = Label(box, "")
    local y = RegionRow(box, 0)
    bossLabel:SetPoint("TOPLEFT", 0, y - 8)
    bossLabel:SetWidth(W - 2 * PAD)
    bossLabel:SetJustifyH("LEFT")
    bossLabel:SetWordWrap(true)
    bossBox = CreateFrame("Frame", nil, box)
    bossBox:SetPoint("TOPLEFT", bossLabel, "BOTTOMLEFT", 0, -6)
    bossBox:SetPoint("RIGHT")
    bossBox:SetHeight(1)
    box:SetHeight(300)
    return box
end

-- Options: the switch to Blizzard's list and the clean-up rules.
-- Notes: up to Notes.MAX sign-up notes, offered to copy under Blizzard's
-- sign-up dialog (the game won't let an addon fill its note box).
local noteBoxes = {}
local function BuildNotes(parent)
    local box = CreateFrame("Frame", nil, parent)
    local intro = Label(box, "Click Apply to sign up with a note: these are offered to copy under Blizzard's sign-up window. Shift-click Apply signs up at once, no note.")
    intro:SetPoint("TOPLEFT")
    intro:SetPoint("RIGHT")
    intro:SetJustifyH("LEFT")
    intro:SetWordWrap(true)
    local prev = intro
    for i = 1, ns.Notes.MAX do
        local e = Kit.Edit(box, W - 2 * PAD, function(text) ns.Notes.Set(i, text) end)
        e:SetMaxLetters(255)
        e:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, i == 1 and -10 or -6)
        Kit.Hint(e, "Note " .. i)
        noteBoxes[i] = e
        prev = e
    end
    return box
end

local function PaintNotes()
    local list = ns.Notes.All()
    for i, e in ipairs(noteBoxes) do e:SetText(list[i] or "") end
end

local function BuildOptions(parent)
    local box = CreateFrame("Frame", nil, parent)
    local c = ns.db.cleanup
    local function Set(key, on)
        c[key] = on
        ns.Log.Emit("setting", { key = "cleanup." .. key, on = on })
        ns.Pane.Render()
    end
    local y = 0
    local blizz = Kit.Check(box, "Use Blizzard's group list instead", function(on)
        ns.db.useBlizzard = on
        ns.Log.Emit("setting", { key = "useBlizzard", on = on })
        ns.Pane.Update()
    end)
    blizz:SetPoint("TOPLEFT", 0, y)
    box.blizz = blizz
    y = y - 22
    local hint = Label(box, "A PickupGroup button on Blizzard's panel brings this back.")
    hint:SetPoint("TOPLEFT", 0, y)
    hint:SetWidth(W - 2 * PAD); hint:SetJustifyH("LEFT"); hint:SetWordWrap(true)
    y = y - 32
    local names = Kit.Check(box, "Colour names for friends / guild", function(on)
        ns.db.nameColors = on or nil
        ns.Log.Emit("setting", { key = "nameColors", on = on })
        ns.Pane.Render()
    end)
    names:SetPoint("TOPLEFT", 0, y)
    names:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Colour names for friends / guild")
        GameTooltip:AddLine("Like Blizzard's list: group names turn green with a guildmate in, blue with a friend. Replaces the marks.", 0.74, 0.74, 0.74, true)
        GameTooltip:Show()
    end)
    names:HookScript("OnLeave", function() GameTooltip:Hide() end)
    box.names = names
    y = y - 30

    local head = Label(box, "Clean-up: hide listings that...")
    head:SetPoint("TOPLEFT", 0, y)
    y = y - 18
    box.checks = {}
    for _, row in ipairs({
        { "stale", "Are listed longer than" },
        { "advert", "Look like adverts" },
        { "carry", "Offer a carry" },
        { "blacklist", "Are led by a blacklisted player" },
    }) do
        local key = row[1]
        local cb = Kit.Check(box, row[2], function(on) Set(key, on) end)
        cb:SetPoint("TOPLEFT", 0, y)
        box.checks[key] = cb
        if key == "stale" then
            local hours = Kit.Edit(box, 36, function(text)
                local n = tonumber(text)
                if n and n > 0 then c.staleHours = n; ns.Pane.Render() end
            end, true)
            hours:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            local unit = Label(box, "hours")
            unit:SetPoint("LEFT", hours, "RIGHT", 4, 0)
            box.hours = hours
        end
        y = y - 22
    end
    local tip = Label(box, "Adverts: no leader score and the voice chat field filled in. "
        .. "Right-click a row to report, blacklist or hide its leader.")
    tip:SetPoint("TOPLEFT", 0, y - 2)
    tip:SetWidth(W - 2 * PAD); tip:SetJustifyH("LEFT"); tip:SetWordWrap(true)
    y = y - 48

    box.count = Label(box, "")
    box.count:SetPoint("TOPLEFT", 0, y - 4)
    local clear = CreateFrame("Button", nil, box)
    clear:SetSize(60, 20)
    clear:SetPoint("TOPRIGHT", 0, y)
    Kit.Button(clear)
    clear:SetNormalFontObject("PickupGroupFontSmall")
    clear:SetText("Clear")
    clear:SetScript("OnClick", function(self)
        if not self.armed then
            self.armed = true; self:SetText("Sure?")
            C_Timer.After(3, function() self.armed = nil; self:SetText("Clear") end)
            return
        end
        self.armed = nil; self:SetText("Clear")
        ns.Cleanup.Clear(); Sidecar.Show("options"); ns.Pane.Render()
    end)
    box:Hide()
    return box
end

local function PaintOptions()
    local o, c = optionsView, ns.db.cleanup
    o.blizz:Set(ns.db.useBlizzard)
    o.names:Set(ns.db.nameColors)
    for key, cb in pairs(o.checks) do cb:Set(c[key]) end
    o.hours:SetText(tostring(c.staleHours or 3))
    local n = ns.Cleanup.Count()
    o.count:SetText(("Blacklist: %d leader%s"):format(n, n == 1 and "" or "s"))
end

local function Build()
    Kit.ApplyFontFace()
    frame = CreateFrame("Frame", "PickupGroupSidecar", PVEFrame)
    frame:SetWidth(W)
    frame:SetPoint("TOPLEFT", PVEFrame, "TOPRIGHT", 1, 0)
    frame:SetPoint("BOTTOMLEFT", PVEFrame, "BOTTOMRIGHT", 1, 0)
    frame:SetFrameStrata("DIALOG")  -- above Raider.IO's panel, which it covers
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    Kit.Fill(frame, { 0.06, 0.06, 0.06, 1 })
    Kit.Border(frame)

    -- Header tabs: Filter (the filter being edited) and Options.
    local prev
    for _, t in ipairs({ { "filter", "Filter" }, { "notes", "Notes" }, { "options", "Options" } }) do
        local b = CreateFrame("Button", nil, frame)
        b:SetHeight(26)
        b.text = b:CreateFontString(nil, "OVERLAY", "PickupGroupFont")
        b.text:SetPoint("LEFT")
        b.text:SetText(t[2])
        b:SetWidth(b.text:GetStringWidth())
        b.under = b:CreateTexture(nil, "OVERLAY")
        b.under:SetColorTexture(MINT[1], MINT[2], MINT[3], 1)
        b.under:SetHeight(2)
        b.under:SetPoint("BOTTOMLEFT", 0, 1)
        b.under:SetPoint("BOTTOMRIGHT", 0, 1)
        b.view = t[1]
        b:SetScript("OnClick", function(self) Sidecar.Show(self.view) end)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 14, 0) else b:SetPoint("TOPLEFT", PAD, 0) end
        headTabs[#headTabs + 1] = b
        prev = b
    end
    Kit.HeaderIcon(frame, Kit.CLOSE, "Close", function() frame:Hide() end):SetPoint("TOPRIGHT", -2, -1)
    local rule = frame:CreateTexture(nil, "OVERLAY")
    rule:SetColorTexture(0, 0, 0, 1)
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", 0, -26)
    rule:SetPoint("TOPRIGHT", 0, -26)

    local body = CreateFrame("Frame", nil, frame)
    body:SetPoint("TOPLEFT", PAD, -34)
    body:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    filterView = body
    optionsView = BuildOptions(frame)
    optionsView:SetPoint("TOPLEFT", PAD, -34)
    optionsView:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    notesView = BuildNotes(frame)
    notesView:SetPoint("TOPLEFT", PAD, -34)
    notesView:SetPoint("BOTTOMRIGHT", -PAD, PAD)

    keysBox = BuildKeys(body)
    keysBox:SetPoint("TOPLEFT")
    keysBox:SetPoint("RIGHT")
    raidBox = BuildRaid(body)
    raidBox:SetPoint("TOPLEFT")
    raidBox:SetPoint("RIGHT")

    -- Reset: the filter back to its starting rules; a second
    -- click confirms.
    local resetBtn = CreateFrame("Button", nil, body)
    resetBtn:SetSize(72, 22)
    resetBtn:SetPoint("BOTTOMLEFT")
    Kit.Button(resetBtn)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function(self)
        if not self.armed then
            self.armed = true
            self:SetText("Sure?")
            C_Timer.After(3, function() self.armed = nil; self:SetText("Reset") end)
            return
        end
        self.armed = nil
        self:SetText("Reset")
        Filters.Reset(editing)
        Sidecar.Paint(); Changed()
    end)
    frame:Hide()
end

-- Open on a filter (the active one by default); toggles when already open on it.
-- Switch the sidecar between its Filter and Options views.
function Sidecar.Show(which)
    view = which
    filterView:SetShown(which == "filter")
    optionsView:SetShown(which == "options")
    notesView:SetShown(which == "notes")
    for _, t in ipairs(headTabs) do
        local on = t.view == which
        t.text:SetTextColor(on and MINT[1] or 0.74, on and MINT[2] or 0.74, on and MINT[3] or 0.74)
        t.under:SetShown(on)
    end
    if which == "options" then PaintOptions()
    elseif which == "notes" then PaintNotes()
    else Sidecar.Paint() end
end

-- Open on a filter (the active one by default), or on Options; clicking
-- what's already showing closes it.
function Sidecar.Open(f, which)
    if not PVEFrame then return end
    if not frame then Build() end
    which = which or "filter"
    f = f or Filters.Active()
    if frame:IsShown() and view == which and (which ~= "filter" or editing == f) then frame:Hide() return end
    editing = f
    RequestRaidInfo()  -- lockouts for Match my lockout
    frame:Show()
    Sidecar.Show(which)
end

-- New results can bring raids the boss list hasn't shown yet.
function Sidecar.RefreshBosses()
    if frame and frame:IsShown() and editing and editing.kind == "raid" then PaintRaid(editing) end
end

function Sidecar.Hide()
    if frame then frame:Hide() end
end

-- The notes, ready to copy, under Blizzard's sign-up dialog while it's open:
-- click one to select it, then Ctrl+C and Ctrl+V into Blizzard's note box.
EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder", function()
    local dialog = LFGListApplicationDialog
    if not dialog then return end
    local strip
    dialog:HookScript("OnShow", function()
        local notes = ns.Notes.List()
        if #notes == 0 then return end
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
                e:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)
                strip.boxes[i] = e
            end
        end
        for i, e in ipairs(strip.boxes) do
            e.note = notes[i]
            e:SetText(notes[i] or "")
            e:SetShown(notes[i] ~= nil)
        end
        strip:SetHeight(26 + #notes * 24)
        strip:Show()
        strip.boxes[1]:SetFocus()
        strip.boxes[1]:HighlightText()
    end)
    dialog:HookScript("OnHide", function() if strip then strip:Hide() end end)
end)

function Sidecar.Follow(f)
    if frame and frame:IsShown() then editing = f; Sidecar.Paint() end
end
