--[[
    PickupGroup - Week.lua
    This week at a glance, for the panel: Mythic+ runs and the Great Vault,
    raid lockouts, and the week's affixes. Reads the game; draws only
    tooltips.
--]]

local _, ns = ...

local Week = {}
ns.Week = Week

local GREY, WHITE = { 0.55, 0.55, 0.55 }, { 1, 1, 1 }

-- This week's runs, newest first: { level, code, timed }.
function Week.Runs()
    local out = {}
    local history = C_MythicPlus.GetRunHistory and C_MythicPlus.GetRunHistory(false, true) or {}
    for _, run in ipairs(history) do
        local name = run.mapChallengeModeID and C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID)
        out[#out + 1] = { level = run.level or 0, code = name and ns.Groups.Code(name) or "?", timed = run.completed == true }
    end
    return out
end

-- "0 Runs", "1 Run", "4 Runs".
function Week.RunsLabel()
    local n = #Week.Runs()
    return n .. (n == 1 and " Run" or " Runs")
end

local function Accent() return ns.Kit.Accent() end

-- Hover on the Runs button: each run, then the vault's three Mythic+ slots.
function Week.RunsTooltip(owner)
    local runs = Week.Runs()
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:SetText(#runs == 0 and "No Mythic+ Runs This Week" or (Week.RunsLabel() .. " This Week"), 1, 1, 1)
    for _, r in ipairs(runs) do
        local c = r.timed and WHITE or GREY
        GameTooltip:AddDoubleLine("+" .. r.level .. " " .. r.code, r.timed and "timed" or "over time",
            1, 1, 1, c[1], c[2], c[3])
    end
    -- Vault slots open at the 1st, 4th and 8th best run; each rewards the
    -- item level of that run's key.
    local levels = {}
    for _, r in ipairs(runs) do levels[#levels + 1] = r.level end
    table.sort(levels, function(a, b) return a > b end)
    GameTooltip:AddLine(" ")
    local a = Accent()
    GameTooltip:AddLine("Great Vault", a[1], a[2], a[3])
    for _, slot in ipairs({ 1, 4, 8 }) do
        local lvl = levels[slot]
        local label = slot .. (slot == 1 and " run" or " runs")
        if lvl then
            local ilvl = C_MythicPlus.GetRewardLevelForDifficultyLevel and select(2, C_MythicPlus.GetRewardLevelForDifficultyLevel(lvl))
            GameTooltip:AddDoubleLine(label, ilvl and ("+" .. lvl .. "  (" .. ilvl .. ")") or ("+" .. lvl), 1, 1, 1, 1, 1, 1)
        else
            GameTooltip:AddDoubleLine(label, (slot - #levels) .. " to go", GREY[1], GREY[2], GREY[3], GREY[1], GREY[2], GREY[3])
        end
    end
    if ns.Hints() then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click for your sign-up history.", GREY[1], GREY[2], GREY[3])
    end
    GameTooltip:Show()
end

-- Raid lockouts this week: { name, diff, done, total, reset (seconds) }.
function Week.Lockouts()
    local out = {}
    for i = 1, GetNumSavedInstances() do
        local name, _, reset, _, locked, _, _, isRaid, _, diffName, total, done = GetSavedInstanceInfo(i)
        if isRaid and locked and name then
            out[#out + 1] = { name = name, diff = diffName or "", done = done or 0, total = total or 0, reset = reset }
        end
    end
    table.sort(out, function(x, y) if x.name ~= y.name then return x.name < y.name end return x.diff < y.diff end)
    return out
end

-- Hover on the Lockouts button: each raid with its kills per difficulty, then the reset.
function Week.LockoutsTooltip(owner)
    local list = Week.Lockouts()
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:SetText("Raid Lockouts", 1, 1, 1)
    if #list == 0 then
        GameTooltip:AddLine("Not saved to any raid this week.", GREY[1], GREY[2], GREY[3])
    end
    local last, reset
    for _, l in ipairs(list) do
        if l.name ~= last then
            local a = Accent()
            GameTooltip:AddLine(l.name, a[1], a[2], a[3])
            last = l.name
        end
        GameTooltip:AddDoubleLine("  " .. l.diff, l.done .. "/" .. l.total, 1, 1, 1, 1, 1, 1)
        reset = reset or l.reset
    end
    local left = reset or (C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset())
    if left and left > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Resets in " .. SecondsToTime(left, true), GREY[1], GREY[2], GREY[3])
    end
    GameTooltip:Show()
end

-- This week's affixes: { id, name, desc, icon }.
function Week.Affixes()
    local out = {}
    for _, a in ipairs(C_MythicPlus.GetCurrentAffixes() or {}) do
        local name, desc, icon = C_ChallengeMode.GetAffixInfo(a.id)
        if name then out[#out + 1] = { id = a.id, name = name, desc = desc, icon = icon } end
    end
    return out
end

-- Hover on the single affix icon: every affix this week, name and what it does.
function Week.AffixTooltip(owner)
    local list = Week.Affixes()
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:SetText("This Week's Affixes", 1, 1, 1)
    if #list == 0 then GameTooltip:AddLine("Not known yet.", GREY[1], GREY[2], GREY[3]) end
    for _, a in ipairs(list) do
        GameTooltip:AddLine("|T" .. a.icon .. ":14:14:0:0:64:64:5:59:5:59|t " .. a.name, 1, 1, 1)
        if a.desc then GameTooltip:AddLine(a.desc, 0.74, 0.74, 0.74, true) end
    end
    GameTooltip:Show()
end
