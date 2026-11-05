--[[
    PickupGroup - AES/Adapter.lua
    When atrocityEssentials (AES) is loaded, PickupGroup folds into it:
      - the look takes AES's accent (its brand colour), font, arrow and role art
        (UI/Kit.lua draws the same look either way)
      - settings, sign-up notes and sign-up history become three tabs on AES's
        Group & Dungeon > Keys & Group Finder page; the pane's menu and the
        panel's history buttons open them
      - our teleport button gives way to AES's LFG Reminder while it's on
      - AES's own Group Finder Panel joins the clash prompt (same spot)
    Without AES nothing here runs.

    AES has no public plugin API; we use what its options addon itself
    reaches through atrocityEssentials.NS. If a piece we rely on is missing
    (a new AES build moved it), PickupGroup says so once and keeps its own
    settings view, so a break never looks like an AES error. AES loads first
    (OptionalDeps), so it's settled when this file runs.
--]]

local _, ns = ...

local A = { on = false }
ns.AESMode = A

local Kit = ns.Kit
local AE
local PAGE = "KeysGroupFinder"  -- no master switch there, so added tabs always show
local TABS = {
    options = { key = "pug_settings", text = "PickupGroup", builderId = "PUG_AESSettings" },
    notes   = { key = "pug_notes", text = "Sign-Up Notes", builderId = "PUG_AESNotes" },
    history = { key = "pug_history", text = "Sign-Up History", builderId = "PUG_AESHistory" },
}
local ORDER = { "options", "notes", "history" }
local MEDIA = "Interface\\AddOns\\atrocityEssentials\\Media\\"

local function Usable()
    local addon = _G.atrocityEssentials
    local n = type(addon) == "table" and addon.NS
    if not (n and n.Theme and n.ApplyThemeFont and n.WithOptions and n.CreatePrompt and n.GetFontPath) then return end
    return n
end

local function Misc()
    local p = AE and AE.db and AE.db.profile
    return p and p.Miscellaneous
end

-- Back to our own settings view for the rest of the session.
function A.Fallback(why)
    if not A.on then return end
    A.on = false
    ns.Log.Emit("error", { msg = "AES mode off: " .. tostring(why) })
    ns.Print("Couldn't fit into this version of atrocityEssentials: settings and notes stay in PickupGroup's panel.")
end

-- Open one of our tabs in AES's settings window ("options", "notes", "history").
function A.Open(view)
    local tab = TABS[view]
    if not tab then return end
    AE:WithOptions(function()
        local G = AE.GUIFrame
        G.tabbedPageState = G.tabbedPageState or {}
        G.tabbedPageState[PAGE] = tab.key
        G:OpenPage(PAGE)
    end)
end

-- AES's own Group Finder Panel, on in this profile: the clash prompt's line.
function A.PanelClash()
    if ns.clashHold.aesPanelConflict then return ns.clashHold.aesPanelConflict end
    local m = Misc()
    if m and type(m.GroupFinderPanel) == "table" and m.GroupFinderPanel.Enabled == true then
        return "atrocityEssentials' Group Finder Panel is on"
    end
end

function A.SetPanel(on)
    local m = Misc()
    if m and type(m.GroupFinderPanel) == "table" then m.GroupFinderPanel.Enabled = on and true or false end
end

-- AES's LFG Reminder (teleport popup on joining) is on.
function A.ReminderOn()
    local m = Misc()
    return A.on and m and type(m.LFGReminder) == "table" and m.LFGReminder.Enabled == true or false
end

-- ===========================================================================
-- The tabs (built with AES's own option widgets, so they're AES through and through)
-- ===========================================================================
local G, Theme

local repaintQueued = false
local function Repaint()
    if repaintQueued then return end
    repaintQueued = true
    C_Timer.After(0, function()
        repaintQueued = false
        if G:IsShown() and G.selectedSidebarItem == PAGE and not GetCurrentKeyBoardFocus() then G:RefreshContent() end
    end)
end

local function Text(parent, color)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    AE:ApplyThemeFont(fs, "small")
    local c = color or Theme.textSecondary
    fs:SetTextColor(c[1], c[2], c[3], 1)
    fs:SetWordWrap(false)
    return fs
end

local function Pad(y, card) return y + card:GetContentHeight() + Theme.paddingSmall end

-- Ours, not AES's: name and version on the first card.
local function Intro(scrollChild, y, text)
    local card = G:CreateCard(scrollChild, "PickupGroup " .. ns.Version(), y)
    card:AddLabel(G:Note(text))
    return Pad(y, card)
end

local function BuildSettings(scrollChild, y)
    y = Intro(scrollChild, y, "Filters, the group list and sign-ups for the Group Finder. The filters live in the panel beside the Group Finder; these are the rest.")
    local card = G:CreateCard(scrollChild, "Settings", y)
    local opts = ns.Sidecar.OPTIONS
    for i = 1, #opts, 2 do
        local row = G:CreateRow(card.content, 40)
        for j = i, math.min(i + 1, #opts) do
            local o = opts[j]
            local c = G:CreateCheckbox(row, o[2], o[4]() and true or false, function(on)
                ns.Sidecar.SetOption(o, on)
                Repaint()
            end)
            if o[3] and c.SetTooltip then c:SetTooltip(o[3]) end
            row:AddWidget(c, 0.5)
        end
        card:AddRow(row, 40)
    end
    local why = ns.Notes.Conflict()
    if why then card:AddLabel(G:Note("Notes under sign-up are off: " .. why .. ".")) end
    y = Pad(y, card)

    local bl = G:CreateCard(scrollChild, "Blacklist", y)
    local n = ns.Cleanup.Count()
    bl:AddLabel(G:Note(("%d leader%s blacklisted. Right-click a group in the list to blacklist its leader."):format(n, n == 1 and "" or "s")))
    if n > 0 then
        local row = G:CreateRow(bl.content, 34)
        row:AddWidget(G:CreateButton(row, "Clear Blacklist", {
            width = 140, height = 24,
            callback = function()
                AE:CreatePrompt({
                    title = "Clear Blacklist", text = "Remove every leader from PickupGroup's blacklist?",
                    acceptText = "Clear", onAccept = function() ns.Cleanup.Clear(); ns.Pane.Render(); Repaint() end,
                })
            end,
        }), 0.3)
        bl:AddRow(row, 34)
    end
    return Pad(y, bl) - Theme.paddingSmall
end

local function BuildNotes(scrollChild, y)
    local card = G:CreateCard(scrollChild, "Sign-Up Notes", y)
    card:AddLabel(G:Note("Shift-click Apply to sign up with a note: these are offered to copy under Blizzard's sign-up window. A plain click signs up at once."))
    local why = ns.Notes.Conflict()
    if why then card:AddLabel(G:Note("Not shown under Blizzard's window: " .. why .. ".")) end
    local list = ns.Notes.All()
    for i = 1, ns.Notes.MAX do
        local row = G:CreateRow(card.content, 40)
        local box = G:CreateEditBox(row, "Note " .. i, list[i] or "", function(text) ns.Notes.Set(i, text) end)
        if box.editBox and box.editBox.SetMaxLetters then box.editBox:SetMaxLetters(255) end
        row:AddWidget(box, 1)
        card:AddRow(row, 40)
    end
    return Pad(y, card) - Theme.paddingSmall
end

local allChars = false
local HISTORY_ROWS = 100  -- ponytail: newest 100 here; the export has every one

local function BuildHistory(scrollChild, y)
    local sum = ns.History.Summary(allChars)
    local card = G:CreateCard(scrollChild, sum.big .. " " .. sum.label, y)
    card:AddLabel(G:Note(sum.quip))
    card:AddLabel(G:Note(sum.records))
    card:AddLabel(G:Note(sum.rates))
    local row = G:CreateRow(card.content, 40)
    row:AddWidget(G:CreateCheckbox(row, "All Characters", allChars, function(on) allChars = on; Repaint() end), 0.4)
    row:AddWidget(G:CreateButton(row, "Export", {
        width = 100, height = 24, tooltip = "Your sign-ups and lifetime counts as spreadsheet text.",
        callback = function() ns.History.ShowExport(allChars) end,
    }), 0.3)
    row:AddWidget(G:CreateButton(row, "Reset", {
        width = 100, height = 24,
        callback = function()
            AE:CreatePrompt({
                title = "Reset History",
                text = allChars and "Wipe every character's sign-ups and counts?" or "Wipe this character's sign-ups and counts?",
                acceptText = "Reset", onAccept = function() ns.History.Reset(allChars); Repaint() end,
            })
        end,
    }), 0.3)
    card:AddRow(row, 40)
    y = Pad(y, card)

    local list = sum.list
    local t = G:CreateCard(scrollChild, "Sign-Ups", y)
    if #list == 0 then
        t:AddLabel(G:Note("Nothing here yet."))
        return Pad(y, t) - Theme.paddingSmall
    end
    local cols = ns.History.COLS
    local head = G:CreateRow(t.content, 18)
    local x = 0
    for i, c in ipairs(cols) do
        if allChars or i ~= 2 then
            local fs = Text(head, Theme.textMuted)
            fs:SetPoint("LEFT", head, "LEFT", x, 0)
            fs:SetText(c[1])
            x = x + c[2] + 20
        end
    end
    t:AddRow(head, 18, 2)
    for i = 1, math.min(#list, HISTORY_ROWS) do
        local r = G:CreateRow(t.content, 18)
        local cells = { ns.History.Cells(list[i]) }
        local color = cells[6]
        x = 0
        for c = 1, 5 do
            if allChars or c ~= 2 then
                local fs = Text(r, c == 5 and color or nil)
                fs:SetPoint("LEFT", r, "LEFT", x, 0)
                fs:SetWidth(cols[c][2] + 14)
                fs:SetJustifyH("LEFT")
                fs:SetText(cells[c])
                x = x + cols[c][2] + 20
            end
        end
        t:AddRow(r, 18, 2)
    end
    if #list > HISTORY_ROWS then t:AddLabel(G:Note(("Newest %d of %d shown; Export has them all."):format(HISTORY_ROWS, #list))) end
    return Pad(y, t) - Theme.paddingSmall
end

local BUILDERS = { options = BuildSettings, notes = BuildNotes, history = BuildHistory }

-- ===========================================================================
-- Wiring
-- ===========================================================================
local NEEDS = { "RegisterContent", "RefreshContent", "OpenPage", "CreateCard", "CreateRow",
                "CreateButton", "CreateEditBox", "CreateCheckbox", "Note", "IsShown" }

local function Register()
    G, Theme = AE.GUIFrame, AE.Theme
    local tabs = G and G.TabbedPages and G.TabbedPages[PAGE]
    if not tabs then return A.Fallback("no Keys & Group Finder page") end
    for _, fn in ipairs(NEEDS) do
        if type(G[fn]) ~= "function" then return A.Fallback("options window has no " .. fn) end
    end
    for _, view in ipairs(ORDER) do
        local tab, build = TABS[view], BUILDERS[view]
        G:RegisterContent(tab.builderId, function(scrollChild, yOffset)
            local ok, y = pcall(build, scrollChild, yOffset)
            if ok then return y end
            A.Fallback(y)
            return yOffset
        end)
        local present = false
        for _, t in ipairs(tabs) do if t.key == tab.key then present = true end end
        if not present then tabs[#tabs + 1] = { key = tab.key, text = tab.text, builderId = tab.builderId } end
    end
end

-- One-time notice that the settings moved.
local function Notice()
    if ns.db.aesNoticeShown then return end
    ns.db.aesNoticeShown = true
    AE:CreatePrompt({
        title = "PickupGroup",
        text = "With atrocityEssentials loaded, PickupGroup's settings, sign-up notes and sign-up history live in the AES settings window, under Group & Dungeon > Keys & Group Finder. The filters stay in the panel beside the Group Finder.",
        acceptText = "Open Settings",
        cancelText = "OK",
        onAccept = function() A.Open("options") end,
    })
end

AE = Usable()
if AE then
    A.on = true
    -- The look: AES's accent (live: it follows a change in AES's settings),
    -- its font, its arrow and role art.
    local DEFAULT = { 0.451, 0.506, 1.0 }
    function Kit.Accent()
        local b = AE.GUITheme and AE.GUITheme.brand
        return (type(b) == "table" and b[1]) and b or DEFAULT
    end
    Kit.FaceOverride = function() return AE:GetFontPath() end
    Kit.ARROW_ART = MEDIA .. "GUITextures\\aesArrow.png"
    Kit.ROLE_ART = { TANK = MEDIA .. "RoleIcons\\tank-modern.png", HEALER = MEDIA .. "RoleIcons\\healer-modern.png",
                     DAMAGER = MEDIA .. "RoleIcons\\dps-modern.png" }

    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function(self, event, name)
        if event == "PLAYER_LOGIN" then
            C_Timer.After(3, function() if A.on then Notice() end end)
        elseif name == "atrocityEssentials_Options" then
            self:UnregisterEvent("ADDON_LOADED")
            local ok, err = pcall(Register)
            if not ok then A.Fallback(err) end
        end
    end)
    if C_AddOns.IsAddOnLoaded("atrocityEssentials_Options") then
        local ok, err = pcall(Register)
        if not ok then A.Fallback(err) end
    end
end
