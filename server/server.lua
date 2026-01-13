local Utils = require 'shared.utils'
local QBCore, ESX, QBX

CreateThread(function()
    local framework = Utils.GetFramework()
    if framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif framework == 'qbx' then
        QBX = exports.qbx_core
    elseif framework == 'esx' then
        ESX = exports["es_extended"]:getSharedObject()
    end
end)

lib.callback.register('legends_platechanger:server:CheckOwnerVehicle', function(source, oldPlate)
    local framework = Utils.GetFramework()

    if framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end

        local result = MySQL.single.await('SELECT plate FROM player_vehicles WHERE plate = ? AND citizenid = ?', {oldPlate, Player.PlayerData.citizenid})
        if result then return true end

        local trimmedResult = MySQL.single.await('SELECT plate FROM player_vehicles WHERE REPLACE(REPLACE(REPLACE(plate, " ", ""), "-", ""), "_", "") = ? AND citizenid = ?', {oldPlate, Player.PlayerData.citizenid})
        if trimmedResult then return true end

    elseif framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(source)
        if not Player then return false end

        local result = MySQL.single.await('SELECT plate FROM player_vehicles WHERE plate = ? AND citizenid = ?', {oldPlate, Player.PlayerData.citizenid})
        if result then return true end

        local trimmedResult = MySQL.single.await('SELECT plate FROM player_vehicles WHERE REPLACE(REPLACE(REPLACE(plate, " ", ""), "-", ""), "_", "") = ? AND citizenid = ?', {oldPlate, Player.PlayerData.citizenid})
        if trimmedResult then return true end

    elseif framework == 'esx' then
        local core = Utils.GetCoreObject()
        if not core or not core.GetPlayerFromId then return false end
        local xPlayer = core.GetPlayerFromId(source)
        if not xPlayer then return false end

        local result = MySQL.single.await('SELECT plate FROM owned_vehicles WHERE REPLACE (plate, " ", "") = ? AND owner = ?', {oldPlate, xPlayer.identifier})
        if result then return true end
    end

    return false
end)

RegisterNetEvent('legends_platechanger:server:updatePlate', function(netID, oldPlate, newPlate)
    local src = source
    local framework = Utils.GetFramework()

    local Player, citizenid, identifier

    if framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end
        citizenid = Player.PlayerData.citizenid

        if Config.RequireJob and Player.PlayerData.job.name ~= Config.Job then
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("no_job"), 'error')
            return
        end
    elseif framework == 'qbx' then
        Player = exports.qbx_core:GetPlayer(src)
        if not Player then return end
        citizenid = Player.PlayerData.citizenid

        if Config.RequireJob and Player.PlayerData.job.name ~= Config.Job then
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("no_job"), 'error')
            return
        end
    elseif framework == 'esx' then
        local ESX = exports["es_extended"]:getSharedObject()
        Player = ESX.GetPlayerFromId(src)
        if not Player then return end
        identifier = Player.identifier

        if Config.RequireJob and Player.job.name ~= Config.Job then
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("no_job"), 'error')
            return
        end
    end

    local checkPlate
    if framework == 'qb' or framework == 'qbx' then
        checkPlate = MySQL.query.await('SELECT * FROM player_vehicles WHERE plate = ?', {newPlate})
    elseif framework == 'esx' then
        checkPlate = MySQL.query.await('SELECT * FROM owned_vehicles WHERE plate = ?', {newPlate})
    end

    if not checkPlate[1] then
        if framework == 'qb' or framework == 'qbx' then
            MySQL.query('SELECT plate, mods FROM player_vehicles WHERE plate = ? AND citizenid = ?', {oldPlate, citizenid}, function(result)
                if result[1] then
                    local veh = NetworkGetEntityFromNetworkId(netID)
                    local mods = json.decode(result[1].mods)
                    mods["plate"] = newPlate
                    MySQL.update('UPDATE player_vehicles SET mods = ? WHERE plate = ?', {json.encode(mods), result[1].plate})
                    MySQL.update('UPDATE player_vehicles SET plate = ? WHERE plate = ?', {newPlate, result[1].plate})
                    SetVehicleNumberPlateText(veh, newPlate)
                    TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("new_license_plate") .. newPlate, 'success')
                    Utils.Inventory.RemoveItem(src, Config.Item, 1)
                else
                    MySQL.query('SELECT plate, mods FROM player_vehicles WHERE REPLACE(REPLACE(REPLACE(plate, " ", ""), "-", ""), "_", "") = ? AND citizenid = ?', {oldPlate, citizenid}, function(trimmedResult)
                        if trimmedResult[1] then
                            local veh = NetworkGetEntityFromNetworkId(netID)
                            local mods = json.decode(trimmedResult[1].mods)
                            mods["plate"] = newPlate
                            MySQL.update('UPDATE player_vehicles SET mods = ? WHERE plate = ?', {json.encode(mods), trimmedResult[1].plate})
                            MySQL.update('UPDATE player_vehicles SET plate = ? WHERE plate = ?', {newPlate, trimmedResult[1].plate})
                            SetVehicleNumberPlateText(veh, newPlate)
                            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("new_license_plate") .. newPlate, 'success')
                            Utils.Inventory.RemoveItem(src, Config.Item, 1)
                        end
                    end)
                end
            end)
        elseif framework == 'esx' then
            MySQL.query('SELECT plate, vehicle FROM owned_vehicles WHERE REPLACE (plate, " ", "") = ? AND owner = ?', {oldPlate, identifier}, function(result)
                if result[1] then
                    local veh = NetworkGetEntityFromNetworkId(netID)
                    local vehicle = json.decode(result[1].vehicle)
                    vehicle["plate"] = newPlate
                    MySQL.update('UPDATE owned_vehicles SET vehicle = ? WHERE REPLACE (plate, " ", "") = ?', {json.encode(vehicle), oldPlate})
                    MySQL.update('UPDATE owned_vehicles SET plate = ? WHERE REPLACE (plate, " ", "") = ?', {newPlate, oldPlate})
                    SetVehicleNumberPlateText(veh, newPlate)
                    TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("new_license_plate") .. newPlate, 'success')
                    Utils.Inventory.RemoveItem(src, Config.Item, 1)
                end
            end)
        end
    else
        TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("same_plate"), 'error')
    end
end)

CreateThread(function()
    Wait(1000)
    local framework = Utils.GetFramework()

    if framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        QBCore.Functions.CreateUseableItem(Config.Item, function(source)
            TriggerClientEvent('legends_platechanger:client:Menu', source)
        end)
    elseif framework == 'qbx' then
        exports.qbx_core:CreateUseableItem(Config.Item, function(source)
            TriggerClientEvent('legends_platechanger:client:Menu', source)
        end)
    elseif framework == 'esx' then
        local ESX = exports["es_extended"]:getSharedObject()
        ESX.RegisterUsableItem(Config.Item, function(source)
            TriggerClientEvent('legends_platechanger:client:Menu', source)
        end)
    end
end)

RegisterNetEvent('legends_platechanger:server:BuyPlate', function()
    local src = source
    local framework = Utils.GetFramework()

    local Player

    if framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        if Config.RequireJob and Player.PlayerData.job.name ~= Config.Job then
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("no_job"), 'error')
            return
        end

        local hasItem = Utils.Inventory.HasItem(Config.Item, src)
        if hasItem then
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("npc_already_have"), 'error')
            return
        end

        if Player.PlayerData.money.bank >= Config.NPCPrice then
            Player.Functions.RemoveMoney('bank', Config.NPCPrice, 'license-plate-purchase')
            Utils.Inventory.AddItem(src, Config.Item, 1)

            local inventorySystem = Utils.GetInventorySystem()
            if inventorySystem ~= 'ox_inventory' then
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Item], "add")
            end

            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("npc_success") .. Config.NPCPrice, 'success')
        else
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("npc_no_money"), 'error')
        end

    elseif framework == 'qbx' then
        Player = exports.qbx_core:GetPlayer(src)
        if not Player then return end

        if Config.RequireJob and Player.PlayerData.job.name ~= Config.Job then
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("no_job"), 'error')
            return
        end

        local hasItem = Utils.Inventory.HasItem(Config.Item, src)
        if hasItem then
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("npc_already_have"), 'error')
            return
        end

        if Player.PlayerData.money.bank >= Config.NPCPrice then
            Player.Functions.RemoveMoney('bank', Config.NPCPrice, 'license-plate-purchase')
            Utils.Inventory.AddItem(src, Config.Item, 1)
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("npc_success") .. Config.NPCPrice, 'success')
        else
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("npc_no_money"), 'error')
        end

    elseif framework == 'esx' then
        local ESX = exports["es_extended"]:getSharedObject()
        Player = ESX.GetPlayerFromId(src)
        if not Player then return end

        if Config.RequireJob and Player.job.name ~= Config.Job then
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("no_job"), 'error')
            return
        end

        local hasItem = Utils.Inventory.HasItem(Config.Item, src)
        if hasItem then
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("npc_already_have"), 'error')
            return
        end

        if Player.getAccount('bank').money >= Config.NPCPrice then
            Player.removeAccountMoney('bank', Config.NPCPrice, 'license-plate-purchase')
            Utils.Inventory.AddItem(src, Config.Item, 1)
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("npc_success") .. Config.NPCPrice, 'success')
        else
            TriggerClientEvent('legends_platechanger:client:libNotify', src, _L("npc_no_money"), 'error')
        end
    end
end)

-- Version checker
AddEventHandler('onResourceStart', function(resourceName)
    Wait(2000)
    if resourceName == GetCurrentResourceName() then
        local url = 'https://raw.githubusercontent.com/LegendsTeamDev/versionChecks/main/legends_plates.txt?' .. math.random()

        PerformHttpRequest(url, function(statusCode, responseText)
            if statusCode ~= 200 then return end

            local success, data = pcall(json.decode, responseText)
            if not success then return end

            local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
            currentVersion = currentVersion:match("^%s*(.-)%s*$")

            if currentVersion ~= data.version then
                print("^8========== ^1UPDATE REQUIRED ^8==========^0")
                print("^3Resource:^0 " .. GetCurrentResourceName() .. " ^8is OUTDATED!")
                print("^3Your Version:^0 ^1" .. currentVersion .. "^0")
                print("^3Latest Version:^0 ^2" .. data.version .. "^0")
                print("^3Release Notes:^0 ^5" .. data.notes)
                print("^3Changes:^0 ^6" .. data.changes)
                print("^3Download:^0 ^6https://keymaster.fivem.net/asset-grants")
                print("^3Read More:^0 ^6" .. data.discordLink)
                print("^8========================================^0")
            end
        end, 'GET')
    end
end)
