local Utils = require 'shared.utils'
local QBCore, ESX, QBX
local npcPed = nil
local npcBlip = nil

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

local function CreateNPC()
    if not Config.EnableNPC then return end

    local coords = Config.NPCCoords
    local model = Config.NPCModel

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end

    npcPed = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityHeading(npcPed, coords.w)
    FreezeEntityPosition(npcPed, true)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    SetPedDiesWhenInjured(npcPed, false)
    SetPedCanPlayAmbientAnims(npcPed, true)
    SetPedCanRagdollFromPlayerImpact(npcPed, false)
    SetEntityCanBeDamaged(npcPed, false)
    SetPedCanBeTargetted(npcPed, false)

    if Config.NPCBlip.enabled then
        npcBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(npcBlip, Config.NPCBlip.sprite)
        SetBlipDisplay(npcBlip, 4)
        SetBlipScale(npcBlip, Config.NPCBlip.scale)
        SetBlipColour(npcBlip, Config.NPCBlip.color)
        SetBlipAsShortRange(npcBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.NPCBlip.name)
        EndTextCommandSetBlipName(npcBlip)
    end

    local targetSystem = Utils.GetTargetSystem()

    if targetSystem == 'ox_target' or targetSystem == 'qb-target' then
        Utils.Target.AddEntityTarget(npcPed, {
            {
                name = 'legends_platechanger_npc',
                icon = 'fas fa-clipboard',
                label = _L("npc_buy_plate"),
                distance = 2.5,
                canInteract = function()
                    local Player = Utils.GetPlayerData()
                    return Utils.HasRequiredJob(Player)
                end
            }
        })
    else
        CreateThread(function()
            while npcPed and DoesEntityExist(npcPed) do
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local npcCoords = GetEntityCoords(npcPed)
                local distance = #(playerCoords - npcCoords)

                if distance <= 2.5 then
                    local Player = Utils.GetPlayerData()
                    if Utils.HasRequiredJob(Player) then
                        lib.showTextUI('[E] ' .. _L("npc_buy_plate"), {
                            position = "right-center",
                            icon = 'clipboard'
                        })

                        if IsControlJustReleased(0, 38) then
                            TriggerEvent('legends_platechanger:client:BuyPlateFromNPC')
                        end
                    end
                else
                    lib.hideTextUI()
                end

                Wait(0)
            end
            lib.hideTextUI()
        end)
    end
end

local function RemoveNPC()
    if npcPed then
        Utils.Target.RemoveEntityTarget(npcPed, 'legends_platechanger_npc')
        DeleteEntity(npcPed)
        npcPed = nil
    end

    if npcBlip then
        RemoveBlip(npcBlip)
        npcBlip = nil
    end
end

RegisterNetEvent('legends_platechanger:client:BuyPlateFromNPC', function()
    local Player = Utils.GetPlayerData()

    if not Utils.HasRequiredJob(Player) then
        lib.notify({
            title = _L("no_job"),
            type = 'error'
        })
        return
    end

    local hasItem = Utils.Inventory.HasItem(Config.Item)

    if hasItem then
        lib.notify({
            title = _L("npc_already_have"),
            type = 'error'
        })
        return
    end

    local confirm = lib.alertDialog({
        header = _L("npc_buy_plate"),
        content = _L("npc_buy_desc") .. Config.NPCPrice,
        centered = true,
        cancel = true
    })

    if confirm == 'confirm' then
        TriggerServerEvent('legends_platechanger:server:BuyPlate')
    end
end)

RegisterNetEvent('legends_platechanger:client:libNotify', function(message, type)
    lib.notify({
        title = message,
        type = type
    })
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(1000)
        CreateNPC()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RemoveNPC()
    end
end)

CreateThread(function()
    local framework = Utils.GetFramework()
    if framework == 'qb' or framework == 'qbx' then
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
            Wait(2000)
            CreateNPC()
        end)

        RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
            RemoveNPC()
        end)
    elseif framework == 'esx' then
        RegisterNetEvent('esx:playerLoaded', function()
            Wait(2000)
            CreateNPC()
        end)

        RegisterNetEvent('esx:onPlayerLogout', function()
            RemoveNPC()
        end)
    end
end)
