local mq = require('mq')
local utils = require('utils')
local commands = require('commands')
local gui = require('gui')
local nav = require('nav')
local spells = require('spells')
local malo = require('malo')
local slow = require('slow')
local cripple = require('cripple')
local healing = require('healing')
local cures = require('cures')
local canni = require('canni')
local assist = require('assist')

local DEBUG_MODE = false
-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

local class = mq.TLO.Me.Class()
if class ~= "Shaman" then
    print("This script is only for Shaman.")
    mq.exit()
end

local currentLevel = mq.TLO.Me.Level()

utils.PluginCheck()

mq.cmd('/squelch /assist off')

mq.imgui.init('controlGUI', gui.controlGUI)

commands.init()
commands.initALL()

local startupRun = false
local function checkBotOn(currentLevel)
    if gui.botOn and not startupRun then
        nav.setCamp()
        spells.startup(currentLevel)
        startupRun = true  -- Set flag to prevent re-running
        printf("Bot has been turned on. Running spells.startup.")
        local buffer = require('buffer')
        if gui.buffsOn then
            buffer.buffRoutine()
        end
    elseif not gui.botOn and startupRun then
        -- Optional: Reset the flag if bot is turned off
        startupRun = false
        printf("Bot has been turned off. Ready to run spells.startup again.")
    end
end

local toggleboton = false
local function returnChaseToggle()
    -- Check if bot is on and return-to-camp is enabled, and only set camp if toggleboton is false
    if gui.botOn and gui.returnToCamp and not toggleboton then
        nav.setCamp()
        toggleboton = true
    elseif not gui.botOn and toggleboton then
        -- Clear camp if bot is turned off after being on
        nav.clearCamp()
        toggleboton = false
    end
end

utils.loadMaloConfig()
utils.loadSlowConfig()
utils.loadCrippleConfig()

while gui.controlGUI do

    returnChaseToggle()

    if gui.botOn then

        checkBotOn(currentLevel)

        utils.monitorNav()

        if gui.sitMed then
            debugPrint("Sitting for medding.")
            utils.sitMed()
        end

        if gui.canniOn then
            debugPrint("Canni routine.")
            canni.canniRoutine()
        end

        if gui.mainHeal or gui.torporOn then
            debugPrint("Healing routine.")
            healing.healRoutine()
        end

        if gui.maloOn then
            debugPrint("Malo routine.")
            malo.maloRoutine()
        end

        if gui.slowOn then
            debugPrint("Slow routine.")
            slow.slowRoutine()
        end

        if gui.crippleOn then
            debugPrint("Cripple routine.")
            cripple.crippleRoutine()
        end

        if gui.buffsOn then
            debugPrint("Buff routine.")
            utils.monitorBuffs()
         end

        if gui.curesOn then
            debugPrint("Cure routine.")
            cures.cureRoutine()
        end

        if gui.assistOn then
            debugPrint("Assist routine.")
            assist.assistRoutine()
            if gui.petOn then
                debugPrint("Pet utils routine.")
                utils.monitorPet()
            end
        end

        local newLevel = mq.TLO.Me.Level()
        if newLevel ~= currentLevel then
            printf(string.format("Level has changed from %d to %d. Updating spells.", currentLevel, newLevel))
            spells.startup(newLevel)
            currentLevel = newLevel
        end
    end

    mq.doevents()
    mq.delay(50)
end