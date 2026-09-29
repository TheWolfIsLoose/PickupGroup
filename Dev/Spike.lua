--[[
    PickupGroup - Dev/Spike.lua  (THROWAWAY: Phase 1 in-game tests; delete
    with its TOC line once the answers are in the roadmap)

    /pug spike opens a small test bar under the Group Finder:
      Cover   1a  our opaque frame over Blizzard's search panel, on / off
      Dialog  1b  open Blizzard's sign-up dialog for the selected group,
                  then press Blizzard's own Sign Up in it
      Direct  1b' sign up to the selected group straight from our click
      Search  1c  run a search from our click; the log records the time
                  since the previous search and whether it was refused
    Select a group in Blizzard's list first (Cover off) for Dialog/Direct.
    Everything lands in /pug log; blocked actions are logged by Core.
--]]

local _, ns = ...
local Kit = ns.Kit

local Spike = {}
ns.Spike = Spike

local bar, cover
local lastSearch  -- GetTime() of the previous search, any source
local ours = false

local function Note(fmt, ...)
    ns.Log.Emit("spike", { text = fmt:format(...) })
end

local function Panel() return LFGListFrame and LFGListFrame.SearchPanel end

local function Selected()
    local p = Panel()
    local id = p and p.selectedResult
    if not id then Note("no group selected in Blizzard's list") end
    return id
end

local function MyRoles()
    local spec = GetSpecialization()
    local role = spec and GetSpecializationRole(spec) or "DAMAGER"
    return role == "TANK", role == "HEALER", role == "DAMAGER"
end

local function Button(label, x, onClick)
    local b = CreateFrame("Button", nil, bar)
    b:SetSize(64, 22)
    b:SetPoint("LEFT", x, 0)
    Kit.Button(b)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    return b
end

-- 1a: our frame over Blizzard's search panel; Blizzard's frames untouched.
local function ToggleCover()
    local p = Panel()
    if not p then return Note("cover: search panel not found") end
    if not cover then
        cover = CreateFrame("Frame", nil, p)
        cover:SetAllPoints(p)
        cover:SetFrameLevel(p:GetFrameLevel() + 50)
        cover:EnableMouse(true)
        Kit.Fill(cover, Kit.Palette.bgDark)
        Kit.Border(cover)
        local t = cover:CreateFontString(nil, "OVERLAY", "PickupGroupFontLarge")
        t:SetPoint("CENTER")
        t:SetText("|cff98ff98Pickup|rGroup cover (spike)")
        cover:Hide()
    end
    cover:SetShown(not cover:IsShown())
    Note("cover %s (panel level %d)", cover:IsShown() and "on" or "off", p:GetFrameLevel())
end

-- 1b: Blizzard's own dialog, opened by our click.
local function OpenDialog()
    local id = Selected()
    if not id then return end
    if not LFGListApplicationDialog_Show then return Note("dialog: LFGListApplicationDialog_Show missing") end
    local ok, err = pcall(LFGListApplicationDialog_Show, LFGListApplicationDialog, id)
    Note("dialog opened for result %s: ok %s %s. Now press Blizzard's Sign Up.", id, tostring(ok), err and tostring(err) or "")
end

-- 1b': the sign-up call straight from our click.
local function Direct()
    local id = Selected()
    if not id then return end
    local t, h, d = MyRoles()
    local ok, err = pcall(C_LFGList.ApplyToGroup, id, t, h, d)
    Note("direct sign-up to result %s (tank %s heal %s dps %s): ok %s %s", id, tostring(t), tostring(h), tostring(d),
        tostring(ok), err and tostring(err) or "")
end

-- 1c: a search from our click, through Blizzard's own search function.
local function Search()
    local p = Panel()
    if not (p and LFGListSearchPanel_DoSearch) then return Note("search: panel or function missing") end
    ours = true
    local ok, err = pcall(LFGListSearchPanel_DoSearch, p)
    ours = false
    if not ok then Note("search error: %s", tostring(err)) end
end

local function Build()
    Kit.ApplyFontFace()
    bar = CreateFrame("Frame", nil, PVEFrame)
    bar:SetSize(4 * 68 + 8, 30)
    bar:SetPoint("TOPRIGHT", PVEFrame, "BOTTOMRIGHT", 0, -30)
    Kit.Fill(bar, Kit.Palette.panelBg)
    Kit.Border(bar)
    Button("Cover", 4, ToggleCover)
    Button("Dialog", 72, OpenDialog)
    Button("Direct", 140, Direct)
    Button("Search", 208, Search)

    -- Every search, ours or Blizzard's, with the gap since the one before.
    hooksecurefunc("LFGListSearchPanel_DoSearch", function()
        local now = GetTime()
        Note("search sent by %s, %s since the previous one", ours and "our click" or "Blizzard",
            lastSearch and ("%.1fs"):format(now - lastSearch) or "first")
        lastSearch = now
    end)
    ns.On("LFG_LIST_SEARCH_RESULTS_RECEIVED", function()
        Note("search results received, %s groups", tostring((C_LFGList.GetFilteredSearchResults())))
    end)
    ns.On("LFG_LIST_SEARCH_FAILED", function(reason)
        Note("search FAILED: %s, %s after it was sent", tostring(reason),
            lastSearch and ("%.1fs"):format(GetTime() - lastSearch) or "?")
    end)
    ns.On("LFG_LIST_APPLICATION_STATUS_UPDATED", function(id, new, old, name)
        Note("application %s: %s -> %s (%s)", tostring(id), tostring(old), tostring(new), tostring(name))
    end)
    Note("spike bar built")
end

function Spike.Toggle()
    if not PVEFrame then return ns.Print("Open the Group Finder first.") end
    if not bar then Build() else bar:SetShown(not bar:IsShown()) end
end
