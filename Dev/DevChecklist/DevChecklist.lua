--[[
    DevChecklist: a movable in-game list of what to test.
    Each addon has its own round file in Rounds/ (DevChecklist_Rounds[addon] =
    { round = "name", items = { { area, text, send }, ... } }), so a round for
    one addon never overwrites another's. Only the addon being worked on gets
    its file rewritten; a round is emptied only once it's all ticked (or the
    player drops it). Ticks are saved per item text in DevChecklistDB.done.
    Shows at login while anything is unticked; /dc shows or hides it.
--]]

local W, PAD = 360, 10
local frame

-- Non-empty rounds, sorted by addon name.
local function Rounds()
    local list = {}
    for addon, r in pairs(DevChecklist_Rounds or {}) do
        if type(r) == "table" and r.items and #r.items > 0 then r.addon = addon; list[#list + 1] = r end
    end
    table.sort(list, function(a, b) return a.addon < b.addon end)
    return list
end

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
    title:SetText("To test")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)

    local y = -PAD - 22
    for _, r in ipairs(Rounds()) do
        local rt = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rt:SetPoint("TOPLEFT", PAD, y - 6)
        rt:SetText(r.addon .. ": " .. (r.round or ""))
        y = y - 26
        local lastArea
        for _, item in ipairs(r.items) do
            local area, text, provide = item[1], item[2], item[3]
            if area ~= lastArea then
                local h = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                h:SetPoint("TOPLEFT", PAD, y - 4)
                h:SetText(area)
                y = y - 20
                lastArea = area
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
            fs:SetText(text .. ((provide and provide ~= "") and ("  |cffbdbdbdSend: " .. provide .. "|r") or ""))
            y = y - math.max(20, fs:GetStringHeight() + 8)
        end
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
    for _, r in ipairs(Rounds()) do
        for _, item in ipairs(r.items) do
            if not DevChecklistDB.done[item[2]] then Toggle() return end
        end
    end
end)

SLASH_DEVCHECKLIST1 = "/dc"
SlashCmdList.DEVCHECKLIST = Toggle
