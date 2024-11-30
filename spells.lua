mq = require('mq')

local DEBUG_MODE = false
-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

local spells = {
    Malo = {
        {level = 60, name = "Malo"},
        {level = 57, name = "Malosini"},
        {level = 48, name = "Malosi"},
        {level = 32, name = "Malaisement"},
        {level = 18, name = "Malaise"}
    },
    Slow = {
        {level = 51, name = "Turgur's Insects"},
        {level = 38, name = "Togor's Insects"},
        {level = 27, name = "Tagar's Insects"},
        {level = 13, name = "Walking Sleep"},
        {level = 5, name = "Drowsy"}
    },
    Cripple = {
        {level = 53, name = "Cripple"},
        {level = 41, name = "Incapacitate"},
        {level = 29, name = "Listless Power"},
        {level = 12, name = "Disempower"}
    },
    PoisonDot = {
        {level = 56, name = "Bane of Nife"},
        {level = 49, name = "Envenomed Bolt"},
        {level = 37, name = "Venom of the Snake"},
        {level = 24, name = "Envenomed Breath"},
        {level = 8, name = "Tainted Breath"}
    },
    DiseaseDot = {
        {level = 59, name = "Pox of Bertoxxulous"},
        {level = 49, name = "Plague"},
        {level = 31, name = "Scourge"},
        {level = 19, name = "Affliction"},
        {level = 15, name = "Infectious Cloud"},
        {level = 4, name = "Sicken"}
    },
    RegenBuff = {
        {level = 52, name = "Regrowth"},
        {level = 39, name = "Chloroplast"},
        {level = 23, name = "Regeneration"}
    },
    SoWBuff = {
        {level = 9, name = "Spirit of Wolf"}
    },
    HPBuff = {
        {level = 59, name = "Kragg's Harnessing"},
        {level = 55, name = "Talisman of Kragg"},
        {level = 40, name = "Talisman of Altuna"},
        {level = 32, name = "Talisman of Tnarg"},
        {level = 1, name = "Inner Fire"}
    },
    ACBuff = {
        {level = 54, name = "Shroud of the Spirits"},
        {level = 42, name = "Guardian"},
        {level = 31, name = "Shifting Shield"},
        {level = 20, name = "Protect"},
        {level = 11, name = "Turtle Skin"},
        {level = 3, name = "Scale Skin"}
    },
    Canni = {
        {level = 54, name = "Cannibalize III"},
        {level = 38, name = "Cannibalize II"},
        {level = 23, name = "Cannibalize"}
    },
    Heal = {
        {level = 51, name = "Superior Healing"},
        {level = 29, name = "Greater Healing"},
        {level = 19, name = "Healing"},
        {level = 9, name = "Light Healing"},
        {level = 1, name = "Minor Healing"}
    },
    Haste = {
        {level = 60, name = "Unity of the Shissar"},
        {level = 56, name = "Celerity"},
        {level = 42, name = "Alacrity"},
        {level = 26, name = "Quickness"}
    },
    StrBuff = {
        {level = 60, name = "Unity of the Shissar"},
        {level = 58, name = "Talisman of the Rhino"},
        {level = 57, name = "Maniacal Strength"},
        {level = 46, name = "Strength"},
        {level = 39, name = "Furious Strength"},
        {level = 28, name = "Raging Strength"},
        {level = 18, name = "Spirit Strength"},
        {level = 1, name = "Strengthen"}
    },
    StaBuff = {
        {level = 60, name = "Unity of the Shissar"},
        {level = 57, name = "Talisman of the Brute"},
        {level = 54, name = "Riotous Health"},
        {level = 43, name = "Stamina"},
        {level = 30, name = "Health"},
        {level = 21, name = "Spirit of Ox"},
        {level = 6, name = "Spirit of Bear"}
    },
    AgiBuff = {
        {level = 60, name = "Unity of the Shissar"},
        {level = 57, name = "Talisman of the Cat"},
        {level = 53, name = "Deliriously Nimble"},
        {level = 41, name = "Agility"},
        {level = 31, name = "Nimble"},
        {level = 18, name = "Spirit of Cat"},
        {level = 3, name = "Feet like Cat"}
    },
    DexBuff = {
        {level = 60, name = "Unity of the Shissar"},
        {level = 59, name = "Talisman of the Raptor"},
        {level = 58, name = "Mortal Deftness"},
        {level = 48, name = "Dexterity"},
        {level = 39, name = "Deftness"},
        {level = 25, name = "Rising Dexterity"},
        {level = 21, name = "Spirit of Monkey"},
        {level = 1, name = "Dexterous Aura"}
    },
    DiseaseBuff = {
        {level = 60, name = "Talisman of Purity"},
        {level = 50, name = "Talisman of Jasinth"},
        {level = 30, name = "Resist Disease"},
        {level = 8, name = "Endure Disease"}
    },
    CureDisease = {
        {level = 48, name = "Abolish Disease"},
        {level = 22, name = "Counteract Disease"},
        {level = 1, name = "Cure Disease"}
    },
    PoisonBuff = {
        {level = 60, name = "Talisman of Purity"},
        {level = 53, name = "Talisman of Shadoo"},
        {level = 35, name = "Resist Poison"},
        {level = 11, name = "Endure Poison"}
    },
    CurePoison = {
        {level = 26, name = "Counteract Poison"},
        {level = 2, name = "Cure Poison"}
    },
    FireBuff = {
        {level = 27, name = "Resist Fire"},
        {level = 5, name = "Endure Fire"}
    },
    ColdBuff = {
        {level = 24, name = "Resist Cold"},
        {level = 1, name = "Endure Cold"}
    },
    MagicBuff = {
        {level = 43, name = "Resist Magic"},
        {level = 19, name = "Endure Magic"}
    },
    SummonPet = {
        {level = 55, name = "Spirit of the Howler"},
        {level = 45, name = "Frenzied Spirit"},
        {level = 41, name = "Guardian Spirit"},
        {level = 37, name = "Vigilant Spirit"},
        {level = 32, name = "Companion Spirit"}
    },
    Torpor = {
        {level = 59, name = "Torpor"}
    },
    Unity = {
        {level = 60, name = "Unity of the Shissar"}
    }
}

-- Function to find the best spell for a given type and level
function spells.findBestSpell(spellType, charLevel)
    local spellsList = spells[spellType]

    if not spellsList then
        return nil -- Return nil if the spell type doesn't exist
    end

    -- Special handling for DiseaseBuff and PoisonBuff at level 60
    if (spellType == "DiseaseBuff" or spellType == "PoisonBuff") and charLevel == 60 then
        if mq.TLO.Me.Book('Talisman of Purity')() then
            debugPrint("Using Talisman of Purity for Disease and Poison Resist at level 60")
            return "Talisman of Purity"
        elseif spellType == "DiseaseBuff" then
            debugPrint("Falling back to Talisman of Jasinth for Disease Resist at level 60")
            return "Talisman of Jasinth"
        elseif spellType == "PoisonBuff" then
            debugPrint("Falling back to Talisman of Shadoo for Poison Resist at level 60")
            return "Talisman of Shadoo"
        end
    end

    -- Special handling for Unity of the Shissar at level 60
    if (spellType == "Haste" or spellType == "StrBuff" or spellType == "StaBuff" or spellType == "AgiBuff" or spellType == "DexBuff") and charLevel == 60 then
        if mq.TLO.Me.Book('Unity of the Shissar')() then
            debugPrint("Using Unity of the Shissar for Buffs at level 60")
            return "Unity of the Shissar"
        else
            -- Fall back to individual spell options for each type
            local fallbacks = {
                Haste = "Celerity",
                StrBuff = "Talisman of the Rhino",
                StaBuff = "Talisman of the Brute",
                AgiBuff = "Talisman of the Cat",
                DexBuff = "Talisman of the Raptor"
            }
            local fallbackSpell = fallbacks[spellType]
            if fallbackSpell then
                debugPrint("Falling back to", fallbackSpell, "for", spellType, "at level 60")
                return fallbackSpell
            end
        end
    end

    -- Special handling for Malo at level 60
    if spellType == "Malo" and charLevel == 60 then
        if mq.TLO.Me.Book('Malo')() then
            debugPrint("Using Malo for Malo at level 60")
            return "Malo"
        else
            debugPrint("Falling back to Malosini for Malo at level 60")
            return "Malosini"
        end
    end

    -- General spell search for other types and levels
    for _, spell in ipairs(spellsList) do
        if charLevel >= spell.level then
            debugPrint("Using spell", spell.name, "for type", spellType, "at level", charLevel)
            return spell.name
        end
    end

    return nil
end

function spells.loadDefaultSpells(charLevel)
    local defaultSpells = {}
    local slot = 1 -- Initialize slot counter

    if charLevel >= 18 then
        defaultSpells[slot] = spells.findBestSpell("Malo", charLevel)
        print("Slot " .. slot .. ": Malo")
        slot = slot + 1
    end
    if charLevel >= 5 then
        defaultSpells[slot] = spells.findBestSpell("Slow", charLevel)
        print("Slot " .. slot .. ": Slow")
        slot = slot + 1
    end
    if charLevel >= 12 then
        defaultSpells[slot] = spells.findBestSpell("Cripple", charLevel)
        print("Slot " .. slot .. ": Cripple")
        slot = slot + 1
    end
    if charLevel >= 8 then
        defaultSpells[slot] = spells.findBestSpell("PoisonDot", charLevel)
        print("Slot " .. slot .. ": PoisonDot")
        slot = slot + 1
    end
    if charLevel >= 4 then
        defaultSpells[slot] = spells.findBestSpell("DiseaseDot", charLevel)
        print("Slot " .. slot .. ": DiseaseDot")
        slot = slot + 1
    end
    if charLevel >= 2 then
        defaultSpells[slot] = spells.findBestSpell("SoWBuff", charLevel)
        print("Slot " .. slot .. ": SoWBuff")
        slot = slot + 1
    end
    if charLevel >= 23 then
        defaultSpells[slot] = spells.findBestSpell("RegenBuff", charLevel)
        print("Slot " .. slot .. ": RegenBuff")
        slot = slot + 1
    end
    if charLevel >= 59 then
        defaultSpells[slot] = spells.findBestSpell("Torpor", charLevel)
        print("Slot " .. slot .. ": Torpor")
        slot = slot + 1
    end
    if charLevel >= 23 then
        defaultSpells[slot] = spells.findBestSpell("Canni", charLevel)
        print("Slot " .. slot .. ": Canni")
        slot = slot + 1
    end
    if charLevel >= 1 then
        defaultSpells[slot] = spells.findBestSpell("Heal", charLevel)
        print("Slot " .. slot .. ": Heal")
        slot = slot + 1
    end

    return defaultSpells
end

-- Function to memorize spells in the correct slots with delay
function spells.memorizeSpells(spells)
    for slot, spellName in pairs(spells) do
        if spellName then
            -- Check if the spell is already in the correct slot
            if mq.TLO.Me.Gem(slot)() == spellName then
                printf(string.format("Spell %s is already memorized in slot %d", spellName, slot))
            else
                -- Clear the slot first to avoid conflicts
                mq.cmdf('/memorize "" %d', slot)
                mq.delay(500)  -- Short delay to allow the slot to clear

                -- Issue the /memorize command to memorize the spell in the slot
                mq.cmdf('/memorize "%s" %d', spellName, slot)
                mq.delay(1000)  -- Initial delay to allow the memorization command to take effect

                -- Loop to check if the spell is correctly memorized
                local maxAttempts = 10
                local attempt = 0
                while mq.TLO.Me.Gem(slot)() ~= spellName and attempt < maxAttempts do
                    mq.delay(500)  -- Check every 0.5 seconds
                    attempt = attempt + 1
                end

                -- Check if memorization was successful
                if mq.TLO.Me.Gem(slot)() ~= spellName then
                    printf(string.format("Failed to memorize spell: %s in slot %d", spellName, slot))
                else
                    printf(string.format("Successfully memorized %s in slot %d", spellName, slot))
                end
            end
        end
    end
end

function spells.loadAndMemorizeSpell(spellType, level, spellSlot)

    local bestSpell = spells.findBestSpell(spellType, level)

    if not bestSpell then
        printf("No spell found for type: " .. spellType .. " at level: " .. level)
        return
    end

    -- Check if the spell is already in the correct spell gem slot
    if mq.TLO.Me.Gem(spellSlot).Name() == bestSpell then
        printf("Spell " .. bestSpell .. " is already memorized in slot " .. spellSlot)
        return true
    end

    -- Memorize the spell in the correct slot
    mq.cmdf('/memorize "%s" %d', bestSpell, spellSlot)

    -- Add a delay to wait for the spell to be memorized
    local maxAttempts = 10
    local attempt = 0
    while mq.TLO.Me.Gem(spellSlot).Name() ~= bestSpell and attempt < maxAttempts do
        mq.delay(2000) -- Wait 2 seconds before checking again
        attempt = attempt + 1
    end

    -- Check if the spell is now memorized correctly
    if mq.TLO.Me.Gem(spellSlot).Name() == bestSpell then
        printf("Successfully memorized spell " .. bestSpell .. " in slot " .. spellSlot)
        return true
    else
        printf("Failed to memorize spell " .. bestSpell .. " in slot " .. spellSlot)
        return false
    end
end

function spells.startup(charLevel)

    local defaultSpells = spells.loadDefaultSpells(charLevel)

    spells.memorizeSpells(defaultSpells)
end

return spells