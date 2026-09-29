--[[
    PickupGroup - UI/Pane.lua
    The pane: our own frame laid over Blizzard's search panel on Premade
    Groups > Dungeons and Raids - Midnight. Blizzard's frames are never
    hidden, moved or written; the pane just covers them.

      top bar   tab . count . Refresh . Blizzard-list switch
      headers   Name | Dungeon/Raid | Comp | Score/Bosses | roles (apply as)
      rows      sign-ups pinned first (mint edge), then results; wheel scrolls

    Action button: Apply (shift-click: Blizzard's sign-up dialog, for a
    note) / time left (hover: Cancel) / Reapply (second click confirms).
--]]

local _, ns = ...

local Pane = {}
ns.Pane = Pane

local Kit, Groups = ns.Kit, ns.Groups
local ROW_H, BAR_H, HEAD_H = 24, 26, 20
local W_INST, W_COMP, W_SCORE, W_ACT, GAP, PAD = 38, 78, 34, 56, 6, 6
local TILE = 14
local W_DIFF = 16
-- Difficulty letters in loot-quality colours: N uncommon green, H rare blue,
-- M legendary orange (epic purple skipped: too dark to read here).
local DIFF_COLOR = { N = { 0.12, 1, 0 }, H = { 0, 0.44, 0.87 }, M = { 1, 0.5, 0 }, LFR = { 0.7, 0.7, 0.7 } }
local TITLE_BAND = 30  -- Blizzard's window title and close button stay uncovered
local BOTTOM_ROW = 30  -- height left for Blizzard's Back / Sign Up buttons
local REFRESH_WAIT = 3  -- seconds between searches the client accepts (Phase 1)
local ROLE_ATLAS = { TANK = "roleicon-tiny-tank", HEALER = "roleicon-tiny-healer", DAMAGER = "roleicon-tiny-dps" }
local ROLES = { "TANK", "HEALER", "DAMAGER" }
local MINT = Kit.Palette.brand
local OVER = { declined = true, declined_full = true, declined_delisted = true, cancelled = true,
               timedout = true, invitedeclined = true, failed = true }

-- How a sign-up ended, as its button shows it for OUTCOME_TTL seconds.
local OUTCOME_TTL = 5
local AMBER, GREY, WHITE = { 1, 0.72, 0.3 }, { 0.6, 0.6, 0.6 }, { 1, 1, 1 }
local OUTCOME = {
    declined = { "Declined", AMBER }, declined_full = { "Filled", GREY },
    declined_delisted = { "Delisted", GREY }, cancelled = { "Withdrawn", GREY },
    timedout = { "Expired", GREY }, invitedeclined = { "Passed", GREY },
    failed = { "Failed", AMBER }, inviteaccepted = { "Joined", MINT },
}
local recent, cache = {}, {}  -- ended sign-ups on show; last pinned row per ID

local panel, pane, backButton, refresh, countText, tabBar, plusTab, hiddenButton
local showHidden = false
local tabs = {}
local rows, roleButtons = {}, {}
local pinned, results = {}, {}
local offset = 0
local lastSearch, armed = 0, nil

local function Panel() return LFGListFrame and LFGListFrame.SearchPanel end

local function Eligible()
    local p = Panel()
    if not (p and p:IsShown()) then return false end
    if p.categoryID == 2 then return true end  -- Dungeons
    local recommended = Enum.LFGListFilter and Enum.LFGListFilter.Recommended or 1
    return p.categoryID == 3 and bit.band(p.filters or 0, recommended) ~= 0  -- Raids - current
end

local function Text(parent, font, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "PickupGroupFontSmall")
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    return fs
end

local function Clock(sec)
    sec = math.max(0, math.floor(sec or 0))
    return ("%d:%02d"):format(sec / 60, sec % 60)
end

-- ---------------------------------------------------------------------------
-- Actions (each runs straight from a click: the game requires it)
-- ---------------------------------------------------------------------------
local function Apply(row)
    local r = Groups.MyRoles()
    C_LFGList.ApplyToGroup(row.id, r.TANK, r.HEALER, r.DAMAGER)
    ns.Log.Emit("apply", { code = row.code, leader = row.leader })
end

local function OnAction(btn, mouse)
    local row = btn.row
    if not row then return end
    if row.status == "applied" then
        C_LFGList.CancelApplication(row.id)
        ns.Log.Emit("cancel", { code = row.code, leader = row.leader })
    elseif row.status == "invited" or row.status == "inviteaccepted" then
        return
    elseif IsShiftKeyDown() and LFGListApplicationDialog_Show then
        LFGListApplicationDialog_Show(LFGListApplicationDialog, row.id)
    elseif OVER[row.status] and armed ~= row.id then
        armed = row.id  -- re-applying takes a second click
        C_Timer.After(3, function() if armed == row.id then armed = nil; Pane.Render() end end)
        Pane.Render()
    else
        armed = nil
        Apply(row)
    end
end

local function Search()
    local p = Panel()
    if p and LFGListSearchPanel_DoSearch then LFGListSearchPanel_DoSearch(p) end
end

-- ---------------------------------------------------------------------------
-- Tooltips
-- ---------------------------------------------------------------------------
local function RowTooltip(frame)
    local row = frame.row
    if not row then return end
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText(row.name or "?", 1, 1, 1)
    if row.hidden then GameTooltip:AddLine("Hidden by clean-up: " .. row.hidden, 1, 0.72, 0.3, true) end
    GameTooltip:AddLine(row.activity .. (row.difficulty and (" (" .. row.difficulty .. ")") or ""), 0.85, 0.85, 0.85)
    GameTooltip:AddDoubleLine("Leader", row.leader or "?", 0.55, 0.55, 0.55, 1, 1, 1)
    if row.isRaid then
        GameTooltip:AddDoubleLine("Members", ("%d: %d tank, %d healer, %d damage"):format(row.members or 0,
            row.counts.TANK, row.counts.HEALER, row.counts.DAMAGER), 0.55, 0.55, 0.55, 1, 1, 1)
        GameTooltip:AddDoubleLine("Bosses down", row.total and (row.down .. "/" .. row.total) or row.down,
            0.55, 0.55, 0.55, 1, 1, 1)
    else
        GameTooltip:AddDoubleLine("Leader score", row.score or 0, 0.55, 0.55, 0.55, 1, 1, 1)
        for _, s in ipairs(row.specs) do
            local c = RAID_CLASS_COLORS[s.file or ""]
            GameTooltip:AddLine(("%s %s"):format(s.spec or "", s.class or ""), c and c.r or 1, c and c.g or 1, c and c.b or 1)
        end
    end
    if row.friends > 0 then GameTooltip:AddDoubleLine("Friends in group", row.friends, 0.55, 0.55, 0.55, MINT[1], MINT[2], MINT[3]) end
    GameTooltip:AddDoubleLine("Listed", Clock(row.age), 0.55, 0.55, 0.55, 1, 1, 1)
    if row.comment and row.comment ~= "" then GameTooltip:AddLine(row.comment, 0.85, 0.85, 0.85, true) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Click Apply: sign up.  Shift-click: add a note first.", 0.55, 0.55, 0.55)
    GameTooltip:AddLine("Right-click the row: report, blacklist or hide the leader.", 0.55, 0.55, 0.55)
    GameTooltip:Show()
end

local function ActionTooltip(btn)
    local row = btn.row
    if not row then return end
    local tip
    if row.status == "applied" then tip = "Click to cancel this sign-up."
    elseif row.status == "invited" then tip = "You're invited: answer in Blizzard's invite window."
    elseif OVER[row.status] then tip = "You signed up here before (" .. row.status:gsub("_", " ") .. "). Click twice to sign up again."
    elseif not row.fits then tip = "No open seat for the roles you sign up as."
    elseif btn.full then tip = "All five sign-ups are in use." end
    if tip then
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText(tip, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end
end

-- ---------------------------------------------------------------------------
-- Rows
-- ---------------------------------------------------------------------------
local function Tile(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(TILE, TILE)
    Kit.Fill(f, { 0.11, 0.11, 0.11, 1 })
    Kit.Border(f)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("TOPLEFT", 1, -1)
    f.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.role = f:CreateTexture(nil, "ARTWORK")
    f.role:SetSize(10, 10)
    f.role:SetPoint("CENTER")
    return f
end

local function BuildRow(i)
    local r = CreateFrame("Button", nil, pane)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", 1, -(BAR_H + HEAD_H + (i - 1) * ROW_H))
    r:SetPoint("TOPRIGHT", -1, -(BAR_H + HEAD_H + (i - 1) * ROW_H))
    r.stripe = r:CreateTexture(nil, "BACKGROUND", nil, -7)
    r.stripe:SetAllPoints()
    r.hover = r:CreateTexture(nil, "BACKGROUND", nil, -6)
    r.hover:SetAllPoints()
    r.hover:SetColorTexture(MINT[1], MINT[2], MINT[3], 0.07)
    r.hover:Hide()
    r.edge = r:CreateTexture(nil, "OVERLAY")
    r.edge:SetColorTexture(MINT[1], MINT[2], MINT[3], 1)
    r.edge:SetPoint("TOPLEFT")
    r.edge:SetPoint("BOTTOMLEFT")
    r.edge:SetWidth(2)

    r.act = CreateFrame("Button", nil, r)
    r.act:SetSize(W_ACT, 18)
    r.act:SetPoint("RIGHT", -PAD, 0)
    Kit.Button(r.act)
    r.act:SetNormalFontObject("PickupGroupFontSmall")
    r.act:SetHighlightFontObject("PickupGroupFontSmall")
    r.act:SetDisabledFontObject("PickupGroupFontSmall")
    r.act:SetScript("OnClick", OnAction)
    r.act:HookScript("OnEnter", function(self) ActionTooltip(self); r.hover:Show() end)
    r.act:HookScript("OnLeave", function() GameTooltip:Hide(); r.hover:Hide() end)

    r.score = Text(r, nil, "RIGHT")
    r.score:SetWidth(W_SCORE)
    r.score:SetPoint("RIGHT", r.act, "LEFT", -GAP, 0)

    r.comp = CreateFrame("Frame", nil, r)
    r.comp:SetSize(W_COMP, TILE)
    r.comp:SetPoint("RIGHT", r.score, "LEFT", -GAP, 0)
    r.tiles = {}
    for t = 1, 5 do
        r.tiles[t] = Tile(r.comp)
        r.tiles[t]:SetPoint("LEFT", (t - 1) * (TILE + 2), 0)
    end
    r.counts = {}
    for c, role in ipairs(ROLES) do
        local icon = r.comp:CreateTexture(nil, "ARTWORK")
        icon:SetSize(10, 10)
        icon:SetPoint("LEFT", (c - 1) * 26, 0)
        icon:SetAtlas(ROLE_ATLAS[role])
        local n = Text(r.comp)
        n:SetPoint("LEFT", icon, "RIGHT", 2, 0)
        r.counts[c] = { icon = icon, n = n, role = role }
    end

    r.inst = Text(r)
    r.inst:SetWidth(W_INST)
    r.inst:SetPoint("RIGHT", r.comp, "LEFT", -GAP, 0)
    r.inst:SetTextColor(0.84, 0.84, 0.84)
    r.diff = Text(r, nil, "CENTER")
    r.diff:SetPoint("RIGHT", r.inst, "LEFT", 0, 0)

    r.name = Text(r)
    r.name:SetPoint("LEFT", PAD, 0)
    r.name:SetPoint("RIGHT", r.diff, "LEFT", -GAP, 0)

    -- Right-click: report, blacklist or hide the leader.
    r:RegisterForClicks("RightButtonUp")
    r:SetScript("OnClick", function(self)
        local row = self.row
        if not (row and row.leader and MenuUtil) then return end
        MenuUtil.CreateContextMenu(self, function(_, root)
            root:CreateTitle(row.leader)
            root:CreateButton("Report and hide", function()
                ns.Cleanup.HideForSession(row.leader)
                if LFGList_ReportListing then LFGList_ReportListing(row.id, row.leader) end
                Pane.Render()
            end)
            root:CreateButton("Blacklist this leader", function()
                ns.Cleanup.Blacklist(row.leader); Pane.Render()
            end)
            root:CreateButton("Hide until reload", function()
                ns.Cleanup.HideForSession(row.leader); Pane.Render()
            end)
        end)
    end)
    r:SetScript("OnEnter", function(self) self.hover:Show(); RowTooltip(self) end)
    r:SetScript("OnLeave", function(self) self.hover:Hide(); GameTooltip:Hide() end)
    rows[i] = r
    return r
end

local function PaintRow(r, row, isPinned, index, full, raidView)
    r.row, r.act.row = row, row
    r:Show()
    r.edge:SetShown(isPinned)
    r.stripe:SetColorTexture(1, 1, 1, (index % 2 == 0) and 0.02 or 0)
    r.name:SetText(row.name or "?")
    r.inst:SetText(row.code)
    r.diff:SetWidth(raidView and W_DIFF or 1)
    local dc = DIFF_COLOR[row.difficulty or ""]
    r.diff:SetText(raidView and (row.difficulty or "") or "")
    if dc then r.diff:SetTextColor(dc[1], dc[2], dc[3]) end
    r:SetAlpha(OVER[row.status] and 0.5 or 1)

    for t, tile in ipairs(r.tiles) do
        local s = row.tiles and row.tiles[t]
        tile:SetShown(s ~= nil)
        if s then
            tile.icon:SetShown(s.filled and s.icon ~= nil)
            if s.icon then tile.icon:SetTexture(s.icon) end
            tile.role:SetShown(not s.filled)
            tile.role:SetAtlas(ROLE_ATLAS[s.role])
            tile.role:SetDesaturated(not s.mine)
            if s.mine then tile.role:SetVertexColor(MINT[1], MINT[2], MINT[3]) else tile.role:SetVertexColor(0.6, 0.6, 0.6) end
        end
    end
    for _, c in ipairs(r.counts) do
        c.icon:SetShown(row.isRaid)
        c.n:SetShown(row.isRaid)
        if row.isRaid then c.n:SetText(row.counts[c.role]) end
    end

    if row.isRaid then
        r.score:SetText(row.total and (row.down .. "/" .. row.total) or row.down)
        r.score:SetTextColor(1, 1, 1)
    else
        local score = row.score or 0
        r.score:SetText(score > 0 and score or "-")
        local color = score > 0 and C_ChallengeMode.GetDungeonScoreRarityColor(score)
        if color then r.score:SetTextColor(color.r, color.g, color.b) else r.score:SetTextColor(0.55, 0.55, 0.55) end
    end

    local act, label, enabled = r.act, "Apply", true
    act.full = full
    local ink = isPinned and MINT or WHITE
    if row.outcome then
        label, enabled, ink = row.outcome.label, false, row.outcome.color
    elseif row.status == "applied" then
        label = Clock(row.remaining)
    elseif row.status == "invited" then
        label = "Invited"
    elseif row.status == "inviteaccepted" then
        label, enabled = "Joined", false
    elseif OVER[row.status] then
        label = (armed == row.id) and "Sure?" or "Reapply"
    elseif not row.fits or full then
        label, enabled = "-", false
    end
    act:SetText(label)
    act:SetEnabled(enabled)
    act:GetFontString():SetTextColor(ink[1], ink[2], ink[3], (enabled or row.outcome) and 1 or 0.4)
end

-- One tab per saved filter of the kind in view; the active one in mint and
-- underlined. Left-click switches, right-click opens its setup.
local function PaintTabs()
    local Filters = ns.Filters
    local kind = Filters.Kind()
    local active = Filters.Active(kind)
    local prev
    for i, f in ipairs(Filters.List(kind)) do
        local t = tabs[i]
        if not t then
            t = CreateFrame("Button", nil, tabBar)
            t:SetHeight(BAR_H)
            t:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            t.text = Text(t, "PickupGroupFont")
            t.text:SetPoint("LEFT")
            t.under = t:CreateTexture(nil, "OVERLAY")
            t.under:SetColorTexture(MINT[1], MINT[2], MINT[3], 1)
            t.under:SetHeight(2)
            t.under:SetPoint("BOTTOMLEFT", 0, 1)
            t.under:SetPoint("BOTTOMRIGHT", 0, 1)
            t:SetScript("OnClick", function(self, button)
                if button == "RightButton" then return ns.Sidecar.Open(self.filter) end
                Filters.SetActive(self.filter)
                offset = 0
                Pane.Render()
                ns.Sidecar.Follow(self.filter)
            end)
            tabs[i] = t
        end
        t.filter = f
        t.text:SetText(f.name)
        t:SetWidth(t.text:GetStringWidth())
        local on = f == active
        t.text:SetTextColor(on and MINT[1] or 0.74, on and MINT[2] or 0.74, on and MINT[3] or 0.74)
        t.under:SetShown(on)
        t:ClearAllPoints()
        if prev then t:SetPoint("LEFT", prev, "RIGHT", 12, 0) else t:SetPoint("LEFT", 8, 0) end
        t:Show()
        prev = t
    end
    for i = #Filters.List(kind) + 1, #tabs do tabs[i]:Hide() end
    plusTab:ClearAllPoints()
    plusTab:SetPoint("LEFT", prev or tabBar, prev and "RIGHT" or "LEFT", prev and 6 or 8, 0)
end

function Pane.Render()
    if not (pane and pane:IsShown()) then return end
    PaintTabs()
    local hiddenCount
    pinned, results, hiddenCount = Groups.List(showHidden)
    if showHidden and hiddenCount == 0 then showHidden = false; pinned, results, hiddenCount = Groups.List(false) end
    hiddenButton.text:SetText(showHidden and "|cffffb84dshowing hidden|r" or (hiddenCount > 0 and (hiddenCount .. " hidden") or ""))
    hiddenButton.text:SetTextColor(0.55, 0.55, 0.55)
    hiddenButton:SetWidth(math.max(1, hiddenButton.text:GetStringWidth()))
    hiddenButton:SetShown(showHidden or hiddenCount > 0)
    -- Sign-ups that just ended stay pinned for OUTCOME_TTL with how they ended.
    local now, showing = GetTime(), {}
    for _, row in ipairs(pinned) do cache[row.id] = row; showing[row.id] = true end
    for id, o in pairs(recent) do
        if o.untilT <= now then
            recent[id] = nil
        elseif not showing[id] then
            local row = CopyTable(o.row)
            row.status, row.outcome = nil, o
            pinned[#pinned + 1] = row
            showing[id] = true
        end
    end
    for i = #results, 1, -1 do if showing[results[i].id] then table.remove(results, i) end end
    local p = Panel()
    local raidView = p and p.categoryID == 3
    local _, active = C_LFGList.GetNumApplications()
    local full = (active or 0) >= (MAX_LFG_LIST_APPLICATIONS or 5)
    local fit = math.max(1, math.floor((pane:GetHeight() - BAR_H - HEAD_H) / ROW_H))
    offset = math.max(0, math.min(offset, #results - (fit - #pinned)))
    countText:SetText(#results)
    local slot = 0
    for _, row in ipairs(pinned) do
        slot = slot + 1
        if slot > fit then break end
        PaintRow(rows[slot] or BuildRow(slot), row, true, slot, full, raidView)
    end
    -- A 1px line under the sign-ups separates them from the scrolling results.
    local nPinned = math.min(#pinned, fit)
    pane.divider:SetShown(nPinned > 0)
    pane.divider:SetPoint("TOPLEFT", 1, -(BAR_H + HEAD_H + nPinned * ROW_H))
    pane.divider:SetPoint("TOPRIGHT", -1, -(BAR_H + HEAD_H + nPinned * ROW_H))
    for i = offset + 1, #results do
        slot = slot + 1
        if slot > fit then break end
        PaintRow(rows[slot] or BuildRow(slot), results[i], false, slot, full, raidView)
    end
    for i = slot + 1, #rows do rows[i]:Hide(); rows[i].row = nil end
    ns.Sidecar.RefreshBosses()
    pane.instHead:SetText(raidView and "Raid" or "Dungeon")
    pane.scoreHead:SetText(raidView and "Bosses" or "Score")
    pane.diffHead:SetWidth(raidView and W_DIFF or 1)
end

-- A pending render collapses bursts of result updates.
local queued = false
local function RenderSoon()
    if queued then return end
    queued = true
    C_Timer.After(0.2, function() queued = false; Pane.Render() end)
end

-- ---------------------------------------------------------------------------
-- Bars
-- ---------------------------------------------------------------------------
local function PaintRoles()
    local mine = Groups.MyRoles()
    local canT, canH, canD = UnitGetAvailableRoles("player")
    local can = { TANK = canT, HEALER = canH, DAMAGER = canD }
    for _, b in ipairs(roleButtons) do
        b:SetEnabled(can[b.role])
        b.icon:SetDesaturated(not mine[b.role])
        b.icon:SetAlpha(not can[b.role] and 0.15 or (mine[b.role] and 1 or 0.4))
    end
end

local function BuildBars()
    local bar = CreateFrame("Frame", nil, pane)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(BAR_H)
    local rule = bar:CreateTexture(nil, "OVERLAY")
    rule:SetColorTexture(0, 0, 0, 1)
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT")
    rule:SetPoint("BOTTOMRIGHT")

    tabBar = bar
    plusTab = CreateFrame("Button", nil, bar)
    plusTab:SetSize(16, BAR_H)
    Kit.Glyph(plusTab, { { 9, 2, 0 }, { 2, 9, 0 } })
    plusTab:SetScript("OnClick", function()
        local f = ns.Filters.New(ns.Filters.Kind())
        offset = 0
        Pane.Render()
        ns.Sidecar.Open(f)
    end)
    plusTab:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM"); GameTooltip:SetText("New filter"); GameTooltip:Show()
    end)
    plusTab:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Blizzard's own list instead (the way back is a button on Blizzard's panel).
    local list = Kit.HeaderIcon(bar, { { 12, 2, 4 }, { 12, 2, 0 }, { 12, 2, -4 } }, "Options",
        function() ns.Sidecar.Open(nil, "options") end)
    list:SetPoint("RIGHT", -2, 0)

    refresh = CreateFrame("Button", nil, bar)
    refresh:SetSize(58, 18)
    local setup = Kit.HeaderIcon(bar, { { 12, 2, 4 }, { 4, 6, 4, nil, -2 }, { 12, 2, -4 }, { 4, 6, -4, nil, 3 } },
        "Set up this filter (right-click a tab works too)", function() ns.Sidecar.Open() end)
    setup:SetPoint("RIGHT", list, "LEFT", 0, 0)
    refresh:SetPoint("RIGHT", setup, "LEFT", -4, 0)
    Kit.Button(refresh)
    refresh:SetNormalFontObject("PickupGroupFontSmall")
    refresh:SetHighlightFontObject("PickupGroupFontSmall")
    refresh:SetDisabledFontObject("PickupGroupFontSmall")
    refresh:SetText("Refresh")
    refresh:SetScript("OnClick", Search)

    countText = Text(bar)
    countText:SetPoint("RIGHT", refresh, "LEFT", -8, 0)
    countText:SetTextColor(0.55, 0.55, 0.55)
    -- How many rows clean-up hid; click to see only those (and back).
    hiddenButton = CreateFrame("Button", nil, bar)
    hiddenButton:SetHeight(BAR_H)
    hiddenButton.text = Text(hiddenButton)
    hiddenButton.text:SetPoint("RIGHT")
    hiddenButton:SetPoint("RIGHT", countText, "LEFT", -8, 0)
    hiddenButton:SetScript("OnClick", function() showHidden = not showHidden; offset = 0; Pane.Render() end)
    hiddenButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(showHidden and "Showing what clean-up hid: click to go back" or "Hidden by clean-up: click to review")
        GameTooltip:Show()
    end)
    hiddenButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local head = CreateFrame("Frame", nil, pane)
    head:SetPoint("TOPLEFT", 0, -BAR_H)
    head:SetPoint("TOPRIGHT", 0, -BAR_H)
    head:SetHeight(HEAD_H)
    local hrule = head:CreateTexture(nil, "OVERLAY")
    hrule:SetColorTexture(0, 0, 0, 1)
    hrule:SetHeight(1)
    hrule:SetPoint("BOTTOMLEFT")
    hrule:SetPoint("BOTTOMRIGHT")

    -- Apply-as roles sit over the action column: Blizzard's own role choice.
    local x = -PAD
    for i = #ROLES, 1, -1 do
        local b = CreateFrame("Button", nil, head)
        b:SetSize(14, 14)
        b:SetPoint("RIGHT", x - (#ROLES - i) * 17, 0)
        b.role = ROLES[i]
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints()
        b.icon:SetAtlas(ROLE_ATLAS[b.role])
        b:SetScript("OnClick", function(self)
            local leader, t, h, d = GetLFGRoles()
            local set = { TANK = t, HEALER = h, DAMAGER = d }
            set[self.role] = not set[self.role]
            SetLFGRoles(leader, set.TANK, set.HEALER, set.DAMAGER)
            PaintRoles()
            Pane.Render()
        end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Sign up as " .. _G[self.role]:lower() .. ": click to switch")
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        roleButtons[#roleButtons + 1] = b
    end

    local function Head(label, width, anchorTo, justify)
        local fs = Text(head, nil, justify)
        fs:SetTextColor(0.55, 0.55, 0.55)
        fs:SetText(label)
        if width then fs:SetWidth(width) end
        return fs
    end
    local actRight = -(PAD + W_ACT + GAP)
    pane.scoreHead = Head("Score", W_SCORE, nil, "RIGHT")
    pane.scoreHead:SetPoint("RIGHT", actRight, 0)
    local comp = Head("Comp", W_COMP)
    comp:SetPoint("RIGHT", pane.scoreHead, "LEFT", -GAP, 0)
    pane.instHead = Head("Dungeon", W_INST)
    pane.instHead:SetPoint("RIGHT", comp, "LEFT", -GAP, 0)
    pane.diffHead = Head("", W_DIFF)
    pane.diffHead:SetPoint("RIGHT", pane.instHead, "LEFT", 0, 0)
    local name = Head("Name")
    name:SetPoint("LEFT", PAD, 0)
end

-- Refresh counts down until the client will take the next search; sign-ups
-- count down their time left.
local function Tick()
    if not (pane and pane:IsShown()) then return end
    local wait = REFRESH_WAIT - (GetTime() - lastSearch)
    refresh:SetEnabled(wait <= 0)
    refresh:SetText(wait > 0 and tostring(math.ceil(wait)) or "Refresh")
    for _, r in ipairs(rows) do
        local row = r:IsShown() and r.row
        if row and row.status == "applied" and row.remaining then
            row.remaining = row.remaining - 1
            r.act:SetText(Clock(row.remaining))
        end
    end
end

local function Build()
    Kit.ApplyFontFace()
    panel = Panel()
    pane = CreateFrame("Frame", "PickupGroupPane", panel)
    -- Blizzard's Back / Sign Up row stays uncovered: Back is the way out.
    pane:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -TITLE_BAND)
    -- Down to just above Blizzard's Back button, so no sliver of the list shows.
    if panel.BackButton then
        pane:SetPoint("RIGHT", panel, "RIGHT")
        pane:SetPoint("BOTTOM", panel.BackButton, "TOP", 0, 2)
    else
        pane:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, BOTTOM_ROW)
    end
    pane:SetFrameLevel(panel:GetFrameLevel() + 50)
    pane:EnableMouse(true)
    Kit.Fill(pane, { 0.031, 0.031, 0.031, 1 })  -- opaque: nothing of Blizzard's list shows through
    Kit.Border(pane)
    BuildBars()
    pane.divider = pane:CreateTexture(nil, "OVERLAY", nil, 7)
    pane.divider:SetColorTexture(0.25, 0.25, 0.25, 1)
    pane.divider:SetHeight(1)
    pane:EnableMouseWheel(true)
    pane:SetScript("OnMouseWheel", function(_, delta)
        offset = math.max(0, offset - delta * 3)
        Pane.Render()
    end)
    pane:SetScript("OnShow", function() PaintRoles(); Pane.Render() end)
    pane:Hide()

    -- The way back from Blizzard's list: a button on Blizzard's panel.
    backButton = CreateFrame("Button", nil, panel)
    -- In the panel's header, just after its category name.
    backButton:SetSize(84, 18)
    if panel.CategoryName then
        backButton:SetPoint("LEFT", panel.CategoryName, "RIGHT", 10, 0)
    else
        backButton:SetPoint("TOP", panel, "TOP", 0, -34)
    end
    backButton:SetFrameLevel(panel:GetFrameLevel() + 50)
    Kit.Button(backButton)
    backButton:SetNormalFontObject("PickupGroupFontSmall")
    backButton:SetText("|cff98ff98Pickup|rGroup")
    backButton:SetScript("OnClick", function() ns.db.useBlizzard = false; Pane.Update() end)
    backButton:Hide()

    C_Timer.NewTicker(1, Tick)
end

function Pane.Update()
    if not Panel() then return end
    if not pane then Build() end
    local eligible = Eligible()
    pane:SetShown(eligible and not ns.db.useBlizzard)
    backButton:SetShown(eligible and ns.db.useBlizzard == true)
    -- The category name's frame is wider than its text: sit just after the text.
    local name = panel.CategoryName
    if backButton:IsShown() and name then
        backButton:ClearAllPoints()
        backButton:SetPoint("LEFT", name, "LEFT", name:GetStringWidth() + 10, 0)
    end
    -- The sidecar belongs to the pane: it closes when the pane goes and
    -- follows the category when it stays.
    if pane:IsShown() then ns.Sidecar.Follow(ns.Filters.Active()) else ns.Sidecar.Hide() end
    ns.Trace("pane", "update: category", tostring(panel.categoryID), "filters", tostring(panel.filters),
        "shown", tostring(pane:IsShown()))
end

-- ---------------------------------------------------------------------------
-- Wiring
-- ---------------------------------------------------------------------------
EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder", function()
    local p = Panel()
    if not p then return ns.Trace("pane", "no search panel") end
    p:HookScript("OnShow", Pane.Update)
    p:HookScript("OnHide", Pane.Update)
    hooksecurefunc("LFGListSearchPanel_SetCategory", Pane.Update)
    -- Every search, ours or Blizzard's, restarts the Refresh wait.
    hooksecurefunc("LFGListSearchPanel_DoSearch", function() lastSearch = GetTime(); Tick() end)
end)

ns.On("LFG_LIST_SEARCH_RESULTS_RECEIVED", function() offset = 0; RenderSoon() end)
ns.On("LFG_LIST_SEARCH_RESULT_UPDATED", RenderSoon)
ns.On("LFG_LIST_APPLICATION_STATUS_UPDATED", function(id, new, old)
    ns.Trace("apply", "status", tostring(id), tostring(old), "->", tostring(new))
    local o = OUTCOME[new]
    local row = cache[id] or (o and Groups.Read(id))
    if o and row then
        recent[id] = { row = row, label = o[1], color = o[2], untilT = GetTime() + OUTCOME_TTL }
        C_Timer.After(OUTCOME_TTL + 0.1, RenderSoon)
    end
    RenderSoon()
end)
ns.On("LFG_LIST_SEARCH_FAILED", function(reason)
    ns.Log.Emit("search_failed", { reason = reason })
    lastSearch = GetTime()
end)
