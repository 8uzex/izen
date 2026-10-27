-- UZEXHUB AUTH V14: expiry sync, Pre Lifetime key support, Thursday/Friday no-key schedule.
-- No-key days are Thursday and Friday in UTC only.
--// UZEXHUB KEY SYSTEM UI V1 - UZEXHUB AUTH LIFETIME PRE / THU-FRI
--// UZEXHUB AUTH - Current Worker
--// GET KEY copies the website. VERIFY KEY validates the key and executes the embedded script.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Player = Players.LocalPlayer

local VERIFY_URL = "https://izoki.bytecraft.workers.dev/uzexhubuzexhub/verify?key="
-- Verification always includes the executor HWID when one is available.
local GUI_NAME = "KhfreshKeySystem"

--// FREE SCHEDULE (UTC)
--// Thursday = 5 and Friday = 6 when using os.date("!*t").wday.
--// Saturday is not a free day.
local FREE_WEEKDAYS_UTC = {
    [5] = "THURSDAY",
    [6] = "FRIDAY",
}

local function getUTCDateInfo()
    local ok, value = pcall(function()
        return os.date("!*t")
    end)

    if ok and type(value) == "table" and tonumber(value.wday) then
        return value
    end

    return nil
end

local function getUTCDayName()
    local utc = getUTCDateInfo()
    if not utc then
        return "UNKNOWN"
    end

    local names = {
        [1] = "SUNDAY",
        [2] = "MONDAY",
        [3] = "TUESDAY",
        [4] = "WEDNESDAY",
        [5] = "THURSDAY",
        [6] = "FRIDAY",
        [7] = "SATURDAY",
    }

    return names[tonumber(utc.wday)] or "UNKNOWN"
end

local function isFreeDayUTC()
    local utc = getUTCDateInfo()
    if not utc then
        -- Fail closed: when UTC cannot be read, require the normal key flow.
        return false
    end

    return FREE_WEEKDAYS_UTC[tonumber(utc.wday)] ~= nil
end

local FREE_DAY_UTC = isFreeDayUTC()
local CURRENT_UTC_DAY = getUTCDayName()

pcall(function()
    local old = CoreGui:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end
end)

--// ============================================================
--// Helpers
--// ============================================================

local function tween(obj, info, props)
    local ok, tw = pcall(function()
        return TweenService:Create(obj, info, props)
    end)
    if ok and tw then
        tw:Play()
        return tw
    end
end

local function requestGet(url)
    local synApi = syn and syn.request
    if type(synApi) == "function" then
        return synApi({Url = url, Method = "GET"})
    end

    local globalRequest = rawget(_G, "request")
    if type(globalRequest) == "function" then
        return globalRequest({Url = url, Method = "GET"})
    end

    local httpRequest = rawget(_G, "http_request")
    if type(httpRequest) == "function" then
        return httpRequest({Url = url, Method = "GET"})
    end

    local httpGlobal = rawget(_G, "http")
    if type(httpGlobal) == "table" and type(httpGlobal.request) == "function" then
        return httpGlobal.request({Url = url, Method = "GET"})
    end

    return {
        StatusCode = 200,
        Body = game:HttpGet(url)
    }
end

local function getStableHWID()
    if type(gethwid) == "function" then
        local ok, value = pcall(gethwid)
        if ok and value and tostring(value) ~= "" then
            return tostring(value)
        end
    end

    local okService, analytics = pcall(function()
        return game:GetService("RbxAnalyticsService")
    end)

    if okService and analytics then
        local okClient, clientId = pcall(function()
            return analytics:GetClientId()
        end)
        if okClient and clientId and tostring(clientId) ~= "" then
            return tostring(clientId)
        end
    end

    return ""
end

local function getClipboard()
    local getter = rawget(_G, "getclipboard")
    if type(getter) == "function" then
        local ok, value = pcall(getter)
        if ok and value ~= nil then return tostring(value) end
    end

    local getter2 = rawget(_G, "readclipboard")
    if type(getter2) == "function" then
        local ok, value = pcall(getter2)
        if ok and value ~= nil then return tostring(value) end
    end

    return nil
end

local function setClipboard(value)
    value = tostring(value or "")

    local candidates = {
        rawget(_G, "setclipboard"),
        rawget(_G, "toclipboard"),
        rawget(_G, "writeclipboard"),
        rawget(_G, "set_clipboard"),
    }

    -- Some executors expose clipboard helpers as direct globals rather than _G fields.
    pcall(function()
        candidates[#candidates + 1] = setclipboard
        candidates[#candidates + 1] = toclipboard
        candidates[#candidates + 1] = writeclipboard
        candidates[#candidates + 1] = set_clipboard
    end)

    for _, setter in ipairs(candidates) do
        if type(setter) == "function" then
            local ok = pcall(setter, value)
            if ok then return true end
        end
    end

    local synApi = syn
    if type(synApi) == "table" then
        local writer = synApi.write_clipboard or synApi.setclipboard
        if type(writer) == "function" then
            local ok = pcall(writer, value)
            if ok then return true end
        end
    end

    return false
end

local function normalizeKey(value)
    return tostring(value or ""):gsub("%s+", "")
end

local function responseStatus(response)
    return tonumber(response and (response.StatusCode or response.Status or response.status_code)) or 0
end

local function responseBody(response)
    return tostring(response and (response.Body or response.body) or "")
end

--// ============================================================
--// GUI ROOT
--// ============================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = GUI_NAME
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = CoreGui

local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 0.55
Overlay.BorderSizePixel = 0
Overlay.Active = true
Overlay.ZIndex = 1
Overlay.Parent = Gui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(560, 430)
Main.Position = UDim2.new(0.5, -280, 0.5, -215)
Main.BackgroundColor3 = Color3.fromRGB(11, 11, 14)
Main.BorderSizePixel = 0
Main.Active = true
Main.ZIndex = 2
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 20)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(58, 58, 68)
MainStroke.Thickness = 1.25
MainStroke.Transparency = 0.1
MainStroke.Parent = Main

local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(1, 80, 1, 80)
Shadow.Position = UDim2.new(0.5, 0, 0.5, 8)
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6014261993"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.38
Shadow.ZIndex = 1
Shadow.Parent = Main

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 70)
TopBar.BackgroundTransparency = 1
TopBar.Active = true
TopBar.ZIndex = 5
TopBar.Parent = Main

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -36, 0, 1)
Divider.Position = UDim2.fromOffset(18, 69)
Divider.BackgroundColor3 = Color3.fromRGB(43, 43, 51)
Divider.BorderSizePixel = 0
Divider.ZIndex = 5
Divider.Parent = Main

local LogoBG = Instance.new("Frame")
LogoBG.Size = UDim2.fromOffset(42, 42)
LogoBG.Position = UDim2.fromOffset(18, 14)
LogoBG.BackgroundColor3 = Color3.fromRGB(31, 31, 37)
LogoBG.BorderSizePixel = 0
LogoBG.ZIndex = 6
LogoBG.Parent = Main

local LogoBGCorner = Instance.new("UICorner")
LogoBGCorner.CornerRadius = UDim.new(0, 13)
LogoBGCorner.Parent = LogoBG

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.fromScale(1, 1)
Logo.BackgroundTransparency = 1
Logo.Font = Enum.Font.GothamBlack
Logo.Text = "K"
Logo.TextSize = 25
Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
Logo.ZIndex = 7
Logo.Parent = LogoBG

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -160, 0, 25)
Title.Position = UDim2.fromOffset(72, 13)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "UZEXHUB"
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(250, 250, 252)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 6
Title.Parent = Main

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -160, 0, 18)
Subtitle.Position = UDim2.fromOffset(72, 38)
Subtitle.BackgroundTransparency = 1
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "UZEXHUB AUTH  •  KEY VERIFICATION"
Subtitle.TextSize = 10
Subtitle.TextColor3 = Color3.fromRGB(124, 124, 136)
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 6
Subtitle.Parent = Main

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(32, 32)
Close.Position = UDim2.new(1, -48, 0, 17)
Close.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
Close.BorderSizePixel = 0
Close.AutoButtonColor = false
Close.Font = Enum.Font.GothamBold
Close.Text = "×"
Close.TextSize = 22
Close.TextColor3 = Color3.fromRGB(160, 160, 170)
Close.ZIndex = 7
Close.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 10)
CloseCorner.Parent = Close

local function makeLabel(parent, text, pos, size, font, textSize, color)
    local obj = Instance.new("TextLabel")
    obj.BackgroundTransparency = 1
    obj.Position = pos
    obj.Size = size
    obj.Font = font
    obj.Text = text
    obj.TextSize = textSize
    obj.TextColor3 = color
    obj.TextXAlignment = Enum.TextXAlignment.Left
    obj.ZIndex = 7
    obj.Parent = parent
    return obj
end

local KeyTitle = makeLabel(
    Main,
    "ACCESS KEY",
    UDim2.fromOffset(20, 86),
    UDim2.new(1, -40, 0, 20),
    Enum.Font.GothamBold,
    11,
    Color3.fromRGB(220, 220, 226)
)

local KeyHint = makeLabel(
    Main,
    "Paste your 136-character key below.",
    UDim2.fromOffset(20, 109),
    UDim2.new(1, -40, 0, 18),
    Enum.Font.Gotham,
    10,
    Color3.fromRGB(105, 105, 116)
)

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, -40, 0, 48)
KeyBox.Position = UDim2.fromOffset(20, 133)
KeyBox.BackgroundColor3 = Color3.fromRGB(18, 18, 23)
KeyBox.BorderSizePixel = 0
KeyBox.ClearTextOnFocus = false
KeyBox.Font = Enum.Font.Code
KeyBox.PlaceholderText = "Paste key here..."
KeyBox.PlaceholderColor3 = Color3.fromRGB(82, 82, 95)
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(240, 240, 246)
KeyBox.TextSize = 12
KeyBox.TextXAlignment = Enum.TextXAlignment.Left
KeyBox.ZIndex = 8
KeyBox.Parent = Main

local KeyPadding = Instance.new("UIPadding")
KeyPadding.PaddingLeft = UDim.new(0, 14)
KeyPadding.PaddingRight = UDim.new(0, 14)
KeyPadding.Parent = KeyBox

local KeyCorner = Instance.new("UICorner")
KeyCorner.CornerRadius = UDim.new(0, 11)
KeyCorner.Parent = KeyBox

local KeyStroke = Instance.new("UIStroke")
KeyStroke.Color = Color3.fromRGB(50, 50, 60)
KeyStroke.Thickness = 1
KeyStroke.Transparency = 0.15
KeyStroke.Parent = KeyBox

local GetKey = Instance.new("TextButton")
GetKey.Size = UDim2.new(0.5, -25, 0, 40)
GetKey.Position = UDim2.fromOffset(20, 196)
GetKey.BackgroundColor3 = Color3.fromRGB(27, 27, 33)
GetKey.BorderSizePixel = 0
GetKey.AutoButtonColor = false
GetKey.Font = Enum.Font.GothamBold
GetKey.Text = "GET KEY"
GetKey.TextSize = 10
GetKey.TextColor3 = Color3.fromRGB(232, 232, 238)
GetKey.ZIndex = 8
GetKey.Parent = Main

local GetKeyCorner = Instance.new("UICorner")
GetKeyCorner.CornerRadius = UDim.new(0, 10)
GetKeyCorner.Parent = GetKey

local GetKeyStroke = Instance.new("UIStroke")
GetKeyStroke.Color = Color3.fromRGB(52, 52, 62)
GetKeyStroke.Thickness = 1
GetKeyStroke.Parent = GetKey

local InfoTitle = makeLabel(
    Main,
    "SECURE LOADER",
    UDim2.fromOffset(20, 252),
    UDim2.new(1, -40, 0, 20),
    Enum.Font.GothamBold,
    11,
    Color3.fromRGB(220, 220, 226)
)

local InfoHint = makeLabel(
    Main,
    "GET KEY copies the current IZOKI website. VERIFY KEY checks your key and runs the embedded script.",
    UDim2.fromOffset(20, 273),
    UDim2.new(1, -40, 0, 30),
    Enum.Font.Gotham,
    10,
    Color3.fromRGB(105, 105, 116)
)
InfoHint.TextWrapped = true
InfoHint.TextYAlignment = Enum.TextYAlignment.Top

local Verify = Instance.new("TextButton")
Verify.Size = UDim2.new(0.5, -25, 0, 40)
Verify.Position = UDim2.new(0.5, 5, 0, 196)
Verify.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Verify.BorderSizePixel = 0
Verify.AutoButtonColor = false
Verify.Font = Enum.Font.GothamBold
Verify.Text = "VERIFY KEY"
Verify.TextSize = 11
Verify.TextColor3 = Color3.fromRGB(0, 0, 0)
Verify.ZIndex = 8
Verify.Parent = Main

local VerifyCorner = Instance.new("UICorner")
VerifyCorner.CornerRadius = UDim.new(0, 11)
VerifyCorner.Parent = Verify

local VerifyStroke = Instance.new("UIStroke")
VerifyStroke.Color = Color3.fromRGB(225, 225, 230)
VerifyStroke.Thickness = 1
VerifyStroke.Transparency = 0.1
VerifyStroke.Parent = Verify



local Status = makeLabel(
    Main,
    "● Waiting for key",
    UDim2.fromOffset(20, 320),
    UDim2.new(1, -40, 0, 20),
    Enum.Font.GothamMedium,
    10,
    Color3.fromRGB(118, 118, 130)
)

local Footer = makeLabel(
    Main,
    "UZEXHUB AUTH  •  izoki.bytecraft.workers.dev",
    UDim2.fromOffset(20, 0),
    UDim2.new(1, -40, 0, 18),
    Enum.Font.Gotham,
    9,
    Color3.fromRGB(68, 68, 78)
)
Footer.Position = UDim2.new(0, 20, 1, -20)
Footer.TextXAlignment = Enum.TextXAlignment.Right


--// ============================================================
--// Button feedback
--// ============================================================

local function hoverButton(button, normal, over)
    button.MouseEnter:Connect(function()
        tween(button, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = over
        })
    end)
    button.MouseLeave:Connect(function()
        tween(button, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = normal
        })
    end)
end

hoverButton(GetKey, Color3.fromRGB(27, 27, 33), Color3.fromRGB(41, 41, 49))
hoverButton(Verify, Color3.fromRGB(255, 255, 255), Color3.fromRGB(222, 222, 222))
hoverButton(Close, Color3.fromRGB(24, 24, 29), Color3.fromRGB(48, 48, 56))

--// ============================================================
--// Get Key
--// ============================================================

local GET_KEY_URL = "https://izoki.bytecraft.workers.dev/uzexhub"
local KEY_FILE_NAME = "KhfreshKeySystem/izoki_key.txt"

local function canUseFileApi()
    return type(isfile) == "function"
        and type(readfile) == "function"
        and type(writefile) == "function"
end

local function ensureFolder()
    local makefolderFn = rawget(_G, "makefolder")
    if type(makefolderFn) ~= "function" then
        makefolderFn = makefolder
    end
    if type(makefolderFn) ~= "function" then return end
    pcall(function()
        if type(isfolder) == "function" then
            if not isfolder("KhfreshKeySystem") then
                makefolderFn("KhfreshKeySystem")
            end
        else
            makefolderFn("KhfreshKeySystem")
        end
    end)
end

local function saveKey(key)
    if not canUseFileApi() then
        return false
    end
    key = normalizeKey(key)
    if key == "" then return false end
    ensureFolder()
    local ok = pcall(function()
        writefile(KEY_FILE_NAME, key)
    end)
    if not ok then return false end

    local verifyOk, saved = pcall(function()
        return readfile(KEY_FILE_NAME)
    end)
    return verifyOk and normalizeKey(saved) == key
end

local function loadSavedKey()
    if not canUseFileApi() then
        return nil
    end
    local exists = false
    pcall(function()
        exists = isfile(KEY_FILE_NAME)
    end)
    if not exists then return nil end

    local ok, value = pcall(function()
        return readfile(KEY_FILE_NAME)
    end)
    if not ok or value == nil then return nil end

    local key = normalizeKey(value)
    if key == "" then return nil end
    return key
end

local function deleteSavedKey()
    local deleter = rawget(_G, "delfile")
    if type(deleter) ~= "function" then return end
    pcall(function()
        if type(isfile) ~= "function" or isfile(KEY_FILE_NAME) then
            deleter(KEY_FILE_NAME)
        end
    end)
end

local function hideKeySystem()
    pcall(function()
        local closeTween = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(Main, closeTween, {Size = UDim2.fromOffset(0, 0)})
        tween(Overlay, closeTween, {BackgroundTransparency = 1})
    end)
    task.wait(0.23)
    pcall(function()
        if Gui and Gui.Parent then Gui:Destroy() end
    end)
end

GetKey.MouseButton1Click:Connect(function()
    local ok = setClipboard(GET_KEY_URL)
    if ok then
        Status.Text = "● Link copied successfully"
        Status.TextColor3 = Color3.fromRGB(112, 220, 148)
        GetKey.Text = "COPIED"
        task.delay(1.1, function()
            if GetKey and GetKey.Parent then
                GetKey.Text = "GET KEY"
            end
        end)
    else
        Status.Text = "● Clipboard unavailable"
        Status.TextColor3 = Color3.fromRGB(255, 171, 90)
        warn("[UZEXHUB] Copy failed. Copy manually: " .. GET_KEY_URL)
    end
end)


Close.MouseButton1Click:Connect(function()
    hideKeySystem()
end)

--// ============================================================
--// Drag using the top bar only
--// ============================================================

local dragging = false
local dragStart = nil
local startPos = nil

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart
    Main.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end)

--// ============================================================
--// Key verification + code execution
--// ============================================================

local verifying = false
local verified = false

--// ============================================================
--// EMBEDDED PAYLOAD
--// Paste the hub source at the very end of this file; it is executed after verification.
--// Do not paste the payload into the UI.
--// ============================================================
local executeEmbeddedScript

local function setBusy(state)
    verifying = state
    Verify.Active = not state
    GetKey.Active = not state
end

local function shakeKeyBox()
    local base = UDim2.fromOffset(20, 133)
    local sequence = {
        UDim2.fromOffset(26, 133),
        UDim2.fromOffset(14, 133),
        UDim2.fromOffset(24, 133),
        base
    }
    for _, pos in ipairs(sequence) do
        tween(KeyBox, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = pos
        })
        task.wait(0.06)
    end
end

local function verifyKey()
    if verifying then return end

    local key = normalizeKey(KeyBox.Text)
    if key == "" then
        Status.Text = "● Enter a key first"
        Status.TextColor3 = Color3.fromRGB(255, 171, 90)
        shakeKeyBox()
        return
    end

    local hwid = getStableHWID()
    if hwid == "" then
        Status.Text = "● Could not read executor HWID"
        Status.TextColor3 = Color3.fromRGB(255, 90, 90)
        return
    end

    setBusy(true)
    Verify.Text = "VERIFYING..."
    Status.Text = "● Checking key with IZOKI..."
    Status.TextColor3 = Color3.fromRGB(175, 175, 188)

    local verifyUrl = VERIFY_URL
        .. HttpService:UrlEncode(key)
        .. "&hwid="
        .. HttpService:UrlEncode(hwid)

    local requestOk, response = pcall(function()
        return requestGet(verifyUrl)
    end)

    if not requestOk or not response then
        setBusy(false)
        Verify.Text = "VERIFY KEY"
        Status.Text = "● Request failed"
        Status.TextColor3 = Color3.fromRGB(255, 90, 90)
        return
    end

    local statusCode = responseStatus(response)
    local body = responseBody(response)
    local valid = false
    local serverMessage = nil
    local serverCode = nil

    if type(statusCode) == "number" and statusCode >= 200 and statusCode < 500 then
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(body)
        end)

        if decodeOk and type(data) == "table" then
            valid = data.valid == true or data.success == true
            serverMessage = data.message
            serverCode = data.code
        end

        if not valid then
            valid = body:find('"valid"%s*:%s*true') ~= nil
                or body:find('"success"%s*:%s*true') ~= nil
        end
    end

    if not valid then
        setBusy(false)
        Verify.Text = "VERIFY KEY"

        if serverCode == "HWID_MISMATCH" then
            Status.Text = "● Key is bound to another device"
        elseif serverCode == "KEY_EXPIRED" then
            Status.Text = "● Key expired"
        elseif serverCode == "KEY_REVOKED" then
            Status.Text = "● Key revoked"
        elseif serverCode == "HWID_REQUIRED" then
            Status.Text = "● HWID is required"
        elseif serverCode == "INVALID_KEY" or serverCode == "INVALID_KEY_FORMAT" or serverCode == "KEY_NOT_FOUND" then
            Status.Text = "● Key not found, expired, or deleted"
        elseif statusCode == 429 then
            Status.Text = "● Too many verify requests; wait and retry"
        elseif statusCode >= 500 then
            Status.Text = "● IZOKI server error; try again later"
        else
            Status.Text = "● " .. tostring(serverMessage or "Invalid or expired key")
        end

        Status.TextColor3 = Color3.fromRGB(255, 90, 90)
        shakeKeyBox()
        return
    end

    verified = true
    local saved = saveKey(key)
    if not saved then
        warn("[UZEXHUB] Key verified, but persistent file storage is unavailable in this executor.")
    end
    Status.Text = "● Key verified successfully"
    Status.TextColor3 = Color3.fromRGB(112, 220, 148)
    Verify.Text = "ACCESS GRANTED"

    -- Hide the key UI as soon as the server approves the key.
    hideKeySystem()
    setBusy(false)

    task.spawn(function()
        executeEmbeddedScript()
    end)
end

Verify.MouseButton1Click:Connect(function()
    if verifying then return end
    verifyKey()
end)

--// ============================================================
--// Opening animation
--// ============================================================

Main.Size = UDim2.fromOffset(0, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Overlay.BackgroundTransparency = 1

tween(Overlay, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0.55
})

tween(Main, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Size = UDim2.fromOffset(560, 430),
    Position = UDim2.new(0.5, -280, 0.5, -215)
})

--// ============================================================================
--// AUTO LOGIN FROM SAVED KEY
--// ============================================================================
--// If a previously verified key exists, verify it silently and launch the
--// embedded source without making the user press VERIFY KEY again.

local function autoLoginSavedKey()
    local savedKey = loadSavedKey()
    if not savedKey then
        return
    end

    task.spawn(function()
        task.wait(0.18)

        local hwid = getStableHWID()
        if hwid == "" then
            Status.Text = "● Saved key found; HWID unavailable"
            Status.TextColor3 = Color3.fromRGB(255, 171, 90)
            return
        end

        setBusy(true)
        Verify.Text = "AUTO VERIFY..."
        Status.Text = "● Verifying saved key..."
        Status.TextColor3 = Color3.fromRGB(175, 175, 188)

        local verifyUrl = VERIFY_URL
            .. HttpService:UrlEncode(savedKey)
            .. "&hwid="
            .. HttpService:UrlEncode(hwid)

        local requestOk, response = pcall(function()
            return requestGet(verifyUrl)
        end)

        local statusCode = responseStatus(response)
        local body = responseBody(response)
        local valid = false
        local serverCode = nil
        local serverMessage = nil

        if requestOk and response and type(statusCode) == "number" and statusCode >= 200 and statusCode < 500 then
            local decodeOk, data = pcall(function()
                return HttpService:JSONDecode(body)
            end)
            if decodeOk and type(data) == "table" then
                valid = data.valid == true or data.success == true
                serverCode = data.code
                serverMessage = data.message
            end
            if not valid then
                valid = body:find('"valid"%s*:%s*true') ~= nil
                    or body:find('"success"%s*:%s*true') ~= nil
            end
        end

        if not valid then
            setBusy(false)
            deleteSavedKey()
            Verify.Text = "VERIFY KEY"
            if serverCode == "HWID_MISMATCH" then
                Status.Text = "● Saved key belongs to another device"
            elseif serverCode == "KEY_EXPIRED" then
                Status.Text = "● Saved key expired"
            elseif serverCode == "KEY_REVOKED" then
                Status.Text = "● Saved key revoked"
            elseif serverCode == "INVALID_KEY" or serverCode == "INVALID_KEY_FORMAT" or serverCode == "KEY_NOT_FOUND" then
                Status.Text = "● Saved key expired, deleted, or no longer exists"
            elseif statusCode == 429 then
                Status.Text = "● Too many verify requests; wait and retry"
            elseif statusCode >= 500 then
                Status.Text = "● IZOKI server error; try again later"
            else
                Status.Text = "● " .. tostring(serverMessage or "Saved key is invalid")
            end
            Status.TextColor3 = Color3.fromRGB(255, 90, 90)
            return
        end

        verified = true
        Status.Text = "● Saved key verified"
        Status.TextColor3 = Color3.fromRGB(112, 220, 148)
        Verify.Text = "ACCESS GRANTED"

        hideKeySystem()
        setBusy(false)

        task.spawn(function()
            executeEmbeddedScript()
        end)
    end)
end

--// ============================================================================
--// PASTE YOUR HUB SCRIPT BELOW THIS LINE
--// ============================================================================
--// KHONG CAN NGOAC LONG STRING; CHI PASTE NGUYEN VAN SOURCE.
--// Chi can paste NGUYEN VAN full hub source ngay ben duoi dong:
--//     --// >>> PASTE HUB SOURCE BELOW <<<
--//
--// Phan code duoc paste nam TRUC TIEP trong executeEmbeddedScript(),
--// nen no chi chay sau khi IZOKI verify thanh cong.
--// ============================================================================

executeEmbeddedScript = function()
    if not verified then
        return false
    end

    if not FREE_DAY_UTC then
        Status.Text = "● Key verified - loading script..."
        Status.TextColor3 = Color3.fromRGB(112, 220, 148)
        Verify.Text = "LOADING..."
    else
        Status.Text = "● FREE ACCESS • " .. CURRENT_UTC_DAY .. " UTC"
        Status.TextColor3 = Color3.fromRGB(112, 220, 148)
        Verify.Text = "FREE ACCESS"
    end

    local runOk, runErr = pcall(function()
        --// ================================================================
        --// >>> PASTE HUB SOURCE DIRECTLY BELOW THIS LINE <<<
        --// No string wrapper is needed around your pasted hub source.
        --// Paste the source exactly as it is.
        --// ================================================================

        -- PASTE YOUR FULL HUB SCRIPT HERE

        --// ================================================================
        --// >>> END OF HUB SOURCE <<<
        --// ================================================================
    end)

    if not runOk then
        Status.Text = "● Embedded script runtime error"
        Status.TextColor3 = Color3.fromRGB(255, 90, 90)
        Verify.Text = "RETRY VERIFY"
        warn("[UZEXHUB] Embedded script runtime error:", runErr)
        return false
    end

    Status.Text = "● Script loaded successfully"
    Status.TextColor3 = Color3.fromRGB(112, 220, 148)
    Verify.Text = "ACCESS GRANTED"

    if FREE_DAY_UTC then
        task.delay(0.08, function()
            hideKeySystem()
        end)
    end

    return true
end

--// ============================================================================
--// UTC FREE DAYS
--// Thursday / Friday UTC only: launch directly, no key required.
--// Sunday / Monday / Tuesday / Wednesday UTC: normal key verification.
--// ============================================================================
if FREE_DAY_UTC then
    verified = true
    Status.Text = "● FREE DAY • " .. CURRENT_UTC_DAY .. " UTC"
    Status.TextColor3 = Color3.fromRGB(112, 220, 148)
    Verify.Text = "FREE ACCESS"

    task.delay(0.05, function()
        local ok, err = pcall(function()
            executeEmbeddedScript()
        end)

        if not ok then
            warn("[UZEXHUB] Free-day launch failed:", err)
        end
    end)
else
    -- Normal days: key is required. Saved key can still auto-login.
    Status.Text = "● " .. CURRENT_UTC_DAY .. " UTC • KEY REQUIRED"
    Status.TextColor3 = Color3.fromRGB(118, 118, 130)
    autoLoginSavedKey()
end

return Gui
