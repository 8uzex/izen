-- Uzex Hub | Key Loader
-- Cách dùng (người dùng):
--   getgenv().Key = "UZEX-XXXX-XXXX-XXXX-XXXX"
--   loadstring(game:HttpGet("https://link-toi-file-nay"))()

---------------- CẤU HÌNH (chủ bot sửa) ----------------
local API_URL        = "https://equipment-barrel-hardcover.ngrok-free.dev"   -- link ngrok cố định của bot
local SCRIPT_PREMIUM = "https://raw.githubusercontent.com/8uzex/izen/refs/heads/main/loader.lua"
local SCRIPT_FREE    = "https://raw.githubusercontent.com/8uzex/izen/refs/heads/main/loader.lua"
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

-- ngrok free hiện trang cảnh báo HTML nếu không có header này -> JSON bị lỗi.
-- game:HttpGet không gửi được header, nên dùng hàm request của executor.
local function httpGet(u)
    local req = (syn and syn.request) or (http and http.request)
        or http_request or request or (fluxus and fluxus.request)
    if req then
        local ok, r = pcall(req, {
            Url = u,
            Method = "GET",
            Headers = {
                ["ngrok-skip-browser-warning"] = "1",
                ["User-Agent"] = "UzexLoader/1.0",
            },
        })
        local b = ok and r and (r.Body or r.body)
        if b then return b end
    end
    return game:HttpGet(u)
end

local okReq, body = pcall(httpGet, url)
if not okReq then
    return notify("Không kết nối được server key (bot offline hoặc sai API_URL).")
end

local okJson, res = pcall(function() return HttpService:JSONDecode(body) end)
if not okJson or type(res) ~= "table" then
    return notify("Server trả về dữ liệu lỗi: " .. tostring(body):sub(1, 80))
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
