--[[
    PickupGroup - UI/Sidecar.lua
    The sidecar: a panel on the Group Finder's right edge for setting up a
    filter. Edits apply as they are made (no Save step). It covers
    Raider.IO's panel while open; that frame is never moved.

    Filter tab: the one filter of the kind in view
      keys  dungeons (this season), playstyle, room for my role, leader at
            least my score, leader timed my level, has Bloodlust, has battle
            rez, no other of my class, leader score floor, leader's realm
      raid  leader's realm, bosses that must be alive, My lockout (loot left for me)
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
local filterView, optionsView, notesView, view = nil, nil, nil, "filter"
local headTabs = {}
local open = {}  -- raid name -> heading unfolded (this session)

local function Changed()
    ns.Pane.Render()
    ns.Leader.Render()
end

local function Leading(f) return f ~= nil and f.kind:find("^lead_") ~= nil end

local function Label(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    fs:SetTextColor(0.55, 0.55, 0.55)
    fs:SetText(text)
    return fs
end

local Toggle = Kit.Toggle

-- A row of on/off toggles over a set in the filter (f[key]): all on by
-- default (f[key] = nil), else the set of codes still on.
local setButtons = {}
local function SetRow(box, y, label, key, codes, names, tip)
    local l = Label(box, label)
    l:SetPoint("TOPLEFT", 0, y)
    local cellW = (W - 2 * PAD - 3 * (#codes - 1)) / #codes
    for i, code in ipairs(codes) do
        local b = Toggle(box, names and names[code] or code, cellW, function(self)
            if not editing[key] then
                editing[key] = {}
                for _, c in ipairs(codes) do editing[key][c] = true end
            end
            editing[key][self.code] = not editing[key][self.code] or nil
            local all = true
            for _, c in ipairs(codes) do if not editing[key][c] then all = false end end
            if all then editing[key] = nil end
            Sidecar.Paint(); Changed()
        end)
        b.key, b.code = key, code
        b:SetPoint("TOPLEFT", (i - 1) * (cellW + 3), y - 16)
        Kit.Tip(b, function(self) return names and names[self.code] or ns.Groups.REGION_NAME[self.code] end, tip)
        setButtons[#setButtons + 1] = b
    end
    return y - 16 - 23
end

-- Leader's realm region: four toggles (Americas only).
local function RegionRow(box, y, label)
    if not ns.Groups.SUBREGIONS then return y end
    return SetRow(box, y, label or "Leader's realm", "regions", ns.Groups.REGIONS, nil,
        "Groups whose leader plays on a realm in this region.")
end

local function PaintRegions(f)
    for _, b in ipairs(setButtons) do b:Paint(not f[b.key] or f[b.key][b.code] == true) end
end

local function PaintKeys(f)
    -- Each dungeon shows the player's best timed key there this season.
    local best = {}
    for _, d in ipairs(Filters.Dungeons()) do best[d.name] = d.best end
    for _, b in ipairs(dungeonButtons) do
        local on = not f.dungeons or f.dungeons[b.dungeon] == true
        -- The key in white while the dungeon is on (grey with it when off);
        -- an em dash where there's no timed key.
        local key = "(" .. (best[b.dungeon] and ("+" .. best[b.dungeon]) or "\226\128\148") .. ")"
        b:SetText(b.code .. " " .. (on and ("|cffffffff" .. key .. "|r") or key))
        b:Paint(on)
    end
    for key, c in pairs(checks) do c:Set(f[key]) end
    scoreBox:SetText((f.minScore or 0) > 0 and tostring(f.minScore) or "")
    PaintRegions(f)
end

local function PaintRaid(f)
    PaintRegions(f)
    bossLabel:SetText("Raid box: show its groups. Boss box: only groups with that boss alive.")
    -- Pooled lines: a raid heading (fold, My lockout), then one checkbox
    -- per boss.
    local y, n = 0, 0
    local function Line()
        n = n + 1
        local l = bossLines[n]
        if not l then
            l = CreateFrame("Button", nil, bossBox)
            l:SetHeight(24)
            l:SetScript("OnClick", function(self)
                if self.raid then open[self.raid] = not open[self.raid]; PaintRaid(editing) end
            end)
            l.text = l:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
            l.text:SetPoint("LEFT")
            l.text:SetPoint("RIGHT", -84, 0)
            l.text:SetJustifyH("LEFT")
            l.text:SetWordWrap(false)
            l.check = Kit.Check(l, "", function(on)
                if l.headRaid then  -- a raid's heading: show its groups or not
                    editing.raidsOff = editing.raidsOff or {}
                    editing.raidsOff[l.headRaid] = not on or nil
                    open[l.headRaid] = on  -- hidden raids fold away
                    if not next(editing.raidsOff) then editing.raidsOff = nil end
                    Sidecar.Paint(); Changed()
                    return
                end
                local rules = editing.bosses or {}
                editing.bosses = rules
                rules[l.bossRaid] = rules[l.bossRaid] or {}
                rules[l.bossRaid][l.boss] = on or nil
                Sidecar.Paint(); Changed()
            end)
            l.check:SetPoint("LEFT")
            Kit.Tip(l.check, function() return l.headRaid or l.boss end, function()
                if l.headRaid then return "Ticked: show this raid's groups. Unticked: hide them." end
                return "Ticked: only groups with this boss still alive. Every ticked boss must be alive,"
                    .. " so a group that killed one on the way (or skipped past it) is hidden."
                    .. " Looking for loot you can still get? Use My lockout instead."
            end)
            l.labelColor = { l.check.label:GetTextColor() }
            -- Drawn lock after a boss's name: killed this week (My lockout on).
            l.lock = CreateFrame("Frame", nil, l)
            l.lock:SetSize(7, 9)
            l.lock:SetPoint("LEFT", l.check, "RIGHT", 0, 0)
            local function Bit(w, h, point, x, y)
                local t = l.lock:CreateTexture(nil, "ARTWORK")
                t:SetColorTexture(0.55, 0.55, 0.55, 1)
                t:SetSize(w, h)
                t:SetPoint(point, x, y)
            end
            Bit(7, 5, "BOTTOMLEFT", 0, 0)  -- body
            Bit(1, 3, "BOTTOMLEFT", 1, 5)  -- shackle sides and top
            Bit(1, 3, "BOTTOMLEFT", 5, 5)
            Bit(5, 1, "BOTTOMLEFT", 1, 8)
            -- Tree lines from the raid's checkbox down to each boss's (bosses only).
            l.trunk = l:CreateTexture(nil, "ARTWORK")
            l.trunk:SetColorTexture(0.3, 0.3, 0.3, 1)
            l.trunk:SetWidth(1)
            l.trunk:SetPoint("TOP", l, "TOPLEFT", 6, 6)  -- up to the heading's box (centre of its 12px box)
            l.branch = l:CreateTexture(nil, "ARTWORK")
            l.branch:SetColorTexture(0.3, 0.3, 0.3, 1)
            l.branch:SetSize(11, 1)
            l.branch:SetPoint("LEFT", 6, 0)
            -- My lockout: a live rule (Filters.Lockout), on or off per raid.
            l.want = Toggle(l, "My lockout", 80, function(self)
                editing.lockout = editing.lockout or {}
                editing.lockout[self.raid] = not editing.lockout[self.raid] or nil
                if not next(editing.lockout) then editing.lockout = nil end
                ns.Log.Emit("filter", { action = "my lockout", name = self.raid .. (editing.lockout
                    and editing.lockout[self.raid] and " on" or " off") })
                Sidecar.Paint(); Changed()
            end)
            l.want:SetHeight(18)
            l.want:SetPoint("RIGHT")
            Kit.Tip(l.want, "My lockout", "Hides only groups with nothing left you can loot this week"
                .. " (every boss you haven't killed is dead there, at that group's difficulty)."
                .. " Groups behind you still show, since they may use the skip, but sort below"
                .. " groups that match your kills. Bosses you've killed (at the highest difficulty selected) are dimmed with a lock."
                .. " It never ticks or unticks the boss boxes.")
            bossLines[n] = l
        end
        l:ClearAllPoints()
        l:SetPoint("TOPLEFT", 0, y)
        l:SetPoint("RIGHT")
        l:Show()
        y = y - 24
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
        local shown = not (editing.raidsOff and editing.raidsOff[raid.name])
        h.raid, h.headRaid = raid.name, raid.name
        h.check:SetLabel("")
        h.check:SetPoint("LEFT")
        h.trunk:Hide(); h.branch:Hide()
        h.check:Set(shown)
        h.check:Show()
        h.text:SetPoint("LEFT", 18, 0)
        h.text:Show()
        local lockOn = editing.lockout ~= nil and editing.lockout[raid.name] == true
        local mine = lockOn and select(2, Filters.ShownLockout(raid.name, editing.diffs))
        h.text:SetText((open[raid.name] and "- " or "+ ") .. raid.name
            .. ((not open[raid.name] and set > 0) and ("  (" .. set .. " alive)") or ""))
        local grey = shown and 0.7 or 0.4
        h.text:SetTextColor(grey, grey, grey)
        h.want.raid = raid.name
        h.want:Paint(lockOn)
        h.lock:Hide()
        h.want:Show()
        local list = open[raid.name] and raid.bosses or {}
        for i, boss in ipairs(list) do
            local l = Line()
            l.trunk:SetPoint("BOTTOM", l, i == #list and "LEFT" or "BOTTOMLEFT", 6, 0)
            l.trunk:Show(); l.branch:Show()
            l.raid, l.headRaid = nil, nil
            l.text:Hide()
            l.want:Hide()
            l.bossRaid, l.boss = raid.name, boss
            l.check:SetLabel(boss)
            l.check:SetPoint("LEFT", 18, 0)  -- under its raid's name, not its checkbox
            l.check:Set(rules and rules[boss])
            l.check:Show()
            local killed = mine and mine[boss]
            local c = killed and { 0.4, 0.4, 0.4 } or l.labelColor
            l.check.label:SetTextColor(c[1], c[2], c[3])
            l.lock:SetShown(killed == true)
        end
        y = y - 4
    end
    for i = n + 1, #bossLines do bossLines[i]:Hide() end
    if n == 0 then
        local l = Line()
        l.raid, l.headRaid = nil, nil
        l.check:Hide()
        l.lock:Hide()
        l.trunk:Hide(); l.branch:Hide()
        l.text:SetPoint("LEFT")
        l.text:Show()
        l.text:SetText("Bosses show here once raids are in the results.")
        l.text:SetTextColor(0.55, 0.55, 0.55)
        l.want:Hide()
    end
    bossBox:SetHeight(math.max(1, -y))
    bossBox.scroll:Clamp(bossBox.scroll:GetVerticalScroll())
end

local leadBox
local function PaintLead(f)
    local keys = f.kind == "lead_keys"
    leadBox.title:SetText(keys and "Leading a key" or "Leading a raid")
    leadBox.floorLabel:SetText(keys and "Score at least" or "Item level at least")
    local n = keys and f.minScore or f.minIlvl
    leadBox.floor:SetText((n or 0) > 0 and tostring(n) or "")
    PaintRegions(f)
end

function Sidecar.Paint()
    if not (frame and editing) then return end
    keysBox:SetShown(editing.kind == "keys")
    raidBox:SetShown(editing.kind == "raid")
    leadBox:SetShown(Leading(editing))
    if editing.kind == "keys" then PaintKeys(editing)
    elseif editing.kind == "raid" then PaintRaid(editing)
    else PaintLead(editing) end
end

-- Leading: applicants who miss these are dimmed, with the reason on hover.
local function BuildLead(parent)
    local box = CreateFrame("Frame", nil, parent)
    box.title = box:CreateFontString(nil, "OVERLAY", "PickupGroupFont")
    box.title:SetPoint("TOPLEFT")
    local y = RegionRow(box, -24, "Applicant's realm")
    box.floorLabel = Label(box, "")
    box.floorLabel:SetTextColor(1, 1, 1)
    box.floorLabel:SetPoint("TOPLEFT", 0, y - 12)
    box.floor = Kit.Edit(box, 56, function(text)
        local n = tonumber(text)
        local key = editing.kind == "lead_keys" and "minScore" or "minIlvl"
        editing[key] = (n and n > 0) and n or nil
        Changed()
    end, true)
    Kit.Hint(box.floor, "Any")
    box.floor:SetPoint("TOPRIGHT", 0, y - 8)
    local note = Label(box, "Applicants who don't match are dimmed, with the reason on hover. Nobody is hidden.")
    note:SetPoint("TOPLEFT", 0, y - 44)
    note:SetPoint("RIGHT")
    note:SetJustifyH("LEFT")
    note:SetWordWrap(true)
    box:SetHeight(-y + 80)
    return box
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
        b:SetHitRectInsets(-4, -4, -6, -6)  -- 24px tall to click (WCAG 2.5.8)
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
        b.dungeon, b.code = d.name, d.code
        b:SetPoint("TOPLEFT", ((i - 1) % 4) * (cellW + 3), y - math.floor((i - 1) / 4) * 24)
        b:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(self.dungeon)
            local best = self:GetText():match("%+(%d+)")  -- colour codes have no "+"
            GameTooltip:AddLine(best and ("Your best timed key this season: +" .. best) or "No timed key here this season.", 0.74, 0.74, 0.74)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", function() GameTooltip:Hide() end)
        dungeonButtons[#dungeonButtons + 1] = b
    end
    y = y - math.ceil(#dungeonButtons / 4) * 24 - 8
    y = SetRow(box, y, "Playstyle", "styles", Filters.STYLES, Filters.STYLE_NAME,
        "Groups listed with this playstyle.") - 8

    for _, c in ipairs({
        { "room", "Room for my role" }, { "atLeastMine", "Leader at least my score" },
        { "leaderMyLevel", "Leader timed it at my level", "Keeps groups whose leader has timed this dungeon "
            .. "at your best timed key there (the number on its button above) or higher. "
            .. "Dungeons you haven't timed a key in aren't judged." },
        { "lust", "Group has Bloodlust", "Keeps groups that have it, or will: you or your party bring it, "
            .. "or a seat is still open after you join that a Bloodlust class can take (healer or damage)." },
        { "brez", "Group has battle rez", "Keeps groups that have it, or will: you or your party bring it, "
            .. "or a seat is still open after you join that a battle rez class can take." },
        { "noMyClass", "No other " .. (UnitClass("player") or "of my class") .. " in the group" },
    }) do
        local key = c[1]
        local cb = Kit.Check(box, c[2], function(on) editing[key] = on or nil; Changed() end)
        cb:SetPoint("TOPLEFT", 0, y)
        if c[3] then Kit.Tip(cb, c[2], c[3]) end
        checks[key] = cb
        y = y - 24
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
    local y = SetRow(box, 0, "Difficulty", "diffs", { "N", "H", "M" },
        { N = "Normal", H = "Heroic", M = "Mythic" }, "Groups at this difficulty.")
    y = RegionRow(box, y - 8)
    bossLabel:SetPoint("TOPLEFT", 0, y - 8)
    bossLabel:SetWidth(W - 2 * PAD)
    bossLabel:SetJustifyH("LEFT")
    bossLabel:SetWordWrap(true)
    -- The boss list scrolls (wheel) inside the space down to Reset; a
    -- pulsing chevron says there's more below.
    local scroll = CreateFrame("ScrollFrame", nil, box)
    scroll:SetPoint("TOPLEFT", bossLabel, "BOTTOMLEFT", 0, -6)
    scroll:SetPoint("BOTTOMRIGHT")
    bossBox = CreateFrame("Frame", nil, scroll)
    bossBox:SetSize(W - 2 * PAD, 1)
    scroll:SetScrollChild(bossBox)
    scroll.more = Kit.More(scroll)
    function scroll:Clamp(to)
        local most = math.max(0, bossBox:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.min(math.max(0, to), most))
        self.more:Set(self:GetVerticalScroll() < most - 1)
    end
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta) self:Clamp(self:GetVerticalScroll() - delta * 48) end)
    bossBox.scroll = scroll
    return box
end

-- Options: the switch to Blizzard's list and the clean-up rules.
-- Notes: up to Notes.MAX sign-up notes, offered to copy under Blizzard's
-- sign-up dialog (the game won't let an addon fill its note box).
local noteBoxes = {}
local function BuildNotes(parent)
    local box = CreateFrame("Frame", nil, parent)
    local intro = Label(box, "Shift-click Apply to sign up with a note: these are offered to copy under Blizzard's sign-up window. A plain click signs up at once, no note.")
    intro:SetPoint("TOPLEFT")
    intro:SetPoint("RIGHT")
    intro:SetJustifyH("LEFT")
    intro:SetWordWrap(true)
    box.why = Label(box, "")
    box.why:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -6)
    box.why:SetPoint("RIGHT")
    box.why:SetJustifyH("LEFT")
    box.why:SetWordWrap(true)
    box.why:SetTextColor(1, 0.72, 0.3)
    local prev = box.why
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
    local why = ns.Notes.Conflict()
    if notesView then
        notesView.why:SetText(why and ("Not shown under Blizzard's window: " .. why .. ". Turn it off in EllesmereUI's options (Quality of Life or Group Finder) to use these.") or "")
    end
    local list = ns.Notes.All()
    for i, e in ipairs(noteBoxes) do e:SetText(list[i] or "") end
end

local function BuildOptions(parent)
    local box = CreateFrame("Frame", nil, parent)
    local c = ns.db.cleanup
    -- { key, label, tooltip?, get(), set(on) }; every change is logged.
    local y = 0
    box.switches = {}
    for _, o in ipairs({
        { "raidFurthest", "Sorting: Raid, furthest along first", "Raid groups with the most bosses down sort to the top (after friends, guild and My lockout). Off: fewest down first.",
          function() return ns.db.raidFurthest end, function(on) ns.db.raidFurthest = on or nil; ns.Pane.Render() end },
        -- Opt-out: on for everyone until turned off.
        { "noChime", "Alert: Dungeon, chime when group fills", "Plays a short tone when a dungeon group you joined through a sign-up reaches five.",
          function() return not ns.db.noChime end, function(on) ns.db.noChime = (not on) or nil end },
        { "noShimmer", "Alert: Shimmer on new groups", "With fewer than 20 groups listed, a group new to your list gets one quick shimmer across its row. Its name stays mint either way.",
          function() return not ns.db.noShimmer end, function(on) ns.db.noShimmer = (not on) or nil end },
        "-",  -- a rule between the sorting / alert pair and the rest
        { "useBlizzard", "Use Blizzard's group list instead", "A PickupGroup button on Blizzard's panel brings this back.",
          function() return ns.db.useBlizzard end,
          function(on) ns.db.useBlizzard = on; if on then ns.Filters.RestoreBlizzard() end; ns.Pane.Update() end },
        { "nameColors", "Color names for friends / guild", "Like Blizzard's list: group names turn blue with a friend in, green with a guildmate (blue wins when both). Replaces the marks.",
          function() return ns.db.nameColors end, function(on) ns.db.nameColors = on or nil; ns.Pane.Render() end },
        { "hideDecliners", "Hide groups that declined me", "Once a leader turns down your sign-up, their groups are hidden (under the hidden count) until you /reload. Full or delisted groups don't count.",
          function() return ns.db.hideDecliners end, function(on) ns.db.hideDecliners = on or nil; ns.Pane.Render() end },
        { "swap", "Swap when all sign-ups are out", "With all five sign-ups in use, a group's button reads Swap: click it to withdraw your oldest sign-up, then Apply.",
          function() return ns.db.swap end, function(on) ns.db.swap = on or nil; ns.Pane.Render() end },
        -- Opt-in (player): veterans can turn off the how-to tooltips.
        { "noHints", "Hide hint tooltips", nil, function() return ns.db.noHints end, function(on) ns.db.noHints = on or nil end },
        -- Off for players whose other addons handle sign-up notes (they clash).
        { "noteStrip", "My notes under Blizzard's sign-up window", nil,
          ns.Notes.StripOn, function(on) ns.db.noteStrip = (not on) and false or nil end },
    }) do
      if o == "-" then
        local rule = box:CreateTexture(nil, "ARTWORK")
        rule:SetColorTexture(0.25, 0.25, 0.25, 1)
        rule:SetHeight(1)
        rule:SetPoint("TOPLEFT", 0, y - 4)
        rule:SetPoint("RIGHT")
        y = y - 12
      else
        local cb = Kit.Check(box, o[2], function(on)
            o[5](on)
            ns.Log.Emit("setting", { key = o[1], on = on })
        end)
        cb:SetPoint("TOPLEFT", 0, y)
        if o[3] then Kit.Tip(cb, o[2], o[3]) end
        cb.get = o[4]
        box.switches[#box.switches + 1] = cb
        y = y - 24
      end
    end
    y = y + 6
    box.stripWhy = Label(box, "")
    box.stripWhy:SetPoint("TOPLEFT", 18, y)
    box.stripWhy:SetTextColor(1, 0.72, 0.3)
    y = y - 22

    -- Clean-up: one switch for all its rules; what it hides is in the tooltip.
    box.cleanup = Kit.Check(box, "Clean up the list", function(on)
        for _, key in ipairs({ "stale", "advert", "carry", "blacklist" }) do c[key] = on end
        ns.Log.Emit("setting", { key = "cleanup", on = on })
        ns.Pane.Render()
    end)
    box.cleanup:SetPoint("TOPLEFT", 0, y)
    Kit.Tip(box.cleanup, "Clean up the list", "Hides listings that are listed longer than "
        .. (c.staleHours or 3) .. " hours, look like adverts (no leader score and the voice chat field"
        .. " filled in), offer a carry, or are led by a blacklisted player."
        .. " Right-click a row to report, blacklist or hide its leader.")
    y = y - 30

    box.count = Label(box, "")
    box.count:SetPoint("TOPLEFT", 0, y - 4)
    local clear = CreateFrame("Button", nil, box)
    clear:SetSize(60, 20)
    clear:SetPoint("TOPRIGHT", 0, y)
    Kit.Button(clear)
    clear:SetNormalFontObject("PickupGroupFontSmall")
    Kit.Confirm(clear, "Clear", function() ns.Cleanup.Clear(); Sidecar.Show("options"); ns.Pane.Render() end)
    y = y - 30
    local history = CreateFrame("Button", nil, box)
    history:SetSize(W - 2 * PAD, 22)
    history:SetPoint("TOPLEFT", 0, y)
    Kit.Button(history)
    history:SetText("Sign-up history")
    history:SetScript("OnClick", function() ns.History.Toggle() end)
    box:Hide()
    return box
end

local function PaintOptions()
    local o, c = optionsView, ns.db.cleanup
    for _, cb in ipairs(o.switches) do cb:Set(cb.get()) end
    local why = ns.Notes.Conflict()
    o.stripWhy:SetText(why and ("Off: " .. why .. ".") or "")
    Sidecar.CheckConflict()
    o.cleanup:Set(c.stale or c.advert or c.carry or c.blacklist)
    local n = ns.Cleanup.Count()
    o.count:SetText(("Blacklist: %d leader%s"):format(n, n == 1 and "" or "s"))
end

local function Build()
    Kit.ApplyFontFace()
    frame = CreateFrame("Frame", "PickupGroupSidecar", PVEFrame)
    frame:SetWidth(W)
    frame:SetPoint("TOPLEFT", PVEFrame, "TOPRIGHT", 1, 0)
    frame:SetPoint("BOTTOMLEFT", PVEFrame, "BOTTOMRIGHT", 1, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    Kit.Fill(frame, { 0.06, 0.06, 0.06, 1 })
    Kit.Border(frame)

    -- Header tabs: Filter (the filter being edited), Notes and Options.
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
    raidBox:SetPoint("BOTTOMRIGHT", 0, 30)  -- down to just above Reset
    leadBox = BuildLead(body)
    leadBox:SetPoint("TOPLEFT")
    leadBox:SetPoint("RIGHT")

    -- Reset: the filter back to its starting rules; a second
    -- click confirms.
    local resetBtn = CreateFrame("Button", nil, body)
    resetBtn:SetSize(72, 22)
    resetBtn:SetPoint("BOTTOMLEFT")
    Kit.Button(resetBtn)
    Kit.Confirm(resetBtn, "Reset", function() Filters.Reset(editing); Sidecar.Paint(); Changed() end)
    -- Name and version, bottom right on every tab (level with Reset), as
    -- StockClerk's header shows them; amber for alpha/beta.
    local version = ns.Version()
    local versionLabel = frame:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    versionLabel:SetPoint("RIGHT", frame, "BOTTOMRIGHT", -PAD, PAD + 11)
    versionLabel:SetText(((version:match("%-alpha") or version:match("%-beta") or version:match("^dev")) and "|cffffb84d" or "|cff8c8c8c") .. version .. "|r")
    local nameLabel = frame:CreateFontString(nil, "OVERLAY", "PickupGroupFont")
    nameLabel:SetPoint("RIGHT", versionLabel, "LEFT", -6, 1)
    nameLabel:SetText("|cff98FF98Pickup|rGroup")
    -- Raider.IO's profile panel (when loaded) moves over to the sidecar's
    -- right edge while it's open, and back when it closes.
    frame:HookScript("OnShow", Sidecar.MoveRaiderIO)
    frame:HookScript("OnHide", Sidecar.MoveRaiderIO)
    frame:Hide()
end

-- Raider.IO places its profile panel by anchoring a small frame to the
-- Group Finder's right edge (and re-places it whenever it updates). While
-- one of our docked panels is open (the sidecar, or the quick list beside
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

-- Switch the sidecar between its Filter, Notes and Options views.
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
    RequestRaidInfo()  -- lockouts for My lockout
    frame:Show()
    Sidecar.Show(which)
end

-- New results can bring raids the boss list hasn't shown yet.
function Sidecar.RefreshBosses()
    if frame and frame:IsShown() and editing and editing.kind == "raid" then PaintRaid(editing) end
end

ns.On("UPDATE_INSTANCE_INFO", function() Sidecar.RefreshBosses() end)  -- lockouts arrived

-- Close the sidecar if it's on a filter of that side (leading or searching):
-- the pane and the leader view each close only their own.
function Sidecar.Close(leading)
    if frame and frame:IsShown() and Leading(editing) == leading then frame:Hide() end
end

-- ---------------------------------------------------------------------------
-- Clash alerts: another addon doing the same job on the same Blizzard frame.
-- Said once, in a window you can't miss, each time a clash starts (login, or
-- the other addon's option switched on mid-session).
-- ---------------------------------------------------------------------------
local alert
local function Alert(title, body)
    if not alert then
        Kit.ApplyFontFace()
        alert = CreateFrame("Frame", "PickupGroupConflictAlert", UIParent)
        alert:SetWidth(360)
        alert:SetPoint("TOP", 0, -180)
        alert:SetFrameStrata("DIALOG")
        alert:SetToplevel(true)
        alert:EnableMouse(true)
        alert:SetClampedToScreen(true)
        tinsert(UISpecialFrames, "PickupGroupConflictAlert")  -- Escape closes it
        Kit.Fill(alert, Kit.Palette.panelBg)
        Kit.Border(alert, { 1, 0.72, 0.3, 1 })
        alert.title = alert:CreateFontString(nil, "OVERLAY", "PickupGroupFontLarge")
        alert.title:SetPoint("TOPLEFT", 14, -12)
        alert.title:SetTextColor(1, 0.72, 0.3)
        alert.body = alert:CreateFontString(nil, "OVERLAY", "PickupGroupFont")
        alert.body:SetPoint("TOPLEFT", alert.title, "BOTTOMLEFT", 0, -10)
        alert.body:SetWidth(332)
        alert.body:SetJustifyH("LEFT")
        alert.body:SetWordWrap(true)
        local ok = CreateFrame("Button", nil, alert)
        ok:SetSize(90, 24)
        ok:SetPoint("BOTTOMRIGHT", -12, 12)
        Kit.Button(ok)
        ok:SetText("Got it")
        ok:SetScript("OnClick", function() alert:Hide() end)
    end
    alert.title:SetText(title)
    alert.body:SetText(body)
    alert.body:SetTextColor(0.85, 0.85, 0.85)
    alert:SetHeight(12 + alert.title:GetStringHeight() + 10 + alert.body:GetStringHeight() + 16 + 24 + 12)
    alert:Show()
end

-- The clashes: why (a sentence, or nil), the db key that remembers it, the
-- log line, and the alert's title and text.
local CLASHES = {
    { function() return ns.Notes.Conflict() end, "noteConflict", "notes under Blizzard's window", "PickupGroup: sign-up notes are off",
      ". It and PickupGroup both put a note helper on Blizzard's sign-up window, "
      .. "so PickupGroup's notes are off while it's on.\n\n"
      .. "|cffffffffTo use PickupGroup's notes:|r in EllesmereUI's options (Quality of Life or Group Finder), "
      .. "turn off Persistent Signup Note. PickupGroup's notes come back by themselves.\n\n"
      .. "|cffffffffTo keep EllesmereUI's:|r nothing to do. Shift-click Apply still opens the sign-up window." },
    -- Already on Blizzard's list: nothing overlaps, nothing to say.
    { function() return not ns.db.useBlizzard and ns.FinderClash() or nil end, "finderConflict", "group finder overlap", "PickupGroup: two group finders",
      ". PickupGroup's list covers its filter row, and while the list shows, PickupGroup's filter sets "
      .. "Blizzard's dungeons, role, score, class and playstyle (EllesmereUI's picks there are replaced). "
      .. "Its difficulty menu beside the search box still narrows every search.\n\n"
      .. "|cffffffffTo use PickupGroup:|r turn off Group Finder in EllesmereUI's options.\n\n"
      .. "|cffffffffTo use EllesmereUI's:|r PickupGroup Options > Use Blizzard's group list instead." },
    { function() return ns.QuickList and ns.QuickList.Clash() end, "quickConflict", "quick list", "PickupGroup: quick list is off",
      ". It and PickupGroup both put quick-list buttons beside Blizzard's listing form, so PickupGroup's quick list is off while it's on.\n\n"
      .. "|cffffffffTo use PickupGroup's:|r turn off LFG Quick Create in atrocityEssentials' options. PickupGroup's comes back by itself.\n\n"
      .. "|cffffffffTo keep atrocityEssentials':|r nothing to do." },
}

-- atLoad (login / reload): every clash still on is said again. Otherwise
-- only one that just started (an option switched on mid-session). Several
-- at once share one window.
function Sidecar.CheckConflict(atLoad)
    local parts = {}
    for _, c in ipairs(CLASHES) do
        local why, key, logKey = c[1](), c[2], c[3]
        if why and (atLoad or ns.db[key] ~= why) then
            if ns.db[key] ~= why then ns.Log.Emit("setting", { key = logKey .. " (" .. why .. ")", on = false }) end
            ns.db[key] = why
            parts[#parts + 1] = c
            c.why = why
        elseif not why and ns.db[key] then
            ns.db[key] = nil
            ns.Log.Emit("setting", { key = logKey .. " (clash gone)", on = true })
        end
    end
    if #parts == 1 then return Alert(parts[1][4], parts[1].why .. parts[1][5]) end
    if #parts == 0 then return end
    -- Several: one window, each under its own heading.
    local text = {}
    for i, c in ipairs(parts) do
        text[i] = "|cffffb84d" .. c[4]:gsub("^PickupGroup: ", "") .. "|r\n" .. c.why .. c[5]
    end
    Alert("PickupGroup: addon clashes", table.concat(text, "\n\n"))
end
-- Mid-session: another addon's option switched on (or off) without a reload.
-- Checked every 2 s (a few table reads); a change re-runs the check, which
-- alerts on a new clash, and the quick list steps aside or comes back.
ns.On("PLAYER_LOGIN", function()
    local last
    C_Timer.NewTicker(2, function()
        -- (Each returns nothing when there's no clash, so "or".)
        local now = (ns.Notes.Conflict() or "") .. "|" .. (ns.FinderClash() or "") .. "|" .. (ns.QuickList.Clash() or "")
        if now == last then return end
        local first = last == nil
        last = now
        if not first then Sidecar.CheckConflict(); ns.QuickList.Update() end
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

-- Keep an open sidecar on the category's filter; with `open`, open it too.
function Sidecar.Follow(f, open)
    if frame and frame:IsShown() then editing = f; Sidecar.Paint()
    elseif open then Sidecar.Open(f) end
end
