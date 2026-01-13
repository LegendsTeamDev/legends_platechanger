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

RegisterNetEvent('legends_platechanger:client:Menu', function()
    local Player = Utils.GetPlayerData()

    if not Utils.HasRequiredJob(Player) then
        lib.notify({title = _L("no_job"), type = 'error'})
        return
    end

    local nearByVehicle = lib.getNearbyVehicles(GetEntityCoords(PlayerPedId()), 0.3, true)
    if nearByVehicle[1] then
        local vehicle = nearByVehicle[1].vehicle
        local oldPlate = GetVehicleNumberPlateText(vehicle):gsub('[%p%c%s]', ''):upper()
        local checkOwner = lib.callback.await('legends_platechanger:server:CheckOwnerVehicle', false, oldPlate)
        if checkOwner then
            local plateChangerInput = lib.inputDialog(_L("title"), {{
                type = 'input',
                label = _L("label"),
                description = _L("desc"),
                icon = {'fa', 'clapperboard'}
            }})
            if not plateChangerInput then return end
            local newPlate = string.upper(plateChangerInput[1])
            if #newPlate >= 3 and #newPlate <= 8 then
                TriggerServerEvent('legends_platechanger:server:updatePlate', NetworkGetNetworkIdFromEntity(vehicle), oldPlate, newPlate)
            else
                lib.notify({title = _L("lenght"), type = 'error'})
            end
        else
            lib.notify({title = _L("owner"), type = 'error'})
        end
    else
        lib.notify({title = _L("nearby"), type = 'error'})
    end
end)
