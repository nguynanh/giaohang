Config = {}

Config.UseTarget = false

Config.TruckerJobTruckDeposit = 125
Config.TruckerJobFixedLocation = false
Config.TruckerJobMaxDrops = 20 -- amount of locations before being forced to return to station to reload
Config.TruckerJobDropPrice = 500
Config.TruckerJobBonus = 20 -- this is a percentage to calculate bonus over 5 deliveries.
Config.TruckerJobPaymentTax = 15

Config.TruckerJobLocations = {
    ["jobstart"] = {
        label = "Điểm nhận việc lái xe",
        coords = vector4(149.17, -3213.65, 5.86, 12.5),
    },
    ["vehicle"] = {
        label = "Bãi xe tải (Nơi lấy/trả xe)",
        coords = vector4(141.12, -3204.31, 5.85, 267.5),
    },
    ["stores"] = {
        { name = "Điểm giao hàng 1", coords = vector3(166.48, -3178.67, 5.88) },
        { name = "Điểm giao hàng 2", coords = vector3(179.76, -3180.13, 5.62) },
        { name = "Điểm giao hàng 3", coords = vector3(182.81, -3194.06, 5.72) },
        { name = "Điểm giao hàng 4", coords = vector3(184.92, -3207.8, 5.81) },
        { name = "Điểm giao hàng 5", coords = vector3(171.88, -3224.14, 5.79) },
    }
}

Config.TruckerJobVehicles = {
    ["rumpo"] = {
        ["label"] = "Rumpo Delivery Van",
        ["cargodoors"] = { [0] = 2, [1] = 3 },
        ["trunkpos"] = 1.5
    },
    ["benson"] = {
        ["label"] = "Benson Box Truck",
        ["jobrep"] = 0,
        ["cargodoors"] = { [0] = 5 },
        ["trunkpos"] = 3
    },
    ["mule5"] = {
        ["label"] = "Mule Box Truck",
        ["jobrep"] = 0,
        ["cargodoors"] = { [0] = 2, [1] = 3 },
        ["trunkpos"] = 1.5
    },
    ["pounder"] = {
        ["label"] = "Pounder Box Truck",
        ["jobrep"] = 0,
        ["cargodoors"] = { [0] = 2, [1] = 3 },
        ["trunkpos"] = 7
    },
    ["boxville4"] = {
        ["label"] = "Boxville StepVan",
        ["jobrep"] = 0,
        ["cargodoors"] = { [0] = 2, [1] = 3 },
        ["trunkpos"] = 1.5
    },
}