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

    Action button: Apply (click: sign up at once; shift-click: Blizzard's sign-up
    dialog, for a note) / time left (hover: Cancel) / Reapply (click twice: at once;
    shift-click: the dialog). Shift held while the dialog opens also keeps another
    addon's auto-sign-up from pressing Sign Up for the player (EllesmereUI's).
--]]

local _, ns = ...

local Pane = {}
ns.Pane = Pane

local Kit, Groups = ns.Kit, ns.Groups
local ROW_H, BAR_H, HEAD_H = 24, 26, 20
local W_INST, W_COMP, W_SCORE, W_ACT, GAP, PAD = 38, 97, 34, 56, 6, 6
local TILE, TILE_GAP = 17, 3  -- five tiles: 5 x 17 + 4 x 3 = W_COMP
local W_DIFF = 16
-- Difficulty letters in loot-quality colours: N uncommon green, H rare blue,
-- M legendary orange (epic purple skipped: too dark to read here).
local DIFF_COLOR = { N = { 0.12, 1, 0 }, H = { 0, 0.44, 0.87 }, M = { 1, 0.5, 0 }, LFR = { 0.7, 0.7, 0.7 } }
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
local raidDiff = {}  -- raid name -> { difficulty letter -> groups in view }
local offset = 0
local lastSearch, armed = 0, nil
-- New mark: listings not in the previous search's results (leader + activity),
-- until the next search. Nothing is marked on a category's first search.
local seen, fresh = nil, {}

-- Friends / guild marks at the end of the name column, in the colours WoW
-- players know (Battle.net blue, guild chat green) and in two shapes, so
-- they never differ by colour alone (WCAG 1.4.1): a person for friends, a
-- banner for the guild. Options can colour the name instead, as Blizzard does.
local FRIEND = { 0.51, 0.77, 1 }
local PEOPLE = { { 4, 4, 3 }, { 8, 3, -3 } }
local BANNER = { { 2, 11, 0, nil, -3 }, { 6, 5, 2.5, nil, 1 } }
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

-- Swap (opt-in): the sign-up with the least time left.
local function Oldest()
    local o
    for _, p in ipairs(pinned) do
        if p.status == "applied" and (not o or (p.remaining or 0) < (o.remaining or 0)) then o = p end
    end
    return o
end

local function OnAction(btn)
    local row = btn.row
    if not row then return end
    ns.Trace("pane", "action", row.code, row.leader, "status", row.status, "shift", IsShiftKeyDown())
    if row.status == "applied" then
        C_LFGList.CancelApplication(row.id)
        ns.Log.Emit("cancel", { code = row.code, leader = row.leader })
    elseif row.status == "invited" or row.status == "inviteaccepted" then
        return
    elseif btn.full and ns.db.swap and row.fits and not OVER[row.status] then
        -- Withdraw the oldest; this row's button then reads Apply.
        local o = Oldest()
        if o then
            C_LFGList.CancelApplication(o.id)
            ns.Log.Emit("cancel", { code = o.code, leader = o.leader })
        end
    elseif IsShiftKeyDown() and LFGListApplicationDialog_Show then
        -- Shift-click: Blizzard's sign-up dialog, for a note (our notes show under it).
        armed = nil
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
    local GREY_T = 0.55
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText(row.name or "?", 1, 1, 1)
    if row.hidden then GameTooltip:AddLine("Hidden by clean-up: " .. row.hidden, 1, 0.72, 0.3, true) end
    GameTooltip:AddDoubleLine(row.activity .. (row.difficulty and (" (" .. row.difficulty .. ")") or ""), Clock(row.age),
        0.85, 0.85, 0.85, GREY_T, GREY_T, GREY_T)
    if row.isRaid then
        GameTooltip:AddLine(row.leader or "?", 1, 1, 1)
        GameTooltip:AddLine(("|A:%s:14:14|a %d   |A:%s:14:14|a %d   |A:%s:14:14|a %d"):format(
            ROLE_ATLAS.TANK, row.counts.TANK, ROLE_ATLAS.HEALER, row.counts.HEALER, ROLE_ATLAS.DAMAGER, row.counts.DAMAGER), 1, 1, 1)
        GameTooltip:AddLine(row.total and (row.down .. "/" .. row.total .. " bosses down") or (row.down .. " bosses down"),
            GREY_T, GREY_T, GREY_T)
        -- Which bosses, by name: a lockout isn't cleared in order.
        local listed = {}
        for _, boss in ipairs(row.bosses) do
            listed[boss] = true
            local dead = row.killed[boss]
            GameTooltip:AddDoubleLine("  " .. boss, dead and "Dead" or "Alive", 0.85, 0.85, 0.85,
                dead and 1 or MINT[1], dead and 0.72 or MINT[2], dead and 0.3 or MINT[3])
        end
        for boss in pairs(row.killed) do  -- a name the journal spells differently
            if not listed[boss] then GameTooltip:AddDoubleLine("  " .. boss, "Dead", 0.85, 0.85, 0.85, 1, 0.72, 0.3) end
        end
    else
        local score = row.score or 0
        local c = score > 0 and C_ChallengeMode.GetDungeonScoreRarityColor(score)
        GameTooltip:AddDoubleLine(row.leader or "?", score > 0 and score or "-", 1, 1, 1,
            c and c.r or GREY_T, c and c.g or GREY_T, c and c.b or GREY_T)
        -- Members as their spec icons: each spec's icon is its own.
        local icons = {}
        for _, s in ipairs(row.specs) do
            if s.icon then icons[#icons + 1] = ("|T%s:20:20:0:0:64:64:5:59:5:59|t"):format(s.icon) end
        end
        if #icons > 0 then GameTooltip:AddLine(table.concat(icons, " ")) end
    end
    -- People you know, by name (the game gives Battle.net friends, character
    -- friends and guildmates as name lists); counts if the names don't come.
    if row.friends > 0 or row.guild > 0 then
        local ok, bnet, chars, guild = pcall(C_LFGList.GetSearchResultFriends, row.id)
        local function Names(list)
            local out = {}
            for _, n in ipairs(type(list) == "table" and list or {}) do
                if type(n) == "string" and not issecretvalue(n) then out[#out + 1] = n end
            end
            return out
        end
        local friends = ok and Names(bnet) or {}
        for _, n in ipairs(ok and Names(chars) or {}) do friends[#friends + 1] = n end
        local mates = ok and Names(guild) or {}
        local g = GuildColor()
        if #friends > 0 then
            GameTooltip:AddLine((#friends == 1 and "Friend: " or "Friends: ") .. table.concat(friends, ", "), FRIEND[1], FRIEND[2], FRIEND[3], true)
        elseif row.friends > 0 then
            GameTooltip:AddLine(row.friends .. (row.friends == 1 and " friend" or " friends") .. " in the group", FRIEND[1], FRIEND[2], FRIEND[3])
        end
        if #mates > 0 then
            GameTooltip:AddLine((#mates == 1 and "Guildmate: " or "Guildmates: ") .. table.concat(mates, ", "), g[1], g[2], g[3], true)
        elseif row.guild > 0 then
            GameTooltip:AddLine(row.guild .. (row.guild == 1 and " guildmate" or " guildmates") .. " in the group", g[1], g[2], g[3])
        end
    end
    if row.comment and row.comment ~= "" then GameTooltip:AddLine(row.comment, 0.85, 0.85, 0.85, true) end
    GameTooltip:Show()
end

local function ActionTooltip(btn)
    local row = btn.row
    if not row then return end
    local tip
    if row.status == "applied" then tip = "Click to cancel this sign-up."
    elseif row.status == "invited" then tip = "You're invited: answer in Blizzard's invite window."
    elseif NotLeader() then tip = "Only your party leader can sign the party up."
    elseif OVER[row.status] then tip = "You signed up here before (" .. row.status:gsub("_", " ") .. "). Click twice: sign up again at once. Shift-click: sign up again with a note."
    elseif not row.fits then tip = Groups.Party() and "Not enough open seats for your party's roles." or "No open seat for the roles you sign up as."
    elseif btn.full and ns.db.swap then
        local o = Oldest()
        tip = "All five sign-ups are in use. Click to withdraw the oldest"
            .. (o and (" (" .. (o.code or "?") .. ", " .. (o.leader or "?") .. ")") or "") .. ", then Apply here."
    elseif btn.full then tip = "All five sign-ups are in use (Options: Swap can make room)." end
    if not (tip or ns.Hints()) then return end
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    GameTooltip:SetText(tip or "Click: sign up at once. Shift-click: sign up with a note.", 1, 1, 1, 1, true)
    if ns.Hints() then
        GameTooltip:AddLine("Right-click the row: whisper, report, blacklist or hide the leader.", 0.55, 0.55, 0.55, true)
    end
    GameTooltip:Show()
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
    f.icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)  -- icon border trimmed, plus a ~10% zoom
    f.role = f:CreateTexture(nil, "ARTWORK")
    f.role:SetSize(12, 12)
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
        r.tiles[t]:SetPoint("LEFT", (t - 1) * (TILE + TILE_GAP), 0)
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
    r.new:SetSize(5, 5)
    r.new:SetPoint("LEFT", 3, 0)
    local round = r:CreateMaskTexture()
    round:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    round:SetAllPoints(r.new)
    r.new:AddMaskTexture(round)
    for key, shape in pairs({ friendMark = PEOPLE, guildMark = BANNER }) do
        local m = CreateFrame("Frame", nil, r)
        m:SetSize(10, 12)
        m.tint = Kit.Glyph(m, shape)
        m:Hide()
        r[key] = m
    end
    r.name = Text(r)
    r.name:SetPoint("LEFT", PAD + 5, 0)  -- room for the new mark
    r.name:SetPoint("RIGHT", r.diff, "LEFT", -GAP, 0)

    -- Right-click: whisper, report, blacklist or hide the leader.
    r:RegisterForClicks("RightButtonUp")
    r:SetScript("OnClick", function(self)
        local row = self.row
        if not (row and row.leader and MenuUtil) then return end
        MenuUtil.CreateContextMenu(self, function(_, root)
            root:CreateTitle(row.leader)
            root:CreateButton("Whisper leader", function()
                local tell = ChatFrameUtil and ChatFrameUtil.SendTell or ChatFrame_SendTell
                if tell then tell(row.leader) end
            end)
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
    -- Pinned sign-ups too (player). A mixed group: two marks; a coloured name
    -- goes friend blue, as Blizzard's list does.
    local marks, ink = {}, { 1, 1, 1 }
    if ns.db.nameColors then
        ink = row.friends > 0 and FRIEND or row.guild > 0 and GuildColor() or ink
    else
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
            -- Every tile keeps a black ring: an empty seat already reads as open
            -- (player: the mint ring on your role's seat was clutter).
            for _, t in ipairs(tile._border) do t:SetColorTexture(0, 0, 0, 1) end
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
    elseif full and ns.db.swap and row.fits then
        label = "Swap"
    elseif not row.fits or full then
        label, enabled = "-", false
    end
    act:SetText(label)
    act:SetEnabled(enabled)
    act:GetFontString():SetTextColor(ink[1], ink[2], ink[3], (enabled or row.outcome) and 1 or 0.4)
end

-- The difficulty most groups listed for a raid are on, or nil.
-- The difficulty the player searched ("<raid> (Normal)", Blizzard's
-- suggestion) wins, so it holds with no groups listed; else the one most
-- listed groups for that raid are on.
local SEARCH_DIFF = { N = PLAYER_DIFFICULTY1, H = PLAYER_DIFFICULTY2, M = PLAYER_DIFFICULTY6 }
function Pane.RaidDifficulty(raid)
    local ok, text = pcall(function() return panel.SearchBox:GetText() end)
    if ok and type(text) == "string" and not issecretvalue(text) and raid and text:find(raid, 1, true) then
        for d, word in pairs(SEARCH_DIFF) do
            if text:find("(" .. word .. ")", 1, true) then return d end
        end
    end
    local best, n = nil, 0
    for d, c in pairs(raidDiff[raid] or {}) do if c > n then best, n = d, c end end
    return best
end

function Pane.Render()
    if not (pane and pane:IsShown()) then return end
    ns.Filters.Sync()  -- before Blizzard's search on a category change, too
    summary:SetText(ns.Filters.Summary(ns.Filters.Active()))
    local hiddenCount
    pinned, results, hiddenCount = Groups.List(showHidden)
    if showHidden and hiddenCount == 0 then showHidden = false; pinned, results, hiddenCount = Groups.List(false) end
    -- Difficulty per raid in view (My lockout follows it).
    wipe(raidDiff)
    for _, list in ipairs({ pinned, results }) do
        for _, row in ipairs(list) do
            if row.isRaid and row.difficulty then
                local c = raidDiff[row.activity] or {}
                c[row.difficulty] = (c[row.difficulty] or 0) + 1
                raidDiff[row.activity] = c
            end
        end
    end
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
        if not ns.Hints() then return end
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
        if ns.Hints() then GameTooltip:AddLine("Click to set it up.", 0.74, 0.74, 0.74) end
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
        b:SetPoint("RIGHT", x - (#ROLES - i) * 24, 0)  -- 24px apart (WCAG 2.5.8 spacing)
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
            if not ns.Hints() then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Sign up as " .. _G[self.role]:lower() .. ": click to switch")
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        roleButtons[#roleButtons + 1] = b
    end

    local function Head(label, width, justify)
        local fs = Text(head, nil, justify)
        fs:SetTextColor(0.55, 0.55, 0.55)
        fs:SetText(label)
        if width then fs:SetWidth(width) end
        return fs
    end
    local actRight = -(PAD + W_ACT + GAP)
    pane.scoreHead = Head("Score", W_SCORE, "RIGHT")
    pane.scoreHead:SetPoint("RIGHT", actRight, 0)
    local comp = Head("Comp", W_COMP)
    comp:SetPoint("RIGHT", pane.scoreHead, "LEFT", -GAP, 0)
    pane.instHead = Head("Dungeon", W_INST)
    pane.instHead:SetPoint("RIGHT", comp, "LEFT", -GAP, 0)
    pane.diffHead = Head("", W_DIFF)
    pane.diffHead:SetPoint("RIGHT", pane.instHead, "LEFT", 0, 0)
    local name = Head("Name")
    name:SetPoint("LEFT", PAD + 5, 0)
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
    pane:SetPoint("TOP", panel.SearchBox, "BOTTOM", 0, -4)
    -- Down to just above Blizzard's Back button, so no sliver of the list shows.
    pane:SetPoint("RIGHT", panel, "RIGHT")
    pane:SetPoint("BOTTOM", panel.BackButton, "TOP", 0, 2)
    -- Above Blizzard's list, below its search suggestions (AutoCompleteFrame
    -- sits at a fixed level over the list): the suggestions stay usable.
    -- Our rows nest about 3 levels deep, so the pane sits 5 under.
    local ac = panel.AutoCompleteFrame
    pane:SetFrameLevel(ac and ac:GetFrameLevel() - 5 or panel:GetFrameLevel() + 50)
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
    backButton:SetScript("OnClick", function()
        ns.db.useBlizzard = false
        ns.Log.Emit("setting", { key = "useBlizzard", on = false })
        Pane.Update()
    end)
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
    -- Blizzard's Filter button: our keys filter writes its settings, so say so.
    local fb = p.FilterButton
    if not fb then return ns.Trace("pane", "no Filter button") end
    fb:HookScript("OnEnter", function(self)
        if not (ns.Hints() and pane and pane:IsShown() and ns.Filters.Kind() == "keys") then return end
        if not GameTooltip:IsOwned(self) then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(FILTER) end
        GameTooltip:AddLine("Set by PickupGroup's filter: change it there (click the summary above the list).", 0.74, 0.74, 0.74, true)
        GameTooltip:Show()
    end)
    fb:HookScript("OnLeave", function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
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

-- ---------------------------------------------------------------------------
-- Teleport: a standalone button while the party is full (5/5) for a known
-- dungeon and not yet inside, casting that dungeon's teleport (the "Path
-- of ..." spells in the Hero's Path flyouts, matched by their description).
-- The dungeon: the party's listing, else the group last joined through a
-- sign-up. A secure button: shown, hidden and set up only out of combat.
-- Shift-drag moves it.
-- ---------------------------------------------------------------------------
local teleport, teleportCache = nil, {}
-- On cooldown (just cast, or used earlier): nothing to click. Longer than a
-- global cooldown counts; an unreadable (secret) cooldown counts as ready.
local function OnCooldown(spell)
    local cd = C_Spell.GetSpellCooldown(spell)
    if not cd or issecretvalue(cd.duration) or issecretvalue(cd.startTime) then return false end
    return cd.startTime > 0 and cd.duration > 2
end

local function TeleportSpell(dungeon)
    if teleportCache[dungeon] ~= nil then return teleportCache[dungeon] or nil end
    local found = false
    for i = 1, GetNumFlyouts() do
        local fid = GetFlyoutID(i)
        local _, _, slots, known = GetFlyoutInfo(fid)
        for s = 1, (known and slots or 0) do
            local spellID, _, isKnown = GetFlyoutSlotInfo(fid, s)
            local desc = spellID and C_Spell.GetSpellDescription(spellID) or ""
            if isKnown and desc:lower():find(dungeon:lower(), 1, true) then found = spellID end
        end
    end
    -- Descriptions can load late: only remember a hit.
    if found then teleportCache[dungeon] = found; ns.Trace("teleport", "spell for", dungeon, found) end
    return found or nil
end

-- The party's own listing comes down when the group fills: remember its
-- dungeon until the group breaks up.
local listed, lastDungeon
local function PartyDungeon()
    if not IsInGroup() then listed = nil end
    local entry = C_LFGList.GetActiveEntryInfo()
    local act = entry and entry.activityIDs and entry.activityIDs[1]
    local info = act and C_LFGList.GetActivityInfoTable(act)
    if info and (info.maxNumPlayers or 5) <= 5 then listed = Groups.BaseName(info.fullName) end
    return listed or ns.Applications.LastJoined()
end

local function UpdateTeleport()
    if InCombatLockdown() then return end  -- PLAYER_REGEN_ENABLED tries again
    local dungeon = IsInGroup() and not IsInRaid() and GetNumGroupMembers() == 5
        and not IsInInstance() and PartyDungeon()
    if dungeon ~= lastDungeon then
        lastDungeon = dungeon
        ns.Trace("teleport", "party dungeon", tostring(dungeon), listed and "(party listing)" or "(last sign-up joined)")
    end
    local spell = dungeon and TeleportSpell(dungeon)
    if not spell or OnCooldown(spell) then if teleport then teleport:Hide() end return end
    if not teleport then
        Kit.ApplyFontFace()
        teleport = CreateFrame("Button", "PickupGroupTeleport", UIParent, "SecureActionButtonTemplate")
        teleport:SetSize(150, 26)
        local p = ns.db.teleportPoint or { "TOP", "TOP", 0, -140 }
        teleport:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        teleport:SetFrameStrata("HIGH")
        Kit.Button(teleport)
        teleport:RegisterForClicks("AnyUp", "AnyDown")
        teleport:SetAttribute("type", "spell")
        teleport:SetMovable(true)
        teleport:RegisterForDrag("LeftButton")
        teleport:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
        teleport:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local a, _, b, x, y = self:GetPoint()
            ns.db.teleportPoint = { a, b, x, y }
        end)
        teleport:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetSpellByID(self:GetAttribute("spell"))
            if ns.Hints() then GameTooltip:AddLine("Shift-drag to move.", 0.55, 0.55, 0.55) end
            GameTooltip:Show()
        end)
        teleport:HookScript("OnLeave", function() GameTooltip:Hide() end)
    end
    teleport:SetAttribute("spell", spell)
    teleport:SetText("Teleport: " .. Groups.Code(dungeon))
    teleport:Show()
end

for _, ev in ipairs({ "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "LFG_LIST_ACTIVE_ENTRY_UPDATE",
    "PLAYER_REGEN_ENABLED", "ZONE_CHANGED_NEW_AREA", "SPELLS_CHANGED", "SPELL_UPDATE_COOLDOWN" }) do
    ns.On(ev, UpdateTeleport)
end
