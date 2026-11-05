--[[
    PickupGroup - AES.lua
    What PickupGroup needs to know about atrocityEssentials (AES), which
    carries PickupGroup's group finding as its own Group Finder:
      - An AES build with that Group Finder, switched on, does PickupGroup's
        whole job: PickupGroup steps aside and offers, at login, to turn
        itself off.
      - An older AES's Group Finder Panel sits in the same spot as our panel:
        the clash prompt offers to turn it off.
      - AES's LFG Reminder offers the full-group teleport itself: ours gives way.
    Only reads AES's saved settings (and writes the one panel switch when the
    player says so).
--]]

local addonName, ns = ...

local AES = {}
ns.AES = AES

local function Misc()
    local ae = _G.atrocityEssentials
    local p = type(ae) == "table" and ae.db and ae.db.profile
    return type(p) == "table" and p.Miscellaneous or nil
end

local function Finder()
    local ae = _G.atrocityEssentials
    if type(ae) ~= "table" or not ae.GetModule then return nil end
    local ok, m = pcall(ae.GetModule, ae, "GroupFinderPanel", true)
    return ok and type(m) == "table" and m or nil
end

-- An AES whose Group Finder carries PickupGroup's (it says so with
-- `mergedFilters`), switched on.
function AES.Merged()
    local m = Finder()
    local db = m and m.mergedFilters ~= nil and type(m.db) == "table" and m.db
    return db and db.Enabled == true or false
end

-- PickupGroup's list, panel, leader view and quick list stay out of the way.
function ns.SteppedAside() return AES.Merged() end

-- An older AES's own Group Finder Panel, on: a sentence for the clash prompt.
function AES.PanelClash()
    if ns.clashHold.aesPanelConflict then return ns.clashHold.aesPanelConflict end
    if AES.Merged() then return nil end
    local m = Misc()
    if m and type(m.GroupFinderPanel) == "table" and m.GroupFinderPanel.Enabled == true then
        return "atrocityEssentials' Group Finder Panel is on"
    end
end

function AES.SetPanel(on)
    local m = Misc()
    if m and type(m.GroupFinderPanel) == "table" then m.GroupFinderPanel.Enabled = on and true or false end
end

function AES.ReminderOn()
    local m = Misc()
    return m and type(m.LFGReminder) == "table" and m.LFGReminder.Enabled == true or false
end

-- At login: offer to turn PickupGroup off (every login until it is).
StaticPopupDialogs.PICKUPGROUP_MERGED = {
    text = "atrocityEssentials' Group Finder now does everything PickupGroup does, and it's on.\n\nTurn PickupGroup off? (The game reloads.)",
    button1 = "Turn Off PickupGroup",
    button2 = "Not Now",
    OnAccept = function()
        ns.Log.Emit("setting", { key = "turned off for AES Group Finder", on = true })
        C_AddOns.DisableAddOn(addonName)
        C_UI.Reload()
    end,
    OnCancel = function() ns.Log.Emit("setting", { key = "turned off for AES Group Finder", on = false }) end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

ns.On("PLAYER_LOGIN", function()
    C_Timer.After(3, function()
        if not AES.Merged() then return end
        ns.Print("atrocityEssentials' Group Finder is on, so PickupGroup is staying out of its way.")
        StaticPopup_Show("PICKUPGROUP_MERGED")
    end)
end)
