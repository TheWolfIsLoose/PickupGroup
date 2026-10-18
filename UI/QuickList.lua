--[[
    PickupGroup - UI/QuickList.lua
    Quick list: beside Blizzard's listing form (Dungeons), one row per
    season dungeon showing the party's key there. A click lists that key at
    once as Mythic+ at its level, with the playstyle last picked on
    Blizzard's form.

    The listing is made straight from the click (C_LFGList.CreateListing).
    Blizzard's form is only read (title box, rating, item level, private,
    faction), never written: an addon writing its fields taints them, and
    Blizzard's own List Group / Edit then get blocked. That's also why the
    title can't be set: whatever is in Blizzard's title box goes up.

    Party keys come from LibKeystone when another addon has it loaded
    (BigWigs and others ship it); without it only the player's own key shows.
--]]

local _, ns = ...

local QuickList = {}
ns.QuickList = QuickList

local Kit = ns.Kit
local DUNGEONS = 2  -- Group Finder category: Dungeons
local W, ROW_H, PAD = 220, 24, 8
local party = {}    -- short name -> { level, mapID } (LibKeystone)
local panel, rows = nil, {}

-- Another addon's quick-list buttons on the same form: a sentence, or nil.
function QuickList.Clash()
    local ae = _G.atrocityEssentials
    if type(ae) ~= "table" or not ae.GetModule then return nil end
    local ok, qc = pcall(ae.GetModule, ae, "LFGQuickCreate", true)
    local db = ok and type(qc) == "table" and qc.db
    if type(db) == "table" and db.Enabled ~= false and db.QuickCreate ~= false then
        return "atrocityEssentials' LFG Quick Create is on"
    end
end

-- The playstyle last picked on Blizzard's form (Relaxed until one is).
local function Playstyle()
    return ns.db.listPlaystyle or Enum.LFGEntryGeneralPlaystyle.FunRelaxed
end
local function PlaystyleName(ps) return _G["GROUP_FINDER_GENERAL_PLAYSTYLE" .. ps] or "?" end

-- challenge map ID -> { level, who }: the highest key in the party for each dungeon.
function QuickList.Keys()
    local out = {}
    local function Note(level, mapID, who)
        if (level or 0) > 0 and (mapID or 0) > 0 and (not out[mapID] or level > out[mapID].level) then
            out[mapID] = { level = level, who = who }
        end
    end
    Note(C_MythicPlus.GetOwnedKeystoneLevel(), C_MythicPlus.GetOwnedKeystoneChallengeMapID(), UnitName("player"))
    for who, k in pairs(party) do
        if UnitInParty(who) then Note(k.level, k.mapID, who) end
    end
    return out
end

-- The dungeon's Mythic+ activity at a key level (one activity per level),
-- else its Mythic+ activity of any level, else nil.
function QuickList.Activity(dungeonName, level)
    local groupID = ns.Filters.GroupIDs()[dungeonName]
    if not groupID then return nil end
    local any
    for _, id in ipairs(C_LFGList.GetAvailableActivities(DUNGEONS, groupID) or {}) do
        if C_LFGList.GetKeystoneForActivity(id) == level then return id end
        local info = C_LFGList.GetActivityInfoTable(id)
        if info and info.isMythicPlusActivity then any = any or id end
    end
    return any
end

-- Straight from the click: the only path Blizzard accepts from an addon.
local function List(row)
    local ec = LFGListFrame.EntryCreation
    local ps = Playstyle()
    local ok = C_LFGList.CreateListing({
        activityIDs = { row.activity },
        isAutoAccept = false,
        isCrossFactionListing = ec.CrossFactionGroup:IsShown() and not ec.CrossFactionGroup.CheckButton:GetChecked(),
        isPrivateGroup = ec.PrivateGroup.CheckButton:GetChecked() == true,
        newPlayerFriendly = false,
        playstyle = Enum.LFGEntryPlaystyle.None,
        generalPlaystyle = ps,
        requiredDungeonScore = tonumber(ec.MythicPlusRating.EditBox:GetText()) or 0,
        requiredItemLevel = tonumber(ec.ItemLevel.EditBox:GetText()) or 0,
        requiredPvpRating = 0,
    })
    ns.Log.Emit("lead", { action = ok and "quick-listed" or "quick list refused",
        name = ("%s +%d (%s key, activity %d, %s)"):format(row.code, row.level, row.who, row.activity, PlaystyleName(ps)) })
    if not ok then print("|cff98ff98Pickup|rGroup: the game refused that listing.") end
end

local function Row(i)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, panel)
    r:SetHeight(ROW_H - 2)
    Kit.Button(r)
    r.name = Kit.Text(r, "LEFT", "PickupGroupFontSmall")
    r.name:SetPoint("LEFT", 8, 0)
    r.key = Kit.Text(r, "RIGHT", "PickupGroupFontSmall")
    r.key:SetPoint("RIGHT", -8, 0)
    r.name:SetPoint("RIGHT", r.key, "LEFT", -6, 0)
    r:SetDisabledFontObject("PickupGroupFontDisabled")
    r:SetScript("OnClick", function(self) if self.activity then List(self) end end)
    -- Information tooltip (always shows): what a click lists, or why it can't.
    r:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.dungeon, 1, 1, 1)
        local soft = Kit.Palette.soft
        GameTooltip:AddLine(self.activity
            and ("Lists %s's +%d now as Mythic+, %s, with the title, rating and item level in Blizzard's form."):format(
                self.who, self.level, PlaystyleName(Playstyle()))
            or "No key for this dungeon in your party.", soft[1], soft[2], soft[3], true)
        GameTooltip:Show()
    end)
    r:HookScript("OnLeave", function() GameTooltip:Hide() end)
    rows[i] = r
    return r
end

local function Paint()
    local keys = QuickList.Keys()
    local y = -52
    for i, d in ipairs(ns.Filters.Dungeons()) do
        local r, k = Row(i), keys[d.mapID]
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", PAD, y)
        r:SetPoint("RIGHT", -PAD, 0)
        r.dungeon, r.code = d.name, d.code
        r.name:SetText(d.name)
        r.level, r.who = k and k.level, k and k.who
        r.activity = k and QuickList.Activity(d.name, k.level) or nil
        -- The holder in their class colour (Blizzard's colours pass through).
        local cls = k and select(2, UnitClass(k.who))
        local hex = cls and RAID_CLASS_COLORS[cls] and RAID_CLASS_COLORS[cls]:GenerateHexColor()
        r.key:SetText(k and ("|cffffffff+%d|r %s"):format(k.level, hex and ("|c" .. hex .. k.who .. "|r") or k.who) or "no key")
        r.key:SetTextColor(Kit.Palette.muted[1], Kit.Palette.muted[2], Kit.Palette.muted[3])
        r:SetEnabled(r.activity ~= nil)
        r.name:SetTextColor(r.activity and 1 or 0.55, r.activity and 1 or 0.55, r.activity and 1 or 0.55)
        r:Show()
        y = y - ROW_H
    end
    for i = #ns.Filters.Dungeons() + 1, #rows do rows[i]:Hide() end
    panel.style:SetText(PlaystyleName(Playstyle()))
end

local function Build(ec)
    Kit.ApplyFontFace()
    panel = CreateFrame("Frame", "PickupGroupQuickList", ec)
    panel:SetWidth(W)
    panel:SetPoint("TOPLEFT", PVEFrame, "TOPRIGHT", 1, 0)
    panel:SetPoint("BOTTOMLEFT", PVEFrame, "BOTTOMRIGHT", 1, 0)
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    Kit.Fill(panel, { 0.06, 0.06, 0.06, 1 })
    Kit.Border(panel)
    -- Header: title (hint tooltip on it) over a black line, as the sidecar's.
    local head = CreateFrame("Frame", nil, panel)
    head:SetPoint("TOPLEFT")
    head:SetPoint("TOPRIGHT")
    head:SetHeight(26)
    head:EnableMouse(true)
    local title = Kit.Text(head, "LEFT", "PickupGroupFont")
    title:SetPoint("LEFT", PAD, 0)
    title:SetText("Quick list")
    Kit.Tip(head, "Quick list", "One click lists that dungeon's key in your party as Mythic+ at its level."
        .. " Party members' keys show when they run an addon that shares them (BigWigs and others).", "ANCHOR_TOP")
    local rule = panel:CreateTexture(nil, "OVERLAY")
    rule:SetColorTexture(0, 0, 0, 1)
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", 0, -26)
    rule:SetPoint("TOPRIGHT", 0, -26)
    -- Status: the playstyle a click lists with (changes with Blizzard's form).
    local label = Kit.Text(panel, "LEFT")
    label:SetPoint("TOPLEFT", PAD, -34)
    label:SetText("Lists as")
    label:SetTextColor(Kit.Palette.muted[1], Kit.Palette.muted[2], Kit.Palette.muted[3])
    panel.style = Kit.Text(panel, "LEFT")
    panel.style:SetPoint("LEFT", label, "RIGHT", 6, 0)
    -- Name and version, bottom right, as on the sidecar.
    local version = ns.Version()
    local versionLabel = panel:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    versionLabel:SetPoint("RIGHT", panel, "BOTTOMRIGHT", -PAD, PAD + 11)
    versionLabel:SetText(((version:match("%-alpha") or version:match("%-beta")) and "|cffffb84d" or "|cff8c8c8c") .. version .. "|r")
    local nameLabel = panel:CreateFontString(nil, "OVERLAY", "PickupGroupFont")
    nameLabel:SetPoint("RIGHT", versionLabel, "LEFT", -6, 1)
    nameLabel:SetText("|cff98FF98Pickup|rGroup")
    -- Raider.IO's profile panel moves over to this one while it's open.
    panel:HookScript("OnShow", ns.Sidecar.MoveRaiderIO)
    panel:HookScript("OnHide", ns.Sidecar.MoveRaiderIO)
end

-- The panel, once built (Raider.IO's anchor follows it).
function QuickList.Panel() return panel end

-- Shown on Dungeons only, not while editing a listing, not while it clashes.
function QuickList.Update()
    local ec = LFGListFrame and LFGListFrame.EntryCreation
    if not ec then return end
    local on = ec:IsShown() and ec.selectedCategory == DUNGEONS and not LFGListEntryCreation_IsEditMode(ec)
        and not QuickList.Clash()
    if not on then if panel then panel:Hide() end return end
    if not panel then Build(ec) end
    panel:Show()
    Paint()
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder", function()
    local ec = LFGListFrame and LFGListFrame.EntryCreation
    if not ec then return ns.Trace("quicklist", "no listing form") end
    ec:HookScript("OnShow", function()
        local lks = LibStub and LibStub("LibKeystone", true)
        if lks and IsInGroup() then lks.Request("PARTY") end
        QuickList.Update()
    end)
    ec:HookScript("OnHide", QuickList.Update)
    hooksecurefunc("LFGListEntryCreation_Select", QuickList.Update)
    hooksecurefunc("LFGListEntryCreation_SetEditMode", QuickList.Update)
    -- Read-only: remember the playstyle the player picks on Blizzard's form.
    hooksecurefunc("LFGListEntryCreation_OnPlayStyleSelectedInternal", function(_, ps)
        if type(ps) == "number" and ps > 0 then ns.db.listPlaystyle = ps; if panel and panel:IsShown() then Paint() end end
    end)
end)

ns.On("PLAYER_LOGIN", function()
    local lks = LibStub and LibStub("LibKeystone", true)
    if not lks then return ns.Trace("quicklist", "LibKeystone not loaded: own key only") end
    lks.Register(QuickList, function(level, mapID, _, who, channel)
        if channel ~= "PARTY" then return end
        party[who] = { level = level, mapID = mapID }
        if panel and panel:IsShown() then Paint() end
    end)
end)
ns.On("GROUP_ROSTER_UPDATE", function() if panel and panel:IsShown() then Paint() end end)
