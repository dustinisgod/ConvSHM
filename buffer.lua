local mq = require('mq')
local spells = require('spells')
local gui = require('gui')
local utils = require('utils')
local healing = require('healing')
local canni = require('canni')

local buffer = {}
buffer.buffQueue = {}

local charLevel = mq.TLO.Me.Level()

local DEBUG_MODE = false
-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

-- Define which classes are eligible for each buff type
local buffEligibleClasses = {
    HasteBuff = {WAR = true, MNK = true, ROG = true, PAL = true, SHD = true, BRD = true, BST = true, BER = true},
    StrBuff = {WAR = true, MNK = true, ROG = true, PAL = true, SHD = true, BRD = true, BST = true, BER = true},
    StaBuff = {WAR = true, MNK = true, ROG = true, PAL = true, SHD = true, BRD = true, BST = true, BER = true},
    AgiBuff = {WAR = true, MNK = true, ROG = true, PAL = true, SHD = true, BRD = true, BST = true, BER = true},
    DexBuff = {WAR = true, MNK = true, ROG = true, PAL = true, SHD = true, BRD = true, BST = true, BER = true},
    HPBuff = {ALL = true},
    ACBuff = {ALL = true},
    RegenBuff = {ALL = true},
    SoWBuff = {ALL = true},
    MagicBuff = {ALL = true},
    FireBuff = {ALL = true},
    ColdBuff = {ALL = true},
    DiseaseBuff = {ALL = true},
    PoisonBuff = {ALL = true},
}

-- Helper function to check if a class is eligible for a specific buff type
local function isClassEligibleForBuff(buffType, classShortName)
    local eligibleClasses = buffEligibleClasses[buffType]
    return eligibleClasses and (eligibleClasses[classShortName] or eligibleClasses["ALL"])
end

-- Helper function: Pre-cast checks for combat, movement, and casting status
local function preCastChecks()
    local check = not (mq.TLO.Me.Moving() or mq.TLO.Me.Combat() or mq.TLO.Me.Casting())
    debugPrint("DEBUG: preCastChecks result: ", check)
    return check
end

-- Helper function: Check if we have enough mana to cast the spell
local function hasEnoughMana(spellName)
    local enoughMana = spellName and mq.TLO.Me.CurrentMana() >= mq.TLO.Spell(spellName).Mana()
    debugPrint("DEBUG: Checking mana for spell: ", spellName, " Result: ", enoughMana)
    return enoughMana
end

-- Check if target is within spell range, safely handling nil target and range values
local function isTargetInRange(targetID, spellName)
    local target = mq.TLO.Spawn(targetID)
    local spell = mq.TLO.Spell(spellName)
    
    -- Check for spell range; if not available, use AERange
    local spellRange = spell and spell.Range() or 0
    if spellRange == 0 or spellRange == nil then
        spellRange = spell.AERange() or 0
    end

    -- Validate target and distance, then check if target is within range
    local inRange = target and mq.TLO.Target.LineOfSight() and target.Distance() and (target.Distance() <= spellRange)
    
    -- Improved debug message to handle nil cases
    debugPrint(
        "DEBUG: Target range check for ID: ", targetID, 
        " Spell: ", spellName, 
        " with Range: ", spellRange or "nil", 
        " In Range: ", inRange or false
    )

    return inRange
end

-- Function to handle the heal routine and return
local function handleHealRoutineAndReturn()
    healing.healRoutine()
    canni.canniRoutine()
    utils.monitorNav()
    return true
end

-- Helper function to shuffle a table
local function shuffleTable(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
    debugPrint("DEBUG: Shuffled buffQueue order")
end

function buffer.buffRoutine()
    debugPrint("DEBUG: Entering buffRoutine")

    if not (gui.botOn and gui.buffsOn) then
        debugPrint("DEBUG: Bot or Buff is off. Exiting buffRoutine.")
        return
    end

    if not preCastChecks() then
        debugPrint("DEBUG: Pre-cast checks failed. Exiting buffRoutine.")
        return
    end

    if mq.TLO.Me.PctMana() < 20 then
        debugPrint("DEBUG: Mana below threshold. Exiting buffRoutine.")
        return
    end

    buffer.buffQueue = {} -- Clear previous queue
    local queuedBuffs = {} -- Track buffs already queued for each member

    -- Determine which buffs to apply based on GUI settings
    local spellTypes = {}

    -- Add group-wide buffs to spellTypes
    if gui.HasteBuff and charLevel >= 26 then table.insert(spellTypes, "HasteBuff") end
    if gui.StrBuff and charLevel >= 2 then table.insert(spellTypes, "StrBuff") end
    if gui.StaBuff and charLevel >= 6 then table.insert(spellTypes, "StaBuff") end
    if gui.AgiBuff and charLevel >= 3 then table.insert(spellTypes, "AgiBuff") end
    if gui.DexBuff and charLevel >= 2 then table.insert(spellTypes, "DexBuff") end
    if gui.HPBuff and charLevel >= 2 then table.insert(spellTypes, "HPBuff") end
    if gui.ACBuff and charLevel >= 3 then table.insert(spellTypes, "ACBuff") end
    if gui.RegenBuff and charLevel >= 23 then table.insert(spellTypes, "RegenBuff") end
    if gui.SoWBuff and charLevel >= 9 then table.insert(spellTypes, "SoWBuff") end
    if gui.MagicBuff and charLevel >= 19 then table.insert(spellTypes, "MagicBuff") end
    if gui.FireBuff and charLevel >= 5 then table.insert(spellTypes, "FireBuff") end
    if gui.ColdBuff and charLevel >= 2 then table.insert(spellTypes, "ColdBuff") end
    if gui.DiseaseBuff and charLevel >= 8 then table.insert(spellTypes, "DiseaseBuff") end
    if gui.PoisonBuff and charLevel >= 11 then table.insert(spellTypes, "PoisonBuff") end

    -- Collect group or raid members based on GUI settings
    local groupMembers = {}

    if gui.buffGroup then
        for i = 0, mq.TLO.Group.Members() - 1 do -- Start from 0 to include the player
            local member = mq.TLO.Group.Member(i)
            local memberID = member and member.ID()

            -- Check for valid group members (including self as group member 0)
            if memberID and memberID > 0 and not member.Dead() then
                table.insert(groupMembers, memberID)
                debugPrint("DEBUG: Added group member with ID:", memberID)
            else
                debugPrint("DEBUG: Skipping invalid or dead group member with ID:", memberID or "nil")
            end
        end
    end

    if gui.buffRaid then
        for i = 1, mq.TLO.Raid.Members() do
            local member = mq.TLO.Raid.Member(i)
            local memberID = member and member.ID()

            -- Only add the member if they are valid, alive, and not the player
            if memberID and memberID > 0 and not member.Dead() then
                table.insert(groupMembers, memberID)
            else
                debugPrint("DEBUG: Skipping invalid or dead raid member with ID:", memberID or "nil")
            end
        end
    end

    -- Target each member, check missing buffs, and build the queue
    for _, memberID in ipairs(groupMembers) do
        if not (gui.botOn and gui.buffsOn) then
            debugPrint("DEBUG: Bot or Buff turned off during buff processing. Exiting buffRoutine.")
            return
        end

        if not handleHealRoutineAndReturn() then return end

        debugPrint("DEBUG: Targeting member ID:", memberID)
        mq.cmdf("/tar id %d", memberID)
        mq.delay(300)

        if not mq.TLO.Target() or mq.TLO.Target.ID() ~= memberID then
            debugPrint("DEBUG: Targeting failed for member ID:", memberID)
            break
        end

        local classShortName = mq.TLO.Target.Class.ShortName()
        queuedBuffs[memberID] = queuedBuffs[memberID] or {}

        for _, spellType in ipairs(spellTypes) do

            local bestSpell = spells.findBestSpell(spellType, charLevel)
            local bestspellstring = tostring(bestSpell)

            if bestspellstring and isClassEligibleForBuff(spellType, classShortName) then
                -- Check if the best spell is Unity of the Shissar
                if charLevel == 60 and bestspellstring == "Unity of the Shissar" then
                    debugPrint("DEBUG: Unity of the Shissar detected for member ID:", memberID)
                
                    -- Define all buffs associated with Unity
                    local unityBuffs = {
                        HasteBuff = "Hasted", -- Use "Hasted" for checking Haste
                        StrBuff = "Maniacal Strength",
                        StaBuff = "Riotous Health",
                        AgiBuff = "Deliriously Nimble",
                        DexBuff = "Mortal Deftness",
                    }
                
                    -- Track missing buffs
                    local missingBuffs = {}
                
                    -- Check each Unity buff
                    for buffType, buffName in pairs(unityBuffs) do
                        if buffType == "HasteBuff" then
                            -- Special case: Check directly if the target is hasted
                            if not mq.TLO.Target.Hasted() then
                                table.insert(missingBuffs, buffName)
                            end
                        elseif not mq.TLO.Target.Buff(buffName)() then
                            table.insert(missingBuffs, buffName)
                        end
                    end
                
                    -- If any buffs are missing, queue Unity of the Shissar
                    if #missingBuffs > 0 then
                        debugPrint("DEBUG: Missing Unity buffs for member ID: ", memberID, " Buffs: ", table.concat(missingBuffs, ", "))
                        table.insert(buffer.buffQueue, {memberID = memberID, spell = bestspellstring, spellType = "Unity"})
                        queuedBuffs[memberID]["Unity"] = true -- Mark Unity as queued
                    else
                        debugPrint("DEBUG: All Unity buffs are present for member ID: ", memberID, ". Skipping Unity.")
                    end
                else
                    -- Normal buffing logic for other levels or when Unity is unavailable
                    if mq.TLO.Spell(bestspellstring).StacksTarget() then
                        if not mq.TLO.Target.Buff(bestspellstring)() then
                            if not queuedBuffs[memberID][spellType] then
                                debugPrint("DEBUG: Adding member ID ", memberID, " to buffQueue for spell type:", spellType)
                                table.insert(buffer.buffQueue, {memberID = memberID, spell = bestspellstring, spellType = spellType})
                                queuedBuffs[memberID][spellType] = true -- Mark buff as queued
                            else
                                debugPrint("DEBUG: Buff ", spellType, " already queued for member ID ", memberID, ". Skipping.")
                            end
                        else
                            debugPrint("DEBUG: Buff ", spellType, " already active for member ID ", memberID, ". Skipping.")
                        end
                    else
                        debugPrint("DEBUG: Buff ", spellType, " does not stack for member ID ", memberID, ". Skipping.")
                    end
                end
            end
        end

        mq.delay(100) -- Delay between each member to reduce targeting interruptions
    end

    -- Shuffle the buffQueue order to avoid targeting issues
    shuffleTable(buffer.buffQueue)

    -- Only run processBuffQueue if there are entries in buffer.buffQueue
    if gui.botOn and gui.buffsOn then
        if #buffer.buffQueue > 0 then
            debugPrint("DEBUG: Buffs needed, running processBuffQueue.")
            buffer.processBuffQueue()
        else
            debugPrint("DEBUG: No buffs needed, skipping processBuffQueue.")
            return
        end
    end
end

function buffer.processBuffQueue()
    -- Define slots for each buff type
    local spellSlots = {
        HasteBuff = 6,
        StrBuff = 6,
        StaBuff = 6,
        AgiBuff = 6,
        DexBuff = 6,
        HPBuff = 6,
        ACBuff = 6,
        RegenBuff = 7,
        SoWBuff = 6,
        MagicBuff = 6,
        FireBuff = 6,
        ColdBuff = 6,
        DiseaseBuff = 6,
        PoisonBuff = 6,
        Unity = 6, -- Assign a slot for Unity
    }

    -- Define the buffs applied by Unity
    local unityBuffs = {
        HasteBuff = "Celerity",
        StrBuff = "Maniacal Strength",
        StaBuff = "Riotous Health",
        AgiBuff = "Deliriously Nimble",
        DexBuff = "Mortal Deftness",
    }

    -- Helper function to check if Unity buffs are missing
    local function isUnityBuffMissing()
        for buffType, buffName in pairs(unityBuffs) do
            if buffType == "HasteBuff" then
                if not mq.TLO.Target.Hasted() then
                    debugPrint("DEBUG: Target is missing haste effect.")
                    return true
                end
            elseif not mq.TLO.Target.Buff(buffName)() then
                debugPrint("DEBUG: Target is missing Unity buff:", buffName)
                return true
            end
        end
        return false
    end

    -- Group buff tasks by spell type
    local groupedQueue = {}
    for _, buffTask in ipairs(buffer.buffQueue) do
        local spellType = buffTask.spellType
        if not groupedQueue[spellType] then
            groupedQueue[spellType] = {}
        end
        debugPrint("DEBUG: Adding buff task to groupedQueue for spell type:", spellType)
        table.insert(groupedQueue[spellType], buffTask)
    end

    -- Process each group of tasks by spell type
    for spellType, tasks in pairs(groupedQueue) do
        local spell = tasks[1].spell
        local slot = spellSlots[spellType] -- Get the designated slot for this buff type

        -- Skip processing for non-enabled GUI spell types
        if not gui[spellType] and spellType ~= "Unity" then
            debugPrint("DEBUG: Buff type", spellType, "is no longer enabled. Removing from queue.")
            groupedQueue[spellType] = nil
            goto next_spellType -- Skip this spellType
        end

        -- Check if the spell is already memorized in the designated slot
        local isSpellLoadedInSlot = mq.TLO.Me.Gem(slot)() == spell
        if not isSpellLoadedInSlot then
            debugPrint("DEBUG: Loading spell for type:", spellType, "Spell:", spell, "in slot:", slot)
            spells.loadAndMemorizeSpell(spellType, charLevel, slot)
        else
            debugPrint("DEBUG: Spell", spell, "is already loaded in slot", slot, ". Skipping load.")
        end

        -- Process each task for this spell type across all members
        for _, task in ipairs(tasks) do
            local memberID = task.memberID
            local retries = 0
            local buffApplied = false

            -- Skip processing if mana is too low
            if mq.TLO.Me.PctMana() < 20 then
                debugPrint("DEBUG: Mana below threshold. Exiting buffRoutine.")
                if gui.sitMed then
                    utils.sitMed()
                end
                return -- Exit the entire function if mana is critically low
            end

            if not handleHealRoutineAndReturn() then return end

            -- Retry logic for casting buffs
            while retries < 2 and not buffApplied do
                debugPrint("DEBUG: Targeting member ID:", memberID)
                mq.cmdf('/tar id %d', memberID)
                mq.delay(300)

                if not mq.TLO.Target() or mq.TLO.Target.ID() ~= memberID then
                    debugPrint("DEBUG: Targeting failed for member ID:", memberID)
                    break
                end

                -- Unity logic: Check buffs for the current target
                if spellType == "Unity" then
                    if not isUnityBuffMissing() then
                        debugPrint("DEBUG: Target has all Unity buffs. Skipping Unity for member ID:", memberID)
                        buffApplied = true
                        break
                    else
                        debugPrint("DEBUG: At least one Unity buff is missing. Proceeding with Unity.")
                    end
                elseif mq.TLO.Target.Buff(spell)() then
                    debugPrint("DEBUG: Target already has buff. Skipping member ID:", memberID)
                    buffApplied = true
                    break
                end

                -- Ensure enough mana
                if not hasEnoughMana(spell) then
                    debugPrint("DEBUG: Not enough mana for spell:", spell)
                    if gui.sitMed then
                        utils.sitMed()
                    end
                    return
                end

                -- Check if target is in range
                if not isTargetInRange(memberID, spell) then
                    debugPrint("DEBUG: Target out of range for spell:", spell)
                    break
                end

                -- Wait for the spell to be ready
                local maxReadyAttempts = 20
                local readyAttempt = 0
                while not mq.TLO.Me.SpellReady(spell)() and readyAttempt < maxReadyAttempts do
                    debugPrint("DEBUG: Waiting for spell to be ready, attempt:", readyAttempt)
                    mq.delay(500)
                    readyAttempt = readyAttempt + 1
                end

                -- Cast the spell
                if mq.TLO.Me.SpellReady(spell)() then
                    debugPrint("DEBUG: Casting spell:", spell, "on member ID:", memberID)
                    mq.cmdf('/cast %d', slot)
                    mq.delay(200)
                end

                -- Wait for casting to complete
                while mq.TLO.Me.Casting() do
                    mq.delay(10)
                end

                -- Verify if the buff was applied
                if spellType == "Unity" then
                    if not isUnityBuffMissing() then
                        debugPrint("DEBUG: Unity successfully applied for member ID:", memberID)
                        buffApplied = true
                    else
                        debugPrint("DEBUG: Unity failed to apply for member ID:", memberID)
                    end
                elseif mq.TLO.Target.Buff(spell)() then
                    debugPrint("DEBUG: Buff successfully applied to member ID:", memberID)
                    buffApplied = true
                else
                    debugPrint("DEBUG: Buff failed to apply. Retrying for member ID:", memberID)
                end

                retries = retries + 1
            end

            -- Re-queue the task if buff was not applied
            if not buffApplied then
                debugPrint("DEBUG: Max retries reached. Re-queuing task for member ID:", memberID)
                table.insert(buffer.buffQueue, task)
            end
        end

        ::next_spellType::
    end

    debugPrint("DEBUG: Buff routine completed.")
end

return buffer