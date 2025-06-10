-- locales/vi.lua
local Translations = {
    error = {
        no_deposit = "Yêu cầu đặt cọc $%{value}",
        cancelled = "Đã hủy",
        vehicle_not_correct = "Đây không phải là xe thương mại!",
        no_driver = "Bạn phải là người lái xe để làm điều này..",
        no_work_done = "Bạn chưa hoàn thành công việc nào..",
        backdoors_not_open = "Cửa sau của xe chưa mở",
        get_out_vehicle = "Bạn cần ra khỏi xe để thực hiện hành động này",
        too_far_from_trunk = "Bạn cần lấy các thùng hàng từ phía sau xe của bạn",
        too_far_from_delivery = "Bạn cần đến gần điểm giao hàng hơn",
        truck_not_found = "Không tìm thấy xe tải làm việc của bạn ở gần đây!",
    },
    success = {
        paid_with_cash = "Đã trả tiền cọc $%{value} bằng tiền mặt",
        paid_with_bank = "Đã trả tiền cọc $%{value} từ ngân hàng",
        refund_to_cash = "Đã hoàn lại tiền cọc $%{value} bằng tiền mặt",
        you_earned = "Bạn đã kiếm được $%{value}",
        payslip_time = "Bạn đã đi đến tất cả các cửa hàng .. Đến lúc nhận lương!",
    },
    menu = {
        header = "Các xe tải có sẵn",
        close_menu = "⬅ Đóng Menu",
    },
    mission = {
        store_reached = "Đã đến cửa hàng, lấy một thùng hàng ở cốp xe bằng [E] và giao đến điểm đánh dấu",
        take_box = "Lấy một thùng sản phẩm",
        deliver_box = "Giao thùng sản phẩm",
        another_box = "Lấy một thùng sản phẩm khác",
        goto_next_point = "Bạn đã giao tất cả sản phẩm, đi đến điểm tiếp theo",
        return_to_station = "Bạn đã giao tất cả sản phẩm, trở về trạm",
        job_completed = "Bạn đã hoàn thành tuyến đường của mình, vui lòng nhận tiền lương",
        all_deliveries_complete = "Bạn đã hoàn thành tất cả các điểm giao hàng!",
    },
    info = {
        deliver_e = "~g~E~w~ - Giao sản phẩm",
        deliver = "Giao sản phẩm",
        job_menu_prompt = "Nhấn [E] để xem danh sách xe",
        return_truck_prompt = "Nhấn [E] để trả xe tải",
    }
}

if GetConvar('qb_locale', 'en') == 'vi' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end