--[[
    PickupGroup - UI/Leader.lua
    The leader view: our own frame laid over Blizzard's applicant list while
    the player leads a Mythic Keystone or raid listing. Blizzard's frames are
    never hidden, moved or written.

      top bar   what the group still needs (seats, Bloodlust, battle rez) . applicant count
      target    raids only: target comp T / H / D (presets 10 / 20 / 25 / 30 or typed), per character
      headers   keys:  Name | iLvl | Score | <dungeon code> (best run there) | adds | Invite / Decline
                raids: Name | iLvl | Prog (Raider.IO, this raid) | adds | Invite / Decline
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
local PRESETS = { { 10, 2, 2, 6 }, { 20, 2, 4, 14 }, { 25, 2, 5, 18 }, { 30, 2, 6, 22 } }
local ROLES = { "TANK", "HEALER", "DAMAGER" }
-- Raid buffs / utility by class (checked in game each season). Lust and battle
-- rez come from Filters.LUST / BREZ; a raid wants BREZ_WANT battle rezzers.
local BUFF = { MAGE = "Int", PRIEST = "Stam", WARRIOR = "AP", DRUID = "Vers", SHAMAN = "Skyfury",
               EVOKER = "Bronze", DEMONHUNTER = "Brand", MONK = "Touch", HUNTER = "Mark" }
local BUFF_NAME = { Int = "Arcane Intellect", Stam = "Power Word: Fortitude", AP = "Battle Shout",
                    Vers = "Mark of the Wild", Skyfury = "Skyfury", Bronze = "Blessing of the Bronze",
                    Brand = "Chaos Brand", Touch = "Mystic Touch", Mark = "Hunter's Mark", Lust = "Bloodlust", Rez = "battle rez" }
local BREZ_WANT = 2
local RIO_DIFF = { [1] = "N", [2] = "H", [3] = "M" }
local DIFF_NAME = { N = PLAYER_DIFFICULTY1, H = PLAYER_DIFFICULTY2, M = PLAYER_DIFFICULTY6 }
local STATUS = { invited = "Invited", inviteaccepted = "Joined", invitedeclined = "Passed", declined = "Declined",
                 declined_full = "Declined", declined_delisted = "Declined", cancelled = "Withdrew",
                 timedout = "Expired", failed = "Failed" }

local viewer, pane, needText, countText, keyHead, scoreHead, head, track, thumb, targetBar
local targetEdits, presetButtons = {}, {}
local progCache = {}
local lines = {}
local offset = 0

local function Text(parent, justify, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "PickupGroupFontSmall")
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    return fs
end

-- The listing being led, if it's a key or a raid: activity ID, its info, "keys" / "raid".
local function Listing()
    local e = C_LFGList.GetActiveEntryInfo()
    local act = e and (e.activityIDs and e.activityIDs[1] or e.activityID)
    local info = act and C_LFGList.GetActivityInfoTable(act)
    if not info then return end
    if info.isMythicPlusActivity then return act, info, "keys" end
    if (info.maxNumPlayers or 5) > 5 then return act, info, "raid" end
end

-- Raid target comp for this character: { tanks, healers, damage }.
local function Target()
    local c = ns.CharDB()
    c.raidTarget = c.raidTarget or { 2, 4, 14 }
    return c.raidTarget
end

-- Best Raider.IO progress in this raid, any difficulty: "6/8 H", or nil.
-- Raider.IO is optional: without it the column reads "-".
local function Progress(name, raid)
    local key = name .. "|" .. raid
    if progCache[key] ~= nil then return progCache[key] or nil end
    local p = RaiderIO and RaiderIO.GetProfile and RaiderIO.GetProfile(name)
    local best
    for _, g in ipairs(p and p.raidProfile and p.raidProfile.progress or {}) do
        if g.raid and (g.raid.name == raid or g.raid.shortName == raid) and (g.progressCount or 0) > 0
            and (not best or g.difficulty > best.difficulty) then best = g end
    end
    local list = p and p.raidProfile and p.raidProfile.progress
    if not best and list and list[1] and not progCache["?" .. raid] then
        progCache["?" .. raid] = true  -- once per raid: does Raider.IO name it as the listing does?
        local names = {}
        for _, g in ipairs(list) do names[#names + 1] = tostring(g.raid and g.raid.name) end
        ns.Trace("leader", "no Raider.IO match for", raid, "has:", table.concat(names, ", "))
    end
    local text = best and (best.progressCount .. "/" .. best.raid.bossCount .. " " .. (RIO_DIFF[best.difficulty] or "?"))
    progCache[key] = text or false
    return text
end

local function Eligible()
    if not (viewer and viewer:IsShown()) or ns.db.useBlizzard then return false end
    if IsInGroup() and not UnitIsGroupLeader("player") then return false end  -- only the leader acts
    return Listing() ~= nil
end

-- ---------------------------------------------------------------------------
-- Reading: applicants and what the group has
-- ---------------------------------------------------------------------------
local function Members(id, act, raid)
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
                         timed = best.finishedSuccess, keyMs = best.bestRunDurationMs,
                         prog = raid and Progress(name, raid) }
    end
    return a
end

-- Who's in the group: role counts, class counts, size (a raid read off its roster).
local function Roster()
    if not IsInRaid() then
        local need = Groups.Need()
        local classes = {}
        for file in pairs(need.classes) do classes[file] = 1 end
        return { TANK = need.TANK, HEALER = need.HEALER, DAMAGER = need.DAMAGER, classes = classes, size = need.size }
    end
    local r = { TANK = 0, HEALER = 0, DAMAGER = 0, classes = {}, size = 0 }
    for i = 1, GetNumGroupMembers() do
        local unit = "raid" .. i
        if UnitExists(unit) then
            r.size = r.size + 1
            local file = select(2, UnitClass(unit)) or "?"
            r.classes[file] = (r.classes[file] or 0) + 1
            local role = UnitGroupRolesAssigned(unit)
            if r[role] then r[role] = r[role] + 1 end
        end
    end
    return r
end

-- Seats left by role and the classes the group has, counting invited
-- applicants as seated. Seats come from SEATS (keys) or the target comp (raids).
local function Group(apps, kind)
    local have = Roster()
    local t = kind == "raid" and Target()
    local left, classes, size = {}, have.classes, have.size
    for i, r in ipairs(ROLES) do left[r] = (t and t[i] or SEATS[r]) - have[r] end
    for _, a in ipairs(apps) do
        if a.applicationStatus == "invited" then
            for _, m in ipairs(a.members) do
                size = size + 1
                if left[m.role] then left[m.role] = left[m.role] - 1 end
                classes[m.class or "?"] = (classes[m.class or "?"] or 0) + 1
            end
        end
    end
    local count = function(set) local n = 0 for file, c in pairs(classes) do if set[file] then n = n + c end end return n end
    return left, count(ns.Filters.LUST) > 0, count(ns.Filters.BREZ), size, classes
end

-- The mint "fills a seat" edge waits until the group has this many (player):
-- with one or two seated, comp is wide open and the cue is just noise.
local RING_FROM = 3

-- Cues per member: fills (an open seat), adds (buffs, "Lust", "Rez"), why dimmed.
local function Cue(apps, kind)
    local left, lust, brez, size, classes = Group(apps, kind)
    local raid = kind == "raid"
    local wantRez = raid and BREZ_WANT or 1
    -- ponytail: raid edge from half the target comp; tune with play.
    local ringFrom = RING_FROM
    if raid then local t = Target(); ringFrom = math.ceil((t[1] + t[2] + t[3]) / 2) end
    local f = ns.Filters.Active(kind)
    for _, a in ipairs(apps) do
        local seats = CopyTable(left)
        for _, m in ipairs(a.members) do
            m.fills = (seats[m.role] or 0) > 0
            m.ring = m.fills and size >= ringFrom
            if m.fills then seats[m.role] = seats[m.role] - 1 end
            local adds = {}
            local buff = raid and BUFF[m.class or ""]
            if buff and not classes[m.class] then adds[#adds + 1] = buff end
            if not lust and ns.Filters.LUST[m.class or ""] then adds[#adds + 1] = "Lust" end
            if brez < wantRez and ns.Filters.BREZ[m.class or ""] then adds[#adds + 1] = "Rez" end
            m.addList = adds
            m.adds = table.concat(adds, " ")
            m.region = Groups.Region(m.name)
            m.why = (not m.fills and "no open " .. (_G[m.role] or "seat"):lower() .. " seat")
                or (f.regions and not f.regions[m.region] and ("realm region " .. m.region .. " is off in your filter"))
                or (ns.Cleanup.IsBlacklisted(m.name) and "on your blacklist") or nil
        end
    end
    return left, lust, brez, wantRez
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
    local _, info, kind = Listing()
    local where = info and info.fullName and Groups.BaseName(info.fullName) or "this dungeon"
    if kind == "raid" then
        if m.prog then
            local n, d = m.prog:match("^(%S+) (%a)$")
            GameTooltip:AddLine("Raider.IO: " .. n .. " " .. (DIFF_NAME[d] or d) .. " in " .. where, 1, 1, 1)
        else
            GameTooltip:AddLine(RaiderIO and ("No Raider.IO progress in " .. where) or "Raider.IO not loaded", GREY[1], GREY[2], GREY[3])
        end
    elseif m.keyLevel > 0 then
        local t = m.keyMs and ("  " .. ("%d:%02d"):format(m.keyMs / 60000, (m.keyMs / 1000) % 60)) or ""
        GameTooltip:AddLine("Best in " .. where .. ": +" .. m.keyLevel .. (m.timed and " timed" or " not timed") .. t,
            m.timed and 1 or AMBER[1], m.timed and 1 or AMBER[2], m.timed and 1 or AMBER[3])
    else
        GameTooltip:AddLine("No run in " .. where .. " this season", GREY[1], GREY[2], GREY[3])
    end
    GameTooltip:AddLine("Realm region: " .. (Groups.REGION_NAME and Groups.REGION_NAME[m.region] or m.region), 0.85, 0.85, 0.85)
    if #m.addList > 0 then
        local names = {}
        for i, a in ipairs(m.addList) do names[i] = BUFF_NAME[a] end
        GameTooltip:AddLine("Adds " .. table.concat(names, ", "), MINT[1], MINT[2], MINT[3])
    end
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
    l.new:SetSize(3, 3)
    l.new:SetPoint("LEFT", 3, 0)  -- clear of the 2px edge, clear of the icon
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

-- Raids drop the Score column: Prog and Adds take its room.
local W_PROG = 36
local function Columns(raid, adds, key, score)
    adds:SetWidth(raid and (W_ADDS + W_SCORE + W_KEY - W_PROG) or W_ADDS)
    key:SetWidth(raid and W_PROG or W_KEY)
    score:SetWidth(raid and 1 or W_SCORE)
end

local function PaintMember(l, a, m, first, index, raid)
    l.member, l.app = m, a
    Columns(raid, l.adds, l.key, l.score)
    l:SetHeight(ROW_H)
    l.stripe:SetColorTexture(1, 1, 1, (index % 2 == 0) and 0.05 or 0)
    l.note:Hide()
    for _, f in ipairs({ l.tile, l.name, l.ilvl, l.key, l.adds }) do f:Show() end
    l.new:SetShown(first and a.isNew == true)
    l.tile:ClearAllPoints()
    l.tile:SetPoint("LEFT", first and (PAD + 1) or (PAD + 13), 0)
    l.linkV:SetShown(not first); l.linkH:SetShown(not first)
    l.icon:SetTexture(m.icon)
    l.edge:SetShown(m.ring == true and a.applicationStatus == "applied")
    l.name:SetText((m.name or "?"):match("^[^%-]+") or "?")
    l.ilvl:SetText(("%.0f"):format(m.ilvl))
    l.score:SetText(m.score > 0 and m.score or "-")
    local sc = m.score > 0 and C_ChallengeMode.GetDungeonScoreRarityColor(m.score)
    if sc then l.score:SetTextColor(sc.r, sc.g, sc.b) else l.score:SetTextColor(GREY[1], GREY[2], GREY[3]) end
    l.score:SetShown(not raid)
    if raid then
        l.key:SetText(m.prog or "-")
        local kc = m.prog and { 1, 1, 1 } or GREY
        l.key:SetTextColor(kc[1], kc[2], kc[3])
    else
        -- Best run here: white when timed, amber when not (the tooltip says which).
        l.key:SetText(m.keyLevel > 0 and ("+" .. m.keyLevel) or "-")
        local kc = m.keyLevel == 0 and GREY or (m.timed and { 1, 1, 1 } or AMBER)
        l.key:SetTextColor(kc[1], kc[2], kc[3])
    end
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
    local act, info, kind = Listing()
    if not act then return end
    local raid = kind == "raid"
    local where = info.fullName and Groups.BaseName(info.fullName)
    local apps = {}
    for _, id in ipairs(C_LFGList.GetApplicants() or {}) do
        local ok, a = pcall(Members, id, act, raid and where)
        if ok and a then apps[#apps + 1] = a elseif not ok then ns.LogError(a) end
    end
    table.sort(apps, function(x, y) return (x.displayOrderID or 0) < (y.displayOrderID or 0) end)
    local left, lust, brez, wantRez = Cue(apps, kind)

    local needs = {}
    for _, r in ipairs(ROLES) do
        if left[r] > 0 then needs[#needs + 1] = (left[r] > 1 and (left[r] .. " ") or "") .. _G[r]:lower() end
    end
    if not lust then needs[#needs + 1] = "Bloodlust" end
    local rez = wantRez - brez
    if rez > 0 then needs[#needs + 1] = (rez > 1 and (rez .. " ") or "") .. "battle rez" end
    needText:SetText(#needs > 0 and ("Needs " .. table.concat(needs, ", ")) or "Group has everything")
    countText:SetText(#apps .. (#apps == 1 and " applicant" or " applicants"))
    keyHead:SetText(raid and "Prog" or (where and Groups.Code(where)) or "Key")
    scoreHead:SetShown(not raid)
    Columns(raid, head.adds, keyHead, scoreHead)

    -- Raids: the target comp bar sits under the top bar.
    local top = raid and 2 * BAR_H or BAR_H
    targetBar:SetShown(raid)
    if raid then Leader.PaintTarget() end
    head:SetPoint("TOPLEFT", 0, -top)
    head:SetPoint("TOPRIGHT", -INSET, -top)
    track:SetPoint("TOPRIGHT", -3, -(top + HEAD_H))

    -- Scroll stops once the last applicant is in view (no empty space below).
    local roomH, used, maxOffset = pane:GetHeight() - top - HEAD_H, 0, 0
    for i = #apps, 1, -1 do
        local a = apps[i]
        used = used + #a.members * ROW_H + ((a.comment or "") ~= "" and NOTE_H or 0)
        if used > roomH then maxOffset = i; break end
    end
    offset = math.min(offset, maxOffset)
    local y, n, room = -(top + HEAD_H), 0, roomH
    for i = offset + 1, #apps do
        local a = apps[i]
        local h = #a.members * ROW_H + ((a.comment or "") ~= "" and NOTE_H or 0)
        if -y - top - HEAD_H + h > room then break end
        for m, member in ipairs(a.members) do
            n = n + 1
            local l = Line(n)
            l:ClearAllPoints(); l:SetPoint("TOPLEFT", 1, y); l:SetPoint("TOPRIGHT", -INSET, y)
            PaintMember(l, a, member, m == 1, i, raid)
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

-- The target bar shows the saved comp; the matching preset reads mint.
function Leader.PaintTarget()
    local t = Target()
    for i, e in ipairs(targetEdits) do if not e:HasFocus() then e:SetText(t[i]) end end
    for i, b in ipairs(presetButtons) do
        local p = PRESETS[i]
        local on = t[1] == p[2] and t[2] == p[3] and t[3] == p[4]
        b:GetFontString():SetTextColor(on and MINT[1] or 0.85, on and MINT[2] or 0.85, on and MINT[3] or 0.85)
    end
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
    -- To the viewer's own right edge: a skinned refresh button's backdrop can be
    -- wider than the scroll bar and showed past ours (player screenshot).
    pane:SetPoint("RIGHT", viewer, "RIGHT")
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
    head = CreateFrame("Frame", nil, pane)
    head:SetHeight(HEAD_H)
    local prev  -- chained right to left, as the row columns are, so widths can change per kind
    local function H(text, w, justify)
        local fs = Text(head, justify)
        fs:SetWidth(w)
        if prev then fs:SetPoint("RIGHT", prev, "LEFT", -GAP, 0)
        else fs:SetPoint("RIGHT", -(PAD + W_X + 2 + W_INV + GAP), 0) end
        fs:SetText(text)
        fs:SetTextColor(GREY[1], GREY[2], GREY[3])
        prev = fs
        return fs
    end
    head.adds = H("Adds", W_ADDS)
    keyHead = H("Key", W_KEY, "RIGHT")
    scoreHead = H("Score", W_SCORE, "RIGHT")
    H("iLvl", W_ILVL, "RIGHT")
    local name = Text(head)
    name:SetPoint("LEFT", PAD, 0)
    name:SetText("Name")
    name:SetTextColor(GREY[1], GREY[2], GREY[3])
    -- Raids: target comp. T / H / D boxes (typed) and the presets 10 / 20 / 25 / 30.
    targetBar = CreateFrame("Frame", nil, pane)
    targetBar:SetPoint("TOPLEFT", 0, -BAR_H)
    targetBar:SetPoint("TOPRIGHT", -INSET, -BAR_H)
    targetBar:SetHeight(BAR_H)
    local label = Text(targetBar)
    label:SetPoint("LEFT", PAD + 2, 0)
    label:SetText("Target")
    label:SetTextColor(GREY[1], GREY[2], GREY[3])
    local anchor = label
    for i, r in ipairs(ROLES) do
        local l = Text(targetBar)
        l:SetPoint("LEFT", anchor, "RIGHT", i == 1 and 8 or 6, 0)
        l:SetText(_G[r]:sub(1, 1))
        l:SetTextColor(0.74, 0.74, 0.74)
        local e = Kit.Edit(targetBar, 26, function(text)
            local n = tonumber(text)
            if n and n >= 0 and n <= 40 then Target()[i] = n end
            ns.Trace("leader", "target", table.concat(Target(), "/"))
            Leader.Render()
        end, true)
        e:SetHeight(18)
        e:SetMaxLetters(2)
        e:SetPoint("LEFT", l, "RIGHT", 3, 0)
        e:HookScript("OnEnter", function(self)
            if not ns.Hints() then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Target " .. _G[r]:lower() .. " seats"); GameTooltip:Show()
        end)
        e:HookScript("OnLeave", function() GameTooltip:Hide() end)
        targetEdits[i] = e
        anchor = e
    end
    for i = #PRESETS, 1, -1 do
        local p = PRESETS[i]
        local b = CreateFrame("Button", nil, targetBar)
        b:SetSize(24, 18)
        Kit.Button(b)
        b:SetNormalFontObject("PickupGroupFontSmall")
        b:SetHighlightFontObject("PickupGroupFontSmall")
        b:SetText(p[1])
        b:SetPoint("RIGHT", presetButtons[i + 1] or targetBar, presetButtons[i + 1] and "LEFT" or "RIGHT", presetButtons[i + 1] and -2 or -PAD, 0)
        b:SetScript("OnClick", function()
            local t = Target()
            t[1], t[2], t[3] = p[2], p[3], p[4]
            ns.Trace("leader", "target", table.concat(t, "/"))
            Leader.Render()
        end)
        b:HookScript("OnEnter", function(self)
            if not ns.Hints() then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(p[1] .. " players: " .. p[2] .. " / " .. p[3] .. " / " .. p[4])
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", function() GameTooltip:Hide() end)
        presetButtons[i] = b
    end
    targetBar:Hide()

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

ns.On("LFG_LIST_ACTIVE_ENTRY_UPDATE", function() wipe(progCache) end)
for _, e in ipairs({ "LFG_LIST_APPLICANT_LIST_UPDATED", "LFG_LIST_APPLICANT_UPDATED", "LFG_LIST_ACTIVE_ENTRY_UPDATE",
                     "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED" }) do
    ns.On(e, function() Leader.Update() end)
end
