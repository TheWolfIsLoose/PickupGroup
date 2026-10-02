--[[
    PickupGroup - UI/Sidecar.lua
    The sidecar: a panel on the Group Finder's right edge for setting up a
    filter. Edits apply as they are made (no Save step). It covers
    Raider.IO's panel while open; that frame is never moved.

    Filter tab: the one filter of the kind in view
      keys  dungeons (this season), room for my role, leader at least my
            score, has Bloodlust, has battle rez, no other of my class,
            leader score floor, leader's realm
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
local filterView, optionsView, notesView, view = nil, nil, nil, "filter"
local headTabs = {}
local open = {}  -- raid name -> heading unfolded (this session)
local undo = {}  -- raid name -> boss rules before My lockout (false: none); a second click restores them

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
    -- every colour reads (no colour-on-green). Off: grey text, grey ring.
    function b:Paint(on, color)
        local c = on and (color or MINT) or { 0.6, 0.6, 0.6 }
        self:GetFontString():SetTextColor(c[1], c[2], c[3], 1)
        local ring = on and c or Kit.Palette.ringRest
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
            if not ns.Hints() then return end
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

local DIFF_WORD = { N = "Normal", H = "Heroic", M = "Mythic" }

local function PaintRaid(f)
    PaintRegions(f)
    bossLabel:SetText("Ticked bosses must be alive in the group")
    -- Pooled lines: a raid heading (fold, My lockout), then one checkbox
    -- per boss.
    local y, n = 0, 0
    local function Line()
        n = n + 1
        local l = bossLines[n]
        if not l then
            l = CreateFrame("Button", nil, bossBox)
            l:SetHeight(18)
            l:SetScript("OnClick", function(self)
                if self.raid then open[self.raid] = not open[self.raid]; PaintRaid(editing) end
            end)
            l.text = l:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
            l.text:SetPoint("LEFT")
            l.text:SetPoint("RIGHT", -84, 0)
            l.text:SetJustifyH("LEFT")
            l.text:SetWordWrap(false)
            l.check = Kit.Check(l, "", function(on)
                local rules = editing.bosses or {}
                editing.bosses = rules
                rules[l.bossRaid] = rules[l.bossRaid] or {}
                rules[l.bossRaid][l.boss] = on or nil
                undo[l.bossRaid] = nil  -- edited by hand: My lockout starts over
                Sidecar.Paint(); Changed()
            end)
            l.check:SetPoint("LEFT")
            -- My lockout toggles: on ticks the lockout, off puts back what was ticked before.
            l.want = Toggle(l, "", 80, function(self)
                local raid, text = self.raid, nil
                editing.bosses = editing.bosses or {}
                if undo[raid] ~= nil then
                    editing.bosses[raid] = undo[raid] or nil
                    undo[raid] = nil
                    text = "Your earlier boss picks are back."
                else
                    local d = ns.Pane.RaidDifficulty(raid)
                    if DIFF_WORD[d] then undo[raid] = CopyTable(editing.bosses[raid] or {}) end
                    text = Filters.MatchLockout(editing, raid, d)
                end
                open[raid] = true
                Sidecar.Paint(); Changed()
                GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(text, 1, 1, 1, 1, true); GameTooltip:Show()
            end)
            l.want:SetHeight(16)
            l.want:SetPoint("RIGHT")
            l.want:HookScript("OnEnter", function(self)
                if not ns.Hints() then return end
                local d = ns.Pane.RaidDifficulty(self.raid)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText("My lockout", 1, 1, 1)
                GameTooltip:AddLine("Ticks the bosses this character hasn't killed this week"
                    .. (DIFF_WORD[d] and (" on " .. DIFF_WORD[d] .. ", the difficulty you searched.")
                        or ". Search the raid with a difficulty first (Blizzard's raid + difficulty suggestion).")
                    .. " Click again to put your earlier picks back.",
                    0.8, 0.8, 0.8, true)
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
        h.check:Hide()
        h.text:Show()
        h.text:SetText((open[raid.name] and "- " or "+ ") .. raid.name
            .. ((not open[raid.name] and set > 0) and ("  (" .. set .. " alive)") or ""))
        h.text:SetTextColor(0.7, 0.7, 0.7)
        local d = ns.Pane.RaidDifficulty(raid.name)
        h.want.raid = raid.name
        h.want:SetText("My lockout" .. (d and (" (" .. d .. ")") or ""))
        h.want:Paint(undo[raid.name] ~= nil)
        h.want:Show()
        for _, boss in ipairs(open[raid.name] and raid.bosses or {}) do
            local l = Line()
            l.raid = nil
            l.text:Hide()
            l.want:Hide()
            l.bossRaid, l.boss = raid.name, boss
            l.check:SetLabel(boss)
            l.check:Set(rules and rules[boss])
            l.check:Show()
        end
        y = y - 4
    end
    for i = n + 1, #bossLines do bossLines[i]:Hide() end
    if n == 0 then
        local l = Line()
        l.raid = nil
        l.check:Hide()
        l.text:Show()
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
        b.dungeon, b.code = d.name, d.code
        b:SetPoint("TOPLEFT", ((i - 1) % 4) * (cellW + 3), y - math.floor((i - 1) / 4) * 23)
        b:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(self.dungeon)
            local best = self:GetText():match("%+(%d+)")  -- colour codes have no "+"
            GameTooltip:AddLine(best and ("Your best timed key this season: +" .. best) or "No timed key here this season.", 0.74, 0.74, 0.74)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", function() GameTooltip:Hide() end)
        dungeonButtons[#dungeonButtons + 1] = b
    end
    y = y - math.ceil(#dungeonButtons / 4) * 23 - 8

    for _, c in ipairs({
        { "room", "Room for my role" }, { "atLeastMine", "Leader at least my score" },
        { "lust", "Group has Bloodlust", "Keeps groups that have it, or will: you or your party bring it, "
            .. "or a seat is still open after you join that a Bloodlust class can take (healer or damage)." },
        { "brez", "Group has battle rez", "Keeps groups that have it, or will: you or your party bring it, "
            .. "or a seat is still open after you join that a battle rez class can take." },
        { "noMyClass", "No other " .. (UnitClass("player") or "of my class") .. " in the group" },
    }) do
        local key = c[1]
        local cb = Kit.Check(box, c[2], function(on) editing[key] = on or nil; Changed() end)
        cb:SetPoint("TOPLEFT", 0, y)
        if c[3] then
            cb:HookScript("OnEnter", function(self)
                if not ns.Hints() then return end
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(c[2])
                GameTooltip:AddLine(c[3], 0.74, 0.74, 0.74, true)
                GameTooltip:Show()
            end)
            cb:HookScript("OnLeave", function() GameTooltip:Hide() end)
        end
        checks[key] = cb
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
        notesView.why:SetText(why and ("Not shown under Blizzard's window: " .. why .. ". Turn it off in EllesmereUI (Quality of Life > Group Finder) to use these.") or "")
    end
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
        if not ns.Hints() then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Colour names for friends / guild")
        GameTooltip:AddLine("Like Blizzard's list: group names turn blue with a friend in, green with a guildmate (blue wins when both). Replaces the marks.", 0.74, 0.74, 0.74, true)
        GameTooltip:Show()
    end)
    names:HookScript("OnLeave", function() GameTooltip:Hide() end)
    box.names = names
    y = y - 22
    local swap = Kit.Check(box, "Swap when all sign-ups are out", function(on)
        ns.db.swap = on or nil
        ns.Log.Emit("setting", { key = "swap", on = on })
        ns.Pane.Render()
    end)
    swap:SetPoint("TOPLEFT", 0, y)
    swap:HookScript("OnEnter", function(self)
        if not ns.Hints() then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Swap when all sign-ups are out")
        GameTooltip:AddLine("With all five sign-ups in use, a group's button reads Swap: click it to withdraw your oldest sign-up, then Apply.", 0.74, 0.74, 0.74, true)
        GameTooltip:Show()
    end)
    swap:HookScript("OnLeave", function() GameTooltip:Hide() end)
    box.swap = swap
    y = y - 22
    -- Opt-in (player): veterans can turn off the how-to tooltips.
    local hints = Kit.Check(box, "Hide hint tooltips", function(on)
        ns.db.noHints = on or nil
        ns.Log.Emit("setting", { key = "noHints", on = on })
    end)
    hints:SetPoint("TOPLEFT", 0, y)
    box.hints = hints
    y = y - 22
    -- Off for players whose other addons handle sign-up notes (they clash).
    local strip = Kit.Check(box, "My notes under Blizzard's sign-up window", function(on)
        ns.db.noteStrip = (not on) and false or nil
        ns.Log.Emit("setting", { key = "noteStrip", on = on })
    end)
    strip:SetPoint("TOPLEFT", 0, y)
    box.strip = strip
    y = y - 18
    box.stripWhy = Label(box, "")
    box.stripWhy:SetPoint("TOPLEFT", 18, y)
    box.stripWhy:SetTextColor(1, 0.72, 0.3)
    y = y - 22

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
    y = y - 34
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
    o.blizz:Set(ns.db.useBlizzard)
    o.names:Set(ns.db.nameColors)
    o.swap:Set(ns.db.swap)
    o.hints:Set(ns.db.noHints)
    o.strip:Set(ns.Notes.StripOn())
    local why = ns.Notes.Conflict()
    o.stripWhy:SetText(why and ("Off: " .. why .. ".") or "")
    Sidecar.CheckConflict()
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
    frame:SetFrameStrata("DIALOG")
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
        wipe(undo)
        self.armed = nil
        self:SetText("Reset")
        Filters.Reset(editing)
        Sidecar.Paint(); Changed()
    end)
    -- Raider.IO's profile panel (when loaded) moves over to the sidecar's
    -- right edge while it's open, and back when it closes.
    frame:HookScript("OnShow", Sidecar.MoveRaiderIO)
    frame:HookScript("OnHide", Sidecar.MoveRaiderIO)
    frame:Hide()
end

-- Raider.IO places its profile panel by anchoring a small frame to the
-- Group Finder's right edge (and re-places it whenever it updates). While
-- the sidecar is open that anchor follows the sidecar instead; only an
-- anchor on the Group Finder is touched (a user-placed panel stays put).
local rioHooked, moving
local RIO_GAP = 2  -- a little air between the sidecar and Raider.IO's panel
function Sidecar.MoveRaiderIO()
    local a = _G.RaiderIO_ProfileTooltipAnchor
    if not (a and frame) then return end
    if not rioHooked then
        rioHooked = true
        hooksecurefunc(a, "SetPoint", function(_, _, rel) if not moving and rel == PVEFrame then Sidecar.MoveRaiderIO() end end)
    end
    local p, rel, rp, x, y = a:GetPoint()
    local to = (frame:IsShown() and rel == PVEFrame and frame) or (not frame:IsShown() and rel == frame and PVEFrame)
    if not to then return end
    moving = true
    a:ClearAllPoints()
    a:SetPoint(p, to, rp, x + (to == frame and RIO_GAP or -RIO_GAP), y)
    moving = false
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

-- ---------------------------------------------------------------------------
-- Clash alert: another addon's note tool on Blizzard's sign-up window turns
-- our notes off. Said once, in a window you can't miss, each time the clash
-- starts (login, or the other addon's option switched on mid-session).
-- ---------------------------------------------------------------------------
local alert
local function Alert(why)
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
        alert.title:SetText("PickupGroup: sign-up notes are off")
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
    alert.body:SetText(why .. ". It and PickupGroup both put a note helper on Blizzard's sign-up window, "
        .. "so PickupGroup's notes are off while it's on.\n\n"
        .. "|cffffffffTo use PickupGroup's notes:|r in EllesmereUI's options, Quality of Life > Group Finder, "
        .. "turn off Persistent Signup Note. PickupGroup's notes come back by themselves.\n\n"
        .. "|cffffffffTo keep EllesmereUI's:|r nothing to do. Shift-click Apply still opens the sign-up window.")
    alert.body:SetTextColor(0.85, 0.85, 0.85)
    alert:SetHeight(12 + alert.title:GetStringHeight() + 10 + alert.body:GetStringHeight() + 16 + 24 + 12)
    alert:Show()
end

function Sidecar.CheckConflict()
    local why = ns.Notes.Conflict()
    if why and ns.db.noteConflict ~= why then
        ns.db.noteConflict = why
        ns.Log.Emit("setting", { key = "notes under Blizzard's window (" .. why .. ")", on = false })
        Alert(why)
    elseif not why and ns.db.noteConflict then
        ns.db.noteConflict = nil
        ns.Log.Emit("setting", { key = "notes under Blizzard's window (clash gone)", on = true })
    end
end
ns.On("PLAYER_ENTERING_WORLD", function() C_Timer.After(4, Sidecar.CheckConflict) end)

-- The notes, ready to copy, under Blizzard's sign-up dialog while it's open:
-- click one to select it, then Ctrl+C and Ctrl+V into Blizzard's note box.
EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder", function()
    local dialog = LFGListApplicationDialog
    if not dialog then return end
    local strip
    -- Other addons can have their own sign-up note tools (logged so reports show it).
    ns.Trace("notes", "EllesmereUI loaded:", tostring(C_AddOns.IsAddOnLoaded("EllesmereUI")))
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
        C_Timer.After(0, function()
            if strip:IsVisible() then strip.boxes[1]:SetFocus() end
            ns.Trace("notes", "strip shown, notes", #notes, "focused", strip.boxes[1]:HasFocus())
        end)
    end
    dialog:HookScript("OnShow", Refresh)
    -- Apply on another group while the dialog is open re-uses it (no OnShow).
    hooksecurefunc("LFGListApplicationDialog_Show", function() if dialog:IsShown() then Refresh() end end)
    dialog:HookScript("OnHide", function() if strip then strip:Hide() end end)
end)

function Sidecar.Follow(f)
    if frame and frame:IsShown() then editing = f; Sidecar.Paint() end
end
