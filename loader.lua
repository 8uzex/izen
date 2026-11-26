local ProtectionConfig = {
    SecretKey = "2009",
    
    -- The name of your Hub (shown in the kick message if they try to bypass)
    HubName = "UZEX Hub"
}

-------------------------------------------------------------------------------
-- Arceus X compatibility layer (added). Fills in missing executor functions
-- with safe fallbacks so the rest of the script never errors on them.
-------------------------------------------------------------------------------
pcall(function()
    local G = (type(getgenv) == "function" and getgenv()) or getfenv(0)
    local function def(name, value)
        if G[name] == nil and value ~= nil then
            G[name] = value
        end
    end

    -- HTTP request: Arceus X usually exposes request / http_request
    def("request", http_request or (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request))
    def("http_request", request)

    -- Clipboard
    def("setclipboard", toclipboard or (Clipboard and Clipboard.set) or set_clipboard)

    -- Queue on teleport (script already handles it being nil)
    def("queue_on_teleport", queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport))

    -- firesignal fallback built on getconnections
    if G.firesignal == nil and type(getconnections) == "function" then
        G.firesignal = function(signal, ...)
            for _, conn in ipairs(getconnections(signal)) do
                if conn.Fire then
                    conn:Fire(...)
                elseif conn.Function then
                    task.spawn(conn.Function, ...)
                end
            end
        end
    end

    -- fireproximityprompt fallback
    if G.fireproximityprompt == nil then
        G.fireproximityprompt = function(prompt)
            if prompt and prompt:IsA("ProximityPrompt") then
                prompt:InputHoldBegin()
                task.wait((prompt.HoldDuration or 0) + 0.05)
                prompt:InputHoldEnd()
            end
        end
    end

    -- Tell the user which executor/features were detected
    local name = (type(identifyexecutor) == "function" and select(1, identifyexecutor())) or "Unknown"
    print(("[Uzex] Executor: %s | file=%s | getconnections=%s | request=%s"):format(
        tostring(name),
        tostring(type(writefile) == "function"),
        tostring(type(getconnections) == "function"),
        tostring(type(G.request) == "function")
    ))
end)

-------------------------------------------------------------------------------
-- 👇 YOUR MAIN SCRIPT CODE STARTS HERE 👇
-------------------------------------------------------------------------------

print(ProtectionConfig.HubName .. " Loaded Successfully!")


-------------------------------------------------------------------------------
-- Uzex UI: a small, smooth, dependency-free UI library.
-- Same Library / Window / Tab API the rest of this script already uses.
-- Colours live in Library.Theme below.
-------------------------------------------------------------------------------
local Library = (function()
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Library = {}
Library.Flags = {}
Library.Assets = { Logo = "", Background = "" }
local Assets = Library.Assets

-- Runtime UI language support. Internal game values (Normal/Nightmare, item IDs,
-- remote arguments, etc.) are intentionally not translated.
Library.Language = "English"
Library._TextObjects = setmetatable({}, { __mode = "k" })
local EN_TRANSLATIONS = {
    ["Hop thời tiết"] = "Weather Hop", ["Tự động chuyển server tìm thời tiết"] = "Auto Hop Weather",
    ["Chọn thời tiết"] = "Select Weather", ["Độ trễ chuyển server"] = "Hop Delay", ["Job ID"] = "Job ID",
    ["Nhập Job ID..."] = "Enter Job ID...", ["Vào server theo Job ID"] = "Join Job ID",
    ["Sao chép Job ID hiện tại"] = "Copy Current Job ID",
    ["Sự kiện giới hạn"] = "Limited Event", ["Tự động đưa cá"] = "Auto Give Fish", ["Chọn cá boss"] = "Select Boss Fish", ["Tự dịch chuyển tới NPC"] = "Auto Teleport to NPC",
    ["UZEX Hub"] = "UZEX Hub", ["Trang chủ"] = "Home", ["Chính"] = "Main",
    ["Dịch chuyển"] = "Teleport", ["Cửa hàng"] = "Shop", ["Nâng cấp"] = "Upgrade",
    ["Khác"] = "Misc", ["Cài đặt"] = "Settings", ["Bán cá"] = "Sell Fish",
    ["Tự động bán cá"] = "Auto Sell Fish", ["Cách bán cá #1"] = "Sell Method #1",
    ["Nhiệm vụ vé tự động"] = "Auto Ticket Quest", ["Tự nhận vé nhiệm vụ"] = "Auto Claim Quest Tickets",
    ["Chế độ nhiệm vụ"] = "Quest Mode", ["Chung"] = "General", ["Di chuyển"] = "Movement",
    ["Tốc độ đi bộ"] = "Walk Speed", ["Tốc độ"] = "Speed", ["Tốc độ bay"] = "Fly Speed",
    ["Đi xuyên vật thể"] = "Noclip", ["Nhảy vô hạn"] = "Infinite Jump", ["Đảo"] = "Islands",
    ["Chọn đảo"] = "Select Island", ["Dịch chuyển đến đảo"] = "Teleport to Island",
    ["NPC"] = "NPCs", ["Chọn NPC"] = "Select NPC", ["Dịch chuyển đến NPC"] = "Teleport to NPC",
    ["Người chơi"] = "Players", ["Chọn người chơi"] = "Select Player", ["Dịch chuyển đến người chơi"] = "Teleport to Player",
    ["Mua mồi"] = "Buy Bait",
    ["Chọn mồi"] = "Select Bait", ["Số lượng mua"] = "Purchase Amount", ["Độ trễ mua (phút)"] = "Purchase Delay (minutes)",
    ["Tự động mua mồi"] = "Auto Buy Bait", ["Chế tạo mồi"] = "Craft Bait", ["Số lượng chế tạo"] = "Craft Amount",
    ["Tự động chế tạo mồi"] = "Auto Craft Bait", ["Chế tạo cần câu"] = "Craft Rod",
    ["Chọn cần câu"] = "Select Rod", ["Tự động chế tạo cần câu"] = "Auto Craft Rod",
    ["ESP người chơi"] = "Player ESP", ["Nâng cấp nhân vật"] = "Character Upgrade",
    ["Chọn 2 mục nâng cấp"] = "Select 2 Upgrade Stats", ["Phương thức nâng cấp"] = "Upgrade Method",
    ["Tự động tái sinh"] = "Auto Rebirth", ["Kiểm tra tài nguyên"] = "Check Resources",
    ["Hiển thị"] = "Visuals", ["Chống AFK"] = "Anti-AFK", ["Chống quản trị viên"] = "Anti-Admin",
    ["Tăng sáng tối đa"] = "Full Bright", ["Tắt sương mù"] = "Disable Fog", ["Chế độ hiệu năng"] = "Performance Mode",
    ["Bật thông báo"] = "Enable Notifications", ["Thông báo"] = "Notification", ["Đã bật thông báo"] = "Notifications enabled",
    ["Câu cá"] = "Fishing", ["Khóa thanh bắt cá"] = "Lock Catch Bar", ["Tự động thả câu"] = "Auto Cast",
    ["Tự động câu cá Boss"] = "Auto Farm Boss", ["Tự động câu cá Secret Boss"] = "Auto Farm Secret Boss", ["Kích hoạt Secret Boss"] = "Secret Boss Activation", ["Chuyển server"] = "Server Hop", ["Tự động kiểm tra trạng thái"] = "Auto Check Status", ["Tự động chuyển server tìm God Spirit"] = "Auto Hop to God Spirit Server", ["Tự động chuyển server tìm Maoshan"] = "Auto Hop to Maoshan Server", ["Tự động chuyển server tìm Taoist"] = "Auto Hop to Taoist Server", ["Chuyển server ngay (God Spirit)"] = "Hop Now (God Spirit)", ["Chuyển server ngay (Maoshan)"] = "Hop Now (Maoshan)", ["Chuyển server ngay (Taoist)"] = "Hop Now (Taoist)", ["Cá yêu thích"] = "Favourite Fish", ["Chọn cá"] = "Select Fish", ["Tự động yêu thích cá đã chọn"] = "Auto Favourite Selected Fish", ["Tự động bỏ qua cá"] = "Auto Skip Fish", ["Cá cần bỏ qua"] = "Fishes to Skip", ["Tự động bỏ qua cá đã chọn"] = "Auto Skip Selected Fish", ["Black Tortoise Bloodline - vùng an toàn"] = "Black Tortoise Bloodline - Safe Band",
    ["Cách thả câu"] = "Cast Method", ["Độ trễ thả câu"] = "Cast Delay", ["Tự trang bị mồi tốt nhất"] = "Auto Equip Best Bait",
    ["Tự trang bị cần câu"] = "Auto Equip Rod", ["Kỹ năng"] = "Skills", ["Tự động dùng kỹ năng"] = "Auto Use Skills",
    ["Chọn kỹ năng"] = "Select Skills", ["Boss"] = "Boss", ["Chọn chế độ Boss"] = "Select Boss Mode",
    ["Tự động Enzo"] = "Auto Enzo", ["Tự động Long DiaoHai"] = "Auto Long DiaoHai",
    ["Tự động chơi mini game"] = "Auto Play Minigame", ["Vị trí"] = "Position", ["Lưu vị trí"] = "Save Position",
    ["Đã lưu vị trí!"] = "Position saved!", ["Tự dịch chuyển đến vị trí"] = "Auto Teleport to Position",
    ["Xóa vị trí"] = "Delete Position", ["Đã xóa vị trí!"] = "Position deleted!",
    ["Mã quà tặng"] = "Gift Codes", ["Nhập tất cả mã"] = "Redeem All Codes", ["Menu tiện ích"] = "Utility Menu",
    ["Mở nâng cấp kỹ năng"] = "Open Skill Upgrade", ["Mở học kỹ năng"] = "Open Skill Learning",
    ["Mở giao diện trao đổi"] = "Open Trade UI", ["Mở đặc tính"] = "Open Traits", ["Phím tắt"] = "Hotkeys",
    ["Tắt phím tắt"] = "Disable Hotkeys", ["Phím bật bay"] = "Fly Toggle Key", ["Phím bật xuyên vật thể"] = "Noclip Toggle Key",
    ["Máy chủ"] = "Server", ["Vào lại máy chủ"] = "Rejoin Server", ["Đổi máy chủ ít người"] = "Join Low-Population Server",
    ["Tự vào lại"] = "Auto Rejoin", ["Tự vào lại khi mất kết nối"] = "Auto Rejoin on Disconnect",
    ["Thông báo Discord Webhook"] = "Discord Webhook Notifications", ["Thông báo qua Webhook"] = "Webhook Notifications",
    ["Đường dẫn Webhook"] = "Webhook URL", ["Gửi thử Webhook"] = "Test Webhook", ["Quyền riêng tư"] = "Privacy",
    ["Ẩn ID của tôi (góc trên phải)"] = "Hide My ID (top-right)", ["ID giả"] = "Fake ID",
    ["Số ID giả"] = "Fake ID Number", ["Ẩn tên"] = "Hide Name", ["Tên giả"] = "Fake Name",
    ["Nội dung tên giả"] = "Fake Name Text", ["Language / Ngôn ngữ"] = "Language / Ngôn ngữ",
    ["Tiếng Việt"] = "Tiếng Việt", ["English"] = "English", ["None"] = "None", ["Không có"] = "None",
    ["Bật"] = "Enabled", ["Tắt"] = "Disabled", ["Đang tải..."] = "Loading...",
    ["Đang tìm máy chủ ít người..."] = "Searching for a low-population server...",
    ["Đang tự động kết nối lại..."] = "Reconnecting automatically...",
    ["Đã lưu URL Webhook."] = "Webhook URL saved.", ["Đây không phải liên kết Discord Webhook."] = "This is not a Discord Webhook URL.",
}
local function translateText(value)
    if type(value) ~= "string" then return value end

    -- Build reverse lookup too, so English-created/dynamically updated labels
    -- can always return to Vietnamese when the user switches back.
    local REVERSE_TRANSLATIONS = Library._ReverseTranslations
    if not REVERSE_TRANSLATIONS then
        REVERSE_TRANSLATIONS = {}
        for vi, en in pairs(EN_TRANSLATIONS) do
            if REVERSE_TRANSLATIONS[en] == nil then
                REVERSE_TRANSLATIONS[en] = vi
            end
        end
        Library._ReverseTranslations = REVERSE_TRANSLATIONS
    end

    local map = (Library.Language == "English") and EN_TRANSLATIONS or REVERSE_TRANSLATIONS
    local exact = map[value]
    if exact then return exact end

    local upper = string.upper(value)
    for source, target in pairs(map) do
        if string.upper(source) == upper then
            return string.upper(target)
        end
    end
    return value
end
function Library:SetLanguage(language)
    self.Language = (language == "English") and "English" or "Tiếng Việt"
    for obj, record in pairs(self._TextObjects) do
        if obj and obj.Parent then
            record.updating = true
            obj.Text = translateText(record.source)
            -- Defer resetting the guard until Roblox has delivered the property-change signal.
            task.defer(function()
                record.updating = false
            end)
        else
            self._TextObjects[obj] = nil
        end
    end
end

-- The UZEX emblem (same logo as the UI preview), embedded as a PNG so it needs no Roblox upload.
-- It is written once as a local custom asset.
-- When local custom assets are unavailable, the library's normal fallback logo is used.
local EMBEDDED_LOGO = "iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAVgklEQVR42u3dW4gc15kH8P85p7qru7p77s5EsZ+FHMmDSfZhbfaiCIz9EByzZEZi8WAvSrL74MUaMIvfpHl2INFGsLBZgxeZxZ7OgyMc2BCvNeyDzYJZFEWDhWLDOtHV0lz7Utdzzj5MVbs1Hl0cjTQ9Xf8f6MWpSJpSf/9z6vuqqwAiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiLqIngKHhxrrRBCWJ6JW5ubm1N5+VknJycNPw/5KHxlrVU8E8QdQI5WewASQCflrbUjANpCiIBn6MtOnz7tNJvNJwqFgpMkSV//rKVSCUEQnPnud7+7vJ07Q4cfuy0vfAlACCE0AJ3+tycA/ADAXwP4cwABLwe+fGkUhuGAlPK9UqlUTJIEQvTn+mSMged5CILgKQDv1et1mX1WGAA7e7W3QgiT/rcBAM8BeB7AU+mhTQAJz9jmkiSxABq+7w9rrW2/7lCttUYIIZVS2/5ZYADce+ErIUTStdrvAXAIwGEAj2Shn/6KeNl1h2tSIaQQIgtT0c8/p9ZaMAB2ZuGr9B9RA0istUUAz6RF/wyAYnpotq2T6blm8VNPYQB89W2+SQsf1tpH0tX+BQD7ug7X6bFZ55/X+sQA2KGFLwHIDdv8J7He1Ps+gNomqz1HfsQA6IPVPtvmG2ttDcBkus1/suvwhEVPDIA+KvwNI7x96Rb/EL5o6lmsN/UkzyExAHZ+4Xc39bS11gXwNG7d1FNc8YkB0B/b/I1NvcPpar9nwzafRU8MgD4o/M2aek8BmAbwPQAD6aEm3epzm08MgD5a7Q3Wm3rjAJ4F8CJubupprM/rJT8exADog8Lf0NSbSFf7aQDj2aH4oqnHbT4xAPpgtd+sqfcSgANdRd692rPwiQHQZ6s9m3pE/RwAG79+m470DmD9W3jPgU09ov4KgE2aeuhq6r0EYKLrcDb1iPohAG7xsI2JtOifBZt6RP0VAJs09ZA29Q6m23w29Yj6LQDu8LCNg7i5qadZ9ER9EAAbtvnJhqbeQQBuV9GDhU+0wwPgNk297IadzZp6LHqinR4AXU/H7X7YxotgU4+o/wNACGFv8QRd4IuHbbDwifopAKy1UghhrLWPA3gXwMObrPa8YYfoPtrOm2OyJ+SOpcUfb7i+5xN0ifr9EiDd5pu06Hm3HlFOdgDdOwEWPlFOA4CIGABExAAgIgYAETEAiIgBQEQMACJiABARA4CIGABExAAgIgYAUa+z1vbM34Xftyd6QEUvhICUElJKWGuRJAkDgCgPRS+EgNYarVYLa2triOMYzWaTAUCUh6JvNBpoNBoIwxDGGJRKJV4CEOWp6LNjHMeBEIIBQLRTCx5Ap+Dvtuiz/x+bgEQ7tOiFEFBKQQiBOI7h+36n8HdK0TMAiO6h6JvNJtbW1tBqtRBF0U2XADuh6BkARFtQ9NlITwixo4qeAUCU46JnABCLPsdFzwAgFn2Oi54BQCz6HBc9A4BY9DkuegYAsehzXPQMAOqbos/uxFNq/e3xLHoGAOWo6K21iKIIrVar84tFzwCgnBT92toa2u024jgGABY9A4DyVPTdt+B2FzuLngFAO5QQolPQd1v0LHgGAPUBKSWSJMHKygoajQaLngFAebG6uopmswnf9xEEQed6nkXPAKAc+MMf/gClFJRSnafmsOjv846Lp4B67RIgJ4VvpJSWAUCUI9Zaba3VjuNIa+2278B5CUB0/4veAjAAZKlUUkIIFUXRJSHEDQBYWFjYtp0AdwBE93Gbb61NlFLC8zzlOI7QWn8YBMHhMAwfnZmZOQMAs7OzhjsAov5Z8A0AWSwWZbFYlEEQXAvD8JQx5o1XXnnlg65jBYBt7QMwAIi2brW3QghVLpeV1hpa67NRFJ0UQpycmZm5lqaDqNfrcmFhwc7Ozm57E5ABQHTvqz0KhYIqFovwfT9MkuTXAE58+OGH79frdQ0Ac3NzCgCOHTtmAYjZ2VndCz8AA4DoT6h6IYQG4JRKJSWlRBRF58MwfNta+9aRI0fOZ8cePXrUwXoDEJOTk2ZqasoCMD/5yU+GwjC0r7766up2XgowAIi+4jZfKaVKpZITBIFOkuR9AG9KKd9++eWXw7TQ1eTkZKe7393k+9nPfvZYHMfTSqlpKeU0gPfm5ubk1NSUZgAQ9e42X7quKx3Hge/716IoOimlPHnkyJGz2YFzc3NqYWHB7t27F12Fb44fP+4aY5621r4Ux/EB13VVetmw7e8HZwAQ3WK1B2CEEE65XFZxHENr/YHW+g2l1KkjR458qam3cbU/fvz4I1rrw9baQ4VCYY+1FmEYwvf9qFAoFIwxggFA1IOrfbFYlIVCQYZh2AjD8BdCiJ/PzMx8uPHavl6vi+7Cn5ubU5cvXz4ghHhea/2c67oDSZLA930DwAohJABH9MjrgRkARLcY4WmtTyql3nr55ZcvZqv9sWPHVLo7wLFjx6wQwgDAT3/603Fr7bOXLl16SUo54TgOkiRBu93WYl33TXc98yUHBgDlfbW/qxFevV7PRnida/vZ2VkcP378Sa31i9baZ13XHY/jGFEU2SiKjBBCCiFUL58EBgDlrur/lBFed+EfP358IEmS56SUzwN4ynVdhGGIVqvVvdqrnXA+GACUq23+vYzwXnvttX2FQuGFJEkOua77iLUWQRDYKIoMgJ5f7RkAlNdt/laM8A4DeMZ13WIQBPB9XwNAWvRqp54gBgD15WqPLR7hAUAQBGi1Wom1Vu3E1b6nA8AYAyn57WS699X+AYzw+uakbXsANJtNVKvVTvF3v+ON6G6v7R/gCK+vbFsA1Ot1AMAnn3yCwcFBlEolDA8Po1QqdUc6g4But9rneoTXN5cAYRhicXER165dw/DwMIaHh1Gr1TrFzyCgrOo5wuvDAOh+E8yNGzewuLgIz/MwNjaGoaGhzv/GMMj3Np8jvD4NgO7CdhwH1lq022189tlnuHLlCgYHBzE6OopKpcJdQU4IITjCy1MAdAcB8MXz4ZMkwfXr13Hjxg0MDAxgZGQEg4ODnffBs2nYf6s9gASA43kekiThCC9PAXC7XcHa2hpWV1fhui5GR0fZNOwzpVLJaq0rnuc57XZ7NY7jUwBOzszM/GbjtT1HeDkIgI27gmzVj+MYly9fxueff45arYaxsTEMDAzw8mCnfxgdRyVJ8r9BEPwyiqL/ePXVVy9uttpzhJezANgYBN27guXlZaysrMDzPAwPD2N0dJRNwx14vQ8A4+PjK1NTU3+B9Ouy3Q/S3Lt3L0d4eQ+AzcKgu2nYbDbx+eefs2m4Q2XPxese4dXrddTrdZNe23OExwDYPAiklFBKdZqGi4uLqFQqGB0dxdDQEJuGO8TRo0dl97U9APz4xz/eo5Q6ZIw5zBEeA+C2YdB9edBsNtFoNFAqlTA0NITR0VE2DXtcts0/evRocWho6Blr7WFr7TOu6xbT5+lxhMcAuLtdQbbqR1GEK1eu4Pr16xgYGMDo6Cibhj3YCjh69Kio1WoPSykPAnihUCjsA9DZ5nO1ZwD8SUEghEChUOg0DZeXl+F5XmeUWCgUuCvY3n8nkTYCB621/+N53q4NN+yw8BkAWxMG2YTA93388Y9/xJUrVzrTAzYNt1epVBJCCK/dbidaa8GiZwDctyDI7jS01t62acgweOB0+rm0PBUMgAe2K9isaTgyMoJyucxdwQPuBfAUMAC2JQi6m4ZXr17t3Gn40EMPfalpmPUWiBgAfRYEm33/oFwuY2RkBKOjo2waEgMgb7uCIAhw6dKlzp2GIyMjfGgJMQDyEgRZ09AY03loSbVaxcjICB9aQgyAPIVBd9NwbW2t8zxDNg2JAZCzXYFSCnEc4+rVq7h+/XpnVzA8PNwpfj7ynBgAfRwGmzUNr1692nnAaff3DwBIa60EIGyWJPf5r5h93fYufx4BIEurBzWLF9Zae+LECRmGIT9UDICduyvobhpevnwZ165dw9DQEB566CFUKhULoJE9zOIB/t0cIURyF4Wv0uP0Np3GxmuvvcYbgBgA/XF5kN1puLi4KJaXl1GpVAZqtdp7Fy9eTO7fH2/1+h8vPaVUQSn16eXLl3/50Ucf/eLb3/52snE3YK1VAJA+bjs5d+5ccXx8/Bmt9QsAhpIkAR7QzTm+7zu/+tWvBpIkgWDzhAHQL2HgOA6MMYiiyPE87y/vx59jjEGhUECtVkMURVheXv4/pdQJY8wvH3744U9usc03aeHjxo0bj2itD1lrX3Bdd5+1Fg/mCiW9Bki/sJX1VFj/DIC+CwIhBJrNpt6Kwup6bDaKxWLRdV202+3lMAzfAfDm17/+9fc3+XvI+fl52b3Nv3r16lNSyukkSb5XrVYHgiDA6urqA78EEEIgDMPOjoQYAH3pXr/hljYOtRDCqdVqsNYiiqLzQRC85TjO62NjYxc3bO9tuoU3ae/BfPrpp+O1Wu1ZY8yLSqknS6USGo0GlpeXE2zTd+6FEFz1GQB0m8LX6WqvqtWqs7q6GrXb7f90HOf1lZWVX+/evTvsvqZPCx/dDcelpaWJJEmmtdbTnueNR1GEZrNpgyDIHq3FzwMDgHqo6C3WX4slBwYGlJQSrVbrYqvVeksI8e+7du06lx17+vRpZ//+/Z0HaU5NTRkAuHDhgjs4OHhQCPF8FEUHqtWqajabWFpa0kIIIddvUOC2mwFAPVT4xlpri8Wi8jxPRVGEKIp+kyTJm8Vi8Z2xsbE1YP2x2ZOTkwBg5+fnb1rtL126tKdYLB4yxhwsl8t7jDFoNpvZNl9JKVn0xADoxdXe8zzpui5837/WarVOSSnfGB8f/2Djap+9Yj27tp+bm1MHDhw4YIx5SWv9dLlcdn3f7zT10kdr8d+cGAC9tNoDsEopVavVVBRFSJLkrO/7J4wxp3bt2tV5F978/Lzav3+/mZ+fBwCbbfOzEZ4xZloIMZE19bJtPh+tRQyA3lztRblclqVSCa1Way0IgneEEG9+7Wtfez+bz9+iqWcAYHFx8YkwDH+YJMn3q9VqLX0BZvbaLMltPjEAeqzwrbVaSulUq1WVjfBardbtRnjA+gjPYsMIT2v9ZLVa7b62l2zqEQOg9wpfW2tRLBbVyMiIs7KysiUjvFarZcMw5AiPGAC9us0HIKvVqhJCII7ji+12e8tGeHwXHjEAeq/wDQBbKBRUuVxWURQhjuPfxHH8ZhAE73zzm9/kCI8YAH244HdGeMViEUEQXPN9/xSANx577DGO8IgB0K+rvZRS1Wo1FccxtNZnwzA8obU+NTExwREeMQD6re4BGGOMKJfL0nVdtFqtMAzDt4UQb+7du/emEV660nOERwyAnb7HTwvb8TxPCSEQRdH5MAzfAvD23r17z3cd2xnhTU5OcoRHDIAdrDPC8zzPabVaOoqi9x3HOVEsFm8a4dXrdUxOTn5phHf+/PmJKIqm4zierlQq4+nrrjnCIwZAr6726VZdVioVJaWE7/sX2+32W9bakxMTE2ezY7ubepOTk53Cv3DhghuG4UEhxPNxHB/wPE8lSYKlpSW9ng8c4REDoNcK3wAwhULB8TxP+b6POI4/TJLk31zXrT/66KON9LjskVpfGuGdPXt2j1LqUBRFnRFeq9XC2tpaUigUlJRSPchHbRExAO684BtrrSyXy7JcLst2u32t3W7fboQnulZ7Y61VH3/88QFr7fNa64OlUskNwxBra2s6fcqNBODwiTfEAOit1b4zwkuSBHEcn2232ye11ie7R3gA5LFjx+z+/fstukZ4Z8+eHVdKTZ87d266UChMOI6DZrOZze45wiMGQK/VPW4zwtu3b9+mI7z5+XkxOzurZ2dnAQC/+93vngTwopTyWc/zxn3f74zw0ht2WPjEAOilPf7djvC678vvHuF9/PHHtTAMJx3H+QGAJ8rlMtrtNkd4xADoYV95hLdJU29CSjkdx/GhSqXySNrUs1EUcYRHDIBeXO1xbyM8c+HCBVdr/XSSJC8BOOB5nmq322g0Gjp9fLXiak8MgN4q/C0Z4TmOczCKokPFYnGPlBLtdhurq6uJtVbx2p4YAL234G/pCM91XTcMQzQaDSOltOAIjxgAPbna39cRXtrUI2IA9ErdgyM8onwFAEd4RPkMAI7wiPo9AMT6e65NttqDIzzKB2OMEbkPAGOMLpfLMgiCWEpZqFQqKggCJEnyQRzHr3OER/1Y/IVCwYnjWG/7ArzN1/fy97//faHdbv/z6Ojoj5aXlxtCiDqA1+8wwus0+7pHeJVKxQ3DEL7vd4/wemJ+l17OYHh4GPw68KY7QYRhiHfffRdhGKJfx67W2qRarTqtVuvnhULhH5eWluLZ2VmTyx1A2qQLAfz9b3/72w/K5fJ/7d69+2L3as8RHvVj8b/yyis/6oVFuFdWR5GGAebm5hSArKknv/Od7yTZcZuN8Hzf74zweuXn4Q6AO4A7FX/6XohsUpXfHkC2Ezh9+rQzPz9vpqamuq+LOMIjFn+/BwAAZCu9tVbU63W5e/fuPysWi38Tx/HfcoRHLP77o+eulev1ugQAY8zffeMb3/gnY8wjjUZDt9vtzosyBG/MJxZ/fwbA1NSUXlhYsN/61rf+4bPPPvuXwcHBbNzHbT6x+Lf68rtHT55Ybw0Ic+bMmX8dGhr64dLSUrKTt/1sAt7hg9hHTcCdUvw9uQNIPwwWgJ2bm1OPP/74j1ZWVn4+MjLiWGsTlgqx+LdOz66o63cIW5OFwJkzZzAyMrLjdwLE4mcAMASIxc8AYAgQi58BwBAgFj8DgCFALH4GAEOAWPwMAIYAsfgZAAwBYvEzABgCxOJnADAEiMXPAGAIEIufAcAQIBY/A4AhQCz+3AcAQ4BY/DkPAIYAsfhzHgAMAWLx5zwAGALE4s95ADAEiMWf8wBgCBCLP+cBwBAgFn/OA4AhQCz+nAcAQ4BY/DkPAIYAsfhzHgAMARY/iz/nAcAQYPGz+HMeAAwBFn/eiz/3AcAQYPHn/dzwA84QYPEzAOh2IYAteImqtfamX7T5OdpihsXPALjnEPB9/55fV22theu6qFQqDIDNzz0cx4HrurDWbsn5LhaLksV/h/POU7Dph0dkgbCwsPBXxhiVJPf+ZnLHcTA2Noat+L36biVyHARBgFOnTm3Z+ZFS6pmZmf8GINJQYfHTVw8C4iLHk5NTc3Nzaqt+r8nJSZ7QO6jX61v6+01NTWmeVSIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIrpL/w9HjiVGZn9PMwAAAABJRU5ErkJggg=="

local function decodeBase64(data)
    local lookup = {}
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    for i = 1, #alphabet do
        lookup[alphabet:byte(i)] = i - 1
    end
    local out = {}
    for i = 1, #data, 4 do
        local a, b, c, d = data:byte(i, i + 3)
        local n = lookup[a] * 262144 + lookup[b] * 4096 + (lookup[c] or 0) * 64 + (lookup[d] or 0)
        local x, y, z = n // 65536, n // 256 % 256, n % 256
        if d ~= 61 then
            out[#out + 1] = string.char(x, y, z)
        elseif c ~= 61 then
            out[#out + 1] = string.char(x, y)
        else
            out[#out + 1] = string.char(x)
        end
    end
    return table.concat(out)
end

pcall(function()
    if type(writefile) ~= "function" or typeof(getcustomasset) ~= "function" then
        return
    end
    local folder = "UZEXHubAssets"
    if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(folder) then
        makefolder(folder)
    end
    local path = folder .. "/UZEXHubLogo.png"
    local png = decodeBase64(EMBEDDED_LOGO)
    local fresh = type(isfile) == "function" and type(readfile) == "function" and isfile(path) and readfile(path) == png
    if not fresh then
        writefile(path, png)
    end
    local asset = getcustomasset(path)
    if type(asset) == "string" and asset ~= "" then
        Assets.Logo = asset
    end
end)

local Theme = {
    Background = Color3.fromRGB(12, 12, 13),
    Topbar = Color3.fromRGB(17, 17, 18),
    Sidebar = Color3.fromRGB(14, 14, 15),
    Surface = Color3.fromRGB(22, 22, 24),
    Surface2 = Color3.fromRGB(30, 30, 33),
    Surface3 = Color3.fromRGB(44, 44, 48),
    Stroke = Color3.fromRGB(52, 52, 56),
    Accent = Color3.fromRGB(236, 236, 240),
    AccentText = Color3.fromRGB(14, 14, 15),
    Text = Color3.fromRGB(236, 236, 240),
    Muted = Color3.fromRGB(190, 190, 198),
    Error = Color3.fromRGB(240, 100, 100),
    Warning = Color3.fromRGB(240, 176, 108),
    Success = Color3.fromRGB(130, 215, 160),
}
Library.Theme = Theme

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

---------------------------------------------------------------- helpers
local function tween(obj, time, props, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

local function new(class, props, parent)
    local inst = Instance.new(class)
    for key, value in pairs(props or {}) do
        inst[key] = value
    end
    if class == "TextLabel" or class == "TextButton" or class == "TextBox" then
        local record = { source = tostring(inst.Text or ""), updating = false }
        Library._TextObjects[inst] = record
        record.updating = true
        inst.Text = translateText(record.source)
        task.defer(function()
            record.updating = false
        end)
        inst:GetPropertyChangedSignal("Text"):Connect(function()
            if record.updating then return end
            record.source = tostring(inst.Text or "")
            local translated = translateText(record.source)
            if translated ~= inst.Text then
                record.updating = true
                inst.Text = translated
                record.updating = false
            end
        end)
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function round(parent, radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function outline(parent, color, thickness, transparency)
    return new("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function pad(parent, left, top, right, bottom)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, left),
        PaddingTop = UDim.new(0, top),
        PaddingRight = UDim.new(0, right),
        PaddingBottom = UDim.new(0, bottom),
    }, parent)
end

local function text(parent, props)
    local base = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = FONT,
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Text = "",
        TextStrokeColor3 = Color3.new(0, 0, 0),
        TextStrokeTransparency = 0.45,
    }
    for key, value in pairs(props) do
        base[key] = value
    end
    return new("TextLabel", base, parent)
end

local function hitbox(parent, size)
    return new("TextButton", {
        Size = size or UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3,
    }, parent)
end

local function safe(fn, ...)
    if type(fn) ~= "function" then
        return
    end
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[UZEX Hub] callback error: " .. tostring(err))
    end
end

local function opt(source)
    if type(source) == "string" then
        return { Name = source }
    end
    return type(source) == "table" and source or {}
end

local function titleOf(o)
    return tostring(o.Name or o.Title or o.Text or "")
end

local function descOf(o)
    local d = o.Description or o.Desc
    return d ~= nil and tostring(d) or ""
end

local function register(o, element)
    if o.Flag then
        Library.Flags[o.Flag] = element
    end
    return element
end

local function isPointer(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function attachHover(frame, button)
    button.MouseEnter:Connect(function()
        tween(frame, 0.15, { BackgroundColor3 = Theme.Surface2 })
    end)
    button.MouseLeave:Connect(function()
        tween(frame, 0.2, { BackgroundColor3 = Theme.Surface })
    end)
end

local function contains(list, value)
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

local function keyFrom(value)
    if typeof(value) == "EnumItem" then
        return value
    end
    local ok, found = pcall(function()
        return Enum.KeyCode[tostring(value)]
    end)
    return (ok and found) or Enum.KeyCode.Unknown
end

---------------------------------------------------------------- gui root
local gui

local function getGui()
    if gui and gui.Parent then
        return gui
    end
    gui = new("ScreenGui", {
        Name = "UZEXHubUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9999,
        IgnoreGuiInset = true,
    })
    pcall(function()
        gui.Parent = (type(gethui) == "function" and gethui()) or CoreGui
    end)
    if not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    local holder = new("Frame", {
        Name = "Thông báo",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.fromOffset(270, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, gui)
    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
    }, holder)
    return gui
end

function Library:Notify(o)
    if Library.NotificationsEnabled == false then
        return
    end
    o = opt(o)
    local holder = getGui():FindFirstChild("Notifications")
    if not holder then
        return
    end
    local kind = string.lower(tostring(o.Type or ""))
    local color = Theme.Text
    if kind == "error" then
        color = Theme.Error
    elseif kind == "warning" then
        color = Theme.Warning
    elseif kind == "success" then
        color = Theme.Success
    end

    local wrap = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, holder)
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(1.2, 0, 0, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
    }, wrap)
    round(card, 10)
    outline(card, Theme.Stroke, 1, 0.2)
    pad(card, 14, 10, 12, 10)
    new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, card)

    text(card, {
        Size = UDim2.new(1, 0, 0, 16),
        Font = FONT_BOLD,
        TextSize = 13,
        TextColor3 = color,
        Text = tostring(o.Title or "UZEX Hub"),
        LayoutOrder = 1,
    })
    local content = tostring(o.Content or o.Text or "")
    if content ~= "" then
        text(card, {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextSize = 12,
            TextColor3 = Theme.Muted,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = content,
            LayoutOrder = 2,
        })
    end

    tween(card, 0.4, { Position = UDim2.new(0, 0, 0, 0) })
    task.delay(tonumber(o.Duration) or 4, function()
        if card.Parent then
            tween(card, 0.3, { Position = UDim2.new(1.2, 0, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            task.delay(0.35, function()
                wrap:Destroy()
            end)
        end
    end)
end

---------------------------------------------------------------- tab / elements
local Tab = {}
Tab.__index = Tab

function Tab:_add(frame)
    self._n = self._n + 1
    frame.LayoutOrder = self._n
    frame.Parent = self.Page
    return frame
end

function Tab:_row(height)
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = (Assets.Background ~= "") and 0.8 or 0,
        BorderSizePixel = 0,
    })
    round(f, 8)
    outline(f, Theme.Stroke, 1, 0.4)
    return self:_add(f)
end

function Tab:CreateSection(name)
    local o = opt(name)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
    })
    text(holder, {
        Size = UDim2.new(1, -4, 1, -2),
        Position = UDim2.new(0, 4, 0, 4),
        Font = FONT_BOLD,
        TextSize = 11,
        TextColor3 = Theme.Muted,
        TextYAlignment = Enum.TextYAlignment.Bottom,
        Text = string.upper(titleOf(o)),
    })
    self:_add(holder)
end

function Tab:CreateParagraph(o)
    o = opt(o)
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = (Assets.Background ~= "") and 0.8 or 0,
        BorderSizePixel = 0,
    })
    round(f, 8)
    outline(f, Theme.Stroke, 1, 0.4)
    pad(f, 14, 10, 14, 10)
    new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, f)
    local title = tostring(o.Title or o.Name or "")
    if title ~= "" then
        text(f, {
            Size = UDim2.new(1, 0, 0, 16),
            Font = FONT_BOLD,
            Text = title,
            LayoutOrder = 1,
        })
    end
    local content = tostring(o.Content or o.Text or descOf(o))
    if content ~= "" then
        text(f, {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextSize = 12,
            TextColor3 = Theme.Muted,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = content,
            LayoutOrder = 2,
        })
    end
    self:_add(f)
    return register(o, {})
end
Tab.CreateLabel = Tab.CreateParagraph

function Tab:CreateStatGrid(o)
    o = opt(o)
    local items = o.Items or {}
    local columns = math.max(1, tonumber(o.Columns) or 3)
    local grid = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    })
    new("UIGridLayout", {
        CellSize = UDim2.new(1 / columns, -math.ceil(8 * (columns - 1) / columns), 0, 62),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)

    local valueLabels = {}
    for index, item in ipairs(items) do
        local card = new("Frame", {
            BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = (Assets.Background ~= "") and 0.8 or 0,
            BorderSizePixel = 0,
            LayoutOrder = index,
        }, grid)
        round(card, 10)
        outline(card, Theme.Stroke, 1, 0.4)
        local bar = new("Frame", {
            Position = UDim2.new(0, 12, 0, 10),
            Size = UDim2.fromOffset(18, 2),
            BackgroundColor3 = item.Color or Theme.Accent,
            BorderSizePixel = 0,
        }, card)
        round(bar, 1)
        valueLabels[item.Key] = text(card, {
            Position = UDim2.new(0, 12, 0, 18),
            Size = UDim2.new(1, -24, 0, 22),
            Font = FONT_BOLD,
            TextSize = 15,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(item.Value or "-"),
        })
        text(card, {
            Position = UDim2.new(0, 12, 0, 40),
            Size = UDim2.new(1, -24, 0, 14),
            TextSize = 10,
            TextColor3 = Theme.Muted,
            Text = string.upper(tostring(item.Label or item.Key)),
        })
    end
    self:_add(grid)

    local el = {}
    function el:Set(key, value)
        local label = valueLabels[key]
        if label then
            local s = tostring(value)
            if label.Text ~= s then
                label.Text = s
            end
        end
    end
    return register(o, el)
end

function Tab:CreateButton(o)
    o = opt(o)
    local desc = descOf(o)
    local f = self:_row(desc ~= "" and 52 or 40)
    text(f, {
        Size = UDim2.new(1, -50, 0, desc ~= "" and 18 or 40),
        Position = UDim2.new(0, 14, 0, desc ~= "" and 8 or 0),
        Text = titleOf(o),
    })
    if desc ~= "" then
        text(f, {
            Size = UDim2.new(1, -50, 0, 16),
            Position = UDim2.new(0, 14, 0, 27),
            TextSize = 11,
            TextColor3 = Theme.Muted,
            Text = desc,
        })
    end
    text(f, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(14, 20),
        Font = FONT_BOLD,
        TextSize = 16,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        Text = ">",
    })
    local hit = hitbox(f)
    attachHover(f, hit)
    hit.MouseButton1Down:Connect(function()
        tween(f, 0.08, { BackgroundColor3 = Theme.Surface3 })
    end)
    hit.MouseButton1Up:Connect(function()
        tween(f, 0.2, { BackgroundColor3 = Theme.Surface2 })
    end)
    hit.MouseButton1Click:Connect(function()
        safe(o.Callback)
    end)
    return register(o, {})
end

function Tab:CreateToggle(o)
    o = opt(o)
    local desc = descOf(o)
    local f = self:_row(desc ~= "" and 52 or 42)
    text(f, {
        Size = UDim2.new(1, -80, 0, desc ~= "" and 18 or 42),
        Position = UDim2.new(0, 14, 0, desc ~= "" and 8 or 0),
        Text = titleOf(o),
    })
    if desc ~= "" then
        text(f, {
            Size = UDim2.new(1, -80, 0, 16),
            Position = UDim2.new(0, 14, 0, 27),
            TextSize = 11,
            TextColor3 = Theme.Muted,
            Text = desc,
        })
    end
    local pill = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(40, 22),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
    }, f)
    round(pill, 11)
    local knob = new("Frame", {
        Position = UDim2.new(0, 3, 0.5, -8),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Theme.Muted,
        BorderSizePixel = 0,
    }, pill)
    round(knob, 8)

    local default = (o.CurrentValue or o.Default or o.Value) == true
    local state = default

    local function paint(instant)
        local pillColor = state and Theme.Accent or Theme.Surface3
        local knobColor = state and Theme.AccentText or Theme.Muted
        local knobPos = state and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        if instant then
            pill.BackgroundColor3 = pillColor
            knob.BackgroundColor3 = knobColor
            knob.Position = knobPos
        else
            tween(pill, 0.2, { BackgroundColor3 = pillColor })
            tween(knob, 0.2, { BackgroundColor3 = knobColor, Position = knobPos })
        end
    end

    local function set(value, quiet)
        value = value == true
        if value == state then
            return
        end
        state = value
        paint(false)
        if not quiet then
            safe(o.Callback, value)
        end
    end

    local hit = hitbox(f)
    attachHover(f, hit)
    hit.MouseButton1Click:Connect(function()
        set(not state)
    end)
    paint(true)

    local el = {}
    function el:Get()
        return state
    end
    function el:Set(value, quiet)
        set(value, quiet)
    end
    register(o, el)
    if default then
        safe(o.Callback, true)
    end
    return el
end

function Tab:CreateSlider(o)
    o = opt(o)
    local min = o.Min or (o.Range and o.Range[1]) or 0
    local max = o.Max or (o.Range and o.Range[2]) or 100
    local inc = o.Increment or o.Step or 1
    local frac = tostring(inc):match("%.(%d+)")
    local decimals = frac and #frac or 0
    local suffix = tostring(o.Suffix or o.Unit or "")
    local state = math.clamp(tonumber(o.CurrentValue or o.Default or o.Value) or min, min, max)

    local f = self:_row(56)
    text(f, {
        Size = UDim2.new(1, -110, 0, 18),
        Position = UDim2.new(0, 14, 0, 8),
        Text = titleOf(o),
    })
    local valueLabel = text(f, {
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.fromOffset(90, 18),
        Position = UDim2.new(1, -14, 0, 8),
        TextSize = 12,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    local track = new("Frame", {
        Position = UDim2.new(0, 14, 0, 36),
        Size = UDim2.new(1, -28, 0, 6),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
    }, f)
    round(track, 3)
    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, track)
    round(fill, 3)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, fill)
    round(knob, 6)

    local function fmt(value)
        local s = string.format("%." .. decimals .. "f", value)
        return suffix ~= "" and (s .. " " .. suffix) or s
    end

    local function ratio(value)
        if max == min then
            return 0
        end
        return (value - min) / (max - min)
    end

    local function paint(animate)
        valueLabel.Text = fmt(state)
        local size = UDim2.new(ratio(state), 0, 1, 0)
        if animate then
            tween(fill, 0.15, { Size = size })
        else
            fill.Size = size
        end
    end

    local function apply(value, animate, quiet)
        value = math.clamp(math.floor(value / inc + 0.5) * inc, min, max)
        if value == state then
            return
        end
        state = value
        paint(animate)
        if not quiet then
            safe(o.Callback, value)
        end
    end

    local dragging = false
    local hit = new("TextButton", {
        Position = UDim2.new(0, 8, 0, 26),
        Size = UDim2.new(1, -16, 0, 26),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3,
    }, f)

    local function fromX(x)
        local width = math.max(track.AbsoluteSize.X, 1)
        local p = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        apply(min + (max - min) * p, false)
    end

    hit.InputBegan:Connect(function(input)
        if isPointer(input) then
            dragging = true
            self.Page.ScrollingEnabled = false
            fromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and isMove(input) then
            fromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if dragging and isPointer(input) then
            dragging = false
            self.Page.ScrollingEnabled = true
        end
    end)
    paint(false)

    local el = {}
    function el:Get()
        return state
    end
    function el:Set(value, quiet)
        apply(tonumber(value) or state, true, quiet)
    end
    return register(o, el)
end

function Tab:_dropdown(o, multi)
    local options = table.clone(o.Options or o.Values or o.Items or {})
    local current = o.CurrentOption
    if current == nil then
        current = o.Default
    end

    local state
    local selected = {}
    if multi then
        if type(current) == "table" then
            for _, v in ipairs(current) do
                selected[v] = true
            end
        end
    else
        if type(current) == "table" then
            current = current[1]
        end
        if current == nil or not contains(options, current) then
            current = options[1]
        end
        state = current
    end

    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = (Assets.Background ~= "") and 0.8 or 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    round(f, 8)
    outline(f, Theme.Stroke, 1, 0.4)
    self:_add(f)

    text(f, {
        Size = UDim2.new(0.5, -14, 0, 42),
        Position = UDim2.new(0, 14, 0, 0),
        Text = titleOf(o),
    })
    local valueLabel = text(f, {
        Size = UDim2.new(0.5, -44, 0, 42),
        Position = UDim2.new(0.5, 0, 0, 0),
        TextSize = 12,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local chevron = text(f, {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(1, -20, 0, 0),
        Size = UDim2.fromOffset(14, 42),
        Font = FONT_BOLD,
        TextSize = 15,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        Text = ">",
    })
    local header = hitbox(f, UDim2.new(1, 0, 0, 42))
    attachHover(f, header)

    local list = new("ScrollingFrame", {
        Position = UDim2.new(0, 8, 0, 46),
        Size = UDim2.new(1, -16, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Surface3,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, f)
    new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)

    local open = false
    local buttons = {}

    local function selectedList()
        local result = {}
        for _, v in ipairs(options) do
            if selected[v] then
                result[#result + 1] = v
            end
        end
        return result
    end

    local function listHeight()
        local n = #options
        if n == 0 then
            return 0
        end
        return math.min(n * 30 + (n - 1) * 2, 150)
    end

    local function paintHeader()
        local shown
        if multi then
            local n = #selectedList()
            shown = n > 0 and (n .. " selected") or "None"
        else
            shown = state ~= nil and tostring(state) or "None"
        end
        -- Keep the translation record in sync, otherwise SetLanguage rewrites the
        -- header with the stale source text (e.g. stays "English" after picking Tiếng Việt).
        local record = Library._TextObjects[valueLabel]
        if record then
            record.source = shown
        end
        valueLabel.Text = shown
    end

    local function paintOptions()
        for option, parts in pairs(buttons) do
            local on = multi and selected[option] or (not multi and option == state)
            tween(parts.label, 0.15, { TextColor3 = on and Theme.Text or Theme.Muted })
            tween(parts.button, 0.15, { BackgroundTransparency = (on and not multi) and 0.5 or 1 })
            if parts.box then
                tween(parts.box, 0.15, { BackgroundColor3 = on and Theme.Accent or Theme.Surface3 })
            end
        end
    end

    local function resize()
        local height = listHeight()
        list.Size = UDim2.new(1, -16, 0, height)
        tween(f, 0.22, { Size = UDim2.new(1, 0, 0, open and (46 + height + 8) or 42) })
        tween(chevron, 0.22, { Rotation = open and 90 or 0 })
    end

    local function rebuild()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        buttons = {}
        for index, option in ipairs(options) do
            local b = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Theme.Surface3,
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = index,
            }, list)
            round(b, 6)
            local label = text(b, {
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                TextSize = 12,
                TextColor3 = Theme.Muted,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = tostring(option),
            })
            local box
            if multi then
                box = new("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    BackgroundColor3 = Theme.Surface3,
                    BorderSizePixel = 0,
                }, b)
                round(box, 4)
            end
            buttons[option] = { button = b, label = label, box = box }
            b.MouseEnter:Connect(function()
                if multi or option ~= state then
                    tween(b, 0.12, { BackgroundTransparency = 0.6 })
                end
            end)
            b.MouseLeave:Connect(function()
                local on = multi and selected[option] or (not multi and option == state)
                tween(b, 0.15, { BackgroundTransparency = (on and not multi) and 0.5 or 1 })
            end)
            b.MouseButton1Click:Connect(function()
                if multi then
                    selected[option] = (not selected[option]) or nil
                    paintHeader()
                    paintOptions()
                    safe(o.Callback, selectedList())
                else
                    open = false
                    resize()
                    if option ~= state then
                        state = option
                        paintHeader()
                        paintOptions()
                        safe(o.Callback, option)
                    end
                end
            end)
        end
        paintOptions()
    end

    header.MouseButton1Click:Connect(function()
        open = not open
        resize()
    end)

    rebuild()
    paintHeader()

    local el = {}
    function el:Get()
        if multi then
            return selectedList()
        end
        return state
    end
    function el:Set(value, quiet)
        if multi then
            selected = {}
            if type(value) == "table" then
                for _, v in ipairs(value) do
                    selected[v] = true
                end
            end
            paintHeader()
            paintOptions()
            if not quiet then
                safe(o.Callback, selectedList())
            end
        else
            state = value
            paintHeader()
            paintOptions()
            if not quiet then
                safe(o.Callback, value)
            end
        end
    end
    function el:Refresh(newOptions, keepSelection, quiet)
        options = table.clone(newOptions or {})
        if multi then
            local kept = {}
            if keepSelection then
                for key in pairs(selected) do
                    if contains(options, key) then
                        kept[key] = true
                    end
                end
            end
            selected = kept
        elseif not (keepSelection and state ~= nil and contains(options, state)) then
            state = options[1]
        end
        rebuild()
        paintHeader()
        if open then
            resize()
        end
        if not quiet then
            safe(o.Callback, multi and selectedList() or state)
        end
    end
    return register(o, el)
end

function Tab:CreateDropdown(o)
    o = opt(o)
    return self:_dropdown(o, (o.MultipleOptions or o.Multi) == true)
end

function Tab:CreateInput(o)
    o = opt(o)
    local f = self:_row(42)
    text(f, {
        Size = UDim2.new(1, -170, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        Text = titleOf(o),
    })
    local default = o.CurrentValue or o.Default or o.Value
    local state = default ~= nil and tostring(default) or ""
    local box = new("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(140, 26),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Font = FONT,
        TextSize = 12,
        TextColor3 = Theme.Text,
        PlaceholderText = tostring(o.PlaceholderText or o.Placeholder or ""),
        PlaceholderColor3 = Theme.Muted,
        ClearTextOnFocus = false,
        Text = state,
    }, f)
    round(box, 6)
    local boxStroke = outline(box, Theme.Stroke, 1, 1)
    box.Focused:Connect(function()
        tween(boxStroke, 0.15, { Transparency = 0 })
    end)
    box.FocusLost:Connect(function()
        tween(boxStroke, 0.2, { Transparency = 1 })
        if o.Finished ~= false then
            state = box.Text
            safe(o.Callback, state)
        end
    end)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if o.Numeric == true then
            local cleaned = box.Text:gsub("[^%d%.]", "")
            if cleaned ~= box.Text then
                box.Text = cleaned
                return
            end
        end
        state = box.Text
        if o.Finished == false then
            safe(o.Callback, state)
        end
    end)

    local el = {}
    function el:Get()
        return state
    end
    function el:Set(value, quiet)
        state = tostring(value)
        box.Text = state
        if not quiet and o.Finished ~= false then
            safe(o.Callback, state)
        end
    end
    return register(o, el)
end

function Tab:CreateKeybind(o)
    o = opt(o)
    local f = self:_row(42)
    text(f, {
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        Text = titleOf(o),
    })
    local current = keyFrom(o.CurrentKeybind or o.Default or o.Value)
    local listening = false
    local lastFire = 0

    local button = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(90, 26),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = FONT_BOLD,
        TextSize = 12,
        TextColor3 = Theme.Text,
        Text = current == Enum.KeyCode.Unknown and "None" or current.Name,
    }, f)
    round(button, 6)

    button.MouseButton1Click:Connect(function()
        if listening then
            return
        end
        listening = true
        button.Text = "..."
        tween(button, 0.15, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.AccentText })
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then
                return
            end
            connection:Disconnect()
            listening = false
            lastFire = os.clock()
            if input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= current then
                current = input.KeyCode
                safe(o.OnChanged, current.Name)
            end
            button.Text = current == Enum.KeyCode.Unknown and "None" or current.Name
            tween(button, 0.2, { BackgroundColor3 = Theme.Surface3, TextColor3 = Theme.Text })
        end)
    end)

    UserInputService.InputBegan:Connect(function(input)
        if listening or input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if current ~= Enum.KeyCode.Unknown and input.KeyCode == current and not UserInputService:GetFocusedTextBox() then
            local now = os.clock()
            if now - lastFire > 0.15 then
                lastFire = now
                safe(o.Callback)
            end
        end
    end)

    local el = {}
    function el:Get()
        return current.Name
    end
    function el:Set(value)
        current = keyFrom(value)
        button.Text = current == Enum.KeyCode.Unknown and "None" or current.Name
    end
    return register(o, el)
end

---------------------------------------------------------------- window
local Window = {}
Window.__index = Window

function Window:SelectTab(tab)
    if type(tab) ~= "table" or not tab.Page then
        return
    end
    local previous = self._active
    if previous == tab then
        return
    end
    self._active = tab
    for _, other in ipairs(self._tabs) do
        local on = other == tab
        tween(other.Label, 0.2, { TextColor3 = on and Theme.Text or Theme.Muted })
        tween(other.Button, 0.2, { BackgroundTransparency = on and 0.4 or 1 })
        tween(other.Indicator, 0.2, { BackgroundTransparency = on and 0 or 1 })
        if not on then
            other.Page.Visible = false
        end
    end
    tab.Page.Position = UDim2.new(0, 0, 0, 10)
    tab.Page.Visible = true
    tween(tab.Page, 0.25, { Position = UDim2.new(0, 0, 0, 0) })
end

function Window:CreateTab(o)
    o = opt(o)
    local title = titleOf(o)

    local button = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = #self._tabs + 1,
    }, self._tabList)
    round(button, 8)
    local indicator = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 4, 0.5, 0),
        Size = UDim2.fromOffset(3, 16),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, button)
    round(indicator, 2)
    local label = text(button, {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        TextColor3 = Theme.Muted,
        Text = title,
    })

    local page = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Surface3,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, self._content)
    pad(page, 12, 10, 12, 12)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)

    local tab = setmetatable({
        Button = button,
        Label = label,
        Indicator = indicator,
        Page = page,
        Window = self,
        _n = 0,
    }, Tab)
    table.insert(self._tabs, tab)

    button.MouseEnter:Connect(function()
        if self._active ~= tab then
            tween(button, 0.15, { BackgroundTransparency = 0.7 })
        end
    end)
    button.MouseLeave:Connect(function()
        if self._active ~= tab then
            tween(button, 0.2, { BackgroundTransparency = 1 })
        end
    end)
    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    if #self._tabs == 1 then
        self:SelectTab(tab)
    end
    return tab
end

function Window:Toggle(force)
    local show = force
    if show == nil then
        show = not self._visible
    end
    self._visible = show
    self._toggleToken = (self._toggleToken or 0) + 1
    local token = self._toggleToken
    local main = self._main
    local rest = self._basePos

    -- one tween at a time, so rapid toggles never jump or stutter
    if self._toggleTween then
        pcall(function() self._toggleTween:Cancel() end)
        self._toggleTween = nil
    end
    -- older builds animated the scale; make sure it is back at its fitted size
    local sc = main:FindFirstChildOfClass("UIScale")
    local fitted = main:GetAttribute("FitScale")
    if sc and fitted then
        sc.Scale = fitted
    end

    if show then
        if not main.Visible then
            main.GroupTransparency = 1
            main.Position = rest + UDim2.fromOffset(0, 10)
            main.Visible = true
        end
        -- fade and slide up in a single fast tween
        self._toggleTween = tween(main, 0.16, { GroupTransparency = 0, Position = rest }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    else
        local closing = tween(main, 0.11, { GroupTransparency = 1, Position = rest + UDim2.fromOffset(0, 6) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        self._toggleTween = closing
        closing.Completed:Connect(function(state)
            if state == Enum.PlaybackState.Completed and token == self._toggleToken and not self._visible then
                main.Visible = false
                main.Position = rest
            end
        end)
    end
end

function Window:SetKeybind(key)
    if typeof(key) == "EnumItem" then
        self._toggleKey = key
    end
end

function Window:Destroy()
    if self.Gui then
        self.Gui:Destroy()
    end
end

function Library:CreateWindow(o)
    o = opt(o)
    local root = getGui()
    local width, height = 600, 390

    local main = new("CanvasGroup", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        GroupTransparency = 1,
    }, root)
    round(main, 12)
    outline(main, Theme.Stroke, 1, 0.2)
    local scale = new("UIScale", {}, main)
    local function fit()
        local camera = workspace.CurrentCamera
        if camera then
            local view = camera.ViewportSize
            local fitted = math.clamp(math.min(view.X * 0.94 / width, view.Y * 0.88 / height), 0.5, 1)
            scale.Scale = fitted
            main:SetAttribute("FitScale", fitted)
        end
    end
    fit()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
    end

    local window = setmetatable({
        Gui = root,
        _main = main,
        _tabs = {},
        _visible = false,
        _basePos = main.Position,
        _toggleKey = o.ToggleUIKeybind or Enum.KeyCode.LeftControl,
    }, Window)

    -- background artwork (sits behind everything, with a dark overlay for readability)
    local hasBg = Assets.Background ~= ""
    if hasBg then
        new("ImageLabel", {
            Name = "BackgroundArt",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = Assets.Background,
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 0,
        }, main)
        new("Frame", {
            Name = "BackgroundShade",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
            ZIndex = 0,
        }, main)
        -- darker on the sidebar side, lets the artwork show through on the right
        local shade = main:FindFirstChild("BackgroundShade")
        new("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(0.28, 0.3),
                NumberSequenceKeypoint.new(1, 0.7),
            }),
        }, shade)
    end

    -- title bar
    local top = new("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = Theme.Topbar,
        BackgroundTransparency = hasBg and 0.8 or 0,
        BorderSizePixel = 0,
    }, main)
    new("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    }, top)

    local textX = 16
    if Assets.Logo ~= "" then
        local logo = new("ImageLabel", {
            Position = UDim2.new(0, 12, 0.5, -14),
            Size = UDim2.fromOffset(28, 28),
            BackgroundTransparency = 1,
            Image = Assets.Logo,
            ScaleType = Enum.ScaleType.Fit,
        }, top)
        round(logo, 6)
        textX = 50
    end
    local subtitle = tostring(o.Subtitle or "")
    text(top, {
        Size = UDim2.new(1, -textX - 60, 0, 18),
        Position = UDim2.new(0, textX, 0, subtitle ~= "" and 7 or 14),
        Font = FONT_BOLD,
        TextSize = 15,
        Text = tostring(o.Name or o.Title or "UZEX Hub"),
    })
    if subtitle ~= "" then
        text(top, {
            Size = UDim2.new(1, -textX - 60, 0, 14),
            Position = UDim2.new(0, textX, 0, 25),
            TextSize = 11,
            TextColor3 = Theme.Muted,
            Text = subtitle,
        })
    end

    local close = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Font = FONT_BOLD,
        TextSize = 18,
        TextColor3 = Theme.Muted,
        Text = "-",
    }, top)
    round(close, 8)
    close.MouseEnter:Connect(function()
        tween(close, 0.15, { BackgroundTransparency = 0, TextColor3 = Theme.Text })
    end)
    close.MouseLeave:Connect(function()
        tween(close, 0.2, { BackgroundTransparency = 1, TextColor3 = Theme.Muted })
    end)
    close.MouseButton1Click:Connect(function()
        window:Toggle(false)
        Library:Notify({
            Title = "Đã ẩn",
            Content = "Nhấn " .. window._toggleKey.Name .. " hoặc chạm vào logo để mở lại.",
            Duration = 3,
        })
    end)

    -- dragging
    local dragging, dragStart, startPos = false, nil, nil
    top.InputBegan:Connect(function(input)
        if isPointer(input) then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and isMove(input) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            window._basePos = main.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if dragging and isPointer(input) then
            dragging = false
        end
    end)

    -- sidebar + content
    local sidebar = new("Frame", {
        Position = UDim2.new(0, 0, 0, 46),
        Size = UDim2.new(0, 150, 1, -46),
        BackgroundColor3 = Theme.Sidebar,
        BackgroundTransparency = hasBg and 0.8 or 0,
        BorderSizePixel = 0,
    }, main)
    new("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    }, sidebar)
    local tabList = new("ScrollingFrame", {
        Size = UDim2.new(1, -1, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, sidebar)
    pad(tabList, 8, 10, 8, 10)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)
    window._tabList = tabList

    local content = new("Frame", {
        Position = UDim2.new(0, 150, 0, 46),
        Size = UDim2.new(1, -150, 1, -46),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, main)
    window._content = content

    -- optional Home tab
    local home = o.Home
    if type(home) == "table" then
        local tab = window:CreateTab({ Name = home.Name or "Home" })
        if type(home.Stats) == "table" then
            tab:CreateSection(tostring(home.StatsTitle or "Session"))
            window.Stats = tab:CreateStatGrid({ Items = home.Stats, Columns = 3 })
        end
        tab:CreateParagraph({
            Title = tostring(home.Title or o.Name or ""),
            Content = tostring(home.Desc or o.Subtitle or ""),
        })
        if home.Discord then
            tab:CreateButton({
                Name = tostring(home.DiscordTitle or "Discord"),
                Description = "Copy the invite link",
                Callback = function()
                    local copied = false
                    if type(setclipboard) == "function" then
                        copied = pcall(setclipboard, tostring(home.Discord))
                    end
                    Library:Notify({
                        Title = tostring(home.DiscordTitle or "Discord"),
                        Content = copied and "Invite link copied to clipboard" or tostring(home.Discord),
                        Duration = 3,
                    })
                end,
            })
        end
    end

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode == window._toggleKey
            and not UserInputService:GetFocusedTextBox() then
            window:Toggle()
        end
    end)

    window:Toggle(true)
    return window
end
Library.Window = Library.CreateWindow

return Library
end)()

--------------------------------------------------------------------------------
-- UZEX Hub application
--------------------------------------------------------------------------------

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local Info = ReplicatedStorage:WaitForChild("Info")
local DataFolder = ReplicatedStorage:WaitForChild("Data")
local PlayerData = DataFolder:WaitForChild(LocalPlayer.UserId)

local ToggleHotbar = Events:WaitForChild("ToggleHotbar")
local FishingEvent = Events:WaitForChild("Fishing")
local UpdateFishProgression = Events:WaitForChild("UpdateFishProgression")
local UseSkill = Events:WaitForChild("UseSkill")
local SellFish = Events:WaitForChild("SellFish")
local CraftBaitEvent = Events:WaitForChild("CraftBait")
local CraftRodEvent = Events:WaitForChild("CraftRod")
local RedeemCodeEvent = Events:WaitForChild("RedeemCode")
local EquipBaitEvent = Events:WaitForChild("EquipBait", 9e9)

local Config = {
    AutoCast = false,
    AutoCastMethod = "Instant",
    AntiStaff = false,
    HideName = false,
    NotificationsEnabled = true,
    PerformanceMode = false,
    UpgradeOptions = {"Cash", "Level"},
    UpgradeMethod = "Instant",
    AutoRebirth = false,
    FilterBossFish = false,
    AutoFarmSecretBoss = false,
    AutoSecretBossMode = "Always Active",
    FavoriteFish = "",
    AutoFavoriteFish = false,
    SkipFishList = {},
    AutoSkipFish = false,
    BlackTortoiseBand = 0.12,
    DumpGuyHotbarSlot = 4,
    AutoGiveFish = false,
    AutoGiveEventFish = false,
    AutoGiveEventFishTarget = {},
    EventGiveTeleport = true,
    HopAutoCheck = false,
    AutoHopGodSpirit = false,
    AutoHopMaoshan = false,
    AutoHopTaoist = false,
    AutoHopWeather = false,
    SelectedWeather = "Thunderstorm",
    HopWeatherDelay = 5,
    CastDelay = 1,
    AutoReel = false,
    AutoMiniGame = false,
    BossHitDelay = 15,
    BossMode = "Normal",
    AutoBoss = false,
    AutoSecretBoss = false,
    AutoSkill = false,
    SkillOrder = {"Z", "X", "C", "V"},
    AutoSell = false,
    AutoSellMethod = "Spam",
    SellDelay = 1,
    SelectedBuyBait = "",
    BuyBaitAmount = 1,
    BuyBaitDelay = 1,
    AutoBuyBait = false,
    SelectedBait = "",
    BaitAmount = 1,
    AutoCraftBait = false,
    SelectedRod = "",
    AutoCraftRod = false,
    SelectedIsland = "",
    SelectedNPC = "",
    SelectedPlayer = "",
    ESPEnabled = false,
    AntiAFK = true,
    FullBright = false,
    NoFog = false,
    LoopSpeedEnabled = false,
    WalkSpeed = 30,
    NoclipEnabled = false,
    InfJumpEnabled = false,
    FlyEnabled = false,
    FlySpeed = 2,
    FlyKeybind = "F",
    FlyKeybindEnabled = true,
    NoclipKeybind = "J",
    NoclipKeybindEnabled = true,
    DisableAllKeybinds = false,
    SavedPos = false,
    AutoTPPos = false,
    AutoExecute = false,
    AutoRejoin = true,
    WebhookEnabled = false,
    WebhookUrl = "",
    WebhookInterval = 0,
    WebhookOnCatch = false,
    HideId = true,
    FakeNameEnabled = false,
    FakeName = "Player",
    FakeIdEnabled = false,
    FakeId = "",
    AutoFarmIsland = false,
    SelectedFarmIsland = "Beginning Isle",
    AutoTicketQuest = false,
    AutoDailyQuest = false,
    TicketQuestMode = "Hard",
    AutoEquipBestBait = false,
    AutoEquipRod = false,
    Language = "English"
}

local SAVE_FOLDER = "UZEXHub"
local SAVE_FILE = SAVE_FOLDER .. "/HeavyweighFishingConfig.json"

local function SaveConfig()
    pcall(function()
        if not isfolder(SAVE_FOLDER) then makefolder(SAVE_FOLDER) end
        -- Auto Hop Weather is never saved, so joining a server never starts a hop by itself
        local toSave = table.clone(Config)
        toSave.AutoHopWeather = false
        writefile(SAVE_FILE, HttpService:JSONEncode(toSave))
    end)
end

local function LoadConfig()
    pcall(function()
        if isfile(SAVE_FILE) then
            local decoded = HttpService:JSONDecode(readfile(SAVE_FILE))
            for k, v in pairs(decoded) do
                if Config[k] ~= nil then
                    Config[k] = v
                end
            end
        end
    end)
end

LoadConfig()
Config.AutoHopWeather = false -- not persisted: always starts OFF
if type(Config.AutoGiveEventFishTarget) == "string" then
    Config.AutoGiveEventFishTarget = Config.AutoGiveEventFishTarget ~= "" and { Config.AutoGiveEventFishTarget } or {}
elseif type(Config.AutoGiveEventFishTarget) ~= "table" then
    Config.AutoGiveEventFishTarget = {}
end
Config.AutoFarmIsland = false -- Auto Farm Fish was removed from the UI
Library.NotificationsEnabled = Config.NotificationsEnabled ~= false
Library.Language = (Config.Language == "Tiếng Việt") and "Tiếng Việt" or "English" -- saved language
if type(Config.SkillOrder) ~= "table" then
    Config.SkillOrder = {"Z", "X", "C", "V"}
else
    local validKeys = {Z = true, X = true, C = true, V = true}
    local filtered = {}
    for _, k in ipairs(Config.SkillOrder) do
        if validKeys[k] and not table.find(filtered, k) then
            table.insert(filtered, k)
        end
    end
    Config.SkillOrder = filtered
end

local queueTeleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or queueonteleport
local autoExecQueued = false
-- The script that Auto Execute / Auto Rejoin start again after a teleport.
-- Put the link where THIS script is hosted (the same raw link you use to run it).
local autoExecPayload = [[
task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local lp = Players.LocalPlayer
    while not lp do
        task.wait(0.2)
        lp = Players.LocalPlayer
    end
    repeat task.wait(0.2) until lp.Character and lp:FindFirstChild("PlayerGui")
    local allow = false
    pcall(function()
        if isfile then
            allow = false
            if isfile("UZEXHub/rejoin.flag") and delfile then
                pcall(delfile, "UZEXHub/rejoin.flag")
            end
            -- only run when Auto Execute is ON in the saved config
            if isfile("UZEXHub/HeavyweighFishingConfig.json") then
                local dec = HttpService:JSONDecode(readfile("UZEXHub/HeavyweighFishingConfig.json"))
                allow = (type(dec) == "table" and dec.AutoExecute == true)
            end
        end
    end)
    if not allow then
        return
    end
    local env = (getgenv and getgenv()) or _G
    if env.UzexBootLock and (os.clock() - env.UzexBootLock) < 90 then
        return
    end
    env.UzexBootLock = os.clock()
    local source
    for _ = 1, 3 do
        local ok, body = pcall(game.HttpGet, game, "]] .. "https://raw.githubusercontent.com/8uzex/izen/refs/heads/main/script.lua" .. [[")
        if ok and type(body) == "string" and #body > 0 then
            source = body
            break
        end
        task.wait(3)
    end
    if source then
        local fn = loadstring(source)
        if fn then
            fn()
        end
    end
end)
]]

local function QueueAutoExecute(force)
    if not queueTeleport then return end
    if not Config.AutoExecute then return end
    if autoExecQueued and not force then return end
    if autoExecPayload:find("YOUR-USER", 1, true) then
        pcall(function()
            Library:Notify({
                Title = "Auto Execute ",
                Content = "Hãy đặt liên kết script trong autoExecPayload trước.",
                Type = "warning",
                Duration = 6,
            })
        end)
        return
    end
    autoExecQueued = true
    pcall(function()
        queueTeleport(autoExecPayload)
    end)
end

if Config.AutoExecute then
    QueueAutoExecute()
end

pcall(function()
    LocalPlayer.OnTeleport:Connect(function()
        if Config.AutoExecute then
            QueueAutoExecute()
        end
    end)
end)

local function GetSavedCFrame()
    if type(Config.SavedPos) == "table" and #Config.SavedPos >= 3 then
        local ok, cf = pcall(CFrame.new, unpack(Config.SavedPos))
        if ok and cf then
            return cf
        end
    end
    return nil
end

local IslandFarmPositions = {
    ["Beginning Isle"] = CFrame.new(-297.48, 9.28, 58.78, 0.00, 0.00, 1.00, -0.00, 1.00, -0.00, -1.00, -0.00, 0.00),
    ["Bamboo Isle"] = CFrame.new(-1310.04, 9.28, 29.79, -0.28, -0.00, 0.96, -0.00, 1.00, 0.00, -0.96, -0.00, -0.28),
    ["Fallout Isle"] = CFrame.new(76.47, 9.28, 1265.92, -1.00, 0.00, 0.01, 0.00, 1.00, -0.00, -0.01, -0.00, -1.00),
    ["Sovereign Isle"] = CFrame.new(-1254.18, 9.28, 1301.79, -1.00, 0.00, -0.07, 0.00, 1.00, -0.00, 0.07, -0.00, -1.00),
    ["Perch Isle"] = CFrame.new(-38.55, 9.28, -1343.82, 0.99, -0.00, -0.12, 0.00, 1.00, 0.00, 0.12, -0.00, 0.99),
    ["Frost Isle"] = CFrame.new(-1348.71, 9.28, -1446.51, -1.00, -0.00, -0.03, -0.00, 1.00, 0.00, 0.03, 0.00, -1.00),
    ["Coconut Isle"] = CFrame.new(1431.00, 9.28, -1430.22, -0.17, 0.00, 0.98, -0.00, 1.00, -0.00, -0.98, -0.00, -0.17),
    ["Amber Isle"] = CFrame.new(1122.07, 9.28, 1414.54, 0.03, -0.00, 1.00, -0.00, 1.00, 0.00, -1.00, -0.00, 0.03),
    ["Battlefield Isle"] = CFrame.new(1249.73, 19.56, 68.87, 0.01, 0.00, 1.00, 0.00, 1.00, -0.00, -1.00, 0.00, 0.01),
    ["Mistpeak Isle"] = CFrame.new(2549.02, 9.28, -80.77, -0.03, 0.00, 1.00, 0.00, 1.00, -0.00, -1.00, 0.00, -0.03),
    ["World Angler Isle"] = CFrame.new(-2345.67, 9.28, -203.65, -0.09, -0.00, -1.00, 0.00, 1.00, -0.00, 1.00, -0.00, -0.09),
    ["Weather Isle"] = CFrame.new(-2886.12, 6.76, 1199.79, -0.04, -0.00, -1.00, -0.00, 1.00, -0.00, 1.00, 0.00, -0.04),
    ["Mystic Reef Isle"] = CFrame.new(-2561.58, 9.28, -1288.64, -0.07, -0.00, -1.00, 0.00, 1.00, -0.00, 1.00, -0.00, -0.07)
}

local function GetIslandFarmCFrame(islandKey)
    local key = islandKey or Config.SelectedFarmIsland or ""
    if IslandFarmPositions[key] then
        return IslandFarmPositions[key]
    end
    local cleanKey = tostring(key):gsub("%s*|%s*%d+", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if IslandFarmPositions[cleanKey] then
        return IslandFarmPositions[cleanKey]
    end
    local lowerClean = string.lower(cleanKey)
    for name, cf in pairs(IslandFarmPositions) do
        local lName = string.lower(name)
        if lowerClean == lName or string.find(lowerClean, lName, 1, true) or string.find(lName, lowerClean, 1, true) then
            return cf
        end
    end
    return nil
end

local ModuleCache = {}

local function GetModuleData(mod)
    if not mod or not mod:IsA("ModuleScript") then return nil end
    local cached = ModuleCache[mod]
    if cached ~= nil then
        return cached ~= false and cached or nil
    end
    local ok, data = pcall(require, mod)
    if ok and type(data) == "table" then
        ModuleCache[mod] = data
        return data
    end
    ModuleCache[mod] = false
    return nil
end

-- Anti-AFK: Roblox kicks after 20 minutes idle (error 278), which Auto Rejoin then
-- turns into a server change. Old Roblox Idled handlers are disabled FIRST, and only
-- then do we connect our own (before, the loop below disabled our own handler too).
if getconnections then
    pcall(function()
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
            if conn.Disable then
                conn:Disable()
            elseif conn.Disconnect then
                conn:Disconnect()
            end
        end
    end)
end

local lastAfkTick = os.clock()

local function AntiAfkPulse()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
    pcall(function()
        -- fallback: tiny real input so the idle timer always resets
        VirtualInputManager:SendMouseMoveEvent(1, 1, game)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
    end)
end

LocalPlayer.Idled:Connect(function()
    if not Config.AntiAFK then return end
    AntiAfkPulse()
end)

task.spawn(function()
    while true do
        task.wait(1)
        if Config.AntiAFK then
            local now = os.clock()
            if now - lastAfkTick >= 240 then -- every 4 minutes (kick is at 20)
                lastAfkTick = now
                AntiAfkPulse()
            end

            pcall(function()
                local afkVal = PlayerData and PlayerData:FindFirstChild("AFK")
                if afkVal and afkVal.Value == true then
                    local afkEvent = Events:FindFirstChild("AFK")
                    if afkEvent then
                        afkEvent:FireServer()
                    end
                end
            end)
        else
            lastAfkTick = os.clock()
        end
    end
end)

local cachedChar = LocalPlayer.Character
local cachedHum = cachedChar and cachedChar:FindFirstChildOfClass("Humanoid")
local cachedHrp = cachedChar and cachedChar:FindFirstChild("HumanoidRootPart")
local cachedSkillsFolder = cachedChar and cachedChar:FindFirstChild("Skills")
local cachedStatsFolder = cachedChar and cachedChar:FindFirstChild("Stats")
local FishesFolder = workspace:FindFirstChild("Fishes")

local MainGui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainGui")
local FishingGui = MainGui:WaitForChild("Fishing")
local BarFrame = FishingGui:WaitForChild("BarFrame")
local FishingBar = BarFrame:WaitForChild("Bar")
local SkillBtnFrame = FishingGui:WaitForChild("SkillButton"):WaitForChild("Frame")
local RhythmGui = FishingGui:FindFirstChild("Rhythm")
local BossFightBar = FishingGui:FindFirstChild("BossFightBar")
local MobileGui = MainGui:FindFirstChild("Mobile")
local MobileFishingBtn = MobileGui and MobileGui:FindFirstChild("Fishing")
local RhythmHitEvent = Events:FindFirstChild("RhythmHit")

local function RefreshGuiCache()
    if not MainGui or not MainGui.Parent then
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        MainGui = pg and pg:FindFirstChild("MainGui")
        FishingGui = MainGui and MainGui:FindFirstChild("Fishing")
        BarFrame = FishingGui and FishingGui:FindFirstChild("BarFrame")
        FishingBar = BarFrame and BarFrame:FindFirstChild("Bar")
        local sb = FishingGui and FishingGui:FindFirstChild("SkillButton")
        SkillBtnFrame = sb and sb:FindFirstChild("Frame")
        RhythmGui = FishingGui and FishingGui:FindFirstChild("Rhythm")
        BossFightBar = FishingGui and FishingGui:FindFirstChild("BossFightBar")
        MobileGui = MainGui and MainGui:FindFirstChild("Mobile")
        MobileFishingBtn = MobileGui and MobileGui:FindFirstChild("Fishing")
    else
        if not RhythmGui or not RhythmGui.Parent then
            RhythmGui = FishingGui and FishingGui:FindFirstChild("Rhythm")
        end
        if not BossFightBar or not BossFightBar.Parent then
            BossFightBar = FishingGui and FishingGui:FindFirstChild("BossFightBar")
        end
        if not MobileFishingBtn or not MobileFishingBtn.Parent then
            MobileGui = MainGui and MainGui:FindFirstChild("Mobile")
            MobileFishingBtn = MobileGui and MobileGui:FindFirstChild("Fishing")
        end
    end
    if not RhythmHitEvent then
        RhythmHitEvent = Events:FindFirstChild("RhythmHit")
    end
    if not FishesFolder or not FishesFolder.Parent then
        FishesFolder = workspace:FindFirstChild("Fishes")
    end
end

local _noclipThrottle = 0
RunService.Stepped:Connect(function(_, dt)
    if not Config.NoclipEnabled and not Config.LoopSpeedEnabled then return end
    _noclipThrottle = _noclipThrottle + dt
    if _noclipThrottle < 0.08 then return end
    _noclipThrottle = 0

    local char = cachedChar
    if not char or not char.Parent then return end

    if Config.NoclipEnabled then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if Config.LoopSpeedEnabled and cachedHum and cachedHum.WalkSpeed ~= Config.WalkSpeed then
        cachedHum.WalkSpeed = Config.WalkSpeed
    end
end)

local lastInfJumpTick = 0

local function IsInsideOceanWater(hrp)
    if not hrp then return false end
    local ocean = workspace:FindFirstChild("Ocean")
    if not ocean then return false end
    local pos = hrp.Position
    for _, child in ipairs(ocean:GetChildren()) do
        if child.Name == "Water" and child:IsA("BasePart") then
            local half = child.Size * 0.5
            local diff = child.Position - pos
            if math.abs(diff.X) <= half.X and math.abs(diff.Y) <= half.Y and math.abs(diff.Z) <= half.Z then
                return true
            end
        end
    end
    return false
end

UserInputService.JumpRequest:Connect(function()
    if not Config.InfJumpEnabled then return end
    local now = os.clock()
    if now - lastInfJumpTick < 0.18 then return end
    local char = cachedChar or LocalPlayer.Character
    local hum = cachedHum or (char and char:FindFirstChildOfClass("Humanoid"))
    local hrp = cachedHrp or (char and char:FindFirstChild("HumanoidRootPart"))
    if not char or not hum or not hrp or hum.Health <= 0 then return end
    if char:GetAttribute("Swimming") == true or hrp:FindFirstChildOfClass("BodyPosition") or IsInsideOceanWater(hrp) then
        return
    end
    lastInfJumpTick = now
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end)

local flyConnection = nil
local jumpStateConnection = nil

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if not hrp or not humanoid then return end

    humanoid.PlatformStand = true

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 1e7
    bg.D = 12000
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    jumpStateConnection = humanoid.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall then
            humanoid.PlatformStand = true
        end
    end)

    flyConnection = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        local move = Vector3.zero
        local md = humanoid.MoveDirection

        if md.Magnitude > 0 then
            local flatLook = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
            local flatRight = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)

            if flatLook.Magnitude > 0.01 and flatRight.Magnitude > 0.01 then
                local fwdAmt = md:Dot(flatLook.Unit)
                local rightAmt = md:Dot(flatRight.Unit)

                move += cam.CFrame.LookVector * fwdAmt
                move += cam.CFrame.RightVector * rightAmt
            end
        end

        if move.Magnitude > 0 then move = move.Unit end
        bv.Velocity = move * Config.FlySpeed * 50
        local look = cam.CFrame.LookVector
        bg.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + look, Vector3.new(0, 1, 0))
    end)
end

local function stopFly()
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if humanoid then humanoid.PlatformStand = false end
    if jumpStateConnection then
        jumpStateConnection:Disconnect()
        jumpStateConnection = nil
    end
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if hrp then
        for _, v in pairs(hrp:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then
                v:Destroy()
            end
        end
    end
end

local function IsAntiConfuseActive()
    return Config.AutoSkill or Config.AutoMiniGame or Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland
end

local function ApplyAntiConfuse(char)
    if not IsAntiConfuseActive() then return end
    if char then
        if char:GetAttribute("Confused") == true then
            pcall(function() char:SetAttribute("Confused", false) end)
        end
        if char:GetAttribute("SkillLocked") == true then
            pcall(function() char:SetAttribute("SkillLocked", false) end)
        end
    end
    if SkillBtnFrame then
        for _, btn in ipairs(SkillBtnFrame:GetChildren()) do
            if btn:IsA("TextButton") then
                local lock = btn:FindFirstChild("Lock")
                if lock and lock.Visible then
                    lock.Visible = false
                end
            end
        end
    end
    if FishingGui then
        local hpPlayer = FishingGui:FindFirstChild("HPPlayer")
        local debuff = hpPlayer and hpPlayer:FindFirstChild("Debuff")
        local confusedGui = debuff and debuff:FindFirstChild("Confused")
        if confusedGui then
            pcall(function() confusedGui:Destroy() end)
        end
    end
end

local antiConfuseConns = {}

local function BindCharacterAntiConfuse(char)
    for _, c in ipairs(antiConfuseConns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(antiConfuseConns)
    if not char then return end
    table.insert(antiConfuseConns, char:GetAttributeChangedSignal("Confused"):Connect(function()
        if IsAntiConfuseActive() and char:GetAttribute("Confused") == true then
            ApplyAntiConfuse(char)
        end
    end))
    table.insert(antiConfuseConns, char:GetAttributeChangedSignal("SkillLocked"):Connect(function()
        if IsAntiConfuseActive() and char:GetAttribute("SkillLocked") == true then
            ApplyAntiConfuse(char)
        end
    end))
    if IsAntiConfuseActive() then
        ApplyAntiConfuse(char)
    end
end

local function StepAutoTPPos(char)
    if not Config.AutoTPPos then return end
    if Config.AutoBoss or Config.AutoSecretBoss then return end
    local targetCF = GetSavedCFrame()
    if not targetCF then return end
    local c = char or cachedChar or LocalPlayer.Character
    local hrp = (c and c:FindFirstChild("HumanoidRootPart")) or cachedHrp
    if hrp and (hrp.Position - targetCF.Position).Magnitude > 5 then
        hrp.CFrame = targetCF
    end
end

local function StepAutoFarmIsland(char)
    if not Config.AutoFarmIsland then return end
    if Config.AutoBoss or Config.AutoSecretBoss then return end
    local targetCF = GetIslandFarmCFrame()
    if not targetCF then return end
    local c = char or cachedChar or LocalPlayer.Character
    local hrp = (c and c:FindFirstChild("HumanoidRootPart")) or cachedHrp
    if hrp and (hrp.Position - targetCF.Position).Magnitude > 5 then
        hrp.CFrame = targetCF
    end
end

if cachedChar then
    BindCharacterAntiConfuse(cachedChar)
    task.spawn(function()
        StepAutoTPPos(cachedChar)
        StepAutoFarmIsland(cachedChar)
    end)
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    cachedChar = newChar
    cachedHum = newChar:WaitForChild("Humanoid", 5)
    cachedHrp = newChar:WaitForChild("HumanoidRootPart", 5)
    cachedSkillsFolder = newChar:WaitForChild("Skills", 5)
    cachedStatsFolder = newChar:WaitForChild("Stats", 5)
    BindCharacterAntiConfuse(newChar)
    task.wait(0.3)
    StepAutoTPPos(newChar)
    StepAutoFarmIsland(newChar)
    if Config.FlyEnabled then
        startFly()
    end
end)

local minigameOpenTick = 0
local wasMinigameVisible = false
local bossPhase2SetupUntil = 0

do
    local bp2 = Events:FindFirstChild("BossPhase2Setup")
    if bp2 and bp2:IsA("RemoteEvent") then
        bp2.OnClientEvent:Connect(function()
            bossPhase2SetupUntil = os.clock() + 5
        end)
    end
end

local IsGameAllowingSkill, IsSkillSlotAvailable, IsSkillOnCooldown, IsSkillKeyReady, UzexFilter, TriggerGuiButton
do
local function FindSkillNumberValue(char, key)
    local skillsFolder = cachedSkillsFolder or (char and char:FindFirstChild("Skills"))
    if not skillsFolder then return nil, nil end
    for _, s in ipairs(skillsFolder:GetChildren()) do
        if s:IsA("NumberValue") then
            local k = s:GetAttribute("Key") or s.Name
            if tostring(k) == key then
                return s, skillsFolder
            end
        end
    end
    return nil, skillsFolder
end

local function FindSkillButton(key)
    if not SkillBtnFrame then return nil end
    local direct = SkillBtnFrame:FindFirstChild(key)
    if direct then return direct end
    for _, child in ipairs(SkillBtnFrame:GetChildren()) do
        if child:IsA("GuiObject") then
            if tostring(child:GetAttribute("Key") or "") == key then
                return child
            end
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Name ~= "CD" and desc.Text == key then
                    return child
                end
            end
        end
    end
    return nil
end

function IsGameAllowingSkill(char)
    if not FishingGui or not FishingGui.Visible then
        wasMinigameVisible = false
        return false
    end

    if not wasMinigameVisible then
        wasMinigameVisible = true
        minigameOpenTick = os.clock()
    end

    if (RhythmGui and RhythmGui.Visible) or (BossFightBar and BossFightBar.Visible) then
        return false
    end

    if char:GetAttribute("Phase2") == true then
        bossPhase2SetupUntil = 0
        return false
    end

    if bossPhase2SetupUntil > 0 and os.clock() < bossPhase2SetupUntil then
        return false
    end

    if not IsAntiConfuseActive() then
        if char:GetAttribute("SkillLocked") or char:GetAttribute("Confused") then
            return false
        end
    else
        ApplyAntiConfuse(char)
    end

    local stats = cachedStatsFolder or char:FindFirstChild("Stats")
    if stats and stats:FindFirstChild("Stun") and stats.Stun.Value == true then
        return false
    end

    local fishId = LocalPlayer:GetAttribute("FishID")
    local fishObj = (fishId and FishesFolder) and FishesFolder:FindFirstChild(tostring(fishId)) or nil
    if fishObj then
        local readyVal = fishObj:FindFirstChild("Ready")
        if readyVal then
            if readyVal.Value ~= true then
                return false
            end
        elseif os.clock() - minigameOpenTick < 3.1 then
            return false
        end
        if fishObj:GetAttribute("FinalPhase") == true or fishObj:GetAttribute("PreFinalPhase") == true then
            return false
        end
    elseif os.clock() - minigameOpenTick < 3.1 then
        return false
    end

    local skillsFolder = cachedSkillsFolder or char:FindFirstChild("Skills")
    if skillsFolder then
        for _, s in ipairs(skillsFolder:GetChildren()) do
            if s:IsA("NumberValue") and (s:GetAttribute("UsingSkill") or 0) > 0 then
                return false
            end
        end
    end

    return true
end

function IsSkillSlotAvailable(char, key)
    if PlayerData then
        local rodVal = PlayerData:FindFirstChild("FishingRod")
        local rodInv = PlayerData:FindFirstChild("FishingRodInventory")
        local rf = (rodVal and rodVal.Value ~= "" and rodInv) and rodInv:FindFirstChild(rodVal.Value) or nil
        local skFolder = rf and rf:FindFirstChild("Skill")
        local skVal = skFolder and skFolder:FindFirstChild(key)
        if skVal and skVal:IsA("StringValue") then
            return skVal.Value ~= ""
        end
    end
    local btn = FindSkillButton(key)
    if btn then
        return btn.Visible == true
    end
    local s = FindSkillNumberValue(char, key)
    return s ~= nil
end

function IsSkillOnCooldown(char, key)
    local btn = FindSkillButton(key)
    if btn then
        local cd = btn:FindFirstChild("CD")
        if cd and cd.Visible then
            local txt = cd.Text or ""
            local num = tonumber(string.match(txt, "%d+%.?%d*"))
            if num and num > 0 then
                return true
            end
        end
    end
    local s = FindSkillNumberValue(char, key)
    if s and (s.Value > 0 or (s:GetAttribute("UsingSkill") or 0) > 0) then
        return true
    end
    return false
end

local function IsSkillConfirmedUsed(char, key)
    return IsSkillOnCooldown(char, key)
end

function IsSkillKeyReady(char, key)
    if not IsSkillSlotAvailable(char, key) then
        return false
    end

    if IsSkillOnCooldown(char, key) then
        return false
    end

    local btn = FindSkillButton(key)
    if btn then
        if not btn.Visible then
            return false
        end
        local lock = btn:FindFirstChild("Lock")
        if lock and lock.Visible then
            if IsAntiConfuseActive() then
                lock.Visible = false
            else
                return false
            end
        end
    end

    local s, skillsFolder = FindSkillNumberValue(char, key)
    if s then
        return true
    end

    if skillsFolder and #skillsFolder:GetChildren() > 0 then
        return false
    end

    return btn ~= nil and btn.Visible == true
end

local rhythmLanes = {"A", "S", "D"}
local rhythmKeyMap = {
    A = Enum.KeyCode.A,
    S = Enum.KeyCode.S,
    D = Enum.KeyCode.D
}
local lastRhythmLaneHit = { A = 0, S = 0, D = 0 }
local lastRhythmScan = 0
local lastPhase2HitTick = 0
local phase2BarHistory = {}
local CENTER_BAR_POS = UDim2.new(0.5, 0, 0.5, 0)
local isLockingBar = false
local barPosConn = nil
local boundBar = nil

-- Fish filter: Auto Cast keeps casting until a Boss / Secret Boss fish bites
UzexFilter = { Skip = false, Cache = {}, LastNotify = 0, AntiChecked = {} }
UzexFilter.SecretFarmAllowed = function() return false end

local function LockFishingBar()
    if isLockingBar then return end
    if UzexFilter.Skip or UzexFilter.SkippingFish then return end
    if UzexFilter.SecretFarmAllowed() then return end
    if not FishingGui or not FishingGui.Visible or not FishingBar then return end
    if not (Config.AutoReel or Config.AutoMiniGame or Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland) then return end
    isLockingBar = true
    local char = cachedChar
    if char and (tonumber(char:GetAttribute("GuildPower")) or 0) < 99999999 then
        pcall(function()
            char:SetAttribute("GuildPower", 99999999)
            local stats = cachedStatsFolder or char:FindFirstChild("Stats")
            local rp = stats and stats:FindFirstChild("RodPower")
            if rp then
                local orig = rp.Value
                rp.Value = orig + 1
                rp.Value = orig
            end
        end)
    end
    pcall(function()
        FishingBar:TweenPosition(CENTER_BAR_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0, true)
        FishingBar.Position = CENTER_BAR_POS
    end)
    isLockingBar = false
end

local function BindFishingBarLock()
    if FishingBar and FishingBar ~= boundBar then
        if barPosConn then
            pcall(function() barPosConn:Disconnect() end)
            barPosConn = nil
        end
        boundBar = FishingBar
        barPosConn = FishingBar:GetPropertyChangedSignal("Position"):Connect(function()
            if not isLockingBar and FishingBar.Position.X.Scale ~= 0.5 then
                LockFishingBar()
            end
        end)
    end
end

BindFishingBarLock()

function TriggerGuiButton(btn)
    if not btn then return false end
    if not btn:IsA("GuiButton") then
        btn = btn:FindFirstChildWhichIsA("GuiButton", true) or (btn.Parent and btn.Parent:IsA("GuiButton") and btn.Parent) or nil
        if not btn then return false end
    end
    local triggered = false
    local sigNames = {"MouseButton1Click", "Activated", "MouseButton1Down", "MouseButton1Up"}
    if getconnections then
        for _, sName in ipairs(sigNames) do
            local okSig, sig = pcall(function() return btn[sName] end)
            if okSig and sig then
                pcall(function()
                    for _, conn in pairs(getconnections(sig)) do
                        if conn.Function then
                            task.spawn(conn.Function)
                            triggered = true
                        elseif conn.Fire then
                            conn:Fire()
                            triggered = true
                        end
                    end
                end)
            end
        end
    end
    if firesignal then
        for _, sName in ipairs(sigNames) do
            pcall(function()
                firesignal(btn[sName])
                triggered = true
            end)
        end
    end
    return triggered
end

local getupval = (debug and debug.getupvalue) or getupvalue

local function StepPhase2MiniGame()
    if not BossFightBar or not BossFightBar.Visible then
        if #phase2BarHistory > 0 then
            table.clear(phase2BarHistory)
        end
        return
    end

    local bar = BossFightBar:FindFirstChild("Bar")
    local hitbox = BossFightBar:FindFirstChild("Hitbox")
    if not bar or not hitbox then return end

    local barW = bar.Size.X.Scale
    local barCenter = bar.Position.X.Scale + barW * (0.5 - bar.AnchorPoint.X)
    local hbW = hitbox.Size.X.Scale
    local hbLeft = hitbox.Position.X.Scale - hbW * hitbox.AnchorPoint.X

    local now = os.clock()
    table.insert(phase2BarHistory, { t = now, x = barCenter })
    while #phase2BarHistory > 1 and (now - phase2BarHistory[1].t) > 0.15 do
        table.remove(phase2BarHistory, 1)
    end

    local hitDelay = (tonumber(Config.BossHitDelay) or 15) / 1000
    if hitDelay < 0.005 then
        hitDelay = 0.005
    end

    local handledViaUpval = false
    local onClickFn = nil

    if getconnections and getupval and MobileFishingBtn then
        pcall(function()
            for _, conn in pairs(getconnections(MobileFishingBtn.MouseButton1Down)) do
                local fn = conn.Function and getupval(conn.Function, 1)
                if type(fn) == "function" then
                    onClickFn = fn
                    local u12 = getupval(fn, 1)
                    local u14 = getupval(fn, 2)
                    local u27 = getupval(fn, 3)
                    local u26 = getupval(fn, 4)
                    local u1 = getupval(fn, 5)
                    local u25 = getupval(fn, 6)
                    local u23 = getupval(fn, 7)
                    local u2 = getupval(fn, 8)
                    local u15 = getupval(fn, 9)
                    if u12 == true and type(u14) == "number" and type(u27) == "number" and type(u26) == "number" and type(u1) == "number" and type(u25) == "number" and type(u23) == "number" and type(u2) == "number" and type(u15) == "number" then
                        if math.abs(u2 - hbW) < 0.005 and math.abs(u15 - hbLeft) < 0.005 then
                            handledViaUpval = true
                            if (now - u14 >= hitDelay or u14 == 0) and now - lastPhase2HitTick >= hitDelay then
                                local v91 = (now - 0.025 - u27) % u26 * u1
                                if u25 < v91 then
                                    v91 = u25 * 2 - v91
                                end
                                local v92 = u23 + v91
                                local v93 = u2 * 0.3
                                if v92 >= (u15 - v93 * 0.8) and v92 <= (u15 + u2 + v93 * 0.8) then
                                    lastPhase2HitTick = now
                                    fn(false)
                                end
                            end
                        end
                        break
                    end
                end
            end
        end)
    end

    if handledViaUpval then return end
    if now - lastPhase2HitTick < hitDelay then return end

    local evalX = barCenter
    local pad = hbW * 0.2

    local badBox = BossFightBar:FindFirstChild("HitboxBad")
    if badBox and badBox.Visible then
        local badW = badBox.Size.X.Scale
        local badLeft = badBox.Position.X.Scale - badW * badBox.AnchorPoint.X
        if evalX >= (badLeft - 0.01) and evalX <= (badLeft + badW + 0.01) then
            return
        end
    end

    if evalX >= (hbLeft - pad) and evalX <= (hbLeft + hbW + pad) then
        lastPhase2HitTick = now
        local clicked = false
        if onClickFn then
            pcall(function()
                onClickFn(false)
                clicked = true
            end)
        end
        if not clicked and MobileFishingBtn then
            if getconnections then
                pcall(function()
                    for _, conn in pairs(getconnections(MobileFishingBtn.MouseButton1Down)) do
                        if conn.Function then
                            task.spawn(conn.Function)
                            clicked = true
                        elseif conn.Fire then
                            conn:Fire()
                            clicked = true
                        end
                    end
                end)
            end
            if not clicked and firesignal then
                pcall(function()
                    firesignal(MobileFishingBtn.MouseButton1Down)
                    clicked = true
                end)
            end
        end
        if not clicked then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.delay(0.005, function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end)
            end)
        end
    end
end

local function IsTrapNote(gui)
    if not gui or not gui:IsA("GuiObject") then
        return false
    end
    if gui:GetAttribute("Trap") == true or gui:GetAttribute("trap") == true or gui:GetAttribute("IsTrap") == true then
        return true
    end
    if string.find(string.lower(gui.Name), "trap", 1, true) then
        return true
    end
    local function isRed(c)
        return c and c.R > 0.65 and c.G < 0.45 and c.B < 0.45 and c.R > c.G * 1.8 and c.R > c.B * 1.8
    end
    if isRed(gui.BackgroundColor3) then
        return true
    end
    if (gui:IsA("ImageLabel") or gui:IsA("ImageButton")) and isRed(gui.ImageColor3) then
        return true
    end
    for _, desc in ipairs(gui:GetDescendants()) do
        if desc:IsA("GuiObject") then
            if isRed(desc.BackgroundColor3) then
                return true
            end
            if (desc:IsA("ImageLabel") or desc:IsA("ImageButton")) and isRed(desc.ImageColor3) then
                return true
            end
        end
    end
    return false
end

local function StepRhythmMiniGame()
    if not RhythmGui or not RhythmGui.Visible then return end
    local now = os.clock()
    if now - lastRhythmScan < 0.025 then return end
    lastRhythmScan = now

    for _, lane in ipairs(rhythmLanes) do
        if now - (lastRhythmLaneHit[lane] or 0) >= 0.05 then
            local laneFrame = RhythmGui:FindFirstChild("Progression" .. lane)
            if laneFrame then
                local barFrame = laneFrame:FindFirstChild("BarFrame")
                local targetY = barFrame and barFrame.Position.Y.Scale or 0.85
                local targetNote = nil
                local bestDist = 999
                for _, child in ipairs(laneFrame:GetChildren()) do
                    if child.Name == "Note_FX" and child:IsA("GuiObject") and child.Visible then
                        local dist = math.abs(child.Position.Y.Scale - targetY)
                        if dist < bestDist then
                            bestDist = dist
                            targetNote = child
                        end
                    end
                end
                if targetNote and not IsTrapNote(targetNote) and bestDist <= 0.18 then
                    lastRhythmLaneHit[lane] = now
                    local btn = laneFrame:FindFirstChild("Button")
                    if btn then
                        TriggerGuiButton(btn)
                    end
                    if targetNote.Parent ~= nil then
                        local kc = rhythmKeyMap[lane]
                        if kc then
                            pcall(function()
                                VirtualInputManager:SendKeyEvent(true, kc, false, game)
                                task.delay(0.02, function()
                                    VirtualInputManager:SendKeyEvent(false, kc, false, game)
                                end)
                            end)
                        end
                    end
                    if targetNote.Parent ~= nil and bestDist <= 0.1 and RhythmHitEvent then
                        pcall(function()
                            targetNote:Destroy()
                            RhythmHitEvent:FireServer("hit")
                        end)
                    end
                end
            end
        end
    end
end

local function StepFishingFrame(includeRhythm)
    if not FishingGui or not FishingGui.Visible then return end
    BindFishingBarLock()
    LockFishingBar()
    if Config.AutoMiniGame then
        StepPhase2MiniGame()
        if includeRhythm and not UzexFilter.BTActive then
            StepRhythmMiniGame()
        end
    end
end

RunService.RenderStepped:Connect(function()
    StepFishingFrame(false)
end)

RunService.Stepped:Connect(function()
    StepFishingFrame(false)
end)

RunService.Heartbeat:Connect(function()
    StepFishingFrame(true)
end)

end
local GetModelPart, FindBossTarget, GetButtonLabelText, FindBossMenuFrame, CheckBossStatusOnToggle, clearPlayerESP
do
function GetModelPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj:FindFirstChild("HumanoidRootPart")
            or obj:FindFirstChild("Head")
            or obj.PrimaryPart
            or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function IsSecretBossEntity(obj)
    if not obj then return false end
    if obj:GetAttribute("Secret") == true or obj:GetAttribute("Rarity") == "Secret" then
        return true
    end
    local rawName = tostring(obj:GetAttribute("Name") or obj:GetAttribute("FishName") or obj.Name)
    local lowerName = string.lower(rawName)
    if string.find(lowerName, "secret") or string.find(lowerName, "long diaohai") or string.find(lowerName, "longdiaohai") or string.find(lowerName, "diaohai") or string.find(lowerName, "wuzhi") then
        return true
    end
    local inv = Info:FindFirstChild("Inventory")
    local mod = inv and inv:FindFirstChild(rawName)
    local data = GetModuleData(mod)
    if data and (data.Secret == true or data.Rarity == "Secret" or (data.Boss == true and (tonumber(data.Chance) or 100) <= 1)) then
        return true
    end
    return false
end

local function UzexCleanName(name)
    name = tostring(name or "")
    name = string.gsub(name, "<[^>]+>", "")
    name = string.gsub(name, "%s*[xX]%s*%d+$", "")
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")
    return name
end

local function UzexFishData(name)
    local key = string.lower(name)
    if key == "" then return nil end
    local cached = UzexFilter.Cache[key]
    if cached ~= nil then return cached or nil end
    local inv = Info:FindFirstChild("Inventory")
    local mod = inv and inv:FindFirstChild(name)
    if not mod and inv then
        for _, child in ipairs(inv:GetChildren()) do
            if string.lower(child.Name) == key then
                mod = child
                break
            end
        end
    end
    local data = mod and GetModuleData(mod) or nil
    UzexFilter.Cache[key] = data or false
    return data
end

-- Secret Boss list from the game (Info.FishingAreaRarity["Secret Boss"]), refreshed every 30s
function UzexFilter.SecretSet()
    local now = os.clock()
    if UzexFilter.SecretSetData and now - (UzexFilter.SecretSetAt or 0) < 30 then
        return UzexFilter.SecretSetData
    end
    local set = {}
    pcall(function()
        local mod = Info:FindFirstChild("FishingAreaRarity")
        local data = mod and require(mod)
        local list = type(data) == "table" and data["Secret Boss"]
        if type(list) == "table" then
            for key, value in pairs(list) do
                if type(key) == "string" then set[string.lower(key)] = true end
                if type(value) == "string" then set[string.lower(value)] = true end
            end
        end
    end)
    UzexFilter.SecretSetData = set
    UzexFilter.SecretSetAt = now
    return set
end

-- returns isBoss, isSecret, shownName for the fish currently on the line
function UzexFilter.Classify()
    local isBoss, isSecret, shown, known = false, false, "", false
    pcall(function()
        local names = {}
        local fishId = LocalPlayer:GetAttribute("FishID")
        local fishObj = (fishId and FishesFolder) and FishesFolder:FindFirstChild(tostring(fishId)) or nil
        if fishObj then
            table.insert(names, fishObj.Name)
            for k, v in pairs(fishObj:GetAttributes()) do
                local lk = string.lower(tostring(k))
                if type(v) == "string" then
                    table.insert(names, v)
                    if lk == "rarity" then
                        local lv = string.lower(v)
                        if lv == "secret" then isSecret = true end
                        if lv == "boss" then isBoss = true end
                    end
                elseif v == true then
                    if lk == "boss" or lk == "isboss" then isBoss = true end
                    if lk == "secret" or lk == "issecret" then isSecret = true end
                end
            end
        end
        local pb = FishingGui and FishingGui:FindFirstChild("ProgressionBar")
        if pb then
            for _, d in ipairs(pb:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text ~= "" then
                    table.insert(names, d.Text)
                end
            end
        end
        for _, raw in ipairs(names) do
            local clean = UzexCleanName(raw)
            if clean ~= "" then
                if shown == "" then shown = clean end
                local data = UzexFishData(clean)
                if data then
                    shown = clean
                    known = true
                    if data.Boss == true then isBoss = true end
                    -- secret only when the game says so (no guessing from drop chance)
                    if data.Secret == true or data.SecretBoss == true or data.Rarity == "Secret" then
                        isSecret = true
                    end
                    if data.SpecialBoss == true then isBoss = true end
                    if type(data.Rarity) == "string" and string.lower(data.Rarity) == "boss" then
                        isBoss = true
                    end
                end
                local lower = string.lower(clean)
                if UzexFilter.SecretSet()[lower] then
                    isSecret = true
                    known = true
                end
                if string.find(lower, "secret", 1, true) or string.find(lower, "diaohai", 1, true)
                    or string.find(lower, "wuzhi", 1, true) then
                    isSecret = true
                end
            end
        end
    end)
    return isBoss, isSecret, shown, known
end

-- Drop the rod (cancels a normal fish), equip it again, then cast
function UzexFilter.HoldingRod()
    local c = LocalPlayer.Character
    return c ~= nil and c:GetAttribute("Type") == "Fishing Rod"
end

function UzexFilter.Recycle()
    if UzexFilter.Busy then return end
    UzexFilter.Busy = true
    UzexFilter.NeedRod = true
    task.spawn(function()
        local function toggle()
            pcall(function()
                ToggleHotbar:InvokeServer("1")
            end)
        end
        local function waitFor(state, maxTime)
            local t = 0
            while UzexFilter.HoldingRod() ~= state and t < maxTime do
                task.wait(0.01)
                t = t + 0.01
            end
            return UzexFilter.HoldingRod() == state
        end
        -- 1) drop the rod (cancels the normal fish); the invoke already waits for the server
        if UzexFilter.HoldingRod() then
            toggle()
            waitFor(false, 0.6)
        end
        -- 2) equip it again right away, retry until the rod is really in hand
        for _ = 1, 4 do
            if UzexFilter.HoldingRod() then break end
            toggle()
            if waitFor(true, 0.5) then break end
        end
        -- 3) cast as soon as the old line is gone
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if char and hrp and UzexFilter.HoldingRod() then
            local t = 0
            while char:GetAttribute("Fishing") and t < 0.4 do
                task.wait(0.01)
                t = t + 0.01
            end
            if UzexFilter.HoldingRod() and not char:GetAttribute("Fishing") then
                pcall(function()
                    FishingEvent:FireServer(hrp.CFrame)
                end)
            end
        end
        if UzexFilter.HoldingRod() then
            UzexFilter.NeedRod = false
        end
        UzexFilter.Busy = false
    end)
end

local function IsLongDiaoHaiName(obj)
    local raw = string.lower(tostring(obj:GetAttribute("Name") or obj:GetAttribute("FishName") or obj.Name))
    raw = string.gsub(raw, "%s+", "")
    return string.find(raw, "diaohai", 1, true) ~= nil or string.find(raw, "longdiao", 1, true) ~= nil
end

function FindBossTarget(wantSecret)
    local npcFolder = workspace:FindFirstChild("NPC")
    local bossFolder = npcFolder and npcFolder:FindFirstChild("Boss")

    if not wantSecret then
        if bossFolder then
            for _, boss in ipairs(bossFolder:GetChildren()) do
                local part = GetModelPart(boss)
                if part and not IsSecretBossEntity(boss) and not IsLongDiaoHaiName(boss) then
                    return boss, part
                end
            end
        end
        local wsBoss = workspace:FindFirstChild("Boss") or workspace:FindFirstChild("BossZone")
        if wsBoss then
            local part = GetModelPart(wsBoss)
            if part then
                return wsBoss, part
            end
        end
        return nil, nil
    end

    -- Secret boss (Long DiaoHai) can live in several folders, so check all of them
    local containers = {}
    if bossFolder then table.insert(containers, bossFolder) end
    if npcFolder then
        local god = npcFolder:FindFirstChild("God")
        if god then table.insert(containers, god) end
    end
    for _, n in ipairs({"God", "BossSetUp"}) do
        local f = workspace:FindFirstChild(n)
        if f then table.insert(containers, f) end
    end
    for _, c in ipairs(containers) do
        for _, boss in ipairs(c:GetChildren()) do
            if IsLongDiaoHaiName(boss) or IsSecretBossEntity(boss) then
                local part = GetModelPart(boss)
                if part then
                    return boss, part
                end
            end
        end
    end
    -- last resort: search by name inside the NPC folders
    for _, n in ipairs({"NPC", "God", "BossSetUp"}) do
        local f = workspace:FindFirstChild(n)
        if f then
            for _, d in ipairs(f:GetDescendants()) do
                if d:IsA("Model") and IsLongDiaoHaiName(d) then
                    local part = GetModelPart(d)
                    if part then
                        return d, part
                    end
                end
            end
        end
    end
    return nil, nil
end

local BossFarmPositions = {
    Enzo = CFrame.new(-114.81, 9.28, 1356.67, 0.05, -0.00, -1.00, -0.00, 1.00, -0.00, 1.00, 0.00, 0.05),
    LongDiaoHai = CFrame.new(-2873.62, 32.17, 1337.38, -0.09, 0.00, -1.00, 0.00, 1.00, 0.00, 1.00, -0.00, -0.09)
}

local function GetBossFarmCFrame(wantSecret)
    return wantSecret and BossFarmPositions.LongDiaoHai or BossFarmPositions.Enzo
end

local lastBossActionTick = 0
local lastBossNotifyKey = ""
local lastBossNotifyTick = 0

local function NotifyBoss(title, content, key, cooldown)
end

function GetButtonLabelText(obj)
    if not obj then return "" end
    if obj:IsA("TextButton") or obj:IsA("TextLabel") then
        if obj.Text and obj.Text ~= "" then
            return obj.Text
        end
    end
    local lbl = obj:FindFirstChild("Title") or obj:FindFirstChild("TextLabel") or obj:FindFirstChildWhichIsA("TextLabel", true)
    if lbl and lbl.Text then
        return lbl.Text
    end
    return ""
end

local function TriggerGuiButton(btn)
    if not btn then return false end
    if not btn:IsA("GuiButton") then
        btn = btn:FindFirstChildWhichIsA("GuiButton", true) or (btn.Parent and btn.Parent:IsA("GuiButton") and btn.Parent) or nil
        if not btn then return false end
    end
    local triggered = false
    pcall(function()
        if btn.AbsolutePosition and btn.AbsoluteSize then
            local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
            triggered = true
        end
    end)
    local sigNames = {"MouseButton1Click", "Activated", "MouseButton1Down", "MouseButton1Up"}
    if getconnections then
        for _, sName in ipairs(sigNames) do
            local okSig, sig = pcall(function() return btn[sName] end)
            if okSig and sig then
                pcall(function()
                    for _, conn in pairs(getconnections(sig)) do
                        if conn.Function then
                            task.spawn(conn.Function)
                            triggered = true
                        elseif conn.Fire then
                            conn:Fire()
                            triggered = true
                        end
                    end
                end)
            end
        end
    end
    if firesignal then
        for _, sName in ipairs(sigNames) do
            pcall(function()
                firesignal(btn[sName])
                triggered = true
            end)
        end
    end
    return triggered
end

function FindBossMenuFrame()
    if not MainGui then return nil end
    local menu = MainGui:FindFirstChild("Menu")
    if not menu then return nil end
    for _, name in ipairs({"BossFight", "Boss", "BossMenu", "Raid", "SecretBoss"}) do
        local f = menu:FindFirstChild(name)
        if f and f:IsA("GuiObject") then
            return f
        end
    end
    for _, child in ipairs(menu:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "Info" and child.Name ~= "Black" and child.Name ~= "Dialogue" then
            local title = child:FindFirstChild("Title")
            if title and title:IsA("TextLabel") and string.find(string.lower(title.Text), "boss") then
                return child
            end
            if child:FindFirstChild("Normal", true) and child:FindFirstChild("Hard", true) and child:FindFirstChild("Nightmare", true) then
                return child
            end
        end
    end
    return nil
end

local function GetBossRequirementSummary(bossFrame, bossName)
    local missing = {}
    local rodVal = PlayerData and PlayerData:FindFirstChild("FishingRod")
    local curRodName = rodVal and rodVal.Value or ""
    if curRodName == "" then
        table.insert(missing, "No Fishing Rod equipped")
    end

    local char = LocalPlayer.Character
    local stats = char and char:FindFirstChild("Stats")
    local inv = Info:FindFirstChild("Inventory")
    if inv and bossName then
        local bossMod = inv:FindFirstChild(bossName)
        local bossData = GetModuleData(bossMod)
        local rodMod = curRodName ~= "" and inv:FindFirstChild(curRodName) or nil
        local rodData = GetModuleData(rodMod)
        if bossData and tonumber(bossData.Power) and rodData and tonumber(rodData.Power) then
            local rodBonus = stats and stats:FindFirstChild("RodPower") and tonumber(stats.RodPower.Value) or 0
            local fishBonus = stats and stats:FindFirstChild("FishPower") and tonumber(stats.FishPower.Value) or 0
            local playerPower = tonumber(rodData.Power) + rodBonus
            local bossEffPower = math.max(1, tonumber(bossData.Power) - fishBonus + 4)
            if (playerPower / bossEffPower) <= 0.5 then
                table.insert(missing, string.format("Low Power (%d/%d)", math.floor(playerPower), math.floor(bossEffPower)))
            end
        end
    end

    if bossFrame then
        for _, desc in ipairs(bossFrame:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Visible then
                local txt = desc.Text or ""
                local cur, req = string.match(txt, "^%s*(%d+)%s*/%s*(%d+)%s*$")
                if cur and req then
                    local nCur = tonumber(cur)
                    local nReq = tonumber(req)
                    if nCur and nReq and nCur < nReq then
                        table.insert(missing, cur .. "/" .. req)
                    end
                end
            end
        end
    end

    return missing
end

local bossSummoned = false
local bossSummonTick = 0

local function CloseBossMenuFrame(bossFrame)
    if not bossFrame or not bossFrame.Visible then return end
    local closed = false
    for _, desc in ipairs(bossFrame:GetDescendants()) do
        if desc:IsA("GuiButton") and desc.Visible then
            local bName = string.lower(desc.Name)
            local bTxt = string.lower(GetButtonLabelText(desc))
            local pName = desc.Parent and string.lower(desc.Parent.Name) or ""
            if bName == "close" or bTxt == "x" or pName == "close" then
                if TriggerGuiButton(desc) then
                    closed = true
                    break
                end
            end
        end
    end
    if not closed then
        pcall(function()
            bossFrame.Visible = false
        end)
    end
end

function CheckBossStatusOnToggle(wantSecret)
    bossSummoned = false
    bossSummonTick = 0
    local rodVal = PlayerData and PlayerData:FindFirstChild("FishingRod")
    if not rodVal or rodVal.Value == "" then
        return
    end
    local bossObj = FindBossTarget(wantSecret)
    if not bossObj then
        return
    end
    local hrp = cachedHrp or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
    local targetCF = GetBossFarmCFrame(wantSecret)
    if hrp and targetCF then
        hrp.CFrame = targetCF
    end
    local char = cachedChar or LocalPlayer.Character
    if char and char:GetAttribute("Type") ~= "Fishing Rod" then
        pcall(function()
            ToggleHotbar:InvokeServer("1")
        end)
    end
end

local function FireGuiSignal(btn)
    if not btn then return false end
    if not btn:IsA("GuiButton") then
        btn = btn:FindFirstChildWhichIsA("GuiButton", true) or (btn.Parent and btn.Parent:IsA("GuiButton") and btn.Parent) or nil
        if not btn then return false end
    end
    local triggered = false
    local sigNames = {"MouseButton1Click", "Activated"}
    if firesignal then
        for _, sName in ipairs(sigNames) do
            pcall(function()
                firesignal(btn[sName])
                triggered = true
            end)
        end
    end
    if getconnections then
        for _, sName in ipairs(sigNames) do
            local okSig, sig = pcall(function() return btn[sName] end)
            if okSig and sig then
                pcall(function()
                    for _, conn in pairs(getconnections(sig)) do
                        if conn.Function then
                            task.spawn(conn.Function)
                            triggered = true
                        elseif conn.Fire then
                            conn:Fire()
                            triggered = true
                        end
                    end
                end)
            end
        end
    end
    return triggered
end

local function ClickBossModeAndStart(bossFrame, bossName, mode, wantSecret)
    local targetMode = mode or "Normal"

    local selectContainer = bossFrame:FindFirstChild("Select", true)
    local btnContainer = (selectContainer and selectContainer:FindFirstChild("button")) or selectContainer or bossFrame

    local modeBtn = nil
    if btnContainer then
        modeBtn = btnContainer:FindFirstChild(targetMode)
        if not modeBtn then
            for _, child in ipairs(btnContainer:GetChildren()) do
                if child:IsA("GuiButton") and string.lower(child.Name) == string.lower(targetMode) then
                    modeBtn = child
                    break
                end
            end
        end
    end

    if not modeBtn then
        for _, desc in ipairs(bossFrame:GetDescendants()) do
            if desc:IsA("GuiButton") then
                local dName = string.lower(desc.Name)
                local dText = string.lower(GetButtonLabelText(desc))
                if dName == string.lower(targetMode) or dText == string.lower(targetMode) then
                    modeBtn = desc
                    break
                end
            end
        end
    end

    if modeBtn then
        FireGuiSignal(modeBtn)
        -- Allow the selected difficulty to replicate before starting the fight.
        task.wait(0.6)
    end

    local fightBtn = bossFrame:FindFirstChild("Fight", true)
    if not fightBtn then
        for _, desc in ipairs(bossFrame:GetDescendants()) do
            if desc:IsA("GuiButton") then
                local dName = string.lower(desc.Name)
                local dText = string.lower(GetButtonLabelText(desc))
                if dName == "fight" or dText == "fight" or string.find(dName, "fight") or string.find(dText, "fight") then
                    fightBtn = desc
                    break
                end
            end
        end
    end

    if fightBtn then
        FireGuiSignal(fightBtn)
    end

    local remotes = {}
    local function collectRemotes(folder)
        if not folder then return end
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                table.insert(remotes, child)
            end
        end
    end

    collectRemotes(Events)
    local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    collectRemotes(RemotesFolder)

    local targetNames = {
        ["bossfight"] = true,
        ["startbossfight"] = true,
        ["startboss"] = true,
        ["boss"] = true,
        ["challengeboss"] = true,
        ["fightboss"] = true,
        ["choosedialogueoption"] = true
    }

    for _, ev in ipairs(remotes) do
        local lowerName = string.lower(ev.Name)
        if targetNames[lowerName] or string.find(lowerName, "boss") then
            pcall(function()
                -- The mode button is selected above. Do not send multiple incompatible
                -- argument layouts: later calls can overwrite Nightmare with Normal.
                if ev:IsA("RemoteEvent") then
                    ev:FireServer(targetMode)
                elseif ev:IsA("RemoteFunction") then
                    ev:InvokeServer(targetMode)
                end
            end)
        end
    end

    task.wait(0.25)

    if FishingGui and FishingGui.Visible then
        bossSummoned = true
        bossSummonTick = os.clock()
        if bossFrame then
            CloseBossMenuFrame(bossFrame)
        end
        return true
    end

    return false
end

local lastCaughtBossTick = 0
local lastCaughtFishName = ""

do
    local repEv = Events:FindFirstChild("ReplicateFishCaught")
    if repEv and repEv:IsA("RemoteEvent") then
        repEv.OnClientEvent:Connect(function(charModel, fishName)
            if charModel == LocalPlayer.Character then
                lastCaughtBossTick = os.clock()
                lastCaughtFishName = tostring(fishName or "")
                bossSummoned = false
                bossSummonTick = 0
            end
        end)
    end
end

local trackingBossFight = false

local function MonitorBossMinigame()
    if trackingBossFight then return end
    local fishId = LocalPlayer:GetAttribute("FishID")
    local fishesFolder = workspace:FindFirstChild("Fishes")
    local fishObj = (fishId and fishesFolder) and fishesFolder:FindFirstChild(tostring(fishId)) or nil
    if not fishObj then return end

    trackingBossFight = true
    task.spawn(function()
        local progBar = FishingGui and FishingGui:FindFirstChild("ProgressionBar")
        local fNameLbl = progBar and progBar:FindFirstChild("FishName")
        local fName = (fNameLbl and fNameLbl.Text ~= "" and fNameLbl.Text) or "Boss"
        local hpObj = fishObj:FindFirstChild(LocalPlayer.UserId .. "_PlayerHealth")
        local maxFishHp = tonumber(fishObj:GetAttribute("MaxHealth")) or 100

        local lastScale = 0.5
        local lastHp = hpObj and hpObj.Value or 100
        local lastFishVal = fishObj:IsA("ValueBase") and fishObj.Value or 0
        local hadFinalPhase = false
        local lastFinalHp = 1

        while fishObj.Parent and (FishingGui and FishingGui.Visible) do
            bossSummonTick = os.clock()
            if hpObj then
                lastHp = hpObj.Value
            end
            if fishObj:IsA("ValueBase") then
                lastFishVal = fishObj.Value
            end
            if fishObj:GetAttribute("FinalPhase") == true then
                hadFinalPhase = true
            end
            if fishObj:GetAttribute("FinalPhaseHP") ~= nil then
                lastFinalHp = tonumber(fishObj:GetAttribute("FinalPhaseHP")) or lastFinalHp
            end
            if FishingBar then
                lastScale = FishingBar.Position.X.Scale
            end
            task.wait(0.1)
        end

        task.wait(0.35)
        bossSummoned = false
        bossSummonTick = 0
        trackingBossFight = false
    end)
end

local function StepAutoBoss(char, isMinigame)
    if isMinigame then
        bossSummoned = true
        bossSummonTick = os.clock()
        MonitorBossMinigame()
        return
    end
    local now = os.clock()
    if now - lastBossActionTick < 0.8 then return end
    lastBossActionTick = now

    if bossSummoned and (now - bossSummonTick > 45) then
        bossSummoned = false
    end

    local wantSecret = Config.AutoSecretBoss
    local rodVal = PlayerData and PlayerData:FindFirstChild("FishingRod")
    if not rodVal or rodVal.Value == "" then
        return
    end

    local bossObj, bossPart = FindBossTarget(wantSecret)
    local targetCF = GetBossFarmCFrame(wantSecret)
    if not bossObj and not targetCF then
        return
    end

    local hrp = cachedHrp or (char and char:FindFirstChild("HumanoidRootPart"))
    local bossName = bossObj and (bossObj:GetAttribute("Name") or bossObj.Name) or (wantSecret and "Long DiaoHai" or "Enzo")

    if hrp then
        if targetCF then
            if (hrp.Position - targetCF.Position).Magnitude > 5 then
                hrp.CFrame = targetCF
            end
        elseif bossPart then
            local dist = (hrp.Position - bossPart.Position).Magnitude
            if dist > 12 then
                hrp.CFrame = bossPart.CFrame * CFrame.new(0, 3, -5)
            end
        end
    end

    if char and char:GetAttribute("Type") ~= "Fishing Rod" then
        pcall(function()
            ToggleHotbar:InvokeServer("1")
        end)
    end

    local bossFrame = FindBossMenuFrame()

    if not bossSummoned then
        if bossPart and hrp then
            local prompt = bossObj and bossObj:FindFirstChildWhichIsA("ProximityPrompt", true)
            if not prompt and bossPart then
                prompt = bossPart:FindFirstChildWhichIsA("ProximityPrompt", true)
            end
            if prompt and fireproximityprompt then
                pcall(function()
                    fireproximityprompt(prompt)
                end)
            end
        end

        if bossFrame and bossFrame.Visible then
            ClickBossModeAndStart(bossFrame, bossName, Config.BossMode, wantSecret)
        end

        if MainGui and not bossSummoned then
            local menu = MainGui:FindFirstChild("Menu")
            local dialogue = menu and menu:FindFirstChild("Dialogue")
            if dialogue and dialogue.Visible then
                local btnFrame = dialogue:FindFirstChild("ButtonFrame")
                if btnFrame then
                    local chosenBtn = nil
                    local modeLower = string.lower(Config.BossMode or "Normal")
                    for _, btn in ipairs(btnFrame:GetChildren()) do
                        if btn:IsA("TextButton") and btn.Name ~= "Template" and btn.Visible then
                            local title = btn:FindFirstChild("Title")
                            local txt = title and string.lower(title.Text) or ""
                            if string.find(txt, modeLower) then
                                chosenBtn = btn
                                break
                            elseif not chosenBtn and not string.find(txt, "close") and not string.find(txt, "cancel") and not string.find(txt, "nevermind") and not string.find(txt, "leave") then
                                chosenBtn = btn
                            end
                        end
                    end
                    if chosenBtn then
                        TriggerGuiButton(chosenBtn)
                    end
                end
            end
        end
    else
        if bossFrame and bossFrame.Visible then
            CloseBossMenuFrame(bossFrame)
        end
        if char and char:GetAttribute("Type") ~= "Fishing Rod" then
            pcall(function()
                ToggleHotbar:InvokeServer("1")
            end)
        elseif char and not char:GetAttribute("Fishing") then
            -- boss summoned and rod in hand: cast so the boss fight starts
            local castHrp = cachedHrp or char:FindFirstChild("HumanoidRootPart")
            if castHrp then
                pcall(function()
                    FishingEvent:FireServer(castHrp.CFrame)
                end)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Auto Farm Secret Boss (ported from NNVN)
-- Casts the rod, drops every fish that is not a Secret Boss, and auto-reels the
-- Secret Boss once it is hooked. Mode: "Always Active" / "Only When Weather".
-------------------------------------------------------------------------------
do
local SecretFarmAllowed
local SecretFarm = {
    CurrentTarget = nil,
    CurrentToken = nil,
    CurrentRunId = 0,
    HasHooked = false,
    PendingCancel = false,
    LastCast = 0,
    LastCancel = 0,
    LastFastCancel = 0,
    LastProgress = 0,
    LastNotify = "",
}

local SecretFarmKeywords = { "secret", "hidden", "mythic", "event", "rare" }
local SecretFarmWeather = {
    foggy = true,
    ["blazing sun"] = true,
    snowy = true,
    windy = true,
    rainy = true,
    thunderstorm = true,
}
local SecretFarmNames = {}

local function SecretFarmHasKeyword(text)
    text = string.lower(tostring(text or ""))
    for _, kw in ipairs(SecretFarmKeywords) do
        if string.find(text, kw, 1, true) then
            return true
        end
    end
    return false
end

local function SecretFarmLoadNames()
    local set = {}
    pcall(function()
        local rarity = Info:FindFirstChild("FishingAreaRarity")
        if rarity then
            local data = require(rarity)
            if type(data) == "table" and type(data["Secret Boss"]) == "table" then
                for key in pairs(data["Secret Boss"]) do
                    set[string.lower(tostring(key))] = true
                end
            end
        end
    end)
    pcall(function()
        local inventory = Info:FindFirstChild("Inventory")
        if inventory then
            for _, entry in ipairs(inventory:GetChildren()) do
                if entry:IsA("ModuleScript") then
                    local ok, data = pcall(require, entry)
                    if ok and type(data) == "table" and data.SecretBoss == true then
                        set[string.lower(tostring(data.FishName or entry.Name))] = true
                    end
                end
            end
        end
    end)
    SecretFarmNames = set
end

task.spawn(function()
    while true do
        SecretFarmLoadNames()
        task.wait(30)
    end
end)

local function SecretFarmGetWeather()
    local weather = "Clear"
    pcall(function()
        local gui = MainGui and MainGui.Parent and MainGui
            or LocalPlayer.PlayerGui:FindFirstChild("MainGui")
        local i1 = gui and gui:FindFirstChild("Info")
        local i2 = i1 and i1:FindFirstChild("Info")
        local w = i2 and i2:FindFirstChild("Weather")
        local v = w and w:FindFirstChild("Value")
        if v then
            local raw = v:IsA("TextLabel") and v.Text or v.Value
            weather = tostring(raw):gsub("Weather:%s*", "")
        end
    end)
    return weather
end

SecretFarmAllowed = function()
    if not Config.AutoFarmSecretBoss then
        return false
    end
    -- the summon based boss modes drive the rod themselves
    if Config.AutoBoss or Config.AutoSecretBoss then
        return false
    end
    if Config.AutoSecretBossMode ~= "Only When Weather" then
        return true
    end
    local name = string.lower(SecretFarmGetWeather())
    name = name:gsub("^weather:%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return SecretFarmWeather[name] == true
end

UzexFilter.SecretFarmAllowed = SecretFarmAllowed

local function SecretFarmCurrentTarget()
    local current = SecretFarm.CurrentTarget
    local info = { Name = nil, SecretBoss = false }
    if type(current) == "table" then
        info.Name = current.FishName or current.Name or current.fishName
        info.SecretBoss = current.SecretBoss == true
    elseif typeof(current) == "Instance" then
        info.Name = current:GetAttribute("FishName") or current.Name
        info.SecretBoss = current:GetAttribute("SecretBoss") == true
    elseif type(current) == "string" then
        info.Name = current
    end
    local fishId = LocalPlayer:GetAttribute("FishID")
    local fishes = workspace:FindFirstChild("Fishes")
    local entry = fishId and fishes and fishes:FindFirstChild(tostring(fishId))
    if entry then
        info.Name = info.Name or entry:GetAttribute("FishName") or entry.Name
        info.SecretBoss = info.SecretBoss or entry:GetAttribute("SecretBoss") == true
    end
    local fishing = MainGui and MainGui:FindFirstChild("Fishing")
    local bar = fishing and fishing:FindFirstChild("ProgressionBar")
    local label = bar and bar:FindFirstChild("FishName")
    if (not info.Name or info.Name == "" or info.Name == "???") and label and label.Text ~= "" then
        info.Name = label.Text
    end
    return info
end

local function SecretFarmIsSecret(info)
    info = info or SecretFarmCurrentTarget()
    local lower = string.lower(tostring(info.Name or ""))
    return info.SecretBoss == true or SecretFarmNames[lower] == true or SecretFarmHasKeyword(lower)
end

local function SecretFarmReset()
    SecretFarm.CurrentTarget = nil
    SecretFarm.CurrentToken = nil
    SecretFarm.HasHooked = false
    SecretFarm.PendingCancel = false
end

local function SecretFarmCast()
    if not SecretFarmAllowed() or os.clock() - SecretFarm.LastCast < 0.35 then
        return false
    end
    local char = LocalPlayer.Character
    if not char then return false end
    if char:GetAttribute("Fishing") and not char:GetAttribute("Retractable") then
        return false
    end
    SecretFarm.LastCast = os.clock()
    SecretFarmReset()
    pcall(function()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            FishingEvent:FireServer(hrp.CFrame)
        else
            FishingEvent:FireServer()
        end
    end)
    return true
end

local function SecretFarmDropFish()
    if not SecretFarmAllowed() then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    if not char:GetAttribute("Fishing") then
        SecretFarmReset()
        return true
    end
    SecretFarm.PendingCancel = true
    pcall(function()
        local fishing = MainGui and MainGui:FindFirstChild("Fishing")
        local frame = fishing and fishing:FindFirstChild("BarFrame")
        local bar = frame and frame:FindFirstChild("Bar")
        if bar then
            bar.Position = UDim2.new(-0.15, 0, bar.Position.Y.Scale, bar.Position.Y.Offset)
        end
    end)
    if SecretFarm.CurrentToken and os.clock() - SecretFarm.LastFastCancel > 0.5 then
        SecretFarm.LastFastCancel = os.clock()
        pcall(function()
            Events.FishingMinigame:FireServer(false, SecretFarm.CurrentToken)
        end)
    end
    if not char:GetAttribute("Retractable") then return false end
    if os.clock() - SecretFarm.LastCancel < 0.35 then return false end
    SecretFarm.LastCancel = os.clock()
    pcall(function()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            FishingEvent:FireServer(hrp.CFrame)
        else
            FishingEvent:FireServer()
        end
    end)
    return false
end

local function SecretFarmReel(info)
    if not SecretFarmAllowed() or not SecretFarmIsSecret(info) then return end
    local key = "Secret Boss" .. tostring(info.Name)
    if SecretFarm.LastNotify ~= key then
        SecretFarm.LastNotify = key
        pcall(function()
            Library:Notify({
                Title = "Secret Boss",
                Content = "Đang farm Secret Boss: " .. tostring(info.Name or "Unknown"),
                Duration = 3,
            })
        end)
    end
    if os.clock() - SecretFarm.LastProgress > 0.04 then
        SecretFarm.LastProgress = os.clock()
        pcall(function()
            UpdateFishProgression:FireServer()
        end)
    end
end

task.spawn(function()
    while true do
        if not SecretFarmAllowed() then
            task.wait(1.5)
        else
            task.wait(0.2)
            pcall(function()
                local char = LocalPlayer.Character
                local fishing = MainGui and MainGui:FindFirstChild("Fishing")
                if char and char:GetAttribute("Fishing") then
                    if SecretFarm.PendingCancel then
                        SecretFarmDropFish()
                    elseif SecretFarm.HasHooked and fishing and fishing.Visible then
                        local info = SecretFarmCurrentTarget()
                        if SecretFarmIsSecret(info) then
                            SecretFarm.PendingCancel = false
                            SecretFarmReel(info)
                        elseif info.Name and info.Name ~= "???" then
                            SecretFarm.PendingCancel = true
                            SecretFarmDropFish()
                        end
                    end
                else
                    SecretFarmReset()
                    -- the rod must be in hand before casting: equip it, wait until it is
                    -- really held (retry), and only then cast
                    if not UzexFilter.HoldingRod() and not UzexFilter.Busy then
                        local tries = 0
                        while not UzexFilter.HoldingRod() and tries < 4 and SecretFarmAllowed() do
                            tries = tries + 1
                            pcall(function()
                                ToggleHotbar:InvokeServer("1")
                            end)
                            local waited = 0
                            while not UzexFilter.HoldingRod() and waited < 0.6 do
                                task.wait(0.05)
                                waited = waited + 0.05
                            end
                        end
                    end
                    if UzexFilter.HoldingRod() then
                        task.wait(0.1)
                        SecretFarmCast()
                    end
                end
            end)
        end
    end
end)

pcall(function()
    local minigame = Events:FindFirstChild("FishingMinigame")
    if not minigame then return end
    minigame.OnClientEvent:Connect(function(target, second, token)
        if not target or not second then return end
        SecretFarm.CurrentTarget = target
        SecretFarm.CurrentToken = token
        SecretFarm.HasHooked = true
        SecretFarm.PendingCancel = false
        SecretFarm.CurrentRunId = SecretFarm.CurrentRunId + 1
        local runId = SecretFarm.CurrentRunId
        if not SecretFarmAllowed() then return end
        local info = SecretFarmCurrentTarget()
        if not SecretFarmIsSecret(info) then
            SecretFarm.PendingCancel = true
            task.delay(0.15, SecretFarmDropFish)
            return
        end
        task.spawn(function()
            local active = true
            local conn
            local fishing = MainGui and MainGui:FindFirstChild("Fishing")
            if fishing then
                conn = fishing:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not fishing.Visible then
                        active = false
                        if conn then conn:Disconnect() end
                    end
                end)
            end
            while active do
                if not SecretFarmAllowed() or runId ~= SecretFarm.CurrentRunId then
                    break
                end
                local now = SecretFarmCurrentTarget()
                if not SecretFarmIsSecret(now) then
                    SecretFarm.PendingCancel = true
                    SecretFarmDropFish()
                    break
                end
                SecretFarmReel(now)
                task.wait(0.05)
            end
            if conn then conn:Disconnect() end
            if SecretFarmAllowed() and runId == SecretFarm.CurrentRunId then
                SecretFarmReset()
            end
        end)
    end)
end)
end

-------------------------------------------------------------------------------
-- Favourite Fish / Auto Skip Fish / Black Tortoise Bloodline minigame
-- (ported from NNVN)
-------------------------------------------------------------------------------
do
    -- fish name list used by the Favourite / Skip dropdowns
    function UzexFilter.FishNames()
        local list, seen = {}, {}
        pcall(function()
            local inventory = Info:FindFirstChild("Inventory")
            if inventory then
                for _, entry in ipairs(inventory:GetChildren()) do
                    if entry:IsA("ModuleScript") and not seen[entry.Name] then
                        seen[entry.Name] = true
                        table.insert(list, entry.Name)
                    end
                end
            end
        end)
        if #list == 0 then
            pcall(function()
                local index = PlayerData:FindFirstChild("Index")
                if index then
                    for _, entry in ipairs(index:GetChildren()) do
                        if not seen[entry.Name] then
                            seen[entry.Name] = true
                            table.insert(list, entry.Name)
                        end
                    end
                end
            end)
        end
        if #list == 0 then
            list = {
                "Rainbow Dragonfish", "Frost Queenfish", "Nameless Octoparasite", "Colossal Tigerfish",
                "Heavenpiercer Turtle", "Golden Guardian Fish", "Crimson Electric Eel", "Frost Kingfish",
                "Ascended Perch", "Primordial Kunfish Overlord", "Warbringer Shark", "Flying Fish Emperor",
                "Flying Fish Empress", "Sanguine Fish", "Draconic Koi", "Reborn Puffer Beast",
            }
        end
        table.sort(list)
        return list
    end

    ---------------------------------------------------------------------------
    -- Favourite Fish: favourites every inventory item of the selected fish
    ---------------------------------------------------------------------------
    local function FavoriteSelectedFish()
        local selected = Config.FavoriteFish
        if type(selected) ~= "string" or selected == "" or selected == "No Selection" then
            return 0
        end
        local inventory = PlayerData:FindFirstChild("Inventory")
        local favoriteItem = Events:FindFirstChild("FavoriteItem")
        if not inventory or not favoriteItem then
            return 0
        end
        local prefix = selected .. " | "
        local count = 0
        for _, entry in ipairs(inventory:GetChildren()) do
            if not Config.AutoFavoriteFish then break end
            if entry.Name:sub(1, #prefix) == prefix and not entry.Name:match(" | Favorite$") then
                favoriteItem:FireServer(entry.Name)
                count = count + 1
                task.wait(0.12)
            end
        end
        return count
    end

    task.spawn(function()
        while true do
            if Config.AutoFavoriteFish then
                pcall(FavoriteSelectedFish)
            end
            task.wait(1)
        end
    end)

    ---------------------------------------------------------------------------
    -- Auto Skip Fish: gives up a hooked fish that is in the skip list
    ---------------------------------------------------------------------------
    local skipRequestId = 0
    local lastHookedName = ""

    local function SkipSet()
        local set = {}
        if type(Config.SkipFishList) == "table" then
            for _, name in ipairs(Config.SkipFishList) do
                set[string.lower(UzexCleanName(name))] = true
            end
        end
        return set
    end

    -- Every place the game exposes the name of the fish on the line.
    local function HookedNames(arg)
        local out = {}
        local function add(v)
            if v ~= nil and tostring(v) ~= "" and tostring(v) ~= "???" then
                table.insert(out, tostring(v))
            end
        end
        if type(arg) == "table" then
            add(arg.FishName); add(arg.Name); add(arg.Fish); add(arg.fishName)
        elseif typeof(arg) == "Instance" then
            add(arg:GetAttribute("FishName")); add(arg.Name)
        elseif type(arg) == "string" then
            add(arg)
        end
        pcall(function()
            local fishId = LocalPlayer:GetAttribute("FishID")
            local fishes = workspace:FindFirstChild("Fishes")
            local entry = fishId and fishes and fishes:FindFirstChild(tostring(fishId))
            if entry then
                add(entry:GetAttribute("FishName")); add(entry.Name)
            end
        end)
        pcall(function()
            local pb = FishingGui and FishingGui:FindFirstChild("ProgressionBar")
            local label = pb and pb:FindFirstChild("FishName")
            if label and label:IsA("TextLabel") then
                add(label.Text)
            end
        end)
        return out
    end

    local function MatchesSkip(names, set)
        for _, raw in ipairs(names) do
            local clean = string.lower(UzexCleanName(raw))
            if set[clean] then return clean end
            local stripped = string.gsub(clean, "%s*[%(%[|].-$", "")
            stripped = string.gsub(stripped, "%s+$", "")
            if stripped ~= "" and set[stripped] then return stripped end
        end
        return nil
    end

    pcall(function()
        local minigame = Events:FindFirstChild("FishingMinigame")
        if not minigame then return end
        minigame.OnClientEvent:Connect(function(data, _, token)
            local rawName = type(data) == "table" and (data.FishName or data.Name or data.Fish) or nil
            lastHookedName = tostring(rawName or "")
            if not Config.AutoSkipFish or token == nil then return end
            skipRequestId = skipRequestId + 1
            local myId = skipRequestId
            task.spawn(function()
                local set = SkipSet()
                if next(set) == nil then return end
                -- the fish name can show up a moment after the event, so look for ~0.6s (checked fast)
                local matched
                for _ = 1, 20 do
                    if not Config.AutoSkipFish or myId ~= skipRequestId then return end
                    matched = MatchesSkip(HookedNames(data), set)
                    if matched then break end
                    task.wait(0.03)
                end
                if not matched then return end
                pcall(function()
                    Library:Notify({ Title = "Bỏ qua cá", Content = "Đang bỏ qua: " .. matched, Duration = 2 })
                end)
                UzexFilter.SkippingFish = true
                local lastRetract = 0
                for _ = 1, 60 do
                    if not Config.AutoSkipFish or myId ~= skipRequestId then break end
                    pcall(function()
                        local fishing = MainGui and MainGui:FindFirstChild("Fishing")
                        local frame = fishing and fishing:FindFirstChild("BarFrame")
                        local bar = frame and frame:FindFirstChild("Bar")
                        if bar then
                            bar.Position = UDim2.new(-0.15, 0, bar.Position.Y.Scale, bar.Position.Y.Offset)
                        end
                    end)
                    pcall(function()
                        minigame:FireServer(false, token)
                    end)
                    local char = LocalPlayer.Character
                    if char and char:GetAttribute("Retractable") and os.clock() - lastRetract > 0.12 then
                        lastRetract = os.clock()
                        pcall(function()
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                FishingEvent:FireServer(hrp.CFrame)
                            else
                                FishingEvent:FireServer()
                            end
                        end)
                    end
                    task.wait(0.08)
                    if not (FishingGui and FishingGui.Visible) then break end
                end
                UzexFilter.SkippingFish = false
            end)
        end)
    end)

    ---------------------------------------------------------------------------
    -- Black Tortoise Bloodline rhythm (Hard mode) - runs inside Auto Mini Game.
    -- Hits the good notes only and never presses the red "Bad" notes.
    ---------------------------------------------------------------------------
    local NOTE_SPEED = 1.15 / 1.4
    local HIT_WINDOW = 0.22
    local lanes = { "A", "S", "D" }
    local keyMap = { A = Enum.KeyCode.A, S = Enum.KeyCode.S, D = Enum.KeyCode.D }
    local bt = {
        active = false,
        generation = 0,
        seen = setmetatable({}, { __mode = "k" }),
        lastPress = { A = 0, S = 0, D = 0 },
        pressBusy = { A = false, S = false, D = false },
        connections = {},
    }

    local function IsBlackTortoise(name)
        return string.find(string.lower(tostring(name or "")), "black tortoise", 1, true) ~= nil
    end

    local function IsBadNote(note)
        local c = note.BackgroundColor3
        return c.R > 0.65 and c.G * 1.5 < c.R and c.B * 1.5 < c.R
    end

    local function PressLane(lane)
        if bt.pressBusy[lane] then return false end
        local key = keyMap[lane]
        if not key then return false end
        bt.pressBusy[lane] = true
        local ok = pcall(function()
            VirtualInputManager:SendKeyEvent(true, key, false, game)
        end)
        if not ok then
            bt.pressBusy[lane] = false
            return false
        end
        task.delay(0.025, function()
            pcall(function()
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end)
            bt.pressBusy[lane] = false
        end)
        return true
    end

    local function ScheduleNote(laneFrame, barFrame, lane, note, generation)
        if not note or note.Name ~= "Note_FX" or not note:IsA("GuiObject") then return end
        if bt.seen[note] then return end
        bt.seen[note] = true
        if IsBadNote(note) then return end
        local ok1, noteY = pcall(function() return note.Position.Y.Scale end)
        local ok2, targetY = pcall(function() return barFrame.Position.Y.Scale end)
        if not ok1 or not ok2 or type(noteY) ~= "number" or type(targetY) ~= "number" then return end
        local band = math.clamp(tonumber(Config.BlackTortoiseBand) or 0.12, 0.03, 0.17)
        local delay = math.clamp((targetY - math.min(0.04, band * 0.35) - noteY) / NOTE_SPEED, 0, 2)
        local function try(retries)
            if generation ~= bt.generation or not bt.active or not Config.AutoMiniGame then return end
            if note.Parent ~= laneFrame or not note.Visible or not laneFrame.Parent then return end
            if targetY + HIT_WINDOW < note.Position.Y.Scale then return end
            local best, bestDist = nil, math.huge
            for _, child in ipairs(laneFrame:GetChildren()) do
                if child.Name == "Note_FX" and child:IsA("GuiObject") and child.Visible then
                    local d = math.abs(child.Position.Y.Scale - targetY)
                    if d <= HIT_WINDOW and d < bestDist then
                        best, bestDist = child, d
                    end
                end
            end
            if best == note and not IsBadNote(best) then
                local now = os.clock()
                if now - (bt.lastPress[lane] or 0) >= 0.12 and PressLane(lane) then
                    bt.lastPress[lane] = now
                end
            elseif retries > 0 then
                task.delay(0.04, try, retries - 1)
            end
        end
        task.delay(delay, try, 5)
    end

    local function StopBlackTortoise()
        bt.active = false
        UzexFilter.BTActive = false
        bt.generation = bt.generation + 1
        bt.seen = setmetatable({}, { __mode = "k" })
        bt.pressBusy = { A = false, S = false, D = false }
        for _, conn in ipairs(bt.connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(bt.connections)
    end

    local function StartBlackTortoise(data)
        StopBlackTortoise()
        if type(data) ~= "table" or tostring(data.Mode):lower() ~= "hard" then return end
        if not Config.AutoMiniGame then return end
        local generation = bt.generation
        task.defer(function()
            if generation ~= bt.generation then return end
            local isBT = IsBlackTortoise(lastHookedName)
            if not isBT then
                local ok, _, _, shown = pcall(UzexFilter.Classify)
                isBT = ok and IsBlackTortoise(shown)
            end
            if not isBT then return end
            local gui = FishingGui and FishingGui:FindFirstChild("Rhythm")
            if not gui then return end
            bt.active = true
            UzexFilter.BTActive = true
            for _, lane in ipairs(lanes) do
                local laneFrame = gui:FindFirstChild("Progression" .. lane)
                local barFrame = laneFrame and laneFrame:FindFirstChild("BarFrame")
                if laneFrame and barFrame then
                    table.insert(bt.connections, laneFrame.ChildAdded:Connect(function(child)
                        pcall(ScheduleNote, laneFrame, barFrame, lane, child, generation)
                    end))
                    for _, child in ipairs(laneFrame:GetChildren()) do
                        pcall(ScheduleNote, laneFrame, barFrame, lane, child, generation)
                    end
                end
            end
        end)
    end

    pcall(function()
        local rhythmStart = Events:FindFirstChild("RhythmStart")
        local rhythmStop = Events:FindFirstChild("RhythmStop")
        if rhythmStart then rhythmStart.OnClientEvent:Connect(StartBlackTortoise) end
        if rhythmStop then rhythmStop.OnClientEvent:Connect(StopBlackTortoise) end
    end)
end

local lastMinigameEndTick = 0

task.spawn(function()
    local lastCastTry = 0
    local lastSkillTry = 0
    local skillSeqIndex = 1
    local pendingSkillKey = nil
    local wasMinigameActive = false
    local fightAllowed = false
    local fightStart = nil
    local cancelStage = 0
    local fightKey = nil
    while task.wait(0.08) do
        local now = os.clock()
        RefreshGuiCache()
        local isMinigame = FishingGui and FishingGui.Visible or false
        if wasMinigameActive and not isMinigame then
            lastMinigameEndTick = now
        end
        wasMinigameActive = isMinigame
        -- Fish filter: only fight Boss / Secret Boss fish, drop every other fish and recast
        local filterOn = Config.FilterBossFish
            and not (Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland or UzexFilter.SecretFarmAllowed())
        local curFishId = LocalPlayer:GetAttribute("FishID")
        if filterOn and (isMinigame or curFishId ~= nil) then
            -- every new fish on the line starts a new decision (decided as soon as the fish is known)
            local key = tostring(curFishId or "gui")
            if key ~= fightKey then
                fightKey = key
                fightStart = now
                fightAllowed = false
                cancelStage = 0
            end
            if not fightAllowed and cancelStage == 0 then
                local isBoss, isSecret, shown, known = UzexFilter.Classify()
                local waited = now - fightStart
                if Config.FilterBossFish and isBoss and not isSecret then
                    fightAllowed = true
                    pcall(function()
                        Library:Notify({
                            Title = "Bộ lọc cá",
                            Content = "Đã tìm thấy: " .. (shown ~= "" and shown or "boss fish") .. (isSecret and " (bí mật)" or " (boss)"),
                            Duration = 4,
                        })
                    end)
                elseif (known and waited > 0.15) or waited > 3.0 then
                    cancelStage = 1
                    if now - UzexFilter.LastNotify > 3 then
                        UzexFilter.LastNotify = now
                        pcall(function()
                            Library:Notify({
                                Title = "Bộ lọc cá",
                                Content = "Đã bỏ qua: " .. (shown ~= "" and shown or "unknown fish") .. (isSecret and " [secret]" or (isBoss and " [boss]" or " [normal]")),
                                Duration = 2,
                            })
                        end)
                    end
                    UzexFilter.Recycle()
                end
            elseif cancelStage == 1 and isMinigame and (now - fightStart) > 4 then
                -- One recycle attempt per fish only; repeated recycle calls can cancel
                -- the next cast and skip a Secret Boss bite.
                cancelStage = 2
            end
            UzexFilter.Skip = not fightAllowed
        else
            fightAllowed = false
            fightStart = nil
            fightKey = nil
            cancelStage = 0
            UzexFilter.Skip = false
        end
        -- after a skipped fish the rod must end up in hand again (only for that case, never otherwise)
        if UzexFilter.NeedRod and not UzexFilter.Busy then
            if not Config.FilterBossFish or UzexFilter.HoldingRod() then
                UzexFilter.NeedRod = false
            elseif now - (UzexFilter.LastEquip or 0) > 0.3 then
                UzexFilter.LastEquip = now
                task.spawn(function()
                    pcall(function()
                        ToggleHotbar:InvokeServer("1")
                    end)
                end)
            end
        end
        local activeReel = (Config.AutoReel or Config.AutoMiniGame or Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland) and not UzexFilter.Skip and not UzexFilter.SkippingFish and not secretFarmOn
        local secretFarmOn = UzexFilter.SecretFarmAllowed()
        local activeCast = (Config.AutoCast or Config.AutoFarmIsland or Config.FilterBossFish) and not secretFarmOn
            and not (UzexFilter.HasPendingEventFish and UzexFilter.HasPendingEventFish())
        local activeSkill = (Config.AutoSkill or Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland) and not UzexFilter.Skip

        if not isMinigame then
            skillSeqIndex = 1
            pendingSkillKey = nil
        end

        if activeReel and isMinigame then
            pcall(function()
                UpdateFishProgression:FireServer()
            end)
        end

        if activeSkill and isMinigame then
            local char = cachedChar
            local order = Config.SkillOrder
            local orderCount = type(order) == "table" and #order or 0
            if char and orderCount > 0 then
                if skillSeqIndex < 1 or skillSeqIndex > orderCount then
                    skillSeqIndex = 1
                end

                local readyIdx = nil
                for step = 1, orderCount do
                    local idx = ((skillSeqIndex - 1 + (step - 1)) % orderCount) + 1
                    local k = order[idx]
                    if IsSkillKeyReady(char, k) then
                        readyIdx = idx
                        break
                    end
                end

                if readyIdx then
                    skillSeqIndex = readyIdx
                    local currentKey = order[skillSeqIndex]
                    if IsGameAllowingSkill(char) and (now - lastSkillTry >= 0.25) then
                        lastSkillTry = os.clock()
                        pendingSkillKey = currentKey
                        pcall(function()
                            UseSkill:FireServer(currentKey)
                        end)
                        skillSeqIndex = (skillSeqIndex % orderCount) + 1
                    end
                else
                    for step = 1, orderCount do
                        local idx = ((skillSeqIndex - 1 + (step - 1)) % orderCount) + 1
                        if IsSkillSlotAvailable(char, order[idx]) and not IsSkillOnCooldown(char, order[idx]) then
                            skillSeqIndex = idx
                            break
                        end
                    end
                end
            end
        end

        if Config.AutoBoss or Config.AutoSecretBoss then
            StepAutoBoss(cachedChar, isMinigame)
        else
            if not isMinigame then
                StepAutoTPPos(cachedChar)
                StepAutoFarmIsland(cachedChar)
            end
            if activeCast and not isMinigame then
                local minCastInterval = (Config.AutoCastMethod == "Instant") and 0.05 or math.clamp(tonumber(Config.CastDelay) or 1, 0, 10)
                if (now - lastMinigameEndTick >= minCastInterval) and (now - lastCastTry >= minCastInterval) then
                    local char = cachedChar
                    if char then
                        if char:GetAttribute("Type") ~= "Fishing Rod" then
                            -- Auto Cast no longer equips the rod by itself (equip it manually).
                            -- Auto Farm Island still needs the rod, so it keeps equipping it.
                            if Config.AutoFarmIsland then
                                lastCastTry = now
                                pcall(function()
                                    ToggleHotbar:InvokeServer("1")
                                end)
                            end
                        elseif not char:GetAttribute("Fishing") then
                            local hrp = cachedHrp or char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                lastCastTry = now
                                pcall(function()
                                    FishingEvent:FireServer(hrp.CFrame)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

Events:WaitForChild("Slam").OnClientEvent:Connect(function(remote)
    if (Config.AutoMiniGame or Config.AutoReel or Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland) and not UzexFilter.Skip and remote then
        task.wait(0.05)
        local handled = false
        pcall(function()
            local tc = FishingGui and FishingGui:FindFirstChild("TrashCan")
            local slamGui = tc and tc:FindFirstChild("Slam")
            local btn = slamGui and slamGui:FindFirstChild("Button")
            local line = btn and btn:FindFirstChild("Line")
            if line then
                line.Size = UDim2.new(1, 0, 1, 0)
            end
            if btn then
                TriggerGuiButton(btn)
                if not slamGui.Parent then
                    handled = true
                end
            end
            if not handled then
                remote:FireServer("Perfect")
                if slamGui and slamGui.Parent then
                    slamGui:Destroy()
                end
            end
        end)
    end
end)

Events:WaitForChild("Charge").OnClientEvent:Connect(function(remote)
    if (Config.AutoMiniGame or Config.AutoReel or Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland) and not UzexFilter.Skip and remote then
        task.wait(1.05)
        pcall(function()
            local tc = FishingGui and FishingGui:FindFirstChild("TrashCan")
            local chargeGui = tc and tc:FindFirstChild("Charge")
            local btn = chargeGui and chargeGui:FindFirstChild("Button")
            if btn and chargeGui.Parent then
                TriggerGuiButton(btn)
            end
            if chargeGui and chargeGui.Parent then
                remote:FireServer()
                chargeGui:Destroy()
            end
        end)
    end
end)

function clearPlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local head = char:FindFirstChild("Head")
            if head then
                local esp = head:FindFirstChild("UZEXHubESP")
                if esp then esp:Destroy() end
            end
        end
    end
end

end
local function updateESP()
    if not Config.ESPEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if head and hum then
                    local esp = head:FindFirstChild("UZEXHubESP")
                    if hum.Health > 0 then
                        if not esp then
                            esp = Instance.new("BillboardGui")
                            esp.Name = "UZEXHubESP"
                            esp.Adornee = head
                            esp.Size = UDim2.new(0, 200, 0, 25)
                            esp.StudsOffset = Vector3.new(0, 2.5, 0)
                            esp.AlwaysOnTop = true
                            esp.MaxDistance = math.huge
                            local text = Instance.new("TextLabel")
                            text.Name = "NameText"
                            text.Parent = esp
                            text.Size = UDim2.new(1, 0, 1, 0)
                            text.BackgroundTransparency = 1
                            text.TextScaled = false
                            text.TextSize = 13
                            text.Font = Enum.Font.GothamBold
                            text.TextColor3 = Color3.fromRGB(255, 255, 255)
                            text.TextStrokeTransparency = 0
                            text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            text.TextXAlignment = Enum.TextXAlignment.Center
                            esp.Parent = head
                        end
                        esp.NameText.Text = player.DisplayName
                    else
                        if esp then esp:Destroy() end
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.4) do
        if Config.ESPEnabled then
            updateESP()
        end
    end
end)

local lastSellTime = 0
local lastBuyBaitTime = 0
local StepAutoEquipBestBait
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")

local function FindRemote(name)
    return Events:FindFirstChild(name) or (RemotesFolder and RemotesFolder:FindFirstChild(name))
end

local function FireOrInvokeEvent(ev, ...)
    if not ev then return false end
    local args = {...}
    local ok = pcall(function()
        if ev:IsA("RemoteEvent") then
            ev:FireServer(unpack(args))
        elseif ev:IsA("RemoteFunction") then
            ev:InvokeServer(unpack(args))
        end
    end)
    return ok
end

local function DoBuyBait(baitName, amount)
    if not baitName or baitName == "" then return end
    local amt = math.max(1, math.floor(tonumber(amount) or 1))
    local buyEvent = FindRemote("BuyBait") or FindRemote("Bait") or FindRemote("PurchaseBait") or FindRemote("BaitShop") or FindRemote("BuyItem")
    if buyEvent then
        FireOrInvokeEvent(buyEvent, baitName, amt)
    else
        pcall(function()
            CraftBaitEvent:FireServer(baitName, amt)
        end)
    end
end

-------------------------------------------------------------------------------
-- Auto Sell Fish
--   Spam      : sells all fish again and again
--   When full : sells all fish once the fish storage is full
-------------------------------------------------------------------------------
do
    local SPAM_INTERVAL = 0.5
    local FULL_COOLDOWN = 2
    local FALLBACK_INTERVAL = 60
    local STORAGE_WORDS = { "inventory", "backpack", "bag", "storage", "capacity" }

    local counterLabel = nil
    local lastCounterScan = 0
    local lastMessageScan = 0
    local messageSeen = false
    local warnedFallback = false

    local function SellAllFish()
        lastSellTime = os.clock()
        pcall(function()
            SellFish:FireServer("All")
        end)
    end

    local function ParseFraction(str)
        local a, b = string.match(tostring(str or ""), "([%d%.,]+)%s*/%s*([%d%.,]+)")
        a = tonumber((tostring(a or ""):gsub(",", "")))
        b = tonumber((tostring(b or ""):gsub(",", "")))
        if a and b and b > 0 then
            return a, b
        end
        return nil
    end

    local function HasStorageWord(str)
        str = string.lower(tostring(str or ""))
        for _, w in ipairs(STORAGE_WORDS) do
            if string.find(str, w, 1, true) then
                return true
            end
        end
        return false
    end

    local function IsShown(obj)
        local p = obj
        while p do
            if p:IsA("GuiObject") and not p.Visible then
                return false
            end
            if p:IsA("ScreenGui") and not p.Enabled then
                return false
            end
            p = p.Parent
        end
        return true
    end

    local function InStorageGui(obj, root)
        local p, depth = obj, 0
        while p and p ~= root and depth < 6 do
            if HasStorageWord(p.Name) then
                return true
            end
            p = p.Parent
            depth = depth + 1
        end
        return false
    end

    -- a label such as "45/50" that sits inside the inventory / backpack / storage UI
    local function FindCounter(playerGui)
        for _, d in ipairs(playerGui:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and ParseFraction(d.Text)
                and InStorageGui(d, playerGui) and not (FishingGui and d:IsDescendantOf(FishingGui)) then
                return d
            end
        end
        return nil
    end

    -- an on-screen message such as "Inventory is full"
    local function FullMessageVisible(playerGui)
        for _, d in ipairs(playerGui:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text ~= "" and d.TextTransparency < 0.9 then
                local t = string.lower(d.Text)
                if string.find(t, "full", 1, true) and HasStorageWord(t) and IsShown(d) then
                    return true
                end
            end
        end
        return false
    end

    -- true = full, false = not full, nil = cannot tell
    local function IsFishStorageFull()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then
            return nil
        end
        local now = os.clock()

        if not (counterLabel and counterLabel.Parent) and now - lastCounterScan >= 5 then
            lastCounterScan = now
            counterLabel = FindCounter(playerGui)
        end
        if counterLabel and counterLabel.Parent then
            local cur, cap = ParseFraction(counterLabel.Text)
            if cur and cap then
                -- Fish storage UI may show 999 or 1999 as the cap; sell at 998/1998
                -- so the next catch cannot fill the inventory before the check runs.
                return cur >= math.max(1, cap - 1)
            end
        end

        if now - lastMessageScan >= 1 then
            lastMessageScan = now
            messageSeen = FullMessageVisible(playerGui)
        end
        if messageSeen then
            return true
        end
        return nil
    end

    task.spawn(function()
        while task.wait(0.5) do
            if Config.AutoSell then
                local now = os.clock()
                if Config.AutoSellMethod == "When full" then
                    if now - lastSellTime >= FULL_COOLDOWN then
                        local ok, full = pcall(IsFishStorageFull)
                        if not ok then
                            full = nil
                        end
                        if full == true then
                            SellAllFish()
                        elseif full == nil then
                            -- could not read the storage at all: sell on a timer so fish never pile up
                            if not warnedFallback then
                                warnedFallback = true
                                Library:Notify({
                                    Title = "Tự động bán cá",
                                    Content = "Không đọc được sức chứa túi cá, phương thức này sẽ bán cá mỗi 60 giây.",
                                    Type = "warning",
                                    Duration = 6,
                                })
                            end
                            if now - lastSellTime >= FALLBACK_INTERVAL then
                                SellAllFish()
                            end
                        end
                    end
                elseif now - lastSellTime >= SPAM_INTERVAL then
                    SellAllFish()
                end
            end
        end
    end)
end

task.spawn(function()
    while task.wait(0.8) do
        if Config.AutoBuyBait and Config.SelectedBuyBait ~= "" then
            local delaySec = math.max(1, tonumber(Config.BuyBaitDelay) or 1) * 60
            local now = os.clock()
            if now - lastBuyBaitTime >= delaySec then
                lastBuyBaitTime = now
                DoBuyBait(Config.SelectedBuyBait, Config.BuyBaitAmount)
            end
        end
        if Config.AutoCraftBait and Config.SelectedBait ~= "" then
            pcall(function()
                CraftBaitEvent:FireServer(Config.SelectedBait, math.max(1, math.floor(tonumber(Config.BaitAmount) or 1)))
            end)
        end
        if Config.AutoCraftRod and Config.SelectedRod ~= "" then
            pcall(function()
                CraftRodEvent:FireServer(Config.SelectedRod)
            end)
        end
    end
end)

local lastTicketQuestTime, GetBuyableBaits
do
lastTicketQuestTime = 0
local ChooseDialogueOption = Events:WaitForChild("ChooseDialogueOption", 9e9)

local function HideTicketDialogueUI()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local mg = pg and pg:FindFirstChild("MainGui")
    local menu = mg and mg:FindFirstChild("Menu")
    local dialogue = menu and menu:FindFirstChild("Dialogue")
    if dialogue and dialogue.Visible then
        local nameLabel = dialogue:FindFirstChild("Name", true) or dialogue:FindFirstChild("NPCName", true) or dialogue:FindFirstChild("Title", true)
        local dName = nameLabel and tostring(nameLabel.Text) or ""
        if dName == "" or string.find(dName, "Ticket", 1, true) or string.find(dName, "Giver", 1, true) then
            dialogue.Visible = false
        end
    end
end

local function GetTicketQuestGiverPart()
    local npcFolder = workspace:FindFirstChild("NPC")
    local funcFolder = npcFolder and npcFolder:FindFirstChild("Function")
    local giver = funcFolder and funcFolder:FindFirstChild("Ticket Quest Giver")
    if giver then return giver end
    return workspace:WaitForChild("NPC", 9e9):WaitForChild("Function", 9e9):WaitForChild("Ticket Quest Giver", 9e9)
end

local function GetActiveTicketQuest()
    local pData = PlayerData
    if not pData then return nil end
    local qFolder = pData:FindFirstChild("Quest")
    local mainFolder = qFolder and qFolder:FindFirstChild("Main")
    if mainFolder then
        local tq = mainFolder:FindFirstChild("Hard Ticket Quest")
            or mainFolder:FindFirstChild("Easy Ticket Quest")
            or mainFolder:FindFirstChild("Ticket Quest")
        if tq then return tq end
    end
    for _, child in ipairs(pData:GetChildren()) do
        if child:IsA("Folder") and (child.Name == "Hard Ticket Quest" or child.Name == "Easy Ticket Quest" or child.Name == "Ticket Quest") then
            return child
        end
    end
    return nil
end

local function IsTicketQuestCompleted(tq)
    if not tq then return false end
    local infoMain = Info and Info:FindFirstChild("MainQuest")
    local questInfo = nil
    if infoMain and infoMain:FindFirstChild(tq.Name) then
        pcall(function()
            questInfo = require(infoMain[tq.Name])
        end)
    end

    local hasObjectives = false
    for _, child in ipairs(tq:GetChildren()) do
        if child:IsA("NumberValue") then
            hasObjectives = true
            local targetVal = nil
            if questInfo and questInfo[tonumber(child.Name)] then
                targetVal = tonumber(questInfo[tonumber(child.Name)][2])
            elseif tq:FindFirstChild("Objective") then
                local objVal = tq.Objective:FindFirstChild(child.Name)
                if objVal and objVal:IsA("StringValue") then
                    local parts = string.split(objVal.Value, ",")
                    targetVal = tonumber(parts[2])
                end
            end

            if targetVal and child.Value < targetVal then
                return false
            end
        end
    end
    return hasObjectives
end

local function GetTicketQuestState()
    local tq = GetActiveTicketQuest()
    if not tq then
        return "none"
    end
    if IsTicketQuestCompleted(tq) then
        return "completed"
    else
        return "in_progress"
    end
end

local StepSmartTicketQuest
do
    local questCooldownUntil = 0
    local lastAcceptAttempt = 0
    local lastTurnInAttempt = 0
    local lastRecordedCooldownText = ""

    local function ParseCooldownSeconds(text)
        if not text or text == "" then return nil end
        local lower = string.lower(text)
        if string.find(lower, "another quest in") or string.find(lower, "take another quest in") then
            local m, s = string.match(lower, "(%d+)%s*:%s*(%d+)")
            if m and s then
                return (tonumber(m) or 0) * 60 + (tonumber(s) or 0)
            end
            local mPart = string.match(lower, "(%d+)%s*m")
            local sPart = string.match(lower, "(%d+)%s*s")
            if mPart or sPart then
                return (tonumber(mPart) or 0) * 60 + (tonumber(sPart) or 0)
            end
        end
        return nil
    end

    local function CheckAndSetCooldown(text)
        if not text or text == "" then return end
        if text == lastRecordedCooldownText then return end
        local sec = ParseCooldownSeconds(text)
        if sec and sec > 0 and sec <= 3600 then
            lastRecordedCooldownText = text
            questCooldownUntil = os.clock() + sec
        end
    end

    local function TurnInTicketQuest(giver)
        local g = giver or GetTicketQuestGiverPart()
        if not g then return end
        local turnInArgs = {
            [1] = "Ticket Quest Giver",
            [2] = 1,
            [3] = "Quest",
            [4] = {
                [1] = g
            }
        }
        pcall(function()
            ChooseDialogueOption:FireServer(unpack(turnInArgs))
        end)
        HideTicketDialogueUI()
        lastTurnInAttempt = os.clock()
    end

    local function AcceptTicketQuest(giver)
        local g = giver or GetTicketQuestGiverPart()
        if not g then return end
        local acceptOption = (Config.TicketQuestMode == "Easy") and "EasyAcceptQuest" or "HardAcceptQuest"
        local acceptIndex = (Config.TicketQuestMode == "Easy") and 1 or 2
        local acceptArgs = {
            [1] = "Ticket Quest Giver",
            [2] = acceptIndex,
            [3] = acceptOption,
            [4] = {
                [1] = g,
                [2] = "Ticket Quest"
            }
        }
        pcall(function()
            ChooseDialogueOption:FireServer(unpack(acceptArgs))
        end)
        HideTicketDialogueUI()
        lastAcceptAttempt = os.clock()
    end

    -- after the ticket quest reward is claimed: buy bait, then equip the best bait
    local function AfterTicketClaim()
        task.spawn(function()
            task.wait(0.6)
            if Config.SelectedBuyBait ~= "" then
                DoBuyBait(Config.SelectedBuyBait, Config.BuyBaitAmount)
            end
            task.wait(0.8)
            if StepAutoEquipBestBait then
                pcall(StepAutoEquipBestBait, true)
            end
        end)
    end

    function StepSmartTicketQuest()
        local now = os.clock()
        if now < questCooldownUntil then
            return
        end

        local giver = GetTicketQuestGiverPart()
        if not giver then return end

        local state = GetTicketQuestState()
        if state == "completed" then
            if now - lastTurnInAttempt >= 1.5 then
                TurnInTicketQuest(giver)
                AfterTicketClaim()
                task.wait(0.5)
                AcceptTicketQuest(giver)
            end
        elseif state == "in_progress" then
            return
        else
            if now >= questCooldownUntil and (now - lastAcceptAttempt >= 2) then
                TurnInTicketQuest(giver)
                task.wait(0.4)
                AcceptTicketQuest(giver)
            end
        end
    end

    pcall(function()
        local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            pg.DescendantAdded:Connect(function(desc)
                if desc:IsA("TextLabel") then
                    CheckAndSetCooldown(desc.Text)
                    desc:GetPropertyChangedSignal("Text"):Connect(function()
                        CheckAndSetCooldown(desc.Text)
                    end)
                end
            end)
        end
    end)

    pcall(function()
        for _, ev in ipairs(Events:GetChildren()) do
            if ev:IsA("RemoteEvent") then
                ev.OnClientEvent:Connect(function(...)
                    local args = {...}
                    for _, a in ipairs(args) do
                        if type(a) == "string" then
                            CheckAndSetCooldown(a)
                        elseif type(a) == "table" then
                            for _, sub in pairs(a) do
                                if type(sub) == "string" then
                                    CheckAndSetCooldown(sub)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    pcall(function()
        local startDialogueEvent = Events:FindFirstChild("StartDialogue")
        if startDialogueEvent and startDialogueEvent:IsA("RemoteEvent") then
            startDialogueEvent.OnClientEvent:Connect(function(dialogueName, npcModel, dialogueData)
                if not Config.AutoTicketQuest then return end
                if tostring(dialogueName) == "Ticket Quest Giver" or (npcModel and npcModel.Name == "Ticket Quest Giver") then
                    HideTicketDialogueUI()
                    if type(dialogueData) == "table" and type(dialogueData[1]) == "string" then
                        CheckAndSetCooldown(dialogueData[1])
                    end
                end
            end)
        end
    end)
end

local function GetZengTianguoPart()
    local npcFolder = workspace:FindFirstChild("NPC")
    local funcFolder = npcFolder and npcFolder:FindFirstChild("Function")
    local giver = funcFolder and funcFolder:FindFirstChild("Zeng Tianguo")
    if giver then return giver end
    return workspace:WaitForChild("NPC", 9e9):WaitForChild("Function", 9e9):WaitForChild("Zeng Tianguo", 9e9)
end

local function GetActiveZengTianguoQuest()
    local pData = PlayerData or (DataFolder and DataFolder:FindFirstChild(tostring(LocalPlayer.UserId)))
    if not pData then return nil end
    local qFolder = pData:FindFirstChild("Quest")
    local mainFolder = qFolder and qFolder:FindFirstChild("Main")
    local containers = {
        mainFolder,
        qFolder,
        pData
    }
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                if child:IsA("Folder") or child:IsA("Configuration") then
                    local lower = string.lower(child.Name)
                    if string.find(lower, "zeng", 1, true) and string.find(lower, "tianguo", 1, true) then
                        return child
                    end
                end
            end
        end
    end
    local mg = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainGui")
    local mq = mg and mg:FindFirstChild("Menu") and mg.Menu:FindFirstChild("Quest") and mg.Menu.Quest:FindFirstChild("Menu") and mg.Menu.Quest.Menu:FindFirstChild("Main_Quest")
    if mq then
        for _, child in ipairs(mq:GetChildren()) do
            if child:IsA("GuiObject") and child.Visible and child.Name ~= "Template" then
                local lower = string.lower(child.Name)
                if string.find(lower, "zeng", 1, true) and string.find(lower, "tianguo", 1, true) then
                    if mainFolder then
                        return mainFolder:FindFirstChild(child.Name) or child
                    end
                    return child
                end
            end
        end
    end
    return nil
end

local function IsZengTianguoQuestCompleted(zq)
    if not zq then return false end
    local infoMain = Info and Info:FindFirstChild("MainQuest")
    local questInfo = nil
    if infoMain then
        local qMod = infoMain:FindFirstChild(zq.Name) or infoMain:FindFirstChild("Zeng Tianguo") or infoMain:FindFirstChild("Zeng Tianguo Quest")
        if qMod then
            pcall(function()
                questInfo = require(qMod)
            end)
        end
    end

    local hasObjectives = false
    for _, child in ipairs(zq:GetChildren()) do
        if child:IsA("NumberValue") then
            hasObjectives = true
            local targetVal = nil
            if questInfo and questInfo[tonumber(child.Name)] then
                targetVal = tonumber(questInfo[tonumber(child.Name)][2])
            elseif zq:FindFirstChild("Objective") then
                local objVal = zq.Objective:FindFirstChild(child.Name)
                if objVal and objVal:IsA("StringValue") then
                    local parts = string.split(objVal.Value, ",")
                    targetVal = tonumber(parts[2])
                end
            end

            if targetVal and child.Value < targetVal then
                return false
            end
        end
    end

    if not hasObjectives then
        local mg = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainGui")
        local mq = mg and mg:FindFirstChild("Menu") and mg.Menu:FindFirstChild("Quest") and mg.Menu.Quest:FindFirstChild("Menu") and mg.Menu.Quest.Menu:FindFirstChild("Main_Quest")
        local frame = mq and (mq:FindFirstChild(zq.Name) or mq:FindFirstChild("Zeng Tianguo") or mq:FindFirstChild("Zeng Tianguo Quest"))
        if frame then
            local qFrame = frame:FindFirstChild("Quest")
            if qFrame then
                local allGreen = true
                local foundStats = false
                for _, stat in ipairs(qFrame:GetChildren()) do
                    if stat:IsA("TextLabel") and stat.Name ~= "Title" and stat.Visible then
                        foundStats = true
                        if stat.TextColor3 ~= Color3.fromRGB(144, 255, 110) then
                            allGreen = false
                            break
                        end
                    end
                end
                if foundStats then
                    return allGreen
                end
            end
        end
    end

    return hasObjectives
end

local function HideZengTianguoDialogueUI()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local mg = pg and pg:FindFirstChild("MainGui")
    local menu = mg and mg:FindFirstChild("Menu")
    local dialogue = menu and menu:FindFirstChild("Dialogue")
    if dialogue and dialogue.Visible then
        local nameLabel = dialogue:FindFirstChild("Name", true) or dialogue:FindFirstChild("NPCName", true) or dialogue:FindFirstChild("Title", true)
        local dName = nameLabel and tostring(nameLabel.Text) or ""
        if dName == "" or string.find(dName, "Zeng", 1, true) or string.find(dName, "Tianguo", 1, true) then
            dialogue.Visible = false
        end
    end
end

local StepSmartZengTianguoQuest
do
    local lastActionTick = 0

    local function InteractZengTianguo(giver)
        local g = giver or GetZengTianguoPart()
        if not g then return end
        local args1 = {
            [1] = "Zeng Tianguo",
            [2] = 1,
            [3] = "Quest",
            [4] = {
                [1] = g
            }
        }
        local args2 = {
            [1] = "Zeng Tianguo",
            [2] = 1,
            [3] = "AcceptQuest",
            [4] = {
                [1] = g,
                [2] = "Zeng Tianguo Quest"
            }
        }
        pcall(function()
            ChooseDialogueOption:FireServer(unpack(args1))
        end)
        task.wait(0.3)
        pcall(function()
            ChooseDialogueOption:FireServer(unpack(args2))
        end)
        HideZengTianguoDialogueUI()
        lastActionTick = os.clock()
    end

    function StepSmartZengTianguoQuest()
        local now = os.clock()
        if now - lastActionTick < 3 then
            return
        end

        local zq = GetActiveZengTianguoQuest()
        if zq then
            if IsZengTianguoQuestCompleted(zq) then
                local giver = GetZengTianguoPart()
                if giver then
                    InteractZengTianguo(giver)
                end
            end
            return
        end

        local giver = GetZengTianguoPart()
        if giver then
            InteractZengTianguo(giver)
        end
    end

    pcall(function()
        local startDialogueEvent = Events:FindFirstChild("StartDialogue")
        if startDialogueEvent and startDialogueEvent:IsA("RemoteEvent") then
            startDialogueEvent.OnClientEvent:Connect(function(dialogueName, npcModel)
                if not Config.AutoZengTianguoQuest then return end
                if tostring(dialogueName) == "Zeng Tianguo" or (npcModel and npcModel.Name == "Zeng Tianguo") then
                    HideZengTianguoDialogueUI()
                end
            end)
        end
    end)
end


do
    local function CleanBaitName(str)
        if not str or str == "" then return "" end
        local clean = string.split(str, "|")[1] or str
        return string.gsub(clean, "^%s*(.-)%s*$", "%1")
    end

    local function GetSafeItemCount(obj)
        if not obj then return 0 end
        local count = 0
        pcall(function()
            if obj:IsA("ValueBase") then
                count = tonumber(obj.Value) or 0
            end
        end)
        if count and count > 0 then return count end
        pcall(function()
            local q = obj:FindFirstChild("Quantity") or obj:FindFirstChild("Count") or obj:FindFirstChild("Value") or obj:FindFirstChild("Amount")
            if q and q:IsA("ValueBase") then
                count = tonumber(q.Value) or 0
            end
        end)
        if count and count > 0 then return count end
        pcall(function()
            local attr = obj:GetAttribute("Quantity") or obj:GetAttribute("Count") or obj:GetAttribute("Amount") or obj:GetAttribute("Value")
            if attr then
                count = tonumber(attr) or 0
            end
        end)
        if count and count > 0 then return count end
        pcall(function()
            if obj:IsA("BoolValue") and obj.Value == true then
                count = 1
            end
        end)
        return count or 0
    end

    local function GetBaitLuck(cleanName)
        local infoBait = Info and Info:FindFirstChild("Bait")
        if not infoBait or not cleanName or cleanName == "" then return 0 end
        local mod = infoBait:FindFirstChild(cleanName)
        if not mod or not mod:IsA("ModuleScript") then return 0 end
        local luck = 0
        local success, data = pcall(require, mod)
        if success and type(data) == "table" and data.Luck ~= nil then
            local num = tonumber(data.Luck)
            if not num then
                local str = tostring(data.Luck)
                local cleanStr = string.match(str, "%d+%.?%d*")
                num = tonumber(cleanStr)
            end
            luck = num or 0
        end
        return luck
    end

    local function GetBestOwnedBait()
        local pData = PlayerData
        if not pData then return nil end
        local infoBait = Info and Info:FindFirstChild("Bait")
        if not infoBait then return nil end

        local bestName = nil
        local bestRawName = nil
        local bestLuck = -1
        local bestCount = 0
        local bestSource = nil
        local bestInst = nil

        local function consider(rawName, count, inst, src)
            local c = tonumber(count) or 0
            if c > 0 then
                local clean = CleanBaitName(rawName)
                if infoBait:FindFirstChild(clean) then
                    local luck = GetBaitLuck(clean)
                    if luck > bestLuck then
                        bestLuck = luck
                        bestName = clean
                        bestRawName = rawName
                        bestCount = c
                        bestSource = src
                        bestInst = inst
                    elseif not bestName then
                        bestName = clean
                        bestRawName = rawName
                        bestCount = c
                        bestSource = src
                        bestInst = inst
                    end
                end
            end
        end

        local baitFolder = pData:FindFirstChild("Bait")
        if baitFolder then
            for _, child in ipairs(baitFolder:GetChildren()) do
                local cnt = GetSafeItemCount(child)
                if cnt > 0 then
                    consider(child.Name, cnt, child, "Bait")
                end
            end
        end

        local invFolder = pData:FindFirstChild("Inventory")
        if invFolder then
            for _, child in ipairs(invFolder:GetChildren()) do
                local clean = CleanBaitName(child.Name)
                if infoBait:FindFirstChild(clean) then
                    local cnt = GetSafeItemCount(child)
                    if cnt <= 0 then cnt = 1 end
                    consider(child.Name, cnt, child, "Inventory")
                end
            end
        end

        return bestName, bestRawName, bestLuck, bestCount, bestSource, bestInst
    end

    local BaitImageMap = {}
    local function InitBaitImageMap()
        local infoBait = Info and Info:FindFirstChild("Bait")
        if not infoBait then return end
        for _, bMod in ipairs(infoBait:GetChildren()) do
            if bMod:IsA("ModuleScript") then
                local success, data = pcall(require, bMod)
                if success and type(data) == "table" and data.Image then
                    local rawImg = tostring(data.Image)
                    BaitImageMap[rawImg] = bMod.Name
                    BaitImageMap[string.lower(rawImg)] = bMod.Name
                    local numId = string.match(rawImg, "%d+")
                    if numId then
                        BaitImageMap[numId] = bMod.Name
                    end
                end
            end
        end
    end
    InitBaitImageMap()

    local function GetSlot2Quantity()
        local qty = -1
        pcall(function()
            local mainGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainGui")
            local hotbarList = mainGui and mainGui:FindFirstChild("Main") and mainGui.Main:FindFirstChild("Hotbar") and mainGui.Main.Hotbar:FindFirstChild("List")
            local btn2 = hotbarList and hotbarList:FindFirstChild("2")
            if btn2 then
                local qLabel = btn2:FindFirstChild("Quantity") or (btn2:FindFirstChild("Quantity_BG") and btn2.Quantity_BG:FindFirstChild("Quantity")) or (btn2:FindFirstChild("Detail") and btn2.Detail:FindFirstChild("Quantity")) or (btn2:FindFirstChild("Inner") and btn2.Inner:FindFirstChild("Quantity"))
                if qLabel and qLabel:IsA("TextLabel") then
                    if not qLabel.Visible or qLabel.Text == "" then
                        qty = 0
                    else
                        local n = string.match(qLabel.Text, "%d+")
                        qty = tonumber(n) or 0
                    end
                end
            end
        end)
        if qty == -1 and PlayerData then
            pcall(function()
                local hb = PlayerData:FindFirstChild("Hotbar")
                local slot2 = hb and hb:FindFirstChild("2")
                if slot2 then
                    local q = slot2:FindFirstChild("Quantity")
                    if q and q:IsA("ValueBase") then
                        qty = tonumber(q.Value) or 0
                    end
                end
            end)
        end
        return math.max(0, qty)
    end

    local function GetEquippedBaitName()
        if not next(BaitImageMap) then
            InitBaitImageMap()
        end
        local foundName = nil
        pcall(function()
            local mainGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainGui")
            local hotbarList = mainGui and mainGui:FindFirstChild("Main") and mainGui.Main:FindFirstChild("Hotbar") and mainGui.Main.Hotbar:FindFirstChild("List")
            local btn2 = hotbarList and hotbarList:FindFirstChild("2")
            if btn2 then
                local img = btn2:FindFirstChild("Image") or (btn2:FindFirstChild("Inner") and btn2.Inner:FindFirstChild("Image"))
                if not img then
                    img = btn2:FindFirstChildWhichIsA("ImageLabel", true)
                end
                if img and img.Visible and img.Image ~= "" then
                    local raw = tostring(img.Image)
                    local num = string.match(raw, "%d+")
                    if num and BaitImageMap[num] then
                        foundName = BaitImageMap[num]
                    elseif BaitImageMap[raw] then
                        foundName = BaitImageMap[raw]
                    elseif BaitImageMap[string.lower(raw)] then
                        foundName = BaitImageMap[string.lower(raw)]
                    end
                end

                if not foundName then
                    for _, desc in ipairs(btn2:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Text ~= "" then
                            local cl = CleanBaitName(desc.Text)
                            if Info and Info:FindFirstChild("Bait") and Info.Bait:FindFirstChild(cl) then
                                foundName = cl
                                break
                            end
                        end
                        local attr = desc:GetAttribute("ItemName") or desc:GetAttribute("Bait")
                        if attr and tostring(attr) ~= "" then
                            local cl = CleanBaitName(tostring(attr))
                            if Info and Info:FindFirstChild("Bait") and Info.Bait:FindFirstChild(cl) then
                                foundName = cl
                                break
                            end
                        end
                    end
                end

                local qLabel = btn2:FindFirstChild("Quantity") or (btn2:FindFirstChild("Quantity_BG") and btn2.Quantity_BG:FindFirstChild("Quantity")) or (btn2:FindFirstChild("Detail") and btn2.Detail:FindFirstChild("Quantity")) or (btn2:FindFirstChild("Inner") and btn2.Inner:FindFirstChild("Quantity"))
                if qLabel and qLabel:IsA("TextLabel") then
                    if not qLabel.Visible or qLabel.Text == "" or qLabel.Text == "x0" or qLabel.Text == "0" then
                        foundName = nil
                    end
                end
            end
        end)

        if not foundName and PlayerData then
            pcall(function()
                local hb = PlayerData:FindFirstChild("Hotbar")
                local slot2 = hb and hb:FindFirstChild("2")
                if slot2 then
                    local vn = slot2:FindFirstChild("ValueName")
                    local q = slot2:FindFirstChild("Quantity")
                    local cnt = q and tonumber(q.Value) or 0
                    if vn and vn.Value ~= "" and cnt > 0 then
                        local cl = CleanBaitName(vn.Value)
                        if Info and Info:FindFirstChild("Bait") and Info.Bait:FindFirstChild(cl) then
                            foundName = cl
                        end
                    end
                end
                if not foundName then
                    local bVal = PlayerData:FindFirstChild("EquippedBait") or PlayerData:FindFirstChild("CurrentBait")
                    if bVal and bVal:IsA("StringValue") and bVal.Value ~= "" then
                        foundName = CleanBaitName(bVal.Value)
                    end
                end
                if not foundName then
                    local attr = PlayerData:GetAttribute("EquippedBait") or PlayerData:GetAttribute("Bait")
                    if attr and tostring(attr) ~= "" then
                        foundName = CleanBaitName(tostring(attr))
                    end
                end
            end)
        end

        return foundName
    end

    local lastEquipTime = 0

    function StepAutoEquipBestBait(force)
        if not Config.AutoEquipBestBait and not force then return end
        local now = os.clock()
        if not force and now - lastEquipTime < 2 then return end

        local bestBait, bestRaw, bestLuck, bestCount = GetBestOwnedBait()
        if not bestBait or bestCount <= 0 then
            if force then
                pcall(function()
                    Library:Notify({
                        Title = "Tự trang bị mồi",
                        Content = "Không tìm thấy mồi trong túi đồ",
                        Duration = 3
                    })
                end)
            end
            return
        end

        local curEquipped = GetEquippedBaitName()
        local curQty = GetSlot2Quantity()

        if not force and curEquipped == bestBait and curQty > 0 then
            return
        end

        lastEquipTime = now
        local ev = EquipBaitEvent or (Events and Events:FindFirstChild("EquipBait")) or (Events and Events:WaitForChild("EquipBait", 9e9))
        if ev then
            pcall(function()
                if ev:IsA("RemoteFunction") then
                    ev:InvokeServer(bestBait)
                elseif ev:IsA("RemoteEvent") then
                    ev:FireServer(bestBait)
                else
                    ev:InvokeServer(bestBait)
                end
            end)

            task.delay(0.3, function()
                local checkEq = GetEquippedBaitName()
                local checkQ = GetSlot2Quantity()
                if checkQ <= 0 and checkEq ~= bestBait then
                    pcall(function()
                        if ev:IsA("RemoteFunction") then
                            ev:InvokeServer(bestBait)
                        elseif ev:IsA("RemoteEvent") then
                            ev:FireServer(bestBait)
                        else
                            ev:InvokeServer(bestBait)
                        end
                    end)
                end
            end)
        end

        pcall(function()
            Library:Notify({
                Title = "Tự trang bị mồi",
                Content = "Đã trang bị " .. bestBait .. " - Luck " .. bestLuck .. "%",
                Duration = 3
            })
        end)
    end

    LocalPlayer.CharacterAdded:Connect(function()
        lastEquipTime = 0
    end)
end

-------------------------------------------------------------------------------
-- Auto Claim Daily Quest (menu-based, not NPC)
-- Clicks the checkmark button on each completed daily quest task in the Quest
-- menu, then claims the Daily Reward if it's ready.
-- Works by firing the same remote that the game's own claim button fires.
-------------------------------------------------------------------------------
do
    local lastDailyAttempt = 0
    local DAILY_COOLDOWN = 30  -- seconds between full sweeps

    -- Best-effort remote discovery: the game may use different names.
    local function findRemote(names)
        for _, name in ipairs(names) do
            local r = Events:FindFirstChild(name)
            if r then return r end
        end
        for _, name in ipairs(names) do
            local r = ReplicatedStorage:FindFirstChild(name, true)
            if r then return r end
        end
        return nil
    end

    -- Try to claim via known remote patterns, then via GUI buttons.
    local function TryClaimDaily()
        -- ---- 1) RemoteEvent / RemoteFunction approach ----
        local claimRemote = findRemote({
            "ClaimDailyQuest", "ClaimDailyReward", "ClaimDaily",
            "DailyQuestClaim", "DailyRewardClaim", "ClaimDailyTask",
            "DailyQuest", "DailyReward",
        })
        if claimRemote then
            if claimRemote:IsA("RemoteFunction") then
                pcall(function() claimRemote:InvokeServer() end)
            else
                pcall(function() claimRemote:FireServer() end)
            end
        end

        -- ---- 2) GUI button approach: find the Quest menu and click all
        --         visible claim / checkmark buttons inside Daily Quest tab ----
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local mg = pg and pg:FindFirstChild("MainGui")
        local menu = mg and mg:FindFirstChild("Menu")
        local questMenu = menu and menu:FindFirstChild("Quest")
        if not questMenu then return end

        -- Navigate to the Daily Quest sub-tab if needed
        local function clickButton(container, names)
            for _, name in ipairs(names) do
                local btn = container:FindFirstChild(name, true)
                if btn and btn:IsA("GuiButton") and btn.Visible then
                    local fireClick = btn.MouseButton1Click
                    if fireClick then
                        pcall(function() fireClick:Fire() end)
                        task.wait(0.15)
                    end
                end
            end
        end

        clickButton(questMenu, { "DailyQuest", "Daily Quest", "Daily", "DailyTab" })
        task.wait(0.3)

        -- Now scan for completed task claim buttons
        local function tryClaimButtons(root)
            if not root then return end
            local claimed = 0
            for _, descendant in ipairs(root:GetDescendants()) do
                if descendant:IsA("GuiButton") and descendant.Visible then
                    local name = string.lower(descendant.Name)
                    -- Buttons named Claim, ClaimBtn, CheckMark, Done, Collect etc.
                    if name == "claim" or name == "claimbtn" or name == "claimbutton"
                        or name == "checkmark" or name == "done" or name == "collect"
                        or name == "collectbtn" or name == "completebtn"
                        or string.find(name, "claim", 1, true)
                        or string.find(name, "collect", 1, true) then
                        -- Only click if the parent frame looks like a completed task
                        -- (has a progress label showing the goal is met, or is just enabled)
                        local parent = descendant.Parent
                        local completed = false
                        if parent then
                            for _, child in ipairs(parent:GetDescendants()) do
                                if child:IsA("TextLabel") then
                                    local t = child.Text
                                    -- "10/10" or "25/25" pattern
                                    local a, b = t:match("(%d+)/(%d+)")
                                    if a and b and tonumber(a) >= tonumber(b) then
                                        completed = true
                                        break
                                    end
                                end
                            end
                        end
                        if completed or descendant.BackgroundTransparency < 0.9 then
                            pcall(function() descendant.MouseButton1Click:Fire() end)
                            claimed = claimed + 1
                            task.wait(0.2)
                        end
                    end
                end
            end
            return claimed
        end

        -- Try inside daily quest panel
        local dailyPanel = questMenu:FindFirstChild("DailyQuest", true)
            or questMenu:FindFirstChild("Daily Quest", true)
            or questMenu:FindFirstChild("Daily", true)
        tryClaimButtons(dailyPanel or questMenu)

        -- Also try to claim the Daily Reward (calendar tab)
        local rewardPanel = questMenu:FindFirstChild("DailyReward", true)
            or questMenu:FindFirstChild("Daily Reward", true)
        if rewardPanel then
            local claimBtn = rewardPanel:FindFirstChild("Claim", true)
                or rewardPanel:FindFirstChild("ClaimBtn", true)
                or rewardPanel:FindFirstChild("CollectBtn", true)
            if claimBtn and claimBtn:IsA("GuiButton") and claimBtn.Visible then
                pcall(function() claimBtn.MouseButton1Click:Fire() end)
            end
        end
    end

    -- Expose step function to the main 1-second loop
    _G.StepDailyQuest = function()
        if not Config.AutoDailyQuest then return end
        if os.clock() - lastDailyAttempt < DAILY_COOLDOWN then return end
        lastDailyAttempt = os.clock()
        task.spawn(TryClaimDaily)
    end
end



task.spawn(function()
    while task.wait(1) do
        if Config.AutoTicketQuest then
            StepSmartTicketQuest()
        end
        if type(_G.StepDailyQuest) == "function" then
            _G.StepDailyQuest()
        end
        if Config.AutoEquipBestBait then
            StepAutoEquipBestBait()
        end
    end
end)

function GetBuyableBaits()
    local list = {}
    local seen = {}
    local baitFolder = Info:FindFirstChild("Bait")
    if baitFolder then
        for _, child in ipairs(baitFolder:GetChildren()) do
            local data = GetModuleData(child)
            if data and not data.Ingredient then
                seen[child.Name] = true
                table.insert(list, child.Name)
            end
        end
    end
    local itemFolder = Info:FindFirstChild("Item")
    if itemFolder then
        for _, child in ipairs(itemFolder:GetChildren()) do
            if not seen[child.Name] then
                local data = GetModuleData(child)
                if data and data.Type == "Bait" and not data.Ingredient then
                    seen[child.Name] = true
                    table.insert(list, child.Name)
                end
            end
        end
    end
    table.sort(list)
    return list
end

end
local function GetCraftableBaits()
    local list = {}
    local baitFolder = Info:FindFirstChild("Bait")
    if baitFolder then
        for _, child in ipairs(baitFolder:GetChildren()) do
            local data = GetModuleData(child)
            if data and data.Ingredient then
                table.insert(list, child.Name)
            end
        end
    end
    table.sort(list)
    return list
end

local function GetCraftableRods()
    local list = {}
    local invFolder = Info:FindFirstChild("Inventory")
    if invFolder then
        for _, child in ipairs(invFolder:GetChildren()) do
            local data = GetModuleData(child)
            if data and data.Ingredient and data.Type == "Fishing Rod" then
                table.insert(list, child.Name)
            end
        end
    end
    table.sort(list)
    return list
end

local IslandTargets = {}

local CanonicalIslandOrder = {
    ["Beginning Isle"] = 1,
    ["Bamboo Isle"] = 2,
    ["Fallout Isle"] = 3,
    ["Sovereign Isle"] = 4,
    ["Perch Isle"] = 5,
    ["Frost Isle"] = 6,
    ["Coconut Isle"] = 7,
    ["Amber Isle"] = 8,
    ["Battlefield Isle"] = 9,
    ["Mistpeak Isle"] = 10,
    ["World Angler Isle"] = 11,
    ["Weather Isle"] = 12,
    ["Mystic Reef Isle"] = 13
}

local CanonicalIslandPower = {
    ["Beginning Isle"] = 1,
    ["Bamboo Isle"] = 19,
    ["Fallout Isle"] = 32,
    ["Sovereign Isle"] = 39,
    ["Perch Isle"] = 48,
    ["Frost Isle"] = 55,
    ["Coconut Isle"] = 65,
    ["Amber Isle"] = 75,
    ["Battlefield Isle"] = 90,
    ["Mistpeak Isle"] = 100,
    ["World Angler Isle"] = 100,
    ["Weather Isle"] = 100,
    ["Mystic Reef Isle"] = 100
}

local function GetCanonicalIslandRank(name)
    if CanonicalIslandOrder[name] then
        return CanonicalIslandOrder[name]
    end
    local lowerName = string.lower(name)
    for k, rank in pairs(CanonicalIslandOrder) do
        local lk = string.lower(k)
        if lowerName == lk or string.find(lowerName, lk, 1, true) or string.find(lk, lowerName, 1, true) then
            return rank
        end
    end
    return nil
end

local function GetCanonicalIslandPower(name)
    if CanonicalIslandPower[name] then
        return CanonicalIslandPower[name]
    end
    local lowerName = string.lower(name)
    for k, pwr in pairs(CanonicalIslandPower) do
        local lk = string.lower(k)
        if lowerName == lk or string.find(lowerName, lk, 1, true) or string.find(lk, lowerName, 1, true) then
            return pwr
        end
    end
    return nil
end

local function GetIslandList()
    local rawIslands = {}
    local seen = {}
    table.clear(IslandTargets)

    local sp = workspace:FindFirstChild("Spawnpoint")
    if not sp then return {} end

    local startPart = sp:FindFirstChild("Beginning Isle")
    local startPos = startPart and GetModelPart(startPart) and GetModelPart(startPart).Position or Vector3.zero

    local compassOrder = {}
    local compassPower = {}
    if MainGui then
        local menu = MainGui:FindFirstChild("Menu")
        local compass = menu and menu:FindFirstChild("Compass")
        local areaList = compass and compass:FindFirstChild("AreaList")
        if areaList then
            for _, item in ipairs(areaList:GetChildren()) do
                if item:IsA("GuiObject") and item:FindFirstChild("Track") then
                    local powerVal = nil
                    for _, desc in ipairs(item:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Text then
                            local m = string.match(desc.Text, "Power:%s*(%d+)")
                            if m then
                                powerVal = tonumber(m)
                                break
                            end
                        end
                    end
                    if powerVal then
                        compassPower[item.Name] = powerVal
                    end
                    local orderScore = (powerVal or 999) * 1000 + (item.LayoutOrder or 0)
                    compassOrder[item.Name] = orderScore
                end
            end
        end
    end

    for _, child in ipairs(sp:GetChildren()) do
        local part = GetModelPart(child)
        if part and not seen[child.Name] then
            seen[child.Name] = true
            local rank = GetCanonicalIslandRank(child.Name)
            local weight
            if rank then
                weight = rank
            elseif compassOrder[child.Name] then
                weight = 1000 + compassOrder[child.Name]
            else
                weight = 1e7 + (part.Position - startPos).Magnitude
            end
            local pwr = compassPower[child.Name] or GetCanonicalIslandPower(child.Name)
            table.insert(rawIslands, {
                name = child.Name,
                part = part,
                weight = weight,
                power = pwr
            })
        end
    end

    table.sort(rawIslands, function(a, b)
        if a.weight ~= b.weight then
            return a.weight < b.weight
        end
        return a.name < b.name
    end)

    local list = {}
    for _, entry in ipairs(rawIslands) do
        local label = entry.power and (entry.name .. " | " .. tostring(entry.power)) or entry.name
        IslandTargets[label] = entry.part
        IslandTargets[entry.name] = entry.part
        table.insert(list, label)
    end

    return list
end

local function TeleportToIsland(islandName)
    if not islandName or islandName == "" then return end
    if not IslandTargets[islandName] then
        GetIslandList()
    end
    local targetPart = IslandTargets[islandName]
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and targetPart then
        hrp.CFrame = targetPart.CFrame + Vector3.new(0, 5, 0)
    end
end

local function TeleportUnderIslandWater(islandName)
    if not islandName or islandName == "" then return end
    if not IslandTargets[islandName] then
        GetIslandList()
    end
    local targetPart = IslandTargets[islandName]
    if not targetPart then return end
    local char = LocalPlayer.Character or cachedChar
    local hrp = (char and char:FindFirstChild("HumanoidRootPart")) or cachedHrp
    if not hrp then return end
    local waterY = -25
    local ocean = workspace:FindFirstChild("Ocean")
    if ocean then
        for _, child in ipairs(ocean:GetChildren()) do
            if child.Name == "Water" and child:IsA("BasePart") then
                local topY = child.Position.Y + (child.Size.Y * 0.5)
                waterY = topY - 12
                break
            end
        end
    end
    local targetPos = Vector3.new(targetPart.Position.X, math.min(waterY, targetPart.Position.Y - 15), targetPart.Position.Z)
    hrp.CFrame = CFrame.new(targetPos)
end

local NPCTargets = {}

local function GetNPCList()
    local list = {}
    local seen = {}
    table.clear(NPCTargets)

    local function addNPC(name, part)
        if not name or name == "" then return end
        local norm = string.lower(string.gsub(name, "%s+", ""))
        if norm == "longdiaohai" then
            name = "Long DiaoHai"
        end
        if part and part:IsDescendantOf(workspace) then
            NPCTargets[name] = part
            NPCTargets[norm] = part
        end
        if not seen[norm] then
            seen[norm] = true
            table.insert(list, name)
        end
    end

    for _, folderName in ipairs({"Merchant", "NPCDialogue", "NPCPVP", "NPC", "BossSetUp"}) do
        local f = workspace:FindFirstChild(folderName) or ReplicatedStorage:FindFirstChild(folderName)
        if f then
            for _, child in ipairs(f:GetChildren()) do
                local name = tostring(child.Name)
                if name ~= "" and name ~= "Lamp" and name ~= "Boss" and name ~= "God" then
                    local wsFolder = workspace:FindFirstChild(folderName)
                    local liveModel = wsFolder and wsFolder:FindFirstChild(name)
                    local part = liveModel and GetModelPart(liveModel)
                    addNPC(name, part)
                elseif name == "Boss" or name == "God" then
                    for _, b in ipairs(child:GetChildren()) do
                        local bName = tostring(b.Name)
                        if bName ~= "" and bName ~= "God" then
                            local wsFolder = workspace:FindFirstChild(folderName)
                            local wsSub = wsFolder and wsFolder:FindFirstChild(name)
                            local liveSub = wsSub and wsSub:FindFirstChild(bName)
                            local part = liveSub and GetModelPart(liveSub)
                            addNPC(bName, part)
                        end
                    end
                end
            end
        end
    end

    local godFolder = workspace:FindFirstChild("God") or ReplicatedStorage:FindFirstChild("God")
    if godFolder then
        for _, child in ipairs(godFolder:GetChildren()) do
            local name = tostring(child.Name)
            if name ~= "" and name ~= "Lamp" and name ~= "God" then
                local liveModel = workspace:FindFirstChild("God") and workspace.God:FindFirstChild(name)
                local part = liveModel and GetModelPart(liveModel)
                addNPC(name, part)
            end
        end
    end
    addNPC("Long DiaoHai")

    local priorityOrder = {
        "The Shadow", "TheShadow", "Shadow", "???",
        "Taoist", "Taosi",
        "Maoshan", "Maosan",
        "Long DiaoHai", "LongDiaoHai", "Longdiaohai",
        "Enzo",
        "Blue",
        "Green",
        "Yellow",
        "Nanjiang",
        "Zeng Tianguo"
    }

    local priorityRank = {}
    for rank, name in ipairs(priorityOrder) do
        local lower = string.lower(string.gsub(name, "%s+", ""))
        if not priorityRank[lower] then
            priorityRank[lower] = rank
        end
    end

    local function getRank(name)
        local lower = string.lower(string.gsub(tostring(name), "%s+", ""))
        return priorityRank[lower] or 9999
    end

    table.sort(list, function(a, b)
        local rankA = getRank(a)
        local rankB = getRank(b)
        if rankA ~= rankB then
            return rankA < rankB
        end
        return tostring(a):lower() < tostring(b):lower()
    end)
    return list
end

-- Looser NPC lookup used when the normal lookups find nothing, mainly for the Spirit
-- (God) NPCs: matches by name, by Name attribute, by colour (Blue / Green / Yellow) and
-- by the word "spirit", then picks the one closest to the player.
local function FindLooseNPCPart(npcName, lowerNpc)
    local function norm(text)
        return string.lower((string.gsub(tostring(text or ""), "[%s_%-]+", "")))
    end
    local want = norm(npcName)
    if want == "" then
        return nil
    end
    local color
    for _, c in ipairs({ "blue", "green", "yellow" }) do
        if string.find(want, c, 1, true) then
            color = c
            break
        end
    end
    local anySpirit = string.find(want, "spirit", 1, true) ~= nil or want == "god" or want == "gods"

    local char = LocalPlayer.Character or cachedChar
    local hrp = (char and char:FindFirstChild("HumanoidRootPart")) or cachedHrp
    local best, bestDist

    local function consider(inst, inGod)
        if not (inst:IsA("Model") or inst:IsA("BasePart")) then
            return
        end
        local name = norm(inst.Name)
        local attr = norm(inst:GetAttribute("Name"))
        local hit = (name == want or attr == want)
        if not hit and color and (name == color or attr == color) then
            hit = true
        end
        if not hit and anySpirit and not color then
            hit = inGod and (inst.Parent and inst.Parent.Name == "God") or string.find(name, "spirit", 1, true) ~= nil
        end
        if not hit and #want >= 4 then
            hit = string.find(name, want, 1, true) ~= nil or (#name >= 4 and string.find(want, name, 1, true) ~= nil)
        end
        if not hit then
            return
        end
        local part = GetModelPart(inst)
        if part and part:IsDescendantOf(workspace) then
            local dist = hrp and (part.Position - hrp.Position).Magnitude or 0
            if not best or dist < bestDist then
                best, bestDist = part, dist
            end
        end
    end

    local godFolder = workspace:FindFirstChild("God")
    if godFolder then
        for _, inst in ipairs(godFolder:GetDescendants()) do
            consider(inst, true)
        end
    end
    if not best then
        for _, inst in ipairs(workspace:GetDescendants()) do
            consider(inst, false)
        end
    end
    return best
end

local function TeleportToNPC(npcName)
    if not npcName or npcName == "" then return end
    local lowerNpc = string.lower(string.gsub(tostring(npcName), "%s+", ""))
    local targetPart = nil

    if lowerNpc == "blue" or lowerNpc == "green" or lowerNpc == "yellow" then
        local godFolder = workspace:FindFirstChild("God")
        if godFolder then
            for _, child in ipairs(godFolder:GetChildren()) do
                local cLower = string.lower(string.gsub(tostring(child.Name), "%s+", ""))
                if cLower == lowerNpc then
                    targetPart = GetModelPart(child)
                    if targetPart and targetPart:IsDescendantOf(workspace) then
                        break
                    end
                end
            end
        end
        if not targetPart then
            for _, child in ipairs(workspace:GetChildren()) do
                local cLower = string.lower(string.gsub(tostring(child.Name), "%s+", ""))
                if cLower == lowerNpc then
                    local p = GetModelPart(child)
                    if p and p:IsDescendantOf(workspace) then
                        targetPart = p
                        break
                    end
                end
            end
        end
    elseif string.find(lowerNpc, "longdiaohai") or lowerNpc == "enzo" then
        local _, bossPart = FindBossTarget(string.find(lowerNpc, "longdiaohai") ~= nil)
        if bossPart and bossPart:IsDescendantOf(workspace) then
            targetPart = bossPart
        end
    end

    local candidates = {}
    if not targetPart then
        for _, folderName in ipairs({"NPC", "Merchant", "NPCDialogue", "NPCPVP", "God", "BossSetUp"}) do
            local wsFolder = workspace:FindFirstChild(folderName)
            if wsFolder then
                for _, desc in ipairs(wsFolder:GetDescendants()) do
                    if (desc:IsA("Model") or desc:IsA("BasePart")) and not desc:IsA("Folder") and (desc.Name == npcName or desc:GetAttribute("Name") == npcName) and desc.Name ~= "God" then
                        local p = GetModelPart(desc)
                        if p and p:IsDescendantOf(workspace) then
                            table.insert(candidates, { folder = folderName, part = p })
                        end
                    end
                end
            end
        end
    end
    if not targetPart and #candidates == 0 then
        local directWs = workspace:FindFirstChild(npcName)
        if directWs then
            local p = GetModelPart(directWs)
            if p and p:IsDescendantOf(workspace) then
                targetPart = p
            end
        end
    end
    if #candidates > 0 then
        if (npcName == "Maoshan" or npcName == "Taoist") and #candidates > 1 then
            local daShixiong = workspace:FindFirstChild("Da Shixiong", true)
            local dsPart = daShixiong and GetModelPart(daShixiong)
            for _, cand in ipairs(candidates) do
                if cand.folder == "NPC" then
                    targetPart = cand.part
                    break
                end
                if dsPart and (cand.part.Position - dsPart.Position).Magnitude > 15 then
                    targetPart = cand.part
                    break
                end
            end
        end
        if not targetPart then
            targetPart = candidates[1].part
        end
    end
    if not targetPart or not targetPart:IsDescendantOf(workspace) then
        local cached = NPCTargets[npcName] or NPCTargets[lowerNpc]
        if cached and cached:IsDescendantOf(workspace) then
            targetPart = cached
        end
    end
    if not targetPart or not targetPart:IsDescendantOf(workspace) then
        targetPart = FindLooseNPCPart(npcName, lowerNpc)
    end
    if not targetPart or not targetPart:IsDescendantOf(workspace) then
        pcall(function()
            Library:Notify({
                Title = "Dịch chuyển đến NPC",
                Content = npcName .. " has not spawned on the map yet!",
                Duration = 4
            })
        end)
        return
    end
    local char = LocalPlayer.Character or cachedChar
    local hrp = (char and char:FindFirstChild("HumanoidRootPart")) or cachedHrp
    if hrp and targetPart then
        hrp.CFrame = targetPart.CFrame * CFrame.new(0, 3, -4)
    end
end

local function GetPlayerList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, plr.Name)
        end
    end
    table.sort(list, function(a, b)
        return string.lower(a) < string.lower(b)
    end)
    return list
end

local function TeleportToPlayer(targetName)
    if not targetName or targetName == "" then return end
    local targetPlr = Players:FindFirstChild(targetName)
    if not targetPlr then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and (string.lower(plr.Name) == string.lower(targetName) or string.lower(plr.DisplayName) == string.lower(targetName)) then
                targetPlr = plr
                break
            end
        end
    end
    if not targetPlr then
        pcall(function()
            Library:Notify({
                Title = "Dịch chuyển người chơi",
                Content = "Người chơi " .. tostring(targetName) .. " không tìm thấy!",
                Duration = 3
            })
        end)
        return
    end

    local tChar = targetPlr.Character
    local tHrp = tChar and (tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso") or tChar:FindFirstChild("UpperTorso"))
    if not tHrp then
        pcall(function()
            Library:Notify({
                Title = "Dịch chuyển người chơi",
                Content = targetPlr.Name .. " has no character spawned!",
                Duration = 3
            })
        end)
        return
    end

    local char = LocalPlayer.Character or cachedChar
    local hrp = (char and char:FindFirstChild("HumanoidRootPart")) or cachedHrp
    if hrp then
        hrp.CFrame = tHrp.CFrame * CFrame.new(0, 2, 3)
    end
end

local KnownCodes = {
    "HWF",
    "Welcome",
    "80KLikes",
    "55MVisits",
    "VermilionBird",
    "23KActives"
}

local function RedeemAllCodes()
    task.spawn(function()
        local codeSet = {}
        for _, c in ipairs(KnownCodes) do
            codeSet[c] = true
        end
        local function scanContainer(container)
            if not container then return end
            if container:IsA("ModuleScript") then
                local ok, data = pcall(require, container)
                if ok and type(data) == "table" then
                    for k, v in pairs(data) do
                        if type(k) == "string" then codeSet[k] = true end
                        if type(v) == "string" then codeSet[v] = true end
                    end
                end
            end
            for _, child in ipairs(container:GetChildren()) do
                codeSet[child.Name] = true
                if child:IsA("StringValue") and child.Value ~= "" then
                    codeSet[child.Value] = true
                end
            end
        end
        scanContainer(Info:FindFirstChild("Code"))
        scanContainer(Info:FindFirstChild("Codes"))
        scanContainer(PlayerData:FindFirstChild("Code"))
        scanContainer(PlayerData:FindFirstChild("Codes"))

        for code in pairs(codeSet) do
            pcall(function()
                RedeemCodeEvent:FireServer(code)
            end)
            task.wait(0.15)
        end
    end)
end

local function OpenMenuFrameRemotely(frameName)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local mg = (pg and pg:FindFirstChild("MainGui")) or MainGui
    local menu = mg and mg:FindFirstChild("Menu")
    if not menu then return false end
    local target = menu:FindFirstChild(frameName)
    if not target and (string.lower(frameName) == "trait" or string.find(string.lower(frameName), "trait")) then
        for _, child in pairs(menu:GetChildren()) do
            local lName = string.lower(child.Name)
            if string.find(lName, "trait") or string.find(lName, "reroll") then
                target = child
                frameName = child.Name
                break
            end
        end
        if not target then
            for _, desc in pairs(mg:GetDescendants()) do
                if desc:IsA("Frame") then
                    local lName = string.lower(desc.Name)
                    if string.find(lName, "trait") or string.find(lName, "reroll") then
                        target = desc
                        break
                    end
                end
            end
        end
    end
    if not target then return false end
    for _, child in pairs(menu:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "Info" and child.Name ~= "Black" and child.Name ~= "Dialogue" then
            if child == target or child.Name == frameName then
                child.Visible = not child.Visible
            else
                child.Visible = false
            end
        end
    end
    if target.Parent ~= menu then
        target.Visible = not target.Visible
    end
    return target.Visible
end

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

local OriginalAtmosphere = {}
for _, child in ipairs(Lighting:GetChildren()) do
    if child:IsA("Atmosphere") then
        OriginalAtmosphere[child] = {
            Density = child.Density,
            Haze = child.Haze,
            Glare = child.Glare
        }
    end
end

local applyingLighting = false

local function ApplyLightingSettings()
    if applyingLighting then return end
    applyingLighting = true
    pcall(function()
        if Config.FullBright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        end
        if Config.NoFog then
            Lighting.FogStart = 100000
            Lighting.FogEnd = 100000
            for _, child in ipairs(Lighting:GetChildren()) do
                if child:IsA("Atmosphere") then
                    if not OriginalAtmosphere[child] then
                        OriginalAtmosphere[child] = {
                            Density = child.Density,
                            Haze = child.Haze,
                            Glare = child.Glare
                        }
                    end
                    child.Density = 0
                    child.Haze = 0
                    child.Glare = 0
                end
            end
        end
    end)
    applyingLighting = false
end

local function RestoreFullBright()
    applyingLighting = true
    pcall(function()
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end)
    applyingLighting = false
end

local function RestoreNoFog()
    applyingLighting = true
    pcall(function()
        Lighting.FogStart = OriginalLighting.FogStart
        Lighting.FogEnd = OriginalLighting.FogEnd
        for atm, orig in pairs(OriginalAtmosphere) do
            if atm and atm.Parent then
                atm.Density = orig.Density
                atm.Haze = orig.Haze
                atm.Glare = orig.Glare
            end
        end
    end)
    applyingLighting = false
end

Lighting.Changed:Connect(function()
    if Config.FullBright or Config.NoFog then
        ApplyLightingSettings()
    end
end)

ApplyLightingSettings()

-- Window built on Uzex UI. The existing JSON config
-- remains authoritative; Uzex UI keeps no settings of its own.
-- Replace this placeholder with the real UZEX Hub Discord invite when it is available.
-- The Home tab exposes this URL and copies it when its link button is pressed.
local DISCORD_INVITE = "https://discord.gg/QPux5hHVY"

local Window = Library:CreateWindow({
    Name = "UZEX Hub",
    Subtitle = "Heavyweigh Fishing",
    Icon = Library.Assets.Logo,
    Size = UDim2.fromOffset(640, 460),
    MinSize = Vector2.new(480, 360),
    SidebarWidth = 170,
    DefaultTheme = "Taichi",
    ToggleUIKeybind = Enum.KeyCode.LeftControl,
    ConfigurationSaving = { Enabled = false, FolderName = SAVE_FOLDER },
    SaveSize = false,
    Home = {
        Name = "Trang chủ",
        Title = "UZEX Hub",
        Desc = "Heavyweigh Fishing",
        Discord = DISCORD_INVITE,
        DiscordTitle = "UZEX Hub Discord",
        DiscordIcon = "message-circle",
        Features = false,
        Stats = {
            { Key = "Level", Label = "Level", Value = "-", Color = Color3.fromRGB(206, 172, 108) },
            { Key = "Balance", Label = "Balance", Value = "-", Color = Color3.fromRGB(130, 172, 178) },
            { Key = "Session", Label = "Session", Value = "-", Color = Color3.fromRGB(150, 182, 150) },
            { Key = "Rod", Label = "Rod", Value = "-", Color = Color3.fromRGB(240, 212, 60) },
            { Key = "Crystal", Label = "Crystal", Value = "-", Color = Color3.fromRGB(92, 190, 240) },
            { Key = "Essence", Label = "Essence", Value = "-", Color = Color3.fromRGB(240, 100, 190) },
            { Key = "Bait", Label = "Bait", Value = "-", Color = Color3.fromRGB(120, 200, 120) },
            { Key = "FishCaught", Label = "Fish Caught", Value = "-", Color = Color3.fromRGB(212, 170, 72) },
            { Key = "Ticket", Label = "Ticket", Value = "-", Color = Color3.fromRGB(172, 132, 222) },
            { Key = "TraitReroll", Label = "Trait Reroll", Value = "-", Color = Color3.fromRGB(232, 132, 132) },
            { Key = "HeaviestFish", Label = "Heaviest Fish", Value = "-", Color = Color3.fromRGB(236, 166, 50) },
            { Key = "BaseHP", Label = "Base HP", Value = "-", Color = Color3.fromRGB(226, 90, 90) },
        },
        StatsTitle = "Session",
    },
    Backdrop = {
        Weather = "Snow",
        Mode = "Screen",
        Tint = 0.65,
        Dim = true,
        Density = 1,
        Speed = 1,
    },
    Loading = false,
    UnsupportedExecutor = false,
    ToggleButton = false,
    OpenButton = false
})

-- Keep the draggable UZEX Hub logo; all window visibility changes
-- go through Uzex UI, including restoring a hidden window.
do
    local LogoGui = Instance.new("ScreenGui")
    LogoGui.Name = "UZEXHubLogoGui"
    LogoGui.ResetOnSpawn = false
    LogoGui.DisplayOrder = 10000
    pcall(function() LogoGui.Parent = game:GetService("CoreGui") end)
    if not LogoGui.Parent then LogoGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local LogoFrame = Instance.new("Frame")
    LogoFrame.Size = UDim2.new(0, 36, 0, 36)
    LogoFrame.Position = UDim2.new(0, 8, 0.5, -18)
    LogoFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    LogoFrame.BorderSizePixel = 0
    LogoFrame.Parent = LogoGui
    Instance.new("UICorner", LogoFrame).CornerRadius = UDim.new(0.2, 0)

    local logoStroke = Instance.new("UIStroke", LogoFrame)
    logoStroke.Thickness = 1.5
    logoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local logoGrad = Instance.new("UIGradient", logoStroke)
    logoGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 70, 70)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(244, 244, 244)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 70, 70)),
    })
    task.spawn(function() TweenService:Create(logoGrad, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 180}):Play() end)

    local LogoImg = Instance.new("ImageLabel")
    LogoImg.Size = UDim2.new(1, -4, 1, -4)
    LogoImg.Position = UDim2.new(0, 2, 0, 2)
    LogoImg.BackgroundTransparency = 1
    LogoImg.Image = Library.Assets.Logo
    LogoImg.ScaleType = Enum.ScaleType.Fit
    LogoImg.Parent = LogoFrame

    local LogoBtn = Instance.new("TextButton")
    LogoBtn.Size = UDim2.new(1, 0, 1, 0)
    LogoBtn.BackgroundTransparency = 1
    LogoBtn.Text = ""
    LogoBtn.ZIndex = 5
    LogoBtn.Parent = LogoFrame

    local logoMoved = false -- true once the logo has been dragged, so releasing it never opens the menu
    do
        local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
        LogoBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragInput, dragStart, startPos = true, input, input.Position, LogoFrame.Position
                logoMoved = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                if Vector2.new(delta.X, delta.Y).Magnitude > 8 then
                    logoMoved = true
                end
                if logoMoved then
                    LogoFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                dragInput = nil
            end
        end)
    end

    local lastToggleTime = 0
    local clickStartPos = Vector2.new()

    -- press effect: the logo squeezes on press, springs back on release, and a ring pulses out
    local logoScale = Instance.new("UIScale", LogoFrame)
    local function pulseRing()
        local ring = Instance.new("Frame")
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.new(0.5, 0, 0.5, 0)
        ring.Size = UDim2.new(1, 0, 1, 0)
        ring.BackgroundTransparency = 1
        ring.ZIndex = 4
        ring.Parent = LogoFrame
        Instance.new("UICorner", ring).CornerRadius = UDim.new(0.3, 0)
        local ringStroke = Instance.new("UIStroke", ring)
        ringStroke.Color = Color3.fromRGB(110, 170, 255)
        ringStroke.Thickness = 2
        local info = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(ring, info, { Size = UDim2.new(1.9, 0, 1.9, 0) }):Play()
        TweenService:Create(ringStroke, info, { Transparency = 1 }):Play()
        task.delay(0.42, function() ring:Destroy() end)
    end
    -- Decide "tap" vs "drag" from the whole gesture (global input events), not from the button's own
    -- InputEnded, which can fire early or never when the logo is dragged fast and slips out from under the finger.
    local pressInput, maxDist = nil, 0
    local function isPointerDown(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
    end
    local function distFromStart(input)
        return (Vector2.new(input.Position.X, input.Position.Y) - clickStartPos).Magnitude
    end
    LogoBtn.InputBegan:Connect(function(input)
        if isPointerDown(input) then
            pressInput = input
            clickStartPos = Vector2.new(input.Position.X, input.Position.Y)
            maxDist = 0
            TweenService:Create(logoScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.82 }):Play()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if pressInput and (input == pressInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = distFromStart(input)
            if d > maxDist then maxDist = d end
            if maxDist >= 10 then logoMoved = true end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if pressInput and isPointerDown(input) and (input == pressInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
            pressInput = nil
            local d = distFromStart(input)
            if d > maxDist then maxDist = d end
            local now = tick()
            TweenService:Create(logoScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            if not logoMoved and maxDist < 10 and now - lastToggleTime >= 0.12 then
                lastToggleTime = now
                pulseRing()
                Window:Toggle()
            end
        end
    end)
    Window.Gui.Destroying:Connect(function()
        LogoGui:Destroy()
    end)
end

local Tabs = {
    Main = Window:CreateTab({ Name = "Chính", Icon = "home" }),
    LimitedEvent = Window:CreateTab({ Name = "Sự kiện giới hạn", Icon = "gift" }),
    Teleport = Window:CreateTab({ Name = "Dịch chuyển", Icon = "map-pin" }),
    Hop = Window:CreateTab({ Name = "Chuyển server", Icon = "server" }),
    Shop = Window:CreateTab({ Name = "Cửa hàng", Icon = "shopping-cart" }),
    Upgrade = Window:CreateTab({ Name = "Nâng cấp", Icon = "arrow-up" }),
    Misc = Window:CreateTab({ Name = "Khác", Icon = "layers" }),
    Settings = Window:CreateTab({ Name = "Cài đặt", Icon = "settings" })
}

-------------------------------------------------------------------------------
-- Hop Server tab: God Spirit / Maoshan / Taoist (ported from NNVN Server Hop)
-------------------------------------------------------------------------------
do
    local bootAt = os.clock()
    local hopping = false
    local lastHop = 0
    local HOP_FILE = "UZEXHub/server-hop-visited.json"

    local function Notify(title, content, duration)
        pcall(function()
            Library:Notify({ Title = title, Content = content, Duration = duration or 3 })
        end)
    end

    local function Norm(text)
        return (string.lower(tostring(text or "")):gsub("[_%-]+", " "):gsub("%s+", " "))
    end

    ---------------------------------------------------------------------------
    -- detection
    ---------------------------------------------------------------------------
    local trackerPaths = {
        taoist = { { "NPC", "Function", "Taoist" }, { "NPC", "Taoist" }, { "world", "NPC", "Taoist" } },
        maoshan = { { "NPC", "Function", "Maoshan" }, { "NPC", "Maoshan" }, { "world", "NPC", "Maoshan" } },
    }
    local trackerNames = {
        taoist = { taoist = true },
        maoshan = { maoshan = true, ["mao shan"] = true },
    }
    local cache, cacheAt = {}, {}

    local function FindAtPath(path)
        local node = workspace
        for _, name in ipairs(path) do
            node = node and node:FindFirstChild(name)
            if not node then return nil end
        end
        return node
    end

    local function FindTracker(kind)
        local now = os.clock()
        if cacheAt[kind] and now - cacheAt[kind] < 10 then
            local hit = cache[kind]
            if hit == false then return nil end
            if hit and hit.Parent then return hit end
        end
        local found
        for _, path in ipairs(trackerPaths[kind]) do
            found = FindAtPath(path)
            if found then break end
        end
        if not found then
            local roots = {}
            local npc = workspace:FindFirstChild("NPC")
            if npc then table.insert(roots, npc) end
            local map = workspace:FindFirstChild("Map") or workspace:FindFirstChild("World")
            if map then table.insert(roots, map) end
            if #roots == 0 then table.insert(roots, workspace) end
            for _, root in ipairs(roots) do
                for _, inst in ipairs(root:GetDescendants()) do
                    if trackerNames[kind][Norm(inst.Name)] then
                        found = inst
                        break
                    end
                end
                if found then break end
            end
        end
        cache[kind] = found or false
        cacheAt[kind] = now
        return found
    end

    local godCount, godAt = 0, 0
    local function GodSpiritCount()
        local now = os.clock()
        if now - godAt < 10 then return godCount end
        local count = 0
        local folders = { workspace:FindFirstChild("God") }
        local npc = workspace:FindFirstChild("NPC")
        if npc then table.insert(folders, npc:FindFirstChild("God")) end
        for _, folder in pairs(folders) do
            if folder then
                count = math.max(count, #folder:GetChildren())
            end
        end
        if count == 0 then
            local roots = {}
            if npc then table.insert(roots, npc) end
            local chars = workspace:FindFirstChild("Characters")
            if chars then table.insert(roots, chars) end
            if #roots == 0 then table.insert(roots, workspace) end
            for _, root in ipairs(roots) do
                for _, inst in ipairs(root:GetDescendants()) do
                    local n = Norm(inst.Name)
                    if n == "god spirit" or n == "spirit god" then
                        count = count + 1
                    end
                end
            end
        end
        godCount, godAt = count, now
        return count
    end

    local Checks = {
        ["God Spirit"] = function() return GodSpiritCount() > 0 end,
        ["Maoshan"] = function() return FindTracker("maoshan") ~= nil end,
        ["Taoist"] = function() return FindTracker("taoist") ~= nil end,
    }
    local ConfigKey = {
        ["God Spirit"] = "AutoHopGodSpirit",
        ["Maoshan"] = "AutoHopMaoshan",
        ["Taoist"] = "AutoHopTaoist",
    }
    local FlagName = {
        ["God Spirit"] = "AutoHopGodSpiritToggle",
        ["Maoshan"] = "AutoHopMaoshanToggle",
        ["Taoist"] = "AutoHopTaoistToggle",
    }
    local Order = { "God Spirit", "Maoshan", "Taoist" }

    ---------------------------------------------------------------------------
    -- hop to a fresh public server (never the same one twice within the hour)
    ---------------------------------------------------------------------------
    local function LoadVisited()
        local data = { hour = os.date("!*t").hour, ids = {} }
        pcall(function()
            if isfile and isfile(HOP_FILE) then
                local dec = HttpService:JSONDecode(readfile(HOP_FILE))
                if type(dec) == "table" and dec.hour == data.hour and type(dec.ids) == "table" then
                    data = dec
                end
            end
        end)
        return data
    end

    local function SaveVisited(data)
        pcall(function()
            if writefile then
                writefile(HOP_FILE, HttpService:JSONEncode(data))
            end
        end)
    end

    local function HopServer()
        local placeId = game.PlaceId
        local visited = LoadVisited()
        local seen = {}
        for _, id in ipairs(visited.ids) do seen[tostring(id)] = true end
        local requestFn = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        local cursor = ""
        for _ = 1, 8 do
            local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then url = url .. "&cursor=" .. cursor end
            local raw
            if requestFn then
                local ok, res = pcall(requestFn, { Url = url, Method = "GET" })
                raw = ok and res and res.Body or nil
            else
                local ok, res = pcall(game.HttpGet, game, url)
                raw = ok and res or nil
            end
            local data
            if raw then pcall(function() data = HttpService:JSONDecode(raw) end) end
            if type(data) ~= "table" or type(data.data) ~= "table" then
                task.wait(1)
            else
                for _, server in ipairs(data.data) do
                    local id = tostring(server.id)
                    if id ~= game.JobId and not seen[id]
                        and (tonumber(server.playing) or 0) < (tonumber(server.maxPlayers) or 0) then
                        table.insert(visited.ids, id)
                        SaveVisited(visited)
                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(placeId, id, LocalPlayer)
                        end)
                        task.wait(4)
                        return true
                    end
                end
                if data.nextPageCursor and data.nextPageCursor ~= "" then
                    cursor = data.nextPageCursor
                else
                    break
                end
            end
        end
        return false
    end

    ---------------------------------------------------------------------------
    -- UI
    ---------------------------------------------------------------------------
    local status = Tabs.Hop:CreateStatGrid({
        Columns = 3,
        Items = {
            { Key = "God Spirit", Label = "God Spirit", Value = "-" },
            { Key = "Maoshan", Label = "Maoshan", Value = "-" },
            { Key = "Taoist", Label = "Taoist", Value = "-" },
        },
    })

    local function RefreshStatus()
        for _, name in ipairs(Order) do
            local ok, found = pcall(Checks[name])
            status:Set(name, ok and (found and "🟢 Online" or "🔴 Offline") or "-")
        end
    end

    Tabs.Hop:CreateToggle({
        Flag = "HopAutoCheckToggle",
        Name = "Tự động kiểm tra trạng thái",
        CurrentValue = Config.HopAutoCheck,
        Callback = function(Value)
            Config.HopAutoCheck = Value
            SaveConfig()
        end
    })

    for _, name in ipairs(Order) do
        Tabs.Hop:CreateSection(name)

        Tabs.Hop:CreateToggle({
            Flag = FlagName[name],
            Name = "Tự động chuyển server tìm " .. name,
            CurrentValue = Config[ConfigKey[name]],
            Callback = function(Value)
                Config[ConfigKey[name]] = Value
                SaveConfig()
            end
        })

        Tabs.Hop:CreateButton({
            Name = "Chuyển server ngay (" .. name .. ")",
            Callback = function()
                task.spawn(function()
                    local ok, found = pcall(Checks[name])
                    if ok and found then
                        Notify(name, name .. " đã có trong server này!", 3)
                        return
                    end
                    Notify(name, "Không có " .. name .. ". Đang chuyển server...", 3)
                    if not HopServer() then
                        Notify(name, "Không tìm được server phù hợp, thử lại sau.", 4)
                    end
                end)
            end
        })
    end

    ---------------------------------------------------------------------------
    -- background loops
    ---------------------------------------------------------------------------
    task.spawn(function()
        while true do
            task.wait(4)
            if Config.HopAutoCheck then
                pcall(RefreshStatus)
            end
        end
    end)

    -- Auto hop keeps going across servers (the saved flags + Auto Execute restart it)
    task.spawn(function()
        while true do
            task.wait(2)
            local wanted = {}
            for _, name in ipairs(Order) do
                if Config[ConfigKey[name]] then
                    table.insert(wanted, name)
                end
            end
            if #wanted > 0 and not hopping and os.clock() - bootAt > 12
                and LocalPlayer.Character and game:IsLoaded() then
                local foundName
                for _, name in ipairs(wanted) do
                    local ok, found = pcall(Checks[name])
                    if ok and found then
                        foundName = name
                        break
                    end
                end
                if foundName then
                    for _, name in ipairs(Order) do
                        Config[ConfigKey[name]] = false
                        local flag = Library.Flags[FlagName[name]]
                        if flag and flag.Set then
                            pcall(flag.Set, flag, false, true)
                        end
                    end
                    SaveConfig()
                    pcall(RefreshStatus)
                    Notify(foundName .. " Found!", "Đã dừng tự động chuyển server - " .. foundName .. " đang ở đây!", 6)
                elseif os.clock() - lastHop > 10 then
                    lastHop = os.clock()
                    hopping = true
                    Notify("Hop Server", "Không thấy " .. table.concat(wanted, " / ") .. ". Đang chuyển server...", 2)
                    task.spawn(function()
                        pcall(HopServer)
                        task.wait(8)
                        hopping = false
                    end)
                end
            end
        end
    end)

    ---------------------------------------------------------------------------
    -- Weather hop: keeps changing server until the chosen weather is active
    ---------------------------------------------------------------------------
    local function GetWeatherList()
        local list = {}
        pcall(function()
            local clientMod = ReplicatedStorage:FindFirstChild("ClientModule")
            local wScript = clientMod and clientMod:FindFirstChild("Weather")
            local wFolder = wScript and wScript:FindFirstChild("Weather")
            if not wFolder then return end
            for _, child in ipairs(wFolder:GetChildren()) do
                if child:IsA("ModuleScript") or child:IsA("Folder") then
                    local lower = string.lower(child.Name)
                    if lower ~= "clear" and not string.find(lower, "blood", 1, true) then
                        table.insert(list, child.Name)
                    end
                end
            end
        end)
        if #list == 0 then
            list = { "Rain", "Thunderstorm", "Snow", "Fog", "Windy", "Cloudy", "Solar Eclipse" }
        else
            table.sort(list)
        end
        return list
    end

    local function CleanWeatherText(text)
        text = tostring(text or ""):gsub("<[^>]+>", "")
        text = text:gsub("^%s*[Ww]eather%s*:?%s*", "")
        return (text:gsub("^%s+", ""):gsub("%s+$", ""))
    end

    -- Reads the weather from every place the game exposes it (workspace attribute
    -- and the on-screen Weather label). The two can use different wording.
    local function ReadWeatherSources()
        local sources = {}
        local attr = workspace:GetAttribute("Weather")
        if attr ~= nil and tostring(attr) ~= "" then
            table.insert(sources, CleanWeatherText(attr))
        end
        pcall(function()
            local gui = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
            local i1 = gui and gui:FindFirstChild("Info")
            local i2 = i1 and i1:FindFirstChild("Info")
            local w = i2 and i2:FindFirstChild("Weather")
            local v = w and w:FindFirstChild("Value")
            if not v then return end
            local raw
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                raw = v.Text
            else
                raw = v.Value
            end
            local text = CleanWeatherText(raw)
            if text ~= "" and not table.find(sources, text) then
                table.insert(sources, text)
            end
        end)
        return sources
    end

    local function NormWeather(text)
        return (string.lower(tostring(text or "")):gsub("[^%a]", ""))
    end

    -- "Rain" matches "Rainy", "Snow" matches "Snowy", "Fog" matches "Foggy", ...
    local function WeatherMatches(sources, target)
        local want = NormWeather(target)
        if #want < 3 then return false end
        for _, source in ipairs(sources) do
            local have = NormWeather(source)
            if #have >= 3 and (have == want or string.find(have, want, 1, true) or string.find(want, have, 1, true)) then
                return true
            end
        end
        return false
    end

    local function StopWeatherHop(message)
        Config.AutoHopWeather = false
        SaveConfig()
        local flag = Library.Flags["AutoHopWeatherToggle"]
        if flag and flag.Set then
            pcall(flag.Set, flag, false, true)
        end
        Notify("Hop thời tiết", message, 6)
    end

    Tabs.Hop:CreateSection("Hop thời tiết")

    Tabs.Hop:CreateToggle({
        Flag = "AutoHopWeatherToggle",
        Name = "Tự động chuyển server tìm thời tiết",
        CurrentValue = Config.AutoHopWeather,
        Callback = function(Value)
            Config.AutoHopWeather = Value
            SaveConfig()
        end
    })

    Tabs.Hop:CreateDropdown({
        Flag = "SelectWeatherDropdown",
        Name = "Chọn thời tiết",
        Options = GetWeatherList(),
        CurrentOption = tostring(Config.SelectedWeather or "Thunderstorm"),
        MultipleOptions = false,
        AllowNone = false,
        Callback = function(Value)
            if type(Value) == "table" then Value = Value[1] end
            Config.SelectedWeather = Value or "Thunderstorm"
            SaveConfig()
        end
    })

    Tabs.Hop:CreateSlider({
        Flag = "HopWeatherDelaySlider",
        Name = "Độ trễ chuyển server",
        CurrentValue = math.clamp(tonumber(Config.HopWeatherDelay) or 5, 5, 20),
        Range = {5, 20},
        Increment = 1,
        Callback = function(Value)
            Config.HopWeatherDelay = math.clamp(tonumber(Value) or 5, 5, 20)
            SaveConfig()
        end
    })

    task.spawn(function()
        while true do
            task.wait(2)
            if Config.AutoHopWeather and not hopping and os.clock() - bootAt > 6
                and LocalPlayer.Character and game:IsLoaded() then
                local sources = ReadWeatherSources()
                local cur = table.concat(sources, " / ")
                local target = tostring(Config.SelectedWeather or "")
                if cur == "" and os.clock() - bootAt < 20 then
                    -- weather value has not loaded yet, check again
                elseif WeatherMatches(sources, target) then
                    StopWeatherHop("Đã tìm thấy thời tiết " .. cur .. "! Đã dừng tự động chuyển server.")
                elseif os.clock() - lastHop > 10 then
                    lastHop = os.clock()
                    hopping = true
                    local delaySec = math.clamp(tonumber(Config.HopWeatherDelay) or 5, 5, 20)
                    Notify("Hop thời tiết", "Hiện tại: " .. (cur ~= "" and cur or "Unknown")
                        .. ". Mục tiêu: " .. target .. ". Chuyển server sau " .. delaySec .. "s...", 5)
                    task.spawn(function()
                        task.wait(delaySec)
                        if Config.AutoHopWeather then
                            pcall(HopServer)
                        end
                        task.wait(8)
                        hopping = false
                    end)
                end
            end
        end
    end)

    ---------------------------------------------------------------------------
    -- Join / copy Job ID
    ---------------------------------------------------------------------------
    Tabs.Hop:CreateSection("Job ID")

    local targetJobId = ""

    Tabs.Hop:CreateInput({
        Flag = "JobIdInput",
        Name = "Job ID",
        Placeholder = "Nhập Job ID...",
        Finished = false,
        Callback = function(Value)
            targetJobId = (tostring(Value or ""):gsub("%s+", ""))
        end
    })

    Tabs.Hop:CreateButton({
        Name = "Vào server theo Job ID",
        Callback = function()
            if targetJobId == "" then
                Notify("Job ID", "Hãy nhập Job ID hợp lệ.", 3)
                return
            end
            Notify("Job ID", "Đang vào server " .. targetJobId .. "...", 3)
            task.wait(0.3)
            local ok = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, targetJobId, LocalPlayer)
            end)
            if not ok then
                Notify("Job ID", "Không vào được server này.", 4)
            end
        end
    })

    Tabs.Hop:CreateButton({
        Name = "Sao chép Job ID hiện tại",
        Callback = function()
            local jobId = tostring(game.JobId or "")
            local copied = false
            pcall(function()
                if setclipboard then
                    setclipboard(jobId)
                    copied = true
                elseif toclipboard then
                    toclipboard(jobId)
                    copied = true
                elseif syn and syn.write_clipboard then
                    syn.write_clipboard(jobId)
                    copied = true
                end
            end)
            Notify("Job ID", (copied and "Đã sao chép: " or "Job ID: ") .. jobId, 4)
        end
    })
end


Tabs.Settings:CreateSection("Language / Ngôn ngữ")
local LanguageDropdownObj
LanguageDropdownObj = Tabs.Settings:CreateDropdown({
    Flag = "LanguageDropdown",
    Name = "Language / Ngôn ngữ",
    Options = {"Tiếng Việt", "English"},
    CurrentOption = Library.Language,
    MultipleOptions = false,
    AllowNone = false,
    Callback = function(Value)
        if type(Value) == "table" then Value = Value[1] end
        Library:SetLanguage(Value)
        Config.Language = Library.Language
        SaveConfig()
        task.defer(function()
            if LanguageDropdownObj then
                LanguageDropdownObj:Set(Library.Language, true)
            end
        end)
    end
})

local FlyToggleObj, NoclipToggleObj

local lastFlyToggleTime = 0
local function toggleFly()
    local now = tick()
    if now - lastFlyToggleTime < 0.25 then return end
    lastFlyToggleTime = now
    if FlyToggleObj then
        FlyToggleObj:Set(not Config.FlyEnabled)
    else
        Config.FlyEnabled = not Config.FlyEnabled
        SaveConfig()
        if Config.FlyEnabled then startFly() else stopFly() end
    end
end

local lastNoclipToggleTime = 0
local function toggleNoclip()
    local now = tick()
    if now - lastNoclipToggleTime < 0.25 then return end
    lastNoclipToggleTime = now
    if NoclipToggleObj then
        NoclipToggleObj:Set(not Config.NoclipEnabled)
    else
        Config.NoclipEnabled = not Config.NoclipEnabled
        SaveConfig()
    end
end

Tabs.Main:CreateSection("Bán cá")

Tabs.Main:CreateToggle({
    Flag = "AutoSellToggle",
    Name = "Tự động bán cá",
    CurrentValue = Config.AutoSell,
    Callback = function(Value)
        Config.AutoSell = Value
        if not Value then
            lastSellTime = 0
        end
        SaveConfig()
    end
})

Tabs.Main:CreateDropdown({
    Flag = "AutoSellMethodDropdown",
    Name = "Cách bán cá #1",
    Options = {"Spam", "When full"},
    CurrentOption = Config.AutoSellMethod or "Spam",
    MultipleOptions = false,
    AllowNone = false,
    Callback = function(Value)
        Config.AutoSellMethod = Value or "Spam"
        SaveConfig()
    end
})

Tabs.Main:CreateSection("Nhiệm vụ hàng ngày")

Tabs.Main:CreateToggle({
    Flag = "AutoDailyQuestToggle",
    Name = "Tự nhận nhiệm vụ hàng ngày",
    Description = "Tự tương tác với NPC nhiệm vụ hàng ngày và nhận thưởng",
    CurrentValue = Config.AutoDailyQuest,
    Callback = function(Value)
        Config.AutoDailyQuest = Value
        SaveConfig()
    end
})

Tabs.Main:CreateSection("Nhiệm vụ vé tự động")

Tabs.Main:CreateToggle({
    Flag = "AutoTicketQuestToggle",
    Name = "Tự nhận vé nhiệm vụ",
    CurrentValue = Config.AutoTicketQuest,
    Callback = function(Value)
        Config.AutoTicketQuest = Value
        if not Value then
            lastTicketQuestTime = 0
        end
        SaveConfig()
    end
})

Tabs.Main:CreateDropdown({
    Flag = "TicketQuestModeDropdown",
    Name = "Chế độ nhiệm vụ",
    Options = {"Hard", "Easy"},
    CurrentOption = Config.TicketQuestMode or "Hard",
    MultipleOptions = false,
    AllowNone = false,
    Callback = function(Value)
        Config.TicketQuestMode = Value or "Hard"
        SaveConfig()
    end
})

-------------------------------------------------------------------------------
-- Dump Guy (ported from NNVN): hand in a fish of at least 2,000,000 kg
-------------------------------------------------------------------------------
do
    local MAX_LIMIT = 2000000
    local DUMB_GUY = "Dumb guy"

    local function Notify(content, duration)
        pcall(function()
            Library:Notify({ Title = "Dump Guy", Content = content, Duration = duration or 4 })
        end)
    end

    local lastWarn = 0
    local function Warn(content)
        if os.clock() - lastWarn < 3 then return end
        lastWarn = os.clock()
        Notify(content, 4)
    end

    local function GetSlot()
        return math.clamp(math.floor(tonumber(Config.DumpGuyHotbarSlot) or 4), 1, 10)
    end

    local function WeightOf(name)
        local text = tostring(name or ""):match("|%s*([%d,.]+)%s*$")
        if not text then return nil end
        return tonumber((text:gsub(",", "")))
    end

    local function SlotState(slot)
        local hotbar = PlayerData:FindFirstChild("Hotbar")
        local entry = hotbar and hotbar:FindFirstChild(tostring(slot))
        local valueName = entry and entry:FindFirstChild("ValueName")
        local quantity = entry and entry:FindFirstChild("Quantity")
        if not valueName or not quantity then return nil end
        return {
            Name = tostring(valueName.Value or ""),
            Quantity = tonumber(quantity.Value) or 0,
            Weight = WeightOf(valueName.Value),
        }
    end

    local function FishOverWeight(limit)
        local list = {}
        local inventory = PlayerData:FindFirstChild("Inventory")
        if not inventory then return list end
        for _, entry in ipairs(inventory:GetChildren()) do
            local weight = WeightOf(entry.Name)
            if entry:IsA("NumberValue") and weight and limit < weight and entry.Value > 0 then
                table.insert(list, { Name = entry.Name, Weight = weight })
            end
        end
        table.sort(list, function(a, b) return a.Weight > b.Weight end)
        return list
    end

    local function MoveFishToInventory(slot)
        local moveItems = Events:FindFirstChild("MoveItems")
        if not moveItems then return false end
        if not pcall(function() moveItems:FireServer("Hotbar", tonumber(slot)) end) then
            return false
        end
        for _ = 1, 20 do
            task.wait(0.1)
            local state = SlotState(slot)
            if state and state.Quantity <= 0 and (state.Name == "" or state.Name == "Inventory") then
                return true
            end
        end
        return false
    end

    local function MoveFishToHotbar(name, slot)
        local moveItems = Events:FindFirstChild("MoveItems")
        if not moveItems or not name or not slot then return false end
        if not pcall(function() moveItems:FireServer("Inventory", name, slot) end) then
            return false
        end
        for _ = 1, 10 do
            task.wait(0.15)
            local hotbar = PlayerData:FindFirstChild("Hotbar")
            local entry = hotbar and hotbar:FindFirstChild(slot)
            local valueName = entry and entry:FindFirstChild("ValueName")
            local quantity = entry and entry:FindFirstChild("Quantity")
            if valueName and quantity and tostring(valueName.Value) == tostring(name)
                and (tonumber(quantity.Value) or 0) > 0 then
                return true
            end
        end
        return false
    end

    local function HoldingFish()
        local char = LocalPlayer.Character
        return char ~= nil and char:GetAttribute("Type") == "Fish"
    end

    local function SelectSlot(slot, expectedName)
        if not pcall(function() ToggleHotbar:InvokeServer(tonumber(slot), nil) end) then
            return false
        end
        for _ = 1, 12 do
            task.wait(0.1)
            if HoldingFish() then
                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                if not tool or not expectedName or tool.Name == expectedName
                    or tool:GetAttribute("ValueName") == expectedName
                    or tostring(tool:GetAttribute("FishName") or "") == expectedName then
                    return true
                end
            end
        end
        return false
    end

    local function FindDumbGuy()
        local npc = workspace:FindFirstChild("NPC")
        local functions = npc and npc:FindFirstChild("Function")
        local direct = functions and functions:FindFirstChild(DUMB_GUY)
        if direct then return direct end
        local function norm(text)
            return string.lower((tostring(text or ""):gsub("[%s_%-]+", "")))
        end
        local wanted = { dumbguy = true, dumpguy = true }
        for _, root in ipairs({ npc, workspace }) do
            if root then
                for _, inst in ipairs(root:GetDescendants()) do
                    if (inst:IsA("Model") or inst:IsA("BasePart")) and wanted[norm(inst.Name)] then
                        return inst
                    end
                end
            end
        end
        return nil
    end

    local function TeleportToDumpGuy()
        local npc = FindDumbGuy()
        local part = npc and GetModelPart(npc)
        local char = LocalPlayer.Character
        local hrp = (char and char:FindFirstChild("HumanoidRootPart")) or cachedHrp
        if not part or not hrp then return false end
        hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.4)
        return true
    end

    local function InteractWithDumpGuy()
        local choose = Events:FindFirstChild("ChooseDialogueOption")
        if not choose then
            Notify("Remote ChooseDialogueOption not found!", 3)
            return false
        end
        local npc = FindDumbGuy()
        if not npc then
            Notify("Dumb guy not found in workspace!", 3)
            return false
        end
        if pcall(function() choose:FireServer(DUMB_GUY, 1, "GiveFish", { npc }) end) then
            return true
        end
        local prompt = npc:FindFirstChild("ProximityPrompt", true)
        if prompt and fireproximityprompt then
            pcall(fireproximityprompt, prompt)
            return true
        end
        return false
    end

    -- returns ok, fishName | errorMessage
    local function GiveFish()
        local slot = GetSlot()
        local slotText = tostring(slot)
        local state = SlotState(slot)
        if state and state.Weight and MAX_LIMIT <= state.Weight then
            if not SelectSlot(slotText) then
                return false, "Could not equip fish from hotbar slot " .. slotText
            end
            task.wait(0.3)
            if not HoldingFish() then return false, "Not holding a fish!" end
            if not TeleportToDumpGuy() then return false, "Could not reach Dump Guy." end
            if not InteractWithDumpGuy() then return false, "Could not interact with Dump Guy." end
            return true, state.Name ~= "" and state.Name or "Fish"
        end
        if state and state.Name ~= "" and state.Name ~= "Inventory" then
            MoveFishToInventory(slot)
            task.wait(0.3)
        end
        local list = FishOverWeight(MAX_LIMIT - 1)
        if #list == 0 then
            return false, "No fish at least 2,000,000 kg found."
        end
        local fish = list[1]
        if not MoveFishToHotbar(fish.Name, slotText) then
            return false, "Could not move " .. fish.Name .. " to hotbar"
        end
        task.wait(0.3)
        if not SelectSlot(slotText, fish.Name) then
            return false, "Could not equip " .. fish.Name
        end
        task.wait(0.3)
        if not HoldingFish() then return false, "Not holding a fish!" end
        if not TeleportToDumpGuy() then return false, "Could not reach Dump Guy." end
        if not InteractWithDumpGuy() then return false, "Could not interact with Dump Guy." end
        return true, fish.Name
    end

    task.spawn(function()
        while true do
            if Config.AutoGiveFish then
                local ok, success, message = pcall(GiveFish)
                if ok and success then
                    task.wait(1)
                elseif ok and message and not string.find(message, "No fish at least", 1, true) then
                    Warn(message)
                end
            end
            task.wait(1)
        end
    end)

    Tabs.Main:CreateSection("Dump Guy")

    Tabs.Main:CreateParagraph({
        Title = "Give fish at least 2,000,000 kg",
        Content = "Uses an eligible fish already in the selected slot, or moves a fish of at least 2M kg from the inventory. Default: slot 4."
    })

    Tabs.Main:CreateSlider({
        Flag = "DumpGuyHotbarSlotSlider",
        Name = "Hotbar slot for fish",
        CurrentValue = GetSlot(),
        Range = {1, 10},
        Increment = 1,
        Callback = function(Value)
            Config.DumpGuyHotbarSlot = math.clamp(math.floor(tonumber(Value) or 4), 1, 10)
            SaveConfig()
        end
    })

    Tabs.Main:CreateButton({
        Name = "Give 1 Fish >= 2M kg",
        Callback = function()
            task.spawn(function()
                local ok, success, message = pcall(GiveFish)
                if ok and success then
                    Notify("Fish removed from hotbar: " .. tostring(message), 4)
                else
                    Notify(tostring(ok and message or "Could not give fish."), 4)
                end
            end)
        end
    })

    Tabs.Main:CreateButton({
        Name = "Teleport to Dump Guy",
        Callback = function()
            task.spawn(function()
                Notify(TeleportToDumpGuy() and "Teleported to Dump Guy." or "Dump Guy NPC was not found.", 3)
            end)
        end
    })

    Tabs.Main:CreateToggle({
        Flag = "AutoGiveFishToggle",
        Name = "Auto Give Fish >= 2M kg",
        CurrentValue = Config.AutoGiveFish,
        Callback = function(Value)
            Config.AutoGiveFish = Value
            SaveConfig()
        end
    })
end

-------------------------------------------------------------------------------
-- Limited Event tab: Auto Give Fish to Noro Derasu (ported from star.lua)
-------------------------------------------------------------------------------
do
    local BOSS_FALLBACK = {
        "Azure Carp",
        "Jiaolong Dragonfish",
        "Chainbound Shark",
        "Adult Jiaolong Dragonfish",
        "Elder Chainbound Shark",
        "Elder Jiaolong Dragonfish",
        "Trueform Jiaolongfish",
        "Trueform Perch",
        "Ascended Perch",
        "Primordial Kunfish",
        "Primordial Kunfish Overlord",
        "Warbringer Shark",
        "Dreadscale Grouper",
        "Mutated Koid Whale",
        "Radiant Goldfish",
        "Serpent Fish",
        "Dreadmare Eel",
        "Chromatic Koi",
        "Toxic Chromatic Koi",
        "Crimson Bream Sovereign",
        "Silver Bream Sovereign",
        "Golden Guardian Fish",
        "Colossal Tigerfish",
        "Mountain Fish",
        "Tiger Mirefish",
        "Octoparasitic Fish",
        "Dark kingfish",
        "Golden Shark",
        "Darkness Shark",
        "White Heaven Kunfish",
        "Crimson Bonefiend",
        "Dragonfish Devourer",
        "Yangfish Sovereign",
        "Yangfish Empress",
        "Yinfish Sovereign",
        "Demon Bladefish",
        "Apollo Swordfish",
        "Killer Sawshark",
        "Thunder Fish",
        "Wind Fish",
        "Intuitive Fish King",
        "Aquatic Fish",
        "Flame Fish",
        "Verdant Alligator Gar",
        "Verdant Grouper",
        "Verdant Bonefang",
        "Scarlet Fish",
        "Mountain Dragonwhale",
        "Flying Fish Emperor",
        "Crimson Bonefang",
        "Elder ScarletFish",
        "Colossal Bull Shark",
        "Flying Fish Empress",
        "Draconic Koi",
        "Tigerfang Whale",
        "Golden Dragonfish",
        "Crimson Electric Eel",
        "Reborn Puffer Beast",
        "Heavenpiercer Turtle",
        "Sanguine Fish",
        "Frost Kingfish",
        "Dark Lionfish",
        "Rainbow Dragonfish",
        "Mirage lanternfish",
        "Nameless Octoparasite",
        "Frost QueenFish",
        "Thunder Bull Shark",
        "Black Tortoise Bloodline",
        "Vermilion Birdblood"
    }

    local function trim(s)
        return (tostring(s or ""):gsub("^%s*(.-)%s*$", "%1"))
    end

    local function GetFishNameFromItem(itemName)
        if not itemName or itemName == "" then return "" end
        local clean = string.split(tostring(itemName), "| Favorite")[1]
        clean = string.split(clean, "|")[1]
        clean = trim(clean)
        local clientMod = ReplicatedStorage:FindFirstChild("ClientModule")
        local gs = clientMod and clientMod:FindFirstChild("GameService")
        if gs then
            local ok, res = pcall(function()
                local mod = require(gs)
                return mod and mod.DestringFish and mod.DestringFish(clean)
            end)
            if ok and res and res.FishName then
                return res.FishName
            end
        end
        local parts = string.split(clean, ",")
        if #parts >= 1 and parts[1] ~= "" then
            return parts[1]
        end
        return clean
    end

    local function GetEventBossList()
        local list, seen = {}, {}
        pcall(function()
            local inventory = Info:FindFirstChild("Inventory")
            if not inventory then return end
            for _, child in ipairs(inventory:GetChildren()) do
                if not seen[child.Name] then
                    local data = GetModuleData(child)
                    if data and data.Boss == true then
                        seen[child.Name] = true
                        table.insert(list, child.Name)
                    end
                end
            end
        end)
        if #list == 0 then
            for _, name in ipairs(BOSS_FALLBACK) do
                if not seen[name] then
                    seen[name] = true
                    table.insert(list, name)
                end
            end
        end
        table.sort(list)
        return list
    end

    local bossListItems = GetEventBossList()

    local function ExtractSelected(raw)
        local selected = {}
        if type(raw) == "table" then
            for k, v in pairs(raw) do
                local name
                if type(k) == "string" and v == true then
                    name = k
                elseif type(v) == "string" and v ~= "" then
                    name = v
                end
                if name and table.find(bossListItems, name) and not table.find(selected, name) then
                    table.insert(selected, name)
                end
            end
        elseif type(raw) == "string" and table.find(bossListItems, raw) then
            table.insert(selected, raw)
        end
        return selected
    end
    Config.AutoGiveEventFishTarget = ExtractSelected(Config.AutoGiveEventFishTarget)

    local function GetTargetSet()
        local set, hasAny = {}, false
        local raw = Config.AutoGiveEventFishTarget
        if type(raw) == "table" then
            for k, v in pairs(raw) do
                local name
                if type(k) == "string" and v == true then
                    name = k
                elseif type(v) == "string" and v ~= "" then
                    name = v
                end
                if name then
                    local clean = string.lower(trim(name))
                    if clean ~= "" then
                        set[clean] = true
                        hasAny = true
                    end
                end
            end
        end
        return set, hasAny
    end

    -- Noro Derasu NPC (cached; the slow recursive search is throttled)
    local noroCache, lastNoroSearch = nil, 0
    local function normName(text)
        return string.lower((tostring(text or ""):gsub("[%s_%-]+", "")))
    end
    local function GetNoro()
        if noroCache and noroCache.Parent then
            return noroCache
        end
        noroCache = nil
        local npc = workspace:FindFirstChild("NPC")
        local fn = npc and npc:FindFirstChild("Function")
        local noro = fn and fn:FindFirstChild("Noro Derasu")
        if not noro and os.clock() - lastNoroSearch > 3 then
            lastNoroSearch = os.clock()
            noro = workspace:FindFirstChild("Noro Derasu", true)
            if not noro then
                -- tolerant search: ignores case / spaces / underscores (e.g. "NoroDerasu", "Noro_Derasu")
                for _, inst in ipairs(workspace:GetDescendants()) do
                    if (inst:IsA("Model") or inst:IsA("BasePart")) and normName(inst.Name) == "noroderasu" then
                        noro = inst
                        break
                    end
                end
            end
        end
        noroCache = noro
        return noro
    end

    -- only a fish that is exactly one of the selected boss fish counts (favorited / locked ones are kept)
    local function MatchesEventFish(itemName, targets)
        if not itemName or itemName == "" then return false end
        if string.find(itemName, "Favorite", 1, true) or string.find(itemName, "Lock", 1, true) then
            return false
        end
        if not targets or next(targets) == nil then return false end
        local clean = string.lower(trim(GetFishNameFromItem(itemName)))
        if clean ~= "" and targets[clean] then return true end
        local stripped = trim(string.gsub(clean, "%s*[%(%[].-$", ""))
        return stripped ~= "" and targets[stripped] == true
    end

    local function FindFreeHotbarSlot()
        local hotbar = PlayerData:FindFirstChild("Hotbar")
        if not hotbar then return "4" end
        for i = 4, 10 do
            local slot = hotbar:FindFirstChild(tostring(i))
            if slot then
                local valName = slot:FindFirstChild("ValueName")
                local qty = slot:FindFirstChild("Quantity")
                if (not valName or valName.Value == "") or (qty and qty.Value <= 0) then
                    return tostring(i)
                end
            end
        end
        return "4"
    end

    -- returns slotName, itemInstance, key (the key changes when a fish is handed in)
    local function FindEventFish(targets)
        local hotbar = PlayerData:FindFirstChild("Hotbar")
        if hotbar then
            for i = 2, 10 do
                local slot = hotbar:FindFirstChild(tostring(i))
                local valName = slot and slot:FindFirstChild("ValueName")
                local qty = slot and slot:FindFirstChild("Quantity")
                if valName and valName.Value ~= "" and (not qty or (tonumber(qty.Value) or 0) > 0)
                    and MatchesEventFish(valName.Value, targets) then
                    return tostring(i), nil, "H" .. i .. valName.Value .. "#" .. tostring(qty and qty.Value or 1)
                end
            end
        end
        local inv = PlayerData:FindFirstChild("Inventory")
        if inv then
            for _, child in ipairs(inv:GetChildren()) do
                if child.Name ~= "" and (not child:IsA("ValueBase") or (tonumber(child.Value) or 0) > 0)
                    and MatchesEventFish(child.Name, targets) then
                    local amount = child:IsA("ValueBase") and tostring(child.Value) or "1"
                    return nil, child, "I" .. child.Name .. "#" .. amount
                end
            end
        end
        return nil
    end

    local function NoroPart(noro)
        if not noro then return nil end
        if noro:IsA("BasePart") then return noro end
        return noro.PrimaryPart or noro:FindFirstChild("HumanoidRootPart")
            or noro:FindFirstChildWhichIsA("BasePart", true)
    end

    local function HoldingFish()
        local char = LocalPlayer.Character
        return char ~= nil and char:GetAttribute("Type") == "Fish"
    end

    local lastNotify = 0
    local function Notify(content)
        if os.clock() - lastNotify < 6 then return end
        lastNotify = os.clock()
        pcall(function()
            Library:Notify({ Title = "Limited Event", Content = content, Duration = 4 })
        end)
    end

    -- Used by the auto-cast loop to stop casting while a fish is waiting to be handed in.
    local blockedUntil = 0
    local pendingCache, pendingAt = false, 0
    function UzexFilter.HasPendingEventFish()
        if not Config.AutoGiveEventFish then return false end
        local now = os.clock()
        if now < blockedUntil then return false end
        if now - pendingAt < 0.5 then return pendingCache end
        pendingAt = now
        pendingCache = false
        local targets, hasAny = GetTargetSet()
        if hasAny and GetNoro() then
            local _, _, pendingKey = FindEventFish(targets)
            pendingCache = pendingKey ~= nil
        end
        return pendingCache
    end

    local lastGiveTick, stuckKey, stuckCount = 0, nil, 0
    local function StepAutoGiveEventFish()
        if not Config.AutoGiveEventFish then return end
        local now = os.clock()
        if now < blockedUntil or now - lastGiveTick < 1.5 then return end
        local targets, hasAny = GetTargetSet()
        if not hasAny then return end

        local slot, item, key = FindEventFish(targets)
        if not key then
            stuckKey, stuckCount = nil, 0
            return
        end
        local noro = GetNoro()
        if not noro then
            Notify("Không tìm thấy NPC Noro Derasu.")
            return
        end

        -- the same fish still there after several tries -> pause so Auto Cast is not blocked forever
        if key == stuckKey then
            stuckCount = stuckCount + 1
        else
            stuckKey, stuckCount = key, 1
        end
        if stuckCount > 4 then
            stuckKey, stuckCount = nil, 0
            blockedUntil = os.clock() + 60
            Notify("Không đưa được cá cho Noro Derasu, tạm dừng 60 giây.")
            return
        end
        lastGiveTick = now

        -- move the fish from the inventory to a free hotbar slot and wait until it is there
        if not slot then
            local free = FindFreeHotbarSlot()
            local moveItems = Events:FindFirstChild("MoveItems")
            if not moveItems then return end
            pcall(function()
                moveItems:FireServer("Inventory", item.Name, free)
            end)
            for _ = 1, 10 do
                task.wait(0.15)
                local hotbar = PlayerData:FindFirstChild("Hotbar")
                local entry = hotbar and hotbar:FindFirstChild(free)
                local valName = entry and entry:FindFirstChild("ValueName")
                local qty = entry and entry:FindFirstChild("Quantity")
                if valName and tostring(valName.Value) == item.Name and (not qty or (tonumber(qty.Value) or 0) > 0) then
                    slot = free
                    break
                end
            end
            if not slot then return end
        end

        -- the fish now sits in the hotbar: take its key again so "fish is gone" is measured from here
        do
            local _, _, hotbarKey = FindEventFish(targets)
            if hotbarKey then key = hotbarKey end
        end

        -- go next to the NPC (the server can ignore far away requests), come back afterwards
        local origin
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local part = NoroPart(noro)
        if Config.EventGiveTeleport ~= false and hrp and part and (hrp.Position - part.Position).Magnitude > 8 then
            origin = hrp.CFrame
            hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.5)
        end

        local function restore()
            if origin then
                local c2 = LocalPlayer.Character
                local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                if h2 then h2.CFrame = origin end
            end
        end

        -- the fish must really be in hand, otherwise the NPC rejects the request
        for attempt = 1, 2 do
            pcall(function()
                ToggleHotbar:InvokeServer(tonumber(slot), nil)
            end)
            for _ = 1, 12 do
                task.wait(0.1)
                if HoldingFish() then break end
            end
            if HoldingFish() then break end
        end
        if not HoldingFish() then
            Notify("Không cầm được cá ở ô " .. tostring(slot) .. ".")
            restore()
            return
        end

        local function fishGone()
            local _, _, k2 = FindEventFish(targets)
            return k2 ~= key
        end

        local choose = ChooseDialogueOption or Events:FindFirstChild("ChooseDialogueOption")
        local given = false

        -- 1) dialogue remote (same call the Dump Guy uses)
        if choose then
            pcall(function()
                choose:FireServer("Noro Derasu", 1, "GiveFish", { noro })
            end)
            for _ = 1, 8 do
                task.wait(0.1)
                if fishGone() then given = true break end
            end
            -- 1b) same call with the real instance name (in case it differs from "Noro Derasu")
            if not given and noro.Name ~= "Noro Derasu" then
                pcall(function()
                    choose:FireServer(noro.Name, 1, "GiveFish", { noro })
                end)
                for _ = 1, 8 do
                    task.wait(0.1)
                    if fishGone() then given = true break end
                end
            end
        end

        -- 2) fallback: trigger the NPC's ProximityPrompt
        if not given then
            local prompt = noro:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and fireproximityprompt then
                pcall(fireproximityprompt, prompt)
                for _ = 1, 10 do
                    task.wait(0.1)
                    if fishGone() then given = true break end
                end
            end
        end

        if not given then
            print("[Uzex] Noro Derasu: GiveFish did not remove the fish. NPC =", noro:GetFullName(), "| slot =", slot)
            Notify("Gửi cá cho Noro Derasu chưa thành công (" .. noro:GetFullName() .. ").")
        end

        restore()
    end

    task.spawn(function()
        while task.wait(0.25) do
            if Config.AutoGiveEventFish then
                pcall(StepAutoGiveEventFish)
            end
        end
    end)

    Tabs.LimitedEvent:CreateSection("Tự động đưa cá")

    Tabs.LimitedEvent:CreateToggle({
        Flag = "AutoGiveEventFishToggle",
        Name = "Tự động đưa cá",
        CurrentValue = Config.AutoGiveEventFish,
        Callback = function(Value)
            Config.AutoGiveEventFish = Value
            SaveConfig()
        end
    })

    Tabs.LimitedEvent:CreateToggle({
        Flag = "EventGiveTeleportToggle",
        Name = "Tự dịch chuyển tới NPC",
        CurrentValue = Config.EventGiveTeleport ~= false,
        Callback = function(Value)
            Config.EventGiveTeleport = Value
            SaveConfig()
        end
    })

    Tabs.LimitedEvent:CreateDropdown({
        Flag = "AutoGiveEventFishDropdown",
        Name = "Chọn cá boss",
        Options = bossListItems,
        CurrentOption = table.clone(Config.AutoGiveEventFishTarget),
        MultipleOptions = true,
        Callback = function(Value)
            Config.AutoGiveEventFishTarget = ExtractSelected(Value)
            SaveConfig()
        end
    })
end

Tabs.Settings:CreateSection("Chung")

Tabs.Settings:CreateToggle({
    Flag = "AutoExecuteToggle",
    Name = "Tự chạy script",
    CurrentValue = Config.AutoExecute,
    Callback = function(Value)
        Config.AutoExecute = Value
        SaveConfig()
        if Value then
            QueueAutoExecute()
        end
    end
})

Tabs.Settings:CreateSection("Di chuyển")

Tabs.Settings:CreateToggle({
    Flag = "LoopSpeedToggle",
    Name = "Tốc độ đi bộ",
    CurrentValue = Config.LoopSpeedEnabled,
    Callback = function(Value)
        Config.LoopSpeedEnabled = Value
        SaveConfig()
    end
})

Tabs.Settings:CreateSlider({
    Flag = "WalkSpeedSlider",
    Name = "Tốc độ",
    CurrentValue = Config.WalkSpeed,
    Range = {16, 250},
    Increment = 1,
    Callback = function(Value)
        Config.WalkSpeed = Value
        SaveConfig()
    end
})

FlyToggleObj = Tabs.Settings:CreateToggle({
    Flag = "FlyToggle",
    Name = "Bay",
    CurrentValue = Config.FlyEnabled,
    Callback = function(Value)
        Config.FlyEnabled = Value
        SaveConfig()
        if Value then
            startFly()
        else
            stopFly()
        end
    end
})

Tabs.Settings:CreateSlider({
    Flag = "FlySpeedSlider",
    Name = "Tốc độ bay",
    CurrentValue = Config.FlySpeed,
    Range = {1, 20},
    Increment = 0.1,
    Callback = function(Value)
        Config.FlySpeed = Value
        SaveConfig()
    end
})

NoclipToggleObj = Tabs.Settings:CreateToggle({
    Flag = "NoclipToggle",
    Name = "Đi xuyên vật thể",
    CurrentValue = Config.NoclipEnabled,
    Callback = function(Value)
        Config.NoclipEnabled = Value
        SaveConfig()
    end
})

Tabs.Settings:CreateToggle({
    Flag = "InfJumpToggle",
    Name = "Nhảy vô hạn",
    CurrentValue = Config.InfJumpEnabled,
    Callback = function(Value)
        Config.InfJumpEnabled = Value
        SaveConfig()
    end
})

Tabs.Teleport:CreateSection("Đảo")

do
    local islandList = GetIslandList()
    if (Config.SelectedIsland == "" or not table.find(islandList, Config.SelectedIsland)) and #islandList > 0 then
        Config.SelectedIsland = islandList[1]
    end

    Tabs.Teleport:CreateDropdown({
        Flag = "SelectIslandDropdown",
        Name = "Chọn đảo",
        Options = islandList,
        CurrentOption = Config.SelectedIsland ~= "" and Config.SelectedIsland or islandList[1],
        MultipleOptions = false,
        AllowNone = false,
        Callback = function(Value)
            Config.SelectedIsland = Value or ""
            SaveConfig()
        end
    })
end

Tabs.Teleport:CreateButton({
    Name = "Dịch chuyển đến đảo",
    Callback = function()
        TeleportToIsland(Config.SelectedIsland)
    end
})

Tabs.Teleport:CreateSection("NPC")

do
    local npcList = GetNPCList()
    if (Config.SelectedNPC == "" or not table.find(npcList, Config.SelectedNPC)) and #npcList > 0 then
        Config.SelectedNPC = npcList[1]
    end

    local NPCDropdown = Tabs.Teleport:CreateDropdown({
        Flag = "SelectNPCDropdown",
        Name = "Chọn NPC",
        Options = npcList,
        CurrentOption = Config.SelectedNPC ~= "" and Config.SelectedNPC or npcList[1],
        MultipleOptions = false,
        AllowNone = false,
        Callback = function(Value)
            Config.SelectedNPC = Value or ""
            SaveConfig()
        end
    })

    Tabs.Teleport:CreateButton({
        Name = "Dịch chuyển đến NPC",
        Callback = function()
            local chosen = (NPCDropdown and NPCDropdown:Get()) or Config.SelectedNPC
            TeleportToNPC(chosen)
        end
    })
end

Tabs.Teleport:CreateSection("Người chơi")

do
    local playerList = GetPlayerList()
    if #playerList == 0 then
        playerList = {"None"}
    end
    if (Config.SelectedPlayer == "" or not table.find(playerList, Config.SelectedPlayer)) and #playerList > 0 then
        Config.SelectedPlayer = playerList[1]
    end

    local PlayerDropdown = Tabs.Teleport:CreateDropdown({
        Flag = "SelectPlayerDropdown",
        Name = "Chọn người chơi",
        Options = playerList,
        CurrentOption = Config.SelectedPlayer ~= "" and Config.SelectedPlayer or playerList[1],
        MultipleOptions = false,
        AllowNone = false,
        Callback = function(Value)
            Config.SelectedPlayer = Value or ""
            SaveConfig()
        end
    })

    local function RefreshDropdownPlayers()
        local updated = GetPlayerList()
        if #updated == 0 then
            updated = {"None"}
        end
        if PlayerDropdown then
            PlayerDropdown:Refresh(updated, true, true)
            if not table.find(updated, Config.SelectedPlayer) then
                PlayerDropdown:Set(updated[1])
            end
        end
    end

    Players.PlayerAdded:Connect(function()
        task.wait(0.5)
        RefreshDropdownPlayers()
    end)

    Players.PlayerRemoving:Connect(function()
        task.wait(0.5)
        RefreshDropdownPlayers()
    end)

    Tabs.Teleport:CreateButton({
        Name = "Dịch chuyển đến người chơi",
        Callback = function()
            local chosen = (PlayerDropdown and PlayerDropdown:Get()) or Config.SelectedPlayer
            if chosen and chosen ~= "None" then
                TeleportToPlayer(chosen)
            end
        end
    })
end

-------------------------------------------------------------------------------
-- Index (ported from NNVN): marks every fish entry in the player's Index data as unlocked
-------------------------------------------------------------------------------
Tabs.Shop:CreateSection("Index")

Tabs.Shop:CreateButton({
    Name = "Unlock all fish (Risk)",
    Description = "Sets every fish in your Index data to unlocked",
    Callback = function()
        local index = PlayerData and PlayerData:FindFirstChild("Index")
        if not index then
            pcall(function()
                Library:Notify({
                    Title = "Index",
                    Content = "Index folder not found!",
                    Type = "warning",
                    Duration = 2,
                })
            end)
            return
        end
        local counter = 0
        for _, entry in ipairs(index:GetChildren()) do
            if entry:IsA("NumberValue") or entry:IsA("IntValue") then
                entry.Value = 1
                counter = counter + 1
            elseif entry:IsA("BoolValue") then
                entry.Value = true
                counter = counter + 1
            end
        end
        pcall(function()
            Library:Notify({
                Title = "Index",
                Content = "Unlocked " .. counter .. " fish!",
                Type = "success",
                Duration = 3,
            })
        end)
    end
})

Tabs.Shop:CreateSection("Mua mồi")

do
    local buyBaitList = GetBuyableBaits()
    if Config.SelectedBuyBait == "" and #buyBaitList > 0 then
        Config.SelectedBuyBait = buyBaitList[1]
    end

    Tabs.Shop:CreateDropdown({
        Flag = "SelectBuyBaitDropdown",
        Name = "Chọn mồi",
        Options = buyBaitList,
        CurrentOption = Config.SelectedBuyBait ~= "" and Config.SelectedBuyBait or buyBaitList[1],
        MultipleOptions = false,
        AllowNone = false,
        Callback = function(Value)
            Config.SelectedBuyBait = Value or ""
            SaveConfig()
        end
    })
end

Tabs.Shop:CreateInput({
    Flag = "BuyBaitAmountInput",
    Name = "Số lượng mua",
    CurrentValue = tostring(Config.BuyBaitAmount or 1),
    Numeric = true,
    Finished = false,
    Placeholder = "1",
    Callback = function(Value)
        Config.BuyBaitAmount = math.max(1, math.floor(tonumber(Value) or 1))
        SaveConfig()
    end
})

Tabs.Shop:CreateInput({
    Flag = "BuyBaitDelayInput",
    Name = "Độ trễ mua (phút)",
    CurrentValue = tostring(Config.BuyBaitDelay or 1),
    Numeric = true,
    Finished = false,
    Placeholder = "1",
    Callback = function(Value)
        Config.BuyBaitDelay = math.max(1, math.floor(tonumber(Value) or 1))
        SaveConfig()
    end
})

Tabs.Shop:CreateToggle({
    Flag = "AutoBuyBaitToggle",
    Name = "Tự động mua mồi",
    CurrentValue = Config.AutoBuyBait,
    Callback = function(Value)
        Config.AutoBuyBait = Value
        if not Value then
            lastBuyBaitTime = 0
        end
        SaveConfig()
    end
})

Tabs.Shop:CreateButton({
    Name = "Mua mồi",
    Callback = function()
        DoBuyBait(Config.SelectedBuyBait, Config.BuyBaitAmount)
    end
})

Tabs.Shop:CreateSection("Chế tạo mồi")

do
    local baitList = GetCraftableBaits()
    if Config.SelectedBait == "" and #baitList > 0 then
        Config.SelectedBait = baitList[1]
    end

    Tabs.Shop:CreateDropdown({
        Flag = "SelectBaitDropdown",
        Name = "Chọn mồi",
        Options = baitList,
        CurrentOption = Config.SelectedBait ~= "" and Config.SelectedBait or baitList[1],
        MultipleOptions = false,
        AllowNone = false,
        Callback = function(Value)
            Config.SelectedBait = Value or ""
            SaveConfig()
        end
    })
end

Tabs.Shop:CreateInput({
    Flag = "BaitAmountInput",
    Name = "Số lượng chế tạo",
    CurrentValue = tostring(Config.BaitAmount or 1),
    Numeric = true,
    Finished = false,
    Placeholder = "1",
    Callback = function(Value)
        Config.BaitAmount = math.max(1, math.floor(tonumber(Value) or 1))
        SaveConfig()
    end
})

Tabs.Shop:CreateToggle({
    Flag = "AutoCraftBaitToggle",
    Name = "Tự động chế tạo mồi",
    CurrentValue = Config.AutoCraftBait,
    Callback = function(Value)
        Config.AutoCraftBait = Value
        SaveConfig()
    end
})

Tabs.Shop:CreateButton({
    Name = "Chế tạo mồi",
    Callback = function()
        if Config.SelectedBait ~= "" then
            CraftBaitEvent:FireServer(Config.SelectedBait, math.max(1, math.floor(tonumber(Config.BaitAmount) or 1)))
        end
    end
})

Tabs.Shop:CreateSection("Chế tạo cần câu")

do
    local rodList = GetCraftableRods()
    if Config.SelectedRod == "" and #rodList > 0 then
        Config.SelectedRod = rodList[1]
    end

    Tabs.Shop:CreateDropdown({
        Flag = "SelectRodDropdown",
        Name = "Chọn cần câu",
        Options = rodList,
        CurrentOption = Config.SelectedRod ~= "" and Config.SelectedRod or rodList[1],
        MultipleOptions = false,
        AllowNone = false,
        Callback = function(Value)
            Config.SelectedRod = Value or ""
            SaveConfig()
        end
    })
end

Tabs.Shop:CreateToggle({
    Flag = "AutoCraftRodToggle",
    Name = "Tự động chế tạo cần câu",
    CurrentValue = Config.AutoCraftRod,
    Callback = function(Value)
        Config.AutoCraftRod = Value
        SaveConfig()
    end
})

Tabs.Shop:CreateButton({
    Name = "Chế tạo cần câu",
    Callback = function()
        if Config.SelectedRod ~= "" then
            CraftRodEvent:FireServer(Config.SelectedRod)
        end
    end
})

Tabs.Settings:CreateSection("ESP")

Tabs.Settings:CreateToggle({
    Flag = "ESPPlayers",
    Name = "ESP người chơi",
    CurrentValue = Config.ESPEnabled,
    Callback = function(Value)
        Config.ESPEnabled = Value
        SaveConfig()
        if not Value then
            clearPlayerESP()
        end
    end
})

-------------------------------------------------------------------------------
-- Upgrade tab
-------------------------------------------------------------------------------
do
    local remoteCache = {}

    local function FindRemote(patterns, skipPatterns)
        local key = table.concat(patterns, "|")
        local cached = remoteCache[key]
        if cached and cached.Parent then return cached end
        for _, root in ipairs({ Events, game:GetService("ReplicatedStorage") }) do
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                    local n = string.lower(d.Name)
                    local skip = false
                    for _, sp in ipairs(skipPatterns or {}) do
                        if string.find(n, sp, 1, true) then skip = true end
                    end
                    if not skip then
                        for _, pat in ipairs(patterns) do
                            if string.find(n, pat, 1, true) then
                                remoteCache[key] = d
                                return d
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    local function FireRemote(remote, ...)
        local args = table.pack(...)
        pcall(function()
            if remote:IsA("RemoteFunction") then
                remote:InvokeServer(table.unpack(args, 1, args.n))
            else
                remote:FireServer(table.unpack(args, 1, args.n))
            end
        end)
    end

    local aliases = {
        cash = { "cash", "balance", "money", "coins" },
        level = { "level", "lvl" },
        crystal = { "crystal", "crystals", "gem", "gems" },
        ticket = { "ticket", "tickets" },
    }

    local function ReadResource(name)
        local list = aliases[string.lower(name)] or { string.lower(name) }
        local roots = { PlayerData, LocalPlayer:FindFirstChild("leaderstats"), LocalPlayer }
        for _, root in ipairs(roots) do
            if root then
                for _, child in ipairs(root:GetChildren()) do
                    if child:IsA("ValueBase") then
                        local n = string.lower(child.Name)
                        for _, a in ipairs(list) do
                            if n == a then return child.Value end
                        end
                    end
                end
                local attr = root:GetAttribute(name)
                if attr ~= nil then return attr end
            end
        end
        return nil
    end

    Tabs.Upgrade:CreateSection("Nâng cấp nhân vật")

    Tabs.Upgrade:CreateDropdown({
        Flag = "UpgradeOptionsDropdown",
        Name = "Chọn 2 mục nâng cấp",
        Options = { "Cash", "Level", "Crystal", "Ticket" },
        CurrentOption = table.clone(type(Config.UpgradeOptions) == "table" and Config.UpgradeOptions or { "Cash", "Level" }),
        MultipleOptions = true,
        Callback = function(Value)
            if type(Value) ~= "table" then return end
            local picked = {}
            for i, v in ipairs(Value) do
                if i <= 2 then table.insert(picked, v) end
            end
            Config.UpgradeOptions = picked
            SaveConfig()
        end
    })

    Tabs.Upgrade:CreateDropdown({
        Flag = "UpgradeMethodDropdown",
        Name = "Phương thức nâng cấp",
        Options = { "Instant" },
        CurrentOption = "Instant",
        MultipleOptions = false,
        AllowNone = false,
        Callback = function(Value)
            Config.UpgradeMethod = "Instant"
            SaveConfig()
        end
    })

    Tabs.Upgrade:CreateToggle({
        Flag = "AutoRebirthToggle",
        Name = "Tự động tái sinh",
        CurrentValue = Config.AutoRebirth,
        Callback = function(Value)
            Config.AutoRebirth = Value
            SaveConfig()
        end
    })

    Tabs.Upgrade:CreateButton({
        Name = "Kiểm tra tài nguyên",
        Callback = function()
            local parts = {}
            for _, opt in ipairs({ "Cash", "Level", "Crystal", "Ticket" }) do
                local v = ReadResource(opt)
                table.insert(parts, opt .. ": " .. (v ~= nil and tostring(v) or "?"))
            end
            pcall(function()
                Library:Notify({
                    Title = "Tài nguyên",
                    Content = #parts > 0 and table.concat(parts, "  |  ") or "No upgrade option selected",
                    Duration = 5,
                })
            end)
        end
    })

    task.spawn(function()
        local warned = false
        while true do
            task.wait(0.5)
            if Config.AutoRebirth then
                local rebirth = FindRemote({ "rebirth" })
                if rebirth then
                    local upgrade = FindRemote({ "upgrade" }, { "skill" })
                    if upgrade then
                        for _, opt in ipairs(Config.UpgradeOptions or {}) do
                            FireRemote(upgrade, opt)
                        end
                    end
                    FireRemote(rebirth)
                elseif not warned then
                    warned = true
                    pcall(function()
                        Library:Notify({
                            Title = "Tự động tái sinh",
                            Content = "Không tìm thấy chức năng tái sinh trong game này",
                            Type = "warning",
                            Duration = 5,
                        })
                    end)
                end
            else
                warned = false
            end
        end
    end)
end

Tabs.Misc:CreateSection("Hiển thị")

Tabs.Misc:CreateToggle({
    Flag = "AntiAFKToggle",
    Name = "Chống AFK",
    CurrentValue = Config.AntiAFK,
    Callback = function(Value)
        Config.AntiAFK = Value
        SaveConfig()
    end
})

Tabs.Misc:CreateToggle({
    Flag = "AntiStaffToggle",
    Name = "Chống quản trị viên",
    Description = "Leaves the server when a staff member is in it",
    CurrentValue = Config.AntiStaff,
    Callback = function(Value)
        Config.AntiStaff = Value
        if Value then
            table.clear(UzexFilter.AntiChecked)
        end
        SaveConfig()
    end
})

do
    local hiddenGuis = {}

    function UzexFilter.ApplyHideName()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.DisplayDistanceType = Config.HideName
                and Enum.HumanoidDisplayDistanceType.None
                or Enum.HumanoidDisplayDistanceType.Viewer
        end
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BillboardGui") then
                if Config.HideName then
                    if hiddenGuis[d] == nil then hiddenGuis[d] = d.Enabled end
                    d.Enabled = false
                elseif hiddenGuis[d] ~= nil then
                    d.Enabled = hiddenGuis[d]
                    hiddenGuis[d] = nil
                end
            end
        end
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if Config.HideName then pcall(UzexFilter.ApplyHideName) end
    end)
    task.spawn(function()
        while task.wait(2) do
            if Config.HideName then pcall(UzexFilter.ApplyHideName) end
        end
    end)
end

Tabs.Misc:CreateToggle({
    Flag = "FullBrightToggle",
    Name = "Tăng sáng tối đa",
    CurrentValue = Config.FullBright,
    Callback = function(Value)
        Config.FullBright = Value
        SaveConfig()
        if Value then
            ApplyLightingSettings()
        else
            RestoreFullBright()
            if Config.NoFog then
                ApplyLightingSettings()
            end
        end
    end
})

Tabs.Misc:CreateToggle({
    Flag = "NoFogToggle",
    Name = "Tắt sương mù",
    CurrentValue = Config.NoFog,
    Callback = function(Value)
        Config.NoFog = Value
        SaveConfig()
        if Value then
            ApplyLightingSettings()
        else
            RestoreNoFog()
            if Config.FullBright then
                ApplyLightingSettings()
            end
        end
    end
})

do
    local weak = { __mode = "k" }
    local savedParts = setmetatable({}, weak)       -- BasePart -> { Material, Reflectance, CastShadow, RenderFidelity }
    local savedDecals = setmetatable({}, weak)      -- Decal/Texture -> Transparency
    local savedFx = setmetatable({}, weak)          -- effect -> true
    local savedAtmos = setmetatable({}, weak)       -- Atmosphere -> Density
    local savedExplosions = setmetatable({}, weak)  -- Explosion -> Visible
    local savedAppearance = {}                      -- SurfaceAppearance -> original parent (strong: it is unparented)
    local savedPerf = nil
    local descConn = nil
    local optimized = 0
    local FX_CLASSES = {
        ParticleEmitter = true, Trail = true, Beam = true, Smoke = true,
        Fire = true, Sparkles = true, BloomEffect = true, BlurEffect = true,
        SunRaysEffect = true, DepthOfFieldEffect = true, Clouds = true,
        PointLight = true, SpotLight = true, SurfaceLight = true, Highlight = true,
        ColorCorrectionEffect = true,
    }
    local PERF_QUALITY = 8   -- graphics quality level while Performance Mode is on
    local PERF_FPS_CAP = 120 -- FPS cap while Performance Mode is on

    -- average frames per second over a short window
    local function measureFps(seconds)
        local frames = 0
        local started = os.clock()
        local connection = RunService.Heartbeat:Connect(function()
            frames = frames + 1
        end)
        task.wait(seconds)
        connection:Disconnect()
        return frames / math.max(os.clock() - started, 0.01)
    end

    local function optimize(inst)
        local class = inst.ClassName
        if FX_CLASSES[class] then
            if inst.Enabled then
                savedFx[inst] = true
                inst.Enabled = false
                optimized = optimized + 1
            end
        elseif inst:IsA("BasePart") then
            if savedParts[inst] == nil then
                local fidelity, textureId
                if inst:IsA("MeshPart") then
                    fidelity = inst.RenderFidelity
                    textureId = inst.TextureID
                end
                savedParts[inst] = { inst.Material, inst.Reflectance, inst.CastShadow, fidelity, textureId }
                inst.Material = Enum.Material.SmoothPlastic
                inst.Reflectance = 0
                inst.CastShadow = false
                if fidelity then
                    inst.RenderFidelity = Enum.RenderFidelity.Performance
                    if textureId and textureId ~= "" then
                        inst.TextureID = ""
                    end
                end
                optimized = optimized + 1
            end
        elseif class == "Explosion" then
            if savedExplosions[inst] == nil then
                savedExplosions[inst] = inst.Visible
                inst.Visible = false
                optimized = optimized + 1
            end
        elseif inst:IsA("Decal") then
            if savedDecals[inst] == nil then
                savedDecals[inst] = inst.Transparency
                inst.Transparency = 1
                optimized = optimized + 1
            end
        elseif class == "SurfaceAppearance" then
            if savedAppearance[inst] == nil and inst.Parent then
                savedAppearance[inst] = inst.Parent
                inst.Parent = nil
                optimized = optimized + 1
            end
        elseif class == "Atmosphere" then
            if savedAtmos[inst] == nil then
                savedAtmos[inst] = inst.Density
                inst.Density = 0
                optimized = optimized + 1
            end
        end
    end

    local function applyPerformance(on)
        if on then
            if savedPerf then return end
            local mine = {}
            savedPerf = mine
            optimized = 0
            task.spawn(function()
                local before = measureFps(1)
                if savedPerf ~= mine then return end

                pcall(function()
                    local rendering = settings().Rendering
                    mine.quality = rendering.QualityLevel
                    mine.meshDetail = rendering.MeshPartDetailLevel
                    rendering.QualityLevel = Enum.QualityLevel:FromValue(PERF_QUALITY)
                    rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
                end)
                pcall(function()
                    local ugs = UserSettings():GetService("UserGameSettings")
                    mine.saved = ugs.SavedQualityLevel
                    ugs.SavedQualityLevel = Enum.SavedQualitySetting["QualityLevel" .. PERF_QUALITY]
                end)
                -- Fast Mode: unlock FPS up to 120 (needs an executor with setfpscap)
                pcall(function()
                    if type(setfpscap) == "function" then
                        mine.fpsCap = (type(getfpscap) == "function" and getfpscap()) or 60
                        setfpscap(PERF_FPS_CAP)
                    end
                end)
                pcall(function()
                    mine.lighting = {
                        Lighting.GlobalShadows, Lighting.EnvironmentDiffuseScale,
                        Lighting.EnvironmentSpecularScale, Lighting.ShadowSoftness,
                        Lighting.Technology,
                    }
                    Lighting.GlobalShadows = false
                    Lighting.EnvironmentDiffuseScale = 0
                    Lighting.EnvironmentSpecularScale = 0
                    Lighting.ShadowSoftness = 0
                    Lighting.Technology = Enum.Technology.Compatibility
                end)
                pcall(function()
                    local materials = game:GetService("MaterialService")
                    mine.materials2022 = materials.Use2022Materials
                    materials.Use2022Materials = false
                end)
                pcall(function()
                    local terrain = workspace:FindFirstChildOfClass("Terrain")
                    if terrain then
                        mine.terrain = {
                            terrain.WaterWaveSize, terrain.WaterWaveSpeed,
                            terrain.WaterReflectance, terrain.Decoration,
                        }
                        terrain.WaterWaveSize = 0
                        terrain.WaterWaveSpeed = 0
                        terrain.WaterReflectance = 0
                        terrain.Decoration = false
                    end
                end)

                descConn = workspace.DescendantAdded:Connect(function(d)
                    pcall(optimize, d)
                end)
                local n = 0
                for _, root in ipairs({ workspace, Lighting }) do
                    for _, d in ipairs(root:GetDescendants()) do
                        if savedPerf ~= mine then return end
                        pcall(optimize, d)
                        n = n + 1
                        if n % 300 == 0 then task.wait() end
                    end
                end

                task.wait(1.5)
                local after = measureFps(2)
                if savedPerf ~= mine then return end
                local content
                if before >= 58 then
                    content = string.format("%d objects optimized. FPS is at the cap (%d), so only GPU load and heat drop.", optimized, math.floor(after + 0.5))
                elseif after > before + 1 then
                    content = string.format("FPS %d -> %d (%d objects optimized)", math.floor(before + 0.5), math.floor(after + 0.5), optimized)
                else
                    content = string.format("%d objects optimized. FPS stayed near %d, the limit is elsewhere (CPU or network).", optimized, math.floor(after + 0.5))
                end
                pcall(function()
                    Library:Notify({ Title = "Chế độ hiệu năng", Content = content, Type = "success", Duration = 5 })
                end)
            end)
        else
            if not savedPerf then return end
            if descConn then descConn:Disconnect() descConn = nil end
            local snapshot = savedPerf
            savedPerf = nil
            pcall(function()
                if snapshot.quality then settings().Rendering.QualityLevel = snapshot.quality end
                if snapshot.meshDetail then settings().Rendering.MeshPartDetailLevel = snapshot.meshDetail end
            end)
            pcall(function()
                if snapshot.fpsCap and type(setfpscap) == "function" then setfpscap(snapshot.fpsCap) end
            end)
            pcall(function()
                if snapshot.materials2022 ~= nil then
                    game:GetService("MaterialService").Use2022Materials = snapshot.materials2022
                end
            end)
            pcall(function()
                if snapshot.saved then
                    UserSettings():GetService("UserGameSettings").SavedQualityLevel = snapshot.saved
                end
            end)
            pcall(function()
                local l = snapshot.lighting
                if l then
                    Lighting.GlobalShadows, Lighting.EnvironmentDiffuseScale = l[1], l[2]
                    Lighting.EnvironmentSpecularScale, Lighting.ShadowSoftness = l[3], l[4]
                    if l[5] then Lighting.Technology = l[5] end
                end
            end)
            pcall(function()
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                local t = snapshot.terrain
                if terrain and t then
                    terrain.WaterWaveSize, terrain.WaterWaveSpeed = t[1], t[2]
                    terrain.WaterReflectance, terrain.Decoration = t[3], t[4]
                end
            end)
            task.spawn(function()
                local n = 0
                for inst, v in pairs(savedParts) do
                    pcall(function()
                        inst.Material, inst.Reflectance, inst.CastShadow = v[1], v[2], v[3]
                        if v[4] then inst.RenderFidelity = v[4] end
                        if v[5] then inst.TextureID = v[5] end
                    end)
                    savedParts[inst] = nil
                    n = n + 1
                    if n % 300 == 0 then task.wait() end
                end
                for inst, v in pairs(savedDecals) do
                    pcall(function() inst.Transparency = v end)
                    savedDecals[inst] = nil
                end
                for inst in pairs(savedFx) do
                    pcall(function() inst.Enabled = true end)
                    savedFx[inst] = nil
                end
                for inst, visible in pairs(savedExplosions) do
                    pcall(function() inst.Visible = visible end)
                    savedExplosions[inst] = nil
                end
                for inst, density in pairs(savedAtmos) do
                    pcall(function() inst.Density = density end)
                    savedAtmos[inst] = nil
                end
                for inst, parent in pairs(savedAppearance) do
                    pcall(function()
                        if parent and parent.Parent then inst.Parent = parent end
                    end)
                    savedAppearance[inst] = nil
                end
            end)
        end
    end

    Tabs.Misc:CreateToggle({
        Flag = "PerformanceModeToggle",
        Name = "Chế độ hiệu năng",
        Description = "Fast Mode: quality level 8, FPS cap 120, flat materials, no shadows/effects/lights/textures",
        CurrentValue = Config.PerformanceMode,
        Callback = function(Value)
            Config.PerformanceMode = Value
            SaveConfig()
            applyPerformance(Value)
        end
    })
end

Tabs.Misc:CreateToggle({
    Flag = "EnableNotificationsToggle",
    Name = "Bật thông báo",
    Description = "Show or hide the pop-up notifications",
    CurrentValue = Config.NotificationsEnabled,
    Callback = function(Value)
        Config.NotificationsEnabled = Value
        Library.NotificationsEnabled = Value
        SaveConfig()
        if Value then
            pcall(function()
                Library:Notify({
                    Title = "Thông báo",
                    Content = "Đã bật thông báo",
                    Type = "success",
                    Duration = 2,
                })
            end)
        end
    end
})

Tabs.Main:CreateSection("Câu cá")

Tabs.Main:CreateToggle({
    Flag = "AutoReelToggle",
    Name = "Khóa thanh bắt cá",
    CurrentValue = Config.AutoReel,
    Callback = function(Value)
        Config.AutoReel = Value
        SaveConfig()
    end
})

Tabs.Main:CreateToggle({
    Flag = "AutoCastToggle",
    Name = "Tự động thả câu",
    CurrentValue = Config.AutoCast,
    Callback = function(Value)
        Config.AutoCast = Value
        SaveConfig()
    end
})

Tabs.Main:CreateToggle({
    Flag = "FilterBossFishToggle",
    Name = "Tự động câu cá Boss",
    CurrentValue = Config.FilterBossFish,
    Callback = function(Value)
        Config.FilterBossFish = Value
        SaveConfig()
    end
})

Tabs.Main:CreateToggle({
    Flag = "AutoFarmSecretBossToggle",
    Name = "Tự động câu cá Secret Boss",
    CurrentValue = Config.AutoFarmSecretBoss,
    Callback = function(Value)
        Config.AutoFarmSecretBoss = Value
        if Value then
            Config.AutoCast = false
        end
        SaveConfig()
    end
})

Tabs.Main:CreateDropdown({
    Flag = "AutoSecretBossModeDropdown",
    Name = "Kích hoạt Secret Boss",
    Options = {"Always Active", "Only When Weather"},
    CurrentOption = Config.AutoSecretBossMode == "Only When Weather" and "Only When Weather" or "Always Active",
    MultipleOptions = false,
    AllowNone = false,
    Callback = function(Value)
        Config.AutoSecretBossMode = Value == "Only When Weather" and Value or "Always Active"
        SaveConfig()
    end
})

Tabs.Main:CreateDropdown({
    Flag = "AutoCastMethodDropdown",
    Name = "Cách thả câu",
    Options = {"Instant", "Delay"},
    CurrentOption = Config.AutoCastMethod or "Instant",
    MultipleOptions = false,
    AllowNone = false,
    Callback = function(Value)
        Config.AutoCastMethod = Value or "Instant"
        SaveConfig()
    end
})

Tabs.Main:CreateSlider({
    Flag = "CastDelaySlider",
    Name = "Độ trễ thả câu",
    CurrentValue = Config.CastDelay or 1,
    Range = {1, 10},
    Increment = 0.1,
    Callback = function(Value)
        Config.CastDelay = Value
        SaveConfig()
    end
})

Tabs.Main:CreateToggle({
    Flag = "AutoEquipBestBaitToggle",
    Name = "Tự trang bị mồi tốt nhất",
    CurrentValue = Config.AutoEquipBestBait,
    Callback = function(Value)
        Config.AutoEquipBestBait = Value
        if Value then
            task.spawn(function()
                StepAutoEquipBestBait(true)
            end)
        end
        SaveConfig()
    end
})

do
    local lastRodEquip = 0

    local function EquipRodNow()
        lastRodEquip = os.clock()
        pcall(function()
            ToggleHotbar:InvokeServer("1")
        end)
    end

    -- keeps the fishing rod in hand only when the "Tự trang bị cần câu" toggle is on
    -- (Auto Farm Secret Boss no longer forces it; it only equips right before casting)
    task.spawn(function()
        while task.wait(0.5) do
            if Config.AutoEquipRod and not UzexFilter.Busy and not UzexFilter.NeedRod then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart")
                    and char:GetAttribute("Type") ~= "Fishing Rod"
                    and os.clock() - lastRodEquip > 1.5 then
                    EquipRodNow()
                end
            end
        end
    end)

    Tabs.Main:CreateToggle({
        Flag = "AutoEquipRodToggle",
        Name = "Tự trang bị cần câu",
        CurrentValue = Config.AutoEquipRod,
        Callback = function(Value)
            Config.AutoEquipRod = Value
            SaveConfig()
            if Value then
                task.spawn(function()
                    local char = LocalPlayer.Character
                    if char and char:GetAttribute("Type") ~= "Fishing Rod" then
                        EquipRodNow()
                    end
                end)
            end
        end
    })
end

Tabs.Main:CreateSection("Cá yêu thích")

Tabs.Main:CreateDropdown({
    Flag = "FavoriteFishDropdown",
    Name = "Chọn cá",
    Options = (function()
        local names = UzexFilter.FishNames()
        table.insert(names, 1, "No Selection")
        return names
    end)(),
    CurrentOption = (type(Config.FavoriteFish) == "string" and Config.FavoriteFish ~= "") and Config.FavoriteFish or "No Selection",
    MultipleOptions = false,
    AllowNone = false,
    Callback = function(Value)
        if type(Value) == "table" then Value = Value[1] end
        Config.FavoriteFish = (Value == nil or Value == "No Selection") and "" or Value
        SaveConfig()
    end
})

Tabs.Main:CreateToggle({
    Flag = "AutoFavoriteFishToggle",
    Name = "Tự động yêu thích cá đã chọn",
    CurrentValue = Config.AutoFavoriteFish,
    Callback = function(Value)
        Config.AutoFavoriteFish = Value
        SaveConfig()
    end
})

Tabs.Main:CreateSection("Tự động bỏ qua cá")

Tabs.Main:CreateDropdown({
    Flag = "SkipFishListDropdown",
    Name = "Cá cần bỏ qua",
    Options = UzexFilter.FishNames(),
    CurrentOption = table.clone(type(Config.SkipFishList) == "table" and Config.SkipFishList or {}),
    MultipleOptions = true,
    Callback = function(Value)
        local picked = {}
        if type(Value) == "table" then
            for _, v in ipairs(Value) do
                table.insert(picked, v)
            end
        end
        Config.SkipFishList = picked
        SaveConfig()
    end
})

Tabs.Main:CreateToggle({
    Flag = "AutoSkipFishToggle",
    Name = "Tự động bỏ qua cá đã chọn",
    CurrentValue = Config.AutoSkipFish,
    Callback = function(Value)
        Config.AutoSkipFish = Value
        SaveConfig()
    end
})

Tabs.Main:CreateSection("Kỹ năng")

Tabs.Main:CreateToggle({
    Flag = "AutoSkillToggle",
    Name = "Tự động dùng kỹ năng",
    CurrentValue = Config.AutoSkill,
    Callback = function(Value)
        Config.AutoSkill = Value
        if Value and LocalPlayer.Character then
            ApplyAntiConfuse(LocalPlayer.Character)
        end
        SaveConfig()
    end
})

do
    local allSkillKeys = {"Z", "X", "C", "V"}
    local SkillDropdown

    local function OrderedSkillOptions()
        local options = table.clone(Config.SkillOrder)
        for _, key in ipairs(allSkillKeys) do
            if not table.find(options, key) then
                table.insert(options, key)
            end
        end
        return options
    end

    SkillDropdown = Tabs.Main:CreateDropdown({
        Flag = "SelectSkillDropdown",
        Name = "Chọn kỹ năng",
        Options = OrderedSkillOptions(),
        CurrentOption = table.clone(Config.SkillOrder),
        MultipleOptions = true,
        Callback = function(Value)
            if type(Value) ~= "table" then return end
            local selected = {}
            for _, key in ipairs(Value) do
                selected[key] = true
            end
            for i = #Config.SkillOrder, 1, -1 do
                if not selected[Config.SkillOrder[i]] then
                    table.remove(Config.SkillOrder, i)
                end
            end
            for _, key in ipairs(allSkillKeys) do
                if selected[key] and not table.find(Config.SkillOrder, key) then
                    table.insert(Config.SkillOrder, key)
                end
            end
            if SkillDropdown then
                -- keepSelection, silent: avoid recursively invoking Callback.
                SkillDropdown:Refresh(OrderedSkillOptions(), true, true)
            end
            SaveConfig()
        end
    })
end

Tabs.Main:CreateSection("Boss")

do
    local bossModes = {"Normal", "Hard", "Nightmare"}
    if not table.find(bossModes, Config.BossMode) then
        Config.BossMode = "Normal"
    end

    Tabs.Main:CreateDropdown({
        Flag = "SelectBossModeDropdown",
        Name = "Chọn chế độ Boss",
        Options = bossModes,
        CurrentOption = Config.BossMode,
        MultipleOptions = false,
        AllowNone = false,
        Callback = function(Value)
            Config.BossMode = Value or "Normal"
            SaveConfig()
        end
    })
end

Tabs.Main:CreateToggle({
    Flag = "AutoBossToggle",
    Name = "Tự động Enzo",
    CurrentValue = Config.AutoBoss,
    Callback = function(Value)
        Config.AutoBoss = Value
        SaveConfig()
        if Value then
            task.spawn(function()
                CheckBossStatusOnToggle(false)
            end)
        end
    end
})

Tabs.Main:CreateToggle({
    Flag = "AutoSecretBossToggle",
    Name = "Tự động Long DiaoHai",
    CurrentValue = Config.AutoSecretBoss,
    Callback = function(Value)
        Config.AutoSecretBoss = Value
        SaveConfig()
        if Value then
            task.spawn(function()
                CheckBossStatusOnToggle(true)
            end)
        end
    end
})

Tabs.Main:CreateToggle({
    Flag = "AutoMiniGameToggle",
    Name = "Tự động chơi mini game",
    CurrentValue = Config.AutoMiniGame,
    Callback = function(Value)
        Config.AutoMiniGame = Value
        if Value and LocalPlayer.Character then
            ApplyAntiConfuse(LocalPlayer.Character)
        end
        SaveConfig()
    end
})

Tabs.Main:CreateSlider({
    Flag = "BlackTortoiseBandSlider",
    Name = "Black Tortoise Bloodline - vùng an toàn",
    CurrentValue = tonumber(Config.BlackTortoiseBand) or 0.12,
    Range = {0.03, 0.17},
    Increment = 0.01,
    Callback = function(Value)
        Config.BlackTortoiseBand = math.clamp(tonumber(Value) or 0.12, 0.03, 0.17)
        SaveConfig()
    end
})

Tabs.Main:CreateSection("Vị trí")

Tabs.Main:CreateButton({
    Name = "Lưu vị trí",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = (char and char:FindFirstChild("HumanoidRootPart")) or cachedHrp
        if hrp then
            Config.SavedPos = {hrp.CFrame:GetComponents()}
            SaveConfig()
            pcall(function()
                Library:Notify({
                    Title = "Vị trí",
                    Content = "Đã lưu vị trí!",
                    Duration = 3
                })
            end)
        end
    end
})

Tabs.Main:CreateToggle({
    Flag = "AutoTPPosToggle",
    Name = "Tự dịch chuyển đến vị trí",
    CurrentValue = Config.AutoTPPos,
    Callback = function(Value)
        Config.AutoTPPos = Value
        SaveConfig()
        if Value then
            StepAutoTPPos(LocalPlayer.Character)
        end
    end
})

Tabs.Main:CreateButton({
    Name = "Xóa vị trí",
    Callback = function()
        Config.SavedPos = false
        SaveConfig()
        pcall(function()
            Library:Notify({
                Title = "Vị trí",
                Content = "Đã xóa vị trí!",
                Duration = 3
            })
        end)
    end
})

Tabs.Misc:CreateSection("Mã quà tặng")

Tabs.Misc:CreateButton({
    Name = "Nhập tất cả mã",
    Callback = function()
        RedeemAllCodes()
    end
})

Tabs.Misc:CreateSection("Menu tiện ích")

Tabs.Misc:CreateButton({
    Name = "Mở nâng cấp kỹ năng",
    Callback = function()
        local state = OpenMenuFrameRemotely("SkillUpgrade")
        Library:Notify({
            Title = "Giao diện tiện ích",
            Content = state and "Opened Skill Upgrade" or "Closed Skill Upgrade",
            Duration = 2
        })
    end
})

Tabs.Misc:CreateButton({
    Name = "Mở học kỹ năng",
    Callback = function()
        local state = OpenMenuFrameRemotely("LearnSkill")
        Library:Notify({
            Title = "Giao diện tiện ích",
            Content = state and "Opened Learn Skill" or "Closed Learn Skill",
            Duration = 2
        })
    end
})

Tabs.Misc:CreateButton({
    Name = "Mở giao diện trao đổi",
    Callback = function()
        local state = OpenMenuFrameRemotely("Exchange")
        Library:Notify({
            Title = "Giao diện tiện ích",
            Content = state and "Opened Item Exchange" or "Closed Item Exchange",
            Duration = 2
        })
    end
})

Tabs.Misc:CreateButton({
    Name = "Mở đặc tính",
    Callback = function()
        local state = OpenMenuFrameRemotely("Trait")
        Library:Notify({
            Title = "Giao diện tiện ích",
            Content = state and "Opened Trait" or "Closed Trait",
            Duration = 2
        })
    end
})

Tabs.Settings:CreateKeybind({
    Flag = "ToggleUIKeybind",
    Name = "Phím thu nhỏ giao diện",
    CurrentKeybind = "LeftControl",
    OnChanged = function(NewKey)
        local keyCode = typeof(NewKey) == "EnumItem" and NewKey or Enum.KeyCode[tostring(NewKey)] or Enum.KeyCode.LeftControl
        Window:SetKeybind(keyCode)
    end
})





do
    local function HopLowServer()
        task.spawn(function()
            local placeId = game.PlaceId
            local curJobId = game.JobId
            local requestFn = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
            local targetServer = nil

            pcall(function()
                Library:Notify({
                    Title = "Đổi máy chủ",
                    Content = "Đang tìm máy chủ ít người...",
                    Duration = 4
                })
            end)

            local cursor = ""
            local attempts = 0
            while attempts < 5 and not targetServer do
                attempts = attempts + 1
                local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
                if cursor ~= "" then
                    url = url .. "&cursor=" .. cursor
                end

                local raw = nil
                if requestFn then
                    local res = requestFn({ Url = url, Method = "GET" })
                    if res and res.Body then
                        raw = res.Body
                    end
                else
                    local ok, res = pcall(game.HttpGet, game, url)
                    if ok then raw = res end
                end

                if raw then
                    local data = nil
                    pcall(function() data = HttpService:JSONDecode(raw) end)
                    if data and data.data then
                        local servers = {}
                        for _, s in ipairs(data.data) do
                            if type(s) == "table" and s.id and s.id ~= curJobId then
                                local playing = tonumber(s.playing) or 0
                                local maxP = tonumber(s.maxPlayers) or 1
                                if playing < maxP and playing > 0 then
                                    table.insert(servers, s)
                                end
                            end
                        end
                        table.sort(servers, function(a, b)
                            return (tonumber(a.playing) or 0) < (tonumber(b.playing) or 0)
                        end)
                        if #servers > 0 then
                            targetServer = servers[1]
                            break
                        end
                        if data.nextPageCursor and data.nextPageCursor ~= "" then
                            cursor = data.nextPageCursor
                        else
                            break
                        end
                    else
                        break
                    end
                else
                    break
                end
                task.wait(0.5)
            end

            if targetServer and targetServer.id then
                pcall(function()
                    Library:Notify({
                        Title = "Đổi máy chủ",
                        Content = "Đã tìm thấy máy chủ có " .. tostring(targetServer.playing) .. " người chơi! Đang dịch chuyển...",
                        Duration = 4
                    })
                end)
                task.wait(0.5)
                TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, LocalPlayer)
            else
                pcall(function()
                    Library:Notify({
                        Title = "Đổi máy chủ",
                        Content = "Không tìm thấy máy chủ ít người. Đang chuyển đến máy chủ ngẫu nhiên...",
                        Duration = 4
                    })
                end)
                task.wait(0.5)
                TeleportService:Teleport(placeId, LocalPlayer)
            end
        end)
    end

    Tabs.Misc:CreateSection("Máy chủ")

    Tabs.Misc:CreateButton({
        Name = "Vào lại máy chủ",
        Callback = function()
            pcall(function()
                Library:Notify({
                    Title = "Rejoin",
                    Content = "Đang vào lại máy chủ hiện tại...",
                    Duration = 3
                })
            end)
            task.wait(0.3)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    })

    Tabs.Misc:CreateButton({
        Name = "Đổi máy chủ ít người",
        Callback = function()
            HopLowServer()
        end
    })
end

-------------------------------------------------------------------------------
-- Auto rejoin + Discord webhook
-------------------------------------------------------------------------------
do
    local CoreGui = game:GetService("CoreGui")
    local MarketplaceService = game:GetService("MarketplaceService")

    local sessionStart = os.time()
    local fishCaught = 0
    local lastFish = ""
    local lastReport = os.clock()
    local lastSend = 0
    local gameName = tostring(game.PlaceId)
    task.spawn(function()
        pcall(function()
            gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
        end)
    end)

    local COLOR_INFO = 14083839
    local COLOR_GOOD = 8574880
    local COLOR_WARN = 15773804

    ---------------------------------------------------------------- webhook
    local function validWebhook(url)
        url = tostring(url or "")
        for _, host in ipairs({ "discord.com", "discordapp.com", "ptb.discord.com", "canary.discord.com" }) do
            local prefix = "https://" .. host .. "/api/webhooks/"
            if url:sub(1, #prefix) == prefix and url:match("^%d+/[%w%-_]+", #prefix + 1) then
                return true
            end
        end
        return false
    end

    local function uptime()
        local t = os.time() - sessionStart
        return string.format("%dh %dm", t // 3600, (t % 3600) // 60)
    end

    -- Money / ticket / gem numbers added to every webhook message.
    local currencyCache = {}

    local function findCurrency(keys, exclude)
        local best, bestScore
        for _, root in ipairs({ PlayerData, LocalPlayer:FindFirstChild("leaderstats") }) do
            if root then
                for _, d in ipairs(root:GetDescendants()) do
                    if d:IsA("ValueBase") then
                        local n = string.lower((string.gsub(d.Name, "[%s_%-]", "")))
                        local rank
                        for i, key in ipairs(keys) do
                            if n == key then
                                rank = i
                                break
                            end
                        end
                        if not rank then
                            for i, key in ipairs(keys) do
                                if string.find(n, key, 1, true) and not (exclude and string.find(n, exclude, 1, true)) then
                                    rank = 100 + i
                                    break
                                end
                            end
                        end
                        if rank then
                            local depth, p = 0, d.Parent
                            while p and p ~= root do
                                depth = depth + 1
                                p = p.Parent
                            end
                            local score = rank * 100 + depth
                            if not bestScore or score < bestScore then
                                best, bestScore = d, score
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function readCurrency(slot, keys, exclude)
        local inst = currencyCache[slot]
        if not (inst and inst.Parent) then
            inst = findCurrency(keys, exclude)
            currencyCache[slot] = inst
        end
        local value = inst and tonumber(inst.Value)
        if not value then
            return "-"
        end
        local s, k = string.format("%d", math.floor(value + 0.5)), nil
        repeat
            s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        until k == 0
        return s
    end

    local function sendWebhook(title, description, color, extra, bypassToggle)
        if not (Config.WebhookEnabled or bypassToggle) then
            return false, "disabled"
        end
        local url = Config.WebhookUrl
        if not validWebhook(url) then
            return false, "invalid"
        end
        local req = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
        if not req then
            return false, "no request function"
        end

        local wait = 1.2 - (os.clock() - lastSend)
        if wait > 0 then
            task.wait(wait)
        end
        lastSend = os.clock()

        local fields = {
            { name = "Player", value = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")", inline = true },
            { name = "Uptime", value = uptime(), inline = true },
        }
        if Library.Tier then
            table.insert(fields, 2, { name = "Tier", value = tostring(Library.Tier), inline = true })
        end
        pcall(function()
            fields[#fields + 1] = { name = "Money", value = readCurrency("cash", { "cash", "money", "balance", "coins", "gold" }), inline = true }
            fields[#fields + 1] = { name = "Tickets", value = readCurrency("ticket", { "tickets", "ticket" }, "quest"), inline = true }
            fields[#fields + 1] = { name = "Gems", value = readCurrency("gem", { "gems", "gem", "crystals", "crystal" }), inline = true }
        end)
        for _, field in ipairs(extra or {}) do
            fields[#fields + 1] = field
        end

        local ok, res = pcall(function()
            return req({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({
                    username = "UZEX Hub",
                    embeds = {
                        {
                            title = title,
                            description = description,
                            color = color or COLOR_INFO,
                            fields = fields,
                            footer = { text = "UZEX Hub" },
                            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                        },
                    },
                }),
            })
        end)
        local code = ok and type(res) == "table" and (res.StatusCode or res.status_code) or nil
        return ok and (code == nil or (code >= 200 and code < 300)), code
    end

    pcall(function()
        local ev = Events:FindFirstChild("ReplicateFishCaught")
        if ev and ev:IsA("RemoteEvent") then
            ev.OnClientEvent:Connect(function(charModel, fishName)
                if charModel ~= LocalPlayer.Character then
                    return
                end
                fishCaught = fishCaught + 1
                Library.Session = Library.Session or {}
                Library.Session.fish = fishCaught
                lastFish = tostring(fishName or "")
                if Config.WebhookOnCatch then
                    task.spawn(
                        sendWebhook,
                        "Fish caught",
                        lastFish ~= "" and lastFish or "A fish",
                        COLOR_GOOD,
                        { { name = "Total this session", value = tostring(fishCaught), inline = true } }
                    )
                end
            end)
        end
    end)

    task.spawn(function()
        task.wait(4)
        sendWebhook("UZEX Hub", "The script is running.", COLOR_INFO, {})
    end)

    task.spawn(function()
        while true do
            task.wait(30)
            local minutes = tonumber(Config.WebhookInterval) or 0
            if Config.WebhookEnabled and minutes >= 1 and os.clock() - lastReport >= minutes * 60 then
                lastReport = os.clock()
                sendWebhook(gameName, "", COLOR_INFO, {
                    { name = "Fish caught", value = tostring(fishCaught), inline = true },
                })
            end
        end
    end)

    ---------------------------------------------------------------- auto rejoin
    local GUARD_FILE = SAVE_FOLDER .. "/rejoin.log"
    local FLAG_FILE = SAVE_FOLDER .. "/rejoin.flag"
    local MAX_REJOINS = 4 -- per 10 minutes, so a ban cannot cause an endless loop
    local rejoining = false

    local function recentRejoins()
        local list = {}
        pcall(function()
            if isfile and isfile(GUARD_FILE) then
                for stamp in readfile(GUARD_FILE):gmatch("%d+") do
                    local t = tonumber(stamp)
                    if t and os.time() - t < 600 then
                        list[#list + 1] = t
                    end
                end
            end
        end)
        return list
    end

    local function recordRejoin(list)
        list[#list + 1] = os.time()
        pcall(function()
            if not isfolder(SAVE_FOLDER) then
                makefolder(SAVE_FOLDER)
            end
            writefile(GUARD_FILE, table.concat(list, ","))
        end)
    end

    local function RejoinNow(reason)
        if rejoining or not Config.AutoRejoin then
            return
        end
        local history = recentRejoins()
        if #history >= MAX_REJOINS then
            pcall(function()
                Library:Notify({
                    Title = "Tạm dừng tự vào lại",
                    Content = "Đã vào lại quá nhiều lần trong 10 phút. Vui lòng vào lại thủ công.",
                    Type = "error",
                    Duration = 8,
                })
            end)
            return
        end
        rejoining = true
        recordRejoin(history)

        task.spawn(function()
            reason = tostring(reason or "")
            if reason == "" then
                reason = "Disconnected from the server."
            end
            pcall(function()
                Library:Notify({
                    Title = "Mất kết nối",
                    Content = "Đang tự động kết nối lại...",
                    Type = "warning",
                    Duration = 6,
                })
            end)

            local sent = false
            task.spawn(function()
                sendWebhook("Mất kết nối", reason, COLOR_WARN, {
                    { name = "Action", value = "Rejoining", inline = true },
                })
                sent = true
            end)
            local waited = 0
            while not sent and waited < 4 do
                task.wait(0.25)
                waited = waited + 0.25
            end

            -- Tell the queued loader to start the hub again after the teleport.
            pcall(function()
                if not isfolder(SAVE_FOLDER) then
                    makefolder(SAVE_FOLDER)
                end
                writefile(FLAG_FILE, tostring(os.time()))
            end)
            QueueAutoExecute(true)

            task.wait(2)
            for attempt = 1, 4 do
                pcall(function()
                    if attempt == 1 then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                    else
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    end
                end)
                task.wait(10)
            end
            rejoining = false
        end)
    end

    task.spawn(function()
        pcall(function()
            local gui = CoreGui:WaitForChild("RobloxPromptGui", 60)
            local overlay = gui and gui:WaitForChild("promptOverlay", 60)
            if not overlay then
                return
            end
            overlay.ChildAdded:Connect(function(child)
                if child.Name ~= "ErrorPrompt" then
                    return
                end
                local reason = ""
                pcall(function()
                    reason = child.MessageArea.ErrorFrame.ErrorMessage.Text
                end)
                RejoinNow(reason)
            end)
        end)
    end)

    ---------------------------------------------------------------- anti staff
    local STAFF_MIN_RANK = 200
    local staffChecked = UzexFilter.AntiChecked
    local staffHandled = false

    local function isStaffPlayer(plr)
        if plr == LocalPlayer then return false end
        local found = false
        pcall(function()
            for _, a in ipairs({ "Staff", "IsStaff", "Admin", "IsAdmin", "Moderator", "IsModerator" }) do
                if plr:GetAttribute(a) == true then found = true end
            end
        end)
        if found then return true end
        pcall(function()
            if game.CreatorType == Enum.CreatorType.Group
                and plr:GetRankInGroup(game.CreatorId) >= STAFF_MIN_RANK then
                found = true
            end
        end)
        return found
    end

    local function LeaveForStaff(plr)
        if staffHandled or not Config.AntiStaff then return end
        staffHandled = true
        pcall(function()
            Library:Notify({
                Title = "Anti Staff",
                Content = "Phát hiện quản trị viên: " .. plr.Name .. " - đang rời máy chủ",
                Type = "warning",
                Duration = 6,
            })
        end)
        local sent = false
        task.spawn(function()
            sendWebhook("Staff detected", plr.Name .. " is in the server.", COLOR_WARN, {
                { name = "Action", value = "Leaving server", inline = true },
            })
            sent = true
        end)
        local waited = 0
        while not sent and waited < 3 do
            task.wait(0.25)
            waited = waited + 0.25
        end
        rejoining = true -- stop Auto Rejoin from going back to this server
        QueueAutoExecute(true)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
        task.wait(8)
        pcall(function()
            LocalPlayer:Kick("Anti Staff: " .. plr.Name)
        end)
        staffHandled = false
    end

    local function checkStaff(plr)
        if staffChecked[plr] then return end
        staffChecked[plr] = true
        task.spawn(function()
            if Config.AntiStaff and isStaffPlayer(plr) then
                LeaveForStaff(plr)
            end
        end)
    end

    game:GetService("Players").PlayerAdded:Connect(checkStaff)
    task.spawn(function()
        while task.wait(5) do
            if Config.AntiStaff then
                for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
                    checkStaff(plr)
                end
            end
        end
    end)

    ---------------------------------------------------------------- settings UI
    Tabs.Settings:CreateSection("Tự vào lại")

    Tabs.Settings:CreateToggle({
        Flag = "AutoRejoinToggle",
        Name = "Tự vào lại khi mất kết nối",
        Description = "Rejoins and restarts the hub after a disconnect or kick",
        CurrentValue = Config.AutoRejoin,
        Callback = function(Value)
            Config.AutoRejoin = Value
            SaveConfig()
        end
    })

    Tabs.Settings:CreateSection("Thông báo Discord Webhook")

    Tabs.Settings:CreateToggle({
        Flag = "WebhookEnabledToggle",
        Name = "Thông báo qua Webhook",
        CurrentValue = Config.WebhookEnabled,
        Callback = function(Value)
            Config.WebhookEnabled = Value
            SaveConfig()
        end
    })

    Tabs.Settings:CreateInput({
        Flag = "WebhookUrlInput",
        Name = "Đường dẫn Webhook",
        CurrentValue = Config.WebhookUrl,
        PlaceholderText = "https://discord.com/api/webhooks/...",
        Callback = function(Value)
            local text = (tostring(Value or ""):gsub("%s+", ""))
            if text == "" then
                Config.WebhookUrl = ""
                SaveConfig()
            elseif validWebhook(text) then
                Config.WebhookUrl = text
                SaveConfig()
                Library:Notify({ Title = "Webhook", Content = "Đã lưu URL Webhook.", Type = "success", Duration = 3 })
            else
                Library:Notify({ Title = "Webhook", Content = "Đây không phải liên kết Discord Webhook.", Type = "error", Duration = 4 })
            end
        end
    })

    Tabs.Settings:CreateInput({
        Flag = "WebhookIntervalInput",
        Name = "Báo cáo trạng thái (phút, 0 = tắt)",
        CurrentValue = tostring(Config.WebhookInterval or 0),
        PlaceholderText = "0",
        Numeric = true,
        Callback = function(Value)
            Config.WebhookInterval = math.max(0, math.floor(tonumber(Value) or 0))
            SaveConfig()
        end
    })

    Tabs.Settings:CreateToggle({
        Flag = "WebhookOnCatchToggle",
        Name = "Thông báo mỗi lần câu được cá",
        Description = "Sends a message for each fish caught",
        CurrentValue = Config.WebhookOnCatch,
        Callback = function(Value)
            Config.WebhookOnCatch = Value
            SaveConfig()
        end
    })

    Tabs.Settings:CreateButton({
        Name = "Gửi thử Webhook",
        Callback = function()
            task.spawn(function()
                local ok, info = sendWebhook("Test message", "Your webhook is working.", COLOR_GOOD, nil, true)
                Library:Notify({
                    Title = "Webhook",
                    Content = ok and "Test message sent." or (info == "invalid" and "Set a valid webhook URL first." or "Could not send the message."),
                    Type = ok and "success" or "error",
                    Duration = 4,
                })
            end)
        end
    })
end

-------------------------------------------------------------------------------
-- Privacy: hide or fake the ID number shown in the top-right corner, and show
-- a fake name. Everything here is client-side: only your own screen changes.
-------------------------------------------------------------------------------
do
    local CoreGui = game:GetService("CoreGui")
    local realName = LocalPlayer.Name
    local realDisplay = LocalPlayer.DisplayName
    local realId = tostring(LocalPlayer.UserId)

    local function digitsOnly(text)
        return (tostring(text or ""):gsub("%D", ""))
    end

    -- A fake ID is generated once and saved, so it stays the same between runs.
    if digitsOnly(Config.FakeId) == "" then
        local digits = { "1" }
        for _ = 1, 10 do
            digits[#digits + 1] = tostring(math.random(0, 9))
        end
        Config.FakeId = table.concat(digits)
        SaveConfig()
    end

    local function fakeName()
        local text = tostring(Config.FakeName or "")
        return text ~= "" and text or "Player"
    end

    local function fakeId()
        local digits = digitsOnly(Config.FakeId)
        return digits ~= "" and digits or "10000000001"
    end

    local function replacePlain(text, target, replacement)
        local out, from = {}, 1
        while true do
            local s, e = string.find(text, target, from, true)
            if not s then
                break
            end
            out[#out + 1] = string.sub(text, from, s - 1)
            out[#out + 1] = replacement
            from = e + 1
        end
        out[#out + 1] = string.sub(text, from)
        return table.concat(out)
    end

    -- Longest name first so "Bob123" is not half-replaced by "Bob".
    local names = { realName, realDisplay }
    if #realDisplay > #realName then
        names = { realDisplay, realName }
    end

    local function disguise(text)
        local out = text
        if Config.FakeNameEnabled then
            local fake = fakeName()
            for _, name in ipairs(names) do
                -- Skipping names that appear inside the fake one keeps a label from growing forever.
                if name ~= "" and name ~= fake and not string.find(fake, name, 1, true) then
                    out = replacePlain(out, name, fake)
                end
            end
        end
        if Config.FakeIdEnabled then
            local fake = fakeId()
            if realId ~= fake and not string.find(fake, realId, 1, true) then
                out = replacePlain(out, realId, fake)
            end
        end
        return out
    end

    local tracked = setmetatable({}, { __mode = "k" })   -- label -> { original, shown }
    local hidden = setmetatable({}, { __mode = "k" })    -- label -> its Visible before we hid it
    local watched = setmetatable({}, { __mode = "k" })
    local roots = setmetatable({}, { __mode = "k" })

    local function refresh(label)
        local entry = tracked[label]
        local source = label.Text
        if entry and source == entry.shown then
            source = entry.original
        end

        -- 1) hide any label that shows your real ID
        local hasId = string.find(source, realId, 1, true) ~= nil
        if Config.HideId and hasId then
            if hidden[label] == nil then
                hidden[label] = label.Visible
            end
            if label.Visible then
                label.Visible = false
            end
        elseif hidden[label] ~= nil then
            label.Visible = hidden[label]
            hidden[label] = nil
        end

        -- 2) swap your name / ID for the fake ones
        local want = source
        if Config.FakeNameEnabled or Config.FakeIdEnabled then
            want = disguise(source)
        end
        if want ~= source then
            if entry and entry.original == source then
                entry.shown = want
            else
                tracked[label] = { original = source, shown = want }
            end
            if label.Text ~= want then
                label.Text = want
            end
        else
            if entry and label.Text == entry.shown then
                label.Text = entry.original
            end
            tracked[label] = nil
        end
    end

    local function isOurs(inst)
        return inst:FindFirstAncestor("UZEXHubUI") ~= nil or inst:FindFirstAncestor("UzexKeyPrompt") ~= nil
    end

    local function watch(inst)
        if watched[inst] or not (inst:IsA("TextLabel") or inst:IsA("TextButton")) or isOurs(inst) then
            return
        end
        watched[inst] = true
        refresh(inst)
        inst:GetPropertyChangedSignal("Text"):Connect(function()
            refresh(inst)
        end)
        -- The game may show a hidden label again; keep it hidden.
        inst:GetPropertyChangedSignal("Visible"):Connect(function()
            if hidden[inst] ~= nil and inst.Visible then
                refresh(inst)
            end
        end)
    end

    local function watchRoot(root)
        if not root or roots[root] then
            return
        end
        roots[root] = true
        for _, descendant in ipairs(root:GetDescendants()) do
            watch(descendant)
        end
        root.DescendantAdded:Connect(watch)
    end

    ---------------------------------------------------------------- fake display name above the head
    local function applyDisplay(char)
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            pcall(function()
                humanoid.DisplayName = Config.FakeNameEnabled and fakeName() or realDisplay
            end)
        end
    end

    local function applyAll()
        for label in pairs(watched) do
            if label.Parent then
                refresh(label)
            end
        end
        applyDisplay(LocalPlayer.Character)
    end

    ---------------------------------------------------------------- start watching
    pcall(function()
        watchRoot(LocalPlayer:WaitForChild("PlayerGui"))
    end)
    task.spawn(function()
        pcall(function()
            watchRoot(CoreGui:WaitForChild("PlayerList", 60))
        end)
    end)
    task.spawn(function()
        pcall(function()
            watchRoot(CoreGui:WaitForChild("ExperienceChat", 60))
        end)
    end)
    local function onCharacter(char)
        watchRoot(char)
        task.wait(0.5)
        applyDisplay(char)
    end
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.spawn(onCharacter, char)
    end)
    if LocalPlayer.Character then
        task.spawn(onCharacter, LocalPlayer.Character)
    end

    ---------------------------------------------------------------- settings UI
    Tabs.Settings:CreateSection("Quyền riêng tư")

    Tabs.Settings:CreateToggle({
        Flag = "HideIdToggle",
        Name = "Ẩn ID của tôi (góc trên phải)",
        Description = "Hides the number that shows your user ID",
        CurrentValue = Config.HideId,
        Callback = function(Value)
            Config.HideId = Value
            SaveConfig()
            applyAll()
        end
    })

    Tabs.Settings:CreateToggle({
        Flag = "FakeIdToggle",
        Name = "ID giả",
        Description = "Shows another number instead of your ID (turn Hide off to see it)",
        CurrentValue = Config.FakeIdEnabled,
        Callback = function(Value)
            Config.FakeIdEnabled = Value
            SaveConfig()
            applyAll()
        end
    })

    Tabs.Settings:CreateInput({
        Flag = "FakeIdInput",
        Name = "Số ID giả",
        CurrentValue = fakeId(),
        PlaceholderText = "12345678901",
        Numeric = true,
        Callback = function(Value)
            local digits = string.sub(digitsOnly(Value), 1, 16)
            if digits ~= "" then
                Config.FakeId = digits
                SaveConfig()
                applyAll()
            end
        end
    })

    Tabs.Settings:CreateToggle({
        Flag = "HideNameToggle",
        Name = "Ẩn tên",
        Description = "Hides your name tag above your character",
        CurrentValue = Config.HideName,
        Callback = function(Value)
            Config.HideName = Value
            SaveConfig()
            pcall(UzexFilter.ApplyHideName)
        end
    })

    Tabs.Settings:CreateToggle({
        Flag = "FakeNameToggle",
        Name = "Tên giả",
        Description = "Shows another name for you on your own screen",
        CurrentValue = Config.FakeNameEnabled,
        Callback = function(Value)
            Config.FakeNameEnabled = Value
            SaveConfig()
            applyAll()
        end
    })

    Tabs.Settings:CreateInput({
        Flag = "FakeNameInput",
        Name = "Nội dung tên giả",
        CurrentValue = Config.FakeName,
        PlaceholderText = "Player",
        Callback = function(Value)
            local text = (tostring(Value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
            Config.FakeName = string.sub(text, 1, 20)
            SaveConfig()
            applyAll()
        end
    })
end

-------------------------------------------------------------------------------
-- Home: live Session panel (level, balance, rod, bait, fish ...)
-------------------------------------------------------------------------------
do
    local sessionStart = os.time()
    local values = {}        -- cached ValueBase objects of the player data, shallow ones first
    local lastScan = -1e9

    local function norm(name)
        return (string.lower(tostring(name)):gsub("[%s_%-]", ""))
    end

    local function scan()
        lastScan = os.clock()
        local list = {}
        if PlayerData then
            for _, d in ipairs(PlayerData:GetDescendants()) do
                if d:IsA("ValueBase") then
                    local depth, p = 0, d.Parent
                    while p and p ~= PlayerData do
                        depth = depth + 1
                        p = p.Parent
                    end
                    list[#list + 1] = { inst = d, depth = depth, name = norm(d.Name) }
                end
            end
        end
        table.sort(list, function(a, b)
            return a.depth < b.depth
        end)
        values = list
    end

    local function resolve(keys, exclude)
        for _, key in ipairs(keys) do
            for _, v in ipairs(values) do
                if v.name == key and v.inst.Parent then
                    return v.inst
                end
            end
        end
        for _, key in ipairs(keys) do
            for _, v in ipairs(values) do
                if v.inst.Parent and string.find(v.name, key, 1, true)
                    and not (exclude and string.find(v.name, exclude, 1, true)) then
                    return v.inst
                end
            end
        end
        return nil
    end

    local function fmtNumber(n)
        n = tonumber(n)
        if not n then
            return nil
        end
        if n ~= math.floor(n) then
            return string.format("%.1f", n)
        end
        local s, k = string.format("%d", n), nil
        repeat
            s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        until k == 0
        return s
    end

    local function fmtTime(seconds)
        return string.format("%02d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
    end

    local STATS = {
        { key = "Level", keys = { "level" } },
        { key = "Balance", keys = { "cash", "money", "balance", "coins", "gold" } },
        { key = "Crystal", keys = { "crystals", "crystal" } },
        { key = "Essence", keys = { "essence" } },
        { key = "Ticket", keys = { "tickets", "ticket" }, exclude = "quest" },
        { key = "TraitReroll", keys = { "traitrerolls", "traitreroll", "reroll" } },
        { key = "FishCaught", keys = { "fishcaught", "totalfishcaught", "caught", "fishcount" } },
        { key = "HeaviestFish", keys = { "heaviestfish", "heaviest", "biggestfish", "maxfishweight" } },
        { key = "BaseHP", keys = { "basehp", "basehealth" } },
    }

    local function readBait()
        local hotbar = PlayerData and PlayerData:FindFirstChild("Hotbar")
        local baitInfo = Info and Info:FindFirstChild("Bait")
        if hotbar then
            for _, slot in ipairs(hotbar:GetChildren()) do
                local nameValue = slot:FindFirstChild("ValueName")
                local name = nameValue and tostring(nameValue.Value) or ""
                if name ~= "" and ((baitInfo and baitInfo:FindFirstChild(name)) or string.find(string.lower(name), "bait", 1, true)) then
                    local qty = slot:FindFirstChild("Quantity")
                    local count = qty and fmtNumber(qty.Value)
                    return count and (name .. " x" .. count) or name
                end
            end
        end
        local equipped = PlayerData and (PlayerData:FindFirstChild("EquippedBait") or PlayerData:FindFirstChild("CurrentBait"))
        if equipped and tostring(equipped.Value) ~= "" then
            return tostring(equipped.Value)
        end
        return "None"
    end

    local function update()
        local stats = Window.Stats
        if not stats then
            return
        end
        if os.clock() - lastScan > 20 then
            scan()
        end

        stats:Set("Session", fmtTime(os.time() - sessionStart))

        for _, def in ipairs(STATS) do
            local inst = resolve(def.keys, def.exclude)
            local shown = "-"
            if inst then
                shown = fmtNumber(inst.Value) or tostring(inst.Value)
            end
            stats:Set(def.key, shown)
        end

        -- fall-backs
        local session = Library.Session
        if session and session.fish and not resolve(STATS[7].keys) then
            stats:Set("FishCaught", fmtNumber(session.fish))
        end
        if not resolve(STATS[9].keys) then
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                stats:Set("BaseHP", fmtNumber(humanoid.MaxHealth))
            end
        end

        local rod = PlayerData and PlayerData:FindFirstChild("FishingRod")
        stats:Set("Rod", (rod and tostring(rod.Value) ~= "") and tostring(rod.Value) or "None")
        stats:Set("Bait", readBait())
    end

    task.spawn(function()
        while true do
            pcall(update)
            task.wait(1)
        end
    end)
end

Window:SelectTab(Tabs.Main)
