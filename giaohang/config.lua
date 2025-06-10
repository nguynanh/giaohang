-- file: qb-jobcenter/config.lua
Config = {}

-- YEU CAU CONG VIEC
Config.JobRequired = false -- Dat la 'true' de yeu cau nghe, 'false' de cho phep tat ca moi nguoi
Config.RequiredJobName = 'delivery' -- Ten cua nghe yeu cau (viet chu thuong)

-- CAU HINH NPC
Config.NPC = {
    model = 's_m_y_dockwork_01', -- Model cua NPC
    coords = vector4(1211.03, -3200.55, 5.03, 113.1), -- Toa do NPC (Z da duoc giam de dung tren mat dat)
}

-- CAU HINH XE
Config.Vehicle = {
    spawnPoint = vector4(1201.74, -3197.32, 6.03, 168.12),
    rentPrice = 50, -- Gia thue xe
    model = 'gburrito', -- Loai xe cho thue va giao hang
}

-- CAU HINH DON HANG
Config.Deliveries = {
    {
        name = "Giao Pizza",
        reward = math.random(150, 250),
        pickup = vector3(1108.51, -3172.63, 6.03),
        dropoff = vector3(1274.65, -3254.12, 5.89)
    },
    {
        name = "Giao Hang Dien Tu",
        reward = math.random(300, 450),
        pickup = vector3(1038.2, -3198.88, 5.89),
        dropoff = vector3(1392.21, -3316.32, 5.61)
    }
}

-- NGON NGU
Config.Lang = {
    talk_to_npc = "Nhan [E] de noi chuyen",
    menu_header = "Trung Tam Viec Lam",
    rent_vehicle = "1. Thue xe",
    return_vehicle = "2. Tra xe",
    get_delivery = "3. Nhan don hang",
    cancel_delivery = "4. Huy don hang",
    close_menu = "Dong Menu",
    -- Thong bao
    no_permission = "Ban khong co cong viec phu hop.",
    not_enough_money = "Ban khong du tien de thue xe!",
    vehicle_rented = "Ban da thue mot chiec xe voi gia $",
    already_rented = "Ban da thue mot chiec xe roi!",
    must_be_in_vehicle = "Ban phai o trong xe de tra!",
    not_rented_vehicle = "Day khong phai xe ban thue!",
    vehicle_returned = "Ban da tra xe thanh cong.",
    no_vehicle_rented = "Ban chua thue chiec xe nao.",
    delivery_accepted = "Don hang da duoc nhan! Den diem lay hang.",
    delivery_cancelled = "Ban da huy don hang.",
    already_on_delivery = "Ban dang co mot don hang roi!",
    no_delivery_to_cancel = "Khong co don hang nao de huy.",
    go_to_pickup = "Di den diem nhan hang",
    at_pickup_point = "Nhan [E] de lay hang.",
    package_collected = "Da lay hang! Hay den diem giao.",
    go_to_dropoff = "Di den diem giao hang",
    at_dropoff_point = "Nhan [E] de giao hang.",
    delivery_completed = "Giao hang thanh cong! Ban nhan duoc $",
}