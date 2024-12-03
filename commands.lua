local mq = require 'mq'
local gui = require 'gui'
local nav = require 'nav'
local utils = require 'utils'

local commands = {}

local DEBUG_MODE = false
-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

-- Existing functions

local function setExit()
    print("Closing..")
    gui.isOpen = false
end

local function setSave()
    gui.saveConfig()
end

-- Helper function for on/off commands
local function setToggleOption(option, value, name)
    if value == "on" then
        gui[option] = true
        print(name .. " is now enabled.")
    elseif value == "off" then
        gui[option] = false
        print(name .. " is now disabled.")
    else
        print("Usage: /convSHM " .. name .. " on/off")
    end
end

-- Helper function for numeric value commands
local function setNumericOption(option, value, name)
    if value == "" then
        print("Usage: /convSHM " .. name .. " <number>")
        return
    end
    if not string.match(value, "^%d+$") then
        print("Error: " .. name .. " must be a number with no letters or symbols.")
        return
    end
    gui[option] = tonumber(value)
    print(name .. " set to", gui[option])
end

-- On/Off Commands
local function setBotOnOff(value) setToggleOption("botOn", value, "Bot") end
local function setSwitchWithMA(value) setToggleOption("switchWithMA", value, "Switch with MA") end
local function setBuffGroup(value) setToggleOption("buffGroup", value, "Buff Group") end
local function setBuffRaid(value) setToggleOption("buffRaid", value, "Buff Raid") end
local function setBuffsOn(value) setToggleOption("buffsOn", value, "Buffs") end
local function sethastebuff(value) setToggleOption("HasteBuff", value, "Haste Buff") end
local function setregenbuff(value) setToggleOption("RegenBuff", value, "Regen Buff") end
local function setsowbuff(value) setToggleOption("SoWBuff", value, "Sow Buff") end
local function setstrbuff(value) setToggleOption("StrBuff", value, "Str Buff") end
local function setstaBuff(value) setToggleOption("StaBuff", value, "Sta Buff") end
local function setagiBuff(value) setToggleOption("AgiBuff", value, "Agi Buff") end
local function setdexBuff(value) setToggleOption("DexBuff", value, "Dex Buff") end
local function setfirebuff(value) setToggleOption("FireBuff", value, "Fire Buff") end
local function setcoldbuff(value) setToggleOption("ColdBuff", value, "Cold Buff") end
local function setmagicbuff(value) setToggleOption("MagicBuff", value, "Magic Buff") end
local function setpoisonbuff(value) setToggleOption("PoisonBuff", value, "Poison Buff") end
local function setdiseasebuff(value) setToggleOption("DiseaseBuff", value, "Disease Buff") end
local function setMalo(value) setToggleOption("maloOn", value, "Malo") end
local function setSlow(value) setToggleOption("slowOn", value, "Slow") end
local function setCripple(value) setToggleOption("crippleOn", value, "Cripple") end
local function setSitMed(value) setToggleOption("sitMed", value, "Sit to Med") end
local function setCanni(value) setToggleOption("canniOn", value, "Canni") end
local function setTorpor(value) setToggleOption("torporOn", value, "Torpor") end

-- Numeric Commands
local function setSitMedOnOff(value) setToggleOption("sitMed", value, "Sit to Med") end

-- Combined function for setting main assist, range, and percent
local function setAssist(name, range, percent)
    if name then
        utils.setMainAssist(name)
        print("Main Assist set to", name)
    else
        print("Error: Main Assist name is required.")
        return
    end

    -- Set the assist range if provided
    if range and string.match(range, "^%d+$") then
        gui.assistRange = tonumber(range)
        print("Assist Range set to", gui.assistRange)
    else
        print("Assist Range not provided or invalid. Current range:", gui.assistRange)
    end

    -- Set the assist percent if provided
    if percent and string.match(percent, "^%d+$") then
        gui.assistPercent = tonumber(percent)
        print("Assist Percent set to", gui.assistPercent)
    else
        print("Assist Percent not provided or invalid. Current percent:", gui.assistPercent)
    end
end

local function setChaseOnOff(value)
    if value == "" then
        print("Usage: /convSHM Chase <targetName> <distance> or /convSHM Chase off/on")
    elseif value == 'on' then
        gui.chaseon = true
        gui.returntocamp = false
        gui.pullOn = false
        print("Chase enabled.")
    elseif value == 'off' then
        gui.chaseon = false
        print("Chase disabled.")
    else
        -- Split value into targetName and distance
        local targetName, distanceStr = value:match("^(%S+)%s*(%S*)$")
        
        if not targetName then
            print("Invalid input. Usage: /convSHM Chase <targetName> <distance>")
            return
        end
        
        -- Convert distance to a number, if it's provided
        local distance = tonumber(distanceStr)
        
        -- Check if distance is valid
        if not distance then
            print("Invalid distance provided. Usage: /convSHM Chase <targetName> <distance> or /convSHM Chase off")
            return
        end
        
        -- Pass targetName and valid distance to setChaseTargetAndDistance
        nav.setChaseTargetAndDistance(targetName, distance)
    end
end

-- Combined function for setting camp, return to camp, and chase
local function setCampHere(value1)
    if value1 == "on" then
        gui.chaseon = false
        gui.campLocation = nav.setCamp()
        gui.returntocamp = true
        gui.campDistance = gui.campDistance or 10
        print("Camp location set to current spot. Return to Camp enabled with default distance:", gui.campDistance)
    elseif value1 == "off" then
        -- Disable return to camp
        gui.returntocamp = false
        print("Return To Camp disabled.")
    elseif tonumber(value1) then
        gui.chaseon = false
        gui.campLocation = nav.setCamp()
        gui.returntocamp = true
        gui.campDistance = tonumber(value1)
        print("Camp location set with distance:", gui.campDistance)
    else
        print("Error: Invalid command. Usage: /convSHM camphere <distance>, /convSHM camphere on, /convSHM camphere off")
    end
end

local function setMaloIgnore(scope, action)
    -- Check for a valid target name
    local targetName = mq.TLO.Target.CleanName()
    if not targetName then
        print("Error: No target selected. Please target a mob to modify the malo ignore list.")
        return
    end

    -- Determine if the scope is global or zone-specific
    local isGlobal = (scope == "global")

    if action == "add" then
        utils.addMobToMaloIgnoreList(targetName, isGlobal)
        local scopeText = isGlobal and "global quest NPC ignore list" or "malo ignore list for the current zone"
        print(string.format("'%s' has been added to the %s.", targetName, scopeText))

    elseif action == "remove" then
        utils.removeMobFromMaloIgnoreList(targetName, isGlobal)
        local scopeText = isGlobal and "global quest NPC ignore list" or "malo ignore list for the current zone"
        print(string.format("'%s' has been removed from the %s.", targetName, scopeText))

    else
        print("Error: Invalid action. Usage: /convSHM maloignore zone/global add/remove")
    end
end

local function setSlowIgnore(scope, action)
    -- Check for a valid target name
    local targetName = mq.TLO.Target.CleanName()
    if not targetName then
        print("Error: No target selected. Please target a mob to modify the slow ignore list.")
        return
    end

    -- Determine if the scope is global or zone-specific
    local isGlobal = (scope == "global")

    if action == "add" then
        utils.addMobToSlowIgnoreList(targetName, isGlobal)
        local scopeText = isGlobal and "global quest NPC ignore list" or "slow ignore list for the current zone"
        print(string.format("'%s' has been added to the %s.", targetName, scopeText))

    elseif action == "remove" then
        utils.removeMobFromSlowIgnoreList(targetName, isGlobal)
        local scopeText = isGlobal and "global quest NPC ignore list" or "slow ignore list for the current zone"
        print(string.format("'%s' has been removed from the %s.", targetName, scopeText))

    else
        print("Error: Invalid action. Usage: /convSHM slowignore zone/global add/remove")
    end
end

local function setCrippleIgnore(scope, action)
    -- Check for a valid target name
    local targetName = mq.TLO.Target.CleanName()
    if not targetName then
        print("Error: No target selected. Please target a mob to modify the cripple ignore list.")
        return
    end

    -- Determine if the scope is global or zone-specific
    local isGlobal = (scope == "global")

    if action == "add" then
        utils.addMobToCrippleIgnoreList(targetName, isGlobal)
        local scopeText = isGlobal and "global quest NPC ignore list" or "cripple ignore list for the current zone"
        print(string.format("'%s' has been added to the %s.", targetName, scopeText))

    elseif action == "remove" then
        utils.removeMobFromCrippleIgnoreList(targetName, isGlobal)
        local scopeText = isGlobal and "global quest NPC ignore list" or "cripple ignore list for the current zone"
        print(string.format("'%s' has been removed from the %s.", targetName, scopeText))

    else
        print("Error: Invalid action. Usage: /convSHM crippleignore zone/global add/remove")
    end
end


local function commandHandler(command, ...)
    -- Convert command and arguments to lowercase for case-insensitive matching
    command = string.lower(command)
    local args = {...}
    for i, arg in ipairs(args) do
        args[i] = string.lower(arg)
    end

    if command == "exit" then
        setExit()
    elseif command == "bot" then
        setBotOnOff(args[1])
    elseif command == "save" then
        setSave()
    elseif command == "assist" then
        setAssist(args[1], args[2], args[3])
    elseif command == "switchwithma" then
        setSwitchWithMA(args[1])
    elseif command == "camphere" then
        setCampHere(args[1])
    elseif command == "chase" then
        local chaseValue = args[1]
        if args[2] then
            chaseValue = chaseValue .. " " .. args[2]
        end
        setChaseOnOff(chaseValue)

    elseif command == "sitmed" then
        setSitMedOnOff(args[1])
    elseif command == "buffs" then
        setBuffsOn(args[1])
    elseif command == "buffgroup" then
        setBuffGroup(args[1])
    elseif command == "buffraid" then
        setBuffRaid(args[1])
    elseif command == "hastebuff" then
        sethastebuff(args[1])
    elseif command == "regenbuff" then
        setregenbuff(args[1])
    elseif command == "sowbuff" then
        setsowbuff(args[1])
    elseif command == "strbuff" then
        setstrbuff(args[1])
    elseif command == "stabuff" then
        setstaBuff(args[1])
    elseif command == "agibuff" then
        setagiBuff(args[1])
    elseif command == "dexbuff" then
        setdexBuff(args[1])
    elseif command == "firebuff" then
        setfirebuff(args[1])
    elseif command == "coldbuff" then
        setcoldbuff(args[1])
    elseif command == "magicbuff" then
        setmagicbuff(args[1])
    elseif command == "poisonbuff" then
        setpoisonbuff(args[1])
    elseif command == "diseasebuff" then
        setdiseasebuff(args[1])
    elseif command == "malo" then
        setMalo(args[1])
    elseif command == "slow" then
        setSlow(args[1])
    elseif command == "cripple" then
        setCripple(args[1])
    elseif command == "maloignore" then
        setMaloIgnore(args[1], args[2])
    elseif command == "slowignore" then
        setSlowIgnore(args[1], args[2])
    elseif command == "crippleignore" then
        setCrippleIgnore(args[1], args[2])
    elseif command == "canni" then
        setCanni(args[1])
    elseif command == "torpor" then
        setTorpor(args[1])
    elseif command == "sitmed" then
        setSitMed(args[1])
    end
end

function commands.init()
    -- Single binding for the /convSHM command
    mq.bind('/convSHM', function(command, ...)
        commandHandler(command, ...)
    end)
end

function commands.initALL()
    -- Single binding for the /convBRD command
    mq.bind('/convALL', function(command, ...)
        commandHandler(command, ...)
    end)
end

return commands