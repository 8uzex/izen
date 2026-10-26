-- Uzex Hub | Key Loader
-- Cách dùng (người dùng):
--   getgenv().Key = "UZEX-XXXX-XXXX-XXXX-XXXX"
--   loadstring(game:HttpGet("https://link-toi-file-nay"))()

---------------- CẤU HÌNH (chủ bot sửa) ----------------
local API_URL        = "http://YOUR_SERVER_IP:8080"   -- địa chỉ công khai của bot (API_PORT)
local SCRIPT_PREMIUM = "https://raw.githubusercontent.com/8uzex/izen/refs/heads/main/uzexhub.lua"
local SCRIPT_FREE    = "https://raw.githubusercontent.com/8uzex/izen/refs/heads/main/uzexhub.lua"
---------------------------------------------------------

local HttpService = game:GetService("HttpService")
local Analytics   = game:GetService("RbxAnalyticsService")

local function notify(msg)
    warn("[Uzex] " .. msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Uzex Hub", Text = msg, Duration = 6,
        })
    end)
end

local key = getgenv().Key
if type(key) ~= "string" or key == "" then
    return notify('Thiếu key. Hãy đặt getgenv().Key = "KEY CỦA BẠN" trước khi chạy.')
end

local function getHwid()
    local ok, id = pcall(function()
        if type(gethwid) == "function" then return gethwid() end
        return Analytics:GetClientId()
    end)
    return ok and id or nil
end

local hwid = getHwid()
if not hwid or hwid == "" then
    return notify("Không lấy được HWID từ executor.")
end

-- Gọi API /verify của bot
local url = string.format(
    "%s/verify?key=%s&hwid=%s",
    API_URL, HttpService:UrlEncode(key), HttpService:UrlEncode(hwid)
)

local okReq, body = pcall(function() return game:HttpGet(url) end)
if not okReq then
    return notify("Không kết nối được server key (bot offline hoặc sai API_URL).")
end

local okJson, res = pcall(function() return HttpService:JSONDecode(body) end)
if not okJson or type(res) ~= "table" then
    return notify("Server trả về dữ liệu lỗi.")
end

if not res.ok then
    local reasons = {
        invalid_key   = "Key không tồn tại.",
        expired       = "Key đã hết hạn.",
        hwid_mismatch = "Key đã gắn thiết bị khác. Dùng Reset HWID trong Discord.",
    }
    return notify(reasons[res.reason] or ("Key bị từ chối: " .. tostring(res.reason)))
end

notify("Key hợp lệ (" .. string.upper(tostring(res.tier)) .. "). Đang tải script...")

local scriptUrl = (res.tier == "premium") and SCRIPT_PREMIUM or SCRIPT_FREE
local okLoad, err = pcall(function()
    loadstring(game:HttpGet(scriptUrl))()
end)
if not okLoad then
    notify("Lỗi khi tải script: " .. tostring(err))
end
