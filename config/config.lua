Config = {}

-- Framework Support: 'qb', 'qbx', 'esx', 'auto'
-- 'auto' will automatically detect which framework is available
Config.Framework = 'auto'

-- Interaction System Support: 'ox_target', 'ox_lib', 'qb-target', 'auto'
-- 'auto' will automatically detect which interaction system is available
Config.InteractionType = 'auto'

-- Inventory System Support: 'auto' will detect automatically
-- Supported: qb-inventory, ox_inventory, esx_inventory
Config.Inventory = 'auto'

Config.RequireJob = false -- Set this to true for requireing a job to change plates / false for everyone to be able to change plates with the items

Config.Job = "dmv" -- If Config.RequireJob is set to true this will be the whitelisted job

Config.Item = "licenseplate" -- Item required for changing plates

Config.Lang = "en" -- name of the lang file

-- NPC Settings
Config.EnableNPC = true -- Set to false to disable the NPC
Config.NPCPrice = 5000 -- Price for buying a license plate from NPC
Config.NPCCoords = vector4(1188.85, 2640.11, 38.4, 84.99) -- x, y, z, heading for NPC location
Config.NPCModel = "s_m_y_cop_01" -- NPC model
Config.NPCBlip = {
    enabled = true,
    sprite = 430,
    color = 3,
    scale = 0.8,
    name = "License Plate Shop"
}