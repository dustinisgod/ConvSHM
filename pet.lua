local mq = require('mq')
local gui = require('gui')
local spells = require('spells')

local DEBUG_MODE = false
-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

local pet = {}
local charLevel = mq.TLO.Me.Level()

function pet.petRoutine()
    debugPrint("DEBUG: Checking if pet usage is enabled.")

    if gui.botOn and gui.assistOn and gui.petOn and not mq.TLO.Pet.IsSummoned() and charLevel >= 32 then
            debugPrint("DEBUG: Checking if pet is enabled.")
        local petSpellSlot = 6
        local petSpellName = spells.findBestSpell("SummonPet", charLevel)

        if petSpellName and mq.TLO.Me.Gem(petSpellSlot).Name() ~= petSpellName then
            debugPrint("DEBUG: Loading SummonPet spell in slot 6")
            spells.loadAndMemorizeSpell("SummonPet", charLevel, petSpellSlot)
        end

        if petSpellName then
            debugPrint("DEBUG: Checking if SummonPet spell is ready.")
            local maxReadyAttempts = 20
            local readyAttempt = 0
            while not mq.TLO.Me.SpellReady(petSpellName)() and readyAttempt < maxReadyAttempts do
                if not gui.botOn or not gui.petOn then return end
                readyAttempt = readyAttempt + 1
                mq.delay(1000)
            end

            -- Summon pet if the spell is ready
            if mq.TLO.Me.SpellReady(petSpellName)() then
                debugPrint("DEBUG: Casting SummonPet spell.")
                mq.cmdf('/cast %d', petSpellSlot)
                mq.delay(100) -- Small delay for casting to start
                while mq.TLO.Me.Casting() do
                    mq.delay(50) -- Wait until casting is complete
                end
                mq.delay(100)
            end

            ---@diagnostic disable-next-line: undefined-field
            if mq.TLO.Pet.IsSummoned() and not mq.TLO.Pet.GHold() then
                mq.cmd("/pet ghold on")
            end
        end

    elseif mq.TLO.Pet.IsSummoned() then
        debugPrint("DEBUG: Pet already summoned.")
        return
    else
        debugPrint("DEBUG: No SummonPet spell found.")
        return
    end
end

return pet