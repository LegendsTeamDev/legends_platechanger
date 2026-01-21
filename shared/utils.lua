local Utils = {}

function Utils.GetFramework()
    if Config.Framework == 'auto' then
        if GetResourceState('qbx_core') == 'started' then
            return 'qbx'
        elseif GetResourceState('qb-core') == 'started' then
            return 'qb'
        elseif GetResourceState('es_extended') == 'started' then
            return 'esx'
        else
            print("^1[ERROR] No supported framework detected!")
            return nil
        end
    end
    return Config.Framework
end

function Utils.GetTargetSystem()
    if Config.InteractionType == 'auto' then
        if GetResourceState('ox_target') == 'started' then
            return 'ox_target'
        elseif GetResourceState('qb-target') == 'started' then
            return 'qb-target'
        else
            return 'none'
        end
    end
    return Config.InteractionType
end

function Utils.GetInventorySystem()
    if Config.Inventory == 'auto' then
        if GetResourceState('ox_inventory') == 'started' then
            return 'ox_inventory'
        elseif GetResourceState('qb-inventory') == 'started' then
            return 'qb-inventory'
        elseif GetResourceState('esx_inventory') == 'started' then
            return 'esx_inventory'
        else
            local framework = Utils.GetFramework()
            if framework == 'esx' then
                return 'esx_inventory'
            else
                return 'qb-inventory'
            end
        end
    end
    return Config.Inventory
end

function Utils.GetCoreObject()
    local framework = Utils.GetFramework()
    if framework == 'qb' then
        return exports['qb-core']:GetCoreObject()
    elseif framework == 'qbx' then
        return exports.qbx_core
    elseif framework == 'esx' then
        return exports["es_extended"]:getSharedObject()
    end
    return nil
end

function Utils.GetPlayerData()
    local framework = Utils.GetFramework()

    if framework == 'qb' then
        local core = Utils.GetCoreObject()
        if not core then return nil end
        return core.Functions and core.Functions.GetPlayerData and core.Functions.GetPlayerData() or nil
    elseif framework == 'qbx' then
        if GetResourceState('qbx_core') == 'started' then
            return exports.qbx_core:GetPlayerData()
        end
        return nil
    elseif framework == 'esx' then
        local core = Utils.GetCoreObject()
        if not core then return nil end
        return core.GetPlayerData and core.GetPlayerData() or nil
    end
    return nil
end

function Utils.HasRequiredJob(playerData)
    if not Config.RequireJob then return true end

    local framework = Utils.GetFramework()
    if framework == 'qb' or framework == 'qbx' then
        return playerData.job and playerData.job.name == Config.Job
    elseif framework == 'esx' then
        return playerData.job and playerData.job.name == Config.Job
    end
    return false
end

Utils.Target = {}

function Utils.Target.AddEntityTarget(entity, options)
    local targetSystem = Utils.GetTargetSystem()

    if targetSystem == 'ox_target' then
        local oxOptions = {}
        for _, option in ipairs(options) do
            table.insert(oxOptions, {
                name = option.name,
                icon = option.icon,
                label = option.label,
                distance = option.distance,
                canInteract = option.canInteract,
                onSelect = function()
                    TriggerEvent('legends_platechanger:client:BuyPlateFromNPC')
                end
            })
        end
        exports.ox_target:addLocalEntity(entity, oxOptions)
    elseif targetSystem == 'qb-target' then
        local qbOptions = {}
        for _, option in ipairs(options) do
            table.insert(qbOptions, {
                type = "client",
                event = "legends_platechanger:client:BuyPlateFromNPC",
                icon = option.icon,
                label = option.label,
                canInteract = option.canInteract
            })
        end

        exports['qb-target']:AddTargetEntity(entity, {
            options = qbOptions,
            distance = 2.5
        })
    elseif targetSystem == 'none' or targetSystem == 'ox_lib' then
        if not Utils.Target.entities then Utils.Target.entities = {} end
        Utils.Target.entities[entity] = options
    end
end

function Utils.Target.RemoveEntityTarget(entity, targetName)
    local targetSystem = Utils.GetTargetSystem()

    if targetSystem == 'ox_target' then
        exports.ox_target:removeLocalEntity(entity, targetName)
    elseif targetSystem == 'qb-target' then
        exports['qb-target']:RemoveTargetEntity(entity)
    elseif targetSystem == 'none' or targetSystem == 'ox_lib' then
        if Utils.Target.entities then
            Utils.Target.entities[entity] = nil
        end
    end
end

Utils.Inventory = {}

function Utils.Inventory.HasItem(itemName, source)
    local inventorySystem = Utils.GetInventorySystem()
    local framework = Utils.GetFramework()
    local core = Utils.GetCoreObject()

    if not core then return false end

    if inventorySystem == 'ox_inventory' then
        if IsDuplicityVersion() then
            return exports.ox_inventory:GetItemCount(source, itemName) > 0
        else
            return exports.ox_inventory:Search('count', itemName) > 0
        end
    elseif framework == 'qb' then
        if IsDuplicityVersion() then
            local Player = core.Functions and core.Functions.GetPlayer and core.Functions.GetPlayer(source)
            if not Player then return false end
            return Player.Functions.GetItemByName(itemName) ~= nil
        else
            local playerData = Utils.GetPlayerData()
            if not playerData or not playerData.items then return false end
            for _, item in pairs(playerData.items) do
                if item.name == itemName then
                    return true
                end
            end
        end
    elseif framework == 'qbx' then
        if IsDuplicityVersion() then
            local Player = exports.qbx_core:GetPlayer(source)
            if not Player then return false end
            return Player.Functions.GetItemByName(itemName) ~= nil
        else
            local playerData = Utils.GetPlayerData()
            if not playerData or not playerData.items then return false end
            for _, item in pairs(playerData.items) do
                if item.name == itemName then
                    return true
                end
            end
        end
    elseif framework == 'esx' then
        if IsDuplicityVersion() then
            local xPlayer = core.GetPlayerFromId and core.GetPlayerFromId(source)
            if not xPlayer then return false end
            return xPlayer.getInventoryItem(itemName).count > 0
        else
            local playerData = core.GetPlayerData and core.GetPlayerData()
            if not playerData or not playerData.inventory then return false end
            for _, item in pairs(playerData.inventory) do
                if item.name == itemName then
                    return item.count > 0
                end
            end
        end
    end
    return false
end

function Utils.Inventory.RemoveItem(source, itemName, amount)
    local inventorySystem = Utils.GetInventorySystem()
    local framework = Utils.GetFramework()
    local core = Utils.GetCoreObject()

    if not core then return false end

    if inventorySystem == 'ox_inventory' then
        return exports.ox_inventory:RemoveItem(source, itemName, amount)
    elseif framework == 'qb' then
        local Player = core.Functions and core.Functions.GetPlayer and core.Functions.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.RemoveItem(itemName, amount)
    elseif framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(source)
        if not Player then return false end
        return Player.Functions.RemoveItem(itemName, amount)
    elseif framework == 'esx' then
        local xPlayer = core.GetPlayerFromId and core.GetPlayerFromId(source)
        if not xPlayer then return false end
        xPlayer.removeInventoryItem(itemName, amount)
        return true
    end
    return false
end

function Utils.Inventory.AddItem(source, itemName, amount)
    local inventorySystem = Utils.GetInventorySystem()
    local framework = Utils.GetFramework()
    local core = Utils.GetCoreObject()

    if not core then return false end

    if inventorySystem == 'ox_inventory' then
        return exports.ox_inventory:AddItem(source, itemName, amount)
    elseif framework == 'qb' then
        local Player = core.Functions and core.Functions.GetPlayer and core.Functions.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.AddItem(itemName, amount)
    elseif framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(source)
        if not Player then return false end
        return Player.Functions.AddItem(itemName, amount)
    elseif framework == 'esx' then
        local xPlayer = core.GetPlayerFromId and core.GetPlayerFromId(source)
        if not xPlayer then return false end
        xPlayer.addInventoryItem(itemName, amount)
        return true
    end
    return false
end

return Utils
