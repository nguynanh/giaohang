local QBCore = exports['qb-core']:GetCoreObject()
local Bail = {}

print('[truckerjob] SCRIPT SERVER ĐÃ ĐƯỢC TẢI VÀ ĐANG CHẠY.')

RegisterNetEvent('qb-trucker:server:DoBail', function(bool, vehInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if bool then
        if Player.PlayerData.money.cash >= Config.TruckerJobTruckDeposit then
            Bail[Player.PlayerData.citizenid] = Config.TruckerJobTruckDeposit
            Player.Functions.RemoveMoney('cash', Config.TruckerJobTruckDeposit, 'tow-received-bail')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.paid_with_cash', { value = Config.TruckerJobTruckDeposit }), 'success')
            TriggerClientEvent('qb-trucker:client:SpawnVehicle', src, vehInfo)
        elseif Player.PlayerData.money.bank >= Config.TruckerJobTruckDeposit then
            Bail[Player.PlayerData.citizenid] = Config.TruckerJobTruckDeposit
            Player.Functions.RemoveMoney('bank', Config.TruckerJobTruckDeposit, 'tow-received-bail')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.paid_with_bank', { value = Config.TruckerJobTruckDeposit }), 'success')
            TriggerClientEvent('qb-trucker:client:SpawnVehicle', src, vehInfo)
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_deposit', { value = Config.TruckerJobTruckDeposit }), 'error')
        end
    else
        if Bail[Player.PlayerData.citizenid] then
            Player.Functions.AddMoney('cash', Bail[Player.PlayerData.citizenid], 'trucker-bail-paid')
            Bail[Player.PlayerData.citizenid] = nil
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.refund_to_cash', { value = Config.TruckerJobTruckDeposit }), 'success')
        end
    end
end)

RegisterNetEvent('qb-truckerjob:server:processPayment', function(drops)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        print('[truckerjob] LỖI: Không thể lấy thông tin người chơi từ source: ' .. src)
        return
    end

    print('[truckerjob] Đã nhận được yêu cầu thanh toán từ người chơi: ' .. Player.PlayerData.name)

    if Player.PlayerData.job.name ~= 'trucker' then
        print('[truckerjob] CẢNH BÁO: Người chơi ' .. Player.PlayerData.name .. ' với job ' .. Player.PlayerData.job.name .. ' đã cố gắng gọi sự kiện thanh toán của job trucker.')
        return
    end

    local payment = Config.TruckerJobDropPrice
    local tax = math.ceil(payment / 100) * Config.TruckerJobPaymentTax
    local finalPayment = payment - tax

    if finalPayment < 0 then finalPayment = 0 end
    
    print('[truckerjob] Lương cơ bản: ' .. payment .. ' | Thuế: ' .. tax .. ' | Thực nhận: ' .. finalPayment)

    Player.Functions.AddJobReputation(1)
    Player.Functions.AddMoney('bank', finalPayment, 'trucker-salary')
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.you_earned', { value = finalPayment }), 'success')
    print('[truckerjob] Đã thanh toán thành công cho: ' .. Player.PlayerData.name)
end)

RegisterNetEvent('qb-trucker:server:nano', function()
    local chance = math.random(1, 100)
    if chance > 26 then return end
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    xPlayer.Functions.AddItem('cryptostick', 1, false)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['cryptostick'], 'add')
end)