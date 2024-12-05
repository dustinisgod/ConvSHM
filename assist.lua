local mq = require('mq')
local gui = require('gui')
local utils = require('utils')
local spells = require('spells')
local malo = require('malo')
local slow = require('slow')
local cripple = require('cripple')

local DEBUG_MODE = false
-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

local assist = {}
local charName = mq.TLO.Me.Name()
local charLevel = mq.TLO.Me.Level()

local function hasEnoughMana(spellName)
    local manaCheck = spellName and mq.TLO.Me.CurrentMana() >= mq.TLO.Spell(spellName).Mana()
    debugPrint("Checking mana for spell:", spellName, "Has enough mana:", manaCheck)
    return manaCheck
end

local function inRange(spellName)
    local rangeCheck = mq.TLO.Target() and spellName and mq.TLO.Target.Distance() <= mq.TLO.Spell(spellName).Range() or false
    debugPrint("Checking range for spell:", spellName, "In range:", rangeCheck)
    return rangeCheck
end

local function currentlyActive(spell)
    if not mq.TLO.Target() then
        print("No target selected.")
        return false -- No target to check
    end

    local spellName = mq.TLO.Spell(spell).Name()
    if not spellName then
        print("Spell not found:", spell)
        return false -- Spell doesn't exist or was not found
    end

    -- Safely get the buff count with a default of 0 if nil
    local buffCount = mq.TLO.Target.BuffCount() or 0
    for i = 1, buffCount do
        if mq.TLO.Target.Buff(i).Name() == spellName then
            debugPrint("DEBUG: Spell is active on the target.")
            if mq.TLO.Target.Buff(spellName).Caster() == charName then
                debugPrint("DEBUG: Spell is active on the target and was cast by the character.")
                return true -- Spell is active on the target
            else
                debugPrint("DEBUG: Spell is active on the target but was not cast by the character.")
                return false
            end
        else
            debugPrint("DEBUG: Spell is not active on the target.")
            return false
        end
    end
end

local function handleDot(guiSetting, spellType, minLevel, gemSlot)
    debugPrint("DEBUG: Entering handleDot()")
    local spellName = tostring(spells.findBestSpell(spellType, charLevel))
    if guiSetting and charLevel >= minLevel then
        debugPrint("DEBUG: Checking for dot:", spellName)
        if mq.TLO.Me.PctMana() < 10 then
            debugPrint("DEBUG: Not enough mana to cast dot.")
            return
        end

        if not hasEnoughMana(spellName) then
            debugPrint("DEBUG: Not enough mana to cast dot.")
            return
        end

        if not inRange(spellName) then
            debugPrint("DEBUG: Target is not in range to cast dot.")
            return
        end

        if currentlyActive(spellName) then
            debugPrint("DEBUG: Dot is already active on the target.")
            return
        end

        if spellType == "PoisonDot" then
            if gui.PoisonDotNamedOnly and not mq.TLO.Target.Named() then
                debugPrint("DEBUG: Target is not named.")
                return
            end
        elseif spellType == "DiseaseDot" then
            if gui.DiseaseDotNamedOnly and not mq.TLO.Target.Named() then
                debugPrint("DEBUG: Target is not named.")
                return
            end
        end

        if mq.TLO.Me.Gem(gemSlot)() ~= spellName then
            debugPrint("DEBUG: Loading and memorizing dot spell in slot:", gemSlot)
            spells.loadAndMemorizeSpell(spellType, charLevel, gemSlot)
        end

        local readyAttempt = 0
        while not mq.TLO.Me.SpellReady(spellName)() and readyAttempt < 20 do
            debugPrint("DEBUG: Waiting for dot spell to be ready, attempt:", readyAttempt)
            readyAttempt = readyAttempt + 1
            mq.delay(500)
        end

        debugPrint("DEBUG: Casting dot spell:", spellName)
        mq.cmdf("/cast %s", spellName)
        mq.delay(100)

        while mq.TLO.Me.Casting() do
            debugPrint("DEBUG: Casting dot spell:", spellName)
            if spellType == "PoisonDot" and mq.TLO.Target() and mq.TLO.Target.PctHPs() < gui.PoisonDotStopPct and not mq.TLO.Target.Named() and not mq.TLO.Target.Dead() then
                debugPrint("DEBUG: Stopping cast: target HP above 95%")
                mq.cmd('/stopcast')
                break
            elseif spellType == "DiseaseDot" and mq.TLO.Target() and mq.TLO.Target.PctHPs() < gui.DiseaseDotStopPct and not mq.TLO.Target.Named() and not mq.TLO.Target.Dead() then
                debugPrint("DEBUG: Stopping cast: target HP above 95%")
                mq.cmd('/stopcast')
                break
            end
            mq.delay(10)
        end
    else
        debugPrint("DEBUG: Dot is not enabled or character level is too low.")
        return
    end
end

function assist.assistRoutine()
    debugPrint("DEBUG: Entering assistRoutine()")

    if not gui.botOn and not gui.assistOn then
        debugPrint("DEBUG: Bot or assist is not enabled.")
        return
    end

    -- Use reference location to find mobs within assist range
    local mobsInRange = utils.referenceLocation(gui.assistRange) or {}
    if #mobsInRange == 0 then
        debugPrint("DEBUG: No mobs found within assist range.")
        return
    end

    -- Check if the main assist is a valid PC, is alive, and is in the same zone
    local mainAssistSpawn = mq.TLO.Spawn(gui.mainAssist)
    if mainAssistSpawn and mainAssistSpawn.Type() == "PC" and not mainAssistSpawn.Dead() then
        debugPrint("DEBUG: Main assist is a valid PC and is alive.")
        mq.cmdf("/assist %s", gui.mainAssist)
        mq.delay(200)
    else
        debugPrint("DEBUG: Main assist is not a valid PC or is dead.")
        return
    end

    if mq.TLO.Target() and mq.TLO.Target.Type() == "NPC" then
        debugPrint("DEBUG: Target is an NPC.")

        -- Assuming you have a target's name to check against the lists
        local targetName = mq.TLO.Target.Name()

        if mq.TLO.Target() and gui.maloOn and not utils.maloConfig[targetName] then
            debugPrint("DEBUG: Malo is enabled and target is not in the maloConfig list.")
            if mq.TLO.Target() and not mq.TLO.Target.Maloed() and mq.TLO.Target.PctHPs() >= gui.maloStopPercent then
                debugPrint("DEBUG: Target is not maloed.")
                malo.maloRoutine()
            end
        end

        if mq.TLO.Target() and gui.slowOn and not utils.slowConfig[targetName] then
            debugPrint("DEBUG: Slow is enabled and target is not in the slowConfig list.")
            if mq.TLO.Target() and not mq.TLO.Target.Slowed() and mq.TLO.Target.PctHPs() >= gui.slowStopPercent then
                debugPrint("DEBUG: Target is not slowed.")
                slow.slowRoutine()
            end
        end

        if mq.TLO.Target() and gui.crippleOn and not utils.crippleConfig[targetName] then
            debugPrint("DEBUG: Cripple is enabled and target is not in the crippleConfig list.")
            if mq.TLO.Target() and not mq.TLO.Target.Crippled() and mq.TLO.Target.PctHPs() >= gui.crippleStopPercent then
                debugPrint("DEBUG: Target is not crippled.")
                cripple.crippleRoutine()
            end
        end

        if mq.TLO.Target() and mq.TLO.Target.PctHPs() <= gui.assistPercent and mq.TLO.Target.Distance() <= gui.assistRange and not mq.TLO.Target.Mezzed() and gui.petOn and mq.TLO.Pet.IsSummoned() then
            debugPrint("DEBUG: Target is below assist percent and within assist range. - pet")
            mq.cmd("/squelch /pet attack")
            debugPrint("DEBUG: Pet attack is on.")
        elseif mq.TLO.Target() and gui.petOn and mq.TLO.Pet.IsSummoned() and mq.TLO.Me.Pet.Combat() and (mq.TLO.Target.Mezzed() or mq.TLO.Target.PctHPs() > gui.assistPercent or mq.TLO.Pet.Distance() > gui.assistRange) then
            debugPrint("DEBUG: Target is mezzed, above assist percent, or out of assist range.")
            mq.cmd("/squelch /pet back off")
        end

        if mq.TLO.Target() and mq.TLO.Target.PctHPs() <= gui.assistPercent and mq.TLO.Target.Distance() <= gui.assistRange and not mq.TLO.Target.Mezzed() then
            debugPrint("DEBUG: Target is below assist percent and within assist range - Dots.")
            if mq.TLO.Target() and mq.TLO.Target.PctHPs() >= gui.PoisonDotStopPct and gui.PoisonDotOn then
                debugPrint("DEBUG: Checking for poison dot.")
                handleDot(gui.PoisonDotOn, "PoisonDot", 8, 4)
            end
            if mq.TLO.Target() and mq.TLO.Target.PctHPs() >= gui.DiseaseDotStopPct and gui.DiseaseDotOn then
                debugPrint("DEBUG: Checking for disease dot.")
                handleDot(gui.DiseaseDotOn, "DiseaseDot", 4, 5)
            end
        end
    else
        debugPrint("DEBUG: Target is not an NPC.")
        return
    end
end

return assist