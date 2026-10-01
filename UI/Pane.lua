--[[
    PickupGroup - UI/Pane.lua
    The pane: our own frame laid over Blizzard's search panel on Premade
    Groups > Dungeons and Raids - Midnight, below Blizzard's search row
    (search text is typed there). Blizzard's frames are never hidden,
    moved or written; the pane just covers them.

      top bar   filter summary . hidden . count . setup . options; a mint line across the top
                shrinks over the search cooldown (Blizzard's refresh searches)
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

local panel, pane, backButton, cooldown, countText, summary, hiddenButton
local showHidden = false
local rows, roleButtons = {}, {}
local pinned, results = {}, {}
local offset = 0
local lastSearch, armed = 0, nil
-- New mark: listings not in the previous search's results (leader + activity),
-- until the next search. Nothing is marked on a category's first search.
local seen, fresh = nil, {}

-- Friends / guild mark: a drawn "people" glyph at the end of the name
-- column, in the colours WoW players know (Battle.net blue, guild chat
-- green). Options can colour the name instead, as Blizzard does.
local FRIEND = { 0.51, 0.77, 1 }
local PEOPLE = { { 4, 4, 3 }, { 8, 3, -3 } }
local function GuildColor()
    local c = ChatTypeInfo and ChatTypeInfo.GUILD
    return c and { c.r, c.g, c.b } or { 0.25, 1, 0.25 }
end

local function Panel() return LFGListFrame and LFGListFrame.SearchPanel end

local function Eligible()
    local p = Panel()
    if not (p and p:IsShown()) then return false end
    -- While the player's group is listed, step aside as Blizzard does (its
    -- listing view: members can't act, the leader manages applicants).
    if C_LFGList.HasActiveEntryInfo() then return false end
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
-- Only a party's leader can sign it up; the game ignores anyone else silently.
local function NotLeader() return IsInGroup() and not UnitIsGroupLeader("player") end

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
    if row.friends > 0 then GameTooltip:AddDoubleLine("Friends in group", row.friends, 0.55, 0.55, 0.55, FRIEND[1], FRIEND[2], FRIEND[3]) end
    if row.guild > 0 then
        local g = GuildColor()
        GameTooltip:AddDoubleLine("Guildmates in group", row.guild, 0.55, 0.55, 0.55, g[1], g[2], g[3])
    end
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
    elseif NotLeader() then tip = "Only your party leader can sign the party up."
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
    r.act:SetMotionScriptsWhileDisabled(true)  -- greyed buttons still explain why
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

    r.new = r:CreateTexture(nil, "OVERLAY")
    r.new:SetColorTexture(MINT[1], MINT[2], MINT[3], 1)
    r.new:SetSize(3, 3)
    r.new:SetPoint("LEFT", 1, 0)
    for _, key in ipairs({ "friendMark", "guildMark" }) do
        local m = CreateFrame("Frame", nil, r)
        m:SetSize(10, 12)
        m.tint = Kit.Glyph(m, PEOPLE)
        m:Hide()
        r[key] = m
    end
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
                ns.Log.Emit("report", { name = row.leader, why = "form opened" })
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
    r.new:SetShown(not isPinned and fresh[row.id] == true)
    r.stripe:SetColorTexture(1, 1, 1, (index % 2 == 0) and 0.05 or 0)  -- every other row: easier to track across
    r.name:SetText(row.name or "?")
    local byName, marks, ink = ns.db.nameColors and not isPinned, {}, { 1, 1, 1 }
    if byName then
        ink = row.guild > 0 and GuildColor() or row.friends > 0 and FRIEND or ink
    elseif not isPinned then
        if row.friends > 0 then r.friendMark.tint(FRIEND); marks[#marks + 1] = r.friendMark end
        if row.guild > 0 then r.guildMark.tint(GuildColor()); marks[#marks + 1] = r.guildMark end
    end
    r.name:SetTextColor(ink[1], ink[2], ink[3])
    r.friendMark:Hide(); r.guildMark:Hide()
    local anchor, x = r.diff, -GAP
    for i = #marks, 1, -1 do
        marks[i]:SetPoint("RIGHT", anchor, "LEFT", x, 0)
        marks[i]:Show()
        anchor, x = marks[i], -1
    end
    r.name:SetPoint("RIGHT", anchor, "LEFT", anchor == r.diff and -GAP or -3, 0)
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
            tile.role:SetDesaturated(true)
            tile.role:SetVertexColor(0.6, 0.6, 0.6)
            -- An open seat for the player's role gets a mint 1px ring (the
            -- style guide's "on" mark); every other tile keeps a black one.
            local ring = (s.mine and not s.filled) and MINT or Kit.Palette.border
            for _, t in ipairs(tile._border) do t:SetColorTexture(ring[1], ring[2], ring[3], 1) end
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
    elseif NotLeader() then
        label, enabled = "Leader", false
    elseif OVER[row.status] then
        label = (armed == row.id) and "Sure?" or "Reapply"
    elseif not row.fits or full then
        label, enabled = "-", false
    end
    act:SetText(label)
    act:SetEnabled(enabled)
    act:GetFontString():SetTextColor(ink[1], ink[2], ink[3], (enabled or row.outcome) and 1 or 0.4)
end

function Pane.Render()
    if not (pane and pane:IsShown()) then return end
    ns.Filters.Sync()  -- before Blizzard's search on a category change, too
    summary:SetText(ns.Filters.Summary(ns.Filters.Active()))
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

    -- Blizzard's own list instead (the way back is a button on Blizzard's panel).
    local list = Kit.HeaderIcon(bar, { { 12, 2, 4 }, { 12, 2, 0 }, { 12, 2, -4 } }, "Options",
        function() ns.Sidecar.Open(nil, "options") end)
    list:SetPoint("RIGHT", -2, 0)

    local setup = Kit.HeaderIcon(bar, { { 12, 2, 4 }, { 4, 6, 4, nil, -2 }, { 12, 2, -4 }, { 4, 6, -4, nil, 3 } },
        "Set up the filter", function() ns.Sidecar.Open() end)
    setup:SetPoint("RIGHT", list, "LEFT", 0, 0)

    countText = Text(bar)
    countText:SetPoint("RIGHT", setup, "LEFT", -8, 0)
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

    -- What the filter does, in a line; click to set it up.
    local sb = CreateFrame("Button", nil, bar)
    sb:SetPoint("LEFT", 8, 0)
    sb:SetPoint("RIGHT", hiddenButton, "LEFT", -8, 0)
    sb:SetHeight(BAR_H)
    summary = Text(sb)
    summary:SetPoint("LEFT")
    summary:SetPoint("RIGHT")
    summary:SetJustifyH("LEFT")
    summary:SetWordWrap(false)
    summary:SetTextColor(0.74, 0.74, 0.74)
    sb:SetScript("OnClick", function() ns.Sidecar.Open() end)
    sb:SetScript("OnEnter", function(self)
        summary:SetTextColor(MINT[1], MINT[2], MINT[3])
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Filter: " .. summary:GetText())
        GameTooltip:AddLine("Click to set it up.", 0.74, 0.74, 0.74)
        GameTooltip:Show()
    end)
    sb:SetScript("OnLeave", function() summary:SetTextColor(0.74, 0.74, 0.74); GameTooltip:Hide() end)

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

-- Sign-ups count down their time left.
local function Tick()
    if not (pane and pane:IsShown()) then return end
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
    -- Blizzard's search row stays uncovered: addons can't set search text,
    -- so the player types it there (and searching by key level needs it).
    pane:SetPoint("LEFT", panel, "LEFT")
    if panel.SearchBox then
        pane:SetPoint("TOP", panel.SearchBox, "BOTTOM", 0, -4)
    else
        pane:SetPoint("TOP", panel, "TOP", 0, -TITLE_BAND)
    end
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
    -- Search cooldown: a 1px mint line across the top that shrinks to
    -- nothing while the client won't take another search (Blizzard's
    -- refresh does the searching).
    local line = pane:CreateTexture(nil, "OVERLAY", nil, 7)
    line:SetColorTexture(MINT[1], MINT[2], MINT[3], 1)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT")
    cooldown = CreateFrame("Frame", nil, pane)
    cooldown:Hide()
    cooldown:SetScript("OnHide", function() line:Hide() end)
    cooldown:SetScript("OnUpdate", function(self)
        local left = REFRESH_WAIT - (GetTime() - lastSearch)
        if left <= 0 then return self:Hide() end
        line:SetWidth(math.max(1, pane:GetWidth() * left / REFRESH_WAIT))
        line:Show()
    end)
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
    if pane:IsShown() then ns.Filters.Sync(); ns.Sidecar.Follow(ns.Filters.Active()) else ns.Sidecar.Hide() end
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
    hooksecurefunc("LFGListSearchPanel_SetCategory", function() seen = nil; Pane.Update() end)
    -- Every search restarts the cooldown line.
    hooksecurefunc("LFGListSearchPanel_DoSearch", function() lastSearch = GetTime(); if cooldown then cooldown:Show() end end)
end)

ns.On("LFG_LIST_SEARCH_RESULTS_RECEIVED", function()
    local now = {}
    wipe(fresh)
    local _, ids = C_LFGList.GetSearchResults()
    for _, id in ipairs(ids or {}) do
        local info = C_LFGList.GetSearchResultInfo(id)
        local act = info and info.activityIDs and info.activityIDs[1]
        if info and info.leaderName and act then
            local key = info.leaderName .. "|" .. act
            now[key] = true
            if seen and not seen[key] then fresh[id] = true end
        end
    end
    seen = now
    offset = 0
    RenderSoon()
end)
ns.On("LFG_LIST_SEARCH_RESULT_UPDATED", RenderSoon)
ns.On("GROUP_ROSTER_UPDATE", RenderSoon)
ns.On("PARTY_LEADER_CHANGED", RenderSoon)
ns.On("LFG_LIST_ACTIVE_ENTRY_UPDATE", function() Pane.Update() end)
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
    if cooldown then cooldown:Show() end
end)
