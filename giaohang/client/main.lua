local QBCore = exports['qb-core']:GetCoreObject()
local PlayerJob = {}
local LocationsDone = {}
local CurrentLocation = nil
local CurrentBlip = nil
local hasBox = false
local isWorking = false
local currentCount = 0
local CurrentPlate = nil
local selectedVeh = nil
local TruckVehBlip = nil
local JobStartBlip = nil
local jobNpc = nil
local Delivering = false
local showMarker = false
local markerLocation
local zoneCombo = nil
local returningToStation = false
local inVehicleZone = false

-- Functions

local function createNpc()
    local npcPos = Config.TruckerJobLocations["jobstart"].coords
    local model = `s_m_y_construct_01`
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    jobNpc = CreatePed(4, model, npcPos.x, npcPos.y, npcPos.z - 1.0, npcPos.w, false, true)
    FreezeEntityPosition(jobNpc, true)
    SetEntityInvincible(jobNpc, true)
    SetBlockingOfNonTemporaryEvents(jobNpc, true)
    TaskStartScenarioInPlace(jobNpc, "WORLD_HUMAN_CLIPBOARD", 0, true)
end

local function returnToStation()
    SetBlipRoute(TruckVehBlip, true)
    returningToStation = true
end

local function hasDoneLocation(locationId)
    if LocationsDone and table.type(LocationsDone) ~= "empty" then
        for _, v in pairs(LocationsDone) do
            if v == locationId then return true end
        end
    end
    return false
end

local function getNextLocation()
    local current = 1
    if Config.TruckerJobFixedLocation then
        local pos = GetEntityCoords(PlayerPedId(), true)
        local dist = nil
        for k, v in pairs(Config.TruckerJobLocations["stores"]) do
            local dist2 = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
            if dist then
                if dist2 < dist then
                    current = k
                    dist = dist2
                end
            else
                current = k
                dist = dist2
            end
        end
    else
        while hasDoneLocation(current) do
            current = math.random(#Config.TruckerJobLocations["stores"])
        end
    end
    return current
end

local function isTruckerVehicle(vehicle)
    for k in pairs(Config.TruckerJobVehicles) do
        if GetEntityModel(vehicle) == joaat(k) then return true end
    end
    return false
end

local function getTruckerVehicle(vehicle)
    for k in pairs(Config.TruckerJobVehicles) do
        if GetEntityModel(vehicle) == joaat(k) then return k end
    end
    return false
end

local function RemoveTruckerBlips()
    ClearAllBlipRoutes()
    if TruckVehBlip then RemoveBlip(TruckVehBlip); TruckVehBlip = nil end
    if JobStartBlip then RemoveBlip(JobStartBlip); JobStartBlip = nil end
    if CurrentBlip then RemoveBlip(CurrentBlip); CurrentBlip = nil end
end

local function MenuGarage()
    local truckMenu = { { header = Lang:t("menu.header"), isMenuHeader = true } }
    for k, v in pairs(Config.TruckerJobVehicles) do
        truckMenu[#truckMenu + 1] = {
            header = v.label,
            params = { event = "qb-trucker:client:TakeOutVehicle", args = { vehicle = k } }
        }
    end
    truckMenu[#truckMenu + 1] = { header = Lang:t("menu.close_menu"), txt = "", params = { event = "qb-menu:client:closeMenu" } }
    exports['qb-menu']:openMenu(truckMenu)
end

local function SetDelivering(active)
    if PlayerJob.name ~= "trucker" then return end
    Delivering = active
end

local function ShowMarker(active)
    if PlayerJob.name ~= "trucker" then return end
    showMarker = active
end

local function CreateZone(type, number)
    local coords, heading, boxName, size
    if type == "vehicle" then
        coords = vector3(Config.TruckerJobLocations[type].coords.x, Config.TruckerJobLocations[type].coords.y, Config.TruckerJobLocations[type].coords.z)
        heading = Config.TruckerJobLocations[type].coords.h
        boxName = Config.TruckerJobLocations[type].label
        size = 10
    elseif type == "stores" then
        coords = vector3(Config.TruckerJobLocations[type][number].coords.x, Config.TruckerJobLocations[type][number].coords.y, Config.TruckerJobLocations[type][number].coords.z)
        heading = Config.TruckerJobLocations[type][number].coords.h
        boxName = Config.TruckerJobLocations[type][number].name
        size = 40
    end
    if not coords then return end
    local zone = BoxZone:Create(coords, size, size, { minZ = coords.z - 5.0, maxZ = coords.z + 5.0, name = boxName, debugPoly = false, heading = heading })
    local combo = ComboZone:Create({ zone }, { name = boxName, debugPoly = false })
    combo:onPlayerInOut(function(isPointInside)
        if type == "vehicle" then
            inVehicleZone = isPointInside
        elseif type == "stores" then
            if isPointInside then
                markerLocation = coords
                QBCore.Functions.Notify(Lang:t("mission.store_reached"))
                ShowMarker(true)
                SetDelivering(true)
            else
                ShowMarker(false)
                SetDelivering(false)
            end
        end
    end)
    if type == "stores" then
        if CurrentLocation then
            CurrentLocation.zoneCombo = combo
        end
    end
end

local function getNewLocation()
    local location = getNextLocation()
    if location ~= 0 then
        CurrentLocation = {}
        CurrentLocation.id = location
        CurrentLocation.dropcount = math.random(1, 3)
        CurrentLocation.store = Config.TruckerJobLocations["stores"][location].name
        CurrentLocation.x = Config.TruckerJobLocations["stores"][location].coords.x
        CurrentLocation.y = Config.TruckerJobLocations["stores"][location].coords.y
        CurrentLocation.z = Config.TruckerJobLocations["stores"][location].coords.z
        CreateZone("stores", location)
        CurrentBlip = AddBlipForCoord(CurrentLocation.x, CurrentLocation.y, CurrentLocation.z)
        SetBlipColour(CurrentBlip, 3)
        SetBlipRoute(CurrentBlip, true)
        SetBlipRouteColour(CurrentBlip, 3)
    else
        QBCore.Functions.Notify("Bạn đã hoàn thành tất cả các điểm giao hàng!", "success")
        if CurrentBlip then RemoveBlip(CurrentBlip); ClearAllBlipRoutes(); CurrentBlip = nil end
    end
end

local function CreateElements()
    TruckVehBlip = AddBlipForCoord(Config.TruckerJobLocations["vehicle"].coords.x, Config.TruckerJobLocations["vehicle"].coords.y, Config.TruckerJobLocations["vehicle"].coords.z)
    SetBlipSprite(TruckVehBlip, 326); SetBlipDisplay(TruckVehBlip, 4); SetBlipScale(TruckVehBlip, 0.6); SetBlipAsShortRange(TruckVehBlip, true); SetBlipColour(TruckVehBlip, 5)
    BeginTextCommandSetBlipName("STRING"); AddTextComponentSubstringPlayerName(Config.TruckerJobLocations["vehicle"].label); EndTextCommandSetBlipName(TruckVehBlip)
    JobStartBlip = AddBlipForCoord(Config.TruckerJobLocations["jobstart"].coords.x, Config.TruckerJobLocations["jobstart"].coords.y, Config.TruckerJobLocations["jobstart"].coords.z)
    SetBlipSprite(JobStartBlip, 527); SetBlipDisplay(JobStartBlip, 4); SetBlipScale(JobStartBlip, 0.7); SetBlipAsShortRange(JobStartBlip, true); SetBlipColour(JobStartBlip, 2)
    BeginTextCommandSetBlipName("STRING"); AddTextComponentSubstringPlayerName(Config.TruckerJobLocations["jobstart"].label); EndTextCommandSetBlipName(JobStartBlip)
    createNpc()
    CreateZone("vehicle")
end

local function TableCount(tbl)
    local cnt = 0; for _ in pairs(tbl) do cnt = cnt + 1 end; return cnt
end

local function BackDoorsOpen(vehicle)
    local tv = getTruckerVehicle(vehicle)
    if not tv or not Config.TruckerJobVehicles[tv] then return false end
    local cargodoors = Config.TruckerJobVehicles[tv].cargodoors
    if not cargodoors then return true end
    local cnt = TableCount(cargodoors)
    if cnt == 2 then return GetVehicleDoorAngleRatio(vehicle, cargodoors[0]) > 0.0 and GetVehicleDoorAngleRatio(vehicle, cargodoors[1]) > 0.0
    elseif cnt == 1 then return GetVehicleDoorAngleRatio(vehicle, cargodoors[0]) > 0.0 end
    return false
end

local function GetInTrunk()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return QBCore.Functions.Notify(Lang:t("error.get_out_vehicle"), "error") end
    local pos = GetEntityCoords(ped)
    local jobVehicle = nil
    local vehicles = QBCore.Functions.GetVehicles()
    for i=1, #vehicles do
        if DoesEntityExist(vehicles[i]) then
            if QBCore.Functions.GetPlate(vehicles[i]) == CurrentPlate and #(pos - GetEntityCoords(vehicles[i])) < 20.0 then
                jobVehicle = vehicles[i]
                break
            end
        end
    end
    if not jobVehicle then return QBCore.Functions.Notify("Không tìm thấy xe tải làm việc của bạn ở gần đây!", "error") end
    local tv = getTruckerVehicle(jobVehicle)
    if not tv then return QBCore.Functions.Notify(Lang:t("error.vehicle_not_correct"), "error") end
    if not BackDoorsOpen(jobVehicle) then return QBCore.Functions.Notify(Lang:t("error.backdoors_not_open"), "error") end
    local trunkpos = GetOffsetFromEntityInWorldCoords(jobVehicle, 0.0, -2.5, 0.0)
    if #(pos - trunkpos) > Config.TruckerJobVehicles[tv].trunkpos then return QBCore.Functions.Notify(Lang:t("error.too_far_from_trunk"), "error") end
    if isWorking then return end
    isWorking = true
    QBCore.Functions.Progressbar("work_carrybox", Lang:t("mission.take_box"), 2000, false, true, { disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true, }, { animDict = "anim@gangops@facility@servers@", anim = "hotwire", flags = 16, }, {}, {}, function()
        isWorking = false; StopAnimTask(ped, "anim@gangops@facility@servers@", "hotwire", 1.0); hasBox = true
    end, function()
        isWorking = false; StopAnimTask(ped, "anim@gangops@facility@servers@", "hotwire", 1.0); QBCore.Functions.Notify(Lang:t("error.cancelled"), "error")
    end)
end

local function Deliver()
    isWorking = true
    Wait(500)
    TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_BUM_BIN", 0, true)
    QBCore.Functions.Progressbar("work_dropbox", Lang:t("mission.deliver_box"), 2000, false, true, { disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true, }, {}, {}, {}, function()
        isWorking = false; ClearPedTasks(PlayerPedId()); hasBox = false
        currentCount = currentCount + 1
        if currentCount == CurrentLocation.dropcount then
            LocationsDone[#LocationsDone + 1] = CurrentLocation.id
            TriggerServerEvent("qb-shops:server:RestockShopItems", CurrentLocation.store)
            exports['qb-core']:HideText(); Delivering = false; showMarker = false
            TriggerServerEvent('qb-truckerjob:server:processPayment', 1)
            TriggerServerEvent('qb-trucker:server:nano')
            if CurrentLocation and CurrentLocation.zoneCombo then CurrentLocation.zoneCombo:destroy() end
            CurrentLocation = nil; currentCount = 0
            if CurrentBlip then RemoveBlip(CurrentBlip); ClearAllBlipRoutes(); CurrentBlip = nil end
            if #LocationsDone >= Config.TruckerJobMaxDrops then
                QBCore.Functions.Notify(Lang:t("mission.return_to_station")); returnToStation()
            else
                QBCore.Functions.Notify(Lang:t("mission.goto_next_point")); getNewLocation()
            end
        else
            QBCore.Functions.Notify(Lang:t("mission.another_box"))
        end
    end, function()
        isWorking = false; ClearPedTasks(PlayerPedId()); QBCore.Functions.Notify(Lang:t("error.cancelled"), "error")
    end)
end

-- Events
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    PlayerJob = QBCore.Functions.GetPlayerData().job
    CurrentLocation = nil; CurrentBlip = nil; hasBox = false; isWorking = false
    if PlayerJob.name ~= "trucker" then return end
    CreateElements()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    CurrentLocation = nil; CurrentBlip = nil; hasBox = false; isWorking = false
    if PlayerJob.name ~= "trucker" then return end
    CreateElements()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    RemoveTruckerBlips()
    if jobNpc then DeleteEntity(jobNpc) end
    CurrentLocation = nil; CurrentBlip = nil; hasBox = false; isWorking = false
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    local OldPlayerJob = PlayerJob.name
    PlayerJob = JobInfo
    if OldPlayerJob == "trucker" then
        RemoveTruckerBlips()
        if jobNpc then DeleteEntity(jobNpc); jobNpc = nil end
    elseif PlayerJob.name == "trucker" then
        CreateElements()
    end
end)

RegisterNetEvent('qb-trucker:client:SpawnVehicle', function()
    local vehicleInfo = selectedVeh
    local coords = Config.TruckerJobLocations["vehicle"].coords
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        SetVehicleNumberPlateText(veh, "TRUK" .. tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, coords.w); SetVehicleLivery(veh, 1); SetVehicleColours(veh, 122, 122)
        exports['LegacyFuel']:SetFuel(veh, 100.0); exports['qb-menu']:closeMenu()
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1); SetEntityAsMissionEntity(veh, true, true)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh)); SetVehicleEngineOn(veh, true, true)
        CurrentPlate = QBCore.Functions.GetPlate(veh)
        getNewLocation()
    end, vehicleInfo, coords, true)
end)

RegisterNetEvent('qb-trucker:client:TakeOutVehicle', function(data)
    local vehicleInfo = data.vehicle
    TriggerServerEvent('qb-trucker:server:DoBail', true, vehicleInfo)
    selectedVeh = vehicleInfo
end)

RegisterNetEvent('qb-truckerjob:client:Vehicle', function()
    if IsPedInAnyVehicle(PlayerPedId()) and isTruckerVehicle(GetVehiclePedIsIn(PlayerPedId(), false)) then
        if GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId()), -1) == PlayerPedId() then
            if isTruckerVehicle(GetVehiclePedIsIn(PlayerPedId(), false)) then
                DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
                TriggerServerEvent('qb-trucker:server:DoBail', false)
                LocationsDone = {}
                if CurrentBlip then RemoveBlip(CurrentBlip); ClearAllBlipRoutes(); CurrentBlip = nil end
                if returningToStation or CurrentLocation then
                    ClearAllBlipRoutes(); returningToStation = false
                    QBCore.Functions.Notify(Lang:t("mission.job_completed"), "success")
                end
            else
                QBCore.Functions.Notify(Lang:t("error.vehicle_not_correct"), 'error')
            end
        else
            QBCore.Functions.Notify(Lang:t("error.no_driver"))
        end
    end
end)

-- Threads
CreateThread(function()
    local sleep
    while true do
        sleep = 1000
        local playerPed = PlayerPedId()
        local isTextShown = false
        if jobNpc and DoesEntityExist(jobNpc) then
            local playerCoords = GetEntityCoords(playerPed)
            local npcCoords = GetEntityCoords(jobNpc)
            if #(playerCoords - npcCoords) < 2.5 and not IsPedInAnyVehicle(playerPed, false) then
                sleep = 5; isTextShown = true
                exports['qb-core']:DrawText("Nhấn [E] để xem danh sách xe", "left")
                if IsControlJustReleased(0, 38) then MenuGarage() end
            end
        end
        if inVehicleZone and IsPedInAnyVehicle(playerPed, false) then
            sleep = 5; isTextShown = true
            exports['qb-core']:DrawText("Nhấn [E] để trả xe tải", "left")
            if IsControlJustReleased(0, 38) then TriggerEvent('qb-truckerjob:client:Vehicle') end
        end
        if showMarker then
            DrawMarker(2, markerLocation.x, markerLocation.y, markerLocation.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, false, true, false, false, false)
            sleep = 0
        end
        if Delivering then
            sleep = 0; isTextShown = true
            if IsControlJustReleased(0, 38) then
                if not hasBox then GetInTrunk()
                else
                    if #(GetEntityCoords(playerPed) - markerLocation) < 5 then Deliver()
                    else QBCore.Functions.Notify(Lang:t("error.too_far_from_delivery"), "error") end
                end
            end
        end
        if not isTextShown then exports['qb-core']:HideText() end
        Wait(sleep)
    end
end)