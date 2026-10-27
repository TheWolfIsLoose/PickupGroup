--[[
    PickupGroup - UI/Kit.lua
    The look, shared by every window: fonts, palette and the style helpers.
    Same visual language as StockClerk (its Dev/STYLE.md): flat fills, 1px
    black lines (grey rings on controls), monochrome (white = on), drawn glyphs, no Blizzard templates.
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
    PickupGroupFontDisabled = { 10, 0.55 },  -- disabled button labels: Small in muted
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
    ringRest  = { 0.4, 0.4, 0.4, 1 },          -- controls at rest: 3.3:1 on the panel (WCAG 1.4.11)
    ringHover = { 0.7, 0.7, 0.7, 1 },          -- control under the mouse
    hoverWash = { 0.851, 0.851, 0.851, 0.15 },
    pressFill = { 0.851, 0.851, 0.851, 0.22 },
    border    = { 0, 0, 0, 1 },                -- window edges, tiles (not controls)
    on        = { 1, 1, 1, 1 },                -- on, live, hover, focus (monochrome suite)
    glyphRest = { 0.7, 0.7, 0.7, 1 },          -- header icons at rest
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
    t.icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)  -- icon border trimmed, plus a ~10% zoom
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

-- Toggle button: on = its colour (white by default) as text and ring plus a
-- 2px bar along the bottom, the same mark as an active sidecar tab, so "on"
-- never rests on colour alone (WCAG 1.4.1). Off: grey text, grey ring.
function Kit.Toggle(parent, text, w, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, 20)
    Kit.Button(b)
    b:SetNormalFontObject("PickupGroupFontSmall")
    b:SetHighlightFontObject("PickupGroupFontSmall")
    b:SetText(text)
    local bar = Solid(b, "OVERLAY", 6, Palette.on)
    bar:SetHeight(2)
    bar:SetPoint("BOTTOMLEFT", 1, 1)
    bar:SetPoint("BOTTOMRIGHT", -1, 1)
    function b:Paint(on, color)
        local c = on and (color or Palette.on) or { 0.55, 0.55, 0.55 }
        self:GetFontString():SetTextColor(c[1], c[2], c[3], 1)
        Ring(self, on and c or Palette.ringRest)
        bar:SetColorTexture(c[1], c[2], c[3], 1)
        bar:SetShown(on)
    end
    b:SetScript("OnClick", onClick)
    return b
end

-- Checkbox: 12px light well (grey ring on hover), white square when on; the label is part of the
-- click area, 24px tall (WCAG 2.5.8: rows of checkboxes sit 24px apart).
-- box:Set(on), box:Get(); onChange(on) after a click.
function Kit.Check(parent, label, onChange)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(16)
    b:SetHitRectInsets(0, 0, -4, -4)
    local well = CreateFrame("Frame", nil, b)
    well:SetSize(12, 12)
    well:SetPoint("LEFT")
    Kit.Fill(well, Palette.well)
    Kit.Border(well, Palette.ringRest)
    b:SetScript("OnEnter", function() Ring(well, Palette.ringHover) end)
    b:SetScript("OnLeave", function() Ring(well, Palette.ringRest) end)
    local mark = well:CreateTexture(nil, "OVERLAY")
    mark:SetSize(8, 8)
    mark:SetPoint("CENTER")
    mark:SetColorTexture(Palette.on[1], Palette.on[2], Palette.on[3], 1)
    local text = b:CreateFontString(nil, "OVERLAY", "PickupGroupFontSmall")
    text:SetPoint("LEFT", well, "RIGHT", 6, 0)
    text:SetText(label)
    b:SetWidth(18 + text:GetStringWidth() + 4)
    b.label = text
    local on = false
    function b:Set(v) on = v and true or false; mark:SetShown(on) end
    function b:Get() return on end
    function b:SetLabel(t) text:SetText(t); self:SetWidth(18 + text:GetStringWidth() + 4) end
    b:SetScript("OnClick", function(self) self:Set(not on); onChange(on) end)
    b:Set(false)
    return b
end

-- Text box: light well + grey ring (grey on hover, white while typing). onCommit(text) on Enter or losing
-- focus. Clears focus when hidden (a hidden focused box eats every key).
function Kit.Edit(parent, width, onCommit, numeric)
    local e = CreateFrame("EditBox", nil, parent)
    e:SetSize(width, 20)
    e:SetAutoFocus(false)
    e:SetFontObject("PickupGroupFontSmall")
    e:SetTextInsets(6, 6, 0, 0)
    if numeric then e:SetNumeric(true) end
    Kit.Fill(e, Palette.well)
    Kit.Border(e, Palette.ringRest)
    -- SetScript drops any hooks already on that script, so set before hooking
    -- (the rest ring after typing never came back while this ran last).
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEditFocusLost", function(self) onCommit(self:GetText()) end)
    e:SetScript("OnHide", function(self) self:ClearFocus() end)
    e:HookScript("OnEnter", function(self) if not self:HasFocus() then Ring(self, Palette.ringHover) end end)
    e:HookScript("OnLeave", function(self) if not self:HasFocus() then Ring(self, Palette.ringRest) end end)
    e:HookScript("OnEditFocusGained", function(self) Ring(self, Palette.on) end)
    e:HookScript("OnEditFocusLost", function(self) Ring(self, self:IsMouseOver() and Palette.ringHover or Palette.ringRest) end)
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
