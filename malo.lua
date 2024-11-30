local mq = require('mq')
local gui = require('gui')
local spells = require('spells')
local utils = require('utils')

local malo = {}

local DEBUG_MODE = false
-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

local maloQueue = {} -- Table to keep track of maloed mobs with timestamps
local maloDuration = 30 -- Duration in seconds to keep a mob in the queue

local charLevel = mq.TLO.Me.Level()
debugPrint("DEBUG: Character level:", charLevel)

local function isMaloedRecently(mobID)
    local entry = maloQueue[mobID]
    if entry then
        local elapsed = os.time() - entry
        if elapsed < maloDuration then
            return true
        else
            maloQueue[mobID] = nil -- Remove expired entry
        end
    end
    return false
end

local function addToQueue(mobID)
    maloQueue[mobID] = os.time()
end

local function findNearbyUnmaloedMob()
    local assistRange = gui.assistRange
    local currentZone = mq.TLO.Zone.ShortName()
    local nearbyMobs = mq.getFilteredSpawns(function(spawn)
        return spawn.Type() == "NPC" and spawn.Distance() <= assistRange and spawn.LineOfSight() and (not gui.maloNamedOnly or spawn.Named())
    end)

    if not nearbyMobs or #nearbyMobs == 0 then
        debugPrint("DEBUG: No nearby mobs found.")
        return nil
    end

    for _, mob in ipairs(nearbyMobs) do
        local mobID = mob.ID()
        local mobName = mob.CleanName()

        -- Check maloConfig for the current zone and mob name or global ignore list
        if (utils.maloConfig.globalIgnoreList and utils.maloConfig.globalIgnoreList[mobName]) or
        (utils.maloConfig[currentZone] and utils.maloConfig[currentZone][mobName]) then
            debugPrint("DEBUG: Skipping mob:", mobName, "as it is in the maloConfig global or zone-specific list.")
            goto continue
        end

        debugPrint("DEBUG: Checking mob ID:", mobID)

        -- Target the mob and check if it's unmaloed
        mq.cmdf("/target id %d", mobID)
        mq.delay(100, function() return mq.TLO.Target.ID() == mobID end)

        if mq.TLO.Target.ID() == mobID and not mq.TLO.Target.Maloed() and not isMaloedRecently(mobID) then
            debugPrint("DEBUG: Found unmaloed mob:", mobName)
            return mob
        end

        ::continue::
    end

    debugPrint("DEBUG: No unmaloed mobs found.")
    return nil
end

function malo.maloRoutine()

    if gui.botOn and gui.maloOn and charLevel >= 18 then

        local maloSpell = spells.findBestSpell("Malo", charLevel)
        local mob = findNearbyUnmaloedMob()

        if maloSpell and mob and gui.maloOn then
            local mobID = mob.ID()

            if mq.TLO.Me.PctMana() < 10 then
                return
            end

            if mq.TLO.Me.Gem(1)() ~= maloSpell then
                spells.loadAndMemorizeSpell("Malo", charLevel, 1)
                debugPrint("DEBUG: Loaded Malo spell in slot 1")
            end

            local readyAttempt = 0
            while not mq.TLO.Me.SpellReady(maloSpell)() and readyAttempt < 20 do
                readyAttempt = readyAttempt + 1
                debugPrint("DEBUG: Waiting for Malo spell to be ready, attempt:", readyAttempt)
                mq.delay(500)
            end

            if mq.TLO.Target() and mq.TLO.Target.PctHPs() > gui.maloStopPercent and not mq.TLO.Target.Named() then
                debugPrint("DEBUG: Casting Malo on mob - ID:", mobID)
                mq.cmdf("/cast %s", maloSpell)
                mq.delay(100)
            end

            while mq.TLO.Me.Casting() do
                if mq.TLO.Target.Maloed() then
                    debugPrint("DEBUG: Malo successfully applied to mob - ID:", mobID)
                    addToQueue(mobID)
                    mq.delay(100)
                    break
                end
                if mq.TLO.Target() and mq.TLO.Target.PctHPs() <= gui.maloStopPercent and not mq.TLO.Target.Named() then
                    debugPrint("DEBUG: Stopping cast: target HP above 95%")
                    mq.cmd('/stopcast')
                    break
                end
                mq.delay(10)
            end

            if mq.TLO.Target.Maloed() then
                addToQueue(mobID)
                return true
            end
        else
            return
        end
    else
        return
    end
end

return malo