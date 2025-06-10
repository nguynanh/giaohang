-- file: qb-jobcenter/server/main.lua
local QBCore = exports['qb-core']:GetCoreObject()
local rentedVehicles = {}
local deliveryJobs = {}

local function hasPermission(src)
    if not Config.JobRequired then return true end
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData.job and Player.PlayerData.job.name == Config.RequiredJobName then return true end
    QBCore.Functions.Notify(src, Config.Lang.no_permission, "error")
    return false
end

RegisterNetEvent('qb-jobcenter:server:rentVehicle', function()
    local src = source
    if not hasPermission(src) then return end
    if rentedVehicles[src] then QBCore.Functions.Notify(src, Config.Lang.already_rented, "error"); return end
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveMoney('cash', Config.Vehicle.rentPrice) then
        local vehicle = CreateVehicle(Config.Vehicle.model, Config.Vehicle.spawnPoint, true, true)
        rentedVehicles[src] = vehicle
        TaskWarpPedIntoVehicle(Player.PlayerData.ped, vehicle, -1)
        QBCore.Functions.Notify(src, Config.Lang.vehicle_rented .. Config.Vehicle.rentPrice, "success")
    else
        QBCore.Functions.Notify(src, Config.Lang.not_enough_money, "error")
    end
end)

RegisterNetEvent('qb-jobcenter:server:returnVehicle', function(vehicleNetId)
    local src = source
    if not hasPermission(src) then return end
    local vehicle = NetToVeh(vehicleNetId)
    if not rentedVehicles[src] then QBCore.Functions.Notify(src, Config.Lang.no_vehicle_rented, "error"); return end
    if vehicle ~= rentedVehicles[src] then QBCore.Functions.Notify(src, Config.Lang.not_rented_vehicle, "error"); return end
    DeleteEntity(vehicle)
    rentedVehicles[src] = nil
    QBCore.Functions.Notify(src, Config.Lang.vehicle_returned, "success")
end)

RegisterNetEvent('qb-jobcenter:server:getDelivery', function()
    local src = source
    if not hasPermission(src) then return end
    if deliveryJobs[src] then QBCore.Functions.Notify(src, Config.Lang.already_on_delivery, "error"); return end
    local delivery = Config.Deliveries[math.random(#Config.Deliveries)]
    deliveryJobs[src] = { data = delivery, stage = "pickup" }
    TriggerClientEvent("qb-jobcenter:client:startDelivery", src, delivery)
end)

RegisterNetEvent('qb-jobcenter:server:progressDelivery', function()
    local src = source
    local job = deliveryJobs[src]
    if not job then return end
    if job.stage == "pickup" then
        job.stage = "dropoff"
        deliveryJobs[src] = job
        TriggerClientEvent("qb-jobcenter:client:updateDelivery", src, job.data.dropoff)
    elseif job.stage == "dropoff" then
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.AddMoney('cash', job.data.reward)
        deliveryJobs[src] = nil
        TriggerClientEvent("qb-jobcenter:client:deliveryFinished", src, false) -- false = khong phai bi huy
    end
end)

RegisterNetEvent('qb-jobcenter:server:cancelDelivery', function()
    local src = source
    if not hasPermission(src) then return end
    if not deliveryJobs[src] then QBCore.Functions.Notify(src, Config.Lang.no_delivery_to_cancel, "error"); return end
    deliveryJobs[src] = nil
    TriggerClientEvent("qb-jobcenter:client:deliveryFinished", src, true) -- true = bi huy
end)

AddEventHandler('QBCore:Player:OnLogout', function(Player)
    local src = Player.PlayerData.source
    if rentedVehicles[src] then DeleteEntity(rentedVehicles[src]); rentedVehicles[src] = nil end
    if deliveryJobs[src] then deliveryJobs[src] = nil end
end)