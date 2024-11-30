local mq = require('mq')
local healing = require('healing')
local utils = require('utils')
local gui = require('gui')
local spells = require('spells')
local canni = require('canni')

local cures = {}

-- Configuration
local cureQueue = {}  -- Queue for curing members
local MAX_CURE_RETRIES = 3  -- Maximum retries for each cure attempt
local charLevel = mq.TLO.Me.Level() or 0

local function isGroupMember(targetID)
    for i = 1, mq.TLO.Group.Members() do
        if mq.TLO.Group.Member(i).ID() == targetID then
            return true
        end
    end
    return false
end

-- Function to handle the heal routine and return
local function handleHealRoutineAndReturn()
    healing.healRoutine()
    canni.canniRoutine()
    utils.monitorNav()
    return true
end

-- Function to check if a target is afflicted and return the best cure spell
local function getCureSpell(afflictionType)
    if afflictionType == "Poison" then
        return spells.findBestSpell("CurePoison", charLevel)
    elseif afflictionType == "Disease" then
        return spells.findBestSpell("CureDisease", charLevel)
    end
end

-- Function to check if the cure spell is ready and mana is sufficient
local function preCureChecks()
    return not mq.TLO.Me.Moving() and not mq.TLO.Me.Casting() and mq.TLO.Me.PctMana() >= 20
end

-- Helper function: Check if we have enough mana to cast the spell
local function hasEnoughMana(spellName)
    if not spellName then return false end
    return mq.TLO.Me.CurrentMana() >= mq.TLO.Spell(spellName).Mana()
end

-- Check if target is within spell range, safely handling nil target
local function isTargetInRange(targetID, spellName)
    local target = mq.TLO.Spawn(targetID)
    local spellRange = mq.TLO.Spell(spellName).Range()

    -- Check if both target and spell range exist to avoid nil errors
    if target and target.Distance() and spellRange then
        return target.Distance() <= spellRange
    else
        return false  -- Return false if the target doesn't exist or range can't be determined
    end
end

local function queueAfflictedMembers()

    for i = 1, mq.TLO.Group.Members() do
        local member = mq.TLO.Group.Member(i)
        local memberID = member and member.ID()

        if not memberID then
            goto continue
        end

        if not handleHealRoutineAndReturn() then return end

        -- Target the member and check for poison or disease afflictions
        mq.cmdf('/tar id %s', memberID)
        mq.delay(200)


        if mq.TLO.Target.Poisoned() and charLevel >= 2 then
            table.insert(cureQueue, {name = member.Name(), type = "Poison"})
        elseif mq.TLO.Target.Diseased() and charLevel >= 2 then
            table.insert(cureQueue, {name = member.Name(), type = "Disease"})
        end

        ::continue::
    end

    -- Loop through each extended target slot if enabled in GUI
    for extIndex = 1, 5 do
        if gui["ExtTargetCure" .. extIndex] then
            local extTarget = mq.TLO.Me.XTarget(extIndex)
            local extID = extTarget and extTarget.ID()

            -- Only check if valid and not a group member
            if extID and not isGroupMember(extID) then
                mq.cmdf('/tar id %s', extID)
                mq.delay(200)


                if mq.TLO.Target.Poisoned() and charLevel >= 22 then
                    table.insert(cureQueue, {name = extTarget.CleanName(), type = "Poison"})
                elseif mq.TLO.Target.Diseased() and charLevel >= 4 then
                    table.insert(cureQueue, {name = extTarget.CleanName(), type = "Disease"})
                end
            end
        end
    end
end

-- Process the queue by affliction type using the cureQueue generated in queueAfflictedMembers
local function processCureQueueByType(afflictionType)
    if gui.botOn then
        for i = #cureQueue, 1, -1 do
            local entry = cureQueue[i]
            if entry.type == afflictionType then

                if not handleHealRoutineAndReturn() then return end
                
                local memberName = entry.name
                local spell = getCureSpell(afflictionType)

                -- Target the member to check if they are still afflicted
                mq.cmdf('/target %s', memberName)
                mq.delay(200)  -- Short delay to ensure targeting is complete

                -- Verify if the target is still afflicted with the specific type
                local stillAfflicted = (afflictionType == "Poison" and mq.TLO.Target.Poisoned()) or 
                                       (afflictionType == "Disease" and mq.TLO.Target.Diseased())
                
                -- Remove from queue if no longer afflicted
                if not stillAfflicted then
                    table.remove(cureQueue, i)
                    goto continue  -- Skip to the next member if not afflicted
                end

                -- Proceed to cast if they are still afflicted
                if spell and preCureChecks() then
                    -- Determine the gem slot based on the affliction type
                    
                    -- Memorize the spell if it is not already memorized in the correct slot
                    if mq.TLO.Me.Gem(6).Name() ~= spell then
                        spells.loadAndMemorizeSpell(afflictionType == "Poison" and "CurePoison" or "CureDisease", charLevel, 6)
                    end

                    -- Wait for the spell to be ready
                    local maxReadyAttempts = 10
                    local readyAttempt = 0
                    while not mq.TLO.Me.SpellReady(spell)() and readyAttempt < maxReadyAttempts do
                        mq.delay(1000) -- Wait 1 second before checking again
                        readyAttempt = readyAttempt + 1
                    end
                    
                    if not mq.TLO.Me.SpellReady(spell)() then
                        break
                    end

                    -- Attempt to cure the member
                    local retryCount = 0
                    while retryCount < MAX_CURE_RETRIES do
                        if not hasEnoughMana(spell) then
                            break
                        elseif not isTargetInRange(memberName, spell) then
                            break
                        end

                        mq.cmdf('/target %s', memberName)
                        mq.delay(200)
                        if mq.TLO.Target.CleanName() == memberName then
                            -- Cast using the determined slot (6 for Poison, 7 for Disease)
                            mq.cmdf('/cast %d', 6)
                            while mq.TLO.Me.Casting() do
                                mq.delay(50)
                            end
                            mq.delay(100)
                            table.remove(cureQueue, i)  -- Remove cured member from queue
                            break
                        else
                            retryCount = retryCount + 1
                        end
                    end
                end
            end
            ::continue::
        end
    end
end

-- Main function to monitor and cure afflicted members
function cures.curesRoutine()
    if gui.botOn then
        if gui.useCures then

            if mq.TLO.Me.PctMana() < 20 then
                return
            end

            -- Queue all afflicted members and randomize the queue
            queueAfflictedMembers()

            -- Process each affliction type in turn
            processCureQueueByType("Poison")
            processCureQueueByType("Disease")
        else
            mq.delay(50)
            return
        end
    end
end

return cures