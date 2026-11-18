local ProtectionConfig = {
    SecretKey = "2009",
    
    -- The name of your Hub (shown in the kick message if they try to bypass)
    HubName = "Uzex Hub"
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
    ["Uzex Hub"] = "Uzex Hub", ["Trang chủ"] = "Home", ["Chính"] = "Main",
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
    ["Tự động câu cá Boss"] = "Auto Farm Boss", ["Tự động câu cá Secret Boss"] = "Auto Farm Secret Boss",
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
    local folder = "UzexHubAssets"
    if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(folder) then
        makefolder(folder)
    end
    local path = folder .. "/UzexHubLogo.png"
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
    local folder = "UzexHubAssets"
    if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(folder) then
        makefolder(folder)
    end
    local path = folder .. "/UzexHubBackground.jpg"
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
    Muted = Color3.fromRGB(138, 138, 146),
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
        warn("[Uzex Hub] callback error: " .. tostring(err))
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
        Name = "UzexHubUI",
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
        Text = tostring(o.Title or "Uzex Hub"),
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
        BackgroundTransparency = (Assets.Background ~= "") and 0.25 or 0,
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
        BackgroundTransparency = (Assets.Background ~= "") and 0.25 or 0,
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
        BackgroundTransparency = (Assets.Background ~= "") and 0.25 or 0,
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
        BackgroundTransparency = (Assets.Background ~= "") and 0.25 or 0,
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
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = 0,
        }, main)
        -- darker on the sidebar side, lets the artwork show through on the right
        local shade = main:FindFirstChild("BackgroundShade")
        new("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.28, 0.1),
                NumberSequenceKeypoint.new(1, 0.55),
            }),
        }, shade)
    end

    -- title bar
    local top = new("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = Theme.Topbar,
        BackgroundTransparency = hasBg and 0.35 or 0,
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
        Text = tostring(o.Name or o.Title or "Uzex Hub"),
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
        BackgroundTransparency = hasBg and 0.3 or 0,
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
-- Uzex Hub application
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
    FilterSecretFish = false,
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

local SAVE_FOLDER = "UzexHub"
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
            if isfile("UzexHub/rejoin.flag") and delfile then
                pcall(delfile, "UzexHub/rejoin.flag")
            end
            -- only run when Auto Execute is ON in the saved config
            if isfile("UzexHub/HeavyweighFishingConfig.json") then
                local dec = HttpService:JSONDecode(readfile("UzexHub/HeavyweighFishingConfig.json"))
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

local function LockFishingBar()
    if isLockingBar then return end
    if UzexFilter.Skip then return end
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
        StepRhythmMiniGame()
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
        local filterOn = (Config.FilterBossFish or Config.FilterSecretFish)
            and not (Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland)
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
                if (Config.FilterBossFish and isBoss and not isSecret) or (Config.FilterSecretFish and isSecret) then
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
            if not (Config.FilterBossFish or Config.FilterSecretFish) or UzexFilter.HoldingRod() then
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
        local activeReel = (Config.AutoReel or Config.AutoMiniGame or Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland) and not UzexFilter.Skip
        local activeCast = Config.AutoCast or Config.AutoFarmIsland or Config.FilterBossFish or Config.FilterSecretFish
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
                local esp = head:FindFirstChild("UzexHubESP")
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
                    local esp = head:FindFirstChild("UzexHubESP")
                    if hum.Health > 0 then
                        if not esp then
                            esp = Instance.new("BillboardGui")
                            esp.Name = "UzexHubESP"
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
-- Replace this placeholder with the real Uzex Hub Discord invite when it is available.
-- The Home tab exposes this URL and copies it when its link button is pressed.
local DISCORD_INVITE = "https://discord.gg/pzVJV34AH8"

local Window = Library:CreateWindow({
    Name = "Uzex Hub",
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
        Title = "Uzex Hub",
        Desc = "Heavyweigh Fishing",
        Discord = DISCORD_INVITE,
        DiscordTitle = "Uzex Hub Discord",
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

-- Keep the draggable Uzex Hub logo; all window visibility changes
-- go through Uzex UI, including restoring a hidden window.
do
    local LogoGui = Instance.new("ScreenGui")
    LogoGui.Name = "UzexHubLogoGui"
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
    Shop = Window:CreateTab({ Name = "Cửa hàng", Icon = "shopping-cart" }),
    Upgrade = Window:CreateTab({ Name = "Nâng cấp", Icon = "arrow-up" }),
    Misc = Window:CreateTab({ Name = "Khác", Icon = "layers" }),
    Settings = Window:CreateTab({ Name = "Cài đặt", Icon = "settings" })
}

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
    Flag = "FilterSecretFishToggle",
    Name = "Tự động câu cá Secret Boss",
    CurrentValue = Config.FilterSecretFish,
    Callback = function(Value)
        Config.FilterSecretFish = Value
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
                    username = "Uzex Hub",
                    embeds = {
                        {
                            title = title,
                            description = description,
                            color = color or COLOR_INFO,
                            fields = fields,
                            footer = { text = "Uzex Hub" },
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
        sendWebhook("Uzex Hub", "The script is running.", COLOR_INFO, {})
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
        return inst:FindFirstAncestor("UzexHubUI") ~= nil or inst:FindFirstAncestor("UzexKeyPrompt") ~= nil
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
