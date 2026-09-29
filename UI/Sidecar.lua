--[[
    PickupGroup - UI/Sidecar.lua
    The sidecar: a panel on the Group Finder's right edge for setting up a
    filter. Edits apply as they are made (no Save step). It covers
    Raider.IO's panel while open; that frame is never moved.

    Filter tab (alpha): name, then per kind
      keys  dungeons (this season), room for my role, needs Bloodlust,
            needs battle rez, leader at least my score, leader score floor
      raid  difficulty, bosses down at most, room
    Delete keeps at least one filter per kind.
--]]

local _, ns = ...

local Sidecar = {}
ns.Sidecar = Sidecar

local Kit, Filters = ns.Kit, ns.Filters
local W, PAD = 220, 8
local MINT = Kit.Palette.brand
local DIFF = { { "N", { 0.12, 1, 0 } }, { "H", { 0, 0.44, 0.87 } }, { "M", { 1, 0.5, 0 } } }

local frame, editing
local nameBox, keysBox, raidBox, deleteBtn
local dungeonButtons, checks, diffButtons = {}, {}, {}
local scoreBox, bossBox
local bossLines = {}
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
    function b:Paint(on, color)
        Kit.Fill(self, on and { 0.12, 0.23, 0.14, 1 } or Kit.Palette.bgMedium)
        local c = color or (on and MINT or { 0.55, 0.55, 0.55 })
        self:GetFontString():SetTextColor(c[1], c[2], c[3], on and 1 or 0.5)
    end
    b:SetScript("OnClick", onClick)
    return b
end

local function PaintKeys(f)
    for _, b in ipairs(dungeonButtons) do b:Paint(not f.dungeons or f.dungeons[b.dungeon] == true) end
    for key, c in pairs(checks) do c:Set(f[key]) end
    scoreBox:SetText((f.minScore or 0) > 0 and tostring(f.minScore) or "")
end

-- Each boss cycles Either -> Alive -> Dead: raids aren't cleared in order.
local WANT_NEXT = { [false] = "alive", alive = "dead", dead = false }
local WANT_LOOK = { [false] = { "Either", { 0.55, 0.55, 0.55 } }, alive = { "Alive", MINT }, dead = { "Dead", { 1, 0.72, 0.3 } } }

local function PaintRaid(f)
    for _, b in ipairs(diffButtons) do
        local on = not f.difficulties or f.difficulties[b.diff]
        b:Paint(on, on and b.color or nil)
    end
    checks.raidRoom:Set(f.room)
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
                    .. "Uses your lockout for the difficulty this filter looks for (the highest, if several). "
                    .. "Mythic lockouts are whole, so on Mythic it tells you whether any group can take you.", 0.8, 0.8, 0.8, true)
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
    nameBox:SetText(editing.name or "")
    keysBox:SetShown(editing.kind == "keys")
    raidBox:SetShown(editing.kind == "raid")
    if editing.kind == "keys" then PaintKeys(editing) else PaintRaid(editing) end
    deleteBtn:SetEnabled(#Filters.List(editing.kind) > 1)
end

local function BuildKeys(parent)
    local box = CreateFrame("Frame", nil, parent)
    local y = 0
    local head = Label(box, "Dungeons")
    head:SetPoint("TOPLEFT", 0, y)
    local all = CreateFrame("Button", nil, box)
    all:SetSize(60, 12)
    all:SetPoint("TOPRIGHT", 0, y)
    local allText = Label(all, "All · None")
    allText:SetPoint("RIGHT")
    all:SetScript("OnClick", function()
        -- All when any is off, else none.
        if editing.dungeons then editing.dungeons = nil else editing.dungeons = {} end
        Sidecar.Paint(); Changed()
    end)
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
        { "room", "Room for my role" }, { "lust", "Needs Bloodlust" },
        { "brez", "Needs battle rez" }, { "atLeastMine", "Leader at least my score" },
    }) do
        local key = c[1]
        local cb = Kit.Check(box, c[2], function(on) editing[key] = on or nil; Changed() end)
        cb:SetPoint("TOPLEFT", 0, y)
        checks[key] = cb
        y = y - 20
    end
    y = y - 4
    local l = Label(box, "Leader score at least")
    l:SetPoint("TOPLEFT", 0, y - 4)
    scoreBox = Kit.Edit(box, 56, function(text)
        local n = tonumber(text)
        editing.minScore = (n and n > 0) and n or nil
        Changed()
    end, true)
    scoreBox:SetPoint("TOPRIGHT", 0, y)
    box:SetHeight(-y + 24)
    return box
end

local function BuildRaid(parent)
    local box = CreateFrame("Frame", nil, parent)
    local head = Label(box, "Difficulty")
    head:SetPoint("TOPLEFT")
    local cellW = (W - 2 * PAD - 2 * 3) / 3
    for i, d in ipairs(DIFF) do
        local b = Toggle(box, d[1], cellW, function(self)
            editing.difficulties = editing.difficulties or { N = true, H = true, M = true }
            editing.difficulties[self.diff] = not editing.difficulties[self.diff] or nil
            Sidecar.Paint(); Changed()
        end)
        b.diff, b.color = d[1], d[2]
        b:SetPoint("TOPLEFT", (i - 1) * (cellW + 3), -16)
        diffButtons[i] = b
    end
    local cb = Kit.Check(box, "Room in the raid", function(on) editing.room = on or nil; Changed() end)
    cb:SetPoint("TOPLEFT", 0, -46)
    checks.raidRoom = cb
    local l = Label(box, "Bosses in the group's lockout")
    l:SetPoint("TOPLEFT", 0, -72)
    bossBox = CreateFrame("Frame", nil, box)
    bossBox:SetPoint("TOPLEFT", 0, -88)
    bossBox:SetPoint("RIGHT")
    bossBox:SetHeight(1)
    box:SetHeight(300)
    return box
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

    local title = frame:CreateFontString(nil, "OVERLAY", "PickupGroupFont")
    title:SetPoint("TOPLEFT", PAD, -7)
    title:SetText("Filter")
    title:SetTextColor(MINT[1], MINT[2], MINT[3])
    Kit.HeaderIcon(frame, Kit.CLOSE, "Close", function() frame:Hide() end):SetPoint("TOPRIGHT", -2, -1)
    local rule = frame:CreateTexture(nil, "OVERLAY")
    rule:SetColorTexture(0, 0, 0, 1)
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", 0, -26)
    rule:SetPoint("TOPRIGHT", 0, -26)

    local body = CreateFrame("Frame", nil, frame)
    body:SetPoint("TOPLEFT", PAD, -34)
    body:SetPoint("BOTTOMRIGHT", -PAD, PAD)

    nameBox = Kit.Edit(body, W - 2 * PAD, function(text)
        text = strtrim(text or "")
        if text ~= "" and editing then editing.name = text; ns.Pane.Render() end
    end)
    nameBox:SetPoint("TOPLEFT")
    nameBox:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Filter name (its tab)"); GameTooltip:Show()
    end)
    nameBox:HookScript("OnLeave", function() GameTooltip:Hide() end)

    keysBox = BuildKeys(body)
    keysBox:SetPoint("TOPLEFT", 0, -30)
    keysBox:SetPoint("RIGHT")
    raidBox = BuildRaid(body)
    raidBox:SetPoint("TOPLEFT", 0, -30)
    raidBox:SetPoint("RIGHT")

    deleteBtn = CreateFrame("Button", nil, body)
    deleteBtn:SetSize(72, 22)
    deleteBtn:SetPoint("BOTTOMLEFT")
    Kit.Button(deleteBtn)
    deleteBtn:SetText("Delete")
    deleteBtn:SetScript("OnClick", function()
        if editing and Filters.Delete(editing) then
            editing = Filters.Active(editing.kind)
            Sidecar.Paint(); Changed()
        end
    end)
    frame:Hide()
end

-- Open on a filter (the active one by default); toggles when already open on it.
function Sidecar.Open(f)
    if not PVEFrame then return end
    if not frame then Build() end
    f = f or Filters.Active()
    if frame:IsShown() and editing == f then frame:Hide() return end
    editing = f
    RequestRaidInfo()  -- lockouts for Match my lockout
    Sidecar.Paint()
    frame:Show()
end

-- New results can bring raids the boss list hasn't shown yet.
function Sidecar.RefreshBosses()
    if frame and frame:IsShown() and editing and editing.kind == "raid" then PaintRaid(editing) end
end

function Sidecar.Hide()
    if frame then frame:Hide() end
end

function Sidecar.Follow(f)
    if frame and frame:IsShown() then editing = f; Sidecar.Paint() end
end
