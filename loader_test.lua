-- language: Lua, file: NNVN_UI.lua, target: Roblox / Heavyweight Fishing
-- Companion UI panel for NNVN Hub — exec AFTER the main script loads.
-- Controls all getgenv() flags via smooth toggle panel.
-- No external libraries required.

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local UIS           = game:GetService("UserInputService")
local LP            = Players.LocalPlayer

-- ─── destroy any old instance ──────────────────────────────
local PGui = LP:WaitForChild("PlayerGui")
local existing = PGui:FindFirstChild("NNVN_CustomUI")
if existing then existing:Destroy() end

-- ─── palette ───────────────────────────────────────────────
local C = {
    bg       = Color3.fromRGB(11, 11, 17),
    surface  = Color3.fromRGB(18, 18, 28),
    surface2 = Color3.fromRGB(24, 24, 38),
    accent   = Color3.fromRGB(0, 230, 160),
    accentDim= Color3.fromRGB(0, 80, 56),
    off      = Color3.fromRGB(44, 44, 64),
    text     = Color3.fromRGB(220, 220, 240),
    textDim  = Color3.fromRGB(100, 100, 130),
    danger   = Color3.fromRGB(220, 60, 80),
}

-- ─── tween presets ─────────────────────────────────────────
local TF = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TM = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TB = TweenInfo.new(0.5,  Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ─── root gui ──────────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name              = "NNVN_CustomUI"
SG.ResetOnSpawn      = false
SG.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset    = true
SG.Parent            = PGui

-- ─── main window ───────────────────────────────────────────
local WIN = Instance.new("Frame")
WIN.Name                = "Window"
WIN.Size                = UDim2.new(0, 420, 0, 490)
WIN.Position            = UDim2.new(0.5, -210, 0.5, -245)
WIN.BackgroundColor3    = C.bg
WIN.BorderSizePixel     = 0
WIN.ClipsDescendants    = true
WIN.Parent              = SG

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = parent
    return c
end
local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or C.accent
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

corner(WIN, 12)
stroke(WIN, Color3.fromRGB(0, 60, 42), 1)

-- ─── title bar ─────────────────────────────────────────────
local TITLE = Instance.new("Frame")
TITLE.Size               = UDim2.new(1, 0, 0, 46)
TITLE.BackgroundColor3   = C.surface
TITLE.BorderSizePixel    = 0
TITLE.Parent             = WIN
corner(TITLE, 12)

-- patch bottom radius
local titlePatch = Instance.new("Frame")
titlePatch.Size             = UDim2.new(1, 0, 0, 12)
titlePatch.Position         = UDim2.new(0, 0, 1, -12)
titlePatch.BackgroundColor3 = C.surface
titlePatch.BorderSizePixel  = 0
titlePatch.Parent           = TITLE

-- icon + title
local titleIcon = Instance.new("TextLabel")
titleIcon.Size               = UDim2.new(0, 28, 0, 28)
titleIcon.Position           = UDim2.new(0, 10, 0.5, -14)
titleIcon.BackgroundColor3   = C.accentDim
titleIcon.Text               = "🎣"
titleIcon.Font               = Enum.Font.GothamBold
titleIcon.TextSize           = 15
titleIcon.TextColor3         = C.accent
titleIcon.TextXAlignment     = Enum.TextXAlignment.Center
titleIcon.Parent             = TITLE
corner(titleIcon, 7)

local titleText = Instance.new("TextLabel")
titleText.Size               = UDim2.new(0, 180, 1, 0)
titleText.Position           = UDim2.new(0, 46, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text               = "NNVN Fishing Hub"
titleText.Font               = Enum.Font.GothamBold
titleText.TextSize           = 14
titleText.TextColor3         = C.text
titleText.TextXAlignment     = Enum.TextXAlignment.Left
titleText.Parent             = TITLE

local vBadge = Instance.new("TextLabel")
vBadge.Size                 = UDim2.new(0, 46, 0, 18)
vBadge.Position             = UDim2.new(0, 228, 0.5, -9)
vBadge.BackgroundColor3     = C.accent
vBadge.Text                 = "v4.6.7"
vBadge.Font                 = Enum.Font.GothamBold
vBadge.TextSize             = 10
vBadge.TextColor3           = Color3.fromRGB(0, 20, 14)
vBadge.Parent               = TITLE
corner(vBadge, 9)

-- minimize / close
local function mkCtrlBtn(icon, bgColor, xPos)
    local b = Instance.new("TextButton")
    b.Size               = UDim2.new(0, 26, 0, 26)
    b.Position           = UDim2.new(1, xPos, 0.5, -13)
    b.BackgroundColor3   = bgColor
    b.Text               = icon
    b.Font               = Enum.Font.GothamBold
    b.TextSize           = 14
    b.TextColor3         = Color3.fromRGB(220, 220, 240)
    b.BorderSizePixel    = 0
    b.AutoButtonColor    = false
    b.Parent             = TITLE
    corner(b, 13)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TF, {BackgroundColor3 = bgColor:Lerp(Color3.new(1,1,1), 0.15)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TF, {BackgroundColor3 = bgColor}):Play()
    end)
    return b
end

local BtnMin   = mkCtrlBtn("−", Color3.fromRGB(50, 50, 72), -62)
local BtnClose = mkCtrlBtn("×", C.danger,                   -30)

-- ─── tab bar ───────────────────────────────────────────────
local TABS_BAR = Instance.new("Frame")
TABS_BAR.Size               = UDim2.new(1, 0, 0, 38)
TABS_BAR.Position           = UDim2.new(0, 0, 0, 46)
TABS_BAR.BackgroundColor3   = C.surface
TABS_BAR.BorderSizePixel    = 0
TABS_BAR.Parent             = WIN

local tabPatch = Instance.new("Frame")
tabPatch.Size               = UDim2.new(1, 0, 0, 10)
tabPatch.Position           = UDim2.new(0, 0, 1, -10)
tabPatch.BackgroundColor3   = C.surface
tabPatch.BorderSizePixel    = 0
tabPatch.Parent             = TABS_BAR

local tabRowLayout = Instance.new("UIListLayout")
tabRowLayout.FillDirection  = Enum.FillDirection.Horizontal
tabRowLayout.SortOrder      = Enum.SortOrder.LayoutOrder
tabRowLayout.Padding        = UDim.new(0, 4)
tabRowLayout.Parent         = TABS_BAR

local tabRowPad = Instance.new("UIPadding")
tabRowPad.PaddingLeft       = UDim.new(0, 10)
tabRowPad.PaddingTop        = UDim.new(0, 7)
tabRowPad.Parent            = TABS_BAR

-- ─── content area ──────────────────────────────────────────
local CONTENT = Instance.new("Frame")
CONTENT.Size                = UDim2.new(1, 0, 1, -84)
CONTENT.Position            = UDim2.new(0, 0, 0, 84)
CONTENT.BackgroundTransparency = 1
CONTENT.ClipsDescendants    = true
CONTENT.Parent              = WIN

-- ─── tab + content builder ─────────────────────────────────
local tabRegistry   = {}
local activeTabName = nil

local function createTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(0, 84, 0, 26)
    btn.BackgroundColor3    = C.surface2
    btn.Text                = icon .. "  " .. name
    btn.Font                = Enum.Font.Gotham
    btn.TextSize            = 11
    btn.TextColor3          = C.textDim
    btn.BorderSizePixel     = 0
    btn.AutoButtonColor     = false
    btn.LayoutOrder         = order
    btn.Parent              = TABS_BAR
    corner(btn, 7)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                  = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel       = 0
    scroll.ScrollBarThickness    = 3
    scroll.ScrollBarImageColor3  = C.accent
    scroll.ScrollBarImageTransparency = 0.3
    scroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
    scroll.Visible               = false
    scroll.Parent                = CONTENT

    local layout = Instance.new("UIListLayout")
    layout.SortOrder   = Enum.SortOrder.LayoutOrder
    layout.Padding     = UDim.new(0, 6)
    layout.Parent      = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft    = UDim.new(0, 12)
    pad.PaddingRight   = UDim.new(0, 12)
    pad.PaddingTop     = UDim.new(0, 10)
    pad.PaddingBottom  = UDim.new(0, 14)
    pad.Parent         = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 24)
    end)

    tabRegistry[name] = { btn = btn, scroll = scroll }
    return scroll
end

local function selectTab(name)
    for n, t in pairs(tabRegistry) do
        if n == name then
            TweenService:Create(t.btn, TF, {
                BackgroundColor3 = C.accentDim,
                TextColor3       = C.accent,
            }):Play()
            t.scroll.Visible = true
        else
            TweenService:Create(t.btn, TF, {
                BackgroundColor3 = C.surface2,
                TextColor3       = C.textDim,
            }):Play()
            t.scroll.Visible = false
        end
    end
    activeTabName = name
end

-- ─── widget helpers ────────────────────────────────────────

local function mkSection(parent, text, order)
    local row = Instance.new("Frame")
    row.Size                = UDim2.new(1, 0, 0, 20)
    row.BackgroundTransparency = 1
    row.LayoutOrder         = order
    row.Parent              = parent

    local line = Instance.new("Frame")
    line.Size               = UDim2.new(0.3, 0, 0, 1)
    line.Position           = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3   = C.accentDim
    line.BorderSizePixel    = 0
    line.Parent             = row

    local lbl = Instance.new("TextLabel")
    lbl.Size                = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                = text:upper()
    lbl.Font                = Enum.Font.GothamBold
    lbl.TextSize            = 10
    lbl.TextColor3          = C.accent
    lbl.TextXAlignment      = Enum.TextXAlignment.Left
    lbl.Parent              = row
    return row
end

local function mkToggle(parent, label, flagName, order)
    local row = Instance.new("Frame")
    row.Size                = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3    = C.surface
    row.BorderSizePixel     = 0
    row.LayoutOrder         = order
    row.Parent              = parent
    corner(row, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size                = UDim2.new(1, -68, 1, 0)
    lbl.Position            = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                = label
    lbl.Font                = Enum.Font.Gotham
    lbl.TextSize            = 13
    lbl.TextColor3          = C.text
    lbl.TextXAlignment      = Enum.TextXAlignment.Left
    lbl.Parent              = row

    -- pill background
    local pill = Instance.new("Frame")
    pill.Size               = UDim2.new(0, 44, 0, 24)
    pill.Position           = UDim2.new(1, -58, 0.5, -12)
    pill.BackgroundColor3   = C.off
    pill.BorderSizePixel    = 0
    pill.Parent             = row
    corner(pill, 12)

    local knob = Instance.new("Frame")
    knob.Size               = UDim2.new(0, 18, 0, 18)
    knob.Position           = UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3   = Color3.fromRGB(160, 160, 185)
    knob.BorderSizePixel    = 0
    knob.Parent             = pill
    corner(knob, 9)

    local hitbox = Instance.new("TextButton")
    hitbox.Size             = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text             = ""
    hitbox.Parent           = row

    local state = getgenv()[flagName] == true

    local function setState(val)
        state = val
        getgenv()[flagName] = val
        if val then
            TweenService:Create(pill,  TF, { BackgroundColor3 = C.accent }):Play()
            TweenService:Create(knob,  TF, {
                Position         = UDim2.new(1, -21, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            }):Play()
            TweenService:Create(lbl, TF, { TextColor3 = C.text }):Play()
        else
            TweenService:Create(pill,  TF, { BackgroundColor3 = C.off }):Play()
            TweenService:Create(knob,  TF, {
                Position         = UDim2.new(0, 3, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(160, 160, 185),
            }):Play()
            TweenService:Create(lbl, TF, { TextColor3 = C.textDim }):Play()
        end
    end

    setState(state)
    hitbox.MouseButton1Click:Connect(function() setState(not state) end)
    return row, setState
end

local function mkInput(parent, label, flagName, placeholder, order)
    local row = Instance.new("Frame")
    row.Size                = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3    = C.surface
    row.BorderSizePixel     = 0
    row.LayoutOrder         = order
    row.Parent              = parent
    corner(row, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size                = UDim2.new(0.52, 0, 1, 0)
    lbl.Position            = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                = label
    lbl.Font                = Enum.Font.Gotham
    lbl.TextSize            = 13
    lbl.TextColor3          = C.textDim
    lbl.TextXAlignment      = Enum.TextXAlignment.Left
    lbl.Parent              = row

    local inputBox = Instance.new("Frame")
    inputBox.Size           = UDim2.new(0, 118, 0, 28)
    inputBox.Position       = UDim2.new(1, -130, 0.5, -14)
    inputBox.BackgroundColor3 = C.surface2
    inputBox.BorderSizePixel = 0
    inputBox.Parent         = row
    corner(inputBox, 7)
    stroke(inputBox, C.off, 1)

    local tb = Instance.new("TextBox")
    tb.Size                 = UDim2.new(1, -10, 1, 0)
    tb.Position             = UDim2.new(0, 6, 0, 0)
    tb.BackgroundTransparency = 1
    tb.Text                 = tostring(getgenv()[flagName] or "")
    tb.PlaceholderText      = placeholder or ""
    tb.Font                 = Enum.Font.Gotham
    tb.TextSize             = 12
    tb.TextColor3           = C.accent
    tb.PlaceholderColor3    = C.off
    tb.ClearTextOnFocus     = false
    tb.Parent               = inputBox

    tb.Focused:Connect(function()
        TweenService:Create(inputBox, TF, { BackgroundColor3 = C.accentDim }):Play()
    end)
    tb.FocusLost:Connect(function()
        TweenService:Create(inputBox, TF, { BackgroundColor3 = C.surface2 }):Play()
        getgenv()[flagName] = tb.Text
    end)
    return row
end

local function mkButton(parent, label, callback, accent, order)
    local bg = accent or C.accentDim
    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3    = bg
    btn.BorderSizePixel     = 0
    btn.Text                = label
    btn.Font                = Enum.Font.GothamBold
    btn.TextSize            = 13
    btn.TextColor3          = C.accent
    btn.AutoButtonColor     = false
    btn.LayoutOrder         = order
    btn.Parent              = parent
    corner(btn, 8)

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TF, { BackgroundColor3 = bg:Lerp(C.accent, 0.3) }):Play()
        task.delay(0.18, function()
            TweenService:Create(btn, TF, { BackgroundColor3 = bg }):Play()
        end)
        if callback then pcall(callback) end
    end)
    return btn
end

local function mkSpacer(parent, h, order)
    local s = Instance.new("Frame")
    s.Size                  = UDim2.new(1, 0, 0, h or 4)
    s.BackgroundTransparency = 1
    s.LayoutOrder           = order
    s.Parent                = parent
end

-- ─── build tab: Fishing ────────────────────────────────────
local fTab = createTab("Fishing", "🎣", 1)

mkSection(fTab, "ESP",          1)
mkToggle (fTab, "Skills ESP",   "NNVN_SkillsESP", 2)
mkSpacer (fTab, 2, 3)

mkSection(fTab, "Auto Equip",   4)
mkToggle (fTab, "Best Bait",    "NNVN_AutoEquipBestBait", 5)
mkToggle (fTab, "Best Orb",     "NNVN_AutoEquipBestOrb",  6)
mkSpacer (fTab, 2, 7)

mkSection(fTab, "Auto Buy",     8)
mkToggle (fTab, "Auto Buy Bait","NNVN_AutoBuyBait",        9)
mkInput  (fTab, "Bait Name",    "NNVN_SelectedBait",   "Basic Bait", 10)
mkInput  (fTab, "Quantity",     "NNVN_BaitQuantity",   "1",          11)
mkInput  (fTab, "Buy Delay (s)","NNVN_AutoBuyBaitDelay","3",         12)

-- ─── build tab: Player ─────────────────────────────────────
local pTab = createTab("Player", "👤", 2)

mkSection(pTab, "Movement",     1)
mkToggle (pTab, "Infinite Jump","NNVN_InfiniteJump",  2)
mkToggle (pTab, "Fly Mode",     "NNVN_FlyMode",       3)
mkToggle (pTab, "NoClip",       "NNVN_NoClip",        4)
mkSpacer (pTab, 2, 5)

mkSection(pTab, "Visual",       6)
mkToggle (pTab, "Fullbright",   "NNVN_FullBright",    7)
mkSpacer (pTab, 2, 8)

mkSection(pTab, "Actions",      9)
mkInput  (pTab, "Backflip Dist","NNVN_BackflipDistance","8",        10)
mkButton (pTab, "▶  Do Backflip", function()
    if type(getgenv().NNVN_DoBackflip) == "function" then
        getgenv().NNVN_DoBackflip()
    end
end, nil, 11)

-- ─── build tab: Server ─────────────────────────────────────
local sTab = createTab("Server", "🌐", 3)

mkSection(sTab, "Server Hop",   1)
mkToggle (sTab, "Auto Hop",     "NNVN_AllowAutomaticServerHop", 2)
mkToggle (sTab, "Hop Fight Enzo","NNVN_AutoHopFightEnzo",        3)
mkInput  (sTab, "Grace (s)",    "NNVN_HopGraceSeconds", "20",    4)
mkSpacer (sTab, 2, 5)

mkSection(sTab, "Rejoin",       6)
mkToggle (sTab, "Auto Rejoin",  "NNVN_AutoRejoin",   7)
mkSpacer (sTab, 2, 8)

mkSection(sTab, "Premium",      9)
mkToggle (sTab, "Weather",      "NNVN_PremiumWeatherEnabled",  10)
mkToggle (sTab, "Spirit",       "NNVN_PremiumSpiritEnabled",   11)
mkToggle (sTab, "Taoist",       "NNVN_PremiumTaoistEnabled",   12)
mkToggle (sTab, "Maoshan",      "NNVN_PremiumMaoshanEnabled",  13)

-- ─── build tab: Settings ───────────────────────────────────
local xTab = createTab("⚙", "⚙", 4)

mkSection(xTab, "General",      1)
mkToggle (xTab, "Notifications","NNVN_Notify", 2)
mkSpacer (xTab, 4, 3)

mkSection(xTab, "Discord",      4)
mkButton (xTab, "Copy Discord Link", function()
    if setclipboard then setclipboard("discord.gg/5JJAuHRUgJ") end
end, nil, 5)
mkSpacer (xTab, 2, 6)

mkSection(xTab, "Reload", 7)
mkButton (xTab, "🔄  Reload UI", function()
    task.wait(0.2)
    loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/example/nnvn/main/NNVN_UI.lua"
    , true))()
end, Color3.fromRGB(30, 30, 50), 8)

-- ─── wire tab buttons ──────────────────────────────────────
for name, t in pairs(tabRegistry) do
    t.btn.MouseButton1Click:Connect(function()
        selectTab(name)
    end)
end

selectTab("Fishing")

-- ─── drag logic ────────────────────────────────────────────
local dragging, dragInput, dragStart, startPos

TITLE.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging   = true
        dragStart  = input.Position
        startPos   = WIN.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TITLE.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local d = input.Position - dragStart
        WIN.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

-- ─── minimize / close ──────────────────────────────────────
local minimized  = false
local FULL_SIZE  = WIN.Size

BtnMin.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(WIN, TM, { Size = UDim2.new(0, 420, 0, 46) }):Play()
        BtnMin.Text = "+"
    else
        TweenService:Create(WIN, TM, { Size = FULL_SIZE }):Play()
        BtnMin.Text = "−"
    end
end)

BtnClose.MouseButton1Click:Connect(function()
    TweenService:Create(WIN, TM, {
        Size     = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(
            WIN.Position.X.Scale,
            WIN.Position.X.Offset + 210,
            WIN.Position.Y.Scale,
            WIN.Position.Y.Offset + 245
        ),
    }):Play()
    task.delay(0.35, function() SG:Destroy() end)
end)

-- ─── open animation ────────────────────────────────────────
local finalPos = WIN.Position
WIN.Size       = UDim2.new(0, 0, 0, 0)
WIN.Position   = UDim2.new(
    finalPos.X.Scale, finalPos.X.Offset + 210,
    finalPos.Y.Scale, finalPos.Y.Offset + 245
)
TweenService:Create(WIN, TB, { Size = FULL_SIZE, Position = finalPos }):Play()
