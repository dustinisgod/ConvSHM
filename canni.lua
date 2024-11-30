local mq = require('mq')
local gui = require('gui')
local spells = require('spells')
local utils = require('utils')

local DEBUG_MODE = false
-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

local canni = {}
local charLevel = mq.TLO.Me.Level()

function canni.canniRoutine()

    if gui.botOn and gui.canniOn and charLevel >= 23 and mq.TLO.Me.CurrentHPs() >= 100 and mq.TLO.Me.PctHPs() >= gui.canniMinHPPercent and mq.TLO.Me.PctMana() < 100 then
        debugPrint("DEBUG: Checking if Canni is enabled.")
        local canniSpellSlot = 9
        local canniSpellName = spells.findBestSpell("Canni", charLevel)

        if canniSpellName and mq.TLO.Me.Gem(canniSpellSlot).Name() ~= canniSpellName then
            debugPrint("DEBUG: Loading Canni spell in slot 9")
            spells.loadAndMemorizeSpell("Canni", charLevel, canniSpellSlot)
        end

        if canniSpellName then
            debugPrint("DEBUG: Checking if Canni spell is ready.")
            local maxReadyAttempts = 20
            local readyAttempt = 0
            while not mq.TLO.Me.SpellReady(canniSpellName)() and readyAttempt < maxReadyAttempts do
                if not gui.botOn or not gui.canniOn then return end
                readyAttempt = readyAttempt + 1
                mq.delay(500)
            end

            if mq.TLO.Me.SpellReady(canniSpellName)() then
                debugPrint("DEBUG: Casting Canni spell.")
                mq.cmdf('/cast %d', canniSpellSlot)
                mq.delay(100) -- Small delay for casting to start
                while mq.TLO.Me.Casting() do
                    if mq.TLO.Me.PctMana() == 100 then
                        mq.cmd("/stopcast")
                        break
                    end
                    if mq.TLO.Me.PctHPs() < gui.canniMinHPPercent then
                        mq.cmd("/stopcast")
                        break
                    end
                    mq.delay(50) -- Wait until casting is complete
                end
                if gui.sitMed then
                    utils.sitMed()
                end
            else
                debugPrint("DEBUG: Canni spell not ready.")
                return
            end
        else
            debugPrint("DEBUG: No Canni spell found.")
            return
        end
    else
        debugPrint("DEBUG: Canni not enabled or mana 100% or Health Low")
        return
    end
end

return canni