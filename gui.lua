local mq = require('mq')
local ImGui = require('ImGui')

local charName = mq.TLO.Me.Name()
local configPath = mq.configDir .. '/' .. 'ConvSHM_'.. charName .. '_config.lua'
local config = {}

local gui = {}

gui.isOpen = true

local DEBUG_MODE = false
-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

local function setDefaultConfig()
    gui.botOn = false
    gui.mainAssist = ""
    gui.assistRange = 40
    gui.assistPercent = 95
    gui.assistOn = false
    gui.switchWithMA = true
    gui.returnToCamp = false
    gui.campDistance = 10
    gui.chaseOn = false
    gui.chaseTarget = ""
    gui.chaseDistance = 20
    gui.slowOn = false
    gui.slowRadius = 20
    gui.slowStopPercent = 95
    gui.slowNamedOnly = false
    gui.maloOn = false
    gui.maloRadius = 20
    gui.maloStopPercent = 95
    gui.maloNamedOnly = false
    gui.crippleOn = false
    gui.crippleRadius = 20
    gui.crippleStopPercent = 95
    gui.crippleNamedOnly = false
    gui.buffsOn = false
    gui.buffGroup = false
    gui.buffRaid = false
    gui.HasteBuff = false
    gui.StrBuff = false
    gui.StaBuff = false
    gui.AgiBuff = false
    gui.DexBuff = false
    gui.PoisonBuff = false
    gui.DiseaseBuff = false
    gui.FireBuff = false
    gui.ColdBuff = false
    gui.MagicBuff = false
    gui.RegenBuff = false
    gui.HPBuff = false
    gui.ACBuff = false
    gui.SoWBuff = false
    gui.canniOn = false
    gui.canniMinHPPercent = 30
    gui.regenHealOnly = false
    gui.torporOn = false
    gui.torporpct = 80
    gui.emergencyheal = false
    gui.emergencyhealpct = 30
    gui.mainHeal = false
    gui.mainHealPct = 40
    gui.useCures = false
    gui.sitMed = false
    gui.petOn = false
    gui.DiseaseDotOn = false
    gui.DiseaseDotStopPct = 40
    gui.DiseaseDotNamedOnly = false
    gui.PoisonDotOn = false
    gui.PoisonDotStopPct = 40
    gui.PoisonDotNamedOnly = false
        -- Extended Target Defaults for Healing
        for i = 1, 5 do
            gui["ExtTargetMainHeal" .. i] = false
            gui["ExtTargetMainHeal" .. i .. "Pct"] = 70
            gui["ExtTargetCures" .. i] = false
        end
end

function gui.saveConfig()
    for key, value in pairs(gui) do
        config[key] = value
    end
    mq.pickle(configPath, config)
    print("Configuration saved to " .. configPath)
end

local function loadConfig()
    local configData, err = loadfile(configPath)
    if configData then
        config = configData() or {}
        for key, value in pairs(config) do
            gui[key] = value
        end
    else
        print("Config file not found. Initializing with defaults.")
        setDefaultConfig()
        gui.saveConfig()
    end
end

loadConfig()

function ColoredText(text, color)
    ImGui.TextColored(color[1], color[2], color[3], color[4], text)
end

local function controlGUI()

    gui.isOpen, _ = ImGui.Begin("Convergence Shaman", gui.isOpen, 2)

        if not gui.isOpen then
            mq.exit()
        end

        ImGui.SetWindowSize(440, 600)

        gui.botOn = ImGui.Checkbox("Bot On", gui.botOn or false)

        ImGui.SameLine()

        if ImGui.Button("Save Config") then
            gui.saveConfig()

            ImGui.Spacing()

        end

        if ImGui.CollapsingHeader("Assist Settings") then

            ImGui.Spacing()
            ImGui.SetNextItemWidth(100)
            gui.mainAssist = ImGui.InputText("Assist", gui.mainAssist)


            if ImGui.IsItemDeactivatedAfterEdit() then

                if gui.mainAssist ~= "" then
                    gui.mainAssist = gui.mainAssist:sub(1, 1):upper() .. gui.mainAssist:sub(2):lower()
                end
            end

            -- Validate the spawn if the input is non-empty
            if gui.mainAssist ~= "" then
                local spawn = mq.TLO.Spawn(gui.mainAssist)
                if not (spawn and spawn.Type() == "PC") or gui.mainAssist == charName then
                    ImGui.TextColored(1, 0, 0, 1, "Invalid Target")
                end
            end

            ImGui.Spacing()
            if gui.mainAssist ~= "" then
                ImGui.Spacing()
                ImGui.SetNextItemWidth(100)
                gui.assistRange = ImGui.SliderInt("Assist Range", gui.assistRange, 5, 200)
                ImGui.Spacing()
                ImGui.SetNextItemWidth(100)
                gui.assistPercent= ImGui.SliderInt("Assist %", gui.assistPercent, 5, 100)
                ImGui.Spacing()
                gui.assistOn = ImGui.Checkbox("Assist On", gui.assistOn or false)
                if gui.assistOn then
                    ImGui.Spacing()
                    gui.switchWithMA = ImGui.Checkbox("Switch with MA", gui.switchWithMA or false)
                    ImGui.Spacing()
                    ImGui.Separator()
                    ImGui.Spacing()
                    gui.DiseaseDotOn = ImGui.Checkbox("Disease Dot", gui.DiseaseDotOn or false)
                    if gui.DiseaseDotOn then
                        ImGui.Spacing()
                        ImGui.SetNextItemWidth(100)
                        gui.DiseaseDotStopPct = ImGui.SliderInt("Disease Dot Stop%", gui.DiseaseDotStopPct, 5, 100)
                        gui.DiseaseDotNamedOnly = ImGui.Checkbox("Disease Dot Named Only", gui.DiseaseDotNamedOnly or false)
                    end
                    ImGui.Spacing()
                    ImGui.Separator()
                    ImGui.Spacing()
                    gui.PoisonDotOn = ImGui.Checkbox("Poison Dot", gui.PoisonDotOn or false)
                    if gui.PoisonDotOn then
                        ImGui.Spacing()
                        ImGui.SetNextItemWidth(100)
                        gui.PoisonDotStopPct = ImGui.SliderInt("Poison Dot Stop%", gui.PoisonDotStopPct, 5, 100)
                        gui.PoisonDotNamedOnly = ImGui.Checkbox("Poison Dot Named Only", gui.PoisonDotNamedOnly or false)
                    end
                    ImGui.Spacing()
                    ImGui.Separator()
                    ImGui.Spacing()
                    gui.petOn = ImGui.Checkbox("Use Pet", gui.petOn or false)
                end
            end
        end

        if ImGui.CollapsingHeader("Nav Settings") then

            ImGui.Spacing()

            local previousReturnToCamp = gui.returnToCamp or false
            local previousChaseOn = gui.chaseOn or false

            local currentReturnToCamp = ImGui.Checkbox("Return To Camp", gui.returnToCamp or false)
            if currentReturnToCamp ~= previousReturnToCamp then
                gui.returnToCamp = currentReturnToCamp
                    if gui.returnToCamp then
                        gui.chaseOn = false
                    else
                        local nav = require('nav')
                        nav.campLocation = nil
                    end
                previousReturnToCamp = currentReturnToCamp
            end

            if gui.returnToCamp then
                ImGui.SameLine()
                ImGui.SetNextItemWidth(100)
                gui.campDistance = ImGui.SliderInt("Camp Distance", gui.campDistance, 5, 200)
                ImGui.SameLine()
                ImGui.SetNextItemWidth(100)
                if ImGui.Button("Camp Here") then
                    local nav = require('nav')
                    nav.setCamp()
                end
            end

            local currentChaseOn = ImGui.Checkbox("Chase", gui.chaseOn or false)
            if currentChaseOn ~= previousChaseOn then
                gui.chaseOn = currentChaseOn
                    if gui.chaseOn then
                        local nav = require('nav')
                        gui.returnToCamp = false
                        nav.campLocation = nil
                        gui.pullOn = false
                    end
                previousChaseOn = currentChaseOn
            end

            if gui.chaseOn then
                ImGui.SameLine()
                ImGui.SetNextItemWidth(100)
                gui.chaseTarget = ImGui.InputText("Name", gui.chaseTarget)
                ImGui.SameLine()
                ImGui.SetNextItemWidth(100)
                gui.chaseDistance = ImGui.SliderInt("Chase Distance", gui.chaseDistance, 5, 200)
            end
        end

        ImGui.Spacing()

        if ImGui.CollapsingHeader("Malo Settings:") then

            ImGui.Spacing()

            gui.maloOn = ImGui.Checkbox("Malo", gui.maloOn or false)

            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()

            if gui.maloOn then
                -- Add Mob to Zone Ignore List Button
                if ImGui.Button("+ Malo Zone Ignore") then
                    local utils = require("utils")
                    local targetName = mq.TLO.Target.CleanName()
                    if targetName then
                        utils.addMobToMaloIgnoreList(targetName)  -- Add to the zone-specific ignore list
                        print(string.format("'%s' has been added to the malo ignore list for the current zone.", targetName))
                    else
                        print("Error: No target selected. Please target a mob to add it to the malo ignore list.")
                    end
                end

                -- Remove Mob from Zone Ignore List Button
                if ImGui.Button("- Malo Zone Ignore") then
                    local utils = require("utils")
                    local targetName = mq.TLO.Target.CleanName()
                    if targetName then
                        utils.removeMobFromMaloIgnoreList(targetName)  -- Remove from the zone-specific ignore list
                        print(string.format("'%s' has been removed from the malo ignore list for the current zone.", targetName))
                    else
                        print("Error: No target selected. Please target a mob to remove it from the malo ignore list.")
                    end
                end

                -- Add Mob to Global QuestNPC Ignore List Button
                if ImGui.Button("+ Malo Global Ignore") then
                    local utils = require("utils")
                    local targetName = mq.TLO.Target.CleanName()
                    if targetName then
                        utils.addMobToMaloIgnoreList(targetName, true)  -- Add to the global ignore list
                        print(string.format("'%s' has been added to the global quest NPC ignore list.", targetName))
                    else
                        print("Error: No target selected. Please target a mob to add it to the global quest NPC ignore list.")
                    end
                end

                -- Remove Mob from Global QuestNPC Ignore List Button
                if ImGui.Button("- Malo Global Ignore") then
                    local utils = require("utils")
                    local targetName = mq.TLO.Target.CleanName()
                    if targetName then
                        utils.removeMobFromMaloIgnoreList(targetName, true)  -- Remove from the global ignore list
                        print(string.format("'%s' has been removed from the global quest NPC ignore list.", targetName))
                    else
                        print("Error: No target selected. Please target a mob to remove it from the global quest NPC ignore list.")
                    end
                end

                ImGui.Spacing()

                gui.maloNamedOnly = ImGui.Checkbox("Malo Named Only", gui.maloNamedOnly or false)
                ImGui.Spacing()
                ImGui.SetNextItemWidth(100)
                gui.maloRadius = ImGui.SliderInt("Malo Radius", gui.maloRadius, 5, 100)
                ImGui.Spacing()
                ImGui.SetNextItemWidth(100)
                gui.maloStopPercent = ImGui.SliderInt("Malo Stop %", gui.maloStopPercent, 1, 100)

                ImGui.Spacing()

            end
        end

        if ImGui.CollapsingHeader("Slow Settings:") then

            ImGui.Spacing()

            gui.slowOn = ImGui.Checkbox("Slow", gui.slowOn or false)

            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()

            if gui.slowOn then
                -- Add Mob to Zone Ignore List Button
                if ImGui.Button("+ Slow Zone Ignore") then
                    local utils = require("utils")
                    local targetName = mq.TLO.Target.CleanName()
                    if targetName then
                        utils.addMobToSlowIgnoreList(targetName)  -- Add to the zone-specific ignore list
                        print(string.format("'%s' has been added to the slow ignore list for the current zone.", targetName))
                    else
                        print("Error: No target selected. Please target a mob to add it to the slow ignore list.")
                    end
                end

                -- Remove Mob from Zone Ignore List Button
                if ImGui.Button("- Slow Zone Ignore") then
                    local utils = require("utils")
                    local targetName = mq.TLO.Target.CleanName()
                    if targetName then
                        utils.removeMobFromSlowIgnoreList(targetName)  -- Remove from the zone-specific ignore list
                        print(string.format("'%s' has been removed from the slow ignore list for the current zone.", targetName))
                    else
                        print("Error: No target selected. Please target a mob to remove it from the slow ignore list.")
                    end
                end

                -- Add Mob to Global QuestNPC Ignore List Button
                if ImGui.Button("+ Slow Global Ignore") then
                    local utils = require("utils")
                    local targetName = mq.TLO.Target.CleanName()
                    if targetName then
                        utils.addMobToSlowIgnoreList(targetName, true)  -- Add to the global ignore list
                        print(string.format("'%s' has been added to the global quest NPC ignore list.", targetName))
                    else
                        print("Error: No target selected. Please target a mob to add it to the global quest NPC ignore list.")
                    end
                end

                -- Remove Mob from Global QuestNPC Ignore List Button
                if ImGui.Button("- Slow Global Ignore") then
                    local utils = require("utils")
                    local targetName = mq.TLO.Target.CleanName()
                    if targetName then
                        utils.removeMobFromSlowIgnoreList(targetName, true)  -- Remove from the global ignore list
                        print(string.format("'%s' has been removed from the global quest NPC ignore list.", targetName))
                    else
                        print("Error: No target selected. Please target a mob to remove it from the global quest NPC ignore list.")
                    end
                end

                ImGui.Spacing()

                gui.slowNamedOnly = ImGui.Checkbox("Slow Named Only", gui.slowNamedOnly or false)
                ImGui.Spacing()
                ImGui.SetNextItemWidth(100)
                gui.slowRadius = ImGui.SliderInt("Slow Radius", gui.slowRadius, 5, 100)
                ImGui.Spacing()
                ImGui.SetNextItemWidth(100)
                gui.slowStopPercent = ImGui.SliderInt("Slow Stop %", gui.slowStopPercent, 1, 100)

                ImGui.Spacing()

            end
        end

        if ImGui.CollapsingHeader("Cripple Settings:") then

            ImGui.Spacing()

            gui.crippleOn = ImGui.Checkbox("Cripple", gui.crippleOn or false)

            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()

            if gui.crippleOn then
                -- Add Mob to Zone Ignore List Button
                if ImGui.Button("+ Cripple Zone Ignore") then
                    local utils = require("utils")
                    local targetName = mq.TLO.Target.CleanName()
                    if targetName then
                        utils.addMobToCrippleIgnoreList(targetName)  -- Add to the zone-specific ignore list
                        print(string.format("'%s' has been added to the cripple ignore list for the current zone.", targetName))
                    else
                        print("Error: No target selected. Please target a mob to add it to the cripple ignore list.")
                    end
                end

                -- Remove Mob from Zone Ignore List Button
                if ImGui.Button("- Cripple Zone Ignore") then
                    local utils = require("utils")
                    local targetName = mq.TLO.Target.CleanName()
                    if targetName then
                        utils.removeMobFromCrippleIgnoreList(targetName)  -- Remove from the zone-specific ignore list
                        print(string.format("'%s' has been removed from the cripple ignore list for the current zone.", targetName))
                    else
                        print("Error: No target selected. Please target a mob to remove it from the cripple ignore list.")
                    end
                end

                -- Add Mob to Global QuestNPC Ignore List Button
                if ImGui.Button("+ Cripple Global Ignore") then
                    local utils = require("utils")
                    local targetName = mq.TLO.Target.CleanName()
                    if targetName then
                        utils.addMobToCrippleIgnoreList(targetName, true)  -- Add to the global ignore list
                        print(string.format("'%s' has been added to the global quest NPC ignore list.", targetName))
                    else
                        print("Error: No target selected. Please target a mob to add it to the global quest NPC ignore list.")
                    end
                end

                -- Remove Mob from Global QuestNPC Ignore List Button
                if ImGui.Button("- Cripple Global Ignore") then
                    local utils = require("utils")
                    local targetName = mq.TLO.Target.CleanName()
                    if targetName then
                        utils.removeMobFromCrippleIgnoreList(targetName, true)  -- Remove from the global ignore list
                        print(string.format("'%s' has been removed from the global quest NPC ignore list.", targetName))
                    else
                        print("Error: No target selected. Please target a mob to remove it from the global quest NPC ignore list.")
                    end
                end

                ImGui.Spacing()

                gui.crippleNamedOnly = ImGui.Checkbox("Cripple Named Only", gui.crippleNamedOnly or false)
                ImGui.Spacing()
                ImGui.SetNextItemWidth(100)
                gui.crippleRadius = ImGui.SliderInt("Cripple Radius", gui.crippleRadius, 5, 100)
                ImGui.Spacing()
                ImGui.SetNextItemWidth(100)
                gui.crippleStopPercent = ImGui.SliderInt("Cripple Stop %", gui.crippleStopPercent, 1, 100)

                ImGui.Spacing()

            end
        end

        if ImGui.CollapsingHeader("Heal Settings") then
            ImGui.Spacing()

            gui.mainHeal = ImGui.Checkbox("Main Heal", gui.mainHeal or false)
            if gui.mainHeal then
                ImGui.SetNextItemWidth(100)
                ImGui.SameLine()
                gui.mainHealPct = ImGui.SliderInt("MH %", gui.mainHealPct, 1, 100)
                ImGui.Spacing()
                if ImGui.CollapsingHeader("Main Heal - Extended Target Settings") then
                    for i = 1, 5 do
                        gui["ExtTargetMainHeal" .. i] = ImGui.Checkbox("MH Ext Target " .. i, gui["ExtTargetMainHeal" .. i] or false)
                        if gui["ExtTargetMainHeal" .. i] then
                            ImGui.SameLine()
                            ImGui.SetNextItemWidth(100)
                            gui["ExtTargetMainHeal" .. i .. "Pct"] = ImGui.SliderInt("MH Ext Target " .. i .. " %", gui["ExtTargetMainHeal" .. i .. "Pct"] or 70, 1, 100)
                        end
                    end
                end
            end

            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()

            gui.useCures = ImGui.Checkbox("Cures", gui.useCures or false)
            if gui.useCures then
                ImGui.Spacing()
                if ImGui.CollapsingHeader("Cure - Extended Target Settings") then
                    for i = 1, 5 do
                        gui["ExtTargetCures" .. i] = ImGui.Checkbox("Cure Ext Target " .. i, gui["ExtTargetCures" .. i] or false)
                    end
                end
            end
        end

        if ImGui.CollapsingHeader("Buff Settings") then
            gui.buffsOn = ImGui.Checkbox("Buffs", gui.buffsOn or false)
            if gui.buffsOn then

                if gui.botOn then
                    local utils = require("utils")
                    local currentTime = os.time()
                    local timeLeft = math.max(0, utils.nextBuffTime - currentTime)
        
                    if timeLeft > 0 then
                        ImGui.Text(string.format("Buff Check In: %d seconds", timeLeft))
                    else
                        ImGui.Text("Buff Check Running.")
                    end
                else
                    ImGui.Text("Bot is not active.")
                end

                ImGui.Spacing()

                if ImGui.Button("Force Buff Check") then
                    local utils = require("utils")
                    utils.nextBuffTime = 0
                end

                ImGui.Spacing()

                gui.buffGroup = ImGui.Checkbox("Buff Group", gui.buffGroup or false)
                if gui.buffGroup then
                    gui.buffRaid = false
                end

                ImGui.SameLine()

                gui.buffRaid = ImGui.Checkbox("Buff Raid", gui.buffRaid or false)
                if gui.buffRaid then
                    gui.buffGroup = false
                end

                ImGui.Spacing()
                ImGui.Separator()
                ImGui.Spacing()

                gui.HPBuff = ImGui.Checkbox("HP", gui.HPBuff or false)
                ImGui.SameLine()
                gui.ACBuff = ImGui.Checkbox("AC", gui.ACBuff or false)

                ImGui.Spacing()

                gui.SoWBuff = ImGui.Checkbox("SOW", gui.SoWBuff or false)

                ImGui.Spacing()

                gui.RegenBuff = ImGui.Checkbox("Regen", gui.RegenBuff or false)

                ImGui.Spacing()

                gui.HasteBuff = ImGui.Checkbox("Haste", gui.HasteBuff or false)

                ImGui.Spacing()

                gui.StrBuff = ImGui.Checkbox("STR", gui.StrBuff or false)
                ImGui.SameLine()
                gui.StaBuff = ImGui.Checkbox("STA", gui.StaBuff or false)
                ImGui.SameLine()
                gui.AgiBuff = ImGui.Checkbox("AGI", gui.AgiBuff or false)
                ImGui.SameLine()
                gui.DexBuff = ImGui.Checkbox("DEX", gui.DexBuff or false)

                ImGui.Spacing()

                gui.PoisonBuff = ImGui.Checkbox("Poison", gui.PoisonBuff or false)
                ImGui.SameLine()
                gui.DiseaseBuff = ImGui.Checkbox("Disease", gui.DiseaseBuff or false)
                ImGui.SameLine()
                gui.FireBuff = ImGui.Checkbox("Fire", gui.FireBuff or false)
                ImGui.SameLine()
                gui.ColdBuff = ImGui.Checkbox("Cold", gui.ColdBuff or false)
                ImGui.SameLine()
                gui.MagicBuff = ImGui.Checkbox("Magic", gui.MagicBuff or false)

                ImGui.Spacing()

            end
        end

        if ImGui.CollapsingHeader("Misc Settings") then

            ImGui.Spacing()

            gui.sitMed = ImGui.Checkbox("Sit to Med", gui.sitMed or false)

            gui.canniOn = ImGui.Checkbox("Cannibalize", gui.canniOn or false)
            if gui.canniOn then
                ImGui.SetNextItemWidth(100)
                ImGui.SameLine()
                gui.canniMinHPPercent = ImGui.SliderInt("Canni Min HP%", gui.canniMinHPPercent, 10, 100)
                gui.regenHealOnly = ImGui.Checkbox("Passive Heal Self Only", gui.regenHealOnly or false)
                if gui.regenHealOnly then

                    ImGui.Spacing()

                    gui.torporOn = ImGui.Checkbox("Use Torpor", gui.torporOn or false)
                        if gui.torporOn then
                            ImGui.SetNextItemWidth(100)
                            ImGui.SameLine()
                            gui.torporpct = ImGui.SliderInt("Torpor HP%", gui.torporpct, 10, 100)
                        end
                    ImGui.Spacing()

                    gui.emergencyheal = ImGui.Checkbox("Emergency Heal", gui.emergencyheal or false)
                    ImGui.SameLine()
                    if gui.emergencyheal then
                        ImGui.SetNextItemWidth(100)
                        gui.emergencyhealpct = ImGui.SliderInt("Emergency Heal %", gui.emergencyhealpct, 10, 100)
                    end
                end
            end

            ImGui.Spacing()
        end
    ImGui.End()
end

gui.controlGUI = controlGUI

return gui