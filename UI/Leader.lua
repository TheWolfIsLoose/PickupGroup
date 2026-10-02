--[[
    PickupGroup - UI/Leader.lua
    The leader view, keys only (raids come later): our own frame laid over
    Blizzard's applicant list while the player leads a Mythic Keystone
    listing. Blizzard's frames are never hidden, moved or written.

      top bar   what the group still needs (seats, Bloodlust, battle rez) . applicant count
      headers   Name | iLvl | Score | <dungeon code> (best run there) | adds | Invite / Decline
      rows      one per applicant member, newest Blizzard order; a note line under an
                applicant who wrote one (shown, never read: the game protects it)

    Cues point at what an applicant adds, never at who they are: no class or
    spec filter (player, Decided). A mint edge on the row's left = fills an
    open seat (from 3 in the group); "Lust" / "Rez" = brings what the group lacks; dimmed = over
    the seats for that role, a realm region the keys filter has off, or
    blacklisted (the tooltip says which). Nothing is hidden.
--]]

local _, ns = ...

local Leader = {}
ns.Leader = Leader

local Kit, Groups = ns.Kit, ns.Groups
local MINT, AMBER, GREY = Kit.Palette.brand, { 1, 0.72, 0.3 }, { 0.55, 0.55, 0.55 }
local ROW_H, NOTE_H, BAR_H, HEAD_H, PAD, GAP = 24, 16, 26, 20, 6, 6
local INSET = 10  -- right-hand column kept for the scroll track
local W_ICON, W_ILVL, W_SCORE, W_KEY, W_ADDS, W_INV, W_X = 17, 26, 30, 30, 40, 44, 18
local SEATS = { TANK = 1, HEALER = 1, DAMAGER = 3 }
local STATUS = { invited = "Invited", inviteaccepted = "Joined", invitedeclined = "Passed", declined = "Declined",
                 declined_full = "Declined", declined_delisted = "Declined", cancelled = "Withdrew",
                 timedout = "Expired", failed = "Failed" }

local viewer, pane, needText, countText, keyHead, track, thumb
local lines = {}
local offset = 0

local function Text(parent, justify, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "PickupGroupFontSmall")
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    return fs
end

-- The listing being led, if it's a key: activity ID, its info.
local function KeyListing()
    local e = C_LFGList.GetActiveEntryInfo()
    local act = e and (e.activityIDs and e.activityIDs[1] or e.activityID)
    local info = act and C_LFGList.GetActivityInfoTable(act)
    if info and info.isMythicPlusActivity then return act, info end
end

local function Eligible()
    if not (viewer and viewer:IsShown()) or ns.db.useBlizzard then return false end
    if IsInGroup() and not UnitIsGroupLeader("player") then return false end  -- only the leader acts
    return KeyListing() ~= nil
end

-- ---------------------------------------------------------------------------
-- Reading: applicants and what the group has
-- ---------------------------------------------------------------------------
local function Members(id, act)
    local a = C_LFGList.GetApplicantInfo(id)
    if not a then return nil end
    a.members = {}
    for m = 1, a.numMembers or 0 do
        local name, class, _, _, ilvl, _, _, _, _, role, _, score, _, _, _, spec = C_LFGList.GetApplicantMemberInfo(id, m)
        if issecretvalue(name) then return nil end  -- restricted content (in combat, a key): skip
        local best = C_LFGList.GetApplicantDungeonScoreForListing(id, m, act) or {}
        local _, specName, _, icon = GetSpecializationInfoByID(spec or 0)
        a.members[m] = { name = name, class = class, ilvl = ilvl or 0, role = role, score = score or 0,
                         icon = icon, specName = specName, keyLevel = best.bestRunLevel or 0,
                         timed = best.finishedSuccess, keyMs = best.bestRunDurationMs }
    end
    return a
end

-- Seats left by role and the buff classes the group has, counting invited
-- applicants as seated.
local function Group(apps)
    local need = Groups.Need()
    local left = { TANK = SEATS.TANK - need.TANK, HEALER = SEATS.HEALER - need.HEALER, DAMAGER = SEATS.DAMAGER - need.DAMAGER }
    local classes, size = CopyTable(need.classes), need.size
    for _, a in ipairs(apps) do
        if a.applicationStatus == "invited" then
            for _, m in ipairs(a.members) do
                size = size + 1
                if left[m.role] then left[m.role] = left[m.role] - 1 end
                classes[m.class or "?"] = true
            end
        end
    end
    local has = function(set) for file in pairs(classes) do if set[file] then return true end end end
    return left, has(ns.Filters.LUST), has(ns.Filters.BREZ), size
end

-- The mint "fills a seat" edge waits until the group has this many (player):
-- with one or two seated, comp is wide open and the cue is just noise.
local RING_FROM = 3

-- Cues per member: fills (an open seat), adds ("Lust" / "Rez"), why dimmed.
local function Cue(apps)
    local left, lust, brez, size = Group(apps)
    local f = ns.Filters.Active("keys")
    for _, a in ipairs(apps) do
        local seats = CopyTable(left)
        for _, m in ipairs(a.members) do
            m.fills = (seats[m.role] or 0) > 0
            m.ring = m.fills and size >= RING_FROM
            if m.fills then seats[m.role] = seats[m.role] - 1 end
            local adds = {}
            if not lust and ns.Filters.LUST[m.class or ""] then adds[#adds + 1] = "Lust" end
            if not brez and ns.Filters.BREZ[m.class or ""] then adds[#adds + 1] = "Rez" end
            m.adds = table.concat(adds, " ")
            m.region = Groups.Region(m.name)
            m.why = (not m.fills and "no open " .. (_G[m.role] or "seat"):lower() .. " seat")
                or (f.regions and not f.regions[m.region] and ("realm region " .. m.region .. " is off in your filter"))
                or (ns.Cleanup.IsBlacklisted(m.name) and "on your blacklist") or nil
        end
    end
    return left, lust, brez
end

-- ---------------------------------------------------------------------------
-- Tooltip
-- ---------------------------------------------------------------------------
local function Tooltip(line)
    local m, a = line.member, line.app
    if not m then return end
    GameTooltip:SetOwner(line, "ANCHOR_RIGHT")
    local c = RAID_CLASS_COLORS[m.class or ""]
    GameTooltip:SetText(m.name or "?", c and c.r or 1, c and c.g or 1, c and c.b or 1)
    GameTooltip:AddLine((m.specName or "") .. "  " .. ("%.0f"):format(m.ilvl) .. " item level", 0.85, 0.85, 0.85)
    if m.score > 0 then
        local sc = C_ChallengeMode.GetDungeonScoreRarityColor(m.score)
        GameTooltip:AddLine("Score " .. m.score, sc and sc.r or 1, sc and sc.g or 1, sc and sc.b or 1)
    end
    local _, info = KeyListing()
    local where = info and info.fullName and info.fullName:gsub("%s*%(.-%)$", "") or "this dungeon"
    if m.keyLevel > 0 then
        local t = m.keyMs and ("  " .. ("%d:%02d"):format(m.keyMs / 60000, (m.keyMs / 1000) % 60)) or ""
        GameTooltip:AddLine("Best in " .. where .. ": +" .. m.keyLevel .. (m.timed and " timed" or " not timed") .. t,
            m.timed and 1 or AMBER[1], m.timed and 1 or AMBER[2], m.timed and 1 or AMBER[3])
    else
        GameTooltip:AddLine("No run in " .. where .. " this season", GREY[1], GREY[2], GREY[3])
    end
    GameTooltip:AddLine("Realm region: " .. (Groups.REGION_NAME and Groups.REGION_NAME[m.region] or m.region), 0.85, 0.85, 0.85)
    if m.adds ~= "" then GameTooltip:AddLine("Adds " .. m.adds:gsub("Lust", "Bloodlust"):gsub("Rez", "battle rez"):gsub(" b", ", b"), MINT[1], MINT[2], MINT[3]) end
    if m.fills then GameTooltip:AddLine("Fills an open " .. (_G[m.role] or "seat"):lower() .. " seat", MINT[1], MINT[2], MINT[3]) end
    if m.why then GameTooltip:AddLine("Dimmed: " .. m.why, AMBER[1], AMBER[2], AMBER[3], true) end
    if a.numMembers > 1 then GameTooltip:AddLine("Applied with " .. (a.numMembers - 1) .. " more", 0.85, 0.85, 0.85) end
    if a.comment and a.comment ~= "" then GameTooltip:AddLine(a.comment, 1, 1, 1, true) end
    GameTooltip:Show()
end

-- ---------------------------------------------------------------------------
-- Lines: a member row or a note line, pooled
-- ---------------------------------------------------------------------------
local function Line(i)
    if lines[i] then return lines[i] end
    local l = CreateFrame("Button", nil, pane)
    l.stripe = l:CreateTexture(nil, "BACKGROUND", nil, -7)
    l.stripe:SetAllPoints()
    l.new = l:CreateTexture(nil, "OVERLAY")
    l.new:SetSize(4, 4)
    l.new:SetPoint("LEFT", 2, 0)
    -- Fills an open seat (from RING_FROM in the group): a mint edge on the
    -- row's left, clear of the spec icon (player: a ring on the icon cluttered it).
    l.edge = l:CreateTexture(nil, "OVERLAY")
    l.edge:SetColorTexture(MINT[1], MINT[2], MINT[3], 1)
    l.edge:SetPoint("TOPLEFT")
    l.edge:SetPoint("BOTTOMLEFT")
    l.edge:SetWidth(2)
    l.new:SetColorTexture(MINT[1], MINT[2], MINT[3], 1)
    l.tile = CreateFrame("Frame", nil, l)
    l.tile:SetSize(W_ICON, W_ICON)
    l.tile:SetPoint("LEFT", PAD, 0)
    Kit.Fill(l.tile, { 0.11, 0.11, 0.11, 1 })
    Kit.Border(l.tile)
    l.icon = l.tile:CreateTexture(nil, "ARTWORK")
    l.icon:SetPoint("TOPLEFT", 1, -1)
    l.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    l.icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)
    -- A second member of the same application: indented, joined to the row above.
    l.linkV = l:CreateTexture(nil, "ARTWORK")
    l.linkV:SetColorTexture(0.4, 0.4, 0.4, 1)
    l.linkV:SetSize(1, ROW_H / 2 + 4)
    l.linkV:SetPoint("TOPLEFT", PAD + 6, 4)
    l.linkH = l:CreateTexture(nil, "ARTWORK")
    l.linkH:SetColorTexture(0.4, 0.4, 0.4, 1)
    l.linkH:SetSize(6, 1)
    l.linkH:SetPoint("LEFT", PAD + 6, 0)

    l.x = CreateFrame("Button", nil, l)
    l.x:SetSize(W_X, 18)
    l.x:SetPoint("RIGHT", -PAD, 0)
    Kit.Button(l.x)
    l.x.tint = Kit.Glyph(l.x, { { 9, 2, 0, math.pi / 4 }, { 9, 2, 0, -math.pi / 4 } })
    l.inv = CreateFrame("Button", nil, l)
    l.inv:SetSize(W_INV, 18)
    l.inv:SetPoint("RIGHT", l.x, "LEFT", -2, 0)
    Kit.Button(l.inv)
    l.inv:SetNormalFontObject("PickupGroupFontSmall")
    l.inv:SetHighlightFontObject("PickupGroupFontSmall")
    l.inv:SetDisabledFontObject("PickupGroupFontSmall")
    l.inv:SetText("Invite")
    l.inv:SetScript("OnClick", function(self)
        C_LFGList.InviteApplicant(self.id)
        ns.Log.Emit("lead", { action = "invite", applicant = self.id, name = self.who })
    end)
    l.x:SetScript("OnClick", function(self)
        C_LFGList.DeclineApplicant(self.id)
        ns.Log.Emit("lead", { action = "decline", applicant = self.id, name = self.who })
    end)
    l.x:HookScript("OnEnter", function(self)
        if not ns.Hints() then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Decline"); GameTooltip:Show()
    end)
    l.x:HookScript("OnLeave", function() GameTooltip:Hide() end)

    l.adds = Text(l, "LEFT")
    l.adds:SetWidth(W_ADDS)
    l.adds:SetPoint("RIGHT", l.inv, "LEFT", -GAP, 0)
    l.adds:SetTextColor(MINT[1], MINT[2], MINT[3])
    l.key = Text(l, "RIGHT")
    l.key:SetWidth(W_KEY)
    l.key:SetPoint("RIGHT", l.adds, "LEFT", -GAP, 0)
    l.score = Text(l, "RIGHT")
    l.score:SetWidth(W_SCORE)
    l.score:SetPoint("RIGHT", l.key, "LEFT", -GAP, 0)
    l.ilvl = Text(l, "RIGHT")
    l.ilvl:SetWidth(W_ILVL)
    l.ilvl:SetPoint("RIGHT", l.score, "LEFT", -GAP, 0)
    l.name = Text(l)
    l.name:SetPoint("LEFT", l.tile, "RIGHT", 4, 0)
    l.name:SetPoint("RIGHT", l.ilvl, "LEFT", -GAP, 0)
    l.note = Text(l)
    l.note:SetPoint("LEFT", PAD + W_ICON + 4, 0)
    l.note:SetPoint("RIGHT", -PAD, 0)
    l.note:SetTextColor(0.74, 0.74, 0.74)

    l:SetScript("OnEnter", Tooltip)
    l:SetScript("OnLeave", function() GameTooltip:Hide() end)
    l:EnableMouseWheel(true)
    l:SetScript("OnMouseWheel", function(_, d) offset = math.max(0, offset - d); Leader.Render() end)
    lines[i] = l
    return l
end

local function PaintMember(l, a, m, first, index)
    l.member, l.app = m, a
    l:SetHeight(ROW_H)
    l.stripe:SetColorTexture(1, 1, 1, (index % 2 == 0) and 0.05 or 0)
    l.note:Hide()
    for _, f in ipairs({ l.tile, l.name, l.ilvl, l.score, l.key, l.adds }) do f:Show() end
    l.new:SetShown(first and a.isNew == true)
    l.tile:ClearAllPoints()
    l.tile:SetPoint("LEFT", first and PAD or (PAD + 12), 0)
    l.linkV:SetShown(not first); l.linkH:SetShown(not first)
    l.icon:SetTexture(m.icon)
    l.edge:SetShown(m.ring == true)
    l.name:SetText((m.name or "?"):match("^[^%-]+") or "?")
    l.ilvl:SetText(("%.0f"):format(m.ilvl))
    l.score:SetText(m.score > 0 and m.score or "-")
    local sc = m.score > 0 and C_ChallengeMode.GetDungeonScoreRarityColor(m.score)
    if sc then l.score:SetTextColor(sc.r, sc.g, sc.b) else l.score:SetTextColor(GREY[1], GREY[2], GREY[3]) end
    -- Best run here: white when timed, amber when not (the tooltip says which).
    l.key:SetText(m.keyLevel > 0 and ("+" .. m.keyLevel) or "-")
    local kc = m.keyLevel == 0 and GREY or (m.timed and { 1, 1, 1 } or AMBER)
    l.key:SetTextColor(kc[1], kc[2], kc[3])
    l.adds:SetText(m.adds)
    -- Actions on the applicant's first row; a status in place of Invite once it moved on.
    local open = a.applicationStatus == "applied"
    l.inv:SetShown(first); l.x:SetShown(first and open)
    l.inv.id, l.x.id, l.inv.who, l.x.who = a.applicantID, a.applicantID, m.name, m.name
    l.inv:SetText(open and "Invite" or (STATUS[a.applicationStatus] or a.applicationStatus or "?"))
    l.inv:SetEnabled(open)
    l:SetAlpha((m.why or not open) and 0.5 or 1)
end

local function PaintNote(l, a)
    l.member, l.app = nil, a
    l:SetHeight(NOTE_H)
    l.stripe:SetColorTexture(0, 0, 0, 0)
    for _, f in ipairs({ l.tile, l.name, l.ilvl, l.score, l.key, l.adds, l.inv, l.x, l.new, l.linkV, l.linkH, l.edge }) do f:Hide() end
    l.note:SetText(a.comment)
    l.note:Show()
    l:SetAlpha(a.applicationStatus == "applied" and 1 or 0.5)
end

-- ---------------------------------------------------------------------------
-- Render
-- ---------------------------------------------------------------------------
function Leader.Render()
    if not (pane and pane:IsShown()) then return end
    local act, info = KeyListing()
    if not act then return end
    local apps = {}
    for _, id in ipairs(C_LFGList.GetApplicants() or {}) do
        local ok, a = pcall(Members, id, act)
        if ok and a then apps[#apps + 1] = a elseif not ok then ns.LogError(a) end
    end
    table.sort(apps, function(x, y) return (x.displayOrderID or 0) < (y.displayOrderID or 0) end)
    local left, lust, brez = Cue(apps)

    local needs = {}
    for _, r in ipairs({ "TANK", "HEALER", "DAMAGER" }) do
        if left[r] > 0 then needs[#needs + 1] = (left[r] > 1 and (left[r] .. " ") or "") .. _G[r]:lower() end
    end
    if not lust then needs[#needs + 1] = "Bloodlust" end
    if not brez then needs[#needs + 1] = "battle rez" end
    needText:SetText(#needs > 0 and ("Needs " .. table.concat(needs, ", ")) or "Group has everything")
    countText:SetText(#apps .. (#apps == 1 and " applicant" or " applicants"))
    keyHead:SetText(info and info.fullName and Groups.Code((info.fullName:gsub("%s*%(.-%)$", ""))) or "Key")

    -- Scroll stops once the last applicant is in view (no empty space below).
    local roomH, used, maxOffset = pane:GetHeight() - BAR_H - HEAD_H, 0, 0
    for i = #apps, 1, -1 do
        local a = apps[i]
        used = used + #a.members * ROW_H + ((a.comment or "") ~= "" and NOTE_H or 0)
        if used > roomH then maxOffset = i; break end
    end
    offset = math.min(offset, maxOffset)
    local y, n, room = -(BAR_H + HEAD_H), 0, pane:GetHeight() - BAR_H - HEAD_H
    for i = offset + 1, #apps do
        local a = apps[i]
        local h = #a.members * ROW_H + ((a.comment or "") ~= "" and NOTE_H or 0)
        if -y - BAR_H - HEAD_H + h > room then break end
        for m, member in ipairs(a.members) do
            n = n + 1
            local l = Line(n)
            l:ClearAllPoints(); l:SetPoint("TOPLEFT", 1, y); l:SetPoint("TOPRIGHT", -INSET, y)
            PaintMember(l, a, member, m == 1, i)
            l:Show()
            y = y - ROW_H
        end
        if (a.comment or "") ~= "" then
            n = n + 1
            local l = Line(n)
            l:ClearAllPoints(); l:SetPoint("TOPLEFT", 1, y); l:SetPoint("TOPRIGHT", -INSET, y)
            PaintNote(l, a)
            l:Show()
            y = y - NOTE_H
        end
    end
    for i = n + 1, #lines do lines[i]:Hide() end
    -- Our own scroll cue over Blizzard's scroll bar: a thumb for the part in view.
    local h = track:GetHeight()
    local total, first = math.max(1, #apps), offset
    local inView = 0
    for _, l in ipairs(lines) do if l:IsShown() and l.member and l.member == (l.app and l.app.members[1]) then inView = inView + 1 end end
    thumb:SetShown(inView < #apps)
    thumb:SetHeight(math.max(12, h * inView / total))
    thumb:SetPoint("TOP", 0, -(h - thumb:GetHeight()) * (total > inView and first / (total - inView) or 0))
end

-- ---------------------------------------------------------------------------
-- Build and wiring
-- ---------------------------------------------------------------------------
local function Build()
    Kit.ApplyFontFace()
    pane = CreateFrame("Frame", nil, viewer)
    -- One panel from the column headers' left edge across Blizzard's scroll bar,
    -- up to the top of its refresh button (our own refresh sits in that corner).
    local top = viewer.NameColumnHeader or viewer.ScrollBox
    local corner = viewer.RefreshButton or viewer.ScrollBar or viewer.ScrollBox
    pane:SetPoint("LEFT", top, "LEFT")
    pane:SetPoint("TOP", corner, "TOP")
    pane:SetPoint("RIGHT", viewer.ScrollBar or corner, "RIGHT")
    pane:SetPoint("BOTTOM", viewer.ScrollBox, "BOTTOM")
    pane:SetFrameLevel(viewer.ScrollBox:GetFrameLevel() + 20)
    pane:EnableMouse(true)
    pane:EnableMouseWheel(true)
    pane:SetScript("OnMouseWheel", function(_, d) offset = math.max(0, offset - d); Leader.Render() end)
    Kit.Fill(pane, { 0.031, 0.031, 0.031, 1 })
    Kit.Border(pane)
    needText = Text(pane)
    needText:SetPoint("TOPLEFT", PAD + 2, -8)
    needText:SetPoint("RIGHT", -90, 0)
    needText:SetTextColor(0.74, 0.74, 0.74)
    -- Refresh (the game's own applicant refresh), drawn in our style.
    local refresh = CreateFrame("Button", nil, pane)
    refresh:SetSize(18, 18)
    refresh:SetPoint("TOPRIGHT", -PAD, -4)
    local icon = refresh:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    icon:SetDesaturated(true)
    local rest = Kit.Palette.glyphRest
    icon:SetVertexColor(rest[1], rest[2], rest[3])
    refresh:SetScript("OnClick", function() C_LFGList.RefreshApplicants() end)
    refresh:SetScript("OnEnter", function(self)
        icon:SetVertexColor(MINT[1], MINT[2], MINT[3])
        if not ns.Hints() then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(REFRESH or "Refresh"); GameTooltip:Show()
    end)
    refresh:SetScript("OnLeave", function() icon:SetVertexColor(rest[1], rest[2], rest[3]); GameTooltip:Hide() end)
    countText = Text(pane, "RIGHT")
    countText:SetPoint("RIGHT", refresh, "LEFT", -6, 0)
    countText:SetTextColor(GREY[1], GREY[2], GREY[3])
    -- Column headers, aligned with the row columns (right to left).
    local head = CreateFrame("Frame", nil, pane)
    head:SetPoint("TOPLEFT", 0, -BAR_H)
    head:SetPoint("TOPRIGHT", -INSET, -BAR_H)
    head:SetHeight(HEAD_H)
    local x = -(PAD + W_X + 2 + W_INV + GAP)
    local function H(text, w, justify)
        local fs = Text(head, justify)
        fs:SetWidth(w)
        fs:SetPoint("RIGHT", x, 0)
        fs:SetText(text)
        fs:SetTextColor(GREY[1], GREY[2], GREY[3])
        x = x - w - GAP
        return fs
    end
    H("Adds", W_ADDS)
    keyHead = H("Key", W_KEY, "RIGHT")
    H("Score", W_SCORE, "RIGHT")
    H("iLvl", W_ILVL, "RIGHT")
    local name = Text(head)
    name:SetPoint("LEFT", PAD, 0)
    name:SetText("Name")
    name:SetTextColor(GREY[1], GREY[2], GREY[3])
    -- Our scroll track, in the column over Blizzard's scroll bar (which scrolls
    -- Blizzard's list, not ours).
    track = CreateFrame("Frame", nil, pane)
    track:SetPoint("TOPRIGHT", -3, -(BAR_H + HEAD_H))
    track:SetPoint("BOTTOMRIGHT", -3, 3)
    track:SetWidth(4)
    thumb = track:CreateTexture(nil, "ARTWORK")
    thumb:SetWidth(4)
    thumb:SetColorTexture(0.4, 0.4, 0.4, 1)
    thumb:SetPoint("TOP")
    pane:SetScript("OnShow", function() offset = 0; Leader.Render() end)
    pane:Hide()
end

function Leader.Update()
    if not viewer then return end
    if not pane then Build() end
    pane:SetShown(Eligible())
    Leader.Render()
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder", function()
    viewer = LFGListFrame and LFGListFrame.ApplicationViewer
    if not (viewer and viewer.ScrollBox) then return ns.Trace("leader", "no applicant viewer") end
    viewer:HookScript("OnShow", Leader.Update)
    viewer:HookScript("OnHide", Leader.Update)
end)

for _, e in ipairs({ "LFG_LIST_APPLICANT_LIST_UPDATED", "LFG_LIST_APPLICANT_UPDATED", "LFG_LIST_ACTIVE_ENTRY_UPDATE",
                     "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED" }) do
    ns.On(e, function() Leader.Update() end)
end
