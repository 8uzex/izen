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
Library.Language = "Tiếng Việt"
Library._TextObjects = setmetatable({}, { __mode = "k" })
local EN_TRANSLATIONS = {
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
    ["Cá"] = "Fish", ["Mở khóa tất cả cá"] = "Unlock All Fish", ["Mua mồi"] = "Buy Bait",
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
local EMBEDDED_LOGO = "iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAABywElEQVR42u19d5wkVbX/99xb1WnSZlgyKGkRBBUwkUQkKCrgIorPQFQUEcGIz9k16wP0PQTUh+kp/oQ1YyBHBQFB4pJ3l7Bsmp3Yuaru+f1Rubs6TndPz24Xn2Znerqrq2/d7/d8T7jnAr2jd/SO3tE7ekfv6B29o3f0jq3ooK3r6zIBAPfue29CVz8L98ZrFoN8eBi0z0rQ40tAuB1YuQh87bVQRNTDfu+oPYOY6eSTIZYssfGxciV4yRLw8uXgLY0cZj0BMJhWLIV4fCMIh0MtX06q0muHh1lgDWLzBhHLjE/qhRgzMLRVTOrJHq4rjMsEEgkiwxg0Fy9GYZ99YJx8MllV5xAgVq7cMozKrCSA4WEWuB0iCvA/HebExg3Y2SgWXqkUXgmoXRSwo2JrGwEaAtCniFMAx5nBXJVcokaKUPd7ABBVdjm4yl1p5DO850Wj5Fl5BtS85oj3qSbeU/VzuPw9tceFIz+rxucQCRgAZUiIDLOaAORGCLxEJNYIyGcQ056LAc9fcglloggBqG58egTQAlm27HDIZXfAooAMu+zjPD9dNA8wLOtNYD6Q2VrCzDvE9H5dlwAJ/4u6E95Ffd3ApHonXzSQucH3oIn3NEUYzYCfGgcyO0QY9fpGiaau70kNkpnznuA1un9TCrAsoGikLYDWEuhJkHa/kOIfytD+fcUVtL7E/ZSziQy6ngCGh1nssxJ08gpfln37bN7dUsZRlmkdo5T1ek1LLoxpAkLY4FYKMCyovDGhsoVR5PKbKFMYRa6wiQpmGkUjTYaVL5+V9VjMRkaWbZBRxDBzE3ekGa3pG1Gq2/pHfRpPd2yowfcwAHIkGgUIvOb3bIwwyDYukFocsVg/a3o/4vEFnEzORyKxgBOJ+YjHBkloQgphTxmlANNkmFZulIjul1rseqHkDf/93/SEe+6lS1kCwIoVld2JHgFUOZYuZWkHXmwm/c45vK2Vs95pCfNkZVlvTsRScekA3rSg0oUxNTb5DG2YeJw2jD1KI5PP0ETmBWTzm1Ew0zCtAphNMKuwVGxosKLlP5WpFZdbHOhTA7eCp3crO3VDedq5FK45KTnwP27ou3Hz40cEIg1SxqHrfUgk5qO/f0cMzXklz5+/L8+b/yoeHNydk6kFQtMg4BBCIZ8xhdTuIaGtiAv5h0svpRddVbB0KUS3EgF1I/CDwZVvnVF8vaXwEaWsE2N6YoEU9u0tGqa5aeJJen7jP8SaDXfRutGHMJF9CUUjDYAhhAZJOoTQQSTsRyX92sqhIp8sapqtad4GmonbR1X87haSQIQL2LZzl38Og5nBbEEpE0oZUMoAgaDpKfT1bY/5C/bD4u3ezIu3O0TNmbs3x2JxjQhQDBjF3ASR9kcp9Z9c9l26o5uJoGsIwAmmwLX4F5/ORxlsnW+q4rGJWBIAYCpYGydW4umX/iaeXvs3Wjf6EHKFMRAJaDIBKWIQJJ1AnX8jp5f5b2yIqG63gmYH4DumDririMAbcYId4yM7eMSsoFQRppkHs4V4fAjz5u+LHXc+mnfe5e1q3rxXQWpSggCjaIAIt5Gk711+qf4nL5a1DNQtMYIumFFM1y6FcH38b5xmvI1AFzL4KE1qAIBcYcp8Zt2N8uFVv6LVG+5ErjAKIWKIaUkI0p0pp5qYHK0ZmnaAfvpgp5bDunOk0A4yaN3csO+3ABFBKROmmYVlFRGPD2HbxW/EK/d4H++08zEqkZwvQCBLKbBSd2ma9l+XXULXuUp3xQqoma4rmFECsAfBBv53Ti/sp0DLFNMJmtQABk/mNqqHV18t//3cL7F+7FEAQFzvhyDdAbya0WFpNfCbA/1Mczi3kQxaTQTtwZrrYiplwjDSYFaYO28v7L7n+7H7Xh+y+ge2IxCEshTA1g2QGL7ikti9pRjYigjAt/rDSzf0pwbmfdFk61O6jCcJUJO5EX7wuZ/J+5++CiNTT0OXKcS0FABAsdUVw1Ef+KnFoJ8tWVtuMRlwC0mgfURgzwtpu6tmDqaZwcDgLthzyWnYa5/Trf7+xQRAmEbBhJRXGsgs+/F354zOpBro+IwaHmbh+j/fOoOPZmVeKoW2hAGYZsF6cNX/yb8//l1smngSMb0fuky22dq3w+q3EvjU7ExsMaa5rYTQeSJoL9bsbIKEaeZhGFMYGNwV++7/Sey1zxmWpvdJEKAsYzWDPvvD7+m/mSk10FECuHYpy5NXkPXf53I8lzG/qZjPF0KHJJjPrb9T3vzQMK3ecCd0LQVdS4HZarFf327wUwtATzML9LYTQyvIgGcFCbj3UwiHCIpTWLTtQXjt65fxjrscY7GCBjBA1v8WpHbBT/6Lpg4bZu2O5WRucQQwfNht2vI7jjC/dfrk3szJn2hCe71iqFxxDLc98jXxz6d+CMUmEvpQhyx+A9a6W4BPs8QFYO4RQcS9EyRhFKfAYOyx9wfx2oOXq1TftgwBaVnmY0Lwh6+8JPZAJ12CDswo39//zmnGSRbUVUSxOZqA+dy6O7Xr7v8UXt78EFKJeQAEmK2uAf50wV8b+K0HPbXt1jaZ8W8BGXBThc7dqAbsgCEA5HObMWfennj9oZdgp12PMy3FGisjB5If/9F3tZ8OD7NYvgyMNi82aisBsFNtTiD+xkeKFwkhvqYUIARZf1/5XXnzQ8ug2EJcH4RSRld5PjMKfKIGvsXMZwG4ZWQw00TQuRicEBoMIwtWJl594GdxwEFfsgAhhZBgmN/5wSX654BwzGxWEYB74cPDLJIvmJcLTfuoZSqVN8fpT//8OD285hokY3NBJDto9Wca/FTjT61wJbrAA6hHunNzQNySSMBXAyPYadd34JC3/pCTqe0USUjTNK8ZH9Q+uGI5FdtJAtRO8F+7lGPP9hf/n67FTmQFc9Pk0/Kauz5Aazc/gFRiAZSy0Nn+PK0Gv1vrSzWscSPA51kH+MYIgVpABBxwSKLqrXnWkICtBnTk85sxNHcPHHHMLzF/4QEmETSljBtjhr70sstosl0kQO0C/yXnc7I4Yf1eCnk0GObzm+7Rfn3n+zGZW4dkbA6sjkr+6YKfKp6DmgJ9s5Z+NvWeoMajCNy4dY9WBNwCIug8CRSLk4jFBnH4Mf+H7Xd+mwmGppR1b66YefsvLh/a3A4SaCkBuD7//5yLWDZd/JOUsbcRYD798s3a/7vjvTCtInQtBcVmV4G/YeBT0OZT/Z9XN/C5Bh54psI6TX02UfjvNV0Err8bgq8FotREdSLoNhIgIWGZBTArHHb0z7Db7ieZiqEpNu/LGtpRV7dBCYhWgv/kpSsEAGTSxV8Fwf+rO06GpUzoWnIWgJ/KHkRuYYf9ELBXFhJExOvdBjGBn0kAJMv+RiWP8Dko9Jnhy6Qqj06MZ/XPLh2vsvEs+96l4+V2con4W8mYk3MvhFObHx6v6uMz3fRuy6lVWZAyDiE03HnDh7Dqmd9qEDCF0A5K6sXffmiYEw5zUWfQ0Yj0P4y15XeQ+Y2PFH6ga7GzWcF4Zt3N+q/uOBnK+WKdDfY1C/6APY74u/tf+fp0u6UMVbH6HNIUVGJjfAvGNSwYc21LRS2uGYi2llRF4FBlx4aiNA+XjVHUl2XvOS4bV3b+Kx+v0ue4u5WAs66AlYFDj/45dtnjJJMAzTCLv/nxd+NLW1knQK0E/9c/nP9iTI9/nRWM50f+qf/s5rdDKXPWgd+3Wv7zLvDdmU5lFjEqsEcNDjZHTPTKvXnYaZdDM9LsnJzL44pjSREuUz0jwZHPVJL4HDFeHHAz/H/Lgc5dTwJKGTjy+N9ix12PNgDoRjF/6Y+/l7xgeJi15S2oGJw2AbjlvV/7SP4ETei/IxbmSPoZ+eMb30aZwibEZKrNC3imC/5qVt+dyI68LLH2rhcVfr6ETCJiBRxljZgrA71EHQRrQ8ITl9twi6ufMzhezCUwr0YMVB5fiRqjsrHiYDgxAHIOkwFzqRrgmmqgG0nAsoqQWgJHn/A3zFv4GlMIaKaRP/PH30te1Yqy4WnNDjcg8e2zeXerWPwXQesvmBP0k5uOpnVjjyChD80Sn78U/ORNRxv4FAI3eT4pAn8L+p3l8K80mcoCYhyY+oHJancXDhIBlwQLK6XE2je+pcE9twuS1zot0EXUJ1AKdE2qEmgtcwzCJOB17vHbd/pjwgEdwOVqIEwC3e4OSJhGBn2DO+GYk27mZN/2CmyYJuGQn10Su3+6C4imQQB2ie+6baGl04W7pIgfCMC65s73y0fWXIO+xMKuS/XVC35/Igu/tVcA+K4iCPn+RGXWzIZjKSgpYiJxqP9dGODOBOZyKctlk7p8kk63lqBSDj88XhHPUTBQV+JSUVQVY9S4ULC3U/iquMTqM3skwFA+UQTGL0yas4cEhNBRyG/Gdju9FW955x+UFDGhVOEZGUscuDiBqWXLwM3uT9B0FsCt75+ayn9T1+IHagLm31deKh9e82uk4gtmLfhd0yY88LsxZgkiDYIkSDg9BklCCPtBJCFIQpAGKZxehEK3exMK3XtOCM1/kA5Bmnde71zOv4Kc80I668ztKDiRcK7LB5arVCgQGW9FIVHUOcvJkpyqNgE410rwx4SE/7C/lwYi3fnepeOiB8ZLc8bQ+d0d/5JxJxLOPQmMF/wxEp4CCY9XJfXRbdkBpQzEE/Px0prr8dA/vyJIkCm1xO5GMX/Z8uWkDl92u+yoAnD9/q9+JPdWjbSbhNCs1evvkj+75ThIEZ8Blmwmz0+enxX8XQSbh5JNAyAnXUXC+YvwJr39fufZkNVDBetGJdabS1SAI2Wd7sWe9WLfsjGzYxl9K1euBDig07mJW+28xzsfRVh+CpxWeOMZbMDqvp68MaTIgCBFjFF5PsT+nooD6sjp0wenJZw/dsrpAG3/Xu4SuOOlKoceuzAmYBQncfg7foOdXnm8yQzNUsX3/vSS+LXNugINEwCDadkwqP85JAta/kFNJvbIF8bU/950pNg08RRiWl9X1fZXZnNRkiuuBH7pSH7hWxHX6ni94UTAMgYnOEWIW4qQnu7kVIFJzb6cZeVLVmYo53X+pHfORfUEBafr95Pn2xPC/fHII0snSEoCIlDT4ILfJU0qs8C+0xQF/zIQOwC33QHLAbwqIQUVWF7OtpMQAr27PVR0bU03kYAdFMwjmdoWx5x8h0r1b0eWVVivI77f4gGMAn5T3ba5ACuWQixfTqqo5y+Ka4k9NIJ566NfF+s2/xsJbWAG0n3NgT8qAl0Kfk/KBiQ/BaU8OXKVXImqe63IpfeIQYgYhIhDirj3nJQx52+64wo4ryXfdRAkISF96euQjXBcAHjS189KRGc4qMlHBb/fLbYR5BQ5Ucjyk+sKISDXXblPsZJx8sfCHps4hIhDiOBzzpi77xX++wVpjttkuwu2WyFslwMyoDyEm8+xx69sjESDc6jzB7OCpvVhamIVHvzHRYIIStfiiw3OfXP5clIrVzZu0Bt6gx31B3/rdOylVOFBTcRjqzfcRT+55VjSRaIFm0W07vKrl/eG/UDyJgX5/r8Dfgj3d82ZVMKf7CSdv4mw9QsEEf0QfmCLm0C02rNgAcvlW33fginXksHy21N7SoBDSqDMDWjROPvjhXCQzyUljzSFBzzhukkkQkoKXiCVypSYN1beN1JlwT9GcGyskKVnZW8Ao2ABisGw/N/ZdSNUSev4UpesESXQ+ZLhYn4CRxz/G95p9+OVYRRJCHrzTy6O3dOoK6A18sErV64g4GRlmOlvJ/S+RNEqWDc9NCyUMgEpgC6R/vWDH94E9iybB37hgF864BfQtZhHAsINcIXiAxSKCYQyCITQLjdBn92X/oFJzMremIIVTMuAYAuKydluzPKCcp7iIi8fGJDpLRzrcII/BH4Kgt8ZE0ESmgwqF0dJeXGAIHGWp0xLC3v8bIgKANgnSostp4WcBcMkQJkQDCihQMp2j4gZTApgezdQ14UgIq+oqhKg/ddUmlcdJAFmCKnhoXuW0TY7HoZYfFAYxezFYH7zkmWN72DXUODv66cZRwjgVk1q1j+f+rH8/T1noS++oMP5/uks7glbMxGwRLb0D0SWSTiS3N5sJJPOASwgheZLTXeCu+ogQAZexWDZzpgcsD4++JUDepsILKeASqGvPwkELZ33bwAEJZastgqgOq1YedTc/1lAiIBld9wlF/SZTA7MLlnaGQIRGFtPCZRmYqjE6pbFQ1RgjJQHfItNMFvo60uCiO1yWrbC4+aoAXeMVCCwOj0V0OF4gNBQyG7Caw75JvY7+HOWUiyVKi796SWJ3zSiAupWAI8vsb+dsor/GYulMJkbwd9XXoyYlgpItG72+6nsx1A0OmiV3EU/TgoLDKT6+vDRs09HKpmCYvj+bjDIFYp8V14tyF7giUsIwY9kMysQAdlcDr+6egUy2QwEERTMUKCc2A5fEVQoCGhbrFaQanghUsAJ8NSPHQD0LT8goGkxnH3W+zBnzhxYFjtpzCpBQIK7k2pJIoA9NRCqjeBAft8hBBDDtAxcc+21GBsbBUkNsNwN3dn285nB5NdVeJUGISMerQSqq4AOxwOUBT0+iCcfuhy77vk+DMzZiY2i9aXDhvkPS1A/IOsigGuXsjx5OVnf/LDxFhZ8BBjqwed+LjdNPIW++MKusf71Luv1gevL2VAQ0JWzQkIIActk9CX78ekLzsHAHAKsqmrRe77iSnWu/I0CRg9SB8Y2M37/u78ik8lCCHcCA8oDRHAFoQqcUYUj6xSVZquQ+gNKJHEgSEaB1YoeHUgIInu8SAJsE8CZZ34Yu+w6hHwhkI3k+saknrEM/Z0BIYFiEbjhhhuxefMoYpqEKRikAlkUCD+FSm7yxB47rqOasntcAYaQcWSnXsJTj/xAvvaQbygtlnz1zuniicsviV+79FqWK06urQLqIgDX+ptc/HxcpjCR3cT3P/2/iGn9XZPyq8vye917gkTgT2p/KWlA2kNCEAAWGB0dB/MgTFPZ7wxghGsoQa5DJQbnFTND1wTGxiadmIMGQQCT47ey3S+SwSCnmartdnCAEDgC8PW1LIuW/OyPXTD67yzhDcZPBCTGJyYxOtqPQkFVLEqaFvgD6yOYGUIIGEYBrMgpNvLTtoIUlENYzI57xhyaFeVBbOrqeICrAlat/D/svu9ZPDhvF2bD/OzwMP9m2VKoevz7mmnApUtZLl9O6munFV9HJI4kQD28+mo5Mvm0s2lHN3epiV7OWyku4JX1Cj+qLwLVbFJKaJqEdH6Wmv2vkM7vMvC3qEeVv4mIvwn3/F5wzUltBaLsvstSqchmOo/yVKmf8qOSAKhLltKpk6j9vUUd4yVqjKWoMJaC/NiDHdB1ewwgpPRKZ8c0E2XTeM80VED6ZTz7+I8lM1jTYq9dncm/lYh46VKW0ycA9wdlnhWPJUS2mFb/fu4X0GWnff9GrX897btK5H/JpPYmkEMCURa8luWv18pVep7YzasLr+RVBPL/VFbmKiIATFUCooTavQxLG3pQ6LMFBa7JyZC4Pv90xqShhkgBD4cQIEySgQIk8uoBKGJsiFBhC3lqQHF2PhagxQaw5slrkMtsUpquARZ/DACWLKltnUV1fmE6eQVZwx+YWmQxvwcAnnn5Brl+7FE7+NcFm3cQNbvxZsnS37Ky3oB1c9OCbQJ/rYkuvHUGMpx5oECHHKKSpcf1WHfUrRaobGFPoArSrfpzC3CcQqB2g79s/L3q56Ar4tYoBLINFFjNSc30bahn7nVOBUgtgamJ5/Dis3+QTjjkmA9emHuF25W7aQJYNgwJADEZe1cilpprKmU9vPpXs6BVbS1FQIjuA+BHqd3ott9qSoTe0ynw2+6qn5r09qovyziQ9zcuk+6lWqfWf+UNPDh4Jipvg+Zem7coSsjOgb/kCbcwyStAIlGepQlNgYj5UCegu0IJsIIQMax56tdkFA0rFk8moOi9AHB7DYzXcgEUAFgw3icFeOPEk1i9/k7E9f4ONvloh/QP3vvghEY4h+/08hOQgUVDnQO/f4nB2oRwDCDYF8/+XiK4bq+iv1vPmEetLwz9zUudUnlcwi1U6jD4vfEKVmzCvz6U9Qr0/88NGZHuiQUwK2ixPoysuw8jG/4lSDBYGScvvZblHcthNUUAbrOP73ww9woG3sgMevqlv4lsYTME6bMQ/FxB8gWkM4UWvSK4iMWNAXTM8vtXHAC7H5xEYKlyEKTBofDkLgWIrsGHZy1DoyUCvRKCacFgmbQIva/d4A8nOYPAD1UuOAu8Kkl/EZ4rdZJAN7gCbuOQtav+LFgRk5D7Je43DgCIly69VjajAAQAGBLHJON98aJpmk+vvZ6kiHd55L920C+8VNZXtRTwp0vtnztU3CHwl32PUE19AISBBTqhR/D7TSMH4KkjIkCIQPOTEo1AItzJlwTABOqg5Q+6ACB/AVDYbRLhomOqHvCjlm4b3143QGpJrFtzIwr5jBWLJwnKegcAbFyylJohAAUAinGMFMCmiSdp3ei/EdOSHcr9T9/6V40BUFRcoDwmEGzAgRkAv/1EYHFNqCmHX8LsrQYEIsN1zd4BihLMnqII1E6UOQzCn0QdAH9QMaGEICmyTyOFya3pudQdrgCzgtSTmBx9EmMjD5PtBlhvA5iquQGiUvR/+XJSw6fzPIvNNzCA5zf+Q+QKYx2U/62O+kfdFC7p7x++XcHgkScPOwn+4HXAX2/vL8EN4BGVOu+2ohag8lkZYXfBJwTRMcvPTrDU/SVqPwIqATqVlXI2ut9j96UGbTcgi40v3i6UIoCx/4c+l98ZIK6UDYh8csVS+3lN5V+ja8n5hgles+EusgNhnZD/02PY6sU+CMvk0rBX1EYWRE41IFpfyloN/BwQ2iQCrkk4ql9+S0WFcWymAKi0viDQEckT1BS2qhRwTbj94AecAshAGtBXeSLQ47ECmEviHPUXCXVZQJAZQurYuPbvZJqWpSf6kkqJg+1swO31E8DjS5xV68xvimkSmcKYtW7039BkooO5/1ZJ/1I0hdecl56TPZUrwj5lBYvYbvCH/PCItfihB1GNGgCU7J5T/qisHgIE6Q2SKD93hLVtN/ijMwEiVPQdTmGWuAJcMjfqUAXdqAKYFaRMYHzz48im17HUACjrEPuvhzcUA7D9f/DBQgCjk8/SZHYtpIh1IABI03x3FX+OSlf/RZW7hvRAWc/AjoM/OH0JESCNACqhBsCrk2z0+0pAxKUxFfKCfmGd0iHwR+xKFMz3l/ccDFc1Rs6Rht3KmVYBtgIoZDdhYvNKJwijXgcAleIAEQRg+/+XLH0hCfDezMDG8cepYKTt6q4utv5VwV+z2iuih39wMxASMwJ+Lgtalpf5hkqCqdp6h+b9/7B/T2W7H1FAclec6B2w/D5xV4hjcD1QpCbnWBfEAkjAMgsYH3mEmAHFao+zPs0L3HYoNQlgeNj+RpmBHXcCY3ulgA3jj1J3+v7NnZpqlMP6YIoeps6CP6q0V4QBT1Rn0A9ozv+vRAglG6egND3YOfCXL86j0B2t5NsHr7czhrrN5OB0O5oYeYwsC0wyPregGa8EgGXDqE0AbmNBjcxXxPSUbphKjUw+TYK0Gcv/T9/6NzHwXmOK8MRg6iz4S4kJZa4A6gBwuTT2AYw6/f/KhBBWBhH+fyd8/lLFhIh0X93zgCJditmhAmw3YHL8OZhGXumxGCzFe9iBwHK8lz2xxAkAmmztrktC3pxSE5kXIIWO9qqAdlr/aumfiGug6NhAle7R7QN/IBOAshhAJYCGYwaV4wAVgFyyzTaVbetbKcCIyLhKJ2Q/k6/MKOJc1fEYVflHbZyf7Zvrdl8EHbn0yyjkx1hIQFnmHpVeXx4DuN0NA6pdSADZwiiy+c0QQp+RdkjTtv5Uq3VPRBCs5OUEqn2KNoLfx1i5lfZ3xfFbkxFFLdiZ3iNYUEMi2Aw0gnycz2dG5bZkLQS/5wJE3TMqaXJC1cFNUZWijQabZ1QFMEhoMApjKGQ3ulnZXQBg0cry0St3ARZ5hm5HAMjlR6hoptHeGoDOsGvlQpnwj1zp7zMB/jJL7YNSCAnLNFDMZWBZRQgpavj9qHstYCXZL6SEMk0Y+TQs0/Aapkb53kCHwF/xb/73Dyf2au2URDM6T6dvNAUsM498bpNtyyy1g6PuaxPAtdc61ZtsLSIA2cIITCtfwvbdbP2jpX89N5yauWFtB38FS0UCxXwaA3O3xa77vBlzFuyEQjYdqhqMXuJbOwhYcemwkChkp9A/d1vstM8hGFqwA4x8piwjULUAuU3gp4ouX5R7RxW3Yq8+h2aLCiAoZSCfWW83iBNinru4ryR/W94TkMguG6Q1mTkMIFPcTMrpN9f9S4Cogb8E88FcZUcdVO2h2Rnwh6v7hZDI56aw3yHvxcHHngk93g/TzOH+m67CPX+5HPHUAFhxxHdtdAwDrobQkE+P44AjP4KD3/kJ6PEBmEYOD9/8Czx6y9WQiTgqtRLriOVvAGf+Hg1UNf6LJv7aHTAgMCsUcqOOG6bmPJdGEkCmhgJw2GENYgD6QEDRmHKq/6ijoG2l9aeKQZ1wo8vGgi2dtPyBDayERLGQw7a77odDTjgfUkuiWMgDpOHN7z4XBx3zUeTS43ZDjiaXAKMkhiCkhlx6FPsd9gEcesoXILSU85k6DnzXWdhhyRth5O2uxeFA4EzI/pL7zxRWAe6+hhWbgQDlacF2qYA2qgNmGMYUMQDF3Kd0xKLGU0SNdTI7FldQfcxA0UwTZsXy32msyaZSS4sKG1fWEU9sg+ynkqalyjSwwysPBAmGaRQgpIBSCrl0Hoee8Cm8/thzkM2MOZuVNNYLiEp6JAqpITs1iv0O/w8cfuqXUcwXYFkGSAgoqwilFLbf8yAoywJI+Ft7UofBz1VIgEphWksR8TTmWveoALM4ZbtHgmKk0AcAw8vCFx/p2I8n5moMmzEMK98l8G/W+tfKAlDlc9HM+vwcmqsBKBOhkJ2EkOSlv9zofz6bx6Enno/XH/tx5NNj9saZDa8MtF8rhYbc1ChefcR/4IhTh2EUCmCG1+yDAQgpUMhOllYqlA0et9vyU/D+UIRipzKSrz3jWqcCZoJMlJlzh0o39Xw86jWRBBCPOa3W2852M9VnjUoyPVzR9w3FjjsEfo6Y6C78WSno8T4898htGFn3IuKpFJSyQpM7l83j0BPOx8HHnoOsQwJeE8ya0X9f9ruW/4j3++B3V86xsqAnUpjavBnP3X8D9HgKrFSYTrkKYbZa9gc+i+rEWHjFYnvn3IwEA/3PZGlFj5xoVgR1rfyPtP7V3kYhi0HNEHMbfP4w+EUo9iClhnxmEn/9389gbP0axJNJKOXc4aASOOF8vP64c5BzlUCgA1LkYkLnRyk15CZH8eojPhCy/C74lbKgx5PIjK/HjT+4AFOj6yG0mGMxStuRdAD81ciZaqjGmlOkkgqgWYOOatNMdAVoWyn/GzgllUV0K0exqcZkbr+V84NzDIYeT2Jq88u47ofnY2z9GsQcEvCulgi5XB6HnHg+Dj7uHOQyo3bOvpolIkBo0rb8VcAfiyeRHl+PG678NMZeehaxRJ9dJFZ57U17A36MiGUuAaVXpcyfysp+mwN3twYDaxly0W1s1bhUau71FFq4UuvWzjT4UdLyy3YFYokBZMY34U8/OA9j61d7SgAAOKAEDjnxfBx07DnITbkxAREpAYTQkJ0cw36HVwF/wgb/9Vd8CuPrVyPeNxSQ/uSpkI6CH7V6F0VDvxy8FTYFnaUqoB4VLzDLjsaDf7XJgivKf+qY7K8+0SliohKUshBP9CM7vhHXXXmuRwIWWyHyckngYMcdsDfvCBcMSakhNzWGV9cC/9g6XH/5JzGxfjUSyUEoywyNk4gowW03+OuUe6Gx4zYE5ait6wfac4jZAPm2kEhV2UfVP72j4I++IleXKGVCT/YhPbEJf7zyExjdEFYCbj4/n83jzSd+Cgcd9zHknRSh61IITUd2agz7HXEqDj/1y1XB/9fLz8XYhlWIpQaglFUxiNgN4I++xVxeDky1FgJ1QuFS9xEAdxjU05L/jVh/Kpf4FPSzq2mNDoOfOWy5QivtnSV/SlnQE322O3D5x0PugBcYdEjgTSd8Cgce+zHkp8YghAYpdeQmR7Hf4afi8PdXB//fvv8JjK9fjVhyMEAwQRxF3IMZ2U6NKj9PFH13t4Jg4Kx3AaiVg+1NFK7/Xs4o+KNc2kDHYkshluhDZmIT/nTFxzG6flU4MOgqgVwebzrxPBx43EdRyEwgNzXmgP8/q1v+738CYxtWI54cBCxV3gSkZMUi1xqiVoO/rNCAKvj37bW8NMsIQeu89Z9h+U+1gkNNXEdbwR/QKRFr+T0KEwRWlk0C4xtx3eUfxzs+fgXmbbsrCrmcLfmF/fpCNo83vec8mEYRhdwUDj/1Syjmq4N/fP1qxFNDUMrydkkq33akXFN11PI3EM0Pdyvy14O0fsn7zK8d6LI04EzI/4jPLTWqRBVDb+5ntL2arQr4maJcAZR0DHZIIN6P9PgmXHf5xzG6fnVZihAg5DNFvOGEC3H4+5fBKBSrgP9cjK1fhXhyEEqZ4XX2RGXCv3TzpU6Cnyueolr3pPqJo1VuQCfiAPV2wRAdNsAzqCS4ia8485a/6gQlKo9hONkB2x2wlcDYhtWIp8IpQgBQZhHKNKCYq4PfsfzlcYjwNmohgFEEaDu0qQrVCKD6wcBKuXrekiZ/kwRA3QDa1vpW0S21g7Xj4Qg7VxuLToEf5ZbfDf5F9r13ugQxK8QTA8hMbMJ13/8ExtavRqIvCRXc14HIIQOnvJcV4qkg+Fcj0TcEVlZE88+A9feup8ot7MhGqvWQQP2vaF0cgLoJSvUrAO5aLqQWWvPaz1MXgJ9CKjuiEy9T2cadynEHMuMb8ecrzsP6VY9Dalq5n0v2BUhNw+jaZ/G3Kz7llBgP2qv8Qm3BojsAu4RC7F9bJzdSrV0IVEFEVc0YUdvcgG4Jo9UVA2j7ViDTWShR8ybUsYqLalmGINA6DP6gDKHotevuPoFRakApC4nUEEbXPo3n/n0LNF0DmH2r6W2UpCBjGp5/7G5sWPUIEn1DUEqFzsWB5p+lY+MRkigZxY7tpRje8anb/dluqQfocBage25CI/1xeKYsf3ATCypv2hVswskI79ZDjnYTUkNmcgT7H/URvP5dn0AxX7C3+S4dBCFRyBaw/9s+iGI+jQf/8iMk+ucBnssQ0SS0LPqP8AV3dBdlrmKtK3dC9oKsgTMS1VJks+vo0sVA0/GppiMUateGl87jmoPaavBzyUSnClV2riTnoIUObB4iNeTSY9j3sFNw6Cmfg2mY/meS3UKa2Z/6RIBRKODgd5+DA447E/nMOEjKkuKZ8v6B/uf7P1cdt7Z0V+ZKYZOWmwVqas5S14G/iwmAWvQOassnt9/nLz81RQQDPfCRezP91KDQNBSmxvCqQ9+LQ9/3eafIhwPr+RWkFoPUY2DlW3lmIJ/N4+ATPo4Djj0DhfSEUzYsIhuLhlttV18K3FbwU+11G1TVfaw0C2pVlc7uqsBZtxiomcGnKFPOwaBa/XTQKdnPVcwZEZVsXuLUADjPS6EhPzWGfQ47GYe+73ORzTxiyQQmR17E2LrnEEslwIGKQQKhkM3j4BPPwf7HnobClNtjUJSMV3AT1eqB005Zfq6b0qu3eKOtIwtYHwFsGWNRT3CoejfgmQV/yY+BCB4FGl0KYcv+JYecjENOiQa/Hk8iPbYeN/3oQtxwxfkYX7cGejIJyyUBYW/+UcjmceAJ5+DVx52OQnrcbvoJYS81Znf5L/n76hA6b/nLvaZpupmdqwOgLmCZGVoM1OlBqFBTUGnZL9egwI6Cv/S6S4uA/J+F0JBPj2GfQ5fi0Pd9tjL4x9fj+ssvwNSml1HITOCGKz6N8UBnoaCyKGbzOOiEj+HVx56GfHrCIQEK9Sfwp1GQBGgGLT+FLXm15d1dad2oOwigG74UdaAnIVfwGyhKFXQa/IE2W+VbcvuBQCE05KbGseSQpTjklM9UBv/Eetx45QUY37AGerIfWjyFzPgm3HjFBXbuPxVeRQjHHXjdCR/Ffsd82CEBZzegsmKk2jUT7QJ/edoxOghHdc3LxsuIOj93px8ArEoAsykLUl8AsN7ln9TwiLYX/BWmFvs+vxAS+fQYlhx6Et58yoVVwL8BN15xIcbWP494chCslNNZqB+ZiU246coLytuLOZ/hkcCxPglQKPMQJqdOgr+yD1DZ/+cZMbjUcVzUco3EbIFz8wFAauvtaQv4I+5amX/tVAQKIZGbGsfeh5yIN7/3guqW/4oLMR4Av9fGSynE4v3Ijo/gpisuLG80Cj8w+JoTzsK+x3zQyw5QiVLict3dGdnP07HEzSxQ6/5MQGtagm2x0VCqESeo/uW5Az6/L29LN/cEvC3Cpiaw9yEn4E3v/XQNy/+ZAPgtlBb22K/tR3ZsBDdfcSHGqyiB15xwJvY55gMopMdBQnjuUvTGoh0Cf416ja0kqN/iGEBjO2tvudzQBMW2TPZHlSkTgYRAPj2OvQ55F9548qfqA3/K7uRjb+1NJQ/hpAf7kBsbwc3Oe2LJpE0Y5McbCtk8Dnj3Gdjn6A+gMDWBQB1yWW3CTFr+igYbvflckwCIpp9ame3jxZ2U/RFPVo5sCxj5LJYc/h68Yekna4D/sx742QF/pY0BbBJQ0JO2Erjl8s9gYv3z0FOBFKFT/FPMFvDqd52GV739Q7AKuYjdo6lsTGYM/HVigrY0aqijElLUlLhbHLipmXEKk0Kbwc+IXn9AAARJmMU8Fu26BK9711llzTyC4L/pShvALvjr3RKMlQU92Yfs+AhuKVUCcJZPE1DM5bHvO07FtvscBCOfA5GMHMnmx6Rx8NcuBOouf32mawHETLr/NMvKrTof7Y+4I4JgmUVs88r9IQQ7m3L65b16PInMxAbcdOXnML7+BWer8PIlva7sD7sDIhATUB4J3HqFowRK6wRYQSmFbfY8wOsZMFPgrycmM73ZPXvVwaxfDNQ+J77B93da9lfIaRMEitkpuw8gKzAYyjKhxeO27L/y847sHwh38gmVDwddAVHyGj8waMcENuO2Kz6H8fXPQ08koSwTzAylFEgTKGSnSgJx1HnLPwOSdUuoBRDdDWNqO9RbMsitBn/UZHbPw/a2YC888neMrXsJqTl90PQYkgMp5NOjuOWHX3Bkf7nlD4I9el1fNAnoyRSy4yO448rPIz2yFsmhFKQeQ2JOPzKbN+PFf90KLZ4AO0uHqc5Z2UrZT3XVAMwmK96Za9XQO7oL/FUnBAPMEFJDITuJO37yFezz1pMxtM32mNq8AY/ceDXG1z2PWLK/BPw+wH0jXaIqnC/iN/1gsNNfwI4rpJAd34Tbr/wCXnXMBzC47Y5Ib96Ip25egczmjYglBuzBEPZlNredWpM+/3RL98taRs58J99OHdp05MPs8p/qKeqgCu+gGZD91UhHQdPjyIxvwt1XXwyh6zCKOQhNQk/2gS2repejsm6+bmfsihsTgpUFLZZCZmwT7vnFd6DHklCGAS0Whxbvs60/yQq7LrUZ/B0Xzj0C2OrDBJ0CP1egJmaG1HQIKWFZFmKpfkDZQTmQb8GISmiMotfrk0MCxBzaLj14BcwKUtOhxeIgRZCpOITTgJRIVNmoczaBv5Qr27FXQPccYusBf+u+UUfBX6WUjZmdZh72v+GJWrsqz80CVC6FLX979c+c7ZZ/C3VTmyGA3tFF4O+IBGpTk8oOg5+5e5zO2WD2ekHAVo3mrAK//QFcfSnd9JVTYEyo3eDnniho5s5tRQqA2jegHQc/13m1QWD7/0b10eGI84Ywys2Ncqctf+9oUQygtTqqC+9OQyV5POOWn+sAntcVPNgqi6POz2AojwC8nzlIBKWqgGsQDMpaAXQS/Nwmzc9bOLNotcC/5Xz9aslibhx03BiXTNvycz12ln0LH2iUy8z+zyA/509cgcTKgc9O+w/706nCaDIY7BTl8Cz2+bewOgBqggC6YTEQV9jAsV5Yd4uQaL3sZ5RDllFzLy74JAD41XNRwOcyFeGPtE0oFH0TuD6N3lWyn+u6q13owdcP/vzWFQPgjpy+o5afKnx4AMUUCRBHFXC5dHf/Q8kjDP5gnKDcLHA9gJwR8PPscEU7gAQGkGjYBdiqD+4a8HMVWcpcGryLCvr5ptmTy1TL3+UIw84QITPPKKv8CfxL5V+g/eBvq2zlpuiEu5x0ZpQAyqRkt1NC1bRWO8FfArhIQuJAgM8X+lGg58gNNLl82jqrbDhIQEyBhj8l3QCd03IFlmw7+KkRMu+lDbZKBRAVV6gV7y61ip21/JUNHXlC3v5ZeT16fXEfBE54f8TKEjnkAoSinYRgONDtCVxaPEy1hqhdlt/tYsXVzlX5Ts+EtZ7pLEPPBagwCbleTdlB8Iey9sSR64fD8ToOy/hA3KCcBMuDiC7I4WQOmHzyoAZ87Oi+/S0EP0rTgL4rQ54q4jqutKcAtuJBclNY7IGn0TBBuy2/hz8VfG1gZ143iEfsmPywXaOan8PRtpCDuikAZ7ZTieGFh1X69qM94I/2ALjqa7e2o+EsAHcpSKNnBTchsTj6vdTcaLQb/NU0QbgRjx/hD3fi5NB/CBQC2T+rkr+zp6fZA3aVseJy0M4c+MM6hmfJ7O4AamaDC9DJzD7X9XdGAAgRl9hW8JdijsMuPCMcdCsL5RG763xLTutKiaiYgPseFcpCeL5+wN+mSInSmLs1XfBXG8vqXj5Xd124zsqsZmqmu2SGbxExgEpVaeUmiupwTEuj7TxjPn9kT8ASrBKXXwMThyJjrn9PpW/0zqtKQMWBTw3EA1g4HkdpLQK8nYq8TCC1aS/FGuCPDhBEr4mofAO4Joy4LXDsLPg7TADNWfZ6qgGbvpaQO8tlf/InIjcx+Vps+aMMbV0r4xQiN0GtGZbnUAhRRMgfiqg+8ncy6rzlDxN6eTyDOwxEngWuRu3FQG1W451Jg4R1M9eYVByoiCP4ATXXqnUK/O4+e0KU9+73IvveDpActtyMcI1A5EOVxALCVYJlWArWBzDszUkBlHYBI0cBCKKOW35nA6PIqsVq95/rsPrdZbtbc9TMAmwJ4ZJwDrzcypFXxFLq1zk2kAimacI0jbrWu7bE8hNBKSAR15FMxsHMDqCCJEAhIeDWAsAFgXMDK1BfdeYPgirwq4iwD8EWYwIEpRiJRByJZAJKdQb8DIYgAVMpmIbp3G8OlDK7qx3ZHw+uJPc7sxioYzUABCDeoALgrl0l0GzwpbTMtZJ14LLPIAKKhSLy+QK8HbC4/bJfKUY8oWNwTj8si0t24qWSXbmpbE0OR203VOeDKOwIIAicEA8Few7am4woxejvTyKZjEMp9q6trT6/c83FoolCoWgXK3lFHRzuesCVbmBAA3I75uAMHM1uDdbdsct638H1vZBRFixiZxIwbAIwDAO5XB6CKjN3q8DvXY5SiMeBxYsXwLIUhLeTj393iSjsczso9dt8s58NqMkGfoAwWEtIERv7uTLfYwTnokgIWJbCom3mI5XSYVmqppRsTcDPns2FQh7FYhFCUEn5D5fFALguX312BgBDlZGzjwDaF0zhqIR1id/LJc+RIBSLBqYms5CivZa/FKZEwCtesaO//x/Is7RBJUCBGEUovslBhFVa/xdeH+iNC5eIYTfS72wVbqcKheeMuFuMKYux667bQ9NtFVPLPWsF+BUzpAAy6SwKhYLjAnEoNhL6QI74cO7OOTtzQcAOWfZO+ELMXOb7c7lQLmmQ5S+NNQwDo6NjEKLCvGkx+F0ra5rA3kt2RTIRByt44COQHxPgoCdOJd18KTTxKQiE4COo7CO6bLhKI7jJCIggHOIhEgAJgAmapmHvfXaDu21hu8HvxScEMD4+6RCAvXehL+mjlj9XyBHMKHZ5SyaAmYgD1LXTRiBQVBIVd85vKQsb1m+GECWTpU3gBwNCCBTywK6v2B6Lt1sIw7ACm3kKTwmUbvvlAtbLFnjZiwAAyvYGC8t+UElOn0rDfq77IezXEtlBOFNh/oI52H2PXVDIV94AttXgZ2UrgJGRERimGZC/KjJoU97nIIoMuIG516UBwNlLANzyd5Sud6+WJgpFj51U2dq166HYN43tBL97mKaFOfNiOOj1r0KhYEBK6YDOBp6AgCABEdrwQ4SUAAXle0Vng/2IfmC5L4XO6ysPcqQ/3LgEBISQyOcN7H/AXli0zQAMw2xsx+AmwR/gLKxbtwHMVoC8A24AM2p7xdzkHJud+TLRRWGLjvtUoQU0XOoc+LJRKQUpBV56cR2MIkCCOgJ+1/qaBvCWtx6EVDIJVjb4BAKyO6AGRAlgQ3sCOtkCCpCB7zaQt8146WahwbiDpzwgQCQ9FUAOIemahrcc+XpffXcM/ARLAS+99LK9m49SXgWkggoHAzlqXnHL5H931RQ0QQCTbb3kNsQB6nYDuAyh4U65JRbD6ZirlIKmCaxdux5TUwVIKcCK2w5+hk022azCkn12wmtetzey2SKk1AGSEBD+7j7k/+y5CS5oXfeAA2Fhoog4AZx4gghZfwpIfCIBCAES7rmlY/01FHIG9l7yChzwmt2RzSkIIToCftv/l8hlLaxd+zKkJqDYXeCkSoK8EcVOW3D7sC0iC9AQkTTCFQGb7wfDgr3xlE0GrCA1iU0bN+PllzdA19DcBhUNgj900QSc8v5jENN1AC4YpaMGBITzM0gE0oUO+MkHsWvB3cChG0QkFoHXBMFvn0sEScb+RBv8ZEt/ISRYEd7z3qMRi0tn+7DOgJ+ZoWmEkZExrFu/EZomodjetow9+a/CSo/LOywx1xL5rcn/M3euS1GtM4rZBPLpuQEcighXUgYc8BeDKkBKwlQ6g2eeWg09BsfCdAL8djAwk1Z47UGvwFFHvxGZqTx0LeYAU9q78pINSAEZoQYc0LrAFnZ5saBA/ECQB3SKeICk/TdI7zOFsH/WNB2ZdB5vfNMBePMh+yGdsULWv53gd+9ZLAasWfMCJsYnbIXmBXNVeQwgArwcuWBoy5b/s1wBNOoGVL5VHFQBzrnYlf+uFWGGYguPPvpUqBNeu8HvS1wgn2OcfvY7sXi7bVAsWJBSBzlA9P91FIEDVHKec0EcJASKcBsQ/Jt7Xkjf4rvPkfOv1GCZjDlDQzjj7JPsvH89gfIWgd8FrxDAE088BcMows3msOP9c0mPBPY2Q2m0RHrLOyoSANV8ohviAM25AWXyP+gtsTNlHPnvLphRykJM1/DoI09iasqClKJj4HeDXMWiwsJtBnH+hafCsgBBElLozr+a7RIIzXm44LXJgFwLTr50R4msd/15m0TC7yWheRZfeNZfgyZ05HMmPvaJU7DrbguRy1n24iXuDPgBgIREPg88+shKaJoEswWGChcCBVw8rtLmfEuS/9MiADceNPPc2Ho3wLbowZvp+op+9Zg7UWxfUkGxhVhcw5o1L2H1qhcRTxCUUh0Bv3ezpMDUhIU3H7YPzjrnPZicyEOTOiTpIGgQpPkAdSw0kQ9c15qTEz8QnuT3rbqrJtz3krCtvnDPRdL5HB26FsP4eBbv+8A7cMxxB2JiwrSJsUVjUg/4FTNiusC6dZvw3KrV0GMalLI8Emcon9TBEW3US4G59cj/6i5AB5YCt5wgKnWzrZkRCFb9Mdz2WG7gSEGBlQUhgKmpNO6/7xHEY3bxSafA78anpBSYnLDw/v94Kz50+rswMZ6DlLr9IA2SdAjSIYQOITQIoXlAFqQ5ltwmC3IegpzXCf/n4MNWGf65pfDBf+JJR+GMs96FqSkLwlFFnQI/A1CWvV7ikYcfw9joGDSNPNJmqIDfr5wHlwUAa4GfW1T8MyPIqIFj0RXAnZYb0LwKKE0NeX4hh10BdzIpZUHTCP+4637kc7b07CT4fXfADgp+9OPvxGlnvhtTUwUAAlKPlQFWkv27JJsQpAd4GQC5dF6vea+Rwn2/7ll8ITRoWgwkdExM5LD05KNx3qffh3xeeTajU7Lf3/9QwLKAe+65DyC7ZoPZcu4be66AC2JVlgbkacy52SH/Z1lPwEpfgUKMXLHrTGDxf+XXOa2ynI1J/L72fn8Ab/LATwVaykIiEcNjjz+NZ555CbvvsQPyOQskRMfAbxMAwEyYmrRw5kePx8JFc3D5/1yLQi6PZCpu9y1QBCYFZuF9F0D5HYNLNJKXLnQLf7zAoPSq/DRNRz5vQhDhnE+8F6e8/23IZC0HiNRx8NvRf4mX127GI488jnhCh1KmF+RjWKF4jt8MFSULv6YPxG6V/7M8DdgeJo5+u3LiRMqbKKxcJWBBOQpASGBychK33Xo34nHbB+0k+IMkQGS7A+8+6RBc+j8XYI89d8PkeB5gCT0Wh5RBV8D5mXSQ0EEiZlt10iGEbdV918F/SKEjpsdBkJicyGOnHbfDN79zHt7/H29DOm3aNQQzAH4AUEohmQTuvuc+bBoZgaYJWJ71d/P+wY7HKtAjoN6A8ixa+9/SGEDXuQHtqAko/ayg7OfQ725aybJMxOMabrn57xgfK0LTZMfBH5yLQgpMjFvYe8ku+N7lF+Kcc9+L/v4BTE7kYZkEXYsjpsehaTaYpXT+FZofO3DcBumAXpMx6FocuhaHUoTJyTzi8SQ+fNq78d/f/zxe89q9MDFuQgjhdx7qMPgBp/ovp3DrrXfY4LeskMvm3Td276kX3m6pu1nPXOy26H9dLsDs4rhgh8/63AD3ZX4vveCqeOVPJmLPr7SUiXgiiWeeWYW77/43jjn2YExMWJBCdAz8pX+TUiCbVZBCwwc/fDTecuRB+Otf/o7bbrkPL7y4DsqyoMckNF2HFORt54USF4BhBzYNw4JhFEEksf12i3DIYa/DcW9/M3bdbRHSaUYm0/lof+mYKKXQ16fhX/96HCtXPolEUodhFpx7FiCCgAII9kDk0GrP6HQgT7v7VPcfWrd+hVZuHFqrs7Dd/NPune82AmUo53cLYAFFAgQLiiWUMgFi/OF3f8ORRx7kgQcdAn9kMxxhy/DxcQvzFszFmR89HiedfBQefOAJ3PfPR/HkE6uxfv0mZLN5WKYZSZ1SSiRTCey4wzbYY89dceBBr8JrXrcECxb0oVAAxsdNu4JQzCz4gxz/lz9fD8MoQovpXv5fwXIsv5vFCbcH54BF5g7N5VlHADMV4JteMDBaBVSfpeRFgm3CUWDYbX8UK0jYC0sE26lASAumZSKViuPeex/CA/96EgcevDfS6XD5ayfBHzynkAKGoVAoMGLxBI54ywF4y5EHYGrSwLp1m7D2pY3YuGEzxsfTyGVzAIBEMoGhoQEsWjQX2++wDbZdvBCDgzEAQC4HTEzYwPeKn2YY/EoppFIannzqBfz9H/9EMhWHZRUc1WYBTtUmWNkl264LULHst3nrP73gH3cMYbM8C9A+FRDMBARJABBeFoBcX5LsgiCCbWkM08Cv/98f8bqD954xyx88p99QmCAlQVkK6Snb99U0Dbvuuh1eucd2dlMTLuFA2GlywwSKRcbUpOm1Qg9VPWJmwe/iUdOAP/zuOmQyaaT64076z3TkvxUo/lElqV5uLO+/hYfHte65TKrTDWilCgi/3v481w2wN9RQUE5a0HJSahJMFkzTQF9fHLfffg/+efdjeMMbX2WXCAsxo+AP+/XwUpTMjHxBgfMc3iin5A1ufz8hRdXg40yBXymFvpSGxx9bjZtuuhWpvoRj/U2/AMgL/FleCbCXFVDcmDSfpvXv1uCf5zpu+aa/3upADlUDciB1pOAElZRtXRRbYDahYMFiEz/98a9hmgxB6BrwlyLV3d9AkIAUAlKWP4S3IAhdCX4/3gH88uprkM1nneIf954oTwEoJ3XrL/zhUEHQllb11zYC6IZgYK2rat4PK08HcXBtQMB/VK6kdEiAYcEyDfSlYvjnvQ/iL9fdjsFBCctUXQn+6d7nbgC/ZSn092u4884HcOdd/0BfXwKmWbQLfth1AUoWc4VqAqotCW9shKZn/WcBAXgqsWPrAXia766v8XxtFYCSNQF+ZxnXyihleSWnpmUgHtfwox9ejQ0bJhGLi4rFQTMO/hndqHOalp8ZmiRMTRVw1Y9/BiL2lBizBVam3QbMWbjlxm+C5b5cJejXWevP3U8A6Cj4p68CGvl7ZCPw4F4AgRpyMAcKSSwnxeS4AGzCUgb0mMALL7yEH1z5KyRTzirBHvhbKvtNi9E/IHH11b/BU08/g3hCh2kVodiyV/85qswlab/lud8ZqHwTlHoMw+y3/tzUYqAZAX+rVUAzjB5sCqJKHuzEABwr40w80yxiYDCJ3/32L7j1lgcxNKR5rkAP/NMHv2Xa0v+BB57CNdf8Fv39SZhmwfH3TYeMSy1/UAGoErJv1t9pRYaAuwb8syoI2JwKqNcVKF8hyO6OuyFLEg40sUMCStlqQEjCf337CmxYN454XJRdcw/8TVyHYmg6IZ3O4dJLL4dp2T6/a/XtAGAgUFuy7NeOCaBsQ5CK1p8bjSd1r/XnOmx5FxLA9LoCNRIQrMzmQd8xEAD02kzZUtOWnzb4TctALC7w4ktr8Y1vXAFdp3BwsQf+ptSQUoxkUuKyy67CU888jYQj/ZlNe+Wfm5VRyisECpZyl35Q+a5O05H+s9f3n3UKoBFm5QZmd3lf+NIdYv11AHZ1oBWIB5h2BFrZQSjDKGBgIIFbbr4TP/rhtZg7V8I0rR74mwS/YVqYM1fDb37zN/z5z3/F4EASRSMfAL/pWH7LyQT4y3/tOAwHlkLXEflvQUs6nmWpwy7dGITbGxDkepuG+kpAqeDqMj8bYLHpqAFbCRhOPOBHP/wF/vqXf2LuXA2mYfXA3yD4TcvC0JCOe+55FJdf/iMk++Ke5Wdlj7nl1WS4D9vfV+wv+PH3BahhKGpI/+kH/nh2EYCada4AGrthkfGAiGWi3s9ukIl9qekqATa8VJRSRSgnM7B8+aX417+extCQBtO0euBvAPz9/TqeffZFfOWr37Hr+mHBsgyv6Ec56T+41t/p/Wf3aXRAz5V7/k0P/LPrYACFLcEFaFQFTC8eEAwIBuSkchaZuB1nnOizpQwvJWVaBoRgFAo5fP6zX8dzz63FwKAGK0gCPfBXAL9CKqVjw4YRXPSlr2N8YhSaTnbBj7Kc1KvpWX43FuMuAOKQ9ec650Wjhmd2Wf9ZvDMQt/f1kfGA8mBRcDIpb4WZCpQFOyTAhmOZDBhmAbGYwMjoCD557pexZtVa9A86SqAH/irg1zAyshmf+ewyvPTSC3bQz/H7LTahlOH5+8pb+MMOEQS2AQts3BKK6zToDk6/1Rd3NYJm7VqA5gOCXGdQsGTZKPu7BCulAgtP7Fw0PItkwHKi04aRRyKuYd369Tj33GGsXrUWgwMaDNPqgb804GfZDT5GRkZw4YXDWLVqFZKpGIxiLpBtMfygX8DvV4FyX7gFXAEVV3EutEj68yxeMzALCGD6AcHGSUBVcAX8rjJeetDtGejGANyAoCraQUGjgGRSw7p163DuJ4bx1FPPY86ciJjAVh7tHxjQ8PLLG2zwr16FVF8A/Gw46sodW9PL+6tAB+Dwgp9SJadaAP4tI/BXNwEwZktv09aTgNc9lksdBF9iekFAFSABdiPUphMXMGAUbRLYuHE9zvnYF3HPPY9g/nwNluWWG2+d4GcH/HPn6lj5+DM477wvYPWa1UildBjFvO3vO4rKq/tXlpd6VaEGoCrQ+6c0mKvKN1ttgd+/JRxitn/d6a23rpYZqDCRGP4CIUcFKCclaFeoKY8EVJAEjDxiMYF0ZhLnf2oZrr3mRsyZIyEQWDuwFYFfWba1njdPx403/gMXXPAljIxsRDKpwzAKjtV3U352XMUt9Q1afRf88Dr+qgi/vzHw1+v3z3brD9RqCNJVOwNVbh1Wb//A6K5AJectayhqD4T/XrYLrIm9SUdO+xAouzefYptZPbujABYMNhm6jIPZwle/8l08+8wanPvJ05CIa8hkTL/D8BYOfsu0EE/oIGJcccUv8Ytf/Bq6LqDHyCv0sdhN+Tng91SW6aX6mC0vLhPc2rt029d6A36t8/u3gKagszEoWKt7UGUSiEBKgAQAgDzQB3elsdHtAp4BKGVCEEMJt6mYa/LsFxkWIIWOvv4Erv7lb/DEE8/iixediz332hETE7ZVE0RbJPjtnYMZQ3N0vPDCBlxy8eW4+557MTCQgsUGDLPo+/jsWn6n0w8sp/rPyfeHwF+S8uN6wd8Ov787DncGcfduDdaJWMA0JF5JKyhvgVDod79vQNAf9SexGxMwvJiApQyYqgDDzGNwTgqPPPIozjrjM/jV1X9BMiGQTDjlw1Fda2cp+JnZtvpxib5+DX++7jac87ELce+992FwKAXTysO0Co7VN8rBrywns+L3ZagEfubwNqCtBv+sihXUoeBnoQJoxhWoRwlEnDfUU5ADlp9Kfg8rAdv2m7bVJ3sXbgG2G4UIdp5nFIoKiWQc+UIW3/rGZbjrznvx8Y9/GPvsuxsyGaBYNCCksK9zloLfshQ0TWJwQOLZZ1/C//7vL3Db7XchHpdI9cdQKGYDRGk6sRQzsNLP8jr8uvsz1gI/2gj+LUX610UA3COBJkmAQZD2xBWAUAxFEkLYMpiJwUJBgGGYDCE09A8lcM899+Hhh1di6dLj8b5TT8CiRYNIpxmm4e7CQ7MC/MwMpRhSSswZ0jA6msFVv/4zrrnm95iYGEdffwKWZaBouNbe8hf4eEt9lfc3vy1bAPyoBH70wL/lE0Az8YBWkYAzaaqSgL2zAJGAUgATQziWn4htNeCoAHsDT9uyJVMxKC7iJz/5FW6+6U6c/N7jcfw7j8acOUlks7YiIBL2JiBdCH4b+Aq6rmNgAEini/jtb2/FNdf8AatWr0aqL45UX8xf0RdIm/r/Kq/wxy/BdlQAuIblD11MB8E/ew+tcRvb/SqgNSRQ4kR5JODsLFyVBODsH2B3CmaGTwTEYGGTALOCIOX8rlA0FQRpGBhMYOOmDbj44ivxhz/cgHe+62045pi3YJtthlAsAtmcvf49ShV0GvysbDIjIiQSEvG4xOaRNP76lzvxp+uux5NPPo1YTGJgMAHTKsIwLKeIx5b7CmZodaVyG3tyMNXaKfCjSfBzV6KjHqTM8ixA62iqsRShTwJ21F5EkgCzsncXCGzJrcAgZVt+QfZzpBRAEkQSIIWiYUFImwheePEFXHrJD3DtNX/CkUcegqPedjj22GM3xGIS+TxQKNjgcVt+d2LTDlYMixUIArGYRCIBmCawatWLuPWW23HLLXfi+RdegKZL9A/EYSkDRSMXqt/3gW55dfwcAH9wb8Zgbr9x8DeyGGiWB/2auLotIA3YmnhAQyTgiQNyrL0NQEJpijCQKSC/wSiRTRrKcQGEkA6R2L8TSccimpCahv54AiObN+FnP/81fvvbv2C//Zbg8CPehAMPPAA77LANdF3CKAL5AkNZlve93e9OoY1U6ge/W6XI7O+aJKVELCmg6xKWCaxbN4IHH3wYd9zxdzz08GOYmJhAIqGjbyABpUxH7juWXjk9+5TldVViZYU6+cLZ0MPv6FMO9vDuPp4WqevLNQr+2er3U51Xt4XUAXSYBDw14JMAO7+7A8+Oe0CB5cSAv/OQcoqMCAy2FEjYuW6ydyP0fmbL9oeFkBgYjEOpIv557/24+577MH/ePCxZsicOPHB/7Lffq7DTzjticDAOKQHLsq2yacApObYDlNWlAOxvT3b8QgoJKQFdh31OBUxNFbH6qbV47NGVeOCBf+PxlU9i08gIiIBEQsfAYAKWZcIwcn5AD4ENO7zyaStg5QPLeINbe5e1aedo8De9JmTrC/ptFUHAxkgAqK9YqBIJMNzkX5AE/N8dZeCUEFPAJWAwiAWIpO0WQEAIGwD2Lj0KTJajCAQsZUKQRDJluwvZXBr/uPse3HXX3Uil+rDddtvgFa/cDXvu8UrsutvO2G7xNpg7dx76+lLQYwJSBt0T59J9j8YjLmXBjjVkcxgdHcP69RuwevXzeOaZ5/Dss6vw8svrkM5kIAiIJ3T09cedXL0B0wg0TkWwNiJIAE4lHyx/aXVgfUUY7OhC8G8FQcDZEwycblCw3sBgpeCgHfm3kUWeVLWtP/nzkxxrzz5hUCCVxRAQEFBKAKTALEAO+AVZYJIgssAkoFgAEA4ZaDZBKAsvvPgCnlu1CtdffzN0XUdfXwpzhoYwb/48zJs3F3PnDGJwcAjJZAJ9fUlvPBhAOp1DPp/H1OQkxsYnMDo6htHRMYyPTyCTScMoGiACNF2DHrN9e2bLsfbFkGz3ffvAzwgDP1jHbyuiQCefEn+fI/o1ooE1II0W+czGoF9bsgDcgC+x9ZBAYy6B55MxwAGXwD23FyBkBUUCBAFiAUU2yIkVmFwycNQC2cVBTC5hEAgCUpPQYzqIBMAEw8hj/YYMXnr5JShL2d2y3dJmCtaI+pbVjh0AQghomoSQArG4RDwhnDSfBaWKMC3lFefYYLW8DTl9qx+Q88HAHoJbdqsSiQ9PHQV39WnG6vfA34IsANOW9HWbI4HSQFpVEvAigOR8lmvDyF5P4PgINhGQFxQkIm8zEoJNBGABIgFmckAfJILgczYJKItASsDb45fsXX7jmk0cAJV8dyqb1OG9Ee10nWmqkAQPAzi4NDoYvWevT1858APnQLnVL430l41vGyT/lgz+5lwAmjXav+0k0JBLUKIGXBLwJyWBWNgLCr2XW7DrB9lbdOSm9hi+KrCvWYA8QrDrjG0SsJ9zQW7/zfkX7u+Ivt7S78QIy28O/+s34FCBbdScDspB8Ieej2rRrfxxYQS6MKMNVr8n+7fgLMBMkkBtNcBMTgaAvK7C9sJC4WcOWDnqgLxrYxYgdlODNnEQO6TgWH3iINh9AgiB3/uegaunqOuN6oMQRQLK/z24kzJUWRNVr706c+i5crkf3cMPDfZ76IG/MUO+BRNAfSTg+8P1ZwgquwQV1EAg5GeD1WsxGukW2G8TdnzAvYMsbCIIWnQOqAAm36/noMUn/1opeNXR188hMnCLa1QwAx8gg/AOSpUUA0IFPNF+vi8+uGG5Xx34W7nlpxYoANqCSaA9aqB01NxCFfL/6pUQ+/EBdoKC9nnd7kPk/W5ThJNdcNqQsJO/cwN/LgmQF8BxyYUaCOhwiAi81iYhq68Crw26DSrgKoT34uNSVYGIvv0NAr99Vn/Llf11E8CW8/XbRwLRaqDSewJE4NYIBIgATtqQEASyEywEOXl78lQBB9SAHTx03A0noBhUBD4lUX3gL3UFiMONNkJNNzgEYIYqORdHl+0GNmGtPus6bfW3DvBXJYAt7+u3ggTQIBFwFblN/u7DrjSnAE0w+5ae/J9tgIXJwFcFzlWw63KEPX8GNTBWQTnuAjvwnYKyvvRvJUU8HLUjL3PTwG/W6m+t4OetMwjYDhKofo7G3QL4RBB8BZXAkH0Qh/L37Af37FShD3y/iQgFlD8FC/8iv1UY5PAsP6N809RSeV/q35d9Vy51LVoJ/B74m/k2WxkBVLfk9QUHm1UDpbejPAfvK2vXPSh/p68MgkE9v9wYJdbeIwKPVKgG7Lj0A8use5lG4Ij99lpo7TsD/K0P/FspAXRODVQmgmqqwC/WDxNRsFFpGJwUkPulkX7vjFyP/x9JBeHfI7vvllv6ysDjFgK/Z/XbGgTskcD01EBjRACUF15TeBJ78QL2wF42fQOkUA7kwHkjwxWNSu/y3nv1b9/eDcDfusFfFwFwjwQaUAPTIYKoc0S4DIF4AbwqQwoRgv95VUiHGx0jlIEdoU7J0wd9K4DfA3+LCIAxm1YCtj8uUJ8aqJ8I6lcFlQ4KYLG8G47nNrRqhBoumGmg5VaLtuZqbAnv1gP+urMAhK39aJUaqI9U6lMF9U5YmgYYWjGtuIkztM4/71n95r7tLNoarPtIoLYaaIwI6ieDSgCkFt7M9nTDqb8ZZzu25u5J/voJYKuWA1z3ILSSCJong/aCdvqj2XqQ9oDfwLH1LgbqjBpojggaI4PmCGE2AL7BeAG379xbJPBrhIJ6WYAWqoHGiKCJc0cm9GiWgb0H/NnhAvSGcAaIoHHfqxoAW0kO3LLZ0Nh5mgtm9mZupdFYXi8B9IZw+m5B40QQNfLUBaDtHOB7wO/s6PdiAB1QA6UTun4yaC0hdDPgmwd9D/htcwF6R+uJoDlVUGuy06wDew/43XF3egTQBUTQPBk0cqupqwA2vUKlHvA7pgB6Q135EEKGluwq5Ta/rAw2IoIQIvSc5eznV/q66M8UTZGFvUOxVddro66xUXArpeoCvJQy9Ls/hpVnY+m4R31e72gBAfTAX/2YSk8CbMJNtup6EvF4PDCBqQxYRaOIYiELP0Er0dfXX1MduOXH6fQUlDIbtOgMEhr6Un11gd8wDeRzmaZVg5Q6kslUDStPUMpCJjMRGCtGPJ6CrscDPQfDM9Eegwmnlbr9HiF1pJJ9W812Xm0ngEkAsRn2Lrv9UErhrUccjXlz58IwLMTjGh557FE8t+pp6HqspCGm3bTTMIrYcfud8LoDXoeioSClQDabwV133w7LsipadndiW5aJww45Cgvnz4NhqpLdfaIZnMGQUmB8fAz33HdXVfVARDAMA9ss2g4HvvZgmN5nVLcIwV7+ui7w8ssv44GH7oWu65GgJCJYlon+/kEc97YTYJomAECPCTzw7/vx8roXENPj9r6BofcJGEYBhx96HOYOzYFhmIjHNax9eS0efPifgXHvHfUa8kgCKBZBMS203Kx3lE1gC1/8zDdx8EFLMDEBLFoIfPqzX8bKJx5EPL4QlmWWSHdCoZDBa/c/CD/73x9jdAzoSwGrn9+II455NUzLhCBRcQLbkz+PCz65HIe+eX9MTgGSat94pYD+FPCvh57E8e95A6TUK04JQQL5fBZL9no1rrrsJ5jKAOR4Aqyquxdge0fiOXOA3//pBtx97/GIx+bCYiuS0KTUMDU1hnce936867gjMTIKDA0BN912Nz509lFlKUwpJaamJnDIG9+Gn13xe9ulYSARBz700ffANIuIxRKOMugd7o1xd6ewzGhLEUkAySRMEjAAQGjx3kBWONLpNMbHLUxO5qFrCeSLBdRakFM0DIyNW5iYKMIwYpianGroM3P5PDIZIJsxIYQWLfdBMEzT27DDKEpkM9mAmqi+I65hGBifsDCVMb2Ygya1ytaF3ViGQiwnUCwW69COBMtifO7LZ2D3V9yNOXMW4MWXTBz6xjfife85G//3q+9haGghTNMEgWBaJvr6+vG587+DosEYn8hh4YIUrvjfy3HTrb/F4OBCWFYP/CFC1xJuIyjT1NiomwAWL0ZhZJNIk8AiXR/g8m1keocbkNOkhBQSQsq6gnNEBCml/RDSCbZxXVEXIsJUehKjY+PIZIoQQpbBUUAgX8hj7txF0DTNlskJDYViHqZpIB7Xa8pke09BCSkZQggoS2HTyMtQSnnxiCABEHwCyOdjGJ/cXHMsmC0kkyms3/ACvvPfF+F/vvMTGAYjnbbwybO/hNvv+ivWb1yLuJ4ACYH05Cg+dc7Xsd8+e2NkcwFDg0msWrUGV1z1NSSTc3pBwKhYTGwQJABmLkgU0wCAZeBgOWAkAaxcCWPRIsoCgK73ld303jGNYClVelMpCZSu71eIxeL43JfOgia18io/BjRNw/j4CN5+7Mn49lcvQz5vQtcFpqay+NYlX3Q7itXt1TEraFLDprERvO/Db8FkehKaplWeC2yTh2mZSKX6YYWyDuXvsSwTA4Pz8YfrfoG3HHo8TnjHCdi0OY9tFs3DBed+Hed99hQkE/3IZCawz94H4owPfQoTkyaEIOga4dvf+xxGx0YwODivzOXqHQQZ62Nny8hcAUPFqKBeCQEQMzMRkXXOOVMTABBPLGAiDb2cQIUgGzcxMtzsiwhTUxNO+/GwDy6lRDaXxit22QNfuOCrUEpAKQNDgzo+9dkL8MC/78Tg4KLGgMK+a5DNZZHNpqFpur+PYaXrJYKoUzSyYsTjSXzr0s/goNe8EXPnLsToWBHvOu4k/PXGk3Dzbb+HJmP47Ke+g76+JMbG8lgwP4Hf/PFa3HDLb3vgr8jEAlpqnrPdpBhftA9ykSq29ImTT3aeI9rEAFLJ+dBkvKcAKuCj4bZpPL1P1DQJXdOgaRo0TYemaYjFYiACBgcG8f1Lf4WFCxYgkyliwfw4rvrZj3DNb3/UNPiDQTgptZJ/ox+CGimRVojHk3h53Wp867tfQDJhB0KLJuPzn/42iAjvfMcHcMShh2F8oohUMoaX12/CJZd9EfF4Ckr15mVULIeEhlj/tm7X9s0rTiaL2dl6uhoBbNx4u9NQXrzoKgBN7w/kXXvHjLkPzs31H37RTCYzia986TK85oB9sXksh/nzErjj73fj6/91Ifr65tRdBFTpUMqCpSwo72GWPJTz98Z9ccsyMTg4H3/48y/w+z//DvPmxZFOF7HLTjvjG8M/xpkf/AwKeft7plICl35/GGtfXo1EPFlSL9A7HFkFqScRSy1wYzprQ8a9GgEcfvjhjjMg1igFJBLzkUjMg1JmLxTYMu+sBWLA9eE0HVNTm3DmRy7A+5aegpGRAgb6E1i3bj0u+MJHYCkFIaS3e2/9j5CiR0zXEY/FENNjiMViiMXiiOlx+99YHLFYDPFYHLqmNUkwtivw7e9eiLUvb0R/XxyTkwZOfOep2HGH3ZDJmpg/N4abbrsZv/3jTzAwMA9mT/pHTC4CKxNafAh63zZuYerzALBxSbkF1yICgO7df9ayAF0fEP0DO2J8/BkASQC9VEtVf6DRl/J0wK9hYmIz3vzGY3DRZ76G8QkDmiYgSOGCL56FF15chaGheV6hTeNzScC0GIMD8/DLn9wCrmLdLaWQSup45LFH8KnPndpwUY7vCryIb/zXhbj461dBCIFs1gBAiMclXl6/Ed/67mcqpD97h21cCEqZiA0shpacR2wBisQzFedQ6RNLlthTUgg8WyxmrHiiTw4N7c4vPH8D2dmA3iBPB/xoEfiFkMjlsthh+51x6bd+DJCEYRSwaEECy77xn7j9ruswNLQNTNOYpppkCCGx/eJdKgcJYRcc9fUB6zeMNh0vUspCMtmPv997EzaOjGLhgm1hGHY9Qzwu8MRTK/HMs4/1An81FICyikjOewVkLCmsogECPw0AhwPqjlouwPLl9m2NxcaeZ1brhADmzXtVz/uvheZW9u+seY/tOnoixiXf/Cl23H47TE7lsXB+Ait+/ztcedW3MTCwcPrgD3xeIgEkSx4J5+E9lwTi8dg0SW0Cn/zocuy847YoFGzrTyQwlTZx2JsOx7ve/h+YnNwMKXsqoKKDyRZSC1/FQgMpqzChYslnAGA5ltVWAADx8DCL5csp89Fz0k8QYYf581+lNL1Pql6ZZUULyB0CvwuUyclNWHbR93HEoYdgw8Y85g4l8cjjT+Cir3wMiURq2sExdqy/jBEmJyfxjf/6MnKFLARJRG05xszQNYGRzTY4G1UBdqnvGA5543H4j1POxMSkCSkFNE3CsgBlmjBM4NOf+CruvvcmTKWnqtckbMUBQCHj6F+0LxOBmOiZW7+IjbiICctJ1UEAnjJQQsj7mHHU0Jzdua9ve2QyayFEDL2agAg8M+qwSgxd10P787rBuXr792majomJjVh64hk4+7RzMLK5gGRCRzo9hfM/+yFMTU2ir29g+mWxzpciIuQLOaz4w/8hlxt3pkyV+08Sfan+hhWNaZoYGBjCRRdeCmbAtBTmzolh2Tc/g6OOOAFvOPCNGBvPY5edt8e5Zy/Hl79+hlP+23MFgtZfKQN6agFSi/ZRAARBPAgiPmyYtTuWw6yLALxAIGl/NwyFRHKBmL9gP0xMPId4vLfgwq12y+ay8HbgImDbbbZz3bDIgBrA2GH7XSGkbTGFANKZNPL5AqSUNa2ZlBJT6XG8et/X42tf/i7SGft+ppISH//SeXjsiQec+nmj5d93ztBcu/S5htVtpO+AZ22kRDo9ii9e+D/YZ8ke2Lgpj3lzEvj7Pf/Az355MZ55biUOfM110DSJ8XEDp5z0Ydxwy29w9323YKB/qLcGIHCfrGIeqe0PQnxwe1ImQAJ3VR37qCdXrIACAAntAcPIjms6xOLt3szMVm9ZgANmZRXwwkurIDV7g858HnjDwYcjFuuDZVmQUgORAJGAlBosy4SmxXHk4W9HoWCfR9cYq9c8g3w+U9YYI+ozi8Ui5g7Nw/e+83Mkk30oFCxsszCOH/30cvz+T7/A3LnbgFlVLNCZTtch5pKAZ4UHOURV72dJKZGeGsfrD3orPnzqxzA2biAe05DJ5vHNSy9AIjGAf9xzI379m59hzhwdpmmBSOCzn/oOUsk+B/y9OWlPEgFWRQzt9CaWMU0Wc5kigf4JAHcAqm4CcOMAl11Gm4SQ9wGMxdsdouLxIbDqSS7X5N9z7+0AE4gkclkT++6zBOeceQHS6c2YSk+gUMijUMhhcmoc6fRmnHfORXjN/vsjmzVtRUCE2+78G+rb+FKhWMzhW1/5Efbec3dMTuQxZzCO3/zhj1j2jU8AAMbGNmFycqzCYxTFYqHJbkKMqfQ4MpkxTEyNY3JqrMpjHJOTYzBNo+ZnudI/lezHly78LqSQMAwLg4Marvr59/D4yvuQiPchkUjh+z9ahjXPr0VfKo7JqQL23/dVOO0DFyCTGesFBANzRGhJDO1yuCJikOBH34DEKnC0/18tBuDFAZjEDUrR2+bMXcLz5u+LjRvug673b9UVWEopJJODuPm2v2Dlk8/hlbu9Aul0EZmMhQs/NYxddtkdv//T1diw8WUQCWy/eEec9O7/wDuPOwmZjF1RNzQYx0OPrMT1N/0BqdQQVBUZK4REJjOB8z7+n3jnO96BzSNFxOMxpDM53PvAXXj7Me9FLJa0MwNRwTxmxHSJR1c+gjXPP9tAjp7AihHT4zjysHcim8vUdFWYAU0jPPrYgxgZ3eCsHajQDkxoSKc34MJPXoxX77sPNo3kMTiQwCOPPYGr/u+/kErNgWkaiMUS2LjpZVz6/S/he9/8KbJ5wuSUhTM+/Gnccscf8fSzjyGZ7Nu6VwSSgDJySM7fA/3bHMAMAgntxuXLSR0G1u4AzEYJwHYDdPy1UMh9Kx5P6jvtfAzWvXwXYrHBrZoA7M43GtLpSXz5q+fh6p/8EalUDJlMAZalcMrS9+M9J7wf6akciAgD/QmQACYmimAGBofimJycwhe+fBZyuSxSqf6qk1cpC6lUP9553CnIZiwnDchg6Bj+wsXQtOiGHS7sLBOYNxe48KLP46mnH4psWBL1HQHAMBX6+4fw39/5WVhpc/RnKQUM9AEfPPMU3HDrbzE4EN0URAiJqfQYXrv/YTj9g5/A2IQBIe0Mw3e+9zlkMlMYGJgDy7LsVYMD83Dd367GMW9diqPfehw2b85h7twkLvzkt3Hmucdu9fUpRALKzGHubkdCSw1KM1+EAP8ZABatrCwxK3Z+XL6cFDPT9y9NPMms7idi7LzL2614fI7Tk27rPizLQn//IO646wac9rH3YvPoOixcGEcypWNqykImY0LKOISIIZ0xkckwBgdjWLAghieffBynnvZ2/Pvh+9HXN1C35bIMEzFdQtd0SE0iFtNQLAKZNCObDT8y7s8ZRjZrIpO1G33U4y8T2cttNalD0ySkFMgX7DhH1CMX+l0hl4OzFJgqB6ucJcPLvvh9JJNxMBMWztex4ve/wJ3/+AsGBuaWBPcYmhbDxZd9HuPjUxgYSCKTUTjq8CPwvvd8DOn06NbtCrCC0BKYv8fxSkgmpYwnNq9L3g8wrVhBFeVl1RFbtgwSgCmE/DUzvXHu/H2w7eI34cUXbkQsNrTVZwMsy8Lg4FzcePN1eHzlQzj1lNPwlsPejp12eCX6Un2QTsbMMIDxyVE8+NCj+OsNv8fv/vT/kM5MYWCgsQj2ZHocm8cmkMsbftdermz5/U49FkjEUTSKdfnlhmFg8+gE0lmjvDswV/mVbffINHSYllnxs4gEcrlJnPmhz2DXnXfF8y9sRCIRw8OPrcf//HAZEon+skyCUgqJRB+eW/U4Lvvh13Dex76AiYkCcjkdH3jvJ3DbXX/GyOhG6Jq+9dUGkIBVzKB/u9dicIeDFTMJCPmbB35ERqX0n+/kVacVAZA6+/zM9jDwRDyRGnhq5a/41ps+SPH4vF7/tUAku1AooFBII5kcxHbbbo8FC7ZBMtkPVham0hPYsHEd1m98GZZZRCo1CCm1htNl/X0DEFJrqk8jESGXz6JQyFclAdu90ZFKDTTfD5II2ewUDKN6IHDO0DxYyq6DECSQy+eQy6Wrxg3g1LoPDc4HEaCYoWs6srk0cvksBImtbv6R0GBkR/DKY7+HHd54LpuFnElSvPrmLyeewDCLSgHAOggAWLqU5YoVZJ19bu4X8XjiA7nMuPnH3x6iTU6ugZQJVMgubIU+GEEICcsyUTSKME3TXjxDtr+ra7qzbp9q9L6vrjiYuek9PqQUTj1C7RiH3aW4en4iaudpr9m5qJ0KtOsVyOtSJISoqx7Czh4YoesVXnu1rW7mgZUBLTkP+5/+dys1b3tRzGVvuPUrfcc6Fb1VAVq306RL+QOjWPxAIjVH7L7Xqbj37i9C11O9Xmwh0NhKKx6LIxFPILjwtxWbV2iaNu1rrJfMdF1v+2fpeqyp9zEzNE1v6rttedZfwsyPYvHrzkRi7vakTEWC5JUAsHKf2qaiJmWuWEHW8DCL739Pv1tZ5l0EiN33+qA1MLgLTDOPXhFG9ARVSgWaZ6iWTNBwM5DGH932WdO5xul8ty3K+lsG9NRCLH7tWRYBZBq5x8e2i/8NYFpxMlnTJgAAWLkSBBDreuzbprIwMLgd9lpyGgxjCiRkD/G9o3fMmPWfwKL93o/Uwj3ACgRNv/iBs8k4bPh2WR+F1HkMD7NYtgx89rmZu2Px1OvT6fXWH1e8WeZzIxCi8mYTvaN39I72WH+wBZJx7H/6nSq1aA8q5jNPJ8b6Xn39PBhYDi7t/9e0AnBVABGxpse/qhSjf2Ax9t3/PBjGVER/+t7RO3pHe62/BjM/ge0OPBvJRXswK5DU9G9cfxkVDsPtoh7wN6QAXBWwfDmps8/N3KzFUkcaxYz159+9VW4eeRi63tdr0Ng7ekdn0A8284gP7YT9Tr/TiqXmS6uY+/fE+uTBDyyGheVUd4uKhvImdiwA0GTqs5ZRMPVYH177+uXc6xPWO3pHB/FPApaZw06H/ydiffPBygSR/tkHfkTG0n0is7OtIYAVK8haupTl5d+jBxWrHwCQO+38NrXHkg8hn9/ca9Y4s7Ois4/eMWPS38huxoK9T8TCV51iESCVVbzmluX6zUuvZVlP5L9pAgCAa6+FGh5mIc3ilw0j/6JiiNcevFzNmbMnTCNbV6FJ72g9+Nk0wJYR/reND9t77BFBp++zMvOIDyzGrkd9S4FAplEchZ66AMy05PHGI/FN3UG3OvCs8/LvliL2exJkvrDmeu2m606AFuuvvpd072jljACzBVYm4gMLO/KJDLtQqDg5AhCBmixN7h3NWH8JIzeKvU78P2yz//tNVtAsI3/mrcuTVzVj/ZsmAAA4bPg27Y7lR5hnnZe9StOTpwMw/3XPMu3Bfy5HMrUNlDJ6d6wTlt8ysN+p38W2B7wDVqEAuOWw5AM26m5XgyxT9Eyx2wQqyFgcm5+4A49e9TG4O0/00sDtBr8OI7MB2x38Cbzy+MtMUtBMI//HW5cn390s+KdFAGCm4WWgF7Po04z8vULE92a2rJuuO0G++Pz13m5CvaON1l9Z0OIpHPnNx9C3aC6sEmVeE/xUH/i5pA8AaYCRtnD7BUuQH18HocV6KqDNfr+ZH8fA9gdi3/+4Xgk9RazMtazHXnfrF7ERy0CoUfPfegIAsHTptXLFipOtcy4s7G+ZdDcJPZbLrhN//d1baXJitdM5qLdisH0CQMAqZrHwVUdi8f7HwTItkKDaFr7BOx8mAAWhaxh59A5seOA6iFiy5/K19R5LKDMHLTkf+334Zo7PfaUiGGRZ1lG3LU/e6rrjzZuRaR72emMyzzgv92FdT/yUFczNIw9p1//+GJhmDlLGevUBbXYDrHwGyiw0Hp2vtJSv1oxhhpA6ZGKgJ/3ba/oBZe+MtM+pf8ScXQ8zCdCMYu4zty1PXexib3o6sgXH8DBry5eTedb5hW9LGfssCMZLa27Ub77uJJDQIITWI4G2zhOBJhI605s1zGDVU3dtBT8rWMU09nrPL7Fo36UGGLpVLPz0luWJ01oB/pYRAMC0dCnEihVknXl+/hpNxk9mwFz9zO+0O274IITQeyTQO3pHE+Df/R1XYvGBp5msoCll3DD+kn78bmNQdut+mrb8apHZIF6xwq4PSOwS/6BlFW8CQ9tt9xPNw47+OZQynO3Fe2sGekfvaAj8B51mssUaK/N+yujvfeBHMFcsqW+hTwcJwCYBALjsPCqYWuwkyzLvUwxtlz1PMg87+udgZcCyCj0S6B29oxKCSALKDFl+ZSpNKfMpJbXjb/42TWC4+Yh/mwnA7iQ8PMziJ/9FU3kjexyzdS8Y2i57nGS+5fjfQGoJmEamVzLcO3pHmeHXoMwcmBl7veeXtuy3oIHVk8WiedStF9GGpUuvla0EfwtjAOHDXTX4ofPG5sS1gWuEkG9jwBzZ8IB2+98+gKnxZxFPzO8VC/WO3gG7yMfMjyHWvxh7nfRzzNntMJMVNFbmfTKvvfuGb9C6YWaxnKjlQbS2FXO7JHDuuRwvxKxfkJBLlYKVzbwk/nHTmfTSmuuRSC4AgF5wsHdsrZofRAJGZgSDO78Je777J5xcsLtFgKYs63rE5Ck3f54mppvrnxECCJIAAJzxaeNiIbULlGVBKUM9fO9XxKMPXAIp4tD0ZK9qsHdshZI/D8vIYLsDP4Zd3vpNJfUUCSlIWeaPDUv76B3Lyayns2/XEoBj3sktVTzjU7mzWIj/IdLjUpC55rk/avffcSGmJlYhnpgPu3tuTw30ji0a+SASMHObofcvxm5v+xYW7neqBaUks6kI8nM3D2sXB3HT1svpzLf26wTOOL/4epD4iZBybyZYmam19O9/fEk898SvIKQGXXd3helVmPWOLQr5ICFhGVkoI48FS07Arkd9g5PzX6nAkGyZzyvgzFuH9ZvsxT2tyfN3CQHYh1u99KHzeI7U1fcEiQ+BARIwX3j2j9pD93wFoxv/DT0+CCHjTqVZjwh6x+wHPltFGPkJ9C3cGzsd/iUsfNX7LAIkCGBWv5Ukzr3hS7SuVRV+XUkAgN9LAABOv9B8P7P6tib1HRSDi8VJ9dTDV8onH7oc2amXoMeHIGTMXlDUW23WO2Yl8A2YhQnofQux3evOwnYHf1Lp/QtAgLDM4ghIXnTLl7UflWJjiyUANy6w9GTbJTj9k1PbUCz1FVMVz9K0BIhgTY6toWce/aF47olfIJt+GZreD6nZq856MYLe0dWwJwGQgDILsIpT0PsWYtG+p2C7Az+mkov2ZChItkyAxNUWFS667T9Tz2OYBZaBQcSdp6kZPIKNDM74DB+ilPlVEtphTk8La2J0FT278qdizVPXYGr8OQgRg6b32ZuR9Migd3QN6u3AHrOCKmagrALiQzth4T4nYfFrTlepRXszAMkMsDLvg9C+fPOX6IZSDMyMTpnpI6AGAOD0z/B7mc0LiLQDSQLMULn0en7xuT+JNU9dQyPr7odpZiBlAlJP2uWT7GYPem5C7+iQvCey23OzgjJzUEYOQkuif/EBWLTPUp6/5ESVmLsDESCUApRVeAykfXfeXvLnK062t9tbjmXA8uVqZr9Jlxy2/2NHPoeHWbyYs05mZZ0HyNdLXQIMGIZhbt7wL/HSqj+J9c/fjInNT8I0svbadC1h71BEwokXuHvG9Uihd0wTIuQAHgSwshe3mXmwZUBoCSTn74G5u70F8/c4Xg1u/wYlk3GNCFAmw1LFhyDjl+kDuPr686gwU75+1xNAmAj8wfnIZ/lYKOMM0zKOi8VTCRKAUkAxnzHHRh6mjS/eLjau/QeNb34Mhewme8ERBITUIYQOEprTqbjXzrp31C1LPVXJygQrA8oyAFYgGUMstQCphXtjaMc38tAuh3P/tq9RWmpQCgkCA0Y+YwotdgNBv6pg4c9uVL+T6b1ZSwDODfDqBtxnPvwZ3h0wlrKy3sOKD4glkiACFAOmqaxs+mWeGH2Cxjc9LCZGHqOp8WeRTa+DURiDZeahlGG7CcwNEQHNwrnbxba04uVS1wyeLe1JaJBaAlpiDmIDi5Gc+wr0LXoVp7bZl/sWLlHxwR1IxjTpdlEy8wUw+DERi/0OJFbcdBE9Fo51dRfwZ838XrqU5ZIlYL8ckunMz+N1hjKOU6Z1tKWsA2KJvoTU3JACYFlg08irQn6U89kNVMhtRj6zngq5UZjGFBnFKVhmzpF1rcNNZH9cauI908E6dY4vuIUzjtvx+VTne5ghtARkbAAyPsB6ci70/m1ZTy1ArG8b1pLzSMaSQmj+lLFMwMinDSLxCEntJqLYn+fsjX96Ab1hFkv3AXUr8GedgRseZnE7IEqLJD54Ye4VIHEQmN/MynytUtidNG2erschpG/s2SEHdhVenROp0bbaXGWEuUEgcxPgr/YZ1QiDGwQZU+PA5AbBH2peSg28x2XVetug+4bfex8F5oyyAKtogK3iOIieA8kHIOjvUvB9N3w58VTwXIcNs3Y4oJa3uYR3qyOA4DQaHgbZZACrlF0/8gVeCMZuFhf3VEVzDxJiZ0upHYgwn1nNUcx9RBQnguQWg78lhNEsKJsEci3SqPYeqpdkGrXINVRU3e/hOu+X/X0sZi6QoCwRTTCwmQStZRbPCyGeZqKnE5r+7HUX0YbScxw2zNqileBWtenqEUCDymDlPqCNj99Odyw/3Kp0A4aHWTyXRrKgJuJ9FOujWFI3JFhZ+a4cgzyARIXnI4/4zF9zYRbOH6ElWGkgw4QBcyJTwFBx0T7IVcvNL72WJQAseTzoms7OY8sLizt1BRuX3E7A4Vi0EhyOIfSO3lGXZRFLVy6jjUtsjCxaCV5xLdRMVOv1CKBFroOr+YaX9Xa13JqO5fW+cBnYnxnUKyDpHb2jd/SO3tE7ekfv6B29o3dsacf/B98BwgSGrgyKAAAAAElFTkSuQmCC"

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

-- Background artwork for the main window (embedded JPEG, written once as a local custom asset).
local EMBEDDED_BACKGROUND = "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"

pcall(function()
    if type(writefile) ~= "function" or typeof(getcustomasset) ~= "function" then
        return
    end
    local folder = "UZEXHubAssets"
    if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(folder) then
        makefolder(folder)
    end
    local path = folder .. "/UZEXHubBackground.png"
    local data = decodeBase64(EMBEDDED_BACKGROUND)
    local fresh = type(isfile) == "function" and type(readfile) == "function" and isfile(path) and readfile(path) == data
    if not fresh then
        writefile(path, data)
    end
    local asset = getcustomasset(path)
    if type(asset) == "string" and asset ~= "" then
        Assets.Background = asset
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
        if multi then
            local n = #selectedList()
            valueLabel.Text = n > 0 and (n .. " selected") or "None"
        else
            valueLabel.Text = state ~= nil and tostring(state) or "None"
        end
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
    HopAutoCheck = false,
    AutoHopGodSpirit = false,
    AutoHopMaoshan = false,
    AutoHopTaoist = false,
    CastDelay = 1,
    AutoReel = false,
    AutoMiniGame = false,
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
    AutoEquipRod = false
}

local SAVE_FOLDER = "UZEXHub"
local SAVE_FILE = SAVE_FOLDER .. "/HeavyweighFishingConfig.json"

local function SaveConfig()
    pcall(function()
        if not isfolder(SAVE_FOLDER) then makefolder(SAVE_FOLDER) end
        writefile(SAVE_FILE, HttpService:JSONEncode(Config))
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
Config.AutoFarmIsland = false -- Auto Farm Fish was removed from the UI
Library.NotificationsEnabled = Config.NotificationsEnabled ~= false
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
    if UzexFilter.Skip then return end
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
                            if now - u14 >= 0.035 and now - lastPhase2HitTick >= 0.035 then
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
    if now - lastPhase2HitTick < 0.04 then return end

    local evalX = barCenter
    local targetTime = now - 0.041
    for i = #phase2BarHistory, 1, -1 do
        if phase2BarHistory[i].t <= targetTime then
            evalX = phase2BarHistory[i].x
            break
        end
    end

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
                task.delay(0.01, function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end)
            end)
        end
    end
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
                local bestDist = 0.18
                for _, child in ipairs(laneFrame:GetChildren()) do
                    if child.Name == "Note_FX" and child:IsA("GuiObject") and child.Visible then
                        local dist = math.abs(child.Position.Y.Scale - targetY)
                        if dist <= bestDist then
                            bestDist = dist
                            targetNote = child
                        end
                    end
                end
                if targetNote then
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

RunService.RenderStepped:Connect(function()
    if not FishingGui or not FishingGui.Visible then return end
    BindFishingBarLock()
    LockFishingBar()
    if Config.AutoMiniGame then
        StepPhase2MiniGame()
    end
end)

RunService.Stepped:Connect(function()
    if not FishingGui or not FishingGui.Visible then return end
    BindFishingBarLock()
    LockFishingBar()
end)

RunService.Heartbeat:Connect(function()
    if not FishingGui or not FishingGui.Visible then return end
    BindFishingBarLock()
    LockFishingBar()
    if Config.AutoMiniGame then
        StepPhase2MiniGame()
        if not UzexFilter.BTActive then
            StepRhythmMiniGame()
        end
    end
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
                    if not UzexFilter.HoldingRod() then
                        pcall(function()
                            ToggleHotbar:InvokeServer("1")
                        end)
                        task.wait(0.15)
                    end
                    SecretFarmCast()
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

    pcall(function()
        local minigame = Events:FindFirstChild("FishingMinigame")
        if not minigame then return end
        minigame.OnClientEvent:Connect(function(data, _, token)
            local fishName = type(data) == "table" and data.FishName or nil
            lastHookedName = tostring(fishName or "")
            if not Config.AutoSkipFish or not fishName then return end
            local skipSet = {}
            if type(Config.SkipFishList) == "table" then
                for _, name in ipairs(Config.SkipFishList) do
                    skipSet[name] = true
                end
            end
            if not skipSet[fishName] then return end
            skipRequestId = skipRequestId + 1
            local myId = skipRequestId
            task.delay(3, function()
                if Config.AutoSkipFish and myId == skipRequestId and token ~= nil then
                    pcall(function()
                        minigame:FireServer(false, token)
                    end)
                end
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
        local activeReel = (Config.AutoReel or Config.AutoMiniGame or Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland) and not UzexFilter.Skip and not secretFarmOn
        local secretFarmOn = UzexFilter.SecretFarmAllowed()
        local activeCast = (Config.AutoCast or Config.AutoFarmIsland or Config.FilterBossFish) and not secretFarmOn
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
local DISCORD_INVITE = "https://discord.gg/pzVJV34AH8"

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
end


Tabs.Settings:CreateSection("Language / Ngôn ngữ")
Tabs.Settings:CreateDropdown({
    Flag = "LanguageDropdown",
    Name = "Language / Ngôn ngữ",
    Options = {"Tiếng Việt", "English"},
    CurrentOption = Library.Language,
    MultipleOptions = false,
    AllowNone = false,
    Callback = function(Value)
        if type(Value) == "table" then Value = Value[1] end
        Library:SetLanguage(Value)
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

Tabs.Shop:CreateSection("Cá")

Tabs.Shop:CreateButton({
    Name = "Mở khóa tất cả cá",
    Description = "Shows every fish as unlocked in the Index menu",
    Callback = function()
        local count = 0
        local found = false
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local mg = (pg and pg:FindFirstChild("MainGui")) or MainGui
            if not mg then return end
            local root = nil
            for _, d in ipairs(mg:GetDescendants()) do
                if d:IsA("Frame") or d:IsA("ScrollingFrame") then
                    local n = string.lower(d.Name)
                    if n == "index" or string.find(n, "fishindex", 1, true) or string.find(n, "codex", 1, true)
                        or string.find(n, "collection", 1, true) or string.find(n, "bestiary", 1, true) then
                        root = d
                        break
                    end
                end
            end
            if not root then return end
            found = true
            -- First remove visual lock/cover layers.
            for _, d in ipairs(root:GetDescendants()) do
                local n = string.lower(d.Name)
                if d:IsA("GuiObject") and (n == "lock" or n == "locked" or n == "unknown" or n == "hidden"
                    or string.find(n, "question", 1, true) or n == "cover") then
                    if d.Visible then
                        d.Visible = false
                        count = count + 1
                    end
                elseif d:IsA("ImageLabel") and d.ImageColor3 == Color3.new(0, 0, 0) then
                    d.ImageColor3 = Color3.new(1, 1, 1)
                    count = count + 1
                end
            end

            -- Some Index cards keep the fish name on the card/frame while the
            -- visible TextLabel is still "???". Recover only when the card name
            -- itself is a meaningful name; never fabricate a fish name.
            local genericNames = {
                index = true, fishindex = true, codex = true, collection = true,
                bestiary = true, fish = true, item = true, entry = true, card = true,
                template = true, scrollingframe = true, frame = true, content = true,
                list = true, grid = true, holder = true, container = true, unknown = true,
                hidden = true, ["???"] = true
            }
            for _, label in ipairs(root:GetDescendants()) do
                if label:IsA("TextLabel") and (label.Text == "???" or label.Text == "??? ???") then
                    local node = label.Parent
                    local candidate = nil
                    for _ = 1, 5 do
                        if not node or node == root then break end
                        local nodeName = tostring(node.Name or "")
                        local lowered = string.lower(nodeName)
                        if nodeName ~= "" and not genericNames[lowered]
                            and not string.find(lowered, "template", 1, true)
                            and not string.find(lowered, "unknown", 1, true)
                            and not string.find(nodeName, "?", 1, true) then
                            candidate = nodeName
                            break
                        end
                        node = node.Parent
                    end
                    if candidate then
                        label.Text = candidate
                        count = count + 1
                    end
                end
            end
        end)
        pcall(function()
            Library:Notify({
                Title = "Unlock all fish",
                Content = found and ("Unlocked " .. count .. " entries") or "Index menu not found - open it once, then press again",
                Type = found and "success" or "warning",
                Duration = 4,
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
    local savedAppearance = {}                      -- SurfaceAppearance -> original parent (strong: it is unparented)
    local savedPerf = nil
    local descConn = nil
    local optimized = 0
    local FX_CLASSES = {
        ParticleEmitter = true, Trail = true, Beam = true, Smoke = true,
        Fire = true, Sparkles = true, BloomEffect = true, BlurEffect = true,
        SunRaysEffect = true, DepthOfFieldEffect = true, Clouds = true,
        PointLight = true, SpotLight = true, SurfaceLight = true, Highlight = true,
    }

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
                local fidelity
                if inst:IsA("MeshPart") then
                    fidelity = inst.RenderFidelity
                end
                savedParts[inst] = { inst.Material, inst.Reflectance, inst.CastShadow, fidelity }
                inst.Material = Enum.Material.SmoothPlastic
                inst.Reflectance = 0
                inst.CastShadow = false
                if fidelity then
                    inst.RenderFidelity = Enum.RenderFidelity.Performance
                end
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
                    mine.quality = settings().Rendering.QualityLevel
                    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                end)
                pcall(function()
                    local ugs = UserSettings():GetService("UserGameSettings")
                    mine.saved = ugs.SavedQualityLevel
                    ugs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
                end)
                pcall(function()
                    mine.lighting = {
                        Lighting.GlobalShadows, Lighting.EnvironmentDiffuseScale,
                        Lighting.EnvironmentSpecularScale, Lighting.ShadowSoftness,
                    }
                    Lighting.GlobalShadows = false
                    Lighting.EnvironmentDiffuseScale = 0
                    Lighting.EnvironmentSpecularScale = 0
                    Lighting.ShadowSoftness = 0
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
        Description = "Lower graphics: flat materials, no shadows/effects/lights/textures for more FPS",
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

    -- keeps the fishing rod in hand (waits while the fish filter is swapping the rod itself)
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

-------------------------------------------------------------------------------
-- Support helper: copies what the boss menu looks like so the difficulty picker
-- (Normal / Hard / Nightmare) can be matched to the game exactly.
-------------------------------------------------------------------------------
do
    Tabs.Misc:CreateButton({
        Name = "Copy Boss Menu Info",
        Description = "Open the boss menu, pick Nightmare by hand, then press this and send the text",
        Callback = function()
            local out = { "BossMode setting: " .. tostring(Config.BossMode) }
            local frame = FindBossMenuFrame()
            if not frame then
                out[#out + 1] = "Boss menu frame not found (open the boss menu first)"
            else
                out[#out + 1] = "Frame: " .. frame:GetFullName() .. " | Visible=" .. tostring(frame.Visible)
                local count = 0
                for _, d in ipairs(frame:GetDescendants()) do
                    if count >= 140 then
                        out[#out + 1] = "... (more items not listed)"
                        break
                    end
                    local line
                    if d:IsA("GuiButton") then
                        line = string.format("[Button] %s | text=%q | vis=%s | bg=%s",
                            d.Name, GetButtonLabelText(d), tostring(d.Visible), tostring(d.BackgroundColor3))
                    elseif d:IsA("TextLabel") then
                        line = string.format("[Label] %s | text=%q | vis=%s", d.Name, d.Text, tostring(d.Visible))
                    elseif d:IsA("UIStroke") then
                        line = string.format("[Stroke] on %s | color=%s | thick=%s | enabled=%s",
                            d.Parent and d.Parent.Name or "?", tostring(d.Color), tostring(d.Thickness), tostring(d.Enabled))
                    end
                    if line then
                        local attrs = {}
                        for k, v in pairs(d:GetAttributes()) do
                            attrs[#attrs + 1] = k .. "=" .. tostring(v)
                        end
                        if #attrs > 0 then
                            line = line .. " | attrs: " .. table.concat(attrs, ", ")
                        end
                        out[#out + 1] = line
                        count = count + 1
                    end
                end
            end
            local remotes = {}
            for _, folder in ipairs({ Events, ReplicatedStorage:FindFirstChild("Remotes") }) do
                if folder then
                    for _, r in ipairs(folder:GetChildren()) do
                        if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) and string.find(string.lower(r.Name), "boss", 1, true) then
                            remotes[#remotes + 1] = r.ClassName .. ":" .. r.Name
                        end
                    end
                end
            end
            out[#out + 1] = "Boss remotes: " .. (#remotes > 0 and table.concat(remotes, ", ") or "none")

            local dump = table.concat(out, "\n")
            if #dump > 7000 then
                dump = string.sub(dump, 1, 7000)
            end
            local copied = type(setclipboard) == "function" and pcall(setclipboard, dump)
            Library:Notify({
                Title = "Boss menu",
                Content = copied and "Copied. Paste it into the chat." or "Could not copy to the clipboard.",
                Type = copied and "success" or "error",
                Duration = 4,
            })
        end
    })
end

Window:SelectTab(Tabs.Main)
