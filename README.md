version=1.0.0

# Convergence Shaman Bot Command Guide

### Start Script
- **Command:** `/lua run ConvSHM`
- **Description:** Starts the Lua script Convergence Cleric.

## General Bot Commands
These commands control general bot functionality, allowing you to start, stop, or save configurations.

### Exit Bot
- **Command:** `/ConvSHM exit`
- **Description:** Closes the bot’s GUI, effectively stopping any active commands.

### Enable Bot
- **Command:** `/ConvSHM bot on`
- **Description:** Activates the bot, enabling it to start running automated functions.

### Disable Bot
- **Command:** `/ConvSHM bot off`
- **Description:** Stops the bot from performing any actions, effectively pausing its behavior.

### Save Settings
- **Command:** `/ConvSHM save`
- **Description:** Saves the current settings, preserving any configuration changes.

---

### Set Main Assist
- **Command:** `/ConvSHM assist <name>`
- **Description:** Sets the main assist for the bot to follow in assisting with attacks.

### Set Assist Range
- **Command:** `/ConvSHM assistRange <value>`
- **Description:** Specifies the distance within which the bot will assist the main assist's target.

### Set Assist Percent
- **Command:** `/ConvSHM assistPercent <value>`
- **Description:** Sets the health percentage of the target at which the bot will begin assisting.

---

## Healing
These commands control various healing modes.

### Toggle Main Heal
- **Command:** `/ConvSHM mainheal <on|off>`
- **Description:** Enables or disables normal healing for characters.

### Toggle Cure Usage
- **Command:** `/ConvSHM cures <on|off>`
- **Description:** Enables or disables the use of cures during combat.

---

## Group or Raid Buff Control
These commands control who you want to buff.

### Set Buff Group
- **Command:** `/ConvSHM buffgroup <on|off>`
- **Description:** Enables or disables group buffing for the current group members.

### Set Buff Raid
- **Command:** `/ConvSHM buffraid <on|off>`
- **Description:** Enables or disables raid-wide buffing for all raid members.

---


## Resistance Buff Commands
These commands control different resistance buffs, protecting characters from various damage types.

### Resist Magic
- **Command:** `/ConvSHM buffmagic <on|off>`
- **Description:** Toggles magic resistance buff.

### Resist Fire
- **Command:** `/ConvSHM bufffire <on|off>`
- **Description:** Toggles fire resistance buff.

### Resist Cold
- **Command:** `/ConvSHM buffcold <on|off>`
- **Description:** Toggles cold resistance buff.

### Resist Disease
- **Command:** `/ConvSHM buffdisease <on|off>`
- **Description:** Toggles disease resistance buff.
  
### Resist Poison
- **Command:** `/ConvSHM buffpoison <on|off>`
- **Description:** Toggles poison resistance buff.

---

## Other Utility Commands
Additional bot features to control epic use, meditating, and specific skills.

### Toggle Sit/Med
- **Command:** `/ConvSHM sitmed <on|off>`
- **Description:** Allows the bot to enter sit/meditate mode for faster mana regeneration.

---

## Navigation Commands
Commands to control navigation settings and camping behavior.

### Set Camp Here
- **Command:** `/ConvSHM camphere <distance|on|off>`
- **Description:** Sets the current location as the camp location, with optional distance.

### Enable Return to Camp
- **Command:** `/ConvSHM camphere on`
- **Description:** Enables automatic return to camp when moving too far.

### Disable Return to Camp
- **Command:** `/ConvSHM camphere off`
- **Description:** Disables automatic return to camp.

### Set Camp Distance
- **Command:** `/ConvSHM camphere <distance>`
- **Description:** Sets the distance limit from camp before auto-return is triggered.
- **Usage:** Type `/ConvSHM camphere 100`.

### Set Chase Target and Distance
- **Command:** `/ConvSHM chase <target> <distance> | on | off`
- **Description:** Sets a target and distance for the bot to chase.
- **Usage:** Type `/ConvSHM chase <target> <distance>` or `/ConvSHM chase off`.
- **Example:** `/ConvSHM chase John 30` will set the character John as the chase target at a distance of 30.
- **Example:** `/ConvSHM chase off` will turn chasing off.

---