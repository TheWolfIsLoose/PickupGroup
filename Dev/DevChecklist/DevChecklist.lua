--[[
    DevChecklist: a movable in-game list of what to test this round.
    Checklist.lua holds the items (rewritten between builds); ticks are saved
    per item text in DevChecklistDB.done, so Claude can read what was ticked.
    Shows at login while anything is unticked; /dc shows or hides it.
--]]

local W, PAD = 360, 10
local frame

local function Build()
    frame = CreateFrame("Frame", "DevChecklistFrame", UIParent, "BackdropTemplate")
    frame:SetWidth(W)
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        DevChecklistDB.point = { p, rp, x, y }
    end)
    local pt = DevChecklistDB.point or { "TOPLEFT", "TOPLEFT", 40, -200 }
    frame:SetPoint(pt[1], UIParent, pt[2], pt[3], pt[4])

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", PAD, -PAD)
    title:SetText("To test" .. (DevChecklist_Round and (": " .. DevChecklist_Round) or ""))
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)

    local y = -PAD - 22
    local lastAddon
    for _, item in ipairs(DevChecklist_Items or {}) do
        local addon, text, provide = item[1], item[2], item[3]
        if addon ~= lastAddon then
            local h = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            h:SetPoint("TOPLEFT", PAD, y - 4)
            h:SetText(addon)
            y = y - 20
            lastAddon = addon
        end
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", PAD - 4, y + 4)
        cb:SetChecked(DevChecklistDB.done[text] == true)
        cb:SetScript("OnClick", function(self) DevChecklistDB.done[text] = self:GetChecked() or nil end)
        local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", PAD + 24, y)
        fs:SetWidth(W - 2 * PAD - 24)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(true)
        fs:SetText(text .. ((provide and provide ~= "") and ("  |cff98ff98Send: " .. provide .. "|r") or ""))
        y = y - math.max(20, fs:GetStringHeight() + 8)
    end
    frame:SetHeight(-y + PAD)
end

local function Toggle()
    if not frame then Build() end
    frame:SetShown(not frame:IsShown())
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    DevChecklistDB = DevChecklistDB or {}
    DevChecklistDB.done = DevChecklistDB.done or {}
    for _, item in ipairs(DevChecklist_Items or {}) do
        if not DevChecklistDB.done[item[2]] then Toggle() return end
    end
end)

SLASH_DEVCHECKLIST1 = "/dc"
SlashCmdList.DEVCHECKLIST = Toggle
