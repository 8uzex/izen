-- Uzex Hub | Key Loader
-- Premium (không hiện bảng nhập key):
--   getgenv().Key = "UZEX-XXXX-XXXX-XXXX-XXXX"
--   loadstring(game:HttpGet("https://link-toi-file-nay"))()
-- Free: chạy script không cần đặt key, bấm "Lấy key" để mở trang lấy key,
--   dán key vào ô rồi bấm "Kiểm tra key". Key đúng được lưu lại cho lần sau.

---------------- CẤU HÌNH (chủ bot sửa) ----------------
local API_URL        = "https://equipment-barrel-hardcover.ngrok-free.dev"   -- link ngrok cố định của bot
local SCRIPT_PREMIUM = "https://raw.githubusercontent.com/8uzex/izen/refs/heads/main/loader.lua"
local SCRIPT_FREE    = "https://raw.githubusercontent.com/8uzex/izen/refs/heads/main/loader.lua"
local GET_KEY_URL    = "https://izoki.bytecraft.workers.dev/uzexhub"          -- trang lấy key free
local SAVE_FILE      = "UzexHub_Key.txt"                                       -- nơi lưu key đã nhập đúng
---------------------------------------------------------

local HttpService      = game:GetService("HttpService")
local Analytics        = game:GetService("RbxAnalyticsService")
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local function notify(msg)
    warn("[Uzex] " .. msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Uzex Hub", Text = msg, Duration = 6,
        })
    end)
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

local REASONS = {
    invalid_key   = "Key không tồn tại.",
    expired       = "Key đã hết hạn.",
    hwid_mismatch = "Key đã gắn thiết bị khác. Dùng Reset HWID trong Discord.",
}

-- Trả về "free" / "premium", hoặc nil kèm thông báo lỗi.
local function verify(key)
    local url = string.format(
        "%s/verify?key=%s&hwid=%s",
        API_URL, HttpService:UrlEncode(key), HttpService:UrlEncode(hwid)
    )
    local okReq, body = pcall(httpGet, url)
    if not okReq then
        return nil, "Không kết nối được server key (bot offline hoặc sai API_URL)."
    end
    local okJson, res = pcall(function() return HttpService:JSONDecode(body) end)
    if not okJson or type(res) ~= "table" then
        return nil, "Server trả về dữ liệu lỗi: " .. tostring(body):sub(1, 80)
    end
    if not res.ok then
        return nil, REASONS[res.reason] or ("Key bị từ chối: " .. tostring(res.reason))
    end
    return string.lower(tostring(res.tier))
end

local function launch(tier)
    notify("Key hợp lệ (" .. string.upper(tier) .. "). Đang tải script...")
    local scriptUrl = (tier == "premium") and SCRIPT_PREMIUM or SCRIPT_FREE
    local okLoad, err = pcall(function()
        loadstring(game:HttpGet(scriptUrl))()
    end)
    if not okLoad then
        notify("Lỗi khi tải script: " .. tostring(err))
    end
end

local function saveKey(key)
    pcall(function()
        if type(writefile) == "function" then
            writefile(SAVE_FILE, key)
        end
    end)
end

local function savedKey()
    local value
    pcall(function()
        if type(isfile) == "function" and type(readfile) == "function" and isfile(SAVE_FILE) then
            value = readfile(SAVE_FILE)
        end
    end)
    if type(value) == "string" then
        value = value:gsub("%s+", "")
        if value ~= "" then
            return value
        end
    end
    return nil
end

---------------- Bảng nhập key (cho người dùng free) ----------------
local function showPrompt(prefill)
    local lp = Players.LocalPlayer
    local parent
    pcall(function()
        parent = (type(gethui) == "function" and gethui()) or CoreGui
    end)
    parent = parent or lp:WaitForChild("PlayerGui")

    local old = parent:FindFirstChild("UzexKeyPrompt")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "UzexKeyPrompt"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 10001
    gui.Parent = parent

    local BG, SURFACE, SURFACE2 = Color3.fromRGB(14, 14, 15), Color3.fromRGB(26, 26, 29), Color3.fromRGB(38, 38, 42)
    local STROKE, TEXT, MUTED = Color3.fromRGB(58, 58, 62), Color3.fromRGB(236, 236, 240), Color3.fromRGB(138, 138, 146)
    local OK, BAD = Color3.fromRGB(130, 215, 160), Color3.fromRGB(240, 100, 100)

    local center = UDim2.new(0.5, 0, 0.5, 0)
    local card = Instance.new("CanvasGroup")
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = center + UDim2.fromOffset(0, 14)
    card.Size = UDim2.fromOffset(360, 250)
    card.BackgroundColor3 = BG
    card.BorderSizePixel = 0
    card.GroupTransparency = 1
    card.Parent = gui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = STROKE
    cardStroke.Transparency = 0.2

    local scale = Instance.new("UIScale", card)
    local cam = workspace.CurrentCamera
    if cam then
        scale.Scale = math.clamp(cam.ViewportSize.X * 0.92 / 360, 0.55, 1)
    end

    local body = Instance.new("Frame", card)
    body.Size = UDim2.fromScale(1, 1)
    body.BackgroundTransparency = 1
    local padding = Instance.new("UIPadding", body)
    padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 20), UDim.new(0, 20)
    padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 18), UDim.new(0, 18)
    local layout = Instance.new("UIListLayout", body)
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local function label(props)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamMedium
        l.TextSize = 12
        l.TextColor3 = MUTED
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextWrapped = true
        for k, v in pairs(props) do l[k] = v end
        l.Parent = body
        return l
    end

    label({ Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = TEXT, Text = "Uzex Hub", LayoutOrder = 1 })
    label({
        Size = UDim2.new(1, 0, 0, 44),
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = "Free: bấm \"Lấy key\", làm theo trang web rồi dán key vào ô bên dưới.\nPremium: đặt getgenv().Key = \"KEY\" trước khi chạy script.",
        LayoutOrder = 2,
    })

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, 0, 0, 40)
    input.BackgroundColor3 = SURFACE
    input.BorderSizePixel = 0
    input.Font = Enum.Font.GothamMedium
    input.TextSize = 13
    input.TextColor3 = TEXT
    input.PlaceholderText = "Dán key vào đây"
    input.PlaceholderColor3 = MUTED
    input.ClearTextOnFocus = false
    input.Text = prefill or ""
    input.LayoutOrder = 3
    input.Parent = body
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 10)
    local inputPad = Instance.new("UIPadding", input)
    inputPad.PaddingLeft, inputPad.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
    local inputStroke = Instance.new("UIStroke", input)
    inputStroke.Color = STROKE

    local status = label({ Size = UDim2.new(1, 0, 0, 16), Text = "", LayoutOrder = 4 })

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundTransparency = 1
    row.LayoutOrder = 5
    row.Parent = body
    local rowLayout = Instance.new("UIListLayout", row)
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.Padding = UDim.new(0, 10)
    rowLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function button(text, order, filled)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.5, -5, 1, 0)
        b.BackgroundColor3 = filled and TEXT or SURFACE2
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.TextColor3 = filled and BG or TEXT
        b.Text = text
        b.LayoutOrder = order
        b.Parent = row
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = 0.12 }):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
        end)
        return b
    end

    local checkBtn = button("Kiểm tra key", 1, true)
    local getBtn = button("Lấy key", 2, false)

    local close = Instance.new("TextButton")
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -10, 0, 10)
    close.Size = UDim2.fromOffset(26, 26)
    close.BackgroundTransparency = 1
    close.Font = Enum.Font.GothamBold
    close.TextSize = 16
    close.TextColor3 = MUTED
    close.Text = "x"
    close.ZIndex = 5
    close.Parent = card

    local function setStatus(msg, color)
        status.Text = msg
        status.TextColor3 = color or MUTED
    end

    local done, busy = false, false

    local function closeGui()
        if done then return end
        done = true
        TweenService:Create(card, TweenInfo.new(0.25), {
            GroupTransparency = 1, Position = center + UDim2.fromOffset(0, 14),
        }):Play()
        task.delay(0.3, function() gui:Destroy() end)
    end

    local function submit()
        if busy or done then return end
        local typed = input.Text:gsub("%s+", "")
        if typed == "" then
            return setStatus("Nhập key trước đã.", BAD)
        end
        busy = true
        setStatus("Đang kiểm tra...", MUTED)
        task.spawn(function()
            local tier, message = verify(typed)
            if tier then
                setStatus("Key hợp lệ (" .. string.upper(tier) .. ").", OK)
                saveKey(typed)
                task.wait(0.6)
                closeGui()
                launch(tier)
            else
                setStatus(message or "Key không hợp lệ.", BAD)
                for _, dx in ipairs({ 8, -8, 5, -5, 0 }) do
                    TweenService:Create(card, TweenInfo.new(0.05), { Position = center + UDim2.fromOffset(dx, 0) }):Play()
                    task.wait(0.05)
                end
            end
            busy = false
        end)
    end

    checkBtn.MouseButton1Click:Connect(submit)
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then submit() end
    end)
    getBtn.MouseButton1Click:Connect(function()
        local copied = false
        if type(setclipboard) == "function" then
            copied = pcall(setclipboard, GET_KEY_URL)
        end
        setStatus(copied and "Đã copy link. Dán vào trình duyệt để lấy key." or GET_KEY_URL, copied and OK or MUTED)
    end)
    close.MouseButton1Click:Connect(closeGui)

    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
        GroupTransparency = 0, Position = center,
    }):Play()
end

---------------- Luồng chính ----------------
-- 1) Premium: getgenv().Key = "..." -> kiểm tra và vào thẳng.
local presetKey = getgenv().Key
if type(presetKey) == "string" and presetKey:gsub("%s+", "") ~= "" then
    presetKey = presetKey:gsub("%s+", "")
    local tier, message = verify(presetKey)
    if tier then
        saveKey(presetKey)
        return launch(tier)
    end
    notify(message or "Key không hợp lệ.")
    return showPrompt(presetKey)
end

-- 2) Key đã lưu từ lần trước (free hoặc premium).
local stored = savedKey()
if stored then
    local tier = verify(stored)
    if tier then
        return launch(tier)
    end
end

-- 3) Free: hiện bảng nhập key, có nút "Lấy key".
showPrompt()
