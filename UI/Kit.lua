--[[
    PickupGroup - UI/Kit.lua
    The look, shared by every window: fonts, palette and the style helpers.
    atrocityEssentials' visual language (flat #0e0e0e controls, 1px black
    edges, a grey hover wash, the accent as a 35% fill for "engaged"), drawn
    by our own helpers, with a white accent. No Blizzard templates.
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
    -- AES's sizes: 11 for buttons and labels, 12 body, 14 titles.
    PickupGroupFontSmall = { 11, 1 }, PickupGroupFont = { 12, 1 }, PickupGroupFontLarge = { 14, 1 },
    PickupGroupFontDisabled = { 11, 0.55 },  -- disabled button labels: Small in muted
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
    bgDark    = { 0.031, 0.031, 0.031, 0.97 }, -- window (AES #080808)
    bgMedium  = { 0.055, 0.055, 0.055, 0.90 }, -- controls (AES control fill)
    panelBg   = { 0.055, 0.055, 0.055, 0.98 }, -- docked panel, log window (AES #0e0e0e)
    btnRest   = { 1, 1, 1, 0 },
    well      = { 0.055, 0.055, 0.055, 0.90 }, -- text boxes, checkboxes: the control fill
    ringRest  = { 0, 0, 0, 1 },                -- controls at rest: a black edge, as AES
    ringHover = { 0, 0, 0, 1 },                -- (hover is the wash, not the edge)
    hoverWash = { 0.851, 0.851, 0.851, 0.15 }, -- AES's one hover value
    pressFill = { 0.851, 0.851, 0.851, 0.22 },
    border    = { 0, 0, 0, 1 },
    on        = { 1, 1, 1, 1 },                -- white text
    accent    = { 1, 1, 1, 1 },                -- engaged, headings
    selectA   = 0.35,                          -- accent fill behind an engaged toggle (AES selectedA)
    fillA     = 0.8,                           -- a ticked box
    glyphRest = { 0.85, 0.85, 0.85, 1 },
    -- Text and status tokens (suite style guide): soft 0.74 for tooltip bodies
    -- and secondary text, muted 0.55 (8C8C8C) for labels, headings and "off",
    -- warn yellow FFD84A, bad red FF6666, info blue 5AA9FF (new / worth a
    -- look), good green 4ADE80 (yours, in progress). All 4.5:1+ on the panel.
    soft      = { 0.74, 0.74, 0.74, 1 },
    muted     = { 0.55, 0.55, 0.55, 1 },
    warn      = { 1, 0.847, 0.29, 1 },
    bad       = { 1, 0.4, 0.4, 1 },
    info      = { 0.353, 0.663, 1, 1 },
    good      = { 0.29, 0.871, 0.502, 1 },     -- green 4ADE80: yours and in progress (sign-ups waiting / invited, joined)
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

-- Opaque fill (BACKGROUND -8, frame._bg) or a translucent band over it
-- (-6, frame._band). Call again to recolour.
local function Layer(frame, key, sublevel, color)
    frame[key] = frame[key] or Solid(frame, "BACKGROUND", sublevel, color)
    frame[key]:SetAllPoints()
    frame[key]:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end
function Kit.Fill(frame, color) Layer(frame, "_bg", -8, color) end
function Kit.Band(frame, color) Layer(frame, "_band", -6, color) end

-- One line of small text, no wrap.
function Kit.Text(parent, justify, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "PickupGroupFontSmall")
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    return fs
end

Kit.LEAVER_ATLAS = "groupfinder-icon-leaver"
-- Secret in restricted content: read as "no mark" then.
function Kit.IsLeaver(v) return not issecretvalue(v) and v == true end

-- Spec icon tile: dark square, black ring, trimmed icon (t.icon), leaver mark (t.leaver).
function Kit.Tile(parent, size)
    local t = CreateFrame("Frame", nil, parent)
    t:SetSize(size, size)
    Kit.Fill(t, { 0.11, 0.11, 0.11, 1 })
    Kit.Border(t)
    t.icon = t:CreateTexture(nil, "ARTWORK")
    t.icon:SetPoint("TOPLEFT", 1, -1)
    t.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    t.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)  -- AES's icon zoom (0.3)
    -- Blizzard's leaver mark (the player left groups early lately), on its
    -- own frame so the leader ring drawn over the tile doesn't cover it.
    local top = CreateFrame("Frame", nil, t)
    top:SetAllPoints()
    top:SetFrameLevel(t:GetFrameLevel() + 3)
    t.leaver = top:CreateTexture(nil, "OVERLAY")
    t.leaver:SetAtlas(Kit.LEAVER_ATLAS)
    t.leaver:SetSize(math.floor(size * 0.6), math.floor(size * 0.6))
    t.leaver:SetPoint("CENTER", t, "TOPRIGHT", -1, -1)
    t.leaver:Hide()
    return t
end

-- Hint tooltip on a control (Options can hide hints). title and body may
-- be a function(control); body is optional.
function Kit.Tip(ctrl, title, body, anchor)
    ctrl:HookScript("OnEnter", function(self)
        if not ns.Hints() then return end
        GameTooltip:SetOwner(self, anchor or "ANCHOR_TOP")
        GameTooltip:SetText(type(title) == "function" and title(self) or title, 1, 1, 1)
        local text = type(body) == "function" and body(self) or body
        if text then GameTooltip:AddLine(text, Palette.soft[1], Palette.soft[2], Palette.soft[3], true) end
        GameTooltip:Show()
    end)
    ctrl:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local Ring  -- (below)
-- Destructive action: the first click turns the label to "Sure?" in red
-- (bad) with a red ring, flashing (three 1 s pulses, then it lapses back);
-- the second click runs fn. No confirm dialogs.
function Kit.Confirm(btn, label, fn)
    btn:SetText(label)
    local fs = btn:GetFontString()
    local flash = Kit.Pulse(fs, 0.35, 0.5)
    local function disarm(self)
        self.armed = nil; flash:Stop(); fs:SetAlpha(1)
        self:SetText(label); Ring(self, Palette.ringRest)
    end
    btn:SetScript("OnClick", function(self)
        if self.armed then disarm(self); return fn() end
        self.armed = (self.armed or 0) + 1
        local token = self.armed
        self:SetText("|cffff6666Sure?|r"); Ring(self, Palette.bad)
        flash:Play()
        C_Timer.After(3, function() if self.armed == token then disarm(self) end end)
    end)
end

-- Ring colour for an input: white while typing, light grey under the mouse, else grey.
function Ring(frame, c)
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

-- Flat button: base + band, hover wash, press flash, grey ring. Scripts are
-- hooked, so callers must HookScript too or the wash dies.
function Kit.Button(btn)
    Kit.Fill(btn, Palette.bgMedium)
    Kit.Band(btn, Palette.btnRest)
    Kit.Border(btn, Palette.ringRest)
    local wash = Solid(btn, "ARTWORK", 7, Palette.hoverWash)
    wash:SetPoint("TOPLEFT", 1, -1)
    wash:SetPoint("BOTTOMRIGHT", -1, 1)
    wash:Hide()
    btn:HookScript("OnEnter", function() wash:Show() end)
    btn:HookScript("OnLeave", function() wash:Hide() end)
    btn:HookScript("OnMouseDown", function(self) if self:IsEnabled() then Kit.Band(self, Palette.pressFill) end end)
    btn:HookScript("OnMouseUp", function(self) Kit.Band(self, Palette.btnRest) end)
    btn:SetNormalFontObject("PickupGroupFontSmall")  -- buttons: Small, everywhere
    btn:SetHighlightFontObject("PickupGroupFontSmall")
    btn:SetDisabledFontObject("PickupGroupFontDisabled")
end

-- Drawn icon: flat bars, crisp and tinted as one.
-- bars = { { w, h, y, angle, x }, ... } centred on the frame, or a texture
-- path (a white drawing, shown 16 px). Returns tint(color).
function Kit.Glyph(frame, bars)
    local tex = {}
    if type(bars) == "string" then
        local t = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetSize(16, 16)
        t:SetPoint("CENTER")
        t:SetTexture(bars)
        local function tint(c) t:SetVertexColor(c[1], c[2], c[3], c[4] or 1) end
        tint(Palette.glyphRest)
        return tint
    end
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
-- Refresh: our own drawn circular arrow (Media/Refresh.tga, white, tinted like
-- the bars); rotated bars couldn't draw a smooth ring.
Kit.REFRESH = "Interface\\AddOns\\PickupGroup\\Media\\Refresh"
Kit.MENU = { { 12, 2, 4 }, { 12, 2, 0 }, { 12, 2, -4 } }  -- Settings & Activity
Kit.SLIDERS = { { 12, 2, 4 }, { 4, 6, 4, nil, -2 }, { 12, 2, -4 }, { 4, 6, -4, nil, 3 } }  -- filter setup

-- The suite's pulse: fade to `low` and back (each half `half` s), three
-- times, then stop (WCAG 2.2.2). Returns the animation group; Play restarts it.
function Kit.Pulse(region, low, half)
    local g = region:CreateAnimationGroup()
    local a = g:CreateAnimation("Alpha")
    a:SetFromAlpha(1); a:SetToAlpha(low); a:SetDuration(half); a:SetSmoothing("IN_OUT")
    local b = g:CreateAnimation("Alpha")
    b:SetFromAlpha(low); b:SetToAlpha(1); b:SetDuration(half); b:SetStartDelay(half); b:SetSmoothing("IN_OUT")
    g:SetLooping("REPEAT")
    local loops = 0
    g:SetScript("OnPlay", function() loops = 0 end)
    g:SetScript("OnLoop", function(self) loops = loops + 1; if loops >= 3 then self:Stop() end end)
    return g
end

-- Shimmer: one soft white band sweeps across a row once (two seconds),
-- clipped to it; two gradient halves make the band. Adds r.Shimmer() and
-- r.StopShimmer(). The suite's "this row is news" motion.
function Kit.Shimmer(r, h, w)
    local clip = CreateFrame("Frame", nil, r)
    clip:SetAllPoints()
    clip:SetClipsChildren(true)
    local band = CreateFrame("Frame", nil, clip)
    band:SetSize(w, h)
    band:SetPoint("RIGHT", clip, "LEFT")
    local none, peak = CreateColor(1, 1, 1, 0), CreateColor(1, 1, 1, 0.15)
    for half = 1, 2 do
        local t = band:CreateTexture(nil, "ARTWORK")
        t:SetColorTexture(1, 1, 1, 1)
        t:SetSize(w / 2, h)
        t:SetPoint(half == 1 and "LEFT" or "RIGHT")
        t:SetGradient("HORIZONTAL", half == 1 and none or peak, half == 1 and peak or none)
    end
    band:Hide()
    local sweep = band:CreateAnimationGroup()
    sweep.move = sweep:CreateAnimation("Translation")
    sweep.move:SetDuration(2)
    sweep.move:SetSmoothing("IN_OUT")
    sweep:SetScript("OnPlay", function() band:Show() end)
    sweep:SetScript("OnFinished", function() band:Hide() end)
    sweep:SetScript("OnStop", function() band:Hide() end)
    function r.Shimmer()
        sweep:Stop()
        sweep.move:SetOffset(r:GetWidth() + w, 0)
        sweep:Play()
    end
    function r.StopShimmer() sweep:Stop() end
end

-- A 26px (or h) faint band with a black rule on its inner edge, at the top
-- (header) or bottom (footer) of a frame.
function Kit.Strip(frame, edge, h)
    local s = CreateFrame("Frame", nil, frame)
    s:SetPoint(edge .. "LEFT"); s:SetPoint(edge .. "RIGHT")
    s:SetHeight(h or 26)
    Kit.Fill(s, { 1, 1, 1, 0.035 })
    local inner = edge == "TOP" and "BOTTOM" or "TOP"
    local rule = s:CreateTexture(nil, "OVERLAY")
    rule:SetColorTexture(0, 0, 0, 1)
    rule:SetHeight(1)
    rule:SetPoint(inner .. "LEFT"); rule:SetPoint(inner .. "RIGHT")
    return s
end

-- "More below": a small down chevron at the bottom centre of a list, in place
-- of a scroll bar (the wheel scrolls). When it appears it pulses three times
-- (1.5 s each) and then stays lit: blinking that stops within 5 s needs no
-- pause control (WCAG 2.2.2). more:Set(on).
function Kit.More(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(24, 10)
    f:SetPoint("BOTTOM", 0, 1)
    f:SetFrameLevel(parent:GetFrameLevel() + 10)
    Kit.Fill(f, Palette.bgDark)
    Kit.Glyph(f, { { 8, 2, 0, -math.pi / 4, -2.8 }, { 8, 2, 0, math.pi / 4, 2.8 } })
    local pulse = Kit.Pulse(f, 0.25, 0.75)
    f:Hide()
    function f:Set(on)
        if on and not self:IsShown() then self:Show(); pulse:Play()
        elseif not on and self:IsShown() then pulse:Stop(); self:Hide() end
    end
    return f
end

-- Panel header (suite style guide): a 26px band over a black rule; the icon,
-- the two-tone name and the version (yellow for dev / alpha / beta, muted for
-- releases) on the left. Header icons go on the right, close last.
function Kit.Header(frame)
    local head = Kit.Strip(frame, "TOP")
    local mark = head:CreateTexture(nil, "ARTWORK")
    mark:SetSize(16, 16)
    mark:SetPoint("LEFT", 6, 0)
    mark:SetTexture("Interface\\AddOns\\PickupGroup\\icon.png")
    local name = head:CreateFontString(nil, "OVERLAY", "PickupGroupFont")
    name:SetPoint("LEFT", mark, "RIGHT", 6, 0)
    name:SetText("|cffffffffPickup|r|cffb3b3b3Group|r")
    local v = ns.Version()
    local ver = head:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    ver:SetPoint("BOTTOMLEFT", name, "BOTTOMRIGHT", 6, 1)
    ver:SetText(((v:match("%-alpha") or v:match("%-beta") or v:match("^dev")) and "|cffffd84a" or "|cff8c8c8c") .. v .. "|r")
    return head
end

-- Header icon: drawn glyph, white on hover, one-line tooltip.
function Kit.HeaderIcon(parent, bars, tip, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(24, 24)
    local tint = Kit.Glyph(btn, bars)
    btn:SetScript("OnEnter", function(self)
        tint(Palette.on)
        if not ns.Hints() then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(tip)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() tint(Palette.glyphRest); GameTooltip:Hide() end)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Role art on a texture: Blizzard's small role atlas.
local ROLE_ATLAS = { TANK = "roleicon-tiny-tank", HEALER = "roleicon-tiny-healer", DAMAGER = "roleicon-tiny-dps" }
Kit.ROLE_ATLAS = ROLE_ATLAS
function Kit.RoleIcon(tex, role)
    tex:SetAtlas(ROLE_ATLAS[role])
end

-- The accent, read when a frame is painted.
function Kit.Accent() return Palette.accent end

-- Toggle button (AES's "engaged" look): white text both ways; on = an accent
-- fill at 35% behind it, and the tooltip / summary say it in words (WCAG 1.4.1).
-- b:Paint(on). Height 20 unless given (the panel's are AES's 26).
function Kit.Toggle(parent, text, w, onClick, h)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h or 20)
    Kit.Button(b)
    b:SetText(text)
    local fs = b:GetFontString()
    if fs then fs:SetWordWrap(false) end
    local sel = Solid(b, "BORDER", 1, Palette.accent)
    sel:SetPoint("TOPLEFT", 1, -1)
    sel:SetPoint("BOTTOMRIGHT", -1, 1)
    sel:Hide()
    function b:Paint(on)
        local c = Kit.Accent()
        sel:SetColorTexture(c[1], c[2], c[3], Palette.selectA)
        sel:SetShown(on and true or false)
        self.on = on and true or false
    end
    b:SetScript("OnClick", onClick)
    return b
end

-- Checkbox (AES's skinned tickbox): a 14px control box with a black edge, an
-- accent square when ticked, the hover wash; the label is part of the click
-- area. box:Set(on), box:Get(); onChange(on) after a click.
function Kit.Check(parent, label, onChange)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(18)
    b:SetHitRectInsets(0, 0, -3, -3)
    local well = CreateFrame("Frame", nil, b)
    well:SetSize(14, 14)
    well:SetPoint("LEFT")
    Kit.Fill(well, Palette.well)
    Kit.Border(well, Palette.border)
    local wash = Solid(well, "ARTWORK", 1, Palette.hoverWash)
    wash:SetPoint("TOPLEFT", 1, -1)
    wash:SetPoint("BOTTOMRIGHT", -1, 1)
    wash:Hide()
    b:SetScript("OnEnter", function() wash:Show() end)
    b:SetScript("OnLeave", function() wash:Hide() end)
    local mark = well:CreateTexture(nil, "OVERLAY")
    mark:SetPoint("TOPLEFT", 2, -2)
    mark:SetPoint("BOTTOMRIGHT", -2, 2)
    local text = b:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    text:SetPoint("LEFT", well, "RIGHT", 5, 0)
    text:SetWordWrap(false)
    text:SetText(label)
    b:SetWidth(19 + text:GetStringWidth() + 4)
    b.label, b.well = text, well
    local on = false
    function b:Set(v)
        on = v and true or false
        local c = Kit.Accent()
        mark:SetColorTexture(c[1], c[2], c[3], Palette.fillA)
        mark:SetShown(on)
    end
    function b:Get() return on end
    function b:SetLabel(t) text:SetText(t); self:SetWidth(19 + text:GetStringWidth() + 4) end
    b:SetScript("OnClick", function(self) self:Set(not on); onChange(on) end)
    b:Set(false)
    return b
end

-- Text box: control fill, black edge; the accent edge while typing. onCommit(text)
-- on Enter or losing focus. Clears focus when hidden (a hidden focused box eats every key).
function Kit.Edit(parent, width, onCommit, numeric)
    local e = CreateFrame("EditBox", nil, parent)
    e:SetSize(width, 20)
    e:SetAutoFocus(false)
    e:SetFontObject("PickupGroupFontSmall")
    e:SetTextInsets(6, 6, 0, 0)
    if numeric then e:SetNumeric(true) end
    Kit.Fill(e, Palette.well)
    Kit.Border(e, Palette.border)
    -- SetScript drops any hooks already on that script, so set before hooking
    -- (the rest ring after typing never came back while this ran last).
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEditFocusLost", function(self) onCommit(self:GetText()) end)
    e:SetScript("OnHide", function(self) self:ClearFocus() end)
    e:HookScript("OnEditFocusGained", function(self) Ring(self, Kit.Accent()) end)
    e:HookScript("OnEditFocusLost", function(self) Ring(self, Palette.border) end)
    return e
end

-- A thin rule between groups of controls (AES: #2a2a2a).
function Kit.Rule(parent)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetColorTexture(0.165, 0.165, 0.165, 1)
    t:SetHeight(1)
    return t
end

-- A drawn chevron pointing down; tex:SetRotation turns it.
function Kit.Arrow(parent, size)
    local t = parent:CreateTexture(nil, "OVERLAY")
    t:SetSize(size or 10, size or 10)
    t:SetTexture("Interface\\Buttons\\WHITE8x8")
    t:SetTexCoord(0, 1, 0, 1)
    -- Drawn: two bars in a V (pointing down at 0), turned with the same
    -- angles as AES's art (SetRotation, counter-clockwise: right = pi / 2).
    t:SetAlpha(0)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetAllPoints(t)
    local bars, BASE = {}, { { -1.8, -math.pi / 4 }, { 1.8, math.pi / 4 } }
    for i = 1, 2 do
        bars[i] = holder:CreateTexture(nil, "OVERLAY")
        bars[i]:SetSize(6, 1.5)
    end
    function t:SetVertexColor(r, g, b) for _, bar in ipairs(bars) do bar:SetColorTexture(r, g, b, 1) end end
    function t:SetRotation(rad)
        local c, sn = math.cos(rad), math.sin(rad)
        for i, bar in ipairs(bars) do
            local x = BASE[i][1]
            bar:ClearAllPoints()
            bar:SetPoint("CENTER", x * c, x * sn)
            bar:SetRotation(BASE[i][2] + rad)
        end
    end
    function t:SetShown(on) holder:SetShown(on) end
    function t:Show() holder:Show() end
    function t:Hide() holder:Hide() end
    t:SetVertexColor(0.85, 0.85, 0.85)
    t:SetRotation(0)
    return t
end

-- Slider (AES's Min Score): a label above, a 10px track with an accent thumb.
-- s:SetValue(v) without a callback; onChange(v) on a drag, stepped.
function Kit.Slider(parent, width, max, step, label, onChange)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(width, 28)
    local text = holder:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    text:SetPoint("TOPLEFT")
    local s = CreateFrame("Slider", nil, holder)
    s:SetOrientation("HORIZONTAL")
    s:SetHeight(10)
    s:SetPoint("TOPLEFT", 0, -15)
    s:SetPoint("TOPRIGHT", 0, -15)
    s:SetHitRectInsets(0, 0, -6, -6)
    Kit.Fill(s, Palette.bgMedium)
    Kit.Border(s, Palette.border)
    local thumb = s:CreateTexture(nil, "OVERLAY")
    local c = Kit.Accent()
    thumb:SetColorTexture(c[1], c[2], c[3], 1)
    thumb:SetSize(8, 10)
    s:SetThumbTexture(thumb)
    s:SetMinMaxValues(0, max)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    local quiet = false
    local function Show(v) text:SetText(label .. ": " .. (v > 0 and tostring(v) or "Off")) end
    s:SetScript("OnValueChanged", function(_, value)
        local v = math.floor(value / step + 0.5) * step
        Show(v)
        if not quiet then onChange(v) end
    end)
    function holder:SetValue(v) quiet = true; s:SetValue(v or 0); Show(v or 0); quiet = false end
    holder:SetValue(0)
    holder:EnableMouse(true)
    return holder
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
