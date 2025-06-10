-- file: qb-jobcenter/client/main.lua
local QBCore = exports['qb-core']:GetCoreObject()
local onDelivery = false
local deliveryBlip = nil
local currentDelivery = {}

-- Tao NPC
CreateThread(function()
    RequestModel(Config.NPC.model)
    while not HasModelLoaded(Config.NPC.model) do Wait(100) end
    local ped = CreatePed(4, GetHashKey(Config.NPC.model), Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.coords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
end)

-- Mo Menu chinh
function OpenMainMenu()
    exports['qb-menu']:openMenu({
        { header = Config.Lang.menu_header, isMenuHeader = true },
        { header = Config.Lang.rent_vehicle, txt = "Gia: $" .. Config.Vehicle.rentPrice, params = { event = "qb-jobcenter:client:rentVehicle" }},
        { header = Config.Lang.return_vehicle, params = { event = "qb-jobcenter:client:returnVehicle" }},
        { header = Config.Lang.get_delivery, params = { event = "qb-jobcenter:client:getDelivery" }},
        { header = Config.Lang.cancel_delivery, params = { event = "qb-jobcenter:client:cancelDelivery" }},
        { header = Config.Lang.close_menu, params = { event = "qb-menu:closeMenu" }},
    })
end

-- Vong lap chinh
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Kiem tra tuong tac voi NPC
        local distToNpc = #(playerCoords - Config.NPC.coords.xyz)
        if distToNpc < 2.0 then
            sleep = 5
            local playerData = QBCore.Functions.GetPlayerData()
            local canDoJob = not Config.JobRequired or (playerData.job and playerData.job.name == Config.RequiredJobName)
            if canDoJob then
                exports['qb-core']:DrawText(Config.Lang.talk_to_npc, 'left')
                if IsControlJustReleased(0, 38) then OpenMainMenu() end
            end
        else
             exports['qb-core']:HideText()
        end

        -- Kiem tra tuong tac voi diem giao/nhan hang
        if onDelivery and currentDelivery.stage then
            sleep = 5
            local targetCoords = (currentDelivery.stage == "pickup") and currentDelivery.data.pickup or currentDelivery.data.dropoff
            local distToTarget = #(playerCoords - targetCoords)
            if distToTarget < 2.0 then
                local prompt = (currentDelivery.stage == "pickup") and Config.Lang.at_pickup_point or Config.Lang.at_dropoff_point
                exports['qb-core']:DrawText(prompt, 'left')
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent("qb-jobcenter:server:progressDelivery")
                end
            end
        end
        Wait(sleep)
    end
end)

-- Su kien tu Menu -> Server
RegisterNetEvent("qb-jobcenter:client:rentVehicle", function() TriggerServerEvent("qb-jobcenter:server:rentVehicle") end)
RegisterNetEvent("qb-jobcenter:client:returnVehicle", function()
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then QBCore.Functions.Notify(Config.Lang.must_be_in_vehicle, "error"); return end
    TriggerServerEvent("qb-jobcenter:server:returnVehicle", VehToNet(GetVehiclePedIsIn(playerPed, false)))
end)
RegisterNetEvent("qb-jobcenter:client:getDelivery", function() TriggerServerEvent("qb-jobcenter:server:getDelivery") end)
RegisterNetEvent("qb-jobcenter:client:cancelDelivery", function() TriggerServerEvent("qb-jobcenter:server:cancelDelivery") end)

-- Su kien tu Server -> Client
RegisterNetEvent("qb-jobcenter:client:startDelivery", function(delivery)
    if onDelivery then return end
    onDelivery = true
    currentDelivery = { data = delivery, stage = "pickup" }
    QBCore.Functions.Notify(Config.Lang.delivery_accepted, "success")
    deliveryBlip = AddBlipForCoord(delivery.pickup)
    SetBlipSprite(deliveryBlip, 1); SetBlipRoute(deliveryBlip, true); SetBlipRouteColour(deliveryBlip, 5)
    BeginTextCommandSetBlipName("STRING"); AddTextComponentSubstringPlayerName(Config.Lang.go_to_pickup); EndTextCommandSetBlipName(deliveryBlip)
end)

RegisterNetEvent("qb-jobcenter:client:updateDelivery", function(dropoffCoords)
    currentDelivery.stage = "dropoff"
    QBCore.Functions.Notify(Config.Lang.package_collected, "primary")
    if deliveryBlip then RemoveBlip(deliveryBlip) end
    deliveryBlip = AddBlipForCoord(dropoffCoords)
    SetBlipSprite(deliveryBlip, 1); SetBlipRoute(deliveryBlip, true); SetBlipRouteColour(deliveryBlip, 5)
    BeginTextCommandSetBlipName("STRING"); AddTextComponentSubstringPlayerName(Config.Lang.go_to_dropoff); EndTextCommandSetBlipName(deliveryBlip)
end)

RegisterNetEvent("qb-jobcenter:client:deliveryFinished", function(wasCancelled)
    onDelivery = false
    currentDelivery = {}
    if deliveryBlip then RemoveBlip(deliveryBlip) end
    deliveryBlip = nil
    if wasCancelled then QBCore.Functions.Notify(Config.Lang.delivery_cancelled, "info") else QBCore.Functions.Notify(Config.Lang.delivery_completed, "success") end
end)