local mq = require('mq')
local gui = require('gui')
local nav = require('nav')

local DEBUG_MODE = false
-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

local utils = {}

utils.IsUsingDanNet = true
utils.IsUsingTwist = false
utils.IsUsingCast = true
utils.IsUsingMelee = false

utils.maloConfig = {}
utils.slowConfig = {}
utils.crippleConfig = {}
local maloConfigPath = mq.configDir .. '/' .. 'Conv_Malo_ignore_list.lua'
local slowConfigPath = mq.configDir .. '/' .. 'Conv_Slow_ignore_list.lua'
local crippleConfigPath = mq.configDir .. '/' .. 'Conv_Cripple_ignore_list.lua'


function utils.PluginCheck()
    if utils.IsUsingDanNet then
        if not mq.TLO.Plugin('mq2dannet').IsLoaded() then
            printf("Plugin \ayMQ2DanNet\ax is required. Loading it now.")
            mq.cmd('/plugin mq2dannet noauto')
        end
        -- turn off fullname mode in DanNet
        if mq.TLO.DanNet.FullNames() then
            mq.cmd('/dnet fullnames off')
        end
        if utils.IsUsingTwist then
            if not mq.TLO.Plugin('mq2twist').IsLoaded() then
                printf("Plugin \ayMQ2Twist\ax is required. Loading it now.")
                mq.cmd('/plugin mq2twist noauto')
            end
        end
        if utils.IsUsingCast then
            if not mq.TLO.Plugin('mq2cast').IsLoaded() then
                printf("Plugin \ayMQ2Cast\ax is required. Loading it now.")
                mq.cmd('/plugin mq2cast noauto')
            end
        end
        if not utils.IsUsingMelee then
            if mq.TLO.Plugin('mq2melee').IsLoaded() then
                printf("Plugin \ayMQ2Melee\ax is not recommended. Unloading it now.")
                mq.cmd('/plugin mq2melee unload')
            end
        end
    end
end

function utils.isInGroup()
    local inGroup = mq.TLO.Group() and mq.TLO.Group.Members() > 0
    return inGroup
end

-- Utility: Check if the player is in a group or raid
function utils.isInRaid()
    local inRaid = mq.TLO.Raid.Members() > 0
    return inRaid
end

-- Helper function to check if the target is in campQueue
function utils.isTargetInCampQueue(targetID)
    local pull = require('pull')
    for _, mob in ipairs(pull.campQueue) do
        if mob.ID() == targetID then
            return true
        end
    end
    return false
end

local lastNavTime = 0

function utils.monitorNav()
debugPrint("monitorNav")
    if gui.botOn and (gui.chaseOn or gui.returnToCamp) and not gui.pullOn then
        if not gui then
            printf("Error: gui is nil")
            return
        end

        local currentTime = os.time()

        if gui.returnToCamp and (currentTime - lastNavTime >= 5) then
            debugPrint("Run returntocamp routine")
            nav.checkCampDistance()
            lastNavTime = currentTime
        elseif gui.chaseOn and (currentTime - lastNavTime >= 2) then
            debugPrint("Run Chase routine")
            nav.chase()
            lastNavTime = currentTime
        end
    else
        return
    end
end

local lastCuresTime = 0

function utils.monitorCures()
    if gui.botOn then
        local cures = require('cures')
        if not gui then
            printf("Error: gui is nil")
            return
        end

        local currentTime = os.time()

        if (gui.useCures == true ) and (currentTime - lastCuresTime >= 10) then
            if mq.TLO.Me.PctMana() > 20 then
                cures.curesRoutine()
                lastCuresTime = currentTime
            end
        end
    end
end

utils.nextBuffTime = 0  -- Global variable to track next scheduled time

function utils.monitorBuffs()
    debugPrint("monitorBuffs")
    if gui.botOn and gui.buffsOn then
        debugPrint("Buffs are on")
        if not gui then
            printf("Error: gui is nil")
            return
        end

        local buffer = require('buffer')
        local currentTime = os.time()

        if (gui.HasteBuff or gui.HPBuff or gui.ACBuff or gui.StrBuff or gui.StaBuff or gui.DexBuff or gui.AgiBuff or gui.RegenBuff or gui.SoWBuff or gui.MagicBuff or gui.FireBuff or gui.ColdBuff or gui.PoisonBuff or gui.DiseaseBuff) and (currentTime >= utils.nextBuffTime) then
            debugPrint("DEBUG: Running buff routine...")
            if mq.TLO.Me.PctMana() > 20 then
                debugPrint("DEBUG: Running buff routine...")
                buffer.buffRoutine()
                utils.nextBuffTime = currentTime + 240  -- Schedule next run in 240 seconds
            else
                debugPrint("DEBUG: Buff routine skipped. Mana")
                return
            end
        else
            debugPrint("DEBUG: Buff routine skipped. Not checked marked or not time")
            return
        end
    else
        debugPrint("Buffs are off")
        return
    end
end

function utils.sitMed()
    if not (gui.botOn and gui.sitMed and (mq.TLO.Me.PctMana() < 100 or mq.TLO.Me.PctHPs() < 100) and not mq.TLO.Me.Mount()) then
        debugPrint("SitMed conditions not met")
        return -- Exit early if sitMed conditions are not met
    end

    local nearbyNPCs = mq.TLO.SpawnCount(string.format('npc radius %d', gui.assistRange))() or 0
    local currentHP = mq.TLO.Me.PctHPs() or 100
    local healthThreshold = gui.regenHealOnly and (gui.emergencyhealpct or 50) or (gui.healPct or 90)

    -- Sit logic based on conditions
    if (nearbyNPCs == 0 or currentHP >= healthThreshold) and not mq.TLO.Me.Casting() and not mq.TLO.Me.Moving() then
        if not mq.TLO.Me.Sitting() then
            if mq.TLO.Me.PctMana() == 100 and mq.TLO.Me.PctHPs() < 100 then
                debugPrint("DEBUG: Mana full but health not at 100%. Sitting to regenerate health.")
            else
                debugPrint("DEBUG: Sitting for medding.")
            end
            mq.cmd('/sit')
        end
    end
end

local lastPetTime = 0

function utils.monitorPet()
local pet = require('pet')
debugPrint("monitorPet")
    if gui.botOn and gui.petOn then
        debugPrint("Pet is on")
        if not gui then
            printf("Error: gui is nil")
            return
        end

        local currentTime = os.time()

        if (currentTime - lastPetTime >= 60) then
            debugPrint("Run Pet routine")
            pet.petRoutine()
            lastPetTime = currentTime
        end
    else
        debugPrint("Pet is off")
        return
    end
end

function utils.setMainAssist(charName)
    if charName and charName ~= "" then
        -- Remove spaces, numbers, and symbols
        charName = charName:gsub("[^%a]", "")
        
        -- Capitalize the first letter and make the rest lowercase
        charName = charName:sub(1, 1):upper() .. charName:sub(2):lower()

        gui.mainAssist = charName
    end
end

-- Utility function to check if a table contains a given value
function utils.tableContains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

local hasLoggedError = false

function utils.isInCamp(range)

    range = range or 10  -- Default to a 10-unit range if none is provided

    -- Determine reference location (camp location or main assist's location)
    local referenceLocation
    if gui.returnToCamp then
        -- Use camp location if returnToCamp is enabled
        nav.campLocation = nav.campLocation or {x = 0, y = 0, z = 0}  -- Default camp location if not set
        referenceLocation = {x = nav.campLocation.x, y = nav.campLocation.y, z = nav.campLocation.z}
    elseif gui.chaseOn then
        -- Use main assist's location if chaseOn is enabled
        local mainAssistSpawn = mq.TLO.Spawn(gui.mainAssist)
        if mainAssistSpawn() then
            referenceLocation = {x = mainAssistSpawn.X(), y = mainAssistSpawn.Y(), z = mainAssistSpawn.Z()}
        else
            if not hasLoggedError then
                hasLoggedError = true
            end
            return false  -- No valid main assist, so not in camp
        end
    else
        if not hasLoggedError then
            hasLoggedError = true
        end
        return false  -- Neither camp nor chase is active, so not in camp
    end

    -- Reset error flag if a valid reference location is found
    hasLoggedError = false

    -- Get the player’s current location
    local playerX, playerY, playerZ = mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z()
    if not playerX or not playerY or not playerZ then
        return false  -- Exit if player coordinates are unavailable
    end

    -- Calculate distance from the player to the reference location
    local distanceToCamp = math.sqrt((referenceLocation.x - playerX)^2 +
                                     (referenceLocation.y - playerY)^2 +
                                     (referenceLocation.z - playerZ)^2)
    
    -- Check if the player is within the specified range of the camp location
    return distanceToCamp <= range
end

function utils.referenceLocation(range)
    range = range or 100  -- Set a default range if none is provided

    -- Determine reference location based on returnToCamp or chaseOn settings
    local referenceLocation
    if gui.assistOn and gui.returnToCamp then
        nav.campLocation = nav.campLocation or {x = 0, y = 0, z = 0}  -- Initialize campLocation with a default if needed
        referenceLocation = {x = nav.campLocation.x, y = nav.campLocation.y, z = nav.campLocation.z}
    elseif gui.chaseOn or (not gui.chaseon and not gui.returnToCamp) then
        local mainAssistSpawn = mq.TLO.Spawn(gui.mainAssist)
        if mainAssistSpawn() then
            referenceLocation = {x = mainAssistSpawn.X(), y = mainAssistSpawn.Y(), z = mainAssistSpawn.Z()}
        else
            if not hasLoggedError then
                hasLoggedError = true
            end
            return {}  -- Return an empty table if no valid main assist found
        end
    else
        if not hasLoggedError then
            hasLoggedError = true
        end
        return {}  -- Return an empty table if neither returnToCamp nor chaseOn is enabled
    end

    -- Reset error flag if a valid location is found
    hasLoggedError = false

    local mobsInRange = mq.getFilteredSpawns(function(spawn)
        local mobX, mobY, mobZ = spawn.X(), spawn.Y(), spawn.Z()
        if not mobX or not mobY or not mobZ then
            return false  -- Skip this spawn if any coordinate is nil
        end

        local distanceToReference = math.sqrt((referenceLocation.x - mobX)^2 +
                                              (referenceLocation.y - mobY)^2 +
                                              (referenceLocation.z - mobZ)^2)
        -- Add Line of Sight (LOS) check
        return spawn.Type() == 'NPC' and distanceToReference <= range and spawn.LineOfSight()
    end)

    return mobsInRange  -- Return the list of mobs in range
end

-- Load the malo ignore list from the config file
function utils.loadMaloConfig()
    local configData, err = loadfile(maloConfigPath)
    if configData then
        local config = configData() or {}
        
        -- Load each zone-specific list
        for zone, mobs in pairs(config) do
            utils.maloConfig[zone] = mobs
        end
        
        -- Ensure the global ignore list is always loaded and initialized
        utils.maloConfig.globalIgnoreList = utils.maloConfig.globalIgnoreList or {}
        
        print("Malo ignore list loaded from " .. maloConfigPath)
    else
        print("No malo ignore list found. Starting with an empty list.")
        utils.maloConfig = {globalIgnoreList = {}}  -- Initialize with an empty global list
    end
end

-- Function to add a mob to the malo ignore list using its clean name
function utils.addMobToMaloIgnoreList(targetName, isGlobal)
    local zoneName = isGlobal and "globalIgnoreList" or mq.TLO.Zone.ShortName() or "UnknownZone"
    
    if targetName then
        -- Ensure the zone or global list has an entry in the table
        utils.maloConfig[zoneName] = utils.maloConfig[zoneName] or {}
        
        -- Add the mob's clean name to the appropriate ignore list if not already present
        if not utils.maloConfig[zoneName][targetName] then
            utils.maloConfig[zoneName][targetName] = true
            print(string.format("Added '%s' to the malo ignore list for '%s'.", targetName, zoneName))
            utils.saveMaloConfig() -- Save the configuration after adding
        else
            print(string.format("'%s' is already in the malo ignore list for '%s'.", targetName, zoneName))
        end
    else
        print("Error: No target selected. Please target a mob to add it to the malo ignore list.")
    end
end

-- Function to remove a mob from the malo ignore list using its clean name
function utils.removeMobFromMaloIgnoreList(targetName, isGlobal)
    local zoneName = isGlobal and "globalIgnoreList" or mq.TLO.Zone.ShortName() or "UnknownZone"
    
    if targetName then
        -- Check if the zone or global entry exists in the ignore list
        if utils.maloConfig[zoneName] and utils.maloConfig[zoneName][targetName] then
            utils.maloConfig[zoneName][targetName] = nil  -- Remove the mob entry
            print(string.format("Removed '%s' from the malo ignore list for '%s'.", targetName, zoneName))
            utils.saveMaloConfig()  -- Save the updated ignore list
        else
            print(string.format("'%s' is not in the malo ignore list for '%s'.", targetName, zoneName))
        end
    else
        print("Error: No target selected. Please target a mob to remove it from the malo ignore list.")
    end
end

-- Save the malo ignore list to the config file
function utils.saveMaloConfig()
    local config = {}
    for zone, mobs in pairs(utils.maloConfig) do
        config[zone] = mobs
    end
    mq.pickle(maloConfigPath, config)
    print("Malo ignore list saved to " .. maloConfigPath)
end

-- Load the slow ignore list from the config file
function utils.loadSlowConfig()
    local configData, err = loadfile(slowConfigPath)
    if configData then
        local config = configData() or {}
        
        -- Load each zone-specific list
        for zone, mobs in pairs(config) do
            utils.slowConfig[zone] = mobs
        end
        
        -- Ensure the global ignore list is always loaded and initialized
        utils.slowConfig.globalIgnoreList = utils.slowConfig.globalIgnoreList or {}
        
        print("Slow ignore list loaded from " .. slowConfigPath)
    else
        print("No slow ignore list found. Starting with an empty list.")
        utils.slowConfig = {globalIgnoreList = {}}  -- Initialize with an empty global list
    end
end

-- Function to add a mob to the slow ignore list using its clean name
function utils.addMobToSlowIgnoreList(targetName, isGlobal)
    local zoneName = isGlobal and "globalIgnoreList" or mq.TLO.Zone.ShortName() or "UnknownZone"
    
    if targetName then
        -- Ensure the zone or global list has an entry in the table
        utils.slowConfig[zoneName] = utils.slowConfig[zoneName] or {}
        
        -- Add the mob's clean name to the appropriate ignore list if not already present
        if not utils.slowConfig[zoneName][targetName] then
            utils.slowConfig[zoneName][targetName] = true
            print(string.format("Added '%s' to the slow ignore list for '%s'.", targetName, zoneName))
            utils.saveSlowConfig() -- Save the configuration after adding
        else
            print(string.format("'%s' is already in the slow ignore list for '%s'.", targetName, zoneName))
        end
    else
        print("Error: No target selected. Please target a mob to add it to the slow ignore list.")
    end
end

-- Function to remove a mob from the slow ignore list using its clean name
function utils.removeMobFromSlowIgnoreList(targetName, isGlobal)
    local zoneName = isGlobal and "globalIgnoreList" or mq.TLO.Zone.ShortName() or "UnknownZone"
    
    if targetName then
        -- Check if the zone or global entry exists in the ignore list
        if utils.slowConfig[zoneName] and utils.slowConfig[zoneName][targetName] then
            utils.slowConfig[zoneName][targetName] = nil  -- Remove the mob entry
            print(string.format("Removed '%s' from the slow ignore list for '%s'.", targetName, zoneName))
            utils.saveSlowConfig()  -- Save the updated ignore list
        else
            print(string.format("'%s' is not in the slow ignore list for '%s'.", targetName, zoneName))
        end
    else
        print("Error: No target selected. Please target a mob to remove it from the slow ignore list.")
    end
end

-- Save the slow ignore list to the config file
function utils.saveSlowConfig()
    local config = {}
    for zone, mobs in pairs(utils.slowConfig) do
        config[zone] = mobs
    end
    mq.pickle(slowConfigPath, config)
    print("Slow ignore list saved to " .. slowConfigPath)
end

-- Load the cripple ignore list from the config file
function utils.loadCrippleConfig()
    local configData, err = loadfile(crippleConfigPath)
    if configData then
        local config = configData() or {}
        
        -- Load each zone-specific list
        for zone, mobs in pairs(config) do
            utils.crippleConfig[zone] = mobs
        end
        
        -- Ensure the global ignore list is always loaded and initialized
        utils.crippleConfig.globalIgnoreList = utils.crippleConfig.globalIgnoreList or {}
        
        print("Cripple ignore list loaded from " .. crippleConfigPath)
    else
        print("No cripple ignore list found. Starting with an empty list.")
        utils.crippleConfig = {globalIgnoreList = {}}  -- Initialize with an empty global list
    end
end

-- Function to add a mob to the cripple ignore list using its clean name
function utils.addMobToCrippleIgnoreList(targetName, isGlobal)
    local zoneName = isGlobal and "globalIgnoreList" or mq.TLO.Zone.ShortName() or "UnknownZone"
    
    if targetName then
        -- Ensure the zone or global list has an entry in the table
        utils.crippleConfig[zoneName] = utils.crippleConfig[zoneName] or {}
        
        -- Add the mob's clean name to the appropriate ignore list if not already present
        if not utils.crippleConfig[zoneName][targetName] then
            utils.crippleConfig[zoneName][targetName] = true
            print(string.format("Added '%s' to the cripple ignore list for '%s'.", targetName, zoneName))
            utils.saveCrippleConfig() -- Save the configuration after adding
        else
            print(string.format("'%s' is already in the cripple ignore list for '%s'.", targetName, zoneName))
        end
    else
        print("Error: No target selected. Please target a mob to add it to the cripple ignore list.")
    end
end

-- Function to remove a mob from the cripple ignore list using its clean name
function utils.removeMobFromCrippleIgnoreList(targetName, isGlobal)
    local zoneName = isGlobal and "globalIgnoreList" or mq.TLO.Zone.ShortName() or "UnknownZone"
    
    if targetName then
        -- Check if the zone or global entry exists in the ignore list
        if utils.crippleConfig[zoneName] and utils.crippleConfig[zoneName][targetName] then
            utils.crippleConfig[zoneName][targetName] = nil  -- Remove the mob entry
            print(string.format("Removed '%s' from the cripple ignore list for '%s'.", targetName, zoneName))
            utils.saveCrippleConfig()  -- Save the updated ignore list
        else
            print(string.format("'%s' is not in the cripple ignore list for '%s'.", targetName, zoneName))
        end
    else
        print("Error: No target selected. Please target a mob to remove it from the cripple ignore list.")
    end
end

-- Save the cripple ignore list to the config file
function utils.saveCrippleConfig()
    local config = {}
    for zone, mobs in pairs(utils.crippleConfig) do
        config[zone] = mobs
    end
    mq.pickle(crippleConfigPath, config)
    print("Cripple ignore list saved to " .. crippleConfigPath)
end

return utils