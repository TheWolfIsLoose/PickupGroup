--[[
    PickupGroup - UI/LogPopup.lua
    /pug log: the report (Log.Report) in a copyable text box, pre-selected so
    Ctrl+C works at once. A snapshot taken on open, so a selection survives
    while copying.
--]]

local _, ns = ...

local LogPopup = {}
ns.LogPopup = LogPopup

local Kit = ns.Kit
local frame

local function Build()
    Kit.ApplyFontFace()
    local f = CreateFrame("Frame", "PickupGroupLogPopup", UIParent)
    f:SetSize(520, 420)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    tinsert(UISpecialFrames, "PickupGroupLogPopup")  -- Escape closes it
    Kit.Fill(f, Kit.Palette.panelBg)
    Kit.Border(f)

    local title = f:CreateFontString(nil, "OVERLAY", "PickupGroupFont")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("|cff98ff98Pickup|rGroup log")
    local hint = f:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    hint:SetPoint("TOPLEFT", 12, -28)
    hint:SetText("|cff888888Everything is selected: press Ctrl+C and paste it into your bug report.|r")
    Kit.HeaderIcon(f, Kit.CLOSE, "Close", function() f:Hide() end):SetPoint("TOPRIGHT", -4, -4)

    local well = f:CreateTexture(nil, "BACKGROUND")
    well:SetColorTexture(unpack(Kit.Palette.bgDark))
    well:SetPoint("TOPLEFT", 8, -50)
    well:SetPoint("BOTTOMRIGHT", -8, 38)
    local scroll = CreateFrame("ScrollFrame", "PickupGroupLogPopupScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -52)
    scroll:SetPoint("BOTTOMRIGHT", -28, 40)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontSmall")
    edit:SetWidth(scroll:GetWidth() - 4)
    edit:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(edit)
    -- A hidden focused box swallows every key game-wide.
    f:SetScript("OnHide", function() edit:ClearFocus() end)

    local clear = CreateFrame("Button", nil, f)
    clear:SetSize(80, 22)
    clear:SetPoint("BOTTOMRIGHT", -8, 8)
    Kit.Button(clear)
    clear:SetText("Clear log")

    local function Fill()
        edit:SetText(ns.Log.Report())
        scroll:SetVerticalScroll(0)
        edit:SetFocus()
        edit:HighlightText()
    end
    clear:SetScript("OnClick", function() ns.Log.Clear(); Fill() end)
    f:SetScript("OnShow", Fill)
    return f
end

function LogPopup.Toggle()
    frame = frame or Build()
    frame:SetShown(not frame:IsShown())
end
