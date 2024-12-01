local mq = require('mq')
local gui = require('gui')

local DEBUG_MODE = false

-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

-- Healing module
local healing = {}
local charLevel = mq.TLO.Me.Level()
local mainHealSpell = tostring(mq.TLO.Me.Gem(10))
local torporSpell = "Torpor" -- Replace with the exact spell name if different.

-- Check if enough mana exists to cast a spell
local function hasEnoughMana(spellName)
    debugPrint("Checking mana for spell:", spellName)
    return spellName and mq.TLO.Me.CurrentMana() >= mq.TLO.Spell(spellName).Mana()
end

-- Perform pre-cast checks
local function preCastChecks()
    debugPrint("Moving: ", mq.TLO.Me.Moving(), "Casting: ", mq.TLO.Me.Casting())
    if mq.TLO.Me.Moving() or mq.TLO.Me.Casting() ~= "nil" then
        debugPrint("Cannot cast spell while moving or casting")
        return false
    else
        return true
    end
end

-- Determine if target is within spell range
local function isTargetInRange(targetID, spellName)
    local target = mq.TLO.Spawn(targetID)
    local spellRange = mq.TLO.Spell(spellName).Range()
    if target and target.Distance() and spellRange then
        debugPrint("Checking range for target with spell:", spellName)
        return target.Distance() <= spellRange
    else
        debugPrint("Target or spell range not available")
        return false
    end
end

-- Verify if a target ID belongs to a group member
local function isGroupMember(targetID)
    debugPrint("Checking if target is a group member:", targetID)
    for i = 0, 5 do
        if mq.TLO.Group.Member(i).ID() == targetID then
            return true
        end
    end
    return false
end

-- Check if Torpor is already active
local function isTorporActive()
    if mq.TLO.Me.Song(torporSpell)() then
        debugPrint("Torpor is already active")
        return true
    end
    return false
end

-- Cast a spell on a specific target
local function castSpell(targetID, targetName, spellName)
    if targetID ~= mq.TLO.Target.ID() then
        debugPrint("Targeting:", targetName)
        mq.cmdf('/tar ID %s', targetID)
        mq.delay(200)
    end

    if targetID == mq.TLO.Target.ID() then
        debugPrint("Casting spell:", spellName, "on target:", targetName)
        mq.cmdf('/dgtell ALL Casting %s on %s', spellName, targetName)
        mq.cmdf('/cast %s', spellName)
        mq.delay(100)
    end

    while mq.TLO.Me.Casting() do
        if gui.stopCast and mq.TLO.Target() and mq.TLO.Target.PctHPs() >= 95 then
            debugPrint("Stopping cast: target HP above 95%")
            mq.cmd('/stopcast')
            break
        end
        mq.delay(10)
    end
end

-- Process self-healing logic
local function processSelfHealing()

    if gui.emergencyheal and mq.TLO.Me.PctHPs() <= gui.emergencyhealpct then
        debugPrint("Emergency heal triggered for self")
        if preCastChecks() and mq.TLO.Me.SpellReady(mainHealSpell)() and isTargetInRange(mq.TLO.Me.ID(), mainHealSpell) and hasEnoughMana(mainHealSpell) then
            castSpell(mq.TLO.Me.ID(), mq.TLO.Me.Name(), mainHealSpell)
        elseif not mq.TLO.Me.SpellReady(mainHealSpell)() and hasEnoughMana(mainHealSpell) then
            while not mq.TLO.Me.SpellReady(mainHealSpell)() do
                mq.delay(50)
            end
            if mq.TLO.Me.SpellReady(mainHealSpell)() then
                castSpell(mq.TLO.Me.ID(), mq.TLO.Me.Name(), mainHealSpell)
            end
        end
    elseif gui.torporOn and charLevel >= 59 and mq.TLO.Me.PctHPs() <= gui.torporpct and not isTorporActive() then
        debugPrint("Torpor triggered for self")
        if mq.TLO.Me.SpellReady(torporSpell)() and hasEnoughMana(torporSpell) then
            debugPrint("Casting Torpor on self - 2")
            castSpell(mq.TLO.Me.ID(), mq.TLO.Me.Name(), torporSpell)
        elseif not mq.TLO.Me.SpellReady(torporSpell)() and hasEnoughMana(torporSpell) then
            while not mq.TLO.Me.SpellReady(torporSpell)() do
                mq.delay(50)
            end
            if mq.TLO.Me.SpellReady(torporSpell)() then
                debugPrint("Casting Torpor on self - 3")
                castSpell(mq.TLO.Me.ID(), mq.TLO.Me.Name(), torporSpell)
            end
        end
    else
        debugPrint("Torpor not needed or already active or off")
        return
    end
end

-- Process healing logic for a target
local function processHealsForTarget(targetID, targetName, targetHP, targetClass, isExtendedTarget, extIndex)
    local isPlayer = targetID == mq.TLO.Me.ID()
    local mainHealThreshold = (isExtendedTarget and gui["ExtTargetMainHeal" .. extIndex .. "Pct"]) or gui.mainHealPct

    targetHP = targetHP or 0
    mainHealThreshold = mainHealThreshold or 100

    if isPlayer then
        debugPrint("Processing self-healing logic")
        processSelfHealing()
        return
    end

    if gui.mainHeal and targetHP <= mainHealThreshold then
        debugPrint("Processing heal for:", targetName)
        if preCastChecks() and mq.TLO.Me.SpellReady(mainHealSpell)() and 
           isTargetInRange(targetID, mainHealSpell) and hasEnoughMana(mainHealSpell) then
            castSpell(targetID, targetName, mainHealSpell)
        end
    end
end

-- Main healing routine
function healing.healRoutine()
    if not gui.botOn or not (gui.mainHeal or gui.torporOn) then return end
    debugPrint("Starting healing routine")

    -- Group member healing
    for i = 0, 5 do
        local member = mq.TLO.Group.Member(i)
        if member and not member.Dead() then
            processHealsForTarget(member.ID(), member.Name(), member.PctHPs(), member.Class.ShortName(), false, i)
        end
    end

    -- Extended target healing
    local anyExtendedHealEnabled = false
    for extIndex = 1, 5 do
        if gui["ExtTargetMainHeal" .. extIndex] then
            anyExtendedHealEnabled = true
            break
        end
    end

    if anyExtendedHealEnabled then
        for extIndex = 1, 5 do
            local extTarget = mq.TLO.Me.XTarget(extIndex)
            if extTarget and extTarget.ID() and not extTarget.Dead() and 
               (extTarget.Type() == "PC" or extTarget.Type() == "Pet") then
                local extID, extName, extPctHP, extClass = extTarget.ID(), extTarget.CleanName(), extTarget.PctHPs(), extTarget.Class.ShortName()
                if not isGroupMember(extID) then
                    if gui["ExtTargetMainHeal" .. extIndex] and extPctHP <= gui["ExtTargetMainHeal" .. extIndex .. "Pct"] then
                        processHealsForTarget(extID, extName, extPctHP, extClass, true, extIndex)
                    end
                else
                    debugPrint("Extended target is already a group member:", extName)
                end
            end
        end
    end
    mq.delay(50)
end

return healing
