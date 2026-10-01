--[[
    PickupGroup - UI/Kit.lua
    The look, shared by every window: fonts, palette and the style helpers.
    Same visual language as StockClerk (its Dev/STYLE.md): flat fills, 1px
    black lines, mint accent, drawn glyphs, no Blizzard templates.
--]]

local _, ns = ...

local Kit = {}
ns.Kit = Kit

-- ---------------------------------------------------------------------------
-- Fonts: three sizes in white, plus grey for disabled buttons. Face is
-- Expressway when LibSharedMedia has it, else the bundled Barlow Semi
-- Condensed (SIL OFL, Media/). Expressway can't ship: its license forbids
-- embedding.
-- ---------------------------------------------------------------------------
local FONT_FALLBACK = "Interface\\AddOns\\PickupGroup\\Media\\BarlowSemiCondensed-Medium.ttf"
local FONTS = {
    PickupGroupFontSmall = { 10, 1 }, PickupGroupFont = { 12, 1 }, PickupGroupFontLarge = { 16, 1 },
    PickupGroupFontDisabled = { 12, 0.5 },
}
for name, spec in pairs(FONTS) do
    local fo = CreateFont(name)
    fo:SetFont(FONT_FALLBACK, spec[1], "")
    fo:SetTextColor(spec[2], spec[2], spec[2])
    FONTS[name] = { fo = fo, size = spec[1] }
end

-- Switch to Expressway once other addons have registered their media; every
-- window's build calls this first. Font strings follow their font object.
function Kit.ApplyFontFace()
    if Kit.fontsApplied then return end
    Kit.fontsApplied = true
    local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
    local face = lsm and lsm:Fetch("font", "Expressway", true)
    if face then
        for _, f in pairs(FONTS) do f.fo:SetFont(face, f.size, "") end
    end
end

Kit.Palette = {
    bgDark    = { 0.031, 0.031, 0.031, 0.97 }, -- window
    bgMedium  = { 0.055, 0.055, 0.055, 0.95 }, -- buttons
    panelBg   = { 0.060, 0.060, 0.060, 0.98 }, -- sidecar, log window
    btnRest   = { 1, 1, 1, 0.07 },
    well      = { 1, 1, 1, 0.08 },             -- text boxes, checkboxes: visibly "fill me"
    ringHover = { 0.55, 0.55, 0.55, 1 },       -- input under the mouse
    hoverWash = { 0.851, 0.851, 0.851, 0.15 },
    pressFill = { 0.851, 0.851, 0.851, 0.22 },
    border    = { 0, 0, 0, 1 },
    brand     = { 0.596, 1, 0.596, 1 },        -- mint
    glyphRest = { 0.85, 0.85, 0.85, 1 },
}
local Palette = Kit.Palette

-- Fills use SetColorTexture (White8x8 + vertex colour renders transparent on
-- retail); 1px lines turn off texel snapping so they don't smear across two
-- pixel rows at off-grid UI scales.
local function Solid(frame, layer, sublevel, color)
    local t = frame:CreateTexture(nil, layer, nil, sublevel)
    t:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    t:SetSnapToPixelGrid(false)
    t:SetTexelSnappingBias(0)
    return t
end

-- Opaque background (BACKGROUND -8). Recolourable: call again.
function Kit.Fill(frame, color)
    frame._bg = frame._bg or Solid(frame, "BACKGROUND", -8, color)
    frame._bg:SetAllPoints()
    frame._bg:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

-- Translucent strip over the fill (BACKGROUND -6).
function Kit.Band(frame, color)
    frame._band = frame._band or Solid(frame, "BACKGROUND", -6, color)
    frame._band:SetAllPoints()
    frame._band:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

-- Ring colour for an input: mint while typing, grey under the mouse, else black.
local function Ring(frame, c)
    for _, t in ipairs(frame._border) do t:SetColorTexture(c[1], c[2], c[3], c[4] or 1) end
end

-- 1px ring.
function Kit.Border(frame, color)
    local ring = {}
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local t = Solid(frame, "OVERLAY", 7, color or Palette.border)
        if side == "TOP" or side == "BOTTOM" then
            t:SetHeight(1); t:SetPoint(side .. "LEFT"); t:SetPoint(side .. "RIGHT")
        else
            t:SetWidth(1); t:SetPoint("TOP" .. side); t:SetPoint("BOTTOM" .. side)
        end
        ring[#ring + 1] = t
    end
    frame._border = ring
    return ring
end

-- Flat button: base + band, hover wash, press flash, black ring. Scripts are
-- hooked, so callers must HookScript too or the wash dies.
function Kit.Button(btn)
    Kit.Fill(btn, Palette.bgMedium)
    Kit.Band(btn, Palette.btnRest)
    Kit.Border(btn)
    local wash = Solid(btn, "ARTWORK", 7, Palette.hoverWash)
    wash:SetPoint("TOPLEFT", 1, -1)
    wash:SetPoint("BOTTOMRIGHT", -1, 1)
    wash:Hide()
    btn:HookScript("OnEnter", function() wash:Show() end)
    btn:HookScript("OnLeave", function() wash:Hide() end)
    btn:HookScript("OnMouseDown", function(self) if self:IsEnabled() then Kit.Band(self, Palette.pressFill) end end)
    btn:HookScript("OnMouseUp", function(self) Kit.Band(self, Palette.btnRest) end)
    btn:SetNormalFontObject("PickupGroupFont")
    btn:SetHighlightFontObject("PickupGroupFont")
    btn:SetDisabledFontObject("PickupGroupFontDisabled")
end

-- Drawn icon: flat bars, crisp and tinted as one.
-- bars = { { w, h, y, angle, x }, ... } centred on the frame. Returns tint(color).
function Kit.Glyph(frame, bars)
    local tex = {}
    for i, b in ipairs(bars) do
        local t = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetSize(b[1], b[2])
        t:SetPoint("CENTER", b[5] or 0, b[3] or 0)
        if b[4] then t:SetRotation(b[4]) end
        tex[i] = t
    end
    local function tint(c) for _, t in ipairs(tex) do t:SetColorTexture(c[1], c[2], c[3], c[4] or 1) end end
    tint(Palette.glyphRest)
    return tint
end

Kit.CLOSE = { { 12, 2, 0, math.pi / 4 }, { 12, 2, 0, -math.pi / 4 } }

-- Header icon: drawn glyph, mint on hover, one-line tooltip.
function Kit.HeaderIcon(parent, bars, tip, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(24, 24)
    local tint = Kit.Glyph(btn, bars)
    btn:SetScript("OnEnter", function(self)
        tint(Palette.brand)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(tip)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() tint(Palette.glyphRest); GameTooltip:Hide() end)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Checkbox: 12px light well (grey ring on hover), mint square when on; the label is part of the
-- click area. box:Set(on), box:Get(); onChange(on) after a click.
function Kit.Check(parent, label, onChange)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(16)
    local well = CreateFrame("Frame", nil, b)
    well:SetSize(12, 12)
    well:SetPoint("LEFT")
    Kit.Fill(well, Palette.well)
    Kit.Border(well)
    b:SetScript("OnEnter", function() Ring(well, Palette.ringHover) end)
    b:SetScript("OnLeave", function() Ring(well, Palette.border) end)
    local mark = well:CreateTexture(nil, "OVERLAY")
    mark:SetSize(8, 8)
    mark:SetPoint("CENTER")
    mark:SetColorTexture(Palette.brand[1], Palette.brand[2], Palette.brand[3], 1)
    local text = b:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    text:SetPoint("LEFT", well, "RIGHT", 6, 0)
    text:SetText(label)
    b:SetWidth(18 + text:GetStringWidth() + 4)
    local on = false
    function b:Set(v) on = v and true or false; mark:SetShown(on) end
    function b:Get() return on end
    b:SetScript("OnClick", function(self) self:Set(not on); onChange(on) end)
    b:Set(false)
    return b
end

-- Text box: light well + black ring (grey on hover, mint while typing). onCommit(text) on Enter or losing
-- focus. Clears focus when hidden (a hidden focused box eats every key).
function Kit.Edit(parent, width, onCommit, numeric)
    local e = CreateFrame("EditBox", nil, parent)
    e:SetSize(width, 20)
    e:SetAutoFocus(false)
    e:SetFontObject("PickupGroupFontSmall")
    e:SetTextInsets(6, 6, 0, 0)
    if numeric then e:SetNumeric(true) end
    Kit.Fill(e, Palette.well)
    Kit.Border(e)
    -- SetScript drops any hooks already on that script, so set before hooking
    -- (the rest ring after typing never came back while this ran last).
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEditFocusLost", function(self) onCommit(self:GetText()) end)
    e:SetScript("OnHide", function(self) self:ClearFocus() end)
    e:HookScript("OnEnter", function(self) if not self:HasFocus() then Ring(self, Palette.ringHover) end end)
    e:HookScript("OnLeave", function(self) if not self:HasFocus() then Ring(self, Palette.border) end end)
    e:HookScript("OnEditFocusGained", function(self) Ring(self, Palette.brand) end)
    e:HookScript("OnEditFocusLost", function(self) Ring(self, self:IsMouseOver() and Palette.ringHover or Palette.border) end)
    return e
end

-- Grey placeholder naming the field, shown while the box is empty and unfocused.
function Kit.Hint(e, text)
    local h = e:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    h:SetPoint("LEFT", 6, 0)
    h:SetTextColor(0.55, 0.55, 0.55)
    h:SetText(text)
    local function show() h:SetShown(e:GetText() == "" and not e:HasFocus()) end
    e:HookScript("OnTextChanged", show)
    e:HookScript("OnEditFocusGained", show)
    e:HookScript("OnEditFocusLost", show)
end
