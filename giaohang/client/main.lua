local QBCore = exports['qb-core']:GetCoreObject()
local PlayerJob = {}

-- BIẾN QUẢN LÝ GIAO HÀNG
local LocationsDone = {}
local CurrentLocation = nil
local CurrentBlip = nil
local hasBox = false
local isWorking = false
local currentCount = 0
local jobNpc = nil
local Delivering = false
local showMarker = false
local markerLocation
local zoneCombo = nil
local returningToStation = false

-- BIẾN QUẢN LÝ ĐIỂM LẤY HÀNG (TRUNG GIAN)
local hasAcceptedOrder = false
local goodsPickupCoords = vector4(162.4, -3211.15, 5.95, 204.32)
local goodsPickupBlip = nil
local goodsPickupZone = nil
local canPickupGoods = false

-- BIẾN QUẢN LÝ THUÊ XE
local selectedRentalVeh = nil
local rentedVehiclePlate = nil
local inRentalZone = false

-- ===================================================================================
-- KHAI BÁO HÀM (FUNCTIONS)
-- ===================================================================================

-- NHÓM 1: CÁC HÀM TIỆN ÍCH CƠ BẢN
local function SetDelivering(active)
    if PlayerJob.name ~= "trucker" then return end
    Delivering = active
end

local function ShowMarker(active)
    if PlayerJob.name ~= "trucker" then return end
    showMarker = active
end

-- ===================================================================================
-- CẬP NHẬT: Thêm lại hàm kiểm tra xe tải hợp lệ
-- ===================================================================================
local function isTruckerVehicle(vehicle)
    for k in pairs(Config.TruckerJobVehicles) do
        if GetEntityModel(vehicle) == joaat(k) then return true end
    end
    return false
end
-- ===================================================================================

-- NHÓM 2: CÁC HÀM LOGIC CHÍNH
local function CreateDeliveryZone(number)
    local store = Config.TruckerJobLocations["stores"][number]
    local coords = vector3(store.coords.x, store.coords.y, store.coords.z)
    local boxName = store.name
    local zone = BoxZone:Create(coords, 40.0, 40.0, { minZ = coords.z - 5.0, maxZ = coords.z + 5.0, name = boxName, debugPoly = false })
    local combo = ComboZone:Create({ zone }, { name = boxName, debugPoly = false })
    combo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            markerLocation = coords
            QBCore.Functions.Notify(Lang:t("mission.store_reached"))
            ShowMarker(true)
            SetDelivering(true)
        else
            ShowMarker(false)
            SetDelivering(false)
        end
    end)
    if CurrentLocation then
        CurrentLocation.zoneCombo = combo
    end
end

local function hasDoneLocation(locationId)
    -- SỬA LỖI: Sử dụng cách kiểm tra bảng rỗng chuẩn của Lua
    if LocationsDone and #LocationsDone > 0 then
        for _, v in pairs(LocationsDone) do
            if v == locationId then return true end
        end
    end
    return false
end

local function getNextDeliveryLocation()
    local availableLocations = {}
    for k, v in pairs(Config.TruckerJobLocations["stores"]) do
        if not hasDoneLocation(k) then
            table.insert(availableLocations, k)
        end
    end

    if #availableLocations > 0 then
        if Config.TruckerJobFixedLocation then
            -- Tìm địa điểm gần nhất có sẵn
            local pos = GetEntityCoords(PlayerPedId(), true)
            local minDist = -1
            local closestLocId = 0
            for _, locId in pairs(availableLocations) do
                local storeCoords = Config.TruckerJobLocations["stores"][locId].coords
                local dist2 = #(pos - vector3(storeCoords.x, storeCoords.y, storeCoords.z))
                if minDist == -1 or dist2 < minDist then
                    minDist = dist2
                    closestLocId = locId
                end
            end
            return closestLocId
        else
            -- Chọn ngẫu nhiên từ các địa điểm có sẵn
            return availableLocations[math.random(#availableLocations)]
        end
    else
        return 0 -- Không còn địa điểm nào để giao
    end
end

local function getNewDeliveryRoute()
    local locationId = getNextDeliveryLocation()
    if locationId ~= 0 then
        CurrentLocation = {}
        CurrentLocation.id = locationId
        CurrentLocation.dropcount = math.random(1, 3)
        currentCount = 0 -- Đặt lại số lượng hộp cho địa điểm mới
        CreateDeliveryZone(locationId)
        local storeCoords = Config.TruckerJobLocations["stores"][locationId].coords
        CurrentBlip = AddBlipForCoord(storeCoords.x, storeCoords.y, storeCoords.z)
        SetBlipColour(CurrentBlip, 3)
        SetBlipRoute(CurrentBlip, true)
        SetBlipRouteColour(CurrentBlip, 3)
        QBCore.Functions.Notify("Đã nhận lộ trình, hãy đến điểm giao hàng đầu tiên.", "success")
    else
        QBCore.Functions.Notify("Bạn đã hoàn thành tất cả các điểm giao hàng!", "success")
        -- Chỉ xóa blip và route nếu không còn địa điểm nào và nhiệm vụ hoàn thành hoàn toàn
        if CurrentBlip then RemoveBlip(CurrentBlip); ClearAllBlipRoutes(); CurrentBlip = nil end
        -- Toàn bộ nhiệm vụ đã hoàn thành, bây giờ mới reset LocationsDone
        ResetMissionState()
    end
end

local function returnToJobNpc()
    local jobStartBlip = AddBlipForCoord(Config.TruckerJobLocations["jobstart"].coords.xyz)
    SetBlipRoute(jobStartBlip, true)
    Wait(500)
    -- Không xóa blip ngay lập tức, người chơi cần nhìn thấy nó
    -- RemoveBlip(jobStartBlip)
    returningToStation = true
    QBCore.Functions.Notify(Lang:t("mission.return_to_station"), "success")
end

-- NHÓM 3: CÁC HÀM CÀI ĐẶT, DỌN DẸP & MENU
local function CreateGoodsPickupZoneAndBlip()
    if goodsPickupZone then goodsPickupZone:destroy() end
    goodsPickupZone = BoxZone:Create(goodsPickupCoords.xyz, 10.0, 10.0, { name = "trucker_goods_pickup" })
    goodsPickupZone:onPlayerInOut(function(isInside)
        canPickupGoods = isInside
    end)

    if goodsPickupBlip then RemoveBlip(goodsPickupBlip) end
    goodsPickupBlip = AddBlipForCoord(goodsPickupCoords.x, goodsPickupCoords.y, goodsPickupCoords.z)
    SetBlipSprite(goodsPickupBlip, 198)
    SetBlipDisplay(goodsPickupBlip, 4)
    SetBlipScale(goodsPickupBlip, 0.8)
    SetBlipColour(goodsPickupBlip, 47)
    SetBlipAsShortRange(goodsPickupBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Điểm Lấy Hàng")
    EndTextCommandSetBlipName(goodsPickupBlip)
end

-- Hàm dọn dẹp chỉ cho một điểm giao hàng hiện tại
local function ClearCurrentDeliveryPoint()
    if CurrentBlip then RemoveBlip(CurrentBlip); CurrentBlip = nil end
    if CurrentLocation and CurrentLocation.zoneCombo then CurrentLocation.zoneCombo:destroy(); CurrentLocation.zoneCombo = nil end
    ClearAllBlipRoutes()
    CurrentLocation = nil
    Delivering = false
    showMarker = false
end

-- Reset toàn bộ nhiệm vụ, chỉ gọi khi toàn bộ lộ trình hoàn tất hoặc bị hủy
local function ResetMissionState()
    ClearCurrentDeliveryPoint()
    if goodsPickupBlip then RemoveBlip(goodsPickupBlip); goodsPickupBlip = nil end
    if goodsPickupZone then goodsPickupZone:destroy(); goodsPickupZone = nil end
    LocationsDone = {} -- Đây là thay đổi quan trọng, chỉ reset tất cả các địa điểm đã hoàn thành ở đây
    returningToStation = false
    hasAcceptedOrder = false
    canPickupGoods = false
    currentCount = 0 -- Đảm bảo điều này cũng được reset cho nhiệm vụ mới
end

local function MenuMissionStart()
    local menu = {
        { header = "Công việc Giao hàng", isMenuHeader = true },
        {
            header = "Nhận Đơn Hàng",
            txt = "Bắt đầu một lộ trình giao hàng mới.",
            params = { event = "qb-trucker:client:AcceptMission" }
        },
        -- THÊM MỤC HỦY ĐƠN HÀNG TẠI ĐÂY
        {
            header = "Hủy Đơn Hàng",
            txt = "Hủy nhiệm vụ giao hàng hiện tại.",
            params = { event = "qb-trucker:client:CancelMission" }
        },
        { header = Lang:t("menu.close_menu"), params = { event = "qb-menu:client:closeMenu" } }
    }
    exports['qb-menu']:openMenu(menu)
end

local function MenuVehicleRental()
    local menu = {
        { header = "Dịch vụ Xe tải", isMenuHeader = true },
        {
            header = "Thuê xe tải",
            txt = "Chọn một chiếc xe để thuê (yêu cầu đặt cọc)",
            params = { event = "qb-trucker:client:OpenRentalList" }
        },
        {
            header = "Trả xe đã thuê",
            txt = "Hoàn trả xe để nhận lại tiền cọc",
            params = { event = "qb-trucker:client:ReturnRentedVehicle" }
        },
        { header = Lang:t("menu.close_menu"), params = { event = "qb-menu:client:closeMenu" } }
    }
    exports['qb-menu']:openMenu(menu)
end

local function OpenRentalList()
    local rentalMenu = { { header = "Xe tải cho thuê", isMenuHeader = true } }
    for k, v in pairs(Config.TruckerJobVehicles) do
        rentalMenu[#rentalMenu + 1] = {
            header = v.label,
            params = { event = "qb-trucker:client:RentVehicle", args = { vehicle = k } }
        }
    end
    rentalMenu[#rentalMenu + 1] = { header = Lang:t("menu.close_menu"), params = { event = "qb-menu:client:closeMenu" } }
    exports['qb-menu']:openMenu(rentalMenu)
end

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

local function CreateElements()
    local jobStartCoords = Config.TruckerJobLocations["jobstart"].coords
    local jobBlip = AddBlipForCoord(jobStartCoords.x, jobStartCoords.y, jobStartCoords.z)
    SetBlipSprite(jobBlip, 527); SetBlipDisplay(jobBlip, 4); SetBlipScale(jobBlip, 0.7); SetBlipAsShortRange(jobBlip, true); SetBlipColour(jobBlip, 2)
    BeginTextCommandSetBlipName("STRING"); AddTextComponentSubstringPlayerName(Config.TruckerJobLocations["jobstart"].label); EndTextCommandSetBlipName(jobBlip)
    createNpc()
    local rentalCoords = Config.TruckerJobLocations["vehicle"].coords
    local rentalBlip = AddBlipForCoord(rentalCoords.x, rentalCoords.y, rentalCoords.z)
    SetBlipSprite(rentalBlip, 326); SetBlipDisplay(rentalBlip, 4); SetBlipScale(rentalBlip, 0.6); SetBlipAsShortRange(rentalBlip, true); SetBlipColour(rentalBlip, 5)
    BeginTextCommandSetBlipName("STRING"); AddTextComponentSubstringPlayerName(Config.TruckerJobLocations["vehicle"].label); EndTextCommandSetBlipName(rentalBlip)
    local rentalZone = BoxZone:Create(rentalCoords.xyz, 15.0, 15.0, {name = "trucker_rental_zone"})
    rentalZone:onPlayerInOut(function(isInside)
        inRentalZone = isInside
    end)
end

-- NHÓM 4: CÁC HÀM XỬ LÝ HÀNH ĐỘNG
local function GetGoodsFromTrunk()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return QBCore.Functions.Notify(Lang:t("error.get_out_vehicle"), "error") end
    local vehicle = QBCore.Functions.GetClosestVehicle()
    if not vehicle or #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) > 5.0 then
        return QBCore.Functions.Notify("Không có xe nào ở gần để lấy hàng!", "error")
    end
    local trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -2.5, 0.0)
    if #(GetEntityCoords(ped) - trunkpos) > 2.5 then
        return QBCore.Functions.Notify(Lang:t("error.too_far_from_trunk"), "error")
    end
    if isWorking then return end
    isWorking = true
    QBCore.Functions.Progressbar("work_carrybox", Lang:t("mission.take_box"), 2000, false, true, { disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true, }, { animDict = "anim@gangops@facility@servers@", anim = "hotwire", flags = 16, }, {}, {}, function()
        isWorking = false; StopAnimTask(ped, "anim@gangops@facility@servers@", "hotwire", 1.0); hasBox = true
    end, function()
        isWorking = false; StopAnimTask(ped, "anim@gangops@facility@servers@", "hotwire", 1.0); QBCore.Functions.Notify(Lang:t("error.cancelled"), "error")
    end)
end

local function DeliverGoods()
    isWorking = true
    Wait(500)
    TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_BUM_BIN", 0, true)
    QBCore.Functions.Progressbar("work_dropbox", Lang:t("mission.deliver_box"), 2000, false, true, { disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true, }, {}, {}, {}, function()
        isWorking = false; ClearPedTasks(PlayerPedId()); hasBox = false
        currentCount = currentCount + 1
        if currentCount == CurrentLocation.dropcount then
            LocationsDone[#LocationsDone + 1] = CurrentLocation.id
            TriggerServerEvent('qb-truckerjob:server:processPayment', 1)
            TriggerServerEvent('qb-trucker:server:nano')
            ClearCurrentDeliveryPoint() -- SỬA ĐỔI: Gọi hàm mới để chỉ xóa điểm hiện tại
            if #LocationsDone >= Config.TruckerJobMaxDrops then
                returnToJobNpc()
            else
                QBCore.Functions.Notify(Lang:t("mission.goto_next_point"));
                getNewDeliveryRoute()
            end
        else
            QBCore.Functions.Notify(Lang:t("mission.another_box"))
        end
    end, function()
        isWorking = false; ClearPedTasks(PlayerPedId()); QBCore.Functions.Notify(Lang:t("error.cancelled"), "error")
    end)
end

-- ===================================================================================
-- EVENTS
-- ===================================================================================
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    PlayerJob = QBCore.Functions.GetPlayerData().job
    CreateElements()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    CreateElements()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    if PlayerJob.name ~= "trucker" then
        if jobNpc then DeleteEntity(jobNpc); jobNpc = nil end
        ResetMissionState()
    end
end)

RegisterNetEvent('qb-trucker:client:AcceptMission', function()
    exports['qb-menu']:closeMenu()
    if hasAcceptedOrder or CurrentLocation then
        QBCore.Functions.Notify("Bạn đang có một nhiệm vụ chưa hoàn thành.", "error")
        return
    end
    -- Khi chấp nhận một nhiệm vụ mới, cần reset toàn bộ trạng thái
    ResetMissionState()
    hasAcceptedOrder = true
    CreateGoodsPickupZoneAndBlip()
    QBCore.Functions.Notify("Đã nhận đơn hàng. Hãy đến điểm lấy hàng để bắt đầu.", "primary")
end)

RegisterNetEvent('qb-trucker:client:OpenRentalList', function()
    OpenRentalList()
end)

RegisterNetEvent('qb-trucker:client:RentVehicle', function(data)
    if rentedVehiclePlate then
        QBCore.Functions.Notify("Bạn đã thuê một chiếc xe rồi.", "error")
        return
    end
    selectedRentalVeh = data.vehicle
    TriggerServerEvent('qb-trucker:server:DoBail', true, selectedRentalVeh)
end)

RegisterNetEvent('qb-trucker:client:SpawnVehicle', function()
    local vehicleInfo = selectedRentalVeh
    local coords = Config.TruckerJobLocations["vehicle"].coords
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        SetVehicleNumberPlateText(veh, "THUE" .. tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, coords.w)
        exports['LegacyFuel']:SetFuel(veh, 100.0)
        exports['qb-menu']:closeMenu()
        SetEntityAsMissionEntity(veh, true, true)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        SetVehicleEngineOn(veh, true, true)
        rentedVehiclePlate = QBCore.Functions.GetPlate(veh)
        QBCore.Functions.Notify("Bạn đã thuê xe thành công. Biển số: " .. rentedVehiclePlate, "success")
    end, vehicleInfo, coords, true)
end)

RegisterNetEvent('qb-trucker:client:ReturnRentedVehicle', function()
    exports['qb-menu']:closeMenu()
    if not rentedVehiclePlate then
        QBCore.Functions.Notify("Bạn chưa thuê chiếc xe nào.", "error")
        return
    end
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Bạn phải ngồi trong xe đã thuê để trả.", "error")
        return
    end
    local currentVehicle = GetVehiclePedIsIn(playerPed, false)
    if QBCore.Functions.GetPlate(currentVehicle) == rentedVehiclePlate then
        DeleteVehicle(currentVehicle)
        TriggerServerEvent('qb-trucker:server:DoBail', false)
        rentedVehiclePlate = nil
    else
        QBCore.Functions.Notify("Đây không phải chiếc xe bạn đã thuê.", "error")
    end
end)

-- SỰ KIỆN HỦY ĐƠN HÀNG (ĐÃ SỬA ĐỔI ĐỂ KHÔNG HOÀN TIỀN CỌC TẠI ĐÂY)
RegisterNetEvent('qb-trucker:client:CancelMission', function()
    exports['qb-menu']:closeMenu()
    if hasAcceptedOrder or CurrentLocation then
        ResetMissionState() -- Chỉ reset trạng thái nhiệm vụ giao hàng
        QBCore.Functions.Notify(Lang:t("error.cancelled"), "success") -- Thông báo hủy đơn hàng
    else
        QBCore.Functions.Notify("Bạn không có đơn hàng nào để hủy.", "error")
    end
    -- **Quan trọng:** Không hoàn tiền cọc thuê xe ở đây.
    -- Tiền cọc chỉ được hoàn khi xe được trả về đúng vị trí thông qua 'qb-trucker:client:ReturnRentedVehicle'.
end)

-- ===================================================================================
-- THREADS
-- ===================================================================================
CreateThread(function()
    local sleep
    while true do
        sleep = 1000
        local playerPed = PlayerPedId()
        local isTextShown = false
        if PlayerJob.name == 'trucker' and jobNpc and DoesEntityExist(jobNpc) then
            if #(GetEntityCoords(playerPed) - GetEntityCoords(jobNpc)) < 2.5 then
                sleep = 5; isTextShown = true
                exports['qb-core']:DrawText("Nhấn [E] để tương tác", "left")
                if IsControlJustReleased(0, 38) then MenuMissionStart() end
            end
        end
        if inRentalZone then
            sleep = 5; isTextShown = true
            exports['qb-core']:DrawText("Nhấn [E] để truy cập dịch vụ xe tải", "left")
            if IsControlJustReleased(0, 38) then MenuVehicleRental() end
        end
        if canPickupGoods then
            sleep = 5; isTextShown = true
            exports['qb-core']:DrawText("Nhấn [E] để lấy hàng và bắt đầu lộ trình", "left")
            if IsControlJustReleased(0, 38) then
                if not IsPedInAnyVehicle(playerPed, false) then
                    QBCore.Functions.Notify("Bạn phải ở trong xe tải để bắt đầu nhận lộ trình.", "error")
                else
                    -- CẬP NHẬT: Kiểm tra loại xe
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    if not isTruckerVehicle(vehicle) then
                        QBCore.Functions.Notify("Đây không phải là xe tải hợp lệ cho công việc.", "error")
                    else
                        getNewDeliveryRoute()
                        canPickupGoods = false
                        hasAcceptedOrder = false
                        if goodsPickupBlip then RemoveBlip(goodsPickupBlip); goodsPickupBlip = nil end
                        if goodsPickupZone then goodsPickupZone:destroy(); goodsPickupZone = nil end
                    end
                end
            end
        end
        if showMarker then
            DrawMarker(2, markerLocation.x, markerLocation.y, markerLocation.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, false, true, false, false, false)
            sleep = 0
        end
        if Delivering then
            sleep = 0; isTextShown = true
            if IsControlJustReleased(0, 38) then
                if not hasBox then GetGoodsFromTrunk()
                else
                    if #(GetEntityCoords(playerPed) - markerLocation) < 5 then DeliverGoods()
                    else QBCore.Functions.Notify(Lang:t("error.too_far_from_delivery"), "error") end
                end
            end
        end
        if not isTextShown then exports['qb-core']:HideText() end
        Wait(sleep)
    end
end)