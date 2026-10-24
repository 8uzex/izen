local ProtectionConfig = {
    SecretKey = "2009",
    
    -- The name of your Hub (shown in the kick message if they try to bypass)
    HubName = "Uzex Hub"
}

-------------------------------------------------------------------------------
-- 👇 YOUR MAIN SCRIPT CODE STARTS HERE 👇
-------------------------------------------------------------------------------

print(ProtectionConfig.HubName .. " Loaded Successfully!")

local Library = (function()
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local StatsService = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

local Library = {}

Library.Flags = {}
Library.Windows = {}

local function normalize(source, map)
    local opts = {}
    if type(source) == "string" then
        opts.Name = source
    elseif type(source) == "table" then
        for key, value in pairs(source) do
            opts[key] = value
        end
    end
    for from, to in pairs(map or {}) do
        if opts[to] == nil and opts[from] ~= nil then
            opts[to] = opts[from]
        end
    end
    if opts.Range then
        opts.Min = opts.Min or opts.Range[1]
        opts.Max = opts.Max or opts.Range[2]
    end
    return opts
end

local function finishElement(tab, opts, element, frame, kind)
    element._type = kind
    element._frame = frame
    element._listeners = element._listeners or {}
    local window = tab and tab.Window
    local searchText = opts.Name or opts.Text or opts.Title
    element._searchName = type(searchText) == "string" and searchText or ""
    element._searchKey = string.lower(element._searchName)
    if tab and tab._items then
        table.insert(tab._items, element)
    end
    if opts.Flag then
        Library.Flags[opts.Flag] = element
        if window then
            window:_flagCreated(opts.Flag, element)
        end
    end
    element._userVisible = opts.Visible ~= false
    function element:IsVisible()
        return element._userVisible
    end
    function element:_isShown()
        return element._userVisible and not (tab and tab._userVisible == false)
    end
    function element:SetVisible(visible)
        visible = visible and true or false
        if visible == element._userVisible or element._destroyed then
            return
        end
        element._userVisible = visible
        if not visible then
            if element._onHide then
                element._onHide()
            end
            if element.Open and type(element.SetOpen) == "function" then
                element:SetOpen(false)
            end
        end
        if frame then
            frame.Visible = visible
        end
        if window then
            window._controlsDirty = true
        end
    end
    if frame and not element._userVisible then
        frame.Visible = false
    end
    -- Tooltip: a string, or { Title, Text, Icon }. nil, false or "" hides it.
    function element:SetTooltip(tip)
        element._tooltip = tip
        if frame and window and not element._tooltipBound then
            element._tooltipBound = true
            window:_attachTooltip(element, frame)
        end
    end
    function element:GetTooltip()
        return element._tooltip
    end
    if opts.Tooltip ~= nil and opts.Tooltip ~= false then
        element:SetTooltip(opts.Tooltip)
    end
    function element:Destroy()
        if element._destroyed then
            return
        end
        element._destroyed = true
        if window and window._tipOwner == element then
            window:_hideTooltip()
        end
        for _, disconnect in ipairs(element._listeners) do
            disconnect()
        end
        element._listeners = {}
        if tab and tab._items then
            local index = table.find(tab._items, element)
            if index then
                table.remove(tab._items, index)
            end
        end
        if opts.Flag and Library.Flags[opts.Flag] == element then
            Library.Flags[opts.Flag] = nil
        end
        if window then
            window._controlsDirty = true
        end
        if frame then
            frame:Destroy()
        end
    end
    return element
end

Library.Theme = {
    Background = Color3.fromRGB(15, 18, 26),
    Surface = Color3.fromRGB(18, 22, 31),
    Surface2 = Color3.fromRGB(22, 26, 37),
    Surface3 = Color3.fromRGB(37, 44, 60),
    Stroke = Color3.fromRGB(34, 40, 55),
    StrokeHover = Color3.fromRGB(70, 84, 112),
    Accent = Color3.fromRGB(128, 160, 246),
    AccentDark = Color3.fromRGB(14, 18, 30),
    Text = Color3.fromRGB(228, 232, 242),
    Muted = Color3.fromRGB(116, 126, 148),
    Warning = Color3.fromRGB(240, 176, 108),
    Success = Color3.fromRGB(150, 220, 170),
    Error = Color3.fromRGB(240, 120, 120),
}

-- Order decides which key wins when two theme colors are identical.
local THEME_KEYS = {
    "Accent", "AccentDark", "Background", "Surface", "Surface2", "Surface3",
    "Stroke", "StrokeHover", "Text", "Muted", "Warning", "Success", "Error",
}

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local function preset(background, surface, surface2, surface3, strokeColor, strokeHover, accent, accentDark, text, muted)
    return {
        Background = rgb(table.unpack(background)),
        Surface = rgb(table.unpack(surface)),
        Surface2 = rgb(table.unpack(surface2)),
        Surface3 = rgb(table.unpack(surface3)),
        Stroke = rgb(table.unpack(strokeColor)),
        StrokeHover = rgb(table.unpack(strokeHover)),
        Accent = rgb(table.unpack(accent)),
        AccentDark = rgb(table.unpack(accentDark)),
        Text = rgb(table.unpack(text)),
        Muted = rgb(table.unpack(muted)),
    }
end

Library.ThemePresets = {
    -- Taichi: pure black-and-white (yin-yang). Greys avoid exact 0/255 so nothing gets bound to the theme by accident.
    Taichi = preset({ 8, 8, 8 }, { 14, 14, 14 }, { 22, 22, 22 }, { 40, 40, 40 }, { 58, 58, 58 }, { 150, 150, 150 }, { 244, 244, 244 }, { 10, 10, 10 }, { 240, 240, 240 }, { 140, 140, 140 }),
    -- izen: near-black surfaces with a clean neon-green accent.
    izen = preset({ 3, 10, 6 }, { 5, 15, 9 }, { 8, 22, 13 }, { 14, 40, 23 }, { 18, 61, 33 }, { 52, 145, 78 }, { 0, 255, 112 }, { 3, 28, 15 }, { 229, 255, 237 }, { 116, 163, 131 }),
    -- Colours here must not be pure white, pure black or any other colour the
    -- library hard-codes, or those objects would get bound to the theme.
    Midnight = preset({ 15, 18, 26 }, { 18, 22, 31 }, { 22, 26, 37 }, { 37, 44, 60 }, { 34, 40, 55 }, { 70, 84, 112 }, { 128, 160, 246 }, { 14, 18, 30 }, { 228, 232, 242 }, { 116, 126, 148 }),
    Ocean = preset({ 12, 20, 24 }, { 15, 24, 29 }, { 18, 29, 35 }, { 31, 48, 56 }, { 29, 44, 52 }, { 58, 92, 104 }, { 110, 214, 222 }, { 10, 24, 28 }, { 226, 238, 240 }, { 108, 134, 140 }),
    Rose = preset({ 22, 15, 18 }, { 27, 18, 22 }, { 32, 21, 26 }, { 48, 34, 40 }, { 45, 30, 37 }, { 98, 64, 78 }, { 246, 160, 186 }, { 30, 14, 20 }, { 240, 228, 232 }, { 138, 112, 120 }),
    Emerald = preset({ 13, 20, 17 }, { 16, 24, 20 }, { 20, 29, 24 }, { 33, 47, 40 }, { 30, 44, 37 }, { 62, 96, 78 }, { 132, 226, 170 }, { 12, 26, 18 }, { 228, 240, 233 }, { 110, 136, 122 }),
    Amber = preset({ 22, 18, 13 }, { 27, 22, 16 }, { 32, 26, 19 }, { 49, 41, 31 }, { 46, 38, 28 }, { 100, 82, 58 }, { 246, 196, 120 }, { 30, 22, 10 }, { 242, 236, 226 }, { 140, 126, 106 }),
    Mono = preset({ 16, 16, 17 }, { 20, 20, 21 }, { 25, 25, 26 }, { 40, 40, 42 }, { 38, 38, 40 }, { 84, 84, 88 }, { 236, 236, 240 }, { 20, 20, 22 }, { 234, 234, 236 }, { 122, 122, 128 }),
    Nebula = preset({ 14, 12, 28 }, { 18, 15, 35 }, { 23, 19, 43 }, { 39, 32, 68 }, { 35, 29, 62 }, { 84, 68, 140 }, { 199, 125, 255 }, { 22, 10, 40 }, { 236, 230, 252 }, { 124, 114, 160 }),
    Synthwave = preset({ 20, 12, 30 }, { 25, 15, 37 }, { 31, 18, 45 }, { 52, 30, 72 }, { 47, 27, 66 }, { 110, 58, 150 }, { 255, 94, 198 }, { 38, 8, 30 }, { 250, 232, 246 }, { 150, 118, 160 }),
    Sakura = preset({ 24, 14, 20 }, { 29, 17, 24 }, { 35, 20, 29 }, { 54, 32, 45 }, { 50, 29, 41 }, { 112, 66, 92 }, { 255, 158, 200 }, { 36, 12, 24 }, { 248, 232, 240 }, { 150, 112, 132 }),
    Velvet = preset({ 20, 10, 16 }, { 25, 12, 20 }, { 31, 15, 25 }, { 50, 25, 40 }, { 46, 23, 37 }, { 104, 52, 82 }, { 222, 110, 170 }, { 30, 8, 20 }, { 244, 228, 238 }, { 142, 106, 126 }),
    Crimson = preset({ 18, 10, 12 }, { 23, 12, 15 }, { 28, 14, 18 }, { 46, 24, 29 }, { 42, 22, 27 }, { 104, 46, 56 }, { 244, 74, 94 }, { 32, 8, 12 }, { 244, 230, 232 }, { 142, 106, 112 }),
    Sunset = preset({ 22, 13, 14 }, { 27, 16, 17 }, { 33, 19, 21 }, { 52, 31, 32 }, { 48, 28, 30 }, { 112, 62, 58 }, { 255, 138, 92 }, { 34, 14, 8 }, { 248, 234, 228 }, { 150, 118, 110 }),
    Gold = preset({ 14, 13, 11 }, { 18, 17, 14 }, { 23, 21, 17 }, { 38, 35, 28 }, { 35, 32, 26 }, { 92, 80, 54 }, { 232, 196, 122 }, { 30, 22, 8 }, { 240, 234, 222 }, { 136, 126, 106 }),
    Cyber = preset({ 13, 13, 15 }, { 17, 17, 19 }, { 21, 21, 24 }, { 36, 36, 40 }, { 33, 33, 37 }, { 86, 84, 70 }, { 250, 226, 72 }, { 30, 26, 4 }, { 240, 240, 232 }, { 126, 124, 118 }),
    Toxic = preset({ 11, 14, 11 }, { 14, 18, 14 }, { 18, 23, 18 }, { 31, 39, 30 }, { 28, 36, 28 }, { 74, 98, 60 }, { 184, 255, 74 }, { 18, 30, 6 }, { 232, 242, 228 }, { 116, 134, 110 }),
    Matcha = preset({ 16, 19, 14 }, { 20, 23, 17 }, { 24, 28, 21 }, { 40, 46, 34 }, { 37, 42, 31 }, { 84, 98, 70 }, { 176, 214, 140 }, { 18, 26, 10 }, { 236, 240, 228 }, { 128, 136, 116 }),
    Aurora = preset({ 10, 20, 22 }, { 12, 25, 27 }, { 15, 30, 33 }, { 26, 50, 53 }, { 24, 45, 48 }, { 50, 104, 104 }, { 94, 240, 180 }, { 6, 30, 22 }, { 224, 246, 240 }, { 102, 142, 134 }),
    Frost = preset({ 13, 17, 23 }, { 16, 21, 28 }, { 20, 26, 34 }, { 34, 43, 56 }, { 31, 40, 52 }, { 72, 92, 118 }, { 164, 214, 255 }, { 12, 22, 34 }, { 230, 238, 246 }, { 114, 128, 146 }),
    Abyss = preset({ 7, 11, 22 }, { 9, 14, 28 }, { 12, 18, 35 }, { 22, 31, 58 }, { 20, 28, 52 }, { 44, 64, 120 }, { 72, 148, 255 }, { 6, 14, 34 }, { 226, 234, 250 }, { 100, 116, 152 }),
    -- Seasonal and themed palettes.
    Halloween = preset({ 18, 12, 20 }, { 23, 15, 25 }, { 28, 18, 30 }, { 46, 30, 48 }, { 43, 28, 44 }, { 104, 62, 40 }, { 255, 138, 36 }, { 36, 16, 4 }, { 246, 234, 224 }, { 146, 120, 128 }),
    Haunted = preset({ 14, 12, 20 }, { 18, 15, 26 }, { 22, 18, 32 }, { 38, 31, 54 }, { 35, 29, 50 }, { 70, 96, 64 }, { 156, 255, 110 }, { 14, 30, 8 }, { 232, 240, 228 }, { 120, 116, 140 }),
    Christmas = preset({ 12, 20, 15 }, { 15, 25, 19 }, { 19, 30, 23 }, { 32, 50, 38 }, { 30, 46, 35 }, { 100, 54, 56 }, { 236, 72, 80 }, { 34, 8, 10 }, { 240, 244, 236 }, { 120, 142, 128 }),
    Valentine = preset({ 24, 12, 17 }, { 30, 14, 21 }, { 36, 17, 25 }, { 58, 27, 40 }, { 54, 25, 37 }, { 130, 56, 84 }, { 255, 92, 140 }, { 40, 8, 20 }, { 252, 232, 240 }, { 160, 112, 132 }),
    Lunar = preset({ 22, 10, 10 }, { 28, 12, 12 }, { 34, 15, 14 }, { 54, 24, 22 }, { 50, 22, 20 }, { 130, 92, 40 }, { 246, 196, 84 }, { 38, 16, 6 }, { 250, 236, 222 }, { 160, 120, 108 }),
    Tropical = preset({ 10, 22, 24 }, { 12, 27, 30 }, { 15, 33, 36 }, { 26, 54, 58 }, { 24, 50, 54 }, { 44, 110, 110 }, { 255, 170, 90 }, { 36, 18, 6 }, { 232, 246, 244 }, { 104, 144, 142 }),
    Dracula = preset({ 24, 25, 33 }, { 29, 30, 40 }, { 34, 36, 47 }, { 52, 55, 70 }, { 48, 50, 64 }, { 98, 114, 164 }, { 189, 147, 249 }, { 26, 18, 44 }, { 246, 246, 238 }, { 126, 132, 168 }),
    Coffee = preset({ 20, 16, 13 }, { 25, 20, 16 }, { 30, 24, 19 }, { 48, 39, 31 }, { 45, 36, 29 }, { 104, 82, 62 }, { 214, 170, 124 }, { 32, 22, 12 }, { 240, 230, 218 }, { 142, 124, 108 }),
}

Library.ThemeName = "Midnight"

Library.Assets = {
    Shadow = "rbxassetid://6014261993",
    Glow = "rbxassetid://8992230677",
    Logo = "rbxassetid://103859712365480",
}

local LUCIDE_URL = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"
local lucideSet = nil

local function loadLucide()
    if lucideSet ~= nil then
        return lucideSet
    end
    local ok, result = pcall(function()
        local source = game:HttpGet(LUCIDE_URL)
        return loadstring(source)()
    end)
    if ok and type(result) == "table" then
        lucideSet = result
    else
        lucideSet = false
        warn("[AirFlow] lucide icons unavailable: " .. tostring(result))
    end
    return lucideSet
end

local FONT_PRESETS = {
    ValleySans = {
        Regular = "https://raw.githubusercontent.com/HelsinkiTypeStudio/valley-sans/main/fonts/ttf/ValleySans-Regular.ttf",
        Medium = "https://raw.githubusercontent.com/HelsinkiTypeStudio/valley-sans/main/fonts/ttf/ValleySans-Medium.ttf",
        SemiBold = "https://raw.githubusercontent.com/HelsinkiTypeStudio/valley-sans/main/fonts/ttf/ValleySans-SemiBold.ttf",
    },
}

local FONT_WEIGHTS = {
    Regular = { 400, Enum.FontWeight.Regular },
    Medium = { 500, Enum.FontWeight.Medium },
    SemiBold = { 600, Enum.FontWeight.SemiBold },
    Bold = { 700, Enum.FontWeight.Bold },
}

function Library:LoadFont(opts)
    opts = normalize(opts, {})
    if type(writefile) ~= "function" or type(isfile) ~= "function" or typeof(getcustomasset) ~= "function" then
        warn("[AirFlow] custom fonts need writefile, isfile and getcustomasset")
        return false
    end
    local name = opts.Name or "CustomFont"
    local weights = opts.Weights or FONT_PRESETS[name]
    if type(weights) ~= "table" then
        warn("[AirFlow] no font weights for " .. name)
        return false
    end
    local folder = opts.Folder or "AirFlowFonts"
    pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(folder) then
            makefolder(folder)
        end
    end)
    local faces = {}
    for weightName, url in pairs(weights) do
        local info = FONT_WEIGHTS[weightName]
        if info then
            local path = folder .. "/" .. name .. "-" .. weightName .. ".ttf"
            local ok = true
            if not isfile(path) then
                ok = pcall(function()
                    writefile(path, game:HttpGet(url))
                end)
            end
            if ok then
                table.insert(faces, { name = weightName, weight = info[1], style = "normal", assetId = getcustomasset(path) })
            else
                warn("[AirFlow] could not download " .. weightName .. " weight of " .. name)
            end
        end
    end
    if #faces == 0 then
        return false
    end
    local familyPath = folder .. "/" .. name .. ".json"
    local okWrite = pcall(function()
        writefile(familyPath, HttpService:JSONEncode({ name = name, faces = faces }))
    end)
    if not okWrite then
        return false
    end
    local family = getcustomasset(familyPath)
    local function face(weightName, fallback)
        local info = FONT_WEIGHTS[weightName]
        if info and weights[weightName] then
            return Font.new(family, info[2])
        end
        return fallback
    end
    Library.Fonts.Regular = face("Regular", Library.Fonts.Regular)
    Library.Fonts.Medium = face("Medium", face("Regular", Library.Fonts.Medium))
    Library.Fonts.Bold = face("SemiBold", face("Bold", Library.Fonts.Bold))
    return true
end

function Library:PreloadIcons()
    return loadLucide() ~= false
end

-- Numbers, digit strings and asset URLs are custom images; anything else is
-- a lucide name.
local function assetId(value)
    if type(value) == "number" then
        return "rbxassetid://" .. string.format("%.0f", value)
    end
    if type(value) == "string" then
        if value:match("^%d+$") then
            return "rbxassetid://" .. value
        end
        if value:find("^rbxassetid://") or value:find("^rbxasset://") or value:find("^rbxthumb://") or value:find("^http") then
            return value
        end
    end
    return nil
end

-- Returns image, rect offset, rect size, whether it is a custom image, and
-- whether that custom image should still take the theme tint.
local function resolveIcon(icon)
    if typeof(icon) == "table" then
        return assetId(icon.Image) or icon.Image, icon.RectOffset, icon.RectSize, true, icon.Tint == true
    end
    local asset = assetId(icon)
    if asset then
        return asset, nil, nil, true, false
    end
    if type(icon) ~= "string" then
        return nil
    end
    local name = icon:gsub("^lucide:", "")
    local set = loadLucide()
    if not set then
        return nil
    end
    local entry = (set.Icons and set.Icons[name]) or set[name]
    if type(entry) == "table" then
        local image = entry.Image
        if type(image) == "number" then
            image = "rbxassetid://" .. tostring(image)
        end
        local sheet = (set.Spritesheets and set.Spritesheets[tostring(image)]) or image
        return sheet, entry.ImageRectPosition, entry.ImageRectSize
    elseif type(entry) == "string" then
        return entry
    end
    warn("[AirFlow] unknown lucide icon: " .. name)
    return nil
end

local BUTTON_HINT_ICON = "chevron-right"

local FONT_FAMILY = "rbxasset://fonts/families/BuilderSans.json"
Library.Fonts = {
    Regular = Font.new(FONT_FAMILY, Enum.FontWeight.Regular),
    Medium = Font.new(FONT_FAMILY, Enum.FontWeight.Medium),
    Bold = Font.new(FONT_FAMILY, Enum.FontWeight.SemiBold),
}

local Theme = Library.Theme
local Assets = Library.Assets

-- The Uzex Hub mark supplied with this script, embedded as a PNG so it needs no Roblox upload.
-- It is written once as a local custom asset and keeps its original green artwork.
-- When local custom assets are unavailable, the library's normal fallback logo is used.
local EMBEDDED_LOGO = "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"

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
local Fonts = Library.Fonts

local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
Library.Touch = TOUCH

local SIDEBAR_WIDTH = 188
local HEADER_HEIGHT = 62
local TAB_TILE_HEIGHT = 34
local CARD_HEIGHT = TOUCH and 54 or 48
local CARD_HEIGHT_DESC = TOUCH and 70 or 64
local DROPDOWN_OPTION_HEIGHT = TOUCH and 40 or 34
local CHIP_HEIGHT = TOUCH and 34 or 28
local PROFILE_HEIGHT = 64
local SEARCH_WIDTH = 176
local STACK_BELOW = 440

-- Elements read their geometry from one of these. Cards stand alone on a tab,
-- rows sit flush inside a groupbox.
local METRICS = {
    Card = {
        Compact = false,
        Height = CARD_HEIGHT,
        DescHeight = CARD_HEIGHT_DESC,
        Chip = CHIP_HEIGHT,
        Option = DROPDOWN_OPTION_HEIGHT,
        TextSize = 14,
        DescSize = 13,
        TitleHeight = 18,
        DescGap = 20,
        DescLine = 17,
        Slider = CARD_HEIGHT_DESC,
    },
    Row = {
        Compact = true,
        Height = TOUCH and 40 or 32,
        DescHeight = TOUCH and 54 or 46,
        Chip = TOUCH and 30 or 24,
        Option = TOUCH and 34 or 28,
        TextSize = 13,
        DescSize = 12,
        TitleHeight = 16,
        DescGap = 17,
        DescLine = 15,
        Slider = TOUCH and 54 or 46,
    },
}

local tweenInfoCache = {}

-- Theme bindings: every instance property painted with a theme color is
-- remembered by theme key, so SetTheme can repaint the whole UI live.
-- Held strongly: an Instance's Lua handle can be collected while the Instance
-- still exists, which would silently drop it from a weak table. Destroyed
-- objects are pruned instead, once they have been parentless for two sweeps.
local themeBindings = {}
local themeHooks = {}
local themeLookup = {}
local orphanMarks = {}
local bindingCount = 0
local sweepAt = 4000

local function pruneTable(map, counted)
    for object in pairs(map) do
        if object.Parent == nil then
            if orphanMarks[object] then
                map[object] = nil
                orphanMarks[object] = nil
                if counted then
                    bindingCount -= 1
                end
            else
                orphanMarks[object] = true
            end
        else
            orphanMarks[object] = nil
        end
    end
end

local function sweepBindings()
    pruneTable(themeBindings, true)
    pruneTable(themeHooks, false)
    sweepAt = math.max(4000, bindingCount * 2)
end

local function colorKey(color)
    return math.floor(color.R * 255 + 0.5) .. "," .. math.floor(color.G * 255 + 0.5) .. "," .. math.floor(color.B * 255 + 0.5)
end

local function rebuildThemeLookup()
    table.clear(themeLookup)
    for index = #THEME_KEYS, 1, -1 do
        local name = THEME_KEYS[index]
        themeLookup[colorKey(Library.Theme[name])] = name
    end
end
rebuildThemeLookup()

local function bindColors(object, props)
    for property, value in pairs(props) do
        if typeof(value) == "Color3" then
            local name = themeLookup[colorKey(value)]
            local bound = themeBindings[object]
            if name then
                if not bound then
                    bound = {}
                    themeBindings[object] = bound
                    bindingCount += 1
                    if bindingCount >= sweepAt then
                        sweepBindings()
                    end
                end
                bound[property] = name
            elseif bound then
                bound[property] = nil
            end
        end
    end
end

-- Repaints every bound property from the colours on screen to the new theme.
-- One Heartbeat loop lerps each theme key once per frame and assigns the
-- result, instead of creating a tween per object, which hitched the frame the
-- theme changed on large UIs. A change mid-fade picks up from what is shown.
local shownTheme = table.clone(Library.Theme)
local themeDriver = nil

local function paintBinding(object, bound, colors)
    for property, name in pairs(bound) do
        local color = colors[name]
        if color then
            object[property] = color
        end
    end
end

local function paintBindings(colors)
    for object, bound in pairs(themeBindings) do
        pcall(paintBinding, object, bound, colors)
    end
end

local function driveTheme(duration)
    if themeDriver then
        themeDriver:Disconnect()
        themeDriver = nil
    end
    local from, colors = {}, {}
    for _, name in ipairs(THEME_KEYS) do
        local target = Library.Theme[name]
        local current = shownTheme[name] or target
        if current ~= target then
            from[name] = current
            colors[name] = current
        end
    end
    local function finish()
        for _, name in ipairs(THEME_KEYS) do
            colors[name] = Library.Theme[name]
            shownTheme[name] = Library.Theme[name]
        end
        paintBindings(colors)
    end
    if duration <= 0 or next(from) == nil then
        finish()
        return
    end
    local elapsed = 0
    themeDriver = RunService.Heartbeat:Connect(function(deltaTime)
        elapsed += deltaTime
        if elapsed >= duration then
            themeDriver:Disconnect()
            themeDriver = nil
            finish()
            return
        end
        local alpha = 1 - (1 - elapsed / duration) ^ 5
        for name, start in pairs(from) do
            local color = start:Lerp(Library.Theme[name], alpha)
            colors[name] = color
            shownTheme[name] = color
        end
        paintBindings(colors)
    end)
end

-- Runs fn now and again whenever the theme changes, while owner exists.
local function onTheme(owner, fn)
    themeHooks[owner] = fn
    fn()
end

local function tween(object, props, duration, style, direction, raw)
    duration = duration or 0.2
    if not raw then
        bindColors(object, props)
    end
    if duration <= 0 then
        for key, value in pairs(props) do
            object[key] = value
        end
        return nil
    end
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local key = duration .. style.Name .. direction.Name
    local info = tweenInfoCache[key]
    if not info then
        info = TweenInfo.new(duration, style, direction)
        tweenInfoCache[key] = info
    end
    local t = TweenService:Create(object, info, props)
    t:Play()
    return t
end

local function create(className, props, children)
    local inst = Instance.new(className)
    for key, value in pairs(props) do
        if key ~= "Parent" then
            inst[key] = value
        end
    end
    bindColors(inst, props)
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end

    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

-- Corners in pixels follow the player's corner radius setting: each one
-- remembers the radius it was drawn at, and Library:SetCornerRadius rescales
-- them all. Scale corners (pills, circles) stay as they are.
Library.Roundness = 1
-- A strong table: weak keys would drop the Lua handles for corners nothing
-- else in Lua holds, and those corners would never rescale. Destroyed ones
-- are pruned whenever the radius changes.
Library._cornerBases = {}

local function corner(parent, radius)
    radius = radius or UDim.new(0, 8)
    local object = create("UICorner", {
        CornerRadius = radius.Scale == 0 and UDim.new(0, math.floor(radius.Offset * Library.Roundness + 0.5)) or radius,
        Parent = parent,
    })
    if radius.Scale == 0 then
        Library._cornerBases[object] = radius.Offset
    end
    return object
end

-- A corner that ignores the setting, for shapes that animate their own
-- radius (the minimized island, the morph panels).
function Library._fixedCorner(parent, radius)
    return create("UICorner", { CornerRadius = radius, Parent = parent })
end

-- The radius the window's own corners are drawn at right now.
function Library._radius(pixels)
    return math.floor(pixels * Library.Roundness + 0.5)
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or Theme.Stroke,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function padding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        Parent = parent,
    })
end

local function label(props)
    local defaults = {
        BackgroundTransparency = 1,
        TextColor3 = Theme.Text,
        TextSize = 14,
        FontFace = Fonts.Medium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }
    for key, value in pairs(props) do
        defaults[key] = value
    end
    return create("TextLabel", defaults)
end

local function glow(parent, size, position, transparency, rotation)
    local image = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        Image = Assets.Glow,
        ImageColor3 = Color3.fromRGB(226, 218, 230),
        ImageTransparency = 1,
        Visible = false,
        ZIndex = 0,
        Parent = parent,
    })
    local gradient = create("UIGradient", {
        Rotation = rotation or 90,
        Parent = image,
    })
    onTheme(gradient, function()
        gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Theme.Accent)
    end)
    return image
end

local function edgeHighlight(parent)
    return create("Frame", {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = parent,
    })
end

local CUSTOM_ICON_SCALE = 1.35

local function applyIcon(imageLabel, icon, fixedSize)
    local image, rectOffset, rectSize, custom, tint = resolveIcon(icon)
    if not image then
        return
    end
    imageLabel.Image = image
    imageLabel.ImageRectOffset = rectOffset or Vector2.zero
    imageLabel.ImageRectSize = rectSize or Vector2.zero
    -- The built-in logo is a white mark meant to be tinted.
    if icon == Assets.Logo then
        tint = true
    end
    local keepColours = custom and not tint
    imageLabel:SetAttribute("CustomIcon", keepColours or nil)
    if keepColours then
        -- Original colours, and out of the theme's reach.
        tween(imageLabel, { ImageColor3 = Color3.new(1, 1, 1) }, 0)
    end
    -- Uploaded images usually carry transparent padding and read smaller than
    -- the lucide set, so they are drawn larger. A table icon can pick its own
    -- Scale. Brand logos pass fixedSize, their slots are already sized for them.
    local scale = custom and not fixedSize and icon ~= Assets.Logo and (typeof(icon) == "table" and tonumber(icon.Scale) or CUSTOM_ICON_SCALE) or 1
    local scaler = imageLabel:FindFirstChild("CustomIconScale")
    if scale ~= 1 then
        scaler = scaler or create("UIScale", { Name = "CustomIconScale", Parent = imageLabel })
        scaler.Scale = scale
    elseif scaler then
        scaler:Destroy()
    end
end

-- Selection state for icons: tinted icons change colour, custom images keep
-- their colours and dim instead.
local function tintIcon(imageLabel, color, active, duration)
    if imageLabel:GetAttribute("CustomIcon") then
        tween(imageLabel, { ImageTransparency = active and 0 or 0.4 }, duration)
    else
        tween(imageLabel, { ImageColor3 = color }, duration)
    end
end

local function defaultParent()
    local hidden
    pcall(function()
        if typeof(gethui) == "function" then
            hidden = gethui()
        end
    end)
    if typeof(hidden) == "Instance" then
        return hidden
    end
    local core
    pcall(function()
        core = game:GetService("CoreGui")
        local probe = Instance.new("Folder")
        probe.Parent = core
        probe:Destroy()
    end)
    if core then
        return core
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local insetFrame, insetValue = nil, Vector2.zero
local function pointerPosition()
    local frame = time()
    if insetFrame ~= frame then
        insetFrame = frame
        insetValue = GuiService:GetGuiInset()
    end
    return UserInputService:GetMouseLocation() - insetValue
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function usingTouch()
    return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
end

-- A press that turned into a scroll is not a tap. Returns a check to call
-- from the click handler.
local function tapGuard(button, getScroller)
    local startCanvas
    button.InputBegan:Connect(function(input)
        if isPress(input) then
            local frame = getScroller()
            startCanvas = frame and frame.CanvasPosition
        end
    end)
    return function()
        local frame = getScroller()
        return not (startCanvas and frame and (frame.CanvasPosition - startCanvas).Magnitude > 4)
    end
end

local function pointInside(point, object)
    local position, size = object.AbsolutePosition, object.AbsoluteSize
    return point.X >= position.X and point.X <= position.X + size.X
        and point.Y >= position.Y and point.Y <= position.Y + size.Y
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function glowIcon(parent, icon, color, position)
    local holder = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = position,
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    local image = create("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ImageColor3 = color,
        ScaleType = Enum.ScaleType.Fit,
        Parent = holder,
    })
    applyIcon(image, icon)
    return holder, image
end

local function arrowIndicator(parent, anchorX, offsetX)
    local holder = create("Frame", {
        AnchorPoint = Vector2.new(anchorX, 0.5),
        Position = UDim2.new(anchorX, offsetX, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    local indicator = {}
    local image = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Muted,
        ScaleType = Enum.ScaleType.Fit,
        Parent = holder,
    })
    applyIcon(image, "chevron-down")
    if image.Image ~= "" then
        function indicator:Set(open)
            tween(image, {
                Rotation = open and 180 or 0,
                ImageColor3 = open and Theme.Accent or Theme.Muted,
            }, 0.3, Enum.EasingStyle.Quint)
        end
        return indicator
    end
    image:Destroy()
    local function glyph(rotation, transparency)
        return label({
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(18, 18),
            Text = "›",
            TextSize = 22,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextColor3 = Theme.Muted,
            TextTransparency = transparency,
            Rotation = rotation,
            Parent = holder,
        })
    end
    local down = glyph(90, 0)
    local up = glyph(270, 1)
    function indicator:Set(open)
        tween(down, { TextTransparency = open and 1 or 0 }, 0.2)
        tween(up, { TextTransparency = open and 0 or 1, TextColor3 = open and Theme.Accent or Theme.Muted }, 0.2)
    end
    return indicator
end

local ripplePool = {}

local function ripple(button)
    local mouse = pointerPosition()
    local diameter = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.2
    local circle = table.remove(ripplePool)
    -- A pooled circle can't be reparented if it was destroyed along the way.
    if circle and not pcall(function()
        circle.Parent = nil
    end) then
        circle = nil
    end
    if not circle then
        circle = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
        })
        corner(circle, UDim.new(1, 0))
    end
    circle.Position = UDim2.fromOffset(mouse.X - button.AbsolutePosition.X, mouse.Y - button.AbsolutePosition.Y)
    circle.Size = UDim2.fromOffset(0, 0)
    circle.BackgroundColor3 = Theme.Accent
    circle.BackgroundTransparency = 0.82
    circle.ZIndex = button.ZIndex + 1
    circle.Parent = button
    tween(circle, { Size = UDim2.fromOffset(diameter, diameter), BackgroundTransparency = 1 }, 0.55)
    task.delay(0.55, function()
        -- A button destroyed mid-ripple takes the circle with it: drop it.
        if circle.Parent ~= button or not button.Parent then
            pcall(circle.Destroy, circle)
            return
        end
        circle.Parent = nil
        if #ripplePool < 4 then
            table.insert(ripplePool, circle)
        else
            circle:Destroy()
        end
    end)
end

local function flashStroke(strokeObject)
    if not strokeObject or strokeObject:GetAttribute("Hidden") then
        return
    end
    tween(strokeObject, { Color = Theme.Accent, Transparency = 0.2 }, 0.08)
    task.delay(0.12, function()
        tween(strokeObject, { Color = Theme.Stroke, Transparency = 0 }, 0.35)
    end)
end

local function hoverStroke(target, strokeObject)
    target.MouseEnter:Connect(function()
        tween(strokeObject, { Color = Theme.StrokeHover }, 0.12)
    end)
    target.MouseLeave:Connect(function()
        tween(strokeObject, { Color = Theme.Stroke }, 0.25)
    end)
end

local KEY_NAMES = {
    [Enum.KeyCode.LeftControl] = "LCtrl",
    [Enum.KeyCode.RightControl] = "RCtrl",
    [Enum.KeyCode.LeftShift] = "LShift",
    [Enum.KeyCode.RightShift] = "RShift",
    [Enum.KeyCode.LeftAlt] = "LAlt",
    [Enum.KeyCode.RightAlt] = "RAlt",
    [Enum.KeyCode.Return] = "Enter",
    [Enum.KeyCode.Escape] = "Esc",
    [Enum.KeyCode.Backspace] = "Backspace",
}

local function keyName(keyCode)
    if keyCode == nil then
        return "None"
    end
    return KEY_NAMES[keyCode] or keyCode.Name
end

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return
    end
    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[AirFlow] callback error: " .. tostring(err))
    end
end

-- Runs a user callback on its own thread and waits for it with task.wait.
-- A callback that yields inside an engine call (InvokeServer and the like)
-- resumes at game identity, which can no longer touch the GUI in CoreGui;
-- keeping that on a separate thread leaves the caller's identity intact.
local function isolatedCall(callback)
    local result = nil
    task.spawn(function()
        result = table.pack(pcall(callback))
    end)
    while result == nil do
        task.wait()
    end
    return table.unpack(result, 1, result.n)
end

local function numberFormat(min, max, step)
    local decimals = 0
    local text = tostring(step)
    local dot = text:find("%.")
    if dot then
        decimals = #text - dot
    end
    local pattern = "%." .. decimals .. "f"
    return {
        snap = function(value)
            value = math.floor(value / step + 0.5) * step
            return math.clamp(value, min, max)
        end,
        format = function(value)
            return string.format(pattern, value)
        end,
    }
end

local function metricsOf(tab)
    return tab._metrics or METRICS.Card
end

-- Width of a value control inside a groupbox row. Every dropdown and input in
-- a groupbox uses the same share of the row, so their left edges line up.
local function rowControlWidth(frame, window)
    local width = frame.AbsoluteSize.X / window.Scale.Scale
    return math.clamp(math.floor(width * 0.48), 90, 220)
end

local function card(tab, className, height, opts)
    local compact = metricsOf(tab).Compact
    local props = {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = compact and 1 or 0,
        BorderSizePixel = 0,
        LayoutOrder = tab:_nextOrder(),
        Parent = tab.List,
    }
    if className == "TextButton" then
        props.AutoButtonColor = false
        props.Text = ""
    end
    local frame = create(className, props)
    frame:SetAttribute("NoDrag", true)
    corner(frame)
    local frameStroke = stroke(frame, Theme.Stroke, compact and 1 or 0)
    if compact then
        frameStroke:SetAttribute("Hidden", true)
    end
    return frame, frameStroke
end

local function titleDesc(parent, name, desc, rightReserve, metrics)
    metrics = metrics or METRICS.Card
    local title, descLabel
    if desc then
        local top = math.floor((metrics.DescHeight - (metrics.DescGap + metrics.DescLine)) / 2)
        title = label({
            Position = UDim2.fromOffset(14, top),
            Size = UDim2.new(1, -(14 + rightReserve), 0, metrics.TitleHeight),
            Text = name,
            TextSize = metrics.TextSize,
            Parent = parent,
        })
        descLabel = label({
            Position = UDim2.fromOffset(14, top + metrics.DescGap),
            Size = UDim2.new(1, -(14 + rightReserve), 0, metrics.DescLine),
            Text = desc,
            TextSize = metrics.DescSize,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            Parent = parent,
        })
    else
        title = label({
            Position = UDim2.fromOffset(14, 0),
            Size = UDim2.new(1, -(14 + rightReserve), 1, 0),
            Text = name,
            TextSize = metrics.TextSize,
            Parent = parent,
        })
    end
    return title, descLabel
end

local function beginElement(tab, opts, map, className, rightReserve, fallbackName)
    opts = normalize(opts, map)
    local metrics = metricsOf(tab)
    local height = opts.Desc and metrics.DescHeight or metrics.Height
    local frame, frameStroke = card(tab, className or "Frame", height, opts)
    hoverStroke(frame, frameStroke)
    local title, descLabel
    if rightReserve then
        title, descLabel = titleDesc(frame, opts.Name or fallbackName, opts.Desc, rightReserve, metrics)
    end
    return opts, frame, frameStroke, height, title, descLabel
end

local function reserveRight(title, descLabel, width)
    if title then
        title.Size = UDim2.new(1, -(14 + width), title.Size.Y.Scale, title.Size.Y.Offset)
    end
    if descLabel then
        descLabel.Size = UDim2.new(1, -(14 + width), 0, descLabel.Size.Y.Offset)
    end
end

local Tab = {}
Tab.__index = Tab

function Tab:_nextOrder()
    self._order = self._order + 1
    return self._order
end

function Tab:Section(text)
    local visible = not (type(text) == "table" and text.Visible == false)
    if type(text) == "table" then
        text = text.Name or text.Title or ""
    end
    local inset = metricsOf(self).Compact and 14 or 2
    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder = self:_nextOrder(),
        Parent = self.List,
    })
    local text_ = label({
        Position = UDim2.fromOffset(inset, 8),
        Size = UDim2.new(0, 0, 0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = string.upper(text),
        TextSize = 12,
        TextColor3 = Theme.Muted,
        TextTruncate = Enum.TextTruncate.None,
        Parent = holder,
    })
    local ruleInset = inset == 2 and 0 or inset
    local rule = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -ruleInset, 0, 16),
        Size = UDim2.new(1, -12, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = holder,
    })
    local function fitRule()
        rule.Size = UDim2.new(1, -(text_.AbsoluteSize.X / self.Window.Scale.Scale + inset + 12 + ruleInset), 0, 1)
    end
    text_:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitRule)
    task.defer(fitRule)
    return finishElement(self, { Visible = visible }, {
        Set = function(_, value)
            text_.Text = string.upper(value)
        end,
    }, holder, "Section")
end

function Tab:Divider(opts)
    local caption = type(opts) == "table" and (opts.Text or opts.Name) or type(opts) == "string" and opts or nil
    if caption then
        -- A centred caption with a rule on each side.
        local inset = metricsOf(self).Compact and 14 or 2
        local holder = create("Frame", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            LayoutOrder = self:_nextOrder(),
            Parent = self.List,
        })
        local text_ = label({
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(0, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = caption,
            TextSize = 11,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            TextTruncate = Enum.TextTruncate.None,
            Parent = holder,
        })
        padding(text_, 8, 8)
        local rules = {}
        for index, anchor in ipairs({ 0, 1 }) do
            rules[index] = create("Frame", {
                AnchorPoint = Vector2.new(anchor, 0.5),
                Position = UDim2.new(anchor, anchor == 0 and inset or -inset, 0.5, 0),
                Size = UDim2.new(0.5, -inset, 0, 1),
                BackgroundColor3 = Theme.Stroke,
                BorderSizePixel = 0,
                Parent = holder,
            })
        end
        local function fitRules()
            local half = text_.AbsoluteSize.X / self.Window.Scale.Scale / 2
            for _, rule in ipairs(rules) do
                rule.Size = UDim2.new(0.5, -(inset + half), 0, 1)
            end
        end
        text_:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitRules)
        task.defer(fitRules)
        return finishElement(self, { Visible = not (type(opts) == "table" and opts.Visible == false) }, {
            Set = function(_, value)
                text_.Text = tostring(value)
            end,
        }, holder, "Divider")
    end
    local line = create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        LayoutOrder = self:_nextOrder(),
        Parent = self.List,
    })
    if metricsOf(self).Compact then
        line.BackgroundTransparency = 1
        line.Size = UDim2.new(1, 0, 0, 9)
        create("Frame", {
            Position = UDim2.fromOffset(14, 4),
            Size = UDim2.new(1, -28, 0, 1),
            BackgroundColor3 = Theme.Stroke,
            BorderSizePixel = 0,
            Parent = line,
        })
    end
    return finishElement(self, { Visible = not (type(opts) == "table" and opts.Visible == false) }, {}, line, "Divider")
end

function Tab:Label(opts)
    opts = normalize(opts, { Name = "Text", Title = "Text" })
    local text_ = label({
        Size = UDim2.new(1, 0, 0, 18),
        Text = Library._rich(opts.Text or ""),
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextColor3 = Library._color(opts.Color) or Theme.Muted,
        RichText = true,
        LayoutOrder = self:_nextOrder(),
        Parent = self.List,
    })
    if metricsOf(self).Compact then
        text_.TextSize = 12
        padding(text_, 14, 14)
    else
        padding(text_, 2)
    end
    local handle = {
        Set = function(_, value)
            text_.Text = Library._rich(value)
        end,
        Get = function()
            return text_.Text
        end,
        SetColor = function(_, color)
            tween(text_, { TextColor3 = Library._color(color) or Theme.Muted }, 0.25)
        end,
    }
    if type(opts.Update) == "function" then
        local rate = math.max(tonumber(opts.UpdateRate) or 1, 0.05)
        local running = true
        handle._listeners = handle._listeners or {}
        table.insert(handle._listeners, function()
            running = false
        end)
        task.spawn(function()
            while running and text_.Parent do
                local ok, value = isolatedCall(opts.Update)
                if ok and value ~= nil then
                    text_.Text = Library._rich(value)
                elseif not ok then
                    warn("[AirFlow] label update error: " .. tostring(value))
                end
                task.wait(rate)
            end
        end)
        function handle:SetUpdateRate(seconds)
            rate = math.max(tonumber(seconds) or rate, 0.05)
        end
    end
    return finishElement(self, opts, handle, text_, "Label")
end

function Tab:Paragraph(opts)
    opts = normalize(opts, { Title = "Name" })
    local frame = card(self, "Frame", 0, opts)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    if metricsOf(self).Compact then
        padding(frame, 14, 14, 6, 8)
    else
        padding(frame, 14, 14, 11, 12)
    end
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = frame,
    })
    label({
        Size = UDim2.new(1, 0, 0, 14),
        Text = opts.Name or "",
        LayoutOrder = 1,
        Parent = frame,
    })
    local content = label({
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = Library._rich(opts.Content or ""),
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        TextYAlignment = Enum.TextYAlignment.Top,
        RichText = true,
        LayoutOrder = 2,
        Parent = frame,
    })
    return finishElement(self, opts, {
        Set = function(_, value)
            content.Text = Library._rich(value)
        end,
    }, frame, "Paragraph")
end

local function rowButton(tab, opts)
    local primary = opts.Style == "Primary"
    local boxHeight = TOUCH and 34 or 28
    local height = boxHeight + 6 + (opts.Desc and 16 or 0)
    local button = card(tab, "TextButton", height, opts)

    local box = create("Frame", {
        Position = UDim2.fromOffset(14, 3),
        Size = UDim2.new(1, -28, 0, boxHeight),
        BackgroundColor3 = primary and Theme.Accent or Theme.Surface3,
        BackgroundTransparency = primary and 0.12 or 0.45,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = button,
    })
    corner(box, UDim.new(0, 6))
    local boxStroke = stroke(box, primary and Theme.Accent or Theme.Stroke, primary and 0.4 or 0)

    local row = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Parent = box,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = row,
    })
    local textColor = primary and Theme.AccentDark or Theme.Text
    if opts.Icon then
        local image = create("ImageLabel", {
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            ImageColor3 = primary and Theme.AccentDark or Theme.Accent,
            ScaleType = Enum.ScaleType.Fit,
            LayoutOrder = 1,
            Parent = row,
        })
        applyIcon(image, opts.Icon)
    end
    local title = label({
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = opts.Name or "Button",
        TextSize = 13,
        TextColor3 = textColor,
        TextTruncate = Enum.TextTruncate.None,
        LayoutOrder = 2,
        Parent = row,
    })
    if opts.Desc then
        label({
            Position = UDim2.fromOffset(14, boxHeight + 6),
            Size = UDim2.new(1, -28, 0, 14),
            Text = opts.Desc,
            TextSize = 12,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            Parent = button,
        })
    end

    local restBg = primary and 0.12 or 0.45
    button.MouseEnter:Connect(function()
        tween(box, { BackgroundTransparency = primary and 0 or 0.2 }, 0.12)
        tween(boxStroke, primary and { Transparency = 0 } or { Color = Theme.StrokeHover }, 0.12)
    end)
    button.MouseLeave:Connect(function()
        tween(box, { BackgroundTransparency = restBg }, 0.25)
        tween(boxStroke, primary and { Transparency = 0.4 } or { Color = Theme.Stroke }, 0.25)
    end)
    button.MouseButton1Click:Connect(function()
        ripple(box)
        safeCall(opts.Callback)
    end)

    return finishElement(tab, opts, {
        SetText = function(_, value)
            title.Text = value
        end,
    }, button, "Button")
end

function Tab:Button(opts)
    opts = normalize(opts, { Title = "Name", Description = "Desc" })
    if metricsOf(self).Compact then
        return rowButton(self, opts)
    end
    local primary = opts.Style == "Primary"
    local height = opts.Desc and CARD_HEIGHT_DESC or CARD_HEIGHT
    local button, buttonStroke = card(self, "TextButton", height, opts)
    button.ClipsDescendants = true

    if primary then
        tween(button, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.12 }, 0)
        tween(buttonStroke, { Color = Theme.Accent }, 0)
        buttonStroke.Transparency = 0.4
        button.MouseEnter:Connect(function()
            tween(button, { BackgroundTransparency = 0 }, 0.12)
            tween(buttonStroke, { Transparency = 0 }, 0.12)
        end)
        button.MouseLeave:Connect(function()
            tween(button, { BackgroundTransparency = 0.12 }, 0.25)
            tween(buttonStroke, { Transparency = 0.4 }, 0.25)
        end)
    else
        hoverStroke(button, buttonStroke)
    end

    local textColor = primary and Theme.AccentDark or Theme.Text
    local iconOffset = 0
    if opts.Icon then
        glowIcon(button, opts.Icon, primary and Theme.AccentDark or Theme.Accent, UDim2.new(0, 14, 0.5, 0))
        iconOffset = 26
    end
    local title = titleDesc(button, opts.Name or "Button", opts.Desc, 30)
    if iconOffset > 0 then
        for _, child in ipairs(button:GetChildren()) do
            if child:IsA("TextLabel") then
                child.Position = child.Position + UDim2.fromOffset(iconOffset, 0)
                child.Size = child.Size - UDim2.fromOffset(iconOffset, 0)
            end
        end
    end
    if primary then
        for _, child in ipairs(button:GetChildren()) do
            if child:IsA("TextLabel") then
                tween(child, { TextColor3 = textColor }, 0)
            end
        end
    end

    glowIcon(button, BUTTON_HINT_ICON, primary and Theme.AccentDark or Theme.Muted, UDim2.new(1, -30, 0.5, 0))

    button.MouseButton1Click:Connect(function()
        ripple(button)
        safeCall(opts.Callback)
    end)

    return finishElement(self, opts, {
        SetText = function(_, value)
            title.Text = value
        end,
    }, button, "Button")
end

function Tab:Toggle(opts)
    local button, buttonStroke
    opts, button, buttonStroke = beginElement(self, opts, { Title = "Name", Description = "Desc", CurrentValue = "Default", Value = "Default" }, "TextButton", 56, "Toggle")

    local pill = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = TOUCH and UDim2.fromOffset(44, 24) or UDim2.fromOffset(36, 20),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Parent = button,
    })
    corner(pill, UDim.new(1, 0))
    stroke(pill, Theme.Stroke)

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = TOUCH and UDim2.fromOffset(18, 18) or UDim2.fromOffset(14, 14),
        BackgroundColor3 = Theme.Muted,
        BorderSizePixel = 0,
        Parent = pill,
    })
    corner(knob, UDim.new(1, 0))
    local pillGlow = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 24, 1, 24),
        BackgroundTransparency = 1,
        Image = Assets.Glow,
        ImageColor3 = Theme.Accent,
        ImageTransparency = 1,
        ZIndex = 0,
        Parent = pill,
    })

    local self_ = { Value = opts.Default == true }

    local function render(animate)
        local on = self_.Value
        local duration = animate and 0.25 or 0
        tween(pill, { BackgroundColor3 = on and Theme.Accent or Theme.Surface3 }, duration)
        tween(pillGlow, { ImageTransparency = on and 0.75 or 1 }, duration)
        local knobSize = TOUCH and 18 or 14
        tween(knob, {
            Position = on and UDim2.new(0, (TOUCH and 44 or 36) - 3 - knobSize, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
            BackgroundColor3 = on and Theme.AccentDark or Theme.Muted,
        }, duration, Enum.EasingStyle.Back)
        if animate then
            tween(knob, { Size = UDim2.fromOffset(knobSize + 4, knobSize - 2) }, 0.08)
            task.delay(0.08, function()
                tween(knob, { Size = UDim2.fromOffset(knobSize, knobSize) }, 0.2, Enum.EasingStyle.Back)
            end)
        end
    end

    local fromClick = false
    function self_:Set(value, silent)
        value = value == true
        if value == self_.Value then
            return
        end
        self_.Value = value
        render(true)
        if not fromClick then
            flashStroke(buttonStroke)
        end
        if not silent then
            safeCall(opts.Callback, value)
        end
    end

    function self_:Get()
        return self_.Value
    end

    render(false)
    button.MouseButton1Click:Connect(function()
        fromClick = true
        self_:Set(not self_.Value)
        fromClick = false
    end)

    local handle = finishElement(self, opts, self_, button, "Toggle")
    if self_.Value then
        safeCall(opts.Callback, true)
    end
    return handle
end

function Tab:Slider(opts)
    opts = normalize(opts, { Title = "Name", Description = "Desc", CurrentValue = "Default", Value = "Default", Increment = "Step" })
    local min = opts.Min or 0
    local max = opts.Max or 100
    local step = opts.Step or 1
    local suffix = opts.Suffix or ""
    local numbers = numberFormat(min, max, step)

    local metrics = metricsOf(self)
    local compact = metrics.Compact
    local height = metrics.Slider
    local frame, frameStroke = card(self, "Frame", height, opts)
    hoverStroke(frame, frameStroke)

    label({
        Position = UDim2.fromOffset(14, compact and 5 or 12),
        Size = UDim2.new(1, -120, 0, 18),
        Text = opts.Name or "Slider",
        TextSize = metrics.TextSize,
        Parent = frame,
    })

    local valueChip = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, compact and -14 or -10, 0, compact and 2 or 9),
        Size = UDim2.fromOffset(40, 24),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = frame,
    })
    corner(valueChip, UDim.new(0, 6))
    local chipStroke = stroke(valueChip)
    local valueLabel = label({
        Size = UDim2.new(1, 0, 1, 0),
        TextSize = 13,
        TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.None,
        Parent = valueChip,
    })
    local valueBox = create("TextBox", {
        Position = UDim2.fromOffset(9, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 13,
        FontFace = Fonts.Medium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Visible = false,
        Parent = valueChip,
    })
    create("UISizeConstraint", { MinSize = Vector2.new(14, 0), Parent = valueBox })
    local suffixLabel = label({
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = suffix,
        TextSize = 13,
        TextColor3 = Theme.Accent,
        TextTruncate = Enum.TextTruncate.None,
        Visible = false,
        Parent = valueChip,
    })
    local chipButton = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 2,
        Parent = valueChip,
    })
    local editing = false
    local function fitChip(instant)
        local width
        if editing then
            width = 9 + valueBox.AbsoluteSize.X / (self.Window.Scale.Scale) + suffixLabel.TextBounds.X + 9
            suffixLabel.Position = UDim2.fromOffset(9 + valueBox.AbsoluteSize.X / (self.Window.Scale.Scale), 0)
        else
            width = valueLabel.TextBounds.X + 18
        end
        width = math.max(width, 36)
        if instant then
            valueChip.Size = UDim2.fromOffset(width, 24)
        else
            tween(valueChip, { Size = UDim2.fromOffset(width, 24) }, 0.2)
        end
    end
    valueLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
        if not editing then
            fitChip(false)
        end
    end)
    valueBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if editing then
            fitChip(false)
        end
    end)

    local track = create("Frame", {
        Position = UDim2.new(0, 14, 0, height - (compact and 13 or 18)),
        Size = UDim2.new(1, -28, 0, 5),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Parent = frame,
    })
    corner(track, UDim.new(1, 0))
    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(fill, UDim.new(1, 0))

    local knobGlow = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        BackgroundTransparency = 1,
        Image = Assets.Glow,
        ImageColor3 = Theme.Accent,
        ImageTransparency = 0.85,
        ZIndex = 2,
        Parent = track,
    })
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = track,
    })
    corner(knob, UDim.new(1, 0))

    local hit = create("TextButton", {
        Position = UDim2.new(0, 8, 0, height - (compact and 13 or 18) - (TOUCH and 19 or 13)),
        Size = UDim2.new(1, -16, 0, TOUCH and 40 or 28),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4,
        Parent = frame,
    })

    local self_ = { Value = math.clamp(opts.Default or min, min, max) }
    local dragging = false
    chipButton.MouseEnter:Connect(function()
        tween(chipStroke, { Color = Theme.StrokeHover }, 0.12)
    end)
    chipButton.MouseLeave:Connect(function()
        if not valueBox:IsFocused() then
            tween(chipStroke, { Color = Theme.Stroke }, 0.2)
        end
    end)
    chipButton.MouseButton1Click:Connect(function()
        editing = true
        valueBox.Text = numbers.format(self_.Value)
        valueLabel.Visible = false
        valueBox.Visible = true
        suffixLabel.Visible = suffix ~= ""
        chipButton.Visible = false
        tween(chipStroke, { Color = Theme.StrokeHover }, 0.12)
        valueBox:CaptureFocus()
        task.defer(fitChip, false)
    end)
    valueBox.FocusLost:Connect(function()
        local typed = tonumber(valueBox.Text)
        editing = false
        valueBox.Visible = false
        suffixLabel.Visible = false
        valueLabel.Visible = true
        chipButton.Visible = true
        tween(chipStroke, { Color = Theme.Stroke }, 0.2)
        if typed then
            self_:Set(typed)
        end
        fitChip(false)
    end)
    hit.MouseEnter:Connect(function()
        if not dragging then
            tween(knobGlow, { ImageTransparency = 0.78, Size = UDim2.fromOffset(34, 34) }, 0.15)
        end
    end)
    hit.MouseLeave:Connect(function()
        if not dragging then
            tween(knobGlow, { ImageTransparency = 0.85, Size = UDim2.fromOffset(28, 28) }, 0.2)
        end
    end)

    local snap = numbers.snap

    local function fraction()
        return (max - min) == 0 and 0 or (self_.Value - min) / (max - min)
    end

    local function moveTo(frac, duration, style)
        style = style or Enum.EasingStyle.Linear
        tween(fill, { Size = UDim2.new(frac, 0, 1, 0) }, duration, style)
        tween(knob, { Position = UDim2.new(frac, 0, 0.5, 0) }, duration, style)
        tween(knobGlow, { Position = UDim2.new(frac, 0, 0.5, 0) }, duration, style)
    end

    local function render(duration, style)
        moveTo(fraction(), duration, style)
        valueLabel.Text = numbers.format(self_.Value) .. suffix
    end

    local function settleTo(previousFrac)
        local target = fraction()
        local width = math.max(track.AbsoluteSize.X, 1)
        local overshoot = (target >= previousFrac and 1 or -1) * (5 / width)
        moveTo(math.clamp(target + overshoot, 0, 1), 0.22, Enum.EasingStyle.Quint)
        task.delay(0.22, function()
            if not dragging then
                moveTo(fraction(), 0.18, Enum.EasingStyle.Quint)
            end
        end)
        valueLabel.Text = numbers.format(self_.Value) .. suffix
    end

    local function bounceKnob()
        tween(knob, { Size = UDim2.fromOffset(14, 12) }, 0.08)
        tween(knobGlow, { Size = UDim2.fromOffset(32, 32), ImageTransparency = 0.78 }, 0.12)
        task.delay(0.1, function()
            tween(knob, { Size = UDim2.fromOffset(12, 12) }, 0.25, Enum.EasingStyle.Quint)
            tween(knobGlow, { Size = UDim2.fromOffset(28, 28), ImageTransparency = 0.85 }, 0.25)
        end)
    end

    function self_:Set(value, silent)
        value = snap(tonumber(value) or min)
        if value == self_.Value then
            return
        end
        local previousFrac = fraction()
        self_.Value = value
        if dragging then
            render(0.05)
        else
            settleTo(previousFrac)
            bounceKnob()
            flashStroke(frameStroke)
        end
        if not silent then
            safeCall(opts.Callback, value)
        end
    end

    function self_:Get()
        return self_.Value
    end

    local function updateFromX(x)
        local frac = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        self_:Set(min + (max - min) * frac)
    end

    hit.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging = true
            self_.Dragging = true
            tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.15, Enum.EasingStyle.Back)
            tween(knobGlow, { Size = UDim2.fromOffset(44, 44), ImageTransparency = 0.7 }, 0.15)
            updateFromX(pointerPosition().X)
        end
    end)

    self.Window:_listen("Changed", function(input)
        if dragging and isMove(input) then
            updateFromX(pointerPosition().X)
        end
    end, self_)

    self.Window:_listen("Ended", function(input)
        if dragging and isPress(input) then
            dragging = false
            self_.Dragging = false
            tween(knob, { Size = UDim2.fromOffset(12, 12) }, 0.2)
            tween(knobGlow, { Size = UDim2.fromOffset(28, 28), ImageTransparency = 0.85 }, 0.2)
            safeCall(opts.OnRelease, self_.Value)
        end
    end, self_)

    self_.Value = snap(self_.Value)
    render(0)
    task.defer(fitChip, true)
    return finishElement(self, opts, self_, frame, "Slider")
end

function Tab:Dropdown(opts)
    opts = normalize(opts, { Title = "Name", Description = "Desc", CurrentOption = "Default", Value = "Default", MultipleOptions = "Multi", Values = "Options" })
    if opts.Multi and type(opts.Default) ~= "table" and opts.Default ~= nil then
        opts.Default = { opts.Default }
    elseif not opts.Multi and type(opts.Default) == "table" then
        opts.Default = opts.Default[1]
    end
    local multi = opts.Multi == true
    local options = opts.Options or {}
    local frame, frameStroke, height
    opts, frame, frameStroke, height = beginElement(self, opts, {}, "Frame")
    local metrics = metricsOf(self)
    local compact = metrics.Compact
    local chipHeight = metrics.Chip
    local window = self.Window
    local ROW = TOUCH and 40 or 30
    local MAX_ROWS = opts.MaxRows or 6
    -- Stacked: the chip spans the whole row, with the name (if any) above it.
    local stacked = compact and opts.Stacked == true
    local stackTop = 2
    if stacked then
        stackTop = (opts.Name or "") ~= "" and 20 or 2
        chipHeight = TOUCH and 34 or 30
        height = stackTop + chipHeight + 4
        frame.Size = UDim2.new(1, 0, 0, height)
    end

    local header = create("TextButton", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Parent = frame,
    })
    local titleLabel, descLabel
    if not stacked then
        titleLabel, descLabel = titleDesc(header, opts.Name or "Dropdown", opts.Desc, 180, metrics)
    elseif stackTop > 2 then
        titleLabel = label({
            Position = UDim2.fromOffset(14, 1),
            Size = UDim2.new(1, -28, 0, 16),
            Text = opts.Name,
            TextSize = metrics.TextSize,
            Parent = header,
        })
    end

    local chip = create("Frame", {
        AnchorPoint = stacked and Vector2.zero or Vector2.new(1, 0.5),
        Position = stacked and UDim2.fromOffset(14, stackTop) or UDim2.new(1, compact and -14 or -10, 0.5, 0),
        Size = UDim2.fromOffset(60, chipHeight),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = header,
    })
    corner(chip, UDim.new(0, 6))
    local chipStroke = stroke(chip)
    local valueLabel = label({
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -34, 1, 0),
        TextColor3 = Theme.Muted,
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.None,
        ClipsDescendants = true,
        Parent = chip,
    })
    local arrow = arrowIndicator(chip, 1, -6)
    local measure = label({
        Size = UDim2.fromOffset(0, chipHeight),
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 13,
        Visible = false,
        Parent = chip,
    })
    local fullText = ""
    local function trimmed()
        local maxText = (stacked and frame.AbsoluteSize.X / window.Scale.Scale - 28 or compact and rowControlWidth(frame, window) or 190) - 10 - 34
        measure.Text = fullText
        if measure.TextBounds.X <= maxText then
            return fullText
        end
        local text = fullText
        while #text > 1 do
            text = text:sub(1, -2)
            measure.Text = text .. ".."
            if measure.TextBounds.X <= maxText then
                return text .. ".."
            end
        end
        return ".."
    end
    local function fitChip(instant)
        if stacked then
            chip.Size = UDim2.new(1, -28, 0, chipHeight)
            return
        end
        local width
        if compact then
            width = rowControlWidth(frame, window)
        else
            width = math.clamp(valueLabel.TextBounds.X + 10 + 34, 60, 190)
        end
        reserveRight(titleLabel, descLabel, width + (compact and 24 or 20))
        if instant then
            chip.Size = UDim2.fromOffset(width, chipHeight)
        else
            tween(chip, { Size = UDim2.fromOffset(width, chipHeight) }, 0.2)
        end
    end
    valueLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
        if not compact then
            fitChip(false)
        end
    end)
    if compact then
        -- The chip follows the row every frame; re-measuring the text waits
        -- until the width stops changing so resizing stays cheap.
        local lastWidth, pending = 0, false
        frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            local width = frame.AbsoluteSize.X
            if width == lastWidth then
                return
            end
            lastWidth = width
            fitChip(true)
            if not pending then
                pending = true
                task.delay(0.12, function()
                    pending = false
                    valueLabel.Text = trimmed()
                end)
            end
        end)
    end

    -- Popup: floats over the window under the chip, with search, bulk
    -- actions for multi selection and a scrolling list of checkbox rows.
    -- The popup is a plain clipped frame that unfolds out of the chip, so text
    -- stays crisp. The shadow sits outside the clip.
    local popup = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.fromOffset(220, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 45,
        Parent = window.Body,
    })
    popup:SetAttribute("NoDrag", true)
    local popupShadow = create("ImageLabel", {
        Position = UDim2.fromOffset(-18, -12),
        Size = UDim2.new(1, 36, 1, 36),
        BackgroundTransparency = 1,
        Image = Assets.Shadow,
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Parent = popup,
    })
    local panel = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = popup,
    })
    corner(panel, UDim.new(0, 10))
    local panelStroke = stroke(panel, Theme.Stroke, 1)
    edgeHighlight(panel)
    local inner = create("Frame", {
        Size = UDim2.new(1, 0, 0, 120),
        BackgroundTransparency = 1,
        Parent = panel,
    })
    padding(inner, 8, 8, 8, 8)

    local searchHolder = create("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = inner,
    })
    corner(searchHolder, UDim.new(0, 7))
    local searchStroke = stroke(searchHolder)
    local searchIconHolder, searchIcon = glowIcon(searchHolder, "search", Theme.Muted, UDim2.new(0, 10, 0.5, 0))
    searchIconHolder.Size = UDim2.fromOffset(14, 14)
    local searchBox = create("TextBox", {
        Position = UDim2.fromOffset(32, 0),
        Size = UDim2.new(1, -40, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = opts.SearchPlaceholder or "Search",
        PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text,
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClearTextOnFocus = false,
        Parent = searchHolder,
    })
    searchBox.Focused:Connect(function()
        tween(searchStroke, { Color = Theme.StrokeHover }, 0.15)
        tween(searchIcon, { ImageColor3 = Theme.Accent }, 0.15)
    end)
    searchBox.FocusLost:Connect(function()
        tween(searchStroke, { Color = Theme.Stroke }, 0.2)
        tween(searchIcon, { ImageColor3 = Theme.Muted }, 0.2)
    end)

    local actions = create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Visible = multi,
        Parent = inner,
    })
    local function actionButton(text, position)
        local button = create("TextButton", {
            Position = position,
            Size = UDim2.new(0.5, -3, 1, 0),
            BackgroundColor3 = Theme.Surface3,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ClipsDescendants = true,
            Parent = actions,
        })
        corner(button, UDim.new(0, 6))
        local buttonStroke = stroke(button)
        label({
            Size = UDim2.fromScale(1, 1),
            Text = text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = button,
        })
        button.MouseEnter:Connect(function()
            tween(button, { BackgroundTransparency = 0.05 }, 0.15)
            tween(buttonStroke, { Color = Theme.StrokeHover }, 0.15)
        end)
        button.MouseLeave:Connect(function()
            tween(button, { BackgroundTransparency = 0.35 }, 0.25)
            tween(buttonStroke, { Color = Theme.Stroke }, 0.25)
        end)
        button.MouseButton1Click:Connect(function()
            ripple(button)
        end)
        return button
    end
    local selectAll = actionButton(opts.SelectAllText or "Select all", UDim2.fromOffset(0, 0))
    local clearAll = actionButton(opts.ClearAllText or "Clear all", UDim2.new(0.5, 3, 0, 0))

    local list = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 100),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = TOUCH and 4 or 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        -- Sized by hand: AutomaticCanvasSize under the window's UIScale
        -- sometimes leaves the canvas short, so the list would not scroll.
        CanvasSize = UDim2.new(),
        Parent = inner,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = list,
    })
    local noResults = label({
        Size = UDim2.new(1, 0, 0, ROW),
        Text = opts.NoResultsText or "No results",
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 0,
        Visible = false,
        Parent = list,
    })

    local self_ = { Open = false }
    local selected = {}
    local optionButtons = {}
    local filter = ""

    local function matches(option)
        return filter == "" or string.find(string.lower(tostring(option)), filter, 1, true) ~= nil
    end

    -- Option labels are rich text, so the part matching the search can light up.
    local function escapeRich(text)
        return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
    end
    local function optionText(option)
        local text = tostring(option)
        local at = filter ~= "" and string.find(string.lower(text), filter, 1, true)
        if not at then
            return escapeRich(text)
        end
        local stop = at + #filter - 1
        return escapeRich(text:sub(1, at - 1))
            .. '<font color="#' .. Theme.Accent:ToHex() .. '"><b>' .. escapeRich(text:sub(at, stop)) .. "</b></font>"
            .. escapeRich(text:sub(stop + 1))
    end

    if multi then
        for _, value in ipairs(opts.Default or {}) do
            selected[value] = true
        end
    elseif opts.Default ~= nil then
        selected[opts.Default] = true
    end

    local function currentValue()
        if multi then
            local picked = {}
            for _, option in ipairs(options) do
                if selected[option] then
                    table.insert(picked, option)
                end
            end
            return picked
        end
        for _, option in ipairs(options) do
            if selected[option] then
                return option
            end
        end
        return nil
    end

    -- A picked row rests on a faint accent tint; hovering lifts either kind.
    local function restRow(entry, duration)
        local on, hover = entry.On == true, entry.Hover == true
        tween(entry.Frame, {
            BackgroundColor3 = on and Theme.Accent or Theme.Surface3,
            BackgroundTransparency = on and (hover and 0.8 or 0.88) or (hover and 0.55 or 1),
        }, duration)
        tween(entry.Label, { TextColor3 = (on or hover) and Theme.Text or Theme.Muted }, duration)
    end

    local function paintOption(button, animate)
        local on = selected[button.Option] == true
        if button.On == on and animate then
            return
        end
        button.On = on
        local duration = animate and 0.18 or 0
        restRow(button, duration)
        if multi then
            tween(button.Box, { BackgroundColor3 = on and Theme.Accent or Theme.Surface2 }, duration)
            tween(button.BoxStroke, { Color = on and Theme.Accent or Theme.Stroke }, duration)
        else
            tween(button.Bar, {
                BackgroundTransparency = on and 0 or 1,
                Size = UDim2.fromOffset(3, on and ROW - 14 or 4),
            }, animate and 0.3 or 0, Enum.EasingStyle.Quint)
        end
        tween(button.Check, { ImageTransparency = on and 0 or 1 }, duration)
        if animate and on then
            button.CheckScale.Scale = 0.5
            tween(button.CheckScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
        else
            button.CheckScale.Scale = 1
        end
    end

    local function renderValue(animate)
        local value = currentValue()
        if #options == 0 then
            fullText = opts.EmptyText or "None"
        elseif multi then
            -- Two names at most, then a count, so a long pick stays readable.
            if #value > 2 then
                fullText = tostring(value[1]) .. ", " .. tostring(value[2]) .. "  +" .. (#value - 2)
            else
                fullText = #value > 0 and table.concat(value, ", ") or (opts.NoneText or "None")
            end
        else
            fullText = value ~= nil and tostring(value) or (opts.NoneText or "None")
        end
        valueLabel.Text = trimmed()
        -- A picked value reads in full colour; "None" stays muted.
        local picked = #options > 0 and (if multi then #value > 0 else value ~= nil)
        tween(valueLabel, { TextColor3 = picked and Theme.Text or Theme.Muted }, animate and 0.15 or 0)
        for _, button in pairs(optionButtons) do
            paintOption(button, animate)
        end
    end

    local function visibleCount()
        local count = 0
        for _, option in ipairs(options) do
            if matches(option) then
                count += 1
            end
        end
        return count
    end

    local searchShown = true
    local targetSize = Vector2.new(220, 120)
    local opened = false
    local function layoutPopup(instant)
        searchShown = opts.Searchable ~= false and #options > (opts.SearchAfter or 0)
        searchHolder.Visible = searchShown
        local top = 0
        if searchShown then
            top += 38
        end
        actions.Position = UDim2.fromOffset(0, top)
        if multi and #options > 0 then
            actions.Visible = true
            top += 34
        else
            actions.Visible = false
        end
        local count = visibleCount()
        noResults.Visible = count == 0
        local rows = math.clamp(count, 1, MAX_ROWS)
        local listHeight = rows * ROW + (rows - 1) * 2
        list.CanvasSize = UDim2.fromOffset(0, math.max(count, 1) * (ROW + 2) - 2)
        local scale = window.Scale.Scale
        -- Shrink the list to whichever side of the chip has more room, so the
        -- popup never runs off a short window (phones in landscape).
        local host = window:_popupHost(frame)
        local bodyHeight = host.AbsoluteSize.Y / scale
        local chipTop = (chip.AbsolutePosition.Y - host.AbsolutePosition.Y) / scale
        local room = math.max(bodyHeight - (chipTop + chip.AbsoluteSize.Y / scale) - 14, chipTop - 14) - top - 16
        if room >= ROW then
            listHeight = math.min(listHeight, room)
        end
        list.Position = UDim2.fromOffset(0, top)
        list.Size = UDim2.new(1, 0, 0, listHeight)
        local width = math.max(math.floor(chip.AbsoluteSize.X / scale), opts.PopupWidth or 210)
        local bodyWidth = host.AbsoluteSize.X / scale
        width = math.min(width, math.max(bodyWidth - 16, 120))
        targetSize = Vector2.new(width, top + listHeight + 16)
        inner.Size = UDim2.new(1, 0, 0, targetSize.Y)
        if not opened then
            return
        end
        if instant then
            popup.Size = UDim2.fromOffset(targetSize.X, targetSize.Y)
        else
            tween(popup, { Size = UDim2.fromOffset(targetSize.X, targetSize.Y) }, 0.22, Enum.EasingStyle.Quint)
        end
    end

    local function applyFilter()
        for option, button in pairs(optionButtons) do
            local shown = matches(option)
            button.Frame.Visible = shown
            if shown then
                button.Label.Text = optionText(option)
            end
        end
    end

    local scroller = nil
    local function place()
        local body = window:_popupHost(frame)
        local scale = window.Scale.Scale
        if scroller then
            local centre = chip.AbsolutePosition + chip.AbsoluteSize / 2
            if not pointInside(centre, scroller) then
                self_:SetOpen(false)
                return
            end
        end
        local bodySize = body.AbsoluteSize / scale
        local chipPosition = (chip.AbsolutePosition - body.AbsolutePosition) / scale
        local chipSize = chip.AbsoluteSize / scale
        local right = math.clamp(chipPosition.X + chipSize.X, targetSize.X + 8, math.max(bodySize.X - 8, targetSize.X + 8))
        local below = chipPosition.Y + chipSize.Y + 6
        -- Opening upward pins the content to the bottom edge so it unfolds from the chip.
        if below + targetSize.Y > bodySize.Y - 8 and chipPosition.Y - 6 - targetSize.Y >= 8 then
            popup.AnchorPoint = Vector2.new(1, 1)
            popup.Position = UDim2.fromOffset(right, chipPosition.Y - 6)
            inner.AnchorPoint = Vector2.new(0, 1)
            inner.Position = UDim2.fromScale(0, 1)
        else
            popup.AnchorPoint = Vector2.new(1, 0)
            popup.Position = UDim2.fromOffset(right, below)
            inner.AnchorPoint = Vector2.zero
            inner.Position = UDim2.fromScale(0, 0)
        end
    end

    local stopFollowing = nil
    local closeGeneration = 0
    -- The page behind stops scrolling while the popup is open, so wheel and
    -- swipe input always reach the list instead of dragging the page away.
    local lockedScroller = nil
    local function unlockScroller()
        if lockedScroller then
            lockedScroller.ScrollingEnabled = true
            lockedScroller = nil
        end
    end
    local function scrollToSelected()
        list.CanvasPosition = Vector2.zero
        if multi then
            return
        end
        local value = currentValue()
        if value == nil then
            return
        end
        for index, option in ipairs(options) do
            if option == value then
                list.CanvasPosition = Vector2.new(0, math.max(0, (index - 2) * (ROW + 2)))
                return
            end
        end
    end
    local function setOpen(open)
        if open == self_.Open then
            return
        end
        self_.Open = open
        arrow:Set(open)
        tween(chipStroke, { Color = open and Theme.Accent or Theme.Stroke, Transparency = open and 0.35 or 0 }, 0.2)
        tween(chip, { BackgroundColor3 = open and Theme.Surface2 or Theme.Surface }, 0.2)
        closeGeneration += 1
        if open then
            if window._closePopup and window._closePopup ~= self_._close then
                window._closePopup()
            end
            window._closePopup = self_._close
            scroller = frame:FindFirstAncestorWhichIsA("ScrollingFrame")
            if scroller and scroller.ScrollingEnabled then
                lockedScroller = scroller
                scroller.ScrollingEnabled = false
            end
            -- Drawn over a floating panel when the dropdown lives in one.
            popup.Parent = window:_popupHost(frame)
            filter = ""
            searchBox.Text = ""
            searchBox.PlaceholderText = opts.SearchPlaceholder or (#options > 6 and ("Search " .. #options .. " options") or "Search")
            applyFilter()
            layoutPopup(true)
            renderValue(false)
            scrollToSelected()
            opened = true
            popup.Size = UDim2.fromOffset(targetSize.X, 0)
            place()
            popup.Visible = true
            tween(popup, { Size = UDim2.fromOffset(targetSize.X, targetSize.Y) }, 0.3, Enum.EasingStyle.Quint)
            tween(panelStroke, { Transparency = 0 }, 0.12)
            tween(popupShadow, { ImageTransparency = 0.4 }, 0.3)
            if not stopFollowing then
                stopFollowing = window:_listen("Render", place)
            end
        else
            if window._closePopup == self_._close then
                window._closePopup = nil
            end
            unlockScroller()
            if searchBox:IsFocused() then
                searchBox:ReleaseFocus()
            end
            opened = false
            tween(popup, { Size = UDim2.fromOffset(targetSize.X, 0) }, 0.2, Enum.EasingStyle.Quint)
            tween(popupShadow, { ImageTransparency = 1 }, 0.16)
            local generation = closeGeneration
            task.delay(0.14, function()
                if closeGeneration == generation and not self_.Open then
                    tween(panelStroke, { Transparency = 1 }, 0.06)
                end
            end)
            task.delay(0.21, function()
                if closeGeneration == generation and not self_.Open then
                    popup.Visible = false
                    if stopFollowing then
                        stopFollowing()
                        stopFollowing = nil
                    end
                end
            end)
        end
    end
    self_._close = function()
        setOpen(false)
    end

    local function commit()
        renderValue(true)
        safeCall(opts.Callback, currentValue())
    end

    local function buildOptions()
        local keep = {}
        for index, option in ipairs(options) do
            keep[option] = index
        end
        for option, button in pairs(optionButtons) do
            if not keep[option] then
                button.Frame:Destroy()
                optionButtons[option] = nil
            end
        end
        for index, option in ipairs(options) do
            local existing = optionButtons[option]
            if existing then
                existing.Frame.LayoutOrder = index
                continue
            end
            local row = create("TextButton", {
                Size = UDim2.new(1, -6, 0, ROW),
                BackgroundColor3 = Theme.Surface3,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = index,
                Parent = list,
            })
            corner(row, UDim.new(0, 7))
            -- Multi selection ticks a checkbox on the left. A single pick
            -- gets an accent bar on the left edge and a check on the right.
            local box, boxStroke, bar, check
            if multi then
                box = create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 8, 0.5, 0),
                    Size = UDim2.fromOffset(18, 18),
                    BackgroundColor3 = Theme.Surface2,
                    BorderSizePixel = 0,
                    Parent = row,
                })
                corner(box, UDim.new(0, 5))
                boxStroke = stroke(box, Theme.Stroke)
                check = create("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(12, 12),
                    BackgroundTransparency = 1,
                    ImageColor3 = Theme.AccentDark,
                    ImageTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit,
                    Parent = box,
                })
            else
                bar = create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 3, 0.5, 0),
                    Size = UDim2.fromOffset(3, 4),
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Parent = row,
                })
                corner(bar, UDim.new(1, 0))
                check = create("ImageLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundTransparency = 1,
                    ImageColor3 = Theme.Accent,
                    ImageTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit,
                    Parent = row,
                })
            end
            applyIcon(check, "check")
            local checkScale = create("UIScale", { Parent = check })
            local text_ = label({
                Position = UDim2.fromOffset(multi and 36 or 14, 0),
                Size = UDim2.new(1, multi and -44 or -46, 1, 0),
                Text = optionText(option),
                TextSize = 13,
                TextColor3 = Theme.Muted,
                RichText = true,
                Parent = row,
            })
            local entry = { Option = option, Frame = row, Box = box, BoxStroke = boxStroke, Bar = bar, Check = check, CheckScale = checkScale, Label = text_, On = nil, Hover = false }
            local isTap = tapGuard(row, function()
                return list
            end)
            row.MouseEnter:Connect(function()
                -- Touch fires enter without a matching leave; skip the hover.
                if usingTouch() then
                    return
                end
                entry.Hover = true
                restRow(entry, 0.15)
                if boxStroke and not selected[option] then
                    tween(boxStroke, { Color = Theme.StrokeHover }, 0.15)
                end
            end)
            row.MouseLeave:Connect(function()
                entry.Hover = false
                restRow(entry, 0.25)
                if boxStroke and not selected[option] then
                    tween(boxStroke, { Color = Theme.Stroke }, 0.25)
                end
            end)
            row.MouseButton1Click:Connect(function()
                if not isTap() then
                    return
                end
                if selected[option] then
                    if not multi and opts.AllowNone == false then
                        setOpen(false)
                        return
                    end
                    selected[option] = nil
                else
                    if not multi then
                        selected = {}
                    end
                    selected[option] = true
                end
                commit()
                if not multi then
                    setOpen(false)
                end
            end)
            optionButtons[option] = entry
            paintOption(entry, false)
        end
        applyFilter()
        if self_.Open then
            layoutPopup(false)
        end
    end

    selectAll.MouseButton1Click:Connect(function()
        for _, option in ipairs(options) do
            if matches(option) then
                selected[option] = true
            end
        end
        commit()
    end)
    clearAll.MouseButton1Click:Connect(function()
        selected = {}
        commit()
    end)

    function self_:Set(value, silent)
        selected = {}
        if multi then
            for _, item in ipairs(type(value) == "table" and value or { value }) do
                selected[item] = true
            end
        elseif value ~= nil then
            selected[value] = true
        end
        renderValue(self_.Open)
        flashStroke(frameStroke)
        if not silent then
            safeCall(opts.Callback, currentValue())
        end
    end

    function self_:Get()
        return currentValue()
    end

    local function sameValue(a, b)
        if type(a) ~= "table" or type(b) ~= "table" then
            return a == b
        end
        if #a ~= #b then
            return false
        end
        for index, item in ipairs(a) do
            if b[index] ~= item then
                return false
            end
        end
        return true
    end

    -- A kept pick only counts once its option exists, so a list filled in after a
    -- config load changes the value; the callback runs so scripts see it.
    function self_:Refresh(newOptions, keepSelection, silent)
        local before = currentValue()
        options = newOptions or {}
        if not keepSelection then
            selected = {}
        end
        buildOptions()
        renderValue(false)
        if not silent and not sameValue(before, currentValue()) then
            safeCall(opts.Callback, currentValue())
        end
    end

    -- Every pick, including ones whose option isn't in the list right now, so
    -- saving never drops them.
    function self_:_saveValue()
        local picked = currentValue()
        if multi then
            local seen = {}
            for _, item in ipairs(picked) do
                seen[item] = true
            end
            for item in pairs(selected) do
                if not seen[item] then
                    table.insert(picked, item)
                end
            end
            return picked
        end
        if picked == nil then
            picked = next(selected)
        end
        return picked
    end

    function self_:SetOpen(open)
        setOpen(open == true)
    end

    local headerTap = tapGuard(header, function()
        return frame:FindFirstAncestorWhichIsA("ScrollingFrame")
    end)
    header.MouseButton1Click:Connect(function()
        if headerTap() then
            setOpen(not self_.Open)
        end
    end)
    -- The chip answers the pointer before it is opened.
    header.MouseEnter:Connect(function()
        if not self_.Open and not usingTouch() then
            tween(chipStroke, { Color = Theme.StrokeHover }, 0.15)
            tween(chip, { BackgroundColor3 = Theme.Surface2 }, 0.15)
        end
    end)
    header.MouseLeave:Connect(function()
        if not self_.Open then
            tween(chipStroke, { Color = Theme.Stroke }, 0.25)
            tween(chip, { BackgroundColor3 = Theme.Surface }, 0.25)
        end
    end)
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        filter = string.lower(searchBox.Text)
        applyFilter()
        if self_.Open then
            layoutPopup(false)
        end
    end)
    self_._listeners = {
        function()
            setOpen(false)
            unlockScroller()
            if stopFollowing then
                stopFollowing()
                stopFollowing = nil
            end
            popup:Destroy()
        end,
    }
    window:_listen("Began", function(input)
        if not self_.Open then
            return
        end
        if input.KeyCode == Enum.KeyCode.Escape then
            setOpen(false)
        elseif isPress(input) then
            local point = pointerPosition()
            if not pointInside(point, popup) and not pointInside(point, header) then
                setOpen(false)
            end
        end
    end, self_)

    buildOptions()
    renderValue(false)
    task.defer(fitChip, true)
    return finishElement(self, opts, self_, frame, "Dropdown")
end

Library._amountSuffixes = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, qi = 1e18 }

function Library._parseAmount(text)
    text = string.lower(tostring(text)):gsub("[%s,_%$]", "")
    text = text:gsub("kg$", ""):gsub("/s$", "")
    local number = tonumber(text)
    if number then
        return number
    end
    local digits, suffix = text:match("^(.-)(%a+)$")
    local scale = suffix and Library._amountSuffixes[suffix]
    number = digits and tonumber(digits)
    if number and scale then
        return number * scale
    end
    return nil
end

function Tab:Input(opts)
    local frame, frameStroke, _, titleLabel, descLabel
    opts, frame, frameStroke, _, titleLabel, descLabel = beginElement(self, opts, { Title = "Name", Description = "Desc", PlaceholderText = "Placeholder", CurrentValue = "Default", Value = "Default" }, "Frame", 160, "Input")
    local compact = metricsOf(self).Compact
    local boxHeight = compact and metricsOf(self).Chip + 2 or 30

    local boxHolder = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, compact and -14 or -10, 0.5, 0),
        Size = UDim2.fromOffset(170, boxHeight),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = frame,
    })
    corner(boxHolder, UDim.new(0, 6))
    local boxStroke = stroke(boxHolder)

    local boxIcon = opts.Icon
    if boxIcon then
        glowIcon(boxHolder, boxIcon, Theme.Muted, UDim2.new(0, 8, 0.5, 0))
    end
    local box = create("TextBox", {
        Position = UDim2.fromOffset(boxIcon and 30 or 8, 0),
        Size = UDim2.new(1, boxIcon and -38 or -16, 1, 0),
        BackgroundTransparency = 1,
        Text = opts.Default or "",
        PlaceholderText = opts.Placeholder or "",
        PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text,
        TextSize = compact and 13 or 14,
        FontFace = Fonts.Regular,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        TextTruncate = Enum.TextTruncate.None,
        ClipsDescendants = true,
        Parent = boxHolder,
    })
    boxHolder.ClipsDescendants = true

    local lastText = box.Text
    local value = opts.Numeric and Library._parseAmount(lastText) or nil
    if opts.Numeric and not value then
        lastText = ""
    end
    local focused = false
    local textInset = (boxIcon and 30 or 8) + 8
    local function fitBox(instant)
        local width
        if compact then
            width = rowControlWidth(frame, self.Window)
        else
            local cardWidth = frame.AbsoluteSize.X / self.Window.Scale.Scale
            local maxWidth = math.clamp(cardWidth - 14 - 110 - 20, 100, 200)
            local measured = box.TextBounds.X
            if #box.Text == 0 then
                measured = math.min(box.TextBounds.X, 90)
            end
            width = math.clamp(measured + textInset + 12, 90, maxWidth) + (focused and 8 or 0)
            width = math.min(width, maxWidth + 8)
        end
        reserveRight(titleLabel, descLabel, width + (compact and 24 or 20))
        if instant then
            boxHolder.Size = UDim2.fromOffset(width, boxHeight)
        else
            tween(boxHolder, { Size = UDim2.fromOffset(width, boxHeight) }, 0.18)
        end
    end
    local lastWidth = 0
    frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if frame.AbsoluteSize.X ~= lastWidth then
            lastWidth = frame.AbsoluteSize.X
            fitBox(true)
        end
    end)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        fitBox(false)
        -- Finished = false keeps the original script's live numeric inputs.
        if opts.Finished == false then
            if opts.Numeric then
                local number = Library._parseAmount(box.Text)
                if number then
                    lastText, value = box.Text, number
                    safeCall(opts.Callback, number, false)
                end
            else
                safeCall(opts.Callback, box.Text, false)
            end
        end
    end)
    box:GetPropertyChangedSignal("TextBounds"):Connect(function()
        fitBox(false)
    end)
    task.defer(fitBox, true)

    box.Focused:Connect(function()
        focused = true
        tween(boxStroke, { Color = Theme.StrokeHover }, 0.15)
        fitBox(false)
    end)
    box.FocusLost:Connect(function(enterPressed)
        focused = false
        tween(boxStroke, { Color = Theme.Stroke }, 0.15)
        fitBox(false)
        if opts.Numeric then
            local number = Library._parseAmount(box.Text)
            if not number then
                box.Text = lastText
                return
            end
            lastText, value = box.Text, number
            if opts.Finished ~= false then
                safeCall(opts.Callback, number, enterPressed)
            end
            return
        end
        if opts.Finished ~= false then
            safeCall(opts.Callback, box.Text, enterPressed)
        end
    end)

    return finishElement(self, opts, {
        Set = function(_, newValue)
            box.Text = tostring(newValue)
            if opts.Numeric then
                local number = Library._parseAmount(box.Text)
                if number then
                    lastText, value = box.Text, number
                else
                    box.Text = lastText
                end
            end
            flashStroke(frameStroke)
        end,
        Get = function()
            if opts.Numeric then
                return value
            end
            return box.Text
        end,
        _saveValue = opts.Numeric and function()
            return lastText
        end or nil,
    }, frame, "Input")
end

function Tab:Keybind(opts)
    local frame, frameStroke, _, titleLabel, descLabel
    opts, frame, frameStroke, _, titleLabel, descLabel = beginElement(self, opts, { Title = "Name", Description = "Desc", CurrentKeybind = "Default", Value = "Default" }, "Frame", 110, "Keybind")
    if type(opts.Default) == "string" then
        opts.Default = Enum.KeyCode[opts.Default]
    end
    local compact = metricsOf(self).Compact
    local chipHeight = metricsOf(self).Chip

    local chip = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, compact and -14 or -10, 0.5, 0),
        Size = UDim2.fromOffset(44, chipHeight),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = frame,
    })
    corner(chip, UDim.new(0, 6))
    local chipStroke = stroke(chip)
    local chipLabel = label({
        Size = UDim2.new(1, 0, 1, 0),
        TextSize = 13,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.None,
        Parent = chip,
    })

    local self_ = { Value = opts.Default, Listening = false }

    local function fitChip(instant)
        local width = math.max(chipLabel.TextBounds.X + 20, TOUCH and 44 or 36)
        reserveRight(titleLabel, descLabel, width + (compact and 24 or 20))
        if instant then
            chip.Size = UDim2.fromOffset(width, chipHeight)
        else
            tween(chip, { Size = UDim2.fromOffset(width, chipHeight) }, 0.2)
        end
    end
    chipLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
        fitChip(false)
    end)

    local function render()
        chipLabel.Text = self_.Listening and "..." or keyName(self_.Value)
        tween(chipStroke, { Color = self_.Listening and Theme.StrokeHover or Theme.Stroke }, 0.15)
        tween(chipLabel, { TextColor3 = self_.Listening and Theme.Accent or Theme.Muted }, 0.15)
    end

    function self_:Set(keyCode, silent)
        local wasListening = self_.Listening
        self_.Value = keyCode
        self_.Listening = false
        render()
        if not wasListening then
            flashStroke(frameStroke)
        end
        if not silent then
            safeCall(opts.OnChanged, keyCode)
        end
    end

    chip.MouseButton1Click:Connect(function()
        self_.Listening = not self_.Listening
        render()
    end)

    self.Window:_listen("Began", function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if self_.Listening then
            self.Window._consumedKey = input.KeyCode
            self.Window._consumedAt = os.clock()
            if input.KeyCode == Enum.KeyCode.Escape then
                self_.Listening = false
                render()
            else
                self_:Set(input.KeyCode)
            end
            return
        end
        if not gameProcessed and self_.Value ~= nil and input.KeyCode == self_.Value then
            safeCall(opts.Callback, input.KeyCode)
        end
    end, self_)

    render()
    task.defer(fitChip, true)
    function self_:Get()
        return self_.Value
    end
    self_._onHide = function()
        if self_.Listening then
            self_.Listening = false
            render()
        end
    end
    return finishElement(self, opts, self_, frame, "Keybind")
end

function Tab:ColorPicker(opts)
    local PANEL_HEIGHT = 194
    local frame, frameStroke, height
    opts, frame, frameStroke, height = beginElement(self, opts, { Title = "Name", Description = "Desc", Color = "Default", CurrentValue = "Default", Value = "Default" }, "Frame")
    frame.ClipsDescendants = true
    local metrics = metricsOf(self)
    local compact = metrics.Compact

    local header = create("TextButton", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Parent = frame,
    })
    titleDesc(header, opts.Name or "Color", opts.Desc, 140, metrics)

    -- Closed, the row shows the hex code beside a rounded swatch.
    local swatch = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, compact and -38 or -34, 0.5, 0),
        Size = UDim2.fromOffset(22, 22),
        BorderSizePixel = 0,
        Parent = header,
    })
    corner(swatch, UDim.new(0, 6))
    stroke(swatch, Theme.Stroke)
    local swatchHex = label({
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, compact and -68 or -64, 0.5, 0),
        Size = UDim2.fromOffset(64, 16),
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = header,
    })
    local arrow = arrowIndicator(header, 1, compact and -14 or -12)

    local panel = create("Frame", {
        Position = UDim2.fromOffset(14, height + 2),
        Size = UDim2.new(1, -28, 0, PANEL_HEIGHT - 12),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = frame,
    })

    -- Saturation runs left to right, brightness top to bottom.
    local svBox = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 118),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = panel,
    })
    corner(svBox, UDim.new(0, 8))
    stroke(svBox, Theme.Stroke)
    local svHueGradient = create("UIGradient", {
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 0, 0)),
        Parent = svBox,
    })
    local svDark = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Parent = svBox,
    })
    corner(svDark, UDim.new(0, 8))
    create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90,
        Parent = svDark,
    })

    -- Both handles are a white ring filled with the colour under them, with a
    -- faint dark edge so they read on light and dark spots alike.
    local function knob(parent, size)
        local ring = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(size, size),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 3,
            Parent = parent,
        })
        corner(ring, UDim.new(1, 0))
        stroke(ring, Color3.new(0, 0, 0), 0.7)
        local fill = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, -4, 1, -4),
            BorderSizePixel = 0,
            ZIndex = 3,
            Parent = ring,
        })
        corner(fill, UDim.new(1, 0))
        return ring, fill
    end
    local svCursor, svFill = knob(svBox, 14)

    -- Hue is a slim horizontal track under the square.
    local hueBar = create("TextButton", {
        Position = UDim2.fromOffset(0, 132),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = panel,
    })
    corner(hueBar, UDim.new(1, 0))
    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
        Parent = hueBar,
    })
    local hueCursor, hueFill = knob(hueBar, 16)
    hueCursor.Position = UDim2.fromScale(0, 0.5)

    -- Bottom row: a preview chip and hex field on the left, RGB on the right.
    local hexHolder = create("Frame", {
        Position = UDim2.fromOffset(0, 154),
        Size = UDim2.fromOffset(compact and 110 or 124, 28),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = panel,
    })
    corner(hexHolder, UDim.new(0, 7))
    local hexStroke = stroke(hexHolder)
    local preview = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 6, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BorderSizePixel = 0,
        Parent = hexHolder,
    })
    corner(preview, UDim.new(0, 4))
    stroke(preview, Theme.Stroke)
    local hexBox = create("TextBox", {
        Position = UDim2.fromOffset(30, 0),
        Size = UDim2.new(1, -38, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextTruncate = Enum.TextTruncate.None,
        ClipsDescendants = false,
        TextColor3 = Theme.Text,
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = hexHolder,
    })
    local rgbLabel = label({
        Position = UDim2.fromOffset(compact and 118 or 134, 154),
        Size = UDim2.new(1, compact and -118 or -134, 0, 28),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        Parent = panel,
    })

    local self_ = { Open = false }
    local hue, sat, val = Color3.toHSV(opts.Default or Theme.Accent)
    local dragTarget = nil

    local function toHex(color)
        return string.format("#%02X%02X%02X",
            math.floor(color.R * 255 + 0.5),
            math.floor(color.G * 255 + 0.5),
            math.floor(color.B * 255 + 0.5))
    end

    local function render(duration)
        local color = Color3.fromHSV(hue, sat, val)
        self_.Value = color
        swatch.BackgroundColor3 = color
        preview.BackgroundColor3 = color
        svFill.BackgroundColor3 = color
        hueFill.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        swatchHex.Text = toHex(color)
        svHueGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(hue, 1, 1))
        tween(svCursor, { Position = UDim2.fromScale(sat, 1 - val) }, duration, Enum.EasingStyle.Quint)
        tween(hueCursor, { Position = UDim2.fromScale(hue, 0.5) }, duration, Enum.EasingStyle.Quint)
        if not hexBox:IsFocused() then
            hexBox.Text = toHex(color)
        end
        rgbLabel.Text = string.format("%d  %d  %d",
            math.floor(color.R * 255 + 0.5),
            math.floor(color.G * 255 + 0.5),
            math.floor(color.B * 255 + 0.5))
    end

    local function commit(duration, silent)
        render(duration)
        if not silent then
            safeCall(opts.Callback, self_.Value)
        end
    end

    function self_:Set(color, silent)
        hue, sat, val = Color3.toHSV(color)
        commit(0.25, silent)
        flashStroke(frameStroke)
    end

    function self_:Get()
        return self_.Value
    end

    local function setOpen(open)
        self_.Open = open
        tween(frame, { Size = UDim2.new(1, 0, 0, open and (height + PANEL_HEIGHT) or height) }, 0.35, Enum.EasingStyle.Quint)
        arrow:Set(open)
        if open then
            panel.Visible = true
        else
            task.delay(0.35, function()
                if not self_.Open then
                    panel.Visible = false
                end
            end)
        end
    end

    function self_:SetOpen(open)
        setOpen(open == true)
    end

    header.MouseButton1Click:Connect(function()
        setOpen(not self_.Open)
    end)

    local function updateSV(position)
        sat = math.clamp((position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
        val = 1 - math.clamp((position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
        commit(0.04)
    end
    local function updateHue(position)
        hue = math.clamp((position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 0.999)
        commit(0.04)
    end

    svBox.InputBegan:Connect(function(input)
        if isPress(input) then
            dragTarget = "sv"
            tween(svCursor, { Size = UDim2.fromOffset(18, 18) }, 0.2, Enum.EasingStyle.Quint)
            updateSV(pointerPosition())
        end
    end)
    hueBar.InputBegan:Connect(function(input)
        if isPress(input) then
            dragTarget = "hue"
            tween(hueCursor, { Size = UDim2.fromOffset(20, 20) }, 0.2, Enum.EasingStyle.Quint)
            updateHue(pointerPosition())
        end
    end)
    self.Window:_listen("Changed", function(input)
        if not dragTarget or not isMove(input) then
            return
        end
        local position = pointerPosition()
        if dragTarget == "sv" then
            updateSV(position)
        else
            updateHue(position)
        end
    end, self_)
    self.Window:_listen("Ended", function(input)
        if dragTarget and isPress(input) then
            dragTarget = nil
            tween(svCursor, { Size = UDim2.fromOffset(14, 14) }, 0.25, Enum.EasingStyle.Quint)
            tween(hueCursor, { Size = UDim2.fromOffset(16, 16) }, 0.25, Enum.EasingStyle.Quint)
        end
    end, self_)

    hexBox.Focused:Connect(function()
        tween(hexStroke, { Color = Theme.StrokeHover }, 0.15)
    end)
    hexBox.FocusLost:Connect(function()
        tween(hexStroke, { Color = Theme.Stroke }, 0.15)
        local r, g, b = hexBox.Text:match("^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
        if r then
            self_:Set(Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)))
        else
            hexBox.Text = toHex(self_.Value)
        end
    end)

    render(0)
    return finishElement(self, opts, self_, frame, "ColorPicker")
end

function Tab:Stepper(opts)
    local frame, frameStroke, _, titleLabel, descLabel
    opts, frame, frameStroke, _, titleLabel, descLabel = beginElement(self, opts, { Title = "Name", Description = "Desc", CurrentValue = "Default", Value = "Default", Increment = "Step" }, "Frame", 150, "Stepper")
    local min = opts.Min or 0
    local max = opts.Max or 100
    local step = opts.Step or 1
    local suffix = opts.Suffix or ""
    local numbers = numberFormat(min, max, step)
    local compact = metricsOf(self).Compact
    local chipHeight = metricsOf(self).Chip

    local group = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, compact and -14 or -10, 0.5, 0),
        Size = UDim2.fromOffset(0, chipHeight),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = frame,
    })
    corner(group, UDim.new(0, 6))
    local groupStroke = stroke(group)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = group,
    })

    local function stepButton(text, order)
        local button = create("TextButton", {
            Size = UDim2.fromOffset(chipHeight, chipHeight),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.Muted,
            TextSize = 18,
            FontFace = Fonts.Medium,
            AutoButtonColor = false,
            LayoutOrder = order,
            Parent = group,
        })
        button.MouseEnter:Connect(function()
            tween(button, { TextColor3 = Theme.Accent }, 0.12)
        end)
        button.MouseLeave:Connect(function()
            tween(button, { TextColor3 = Theme.Muted }, 0.2)
        end)
        return button
    end
    local minus = stepButton("−", 1)
    local valueLabel = label({
        Size = UDim2.new(0, 30, 1, 0),
        TextSize = 13,
        TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.None,
        LayoutOrder = 2,
        Parent = group,
    })
    local plus = stepButton("+", 3)
    local function fitValue(instant)
        local width = math.max(valueLabel.TextBounds.X + 12, 30)
        if instant then
            valueLabel.Size = UDim2.new(0, width, 1, 0)
        else
            tween(valueLabel, { Size = UDim2.new(0, width, 1, 0) }, 0.2)
        end
    end
    valueLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
        fitValue(false)
    end)
    group:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        reserveRight(titleLabel, descLabel, group.AbsoluteSize.X / self.Window.Scale.Scale + (compact and 24 or 20))
    end)

    local self_ = { Value = math.clamp(opts.Default or min, min, max) }
    local snap = numbers.snap
    local fromButton = false
    local function render()
        valueLabel.Text = numbers.format(self_.Value) .. suffix
        tween(minus, { TextTransparency = self_.Value <= min and 0.6 or 0 }, 0.15)
        tween(plus, { TextTransparency = self_.Value >= max and 0.6 or 0 }, 0.15)
    end
    function self_:Set(value, silent)
        value = snap(tonumber(value) or min)
        if value == self_.Value then
            return
        end
        self_.Value = value
        render()
        if not fromButton then
            flashStroke(frameStroke)
        end
        if not silent then
            safeCall(opts.Callback, value)
        end
    end
    function self_:Get()
        return self_.Value
    end

    local function bump(direction)
        fromButton = true
        self_:Set(self_.Value + direction * step)
        fromButton = false
        tween(groupStroke, { Color = Theme.StrokeHover }, 0.08)
        task.delay(0.12, function()
            tween(groupStroke, { Color = Theme.Stroke }, 0.2)
        end)
    end
    local function holdRepeat(button, direction)
        local holding = false
        button.InputBegan:Connect(function(input)
            if not isPress(input) then
                return
            end
            holding = true
            bump(direction)
            task.delay(0.4, function()
                while holding do
                    bump(direction)
                    task.wait(0.07)
                end
            end)
        end)
        button.InputEnded:Connect(function(input)
            if isPress(input) then
                holding = false
            end
        end)
        button.MouseLeave:Connect(function()
            holding = false
        end)
    end
    holdRepeat(minus, -1)
    holdRepeat(plus, 1)

    render()
    task.defer(fitValue, true)
    return finishElement(self, opts, self_, frame, "Stepper")
end

function Tab:Progress(opts)
    opts = normalize(opts, { Title = "Name", Description = "Desc", CurrentValue = "Default", Value = "Default" })
    local metrics = metricsOf(self)
    local compact = metrics.Compact
    local extra = compact and 6 or 10
    local frame, frameStroke = card(self, "Frame", (opts.Desc and metrics.DescHeight or metrics.Height) + extra, opts)
    hoverStroke(frame, frameStroke)
    local top
    if opts.Desc then
        top = math.floor((metrics.DescHeight - (metrics.DescGap + metrics.DescLine)) / 2) - 2
    else
        top = compact and 5 or 12
    end

    label({
        Position = UDim2.fromOffset(14, top),
        Size = UDim2.new(1, -110, 0, 18),
        Text = opts.Name or "Progress",
        TextSize = metrics.TextSize,
        Parent = frame,
    })
    if opts.Desc then
        label({
            Position = UDim2.fromOffset(14, top + metrics.DescGap),
            Size = UDim2.new(1, -110, 0, metrics.DescLine),
            Text = opts.Desc,
            TextSize = metrics.DescSize,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            Parent = frame,
        })
    end
    local valueLabel = label({
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, top),
        Size = UDim2.fromOffset(90, 18),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextSize = 13,
        TextColor3 = Library._color(opts.TextColor) or Theme.Accent,
        RichText = true,
        Parent = frame,
    })
    local track = create("Frame", {
        Position = UDim2.new(0, 14, 1, compact and -12 or -16),
        Size = UDim2.new(1, -28, 0, 5),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Parent = frame,
    })
    corner(track, UDim.new(1, 0))
    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Library._color(opts.Color) or Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(fill, UDim.new(1, 0))

    local self_ = { Value = math.clamp(opts.Default or 0, 0, 1) }
    local formatter = opts.Format
    local function render(duration)
        local frac = self_.Value
        tween(fill, { Size = UDim2.new(frac, 0, 1, 0) }, duration, Enum.EasingStyle.Quint)
        if type(formatter) == "function" then
            valueLabel.Text = Library._rich(formatter(frac))
        else
            valueLabel.Text = string.format("%d%%", math.floor(frac * 100 + 0.5))
        end
    end
    function self_:Set(value, silent)
        value = math.clamp(tonumber(value) or 0, 0, 1)
        if value == self_.Value then
            return
        end
        self_.Value = value
        render(0.35)
        if not silent then
            safeCall(opts.Callback, value)
        end
    end
    function self_:Get()
        return self_.Value
    end
    function self_:SetColor(color)
        tween(fill, { BackgroundColor3 = Library._color(color) or Theme.Accent }, 0.25)
    end
    -- The percentage's colour; nil goes back to the accent.
    function self_:SetTextColor(color)
        tween(valueLabel, { TextColor3 = Library._color(color) or Theme.Accent }, 0.25)
    end
    -- Runs render now, and again on a theme change for theme tags in Format.
    onTheme(valueLabel, function()
        render(0)
    end)
    return finishElement(self, opts, self_, frame, "Progress")
end

-- An always-open list the player puts in order: drag a row (by its grip on
-- touch, anywhere on PC) or nudge it with the arrows. Past MaxRows the list
-- scrolls, and dragging near its top or bottom edge scrolls it along.
function Tab:OrderList(opts)
    opts = normalize(opts, { Title = "Name", Description = "Desc", Options = "Items", Values = "Items" })
    local metrics = metricsOf(self)
    local compact = metrics.Compact
    local window = self.Window
    local ROW = TOUCH and 40 or 32
    local GAP = 4
    local STEP = ROW + GAP
    local GRIP = TOUCH and 34 or 26
    local ARROW = TOUCH and 30 or 22
    local maxRows = math.max(math.floor(tonumber(opts.MaxRows) or 6), 1)
    local numbered = opts.Numbered ~= false
    local arrows = opts.Arrows ~= false

    local frame = card(self, "Frame", 0, opts)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    if compact then
        padding(frame, 14, 14, 6, 8)
    else
        padding(frame, 14, 14, 11, 12)
    end
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = frame,
    })
    local name = tostring(opts.Name or "")
    label({
        Size = UDim2.new(1, 0, 0, 18),
        Text = name,
        TextSize = metrics.TextSize,
        Visible = name ~= "",
        LayoutOrder = 1,
        Parent = frame,
    })
    if opts.Desc then
        label({
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = opts.Desc,
            TextSize = metrics.DescSize,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            LayoutOrder = 2,
            Parent = frame,
        })
    end
    local scroller = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, ROW + 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = TOUCH and 4 or 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        -- Sized by hand, like the dropdown list, so it scrolls under UIScale.
        CanvasSize = UDim2.new(),
        ScrollingEnabled = false,
        LayoutOrder = 3,
        Parent = frame,
    })
    scroller:SetAttribute("NoDrag", true)
    local content = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = scroller,
    })
    local empty = label({
        Size = UDim2.new(1, 0, 0, ROW),
        Text = tostring(opts.EmptyText or "Nothing to order"),
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        Visible = false,
        Parent = content,
    })

    -- A lucide icon, or a text glyph when the icon set didn't load.
    local function iconButton(parent, icon, glyph, rotation, props)
        props.BackgroundTransparency = 1
        props.Text = ""
        props.AutoButtonColor = false
        props.Parent = parent
        local button = create("TextButton", props)
        local image = create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = TOUCH and UDim2.fromOffset(16, 16) or UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            ImageColor3 = Theme.Muted,
            ScaleType = Enum.ScaleType.Fit,
            Parent = button,
        })
        applyIcon(image, icon)
        if image.Image ~= "" then
            return button, { Object = image, Color = "ImageColor3", Fade = "ImageTransparency" }
        end
        image:Destroy()
        local text_ = label({
            Size = UDim2.fromScale(1, 1),
            Text = glyph,
            TextSize = 18,
            TextColor3 = Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.None,
            Rotation = rotation,
            Parent = button,
        })
        return button, { Object = text_, Color = "TextColor3", Fade = "TextTransparency" }
    end
    local function tint(icon, color, transparency, duration)
        tween(icon.Object, { [icon.Color] = color, [icon.Fade] = transparency }, duration)
    end

    local self_ = {}
    local entries = {}
    -- The last order Set asked for, including items not in the list right now,
    -- so a saved order still applies once Refresh brings those items in.
    local remembered = {}
    local dragging = nil
    local nudge, beginDrag

    local function slotY(slot)
        return 1 + (slot - 1) * STEP
    end

    local function values()
        local list = {}
        for index, entry in ipairs(entries) do
            list[index] = entry.Value
        end
        return list
    end

    local function layout(instant)
        local count = #entries
        for slot, entry in ipairs(entries) do
            entry.Index.Text = tostring(slot)
            if entry ~= dragging then
                tween(entry.Frame, { Position = UDim2.fromOffset(3, slotY(slot)) }, instant and 0 or 0.22, Enum.EasingStyle.Quint)
            end
            if entry.UpIcon then
                tween(entry.UpIcon.Object, { [entry.UpIcon.Fade] = slot == 1 and 0.7 or 0 }, instant and 0 or 0.15)
                tween(entry.DownIcon.Object, { [entry.DownIcon.Fade] = slot == count and 0.7 or 0 }, instant and 0 or 0.15)
            end
        end
    end

    local function fit()
        local count = #entries
        local canvas = math.max(count, 1) * STEP - GAP + 2
        local shown = math.clamp(count, 1, maxRows)
        local height = shown * STEP - GAP + 2
        local scrolling = count > maxRows
        scroller.Size = UDim2.new(1, 0, 0, height)
        scroller.CanvasSize = UDim2.fromOffset(0, canvas)
        content.Size = UDim2.new(1, scrolling and -8 or 0, 0, canvas)
        if not dragging then
            scroller.ScrollingEnabled = scrolling
        end
        empty.Visible = count == 0
        local maxScroll = math.max(canvas - height, 0)
        if scroller.CanvasPosition.Y > maxScroll then
            scroller.CanvasPosition = Vector2.new(0, maxScroll)
        end
    end

    local function changed(silent)
        self_.Value = values()
        if not silent then
            safeCall(opts.Callback, values())
        end
    end

    local function listScroller()
        if scroller.ScrollingEnabled then
            return scroller
        end
        return frame:FindFirstAncestorWhichIsA("ScrollingFrame")
    end

    local function newEntry(value)
        local row = create("Frame", {
            Size = UDim2.new(1, -6, 0, ROW),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            Parent = content,
        })
        corner(row, UDim.new(0, 7))
        local entry = { Value = value, Frame = row }
        entry.Stroke = stroke(row)
        entry.Scale = create("UIScale", { Parent = row })
        local grip
        grip, entry.GripIcon = iconButton(row, "grip-vertical", "=", 0, {
            Size = UDim2.new(0, GRIP, 1, 0),
        })
        local x = GRIP
        entry.Index = label({
            Position = UDim2.fromOffset(x, 0),
            Size = UDim2.new(0, 22, 1, 0),
            TextSize = 12,
            TextColor3 = Theme.Accent,
            TextTruncate = Enum.TextTruncate.None,
            Visible = numbered,
            Parent = row,
        })
        if numbered then
            x += 22
        end
        local right = arrows and ARROW * 2 + 8 or 10
        entry.Text = label({
            Position = UDim2.fromOffset(x, 0),
            Size = UDim2.new(1, -(x + right), 1, 0),
            Text = tostring(value),
            TextSize = 13,
            Parent = row,
        })
        local buttons = {}
        if arrows then
            local up, down
            up, entry.UpIcon = iconButton(row, "chevron-up", "›", -90, {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -(ARROW + 6), 0, 0),
                Size = UDim2.new(0, ARROW, 1, 0),
            })
            down, entry.DownIcon = iconButton(row, "chevron-down", "›", 90, {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -4, 0, 0),
                Size = UDim2.new(0, ARROW, 1, 0),
            })
            for button, direction in pairs({ [up] = -1, [down] = 1 }) do
                local icon = direction < 0 and entry.UpIcon or entry.DownIcon
                local isTap = tapGuard(button, listScroller)
                button.MouseEnter:Connect(function()
                    if not usingTouch() then
                        tween(icon.Object, { [icon.Color] = Theme.Accent }, 0.12)
                    end
                end)
                button.MouseLeave:Connect(function()
                    tween(icon.Object, { [icon.Color] = Theme.Muted }, 0.2)
                end)
                button.MouseButton1Click:Connect(function()
                    if isTap() then
                        nudge(entry, direction)
                    end
                end)
                table.insert(buttons, button)
            end
        end
        grip.InputBegan:Connect(function(input)
            if isPress(input) then
                beginDrag(entry)
            end
        end)
        -- On PC the whole row drags; on touch only the grip does, so a swipe
        -- across the rows still scrolls.
        row.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
            end
            local point = pointerPosition()
            for _, button in ipairs(buttons) do
                if pointInside(point, button) then
                    return
                end
            end
            beginDrag(entry)
        end)
        row.MouseEnter:Connect(function()
            if not usingTouch() and entry ~= dragging then
                tween(entry.Stroke, { Color = Theme.StrokeHover }, 0.12)
                tint(entry.GripIcon, Theme.Text, 0, 0.12)
            end
        end)
        row.MouseLeave:Connect(function()
            if entry ~= dragging then
                tween(entry.Stroke, { Color = Theme.Stroke }, 0.25)
                tint(entry.GripIcon, Theme.Muted, 0, 0.25)
            end
        end)
        return entry
    end

    -- Reuses the rows whose item is still in the list, so a reorder slides
    -- rows instead of rebuilding them.
    local function build(list)
        local pool = {}
        for _, entry in ipairs(entries) do
            pool[entry.Value] = pool[entry.Value] or {}
            table.insert(pool[entry.Value], entry)
        end
        local nextEntries = {}
        for index, value in ipairs(list) do
            local bucket = pool[value]
            local entry = bucket and table.remove(bucket, 1)
            if not entry then
                entry = newEntry(value)
                entry.Frame.Position = UDim2.fromOffset(3, slotY(index))
            end
            nextEntries[index] = entry
        end
        for _, bucket in pairs(pool) do
            for _, entry in ipairs(bucket) do
                entry.Frame:Destroy()
            end
        end
        entries = nextEntries
    end

    -- items sorted by where they sit in ranking; the rest keep their order after.
    local function arrange(items, ranking)
        local left = {}
        for _, value in ipairs(items) do
            left[value] = (left[value] or 0) + 1
        end
        local result = {}
        for _, pass in ipairs({ ranking, items }) do
            for _, value in ipairs(pass) do
                if (left[value] or 0) > 0 then
                    left[value] -= 1
                    table.insert(result, value)
                end
            end
        end
        return result
    end

    local function scrollIntoView(slot)
        local top = slotY(slot) - 1
        local view = scroller.AbsoluteWindowSize.Y / window.Scale.Scale
        local y = scroller.CanvasPosition.Y
        if top < y then
            y = top
        elseif top + ROW + 2 > y + view then
            y = top + ROW + 2 - view
        end
        if y ~= scroller.CanvasPosition.Y then
            tween(scroller, { CanvasPosition = Vector2.new(0, math.max(y, 0)) }, 0.2)
        end
    end

    function nudge(entry, direction)
        if dragging then
            return
        end
        local from = table.find(entries, entry)
        local to = from and from + direction
        if not to or to < 1 or to > #entries then
            return
        end
        entries[from], entries[to] = entries[to], entries[from]
        layout(false)
        tween(entry.Stroke, { Color = Theme.Accent }, 0.08)
        task.delay(0.18, function()
            if entry ~= dragging then
                tween(entry.Stroke, { Color = Theme.Stroke }, 0.3)
            end
        end)
        scrollIntoView(to)
        changed(false)
    end

    local grabOffset, lastPointer = 0, nil
    local startEntries, stopRender, lockedPage = nil, nil, nil

    -- Moves the held row under the pointer and slides the others out of its way.
    local function follow(pointer)
        local scale = window.Scale.Scale
        local y = (pointer.Y - grabOffset - scroller.AbsolutePosition.Y) / scale + scroller.CanvasPosition.Y
        y = math.clamp(y, slotY(1), slotY(#entries))
        dragging.Frame.Position = UDim2.fromOffset(3, y)
        local slot = math.clamp(math.floor((y - 1) / STEP + 0.5) + 1, 1, #entries)
        local current = table.find(entries, dragging)
        if current ~= slot then
            table.remove(entries, current)
            table.insert(entries, slot, dragging)
            layout(false)
        end
    end

    -- Holding the row near the list's top or bottom edge scrolls it, faster
    -- the closer the pointer gets.
    local function autoScroll(deltaTime)
        if not dragging or not lastPointer then
            return
        end
        local scale = window.Scale.Scale
        local top = scroller.AbsolutePosition.Y
        local bottom = top + scroller.AbsoluteSize.Y
        local zone = ROW * scale
        local speed = 0
        if lastPointer.Y < top + zone then
            speed = -(top + zone - lastPointer.Y) / zone
        elseif lastPointer.Y > bottom - zone then
            speed = (lastPointer.Y - (bottom - zone)) / zone
        end
        if speed == 0 then
            return
        end
        local maxScroll = math.max(scroller.CanvasSize.Y.Offset - scroller.AbsoluteWindowSize.Y / scale, 0)
        local y = math.clamp(scroller.CanvasPosition.Y + math.clamp(speed, -1.5, 1.5) * 360 * deltaTime, 0, maxScroll)
        if y ~= scroller.CanvasPosition.Y then
            scroller.CanvasPosition = Vector2.new(0, y)
            follow(lastPointer)
        end
    end

    function beginDrag(entry)
        if dragging or #entries < 2 or self_._destroyed then
            return
        end
        dragging = entry
        startEntries = table.clone(entries)
        lastPointer = pointerPosition()
        grabOffset = lastPointer.Y - entry.Frame.AbsolutePosition.Y
        entry.Frame.ZIndex = 5
        tween(entry.Frame, { BackgroundColor3 = Theme.Surface3 }, 0.12)
        tween(entry.Stroke, { Color = Theme.Accent }, 0.12)
        tween(entry.Scale, { Scale = 1.02 }, 0.18, Enum.EasingStyle.Back)
        tint(entry.GripIcon, Theme.Accent, 0, 0.12)
        -- Neither the list nor the page scrolls under the finger while dragging.
        scroller.ScrollingEnabled = false
        local page = frame:FindFirstAncestorWhichIsA("ScrollingFrame")
        if page and page.ScrollingEnabled then
            lockedPage = page
            page.ScrollingEnabled = false
        end
        stopRender = window:_listen("Render", autoScroll)
    end

    local function endDrag(silent)
        local entry = dragging
        if not entry then
            return
        end
        dragging = nil
        lastPointer = nil
        if stopRender then
            stopRender()
            stopRender = nil
        end
        if lockedPage then
            lockedPage.ScrollingEnabled = true
            lockedPage = nil
        end
        tween(entry.Frame, { BackgroundColor3 = Theme.Surface }, 0.2)
        tween(entry.Stroke, { Color = Theme.Stroke }, 0.25)
        tween(entry.Scale, { Scale = 1 }, 0.2)
        tint(entry.GripIcon, Theme.Muted, 0, 0.25)
        task.delay(0.22, function()
            if entry ~= dragging then
                entry.Frame.ZIndex = 1
            end
        end)
        layout(false)
        fit()
        for index, other in ipairs(entries) do
            if startEntries[index] ~= other then
                changed(silent)
                break
            end
        end
    end

    window:_listen("Changed", function(input)
        if dragging and isMove(input) then
            lastPointer = pointerPosition()
            follow(lastPointer)
        end
    end, self_)
    window:_listen("Ended", function(input)
        if dragging and isPress(input) then
            endDrag(false)
        end
    end, self_)
    table.insert(self_._listeners, function()
        endDrag(true)
    end)
    self_._onHide = function()
        endDrag(false)
    end

    -- Reorders the items already in the list. Unknown items are remembered for
    -- a later Refresh; items missing from the list keep their order after.
    function self_:Set(list, silent)
        if type(list) ~= "table" then
            return
        end
        endDrag(true)
        remembered = table.clone(list)
        build(arrange(values(), remembered))
        layout(false)
        fit()
        changed(silent)
    end

    function self_:Get()
        return values()
    end

    -- Replaces the items. Items that were already there keep the player's
    -- order unless keepOrder is false; new ones go to the end.
    function self_:Refresh(items, keepOrder, silent)
        endDrag(true)
        items = type(items) == "table" and table.clone(items) or {}
        if keepOrder ~= false then
            items = arrange(items, self_:_saveValue())
        else
            remembered = {}
        end
        build(items)
        layout(false)
        fit()
        changed(silent)
    end

    -- The shown order, then remembered items that aren't in the list right now.
    function self_:_saveValue()
        local list = values()
        local left = {}
        for _, value in ipairs(list) do
            left[value] = (left[value] or 0) + 1
        end
        for _, value in ipairs(remembered) do
            if (left[value] or 0) > 0 then
                left[value] -= 1
            else
                table.insert(list, value)
            end
        end
        return list
    end

    build(type(opts.Items) == "table" and opts.Items or {})
    layout(true)
    fit()
    self_.Value = values()
    return finishElement(self, opts, self_, frame, "OrderList")
end


for name, method in pairs(table.clone(Tab)) do
    if type(method) == "function" and name:sub(1, 1) ~= "_" and name:sub(1, 6) ~= "Create" then
        Tab["Create" .. name] = method
    end
end

local function detectExecutor()
    local name
    pcall(function()
        if typeof(identifyexecutor) == "function" then
            name = (identifyexecutor())
        elseif typeof(getexecutorname) == "function" then
            name = getexecutorname()
        end
    end)
    if type(name) == "string" and #name > 0 then
        return name
    end
    return RunService:IsStudio() and "Studio" or "Unknown"
end

local function executorReport(opts)
    local executor = detectExecutor()
    local supported = opts.SupportedExecutors
    if type(supported) == "table" then
        local lowered = string.lower(executor)
        for _, name in ipairs(supported) do
            if string.find(lowered, string.lower(tostring(name)), 1, true) then
                return executor, true, "Your executor is supported and fully compatible."
            end
        end
        return executor, false, "Not on the supported list. Some features may not work."
    end
    local capabilities = {
        { "writefile", writefile },
        { "readfile", readfile },
        { "getcustomasset", getcustomasset },
        { "setclipboard", setclipboard or toclipboard },
        { "request", request or http_request or (syn and syn.request) },
    }
    local missing = {}
    for _, entry in ipairs(capabilities) do
        if type(entry[2]) ~= "function" then
            table.insert(missing, entry[1])
        end
    end
    if #missing == 0 then
        return executor, true, "Your executor is supported and fully compatible."
    end
    return executor, false, "Missing " .. table.concat(missing, ", ") .. ". Some features may not work."
end

-- "Don't ask again" on the unsupported executor warning: the executor's
-- name goes in a file in the script folder, and the warning is skipped while
-- the same executor is in use. Resetting the folder brings it back.
-- A table, not separate locals: the main chunk is at Luau's 200 local limit.
local UnsupportedSkip = {}

function UnsupportedSkip.Path(folder)
    return tostring(folder) .. "/unsupported_skip.txt"
end

function UnsupportedSkip.Available()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

function UnsupportedSkip.Saved(folder, executor)
    if not UnsupportedSkip.Available() then
        return false
    end
    local path = UnsupportedSkip.Path(folder)
    local ok, saved = pcall(function()
        return isfile(path) and readfile(path) or nil
    end)
    return ok and saved == executor
end

function UnsupportedSkip.Write(folder, path, content)
    if not UnsupportedSkip.Available() then
        return false
    end
    return pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" then
            local built = ""
            for segment in tostring(folder):gmatch("[^/\\]+") do
                built = built == "" and segment or built .. "/" .. segment
                if not isfolder(built) then
                    makefolder(built)
                end
            end
        end
        writefile(path, content)
    end)
end

function UnsupportedSkip.Save(folder, executor)
    return UnsupportedSkip.Write(folder, UnsupportedSkip.Path(folder), executor)
end

-- Custom disclaimers ticked "Don't show again": one key per line in
-- disclaimers.txt. The key is the disclaimer's Id, or a hash of its title
-- and text, so rewording a disclaimer shows it again.
function UnsupportedSkip.DisclaimerKey(entry)
    if entry.Id ~= nil then
        return (tostring(entry.Id):gsub("[\r\n]", " "))
    end
    local source = tostring(entry.Title) .. "\0" .. tostring(entry.Text)
    local hash = 5381
    for index = 1, #source do
        hash = (hash * 33 + source:byte(index)) % 4294967296
    end
    return string.format("%08x", hash)
end

function UnsupportedSkip.DisclaimerAccepted(folder, key)
    if not UnsupportedSkip.Available() then
        return false
    end
    local path = tostring(folder) .. "/disclaimers.txt"
    local ok, saved = pcall(function()
        return isfile(path) and readfile(path) or ""
    end)
    if not ok or type(saved) ~= "string" then
        return false
    end
    for line in saved:gmatch("[^\r\n]+") do
        if line == key then
            return true
        end
    end
    return false
end

function UnsupportedSkip.AcceptDisclaimer(folder, key)
    if UnsupportedSkip.DisclaimerAccepted(folder, key) then
        return true
    end
    local path = tostring(folder) .. "/disclaimers.txt"
    local ok, saved = pcall(function()
        return isfile(path) and readfile(path) or ""
    end)
    saved = ok and type(saved) == "string" and saved or ""
    if saved ~= "" and not saved:match("\n$") then
        saved ..= "\n"
    end
    return UnsupportedSkip.Write(folder, path, saved .. key .. "\n")
end

local gameInfoCache = nil

local function fetchGameInfo()
    if gameInfoCache == nil then
        local ok, info = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        gameInfoCache = ok and type(info) == "table" and info or false
    end
    return gameInfoCache or nil
end

local function detectGameName()
    local info = fetchGameInfo()
    if info and info.Name then
        return info.Name
    end
    return RunService:IsStudio() and "Studio" or "Unknown game"
end

local REGION_NAMES = {
    US = "United States", GB = "United Kingdom", DE = "Germany", FR = "France",
    NL = "Netherlands", SG = "Singapore", JP = "Japan", AU = "Australia",
    BR = "Brazil", IN = "India", HK = "Hong Kong", CA = "Canada",
}

local function detectRegion(callback)
    task.spawn(function()
        local requester = request or http_request or (syn and syn.request) or (http and http.request)
        local region
        if type(requester) == "function" then
            pcall(function()
                local response = requester({ Url = "https://ipinfo.io/json", Method = "GET" })
                local body = type(response) == "table" and (response.Body or response.body) or nil
                if type(body) == "string" then
                    local data = HttpService:JSONDecode(body)
                    if type(data) == "table" and data.country then
                        local label = REGION_NAMES[data.country] or data.country
                        region = data.city and (data.city .. ", " .. label) or label
                    end
                end
            end)
        end
        callback(region or "Unavailable")
    end)
end

local NOTIFY_COLORS = setmetatable({}, {
    __index = function(_, kind)
        if kind == "Success" or kind == "Warning" or kind == "Error" then
            return Theme[kind]
        end
        return nil
    end,
})

local Window = {}
Window.__index = Window

function Library.Window(_, opts)
    opts = normalize(opts, { Name = "Title", LoadingSubtitle = "Subtitle", ToggleUIKeybind = "Keybind" })

    if type(opts.Keybind) == "string" then
        opts.Keybind = Enum.KeyCode[opts.Keybind]
    end
    local size = opts.Size or UDim2.fromOffset(760, 520)
    local keybind = opts.Keybind or Enum.KeyCode.RightControl

    local self = setmetatable({
        Tabs = {},
        CurrentTab = nil,
        Open = true,
        Keybind = keybind,
        _connections = {},
        _controls = {},
        _inputListeners = { Began = {}, Changed = {}, Ended = {}, Render = {} },
        _frameSteps = {},
        _destroyed = false,
        _identity = { Names = {}, Avatars = {} },
        _pinned = {},
        Minimized = false,
        _hideName = false,
        _hideAvatar = false,
        Title = opts.Title or "Airflow",
        _logoIcon = opts.Icon or Assets.Logo,
        _sessionStart = os.clock(),
        _islandLocked = opts.IslandDraggable == false,
    }, Window)
    local saving = type(opts.ConfigurationSaving) == "table" and opts.ConfigurationSaving or {}
    self.ConfigFolder = saving.FolderName or "AirflowUI"
    self.ConfigName = saving.FileName
    self._configListeners = {}
    self._pendingFlags = {}

    local startTheme = opts.DefaultTheme or opts.Theme
    if startTheme ~= nil then
        Library.DefaultTheme = startTheme
    end
    self:_applyDefaultTheme()
    self._uiScale = math.clamp(tonumber(opts.UIScale) or 1, 0.6, 1.5)
    self._adaptive = opts.AdaptiveSize ~= false
    self.UIScale = self._uiScale
    if opts.Density ~= nil then
        Library:SetDensity(opts.Density)
    end
    if opts.CornerRadius ~= nil then
        Library:SetCornerRadius(opts.CornerRadius, true)
    end
    local function dispatch(kind)
        return function(...)
            for _, handler in ipairs(self._inputListeners[kind]) do
                handler(...)
            end
        end
    end
    local renderDispatch = dispatch("Render")
    table.insert(self._connections, RunService.RenderStepped:Connect(function(deltaTime)
        renderDispatch(deltaTime)
        for _, step in ipairs(self._frameSteps) do
            step(deltaTime)
        end
    end))
    table.insert(self._connections, UserInputService.InputBegan:Connect(dispatch("Began")))
    table.insert(self._connections, UserInputService.InputChanged:Connect(dispatch("Changed")))
    table.insert(self._connections, UserInputService.InputEnded:Connect(dispatch("Ended")))

    local gui = create("ScreenGui", {
        Name = opts.Name or "AirflowUI",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        DisplayOrder = 999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    self.Gui = gui

    local root = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        BackgroundTransparency = 1,
        Parent = gui,
    })
    self.Root = root
    local scale = create("UIScale", { Parent = root })
    self.Scale = scale

    local shadow = create("ImageLabel", {
        Position = UDim2.fromOffset(-25, -25),
        Size = UDim2.new(1, 50, 1, 50),
        BackgroundTransparency = 1,
        Image = Assets.Shadow,
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Parent = root,
    })
    self.Shadow = shadow
    self._shadowRest = 0.6

    -- The body is a plain Frame so resizing never re-renders the window into a
    -- texture. It only moves into the fader CanvasGroup while fading.
    local fader = create("CanvasGroup", {
        Name = "Fader",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        ZIndex = 2,
        Parent = root,
    })
    self._fader = fader
    self._bodyAlpha = 1
    local body = create("Frame", {
        Name = "Body",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2,
        Parent = fader,
    })
    self.Body = body
    corner(body, UDim.new(0, 10))
    self.BodyStroke = stroke(body, Theme.Stroke)
    edgeHighlight(body)
    -- Background image: made first so everything else in the body draws over it.
    self._backgroundImage = create("ImageLabel", {
        Name = "BackgroundImage",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Crop,
        ImageTransparency = 1,
        Visible = false,
        ZIndex = 0,
        Parent = body,
    })
    corner(self._backgroundImage, UDim.new(0, 10))
    self.BackgroundTransparency = math.clamp(tonumber(opts.BackgroundTransparency) or 0.35, 0, 1)
    self._backgroundGeneration = 0

    -- The sidebar is a flush, solid rail down the left edge, split from the
    -- content by a single hairline.
    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = body,
    })
    self.Sidebar = sidebar
    -- One rounded fill that runs past the rail's right edge, where the rail
    -- clips it: the left corners round with the window, the right edge is
    -- square, and nothing overlaps, so it fades evenly when see-through.
    local sidebarFill = create("Frame", {
        Name = "Fill",
        Size = UDim2.new(1, 24, 1, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = sidebar,
    })
    corner(sidebarFill, UDim.new(0, 10))
    self.SidebarFill = sidebarFill
    create("Frame", {
        Name = "Divider",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = sidebar,
    })

    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })
    local logo = create("ImageLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.fromOffset(32, 32),
        BackgroundTransparency = 1,
        Image = "",
        ImageColor3 = Theme.Accent,
        ScaleType = Enum.ScaleType.Fit,
        Parent = header,
    })
    applyIcon(logo, opts.Icon or Assets.Logo, true)
    local subtitle = opts.Version or opts.Subtitle
    label({
        Position = UDim2.new(0, 56, 0.5, subtitle and -15 or -9),
        Size = UDim2.new(1, -68, 0, 18),
        Text = self.Title,
        TextSize = 14,
        FontFace = Fonts.Bold,
        Parent = header,
    })
    if subtitle then
        label({
            Position = UDim2.new(0, 56, 0.5, 3),
            Size = UDim2.new(1, -68, 0, 14),
            Text = tostring(subtitle),
            TextSize = 11,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            Parent = header,
        })
    end

    local profileEnabled = opts.Profile ~= false
    local tabList = create("ScrollingFrame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(0, HEADER_HEIGHT),
        Size = UDim2.new(1, 0, 1, -(HEADER_HEIGHT + (profileEnabled and PROFILE_HEIGHT + 4 or 12))),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Parent = sidebar,
    })
    self.TabList = tabList
    -- The highlight sits beside the stack of buttons, so it scrolls and clips
    -- with them and glides between tiles.
    local indicator = create("Frame", {
        Position = UDim2.fromOffset(8, 2),
        Size = UDim2.new(1, -16, 0, TAB_TILE_HEIGHT),
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Visible = false,
        Parent = tabList,
    })
    corner(indicator, UDim.new(0, 7))
    -- The active tab is just a quiet neutral fill with white text; the bar
    -- is kept for callers but stays hidden.
    local pill = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(2, 14),
        BackgroundColor3 = Theme.Accent,
        Visible = false,
        BorderSizePixel = 0,
        Parent = indicator,
    })
    corner(pill, UDim.new(1, 0))
    self._indicatorPill = pill
    self.Indicator = indicator
    local stack = create("Frame", {
        Name = "Stack",
        Position = UDim2.fromOffset(8, 2),
        Size = UDim2.new(1, -16, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = tabList,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = stack,
    })
    self._tabStack = stack

    -- More tabs than fit: a fade and a small "more" chip at the hidden end.
    self:_overflowHint(sidebar, tabList, stack, true, Theme.Surface)

    if profileEnabled then
        self:_buildProfile(sidebar)
    end

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(SIDEBAR_WIDTH + 1, 0),
        Size = UDim2.new(1, -(SIDEBAR_WIDTH + 1), 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = body,
    })
    self.Content = content
    self:_sidebarResize(sidebar, tonumber(opts.SidebarWidth) or SIDEBAR_WIDTH)
    self._outLayer = create("CanvasGroup", {
        Name = "TransitionOut",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 2,
        Parent = content,
    })
    self._inLayer = create("CanvasGroup", {
        Name = "TransitionIn",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 3,
        Parent = content,
    })

    local minimizeButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = content,
    })
    minimizeButton:SetAttribute("NoDrag", true)
    -- A bare "minimize" arrows glyph, no box: muted at rest, full text
    -- colour and a touch smaller on hover, as if pulling in.
    local minimizeGlyph = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Muted,
        ScaleType = Enum.ScaleType.Fit,
        Parent = minimizeButton,
    })
    applyIcon(minimizeGlyph, "minimize-2")
    minimizeButton.MouseEnter:Connect(function()
        tween(minimizeGlyph, { ImageColor3 = Theme.Text, Size = UDim2.fromOffset(18, 18) }, 0.2, Enum.EasingStyle.Quint)
    end)
    minimizeButton.MouseLeave:Connect(function()
        tween(minimizeGlyph, { ImageColor3 = Theme.Muted, Size = UDim2.fromOffset(20, 20) }, 0.25, Enum.EasingStyle.Quint)
    end)
    minimizeButton.MouseButton1Click:Connect(function()
        self:Minimize()
    end)
    self.MinimizeButton = minimizeButton

    if opts.Search ~= false then
        self:_buildSearch(content)
    end

    local notifyHolder = create("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 280, 1, -40),
        BackgroundTransparency = 1,
        Parent = gui,
    })
    local function fitToasts()
        notifyHolder.Size = UDim2.new(0, math.min(280, gui.AbsoluteSize.X - 40), 1, -40)
    end
    table.insert(self._connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitToasts))
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 4),
        Parent = notifyHolder,
    })
    self.NotifyHolder = notifyHolder
    self._notifyOrder = 0
    self._toasts = {}
    self.MaxNotifications = opts.MaxNotifications or 4

    self._controlsDirty = true
    table.insert(self._connections, body.DescendantAdded:Connect(function()
        self._controlsDirty = true
    end))
    table.insert(self._connections, body.DescendantRemoving:Connect(function()
        self._controlsDirty = true
    end))

    self:SetDragStyle(opts.DragStyle or (opts.DragSkeleton == false and "Off" or "Outline"))
    self:SetIslandStyle(opts.IslandStyle)
    if opts.Transparent then
        self:SetTransparent(true)
    end
    if opts.Background then
        task.spawn(self.SetBackground, self, opts.Background)
    end
    self:_enableDrag()
    self.MaxSize = opts.MaxSize
    self.KeepOnScreen = opts.KeepOnScreen ~= false
    self:_enableResize(opts.MinSize or Vector2.new(480, 360))
    -- The window's exact size rides along in configs as a hidden flag.
    if opts.SaveSize ~= false then
        local window = self
        local sizeFlag = { _type = "WindowSize", _listeners = {} }
        function sizeFlag:Get()
            local current = window:GetSize()
            return { Width = current.X, Height = current.Y }
        end
        function sizeFlag:Set(value)
            if type(value) == "table" and tonumber(value.Width) and tonumber(value.Height) then
                window:SetSize(Vector2.new(tonumber(value.Width), tonumber(value.Height)))
            end
        end
        local flag = type(opts.SaveSize) == "string" and opts.SaveSize or "__WindowSize"
        Library.Flags[flag] = sizeFlag
        self:_flagCreated(flag, sizeFlag)
    end

    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self.Keybind then
            task.defer(function()
                local consumed = self._consumedKey == input.KeyCode and os.clock() - (self._consumedAt or 0) < 0.2
                self._consumedKey = nil
                if not consumed and not self._destroyed then
                    if self.Minimized then
                        self:Restore()
                    else
                        self:Toggle(not self.Open)
                    end
                end
            end)
        end
    end))

    pcall(function()
        if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
            syn.protect_gui(gui)
        end
    end)
    gui.Parent = opts.Parent or defaultParent()

    scale.Scale = 0.9
    shadow.ImageTransparency = 1
    self.BodyStroke.Transparency = 1
    root.Visible = false
    self:_fitToScreen(true)
    table.insert(self._connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:_fitToScreen()
        self:_clampToScreen()
    end))
    local toggleOpts = opts.ToggleButton
    if toggleOpts == nil or toggleOpts == true then
        toggleOpts = {}
    end
    if type(toggleOpts) == "table" then
        self:_createToggleButton(toggleOpts)
    end
    -- The toggle button already brings a hidden window back.
    local toggleShown = self.ToggleButton ~= nil and self:_toggleButtonAllowed()
    if (opts.OpenButton ~= nil and opts.OpenButton ~= false) or (opts.OpenButton == nil and TOUCH and not toggleShown) then
        self:_createOpenButton(type(opts.OpenButton) == "table" and opts.OpenButton or {})
    end
    if opts.Backdrop ~= false then
        self:_buildBackdrop(type(opts.Backdrop) == "table" and opts.Backdrop or {})
    end
    self._introDone = false

    table.insert(Library.Windows, self)

    if opts.Home ~= false then
        self:_buildHome(type(opts.Home) == "table" and opts.Home or {})
    end

    local loading = opts.Loading
    if type(loading) == "table" then
        opts.LoadingDuration = loading.Duration or opts.LoadingDuration
        opts.LoadingText = loading.Text or loading.Subtitle or opts.LoadingText
        opts.LoadingSteps = loading.Steps or opts.LoadingSteps
        opts.LoadingTitle = loading.Title or opts.LoadingTitle
        loading = loading.Enabled ~= false
    end
    -- An executor off the supported list (or missing the file / asset API)
    -- stops at a warning card before the window opens.
    local prompts = {}
    local gate = opts.UnsupportedExecutor
    if gate ~= false then
        gate = type(gate) == "table" and gate or {}
        local list = opts.SupportedExecutors or (type(opts.Home) == "table" and opts.Home.SupportedExecutors or nil)
        local executor, supported, message = executorReport({ SupportedExecutors = list })
        if not supported and not UnsupportedSkip.Saved(self.ConfigFolder, executor) then
            local block = gate.Block == true
            local folder = self.ConfigFolder
            table.insert(prompts, {
                Title = gate.Title or "Unsupported executor",
                Subtitle = executor,
                Text = block and ((gate.Text or message) .. " This script can't run here.") or (gate.Text or message),
                Icon = "shield-alert",
                Color = Theme.Warning,
                ContinueText = "Continue anyway",
                ExitText = "Exit",
                Block = block,
                RememberText = "Don't ask again on this executor",
                Remember = function()
                    UnsupportedSkip.Save(folder, executor)
                end,
            })
        end
    end
    -- Custom disclaimers queue up after the executor warning, in order. Each
    -- one must be accepted (or skipped by an earlier "Don't show again").
    local disclaimers = opts.Disclaimer or opts.Disclaimers
    if type(disclaimers) == "string" or (type(disclaimers) == "table" and (disclaimers.Title ~= nil or disclaimers.Text ~= nil)) then
        disclaimers = { disclaimers }
    end
    if type(disclaimers) == "table" then
        for _, entry in ipairs(disclaimers) do
            if type(entry) == "string" then
                entry = { Text = entry }
            end
            if type(entry) == "table" then
                local key = UnsupportedSkip.DisclaimerKey(entry)
                local folder = self.ConfigFolder
                local block = entry.Block == true
                local rememberable = entry.Remember ~= false and not block
                if not (rememberable and UnsupportedSkip.DisclaimerAccepted(folder, key)) then
                    local callback = entry.Callback
                    table.insert(prompts, {
                        Title = entry.Title or "Disclaimer",
                        Subtitle = entry.Subtitle,
                        Text = entry.Text or "",
                        Icon = entry.Icon or "info",
                        Color = entry.Color or Theme.Accent,
                        ContinueText = entry.AcceptText or "I understand",
                        ExitText = entry.DeclineText == nil and "Exit" or entry.DeclineText,
                        RememberText = rememberable and (entry.RememberText or "Don't show again") or nil,
                        Remember = function()
                            UnsupportedSkip.AcceptDisclaimer(folder, key)
                        end,
                        Callback = type(callback) == "function" and callback or nil,
                        Block = block,
                    })
                end
            end
        end
    end
    if #prompts > 0 then
        opts._prompts = prompts
    end
    if loading == false and opts._prompts then
        opts.LoadingDuration = opts.LoadingDuration or 0.5
        loading = true
    end
    if loading == false then
        task.defer(function()
            self:_playIntro()
        end)
    else
        self:_showLoader(opts)
    end
    return self
end

Library.CreateWindow = Library.Window



function Library:Notify(opts)
    local window = Library.Windows[#Library.Windows]
    if window then
        return window:Notify(opts)
    end
end

function Library:Confirm(opts)
    local window = Library.Windows[#Library.Windows]
    if window then
        return window:Confirm(opts)
    end
end

function Library:Dialog(opts)
    local window = Library.Windows[#Library.Windows]
    if window then
        return window:Dialog(opts)
    end
end

local function isShown(object, stopAt, point)
    local child = object
    while child and child ~= stopAt and child:IsA("GuiObject") do
        if not child.Visible then
            return false
        end
        local parent = child.Parent
        if parent and parent ~= stopAt and parent:IsA("GuiObject") and (parent.ClipsDescendants or parent:IsA("ScrollingFrame")) and not pointInside(point, parent) then
            return false
        end
        child = parent
    end
    return true
end

function Window:_refreshControls()
    local controls = {}
    for _, object in ipairs(self.Body:GetDescendants()) do
        if object:IsA("GuiButton") or object:IsA("TextBox") or object:GetAttribute("NoDrag") then
            table.insert(controls, object)
        end
    end
    self._controls = controls
    self._controlsDirty = false
end

function Window:_overControl(point)
    if self._dialog or self:_overPopout(point) then
        return true
    end
    if self._controlsDirty then
        self:_refreshControls()
    end
    for _, object in ipairs(self._controls) do
        if object.Parent and pointInside(point, object) and isShown(object, self.Body, point) then
            return true
        end
    end
    return false
end

-- Tooltips: one shared card per window that follows the pointer over any
-- element built with Tooltip = "..." or { Title, Text, Icon }. It appears
-- after a short hover (straight away when moving from one tooltip to the
-- next), hides on press, and shows on a long press on touch screens.
function Window:_tooltipCard()
    if self._tip then
        return self._tip
    end
    local holder = create("CanvasGroup", {
        Name = "Tooltip",
        Size = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        Visible = false,
        ZIndex = 60,
        Parent = self.Gui,
    })
    local tipScale = create("UIScale", { Parent = holder })
    -- Bare text, no card: a dark outline keeps it readable over anything.
    -- The holder is sized from the text by hand, since scale sizes inside an
    -- automatic size would stretch it across the screen.
    local PAD = 4
    local panel = create("Frame", {
        Position = UDim2.fromOffset(PAD, PAD),
        Size = UDim2.fromOffset(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Parent = holder,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = panel,
    })
    local function outline(object)
        create("UIStroke", {
            Color = Color3.new(0, 0, 0),
            Transparency = 0.35,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            Parent = object,
        })
    end
    local head = create("Frame", {
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = panel,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = head,
    })
    local icon = create("ImageLabel", {
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Accent,
        ScaleType = Enum.ScaleType.Fit,
        LayoutOrder = 1,
        Parent = head,
    })
    local title = label({
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 13,
        FontFace = Fonts.Bold,
        TextTruncate = Enum.TextTruncate.None,
        LayoutOrder = 2,
        Parent = head,
    })
    outline(title)
    local body = label({
        Size = UDim2.fromOffset(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 12,
        FontFace = Fonts.Medium,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        TextYAlignment = Enum.TextYAlignment.Top,
        LineHeight = 1.1,
        LayoutOrder = 2,
        Parent = panel,
    })
    outline(body)
    create("UISizeConstraint", { MaxSize = Vector2.new(240, math.huge), Parent = body })
    local function fit()
        local scale = math.max(tipScale.Scale, 0.01)
        local size = panel.AbsoluteSize / scale
        holder.Size = UDim2.fromOffset(size.X + PAD * 2, size.Y + PAD * 2)
    end
    panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    local tip = {
        Holder = holder,
        Scale = tipScale,
        Pad = PAD,
        Head = head,
        Icon = icon,
        Title = title,
        Body = body,
        Shown = false,
        Fit = fit,
    }
    self._tip = tip
    -- Follow the pointer, and drop the card once its element is gone or off
    -- screen (tab switched, window hidden or minimized).
    self:_listen("Render", function(deltaTime)
        local owner = self._tipOwner
        if not owner then
            return
        end
        local frame = owner._frame
        if owner._destroyed or not self.Open or self.Minimized or not frame or not frame.Parent
            or (owner._isShown and not owner:_isShown()) or not isShown(frame, self.Body, frame.AbsolutePosition + frame.AbsoluteSize / 2) then
            self:_hideTooltip()
            return
        end
        local pointer = pointerPosition() - self.Gui.AbsolutePosition
        local pad = tip.Pad * tipScale.Scale
        local size = holder.AbsoluteSize - Vector2.one * pad * 2
        local view = self.Gui.AbsoluteSize
        local x, y
        if tip.Touch then
            x, y = pointer.X - size.X / 2, pointer.Y - size.Y - 30
        else
            x, y = pointer.X + 14, pointer.Y + 20
            if x + size.X > view.X - 8 then
                x = pointer.X - size.X - 10
            end
            if y + size.Y > view.Y - 8 then
                y = pointer.Y - size.Y - 12
            end
        end
        local target = Vector2.new(
            math.clamp(x, 8, math.max(8, view.X - size.X - 8)),
            math.clamp(y, 8, math.max(8, view.Y - size.Y - 8))
        )
        local current = tip.Position
        if not current or tip.Snap then
            -- Rises a few pixels into place as it fades in.
            current = target + Vector2.new(0, 6)
            tip.Snap = false
        else
            current = current:Lerp(target, math.min(deltaTime * 22, 1))
        end
        tip.Position = current
        holder.Position = UDim2.fromOffset(math.floor(current.X - pad + 0.5), math.floor(current.Y - pad + 0.5))
    end)
    -- A press anywhere (a dropdown chip inside the card, a key) hides it.
    self:_listen("Began", function(input)
        if self._tipOwner and not tip.Touch and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Keyboard) then
            self:_hideTooltip()
        end
    end)
    return tip
end

function Window:_showTooltip(element, touch)
    local value = element._tooltip
    local text, titleText, iconName
    if type(value) == "table" then
        text, titleText, iconName = value.Text or value.Content or value.Desc, value.Title or value.Name, value.Icon
    elseif value ~= nil and value ~= false then
        text = tostring(value)
    end
    if (text == nil or text == "") and (titleText == nil or titleText == "") then
        return
    end
    local tip = self:_tooltipCard()
    tip.Title.Text = titleText or ""
    tip.Title.Visible = titleText ~= nil and titleText ~= ""
    tip.Icon.Visible = iconName ~= nil
    if iconName ~= nil then
        applyIcon(tip.Icon, iconName)
    end
    tip.Head.Visible = tip.Title.Visible or iconName ~= nil
    tip.Body.Text = text or ""
    tip.Body.Visible = text ~= nil and text ~= ""
    tip.Fit()
    tip.Body.TextColor3 = Theme.Text
    tip.Scale.Scale = math.max(self.Scale.Scale, 0.75)
    tip.Touch = touch == true
    local wasShown = tip.Shown
    self._tipOwner = element
    tip.Shown = true
    tip.Generation = (tip.Generation or 0) + 1
    local holder = tip.Holder
    if not wasShown then
        tip.Snap = true
        holder.Visible = true
        holder.GroupTransparency = 1
        tip.Scale.Scale = tip.Scale.Scale * 0.96
    end
    tween(holder, { GroupTransparency = 0 }, 0.14, Enum.EasingStyle.Quad)
    tween(tip.Scale, { Scale = math.max(self.Scale.Scale, 0.75) }, 0.18, Enum.EasingStyle.Back)
end

function Window:_hideTooltip(element)
    local tip = self._tip
    if not tip or not tip.Shown or (element and self._tipOwner ~= element) then
        return
    end
    self._tipOwner = nil
    self._tipHiddenAt = os.clock()
    tip.Shown = false
    tip.Generation = (tip.Generation or 0) + 1
    local generation = tip.Generation
    tween(tip.Holder, { GroupTransparency = 1 }, 0.1, Enum.EasingStyle.Quad)
    task.delay(0.1, function()
        if tip.Generation == generation then
            tip.Holder.Visible = false
        end
    end)
end

function Window:_attachTooltip(element, frame)
    local hovering, token, pressAt = false, 0, nil
    local function begin(delay, touch)
        token += 1
        local mine = token
        task.delay(delay, function()
            if token ~= mine or not hovering or element._destroyed or self._destroyed then
                return
            end
            -- A finger that moved was scrolling, not holding.
            if touch and pressAt and (pointerPosition() - pressAt).Magnitude > 10 then
                return
            end
            self:_showTooltip(element, touch)
        end)
    end
    table.insert(element._listeners, (function()
        local connections = {
            frame.MouseEnter:Connect(function()
                if usingTouch() then
                    return
                end
                hovering = true
                local recent = os.clock() - (self._tipHiddenAt or 0) < 0.35 or self._tipOwner ~= nil
                begin(recent and 0 or 0.45, false)
            end),
            frame.MouseLeave:Connect(function()
                hovering = false
                token += 1
                self:_hideTooltip(element)
            end),
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    hovering = true
                    pressAt = pointerPosition()
                    begin(0.5, true)
                end
            end),
            frame.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    hovering = false
                    token += 1
                    self:_hideTooltip(element)
                end
            end),
        }
        return function()
            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end
        end
    end)())
end

-- While dragging, a stand-in follows the pointer while the window stays put,
-- and the window glides into its spot on release. The look is the player's
-- Drag Style; "Off" drags the window itself.
Library.DragStyles = { "Outline", "Brackets", "Ghost", "Frame", "Off" }

local function makeSkeleton(window)
    local root = window.Root
    local style = window.DragStyle or "Outline"
    local skeleton = create("Frame", {
        AnchorPoint = root.AnchorPoint,
        Position = root.Position,
        Size = UDim2.fromOffset(root.AbsoluteSize.X, root.AbsoluteSize.Y),
        BackgroundColor3 = style == "Ghost" and Theme.Background or Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 40,
        Parent = window.Gui,
    })
    corner(skeleton, UDim.new(0, 10))
    -- Each part fades from hidden to its shown values, and back on release.
    local parts = {}
    local function part(object, shown)
        local hidden = {}
        for key in pairs(shown) do
            hidden[key] = 1
        end
        table.insert(parts, { Object = object, Shown = shown, Hidden = hidden })
    end
    local function brackets(length, inset)
        for _, spot in ipairs({ Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) }) do
            local at = UDim2.new(spot.X, spot.X == 0 and inset or -inset, spot.Y, spot.Y == 0 and inset or -inset)
            for _, size in ipairs({ UDim2.fromOffset(length, 2), UDim2.fromOffset(2, length) }) do
                local bracket = create("Frame", {
                    AnchorPoint = spot,
                    Position = at,
                    Size = size,
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Parent = skeleton,
                })
                corner(bracket, UDim.new(1, 0))
                part(bracket, { BackgroundTransparency = 0 })
            end
        end
    end
    if style == "Brackets" then
        -- Just the four corners of the window, a little longer.
        brackets(22, 0)
    elseif style == "Ghost" then
        -- A see-through copy of the window's panel.
        part(skeleton, { BackgroundTransparency = 0.35 })
        part(stroke(skeleton, Theme.Stroke, 1, 1), { Transparency = 0 })
    elseif style == "Frame" then
        -- A single quiet line, nothing else.
        part(stroke(skeleton, Theme.StrokeHover, 1, 1), { Transparency = 0 })
    else
        -- Outline: a faint accent wash, an outline and corner brackets.
        part(skeleton, { BackgroundTransparency = 0.92 })
        part(stroke(skeleton, Theme.Accent, 1, 1.5), { Transparency = 0.2 })
        brackets(16, 6)
    end
    local scale = create("UIScale", { Scale = 1.02, Parent = skeleton })
    for _, item in ipairs(parts) do
        tween(item.Object, item.Shown, 0.15, Enum.EasingStyle.Quad)
    end
    tween(scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Quint)
    local function fade()
        for _, item in ipairs(parts) do
            tween(item.Object, item.Hidden, 0.2, Enum.EasingStyle.Quad)
        end
        task.delay(0.22, function()
            skeleton:Destroy()
        end)
    end
    return skeleton, fade
end

function Window:_enableDrag()
    local dragging, moved = false, false
    local grabOffset, pressPoint = Vector2.zero, Vector2.zero
    local target = nil
    local skeleton, fadeSkeleton = nil, nil

    local function centre()
        local root = self.Root
        return root.AbsolutePosition + root.AbsoluteSize * root.AnchorPoint - self.Gui.AbsolutePosition
    end

    local function dropSkeleton()
        if not skeleton then
            return
        end
        local spot = Vector2.new(skeleton.Position.X.Offset, skeleton.Position.Y.Offset)
        if self.KeepOnScreen then
            spot = self:_clampedCentre(spot)
        end
        if self._clampTween then
            self._clampTween:Cancel()
        end
        self._clampTween = tween(self.Root, { Position = UDim2.fromOffset(spot.X, spot.Y) }, 0.3, Enum.EasingStyle.Quint)
        fadeSkeleton()
        skeleton, fadeSkeleton = nil, nil
    end

    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input)
        if not isPress(input) then
            return
        end
        if not self.Open or not self.Root.Visible then
            return
        end
        local point = pointerPosition()
        if self._resizeActive or (self._grip and pointInside(point, self._grip)) then
            return
        end
        if not pointInside(point, self.Body) or self:_overControl(point) then
            return
        end
        if self._clampTween then
            self._clampTween:Cancel()
            self._clampTween = nil
        end
        dragging, moved = true, false
        pressPoint = point
        grabOffset = point - centre()
    end))

    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if not dragging then
            return
        end
        if isPress(input) then
            dragging = false
            target = nil
            if skeleton then
                dropSkeleton()
            else
                self:_clampToScreen()
            end
        end
    end))

    table.insert(self._frameSteps, function(deltaTime)
        if not dragging then
            return
        end
        local point = pointerPosition()
        if not moved and (point - pressPoint).Magnitude > 3 then
            moved = true
            if self.DragSkeleton then
                skeleton, fadeSkeleton = makeSkeleton(self)
            end
        end
        if not moved then
            return
        end
        -- Hidden or minimized mid-drag: land it where the outline is.
        if skeleton and (not self.Open or not self.Root.Visible) then
            dragging = false
            dropSkeleton()
            return
        end
        target = point - grabOffset
        local alpha = 1 - math.exp(-deltaTime * 45)
        if skeleton then
            local current = Vector2.new(skeleton.Position.X.Offset, skeleton.Position.Y.Offset)
            local step = current:Lerp(target, alpha)
            skeleton.Position = UDim2.fromOffset(step.X, step.Y)
        else
            local step = centre():Lerp(target, alpha)
            self.Root.Position = UDim2.fromOffset(step.X, step.Y)
        end
    end)
end

-- One of Library.DragStyles; anything else falls back to "Outline".
-- Returns the style it settled on.
function Window:SetDragStyle(style)
    style = table.find(Library.DragStyles, style) and style or "Outline"
    self.DragStyle = style
    self.DragSkeleton = style ~= "Off"
    return style
end

function Window:GetDragStyle()
    return self.DragStyle
end

-- How the minimized island shows the session card: opening it while
-- hovered, or keeping it open the whole time it's minimized.
Library.IslandStyles = { "Show on Hover", "Always Show" }

-- One of Library.IslandStyles; anything else falls back to "Show on Hover".
-- Returns the style it settled on.
function Window:SetIslandStyle(style)
    style = table.find(Library.IslandStyles, style) and style or "Show on Hover"
    self.IslandStyle = style
    if self._islandSettle then
        self._islandSettle()
    end
    return style
end

function Window:GetIslandStyle()
    return self.IslandStyle
end

-- The older on/off switch: off is the "Off" style, on brings back the
-- default style if it was off.
function Window:SetDragSkeleton(enabled)
    if enabled == false then
        self:SetDragStyle("Off")
    elseif self.DragStyle == "Off" or not self.DragStyle then
        self:SetDragStyle("Outline")
    end
end

-- The sidebar's divider is a grab strip: dragging it sets the rail's width,
-- kept between a usable minimum and enough room for the content.
function Window:_sidebarResize(sidebar, width)
    local divider = sidebar:FindFirstChild("Divider")
    local want = width
    local function apply(value, remember)
        if remember ~= false then
            want = value
        end
        local room = self.Body.AbsoluteSize.X / self.Scale.Scale - 300
        value = math.floor(math.clamp(value, 150, math.max(math.min(300, room), 150)))
        self.SidebarWidth = value
        sidebar.Size = UDim2.new(0, value, 1, 0)
        self.Content.Position = UDim2.fromOffset(value + 1, 0)
        self.Content.Size = UDim2.new(1, -(value + 1), 1, 0)
    end
    self.SetSidebarWidth = function(_, value)
        apply(tonumber(value) or SIDEBAR_WIDTH)
    end
    apply(width)
    local grip = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 6, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 6,
        Parent = sidebar,
    })
    grip:SetAttribute("NoDrag", true)
    local dragging, startX, startWidth = false, 0, width
    local function light(on)
        if divider then
            tween(divider, { BackgroundColor3 = on and Theme.Accent or Theme.Stroke }, 0.15)
        end
    end
    grip.MouseEnter:Connect(function()
        light(true)
    end)
    grip.MouseLeave:Connect(function()
        if not dragging then
            light(false)
        end
    end)
    grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, startX, startWidth = true, input.Position.X, self.SidebarWidth
            want = startWidth
            light(true)
        end
    end)
    self:_listen("Changed", function(input)
        if dragging and isMove(input) then
            apply(startWidth + (input.Position.X - startX) / self.Scale.Scale)
        end
    end)
    self:_listen("Ended", function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            light(false)
        end
    end)
    -- Shrinking the window pulls an over-wide rail back in.
    self.Body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if not dragging then
            apply(want, false)
        end
    end)
end

-- See-through window: the body and sidebar let the game show through, and the
-- shadow lightens so it doesn't smudge behind them.
function Window:SetTransparent(enabled)
    self.Transparent = enabled == true
    local on = self.Transparent
    self._shadowRest = on and 0.85 or 0.6
    tween(self.Body, { BackgroundTransparency = on and 0.35 or 0 }, 0.25)
    -- See-through, the rail stays a touch more solid than the body so the
    -- tabs keep their contrast; over a background image it lets more through.
    local railAlpha = on and 0.5 or (self.Background and 0.45 or 0)
    tween(self.SidebarFill, { BackgroundTransparency = railAlpha }, 0.25)
    if self.Open and not self.Minimized and self.Root.Visible then
        tween(self.Shadow, { ImageTransparency = self._shadowRest }, 0.25)
    end
end

local function orderedChildren(parent)
    local children = {}
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") then
            table.insert(children, child)
        end
    end
    table.sort(children, function(a, b)
        return a.LayoutOrder < b.LayoutOrder
    end)
    return children
end

local function popIn(object, delay, force)
    if not object.Visible and not force then
        return
    end
    object.Visible = false
    task.delay(delay, function()
        if not object.Parent then
            return
        end
        local scaleObject = create("UIScale", { Scale = 0.94, Parent = object })
        object.Visible = true
        tween(scaleObject, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
        task.delay(0.4, function()
            scaleObject:Destroy()
        end)
    end)
end

function Window:_revealCards(tab, baseDelay)
    local container = tab.CurrentSubTab or tab
    if container._revealed then
        return
    end
    container._revealed = true
    local index = 0
    local function reveal(object)
        popIn(object, (baseDelay or 0) + index * 0.035)
        index += 1
    end
    local columns = container._columnSet
    for _, child in ipairs(orderedChildren(container.List)) do
        if columns and child == columns.Holder then
            local left, right = orderedChildren(columns.Left), orderedChildren(columns.Right)
            for row = 1, math.max(#left, #right) do
                if left[row] then
                    reveal(left[row])
                end
                if right[row] then
                    reveal(right[row])
                end
            end
        else
            reveal(child)
        end
    end
end

function Window:_playIntro(morph)
    if self._introDone or self._destroyed then
        return
    end
    self._introDone = true
    self:_refreshBackdrop(true)
    task.delay(0.4, function()
        self:_refreshToggleButton()
    end)
    -- Build the minimized bar ahead of time so the first minimize doesn't
    -- pay for it mid-click.
    task.delay(1.5, function()
        if not self._destroyed and not self.MiniBar then
            self:_buildMiniBar()
        end
    end)
    local root, shadow, scale = self.Root, self.Shadow, self.Scale
    if self.CurrentTab then
        self:_revealCards(self.CurrentTab, morph and 0.15 or 0.25)
    end
    root.Visible = true
    if morph then
        scale.Scale = self._fitScale or 1
        root.Position = UDim2.fromScale(0.5, 0.5)
        self:_fade(0, 0.3)
        tween(self.BodyStroke, { Transparency = 0 }, 0.3)
        tween(shadow, { ImageTransparency = 0.6 }, 0.3)
    else
        root.Position = UDim2.new(0.5, 0, 0.5, 24)
        tween(scale, { Scale = self._fitScale or 1 }, 0.5, Enum.EasingStyle.Back)
        tween(root, { Position = UDim2.fromScale(0.5, 0.5) }, 0.5, Enum.EasingStyle.Quint)
        self:_fade(0, 0.35)
        tween(self.BodyStroke, { Transparency = 0 }, 0.35)
    end
    if not morph then
        tween(shadow, { ImageTransparency = 0.6 }, 0.5)
    end

    for index, tab in ipairs(self.Tabs) do
        popIn(tab._button, 0.1 + index * 0.05, true)
    end
    self.Indicator.Visible = false
    task.delay(0.15 + #self.Tabs * 0.05, function()
        if self.CurrentTab then
            self:_placeIndicator(self.CurrentTab)
        end
    end)
end

function Window:_showLoader(opts)
    local duration = opts.LoadingDuration or 1.6
    local gui = self.Gui
    -- A compact card: logo, title and subtitle on top, a checklist of the
    -- loading steps under a hairline, and a thin progress line along the
    -- bottom edge. Everything but the prompt cards lives in one canvas group
    -- so it can fade as a unit.
    local steps = opts.LoadingSteps or { "Preparing interface", "Loading icons", "Almost there" }
    local WIDTH, PAD, STEP = 340, 22, 24
    local listTop = 80
    local height = listTop + #steps * STEP + 18
    local loader = create("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 10),
        Size = UDim2.fromOffset(WIDTH, height),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ZIndex = 10,
        Parent = gui,
    })
    local loaderCorner = corner(loader, UDim.new(0, 12))
    local loaderStroke = stroke(loader, Theme.Stroke, 1)
    local loaderScale = create("UIScale", { Scale = 0.97, Parent = loader })
    local loaderShadow = create("ImageLabel", {
        Position = UDim2.fromOffset(-25, -25),
        Size = UDim2.new(1, 50, 1, 50),
        BackgroundTransparency = 1,
        Image = Assets.Shadow,
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 0,
        Parent = loader,
    })
    local content = create("CanvasGroup", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = loader,
    })

    local logo = create("ImageLabel", {
        Position = UDim2.fromOffset(PAD, PAD),
        Size = UDim2.fromOffset(30, 30),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Accent,
        ScaleType = Enum.ScaleType.Fit,
        Parent = content,
    })
    applyIcon(logo, opts.Icon or Assets.Logo, true)
    local TEXT_X = PAD + 42
    local titleLabel = label({
        Position = UDim2.fromOffset(TEXT_X, PAD - 2),
        Size = UDim2.new(1, -(TEXT_X + 70), 0, 18),
        Text = opts.LoadingTitle or opts.Title or "Airflow",
        TextSize = 15,
        FontFace = Fonts.Bold,
        Parent = content,
    })
    local statusLabel = label({
        Position = UDim2.fromOffset(TEXT_X, PAD + 17),
        Size = UDim2.new(1, -(TEXT_X + 70), 0, 15),
        Text = opts.LoadingText or opts.Subtitle or "Loading",
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        Parent = content,
    })
    local percentLabel = label({
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -PAD, 0, PAD + 6),
        Size = UDim2.fromOffset(56, 16),
        Text = "0%",
        TextSize = 13,
        FontFace = Fonts.Medium,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = content,
    })
    create("Frame", {
        Position = UDim2.fromOffset(PAD, listTop - 14),
        Size = UDim2.new(1, -PAD * 2, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = content,
    })

    -- Each step: a marker and its text. Pending is a dim dot, the running
    -- step a turning arc, and a finished one a check.
    local rows = {}
    for index, text in ipairs(steps) do
        local row = create("Frame", {
            Position = UDim2.fromOffset(PAD, listTop + (index - 1) * STEP),
            Size = UDim2.new(1, -PAD * 2, 0, STEP),
            BackgroundTransparency = 1,
            Parent = content,
        })
        local dot = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 7, 0.5, 0),
            Size = UDim2.fromOffset(6, 6),
            BackgroundColor3 = Theme.Surface3,
            BorderSizePixel = 0,
            Parent = row,
        })
        corner(dot, UDim.new(1, 0))
        local spinner = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 7, 0.5, 0),
            Size = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = row,
        })
        corner(spinner, UDim.new(1, 0))
        local spinnerStroke = create("UIStroke", {
            Color = Theme.Accent,
            Thickness = 2,
            Parent = spinner,
        })
        create("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(0.501, 1),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = spinnerStroke,
        })
        local check = create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 7, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            ImageColor3 = Theme.Accent,
            ImageTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
            Parent = row,
        })
        applyIcon(check, "check")
        local stepLabel = label({
            Position = UDim2.fromOffset(24, 0),
            Size = UDim2.new(1, -24, 1, 0),
            Text = tostring(text),
            TextSize = 13,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            TextTransparency = 1,
            Parent = row,
        })
        rows[index] = { Dot = dot, Spinner = spinner, Check = check, Label = stepLabel, State = "pending" }
        -- The rows fade in one after another once the card is up.
        task.delay(0.15 + index * 0.06, function()
            if loader.Parent and rows[index].State == "pending" then
                tween(stepLabel, { TextTransparency = 0.45 }, 0.3)
            end
        end)
    end
    local function setStep(index, state)
        local row = rows[index]
        if not row or row.State == state then
            return
        end
        row.State = state
        row.Dot.Visible = state == "pending"
        row.Spinner.Visible = state == "active"
        tween(row.Check, { ImageTransparency = state == "done" and 0 or 1 }, 0.2)
        tween(row.Label, {
            TextTransparency = state == "pending" and 0.45 or 0,
            TextColor3 = state == "active" and Theme.Text or Theme.Muted,
        }, 0.2)
    end

    local track = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Parent = content,
    })
    local fill = create("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })

    tween(loader, { GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) }, 0.45, Enum.EasingStyle.Quint)
    tween(loaderScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Quint)
    tween(loaderShadow, { ImageTransparency = 0.55 }, 0.4)
    tween(fill, { Size = UDim2.fromScale(0.85, 1) }, duration * 0.8, Enum.EasingStyle.Quart)
    -- The percentage follows the bar and the running step's arc turns.
    local percentStep
    percentStep = RunService.RenderStepped:Connect(function(deltaTime)
        if not loader.Parent then
            percentStep:Disconnect()
            return
        end
        percentLabel.Text = math.floor(fill.Size.X.Scale * 100 + 0.5) .. "%"
        for _, row in ipairs(rows) do
            if row.State == "active" then
                row.Spinner.Rotation = (row.Spinner.Rotation + deltaTime * 360) % 360
            end
        end
    end)

    task.spawn(loadLucide)

    for index in ipairs(steps) do
        task.delay(duration * (index - 1) / #steps, function()
            if not loader.Parent then
                return
            end
            if index > 1 then
                setStep(index - 1, "done")
            end
            setStep(index, "active")
        end)
    end
    local function completeSteps()
        for index in ipairs(rows) do
            setStep(index, "done")
        end
    end

    local function finish()
        completeSteps()
        tween(content, { GroupTransparency = 1 }, 0.18)

        local fit = self._fitScale or 1
        local target = self.Root.Size
        tween(loader, {
            Size = UDim2.fromOffset(target.X.Offset * fit, target.Y.Offset * fit),
            Position = UDim2.fromScale(0.5, 0.5),
        }, 0.5, Enum.EasingStyle.Quint)
        tween(loaderCorner, { CornerRadius = UDim.new(0, Library._radius(10)) }, 0.5, Enum.EasingStyle.Quint)
        tween(loaderScale, { Scale = 1 }, 0.5, Enum.EasingStyle.Quint)

        task.delay(0.28, function()
            self:_playIntro(true)
            tween(loader, { GroupTransparency = 1 }, 0.25)
            tween(loaderStroke, { Transparency = 1 }, 0.2)
            tween(loaderShadow, { ImageTransparency = 1 }, 0.2)
        end)
        task.delay(0.6, function()
            loader:Destroy()
        end)
    end

    -- Prompt cards (unsupported executor, custom disclaimers): the checklist
    -- gives way to one card at a time, each with Exit and Continue, before
    -- the window opens.
    local function hideBar()
        completeSteps()
        tween(content, { GroupTransparency = 1 }, 0.18)
    end

    local function showCard(info, onContinue)
        local WIDTH, PAD, MAX_BODY = 360, 24, 220
        local tone = info.Color or Theme.Accent
        -- Fixed width from the start, so the body wraps at its final width
        -- while the loader is still resizing.
        local warnCard = create("CanvasGroup", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(0, WIDTH, 1, 0),
            BackgroundTransparency = 1,
            GroupTransparency = 1,
            ZIndex = 5,
            Parent = loader,
        })
        local badge = create("Frame", {
            Position = UDim2.fromOffset(PAD, PAD),
            Size = UDim2.fromOffset(44, 44),
            BackgroundColor3 = tone,
            BackgroundTransparency = 0.86,
            BorderSizePixel = 0,
            Parent = warnCard,
        })
        corner(badge, UDim.new(0, 12))
        stroke(badge, tone, 1).Transparency = 0.6
        local badgeIcon = create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(22, 22),
            BackgroundTransparency = 1,
            ImageColor3 = tone,
            ScaleType = Enum.ScaleType.Fit,
            Parent = badge,
        })
        applyIcon(badgeIcon, info.Icon or "info")
        label({
            Position = UDim2.fromOffset(PAD + 58, info.Subtitle and PAD + 3 or PAD + 12),
            Size = UDim2.new(1, -(PAD * 2 + 58), 0, 20),
            Text = info.Title,
            TextSize = 17,
            Parent = warnCard,
        })
        if info.Subtitle then
            label({
                Position = UDim2.fromOffset(PAD + 58, PAD + 25),
                Size = UDim2.new(1, -(PAD * 2 + 58), 0, 16),
                Text = tostring(info.Subtitle),
                TextSize = 13,
                TextColor3 = tone,
                Parent = warnCard,
            })
        end
        -- Long text scrolls past MAX_BODY instead of pushing the card off screen.
        local scroller = create("ScrollingFrame", {
            Position = UDim2.fromOffset(PAD, PAD + 60),
            Size = UDim2.new(1, -PAD * 2, 0, 16),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = TOUCH and 4 or 3,
            ScrollBarImageColor3 = Theme.Accent,
            ScrollBarImageTransparency = 0.4,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(),
            Parent = warnCard,
        })
        local body = label({
            Size = UDim2.new(1, -8, 0, 0),
            Text = tostring(info.Text),
            TextSize = 13,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = scroller,
        })
        local row = create("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, PAD, 1, -PAD + 4),
            Size = UDim2.new(1, -PAD * 2, 0, 34),
            BackgroundTransparency = 1,
            Parent = warnCard,
        })
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = row,
        })

        -- Don't ask again: only offered when Continue is, and the executor
        -- can write the file that remembers it.
        local remember = false
        local rememberRow = nil
        if not info.Block and info.RememberText and UnsupportedSkip.Available() then
            local boxSize = TOUCH and 20 or 16
            rememberRow = create("TextButton", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, PAD, 1, -PAD + 4 - 34 - 12),
                Size = UDim2.new(1, -PAD * 2, 0, TOUCH and 28 or 22),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = warnCard,
            })
            local box = create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(boxSize, boxSize),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Parent = rememberRow,
            })
            corner(box, UDim.new(0, 4))
            local boxStroke = stroke(box, Theme.Stroke, 1)
            local check = create("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(boxSize - 4, boxSize - 4),
                BackgroundTransparency = 1,
                ImageColor3 = Theme.AccentDark,
                ImageTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                Parent = box,
            })
            applyIcon(check, "check")
            local rememberLabel = label({
                Position = UDim2.fromOffset(boxSize + 8, 0),
                Size = UDim2.new(1, -(boxSize + 8), 1, 0),
                Text = info.RememberText,
                TextSize = 12,
                FontFace = Fonts.Regular,
                TextColor3 = Theme.Muted,
                Parent = rememberRow,
            })
            rememberRow.MouseEnter:Connect(function()
                tween(boxStroke, { Color = remember and Theme.Accent or Theme.StrokeHover }, 0.12)
                tween(rememberLabel, { TextColor3 = Theme.Text }, 0.12)
            end)
            rememberRow.MouseLeave:Connect(function()
                tween(boxStroke, { Color = remember and Theme.Accent or Theme.Stroke }, 0.2)
                tween(rememberLabel, { TextColor3 = remember and Theme.Text or Theme.Muted }, 0.2)
            end)
            rememberRow.MouseButton1Click:Connect(function()
                remember = not remember
                tween(box, { BackgroundColor3 = remember and Theme.Accent or Theme.Surface2 }, 0.15)
                tween(boxStroke, { Color = remember and Theme.Accent or Theme.Stroke }, 0.15)
                tween(check, { ImageTransparency = remember and 0 or 1 }, 0.15)
                tween(rememberLabel, { TextColor3 = remember and Theme.Text or Theme.Muted }, 0.15)
            end)
        end

        local chosen = false
        local function button(text, primary, order, callback)
            local frame = create("TextButton", {
                Size = UDim2.fromOffset(0, 34),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = primary and Theme.Accent or Theme.Surface2,
                BackgroundTransparency = primary and 0.12 or 0,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = order,
                Parent = row,
            })
            corner(frame, UDim.new(0, 7))
            local frameStroke = stroke(frame, primary and Theme.Accent or Theme.Stroke, 1)
            frameStroke.Transparency = primary and 0.4 or 0
            padding(frame, 14, 14)
            label({
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = text,
                TextSize = 13,
                TextColor3 = primary and Theme.AccentDark or Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = frame,
            })
            frame.MouseEnter:Connect(function()
                if primary then
                    tween(frame, { BackgroundTransparency = 0 }, 0.12)
                    tween(frameStroke, { Transparency = 0 }, 0.12)
                else
                    tween(frameStroke, { Color = Theme.StrokeHover }, 0.12)
                end
            end)
            frame.MouseLeave:Connect(function()
                if primary then
                    tween(frame, { BackgroundTransparency = 0.12 }, 0.2)
                    tween(frameStroke, { Transparency = 0.4 }, 0.2)
                else
                    tween(frameStroke, { Color = Theme.Stroke }, 0.2)
                end
            end)
            frame.MouseButton1Click:Connect(function()
                if chosen then
                    return
                end
                chosen = true
                callback()
            end)
        end
        if info.ExitText ~= false then
            button(info.ExitText or "Exit", info.Block, 1, function()
                if info.Callback then
                    task.spawn(info.Callback, false)
                end
                tween(loader, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 12) }, 0.25, Enum.EasingStyle.Quint)
                tween(loaderShadow, { ImageTransparency = 1 }, 0.2)
                task.delay(0.25, function()
                    self:Destroy()
                end)
            end)
        end
        if not info.Block then
            button(info.ContinueText or "Continue", true, 2, function()
                if remember and info.Remember then
                    info.Remember()
                end
                if info.Callback then
                    task.spawn(info.Callback, true)
                end
                tween(warnCard, { GroupTransparency = 1 }, 0.15)
                task.delay(0.15, function()
                    warnCard:Destroy()
                    onContinue()
                end)
            end)
        end

        -- The card grows to fit the message, then it fades in. The wrapped
        -- height can land a few frames late (font loading, the scroller's
        -- layout), so the card refits whenever it changes.
        local laidOut = false
        -- TextBounds of wrapped text stops at the label's current height, so
        -- the card would fit to its own clipped text; the full wrapped height
        -- is measured at the body's width instead.
        local function measure()
            local ok, size = pcall(function()
                local params = Instance.new("GetTextBoundsParams")
                params.Text = body.Text
                params.Font = body.FontFace
                params.Size = body.TextSize
                params.Width = WIDTH - PAD * 2 - 8
                return game:GetService("TextService"):GetTextBoundsAsync(params)
            end)
            return ok and size and math.ceil(size.Y) + 2 or body.TextBounds.Y
        end
        local function fit(duration)
            local textHeight = math.max(measure(), 16)
            local bodyHeight = math.min(textHeight, MAX_BODY)
            body.Size = UDim2.new(1, -8, 0, textHeight)
            scroller.Size = UDim2.new(1, -PAD * 2, 0, bodyHeight)
            scroller.CanvasSize = UDim2.fromOffset(0, textHeight)
            local height = PAD + 60 + bodyHeight + 18 + 34 + PAD - 4
            if rememberRow then
                height += rememberRow.Size.Y.Offset + 10
            end
            tween(loader, { Size = UDim2.fromOffset(WIDTH, height) }, duration, Enum.EasingStyle.Quint)
        end
        body:GetPropertyChangedSignal("TextBounds"):Connect(function()
            if laidOut and loader.Parent and warnCard.Parent then
                fit(0.2)
            end
        end)
        task.delay(0.15, function()
            if not loader.Parent then
                return
            end
            laidOut = true
            fit(0.35)
            task.delay(0.12, function()
                tween(warnCard, { GroupTransparency = 0 }, 0.3)
                badge.Size = UDim2.fromOffset(34, 34)
                badge.Position = UDim2.fromOffset(PAD + 5, PAD + 5)
                tween(badge, { Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(PAD, PAD) }, 0.45, Enum.EasingStyle.Back)
            end)
        end)
    end

    local function runPrompts(queue, index)
        if not loader.Parent then
            return
        end
        local info = queue[index]
        if not info then
            finish()
            return
        end
        showCard(info, function()
            runPrompts(queue, index + 1)
        end)
    end

    task.delay(duration, function()
        tween(fill, { Size = UDim2.fromScale(1, 1) }, 0.25, Enum.EasingStyle.Quint)
        task.delay(0.25, function()
            if not loader.Parent then
                return
            end
            if opts._prompts then
                hideBar()
                runPrompts(opts._prompts, 1)
            else
                finish()
            end
        end)
    end)
end

function Window:_fitToScreen(instant)
    local viewport = self.Gui.AbsoluteSize
    if viewport.X == 0 or viewport.Y == 0 then
        return
    end
    local size = self.Root.Size
    -- The player's UI scale, times the adaptive factor for this screen, shrunk
    -- further when the window wouldn't fit.
    local wanted = (self._uiScale or 1) * (self._adaptive ~= false and Library._adaptiveFactor(viewport) or 1)
    local scale = math.min(wanted, (viewport.X - 24) / math.max(size.X.Offset, 1), (viewport.Y - 24) / math.max(size.Y.Offset, 1))
    self._fitScale = math.max(scale, 0.45)
    if self._introDone and self.Open then
        if instant then
            self.Scale.Scale = self._fitScale
        else
            tween(self.Scale, { Scale = self._fitScale }, 0.2)
        end
    end
end

-- Adaptive size: the window is drawn for a 1080p screen and grows on larger
-- ones (up to 1.75x on 4K) or shrinks a little on small laptops, so it covers
-- about the same share of any screen. 1080p-class screens, windowed or with
-- the topbar inset, stay at exactly 1. Touch screens only use the fit.
function Library._adaptiveFactor(viewport)
    if TOUCH then
        return 1
    end
    local factor = math.min(viewport.X / 1920, viewport.Y / 1020)
    if factor > 0.9 and factor < 1.15 then
        return 1
    end
    return math.clamp(math.floor(factor * 20 + 0.5) / 20, 0.85, 1.75)
end

function Window:SetAdaptiveSize(enabled)
    self._adaptive = enabled ~= false
    self:_fitToScreen()
    task.delay(0.22, function()
        if not self._destroyed then
            self:_clampToScreen()
        end
    end)
end

function Window:GetAdaptiveSize()
    return self._adaptive ~= false
end

-- UI scale: 0.6 to 1.5 on top of the automatic fit to small screens.
function Window:SetUIScale(value)
    value = math.clamp(tonumber(value) or 1, 0.6, 1.5)
    self.UIScale = value
    self._uiScale = value
    self:_fitToScreen()
    task.delay(0.22, function()
        if not self._destroyed then
            self:_clampToScreen()
        end
    end)
end

function Window:GetUIScale()
    return self._uiScale or 1
end

-- Density: the spacing between cards, groupboxes and rows. Shared by every
-- window, like the theme. Anything built with Library._space follows it.
Library.DensityModes = { Compact = 0.55, Default = 1, Comfortable = 1.45 }
Library.Density = "Default"

-- Small gaps (a groupbox's 2px rows) still move visibly between modes.
function Library._spaced(base, factor)
    if base <= 0 then
        return 0
    end
    return math.max(math.floor(base * factor + (factor - 1) * 4 + 0.5), 0)
end

function Library._space(object, base)
    local factor = Library.DensityModes[Library.Density] or 1
    if object:IsA("UIListLayout") or object:IsA("UIGridLayout") then
        object:SetAttribute("Space", base)
        object.Padding = UDim.new(0, Library._spaced(base, factor))
    elseif object:IsA("UIPadding") then
        -- base is { left, right, top, bottom }
        object:SetAttribute("SpaceL", base[1])
        object:SetAttribute("SpaceR", base[2])
        object:SetAttribute("SpaceT", base[3])
        object:SetAttribute("SpaceB", base[4])
        object.PaddingLeft = UDim.new(0, math.floor(base[1] * math.sqrt(factor) + 0.5))
        object.PaddingRight = UDim.new(0, math.floor(base[2] * math.sqrt(factor) + 0.5))
        object.PaddingTop = UDim.new(0, Library._spaced(base[3], factor))
        object.PaddingBottom = UDim.new(0, Library._spaced(base[4], factor))
    end
    return object
end

function Library:SetDensity(mode)
    if type(mode) == "string" then
        for name in pairs(Library.DensityModes) do
            if name:lower() == mode:lower() then
                mode = name
                break
            end
        end
    end
    if not Library.DensityModes[mode] then
        mode = "Default"
    end
    Library.Density = mode
    for _, window in ipairs(Library.Windows) do
        if window.Gui and window.Gui.Parent then
            for _, object in ipairs(window.Gui:GetDescendants()) do
                local base = object:GetAttribute("Space")
                if base then
                    Library._space(object, base)
                elseif object:GetAttribute("SpaceL") then
                    Library._space(object, {
                        object:GetAttribute("SpaceL"), object:GetAttribute("SpaceR"),
                        object:GetAttribute("SpaceT"), object:GetAttribute("SpaceB"),
                    })
                end
            end
        end
    end
    return mode
end

function Window:SetDensity(mode)
    return Library:SetDensity(mode)
end

function Window:GetDensity()
    return Library.Density
end

-- Nearest centre that keeps the whole window inside the viewport.
function Window:_clampedCentre(centre)
    local viewport = self.Gui.AbsoluteSize
    local half = self.Root.AbsoluteSize / 2
    return Vector2.new(
        math.clamp(centre.X, math.min(half.X, viewport.X / 2), math.max(viewport.X - half.X, viewport.X / 2)),
        math.clamp(centre.Y, math.min(half.Y, viewport.Y / 2), math.max(viewport.Y - half.Y, viewport.Y / 2))
    )
end

function Window:_clampToScreen()
    if not self.KeepOnScreen or self._resizeActive then
        return
    end
    local root = self.Root
    local centre = root.AbsolutePosition + root.AbsoluteSize / 2 - self.Gui.AbsolutePosition
    local clamped = self:_clampedCentre(centre)
    if (clamped - centre).Magnitude > 0.5 then
        self._clampTween = tween(root, { Position = UDim2.fromOffset(clamped.X, clamped.Y) }, 0.25, Enum.EasingStyle.Quint)
    end
end

function Window:_createOpenButton(opts)
    local gui = self.Gui
    local pill = create("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 14),
        Size = UDim2.fromOffset(0, 40),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 30,
        Parent = gui,
    })
    corner(pill, UDim.new(1, 0))
    stroke(pill, Theme.Stroke)
    padding(pill, 12, 16)
    local icon = create("ImageLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Accent,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 31,
        Parent = pill,
    })
    applyIcon(icon, opts.Icon or Assets.Logo, true)
    label({
        Position = UDim2.fromOffset(28, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = opts.Title or "Airflow",
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.None,
        ZIndex = 31,
        Parent = pill,
    })
    self.OpenButton = pill

    local dragging, moved = false, false
    local grab = Vector2.zero
    pill.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging = true
            moved = false
            grab = pointerPosition() - pill.AbsolutePosition
        end
    end)
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if isMove(input) then
            local point = pointerPosition() - grab - gui.AbsolutePosition
            if (point - (pill.AbsolutePosition - gui.AbsolutePosition)).Magnitude > 3 then
                moved = true
            end
            pill.AnchorPoint = Vector2.new(0, 0)
            pill.Position = UDim2.fromOffset(
                math.clamp(point.X, 0, math.max(gui.AbsoluteSize.X - pill.AbsoluteSize.X, 0)),
                math.clamp(point.Y, 0, math.max(gui.AbsoluteSize.Y - pill.AbsoluteSize.Y, 0))
            )
        end
    end))
    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if dragging and isPress(input) then
            dragging = false
            if not moved then
                self:Toggle()
            end
        end
    end))
end

-- Square floating button that minimizes and restores the window. Shown on
-- touch devices only, or everywhere with Platform = "Both".
function Window:_toggleButtonAllowed()
    return self._toggleEnabled and (TOUCH or self._togglePlatform == "Both")
end

function Window:_refreshToggleButton()
    local button = self.ToggleButton
    if not button then
        return
    end
    local shown = self._introDone and not self._destroyed and self:_toggleButtonAllowed()
    if shown and not button.Visible then
        button.Visible = true
        button.Size = UDim2.fromOffset(0, 0)
        tween(button, { Size = UDim2.fromOffset(self._toggleSize, self._toggleSize) }, 0.45, Enum.EasingStyle.Quint)
    elseif not shown then
        button.Visible = false
    end
    -- Folded (window minimized or hidden): the outline takes the accent.
    local folded = self.Minimized or not self.Open
    tween(self._toggleStroke, { Color = folded and Theme.Accent or Theme.Stroke, Transparency = folded and 0.3 or 0 }, 0.35)
    local icon = self._toggleIcon
    tween(icon, { Rotation = folded and 180 or 0 }, 0.5, Enum.EasingStyle.Quint)
    if not icon:GetAttribute("CustomIcon") then
        tween(icon, { ImageColor3 = folded and Theme.Text or Theme.Accent }, 0.35)
    end
end

function Window:_createToggleButton(opts)
    local gui = self.Gui
    local size = tonumber(opts.Size) or (TOUCH and 56 or 50)
    local iconSize = math.floor(size * 0.46)
    self._toggleEnabled = opts.Enabled ~= false
    self._togglePlatform = opts.Platform == "Both" and "Both" or "Mobile"
    self._toggleSize = size
    local button = create("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = opts.Position or UDim2.new(0, 18 + size / 2, 0.5, 0),
        Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 30,
        Parent = gui,
    })
    corner(button, UDim.new(0, 12))
    local buttonStroke = stroke(button, Theme.Stroke)
    local icon = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(iconSize, iconSize),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Accent,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 31,
        Parent = button,
    })
    local buttonScale = create("UIScale", { Parent = button })
    self.ToggleButton = button
    self._toggleStroke = buttonStroke
    self._toggleIcon = icon
    self:SetToggleButtonIcon(opts.Icon or "layout-grid")

    local dragging, moved = false, false
    local grab = Vector2.zero
    button.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging = true
            moved = false
            grab = pointerPosition() - button.AbsolutePosition
            tween(buttonScale, { Scale = 0.94 }, 0.18, Enum.EasingStyle.Quint)
        end
    end)
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging or not isMove(input) then
            return
        end
        local point = pointerPosition() - grab - gui.AbsolutePosition
        if (point - (button.AbsolutePosition - gui.AbsolutePosition)).Magnitude > 3 then
            moved = true
        end
        if moved then
            button.AnchorPoint = Vector2.zero
            button.Position = UDim2.fromOffset(
                math.clamp(point.X, 0, math.max(gui.AbsoluteSize.X - button.AbsoluteSize.X, 0)),
                math.clamp(point.Y, 0, math.max(gui.AbsoluteSize.Y - button.AbsoluteSize.Y, 0))
            )
        end
    end))
    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if not dragging or not isPress(input) then
            return
        end
        dragging = false
        tween(buttonScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Quint)
        if moved then
            return
        end
        ripple(button)
        if not self.Open then
            self:Toggle(true)
        elseif self.Minimized then
            self:Restore()
        else
            self:Minimize()
        end
    end))
end

function Window:SetToggleButton(enabled)
    self._toggleEnabled = enabled ~= false
    self:_refreshToggleButton()
end

function Window:SetToggleButtonPlatform(platform)
    self._togglePlatform = platform == "Both" and "Both" or "Mobile"
    self:_refreshToggleButton()
end

function Window:SetToggleButtonIcon(icon)
    local image = self._toggleIcon
    if not image then
        return
    end
    image.Image = ""
    applyIcon(image, icon)
    if image.Image == "" then
        applyIcon(image, Assets.Logo)
    end
    if not image:GetAttribute("CustomIcon") then
        tween(image, { ImageColor3 = (self.Minimized or not self.Open) and Theme.Text or Theme.Accent }, 0)
    end
end

function Window:_enableResize(minSize)
    local maxSize = self.MaxSize or Vector2.new(math.huge, math.huge)
    self._minSize = minSize
    local root = self.Root
    local grip = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, 4, 1, 4),
        Size = UDim2.fromOffset(32, 32),
        BackgroundTransparency = 1,
        Active = true,
        ZIndex = 20,
        Parent = root,
    })
    self._grip = grip
    -- An arc that traces the window's own rounded corner: a rounded square
    -- laid over the corner whose outline fades out away from it, so only the
    -- curve and a short run of each edge show. Faint at rest, accent in use.
    local gripArc = create("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.fromOffset(26, 26),
        BackgroundTransparency = 1,
        ZIndex = 20,
        Parent = grip,
    })
    corner(gripArc, UDim.new(0, 10))
    local gripStroke = create("UIStroke", {
        Color = Theme.Muted,
        Thickness = 2,
        Transparency = 0.55,
        Parent = gripArc,
    })
    create("UIGradient", {
        Rotation = 45,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.55, 1),
            NumberSequenceKeypoint.new(0.85, 0),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Parent = gripStroke,
    })
    local function lightGrip(on)
        tween(gripStroke, {
            Color = on and Theme.Accent or Theme.Muted,
            Transparency = on and 0 or 0.55,
        }, on and 0.15 or 0.3, Enum.EasingStyle.Quint)
    end

    -- The size follows the pointer through a critically damped spring, so it
    -- glides after the cursor and eases to rest when released instead of
    -- snapping. While resizing, the window is anchored at its top-left corner
    -- so only the right and bottom edges move and nothing jitters on half pixels.
    local STIFFNESS = 20
    local resizing = false
    local startSize = Vector2.zero
    local startPointer = Vector2.zero
    local current = Vector2.zero
    local velocity = Vector2.zero
    local target = Vector2.zero
    local applied = Vector2.zero

    local function readSize()
        return Vector2.new(root.Size.X.Offset, root.Size.Y.Offset)
    end

    local function pin()
        if root.AnchorPoint == Vector2.zero then
            return
        end
        -- A clamp tween still writing centre coordinates would fight the new anchor.
        if self._clampTween then
            self._clampTween:Cancel()
            self._clampTween = nil
        end
        local topLeft = root.AbsolutePosition - self.Gui.AbsolutePosition
        root.AnchorPoint = Vector2.zero
        root.Position = UDim2.fromOffset(topLeft.X, topLeft.Y)
    end

    local function unpin()
        local topLeft = root.AbsolutePosition - self.Gui.AbsolutePosition
        local half = root.AbsoluteSize / 2
        root.AnchorPoint = Vector2.new(0.5, 0.5)
        root.Position = UDim2.fromOffset(topLeft.X + half.X, topLeft.Y + half.Y)
    end

    local function clampSize(size)
        return Vector2.new(
            math.floor(math.clamp(size.X, minSize.X, maxSize.X) + 0.5),
            math.floor(math.clamp(size.Y, minSize.Y, maxSize.Y) + 0.5)
        )
    end

    grip.InputBegan:Connect(function(input)
        if not isPress(input) or not self.Open then
            return
        end
        if not self._resizeActive then
            pin()
            current = readSize()
            velocity = Vector2.zero
            applied = current
        end
        self._resizeActive = true
        resizing = true
        startSize = current
        startPointer = pointerPosition()
        target = clampSize(startSize)
        lightGrip(true)
    end)
    grip.MouseEnter:Connect(function()
        if not resizing then
            lightGrip(true)
        end
    end)
    grip.MouseLeave:Connect(function()
        if not resizing then
            lightGrip(false)
        end
    end)
    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if resizing and isPress(input) then
            resizing = false
            lightGrip(false)
        end
    end))

    table.insert(self._frameSteps, function(deltaTime)
        if not self._resizeActive then
            return
        end
        if resizing then
            local delta = (pointerPosition() - startPointer) / self.Scale.Scale
            target = clampSize(startSize + delta)
        end
        local dt = math.min(deltaTime, 1 / 30)
        local decay = math.exp(-STIFFNESS * dt)
        local offset = current - target
        local drift = (velocity + offset * STIFFNESS) * dt
        velocity = (velocity - drift * STIFFNESS) * decay
        current = target + (offset + drift) * decay

        local rounded = Vector2.new(math.floor(current.X + 0.5), math.floor(current.Y + 0.5))
        if rounded ~= applied then
            applied = rounded
            root.Size = UDim2.fromOffset(rounded.X, rounded.Y)
        end

        if not resizing and (current - target).Magnitude < 0.3 and velocity.Magnitude < 3 then
            current = target
            velocity = Vector2.zero
            applied = target
            root.Size = UDim2.fromOffset(target.X, target.Y)
            unpin()
            self._resizeActive = false
            self:_fitToScreen()
            self:_clampToScreen()
        end
    end)
end

-- The window's own size in pixels, before the UI scale and screen fit.
function Window:GetSize()
    return Vector2.new(self.Root.Size.X.Offset, self.Root.Size.Y.Offset)
end

-- Resizes to an exact size, kept within MinSize and MaxSize. Ignored while the
-- player is dragging the grip.
function Window:SetSize(size, instant)
    if typeof(size) == "UDim2" then
        size = Vector2.new(size.X.Offset, size.Y.Offset)
    end
    if typeof(size) ~= "Vector2" or self._resizeActive then
        return
    end
    local minSize = self._minSize or Vector2.zero
    local maxSize = self.MaxSize or Vector2.new(math.huge, math.huge)
    size = Vector2.new(
        math.floor(math.clamp(size.X, minSize.X, maxSize.X) + 0.5),
        math.floor(math.clamp(size.Y, minSize.Y, maxSize.Y) + 0.5)
    )
    if size == self:GetSize() then
        return
    end
    local duration = (instant or not self.Root.Visible) and 0 or 0.3
    tween(self.Root, { Size = UDim2.fromOffset(size.X, size.Y) }, duration, Enum.EasingStyle.Quint)
    task.delay(duration + 0.02, function()
        if not self._destroyed then
            self:_fitToScreen()
            self:_clampToScreen()
        end
    end)
end

-- Configs are plain JSON, one file per config, in the same shape as a share code:
--   {"Folder":"MyHub","Name":"farm","Version":1,"Config":"{\"AutoFarm\":{\"Value\":true,\"Type\":\"Toggle\"}}"}
-- Config holds the flags as their own JSON string, each one {"Value":...,"Type":...}.
-- Colours are {"Hex":"ff5a5a"}, keybinds are key names, an empty dropdown has no Value.

local CONFIG_VERSION = 1
local LEGACY_SHARE_PREFIX = "airflow:"

local function configPath(self, name)
    return self.ConfigFolder .. "/" .. name .. ".json"
end

local function fileApiAvailable()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

-- Makes every missing folder along the path, so FolderName can be "Hub/Game".
local function ensureFolder(folder)
    if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
        return
    end
    local path = ""
    for segment in tostring(folder):gmatch("[^/\\]+") do
        path = path == "" and segment or path .. "/" .. segment
        if not isfolder(path) then
            makefolder(path)
        end
    end
end

local function colorToHex(color)
    return string.format("%02x%02x%02x",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5))
end

local function colorFromValue(value)
    if type(value) == "table" then
        if type(value.Hex) == "string" then
            value = value.Hex
        elseif type(value[1]) == "number" then
            -- Older configs stored { r, g, b } in 0-1.
            return Color3.new(value[1], value[2] or 0, value[3] or 0)
        end
    end
    if type(value) == "string" then
        local r, g, b = value:match("^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
        if r then
            return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
        end
    end
    return nil
end

local function serializeFlag(element)
    local kind = element._type
    local value = element:Get()
    if type(element._saveValue) == "function" then
        value = element:_saveValue()
    end
    if kind == "Keybind" then
        return { Type = kind, Value = value and value.Name or nil }
    elseif kind == "ColorPicker" then
        return { Type = kind, Value = typeof(value) == "Color3" and { Hex = colorToHex(value) } or nil }
    end
    return { Type = kind, Value = value }
end

local function deserializeFlag(element, entry, silent)
    local kind = element._type
    local value = entry.Value
    if kind == "Keybind" then
        element:Set(type(value) == "string" and Enum.KeyCode[value] or nil, silent)
    elseif kind == "ColorPicker" then
        local color = colorFromValue(value)
        if color then
            element:Set(color, silent)
        end
    elseif kind == "Dropdown" then
        -- A dropdown saved with nothing picked has no Value at all.
        element:Set(value, silent)
    elseif kind == "Toggle" then
        if type(value) == "boolean" then
            element:Set(value, silent)
        end
    elseif kind == "Slider" or kind == "Stepper" or kind == "Progress" then
        local number = tonumber(value)
        if number then
            element:Set(number, silent)
        end
    elseif value ~= nil then
        element:Set(value, silent)
    end
end

local function entryMatches(element, entry)
    return type(entry) == "table" and (entry.Type == nil or entry.Type == element._type)
end

-- Flags a config holds but no element has claimed yet are kept here. They are
-- applied when an element with that flag is created and written back on save,
-- so a config survives elements that only exist some of the time.
local function collectFlags(self)
    local data = {}
    if self and self._pendingFlags then
        for flag, pending in pairs(self._pendingFlags) do
            data[flag] = pending.Entry
        end
    end
    for flag, element in pairs(Library.Flags) do
        if element._type and type(element.Get) == "function" then
            local ok, entry = pcall(serializeFlag, element)
            if ok then
                data[flag] = entry
            end
        end
    end
    return data
end

function Window:_applyFlags(data, silent)
    silent = silent == true
    self._pendingFlags = {}
    for flag, entry in pairs(data) do
        local element = Library.Flags[flag]
        if element and type(element.Set) == "function" then
            if entryMatches(element, entry) then
                pcall(deserializeFlag, element, entry, silent)
            end
        elseif type(entry) == "table" then
            self._pendingFlags[flag] = { Entry = entry, Silent = silent }
        end
    end
end

-- Every flagged element reports here: its starting value becomes its default,
-- and a value waiting from an earlier load is applied once the constructor returns.
function Window:_flagCreated(flag, element)
    local ok, entry = pcall(serializeFlag, element)
    if ok then
        element._defaultEntry = entry
    end
    local pending = self._pendingFlags and self._pendingFlags[flag]
    if not pending then
        return
    end
    task.defer(function()
        if self._pendingFlags[flag] ~= pending or Library.Flags[flag] ~= element or element._destroyed then
            return
        end
        self._pendingFlags[flag] = nil
        if entryMatches(element, pending.Entry) then
            pcall(deserializeFlag, element, pending.Entry, pending.Silent)
        end
    end)
end

-- Anything listening for config changes (the config manager's status line).
function Window:_configChanged()
    for _, handler in ipairs(self._configListeners) do
        safeCall(handler)
    end
end

function Window:OnConfigChanged(handler)
    table.insert(self._configListeners, handler)
    return function()
        local index = table.find(self._configListeners, handler)
        if index then
            table.remove(self._configListeners, index)
        end
    end
end

local function validConfigName(name)
    return type(name) == "string" and name ~= "" and not name:find('[\\/:%*%?"<>|]')
end

local function encodeConfig(self, name, flags)
    return HttpService:JSONEncode({
        Folder = self.ConfigFolder,
        Name = name,
        Version = CONFIG_VERSION,
        Config = HttpService:JSONEncode(flags),
    })
end

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64_INDEX = {}
for index = 1, #B64 do
    B64_INDEX[B64:byte(index)] = index - 1
end

-- Only for reading the old "airflow:<base64>" share codes.
local function base64Decode(text)
    if #text % 4 ~= 0 then
        return nil
    end
    local out = {}
    for index = 1, #text, 4 do
        local n, pad = 0, 0
        for offset = 0, 3 do
            local byte = text:byte(index + offset)
            local value = B64_INDEX[byte]
            if byte == 61 and index + 3 >= #text then
                pad += 1
                value = 0
            elseif value == nil or pad > 0 then
                return nil
            end
            n = n * 64 + value
        end
        if pad > 2 then
            return nil
        end
        local chunk = string.char(bit32.extract(n, 16, 8), bit32.extract(n, 8, 8), bit32.extract(n, 0, 8))
        table.insert(out, chunk:sub(1, 3 - pad))
    end
    return table.concat(out)
end

-- Reads a config file or a pasted code: the JSON above (Config as a string or
-- a table), a bare flag table, or an old "airflow:" code. Returns flags, info.
local function decodeConfig(text)
    text = tostring(text or ""):match("^%s*(.-)%s*$")
    if text:sub(1, #LEGACY_SHARE_PREFIX) == LEGACY_SHARE_PREFIX then
        text = base64Decode((text:sub(#LEGACY_SHARE_PREFIX + 1):gsub("%s", "")))
        if not text then
            return nil, "invalid config code"
        end
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(text)
    end)
    if not ok or type(data) ~= "table" then
        return nil, "invalid config code"
    end
    local info = {}
    -- A bare flag table could have a flag named Config, but its entry carries a Type.
    if type(data.Config) == "string" or (type(data.Config) == "table" and data.Config.Type == nil) then
        info.Folder = type(data.Folder) == "string" and data.Folder or nil
        info.Name = type(data.Name) == "string" and data.Name or nil
        info.Version = tonumber(data.Version)
        local flags = data.Config
        if type(flags) == "string" then
            ok, flags = pcall(function()
                return HttpService:JSONDecode(data.Config)
            end)
            if not ok then
                return nil, "invalid config code"
            end
        end
        if type(flags) ~= "table" then
            return nil, "invalid config code"
        end
        data = flags
    end
    for flag, entry in pairs(data) do
        if type(flag) ~= "string" or type(entry) ~= "table" then
            return nil, "invalid config code"
        end
    end
    return data, info
end

local function writeConfig(self, name, data)
    if not validConfigName(name) then
        return false, "invalid config name"
    end
    if not fileApiAvailable() then
        return false, "file API unavailable"
    end
    local encoded, text = pcall(encodeConfig, self, name, data)
    if not encoded then
        return false, "could not encode config"
    end
    ensureFolder(self.ConfigFolder)
    return pcall(writefile, configPath(self, name), text)
end

local function readConfig(self, name)
    if not fileApiAvailable() then
        return nil, "file API unavailable"
    end
    if not validConfigName(name) then
        return nil, "invalid config name"
    end
    local path = configPath(self, name)
    if not isfile(path) then
        return nil, "no config named " .. tostring(name)
    end
    local ok, text = pcall(readfile, path)
    if not ok or type(text) ~= "string" then
        return nil, "could not read " .. name
    end
    local data, info = decodeConfig(text)
    if not data then
        return nil, "config is not valid JSON"
    end
    return data, info
end

function Window:ConfigExists(name)
    return validConfigName(name) and fileApiAvailable() and isfile(configPath(self, name)) or false
end

function Window:SaveConfig(name)
    name = name or self.ConfigName
    if not name then
        return false, "no config name"
    end
    local ok, err = writeConfig(self, name, collectFlags(self))
    if ok then
        self.ConfigName = name
    end
    return ok, err
end

function Window:LoadConfig(name, silent)
    name = name or self.ConfigName
    if not name then
        return false, "no config name"
    end
    local data, err = readConfig(self, name)
    if not data then
        return false, err
    end
    self:_applyFlags(data, silent)
    self.ConfigName = name
    self.LoadedConfig = name
    self:_configChanged()
    return true
end

function Window:DeleteConfig(name)
    if not fileApiAvailable() or type(delfile) ~= "function" then
        return false, "file API unavailable"
    end
    if not validConfigName(name) then
        return false, "invalid config name"
    end
    local path = configPath(self, name)
    if not isfile(path) then
        return false, "no config named " .. name
    end
    local ok, err = pcall(delfile, path)
    if not ok then
        return false, err
    end
    if self.LoadedConfig == name then
        self.LoadedConfig = nil
    end
    self:_configChanged()
    return true
end

-- Moves the file and anything pointing at it: the loaded name and both autoloads.
function Window:RenameConfig(name, newName)
    if not validConfigName(newName) then
        return false, "invalid config name"
    end
    if name == newName then
        return true
    end
    if self:ConfigExists(newName) then
        return false, newName .. " already exists"
    end
    local data, err = readConfig(self, name)
    if not data then
        return false, err
    end
    local ok
    ok, err = writeConfig(self, newName, data)
    if not ok then
        return false, err
    end
    if type(delfile) == "function" then
        pcall(delfile, configPath(self, name))
    end
    if self.LoadedConfig == name then
        self.LoadedConfig = newName
    end
    if self.ConfigName == name then
        self.ConfigName = newName
    end
    for _, scope in ipairs({ "Global", "Account" }) do
        if self:GetAutoload(scope) == name then
            self:SetAutoload(newName, scope)
        end
    end
    self:_configChanged()
    return true
end

function Window:ListConfigs()
    local names = {}
    if type(listfiles) ~= "function" or type(isfolder) ~= "function" or not isfolder(self.ConfigFolder) then
        return names
    end
    local ok, paths = pcall(listfiles, self.ConfigFolder)
    if not ok or type(paths) ~= "table" then
        return names
    end
    for _, path in ipairs(paths) do
        local name = path:match("([^/\\]+)%.json$")
        if name then
            table.insert(names, name)
        end
    end
    table.sort(names, function(a, b)
        return a:lower() < b:lower()
    end)
    return names
end

-- Puts every flagged element back to the value it was created with.
function Window:ResetConfig(silent)
    self._pendingFlags = {}
    for _, element in pairs(Library.Flags) do
        if element._defaultEntry and type(element.Set) == "function" then
            pcall(deserializeFlag, element, element._defaultEntry, silent == true)
        end
    end
    self:_configChanged()
    return true
end

-- Empties a folder and removes it, one file at a time when the executor has
-- no delfolder or it refuses a folder that still has files in it.
local function wipeFolder(path)
    if type(isfolder) ~= "function" or not isfolder(path) then
        return true
    end
    if type(delfolder) == "function" and pcall(delfolder, path) and not isfolder(path) then
        return true
    end
    if type(listfiles) == "function" then
        local ok, entries = pcall(listfiles, path)
        for _, entry in ipairs(ok and entries or {}) do
            if isfolder(entry) then
                wipeFolder(entry)
            elseif type(delfile) == "function" then
                pcall(delfile, entry)
            end
        end
    end
    if type(delfolder) == "function" then
        pcall(delfolder, path)
    end
    return not isfolder(path)
end

-- Deletes the script's whole workspace folder: configs, themes, the default
-- theme, autoload, settings and the execution count.
function Window:ClearWorkspace()
    local ok = wipeFolder(self.ConfigFolder)
    self.LoadedConfig = nil
    for _, handler in ipairs(self._workspaceListeners or {}) do
        safeCall(handler)
    end
    self:_configChanged()
    return ok
end

-- Share codes are the same JSON a config file holds.

function Window:ExportConfig(name)
    local data, err
    if name then
        data, err = readConfig(self, name)
        if not data then
            return nil, err
        end
    else
        data = collectFlags(self)
        name = self.LoadedConfig or self.ConfigName
    end
    local ok, code = pcall(encodeConfig, self, name, data)
    if not ok then
        return nil, "could not encode config"
    end
    return code
end

-- Reads a code without applying it. Returns flags and { Folder, Name, Version }.
function Window:DecodeConfig(code)
    return decodeConfig(code)
end

-- saveAs: a name to save under, true for the name inside the code, or nil to
-- only apply it. Codes made for another folder are refused unless force is set.
function Window:ImportConfig(code, saveAs, force)
    local data, info = decodeConfig(code)
    if not data then
        return false, info
    end
    if not force and info.Folder and info.Folder ~= self.ConfigFolder then
        return false, "config is for " .. info.Folder
    end
    if saveAs == true then
        saveAs = info.Name
        if not validConfigName(saveAs) then
            return false, "config has no usable name"
        end
    end
    if saveAs then
        local ok, err = writeConfig(self, saveAs, data)
        if not ok then
            return false, err
        end
    end
    self:_applyFlags(data)
    if saveAs then
        self.ConfigName = saveAs
        self.LoadedConfig = saveAs
    end
    self:_configChanged()
    return true, nil, saveAs
end

local function readText(path)
    if not fileApiAvailable() or not isfile(path) then
        return nil
    end
    local ok, text = pcall(readfile, path)
    if ok and type(text) == "string" and text ~= "" then
        return text
    end
    return nil
end

local function removeFile(path)
    if fileApiAvailable() and type(delfile) == "function" and isfile(path) then
        pcall(delfile, path)
    end
end

-- Manager settings (autoload mode) live beside the configs, apart
-- from the flags, so loading a config never changes them.

local function settingsPath(self)
    return self.ConfigFolder .. "/configsettings.txt"
end

function Window:_readConfigSettings()
    local text = readText(settingsPath(self))
    if text then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(text)
        end)
        if ok and type(data) == "table" then
            return data
        end
    end
    return {}
end

function Window:_writeConfigSettings(changes)
    if not fileApiAvailable() then
        return false, "file API unavailable"
    end
    local data = self:_readConfigSettings()
    for key, value in pairs(changes) do
        data[key] = value
    end
    ensureFolder(self.ConfigFolder)
    return pcall(writefile, settingsPath(self), HttpService:JSONEncode(data))
end

-- Autoload: one config name kept next to the configs, either for every
-- account ("Global") or only the local player ("Account").

local function autoloadPath(self, scope)
    if scope == "Account" then
        return self.ConfigFolder .. "/autoload_" .. tostring(LocalPlayer and LocalPlayer.UserId or 0) .. ".txt"
    end
    return self.ConfigFolder .. "/autoload.txt"
end

function Window:GetAutoloadMode()
    return self:_readConfigSettings().AutoloadMode == "Account" and "Account" or "Global"
end

function Window:GetAutoload(scope)
    if scope then
        return readText(autoloadPath(self, scope))
    end
    return readText(autoloadPath(self, "Account")) or readText(autoloadPath(self, "Global"))
end

function Window:SetAutoload(name, scope)
    if not fileApiAvailable() then
        return false, "file API unavailable"
    end
    scope = scope or self:GetAutoloadMode()
    local ok, err = true, nil
    if name == nil or name == "" then
        removeFile(autoloadPath(self, scope))
        if scope == "Global" then
            removeFile(autoloadPath(self, "Account"))
        end
    else
        ensureFolder(self.ConfigFolder)
        ok, err = pcall(writefile, autoloadPath(self, scope), tostring(name))
        if ok and scope == "Global" then
            removeFile(autoloadPath(self, "Account"))
        end
    end
    self:_configChanged()
    return ok, err
end

-- Switching the mode moves the current autoload so only one stays active.
function Window:SetAutoloadMode(mode)
    mode = mode == "Account" and "Account" or "Global"
    if mode == self:GetAutoloadMode() then
        return true
    end
    local current = self:GetAutoload()
    local ok, err = self:_writeConfigSettings({ AutoloadMode = mode })
    if not ok then
        return false, err
    end
    removeFile(autoloadPath(self, mode == "Account" and "Global" or "Account"))
    if current then
        return self:SetAutoload(current, mode)
    end
    self:_configChanged()
    return true
end

function Window:LoadAutoload(silent)
    local name = self:GetAutoload()
    if not name then
        return false, "no autoload config"
    end
    return self:LoadConfig(name, silent)
end

-- Themes

Library._themeListeners = {}

local function toColor(value)
    if typeof(value) == "Color3" then
        return value
    elseif type(value) == "string" then
        local r, g, b = value:match("^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
        if r then
            return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
        end
    elseif type(value) == "table" then
        local r, g, b = value[1] or value.R, value[2] or value.G, value[3] or value.B
        if tonumber(r) and tonumber(g) and tonumber(b) then
            return Color3.fromRGB(r, g, b)
        end
    end
    return nil
end

local function hexOf(color)
    return string.format("#%02X%02X%02X",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5))
end

-- Coloured text for statuses, metrics, table cells and labels. A theme key
-- used as a tag, <Success>online</Success>, follows theme changes; plain
-- rich text such as <font color="#ff5a5a"> works too. Library.Colorize wraps
-- text for you. Table fields, not locals: the chunk is at Luau's 200 limit.
Library._toneTags = {}
for _, name in ipairs(THEME_KEYS) do
    Library._toneTags[string.lower(name)] = name
end

-- A theme key, a Color3, "#rrggbb" or { r, g, b } as a Color3.
function Library._color(value)
    if type(value) == "string" then
        local key = Library._toneTags[string.lower(value)]
        if key then
            return Theme[key]
        end
    end
    return toColor(value)
end

function Library._rich(text)
    text = tostring(text == nil and "" or text)
    if not string.find(text, "<", 1, true) then
        return text
    end
    return (string.gsub(text, "<(/?)(%a+%d*)>", function(slash, name)
        local key = Library._toneTags[string.lower(name)]
        if not key then
            return nil
        end
        if slash == "/" then
            return "</font>"
        end
        return '<font color="' .. hexOf(Theme[key]) .. '">'
    end))
end

-- Library.Colorize("12 ms", "Success") or Library:Colorize(text, Color3).
function Library.Colorize(...)
    local args = { ... }
    if args[1] == Library then
        table.remove(args, 1)
    end
    local text, color = tostring(args[1] == nil and "" or args[1]), args[2]
    local key = type(color) == "string" and Library._toneTags[string.lower(color)]
    if key then
        return "<" .. key .. ">" .. text .. "</" .. key .. ">"
    end
    local resolved = toColor(color)
    if not resolved then
        return text
    end
    return '<font color="' .. hexOf(resolved) .. '">' .. text .. "</font>"
end

-- The window's corner radius in pixels, 0 (square) to 20; every other
-- rounded corner scales with it. The default is 10. Corners ease to the new
-- radius instead of jumping. Returns the radius it settled on.
function Library:SetCornerRadius(pixels, instant)
    pixels = math.clamp(math.floor((tonumber(pixels) or 10) + 0.5), 0, 20)
    Library.Roundness = pixels / 10
    for object, base in pairs(Library._cornerBases) do
        if not object.Parent then
            Library._cornerBases[object] = nil
        else
            local radius = UDim.new(0, math.floor(base * Library.Roundness + 0.5))
            if instant then
                object.CornerRadius = radius
            else
                tween(object, { CornerRadius = radius }, 0.25, Enum.EasingStyle.Quint)
            end
        end
    end
    return pixels
end

function Library:GetCornerRadius()
    return math.floor(Library.Roundness * 10 + 0.5)
end

function Library:SetTheme(theme, instant)
    if type(theme) == "string" then
        local found = Library.ThemePresets[theme]
        if not found then
            return false
        end
        Library.ThemeName = theme
        theme = found
    elseif type(theme) ~= "table" then
        return false
    end
    local changed = false
    for _, name in ipairs(THEME_KEYS) do
        local color = toColor(theme[name])
        if color and color ~= Theme[name] then
            Theme[name] = color
            changed = true
        end
    end
    if not changed then
        return true
    end
    rebuildThemeLookup()
    sweepBindings()
    driveTheme(instant and 0 or 0.3)
    for owner, fn in pairs(themeHooks) do
        if owner.Parent then
            pcall(fn)
        end
    end
    for _, fn in ipairs(Library._themeListeners) do
        pcall(fn)
    end
    return true
end

function Library:GetTheme()
    local copy = {}
    for _, name in ipairs(THEME_KEYS) do
        copy[name] = Theme[name]
    end
    return copy
end

-- The script's starting theme: a preset name or a colour table. A default the
-- player picked in the theme manager still wins over it.
function Library:SetDefaultTheme(theme)
    Library.DefaultTheme = theme
    if theme == nil then
        return true
    end
    local live = false
    for _, window in ipairs(Library.Windows) do
        if not window._destroyed then
            if window:GetDefaultTheme() then
                return true
            end
            live = true
        end
    end
    return Library:SetTheme(theme, not live)
end

function Library:GetDefaultTheme()
    return Library.DefaultTheme
end

local function themeFolder(self)
    return self.ConfigFolder .. "/themes"
end

function Window:SaveTheme(name)
    if not fileApiAvailable() then
        return false, "file API unavailable"
    end
    if type(name) ~= "string" or name == "" then
        return false, "theme needs a name"
    end
    ensureFolder(self.ConfigFolder)
    ensureFolder(themeFolder(self))
    local data = {}
    for _, key in ipairs(THEME_KEYS) do
        data[key] = hexOf(Theme[key])
    end
    return pcall(function()
        writefile(themeFolder(self) .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
end

function Window:LoadTheme(name, instant)
    if Library.ThemePresets[name] then
        return Library:SetTheme(name, instant)
    end
    local text = readText(themeFolder(self) .. "/" .. tostring(name) .. ".json")
    if not text then
        return false, "no theme named " .. tostring(name)
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(text)
    end)
    if not ok or type(data) ~= "table" then
        return false, "theme is not valid JSON"
    end
    Library.ThemeName = name
    return Library:SetTheme(data, instant)
end

function Window:DeleteTheme(name)
    if not fileApiAvailable() or type(delfile) ~= "function" then
        return false, "file API unavailable"
    end
    local path = themeFolder(self) .. "/" .. tostring(name) .. ".json"
    if not isfile(path) then
        return false, "no theme named " .. tostring(name)
    end
    delfile(path)
    if self:GetDefaultTheme() == name then
        self:SetDefaultTheme(nil)
    end
    return true
end

function Window:ListThemes()
    local names = {}
    if type(listfiles) ~= "function" or type(isfolder) ~= "function" or not isfolder(themeFolder(self)) then
        return names
    end
    for _, path in ipairs(listfiles(themeFolder(self))) do
        local name = path:match("([^/\\]+)%.json$")
        if name then
            table.insert(names, name)
        end
    end
    table.sort(names)
    return names
end

function Window:GetDefaultTheme()
    return readText(themeFolder(self) .. "/default.txt")
end

function Window:SetDefaultTheme(name)
    if not fileApiAvailable() then
        return false, "file API unavailable"
    end
    ensureFolder(self.ConfigFolder)
    ensureFolder(themeFolder(self))
    local path = themeFolder(self) .. "/default.txt"
    if name == nil or name == "" then
        if isfile(path) and type(delfile) == "function" then
            pcall(delfile, path)
        end
        return true
    end
    return pcall(writefile, path, tostring(name))
end

function Window:_applyDefaultTheme()
    local name = self:GetDefaultTheme()
    if name then
        local ok, loaded = pcall(self.LoadTheme, self, name, true)
        if ok and loaded then
            return
        end
    end
    if Library.DefaultTheme ~= nil then
        pcall(Library.SetTheme, Library, Library.DefaultTheme, true)
    end
end

-- Background images

-- Image assets anyone can use, from Fluent-modded's themes.
Library.BackgroundPresets = {
    ["Deep Violet"] = "rbxassetid://136310484943077",
    ["Blood Red"] = "rbxassetid://121343473918667",
    ["Cyanic"] = "rbxassetid://95656189244173",
    ["Amber Glow"] = "rbxassetid://107795771598485",
    ["Bloomings"] = "rbxassetid://133541508207801",
    ["Lavender Pink"] = "rbxassetid://126107479485287",
}
Library.BackgroundPresetOrder = { "Deep Violet", "Blood Red", "Cyanic", "Amber Glow", "Bloomings", "Lavender Pink" }

-- Table fields, not locals: the library chunk is at Luau's 200 local limit.
Library._imageExtensions = { png = true, jpg = true, jpeg = true, webp = true, gif = true, bmp = true }

function Window:_backgroundFolder()
    return self.ConfigFolder .. "/backgrounds"
end

function Window:_trimBackground(source)
    return (tostring(source or ""):match("^%s*(.-)%s*$"))
end

-- Turns a background source into something ImageLabel.Image takes. Web images
-- are downloaded once into backgrounds/cache and loaded with getcustomasset,
-- so this yields the first time a URL is used.
function Window:_resolveBackground(source)
    source = self:_trimBackground(source)
    local preset = Library.BackgroundPresets[source]
    if preset then
        return preset
    end
    if source:match("^%d+$") then
        return "rbxassetid://" .. source
    end
    if source:match("^rbxassetid://%d+") or source:match("^rbxasset://") or source:match("^rbxthumb://")
        or source:match("^https?://www%.roblox%.com/asset") then
        return source
    end
    local canLoad = fileApiAvailable() and typeof(getcustomasset) == "function"
    if source:match("^https?://") then
        if not canLoad then
            return nil, "web images need writefile and getcustomasset"
        end
        local clean = source:match("^[^?#]+") or source
        local ext = (clean:match("%.(%w+)$") or "png"):lower()
        if not Library._imageExtensions[ext] then
            ext = "png"
        end
        local key = (clean:gsub("^https?://", ""):gsub("[^%w]", "_")):sub(-60)
        local folder = self:_backgroundFolder() .. "/cache"
        local path = folder .. "/" .. key .. "_" .. #source .. "." .. ext
        if not isfile(path) then
            local ok, body = pcall(function()
                local request = (syn and syn.request) or http_request or request
                if request then
                    local response = request({ Url = source, Method = "GET" })
                    return response and response.Body
                end
                return game:HttpGet(source, true)
            end)
            if not ok or type(body) ~= "string" or #body < 128 then
                return nil, "could not download the image"
            end
            local head = body:sub(1, 64):lower()
            if head:find("<!doctype") or head:find("<html") then
                return nil, "that link is a web page, not an image"
            end
            ensureFolder(folder)
            if not pcall(writefile, path, body) then
                return nil, "could not save the image"
            end
        end
        local ok, asset = pcall(getcustomasset, path)
        if ok and type(asset) == "string" and asset ~= "" then
            return asset
        end
        pcall(delfile, path)
        return nil, "the downloaded file is not an image"
    end
    -- A file in the backgrounds folder, or any path in the workspace.
    if canLoad then
        for _, path in ipairs({ self:_backgroundFolder() .. "/" .. source, source }) do
            if isfile(path) then
                local ok, asset = pcall(getcustomasset, path)
                if ok and type(asset) == "string" and asset ~= "" then
                    return asset
                end
                return nil, "could not load " .. source
            end
        end
    end
    return nil, "no image called " .. source
end

-- source: a preset name, an image asset id, an rbxassetid:// link, an http(s)
-- image URL, or an image file in <ConfigFolder>/backgrounds. nil or "None"
-- removes it. May yield while a web image downloads.
function Window:SetBackground(source)
    self._backgroundGeneration += 1
    local generation = self._backgroundGeneration
    local image = self._backgroundImage
    source = source ~= false and self:_trimBackground(source) or ""
    if source == "" or source == "None" then
        self.Background = nil
        tween(image, { ImageTransparency = 1 }, 0.25)
        task.delay(0.25, function()
            if self._backgroundGeneration == generation then
                image.Visible = false
                image.Image = ""
            end
        end)
        self:SetTransparent(self.Transparent)
        return true
    end
    local asset, err = self:_resolveBackground(source)
    if self._backgroundGeneration ~= generation or self._destroyed then
        return false, "replaced by a newer background"
    end
    if not asset then
        return false, err
    end
    self.Background = source
    image.Image = asset
    image.Visible = true
    tween(image, { ImageTransparency = self.BackgroundTransparency }, 0.3)
    self:SetTransparent(self.Transparent)
    return true
end

function Window:GetBackground()
    return self.Background
end

-- 0 shows the image fully, 1 hides it behind the theme background colour.
function Window:SetBackgroundTransparency(value)
    self.BackgroundTransparency = math.clamp(tonumber(value) or 0.35, 0, 1)
    if self.Background then
        tween(self._backgroundImage, { ImageTransparency = self.BackgroundTransparency }, 0.15)
    end
end

-- Preset names, then the image files in <ConfigFolder>/backgrounds.
function Window:ListBackgrounds()
    local names = table.clone(Library.BackgroundPresetOrder)
    local folder = self:_backgroundFolder()
    if type(listfiles) == "function" and type(isfolder) == "function" and isfolder(folder) then
        local files = {}
        for _, path in ipairs(listfiles(folder)) do
            local name = path:match("([^/\]+)$")
            local ext = name and name:match("%.(%w+)$")
            if ext and Library._imageExtensions[ext:lower()] then
                table.insert(files, name)
            end
        end
        table.sort(files)
        for _, name in ipairs(files) do
            table.insert(names, name)
        end
    end
    return names
end

local function emptyState(parent, icon, text)
    local holder = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, -10),
        Size = UDim2.fromOffset(200, 70),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    local image = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.fromOffset(26, 26),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Muted,
        ImageTransparency = 0.15,
        ScaleType = Enum.ScaleType.Fit,
        Parent = holder,
    })
    applyIcon(image, icon)
    local caption = label({
        Position = UDim2.fromOffset(0, 36),
        Size = UDim2.new(1, 0, 0, 16),
        Text = text,
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = holder,
    })
    return holder, caption, image
end

local function fadeSlideIn(group, restY)
    restY = restY or 0
    group.GroupTransparency = 1
    group.Position = UDim2.fromOffset(0, restY + 14)
    group.Visible = true
    tween(group, { GroupTransparency = 0, Position = UDim2.fromOffset(0, restY) }, 0.32, Enum.EasingStyle.Quint)
end

local function formatDuration(seconds)
    seconds = math.max(math.floor(seconds), 0)
    local days = math.floor(seconds / 86400)
    local hours = math.floor(seconds / 3600) % 24
    local minutes = math.floor(seconds / 60) % 60
    if days > 0 then
        return string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, seconds % 60)
    end
    return string.format("%ds", seconds)
end

local function shortId(id)
    if type(id) ~= "string" or id == "" then
        return "Studio"
    end
    if #id > 16 then
        return id:sub(1, 8) .. "..." .. id:sub(-4)
    end
    return id
end

local function copyToClipboard(text)
    local setter = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if type(setter) ~= "function" then
        return false
    end
    return (pcall(setter, tostring(text)))
end

local function fetchServers(order)
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=100&excludeFullGames=true",
        game.PlaceId,
        order
    )
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(body) ~= "string" then
        return nil
    end
    local decoded, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not decoded or type(data) ~= "table" or type(data.data) ~= "table" then
        return nil
    end
    return data.data
end

-- Small on/off pill used on the home card for the privacy switches.
local function miniSwitch(parent, initial, order, callback)
    local pill = create("TextButton", {
        Size = UDim2.fromOffset(30, 16),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        Parent = parent,
    })
    corner(pill, UDim.new(1, 0))
    stroke(pill)
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Theme.Muted,
        BorderSizePixel = 0,
        Parent = pill,
    })
    corner(knob, UDim.new(1, 0))
    local on = initial == true
    local function render(animate)
        local duration = animate and 0.22 or 0
        tween(pill, { BackgroundColor3 = on and Theme.Accent or Theme.Surface3 }, duration)
        tween(knob, {
            Position = on and UDim2.new(0, 16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            BackgroundColor3 = on and Theme.AccentDark or Theme.Muted,
        }, duration, Enum.EasingStyle.Back)
    end
    pill.MouseButton1Click:Connect(function()
        on = not on
        render(true)
        safeCall(callback, on)
    end)
    render(false)
    return pill
end

local function softButton(parent, text, props, callback)
    local button = create("TextButton", {
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = parent,
    })
    for key, value in pairs(props) do
        button[key] = value
    end
    corner(button, UDim.new(0, 6))
    local buttonStroke = stroke(button)
    local text_ = label({
        Size = UDim2.fromScale(1, 1),
        Text = text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = button,
    })
    if button.AutomaticSize == Enum.AutomaticSize.X then
        text_.Size = UDim2.new(0, 0, 1, 0)
        text_.AutomaticSize = Enum.AutomaticSize.X
        text_.TextTruncate = Enum.TextTruncate.None
        padding(button, 14, 14)
    end
    button.MouseEnter:Connect(function()
        tween(button, { BackgroundTransparency = 0.15 }, 0.12)
        tween(buttonStroke, { Color = Theme.StrokeHover }, 0.12)
    end)
    button.MouseLeave:Connect(function()
        tween(button, { BackgroundTransparency = 0.45 }, 0.25)
        tween(buttonStroke, { Color = Theme.Stroke }, 0.25)
    end)
    button.MouseButton1Click:Connect(function()
        ripple(button)
        safeCall(callback)
    end)
    return button, text_
end

local function panelCard(parent, height, order)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        LayoutOrder = order,
        Parent = parent,
    })
    frame:SetAttribute("NoDrag", true)
    corner(frame, UDim.new(0, 10))
    stroke(frame)
    return frame
end

local STAT_TYPES = {
    Players = { "users", "Players" },
    Friends = { "user-check", "Friends" },
    Execs = { "zap", "Execs" },
    Session = { "timer", "Session" },
    Uptime = { "timer", "Session" },
    FPS = { "gauge", "FPS" },
    Ping = { "wifi", "Ping" },
    Executor = { "terminal", "Executor" },
    Game = { "gamepad-2", "Game" },
    Region = { "globe", "Region" },
    Time = { "clock", "Time" },
    ServerAge = { "server", "Server age" },
    Memory = { "cpu", "Memory" },
}

-- Health colour for a live metric: Success under good, Warning under bad,
-- Error past it. lowerIsBetter flips the scale (ping, memory).
function Library._healthColor(value, good, bad, lowerIsBetter)
    if type(value) ~= "number" then
        return Theme.Text
    end
    if lowerIsBetter then
        return value <= good and Theme.Success or value <= bad and Theme.Warning or Theme.Error
    end
    return value >= good and Theme.Success or value >= bad and Theme.Warning or Theme.Error
end

local function bumpExecutions(folder)
    if not fileApiAvailable() then
        return nil
    end
    local path = folder .. "/executions.txt"
    local count = 0
    pcall(function()
        ensureFolder(folder)
        if isfile(path) then
            count = tonumber(readfile(path)) or 0
        end
    end)
    count += 1
    pcall(writefile, path, tostring(count))
    return count
end

-- Containers: a tab or sub tab owns a scrolling list. Elements added straight
-- to it stack full width, groupboxes go into two columns underneath.

local function buildContainer(owner, parent, top, emptyIcon, emptyText)
    local list = create("ScrollingFrame", {
        Position = UDim2.fromOffset(0, top),
        Size = UDim2.new(1, 0, 1, -top),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.5,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Parent = parent,
    })
    Library._space(padding(list, 24, 24, 2, 24), { 24, 24, 2, 24 })
    Library._space(create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = list,
    }), 8)
    owner.List = list
    owner._items = {}
    owner._groupboxes = {}
    owner._childCount = 0
    owner._emptyText = emptyText
    owner._empty, owner._emptyCaption = emptyState(parent, emptyIcon, emptyText)
    list.ChildAdded:Connect(function(child)
        if child:IsA("GuiObject") then
            owner._childCount += 1
            owner:_refreshEmpty()
        end
    end)
    list.ChildRemoved:Connect(function(child)
        if child:IsA("GuiObject") then
            owner._childCount = math.max(owner._childCount - 1, 0)
            owner:_refreshEmpty()
        end
    end)
    owner:_refreshEmpty()
    return list
end

function Tab:_refreshEmpty()
    local empty = self._empty
    if not empty then
        return
    end
    if self._subTabs then
        empty.Visible = false
    else
        empty.Visible = self._childCount == 0
    end
end

function Tab:_columns()
    if self._columnSet then
        return self._columnSet
    end
    local holder = create("Frame", {
        Name = "Columns",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 100000,
        Parent = self.List,
    })
    local layout = Library._space(create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = holder,
    }), 10)
    local function column(order)
        local frame = create("Frame", {
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = holder,
        })
        Library._space(create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = frame,
        }), 10)
        return frame
    end
    local set = { Holder = holder, Left = column(1), Right = column(2), Counts = { 0, 0 }, Stacked = false }
    local window = self.Window
    -- Narrow windows stack the right column under the left one.
    local function relayout()
        local width = holder.AbsoluteSize.X / window.Scale.Scale
        if width <= 0 then
            return
        end
        local stacked = width < STACK_BELOW
        local gap = layout.Padding.Offset
        if stacked == set.Stacked and gap == set.Gap then
            return
        end
        set.Stacked = stacked
        set.Gap = gap
        layout.FillDirection = stacked and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
        local size = stacked and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -gap / 2, 0, 0)
        set.Left.Size = size
        set.Right.Size = size
    end
    holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
    layout:GetPropertyChangedSignal("Padding"):Connect(relayout)
    task.defer(relayout)
    self._columnSet = set
    return set
end

function Tab:Groupbox(opts, icon)
    if self._groupbox then
        return self.Parent:Groupbox(opts, icon)
    end
    opts = normalize(opts, { Title = "Name" })
    if icon ~= nil and opts.Icon == nil then
        opts.Icon = icon
    end
    local window = self.Window
    local set = self:_columns()
    local side = opts.Side
    if side == "Left" or side == 1 then
        side = 1
    elseif side == "Right" or side == 2 then
        side = 2
    else
        side = set.Counts[1] <= set.Counts[2] and 1 or 2
    end
    set.Counts[side] += 1

    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        LayoutOrder = set.Counts[side],
        Parent = side == 1 and set.Left or set.Right,
    })
    box:SetAttribute("NoDrag", true)
    corner(box, UDim.new(0, 10))
    stroke(box)
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = box,
    })

    -- The header is a filled strip: icon and bold title on the left, a
    -- chevron on the right. Pressing anywhere on it folds the box.
    local header = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = 1,
        Parent = box,
    })
    corner(header, UDim.new(0, 10))
    -- Squares the strip's lower corners so it meets the body flat.
    local headerFill = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Parent = header,
    })
    local titleX = 14
    if opts.Icon then
        local headerIcon = create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 14, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            ImageColor3 = Theme.Accent,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 2,
            Parent = header,
        })
        applyIcon(headerIcon, opts.Icon)
        titleX = 37
    end
    local collapseButton = create("ImageLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Muted,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 2,
        Parent = header,
    })
    applyIcon(collapseButton, "chevron-down")
    -- Beside the chevron, a button that pops the box out into a floating
    -- panel (and docks it back once it's out). PopOut = false leaves it off.
    local canPop = opts.PopOut ~= false
    local popButton, popIcon
    if canPop then
        popButton = create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -34, 0.5, 0),
            Size = UDim2.fromOffset(24, 24),
            BackgroundColor3 = Theme.Surface2,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 3,
            Parent = header,
        })
        corner(popButton, UDim.new(0, 6))
        popIcon = create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(13, 13),
            BackgroundTransparency = 1,
            ImageColor3 = Theme.Muted,
            ImageTransparency = TOUCH and 0 or 0.45,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 3,
            Parent = popButton,
        })
        applyIcon(popIcon, "picture-in-picture-2")
    end
    local title = label({
        Position = UDim2.fromOffset(titleX, 0),
        Size = UDim2.new(1, -(titleX + (canPop and 66 or 40)), 1, 0),
        Text = opts.Name or "Groupbox",
        TextSize = 13,
        FontFace = Fonts.Bold,
        ZIndex = 2,
        Parent = header,
    })

    local rule = create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        Parent = box,
    })
    local body = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        LayoutOrder = 3,
        Parent = box,
    })
    local inner = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = body,
    })
    Library._space(padding(inner, 0, 0, 6, 8), { 0, 0, 6, 8 })
    Library._space(create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = inner,
    }), 2)

    local group = setmetatable({
        Name = opts.Name or "Groupbox",
        Window = window,
        Parent = self,
        List = inner,
        Frame = box,
        _frame = box,
        _order = 0,
        _groupbox = true,
        _metrics = METRICS.Row,
        _items = {},
    }, Tab)
    table.insert(self._groupboxes, group)

    local collapsed = false
    local generation = 0
    local function setCollapsed(value, instant)
        value = value == true
        if value == collapsed then
            return
        end
        collapsed = value
        generation += 1
        local current = generation
        local duration = instant and 0 or 0.32
        -- Anything open inside the box (a dropdown list, a picker, a focused
        -- box) closes with it, rather than floating over a folded header.
        if value then
            for _, element in ipairs(group._items) do
                if element._onHide then
                    element._onHide()
                end
                if element.Open and type(element.SetOpen) == "function" then
                    element:SetOpen(false)
                end
            end
        end
        window._controlsDirty = true
        local scale = window.Scale.Scale
        if value then
            body.AutomaticSize = Enum.AutomaticSize.None
            body.Size = UDim2.new(1, 0, 0, body.AbsoluteSize.Y / scale)
            tween(body, { Size = UDim2.new(1, 0, 0, 0) }, duration, Enum.EasingStyle.Quint)
        else
            tween(body, { Size = UDim2.new(1, 0, 0, inner.AbsoluteSize.Y / scale) }, duration, Enum.EasingStyle.Quint)
            local function settle()
                if generation == current and not collapsed then
                    body.AutomaticSize = Enum.AutomaticSize.Y
                    body.Size = UDim2.new(1, 0, 0, 0)
                end
            end
            if duration > 0 then
                task.delay(duration, settle)
            else
                settle()
            end
        end
        local motion = instant and 0 or 0.3
        -- Folded, the strip is the whole box: the hairline under it drops out
        -- of the layout once the body has closed, so the box ends exactly at
        -- the strip and both share the same rounded corners.
        if value then
            local function fold()
                if generation == current and collapsed then
                    rule.Visible = false
                    headerFill.Visible = false
                end
            end
            if duration > 0 then
                task.delay(duration, fold)
            else
                fold()
            end
        else
            rule.Visible = true
            headerFill.Visible = true
        end
        tween(collapseButton, { Rotation = value and -90 or 0 }, motion, Enum.EasingStyle.Quint)
    end

    local function hover(on)
        local duration = on and 0.15 or 0.25
        tween(collapseButton, { ImageColor3 = on and Theme.Text or Theme.Muted }, duration)
        if popIcon and not TOUCH then
            tween(popIcon, { ImageTransparency = on and 0 or 0.45 }, duration)
        end
    end
    header.MouseEnter:Connect(function()
        hover(true)
    end)
    header.MouseLeave:Connect(function()
        hover(false)
    end)
    local isTap = tapGuard(header, function()
        return box:FindFirstAncestorWhichIsA("ScrollingFrame")
    end)
    -- Popping out: the box itself is lifted out of its column into a panel
    -- on the window's pop-out layer, and a slot holds its place in the column
    -- (pressing the slot docks it back). The header drags the panel; a drop
    -- is clamped on screen and the spot is remembered for the next pop-out.
    local popped, popGeneration = false, 0
    local panel, panelScale, panelShadow, slot, stopPanel
    local dragStart, dragOrigin, dragMoved, suppressClick = nil, nil, false, false
    local animating = false

    local function layerScale()
        return math.max(window.Scale.Scale, 0.05)
    end
    local function toLayer(point)
        return (point - window._popLayer.AbsolutePosition) / layerScale()
    end
    -- Keeps a panel's top-centre spot on screen, header always reachable.
    local function clampSpot(spot, width, height)
        local view = window._popLayer.AbsoluteSize / layerScale()
        local margin = 8
        local x = math.clamp(spot.X, width / 2 + margin, math.max(view.X - width / 2 - margin, width / 2 + margin))
        local y = math.clamp(spot.Y, margin, math.max(view.Y - math.min(height, 120) - margin, margin))
        return Vector2.new(x, y)
    end
    local function closeInner()
        for _, element in ipairs(group._items) do
            if element._onHide then
                element._onHide()
            end
            if element.Open and type(element.SetOpen) == "function" then
                element:SetOpen(false)
            end
        end
    end
    local function setPopIcon(out)
        if popIcon then
            applyIcon(popIcon, out and "minimize-2" or "picture-in-picture-2")
        end
    end

    local function popOut()
        if popped or not canPop or not box.Parent or group._destroyed then
            return
        end
        -- A dock still in flight lands first, so the box is back in its column.
        if group._settleDock then
            group._settleDock()
        end
        local layer = window:_popoutLayer()
        popped = true
        group._popped = true
        popGeneration += 1
        local current = popGeneration
        closeInner()
        window:_closePopups()
        local scale = layerScale()
        local column = box.Parent
        local from = toLayer(box.AbsolutePosition)
        local width = box.AbsoluteSize.X / scale
        local height = box.AbsoluteSize.Y / scale

        -- The slot left behind: starts at the box's height so nothing below
        -- jumps, then eases down to a slim bar.
        slot = create("TextButton", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = Theme.Surface2,
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ClipsDescendants = true,
            LayoutOrder = box.LayoutOrder,
            Parent = column,
        })
        slot:SetAttribute("NoDrag", true)
        corner(slot, UDim.new(0, 10))
        stroke(slot, Theme.Stroke, 1).Transparency = 0.3
        local slotLabel = label({
            Size = UDim2.new(1, -24, 0, 40),
            Position = UDim2.fromOffset(12, 0),
            Text = Library._rich(group.Name) .. '<font transparency="0.4">  ·  popped out, click to dock</font>',
            TextSize = 12,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Center,
            RichText = true,
            TextTransparency = 1,
            Parent = slot,
        })
        local thisSlot = slot
        slot.MouseEnter:Connect(function()
            tween(thisSlot, { BackgroundTransparency = 0.35 }, 0.15)
        end)
        slot.MouseLeave:Connect(function()
            tween(thisSlot, { BackgroundTransparency = 0.6 }, 0.25)
        end)
        slot.MouseButton1Click:Connect(function()
            if slot == thisSlot then
                group:Dock()
            end
        end)
        tween(slot, { Size = UDim2.new(1, 0, 0, 40) }, 0.42, Enum.EasingStyle.Quint)
        tween(slotLabel, { TextTransparency = 0 }, 0.3)
        slot.Visible = box.Visible

        panel = create("Frame", {
            Name = "PopOut",
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromOffset(from.X + width / 2, from.Y),
            Size = UDim2.fromOffset(width, height),
            BackgroundTransparency = 1,
            Parent = layer,
        })
        panel:SetAttribute("NoDrag", true)
        panelScale = create("UIScale", { Parent = panel })
        panelShadow = create("ImageLabel", {
            Position = UDim2.fromOffset(-24, -18),
            Size = UDim2.new(1, 48, 1, 44),
            BackgroundTransparency = 1,
            Image = Assets.Shadow,
            ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 1,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            ZIndex = 0,
            Parent = panel,
        })
        table.insert(window._popPanels, panel)
        box.Parent = panel
        window._controlsDirty = true
        setPopIcon(true)

        -- Lifts off the column: a spring up and out to its float spot, with
        -- the shadow deepening under it.
        local spot = clampSpot(group._popSpot or Vector2.new(from.X + width / 2 + 22, from.Y - 14), width, height)
        animating = true
        panelScale.Scale = 0.97
        tween(panel, { Position = UDim2.fromOffset(spot.X, spot.Y) }, 0.5, Enum.EasingStyle.Quint)
        tween(panelScale, { Scale = 1 }, 0.55, Enum.EasingStyle.Back)
        tween(panelShadow, { ImageTransparency = 0.35 }, 0.4)
        task.delay(0.5, function()
            if popGeneration == current then
                animating = false
            end
        end)

        -- Each frame: the panel follows the box's height (folding, rows
        -- coming and going), mirrors its visibility, and stays on screen.
        local thisPanel = panel
        stopPanel = window:_listen("Render", function()
            if panel ~= thisPanel or not thisPanel.Parent then
                return
            end
            local boxHeight = box.AbsoluteSize.Y / layerScale()
            if math.abs(thisPanel.Size.Y.Offset - boxHeight) > 0.5 then
                thisPanel.Size = UDim2.fromOffset(thisPanel.Size.X.Offset, boxHeight)
            end
            thisPanel.Visible = box.Visible
            if slot then
                slot.Visible = box.Visible
            end
            if not animating and not dragStart then
                local position = Vector2.new(thisPanel.Position.X.Offset, thisPanel.Position.Y.Offset)
                local clamped = clampSpot(position, thisPanel.Size.X.Offset, boxHeight)
                if (clamped - position).Magnitude > 0.5 then
                    thisPanel.Position = UDim2.fromOffset(clamped.X, clamped.Y)
                end
            end
        end)
    end

    local function dock(instant)
        if not popped then
            return
        end
        popped = false
        group._popped = false
        popGeneration += 1
        dragStart, dragMoved, suppressClick = nil, false, false
        closeInner()
        window:_closePopups()
        local oldPanel, oldSlot, oldStop, oldScale, oldShadow = panel, slot, stopPanel, panelScale, panelShadow
        panel, slot, stopPanel = nil, nil, nil
        setPopIcon(false)
        group._popSpot = Vector2.new(oldPanel.Position.X.Offset, oldPanel.Position.Y.Offset)
        local settled = false
        local function settle()
            if settled then
                return
            end
            settled = true
            if group._settleDock == settle then
                group._settleDock = nil
            end
            if oldStop then
                oldStop()
            end
            local index = table.find(window._popPanels, oldPanel)
            if index then
                table.remove(window._popPanels, index)
            end
            -- Back into the column, unless it was popped again meanwhile.
            if box.Parent == oldPanel then
                if oldSlot and oldSlot.Parent and not group._destroyed then
                    box.Parent = oldSlot.Parent
                    box.LayoutOrder = oldSlot.LayoutOrder
                end
            end
            if oldSlot then
                oldSlot:Destroy()
            end
            if box.Parent ~= oldPanel then
                oldPanel:Destroy()
            end
            animating = false
            window._controlsDirty = true
        end
        group._settleDock = settle
        -- Flies home only when its slot is on screen; otherwise (another tab,
        -- the window hidden) it just drops back into place.
        local canFly = not instant and oldSlot and oldSlot.Parent and window.Root.Visible and box.Visible
            and oldSlot.AbsoluteSize.X > 0 and isShown(oldSlot, window.Body, oldSlot.AbsolutePosition + oldSlot.AbsoluteSize / 2)
        if not canFly then
            settle()
            return
        end
        animating = true
        local scale = layerScale()
        local height = box.AbsoluteSize.Y / scale
        local width = oldSlot.AbsoluteSize.X / scale
        tween(oldSlot, { Size = UDim2.new(1, 0, 0, height) }, 0.36, Enum.EasingStyle.Quint)
        local oldLabel = oldSlot:FindFirstChildWhichIsA("TextLabel")
        if oldLabel then
            tween(oldLabel, { TextTransparency = 1 }, 0.12)
        end
        -- The slot's top stays put as it grows, so its spot is the landing.
        local target = toLayer(oldSlot.AbsolutePosition)
        tween(oldPanel, {
            Position = UDim2.fromOffset(target.X + width / 2, target.Y),
            Size = UDim2.fromOffset(width, height),
        }, 0.36, Enum.EasingStyle.Quint)
        tween(oldScale, { Scale = 1 }, 0.2)
        tween(oldShadow, { ImageTransparency = 1 }, 0.3)
        task.delay(0.37, settle)
    end

    -- Dragging the floating panel by its header.
    header.InputBegan:Connect(function(input)
        if not popped or not isPress(input) or not panel then
            return
        end
        dragStart = Vector2.new(input.Position.X, input.Position.Y)
        dragOrigin = Vector2.new(panel.Position.X.Offset, panel.Position.Y.Offset)
        dragMoved = false
        suppressClick = false
    end)
    window:_listen("Changed", function(input)
        if not dragStart or not panel or not isMove(input) then
            return
        end
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
        if not dragMoved then
            if delta.Magnitude < (TOUCH and 8 or 5) then
                return
            end
            dragMoved, suppressClick = true, true
            animating = false
            closeInner()
            window:_closePopups()
            tween(panelScale, { Scale = 1.025 }, 0.18, Enum.EasingStyle.Quint)
            tween(panelShadow, { ImageTransparency = 0.15 }, 0.18)
        end
        local spot = clampSpot(dragOrigin + delta / layerScale(), panel.Size.X.Offset, panel.Size.Y.Offset)
        panel.Position = UDim2.fromOffset(spot.X, spot.Y)
    end, group)
    window:_listen("Ended", function(input)
        if not dragStart or not isPress(input) then
            return
        end
        dragStart = nil
        if dragMoved and panel then
            dragMoved = false
            tween(panelScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
            tween(panelShadow, { ImageTransparency = 0.35 }, 0.3)
            group._popSpot = Vector2.new(panel.Position.X.Offset, panel.Position.Y.Offset)
        end
    end, group)
    if popButton then
        popButton.MouseEnter:Connect(function()
            tween(popButton, { BackgroundTransparency = 0 }, 0.15)
            tween(popIcon, { ImageColor3 = Theme.Text }, 0.15)
        end)
        popButton.MouseLeave:Connect(function()
            tween(popButton, { BackgroundTransparency = 1 }, 0.25)
            tween(popIcon, { ImageColor3 = Theme.Muted }, 0.25)
        end)
        popButton.MouseButton1Click:Connect(function()
            if popped then
                dock()
            else
                popOut()
            end
        end)
    end

    header.MouseButton1Click:Connect(function()
        if suppressClick then
            suppressClick = false
            return
        end
        if isTap() then
            setCollapsed(not collapsed)
        end
    end)

    function group:PopOut()
        popOut()
    end
    function group:Dock()
        dock()
    end
    function group:IsPoppedOut()
        return popped
    end
    function group:SetCollapsed(value)
        setCollapsed(value)
    end
    function group:Collapse()
        setCollapsed(true)
    end
    function group:Expand()
        setCollapsed(false)
    end
    function group:IsCollapsed()
        return collapsed
    end
    function group:SetTitle(text)
        group.Name = tostring(text)
        title.Text = group.Name
    end
    group._userVisible = opts.Visible ~= false
    function group:IsVisible()
        return group._userVisible
    end
    function group:SetVisible(visible)
        visible = visible and true or false
        if visible == group._userVisible then
            return
        end
        group._userVisible = visible
        if not visible then
            for _, element in ipairs(group._items) do
                if element._onHide then
                    element._onHide()
                end
                if element.Open and type(element.SetOpen) == "function" then
                    element:SetOpen(false)
                end
            end
        end
        box.Visible = visible
        window._controlsDirty = true
    end
    if not group._userVisible then
        box.Visible = false
    end
    function group:Destroy()
        for index = #group._items, 1, -1 do
            local element = group._items[index]
            if type(element.Destroy) == "function" then
                element:Destroy()
            end
        end
        local owner = group.Parent
        local index = table.find(owner._groupboxes, group)
        if index then
            table.remove(owner._groupboxes, index)
        end
        set.Counts[side] = math.max(set.Counts[side] - 1, 0)
        dock(true)
        group._destroyed = true
        window._controlsDirty = true
        box:Destroy()
    end

    if opts.Collapsed then
        setCollapsed(true, true)
    end
    if opts.PoppedOut then
        task.defer(popOut)
    end
    return group
end

local function sideGroupbox(side)
    return function(self, opts, icon)
        opts = normalize(opts, { Title = "Name" })
        opts.Side = side
        return self:Groupbox(opts, icon)
    end
end

Tab.CreateGroupbox = Tab.Groupbox
Tab.AddGroupbox = Tab.Groupbox
Tab.AddLeftGroupbox = sideGroupbox("Left")
Tab.AddRightGroupbox = sideGroupbox("Right")

-- Button rows: equal-width buttons side by side.

function Tab:ButtonRow(opts)
    local specs = type(opts) == "table" and (opts.Buttons or opts) or {}
    local compact = metricsOf(self).Compact
    local boxHeight = TOUCH and 34 or 30
    local frame = card(self, "Frame", boxHeight + (compact and 4 or 14), {})
    local inset = compact and 14 or 7
    local holder = create("Frame", {
        Position = UDim2.fromOffset(inset, compact and 2 or 7),
        Size = UDim2.new(1, -inset * 2, 0, boxHeight),
        BackgroundTransparency = 1,
        Parent = frame,
    })
    local count = math.max(#specs, 1)
    local handle = { Buttons = {} }
    local names = {}
    for index, spec in ipairs(specs) do
        if type(spec) == "string" then
            spec = { Name = spec }
        end
        local text = spec.Name or spec.Title or "Button"
        table.insert(names, text)
        local button, text_ = softButton(holder, text, {
            Position = UDim2.new((index - 1) / count, (index - 1) * 6 / count, 0, 0),
            Size = UDim2.new(1 / count, -6 * (count - 1) / count, 1, 0),
        }, function()
            safeCall(spec.Callback)
        end)
        text_.TextSize = 13
        if spec.Style == "Primary" then
            tween(button, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.12 }, 0)
            tween(text_, { TextColor3 = Theme.AccentDark }, 0)
        elseif spec.Style == "Danger" then
            tween(text_, { TextColor3 = Theme.Error }, 0)
        end
        handle.Buttons[index] = { Button = button, Label = text_ }
    end
    function handle:SetText(index, text)
        local entry = handle.Buttons[index]
        if entry then
            entry.Label.Text = tostring(text)
        end
    end
    return finishElement(self, { Name = table.concat(names, " "), Visible = not (type(opts) == "table" and opts.Visible == false) }, handle, frame, "ButtonRow")
end

-- A text box with an action button beside it, for naming new configs and themes.
-- Without buttonText the box spans the row on its own.
local function actionInput(tab, placeholder, buttonText, callback)
    local boxHeight = TOUCH and 34 or 30
    local frame = card(tab, "Frame", boxHeight + 4, {})
    local inset = metricsOf(tab).Compact and 14 or 7
    local box
    local button = buttonText and softButton(frame, buttonText, {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -inset, 0, 2),
        Size = UDim2.fromOffset(0, boxHeight),
        AutomaticSize = Enum.AutomaticSize.X,
    }, function()
        safeCall(callback, box.Text)
    end)
    local holder = create("Frame", {
        Position = UDim2.fromOffset(inset, 2),
        Size = UDim2.new(1, -(inset * 2 + (button and 70 or 0)), 0, boxHeight),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = frame,
    })
    corner(holder, UDim.new(0, 6))
    local holderStroke = stroke(holder)
    box = create("TextBox", {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -16, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = placeholder,
        PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text,
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClearTextOnFocus = false,
        Parent = holder,
    })
    box.Focused:Connect(function()
        tween(holderStroke, { Color = Theme.StrokeHover }, 0.15)
    end)
    box.FocusLost:Connect(function(enterPressed)
        tween(holderStroke, { Color = Theme.Stroke }, 0.2)
        if enterPressed and box.Text ~= "" then
            safeCall(callback, box.Text)
        end
    end)
    if button then
        local function fit()
            local width = button.AbsoluteSize.X / tab.Window.Scale.Scale
            holder.Size = UDim2.new(1, -(inset * 2 + width + 6), 0, boxHeight)
        end
        button:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
        task.defer(fit)
    end
    return finishElement(tab, { Name = placeholder }, {
        Get = function()
            return box.Text
        end,
        Set = function(_, value)
            box.Text = tostring(value or "")
        end,
    }, frame, "ActionInput")
end

local function trim(text)
    return (tostring(text or ""):match("^%s*(.-)%s*$"))
end

-- Managers go in their own groupbox when added straight to a tab.
local function managerHost(tab, opts, name, icon)
    if tab._groupbox then
        return tab
    end
    local host = tab:Groupbox({ Name = opts.Name or name, Icon = opts.Icon or icon, Side = opts.Side })
    -- Library chrome, not a script feature: the feature list skips it.
    host._manager = true
    return host
end

function Tab:ConfigManager(opts)
    opts = normalize(opts, { Title = "Name" })
    local host = managerHost(self, opts, "Configs", "folder")
    local window = self.Window
    local manager = {}
    local list, status, modeList

    local function notify(ok, title, detail)
        window:Notify({ Title = title, Content = detail, Type = ok and "Success" or "Error", Duration = 3 })
    end

    local function refreshStatus()
        status:Set(("loaded: %s   |   autoload: %s"):format(window.LoadedConfig or "none", window:GetAutoload() or "none"))
    end

    local function pickedName()
        local name = list:Get()
        if not name then
            notify(false, "No config selected", "Pick one from the list first")
        end
        return name
    end

    local nameInput = actionInput(host, opts.Placeholder or "config name", nil, function(text)
        manager:Create(text)
    end)
    local names = window:ListConfigs()
    local initial = window.LoadedConfig or window:GetAutoload()
    list = host:Dropdown({
        Stacked = true,
        Options = names,
        Default = table.find(names, initial) and initial or nil,
        EmptyText = "--",
        NoneText = "--",
    })
    host:ButtonRow({
        { Name = "Create", Callback = function() manager:Create(nameInput:Get()) end },
        { Name = "Save", Callback = function() manager:Save() end },
    })
    host:ButtonRow({
        { Name = "Load", Callback = function() manager:Load() end },
        { Name = "Delete", Style = "Danger", Callback = function() manager:Delete() end },
    })
    host:ButtonRow({
        { Name = "Set autoload", Callback = function() manager:SetAutoload() end },
        { Name = "Clear autoload", Callback = function() manager:ClearAutoload() end },
    })
    host:ButtonRow({
        { Name = "Rename", Callback = function() manager:Rename(nil, nameInput:Get()) end },
        { Name = "Reset", Style = "Danger", Callback = function() manager:Reset() end },
    })
    status = host:Label("loaded: none   |   autoload: none")
    modeList = host:Dropdown({
        Name = "Autoload mode",
        Stacked = true,
        Options = { "All accounts", "This account" },
        Default = window:GetAutoloadMode() == "Account" and "This account" or "All accounts",
        AllowNone = false,
        Callback = function(choice)
            manager:SetAutoloadMode(choice == "This account" and "Account" or "Global")
        end,
    })
    host:Button({ Name = "Refresh list", Callback = function() manager:Refresh() end })
    host:Divider({ Text = "share" })
    host:Button({ Name = "Copy code", Callback = function() manager:Export() end })
    local codeInput = actionInput(host, "paste a config code...", nil, function(text)
        manager:Import(text)
    end)
    host:Button({ Name = "Import code", Callback = function() manager:Import(codeInput:Get()) end })

    function manager:Refresh()
        local names = window:ListConfigs()
        local keep = list:Get()
        list:Refresh(names, true)
        if keep and not table.find(names, keep) then
            list:Set(window.LoadedConfig and table.find(names, window.LoadedConfig) and window.LoadedConfig or nil, true)
        end
        refreshStatus()
    end

    local function select(name)
        manager:Refresh()
        list:Set(name, true)
    end

    function manager:Create(name)
        name = trim(name)
        if name == "" then
            notify(false, "Name the config", "Type a name before creating it")
            return
        end
        if not validConfigName(name) then
            notify(false, "Invalid name", 'Names cannot contain \\ / : * ? " < > |')
            return
        end
        local ok, err = window:SaveConfig(name)
        if ok then
            window.LoadedConfig = name
            nameInput:Set("")
            select(name)
        end
        notify(ok, ok and "Config created" or "Create failed", ok and name or tostring(err))
    end

    function manager:Save(name)
        name = name or list:Get()
        if not name then
            local typed = trim(nameInput:Get())
            if typed == "" then
                notify(false, "No config selected", "Pick one from the list or type a name")
                return
            end
            return manager:Create(typed)
        end
        local ok, err = window:SaveConfig(name)
        if ok then
            window.LoadedConfig = name
            refreshStatus()
        end
        notify(ok, ok and "Config saved" or "Save failed", ok and name or tostring(err))
    end

    function manager:Load(name)
        name = name or pickedName()
        if not name then
            return
        end
        local ok, err = window:LoadConfig(name)
        notify(ok, ok and "Config loaded" or "Load failed", ok and name or tostring(err))
    end

    function manager:Delete(name)
        name = name or pickedName()
        if not name then
            return
        end
        window:Confirm({
            Title = "Delete config",
            Content = "Remove " .. name .. "? This cannot be undone.",
            Icon = "trash-2",
            ConfirmText = "Delete",
            Callback = function()
                local ok, err = window:DeleteConfig(name)
                if ok then
                    if window:GetAutoload("Account") == name then
                        window:SetAutoload(nil, "Account")
                    end
                    if window:GetAutoload("Global") == name then
                        window:SetAutoload(nil, "Global")
                    end
                    list:Set(nil, true)
                end
                manager:Refresh()
                notify(ok, ok and "Config deleted" or "Delete failed", ok and name or tostring(err))
            end,
        })
    end

    function manager:Rename(name, newName)
        name = name or pickedName()
        if not name then
            return
        end
        newName = trim(newName)
        if newName == "" then
            notify(false, "Name the config", "Type the new name in the name box")
            return
        end
        if not validConfigName(newName) then
            notify(false, "Invalid name", 'Names cannot contain \\ / : * ? " < > |')
            return
        end
        local ok, err = window:RenameConfig(name, newName)
        if ok then
            nameInput:Set("")
            select(newName)
        end
        notify(ok, ok and "Config renamed" or "Rename failed", ok and (name .. " -> " .. newName) or tostring(err))
    end

    function manager:Reset()
        window:Confirm({
            Title = "Reset settings",
            Content = "Put every setting back to its default and delete this script's folder? Saved configs, themes and autoload are removed for good.",
            Icon = "rotate-ccw",
            ConfirmText = "Reset",
            Callback = function()
                window:ResetConfig()
                local wiped = window:ClearWorkspace()
                window:_applyDefaultTheme()
                list:Set(nil, true)
                manager:Refresh()
                modeList:Set("All accounts", true)
                notify(wiped, wiped and "Settings reset" or "Reset incomplete",
                    wiped and "Everything is back to its default" or "Some files in " .. window.ConfigFolder .. " could not be deleted")
            end,
        })
    end

    function manager:SetAutoload(name)
        name = name or pickedName()
        if not name then
            return
        end
        local ok, err = window:SetAutoload(name)
        notify(ok, ok and "Autoload set" or "Autoload failed", ok and name or tostring(err))
    end

    function manager:ClearAutoload()
        local current = window:GetAutoload()
        if not current then
            notify(false, "No autoload", "Nothing is set to autoload")
            return
        end
        local ok, err = window:SetAutoload(nil)
        notify(ok, ok and "Autoload cleared" or "Clear failed", ok and current or tostring(err))
    end

    function manager:ToggleAutoload(name)
        name = name or pickedName()
        if not name then
            return
        end
        if window:GetAutoload() == name then
            manager:ClearAutoload()
        else
            manager:SetAutoload(name)
        end
    end

    function manager:SetAutoloadMode(mode)
        local ok, err = window:SetAutoloadMode(mode)
        local label_ = mode == "Account" and "This account" or "All accounts"
        if modeList:Get() ~= label_ then
            modeList:Set(label_, true)
        end
        notify(ok ~= false, ok ~= false and "Autoload mode" or "Mode change failed", ok ~= false and label_ or tostring(err))
    end

    function manager:Export(name)
        local code, err = window:ExportConfig(name)
        if not code then
            notify(false, "Export failed", tostring(err))
            return nil
        end
        window:CopyToClipboard(code, "Config code")
        return code
    end

    function manager:Import(code)
        code = trim(code)
        if code == "" then
            notify(false, "Nothing to import", "Paste a config code first")
            return
        end
        local data, info = window:DecodeConfig(code)
        if not data then
            notify(false, "Import failed", "Invalid config code")
            return
        end
        -- The typed name wins; otherwise the code's own name, never overwriting a config.
        local saveAs = trim(nameInput:Get())
        if saveAs == "" then
            saveAs = nil
            if validConfigName(info.Name) then
                saveAs = info.Name
                local index = 2
                while window:ConfigExists(saveAs) do
                    saveAs = ("%s (%d)"):format(info.Name, index)
                    index += 1
                end
            end
        elseif not validConfigName(saveAs) then
            notify(false, "Invalid name", 'Names cannot contain \\ / : * ? " < > |')
            return
        end
        local function run()
            local ok, err = window:ImportConfig(code, saveAs, true)
            if ok then
                codeInput:Set("")
                if saveAs then
                    nameInput:Set("")
                    select(saveAs)
                end
            end
            notify(ok, ok and "Config imported" or "Import failed", ok and (saveAs or "Applied to current settings") or tostring(err))
        end
        if info.Folder and info.Folder ~= window.ConfigFolder then
            window:Confirm({
                Title = "Different script",
                Content = ("This config was made for %s. Import it anyway? Only matching settings are applied."):format(info.Folder),
                Icon = "triangle-alert",
                ConfirmText = "Import",
                Callback = run,
            })
            return
        end
        run()
    end

    local disconnect = window:OnConfigChanged(function()
        -- Configs can arrive from elsewhere (a cloud install), so the list is reread.
        manager:Refresh()
        if window.LoadedConfig and list:Get() == nil then
            list:Set(window.LoadedConfig, true)
        end
    end)
    status._listeners = status._listeners or {}
    table.insert(status._listeners, disconnect)

    refreshStatus()
    return manager
end

local PRESET_ORDER = {
    "Midnight", "Nebula", "Synthwave", "Sakura", "Velvet", "Rose", "Crimson", "Sunset", "Amber", "Gold",
    "Cyber", "Toxic", "Matcha", "Emerald", "Aurora", "Ocean", "Frost", "Abyss", "Mono",
    "Halloween", "Haunted", "Christmas", "Valentine", "Lunar", "Tropical", "Dracula", "Coffee",
}

local function presetNames()
    local names, seen = {}, {}
    for _, name in ipairs(PRESET_ORDER) do
        if Library.ThemePresets[name] then
            table.insert(names, name)
            seen[name] = true
        end
    end
    local extra = {}
    for name in pairs(Library.ThemePresets) do
        if not seen[name] then
            table.insert(extra, name)
        end
    end
    table.sort(extra)
    for _, name in ipairs(extra) do
        table.insert(names, name)
    end
    return names
end

function Tab:ThemeManager(opts)
    opts = normalize(opts, { Title = "Name" })
    local host = managerHost(self, opts, "Themes", "palette")
    local window = self.Window
    local manager = {}
    local themes, status, defaultRow, presets
    local weather, weatherMode, dim, transparent, dragSkeleton, islandStyle
    local background, backgroundInput, backgroundOpacity, backgroundLabel
    local uiScale, density, adaptive, cornerRadius

    local function notify(ok, title, detail)
        window:Notify({ Title = title, Content = detail, Type = ok and "Success" or "Error", Duration = 3 })
    end

    local function refreshStatus()
        local current = window:GetDefaultTheme()
        status:Set("Default theme: " .. (current or "none"))
        local picked = themes:Get() or presets:Get()
        defaultRow:SetText(2, (picked and picked == current) and "Clear Default" or "Set Default")
    end

    local function pickedTheme()
        local name = themes:Get()
        if not name then
            notify(false, "No theme selected", "Pick one from the list first")
        end
        return name
    end

    presets = host:Dropdown({
        Name = "Preset",
        Options = presetNames(),
        Default = Library.ThemePresets[Library.ThemeName or ""] and Library.ThemeName or nil,
        NoneText = "custom",
        AllowNone = false,
        Callback = function(name)
            if name then
                Library:SetTheme(name)
                themes:Set(nil, true)
                refreshStatus()
            end
        end,
    })
    local labels = { None = "None", Snow = "Snow", Rain = "Rain", Ember = "Hell Fire", Sakura = "Sakura", Fireflies = "Fireflies", Matrix = "Matrix" }
    if window._backdrop and opts.Weather ~= false then
        weather = host:Dropdown({
            Name = "Weather",
            Options = { "Snow", "Rain", "Hell Fire", "Sakura", "Fireflies", "Matrix", "None" },
            Default = labels[window.Weather] or "None",
            AllowNone = false,
            Callback = function(name)
                if name then
                    window:SetWeather(name)
                end
            end,
        })
    end
    if window._backdrop and opts.Weather ~= false then
        weatherMode = host:Dropdown({
            Name = "Weather Mode",
            Options = { "Screen", "UI" },
            Default = window.WeatherMode,
            AllowNone = false,
            Callback = function(mode)
                if mode then
                    window:SetWeatherMode(mode)
                end
            end,
        })
    end
    if window._backdrop and opts.Dim ~= false then
        dim = host:Toggle({
            Name = "Dim",
            Default = window._backdropDim,
            Callback = function(value)
                window:SetDim(value)
            end,
        })
    end
    if opts.Transparent ~= false then
        transparent = host:Toggle({
            Name = "Transparent",
            Default = window.Transparent == true,
            Callback = function(value)
                window:SetTransparent(value)
            end,
        })
    end
    if opts.DragSkeleton ~= false and opts.DragStyle ~= false then
        dragSkeleton = host:Dropdown({
            Name = "Drag Style",
            Options = Library.DragStyles,
            Default = window.DragStyle,
            AllowNone = false,
            Callback = function(style)
                if style then
                    window:SetDragStyle(style)
                end
            end,
        })
    end
    if opts.IslandStyle ~= false then
        islandStyle = host:Dropdown({
            Name = "Dynamic Island",
            Options = Library.IslandStyles,
            Default = window.IslandStyle,
            AllowNone = false,
            Callback = function(style)
                if style then
                    window:SetIslandStyle(style)
                end
            end,
        })
    end
    if opts.AdaptiveSize ~= false then
        adaptive = host:Toggle({
            Name = "Adaptive Size",
            Default = window:GetAdaptiveSize(),
            Callback = function(value)
                window:SetAdaptiveSize(value)
            end,
        })
    end
    if opts.Scale ~= false then
        uiScale = host:Slider({
            Name = "UI Scale",
            Min = 60,
            Max = 150,
            Increment = 5,
            Default = math.floor(window:GetUIScale() * 100 + 0.5),
            Suffix = "%",
            -- Rescaling mid-drag would move the slider out from under the
            -- pointer, so a drag applies on release.
            Callback = function(value)
                if not (uiScale and uiScale.Dragging) then
                    window:SetUIScale(value / 100)
                end
            end,
            OnRelease = function(value)
                window:SetUIScale(value / 100)
            end,
        })
    end
    if opts.Density ~= false then
        density = host:Dropdown({
            Name = "Density",
            Options = { "Compact", "Default", "Comfortable" },
            Default = Library.Density,
            AllowNone = false,
            Callback = function(mode)
                if mode then
                    Library:SetDensity(mode)
                end
            end,
        })
    end
    if opts.CornerRadius ~= false then
        cornerRadius = host:Slider({
            Name = "Corner Radius",
            Min = 0,
            Max = 20,
            Increment = 1,
            Default = Library:GetCornerRadius(),
            Suffix = "px",
            Callback = function(value)
                Library:SetCornerRadius(value)
            end,
        })
    end
    if opts.Background ~= false then
        -- The dropdown shows listed images by name, "custom" for ids and links.
        backgroundLabel = function(source)
            if source == nil or source == "" then
                return "None"
            end
            return table.find(window:ListBackgrounds(), source) and source or nil
        end
        local function applyBackground(source, fromList)
            task.spawn(function()
                local ok, err = window:SetBackground(source)
                if ok and not fromList then
                    background:Set(backgroundLabel(window.Background), true)
                elseif not ok and err ~= "replaced by a newer background" then
                    notify(false, "Background failed", tostring(err))
                end
            end)
        end
        local options = window:ListBackgrounds()
        table.insert(options, 1, "None")
        background = host:Dropdown({
            Name = "Background",
            Options = options,
            Default = backgroundLabel(window.Background),
            NoneText = "custom",
            AllowNone = false,
            Callback = function(name)
                if name then
                    applyBackground(name, true)
                end
            end,
        })
        backgroundInput = actionInput(host, "image id or url", "Set", function(text)
            text = trim(text)
            if text == "" then
                notify(false, "No image", "Paste an image id or link first")
                return
            end
            applyBackground(text)
        end)
        backgroundOpacity = host:Slider({
            Name = "Background Opacity",
            Min = 0,
            Max = 100,
            Default = math.floor((1 - window.BackgroundTransparency) * 100 + 0.5),
            Suffix = "%",
            Callback = function(value)
                window:SetBackgroundTransparency(1 - value / 100)
            end,
        })
    end
    local nameInput = actionInput(host, opts.Placeholder or "theme name", "Create", function(text)
        manager:Create(text)
    end)
    themes = host:Dropdown({
        Name = "Theme",
        Options = window:ListThemes(),
        Default = (function()
            local current = window:GetDefaultTheme()
            return current and not Library.ThemePresets[current] and current or nil
        end)(),
        EmptyText = "no themes",
        NoneText = "select",
        Callback = function()
            refreshStatus()
        end,
    })
    host:ButtonRow({
        { Name = "Save", Callback = function() manager:Save() end },
        { Name = "Load", Callback = function() manager:Load() end },
    })
    defaultRow = host:ButtonRow({
        { Name = "Delete", Callback = function() manager:Delete() end },
        { Name = "Set Default", Callback = function() manager:ToggleDefault() end },
    })
    status = host:Label("Default theme: none")

    function manager:Refresh()
        themes:Refresh(window:ListThemes(), true)
        if background then
            local options = window:ListBackgrounds()
            table.insert(options, 1, "None")
            background:Refresh(options, true, true)
        end
        refreshStatus()
    end

    function manager:Create(name)
        name = trim(name)
        if name == "" then
            notify(false, "Name the theme", "Type a name before creating it")
            return
        end
        if Library.ThemePresets[name] then
            notify(false, "Name taken", name .. " is a built-in preset")
            return
        end
        local ok, err = window:SaveTheme(name)
        manager:Refresh()
        if ok then
            themes:Set(name, true)
            nameInput:Set("")
            refreshStatus()
        end
        notify(ok, ok and "Theme created" or "Create failed", ok and name or tostring(err))
    end

    function manager:Save(name)
        name = name or pickedTheme()
        if not name then
            return
        end
        local ok, err = window:SaveTheme(name)
        notify(ok, ok and "Theme saved" or "Save failed", ok and name or tostring(err))
    end

    function manager:Load(name)
        name = name or pickedTheme()
        if not name then
            return
        end
        local ok, err = window:LoadTheme(name)
        if ok then
            presets:Set(nil, true)
        end
        notify(ok ~= false, ok and "Theme loaded" or "Load failed", ok and name or tostring(err))
    end

    function manager:Delete(name)
        name = name or pickedTheme()
        if not name then
            return
        end
        window:Confirm({
            Title = "Delete theme",
            Content = "Remove " .. name .. "? This cannot be undone.",
            Icon = "trash-2",
            ConfirmText = "Delete",
            Callback = function()
                local ok, err = window:DeleteTheme(name)
                manager:Refresh()
                notify(ok, ok and "Theme deleted" or "Delete failed", ok and name or tostring(err))
            end,
        })
    end

    function manager:ToggleDefault(name)
        name = name or themes:Get() or presets:Get()
        if not name then
            notify(false, "Nothing selected", "Pick a theme or a preset first")
            return
        end
        local clearing = window:GetDefaultTheme() == name
        local ok, err = window:SetDefaultTheme(not clearing and name or nil)
        refreshStatus()
        notify(ok ~= false, clearing and "Default cleared" or "Default theme set", ok ~= false and name or tostring(err))
    end

    if opts.Customize ~= false then
        host:Divider()
        local fields = opts.Colors or {
            { "Accent", "Accent" },
            { "Background", "Background" },
            { "Surface2", "Surface" },
            { "Text", "Text" },
            { "Muted", "Muted text" },
        }
        for _, field in ipairs(fields) do
            local key, title = field[1], field[2] or field[1]
            local pending, scheduled = nil, false
            local picker
            picker = host:ColorPicker({
                Name = title,
                Default = Theme[key],
                Callback = function(color)
                    -- Dragging the picker fires every frame; repaint at most
                    -- a dozen times a second.
                    pending = color
                    if scheduled then
                        return
                    end
                    scheduled = true
                    task.delay(0.08, function()
                        scheduled = false
                        Library:SetTheme({ [key] = pending }, true)
                        presets:Set(nil, true)
                    end)
                end,
            })
            table.insert(Library._themeListeners, function()
                if picker.Value ~= Theme[key] then
                    picker:Set(Theme[key], true)
                end
            end)
        end
    end

    -- One hidden flag carries the palette and the look settings above, so
    -- configs save and load the theme. Not a flag per toggle: flagged toggles
    -- would count as running features on the minimized island.
    if opts.Flag ~= false then
        local flag = type(opts.Flag) == "string" and opts.Flag or "__Theme"
        local look = { _type = "Theme", _searchName = "Theme", _searchKey = "theme", _listeners = {} }

        function look:Get()
            local colors = {}
            for _, key in ipairs(THEME_KEYS) do
                colors[key] = colorToHex(Theme[key])
            end
            return {
                Name = presets:Get() or themes:Get(),
                Colors = colors,
                Weather = weather and window.Weather or nil,
                WeatherMode = weatherMode and window.WeatherMode or nil,
                -- if-expressions, not and/or: a switched-off value is false, not nil.
                Dim = if dim then window._backdropDim == true else nil,
                Transparent = if transparent then window.Transparent == true else nil,
                DragStyle = dragSkeleton and window.DragStyle or nil,
                IslandStyle = islandStyle and window.IslandStyle or nil,
                CornerRadius = cornerRadius and Library:GetCornerRadius() or nil,
                UIScale = uiScale and window:GetUIScale() or nil,
                AdaptiveSize = if adaptive then window:GetAdaptiveSize() else nil,
                Density = density and Library.Density or nil,
                -- "" is no background; a missing field leaves it alone on load.
                Background = background and (window.Background or "") or nil,
                BackgroundTransparency = background and window.BackgroundTransparency or nil,
            }
        end

        function look:Set(value)
            if type(value) ~= "table" then
                return
            end
            if type(value.Colors) == "table" then
                Library:SetTheme(value.Colors)
            end
            local name = type(value.Name) == "string" and value.Name or nil
            if name and Library.ThemePresets[name] then
                Library.ThemeName = name
                presets:Set(name, true)
                themes:Set(nil, true)
            else
                if name then
                    Library.ThemeName = name
                end
                presets:Set(nil, true)
                themes:Set(name and table.find(window:ListThemes(), name) and name or nil, true)
            end
            if weather and type(value.Weather) == "string" then
                window:SetWeather(value.Weather)
                weather:Set(labels[window.Weather] or "None", true)
            end
            if weatherMode and type(value.WeatherMode) == "string" then
                window:SetWeatherMode(value.WeatherMode)
                weatherMode:Set(window.WeatherMode, true)
            end
            if dim and type(value.Dim) == "boolean" then
                window:SetDim(value.Dim)
                dim:Set(value.Dim, true)
            end
            if transparent and type(value.Transparent) == "boolean" then
                window:SetTransparent(value.Transparent)
                transparent:Set(value.Transparent, true)
            end
            if dragSkeleton and type(value.DragStyle) == "string" then
                dragSkeleton:Set(window:SetDragStyle(value.DragStyle), true)
            elseif dragSkeleton and type(value.DragSkeleton) == "boolean" then
                -- Configs saved before drag styles.
                window:SetDragSkeleton(value.DragSkeleton)
                dragSkeleton:Set(window.DragStyle, true)
            end
            if islandStyle and type(value.IslandStyle) == "string" then
                islandStyle:Set(window:SetIslandStyle(value.IslandStyle), true)
            end
            if cornerRadius and tonumber(value.CornerRadius) then
                cornerRadius:Set(Library:SetCornerRadius(value.CornerRadius), true)
            end
            if adaptive and type(value.AdaptiveSize) == "boolean" then
                window:SetAdaptiveSize(value.AdaptiveSize)
                adaptive:Set(value.AdaptiveSize, true)
            end
            if uiScale and tonumber(value.UIScale) then
                window:SetUIScale(tonumber(value.UIScale))
                uiScale:Set(math.floor(window:GetUIScale() * 100 + 0.5), true)
            end
            if density and type(value.Density) == "string" then
                density:Set(Library:SetDensity(value.Density), true)
            end
            if background and tonumber(value.BackgroundTransparency) then
                window:SetBackgroundTransparency(tonumber(value.BackgroundTransparency))
                backgroundOpacity:Set(math.floor((1 - window.BackgroundTransparency) * 100 + 0.5), true)
            end
            if background and type(value.Background) == "string" and value.Background ~= (window.Background or "") then
                local source = value.Background
                background:Set(backgroundLabel(source), true)
                -- A web image may download first; don't hold up the rest of the config.
                task.spawn(window.SetBackground, window, source)
            end
            refreshStatus()
        end

        Library.Flags[flag] = look
        window:_flagCreated(flag, look)
    end

    -- A reset wipes the themes folder, so drop the stale list.
    window._workspaceListeners = window._workspaceListeners or {}
    table.insert(window._workspaceListeners, function()
        themes:Set(nil, true)
        manager:Refresh()
    end)

    refreshStatus()
    return manager
end

Tab.CreateButtonRow = Tab.ButtonRow
Tab.CreateConfigManager = Tab.ConfigManager
Tab.CreateThemeManager = Tab.ThemeManager

-- Status: read-only key/value lines, mostly for groupboxes, in several styles.

local STATUS_HEIGHT = { Plain = 22, Row = 24, Badge = 28, Dot = 24, Bar = 38, Stat = 46 }

-- Tone: a theme key, a Color3 or "#rrggbb".
local function toneColor(tone)
    return Library._color(tone) or Theme.Accent
end

local function formatNumber(value)
    if value == math.floor(value) then
        return tostring(math.floor(value))
    end
    return string.format("%.1f", value)
end

local function parseFraction(value, max)
    if type(value) == "number" and type(max) == "number" then
        return value, max
    end
    if type(value) == "string" then
        local cleaned = (value:gsub(",", ""))
        local current, total = cleaned:match("^%s*(%-?[%d%.]+)%s*/%s*(%-?[%d%.]+)")
        if current then
            return tonumber(current), tonumber(total)
        end
    end
    return nil, nil
end

function Tab:Status(opts)
    opts = normalize(opts, { Title = "Name", Text = "Value", Content = "Value", CurrentValue = "Value", Default = "Value" })
    local style = STATUS_HEIGHT[opts.Style] and opts.Style or "Plain"
    local compact = metricsOf(self).Compact
    local window = self.Window
    local height = STATUS_HEIGHT[style]
    local pad = compact and 0 or 8
    local frame = card(self, "Frame", height + pad * 2, opts)
    local holder = create("Frame", {
        Position = UDim2.fromOffset(14, pad),
        Size = UDim2.new(1, -28, 0, height),
        BackgroundTransparency = 1,
        Parent = frame,
    })

    local handle = { Value = opts.Value, Max = opts.Max, Tone = opts.Tone or "Accent", Name = opts.Name or "", Color = opts.Color or opts.ValueColor }
    local keyLabel, valueLabel, chip, chipStroke, dot, pulse, fill
    local tinted = false

    local function keyText()
        return style == "Plain" and (handle.Name .. ":") or handle.Name
    end

    if style == "Plain" then
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
            Parent = holder,
        })
        keyLabel = label({
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            TextSize = 12,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            TextTruncate = Enum.TextTruncate.None,
            LayoutOrder = 1,
            Parent = holder,
        })
        valueLabel = label({
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            TextSize = 12,
            TextColor3 = Theme.Text,
            TextTruncate = Enum.TextTruncate.None,
            LayoutOrder = 2,
            Parent = holder,
        })
    elseif style == "Stat" then
        keyLabel = label({
            Position = UDim2.fromOffset(0, 3),
            Size = UDim2.new(1, 0, 0, 14),
            TextSize = 11,
            TextColor3 = Theme.Muted,
            Parent = holder,
        })
        valueLabel = label({
            Position = UDim2.fromOffset(0, 18),
            Size = UDim2.new(1, 0, 0, 24),
            TextSize = 20,
            FontFace = Fonts.Bold,
            TextColor3 = Theme.Text,
            Parent = holder,
        })
    else
        local keyX = 0
        if style == "Dot" then
            keyX = 18
            pulse = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 5, 0.5, 0),
                Size = UDim2.fromOffset(8, 8),
                BackgroundColor3 = toneColor(handle.Tone),
                BackgroundTransparency = 0.4,
                BorderSizePixel = 0,
                Parent = holder,
            })
            corner(pulse, UDim.new(1, 0))
            dot = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 5, 0.5, 0),
                Size = UDim2.fromOffset(8, 8),
                BackgroundColor3 = toneColor(handle.Tone),
                BorderSizePixel = 0,
                Parent = holder,
            })
            corner(dot, UDim.new(1, 0))
            if opts.Pulse ~= false then
                TweenService:Create(pulse, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), {
                    Size = UDim2.fromOffset(20, 20),
                    BackgroundTransparency = 1,
                }):Play()
            else
                pulse.Visible = false
            end
        end
        local rowHeight = style == "Bar" and 18 or height
        keyLabel = label({
            Position = UDim2.fromOffset(keyX, 0),
            Size = UDim2.new(0.55, -keyX, 0, rowHeight),
            TextSize = 12,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            Parent = holder,
        })
        if style == "Badge" then
            tinted = true
            chip = create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(0, 22),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = toneColor(handle.Tone),
                BackgroundTransparency = 0.86,
                BorderSizePixel = 0,
                Parent = holder,
            })
            corner(chip, UDim.new(1, 0))
            chipStroke = stroke(chip, toneColor(handle.Tone), 0.6)
            padding(chip, 10, 10)
            valueLabel = label({
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 12,
                TextColor3 = toneColor(handle.Tone),
                TextTruncate = Enum.TextTruncate.None,
                Parent = chip,
            })
        else
            valueLabel = label({
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0.45, 0, 0, rowHeight),
                TextSize = 12,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = holder,
            })
        end
        if style == "Bar" then
            local track = create("Frame", {
                Position = UDim2.fromOffset(0, 25),
                Size = UDim2.new(1, 0, 0, 5),
                BackgroundColor3 = Theme.Surface3,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = holder,
            })
            corner(track, UDim.new(1, 0))
            fill = create("Frame", {
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = toneColor(handle.Tone),
                BorderSizePixel = 0,
                Parent = track,
            })
            corner(fill, UDim.new(1, 0))
        end
    end

    local lastText = nil
    local function render(animate)
        keyLabel.Text = Library._rich(keyText())
        local value = handle.Value
        local text = value == nil and (opts.Placeholder or "-") or tostring(value)
        if style == "Bar" then
            local current, total = parseFraction(value, handle.Max)
            if current and total then
                handle.Max = total
                text = formatNumber(current) .. " / " .. formatNumber(total)
                local fraction = total > 0 and math.clamp(current / total, 0, 1) or 0
                tween(fill, { Size = UDim2.new(fraction, 0, 1, 0) }, animate and 0.4 or 0, Enum.EasingStyle.Quint)
            elseif type(value) == "number" and value <= 1 then
                text = string.format("%d%%", math.floor(value * 100 + 0.5))
                tween(fill, { Size = UDim2.new(math.clamp(value, 0, 1), 0, 1, 0) }, animate and 0.4 or 0, Enum.EasingStyle.Quint)
            end
        end
        text = Library._rich((opts.Prefix or "") .. text .. (opts.Suffix or ""))
        local changed = lastText ~= nil and text ~= lastText
        lastText = text
        valueLabel.Text = text
        local tone = toneColor(handle.Tone)
        local duration = animate and 0.25 or 0
        -- Color paints the whole value; inline tags still win over it.
        local valueColor = not tinted and Library._color(handle.Color) or Theme.Text
        if not tinted and not (changed and animate and opts.Flash ~= false) then
            tween(valueLabel, { TextColor3 = valueColor }, duration)
        end
        if chip then
            tween(chip, { BackgroundColor3 = tone }, duration)
            tween(chipStroke, { Color = tone }, duration)
            tween(valueLabel, { TextColor3 = tone }, duration)
        end
        if dot then
            tween(dot, { BackgroundColor3 = tone }, duration)
            tween(pulse, { BackgroundColor3 = tone }, 0)
        end
        if fill then
            tween(fill, { BackgroundColor3 = tone }, duration)
        end
        -- A brief accent flash marks a changed value.
        if changed and animate and not tinted and opts.Flash ~= false then
            tween(valueLabel, { TextColor3 = Theme.Accent }, 0.08)
            task.delay(0.1, function()
                if valueLabel.Parent then
                    tween(valueLabel, { TextColor3 = Library._color(handle.Color) or Theme.Text }, 0.45)
                end
            end)
        end
    end

    keyLabel.RichText = true
    valueLabel.RichText = true
    -- Theme tags in the text are baked to colours, so repaint on theme change.
    onTheme(holder, function()
        if lastText ~= nil then
            render(false)
        end
    end)

    function handle:Set(value, max)
        handle.Value = value
        if max ~= nil then
            handle.Max = max
        end
        render(true)
    end
    function handle:Get()
        return handle.Value
    end
    function handle:SetTone(tone)
        handle.Tone = tone
        render(true)
    end
    -- nil goes back to the normal text colour.
    function handle:SetColor(color)
        handle.Color = color
        render(true)
    end
    function handle:SetName(name)
        handle.Name = tostring(name)
        render(false)
    end
    function handle:Text()
        return valueLabel.Text
    end
    -- The value's resting colour, for the copy pinned on the minimized island.
    function handle._shownColor()
        if handle.Color ~= nil then
            return Library._color(handle.Color) or Theme.Text
        end
        if style == "Badge" or style == "Dot" or style == "Bar" then
            return toneColor(handle.Tone)
        end
        return Theme.Text
    end

    handle._listeners = {}
    if type(opts.Update) == "function" then
        local rate = math.max(tonumber(opts.UpdateRate) or 1, 0.05)
        local running = true
        table.insert(handle._listeners, function()
            running = false
        end)
        task.spawn(function()
            while running and frame.Parent do
                local ok, value, extra = isolatedCall(opts.Update)
                if ok then
                    if value ~= nil then
                        handle.Value = value
                    end
                    if type(extra) == "number" then
                        handle.Max = extra
                    elseif type(extra) == "string" or typeof(extra) == "Color3" then
                        handle.Tone = extra
                    end
                    render(true)
                else
                    warn("[AirFlow] status update error: " .. tostring(value))
                end
                task.wait(rate)
            end
        end)
        function handle:SetUpdateRate(seconds)
            rate = math.max(tonumber(seconds) or rate, 0.05)
        end
    end
    if opts.Pin then
        table.insert(window._pinned, handle)
        table.insert(handle._listeners, function()
            local index = table.find(window._pinned, handle)
            if index then
                table.remove(window._pinned, index)
            end
        end)
    end

    render(false)
    return finishElement(self, opts, handle, frame, "Status")
end

function Tab:Statuses(entries, shared)
    local handles = {}
    for index, entry in ipairs(entries or {}) do
        local entryOpts = type(entry) == "table" and table.clone(entry) or { Name = tostring(entry) }
        for key, value in pairs(shared or {}) do
            if entryOpts[key] == nil then
                entryOpts[key] = value
            end
        end
        local handle = self:Status(entryOpts)
        handles[entryOpts.Name or entryOpts.Title or index] = handle
    end
    return handles
end

-- Status list: a read-only block of rows that grows up to MaxRows, then
-- scrolls inside itself. Rows are reused between refreshes so nothing flickers.
function Tab:StatusList(opts)
    opts = normalize(opts, { Title = "Name" })
    local compact = metricsOf(self).Compact
    local window = self.Window
    local maxRows = math.max(math.floor(tonumber(opts.MaxRows) or 5), 1)
    local frame = card(self, "Frame", 0, opts)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    if compact then
        padding(frame, 14, 14, 6, 8)
    else
        padding(frame, 14, 14, 11, 12)
    end
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = frame,
    })
    local heading = label({
        Size = UDim2.new(1, 0, 0, 16),
        Text = string.upper(tostring(opts.Name or "")),
        TextSize = 11,
        TextColor3 = Theme.Muted,
        Visible = tostring(opts.Name or "") ~= "",
        LayoutOrder = 1,
        Parent = frame,
    })
    local scroller = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollingEnabled = false,
        LayoutOrder = 2,
        Parent = frame,
    })
    scroller:SetAttribute("NoDrag", true)
    local content = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = scroller,
    })
    local contentPadding = padding(content, 0, 0, 0, 0)
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = content,
    })
    local empty = label({
        Size = UDim2.new(1, 0, 0, 24),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = tostring(opts.EmptyText or "Nothing yet"),
        TextSize = 13,
        LineHeight = 1.1,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        LayoutOrder = 0,
        Parent = content,
    })

    local rowObjects, rows, signature, raw = {}, {}, nil, {}
    local handle = { _listeners = {} }

    -- Fits the list to its first MaxRows rows, measured, so wrapped rows count
    -- at their real height. Past MaxRows the list scrolls.
    local function fit()
        if handle._destroyed then
            return
        end
        local scale = window.Scale.Scale
        local count = #rows
        local height = 0
        if count == 0 then
            height = empty.AbsoluteSize.Y / scale
        else
            local shown = math.min(count, maxRows)
            for index = 1, shown do
                height += rowObjects[index].Frame.AbsoluteSize.Y / scale
            end
            height += (shown - 1) * 2
        end
        height = math.ceil(height)
        local scrolling = count > maxRows
        scroller.ScrollingEnabled = scrolling
        contentPadding.PaddingRight = UDim.new(0, scrolling and 8 or 0)
        if scroller.Size.Y.Offset ~= height then
            scroller.Size = UDim2.new(1, 0, 0, height)
        end
        local maxScroll = math.max(scroller.AbsoluteCanvasSize.Y - scroller.AbsoluteWindowSize.Y, 0) / scale
        if scroller.CanvasPosition.Y > maxScroll then
            scroller.CanvasPosition = Vector2.new(0, maxScroll)
        end
    end

    local function fitText(row)
        if row.Value.Visible then
            row.Text.Size = UDim2.new(1, -(math.ceil(row.Value.AbsoluteSize.X / window.Scale.Scale) + 12), 0, 24)
        else
            row.Text.Size = UDim2.new(1, 0, 0, 24)
        end
    end

    local function newRow(order)
        local holder = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = content,
        })
        local row = {
            Frame = holder,
            Text = label({
                Size = UDim2.new(1, 0, 0, 24),
                AutomaticSize = Enum.AutomaticSize.Y,
                Text = "",
                TextSize = 13,
                LineHeight = 1.1,
                FontFace = Fonts.Regular,
                TextColor3 = Theme.Muted,
                TextWrapped = true,
                TextTruncate = Enum.TextTruncate.None,
                RichText = true,
                Parent = holder,
            }),
            Value = label({
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 24),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = "",
                TextSize = 12,
                FontFace = Fonts.Medium,
                TextColor3 = Theme.Text,
                RichText = true,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.None,
                Visible = false,
                Parent = holder,
            }),
        }
        row.Connections = {
            holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit),
            row.Value:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                fitText(row)
            end),
        }
        return row
    end

    local function normalizeRow(entry)
        if type(entry) == "table" then
            local text = entry.Text or entry.Name or entry[1]
            local tone = entry.Tone or entry.Color
            return {
                Text = tostring(text == nil and "" or text),
                Value = entry.Value ~= nil and tostring(entry.Value) or nil,
                Tone = (type(tone) == "string" or typeof(tone) == "Color3") and tone or nil,
            }
        end
        return { Text = tostring(entry) }
    end

    local function rowKey(entry)
        return entry.Text .. "\0" .. (entry.Value or "\1") .. "\0" .. tostring(entry.Tone or "")
    end

    -- Tone tints the value, or the text when there is no value.
    local function paint(row, entry)
        local key = rowKey(entry)
        if row.Key == key then
            return
        end
        row.Key = key
        row.Text.Text = Library._rich(entry.Text)
        local tone = entry.Tone and Library._color(entry.Tone) or nil
        if entry.Value then
            row.Value.Text = Library._rich(entry.Value)
            row.Value.Visible = true
            tween(row.Value, { TextColor3 = tone or Theme.Text }, 0)
            tween(row.Text, { TextColor3 = Theme.Muted }, 0)
        else
            row.Value.Visible = false
            tween(row.Text, { TextColor3 = tone or Theme.Muted }, 0)
        end
        fitText(row)
    end

    local function dropRow(row)
        for _, connection in ipairs(row.Connections) do
            connection:Disconnect()
        end
        row.Frame:Destroy()
    end

    function handle:Set(list)
        if type(list) ~= "table" or handle._destroyed then
            return
        end
        local nextRows, keys = {}, {}
        raw = {}
        for index, entry in ipairs(list) do
            raw[index] = type(entry) == "table" and table.clone(entry) or entry
            local row = normalizeRow(entry)
            nextRows[index] = row
            keys[index] = rowKey(row)
        end
        local nextSignature = table.concat(keys, "\2") .. "#" .. #nextRows
        if nextSignature == signature then
            return
        end
        signature = nextSignature
        rows = nextRows
        for index, entry in ipairs(rows) do
            local row = rowObjects[index]
            if not row then
                row = newRow(index)
                rowObjects[index] = row
            end
            paint(row, entry)
        end
        for index = #rowObjects, #rows + 1, -1 do
            dropRow(rowObjects[index])
            rowObjects[index] = nil
        end
        empty.Visible = #rows == 0
        fit()
    end
    function handle:Get()
        local copy = {}
        for index, entry in ipairs(raw) do
            copy[index] = type(entry) == "table" and table.clone(entry) or entry
        end
        return copy
    end
    function handle:Clear()
        handle:Set({})
    end
    function handle:SetName(text)
        text = tostring(text or "")
        heading.Text = string.upper(text)
        heading.Visible = text ~= ""
        handle._searchName = text
        handle._searchKey = string.lower(text)
    end
    local rate = math.max(tonumber(opts.UpdateRate) or 1, 0.05)
    function handle:SetUpdateRate(seconds)
        rate = math.max(tonumber(seconds) or rate, 0.05)
    end

    -- Theme tags are baked into the text, so a theme change repaints the rows.
    onTheme(content, function()
        for index, row in ipairs(rowObjects) do
            if rows[index] then
                row.Key = nil
                paint(row, rows[index])
            end
        end
    end)

    local emptyConnection = empty:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    table.insert(handle._listeners, function()
        handle._destroyed = true
        emptyConnection:Disconnect()
        for _, row in ipairs(rowObjects) do
            for _, connection in ipairs(row.Connections) do
                connection:Disconnect()
            end
        end
    end)

    -- Refreshes only while someone can see it: window open and not minimized,
    -- its tab and sub tab showing, and neither it nor its groupbox hidden.
    local function onScreen()
        if window._destroyed or not window.Open or window.Minimized or not handle._userVisible then
            return false
        end
        local page = self
        if page._groupbox then
            if page._userVisible == false then
                return false
            end
            page = page.Parent
        end
        if page._isSubTab then
            if page.Parent.CurrentSubTab ~= page then
                return false
            end
            page = page.Parent
        end
        return window.CurrentTab == page
    end

    if type(opts.Update) == "function" then
        local alive = true
        table.insert(handle._listeners, function()
            alive = false
        end)
        task.defer(function()
            local first = true
            while alive and frame.Parent do
                if first or onScreen() then
                    first = false
                    local ok, result = isolatedCall(opts.Update)
                    if ok then
                        if result ~= nil then
                            handle:Set(result)
                        end
                    else
                        warn("[AirFlow] status list update error: " .. tostring(result))
                    end
                end
                task.wait(rate)
            end
        end)
    end

    handle:Set(opts.Rows or {})
    return finishElement(self, opts, handle, frame, "StatusList")
end

Tab.CreateStatus = Tab.Status
Tab.AddStatus = Tab.Status
Tab.CreateStatuses = Tab.Statuses
Tab.CreateStatusList = Tab.StatusList
Tab.AddStatusList = Tab.StatusList

-- Image and Viewport: media cards. Image shows a picture from the same sources
-- as window backgrounds, plus "Avatar" for the player's headshot. Viewport
-- shows a 3D model or the player's avatar, turning slowly; drag it to spin it
-- by hand.

function Tab:_mediaCard(opts, defaultHeight)
    opts = normalize(opts, { Title = "Name", Description = "Desc" })
    local metrics = metricsOf(self)
    local compact = metrics.Compact
    local mediaHeight = math.clamp(tonumber(opts.Height) or defaultHeight, 40, 600)
    local inset = compact and 14 or 8
    local hasHead = type(opts.Name) == "string" and opts.Name ~= ""
    local titleTop = compact and 4 or 10
    local mediaTop = hasHead and (titleTop + (opts.Desc and 38 or 22)) or (compact and 4 or inset)
    local height = mediaTop + mediaHeight + (compact and 6 or inset)
    local frame, frameStroke = card(self, "Frame", height, opts)
    hoverStroke(frame, frameStroke)
    local title, descLabel
    if hasHead then
        title = label({
            Position = UDim2.fromOffset(14, titleTop),
            Size = UDim2.new(1, -28, 0, metrics.TitleHeight),
            Text = opts.Name,
            TextSize = metrics.TextSize,
            Parent = frame,
        })
        if opts.Desc then
            descLabel = label({
                Position = UDim2.fromOffset(14, titleTop + metrics.TitleHeight + 1),
                Size = UDim2.new(1, -28, 0, metrics.DescLine),
                Text = opts.Desc,
                TextSize = metrics.DescSize,
                FontFace = Fonts.Regular,
                TextColor3 = Theme.Muted,
                Parent = frame,
            })
        end
    end
    local media = create("Frame", {
        Position = UDim2.fromOffset(inset, mediaTop),
        Size = UDim2.new(1, -inset * 2, 0, mediaHeight),
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = frame,
    })
    corner(media, UDim.new(0, 6))
    stroke(media, Theme.Stroke)
    local placeholder = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(22, 22),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Muted,
        ImageTransparency = 0.3,
        ScaleType = Enum.ScaleType.Fit,
        Parent = media,
    })
    -- A caption over the bottom of the picture, on a dark fade.
    local captionHolder = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 3,
        Parent = media,
    })
    create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new(1, 0),
        Parent = captionHolder,
    })
    local caption = label({
        Position = UDim2.fromOffset(10, 8),
        Size = UDim2.new(1, -20, 1, -10),
        TextSize = 12,
        TextColor3 = Color3.new(1, 1, 1),
        ZIndex = 4,
        Parent = captionHolder,
    })
    local function setCaption(text)
        text = text ~= nil and tostring(text) or ""
        caption.Text = text
        captionHolder.Visible = text ~= ""
    end
    setCaption(opts.Caption)
    return opts, {
        Frame = frame,
        Stroke = frameStroke,
        Media = media,
        Placeholder = placeholder,
        Title = title,
        Desc = descLabel,
        SetCaption = setCaption,
    }
end

function Tab:Image(opts)
    local parts
    opts, parts = self:_mediaCard(opts, 160)
    local window = self.Window
    local media = parts.Media
    applyIcon(parts.Placeholder, "image")
    -- Enum lookups throw on unknown names.
    local function scaleType(name, fallback)
        local ok, value = pcall(function()
            return Enum.ScaleType[tostring(name)]
        end)
        return ok and value or fallback
    end
    local image = create("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ImageTransparency = 1,
        ScaleType = scaleType(opts.ScaleType or "Crop", Enum.ScaleType.Crop),
        ZIndex = 2,
        Parent = media,
    })
    corner(image, UDim.new(0, 6))
    if opts.Color then
        image.ImageColor3 = opts.Color
    end

    local handle = { Value = nil }
    local generation = 0

    -- Yields while a web image downloads. Returns ok, err like SetBackground.
    function handle:SetImage(source)
        generation += 1
        local current = generation
        handle.Value = source
        if source == nil or source == "" or source == "None" then
            tween(image, { ImageTransparency = 1 }, 0.2)
            tween(parts.Placeholder, { ImageTransparency = 0.3 }, 0.2)
            return true
        end
        local asset, err
        if type(source) == "number" then
            asset = "rbxassetid://" .. math.floor(source)
        elseif type(source) == "string" and ({ avatar = true, headshot = true })[source:lower()] then
            asset = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=420&h=420"
        else
            local ok, result, message = pcall(window._resolveBackground, window, tostring(source))
            if ok then
                asset, err = result, message
            else
                err = tostring(result)
            end
        end
        if generation ~= current then
            return false, "replaced by a newer image"
        end
        if not asset then
            warn("[AirFlow] image: " .. tostring(err))
            return false, err
        end
        image.ImageTransparency = 1
        image.Image = asset
        -- Fade in once it has loaded, or after a few seconds regardless.
        task.spawn(function()
            local waited = 0
            while not image.IsLoaded and waited < 4 and generation == current and image.Parent do
                waited += task.wait(0.05)
            end
            if generation == current and image.Parent then
                tween(image, { ImageTransparency = 0 }, 0.35)
                tween(parts.Placeholder, { ImageTransparency = 1 }, 0.2)
            end
        end)
        return true
    end
    handle.Set = handle.SetImage

    function handle:Get()
        return handle.Value
    end

    function handle:SetCaption(text)
        parts.SetCaption(text)
    end

    function handle:SetScaleType(name)
        image.ScaleType = scaleType(name, image.ScaleType)
    end

    function handle:SetColor(color)
        image.ImageColor3 = typeof(color) == "Color3" and color or Color3.new(1, 1, 1)
    end

    function handle:SetTitle(text)
        if parts.Title then
            parts.Title.Text = tostring(text)
        end
    end

    if opts.Image ~= nil then
        task.spawn(handle.SetImage, handle, opts.Image)
    end
    return finishElement(self, opts, handle, parts.Frame, "Image")
end

function Tab:Viewport(opts)
    local parts
    opts, parts = self:_mediaCard(opts, 180)
    local window = self.Window
    local media = parts.Media
    applyIcon(parts.Placeholder, "box")

    local viewport = create("ViewportFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ImageTransparency = 1,
        Ambient = opts.Ambient or Color3.fromRGB(165, 160, 175),
        LightColor = opts.LightColor or Color3.fromRGB(255, 250, 245),
        LightDirection = Vector3.new(-0.6, -1, -0.8),
        ZIndex = 2,
        Parent = media,
    })
    local camera = Instance.new("Camera")
    camera.FieldOfView = math.clamp(tonumber(opts.FieldOfView) or 35, 10, 90)
    camera.Parent = viewport
    viewport.CurrentCamera = camera
    local world = Instance.new("WorldModel")
    world.Parent = viewport

    local handle = {
        Model = nil,
        Spin = opts.Spin ~= false,
        SpinSpeed = tonumber(opts.SpinSpeed) or 25,
    }
    local angle = math.rad(tonumber(opts.Angle) or 0)
    local pitch = math.rad(tonumber(opts.Pitch) or 10)
    local distanceScale = tonumber(opts.Distance) or 1
    local center, distance, basis = nil, 10, CFrame.new()
    local source = nil
    local generation = 0
    local dragging, lastX, resumeAt = false, 0, 0

    local function place()
        if not center then
            return
        end
        local direction = basis:VectorToWorldSpace(Vector3.new(
            math.sin(angle) * math.cos(pitch),
            math.sin(pitch),
            -math.cos(angle) * math.cos(pitch)
        ))
        camera.CFrame = CFrame.lookAt(center + direction * distance, center)
    end

    local function fit(model)
        local cf, size
        if model:IsA("Model") then
            cf, size = model:GetBoundingBox()
            basis = model:GetPivot().Rotation
        elseif model:IsA("BasePart") then
            cf, size = model.CFrame, model.Size
            basis = model.CFrame.Rotation
        else
            return false
        end
        center = cf.Position
        local radius = math.max(size.Magnitude / 2, 0.5)
        distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * distanceScale
        place()
        return true
    end

    -- A copy with its scripts and sounds stripped and every part anchored.
    local function prepare(instance)
        local copy = instance
        if opts.Clone ~= false then
            local archivable = instance.Archivable
            pcall(function()
                instance.Archivable = true
            end)
            local ok, result = pcall(instance.Clone, instance)
            pcall(function()
                instance.Archivable = archivable
            end)
            copy = ok and result or nil
        end
        if not copy then
            return nil
        end
        local function clean(object)
            if object:IsA("LuaSourceContainer") or object:IsA("Sound") or object:IsA("ForceField") then
                object:Destroy()
            elseif object:IsA("BasePart") then
                object.Anchored = true
                object.CanCollide = false
            end
        end
        for _, object in ipairs(copy:GetDescendants()) do
            pcall(clean, object)
        end
        if copy:IsA("BasePart") then
            copy.Anchored = true
        end
        local humanoid = copy:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end
        return copy
    end

    local function resolve(value)
        if type(value) == "function" then
            local ok, result = pcall(value)
            value = ok and result or nil
        end
        if type(value) == "string" and ({ avatar = true, player = true, character = true })[value:lower()] then
            value = LocalPlayer
        end
        if typeof(value) == "Instance" and value:IsA("Player") then
            local character = value.Character
            if not character then
                character = value.CharacterAdded:Wait()
                -- Let the body parts and accessories load in.
                task.wait(0.5)
            end
            value = character
        end
        return typeof(value) == "Instance" and value or nil
    end

    -- Yields while waiting for a character to spawn.
    function handle:SetModel(value)
        generation += 1
        local current = generation
        source = value
        if handle.Model then
            handle.Model:Destroy()
            handle.Model = nil
        end
        center = nil
        if value == nil then
            tween(viewport, { ImageTransparency = 1 }, 0.2)
            tween(parts.Placeholder, { ImageTransparency = 0.3 }, 0.2)
            return true
        end
        local instance = resolve(value)
        if generation ~= current then
            return false, "replaced by a newer model"
        end
        if not instance then
            return false, "no model to show"
        end
        local copy = prepare(instance)
        if not copy then
            return false, "could not copy the model"
        end
        copy.Parent = world
        handle.Model = copy
        if not fit(copy) then
            copy:Destroy()
            handle.Model = nil
            return false, "not a Model or a part"
        end
        viewport.ImageTransparency = 1
        tween(viewport, { ImageTransparency = 0 }, 0.35)
        tween(parts.Placeholder, { ImageTransparency = 1 }, 0.2)
        return true
    end
    handle.Set = handle.SetModel

    function handle:Get()
        return handle.Model
    end

    -- Copies the source again, e.g. after the character respawned or changed.
    function handle:Refresh()
        return handle:SetModel(source)
    end

    function handle:SetSpin(enabled)
        handle.Spin = enabled ~= false
    end

    function handle:SetSpinSpeed(degrees)
        handle.SpinSpeed = tonumber(degrees) or handle.SpinSpeed
    end

    function handle:SetAngle(degrees)
        angle = math.rad(tonumber(degrees) or 0)
        place()
    end

    function handle:SetCaption(text)
        parts.SetCaption(text)
    end

    function handle:SetTitle(text)
        if parts.Title then
            parts.Title.Text = tostring(text)
        end
    end

    media.InputBegan:Connect(function(input)
        if isPress(input) and handle.Model then
            dragging = true
            lastX = pointerPosition().X
        end
    end)
    window:_listen("Changed", function(input)
        if dragging and isMove(input) then
            local x = pointerPosition().X
            angle -= (x - lastX) * 0.012
            lastX = x
            place()
        end
    end, handle)
    window:_listen("Ended", function(input)
        if dragging and isPress(input) then
            dragging = false
            resumeAt = os.clock() + 1.5
        end
    end, handle)
    window:_listen("Render", function(deltaTime)
        if handle.Spin and center and not dragging and os.clock() >= resumeAt and window.Open and not window.Minimized
            and parts.Frame.Visible then
            angle += math.rad(handle.SpinSpeed) * deltaTime
            place()
        end
    end, handle)

    if opts.Model ~= nil then
        task.spawn(handle.SetModel, handle, opts.Model)
    end
    return finishElement(self, opts, handle, parts.Frame, "Viewport")
end

-- Table: rows under a header, sortable by clicking a column. Rank = true adds
-- a # column with medals for the top three, for leaderboards.

function Tab:Table(opts)
    opts = normalize(opts, { Title = "Name", Description = "Desc", Data = "Rows", OnRowClick = "Callback" })
    local window = self.Window
    local metrics = metricsOf(self)
    local compact = metrics.Compact
    local rowHeight = tonumber(opts.RowHeight) or (TOUCH and 32 or 26)
    local maxRows = math.max(math.floor(tonumber(opts.MaxRows) or 8), 1)
    local headerHeight = TOUCH and 28 or 24
    local textSize = compact and 12 or 13
    local inset = compact and 14 or 8
    local hasHead = type(opts.Name) == "string" and opts.Name ~= ""
    local titleTop = compact and 4 or 10
    local searchable = opts.Search ~= false
    local searchHeight = TOUCH and 30 or 26
    local searchTop = hasHead and (titleTop + (opts.Desc and 38 or 22)) or (compact and 4 or inset)
    local gridTop = searchTop + (searchable and searchHeight + 6 or 0)
    local bottom = compact and 6 or inset

    local frame, frameStroke = card(self, "Frame", gridTop + headerHeight + rowHeight + bottom, opts)
    hoverStroke(frame, frameStroke)
    local title
    if hasHead then
        title = label({
            Position = UDim2.fromOffset(14, titleTop),
            Size = UDim2.new(1, -28, 0, metrics.TitleHeight),
            Text = opts.Name,
            TextSize = metrics.TextSize,
            Parent = frame,
        })
        if opts.Desc then
            label({
                Position = UDim2.fromOffset(14, titleTop + metrics.TitleHeight + 1),
                Size = UDim2.new(1, -28, 0, metrics.DescLine),
                Text = opts.Desc,
                TextSize = metrics.DescSize,
                FontFace = Fonts.Regular,
                TextColor3 = Theme.Muted,
                Parent = frame,
            })
        end
    end
    -- Search: filters rows by any cell's text as you type. A count of what
    -- matches shows on the right while it filters.
    local query = ""
    local searchBox, searchCount
    if searchable then
        local holder = create("Frame", {
            Position = UDim2.fromOffset(inset, searchTop),
            Size = UDim2.new(1, -inset * 2, 0, searchHeight),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            Parent = frame,
        })
        holder:SetAttribute("NoDrag", true)
        corner(holder, UDim.new(0, 6))
        local searchStroke = stroke(holder)
        local iconHolder, searchIcon = glowIcon(holder, "search", Theme.Muted, UDim2.new(0, 9, 0.5, 0))
        iconHolder.Size = UDim2.fromOffset(13, 13)
        searchCount = label({
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -9, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = "",
            TextSize = 11,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            TextTruncate = Enum.TextTruncate.None,
            Visible = false,
            Parent = holder,
        })
        searchBox = create("TextBox", {
            Position = UDim2.fromOffset(29, 0),
            Size = UDim2.new(1, -90, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = opts.SearchPlaceholder or "Search",
            PlaceholderColor3 = Theme.Muted,
            TextColor3 = Theme.Text,
            TextSize = 12,
            FontFace = Fonts.Regular,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ClearTextOnFocus = false,
            Parent = holder,
        })
        searchBox.Focused:Connect(function()
            tween(searchStroke, { Color = Theme.StrokeHover }, 0.15)
            tween(searchIcon, { ImageColor3 = Theme.Accent }, 0.15)
        end)
        searchBox.FocusLost:Connect(function()
            tween(searchStroke, { Color = Theme.Stroke }, 0.2)
            tween(searchIcon, { ImageColor3 = Theme.Muted }, 0.2)
        end)
    end

    local grid = create("Frame", {
        Position = UDim2.fromOffset(inset, gridTop),
        Size = UDim2.new(1, -inset * 2, 0, headerHeight + rowHeight),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = frame,
    })
    corner(grid, UDim.new(0, 6))
    stroke(grid, Theme.Stroke)
    local header = create("Frame", {
        Size = UDim2.new(1, 0, 0, headerHeight),
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Parent = grid,
    })
    create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = header,
    })
    local body = create("ScrollingFrame", {
        Position = UDim2.fromOffset(0, headerHeight),
        Size = UDim2.new(1, 0, 1, -headerHeight),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Parent = grid,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = body,
    })
    local empty = label({
        Position = UDim2.fromOffset(0, headerHeight),
        Size = UDim2.new(1, 0, 0, rowHeight),
        Text = opts.EmptyText or "Nothing here yet",
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = grid,
    })

    local handle = { Rows = {} }
    local shownCount = nil
    local columns, headerCells = {}, {}
    local pool = {}
    local sortKey, sortDescending = nil, false
    local shownHeight = nil
    local MEDALS = {
        Color3.fromRGB(245, 200, 90),
        Color3.fromRGB(200, 206, 218),
        Color3.fromRGB(214, 146, 96),
    }

    local function alignment(column)
        local align = type(column.Align) == "string" and column.Align:lower() or nil
        if align == "right" then
            return Enum.TextXAlignment.Right
        elseif align == "center" or align == "centre" then
            return Enum.TextXAlignment.Center
        end
        return Enum.TextXAlignment.Left
    end

    -- Widths: a number above 1 is pixels, up to 1 is a share of what the pixel
    -- columns leave, and the rest split whatever share is left.
    local function layoutColumns()
        local pixels, shares, autos = 0, 0, 0
        for _, column in ipairs(columns) do
            local width = tonumber(column.Width)
            if width and width > 1 then
                pixels += width
            elseif width and width > 0 then
                shares += width
            else
                autos += 1
            end
        end
        local left = math.max(1 - shares, 0)
        for _, column in ipairs(columns) do
            local width = tonumber(column.Width)
            local share
            if width and width > 1 then
                column.UDim = UDim.new(0, width)
            else
                share = (width and width > 0) and width or (autos > 0 and left / autos or 0)
                column.UDim = UDim.new(share, -pixels * share)
            end
        end
    end

    local function columnValue(row, column)
        if column.Rank then
            return nil
        end
        if row[1] ~= nil or column.Key == nil then
            return row[column.Index]
        end
        return row[column.Key]
    end

    local function display(value, column, row)
        if type(column.Format) == "function" then
            local ok, text = pcall(column.Format, value, row)
            if ok and text ~= nil then
                return tostring(text)
            end
        end
        if type(value) == "number" then
            local whole = value == math.floor(value)
            local text = whole and string.format("%d", value) or string.format("%.2f", value)
            -- Thousands separators on the whole part.
            local sign, int, rest = text:match("^(%-?)(%d+)(.*)$")
            if int then
                int = int:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
                return sign .. int .. rest
            end
            return text
        end
        if value == nil then
            return ""
        end
        return tostring(value)
    end

    local function paintHeader()
        for _, cell in ipairs(headerCells) do
            local column = cell.Column
            local active = sortKey ~= nil and sortKey == column
            tween(cell.Label, { TextColor3 = active and Theme.Text or Theme.Muted }, 0.15)
            cell.Arrow.Visible = active
            if active then
                tween(cell.Arrow, { Rotation = sortDescending and 0 or 180 }, 0.2, Enum.EasingStyle.Quint)
            end
        end
    end

    local function sortedRows()
        local list = {}
        for index, row in ipairs(handle.Rows) do
            list[index] = { Row = row, Index = index }
        end
        if sortKey then
            local column = sortKey
            table.sort(list, function(a, b)
                local x, y = columnValue(a.Row, column), columnValue(b.Row, column)
                local nx, ny = tonumber(x), tonumber(y)
                if nx and ny then
                    if nx ~= ny then
                        if sortDescending then
                            return nx > ny
                        end
                        return nx < ny
                    end
                elseif x ~= nil and y ~= nil then
                    local sx, sy = string.lower(tostring(x)), string.lower(tostring(y))
                    if sx ~= sy then
                        if sortDescending then
                            return sx > sy
                        end
                        return sx < sy
                    end
                elseif x ~= y then
                    -- Empty cells sink to the bottom either way.
                    return x ~= nil
                end
                return a.Index < b.Index
            end)
        end
        -- Ranks come from the full order, so filtering never renumbers them.
        for position, item in ipairs(list) do
            item.Rank = position
        end
        if query == "" then
            return list
        end
        local shown = {}
        for _, item in ipairs(list) do
            for _, column in ipairs(columns) do
                if not column.Rank then
                    local text = display(columnValue(item.Row, column), column, item.Row)
                    text = string.lower((string.gsub(text, "<[^>]->", "")))
                    if string.find(text, query, 1, true) then
                        table.insert(shown, item)
                        break
                    end
                end
            end
        end
        return shown
    end

    local function newRow()
        local rowFrame = create("TextButton", {
            Size = UDim2.new(1, 0, 0, rowHeight),
            BackgroundColor3 = Theme.Surface3,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Parent = body,
        })
        -- The accent bar on a highlighted row sits beside the cells, outside
        -- their layout.
        local marker = create("Frame", {
            Position = UDim2.new(0, 3, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 2, 1, -10),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = rowFrame,
        })
        corner(marker, UDim.new(1, 0))
        local cellsFrame = create("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = rowFrame,
        })
        padding(cellsFrame, 10, 10)
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = cellsFrame,
        })
        local entry = { Frame = rowFrame, Marker = marker, Cells = {}, Hover = false }
        for order, column in ipairs(columns) do
            local cell = create("Frame", {
                Size = UDim2.new(column.UDim.Scale, column.UDim.Offset, 1, 0),
                BackgroundTransparency = 1,
                LayoutOrder = order,
                Parent = cellsFrame,
            })
            local text = label({
                Size = UDim2.new(1, -6, 1, 0),
                TextSize = textSize,
                FontFace = column.Rank and Fonts.Bold or Fonts.Regular,
                TextColor3 = Theme.Text,
                TextXAlignment = alignment(column),
                RichText = not column.Rank,
                Parent = cell,
            })
            local badge
            if column.Rank then
                text.Size = UDim2.fromScale(1, 1)
                text.TextXAlignment = Enum.TextXAlignment.Center
                badge = create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(rowHeight - 8, rowHeight - 8),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 0,
                    Parent = cell,
                })
                corner(badge, UDim.new(1, 0))
            end
            entry.Cells[order] = { Label = text, Badge = badge }
        end
        local canTap = tapGuard(rowFrame, function()
            return body
        end)
        rowFrame.MouseEnter:Connect(function()
            entry.Hover = true
            tween(rowFrame, { BackgroundTransparency = 0.35 }, 0.1)
        end)
        rowFrame.MouseLeave:Connect(function()
            entry.Hover = false
            tween(rowFrame, {
                BackgroundColor3 = entry.Highlighted and Theme.Accent or Theme.Surface3,
                BackgroundTransparency = entry.Rest or 1,
            }, 0.2)
        end)
        rowFrame.MouseButton1Click:Connect(function()
            if entry.Data and canTap() then
                safeCall(opts.Callback, entry.Data, entry.Index)
            end
        end)
        return entry
    end

    local function fitHeight(instant)
        local count = shownCount or #handle.Rows
        local visible = math.clamp(count, 1, maxRows)
        local gridHeight = headerHeight + visible * rowHeight
        local total = gridTop + gridHeight + bottom
        if shownHeight == total then
            return
        end
        local duration = (instant or shownHeight == nil) and 0 or 0.25
        shownHeight = total
        tween(grid, { Size = UDim2.new(1, -inset * 2, 0, gridHeight) }, duration, Enum.EasingStyle.Quint)
        tween(frame, { Size = UDim2.new(1, 0, 0, total) }, duration, Enum.EasingStyle.Quint)
    end

    local function render()
        local list = sortedRows()
        for position, item in ipairs(list) do
            local entry = pool[position]
            if not entry then
                entry = newRow()
                pool[position] = entry
            end
            local row = item.Row
            entry.Data = row
            entry.Index = item.Index
            entry.Frame.LayoutOrder = position
            entry.Frame.Visible = true
            local highlighted = row.Highlight == true
            if not highlighted and type(opts.Highlight) == "function" then
                local ok, result = pcall(opts.Highlight, row, item.Index)
                highlighted = ok and result == true
            end
            entry.Highlighted = highlighted
            entry.Rest = highlighted and 0.86 or (position % 2 == 0 and 0.78 or 1)
            if not entry.Hover then
                entry.Frame.BackgroundColor3 = highlighted and Theme.Accent or Theme.Surface3
                entry.Frame.BackgroundTransparency = entry.Rest
                bindColors(entry.Frame, { BackgroundColor3 = entry.Frame.BackgroundColor3 })
            end
            entry.Marker.BackgroundTransparency = highlighted and 0 or 1
            for order, column in ipairs(columns) do
                local cell = entry.Cells[order]
                if column.Rank then
                    local medal = MEDALS[item.Rank]
                    cell.Label.Text = tostring(item.Rank)
                    cell.Label.TextColor3 = medal and Color3.fromRGB(28, 22, 18) or Theme.Muted
                    bindColors(cell.Label, { TextColor3 = cell.Label.TextColor3 })
                    cell.Badge.BackgroundColor3 = medal or Theme.Surface3
                    cell.Badge.BackgroundTransparency = medal and 0.05 or 1
                else
                    local value = columnValue(row, column)
                    cell.Label.Text = Library._rich(display(value, column, row))
                    -- Column Color: a colour, a theme key or a function(value, row)
                    -- returning either. A row's Colors[key or index] beats it.
                    local wanted = column.Color
                    if type(wanted) == "function" then
                        local ok, result = pcall(wanted, value, row)
                        wanted = ok and result or nil
                    end
                    if type(row.Colors) == "table" then
                        local own = row.Colors[column.Key or column.Index]
                        if own == nil then
                            own = row.Colors[column.Index]
                        end
                        if own ~= nil then
                            wanted = own
                        end
                    end
                    local color = Library._color(wanted) or (highlighted and Theme.Accent or Theme.Text)
                    cell.Label.TextColor3 = color
                    bindColors(cell.Label, { TextColor3 = color })
                end
            end
        end
        for position = #list + 1, #pool do
            pool[position].Frame.Visible = false
            pool[position].Data = nil
        end
        shownCount = #list
        empty.Visible = #list == 0
        empty.Text = (#list == 0 and query ~= "" and #handle.Rows > 0) and (opts.NoMatchText or "No rows match")
            or (opts.EmptyText or "Nothing here yet")
        if searchCount then
            searchCount.Visible = query ~= ""
            searchCount.Text = #list .. " / " .. #handle.Rows
        end
        fitHeight()
    end

    local function buildHeader()
        for _, cell in ipairs(headerCells) do
            cell.Frame:Destroy()
        end
        table.clear(headerCells)
        for _, entry in ipairs(pool) do
            entry.Frame:Destroy()
        end
        table.clear(pool)
        local row = header:FindFirstChild("Cells") or create("Frame", {
            Name = "Cells",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = header,
        })
        if not row:FindFirstChildOfClass("UIListLayout") then
            padding(row, 10, 10)
            create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = row,
            })
        end
        for order, column in ipairs(columns) do
            local cell = create("TextButton", {
                Size = UDim2.new(column.UDim.Scale, column.UDim.Offset, 1, 0),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = order,
                Parent = row,
            })
            local align = column.Rank and Enum.TextXAlignment.Center or alignment(column)
            local right = align == Enum.TextXAlignment.Right
            local text = label({
                Size = UDim2.new(1, align == Enum.TextXAlignment.Center and 0 or -16, 1, 0),
                Position = UDim2.fromOffset(right and 16 or 0, 0),
                Text = string.upper(column.Name),
                TextSize = 11,
                FontFace = Fonts.Bold,
                TextColor3 = Theme.Muted,
                TextXAlignment = align,
                Parent = cell,
            })
            local arrow = create("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(12, 12),
                BackgroundTransparency = 1,
                ImageColor3 = Theme.Accent,
                ScaleType = Enum.ScaleType.Fit,
                Visible = false,
                Parent = cell,
            })
            applyIcon(arrow, "chevron-down")
            -- The arrow sits just after the header text (before it when the
            -- column is right aligned).
            local function placeArrow()
                local width = text.TextBounds.X
                if right then
                    arrow.Position = UDim2.new(1, -(width + 15), 0.5, 0)
                elseif align == Enum.TextXAlignment.Center then
                    arrow.Position = UDim2.new(0.5, width / 2 + 3, 0.5, 0)
                else
                    local cellWidth = cell.AbsoluteSize.X / math.max(window.Scale.Scale, 0.01)
                    arrow.Position = UDim2.new(0, math.clamp(width + 4, 0, math.max(cellWidth - 12, 0)), 0.5, 0)
                end
            end
            text:GetPropertyChangedSignal("TextBounds"):Connect(placeArrow)
            cell:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeArrow)
            task.defer(placeArrow)
            local sortable = column.Sortable and not column.Rank
            if sortable then
                cell.MouseEnter:Connect(function()
                    if sortKey ~= column then
                        tween(text, { TextColor3 = Theme.Text }, 0.12)
                    end
                end)
                cell.MouseLeave:Connect(function()
                    if sortKey ~= column then
                        tween(text, { TextColor3 = Theme.Muted }, 0.2)
                    end
                end)
                cell.MouseButton1Click:Connect(function()
                    -- Numbers sort high to low first, text A to Z; the second
                    -- click flips it and the third goes back to the given order.
                    if sortKey ~= column then
                        local numeric = false
                        for _, data in ipairs(handle.Rows) do
                            local value = columnValue(data, column)
                            if value ~= nil then
                                numeric = tonumber(value) ~= nil
                                break
                            end
                        end
                        sortKey, sortDescending = column, numeric
                        column.FirstDescending = numeric
                    elseif sortDescending == column.FirstDescending then
                        sortDescending = not sortDescending
                    else
                        sortKey = nil
                    end
                    paintHeader()
                    render()
                end)
            end
            table.insert(headerCells, { Frame = cell, Label = text, Arrow = arrow, Column = column })
        end
        paintHeader()
    end

    function handle:SetColumns(list)
        table.clear(columns)
        if opts.Rank then
            table.insert(columns, { Name = "#", Rank = true, Width = TOUCH and 40 or 36, Sortable = false })
        end
        for index, column in ipairs(type(list) == "table" and list or {}) do
            if type(column) ~= "table" then
                column = { Name = tostring(column) }
            end
            local name = column.Name or column.Title or ("Column " .. index)
            table.insert(columns, {
                Name = name,
                Key = column.Key or name,
                Index = index,
                Width = column.Width,
                Align = column.Align,
                Format = column.Format,
                Color = column.Color,
                Sortable = column.Sortable ~= false and opts.Sortable ~= false,
            })
        end
        sortKey = nil
        layoutColumns()
        buildHeader()
        render()
    end

    local function findColumn(key)
        if type(key) == "number" then
            return columns[key + (opts.Rank and 1 or 0)]
        end
        for _, column in ipairs(columns) do
            if not column.Rank and (column.Key == key or column.Name == key) then
                return column
            end
        end
        return nil
    end

    function handle:SetRows(rows)
        handle.Rows = {}
        for index, row in ipairs(type(rows) == "table" and rows or {}) do
            handle.Rows[index] = type(row) == "table" and row or { row }
        end
        render()
    end
    handle.Set = handle.SetRows

    function handle:GetRows()
        return handle.Rows
    end
    handle.Get = handle.GetRows

    function handle:AddRow(row, position)
        row = type(row) == "table" and row or { row }
        if tonumber(position) then
            table.insert(handle.Rows, math.clamp(math.floor(position), 1, #handle.Rows + 1), row)
        else
            table.insert(handle.Rows, row)
        end
        render()
        return #handle.Rows
    end

    -- Replaces a row (by its index in the list you gave) and flashes it.
    function handle:UpdateRow(index, row)
        if not handle.Rows[index] then
            return false
        end
        handle.Rows[index] = type(row) == "table" and row or { row }
        render()
        for _, entry in ipairs(pool) do
            if entry.Index == index and entry.Frame.Visible then
                local restColor = entry.Highlighted and Theme.Accent or Theme.Surface3
                tween(entry.Frame, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.7 }, 0.08)
                task.delay(0.1, function()
                    if not entry.Hover then
                        tween(entry.Frame, { BackgroundColor3 = restColor, BackgroundTransparency = entry.Rest }, 0.5)
                    end
                end)
                break
            end
        end
        return true
    end

    function handle:RemoveRow(index)
        if not handle.Rows[index] then
            return false
        end
        table.remove(handle.Rows, index)
        render()
        return true
    end

    function handle:Clear()
        handle:SetRows({})
    end

    -- Sort(nil) goes back to the given order.
    function handle:Sort(key, descending)
        sortKey = key ~= nil and findColumn(key) or nil
        sortDescending = descending == true
        if sortKey then
            sortKey.FirstDescending = sortDescending
        end
        paintHeader()
        render()
    end

    function handle:SetTitle(text)
        if title then
            title.Text = tostring(text)
        end
    end

    function handle:SetMaxRows(count)
        maxRows = math.max(math.floor(tonumber(count) or maxRows), 1)
        fitHeight()
    end

    handle:SetColumns(opts.Columns or {})
    handle:SetRows(opts.Rows or {})
    if opts.SortBy ~= nil then
        handle:Sort(opts.SortBy, opts.SortDescending ~= false)
    end
    fitHeight(true)
    if searchBox then
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local text = string.lower(trim(searchBox.Text))
            if text ~= query then
                query = text
                body.CanvasPosition = Vector2.zero
                render()
            end
        end)
    end
    function handle:SetSearch(text)
        if searchBox then
            searchBox.Text = tostring(text or "")
        end
    end
    -- Theme tags in cells are baked to colours; repaint them on theme change.
    onTheme(grid, render)
    return finishElement(self, opts, handle, frame, "Table")
end

Tab.CreateImage = Tab.Image
Tab.AddImage = Tab.Image
Tab.CreateViewport = Tab.Viewport
Tab.AddViewport = Tab.Viewport
Tab.CreateTable = Tab.Table
Tab.AddTable = Tab.Table
Tab.CreateLeaderboard = Tab.Table

local function settleSubOut(ui)
    if ui.OutFrame then
        ui.OutFrame.Parent = ui.Area
        ui.OutFrame.Visible = false
        ui.OutFrame = nil
    end
    ui.Out.Visible = false
end

local function settleSubIn(ui)
    if ui.InFrame then
        ui.InFrame.Parent = ui.Area
        ui.InFrame.Position = UDim2.fromOffset(0, 0)
        ui.InFrame = nil
    end
    ui.In.Visible = false
end

function Tab:_setupSubTabs()
    local top = self._headerBottom
    local page = self._page
    local strip = create("ScrollingFrame", {
        Name = "SubTabs",
        Position = UDim2.fromOffset(24, top - 4),
        Size = UDim2.new(1, -48, 0, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        CanvasSize = UDim2.new(),
        Parent = page,
    })
    strip:SetAttribute("NoDrag", true)
    local highlight = create("Frame", {
        Size = UDim2.fromOffset(0, 32),
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Visible = false,
        Parent = strip,
    })
    corner(highlight, UDim.new(0, 8))
    stroke(highlight, Theme.Stroke)
    local row = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = strip,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = row,
    })
    self.Window:_overflowHint(page, strip, row, false, Theme.Background)
    local areaTop = top + 36
    local area = create("Frame", {
        Name = "SubPages",
        Position = UDim2.fromOffset(0, areaTop),
        Size = UDim2.new(1, 0, 1, -areaTop),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = page,
    })
    local ui = {
        Strip = strip,
        Row = row,
        Highlight = highlight,
        Area = area,
        Out = create("CanvasGroup", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 2,
            Parent = area,
        }),
        In = create("CanvasGroup", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 3,
            Parent = area,
        }),
        Generation = 0,
    }
    self._sub = ui
    self._subTabs = {}
    self.List.Visible = false
    self:_refreshEmpty()
    -- Keep the pill under the selected tab when widths change after layout.
    row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if self.CurrentSubTab and not ui.Moving then
            self:_placeSubHighlight(self.CurrentSubTab, true)
        end
    end)
end

function Tab:_placeSubHighlight(sub, instant)
    local ui = self._sub
    local scale = self.Window.Scale.Scale
    local button = sub._button
    local width = button.AbsoluteSize.X / scale
    if width <= 0 then
        return
    end
    local x = (button.AbsolutePosition.X - ui.Row.AbsolutePosition.X) / scale
    local props = { Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(width, 32) }
    if instant or not ui.Highlight.Visible then
        ui.Highlight.Visible = true
        ui.Highlight.Position = props.Position
        ui.Highlight.Size = props.Size
    else
        ui.Moving = true
        tween(ui.Highlight, props, 0.35, Enum.EasingStyle.Quint)
        task.delay(0.36, function()
            ui.Moving = false
        end)
    end
    local view = ui.Strip.AbsoluteSize.X / scale
    local canvasX = ui.Strip.CanvasPosition.X
    if x < canvasX then
        tween(ui.Strip, { CanvasPosition = Vector2.new(math.max(x - 8, 0), 0) }, 0.3, Enum.EasingStyle.Quint)
    elseif x + width > canvasX + view then
        tween(ui.Strip, { CanvasPosition = Vector2.new(x + width - view + 8, 0) }, 0.3, Enum.EasingStyle.Quint)
    end
end

function Tab:SubTab(opts, icon)
    if self._groupbox or self._isSubTab then
        return self.Parent:SubTab(opts, icon)
    end
    opts = normalize(opts, { Title = "Name", Description = "Desc" })
    if icon ~= nil and opts.Icon == nil then
        opts.Icon = icon
    end
    if not self._subTabs then
        self:_setupSubTabs()
    end
    local ui = self._sub
    local index = #self._subTabs + 1
    local sub = setmetatable({
        Name = opts.Name or ("Page " .. index),
        Window = self.Window,
        Parent = self,
        _order = 0,
        _isSubTab = true,
        _index = index,
        _iconName = opts.Icon,
    }, Tab)
    local frame = create("Frame", {
        Name = sub.Name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = ui.Area,
    })
    sub._frame = frame
    buildContainer(sub, frame, 0, opts.Icon or self._iconName or "layout-grid", opts.EmptyText or "Nothing here yet")

    local button = create("TextButton", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = index,
        Parent = ui.Row,
    })
    padding(button, 14, 14)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = button,
    })
    if opts.Icon then
        local image = create("ImageLabel", {
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            ImageColor3 = Theme.Muted,
            ScaleType = Enum.ScaleType.Fit,
            LayoutOrder = 1,
            Parent = button,
        })
        applyIcon(image, opts.Icon)
        if image:GetAttribute("CustomIcon") then
            image.ImageTransparency = 0.4
        end
        sub._iconImage = image
    end
    sub._label = label({
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = sub.Name,
        TextSize = 13,
        TextColor3 = Theme.Muted,
        TextTruncate = Enum.TextTruncate.None,
        LayoutOrder = 2,
        Parent = button,
    })
    sub._button = button
    button.MouseEnter:Connect(function()
        if self.CurrentSubTab ~= sub then
            tween(sub._label, { TextColor3 = Theme.Text }, 0.12)
        end
    end)
    button.MouseLeave:Connect(function()
        if self.CurrentSubTab ~= sub then
            tween(sub._label, { TextColor3 = Theme.Muted }, 0.2)
        end
    end)
    button.MouseButton1Click:Connect(function()
        self:SelectSubTab(sub)
    end)

    table.insert(self._subTabs, sub)
    if index == 1 then
        self:SelectSubTab(sub, true)
    end
    return sub
end

Tab.CreateSubTab = Tab.SubTab
Tab.AddSubTab = Tab.SubTab

function Tab:SelectSubTab(sub, instant)
    if type(sub) ~= "table" then
        for index, entry in ipairs(self._subTabs or {}) do
            if entry.Name == sub or index == sub then
                sub = entry
                break
            end
        end
    end
    if type(sub) ~= "table" or not self._sub then
        return
    end
    local previous = self.CurrentSubTab
    if previous == sub then
        return
    end
    self.Window:_resetSearch()
    self.Window:_closePopups()
    self.CurrentSubTab = sub
    local ui = self._sub
    settleSubOut(ui)
    settleSubIn(ui)
    ui.Generation += 1
    local generation = ui.Generation

    local fade = instant and 0 or 0.2
    if previous then
        tween(previous._label, { TextColor3 = Theme.Muted }, fade)
        if previous._iconImage then
            tintIcon(previous._iconImage, Theme.Muted, false, fade)
        end
    end
    tween(sub._label, { TextColor3 = Theme.Text }, fade)
    if sub._iconImage then
        tintIcon(sub._iconImage, Theme.Accent, true, fade)
    end
    self:_placeSubHighlight(sub, instant)

    if instant or not previous then
        if previous then
            previous._frame.Visible = false
        end
        sub._frame.Visible = true
        return
    end

    local direction = sub._index > previous._index and 1 or -1
    ui.OutFrame = previous._frame
    previous._frame.Parent = ui.Out
    ui.Out.GroupTransparency = 0
    ui.Out.Position = UDim2.fromOffset(0, 0)
    ui.Out.Visible = true
    tween(ui.Out, { GroupTransparency = 1, Position = UDim2.fromOffset(-direction * 28, 0) }, 0.2)

    ui.InFrame = sub._frame
    sub._frame.Visible = true
    sub._frame.Parent = ui.In
    ui.In.GroupTransparency = 1
    ui.In.Position = UDim2.fromOffset(direction * 28, 0)
    ui.In.Visible = true
    tween(ui.In, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.34, Enum.EasingStyle.Quint)

    task.delay(0.2, function()
        if ui.Generation == generation then
            settleSubOut(ui)
        end
    end)
    task.delay(0.34, function()
        if ui.Generation == generation then
            settleSubIn(ui)
        end
    end)
end

-- Search: one box over the whole window. Typing lists matching tabs, pages,
-- groupboxes and controls from every tab; picking one opens its tab and page,
-- scrolls it into view and flashes it.

Window._searchIcons = {
    Tab = "app-window",
    Page = "panels-top-left",
    Groupbox = "layout-grid",
    Button = "mouse-pointer-click",
    ButtonRow = "mouse-pointer-click",
    Toggle = "toggle-right",
    Slider = "sliders-horizontal",
    Dropdown = "list",
    Input = "text-cursor-input",
    Keybind = "keyboard",
    ColorPicker = "palette",
    Stepper = "chevrons-up-down",
    Progress = "activity",
    Status = "activity",
    StatusList = "activity",
    Label = "type",
    Paragraph = "type",
    OrderList = "list-ordered",
}

function Window:_searchResults(query)
    local results = {}
    local function consider(name, entry)
        if type(name) ~= "string" or name == "" then
            return
        end
        local at = string.find(string.lower(name), query, 1, true)
        if not at then
            return
        end
        entry.Name = name
        entry.At = at
        -- Name starts first, then word starts, then anywhere inside a word.
        entry.Rank = at == 1 and 0 or (string.find(string.sub(name, at - 1, at - 1), "[%s%p]") and 1 or 2)
        entry.Order = #results + 1
        table.insert(results, entry)
    end
    local function shown(element)
        return not element._destroyed
            and element._type ~= "Section" and element._type ~= "Divider"
            and (element._isShown == nil or element:_isShown())
    end
    for _, tab in ipairs(self.Tabs) do
        consider(tab.Name, { Kind = "Tab", Tab = tab, Icon = tab._iconName })
        for _, page in ipairs(tab._subTabs or { tab }) do
            local sub = page._isSubTab and page or nil
            local path = tab.Name
            if sub then
                consider(sub.Name, { Kind = "Page", Tab = tab, Sub = sub, Path = tab.Name })
                path = tab.Name .. "  ›  " .. sub.Name
            end
            if not page._noSearch then
                for _, element in ipairs(page._items or {}) do
                    if shown(element) then
                        consider(element._searchName, { Kind = element._type, Tab = tab, Sub = sub, Target = element, Path = path })
                    end
                end
                for _, group in ipairs(page._groupboxes or {}) do
                    if group._userVisible ~= false then
                        consider(group.Name, { Kind = "Groupbox", Tab = tab, Sub = sub, Target = group, Path = path })
                        local groupPath = path .. "  ›  " .. group.Name
                        for _, element in ipairs(group._items) do
                            if shown(element) then
                                consider(element._searchName, { Kind = element._type, Tab = tab, Sub = sub, Target = element, Group = group, Path = groupPath })
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(results, function(a, b)
        if a.Rank ~= b.Rank then
            return a.Rank < b.Rank
        end
        return a.Order < b.Order
    end)
    return results
end

-- Marks a found control: it pops, a soft accent glow blooms around it, a
-- sheen of light sweeps across it and a bright spot runs round its border,
-- then everything breathes once more and fades.
function Window:_flash(frame, radius)
    for _, name in ipairs({ "SearchFlash", "SearchGlow" }) do
        local old = frame:FindFirstChild(name)
        if old then
            old:Destroy()
        end
    end
    radius = radius or 8
    local accent = Theme.Accent
    local bright = accent:Lerp(Color3.new(1, 1, 1), 0.65)

    -- Outer glow: a wide, faint stroke around a second outline.
    local halo = create("Frame", {
        Name = "SearchGlow",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 10,
        Parent = frame,
    })
    corner(halo, UDim.new(0, radius))
    local haloStroke = create("UIStroke", {
        Color = accent,
        Thickness = 1,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = halo,
    })

    -- Wash with a moving sheen: a brighter diagonal band crosses it once.
    local wash = create("Frame", {
        Name = "SearchFlash",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = frame,
    })
    corner(wash, UDim.new(0, radius))
    local sheen = create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.7),
            NumberSequenceKeypoint.new(0.4, 0.55),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(0.6, 0.55),
            NumberSequenceKeypoint.new(1, 0.7),
        }),
        Rotation = 18,
        Offset = Vector2.new(-1, 0),
        Parent = wash,
    })

    -- Border light: the ring's gradient turns, so a bright spot runs round it.
    local ring = create("UIStroke", {
        Color = Color3.new(1, 1, 1),
        Thickness = 1.6,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = wash,
    })
    local runner = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, accent),
            ColorSequenceKeypoint.new(0.5, bright),
            ColorSequenceKeypoint.new(1, accent),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.45),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 0.45),
        }),
        Parent = ring,
    })

    -- Groupboxes clip their rows, so anything drawn outside a control is cut
    -- off at its corners. The strokes go on the inside of the control where
    -- the engine supports it; otherwise everything is inset by its width.
    local inside = pcall(function()
        haloStroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
        ring.BorderStrokePosition = Enum.BorderStrokePosition.Inner
    end)
    local glowWidth = inside and 6 or 3
    if not inside then
        halo.Position = UDim2.fromOffset(glowWidth + 1, glowWidth + 1)
        halo.Size = UDim2.new(1, -(glowWidth + 1) * 2, 1, -(glowWidth + 1) * 2)
        wash.Position = UDim2.fromOffset(2, 2)
        wash.Size = UDim2.new(1, -4, 1, -4)
    end

    -- A small pop, unless something else is scaling the control already. It
    -- never grows past full size, which would be clipped as well.
    local pop
    if not frame:FindFirstChildOfClass("UIScale") then
        pop = create("UIScale", { Scale = 0.975, Parent = frame })
        tween(pop, { Scale = 1 }, 0.4, Enum.EasingStyle.Quint)
    end

    tween(wash, { BackgroundTransparency = 0.8 }, 0.2, Enum.EasingStyle.Quad)
    tween(ring, { Transparency = 0 }, 0.2, Enum.EasingStyle.Quad)
    tween(haloStroke, { Thickness = glowWidth, Transparency = 0.72 }, 0.35, Enum.EasingStyle.Quint)
    tween(sheen, { Offset = Vector2.new(1, 0) }, 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    tween(runner, { Rotation = 540 }, 2.2, Enum.EasingStyle.Quad)
    task.spawn(function()
        task.wait(0.75)
        -- One softer breath, then fade out.
        tween(wash, { BackgroundTransparency = 0.9 }, 0.35, Enum.EasingStyle.Sine)
        tween(haloStroke, { Thickness = glowWidth / 2, Transparency = 0.85 }, 0.35, Enum.EasingStyle.Sine)
        task.wait(0.35)
        tween(wash, { BackgroundTransparency = 0.84 }, 0.3, Enum.EasingStyle.Sine)
        tween(haloStroke, { Thickness = glowWidth * 0.85, Transparency = 0.76 }, 0.3, Enum.EasingStyle.Sine)
        task.wait(0.4)
        tween(wash, { BackgroundTransparency = 1 }, 0.55, Enum.EasingStyle.Quad)
        tween(ring, { Transparency = 1 }, 0.65, Enum.EasingStyle.Quad)
        tween(haloStroke, { Thickness = glowWidth, Transparency = 1 }, 0.65, Enum.EasingStyle.Quad)
        task.wait(0.7)
        wash:Destroy()
        halo:Destroy()
        if pop then
            pop:Destroy()
        end
    end)
end

function Window:_revealResult(result)
    local tab, sub, target, group = result.Tab, result.Sub, result.Target, result.Group
    if self.CurrentTab ~= tab then
        self:SelectTab(tab)
    end
    if sub then
        tab:SelectSubTab(sub)
    end
    if not target then
        local button = sub and sub._button or tab._button
        task.delay(0.1, function()
            if button.Parent then
                self:_flash(button, sub and 8 or 10)
            end
        end)
        return
    end
    local expanding = group ~= nil and group:IsCollapsed()
    if expanding then
        group:Expand()
    end
    local list = (sub or tab).List
    task.spawn(function()
        -- Let the freshly shown page lay out before measuring it.
        task.wait()
        task.wait()
        if expanding then
            task.wait(0.3)
        end
        local frame = target._frame
        if self._destroyed or target._destroyed or not frame or not frame.Parent or not list then
            return
        end
        local scale = self.Scale.Scale
        local top = (frame.AbsolutePosition.Y - list.AbsolutePosition.Y) / scale + list.CanvasPosition.Y
        local height = frame.AbsoluteSize.Y / scale
        local view = list.AbsoluteWindowSize.Y / scale
        local limit = math.max(list.AbsoluteCanvasSize.Y / scale - view, 0)
        local y = math.clamp(top + height / 2 - view / 2, 0, limit)
        if math.abs(y - list.CanvasPosition.Y) > 2 then
            tween(list, { CanvasPosition = Vector2.new(0, y) }, 0.45, Enum.EasingStyle.Quint)
            task.wait(0.25)
        end
        if frame.Parent then
            self:_flash(frame, target._groupbox and 10 or 8)
        end
    end)
end

function Window:_resetSearch()
    if self.SearchBox and self.SearchBox.Text ~= "" then
        self.SearchBox.Text = ""
    end
end

-- Page titles stop short of the search box and close button.
function Window:_fitTitle(tab)
    local right = self.SearchBox and (self._searchWidth or SEARCH_WIDTH) + 72 or 56
    local reserve = tab._titleX + right
    tab._title.Size = UDim2.new(1, -reserve, 0, 24)
    if tab._desc then
        tab._desc.Size = UDim2.new(1, -reserve, 0, 16)
    end
end

function Window:_buildSearch(content)
    -- No box: the icon and text sit on a thin baseline. Focus draws an
    -- accent line out from the middle of it.
    local holder = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -56, 0, 14),
        Size = UDim2.fromOffset(SEARCH_WIDTH, 34),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = content,
    })
    holder:SetAttribute("NoDrag", true)
    local baseline = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = holder,
    })
    local focusLine = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -1),
        Size = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = holder,
    })
    corner(focusLine, UDim.new(1, 0))
    -- Kept for the focus handlers below, which recolour it.
    local _, icon = glowIcon(holder, "search", Theme.Muted, UDim2.new(0, 2, 0.5, -1))
    icon.Parent.Size = UDim2.fromOffset(15, 15)
    local box = create("TextBox", {
        Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -28, 1, -2),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search",
        PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text,
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClearTextOnFocus = false,
        Parent = holder,
    })
    holder.MouseEnter:Connect(function()
        if not box:IsFocused() then
            tween(baseline, { BackgroundColor3 = Theme.StrokeHover }, 0.15)
        end
    end)
    holder.MouseLeave:Connect(function()
        tween(baseline, { BackgroundColor3 = Theme.Stroke }, 0.25)
    end)
    self.SearchBox = box

    -- Results float over the window under the box, like a dropdown popup.
    local rowHeight = TOUCH and 40 or 34
    local maxRows = 8
    local popup = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.fromOffset(300, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 45,
        Parent = self.Body,
    })
    popup:SetAttribute("NoDrag", true)
    local popupShadow = create("ImageLabel", {
        Position = UDim2.fromOffset(-18, -12),
        Size = UDim2.new(1, 36, 1, 36),
        BackgroundTransparency = 1,
        Image = Assets.Shadow,
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Parent = popup,
    })
    local panel = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = popup,
    })
    corner(panel, UDim.new(0, 10))
    local panelStroke = stroke(panel, Theme.Stroke, 1)
    edgeHighlight(panel)
    local list = create("ScrollingFrame", {
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.new(1, -12, 1, -12),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = TOUCH and 4 or 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(),
        Parent = panel,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = list,
    })
    local noResults = label({
        Size = UDim2.new(1, 0, 0, rowHeight),
        Text = "No results",
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 0,
        Visible = false,
        Parent = list,
    })

    local rows = {}
    local results = {}
    local selected = 1
    local open = false
    local generation = 0
    local shownSize = Vector2.new(300, 0)
    local stopFollowing = nil
    local closeResults

    local function place()
        local scale = self.Scale.Scale
        local bodyPosition = self.Body.AbsolutePosition
        local bodyWidth = self.Body.AbsoluteSize.X / scale
        local right = (holder.AbsolutePosition.X + holder.AbsoluteSize.X - bodyPosition.X) / scale
        local top = (holder.AbsolutePosition.Y + holder.AbsoluteSize.Y - bodyPosition.Y) / scale + 6
        right = math.clamp(right, shownSize.X + 8, math.max(bodyWidth - 8, shownSize.X + 8))
        popup.Position = UDim2.fromOffset(right, top)
    end

    local function measure()
        local scale = self.Scale.Scale
        local bodySize = self.Body.AbsoluteSize / scale
        local below = (holder.AbsolutePosition.Y + holder.AbsoluteSize.Y - self.Body.AbsolutePosition.Y) / scale + 6
        local count = math.max(#rows, 1)
        local height = math.min(count, maxRows) * (rowHeight + 2) - 2 + 12
        height = math.max(math.min(height, bodySize.Y - below - 12), rowHeight + 12)
        local width = math.min(math.max(holder.AbsoluteSize.X / scale, 300), math.max(bodySize.X - 16, 160))
        shownSize = Vector2.new(width, height)
    end

    local function paintSelection()
        for index, row in ipairs(rows) do
            local on = index == selected
            tween(row.Button, { BackgroundTransparency = on and 0.35 or 1 }, 0.12)
            tintIcon(row.Icon, on and Theme.Accent or Theme.Muted, on, 0.12)
        end
    end

    local function keepSelectionInView()
        local rowTop = (selected - 1) * (rowHeight + 2)
        local view = list.AbsoluteWindowSize.Y / self.Scale.Scale
        local y = list.CanvasPosition.Y
        if rowTop < y then
            y = rowTop
        elseif rowTop + rowHeight > y + view then
            y = rowTop + rowHeight - view
        else
            return
        end
        list.CanvasPosition = Vector2.new(0, math.max(y, 0))
    end

    local function setOpen(value)
        if value == open then
            return
        end
        open = value
        generation += 1
        local current = generation
        if value then
            if self._closePopup and self._closePopup ~= closeResults then
                self._closePopup()
            end
            self._closePopup = closeResults
            place()
            popup.Size = UDim2.fromOffset(shownSize.X, 0)
            popup.Visible = true
            tween(popup, { Size = UDim2.fromOffset(shownSize.X, shownSize.Y) }, 0.26, Enum.EasingStyle.Quint)
            tween(panelStroke, { Transparency = 0 }, 0.12)
            tween(popupShadow, { ImageTransparency = 0.55 }, 0.26)
            if not stopFollowing then
                stopFollowing = self:_listen("Render", place)
            end
        else
            if self._closePopup == closeResults then
                self._closePopup = nil
            end
            tween(popup, { Size = UDim2.fromOffset(shownSize.X, 0) }, 0.18, Enum.EasingStyle.Quint)
            tween(popupShadow, { ImageTransparency = 1 }, 0.14)
            task.delay(0.19, function()
                if generation == current and not open then
                    popup.Visible = false
                    panelStroke.Transparency = 1
                    if stopFollowing then
                        stopFollowing()
                        stopFollowing = nil
                    end
                end
            end)
        end
    end
    closeResults = function()
        setOpen(false)
    end

    local function choose(result)
        if not result then
            return
        end
        setOpen(false)
        box.Text = ""
        if box:IsFocused() then
            box:ReleaseFocus()
        end
        self:_revealResult(result)
    end

    local function escape(text)
        return (string.gsub(string.gsub(string.gsub(text, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
    end

    local function render(query)
        for _, row in ipairs(rows) do
            row.Button:Destroy()
        end
        table.clear(rows)
        results = self:_searchResults(query)
        selected = 1
        local accent = colorToHex(Theme.Accent)
        for index, result in ipairs(results) do
            if index > 50 then
                break
            end
            local button = create("TextButton", {
                Size = UDim2.new(1, 0, 0, rowHeight),
                BackgroundColor3 = Theme.Surface3,
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = index,
                Parent = list,
            })
            corner(button, UDim.new(0, 7))
            -- One line of breadcrumbs: tab, sub tab and groupbox in muted
            -- text, each split by a chevron, ending on the match in accent.
            local crumbs = create("Frame", {
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -20, 1, 0),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Parent = button,
            })
            create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
                Parent = crumbs,
            })
            local part = 0
            local firstIcon = nil
            local function crumbIcon(icon)
                if not icon then
                    return
                end
                part += 1
                local image = create("ImageLabel", {
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundTransparency = 1,
                    ImageColor3 = Theme.Muted,
                    ScaleType = Enum.ScaleType.Fit,
                    LayoutOrder = part,
                    Parent = crumbs,
                })
                applyIcon(image, icon)
                firstIcon = firstIcon or image
            end
            local function crumbText(text, color, rich)
                part += 1
                return label({
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = text,
                    RichText = rich == true,
                    TextSize = 13,
                    FontFace = color and Fonts.Medium or Fonts.Regular,
                    TextColor3 = color or Theme.Muted,
                    TextTruncate = Enum.TextTruncate.None,
                    LayoutOrder = part,
                    Parent = crumbs,
                })
            end
            local function chevron()
                crumbText(">")
            end
            local tab, sub, group = result.Tab, result.Sub, result.Group
            local onTab = result.Kind == "Tab"
            local onSub = result.Kind == "Page"
            local onGroup = result.Kind == "Groupbox"
            crumbIcon(tab._iconName or "layout-grid")
            if not onTab then
                crumbText(tab.Name)
                if sub then
                    chevron()
                    crumbIcon(sub._iconName or "layers")
                    if not onSub then
                        crumbText(sub.Name)
                    end
                end
                if group and not onGroup then
                    chevron()
                    crumbText(group.Name)
                end
                if not onSub then
                    chevron()
                end
            end
            -- The match itself: accent, with the typed part in bold.
            local name = result.Name
            local stop = result.At + #query
            local marked = escape(string.sub(name, 1, result.At - 1))
                .. "<b>" .. escape(string.sub(name, result.At, stop - 1)) .. "</b>"
                .. escape(string.sub(name, stop))
            crumbText(marked, Theme.Accent, true)
            local image = firstIcon
            local isTap = tapGuard(button, function()
                return list
            end)
            button.MouseEnter:Connect(function()
                if not usingTouch() then
                    selected = index
                    paintSelection()
                end
            end)
            button.MouseButton1Click:Connect(function()
                if isTap() then
                    choose(result)
                end
            end)
            table.insert(rows, { Button = button, Icon = image })
        end
        noResults.Visible = #rows == 0
        list.CanvasSize = UDim2.fromOffset(0, math.max(#rows, 1) * (rowHeight + 2) - 2)
        list.CanvasPosition = Vector2.zero
        paintSelection()
        measure()
        if open then
            place()
            tween(popup, { Size = UDim2.fromOffset(shownSize.X, shownSize.Y) }, 0.2, Enum.EasingStyle.Quint)
        end
    end

    local function update()
        local query = string.match(string.lower(box.Text), "^%s*(.-)%s*$")
        if query == "" then
            setOpen(false)
            return
        end
        render(query)
        setOpen(true)
    end

    box.Focused:Connect(function()
        tween(focusLine, { Size = UDim2.new(1, 0, 0, 2) }, 0.35, Enum.EasingStyle.Quint)
        tween(icon, { ImageColor3 = Theme.Accent }, 0.15)
        if box.Text ~= "" then
            update()
        end
    end)
    box.FocusLost:Connect(function(enterPressed)
        tween(focusLine, { Size = UDim2.new(0, 0, 0, 2) }, 0.3, Enum.EasingStyle.Quint)
        tween(icon, { ImageColor3 = Theme.Muted }, 0.2)
        if enterPressed and open then
            choose(results[selected])
        end
    end)
    box:GetPropertyChangedSignal("Text"):Connect(update)
    self:_listen("Began", function(input)
        if not open then
            return
        end
        if input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.Down then
            if #rows > 0 then
                local step = input.KeyCode == Enum.KeyCode.Up and -1 or 1
                selected = math.clamp(selected + step, 1, #rows)
                paintSelection()
                keepSelectionInView()
            end
        elseif input.KeyCode == Enum.KeyCode.Escape then
            setOpen(false)
        elseif isPress(input) then
            local point = pointerPosition()
            if not pointInside(point, popup) and not pointInside(point, holder) then
                setOpen(false)
            end
        end
    end)

    local function fit()
        local width = content.AbsoluteSize.X / self.Scale.Scale
        local searchWidth = math.clamp(math.floor(width * 0.32), 110, SEARCH_WIDTH)
        holder.Size = UDim2.fromOffset(searchWidth, 34)
        if searchWidth ~= self._searchWidth then
            self._searchWidth = searchWidth
            for _, tab in ipairs(self.Tabs) do
                self:_fitTitle(tab)
            end
        end
    end
    content:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    task.defer(fit)
end

-- Identity: the player's name and headshot shown in the sidebar and on the
-- home tab. The privacy switches hide them everywhere at once.

function Window:_trackName(textLabel, kind)
    table.insert(self._identity.Names, { Label = textLabel, Kind = kind })
    self:_renderIdentity()
end

function Window:_trackAvatar(image, placeholder)
    table.insert(self._identity.Avatars, { Image = image, Placeholder = placeholder })
    self:_renderIdentity(true)
end

function Window:_renderIdentity(instant)
    for _, entry in ipairs(self._identity.Names) do
        if entry.Kind == "User" then
            entry.Label.Text = self._hideName and "@hidden" or ("@" .. LocalPlayer.Name)
        else
            entry.Label.Text = self._hideName and "Hidden" or LocalPlayer.DisplayName
        end
    end
    local duration = instant and 0 or 0.2
    for _, entry in ipairs(self._identity.Avatars) do
        tween(entry.Image, { ImageTransparency = self._hideAvatar and 1 or 0 }, duration)
        tween(entry.Placeholder, { ImageTransparency = self._hideAvatar and 0.2 or 1 }, duration)
    end
end

function Window:SetHideName(hidden)
    self._hideName = hidden == true
    self:_renderIdentity()
end

function Window:SetHideAvatar(hidden)
    self._hideAvatar = hidden == true
    self:_renderIdentity()
end

local function avatar(window, parent, props, ringColor, ringTransparency, ringThickness)
    local holder = create("Frame", {
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Parent = parent,
    })
    for key, value in pairs(props) do
        holder[key] = value
    end
    corner(holder, UDim.new(1, 0))
    stroke(holder, ringColor or Theme.Stroke, ringTransparency or 0, ringThickness or 1)
    local image = create("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150",
        Parent = holder,
    })
    corner(image, UDim.new(1, 0))
    local placeholder = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.45, 0.45),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Muted,
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        Parent = holder,
    })
    applyIcon(placeholder, "user")
    window:_trackAvatar(image, placeholder)
    return holder
end

function Window:_buildProfile(sidebar)
    create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -PROFILE_HEIGHT),
        Size = UDim2.new(1, -20, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    local card = create("TextButton", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -8),
        Size = UDim2.new(1, -16, 0, PROFILE_HEIGHT - 16),
        BackgroundColor3 = Theme.Surface2,
        BackgroundTransparency = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = sidebar,
    })
    corner(card, UDim.new(0, 8))
    local cardStroke = stroke(card, Theme.Stroke, 0)
    local head = avatar(self, card, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(32, 32),
    })
    local online = create("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 1, 1, 1),
        Size = UDim2.fromOffset(9, 9),
        BackgroundColor3 = Theme.Success,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = head,
    })
    corner(online, UDim.new(1, 0))
    stroke(online, Theme.Surface2, 0, 2)
    local name = label({
        Position = UDim2.new(0, 48, 0.5, -15),
        Size = UDim2.new(1, -74, 0, 15),
        TextSize = 12,
        FontFace = Fonts.Bold,
        Parent = card,
    })
    self:_trackName(name, "Display")
    local gameLabel = label({
        Position = UDim2.new(0, 48, 0.5, 1),
        Size = UDim2.new(1, -74, 0, 13),
        Text = "…",
        TextSize = 11,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        Parent = card,
    })
    local chevron = create("ImageLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Muted,
        ScaleType = Enum.ScaleType.Fit,
        Parent = card,
    })
    applyIcon(chevron, "chevron-right")
    task.spawn(function()
        gameLabel.Text = detectGameName()
    end)
    card.MouseEnter:Connect(function()
        if usingTouch() then
            return
        end
        tween(cardStroke, { Color = Theme.StrokeHover }, 0.12)
        tween(chevron, { ImageColor3 = Theme.Text, Position = UDim2.new(1, -6, 0.5, 0) }, 0.15)
    end)
    card.MouseLeave:Connect(function()
        tween(cardStroke, { Color = Theme.Stroke }, 0.2)
        tween(chevron, { ImageColor3 = Theme.Muted, Position = UDim2.new(1, -8, 0.5, 0) }, 0.2)
    end)
    card.MouseButton1Click:Connect(function()
        if self.Home then
            self:SelectTab(self.Home)
        end
    end)
    self.Profile = card
end

-- Server actions

function Window:Rejoin()
    self:Notify({ Title = "Rejoining", Content = "Teleporting back into this server", Icon = "refresh-cw", Duration = 3 })
    task.spawn(function()
        local ok, err = pcall(function()
            if #Players:GetPlayers() <= 1 or game.JobId == "" then
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end)
        if not ok then
            self:Notify({ Title = "Rejoin failed", Content = tostring(err), Type = "Error", Duration = 4 })
        end
    end)
end

local function hopServers(window, order, pick, title)
    task.spawn(function()
        local servers = fetchServers(order)
        if not servers then
            window:Notify({ Title = title .. " failed", Content = "Could not load the server list", Type = "Error", Duration = 4 })
            return
        end
        local candidates = {}
        for _, server in ipairs(servers) do
            if type(server) == "table" and server.id ~= game.JobId then
                local playing, capacity = tonumber(server.playing), tonumber(server.maxPlayers)
                if playing and capacity and playing < capacity then
                    table.insert(candidates, server)
                end
            end
        end
        local target = #candidates > 0 and pick(candidates) or nil
        if not target then
            window:Notify({ Title = title .. " failed", Content = "No other open server found", Type = "Warning", Duration = 4 })
            return
        end
        window:Notify({
            Title = title,
            Content = string.format("Joining a server with %d/%d players", target.playing, target.maxPlayers),
            Icon = "server",
            Duration = 3,
        })
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, LocalPlayer)
        end)
        if not ok then
            window:Notify({ Title = title .. " failed", Content = tostring(err), Type = "Error", Duration = 4 })
        end
    end)
end

function Window:ServerHop()
    hopServers(self, "Desc", function(list)
        return list[math.random(1, #list)]
    end, "Server hop")
end

function Window:JoinLowestServer()
    hopServers(self, "Asc", function(list)
        table.sort(list, function(a, b)
            return a.playing < b.playing
        end)
        return list[1]
    end, "Lowest server")
end

function Window:CopyToClipboard(text, what)
    local ok = copyToClipboard(text)
    self:Notify({
        Title = ok and "Copied" or "Clipboard unavailable",
        Content = ok and (what or tostring(text)) or "Your executor has no setclipboard",
        Type = ok and "Success" or "Error",
        Icon = ok and "clipboard-check" or nil,
        Duration = 2.5,
    })
    return ok
end

-- Home

-- Home reads top to bottom: a banner greeting the player, a performance card
-- with live graphs, the server and links side by side, and a status line.

-- A Home card that grows with its stacked contents.
function Window:_homeCard(parent, order)
    local card = panelCard(parent, 0, order)
    card.AutomaticSize = Enum.AutomaticSize.Y
    padding(card, 16, 16, 14, 14)
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
    return card
end

-- A small caps heading at the top of a Home card.
function Window:_homeCaption(parent, text, order)
    return label({
        Size = UDim2.new(1, 0, 0, 22),
        Text = string.upper(text),
        TextSize = 10,
        TextColor3 = Theme.Muted,
        TextYAlignment = Enum.TextYAlignment.Top,
        LayoutOrder = order,
        Parent = parent,
    })
end

-- A rounded chip of an icon and short text. Returns the chip, its label and
-- its icon so callers can recolour them.
function Window:_homeChip(parent, order, icon, text, color)
    local chip = create("TextButton", {
        Size = UDim2.fromOffset(0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        Parent = parent,
    })
    corner(chip, UDim.new(0, 6))
    local chipStroke = stroke(chip)
    padding(chip, 8, 9)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = chip,
    })
    local image = create("ImageLabel", {
        Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
        ImageColor3 = color or Theme.Muted,
        ScaleType = Enum.ScaleType.Fit,
        LayoutOrder = 1,
        Parent = chip,
    })
    applyIcon(image, icon)
    local text_ = label({
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = text,
        TextSize = 12,
        TextColor3 = color or Theme.Muted,
        TextTruncate = Enum.TextTruncate.None,
        LayoutOrder = 2,
        Parent = chip,
    })
    return chip, text_, image, chipStroke
end

-- A chip that flips on press: on, it takes the accent; off, it sits muted.
function Window:_homeToggleChip(parent, order, icon, text, initial, callback)
    local chip, text_, image, chipStroke = self:_homeChip(parent, order, icon, text)
    local on = initial == true
    local function paint(duration)
        tween(chip, { BackgroundColor3 = on and Theme.Accent or Theme.Surface3, BackgroundTransparency = on and 0.85 or 0.2 }, duration)
        tween(chipStroke, { Color = on and Theme.Accent or Theme.Stroke, Transparency = on and 0.6 or 0 }, duration)
        tween(text_, { TextColor3 = on and Theme.Accent or Theme.Muted }, duration)
        tween(image, { ImageColor3 = on and Theme.Accent or Theme.Muted }, duration)
    end
    paint(0)
    chip.MouseButton1Click:Connect(function()
        on = not on
        paint(0.2)
        safeCall(callback, on)
    end)
    return chip
end

function Window:_homeProfile(list, opts, order)
    local banner = panelCard(list, 140, order)
    banner.ClipsDescendants = true

    -- The avatar bust stands on the banner's right edge and fades in from
    -- the left, so it reads as part of the card rather than a framed photo.
    local bust = create("ImageLabel", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, 0),
        Size = UDim2.fromOffset(140, 140),
        BackgroundTransparency = 1,
        Image = "rbxthumb://type=AvatarBust&id=" .. tostring(LocalPlayer.UserId) .. "&w=420&h=420",
        ScaleType = Enum.ScaleType.Fit,
        Parent = banner,
    })
    create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.45, 0),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Parent = bust,
    })
    local bustPlaceholder = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.6, 0.55),
        Size = UDim2.fromOffset(40, 40),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Muted,
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        Parent = bust,
    })
    applyIcon(bustPlaceholder, "user")
    self:_trackAvatar(bust, bustPlaceholder)

    local textWidth = UDim2.new(1, -190, 0, 0)
    label({
        Position = UDim2.fromOffset(22, 20),
        Size = textWidth + UDim2.fromOffset(0, 14),
        Text = string.upper(opts.Welcome or "Welcome back"),
        TextSize = 10,
        TextColor3 = Theme.Muted,
        Parent = banner,
    })
    local nameLabel = label({
        Position = UDim2.fromOffset(22, 35),
        Size = textWidth + UDim2.fromOffset(0, 32),
        TextSize = 26,
        FontFace = Fonts.Bold,
        Parent = banner,
    })
    self:_trackName(nameLabel, "Display")
    local userLabel = label({
        Position = UDim2.fromOffset(22, 67),
        Size = textWidth + UDim2.fromOffset(0, 16),
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        Parent = banner,
    })
    self:_trackName(userLabel, "User")

    -- Chips along the bottom: tier, time left, then the privacy toggles.
    local chips = create("Frame", {
        Position = UDim2.new(0, 22, 1, -40),
        Size = UDim2.new(1, -44, 0, 24),
        BackgroundTransparency = 1,
        Parent = banner,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = chips,
    })
    local tier = opts.Tier
    if tier == nil then
        tier = "Free"
    end
    if tier then
        local tierChip, tierText, tierIcon = self:_homeChip(chips, 1, opts.TierIcon or self._logoIcon, tostring(tier), Theme.Accent)
        tierChip.Active = false
        tierText.FontFace = Fonts.Bold
        tierIcon.Size = UDim2.fromOffset(13, 13)
        self.TierLabel = tierText
    end
    local expiryChip, expiryText = self:_homeChip(chips, 2, "clock", "")
    expiryChip.Active = false
    expiryChip.Visible = false
    self:_homeToggleChip(chips, 3, "eye-off", "Name", self._hideName, function(on)
        self:SetHideName(on)
    end)
    self:_homeToggleChip(chips, 4, "user-x", "Avatar", self._hideAvatar, function(on)
        self:SetHideAvatar(on)
    end)

    return function()
        local value = opts.Expiry
        if type(value) == "function" then
            local ok, result = pcall(value)
            value = ok and result or nil
        end
        if type(value) == "number" then
            local left = value - os.time()
            expiryText.Text = left > 0 and (formatDuration(left) .. " left") or "Expired"
        elseif value ~= nil then
            expiryText.Text = tostring(value)
        end
        expiryChip.Visible = expiryText.Text ~= ""
    end
end

-- A large live readout with a short bar history under it. Returns the value
-- label and a push(value, color) that adds a sample.
function Window:_homeGraph(parent, order, icon, title, ceiling)
    local cell = create("Frame", {
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Parent = parent,
    })
    local holder = glowIcon(cell, icon, Theme.Muted, UDim2.new(0, 0, 0, 7))
    holder.Size = UDim2.fromOffset(12, 12)
    label({
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(1, -18, 0, 14),
        Text = string.upper(title),
        TextSize = 10,
        TextColor3 = Theme.Muted,
        Parent = cell,
    })
    local value = label({
        Position = UDim2.fromOffset(0, 16),
        Size = UDim2.new(1, 0, 0, 28),
        Text = "…",
        TextSize = 24,
        FontFace = Fonts.Bold,
        RichText = true,
        Parent = cell,
    })
    local track = create("Frame", {
        Position = UDim2.fromOffset(0, 50),
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        Parent = cell,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = track,
    })
    local COUNT = 24
    local bars, samples = {}, {}
    for index = 1, COUNT do
        local bar = create("Frame", {
            Size = UDim2.new(1 / COUNT, -2, 0, 2),
            BackgroundColor3 = Theme.Surface3,
            BorderSizePixel = 0,
            LayoutOrder = index,
            Parent = track,
        })
        corner(bar, UDim.new(0, 2))
        bars[index] = bar
    end
    local function push(sample, color)
        table.insert(samples, sample)
        if #samples > COUNT then
            table.remove(samples, 1)
        end
        local top = ceiling or 1
        for _, s in ipairs(samples) do
            top = math.max(top, s)
        end
        local offset = COUNT - #samples
        for index, bar in ipairs(bars) do
            local s = samples[index - offset]
            local latest = index == COUNT
            local height = s and math.max(s / top, 0.08) or 0
            tween(bar, {
                Size = UDim2.new(1 / COUNT, -2, height, s and 0 or 2),
                BackgroundColor3 = (latest and color) or (s and Theme.Muted or Theme.Surface3),
                BackgroundTransparency = latest and 0 or (s and 0.6 or 0),
            }, 0.35, Enum.EasingStyle.Quint)
        end
    end
    return value, push
end

-- A small figure: value over a caps caption.
function Window:_homeFigure(parent, order, title)
    local cell = create("Frame", {
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Parent = parent,
    })
    local value = label({
        Size = UDim2.new(1, -8, 0, 20),
        Text = "…",
        TextSize = 15,
        FontFace = Fonts.Bold,
        RichText = true,
        Parent = cell,
    })
    label({
        Position = UDim2.fromOffset(0, 21),
        Size = UDim2.new(1, -8, 0, 14),
        Text = string.upper(title),
        TextSize = 10,
        TextColor3 = Theme.Muted,
        Parent = cell,
    })
    return value
end

-- A square tile button: an icon over a short label.
function Window:_homeAction(parent, order, icon, text, callback)
    local button = create("TextButton", {
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true,
        LayoutOrder = order,
        Parent = parent,
    })
    corner(button, UDim.new(0, 8))
    local buttonStroke = stroke(button)
    local image = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 11),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Text,
        ScaleType = Enum.ScaleType.Fit,
        Parent = button,
    })
    applyIcon(image, icon)
    label({
        Position = UDim2.new(0, 4, 0, 32),
        Size = UDim2.new(1, -8, 0, 14),
        Text = text,
        TextSize = 11,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = button,
    })
    button.MouseEnter:Connect(function()
        tween(button, { BackgroundTransparency = 0 }, 0.15, Enum.EasingStyle.Quint)
        tween(buttonStroke, { Color = Theme.StrokeHover }, 0.15)
        tween(image, { ImageColor3 = Theme.Accent }, 0.15)
    end)
    button.MouseLeave:Connect(function()
        tween(button, { BackgroundTransparency = 0.5 }, 0.25, Enum.EasingStyle.Quint)
        tween(buttonStroke, { Color = Theme.Stroke }, 0.25)
        tween(image, { ImageColor3 = Theme.Text }, 0.25)
    end)
    button.MouseButton1Click:Connect(function()
        ripple(button)
        safeCall(callback)
    end)
    return button
end

function Window:_homeGame(parent, order)
    local card = self:_homeCard(parent, order)
    local head = create("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = card,
    })
    local icon = create("ImageLabel", {
        Size = UDim2.fromOffset(44, 44),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150",
        Parent = head,
    })
    corner(icon, UDim.new(0, 10))
    stroke(icon)
    local gameName = label({
        Position = UDim2.fromOffset(56, 3),
        Size = UDim2.new(1, -56, 0, 20),
        Text = "Loading",
        TextSize = 15,
        FontFace = Fonts.Bold,
        Parent = head,
    })
    local detail = label({
        Position = UDim2.fromOffset(56, 24),
        Size = UDim2.new(1, -56, 0, 16),
        Text = "",
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        Parent = head,
    })
    local owner = nil
    task.spawn(function()
        local info = fetchGameInfo()
        gameName.Text = info and info.Name or detectGameName()
        owner = info and type(info.Creator) == "table" and info.Creator.Name or nil
    end)

    local actions = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        Parent = card,
    })
    padding(actions, 0, 0, 12, 0)
    create("UIGridLayout", {
        CellPadding = UDim2.fromOffset(6, 6),
        CellSize = UDim2.new(0.25, -5, 0, 54),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = actions,
    })
    self:_homeAction(actions, 1, "refresh-cw", "Rejoin", function()
        self:Rejoin()
    end)
    self:_homeAction(actions, 2, "shuffle", "Hop", function()
        self:ServerHop()
    end)
    self:_homeAction(actions, 3, "users", "Lowest", function()
        self:JoinLowestServer()
    end)
    self:_homeAction(actions, 4, "copy", "Job ID", function()
        self:CopyToClipboard(game.JobId, "Job ID")
    end)

    label({
        Size = UDim2.new(1, 0, 0, 26),
        Text = "Job " .. shortId(game.JobId) .. "  ·  Place " .. tostring(game.PlaceId),
        TextSize = 11,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextYAlignment = Enum.TextYAlignment.Bottom,
        LayoutOrder = 3,
        Parent = card,
    })

    -- The detail line keeps the player count live.
    return function()
        local count = #Players:GetPlayers() .. "/" .. Players.MaxPlayers .. " players"
        detail.Text = owner and ("by " .. owner .. "  ·  " .. count) or count
    end
end

-- One row of the links card: icon, title and text, and a round icon button.
function Window:_homeLink(card, order, icon, title, text, buttonIcon, callback)
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Parent = card,
    })
    create("Frame", {
        Name = "Rule",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = row,
    })
    local holder = glowIcon(row, icon, Theme.Accent, UDim2.new(0, 0, 0.5, 0))
    holder.Size = UDim2.fromOffset(16, 16)
    local titleLabel = label({
        Position = UDim2.fromOffset(28, 6),
        Size = UDim2.new(1, -68, 0, 18),
        Text = title,
        TextSize = 13,
        Parent = row,
    })
    local textLabel = label({
        Position = UDim2.fromOffset(28, 24),
        Size = UDim2.new(1, -68, 0, 15),
        Text = text,
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        Parent = row,
    })
    local button = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    corner(button, UDim.new(0, 8))
    local buttonStroke = stroke(button)
    local image = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Muted,
        ScaleType = Enum.ScaleType.Fit,
        Parent = button,
    })
    applyIcon(image, buttonIcon)
    button.MouseEnter:Connect(function()
        tween(button, { BackgroundTransparency = 0 }, 0.15, Enum.EasingStyle.Quint)
        tween(buttonStroke, { Color = Theme.StrokeHover }, 0.15)
        tween(image, { ImageColor3 = Theme.Accent }, 0.15)
    end)
    button.MouseLeave:Connect(function()
        tween(button, { BackgroundTransparency = 0.5 }, 0.25, Enum.EasingStyle.Quint)
        tween(buttonStroke, { Color = Theme.Stroke }, 0.25)
        tween(image, { ImageColor3 = Theme.Muted }, 0.25)
    end)
    button.MouseButton1Click:Connect(function()
        safeCall(callback)
    end)
    return row, titleLabel, textLabel
end

-- Builds the links card into parent, or nothing when there are no links and
-- the feature list is off. Returns the card (or nil) and the feature refresh.
function Window:_homeLinks(parent, opts, order)
    local links = {}
    if opts.Discord then
        table.insert(links, {
            Icon = opts.DiscordIcon or "message-circle",
            Title = opts.DiscordTitle or "Community",
            Text = opts.Discord,
        })
    end
    if opts.Website then
        table.insert(links, {
            Icon = opts.WebsiteIcon or "globe",
            Title = opts.WebsiteTitle or "Website",
            Text = opts.Website,
        })
    end
    for _, link in ipairs(opts.Links or {}) do
        table.insert(links, link)
    end
    local features = opts.Features
    if #links == 0 and features == false then
        return nil, function() end
    end
    local card = self:_homeCard(parent, order)
    self:_homeCaption(card, "Links", 0)
    for index, link in ipairs(links) do
        local action = type(link.Callback) == "function"
        self:_homeLink(card, index, link.Icon or "link", link.Title or "", link.Text or "", action and "arrow-up-right" or "copy", function()
            if action then
                safeCall(link.Callback)
            else
                self:CopyToClipboard(link.Copy or link.Text, link.Title)
            end
        end)
    end
    local refresh = function() end
    if features ~= false then
        if type(features) == "table" then
            self._featuresTitle = features.Title
            self._features = features.List or (#features > 0 and features or nil)
        end
        local _, _, text_ = self:_homeLink(card, 100,
            type(features) == "table" and features.Icon or "list-checks",
            type(features) == "table" and features.Title or "Feature list",
            "", "chevron-right", function()
                self:ShowFeatures()
            end)
        refresh = function()
            local desc = type(features) == "table" and features.Desc
            text_.Text = desc or (self:_featureSummary())
        end
        task.defer(refresh)
    end
    -- The first row needs no rule above it.
    local first = nil
    for _, child in ipairs(card:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChild("Rule") and (not first or child.LayoutOrder < first.LayoutOrder) then
            first = child
        end
    end
    if first then
        first.Rule.Visible = false
    end
    return card, refresh
end

-- A quiet status line under the cards: executor support on the left, the
-- hide key on the right.
function Window:_homeExecutor(list, opts, order)
    local line = create("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Parent = list,
    })
    local executor, supported, message = executorReport(opts)
    local dot = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 4, 0.5, 0),
        Size = UDim2.fromOffset(7, 7),
        BackgroundColor3 = supported and Theme.Success or Theme.Warning,
        BorderSizePixel = 0,
        Parent = line,
    })
    corner(dot, UDim.new(1, 0))
    local left = create("Frame", {
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(1, -170, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = line,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = left,
    })
    label({
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = executor,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.None,
        LayoutOrder = 1,
        Parent = left,
    })
    label({
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = message,
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = supported and Theme.Muted or Theme.Warning,
        TextTruncate = Enum.TextTruncate.None,
        LayoutOrder = 2,
        Parent = left,
    })

    local hint = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -2, 0.5, 0),
        Size = UDim2.fromOffset(0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Parent = line,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = hint,
    })
    label({
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = TOUCH and "Tap the pill or" or "Hide with",
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextTruncate = Enum.TextTruncate.None,
        LayoutOrder = 1,
        Parent = hint,
    })
    local chip = create("Frame", {
        Size = UDim2.fromOffset(0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        Parent = hint,
    })
    corner(chip, UDim.new(0, 5))
    stroke(chip)
    padding(chip, 6, 6)
    self._keyChipLabel = label({
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = keyName(self.Keybind),
        TextSize = 11,
        FontFace = Fonts.Bold,
        TextTruncate = Enum.TextTruncate.None,
        Parent = chip,
    })
end

-- Feature list: every control the script adds, grouped by tab, or a list the
-- script writes itself. Items that match a control jump to it when picked.

Window._featureKinds = {
    Toggle = true,
    Slider = true,
    Dropdown = true,
    Input = true,
    Keybind = true,
    ColorPicker = true,
    Stepper = true,
    Button = true,
    ButtonRow = true,
    OrderList = true,
}

function Window:_featureGroups()
    local found, byName = {}, {}
    for _, tab in ipairs(self.Tabs) do
        if tab ~= self.Home and tab._userVisible ~= false then
            local group = { Name = tab.Name, Icon = tab._iconName, Items = {} }
            for _, page in ipairs(tab._subTabs or { tab }) do
                local sub = page._isSubTab and page or nil
                local function add(name, element, box, path)
                    if type(name) ~= "string" or name == "" then
                        return
                    end
                    local item = {
                        Name = name,
                        Kind = element._type == "ButtonRow" and "Button" or element._type,
                        Path = path,
                        Result = { Tab = tab, Sub = sub, Target = element, Group = box },
                    }
                    table.insert(group.Items, item)
                    byName[string.lower(name)] = byName[string.lower(name)] or item
                end
                local function addElement(element, box, path)
                    if element._destroyed or not self._featureKinds[element._type] or (element._isShown and not element:_isShown()) then
                        return
                    end
                    if element._type == "ButtonRow" and element.Buttons then
                        for _, button in ipairs(element.Buttons) do
                            add(button.Label.Text, element, box, path)
                        end
                    else
                        add(element._searchName, element, box, path)
                    end
                end
                if not page._noSearch then
                    for _, element in ipairs(page._items or {}) do
                        addElement(element, nil, sub and sub.Name or nil)
                    end
                    for _, box in ipairs(page._groupboxes or {}) do
                        if box._userVisible ~= false and not box._manager then
                            for _, element in ipairs(box._items) do
                                addElement(element, box, sub and (sub.Name .. "  ›  " .. box.Name) or box.Name)
                            end
                        end
                    end
                end
            end
            if #group.Items > 0 then
                table.insert(found, group)
            end
        end
    end
    local custom = self._features
    if type(custom) ~= "table" then
        return found
    end
    -- A written list: groups of items, or bare items, which gather into one
    -- group where the first one appears.
    local function customItem(entry)
        if type(entry) ~= "table" then
            entry = { Name = entry }
        end
        local name = tostring(entry.Name or entry.Title or entry[1] or "")
        local link = byName[string.lower(name)]
        return {
            Name = name,
            Desc = entry.Desc or entry.Description,
            Tag = entry.Tag,
            Icon = entry.Icon,
            Kind = link and link.Kind,
            Path = link and link.Path,
            Result = link and link.Result,
            Callback = entry.Callback,
        }
    end
    local groups, loose = {}, nil
    for _, entry in ipairs(custom) do
        if type(entry) == "table" and type(entry.Items) == "table" then
            local group = { Name = tostring(entry.Name or entry.Title or "Features"), Icon = entry.Icon, Items = {} }
            for _, item in ipairs(entry.Items) do
                table.insert(group.Items, customItem(item))
            end
            table.insert(groups, group)
        else
            if not loose then
                loose = { Name = self._featuresTitle or "Features", Items = {} }
                table.insert(groups, loose)
            end
            table.insert(loose.Items, customItem(entry))
        end
    end
    return groups
end

function Window:_featureSummary()
    local groups = self:_featureGroups()
    local count = 0
    for _, group in ipairs(groups) do
        count += #group.Items
    end
    local text = count .. (count == 1 and " feature" or " features")
    if type(self._features) ~= "table" and #groups > 0 then
        text ..= " across " .. #groups .. (#groups == 1 and " tab" or " tabs")
    end
    return text, groups, count
end

-- Opens the feature list over the window. Search filters it; picking an item
-- linked to a control closes the list and jumps to that control.
function Window:ShowFeatures()
    if self._dialog then
        self._dialog.Close()
    end
    local summary, groups, total = self:_featureSummary()
    local PAD = 16
    local ROW = TOUCH and 44 or 38
    local body = self.Body

    local overlay = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 40,
        Parent = body,
    })
    -- A canvas group so the whole list fades as one on open and close.
    local card_ = create("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 10),
        Size = UDim2.fromOffset(420, 460),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Active = true,
        Parent = overlay,
    })
    corner(card_, UDim.new(0, 12))
    local cardStroke = stroke(card_, Theme.Stroke, 1)
    local cardScale = create("UIScale", { Scale = 0.94, Parent = card_ })
    local function fit()
        local scale = self.Scale.Scale
        local size = body.AbsoluteSize / scale
        card_.Size = UDim2.fromOffset(math.min(440, size.X - 24), math.min(480, size.Y - 24))
    end
    fit()
    local fitConnection = body:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)

    local iconHolder = glowIcon(card_, "list-checks", Theme.Accent, UDim2.new(0, PAD, 0, PAD + 10))
    iconHolder.Size = UDim2.fromOffset(18, 18)
    label({
        Position = UDim2.fromOffset(PAD + 28, PAD),
        Size = UDim2.new(1, -(PAD * 2 + 28 + 36), 0, 18),
        Text = self._featuresTitle or "Features",
        TextSize = 15,
        Parent = card_,
    })
    label({
        Position = UDim2.fromOffset(PAD + 28, PAD + 19),
        Size = UDim2.new(1, -(PAD * 2 + 28 + 36), 0, 14),
        Text = summary,
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        Parent = card_,
    })
    local closeButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -(PAD - 6), 0, PAD - 6),
        Size = TOUCH and UDim2.fromOffset(40, 40) or UDim2.fromOffset(32, 32),
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Parent = card_,
    })
    corner(closeButton, UDim.new(0, 8))
    local closeIcon = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Muted,
        ScaleType = Enum.ScaleType.Fit,
        Parent = closeButton,
    })
    applyIcon(closeIcon, "x")
    if closeIcon.Image == "" then
        closeIcon:Destroy()
        label({ Size = UDim2.fromScale(1, 1), Text = "×", TextSize = 20, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center, Parent = closeButton })
    end
    closeButton.MouseEnter:Connect(function()
        tween(closeButton, { BackgroundTransparency = 0.5 }, 0.12)
    end)
    closeButton.MouseLeave:Connect(function()
        tween(closeButton, { BackgroundTransparency = 1 }, 0.2)
    end)

    local top = PAD + 44
    local searchHolder = create("Frame", {
        Position = UDim2.fromOffset(PAD, top),
        Size = UDim2.new(1, -PAD * 2, 0, TOUCH and 36 or 32),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = card_,
    })
    corner(searchHolder, UDim.new(0, 7))
    local searchStroke = stroke(searchHolder)
    local _, searchIcon = glowIcon(searchHolder, "search", Theme.Muted, UDim2.new(0, 10, 0.5, 0))
    searchIcon.Parent.Size = UDim2.fromOffset(14, 14)
    local searchBox = create("TextBox", {
        Position = UDim2.fromOffset(32, 0),
        Size = UDim2.new(1, -40, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search features",
        PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text,
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClearTextOnFocus = false,
        Parent = searchHolder,
    })
    searchBox.Focused:Connect(function()
        tween(searchStroke, { Color = Theme.StrokeHover }, 0.15)
        tween(searchIcon, { ImageColor3 = Theme.Accent }, 0.15)
    end)
    searchBox.FocusLost:Connect(function()
        tween(searchStroke, { Color = Theme.Stroke }, 0.2)
        tween(searchIcon, { ImageColor3 = Theme.Muted }, 0.2)
    end)
    top += (TOUCH and 36 or 32) + 10

    local scroller = create("ScrollingFrame", {
        Position = UDim2.fromOffset(PAD, top),
        Size = UDim2.new(1, -PAD * 2 + 6, 1, -(top + PAD - 4)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = TOUCH and 4 or 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(),
        Parent = card_,
    })
    local content = create("Frame", {
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = scroller,
    })
    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = content,
    })
    -- Canvas sized by hand, as elsewhere, so it scrolls under UIScale.
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroller.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y / self.Scale.Scale + 4)
    end)
    local noResults = label({
        Size = UDim2.new(1, 0, 0, 60),
        Text = total == 0 and "No features yet" or "No matches",
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 0,
        Visible = total == 0,
        Parent = content,
    })

    local dialog = {}
    local closed = false
    local stopEscape = nil
    function dialog.Close()
        if closed then
            return
        end
        closed = true
        if self._dialog == dialog then
            self._dialog = nil
        end
        fitConnection:Disconnect()
        if stopEscape then
            -- Deferred: Close can run from inside the input dispatch loop.
            task.defer(stopEscape)
        end
        if searchBox:IsFocused() then
            searchBox:ReleaseFocus()
        end
        tween(overlay, { BackgroundTransparency = 1 }, 0.18)
        tween(card_, { Position = UDim2.new(0.5, 0, 0.5, 8), GroupTransparency = 1 }, 0.18, Enum.EasingStyle.Quint)
        tween(cardScale, { Scale = 0.96 }, 0.18, Enum.EasingStyle.Quint)
        tween(cardStroke, { Transparency = 1 }, 0.12)
        task.delay(0.2, function()
            overlay:Destroy()
        end)
    end

    local sections = {}
    local order = 0
    for _, group in ipairs(groups) do
        order += 1
        local header = create("Frame", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = content,
        })
        local headIcon = glowIcon(header, group.Icon or "layout-grid", Theme.Accent, UDim2.new(0, 2, 0, 18))
        headIcon.Size = UDim2.fromOffset(14, 14)
        label({
            Position = UDim2.fromOffset(24, 10),
            Size = UDim2.new(1, -70, 0, 16),
            Text = string.upper(group.Name),
            TextSize = 11,
            TextColor3 = Theme.Muted,
            Parent = header,
        })
        local countLabel = label({
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -4, 0, 10),
            Size = UDim2.new(0, 40, 0, 16),
            Text = tostring(#group.Items),
            TextSize = 11,
            TextColor3 = Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = header,
        })
        local section = { Header = header, Count = countLabel, Rows = {} }
        for _, item in ipairs(group.Items) do
            order += 1
            local sub = item.Desc or item.Path
            local clickable = item.Result ~= nil or type(item.Callback) == "function"
            local row = create("TextButton", {
                Size = UDim2.new(1, 0, 0, sub and ROW + 4 or ROW - 4),
                BackgroundColor3 = Theme.Surface2,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = order,
                Parent = content,
            })
            corner(row, UDim.new(0, 8))
            local rowIcon = glowIcon(row, item.Icon or self._searchIcons[item.Kind] or "check", Theme.Muted, UDim2.new(0, 10, 0.5, 0))
            rowIcon.Size = UDim2.fromOffset(14, 14)
            local right = 12 + (clickable and 22 or 0)
            local tag
            if item.Tag then
                tag = create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -(clickable and 30 or 10), 0.5, 0),
                    Size = UDim2.fromOffset(0, 20),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 0.85,
                    BorderSizePixel = 0,
                    Parent = row,
                })
                corner(tag, UDim.new(0, 5))
                padding(tag, 7, 7)
                label({
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = tostring(item.Tag),
                    TextSize = 11,
                    TextColor3 = Theme.Accent,
                    TextTruncate = Enum.TextTruncate.None,
                    Parent = tag,
                })
            end
            local nameLabel = label({
                Position = UDim2.fromOffset(34, sub and 5 or 0),
                Size = UDim2.new(1, -(34 + right), 0, sub and 18 or ROW - 4),
                Text = item.Name,
                TextSize = 13,
                Parent = row,
            })
            local subLabel
            if sub then
                subLabel = label({
                    Position = UDim2.fromOffset(34, 23),
                    Size = UDim2.new(1, -(34 + right), 0, 14),
                    Text = sub,
                    TextSize = 11,
                    FontFace = Fonts.Regular,
                    TextColor3 = Theme.Muted,
                    Parent = row,
                })
            end
            if tag then
                local function reserveTag()
                    local width = 34 + right + tag.AbsoluteSize.X / self.Scale.Scale + 8
                    nameLabel.Size = UDim2.new(1, -width, 0, nameLabel.Size.Y.Offset)
                    if subLabel then
                        subLabel.Size = UDim2.new(1, -width, 0, 14)
                    end
                end
                tag:GetPropertyChangedSignal("AbsoluteSize"):Connect(reserveTag)
                task.defer(reserveTag)
            end
            if clickable then
                local go = create("ImageLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundTransparency = 1,
                    ImageColor3 = Theme.Muted,
                    ImageTransparency = 0.4,
                    ScaleType = Enum.ScaleType.Fit,
                    Parent = row,
                })
                applyIcon(go, "arrow-up-right")
            end
            local isTap = tapGuard(row, function()
                return scroller
            end)
            row.MouseEnter:Connect(function()
                if not usingTouch() then
                    tween(row, { BackgroundTransparency = 0.3 }, 0.12)
                end
            end)
            row.MouseLeave:Connect(function()
                tween(row, { BackgroundTransparency = 1 }, 0.2)
            end)
            row.MouseButton1Click:Connect(function()
                if not clickable or not isTap() then
                    return
                end
                dialog.Close()
                if item.Result then
                    self:_revealResult(item.Result)
                end
                safeCall(item.Callback)
            end)
            table.insert(section.Rows, { Frame = row, Key = string.lower(item.Name .. " " .. (sub or "")) })
        end
        table.insert(sections, section)
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(searchBox.Text)
        local any = false
        for _, section in ipairs(sections) do
            local shown = 0
            for _, row in ipairs(section.Rows) do
                local match = query == "" or string.find(row.Key, query, 1, true) ~= nil
                row.Frame.Visible = match
                if match then
                    shown += 1
                end
            end
            section.Header.Visible = shown > 0
            section.Count.Text = tostring(shown)
            any = any or shown > 0
        end
        noResults.Visible = not any
        scroller.CanvasPosition = Vector2.zero
    end)
    closeButton.MouseButton1Click:Connect(dialog.Close)
    overlay.MouseButton1Click:Connect(dialog.Close)
    stopEscape = self:_listen("Began", function(input)
        if input.KeyCode == Enum.KeyCode.Escape then
            dialog.Close()
        end
    end)

    self._dialog = dialog
    tween(overlay, { BackgroundTransparency = 0.45 }, 0.25)
    tween(card_, { Position = UDim2.fromScale(0.5, 0.5), GroupTransparency = 0 }, 0.3, Enum.EasingStyle.Quint)
    tween(cardScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
    return dialog
end

function Window:_homeStats(list, opts, order, tab)
    local show = opts.Stats or { "Players", "Execs", "Session", "FPS", "Ping" }
    -- FPS and ping get large readouts with a bar history; every other stat
    -- is a small figure in the row under them.
    local card = self:_homeCard(list, order)
    local graphs = create("Frame", {
        Size = UDim2.new(1, 0, 0, 76),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = card,
    })
    create("UIGridLayout", {
        CellPadding = UDim2.fromOffset(24, 0),
        CellSize = UDim2.new(0.5, -12, 0, 76),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = graphs,
    })
    local rule = create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        Parent = card,
    })
    local figures = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Parent = card,
    })
    padding(figures, 0, 0, 12, 0)
    local figureGrid = create("UIGridLayout", {
        CellPadding = UDim2.fromOffset(0, 8),
        CellSize = UDim2.new(0.25, 0, 0, 36),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = figures,
    })
    local values, sparks = {}, {}
    local graphCount, figureCount = 0, 0
    for index, name in ipairs(show) do
        local kind = STAT_TYPES[name]
        if kind and not values[name] then
            if name == "FPS" or name == "Ping" then
                graphCount += 1
                values[name], sparks[name] = self:_homeGraph(graphs, index, kind[1], kind[2], name == "FPS" and 60 or 100)
            else
                figureCount += 1
                values[name] = self:_homeFigure(figures, index, kind[2])
            end
        end
    end
    graphs.Visible = graphCount > 0
    figures.Visible = figureCount > 0
    rule.Visible = graphCount > 0 and figureCount > 0
    if graphCount == 0 then
        padding(figures, 0, 0, 0, 0)
    end
    local function fitFigures()
        local width = figures.AbsoluteSize.X / self.Scale.Scale
        local columns = math.clamp(figureCount, 1, width >= 440 and 5 or 3)
        figureGrid.CellSize = UDim2.new(1 / columns, 0, 0, 36)
    end
    figures:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitFigures)
    task.defer(fitFigures)

    if values.Executor then
        values.Executor.Text = detectExecutor()
    end
    if values.Game then
        values.Game.Text = "Loading"
        task.spawn(function()
            values.Game.Text = detectGameName()
        end)
    end
    if values.Region then
        values.Region.Text = "Loading"
        detectRegion(function(region)
            values.Region.Text = region
        end)
    end
    if values.Execs then
        local executions = bumpExecutions(opts.StatsFolder or self.ConfigFolder)
        values.Execs.Text = executions and tostring(executions) or "—"
    end
    if values.Friends then
        local friends = {}
        local function recount()
            local total = 0
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local known = friends[player.UserId]
                    if known == nil then
                        local ok, result = pcall(function()
                            return LocalPlayer:IsFriendsWith(player.UserId)
                        end)
                        known = ok and result == true
                        friends[player.UserId] = known
                    end
                    if known then
                        total += 1
                    end
                end
            end
            values.Friends.Text = tostring(total)
        end
        task.spawn(recount)
        table.insert(self._connections, Players.PlayerAdded:Connect(function()
            task.spawn(recount)
        end))
        table.insert(self._connections, Players.PlayerRemoving:Connect(function()
            task.defer(recount)
        end))
    end

    local session = values.Session or values.Uptime
    local started = os.clock()
    local frames = 0
    self:_listen("Render", function()
        frames += 1
    end)
    -- FPS, ping and memory are tinted by how healthy they are, unless the
    -- script turns that off with StatColors = false.
    local tinted = opts.StatColors ~= false
    local function tint(valueLabel, color)
        if tinted and valueLabel.TextColor3 ~= color then
            tween(valueLabel, { TextColor3 = color }, 0.3)
        end
    end
    return function()
        if values.FPS then
            values.FPS.Text = tostring(frames)
            tint(values.FPS, Library._healthColor(frames, 50, 30))
            sparks.FPS(frames, Library._healthColor(frames, 50, 30))
        end
        frames = 0
        if values.Ping then
            local ok, ping = pcall(function()
                return math.floor(LocalPlayer:GetNetworkPing() * 1000)
            end)
            ping = ok and ping or 0
            values.Ping.Text = ping .. "ms"
            tint(values.Ping, Library._healthColor(ping, 90, 180, true))
            sparks.Ping(ping, Library._healthColor(ping, 90, 180, true))
        end
        if values.Players then
            values.Players.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
        end
        if session then
            session.Text = formatDuration(os.clock() - started)
        end
        if values.Time then
            values.Time.Text = os.date(opts.TimeFormat or "%H:%M")
        end
        if values.ServerAge then
            values.ServerAge.Text = formatDuration(workspace.DistributedGameTime)
        end
        if values.Memory then
            local ok, memory = pcall(function()
                return StatsService:GetTotalMemoryUsageMb()
            end)
            values.Memory.Text = ok and string.format("%d MB", memory) or "—"
            tint(values.Memory, ok and Library._healthColor(memory, 1500, 3000, true) or Theme.Text)
        end
    end, function()
        frames = 0
    end
end

local function homePage(sub, page)
    local list = sub.List
    if type(page.Content) == "string" then
        local card_ = panelCard(list, 0, 1)
        card_.AutomaticSize = Enum.AutomaticSize.Y
        padding(card_, 16, 16, 14, 16)
        label({
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = page.Content,
            TextSize = 13,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = card_,
        })
    end
    if type(page.Entries) == "table" then
        for index, entry in ipairs(page.Entries) do
            local card_ = panelCard(list, 0, index + 1)
            card_.AutomaticSize = Enum.AutomaticSize.Y
            padding(card_, 16, 16, 14, 16)
            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = card_,
            })
            local head = create("Frame", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Parent = card_,
            })
            label({
                Size = UDim2.new(1, -90, 1, 0),
                Text = entry.Title or entry.Version or "Update",
                TextSize = 15,
                Parent = head,
            })
            if entry.Date or entry.Tag then
                local chip = create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(0, 20),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = Theme.Surface,
                    BorderSizePixel = 0,
                    Parent = head,
                })
                corner(chip, UDim.new(0, 5))
                stroke(chip)
                padding(chip, 8, 8)
                label({
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = entry.Tag or entry.Date,
                    TextSize = 11,
                    TextColor3 = Theme.Muted,
                    TextTruncate = Enum.TextTruncate.None,
                    Parent = chip,
                })
            end
            local body = entry.Content or entry.Body
            if type(entry.Changes) == "table" then
                body = "• " .. table.concat(entry.Changes, "\n• ")
            end
            if body then
                label({
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Text = body,
                    TextSize = 13,
                    FontFace = Fonts.Regular,
                    TextColor3 = Theme.Muted,
                    TextWrapped = true,
                    TextTruncate = Enum.TextTruncate.None,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    LayoutOrder = 2,
                    Parent = card_,
                })
            end
        end
    end
    if type(page.Build) == "function" then
        safeCall(page.Build, sub, list)
    else
        sub._noSearch = true
    end
end

function Window:_buildHome(opts)
    self._hideName = opts.HideName == true
    self._hideAvatar = opts.HideAvatar == true
    self:_renderIdentity(true)
    local tab = self:Tab({
        Name = opts.Name or "Home",
        Desc = opts.Desc,
        Icon = opts.Icon or "house",
        PageTitle = opts.Title or "Home",
    })
    tab._order = 100
    self.Home = tab

    local pages = opts.Pages or opts.Tabs
    local overview = tab
    if type(pages) == "table" and #pages > 0 then
        overview = tab:SubTab({ Name = opts.OverviewName or "Overview", Icon = opts.TabIcon or "layout-grid" })
    end
    overview._noSearch = true
    overview._order = 100
    local list = overview.List

    local refreshExpiry = self:_homeProfile(list, opts, 1)
    local refreshStats, resetStats = self:_homeStats(list, opts, 2, tab)

    -- Server and links side by side, stacked when narrow.
    local split = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Parent = list,
    })
    local splitLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = split,
    })
    local function column(order_)
        local frame = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = order_,
            Parent = split,
        })
        create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })
        return frame
    end
    local leftColumn, rightColumn = column(1), column(2)
    local refreshGame = self:_homeGame(leftColumn, 1)
    local linksCard, refreshFeatures = self:_homeLinks(rightColumn, opts, 1)
    if not linksCard then
        rightColumn:Destroy()
    end
    local function fitSplit()
        local wide = linksCard ~= nil and split.AbsoluteSize.X / self.Scale.Scale >= 540
        splitLayout.FillDirection = wide and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
        local size = wide and UDim2.new(0.5, -5, 0, 0) or UDim2.new(1, 0, 0, 0)
        leftColumn.Size = size
        if linksCard then
            rightColumn.Size = size
        end
    end
    split:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitSplit)
    task.defer(fitSplit)

    self:_homeExecutor(list, opts, 4)

    if type(pages) == "table" then
        for _, page in ipairs(pages) do
            homePage(tab:SubTab({ Name = page.Name or page.Title or "Page", Icon = page.Icon }), page)
        end
    end

    refreshExpiry()
    refreshStats()
    refreshGame()
    task.spawn(function()
        while not self._destroyed and tab._page.Parent do
            task.wait(1)
            if self.Open and self.CurrentTab == tab then
                refreshStats()
                refreshExpiry()
                refreshGame()
                refreshFeatures()
            else
                resetStats()
            end
        end
    end)
    return tab
end

function Window:Tab(opts, icon)
    opts = normalize(opts, { Title = "Name", Description = "Desc" })
    if icon ~= nil and opts.Icon == nil then
        opts.Icon = icon
    end
    local tab = setmetatable({
        Name = opts.Name or "Tab",
        Window = self,
        _order = 0,
    }, Tab)

    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, TAB_TILE_HEIGHT),
        BackgroundColor3 = Theme.Surface3,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = #self.Tabs + 1,
        Parent = self._tabStack,
    })
    corner(button, UDim.new(0, 7))
    local buttonStroke = stroke(button, Theme.Stroke, 1)
    buttonStroke.Enabled = false
    tab._button = button

    local hasIcon = opts.Icon ~= nil
    if hasIcon then
        local iconImage = create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 20, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            ImageColor3 = Theme.Muted,
            ScaleType = Enum.ScaleType.Fit,
            Parent = button,
        })
        applyIcon(iconImage, opts.Icon)
        if iconImage:GetAttribute("CustomIcon") then
            iconImage.ImageTransparency = 0.4
        end
        tab._icon = iconImage
    end
    tab._label = label({
        Position = UDim2.fromOffset(hasIcon and 38 or 14, 0),
        Size = UDim2.new(1, hasIcon and -46 or -22, 1, 0),
        Text = tab.Name,
        TextSize = 13,
        TextColor3 = Theme.Muted,
        Parent = button,
    })

    local page = create("Frame", {
        Name = tab.Name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.Content,
    })
    tab._page = page
    local titleX = 24
    if hasIcon then
        local holder = glowIcon(page, opts.Icon, Theme.Accent, UDim2.new(0, 24, 0, 32))
        holder.Size = UDim2.fromOffset(20, 20)
        titleX = 54
    end
    tab._titleX = titleX
    tab._title = label({
        Position = UDim2.fromOffset(titleX, 20),
        Size = UDim2.new(1, -titleX, 0, 24),
        Text = opts.PageTitle or tab.Name,
        TextSize = 22,
        Parent = page,
    })
    if opts.Desc then
        tab._desc = label({
            Position = UDim2.fromOffset(titleX, 44),
            Size = UDim2.new(1, -titleX, 0, 16),
            Text = opts.Desc,
            TextSize = 13,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            Parent = page,
        })
    end
    local listTop = opts.Desc and 70 or 58
    tab._headerBottom = listTop
    tab._iconName = opts.Icon
    buildContainer(tab, page, listTop, opts.Icon or "layout-grid", opts.EmptyText or "Nothing here yet")

    local pressScale = create("UIScale", { Parent = button })
    local function release()
        tween(pressScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Quint)
    end
    button.MouseEnter:Connect(function()
        if self.CurrentTab ~= tab and not usingTouch() then
            tween(button, { BackgroundTransparency = 0.75 }, 0.2, Enum.EasingStyle.Quint)
            tween(tab._label, { TextColor3 = Theme.Text }, 0.2)
            if tab._icon then
                tintIcon(tab._icon, Theme.Text, true, 0.2)
            end
        end
    end)
    button.MouseLeave:Connect(function()
        release()
        if self.CurrentTab ~= tab then
            tween(button, { BackgroundTransparency = 1 }, 0.3, Enum.EasingStyle.Quint)
            tween(tab._label, { TextColor3 = Theme.Muted }, 0.3)
            if tab._icon then
                tintIcon(tab._icon, Theme.Muted, false, 0.3)
            end
        end
    end)
    button.MouseButton1Down:Connect(function()
        tween(pressScale, { Scale = 0.97 }, 0.15, Enum.EasingStyle.Quint)
    end)
    button.MouseButton1Up:Connect(release)
    local isTap = tapGuard(button, function()
        return self.TabList
    end)
    button.MouseButton1Click:Connect(function()
        release()
        if isTap() then
            self:SelectTab(tab)
        end
    end)
    tab._stroke = buttonStroke
    self:_fitTitle(tab)

    if not self._introDone then
        button.Visible = false
    end
    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
        task.defer(function()
            if not self.CurrentTab then
                self:SelectTab(tab)
            end
        end)
    end
    return tab
end

Window.CreateTab = Window.Tab

-- Cloud configs: a tab for browsing, previewing, installing and publishing
-- configs other players shared. The library draws it; OnFetch, OnPublish and
-- the other callbacks are the script's backend. Favorites, installs and the
-- sort order are remembered in the script's settings file.
function Window:CloudConfigs(opts)
    opts = normalize(opts, { Title = "Name", Description = "Desc" })
    local window = self
    local tab = self:Tab({
        Name = opts.Name or "Cloud",
        Desc = opts.Desc,
        Icon = opts.Icon or "cloud",
        PageTitle = opts.PageTitle,
    })
    tab._noSearch = true
    tab.List.Visible = false
    if tab._empty then
        tab._empty:Destroy()
        tab._empty = nil
    end

    local CARD = 116
    local ROW = TOUCH and 36 or 32
    local CHIP = TOUCH and 30 or 26
    local SORTS = { "Popular", "New", "Top", "Installs" }
    local SORT_NAMES = { Popular = "Popular", New = "Newest", Top = "Top rated", Installs = "Most installed" }
    local FILTERS = { "All", "Favorites", "Mine", "Installed" }
    local NAME_LIMIT = 40
    local DESC_LIMIT = math.max(math.floor(tonumber(opts.DescriptionLimit) or 300), 20)
    local pageSize = math.max(math.floor(tonumber(opts.PageSize) or 20), 1)
    local tagList = type(opts.Tags) == "table" and opts.Tags or {}
    local maxTags = math.max(math.floor(tonumber(opts.MaxTags) or 3), 0)
    local anonName = tostring(opts.StreamerName or "Ouroboros User")

    local cloud = { Tab = tab }
    local records, byId = {}, {}
    local cards = {}
    local hasMore, page, token = false, 0, 0
    local loading = false
    local query = { Search = "", Sort = "Popular", Filter = "All", Tag = nil }
    local views, currentView = {}, nil
    local detail, detailRecord, detailToken = {}, nil, 0

    local stored = window:_readConfigSettings()
    local favorites = type(stored.CloudFavorites) == "table" and stored.CloudFavorites or {}
    local installed = type(stored.CloudInstalled) == "table" and stored.CloudInstalled or {}
    if table.find(SORTS, stored.CloudSort) then
        query.Sort = stored.CloudSort
    elseif table.find(SORTS, opts.Sort) then
        query.Sort = opts.Sort
    end
    local function persist(key, value)
        window:_writeConfigSettings({ [key] = value })
    end

    local function notify(ok, title, detail_)
        window:Notify({ Title = title, Content = detail_, Type = ok and "Success" or "Error", Duration = 3 })
    end

    -- The Home tab's hide-name switch doubles as streamer mode.
    local function streamerOn()
        return window._hideName == true
    end

    -- Records

    local function countFlags(code)
        local data = type(code) == "string" and window:DecodeConfig(code)
        if not data then
            return nil
        end
        local count = 0
        for _ in pairs(data) do
            count += 1
        end
        return count
    end

    local function compact(number)
        number = math.max(math.floor(tonumber(number) or 0), 0)
        if number >= 1e6 then
            return (("%.1f"):format(number / 1e6):gsub("%.0$", "")) .. "m"
        elseif number >= 1e3 then
            return (("%.1f"):format(number / 1e3):gsub("%.0$", "")) .. "k"
        end
        return tostring(number)
    end

    local function ago(stamp)
        stamp = tonumber(stamp)
        if not stamp then
            return nil
        end
        local delta = os.time() - stamp
        if delta < 60 then
            return "just now"
        elseif delta < 3600 then
            return math.floor(delta / 60) .. "m ago"
        elseif delta < 86400 then
            return math.floor(delta / 3600) .. "h ago"
        elseif delta < 604800 then
            return math.floor(delta / 86400) .. "d ago"
        elseif delta < 2592000 then
            return math.floor(delta / 604800) .. "w ago"
        end
        return os.date("%d %b %Y", stamp)
    end

    local function escape(text)
        return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;"))
    end

    -- Rich text with every match of the search drawn in the accent.
    local function highlight(text)
        local needle = string.lower(query.Search)
        if needle == "" then
            return escape(text)
        end
        local lower = string.lower(text)
        local hex = colorToHex(Theme.Accent)
        local out, from = {}, 1
        while true do
            local first, last = string.find(lower, needle, from, true)
            if not first then
                break
            end
            table.insert(out, escape(text:sub(from, first - 1)))
            table.insert(out, ('<font color="#%s"><b>%s</b></font>'):format(hex, escape(text:sub(first, last))))
            from = last + 1
        end
        table.insert(out, escape(text:sub(from)))
        return table.concat(out)
    end

    local function normalizeRecord(raw)
        if type(raw) ~= "table" then
            return nil
        end
        local id = raw.Id ~= nil and tostring(raw.Id) or HttpService:GenerateGUID(false)
        local record = byId[id] or { Id = id }
        for key, value in pairs(raw) do
            if key ~= "Id" then
                record[key] = value
            end
        end
        record.Name = tostring(record.Name or "Untitled")
        record.Author = tostring(record.Author or "Unknown")
        record.Description = record.Description ~= nil and tostring(record.Description) or ""
        local tags = {}
        for _, tag in ipairs(type(record.Tags) == "table" and record.Tags or {}) do
            table.insert(tags, tostring(tag))
        end
        record.Tags = tags
        record.Installs = tonumber(record.Installs) or 0
        record.Likes = tonumber(record.Likes) or 0
        record.Updated = tonumber(record.Updated or record.Created)
        record.Liked = record.Liked == true
        if type(record.Code) ~= "string" or record.Code == "" then
            record.Code = nil
        end
        record.Count = tonumber(record.Count) or countFlags(record.Code)
        record.Mine = record.Mine == true or tonumber(record.AuthorId) == LocalPlayer.UserId or tonumber(record.OwnerId) == LocalPlayer.UserId
        byId[id] = record
        return record
    end

    local function publicRecord(record)
        return {
            Id = record.Id,
            Name = record.Name,
            Description = record.Description,
            Author = record.Author,
            AuthorId = record.AuthorId,
            Tags = table.clone(record.Tags),
            Installs = record.Installs,
            Likes = record.Likes,
            Liked = record.Liked,
            Updated = record.Updated,
            Code = record.Code,
            Count = record.Count,
            Folder = record.Folder,
            Mine = record.Mine,
        }
    end

    -- What is kept locally for favorites and installs: no code, it is refetched.
    local function summary(record)
        local kept = publicRecord(record)
        kept.Code = nil
        kept.Liked = nil
        return kept
    end

    local function installState(record)
        local mark = installed[record.Id]
        if type(mark) ~= "table" then
            return nil
        end
        if record.Updated and tonumber(mark.Updated) and record.Updated > tonumber(mark.Updated) then
            return "Update"
        end
        return "Installed"
    end

    local function otherScript(record)
        return type(record.Folder) == "string" and record.Folder ~= window.ConfigFolder
    end

    -- Small pieces

    local function iconButton(parent, icon, glyph, size, plain)
        local button = create("TextButton", {
            Size = UDim2.fromOffset(size, size),
            BackgroundColor3 = Theme.Surface2,
            BackgroundTransparency = plain and 1 or 0,
            Text = "",
            AutoButtonColor = false,
            Parent = parent,
        })
        corner(button, UDim.new(0, 8))
        if not plain then
            hoverStroke(button, stroke(button))
        end
        local image = create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(15, 15),
            BackgroundTransparency = 1,
            ImageColor3 = Theme.Muted,
            ScaleType = Enum.ScaleType.Fit,
            Parent = button,
        })
        applyIcon(image, icon)
        if image.Image == "" then
            image:Destroy()
            image = label({
                Size = UDim2.fromScale(1, 1),
                Text = glyph,
                TextSize = 15,
                TextColor3 = Theme.Muted,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextTruncate = Enum.TextTruncate.None,
                Parent = button,
            })
        end
        return button, image
    end

    local function primary(button, text_)
        tween(button, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.12 }, 0)
        tween(text_, { TextColor3 = Theme.AccentDark }, 0)
        text_.FontFace = Fonts.Bold
    end

    local function clear(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
    end

    local function chip(parent, text, order, onClick)
        local button = create("TextButton", {
            Size = UDim2.fromOffset(0, CHIP),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme.Surface2,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = order,
            Parent = parent,
        })
        button:SetAttribute("NoDrag", true)
        corner(button, UDim.new(1, 0))
        local chipStroke = stroke(button)
        padding(button, 12, 12)
        local text_ = label({
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = text,
            TextSize = 12,
            TextColor3 = Theme.Muted,
            TextTruncate = Enum.TextTruncate.None,
            Parent = button,
        })
        local object = { Button = button, Label = text_ }
        function object.Set(on, instant)
            local duration = instant and 0 or 0.15
            tween(button, { BackgroundColor3 = on and Theme.Accent or Theme.Surface2 }, duration)
            tween(text_, { TextColor3 = on and Theme.AccentDark or Theme.Muted }, duration)
            tween(chipStroke, { Transparency = on and 1 or 0 }, duration)
        end
        if onClick then
            button.MouseButton1Click:Connect(onClick)
        else
            button.Active = false
        end
        return object
    end

    local function tagPill(parent, text, order)
        local pill = label({
            Size = UDim2.fromOffset(0, 18),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme.Surface3,
            BackgroundTransparency = 0.2,
            Text = text,
            TextSize = 11,
            TextColor3 = Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.None,
            LayoutOrder = order,
            Parent = parent,
        })
        corner(pill, UDim.new(0, 5))
        padding(pill, 7, 7)
        return pill
    end

    local function hlist(parent, gap, wraps)
        return create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, gap),
            Wraps = wraps == true,
            Parent = parent,
        })
    end

    local function vlist(parent, gap)
        return create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, gap),
            Parent = parent,
        })
    end

    local function wrapped(parent, text, size, color, order, font)
        return label({
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = text,
            TextSize = size,
            FontFace = font or Fonts.Regular,
            TextColor3 = color or Theme.Text,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            TextYAlignment = Enum.TextYAlignment.Top,
            LayoutOrder = order,
            Parent = parent,
        })
    end

    local function scroller(parent, visible)
        local frame = create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            ScrollBarImageTransparency = 0.4,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
            Visible = visible ~= false,
            Parent = parent,
        })
        frame:SetAttribute("NoDrag", true)
        return frame
    end

    -- A text box on the surface colour. Multi-line boxes show a counter.
    local function field(parent, order, placeholder, height, limit)
        local multi = height > ROW
        local holder = create("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            LayoutOrder = order,
            Parent = parent,
        })
        corner(holder, UDim.new(0, 8))
        local holderStroke = stroke(holder)
        local box = create("TextBox", {
            Position = UDim2.fromOffset(10, multi and 8 or 0),
            Size = UDim2.new(1, -20, 1, multi and -24 or 0),
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = placeholder,
            PlaceholderColor3 = Theme.Muted,
            TextColor3 = Theme.Text,
            TextSize = 13,
            FontFace = Fonts.Regular,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = multi and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
            MultiLine = multi,
            TextWrapped = multi,
            ClearTextOnFocus = false,
            Parent = holder,
        })
        local counter = multi and label({
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -10, 1, -4),
            Size = UDim2.fromOffset(0, 14),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = "",
            TextSize = 11,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            TextTruncate = Enum.TextTruncate.None,
            Parent = holder,
        })
        box.Focused:Connect(function()
            tween(holderStroke, { Color = Theme.StrokeHover }, 0.15)
        end)
        box.FocusLost:Connect(function()
            tween(holderStroke, { Color = Theme.Stroke }, 0.2)
        end)
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local text = box.Text
            local length = utf8.len(text) or #text
            if limit and length > limit then
                local cut = utf8.offset(text, limit + 1)
                box.Text = cut and text:sub(1, cut - 1) or text:sub(1, limit)
                return
            end
            if counter then
                counter.Text = limit and (length .. "/" .. limit) or ""
            end
        end)
        if counter and limit then
            counter.Text = "0/" .. limit
        end
        return box, holderStroke
    end

    local function uniqueName(base)
        base = trim((tostring(base or ""):gsub('[\\/:%*%?"<>|]', "")))
        if base == "" then
            base = "Cloud config"
        end
        local name, index = base, 2
        while window:ConfigExists(name) do
            name = ("%s (%d)"):format(base, index)
            index += 1
        end
        return name
    end

    -- Layout: the page holds three views that slide over each other.

    local top = tab._headerBottom
    -- One pixel wider than the content on every side: root clips the slide,
    -- and the strokes along its edges would be clipped with it.
    local root = create("Frame", {
        Position = UDim2.fromOffset(23, top - 1),
        Size = UDim2.new(1, -46, 1, -(top + 14)),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = tab._page,
    })
    for _, name in ipairs({ "Browse", "Detail", "Publish" }) do
        views[name] = create("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = root,
        })
        padding(views[name], 1, 1, 1, 1)
    end

    local function showView(view)
        if currentView == view then
            return
        end
        local previous = currentView
        currentView = view
        if previous then
            previous.Visible = false
        end
        local fromX = view == views.Browse and -24 or 24
        view.Position = UDim2.fromOffset(fromX, 0)
        view.Visible = true
        tween(view, { Position = UDim2.fromOffset(0, 0) }, 0.3, Enum.EasingStyle.Quint)
    end

    -- Browse: search, publish and refresh, the filter strip, then results.

    local browse = views.Browse
    local toolbar = create("Frame", {
        Size = UDim2.new(1, 0, 0, ROW),
        BackgroundTransparency = 1,
        Parent = browse,
    })
    local publishButton, publishText = softButton(toolbar, "Publish", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
    }, function()
        cloud:OpenPublish()
    end)
    primary(publishButton, publishText)
    publishButton.Visible = type(opts.OnPublish) == "function"
    local refreshButton, refreshIcon = iconButton(toolbar, "refresh-cw", "R", ROW)
    refreshButton.AnchorPoint = Vector2.new(1, 0)
    local searchHolder = create("Frame", {
        Size = UDim2.new(1, -(ROW + 8), 1, 0),
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        Parent = toolbar,
    })
    corner(searchHolder, UDim.new(0, 8))
    local searchStroke = stroke(searchHolder)
    local searchIcon, searchImage = glowIcon(searchHolder, "search", Theme.Muted, UDim2.new(0, 10, 0.5, 0))
    searchIcon.Size = UDim2.fromOffset(14, 14)
    local searchBox = create("TextBox", {
        Position = UDim2.fromOffset(32, 0),
        Size = UDim2.new(1, -62, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = opts.SearchPlaceholder or (TOUCH and "Search configs..." or "Search configs...   ( / )"),
        PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text,
        TextSize = 13,
        FontFace = Fonts.Regular,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        Parent = searchHolder,
    })
    local searchClear = iconButton(searchHolder, "x", "x", 24, true)
    searchClear.AnchorPoint = Vector2.new(1, 0.5)
    searchClear.Position = UDim2.new(1, -4, 0.5, 0)
    searchClear.Visible = false

    local fetch
    local searchToken = 0
    local recent = type(stored.CloudRecent) == "table" and stored.CloudRecent or {}
    local recentFrame = create("Frame", {
        Position = UDim2.fromOffset(0, ROW + 4),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 5,
        Parent = browse,
    })
    corner(recentFrame, UDim.new(0, 8))
    stroke(recentFrame)
    padding(recentFrame, 6, 6, 6, 6)
    vlist(recentFrame, 2)

    local function rememberSearch(text)
        text = trim(text)
        if #text < 2 then
            return
        end
        for index = #recent, 1, -1 do
            if string.lower(recent[index]) == string.lower(text) then
                table.remove(recent, index)
            end
        end
        table.insert(recent, 1, text)
        while #recent > 6 do
            table.remove(recent)
        end
        persist("CloudRecent", recent)
    end

    local function showRecent(show)
        show = show and #recent > 0 and searchBox.Text == ""
        if show == recentFrame.Visible then
            return
        end
        recentFrame.Visible = show
        if not show then
            return
        end
        clear(recentFrame)
        local header = create("Frame", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder = 0,
            Parent = recentFrame,
        })
        label({
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.new(1, -60, 1, 0),
            Text = "Recent searches",
            TextSize = 11,
            TextColor3 = Theme.Muted,
            Parent = header,
        })
        local wipe = create("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -6, 0, 0),
            Size = UDim2.fromOffset(0, 20),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = "Clear",
            TextSize = 11,
            FontFace = Fonts.Medium,
            TextColor3 = Theme.Accent,
            AutoButtonColor = false,
            Parent = header,
        })
        wipe.MouseButton1Down:Connect(function()
            recent = {}
            persist("CloudRecent", recent)
            showRecent(false)
        end)
        for index, text in ipairs(recent) do
            local row = create("TextButton", {
                Size = UDim2.new(1, 0, 0, TOUCH and 32 or 28),
                BackgroundColor3 = Theme.Surface3,
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = index,
                Parent = recentFrame,
            })
            corner(row, UDim.new(0, 6))
            local icon = glowIcon(row, "history", Theme.Muted, UDim2.new(0, 8, 0.5, 0))
            icon.Size = UDim2.fromOffset(13, 13)
            label({
                Position = UDim2.fromOffset(28, 0),
                Size = UDim2.new(1, -34, 1, 0),
                Text = text,
                TextSize = 13,
                FontFace = Fonts.Regular,
                Parent = row,
            })
            row.MouseEnter:Connect(function()
                tween(row, { BackgroundTransparency = 0.5 }, 0.1)
            end)
            row.MouseLeave:Connect(function()
                tween(row, { BackgroundTransparency = 1 }, 0.15)
            end)
            row.MouseButton1Down:Connect(function()
                searchToken += 1
                searchBox.Text = text
                query.Search = text
                rememberSearch(text)
                showRecent(false)
                searchBox:ReleaseFocus()
                fetch(false)
            end)
        end
    end

    local function fitToolbar()
        local scale = window.Scale.Scale
        local publishWidth = publishButton.Visible and (publishButton.AbsoluteSize.X / scale + 8) or 0
        refreshButton.Position = UDim2.new(1, -publishWidth, 0, 0)
        searchHolder.Size = UDim2.new(1, -(publishWidth + ROW + 8), 1, 0)
        recentFrame.Size = UDim2.new(1, -(publishWidth + ROW + 8), 0, 0)
    end
    publishButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitToolbar)
    task.defer(fitToolbar)

    -- A pixel taller than the chips on each side, so their strokes aren't clipped.
    local filterRow = create("Frame", {
        Position = UDim2.fromOffset(0, ROW + 7),
        Size = UDim2.new(1, 0, 0, CHIP + 2),
        BackgroundTransparency = 1,
        Parent = browse,
    })
    local sortButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -1, 0, 1),
        Size = UDim2.fromOffset(0, CHIP),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.Surface2,
        Text = "",
        AutoButtonColor = false,
        Parent = filterRow,
    })
    corner(sortButton, UDim.new(1, 0))
    hoverStroke(sortButton, stroke(sortButton))
    padding(sortButton, 10, 12)
    hlist(sortButton, 6)
    local sortIcon = glowIcon(sortButton, "arrow-down-up", Theme.Accent, UDim2.new())
    sortIcon.Size = UDim2.fromOffset(13, 13)
    local sortLabel = label({
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = SORT_NAMES[query.Sort],
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.None,
        LayoutOrder = 2,
        Parent = sortButton,
    })
    local filterStrip = create("ScrollingFrame", {
        Size = UDim2.new(1, -120, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        CanvasSize = UDim2.new(),
        Parent = filterRow,
    })
    filterStrip:SetAttribute("NoDrag", true)
    hlist(filterStrip, 6)
    padding(filterStrip, 1, 1, 1, 1)
    local function fitFilters()
        local width = sortButton.AbsoluteSize.X / window.Scale.Scale
        filterStrip.Size = UDim2.new(1, -(width + 8), 1, 0)
    end
    sortButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitFilters)
    task.defer(fitFilters)

    local resultsTop = ROW + 8 + CHIP + 10
    local results = scroller(browse)
    results.Position = UDim2.fromOffset(0, resultsTop)
    results.Size = UDim2.new(1, 0, 1, -resultsTop)
    padding(results, 1, 6, 1, 12)
    vlist(results, 10)
    local summaryRow = create("Frame", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
        Parent = results,
    })
    local summaryLabel = label({
        Size = UDim2.new(1, -100, 1, 0),
        Text = "",
        RichText = true,
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        Parent = summaryRow,
    })
    local resetButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = "Clear filters",
        TextSize = 12,
        FontFace = Fonts.Medium,
        TextColor3 = Theme.Accent,
        AutoButtonColor = false,
        Visible = false,
        Parent = summaryRow,
    })
    local resetFilters

    local function filtered()
        return query.Search ~= "" or query.Tag ~= nil or query.Filter ~= "All"
    end

    -- "12 configs in Favorites, tagged PvP, matching "boss"", or "Searching..."
    local function renderSummary(pending)
        local parts = {}
        if query.Filter ~= "All" then
            table.insert(parts, "in " .. query.Filter)
        end
        if query.Tag then
            table.insert(parts, "tagged " .. escape(query.Tag))
        end
        if query.Search ~= "" then
            table.insert(parts, ('matching <font color="#%s">"%s"</font>'):format(colorToHex(Theme.Accent), escape(query.Search)))
        end
        local context = #parts > 0 and (" " .. table.concat(parts, ", ")) or ""
        if pending or (loading and #records == 0) then
            summaryLabel.Text = "Searching" .. context .. "..."
        else
            local count = #records
            summaryLabel.Text = ("%d%s config%s%s"):format(count, hasMore and "+" or "", (count == 1 and not hasMore) and "" or "s", context)
        end
        resetButton.Visible = filtered()
    end

    local spin = nil
    local function busy(on)
        loading = on
        if on and not spin then
            refreshIcon.Rotation = 0
            spin = TweenService:Create(refreshIcon, TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
            spin:Play()
        elseif not on and spin then
            spin:Cancel()
            spin = nil
            tween(refreshIcon, { Rotation = 360 }, 0.35, Enum.EasingStyle.Quint)
        end
        renderSummary()
    end
    local grid = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = results,
    })
    local gridLayout = create("UIGridLayout", {
        CellSize = UDim2.new(1, 0, 0, CARD),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = grid,
    })
    local function fitGrid()
        local width = results.AbsoluteSize.X / window.Scale.Scale
        local columns = width >= 620 and 2 or 1
        gridLayout.CellSize = UDim2.new(1 / columns, -(columns - 1) * 8 / columns, 0, CARD)
    end
    results:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitGrid)
    task.defer(fitGrid)
    local moreButton = softButton(results, "Load more", {
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = 2,
        Visible = false,
    }, function()
        cloud:LoadMore()
    end)
    local stateFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 180),
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 3,
        Parent = results,
    })

    -- Loading placeholders that pulse where cards will land.
    local skeletons = {}
    local function addSkeletons(count)
        for _ = 1, count do
            local cell = create("Frame", {
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                LayoutOrder = 100000 + #skeletons,
                Parent = grid,
            })
            corner(cell, UDim.new(0, 10))
            stroke(cell)
            for index, spec in ipairs({ { 14, 0.45 }, { 36, 0.3 }, { 58, 0.8 }, { 76, 0.6 } }) do
                local bar = create("Frame", {
                    Position = UDim2.fromOffset(14, spec[1]),
                    Size = UDim2.new(spec[2], -14, 0, index == 1 and 14 or 10),
                    BackgroundColor3 = Theme.Surface3,
                    BorderSizePixel = 0,
                    Parent = cell,
                })
                corner(bar, UDim.new(0, 4))
                TweenService:Create(bar, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                    BackgroundTransparency = 0.65,
                }):Play()
            end
            table.insert(skeletons, cell)
        end
    end
    local function clearSkeletons()
        for _, cell in ipairs(skeletons) do
            cell:Destroy()
        end
        skeletons = {}
    end

    -- kind: nil hides it, or "empty" / "error" with a message.
    local function setState(kind, text)
        clear(stateFrame)
        stateFrame.Visible = kind ~= nil
        if not kind then
            return
        end
        local holder, caption = emptyState(stateFrame, kind == "error" and "cloud-off" or "search-x", text)
        holder.Size = UDim2.fromOffset(280, 70)
        holder.Position = UDim2.new(0.5, 0, 0, 60)
        caption.TextWrapped = true
        caption.TextTruncate = Enum.TextTruncate.None
        caption.Size = UDim2.new(1, 0, 0, 32)
        if kind == "error" or filtered() then
            softButton(stateFrame, kind == "error" and "Try again" or "Clear filters", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 132),
                Size = UDim2.fromOffset(0, 30),
                AutomaticSize = Enum.AutomaticSize.X,
            }, function()
                if kind == "error" then
                    cloud:Refresh()
                else
                    resetFilters()
                end
            end)
        end
        renderSummary()
    end

    -- Cards

    local openDetail, installRecord, refreshRecord

    local function renderCard(card)
        local record = card.Record
        card.Title.Text = highlight(record.Name)
        local meta = { "by " .. record.Author }
        local when = ago(record.Updated)
        if when then
            table.insert(meta, when)
        end
        if record.Count then
            table.insert(meta, record.Count .. (record.Count == 1 and " setting" or " settings"))
        end
        card.Meta.Text = table.concat(meta, "  ·  ")
        card.Desc.Text = record.Description ~= "" and highlight(record.Description) or "No description"
        card.Desc.TextTransparency = record.Description ~= "" and 0.2 or 0.55
        card.Likes.Text = compact(record.Likes)
        card.Installs.Text = compact(record.Installs)
        tween(card.Heart, { ImageColor3 = record.Liked and Theme.Accent or Theme.Muted }, 0.15)
        local state = installState(record)
        local badge, color
        if state == "Update" then
            badge, color = "UPDATE", Theme.Accent
        elseif state == "Installed" then
            badge, color = "INSTALLED", Theme.Success
        elseif record.Mine then
            badge, color = "YOURS", Theme.Accent
        elseif otherScript(record) then
            badge, color = "OTHER SCRIPT", Theme.Warning
        end
        card.Badge.Visible = badge ~= nil
        if badge then
            card.Badge.Text = badge
            tween(card.Badge, { TextColor3 = color, BackgroundColor3 = color }, 0)
        end
        card.Star.Visible = favorites[record.Id] ~= nil
        card.InstallText.Text = state == "Update" and "Update" or (state == "Installed" and "Reinstall" or "Install")
        clear(card.TagRow)
        for index, tag in ipairs(record.Tags) do
            if index > 3 then
                tagPill(card.TagRow, "+" .. (#record.Tags - 3), index)
                break
            end
            tagPill(card.TagRow, tag, index)
        end
    end

    local function buildCard(record, order)
        local frame = create("TextButton", {
            BackgroundColor3 = Theme.Surface2,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = order,
            Parent = grid,
        })
        frame:SetAttribute("NoDrag", true)
        corner(frame, UDim.new(0, 10))
        hoverStroke(frame, stroke(frame))
        padding(frame, 14, 14, 12, 12)
        local card = { Record = record, Frame = frame }
        card.Title = label({
            Size = UDim2.new(1, -110, 0, 18),
            RichText = true,
            TextSize = 14,
            FontFace = Fonts.Bold,
            Parent = frame,
        })
        local corner_ = create("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.fromScale(1, 0),
            Size = UDim2.fromOffset(0, 18),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Parent = frame,
        })
        local cornerLayout = hlist(corner_, 6)
        cornerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        card.Star = label({
            Size = UDim2.fromOffset(14, 18),
            Text = "★",
            TextSize = 13,
            TextColor3 = Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.None,
            LayoutOrder = 1,
            Parent = corner_,
        })
        card.Badge = label({
            Size = UDim2.fromOffset(0, 17),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 0.85,
            TextSize = 10,
            FontFace = Fonts.Bold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.None,
            LayoutOrder = 2,
            Parent = corner_,
        })
        corner(card.Badge, UDim.new(0, 5))
        padding(card.Badge, 6, 6)
        card.Meta = label({
            Position = UDim2.fromOffset(0, 20),
            Size = UDim2.new(1, 0, 0, 16),
            TextSize = 12,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            Parent = frame,
        })
        card.Desc = label({
            Position = UDim2.fromOffset(0, 41),
            RichText = true,
            Size = UDim2.new(1, 0, 0, 30),
            TextSize = 12,
            FontFace = Fonts.Regular,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = frame,
        })
        local bottom = create("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Parent = frame,
        })
        card.TagRow = create("Frame", {
            Size = UDim2.new(1, -190, 1, 0),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Parent = bottom,
        })
        hlist(card.TagRow, 4)
        local install, installText = softButton(bottom, "Install", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(76, 26),
        }, function()
            installRecord(record)
        end)
        primary(install, installText)
        card.InstallText = installText
        local stats = create("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -86, 0.5, 0),
            Size = UDim2.fromOffset(0, 20),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Parent = bottom,
        })
        hlist(stats, 4)
        local function stat(icon, order_)
            local holder, image = glowIcon(stats, icon, Theme.Muted, UDim2.new())
            holder.Size = UDim2.fromOffset(12, 12)
            holder.LayoutOrder = order_
            local text_ = label({
                Size = UDim2.fromOffset(0, 20),
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 12,
                TextColor3 = Theme.Muted,
                TextTruncate = Enum.TextTruncate.None,
                LayoutOrder = order_ + 1,
                Parent = stats,
            })
            return text_, image
        end
        card.Likes, card.Heart = stat("heart", 1)
        create("Frame", { Size = UDim2.fromOffset(4, 1), BackgroundTransparency = 1, LayoutOrder = 3, Parent = stats })
        card.Installs = stat("download", 4)
        local isTap = tapGuard(frame, function()
            return results
        end)
        frame.MouseButton1Click:Connect(function()
            if isTap() then
                if query.Search ~= "" then
                    rememberSearch(query.Search)
                end
                openDetail(record)
            end
        end)
        cards[record.Id] = card
        renderCard(card)
        return card
    end

    local function renderList()
        for _, card in pairs(cards) do
            card.Frame:Destroy()
        end
        cards = {}
        for index, record in ipairs(records) do
            buildCard(record, index)
        end
    end

    -- Favorites and Installed are kept on this device, so they filter locally.
    local function localRecords()
        local source = query.Filter == "Favorites" and favorites or installed
        local search = string.lower(query.Search)
        local list = {}
        for id, entry in pairs(source) do
            local kept = query.Filter == "Favorites" and entry or (type(entry) == "table" and entry.Record)
            if type(kept) == "table" then
                kept = table.clone(kept)
                kept.Id = id
                local record = normalizeRecord(kept)
                local matches = search == "" or string.find(string.lower(record.Name), search, 1, true)
                    or string.find(string.lower(record.Description), search, 1, true)
                if matches and query.Tag then
                    matches = table.find(record.Tags, query.Tag) ~= nil
                end
                if matches then
                    table.insert(list, record)
                end
            end
        end
        table.sort(list, function(a, b)
            if query.Sort == "New" then
                return (a.Updated or 0) > (b.Updated or 0)
            elseif query.Sort == "Installs" then
                return a.Installs > b.Installs
            end
            return a.Likes > b.Likes
        end)
        return list
    end

    local function emptyText()
        if query.Filter == "Favorites" then
            return "No favorites yet. Open a config and press Favorite to keep it here."
        elseif query.Filter == "Installed" then
            return "Nothing installed from the cloud yet"
        elseif query.Filter == "Mine" then
            return "You haven't published anything yet"
        elseif query.Search ~= "" or query.Tag then
            return "No configs match your search"
        end
        return tostring(opts.EmptyText or "No configs shared yet. Be the first!")
    end

    function fetch(more)
        token += 1
        local myToken = token
        if query.Filter == "Favorites" or query.Filter == "Installed" then
            busy(false)
            clearSkeletons()
            records = localRecords()
            hasMore = false
            renderList()
            moreButton.Visible = false
            setState(#records == 0 and "empty" or nil, emptyText())
            return
        end
        if type(opts.OnFetch) ~= "function" then
            renderList()
            setState(#records == 0 and "empty" or nil, emptyText())
            return
        end
        if more then
            if not hasMore then
                return
            end
            page += 1
        else
            page = 1
            records = {}
            renderList()
            results.CanvasPosition = Vector2.zero
        end
        busy(true)
        clearSkeletons()
        addSkeletons(more and 2 or 4)
        moreButton.Visible = false
        setState(nil)
        local fetchQuery = {
            Search = query.Search,
            Sort = query.Sort,
            Filter = query.Filter,
            Tag = query.Tag,
            Page = page,
            PageSize = pageSize,
            Folder = window.ConfigFolder,
            UserId = LocalPlayer.UserId,
        }
        task.spawn(function()
            local ok, list, extra = isolatedCall(function()
                return opts.OnFetch(fetchQuery)
            end)
            if myToken ~= token then
                return
            end
            busy(false)
            clearSkeletons()
            if not ok or type(list) ~= "table" then
                if more then
                    page -= 1
                end
                if not ok then
                    warn("[AirFlow] cloud OnFetch error: " .. tostring(list))
                end
                hasMore = more and hasMore or false
                moreButton.Visible = false
                setState("error", not ok and "Could not load configs" or tostring(extra or "Could not load configs"))
                return
            end
            hasMore = extra == true
            local seen = {}
            for _, record in ipairs(records) do
                seen[record] = true
            end
            for _, raw in ipairs(list) do
                local record = normalizeRecord(raw)
                if record and not seen[record] then
                    seen[record] = true
                    table.insert(records, record)
                    buildCard(record, #records)
                end
            end
            moreButton.Visible = hasMore
            setState(#records == 0 and "empty" or nil, emptyText())
        end)
    end

    -- Near the bottom, the next page loads by itself.
    results:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if not hasMore or loading then
            return
        end
        local scale = window.Scale.Scale
        local remaining = results.AbsoluteCanvasSize.Y / scale - results.AbsoluteWindowSize.Y / scale - results.CanvasPosition.Y
        if remaining < 160 then
            fetch(true)
        end
    end)

    -- Filters and sorting

    local filterChips, tagChips = {}, {}
    local function renderFilters(instant)
        for name, object in pairs(filterChips) do
            object.Set(query.Filter == name, instant)
        end
        for name, object in pairs(tagChips) do
            object.Set(query.Tag == name, instant)
        end
        sortLabel.Text = SORT_NAMES[query.Sort]
    end
    for index, name in ipairs(FILTERS) do
        if not (name == "Mine" and opts.MineFilter == false) then
            filterChips[name] = chip(filterStrip, name, index, function()
                if query.Filter ~= name then
                    query.Filter = name
                    renderFilters()
                    fetch(false)
                end
            end)
        end
    end
    if #tagList > 0 then
        create("Frame", {
            Size = UDim2.fromOffset(1, 16),
            BackgroundColor3 = Theme.Stroke,
            BorderSizePixel = 0,
            LayoutOrder = 10,
            Parent = filterStrip,
        })
    end
    for index, tag in ipairs(tagList) do
        tag = tostring(tag)
        tagChips[tag] = chip(filterStrip, tag, 10 + index, function()
            query.Tag = query.Tag ~= tag and tag or nil
            renderFilters()
            fetch(false)
        end)
    end
    sortButton.MouseButton1Click:Connect(function()
        local index = table.find(SORTS, query.Sort) or 1
        query.Sort = SORTS[index % #SORTS + 1]
        persist("CloudSort", query.Sort)
        renderFilters()
        fetch(false)
    end)

    function resetFilters()
        searchToken += 1
        searchBox.Text = ""
        query.Search, query.Tag, query.Filter = "", nil, "All"
        renderFilters()
        fetch(false)
    end
    resetButton.MouseButton1Click:Connect(resetFilters)

    -- Typing searches after a short pause; Enter searches now.
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchClear.Visible = searchBox.Text ~= ""
        showRecent(searchBox:IsFocused())
        searchToken += 1
        local mine = searchToken
        local text = trim(searchBox.Text)
        if text ~= query.Search then
            renderSummary(true)
        end
        task.delay(0.35, function()
            text = trim(searchBox.Text)
            if mine == searchToken and text ~= query.Search then
                query.Search = text
                fetch(false)
            end
        end)
    end)
    searchBox.Focused:Connect(function()
        tween(searchStroke, { Color = Theme.Accent }, 0.15)
        tween(searchImage, { ImageColor3 = Theme.Accent }, 0.15)
        showRecent(true)
    end)
    searchBox.FocusLost:Connect(function(enterPressed)
        tween(searchStroke, { Color = Theme.Stroke }, 0.2)
        tween(searchImage, { ImageColor3 = Theme.Muted }, 0.2)
        rememberSearch(searchBox.Text)
        -- Late enough for a press on a recent search to land first.
        task.delay(0.15, function()
            if not searchBox:IsFocused() then
                showRecent(false)
            end
        end)
        if enterPressed then
            searchToken += 1
            local text = trim(searchBox.Text)
            if text ~= query.Search then
                query.Search = text
                fetch(false)
            end
        end
    end)
    searchClear.MouseButton1Click:Connect(function()
        searchToken += 1
        searchBox.Text = ""
        if query.Search ~= "" then
            query.Search = ""
            fetch(false)
        end
    end)
    -- "/" jumps to the search box while the list is showing.
    window:_listen("Began", function(input, processed)
        if processed or input.KeyCode ~= Enum.KeyCode.Slash then
            return
        end
        if window.Open and window.CurrentTab == tab and currentView == views.Browse and not UserInputService:GetFocusedTextBox() then
            task.defer(function()
                searchBox:CaptureFocus()
                searchBox.Text = searchBox.Text:gsub("/$", "")
            end)
        end
    end, cloud)
    refreshButton.MouseButton1Click:Connect(function()
        cloud:Refresh()
    end)

    -- Actions on a record

    -- Runs callback with the record's code, asking the backend for it first
    -- when the list came without codes.
    local function withCode(record, callback, onFail)
        if record.Code then
            callback(record.Code)
            return
        end
        local function fail(reason)
            if onFail then
                onFail(reason)
            else
                notify(false, "Could not load config", reason)
            end
        end
        if type(opts.OnFetchCode) ~= "function" then
            fail("This config has no code")
            return
        end
        task.spawn(function()
            local ok, code, reason = isolatedCall(function()
                return opts.OnFetchCode(publicRecord(record))
            end)
            if ok and type(code) == "string" and code ~= "" then
                record.Code = code
                record.Count = record.Count or countFlags(code)
                callback(code)
            else
                fail(tostring(reason or (not ok and "the request failed") or "no code came back"))
            end
        end)
    end

    function installRecord(record)
        if record._busy then
            return
        end
        record._busy = true
        withCode(record, function(code)
            record._busy = nil
            local data, info = window:DecodeConfig(code)
            if not data then
                notify(false, "Install failed", "The config code is invalid")
                return
            end
            local count = 0
            for _ in pairs(data) do
                count += 1
            end
            local mark = installed[record.Id]
            local saveAs = nil
            if fileApiAvailable() then
                -- An update overwrites the config it installed last time.
                saveAs = type(mark) == "table" and type(mark.Name) == "string" and window:ConfigExists(mark.Name) and mark.Name
                    or uniqueName(record.Name)
            end
            local other = info.Folder and info.Folder ~= window.ConfigFolder
            local function apply(save)
                local name = save and saveAs or nil
                local ok, err = window:ImportConfig(code, name, true)
                if not ok then
                    notify(false, "Install failed", tostring(err))
                    return
                end
                installed[record.Id] = { Updated = record.Updated or os.time(), Name = name, At = os.time(), Record = summary(record) }
                persist("CloudInstalled", installed)
                record.Installs += 1
                refreshRecord(record)
                notify(true, "Config installed", name and ("Saved as " .. name) or "Applied to your current settings")
                if opts.OnInstall then
                    task.spawn(safeCall, opts.OnInstall, publicRecord(record), name)
                end
            end
            local content = ("%s by %s changes %d setting%s."):format(record.Name, record.Author, count, count == 1 and "" or "s")
            if other then
                content ..= (" It was made for %s, so only matching settings apply."):format(info.Folder)
            end
            if saveAs then
                content ..= (" Install also saves it as %s; Apply only doesn't."):format(saveAs)
            end
            local buttons = { { Title = "Cancel" } }
            table.insert(buttons, { Title = "Apply only", Variant = not saveAs and "Primary" or nil, Callback = function()
                apply(false)
            end })
            if saveAs then
                table.insert(buttons, { Title = "Install", Variant = "Primary", Callback = function()
                    apply(true)
                end })
            end
            window:Dialog({
                Title = installState(record) == "Update" and "Update config" or "Install config",
                Content = content,
                Icon = other and "triangle-alert" or "download",
                Buttons = buttons,
            })
        end, function(reason)
            record._busy = nil
            notify(false, "Could not load config", reason)
        end)
    end

    local function toggleLike(record)
        if type(opts.OnLike) ~= "function" or record._liking then
            return
        end
        local liked = not record.Liked
        record.Liked = liked
        record.Likes = math.max(record.Likes + (liked and 1 or -1), 0)
        record._liking = true
        refreshRecord(record)
        task.spawn(function()
            local ok, result, reason = isolatedCall(function()
                return opts.OnLike(publicRecord(record), liked)
            end)
            record._liking = nil
            if not ok or result == false then
                record.Liked = not liked
                record.Likes = math.max(record.Likes + (liked and -1 or 1), 0)
                refreshRecord(record)
                notify(false, "Like not saved", tostring(reason or "Try again in a moment"))
            end
        end)
    end

    local function toggleFavorite(record)
        local on = favorites[record.Id] == nil
        favorites[record.Id] = on and summary(record) or nil
        persist("CloudFavorites", favorites)
        refreshRecord(record)
        window:Notify({
            Title = on and "Added to favorites" or "Removed from favorites",
            Content = record.Name,
            Icon = "star",
            Duration = 2,
        })
    end

    local function removeRecord(record)
        local index = table.find(records, record)
        if index then
            table.remove(records, index)
        end
        byId[record.Id] = nil
        local card = cards[record.Id]
        if card then
            card.Frame:Destroy()
            cards[record.Id] = nil
        end
        if #records == 0 and not loading then
            setState("empty", emptyText())
        end
    end

    local function deleteRecord(record)
        window:Confirm({
            Title = "Delete config",
            Content = ("Remove %s from the cloud? People who installed it keep their copy."):format(record.Name),
            Icon = "trash-2",
            ConfirmText = "Delete",
            Callback = function()
                task.spawn(function()
                    local ok, result, reason = isolatedCall(function()
                        return opts.OnDelete(publicRecord(record))
                    end)
                    if not ok or result == false then
                        notify(false, "Delete failed", tostring(reason or "Try again in a moment"))
                        return
                    end
                    favorites[record.Id] = nil
                    persist("CloudFavorites", favorites)
                    removeRecord(record)
                    showView(views.Browse)
                    notify(true, "Config deleted", record.Name)
                end)
            end,
        })
    end

    local function reportRecord(record)
        local reasons = type(opts.ReportReasons) == "table" and opts.ReportReasons or { "Broken", "Spam", "Inappropriate" }
        local buttons = { { Title = "Cancel" } }
        for _, reason in ipairs(reasons) do
            table.insert(buttons, { Title = tostring(reason), Callback = function()
                task.spawn(function()
                    local ok, result = isolatedCall(function()
                        return opts.OnReport(publicRecord(record), tostring(reason))
                    end)
                    local sent = ok and result ~= false
                    notify(sent, sent and "Report sent" or "Report failed", sent and "Thanks for letting us know" or "Try again in a moment")
                end)
            end })
        end
        window:Dialog({
            Title = "Report config",
            Content = ("What's wrong with %s?"):format(record.Name),
            Icon = "flag",
            Buttons = buttons,
        })
    end

    -- Detail view

    local detailList = scroller(views.Detail)
    padding(detailList, 1, 8, 1, 16)
    vlist(detailList, 10)

    local function valueText(entry)
        local value = type(entry) == "table" and entry.Value or nil
        if value == nil then
            return "None"
        elseif type(value) == "boolean" then
            return value and "On" or "Off"
        elseif type(value) == "number" then
            return (("%.2f"):format(value):gsub("%.?0+$", ""))
        elseif type(value) == "table" then
            if type(value.Hex) == "string" then
                return "#" .. string.upper(value.Hex)
            elseif type(value.Colors) == "table" then
                local text = type(value.Name) == "string" and value.Name or "Custom"
                if type(value.Background) == "string" and value.Background ~= "" then
                    text ..= ", image"
                end
                return text
            end
            local parts = {}
            for index, item in ipairs(value) do
                parts[index] = tostring(item)
            end
            return #parts > 0 and table.concat(parts, ", ") or "None"
        end
        return tostring(value)
    end

    local function encoded(entry)
        local ok, text = pcall(HttpService.JSONEncode, HttpService, type(entry) == "table" and entry.Value or nil)
        return ok and text or tostring(entry)
    end

    local function renderDetail()
        local record = detailRecord
        if not record or not detail.Meta then
            return
        end
        detail.Title.Text = record.Name
        local meta = { "by " .. record.Author }
        local when = ago(record.Updated)
        if when then
            table.insert(meta, "updated " .. when)
        end
        if otherScript(record) then
            table.insert(meta, "made for " .. record.Folder)
        end
        detail.Meta.Text = table.concat(meta, "  ·  ")
        detail.Stats.Text = ("%s like%s  ·  %s install%s"):format(
            compact(record.Likes), record.Likes == 1 and "" or "s",
            compact(record.Installs), record.Installs == 1 and "" or "s")
        if detail.BuiltFor ~= record or detail.BuiltMine ~= record.Mine then
            detail.BuiltFor, detail.BuiltMine = record, record.Mine
            local row = detail.Actions
            clear(row)
            local order = 0
            local function action(text, style, callback)
                order += 1
                local button, text_ = softButton(row, text, {
                    Size = UDim2.new(0, 0, 0, 30),
                    AutomaticSize = Enum.AutomaticSize.X,
                    LayoutOrder = order,
                }, callback)
                text_.TextSize = 13
                if style == "Primary" then
                    primary(button, text_)
                elseif style == "Danger" then
                    tween(text_, { TextColor3 = Theme.Error }, 0)
                end
                return text_
            end
            detail.InstallLabel = action("Install", "Primary", function()
                installRecord(record)
            end)
            if type(opts.OnLike) == "function" then
                detail.LikeLabel = action("Like", nil, function()
                    toggleLike(record)
                end)
            end
            detail.FavoriteLabel = action("Favorite", nil, function()
                toggleFavorite(record)
            end)
            action("Copy code", nil, function()
                withCode(record, function(code)
                    window:CopyToClipboard(code, "Config code")
                end)
            end)
            if record.Mine then
                if type(opts.OnUpdate) == "function" then
                    action("Edit", nil, function()
                        cloud:OpenPublish(record)
                    end)
                end
                if type(opts.OnDelete) == "function" then
                    action("Delete", "Danger", function()
                        deleteRecord(record)
                    end)
                end
            elseif type(opts.OnReport) == "function" then
                action("Report", "Danger", function()
                    reportRecord(record)
                end)
            end
        end
        local state = installState(record)
        detail.InstallLabel.Text = state == "Update" and "Update" or (state == "Installed" and "Reinstall" or "Install")
        if detail.LikeLabel then
            detail.LikeLabel.Text = (record.Liked and "Liked" or "Like") .. "  ·  " .. compact(record.Likes)
        end
        detail.FavoriteLabel.Text = favorites[record.Id] and "Favorited" or "Favorite"
    end

    -- Every setting in the config next to the player's own: changed ones
    -- first, then the same ones, then flags this script doesn't have.
    local function fillPreview(record, myToken)
        local function mismatch(text)
            if detailToken == myToken then
                detail.Summary.Text = text
            end
        end
        withCode(record, function(code)
            if detailToken ~= myToken then
                return
            end
            local data = window:DecodeConfig(code)
            if not data then
                mismatch("The config code is invalid")
                return
            end
            local current = collectFlags(window)
            local rows = {}
            local changed = 0
            for flag, entry in pairs(data) do
                local element = Library.Flags[flag]
                local known = element ~= nil
                local differs = known and encoded(entry) ~= encoded(current[flag])
                if differs then
                    changed += 1
                end
                table.insert(rows, {
                    Name = element and element._searchName ~= "" and element._searchName or flag,
                    Value = valueText(entry),
                    Known = known,
                    Changed = differs,
                    Rank = differs and 0 or (known and 1 or 2),
                })
            end
            table.sort(rows, function(a, b)
                if a.Rank ~= b.Rank then
                    return a.Rank < b.Rank
                end
                return string.lower(a.Name) < string.lower(b.Name)
            end)
            record.Count = #rows
            detail.Summary.Text = changed == 0 and ("%d settings, all the same as yours"):format(#rows)
                or ("%d settings, %d different from yours"):format(#rows, changed)
            clear(detail.Rows)
            for index, item in ipairs(rows) do
                if index > 150 then
                    wrapped(detail.Rows, ("and %d more"):format(#rows - 150), 12, Theme.Muted, index)
                    break
                end
                local rowFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Theme.Surface2,
                    BackgroundTransparency = item.Changed and 0 or 0.5,
                    BorderSizePixel = 0,
                    LayoutOrder = index,
                    Parent = detail.Rows,
                })
                corner(rowFrame, UDim.new(0, 7))
                if item.Changed then
                    local dot = create("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.new(0, 10, 0.5, 0),
                        Size = UDim2.fromOffset(6, 6),
                        BackgroundColor3 = Theme.Accent,
                        BorderSizePixel = 0,
                        Parent = rowFrame,
                    })
                    corner(dot, UDim.new(1, 0))
                end
                label({
                    Position = UDim2.fromOffset(24, 0),
                    Size = UDim2.new(0.55, -24, 1, 0),
                    Text = item.Known and item.Name or (item.Name .. "  (not in this script)"),
                    TextSize = 12,
                    TextColor3 = item.Known and Theme.Text or Theme.Muted,
                    Parent = rowFrame,
                })
                label({
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -10, 0, 0),
                    Size = UDim2.new(0.45, -10, 1, 0),
                    Text = item.Value,
                    TextSize = 12,
                    FontFace = Fonts.Regular,
                    TextColor3 = item.Changed and Theme.Accent or Theme.Muted,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = rowFrame,
                })
            end
            if cards[record.Id] then
                renderCard(cards[record.Id])
            end
        end, mismatch)
    end

    function openDetail(record)
        detailRecord = record
        detailToken += 1
        local myToken = detailToken
        clear(detailList)
        detail = {}
        detailList.CanvasPosition = Vector2.zero
        softButton(detailList, "Back", {
            Size = UDim2.new(0, 0, 0, 28),
            AutomaticSize = Enum.AutomaticSize.X,
            LayoutOrder = 1,
        }, function()
            showView(views.Browse)
        end)
        detail.Title = wrapped(detailList, record.Name, 20, Theme.Text, 2, Fonts.Bold)
        detail.Meta = wrapped(detailList, "", 12, Theme.Muted, 3)
        if record.Description ~= "" then
            wrapped(detailList, record.Description, 13, Theme.Text, 4)
        end
        if #record.Tags > 0 then
            local tagsRow = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 5,
                Parent = detailList,
            })
            hlist(tagsRow, 4, true)
            for index, tag in ipairs(record.Tags) do
                tagPill(tagsRow, tag, index)
            end
        end
        detail.Stats = wrapped(detailList, "", 12, Theme.Muted, 6)
        detail.Actions = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 7,
            Parent = detailList,
        })
        hlist(detail.Actions, 6, true)
        create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Theme.Stroke,
            BorderSizePixel = 0,
            LayoutOrder = 8,
            Parent = detailList,
        })
        wrapped(detailList, "Settings", 14, Theme.Text, 9, Fonts.Bold)
        detail.Summary = wrapped(detailList, "Loading settings...", 12, Theme.Muted, 10)
        detail.Rows = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 11,
            Parent = detailList,
        })
        vlist(detail.Rows, 4)
        renderDetail()
        showView(views.Detail)
        fillPreview(record, myToken)
    end

    function refreshRecord(record)
        local card = cards[record.Id]
        if card then
            renderCard(card)
        end
        if detailRecord == record and currentView == views.Detail then
            renderDetail()
        end
    end

    -- Publish view: also the edit form for the player's own configs.

    local form = { Mode = "Publish", Record = nil, Source = false, Tags = {}, Busy = false }
    local publishList = scroller(views.Publish)
    padding(publishList, 1, 8, 1, 16)
    vlist(publishList, 8)
    softButton(publishList, "Back", {
        Size = UDim2.new(0, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = 1,
    }, function()
        showView(form.Mode == "Edit" and form.Record and views.Detail or views.Browse)
    end)
    local formTitle = wrapped(publishList, "Publish a config", 20, Theme.Text, 2, Fonts.Bold)
    wrapped(publishList, "Name", 12, Theme.Muted, 3)
    local nameBox = field(publishList, 4, "What is it for?", ROW, NAME_LIMIT)
    wrapped(publishList, "Description", 12, Theme.Muted, 5)
    local descBox = field(publishList, 6, "What does it do, and how should people use it?", 90, DESC_LIMIT)
    local tagsTitle = wrapped(publishList, "Tags", 12, Theme.Muted, 7)
    local tagsRow = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 8,
        Parent = publishList,
    })
    hlist(tagsRow, 6, true)
    tagsTitle.Visible = #tagList > 0 and maxTags > 0
    tagsRow.Visible = tagsTitle.Visible
    wrapped(publishList, "Settings to share", 12, Theme.Muted, 9)
    local sourceRow = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 10,
        Parent = publishList,
    })
    hlist(sourceRow, 6, true)
    local sourceSummary = wrapped(publishList, "", 12, Theme.Muted, 11)
    local identityNote = wrapped(publishList, "", 12, Theme.Muted, 12)
    local formError = wrapped(publishList, "", 12, Theme.Error, 13)
    formError.Visible = false
    local submitRow = create("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        LayoutOrder = 14,
        Parent = publishList,
    })
    hlist(submitRow, 6)
    local submitButton, submitText = softButton(submitRow, "Publish", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = 1,
    }, function()
        cloud:_submit()
    end)
    primary(submitButton, submitText)
    softButton(submitRow, "Cancel", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = 2,
    }, function()
        showView(form.Mode == "Edit" and form.Record and views.Detail or views.Browse)
    end)

    local formTagChips = {}
    local function renderFormTags()
        for tag, object in pairs(formTagChips) do
            object.Set(table.find(form.Tags, tag) ~= nil)
        end
        tagsTitle.Text = maxTags > 0 and ("Tags  (%d/%d)"):format(#form.Tags, maxTags) or "Tags"
    end
    for index, tag in ipairs(tagList) do
        tag = tostring(tag)
        formTagChips[tag] = chip(tagsRow, tag, index, function()
            local at = table.find(form.Tags, tag)
            if at then
                table.remove(form.Tags, at)
            elseif #form.Tags < maxTags then
                table.insert(form.Tags, tag)
            else
                notify(false, "Too many tags", ("Pick up to %d"):format(maxTags))
            end
            renderFormTags()
        end)
    end

    -- The code and setting count for the picked source, or nil and why not.
    local function sourceCode(name)
        if form.Source == "Keep" then
            return nil, form.Record and form.Record.Count
        elseif form.Source then
            local code, err = window:ExportConfig(form.Source)
            if not code then
                return nil, nil, err
            end
            return code, countFlags(code)
        end
        local ok, code = pcall(encodeConfig, window, name ~= "" and name or "Cloud config", collectFlags(window))
        if not ok then
            return nil, nil, "could not encode your settings"
        end
        return code, countFlags(code)
    end

    local sourceChips = {}
    local function renderSource()
        for key, object in pairs(sourceChips) do
            object.Set(key == (form.Source or "*current"))
        end
        local _, count, err = sourceCode(trim(nameBox.Text))
        if err then
            sourceSummary.Text = tostring(err)
        elseif form.Source == "Keep" then
            sourceSummary.Text = "Keeps the settings already published" .. (count and (" (" .. count .. ")") or "")
        else
            sourceSummary.Text = ("%d setting%s from %s"):format(count or 0, count == 1 and "" or "s", form.Source or "your current settings")
        end
    end

    local function buildSources()
        clear(sourceRow)
        sourceChips = {}
        local order = 0
        local function add(key, text)
            order += 1
            sourceChips[key] = chip(sourceRow, text, order, function()
                form.Source = key ~= "*current" and key or false
                renderSource()
            end)
        end
        if form.Mode == "Edit" then
            add("Keep", "Keep published settings")
        end
        add("*current", "Current settings")
        for _, name in ipairs(window:ListConfigs()) do
            add(name, name)
        end
        renderSource()
    end

    local function showError(text)
        formError.Text = tostring(text)
        formError.Visible = true
    end

    function cloud:OpenPublish(record)
        local editing = type(record) == "table" and record.Id and byId[record.Id] or nil
        if editing then
            form.Mode, form.Record = "Edit", editing
            form.Source = "Keep"
            form.Tags = table.clone(editing.Tags)
            nameBox.Text = editing.Name
            descBox.Text = editing.Description
        elseif form.Mode == "Edit" then
            -- Leaving an edit starts a fresh draft; a publish draft is kept.
            form.Mode, form.Record, form.Source, form.Tags = "Publish", nil, false, {}
            nameBox.Text = ""
            descBox.Text = ""
        end
        formTitle.Text = editing and "Edit config" or "Publish a config"
        submitText.Text = editing and "Save changes" or "Publish"
        formError.Visible = false
        local streamer = streamerOn()
        identityNote.Text = streamer and ("Your name is hidden, so you publish as " .. anonName)
            or ("You publish as " .. LocalPlayer.DisplayName)
        renderFormTags()
        buildSources()
        publishList.CanvasPosition = Vector2.zero
        showView(views.Publish)
    end

    nameBox:GetPropertyChangedSignal("Text"):Connect(function()
        formError.Visible = false
    end)

    function cloud:_submit()
        if form.Busy then
            return
        end
        local name = trim(nameBox.Text)
        if name == "" then
            showError("Give your config a name")
            return
        end
        local code, count, err = sourceCode(name)
        if err then
            showError(err)
            return
        end
        if form.Source ~= "Keep" and (count or 0) == 0 then
            showError("There are no settings to share")
            return
        end
        local editing = form.Mode == "Edit" and form.Record or nil
        local callback = editing and opts.OnUpdate or opts.OnPublish
        if type(callback) ~= "function" then
            showError(editing and "Editing isn't available" or "Publishing isn't available")
            return
        end
        local streamer = streamerOn()
        local payload = {
            Name = name,
            Description = trim(descBox.Text),
            Tags = table.clone(form.Tags),
            Code = code,
            Count = count,
            Folder = window.ConfigFolder,
            Author = streamer and anonName or LocalPlayer.DisplayName,
            AuthorId = not streamer and LocalPlayer.UserId or nil,
            OwnerId = LocalPlayer.UserId,
            Streamer = streamer,
        }
        form.Busy = true
        submitText.Text = editing and "Saving..." or "Publishing..."
        formError.Visible = false
        task.spawn(function()
            local ok, result, reason = isolatedCall(function()
                if editing then
                    return callback(publicRecord(editing), payload)
                end
                return callback(payload)
            end)
            form.Busy = false
            submitText.Text = editing and "Save changes" or "Publish"
            if not ok or result == false then
                if not ok then
                    warn("[AirFlow] cloud publish error: " .. tostring(result))
                end
                showError(ok and reason and tostring(reason) or "Something went wrong, try again")
                return
            end
            local merged = table.clone(payload)
            merged.Code = code or (editing and editing.Code)
            merged.Updated = os.time()
            if type(result) == "table" then
                for key, value in pairs(result) do
                    merged[key] = value
                end
            end
            if editing then
                merged.Id = editing.Id
                normalizeRecord(merged)
                if favorites[editing.Id] then
                    favorites[editing.Id] = summary(editing)
                    persist("CloudFavorites", favorites)
                end
                refreshRecord(editing)
                notify(true, "Config updated", name)
                openDetail(editing)
            else
                nameBox.Text = ""
                descBox.Text = ""
                form.Tags = {}
                form.Source = false
                if type(result) == "table" then
                    merged.Mine = true
                    local record = normalizeRecord(merged)
                    if query.Filter == "All" or query.Filter == "Mine" then
                        table.insert(records, 1, record)
                        renderList()
                        setState(nil)
                    end
                    notify(true, "Config published", name)
                    openDetail(record)
                else
                    notify(true, "Config published", name)
                    showView(views.Browse)
                    fetch(false)
                end
            end
        end)
    end

    -- Handle

    function cloud:Refresh()
        fetch(false)
    end

    function cloud:LoadMore()
        if not loading then
            fetch(true)
        end
    end

    -- For backends that push results instead of answering OnFetch.
    function cloud:SetConfigs(list, more)
        token += 1
        busy(false)
        clearSkeletons()
        records = {}
        for _, raw in ipairs(type(list) == "table" and list or {}) do
            local record = normalizeRecord(raw)
            if record then
                table.insert(records, record)
            end
        end
        hasMore = more == true
        renderList()
        moreButton.Visible = hasMore
        setState(#records == 0 and "empty" or nil, emptyText())
    end

    function cloud:AddConfigs(list, more)
        token += 1
        busy(false)
        clearSkeletons()
        for _, raw in ipairs(type(list) == "table" and list or {}) do
            local record = normalizeRecord(raw)
            if record and not table.find(records, record) then
                table.insert(records, record)
                buildCard(record, #records)
            end
        end
        hasMore = more == true
        moreButton.Visible = hasMore
        setState(#records == 0 and "empty" or nil, emptyText())
    end

    function cloud:UpdateConfig(id, changes)
        local record = byId[tostring(id)]
        if record and type(changes) == "table" then
            local merged = table.clone(changes)
            merged.Id = record.Id
            normalizeRecord(merged)
            refreshRecord(record)
        end
    end

    function cloud:RemoveConfig(id)
        local record = byId[tostring(id)]
        if record then
            removeRecord(record)
            if detailRecord == record and currentView == views.Detail then
                showView(views.Browse)
            end
        end
    end

    function cloud:SetLoading(on)
        token += 1
        busy(on == true)
        clearSkeletons()
        if loading then
            addSkeletons(4)
            setState(nil)
        end
    end

    function cloud:SetError(text)
        token += 1
        busy(false)
        clearSkeletons()
        setState(text and "error" or nil, tostring(text or ""))
    end

    function cloud:Open(id)
        local record = byId[tostring(id)]
        if record then
            window:SelectTab(tab)
            openDetail(record)
        end
    end

    function cloud:Back()
        showView(views.Browse)
    end

    function cloud:GetQuery()
        return table.clone(query)
    end

    function cloud:GetFavorites()
        local list = {}
        for id, kept in pairs(favorites) do
            local copy = table.clone(kept)
            copy.Id = id
            table.insert(list, copy)
        end
        return list
    end

    function cloud:GetInstalled()
        local list = {}
        for id, mark in pairs(installed) do
            table.insert(list, { Id = id, Name = mark.Name, Updated = mark.Updated, Record = mark.Record })
        end
        return list
    end

    renderFilters(true)
    showView(views.Browse)
    -- The first fetch waits until the tab is opened, so a hidden tab costs nothing.
    local fetched = false
    local function firstFetch()
        if not fetched and tab._page.Visible then
            fetched = true
            fetch(false)
        end
    end
    tab._page:GetPropertyChangedSignal("Visible"):Connect(firstFetch)
    if type(opts.OnFetch) ~= "function" then
        fetched = true
        setState("empty", emptyText())
    else
        task.defer(firstFetch)
    end
    return cloud
end

Window.CreateCloudConfigs = Window.CloudConfigs
Window.CloudConfig = Window.CloudConfigs
Window.CreateCloudConfig = Window.CloudConfigs

-- Tab badges were removed. These stay as no-ops so older scripts that call
-- them keep running.
function Tab:SetBadge() end

function Tab:GetBadge()
    return nil
end

function Window:Dialog(opts)
    opts = normalize(opts, { Text = "Content", Message = "Content" })
    if self._dialog then
        self._dialog.Close()
    end
    local WIDTH = 300
    local PAD = 18

    local overlay = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 40,
        Parent = self.Body,
    })
    local card = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 10),
        Size = UDim2.fromOffset(WIDTH, 120),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 41,
        Parent = overlay,
    })
    corner(card, UDim.new(0, 10))
    local cardStroke = stroke(card, Theme.Stroke, 1)
    local cardScale = create("UIScale", { Scale = 0.94, Parent = card })
    local fading = {}

    local titleOffset = 0
    if opts.Icon then
        local holder, image = glowIcon(card, opts.Icon, Theme.Accent, UDim2.new(0, PAD, 0, PAD + 9))
        image.ImageTransparency = 1
        holder.ZIndex = 42
        image.ZIndex = 42
        table.insert(fading, { image, "ImageTransparency", 0 })
        titleOffset = 24
    end
    local title = label({
        Position = UDim2.fromOffset(PAD + titleOffset, PAD),
        Size = UDim2.new(1, -(PAD * 2 + titleOffset), 0, 18),
        Text = opts.Title or "Are you sure?",
        TextSize = 15,
        TextTransparency = 1,
        ZIndex = 42,
        Parent = card,
    })
    table.insert(fading, { title, "TextTransparency", 0 })

    local contentHeight = 0
    if opts.Content then
        local content = label({
            Position = UDim2.fromOffset(PAD, PAD + 24),
            Size = UDim2.new(1, -PAD * 2, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = opts.Content,
            TextSize = 13,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            TextWrapped = true,
            TextTransparency = 1,
            TextTruncate = Enum.TextTruncate.None,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 42,
            Parent = card,
        })
        table.insert(fading, { content, "TextTransparency", 0 })
        contentHeight = math.max(content.TextBounds.Y, 16) + 6
        content:GetPropertyChangedSignal("TextBounds"):Connect(function()
            local newHeight = math.max(content.TextBounds.Y, 16) + 6
            if newHeight ~= contentHeight then
                contentHeight = newHeight
                card.Size = UDim2.fromOffset(WIDTH, PAD + 24 + contentHeight + 12 + 34 + PAD)
                local rowFrame = card:FindFirstChild("ButtonRow")
                if rowFrame then
                    rowFrame.Position = UDim2.fromOffset(PAD, PAD + 24 + contentHeight + 12)
                end
            end
        end)
    end

    local row = create("Frame", {
        Name = "ButtonRow",
        Position = UDim2.fromOffset(PAD, PAD + 24 + contentHeight + 12),
        Size = UDim2.new(1, -PAD * 2, 0, 34),
        BackgroundTransparency = 1,
        ZIndex = 42,
        Parent = card,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = row,
    })
    card.Size = UDim2.fromOffset(WIDTH, PAD + 24 + contentHeight + 12 + 34 + PAD)

    local dialog = {}
    local closed = false
    function dialog.Close()
        if closed then
            return
        end
        closed = true
        if self._dialog == dialog then
            self._dialog = nil
        end
        tween(overlay, { BackgroundTransparency = 1 }, 0.18)
        tween(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 8) }, 0.18, Enum.EasingStyle.Quint)
        tween(cardScale, { Scale = 0.96 }, 0.18, Enum.EasingStyle.Quint)
        tween(cardStroke, { Transparency = 1 }, 0.12)
        for _, entry in ipairs(fading) do
            tween(entry[1], { [entry[2]] = 1 }, 0.12)
        end
        task.delay(0.2, function()
            overlay:Destroy()
        end)
    end

    for index, spec in ipairs(opts.Buttons or {}) do
        local primary = spec.Variant == "Primary"
        local buttonFrame = create("TextButton", {
            Size = UDim2.fromOffset(0, 34),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = primary and Theme.Accent or Theme.Surface2,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ClipsDescendants = true,
            LayoutOrder = index,
            ZIndex = 43,
            Parent = row,
        })
        corner(buttonFrame, UDim.new(0, 7))
        local buttonStroke = stroke(buttonFrame, primary and Theme.Accent or Theme.Stroke, 1)
        padding(buttonFrame, 14, 14)
        local text = label({
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = spec.Title or spec.Name or "OK",
            TextSize = 13,
            TextColor3 = primary and Theme.AccentDark or Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTransparency = 1,
            ZIndex = 44,
            Parent = buttonFrame,
        })
        local restBg = primary and 0.12 or 0
        local restStroke = primary and 0.4 or 0
        table.insert(fading, { buttonFrame, "BackgroundTransparency", restBg })
        table.insert(fading, { buttonStroke, "Transparency", restStroke })
        table.insert(fading, { text, "TextTransparency", 0 })
        buttonFrame.MouseEnter:Connect(function()
            if closed then
                return
            end
            if primary then
                tween(buttonFrame, { BackgroundTransparency = 0 }, 0.12)
                tween(buttonStroke, { Transparency = 0 }, 0.12)
            else
                tween(buttonStroke, { Color = Theme.StrokeHover }, 0.12)
            end
        end)
        buttonFrame.MouseLeave:Connect(function()
            if closed then
                return
            end
            if primary then
                tween(buttonFrame, { BackgroundTransparency = restBg }, 0.2)
                tween(buttonStroke, { Transparency = restStroke }, 0.2)
            else
                tween(buttonStroke, { Color = Theme.Stroke }, 0.2)
            end
        end)
        buttonFrame.MouseButton1Click:Connect(function()
            dialog.Close()
            safeCall(spec.Callback)
        end)
    end

    if opts.CloseOnBackdrop ~= false then
        overlay.MouseButton1Click:Connect(function()
            dialog.Close()
            safeCall(opts.OnCancel)
        end)
    end

    self._dialog = dialog
    tween(overlay, { BackgroundTransparency = 0.45 }, 0.25)
    tween(card, { BackgroundTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) }, 0.3, Enum.EasingStyle.Quint)
    tween(cardStroke, { Transparency = 0 }, 0.25)
    tween(cardScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
    for _, entry in ipairs(fading) do
        tween(entry[1], { [entry[2]] = entry[3] }, 0.25)
    end
    return dialog
end

function Window:Confirm(opts)
    opts = normalize(opts, { Text = "Content", Message = "Content" })
    return self:Dialog({
        Title = opts.Title or "Are you sure?",
        Content = opts.Content,
        Icon = opts.Icon,
        OnCancel = opts.OnCancel,
        Buttons = {
            { Title = opts.CancelText or "Cancel", Callback = opts.OnCancel },
            { Title = opts.ConfirmText or "Confirm", Variant = "Primary", Callback = opts.Callback },
        },
    })
end

function Window:_listen(kind, handler, owner)
    local list = self._inputListeners[kind]
    table.insert(list, handler)
    local function disconnect()
        for index, entry in ipairs(list) do
            if entry == handler then
                table.remove(list, index)
                break
            end
        end
    end
    if owner then
        owner._listeners = owner._listeners or {}
        table.insert(owner._listeners, disconnect)
    end
    return disconnect
end

function Window:_indicatorY(tab)
    local stack = self._tabStack
    return (tab._button.AbsolutePosition.Y - stack.AbsolutePosition.Y) / self.Scale.Scale + stack.Position.Y.Offset
end

function Window:_placeIndicator(tab)
    local indicator = self.Indicator
    local targetY = self:_indicatorY(tab)
    if not indicator.Visible then
        indicator.Visible = true
        indicator.Position = UDim2.fromOffset(8, targetY)
        indicator.BackgroundTransparency = 1
        tween(indicator, { BackgroundTransparency = 0.35 }, 0.3)
    end
    tween(indicator, { Position = UDim2.fromOffset(8, targetY) }, 0.45, Enum.EasingStyle.Quint)
end

-- While a tab list or sub tab strip runs past an end, that end gets a fade
-- and a small chip with a chevron and how many tabs are out of sight there.
-- Pressing the chip scrolls most of a view toward them.
function Window:_overflowHint(host, scroller, items, vertical, fadeColor)
    local overlay = create("Frame", {
        AnchorPoint = scroller.AnchorPoint,
        Position = scroller.Position,
        Size = scroller.Size,
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = host,
    })
    local function mirror()
        overlay.Position = scroller.Position
        overlay.Size = scroller.Size
        overlay.Visible = scroller.Visible
    end
    for _, property in ipairs({ "Position", "Size", "Visible" }) do
        scroller:GetPropertyChangedSignal(property):Connect(mirror)
    end

    local function axis(vector)
        return vertical and vector.Y or vector.X
    end
    local function scale()
        return self.Scale and self.Scale.Scale or 1
    end
    local function scrollBy(direction)
        local view = axis(scroller.AbsoluteWindowSize) / scale()
        local limit = math.max(axis(scroller.AbsoluteCanvasSize) / scale() - view, 0)
        local target = math.clamp(axis(scroller.CanvasPosition) + direction * view * 0.75, 0, limit)
        tween(scroller, { CanvasPosition = vertical and Vector2.new(0, target) or Vector2.new(target, 0) }, 0.35, Enum.EasingStyle.Quint)
    end

    local hints = {}
    for _, direction in ipairs({ -1, 1 }) do
        local far = direction > 0
        local fade = create("Frame", {
            AnchorPoint = vertical and Vector2.new(0, far and 1 or 0) or Vector2.new(far and 1 or 0, 0),
            Position = vertical and UDim2.fromScale(0, far and 1 or 0) or UDim2.fromScale(far and 1 or 0, 0),
            Size = vertical and UDim2.new(1, 0, 0, 34) or UDim2.new(0, 48, 1, 0),
            BackgroundColor3 = fadeColor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            Parent = overlay,
        })
        create("UIGradient", {
            Rotation = vertical and (far and 270 or 90) or (far and 180 or 0),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.4, 0.2),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = fade,
        })
        local home = vertical and UDim2.new(0.5, 0, far and 1 or 0, far and -5 or 5) or UDim2.new(far and 1 or 0, far and -2 or 2, 0.5, 0)
        local chip = create("TextButton", {
            AnchorPoint = vertical and Vector2.new(0.5, far and 1 or 0) or Vector2.new(far and 1 or 0, 0.5),
            Position = home,
            Size = UDim2.fromOffset(0, 20),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme.Surface3,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Visible = false,
            ZIndex = 2,
            Parent = overlay,
        })
        corner(chip, UDim.new(1, 0))
        local chipStroke = stroke(chip, Theme.Stroke, 1)
        padding(chip, 7, 7)
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 3),
            Parent = chip,
        })
        local arrow = create("ImageLabel", {
            Size = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1,
            ImageColor3 = Theme.Accent,
            ImageTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
            LayoutOrder = 1,
            ZIndex = 2,
            Parent = chip,
        })
        applyIcon(arrow, vertical and (far and "chevron-down" or "chevron-up") or (far and "chevron-right" or "chevron-left"))
        local arrowFade = "ImageTransparency"
        if arrow.Image == "" then
            arrow:Destroy()
            arrow = label({
                Size = UDim2.fromOffset(10, 20),
                Text = "›",
                TextSize = 16,
                TextColor3 = Theme.Accent,
                TextTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextTruncate = Enum.TextTruncate.None,
                Rotation = vertical and (far and 90 or -90) or (far and 0 or 180),
                LayoutOrder = 1,
                ZIndex = 2,
                Parent = chip,
            })
            arrowFade = "TextTransparency"
        end
        local count = label({
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = "",
            TextSize = 11,
            TextColor3 = Theme.Text,
            TextTransparency = 1,
            TextTruncate = Enum.TextTruncate.None,
            Visible = false,
            LayoutOrder = 2,
            ZIndex = 2,
            Parent = chip,
        })
        chip.MouseEnter:Connect(function()
            if not usingTouch() then
                tween(chipStroke, { Color = Theme.StrokeHover }, 0.12)
            end
        end)
        chip.MouseLeave:Connect(function()
            tween(chipStroke, { Color = Theme.Stroke }, 0.2)
        end)
        chip.MouseButton1Click:Connect(function()
            scrollBy(direction)
        end)
        hints[direction] = {
            Direction = direction,
            Fade = fade,
            Chip = chip,
            Stroke = chipStroke,
            Arrow = arrow,
            ArrowFade = arrowFade,
            Count = count,
            Home = home,
            Shown = false,
            Generation = 0,
        }
    end

    local function show(hint, on)
        if hint.Shown == on then
            return
        end
        hint.Shown = on
        hint.Generation += 1
        local away = hint.Home + (vertical and UDim2.fromOffset(0, hint.Direction * 6) or UDim2.fromOffset(hint.Direction * 6, 0))
        local value = on and 0 or 1
        if on then
            hint.Fade.Visible = true
            hint.Chip.Visible = true
            hint.Chip.Position = away
            tween(hint.Chip, { Position = hint.Home, BackgroundTransparency = 0.08 }, 0.3, Enum.EasingStyle.Quint)
        else
            tween(hint.Chip, { Position = away, BackgroundTransparency = 1 }, 0.2, Enum.EasingStyle.Quint)
            local generation = hint.Generation
            task.delay(0.21, function()
                if hint.Generation == generation then
                    hint.Fade.Visible = false
                    hint.Chip.Visible = false
                end
            end)
        end
        tween(hint.Fade, { BackgroundTransparency = value }, 0.2)
        tween(hint.Stroke, { Transparency = value }, 0.2)
        tween(hint.Arrow, { [hint.ArrowFade] = value }, 0.2)
        tween(hint.Count, { TextTransparency = value }, 0.2)
    end

    local function refresh()
        local view = axis(scroller.AbsoluteWindowSize)
        local overflow = (axis(scroller.AbsoluteCanvasSize) - view) / scale()
        local position = axis(scroller.CanvasPosition)
        local start = axis(scroller.AbsolutePosition)
        local before, after = 0, 0
        for _, item in ipairs(items:GetChildren()) do
            if item:IsA("GuiObject") and item.Visible and axis(item.AbsoluteSize) > 0 then
                local centre = axis(item.AbsolutePosition) + axis(item.AbsoluteSize) / 2 - start
                if centre < 0 then
                    before += 1
                elseif centre > view then
                    after += 1
                end
            end
        end
        for direction, hint in pairs(hints) do
            local hidden = direction < 0 and before or after
            hint.Count.Text = tostring(hidden)
            hint.Count.Visible = hidden > 0
            show(hint, overflow > 1 and (direction < 0 and position > 1 or direction > 0 and position < overflow - 1))
        end
    end
    for _, property in ipairs({ "CanvasPosition", "AbsoluteCanvasSize", "AbsoluteWindowSize" }) do
        scroller:GetPropertyChangedSignal(property):Connect(refresh)
    end
    task.defer(refresh)
end

function Window:_scrollTabIntoView(tab)
    local list = self.TabList
    local scale = self.Scale.Scale
    local top = (tab._button.AbsolutePosition.Y - list.AbsolutePosition.Y) / scale + list.CanvasPosition.Y
    local bottom = top + tab._button.AbsoluteSize.Y / scale
    local view = list.AbsoluteWindowSize.Y / scale
    local y = list.CanvasPosition.Y
    if top - 8 < y then
        y = top - 8
    elseif bottom + 8 > y + view then
        y = bottom + 8 - view
    else
        return
    end
    tween(list, { CanvasPosition = Vector2.new(0, math.max(0, y)) }, 0.35, Enum.EasingStyle.Quint)
end

function Window:_closePopups()
    if self._closePopup then
        self._closePopup()
    end
end

-- Popped-out groupboxes float on one screen-wide layer above the window. It
-- carries the window's scale, so a panel keeps the size it had in its column,
-- and it shows while the window is open (minimized included).
function Window:_popoutLayer()
    if self._popLayer then
        return self._popLayer
    end
    local layer = create("Frame", {
        Name = "PopOuts",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 20,
        Parent = self.Gui,
    })
    local layerScale = create("UIScale", { Parent = layer })
    self._popLayer = layer
    self._popPanels = {}
    self:_listen("Render", function()
        local scale = math.max(self.Scale.Scale, 0.05)
        if math.abs(layerScale.Scale - scale) > 1e-4 then
            layerScale.Scale = scale
            layer.Size = UDim2.fromScale(1 / scale, 1 / scale)
        end
        layer.Visible = self.Open == true and not self._destroyed
    end)
    return layer
end

-- Where a control's popup is drawn: the pop-out layer for one inside a
-- floating panel, otherwise the window body.
function Window:_popupHost(object)
    local layer = self._popLayer
    if layer and object and object:IsDescendantOf(layer) then
        return layer
    end
    return self.Body
end

-- A floating panel under the point counts as a control, so pressing it never
-- starts a window drag.
function Window:_overPopout(point)
    local layer = self._popLayer
    if not layer or not layer.Visible then
        return false
    end
    for _, panel in ipairs(self._popPanels) do
        if panel.Parent and panel.Visible and pointInside(point, panel) then
            return true
        end
    end
    return false
end

-- Fades the whole body by lending it to the fader CanvasGroup, then hands it
-- back to the root once fully shown so it renders directly again.
function Window:_fade(target, duration)
    local fader, body = self._fader, self.Body
    self._fadeGeneration = (self._fadeGeneration or 0) + 1
    local generation = self._fadeGeneration
    if body.Parent ~= fader then
        fader.GroupTransparency = self._bodyAlpha
        body.Parent = fader
    end
    fader.Visible = true
    self._bodyAlpha = target
    tween(fader, { GroupTransparency = target }, duration)
    task.delay(duration + 0.03, function()
        if self._fadeGeneration == generation and target <= 0 and not self._destroyed then
            body.Parent = self.Root
            fader.Visible = false
        end
    end)
end

function Window:SelectTab(tab)
    if self.CurrentTab == tab then
        return
    end
    local previous = self.CurrentTab
    self:_resetSearch()
    self:_closePopups()
    self.CurrentTab = tab

    self:_settleTransition()
    local generation = (self._transitionGeneration or 0) + 1
    self._transitionGeneration = generation

    if previous then
        tween(previous._label, { TextColor3 = Theme.Muted }, 0.3)
        if previous._icon then
            tintIcon(previous._icon, Theme.Muted, false, 0.3)
        end
        local outLayer = self._outLayer
        previous._page.Parent = outLayer
        self._outPage = previous._page
        outLayer.GroupTransparency = 0
        outLayer.Position = UDim2.fromOffset(0, 0)
        outLayer.Visible = true
        tween(outLayer, { GroupTransparency = 1, Position = UDim2.fromOffset(0, -6) }, 0.2, Enum.EasingStyle.Quint)
        task.delay(0.18, function()
            if self._transitionGeneration == generation then
                self:_settleOut()
            end
        end)
    end

    tween(tab._button, { BackgroundTransparency = 1 }, 0.2)
    tween(tab._stroke, { Transparency = 1 }, 0.2)
    tween(tab._label, { TextColor3 = Theme.Text }, 0.3)
    if tab._icon then
        tintIcon(tab._icon, Theme.Text, true, 0.3)
    end

    self:_placeIndicator(tab)
    self:_scrollTabIntoView(tab)

    local page = tab._page
    page.Position = UDim2.fromOffset(0, 0)
    page.Visible = true
    page.Parent = self._inLayer
    self._inPage = page
    fadeSlideIn(self._inLayer)
    task.delay(0.32, function()
        if self._transitionGeneration == generation then
            self:_settleIn()
        end
    end)
end

function Window:_settleOut()
    local page = self._outPage
    if page then
        page.Parent = self.Content
        page.Visible = false
        self._outPage = nil
    end
    self._outLayer.Visible = false
end

function Window:_settleIn()
    local page = self._inPage
    if page then
        page.Parent = self.Content
        page.Position = UDim2.fromOffset(0, 0)
        self._inPage = nil
    end
    self._inLayer.Visible = false
end

function Window:_settleTransition()
    self:_settleOut()
    self:_settleIn()
end

-- Backdrop: a black tint over the game while the window is up, with an
-- optional weather layer (rain, snow or hell fire embers) drifting through it.
-- It fades out when the window is minimized or hidden and sweeps back in with
-- a gust when it comes back.

local WEATHER = {
    -- The rain texture is a wide sheet with one faint streak down the middle
    -- (about 1/60 of its width, 57% of its height), so it is stretched much
    -- wider than the drop it draws. See RAIN_STREAK.
    Rain = { Image = "rbxassetid://241868005", Count = 90, Stretch = true },
    Snow = { Image = "rbxassetid://99851851", Count = 60 },
    Ember = { Image = "rbxassetid://242205518", Count = 55 },
    -- Drawn with plain frames and text, no images: petals are tinted pills
    -- that flip as they fall, matrix columns are text strips.
    Sakura = { Petal = true, Count = 46, Glow = Color3.fromRGB(255, 150, 190), GlowAmount = 0.1 },
    Fireflies = { Image = Assets.Glow, Count = 34, Glow = Color3.fromRGB(70, 150, 60), GlowAmount = 0.16 },
    Matrix = {
        Text = true,
        Count = 38,
        Glow = Color3.fromRGB(30, 200, 90),
        GlowAmount = 0.07,
        Glyphs = "01234567890123456789アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン+-*=<>:",
    },
}
local WEATHER_NAMES = {
    rain = "Rain",
    snow = "Snow",
    ember = "Ember",
    embers = "Ember",
    fire = "Ember",
    hellfire = "Ember",
    sakura = "Sakura",
    petals = "Sakura",
    cherryblossom = "Sakura",
    firefly = "Fireflies",
    fireflies = "Fireflies",
    matrix = "Matrix",
    matrixrain = "Matrix",
    code = "Matrix",
}
local RAIN_STREAK = Vector2.new(7 / 420, 151 / 263)
local weatherRandom = Random.new()

-- "UI" keeps the weather inside the window, behind its content; anything
-- else drifts it across the whole screen.
local function weatherMode(mode)
    if type(mode) == "string" and ({ ui = true, window = true, inside = true })[mode:lower()] then
        return "UI"
    end
    return "Screen"
end

local function weatherName(name)
    if type(name) ~= "string" then
        return "None"
    end
    return WEATHER_NAMES[(name:lower():gsub("[%s_%-]", ""))] or "None"
end

local function roll(min, max)
    return weatherRandom:NextNumber(min, max)
end

-- Places a particle. `anywhere` scatters it over the whole screen (first
-- frame after the backdrop appears), otherwise it enters from its edge.
local function seedParticle(kind, particle, width, height, anywhere)
    particle.Time = roll(0, 10)
    particle.Phase = roll(0, math.pi * 2)
    if kind == "Rain" then
        local w = roll(2, 3.5)
        particle.Size = Vector2.new(w, roll(26, 52))
        particle.VY = roll(950, 1400)
        particle.VX = particle.VY * 0.12
        particle.Sway, particle.Spin = 0, 0
        particle.Rotation = -math.deg(math.atan2(particle.VX, particle.VY))
        particle.Alpha = roll(0, 0.35)
        particle.X = roll(-0.15 * width, width)
        particle.Y = anywhere and roll(-40, height) or roll(-120, -particle.Size.Y)
    elseif kind == "Snow" then
        local s = roll(6, 17)
        particle.Size = Vector2.new(s, s)
        particle.VY = roll(30, 55) * (0.6 + s / 17)
        particle.VX = roll(-8, 14)
        particle.Sway = roll(12, 38)
        particle.Frequency = roll(0.5, 1.3)
        particle.Spin = roll(-60, 60)
        particle.Rotation = roll(0, 360)
        particle.Alpha = roll(0.05, 0.45)
        particle.X = roll(0, width)
        particle.Y = anywhere and roll(-20, height) or roll(-60, -s)
    elseif kind == "Sakura" then
        local s = roll(7, 14)
        particle.Size = Vector2.new(s, s * roll(0.55, 0.75))
        particle.VY = roll(35, 70)
        particle.VX = roll(18, 45)
        particle.Sway = roll(14, 34)
        particle.Frequency = roll(0.6, 1.4)
        particle.Flutter = roll(1.2, 2.6)
        particle.Spin = roll(-90, 90)
        particle.Rotation = roll(0, 360)
        particle.Alpha = roll(0.05, 0.35)
        particle.Color = Color3.fromRGB(255, 205, 220):Lerp(Color3.fromRGB(255, 140, 180), roll(0, 1))
        particle.X = roll(-0.25 * width, width)
        particle.Y = anywhere and roll(-20, height) or roll(-60, -s)
    elseif kind == "Fireflies" then
        -- They wander instead of crossing the screen, and live a few seconds:
        -- fade in, pulse, fade out, then turn up somewhere else.
        local s = roll(14, 28)
        particle.Size = Vector2.new(s, s)
        particle.VY = roll(-14, 8)
        particle.VX = roll(-12, 12)
        particle.Sway = roll(10, 30)
        particle.SwayY = roll(8, 22)
        particle.Frequency = roll(0.3, 0.8)
        particle.Spin, particle.Rotation = 0, 0
        particle.Alpha = roll(0, 0.25)
        particle.Life = roll(5, 11)
        particle.Age = anywhere and roll(0, particle.Life) or 0
        particle.Pulse = roll(1.5, 3.5)
        particle.Color = Color3.fromRGB(200, 255, 120):Lerp(Color3.fromRGB(255, 230, 120), roll(0, 1))
        particle.X = roll(0, width)
        particle.Y = roll(height * 0.15, height)
    elseif kind == "Matrix" then
        local definition = WEATHER.Matrix
        if not definition.List then
            definition.List = {}
            for _, code in utf8.codes(definition.Glyphs) do
                table.insert(definition.List, utf8.char(code))
            end
        end
        local list = definition.List
        local s = math.floor(roll(12, 19))
        local length = math.floor(roll(8, 20))
        particle.TextSize = s
        particle.Size = Vector2.new(s + 6, s * length)
        particle.VY = roll(160, 360) * (s / 15)
        particle.VX, particle.Sway, particle.Spin, particle.Rotation = 0, 0, 0, 0
        -- Smaller columns read as further away: dimmer.
        particle.Alpha = roll(0, 0.25) + (19 - s) * 0.04
        particle.X = math.floor(roll(0, width) / 18) * 18 + 9
        particle.Y = anywhere and roll(-particle.Size.Y / 2, height) or -particle.Size.Y / 2 - roll(0, 240)
        particle.Chars = {}
        for index = 1, length do
            particle.Chars[index] = list[math.random(#list)]
        end
        particle.Shuffle = roll(0.05, 0.2)
    else
        local s = roll(4, 12)
        particle.Size = Vector2.new(s, s)
        particle.VY = -roll(60, 170)
        particle.VX = roll(-12, 12)
        particle.Sway = roll(8, 28)
        particle.Frequency = roll(1, 2.4)
        particle.Spin = roll(-140, 140)
        particle.Rotation = roll(0, 360)
        particle.Alpha = roll(0, 0.3)
        particle.Color = Color3.fromRGB(255, 70, 20):Lerp(Color3.fromRGB(255, 190, 70), roll(0, 1))
        particle.X = roll(0, width)
        particle.Y = anywhere and roll(height * 0.2, height + 10) or height + roll(10, 80)
    end
    local label = particle.Label
    if kind == "Rain" then
        label.Size = UDim2.fromOffset(particle.Size.X / RAIN_STREAK.X, particle.Size.Y / RAIN_STREAK.Y)
    else
        label.Size = UDim2.fromOffset(particle.Size.X, particle.Size.Y)
    end
    if kind == "Matrix" then
        label.TextSize = particle.TextSize
        label.Text = table.concat(particle.Chars, "\n")
    elseif kind == "Sakura" then
        label.BackgroundColor3 = particle.Color
    else
        label.ImageColor3 = particle.Color
            or (kind == "Rain" and Color3.fromRGB(190, 210, 245) or Color3.new(1, 1, 1))
    end
end

function Window:_buildBackdrop(opts)
    local layer = create("Frame", {
        Name = "Backdrop",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 0,
        Parent = self.Gui,
    })
    local tint = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = layer,
    })
    -- Darker towards the top and bottom edges.
    create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Parent = tint,
    })
    -- Heat rising from the bottom of the screen, hell fire only.
    local heat = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.fromScale(1, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 60, 15),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = layer,
    })
    create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new(1, 0),
        Parent = heat,
    })
    -- Holds the heat and the particles so both move together between the
    -- screen and the window.
    local field = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 2,
        Parent = layer,
    })
    heat.Parent = field
    self._backdrop = layer
    self._backdropTintFrame = tint
    self._backdropHeat = heat
    self._weatherField = field
    self._weatherParticles = {}
    self._backdropFade = 0
    self._weatherKick = 0
    self._backdropShown = false
    self._backdropEnabled = opts.Enabled ~= false
    self._backdropTint = math.clamp(tonumber(opts.Tint) or 0.45, 0, 1)
    self._backdropDim = opts.Dim ~= false
    self._dimLevel = self._backdropDim and 1 or 0
    self._weatherDensity = math.clamp(tonumber(opts.Density) or 1, 0, 3)
    self._weatherSpeed = math.clamp(tonumber(opts.Speed) or 1, 0.1, 3)
    self.Weather = weatherName(opts.Weather == nil and "Snow" or opts.Weather)
    self.WeatherMode = "Screen"
    self:SetWeatherMode(opts.Mode)
    self:_rebuildWeather()
    table.insert(self._frameSteps, function(deltaTime)
        self:_stepBackdrop(deltaTime)
    end)
end

-- The area the particles cover, in the field's own (unscaled) units.
function Window:_weatherSize()
    if self.WeatherMode == "UI" then
        return Vector2.new(self.Root.Size.X.Offset, self.Root.Size.Y.Offset)
    end
    return self.Gui.AbsoluteSize
end

function Window:_rebuildWeather()
    for _, particle in ipairs(self._weatherParticles) do
        particle.Label:Destroy()
    end
    self._weatherParticles = {}
    local definition = WEATHER[self.Weather]
    if not definition then
        return
    end
    -- The glow along the bottom: red heat for hell fire, a soft tint for the
    -- others that ask for one.
    self._backdropHeat.BackgroundColor3 = definition.Glow or Color3.fromRGB(255, 60, 15)
    local size = self:_weatherSize()
    -- The window is a fraction of the screen, so it gets fewer particles.
    local count = definition.Count * self._weatherDensity * (self.WeatherMode == "UI" and 0.45 or 1)
    for _ = 1, math.floor(count + 0.5) do
        local instance, property
        if definition.Text then
            property = "TextTransparency"
            instance = create("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Text = "",
                TextColor3 = Color3.fromRGB(90, 255, 140),
                TextTransparency = 1,
                FontFace = Font.fromEnum(Enum.Font.Code),
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                LineHeight = 1,
                ZIndex = 2,
                Parent = self._weatherField,
            })
            -- A fading tail and a pale leading glyph.
            create("UIGradient", {
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(0.88, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 255, 240)),
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.6, 0.45),
                    NumberSequenceKeypoint.new(1, 0),
                }),
                Parent = instance,
            })
        elseif definition.Petal then
            property = "BackgroundTransparency"
            instance = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 190, 210),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = self._weatherField,
            })
            corner(instance, UDim.new(1, 0))
            create("UIGradient", {
                Rotation = 35,
                Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(235, 200, 215)),
                Parent = instance,
            })
        else
            property = "ImageTransparency"
            instance = create("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = definition.Image,
                ImageTransparency = 1,
                ScaleType = definition.Stretch and Enum.ScaleType.Stretch or Enum.ScaleType.Fit,
                ZIndex = 2,
                Parent = self._weatherField,
            })
        end
        local particle = { Label = instance, Property = property }
        seedParticle(self.Weather, particle, size.X, size.Y, true)
        table.insert(self._weatherParticles, particle)
    end
end

function Window:_stepBackdrop(deltaTime)
    local target = self._backdropShown and 1 or 0
    local fade = self._backdropFade
    if fade == target and target == 0 then
        return
    end
    if fade < target then
        fade = math.min(fade + deltaTime / 0.45, target)
    elseif fade > target then
        fade = math.max(fade - deltaTime / 0.25, target)
    end
    self._backdropFade = fade
    if fade <= 0 then
        self._backdrop.Visible = false
        self._weatherField.Visible = false
        return
    end
    local eased = 1 - (1 - fade) ^ 3
    local kind = self.Weather
    -- The dim eases on its own so turning it off doesn't touch the weather.
    local dim = self._dimLevel
    if self._backdropDim then
        dim = math.min(dim + deltaTime / 0.3, 1)
    else
        dim = math.max(dim - deltaTime / 0.3, 0)
    end
    self._dimLevel = dim
    self._backdropTintFrame.BackgroundTransparency = 1 - self._backdropTint * eased * dim
    local definition = WEATHER[kind]
    self._backdropHeat.BackgroundTransparency = kind == "Ember"
        and 1 - (0.22 + math.sin(os.clock() * 2.1) * 0.05) * eased
        or definition and definition.GlowAmount and 1 - (definition.GlowAmount + math.sin(os.clock() * 0.8) * definition.GlowAmount * 0.25) * eased
        or 1

    -- The gust on restore: particles rush in fast and settle back.
    local kick = self._weatherKick
    self._weatherKick = math.max(kick - deltaTime * 1.3, 0)
    local speed = self._weatherSpeed * (1 + kick * kick * 2.5)
    local size = self:_weatherSize()
    local width, height = size.X, size.Y
    for _, particle in ipairs(self._weatherParticles) do
        particle.Time += deltaTime
        particle.X += particle.VX * deltaTime * speed
        particle.Y += particle.VY * deltaTime * speed
        particle.Rotation += particle.Spin * deltaTime * speed
        local margin = math.max(particle.Size.X, particle.Size.Y)
        if particle.Life then
            particle.Age += deltaTime
        end
        if (particle.Life and particle.Age > particle.Life)
            or (not particle.Life and ((particle.VY > 0 and particle.Y > height + margin) or (particle.VY < 0 and particle.Y < -margin))) then
            seedParticle(kind, particle, width, height, false)
        elseif particle.X > width + margin * 4 then
            particle.X -= width + margin * 6
        elseif particle.X < -margin * 4 then
            particle.X += width + margin * 6
        end
        local x = particle.X
        local alpha = 1 - particle.Alpha
        if particle.Sway ~= 0 then
            x += math.sin(particle.Time * particle.Frequency + particle.Phase) * particle.Sway
        end
        local y = particle.Y
        local label = particle.Label
        if kind == "Ember" then
            -- Flicker, and burn out on the way up.
            alpha *= math.clamp(particle.Y / (height * 0.85), 0, 1) ^ 0.6
            alpha *= 0.75 + math.sin(particle.Time * 9 + particle.Phase) * 0.25
        elseif kind == "Sakura" then
            -- Flip: the petal narrows and widens as it turns over.
            local turn = math.abs(math.cos(particle.Time * particle.Flutter + particle.Phase))
            label.Size = UDim2.fromOffset(particle.Size.X * (0.3 + turn * 0.7), particle.Size.Y)
        elseif kind == "Fireflies" then
            y += math.cos(particle.Time * particle.Frequency * 1.3 + particle.Phase) * particle.SwayY
            local age, life = particle.Age, particle.Life
            alpha *= math.clamp(math.min(age / 1.2, (life - age) / 1.2), 0, 1)
            alpha *= 0.5 + math.sin(particle.Time * particle.Pulse + particle.Phase) * 0.5
        elseif kind == "Matrix" then
            particle.Shuffle -= deltaTime * speed
            if particle.Shuffle <= 0 then
                particle.Shuffle = roll(0.05, 0.2)
                local list = WEATHER.Matrix.List
                local chars = particle.Chars
                chars[math.random(#chars)] = list[math.random(#list)]
                chars[#chars] = list[math.random(#list)]
                label.Text = table.concat(chars, "\n")
            end
        end
        label.Position = UDim2.fromOffset(x, y)
        label.Rotation = particle.Rotation
        label[particle.Property or "ImageTransparency"] = 1 - alpha * eased
    end
end

function Window:_refreshBackdrop(gust)
    if not self._backdrop then
        return
    end
    local shown = self._backdropEnabled and self._introDone and self.Open and not self.Minimized and not self._destroyed
    if shown and not self._backdropShown then
        self._backdrop.Visible = true
        self._weatherField.Visible = true
        if self._backdropFade <= 0 then
            local size = self:_weatherSize()
            for _, particle in ipairs(self._weatherParticles) do
                seedParticle(self.Weather, particle, size.X, size.Y, true)
            end
        end
        if gust then
            self._weatherKick = 1
        end
    end
    self._backdropShown = shown == true
end

function Window:SetBackdrop(enabled)
    if not self._backdrop then
        return
    end
    self._backdropEnabled = enabled ~= false
    self:_refreshBackdrop(true)
end

function Window:SetBackdropTint(amount)
    if not self._backdrop then
        return
    end
    self._backdropTint = math.clamp(tonumber(amount) or 0.45, 0, 1)
end

-- Turns the black tint on or off, leaving the weather running.
function Window:SetDim(enabled)
    if not self._backdrop then
        return
    end
    self._backdropDim = enabled ~= false
end

function Window:SetWeatherMode(mode)
    if not self._backdrop then
        return
    end
    mode = weatherMode(mode)
    local field = self._weatherField
    if mode == "UI" then
        -- Under everything else in the body: sidebar, content and glows.
        field.ZIndex = 0
        field.Parent = self.Body
    else
        field.ZIndex = 2
        field.Parent = self._backdrop
    end
    if mode == self.WeatherMode then
        return
    end
    self.WeatherMode = mode
    self:_rebuildWeather()
    if self._backdropShown then
        self._weatherKick = 1
    end
end

function Window:SetWeather(name)
    if not self._backdrop then
        return
    end
    local kind = weatherName(name)
    if kind == self.Weather then
        return
    end
    self.Weather = kind
    self:_rebuildWeather()
    if self._backdropShown then
        self._weatherKick = 1
    end
end

function Window:SetWeatherDensity(density)
    if not self._backdrop then
        return
    end
    self._weatherDensity = math.clamp(tonumber(density) or 1, 0, 3)
    self:_rebuildWeather()
end

function Window:SetWeatherSpeed(speed)
    if not self._backdrop then
        return
    end
    self._weatherSpeed = math.clamp(tonumber(speed) or 1, 0.1, 3)
end

-- Minimize: the window folds into a Dynamic Island style pill hanging from
-- the top of the screen. Compact, it shows the logo and a live meter of
-- running toggles. Hovering springs it open into a session card: the
-- player, the game and session time, frame rate and ping meters, the server
-- and running counts, and the key that reopens the window. A
-- notification while minimized opens it briefly to show it. Click or tap
-- restores.

-- One table, not separate locals: the main chunk is at Luau's 200 local limit.
local Mini = {
    -- Sized after the iPhone 18 island: a slimmer, shorter pill sitting close
    -- to the top edge, opening into a wide card with deep rounded corners.
    Top = 8, -- gap from the top of the screen
    Width = TOUCH and 176 or 168, -- compact
    Height = TOUCH and 36 or 32,
    Wide = 340, -- expanded and activity
    Radius = 34, -- corner of the expanded and activity cards
    Bars = 4,
    Pinned = 6,
}

-- The morph is carried by a plain "ghost" panel drawn over the window. The
-- window body itself never moves or fades, so nothing has to be laid out
-- again mid-animation: the ghost covers it, the window is hidden underneath,
-- and on the way back the window is shown under the ghost before it clears.
local function makeGhost(window, position, size, radius)
    if window._ghost then
        window._ghost:Destroy()
    end
    local ghost = create("Frame", {
        Position = UDim2.fromOffset(position.X, position.Y),
        Size = UDim2.fromOffset(size.X, size.Y),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 29,
        Parent = window.Gui,
    })
    local ghostCorner = Library._fixedCorner(ghost, UDim.new(0, radius))
    local ghostStroke = stroke(ghost, Theme.Stroke, 1)
    window._ghost = ghost
    return ghost, ghostStroke, ghostCorner
end

local function morphGhost(ghost, ghostCorner, position, size, radius, duration)
    tween(ghost, {
        Position = UDim2.fromOffset(position.X, position.Y),
        Size = UDim2.fromOffset(size.X, size.Y),
    }, duration, Enum.EasingStyle.Quint)
    tween(ghostCorner, { CornerRadius = UDim.new(0, radius) }, duration, Enum.EasingStyle.Quint)
end

local function dissolve(window, ghost, ghostStroke, duration)
    tween(ghost, { BackgroundTransparency = 1 }, duration, Enum.EasingStyle.Quad)
    tween(ghostStroke, { Transparency = 1 }, duration, Enum.EasingStyle.Quad)
    task.delay(duration + 0.02, function()
        if window._ghost == ghost then
            window._ghost = nil
        end
        ghost:Destroy()
    end)
end

function Window:_buildMiniBar()
    if self.MiniBar then
        return self.MiniBar
    end
    local gui = self.Gui

    -- The island itself: a black pill hanging from the top of the screen. It
    -- is a canvas so its rounded shape clips whatever layer is showing.
    local island = create("CanvasGroup", {
        Name = "Island",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, Mini.Top),
        Size = UDim2.fromOffset(Mini.Width, Mini.Height),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Visible = false,
        ZIndex = 30,
        Parent = gui,
    })
    local islandCorner = Library._fixedCorner(island, UDim.new(0, Mini.Height / 2))
    local islandScale = create("UIScale", { Parent = island })
    self._miniScale = islandScale
    -- How far the split bubble is out of the pill: drawn back in while the
    -- island is open, budded off again once it settles to the pill.
    local merge = create("NumberValue", { Value = 1 })
    local mergeTween
    self._miniOrb = island

    -- The wide layers keep a fixed width, so nothing reflows while the island
    -- grows around them.
    local function layer(name)
        return create("CanvasGroup", {
            Name = name,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(0, Mini.Wide, 0, 400),
            BackgroundTransparency = 1,
            GroupTransparency = 1,
            Parent = island,
        })
    end

    -- Compact: the logo leading, a live meter of running toggles trailing.
    -- A graphite surface, lit from the top, so the pill isn't a flat black
    -- slab; it fades with the layer, leaving the open card black.
    local compact = create("CanvasGroup", {
        Name = "Compact",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(30, 30, 34),
        BorderSizePixel = 0,
        Parent = island,
    })
    create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 120, 120)),
        Parent = compact,
    })
    -- The logo sits in a soft accent disc, like an app glyph.
    local logoDisc = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 5, 0.5, 0),
        Size = UDim2.fromOffset(Mini.Height - 10, Mini.Height - 10),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        Parent = compact,
    })
    corner(logoDisc, UDim.new(1, 0))
    local logo = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Accent,
        ScaleType = Enum.ScaleType.Fit,
        Parent = logoDisc,
    })
    applyIcon(logo, self._logoIcon, true)
    -- The script's name beside the logo, so the pill reads at a glance.
    local miniTitle = label({
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, Mini.Height + 2, 0.5, 0),
        Size = UDim2.new(1, -Mini.Height - 2 - 72, 0, 18),
        Text = self.Title,
        TextSize = 13,
        FontFace = Fonts.Bold,
        TextColor3 = Color3.fromRGB(244, 244, 246),
        Parent = compact,
    })
    local meter = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Parent = compact,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 7),
        Parent = meter,
    })
    local barsHolder = create("Frame", {
        Size = UDim2.fromOffset(Mini.Bars * 3 + (Mini.Bars - 1) * 2, 16),
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 1,
        Parent = meter,
    })
    local bars = {}
    for index = 1, Mini.Bars do
        local bar = create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, (index - 1) * 5, 0.5, 0),
            Size = UDim2.fromOffset(3, 3),
            BackgroundColor3 = Theme.Muted,
            BorderSizePixel = 0,
            Parent = barsHolder,
        })
        corner(bar, UDim.new(1, 0))
        bars[index] = bar
    end
    local countLabel = label({
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = "",
        TextSize = 13,
        FontFace = Fonts.Bold,
        TextTruncate = Enum.TextTruncate.None,
        Visible = false,
        LayoutOrder = 2,
        Parent = meter,
    })
    -- Idle (nothing running): a health dot tinted by frame rate and the
    -- session clock, so the pill never sits empty.
    local idleDot = create("Frame", {
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        LayoutOrder = -1,
        Parent = meter,
    })
    corner(idleDot, UDim.new(1, 0))
    local idleLabel = label({
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = "0s",
        TextSize = 12,
        FontFace = Fonts.Bold,
        TextColor3 = Color3.fromRGB(220, 220, 224),
        TextTruncate = Enum.TextTruncate.None,
        LayoutOrder = 0,
        Parent = meter,
    })

    -- Expanded, on hover: the player's session.
    local expanded = layer("Expanded")
    local expandedList = create("Frame", {
        Position = UDim2.fromOffset(16, 14),
        Size = UDim2.new(1, -32, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = expanded,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = expandedList,
    })
    -- The open card is the player's session, like a now-playing card: who
    -- and where on top with the session clock, two wide meters for frame
    -- rate and ping, then chips for the server and what's running.
    local top = create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = expandedList,
    })
    local face = create("ImageLabel", {
        Size = UDim2.fromOffset(48, 48),
        BackgroundColor3 = Color3.fromRGB(38, 38, 41),
        BorderSizePixel = 0,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150",
        Parent = top,
    })
    corner(face, UDim.new(0, 12))
    local facePlaceholder = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Muted,
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        Parent = face,
    })
    applyIcon(facePlaceholder, "user")
    self:_trackAvatar(face, facePlaceholder)
    local nameLabel = label({
        Position = UDim2.fromOffset(60, 5),
        Size = UDim2.new(1, -150, 0, 20),
        TextSize = 15,
        FontFace = Fonts.Bold,
        TextColor3 = Color3.fromRGB(244, 244, 246),
        Parent = top,
    })
    self:_trackName(nameLabel, "Display")
    local tabLabel = label({
        Position = UDim2.fromOffset(60, 26),
        Size = UDim2.new(1, -150, 0, 15),
        Text = "",
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        Parent = top,
    })
    task.spawn(function()
        tabLabel.Text = detectGameName()
    end)
    local sessionLabel = label({
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 3),
        Size = UDim2.fromOffset(90, 24),
        Text = "0s",
        TextSize = 20,
        FontFace = Fonts.Bold,
        TextColor3 = Color3.fromRGB(244, 244, 246),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = top,
    })
    label({
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 27),
        Size = UDim2.fromOffset(90, 14),
        Text = "session",
        TextSize = 11,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = top,
    })

    -- Two readouts: a large number with its unit, a caption, and a thin
    -- line under them that fills and tints with how healthy it is.
    local meters = create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        Parent = expandedList,
    })
    local function meterPill(position, caption)
        local cell = create("Frame", {
            Position = position,
            Size = UDim2.new(0.5, -10, 1, 0),
            BackgroundTransparency = 1,
            Parent = meters,
        })
        local value = label({
            Size = UDim2.new(1, -70, 0, 24),
            Text = "",
            TextSize = 20,
            FontFace = Fonts.Bold,
            TextColor3 = Color3.fromRGB(244, 244, 246),
            RichText = true,
            Parent = cell,
        })
        label({
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 6),
            Size = UDim2.fromOffset(70, 14),
            Text = caption,
            TextSize = 10,
            TextColor3 = Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = cell,
        })
        local track = create("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, -4),
            Size = UDim2.new(1, 0, 0, 3),
            BackgroundColor3 = Color3.fromRGB(38, 38, 42),
            BorderSizePixel = 0,
            Parent = cell,
        })
        corner(track, UDim.new(1, 0))
        local fill = create("Frame", {
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = Theme.Success,
            BorderSizePixel = 0,
            Parent = track,
        })
        corner(fill, UDim.new(1, 0))
        return fill, value
    end
    local fpsFill, fpsValue = meterPill(UDim2.fromScale(0, 0), "FRAME RATE")
    local pingFill, pingValue = meterPill(UDim2.new(0.5, 10, 0, 0), "PING")

    -- Chips: a muted name and a bold value, the running count in accent.
    local chips = create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Parent = expandedList,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = chips,
    })
    local function chipOf(order, name, color)
        local chipFrame = create("Frame", {
            Size = UDim2.fromOffset(0, 30),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Color3.fromRGB(32, 32, 35),
            BorderSizePixel = 0,
            LayoutOrder = order,
            Parent = chips,
        })
        corner(chipFrame, UDim.new(1, 0))
        padding(chipFrame, 14, 14)
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 7),
            Parent = chipFrame,
        })
        label({
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = name,
            TextSize = 12,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            TextTruncate = Enum.TextTruncate.None,
            LayoutOrder = 1,
            Parent = chipFrame,
        })
        return label({
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = "",
            TextSize = 12,
            FontFace = Fonts.Bold,
            TextColor3 = color or Color3.fromRGB(244, 244, 246),
            TextTruncate = Enum.TextTruncate.None,
            LayoutOrder = 2,
            Parent = chipFrame,
        })
    end
    local playersValue = chipOf(1, "Players")
    local bigCount = chipOf(2, "Running", Theme.Accent)
    local tabValue = chipOf(3, "Tab")

    -- Pinned statuses are no longer shown here; the holder stays so the
    -- refresh below has somewhere to keep its rows.
    local rowsHolder = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 4,
        Parent = expandedList,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = rowsHolder,
    })
    -- What's running, by name, so the count above has something behind it.
    local runningNames = label({
        Size = UDim2.new(1, 0, 0, 15),
        Text = "",
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = Color3.fromRGB(200, 200, 206),
        RichText = true,
        Visible = false,
        LayoutOrder = 4,
        Parent = expandedList,
    })
    local hint = label({
        Size = UDim2.new(1, 0, 0, 14),
        TextSize = 11,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        LayoutOrder = 5,
        Parent = expandedList,
    })

    -- Frame rate is counted every frame; the card's values refresh twice a
    -- second while it's open.
    local sessionStart = self._sessionStart or os.clock()
    local frames, frameClock, fps = 0, os.clock(), 60
    self:_listen("Render", function()
        frames += 1
        local now = os.clock()
        if now - frameClock >= 0.5 then
            fps = math.floor(frames / (now - frameClock) + 0.5)
            frames, frameClock = 0, now
        end
    end)
    local function refreshSession()
        sessionLabel.Text = formatDuration(os.clock() - sessionStart)
        idleLabel.Text = sessionLabel.Text
        tween(idleDot, { BackgroundColor3 = Library._healthColor(fps, 50, 30) }, 0.4)
        local unit = '<font size="12" color="#8A8A93"> %s</font>'
        fpsValue.Text = fps .. string.format(unit, "fps")
        tween(fpsFill, {
            Size = UDim2.fromScale(math.clamp(fps / 60, 0.05, 1), 1),
            BackgroundColor3 = Library._healthColor(fps, 50, 30),
        }, 0.4, Enum.EasingStyle.Quint)
        local okPing, ping = pcall(function()
            return math.floor(LocalPlayer:GetNetworkPing() * 1000)
        end)
        ping = okPing and ping or 0
        pingValue.Text = ping .. string.format(unit, "ms")
        -- Lower ping fills more: 40ms or less is full, 400ms and up is low.
        tween(pingFill, {
            Size = UDim2.fromScale(math.clamp(1 - (ping - 40) / 360, 0.05, 1), 1),
            BackgroundColor3 = Library._healthColor(ping, 90, 180, true),
        }, 0.4, Enum.EasingStyle.Quint)
        playersValue.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
        local tab = self.CurrentTab
        tabValue.Text = tab and tab.Name or "-"
    end
    task.spawn(function()
        while island.Parent do
            if island.Visible and self.Minimized then
                refreshSession()
            end
            task.wait(0.5)
        end
    end)

    -- Activity: a notification that arrives while minimized drops in here.
    local activity = layer("Activity")
    local activityList = create("Frame", {
        Position = UDim2.fromOffset(16, 13),
        Size = UDim2.new(1, -32, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = activity,
    })
    local activityChip = create("Frame", {
        Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Parent = activityList,
    })
    corner(activityChip, UDim.new(1, 0))
    local activityIcon = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(17, 17),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.Accent,
        ScaleType = Enum.ScaleType.Fit,
        Parent = activityChip,
    })
    local activityText = create("Frame", {
        Position = UDim2.fromOffset(46, 0),
        Size = UDim2.new(1, -46, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = activityList,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 1),
        Parent = activityText,
    })
    local activityTitle = label({
        Size = UDim2.new(1, 0, 0, 18),
        TextSize = 14,
        FontFace = Fonts.Bold,
        LayoutOrder = 1,
        Parent = activityText,
    })
    local activityBody = label({
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 12,
        FontFace = Fonts.Regular,
        TextColor3 = Theme.Muted,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        TextYAlignment = Enum.TextYAlignment.Top,
        MaxVisibleGraphemes = 140,
        LayoutOrder = 2,
        Parent = activityText,
    })

    local hit = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = island,
    })

    -- Morphing between shapes: the island springs to its new size while the
    -- old layer fades out and the new one fades in just behind it.
    local layers = { Compact = compact, Expanded = expanded, Activity = activity }
    local mode = "Compact"
    local modeToken = 0
    local sizeTween, cornerTween
    local hovered, pressed = false, false
    local hoverToken = 0
    local dragFrom, dragAnchor, dragging, dragged = nil, nil, false, false
    local activityToken = 0
    local activityLive = false

    local function shapeFor(name)
        if name == "Expanded" then
            return Vector2.new(Mini.Wide, math.floor(expandedList.AbsoluteSize.Y + 28 + 0.5)), Mini.Radius
        elseif name == "Activity" then
            return Vector2.new(Mini.Wide, math.floor(math.max(activityList.AbsoluteSize.Y, 34) + 26 + 0.5)), Mini.Radius
        end
        return Vector2.new(Mini.Width, Mini.Height), Mini.Height / 2
    end

    -- Where the island hangs: the top centre of its shape, as fractions of
    -- the screen so it keeps its spot across resolutions. Dragging moves it;
    -- each shape is clamped on screen, so the wide card slides in from an edge
    -- and the pill goes back to its spot when it folds.
    local saved = self:_readConfigSettings().IslandPosition
    if type(saved) == "table" and tonumber(saved.X) and tonumber(saved.Y) then
        self._islandAnchor = Vector2.new(math.clamp(tonumber(saved.X), 0, 1), math.clamp(tonumber(saved.Y), 0, 1))
    end
    local positionTween
    local function anchorPixels()
        local view = gui.AbsoluteSize
        local anchor = self._islandAnchor
        if not anchor then
            return Vector2.new(view.X / 2, Mini.Top)
        end
        return Vector2.new(anchor.X * view.X, anchor.Y * view.Y)
    end
    local function islandSpot(size, from)
        local view = gui.AbsoluteSize
        local spot = from or anchorPixels()
        local margin = 6
        local x = math.clamp(spot.X, size.X / 2 + margin, math.max(view.X - size.X / 2 - margin, size.X / 2 + margin))
        local y = math.clamp(spot.Y, margin, math.max(view.Y - size.Y - margin, margin))
        return Vector2.new(x, y)
    end
    local function placeIsland(size, duration, style)
        local spot = islandSpot(size)
        if positionTween then
            positionTween:Cancel()
            positionTween = nil
        end
        if duration and duration > 0 then
            positionTween = tween(island, { Position = UDim2.fromOffset(spot.X, spot.Y) }, duration, style or Enum.EasingStyle.Quint)
        else
            island.Position = UDim2.fromOffset(spot.X, spot.Y)
        end
    end
    self._islandReset = function()
        self._islandAnchor = nil
        if island.Visible then
            placeIsland(Vector2.new(island.Size.X.Offset, island.Size.Y.Offset), 0.35)
        end
    end

    local function setMode(name, instant)
        local size, radius = shapeFor(name)
        local changed = name ~= mode
        mode = name
        modeToken += 1
        local token = modeToken
        local current = Vector2.new(island.Size.X.Offset, island.Size.Y.Offset)
        local growing = size.X > current.X + 1 or size.Y > current.Y + 1
        local duration = instant and 0 or (growing and 0.5 or 0.38)
        -- A snap must stop a morph still in flight, or it keeps writing the
        -- old shape over the new one.
        if sizeTween then
            sizeTween:Cancel()
        end
        if cornerTween then
            cornerTween:Cancel()
        end
        placeIsland(size, duration)
        sizeTween = tween(island, { Size = UDim2.fromOffset(size.X, size.Y) }, duration, growing and Enum.EasingStyle.Back or Enum.EasingStyle.Quint)
        cornerTween = tween(islandCorner, { CornerRadius = UDim.new(0, radius) }, duration, Enum.EasingStyle.Quint)
        -- The iOS island gives a soft squeeze as it swells open, then springs
        -- back, so the morph reads as one elastic body rather than a resize.
        if changed and not instant and not pressed and not dragging then
            islandScale.Scale = growing and 0.96 or 1.03
            tween(islandScale, { Scale = 1 }, growing and 0.55 or 0.4, Enum.EasingStyle.Back)
        end
        if changed or instant then
            if mergeTween then
                mergeTween:Cancel()
                mergeTween = nil
            end
            if instant then
                merge.Value = name == "Compact" and 1 or 0
            elseif name == "Compact" then
                -- Wait for the pill to shrink most of the way, then bud off.
                task.delay(duration * 0.55, function()
                    if modeToken == token then
                        mergeTween = tween(merge, { Value = 1 }, 0.6, Enum.EasingStyle.Back)
                    end
                end)
            else
                mergeTween = tween(merge, { Value = 0 }, 0.2, Enum.EasingStyle.Quint)
            end
        end
        if not changed and not instant then
            -- A refit (same shape, new height) bumps the token, which cancels
            -- a fade-in still waiting from the morph; finish it here or the
            -- card stays black until the next hover.
            local target = layers[name]
            if target.GroupTransparency > 0 then
                tween(target, { GroupTransparency = 0 }, 0.22, Enum.EasingStyle.Quad)
            end
            if target ~= compact and target.Position ~= UDim2.fromScale(0.5, 0) then
                tween(target, { Position = UDim2.fromScale(0.5, 0) }, 0.32, Enum.EasingStyle.Quint)
            end
            return
        end
        for key, group in pairs(layers) do
            if key ~= name then
                tween(group, { GroupTransparency = 1 }, instant and 0 or 0.14, Enum.EasingStyle.Quad)
            end
        end
        local target = layers[name]
        if instant then
            target.GroupTransparency = 0
            -- Compact fills the island from its corner; only the wide
            -- layers hang from the centre.
            if target ~= compact then
                target.Position = UDim2.fromScale(0.5, 0)
            end
        else
            -- The new layer rises a few pixels into place as it fades in, so
            -- the content reads as arriving with the shape, not popping in.
            if target ~= compact then
                target.Position = UDim2.new(0.5, 0, 0, 6)
            end
            task.delay(0.1, function()
                if modeToken == token then
                    tween(target, { GroupTransparency = 0 }, 0.22, Enum.EasingStyle.Quad)
                    if target ~= compact then
                        tween(target, { Position = UDim2.fromScale(0.5, 0) }, 0.32, Enum.EasingStyle.Quint)
                    end
                end
            end)
        end
    end

    local function settleMode()
        if hovered and not TOUCH and not dragging then
            setMode("Expanded")
        elseif activityLive then
            setMode("Activity")
        elseif self.IslandStyle == "Always Show" and not dragging then
            self:_refreshMini()
            refreshSession()
            setMode("Expanded")
        else
            setMode("Compact")
        end
    end

    self._islandSettle = function()
        if self.Minimized and island.Visible and not dragging then
            settleMode()
        end
    end

    -- Called by Minimize once the window is out of the way: the island is
    -- reset to its compact pill and its spot handed back for the ghost.
    function self:_miniLand()
        hovered, activityLive = false, false
        activityToken += 1
        islandScale.Scale = 1
        setMode("Compact", true)
        local size = Vector2.new(Mini.Width, Mini.Height)
        local spot = islandSpot(size)
        return Vector2.new(spot.X - size.X / 2, spot.Y), size
    end

    hit.MouseEnter:Connect(function()
        if usingTouch() or dragging then
            return
        end
        hovered = true
        hoverToken += 1
        local token = hoverToken
        -- Already open (the pointer left and came back within the grace):
        -- just stay. Otherwise lean in a touch, and only open once the
        -- pointer rests, so sweeping past the island doesn't burst it open.
        if mode == "Expanded" then
            return
        end
        if not pressed then
            tween(islandScale, { Scale = 1.04 }, 0.18, Enum.EasingStyle.Quint)
        end
        task.delay(0.12, function()
            if hoverToken == token and hovered and self.Minimized and not dragging then
                self:_refreshMini()
                refreshSession()
                setMode("Expanded")
            end
        end)
    end)
    hit.MouseLeave:Connect(function()
        hovered = false
        hoverToken += 1
        local token = hoverToken
        if not pressed then
            tween(islandScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Quint)
        end
        -- A grace period: the card shifts while it morphs and clamps on
        -- screen, so a pointer grazing its edge shouldn't snap it shut.
        task.delay(mode == "Expanded" and 0.28 or 0.1, function()
            if hoverToken == token and not hovered and self.Minimized then
                settleMode()
            end
        end)
    end)
    -- Press and pull to move the island anywhere on screen. It folds to the
    -- pill while carried, lifts a little, and a drop near its home at the top
    -- centre snaps back there. A drag never counts as the click that restores.
    hit.InputBegan:Connect(function(input)
        if not isPress(input) then
            return
        end
        pressed = true
        dragged = false
        tween(islandScale, { Scale = 0.95 }, 0.12, Enum.EasingStyle.Quad)
        if not self._islandLocked then
            dragFrom = Vector2.new(input.Position.X, input.Position.Y)
            dragAnchor = islandSpot(Vector2.new(Mini.Width, Mini.Height))
        end
    end)
    self:_listen("Changed", function(input)
        if not dragFrom or not isMove(input) or not self.Minimized then
            return
        end
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragFrom
        if not dragging then
            if delta.Magnitude < (TOUCH and 10 or 6) then
                return
            end
            dragging, dragged = true, true
            hovered = false
            setMode("Compact")
            tween(islandScale, { Scale = 1.06 }, 0.2, Enum.EasingStyle.Quint)
        end
        local spot = islandSpot(Vector2.new(Mini.Width, Mini.Height), dragAnchor + delta)
        local view = gui.AbsoluteSize
        self._islandAnchor = Vector2.new(spot.X / math.max(view.X, 1), spot.Y / math.max(view.Y, 1))
        if positionTween then
            positionTween:Cancel()
            positionTween = nil
        end
        island.Position = UDim2.fromOffset(spot.X, spot.Y)
    end)
    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if not isPress(input) then
            return
        end
        dragFrom = nil
        if pressed then
            pressed = false
            tween(islandScale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
        end
        if dragging then
            dragging = false
            local home = Vector2.new(gui.AbsoluteSize.X / 2, Mini.Top)
            local spot = islandSpot(Vector2.new(Mini.Width, Mini.Height))
            if (spot - home).Magnitude < 28 then
                self._islandAnchor = nil
                placeIsland(Vector2.new(Mini.Width, Mini.Height), 0.35, Enum.EasingStyle.Back)
            end
            local anchor = self._islandAnchor
            self:_writeConfigSettings({ IslandPosition = anchor and { X = anchor.X, Y = anchor.Y } or false })
            hovered = not usingTouch() and pointInside(pointerPosition(), island)
            task.delay(0.1, function()
                if self.Minimized and not dragging then
                    settleMode()
                end
            end)
        end
    end))
    -- Keeps the island on screen when the viewport changes size.
    table.insert(self._connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if island.Visible and not dragging then
            placeIsland(Vector2.new(island.Size.X.Offset, island.Size.Y.Offset), 0)
        end
    end))
    hit.MouseButton1Click:Connect(function()
        if dragged then
            dragged = false
            return
        end
        if self.Minimized then
            self:Restore()
        end
    end)
    -- Restore hides the island under the pointer, so MouseLeave never fires.
    self._miniUnhover = function()
        hovered, pressed, activityLive = false, false, false
        dragFrom, dragging = nil, false
        activityToken += 1
        islandScale.Scale = 1
        -- Clicked open while expanded: once the island has faded out, fold it
        -- back to the pill so the next minimize starts from it.
        task.delay(0.15, function()
            if not self.Minimized then
                setMode("Compact", true)
            end
        end)
    end

    -- A notification while minimized: the island opens to show it for a few
    -- seconds, then folds back.
    self._islandActivity = function(opts)
        if not self.Minimized or not island.Visible then
            return
        end
        local color = NOTIFY_COLORS[opts.Type] or Theme.Accent
        activityTitle.Text = tostring(opts.Title or "Notification")
        activityTitle.TextColor3 = NOTIFY_COLORS[opts.Type] or Theme.Text
        activityBody.Text = tostring(opts.Content or "")
        activityBody.Visible = activityBody.Text ~= ""
        local icon = opts.Icon
        if icon == nil then
            icon = ({ Success = "circle-check", Warning = "triangle-alert", Error = "circle-x" })[opts.Type] or "bell"
        end
        applyIcon(activityIcon, icon)
        if not activityIcon:GetAttribute("CustomIcon") then
            activityIcon.ImageColor3 = color
        end
        activityChip.BackgroundColor3 = color
        activityLive = true
        activityToken += 1
        local token = activityToken
        task.defer(function()
            if activityToken == token and not hovered and not dragging then
                setMode("Activity")
                islandScale.Scale = 0.96
                tween(islandScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
            end
        end)
        task.delay(math.clamp(tonumber(opts.Duration) or 3, 1.5, 5), function()
            if activityToken == token then
                activityLive = false
                if self.Minimized and not hovered then
                    settleMode()
                end
            end
        end)
    end

    -- The meter dances while anything runs and lies flat when nothing does.
    local running = 0
    self:_listen("Render", function()
        if island.Visible and running > 0 and mode == "Compact" then
            local now = os.clock()
            for index, bar in ipairs(bars) do
                local wave = 0.5 + 0.5 * math.sin(now * (6 + index * 1.4) + index * 1.9)
                bar.Size = UDim2.fromOffset(3, math.floor(4 + wave * 11 + 0.5))
            end
        end
    end)

    -- Split, like iOS with two Live Activities: when toggles are running and
    -- a status is pinned, the pill keeps the status (logo leading, value
    -- trailing) and the running meter buds off into its own little circle
    -- beside it. One activity alone stays in the single pill.
    local pinValue = label({
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(1, -52, 0, 18),
        TextSize = 13,
        FontFace = Fonts.Bold,
        TextXAlignment = Enum.TextXAlignment.Right,
        RichText = true,
        TextTransparency = 1,
        Parent = compact,
    })
    local bubble = create("TextButton", {
        Name = "IslandBubble",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Color3.fromRGB(26, 26, 30),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 30,
        Parent = gui,
    })
    corner(bubble, UDim.new(1, 0))
    local split = create("NumberValue", { Value = 0 })
    local splitOn = false
    local pinnedLead = nil
    local function setSplit(on)
        if on == splitOn then
            return
        end
        splitOn = on
        barsHolder.Parent = on and bubble or meter
        barsHolder.AnchorPoint = on and Vector2.new(0.5, 0.5) or Vector2.new(0, 0)
        barsHolder.Position = on and UDim2.fromScale(0.5, 0.5) or UDim2.new()
        meter.Visible = not on
        tween(pinValue, { TextTransparency = on and 0 or 1 }, 0.2, Enum.EasingStyle.Quad)
        -- Buds off with a spring, and is drawn back in quicker.
        tween(split, { Value = on and 1 or 0 }, on and 0.55 or 0.3, on and Enum.EasingStyle.Back or Enum.EasingStyle.Quint)
        if on then
            islandScale.Scale = 0.96
            tween(islandScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
        end
    end
    self:_listen("Render", function()
        local t = split.Value * merge.Value
        local shown = island.Visible and t > 0.02 and island.GroupTransparency < 0.5
        bubble.Visible = shown
        if not shown then
            return
        end
        local origin = gui.AbsolutePosition
        local pos, size = island.AbsolutePosition - origin, island.AbsoluteSize
        local d = math.min(size.Y, Mini.Height)
        local gap = 6
        -- Buds off the side with room to spare: the right, or the left near
        -- the right edge of the screen.
        local right = pos.X + size.X + gap + d <= gui.AbsoluteSize.X
        local edge = right and pos.X + size.X or pos.X
        local dir = right and 1 or -1
        local inner = edge - dir * d * 0.6
        local outer = edge + dir * (gap + d / 2)
        local x = inner + (outer - inner) * t
        local scale = math.clamp(0.35 + 0.65 * t, 0, 1.2)
        -- Liquid: mid-flight the drop stretches along its path and thins,
        -- then rounds back into a circle as it settles.
        local stretch = math.sin(math.clamp(t, 0, 1) * math.pi)
        bubble.Position = UDim2.fromOffset(x, pos.Y + d / 2)
        bubble.Size = UDim2.fromOffset(d * scale * (1 + 0.4 * stretch), d * scale * (1 - 0.18 * stretch))
        bubble.BackgroundTransparency = island.GroupTransparency
    end)
    bubble.MouseButton1Click:Connect(function()
        if self.Minimized then
            self:Restore()
        end
    end)

    local cardRows = {}
    function self:_refreshMini()
        local count = 0
        for _, element in pairs(Library.Flags) do
            if element._type == "Toggle" and element.Value == true then
                count += 1
            end
        end
        if count ~= running then
            local rising = count > running
            running = count
            countLabel.Text = tostring(count)
            for _, bar in ipairs(bars) do
                tween(bar, { BackgroundColor3 = count > 0 and Theme.Accent or Theme.Muted }, 0.25)
                if count == 0 then
                    tween(bar, { Size = UDim2.fromOffset(3, 3) }, 0.25)
                end
            end
            -- A small bump, like a live activity updating.
            if rising and mode == "Compact" and island.Visible then
                islandScale.Scale = 1.06
                tween(islandScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
            end
        end
        bigCount.Text = tostring(count)
        local names = {}
        for _, element in pairs(Library.Flags) do
            if element._type == "Toggle" and element.Value == true and element._searchName ~= "" then
                table.insert(names, element._searchName)
            end
        end
        table.sort(names)
        local shownNames = {}
        for index = 1, math.min(#names, 3) do
            shownNames[index] = Library._rich(names[index])
        end
        local extra = #names - #shownNames
        runningNames.Text = '<font color="#8A8A93">Running </font>' .. table.concat(shownNames, '<font color="#8A8A93"> · </font>')
            .. (extra > 0 and string.format('<font color="#8A8A93">  +%d</font>', extra) or "")
        runningNames.Visible = #names > 0
        pinnedLead = nil
        for _, handle in ipairs(self._pinned) do
            if not handle._isShown or handle:_isShown() then
                pinnedLead = handle
                break
            end
        end
        if pinnedLead then
            local text = tostring(pinnedLead:Text() or "")
            -- A status with nothing to show yet doesn't take the pill.
            if text:gsub("<[^>]*>", ""):match("%S") then
                pinValue.Text = text
                local color = pinnedLead._shownColor and pinnedLead._shownColor() or Theme.Text
                -- Too dark to read on the black pill: fall back to text colour.
                local _, _, value = color:ToHSV()
                pinValue.TextColor3 = value < 0.35 and Theme.Text or color
            else
                pinnedLead = nil
            end
        end
        setSplit(running > 0 and pinnedLead ~= nil)
        -- The pill's own meter: the clock when idle or when the bars budded
        -- off without a status to keep, the bars and count otherwise.
        local barsHere = running > 0 and not splitOn
        idleDot.Visible = not barsHere
        idleLabel.Visible = not barsHere
        countLabel.Visible = barsHere
        barsHolder.Visible = running > 0
        meter.Visible = not splitOn
        miniTitle.Visible = not splitOn
        local key = typeof(self.Keybind) == "EnumItem" and keyName(self.Keybind)
        hint.Text = TOUCH and "Tap to open" or (key and ("Click or press " .. key .. " to open") or "Click to open")

        local list = {}
        for _, handle in ipairs(self._pinned) do
            if (not handle._isShown or handle:_isShown()) and #list < Mini.Pinned then
                table.insert(list, handle)
            end
        end
        rowsHolder.Visible = false
        for index = 1, math.max(#list, #cardRows) do
            local handle = list[index]
            local row = cardRows[index]
            if handle then
                if not row then
                    local frame = create("Frame", {
                        Size = UDim2.new(1, 0, 0, 18),
                        BackgroundTransparency = 1,
                        LayoutOrder = index,
                        Parent = rowsHolder,
                    })
                    row = {
                        Frame = frame,
                        Key = label({
                            Size = UDim2.new(0.5, -4, 1, 0),
                            TextSize = 12,
                            FontFace = Fonts.Regular,
                            TextColor3 = Theme.Muted,
                            RichText = true,
                            Parent = frame,
                        }),
                        Value = label({
                            AnchorPoint = Vector2.new(1, 0),
                            Position = UDim2.fromScale(1, 0),
                            Size = UDim2.new(0.5, -4, 1, 0),
                            TextSize = 12,
                            TextXAlignment = Enum.TextXAlignment.Right,
                            RichText = true,
                            Parent = frame,
                        }),
                    }
                    cardRows[index] = row
                end
                row.Frame.Visible = true
                row.Key.Text = Library._rich(handle.Name)
                row.Value.Text = handle:Text()
                -- Carries the status's own colour: its Color, or its tone
                -- for the tinted styles (badge, dot, bar).
                local color = handle._shownColor and handle._shownColor() or Theme.Text
                if row.Value.TextColor3 ~= color then
                    tween(row.Value, { TextColor3 = color }, 0.2)
                end
            elseif row then
                row.Frame.Visible = false
            end
        end
        -- Rows coming and going change the expanded height.
        if mode == "Expanded" and (hovered or self.IslandStyle == "Always Show") then
            task.defer(function()
                if mode == "Expanded" and (hovered or self.IslandStyle == "Always Show") and self.Minimized then
                    local size = shapeFor("Expanded")
                    if math.abs(size.Y - island.Size.Y.Offset) > 1 then
                        setMode("Expanded")
                    end
                end
            end)
        end
    end

    self.MiniBar = island
    self.Island = island
    return island
end

function Window:Minimize()
    if self.Minimized or not self._introDone or not self.Open or self._destroyed then
        return
    end
    self.Minimized = true
    self._minimizeGeneration = (self._minimizeGeneration or 0) + 1
    local generation = self._minimizeGeneration
    self:_closePopups()
    self:_refreshToggleButton()
    self:_refreshBackdrop()
    local bar = self:_buildMiniBar()
    self:_refreshMini()
    local gui = self.Gui

    -- Starts from whatever is on screen: the window, or a ghost still
    -- mid-flight if a restore was interrupted.
    local fromPosition = self.Root.AbsolutePosition - gui.AbsolutePosition
    local fromSize = self.Root.AbsoluteSize
    local fromAlpha = 1
    if self._ghost then
        fromPosition = self._ghost.AbsolutePosition - gui.AbsolutePosition
        fromSize = self._ghost.AbsoluteSize
        fromAlpha = self._ghost.BackgroundTransparency
    end

    -- 1. The ghost fades in over the window while it eases back a touch.
    local ghost, ghostStroke, ghostCorner = makeGhost(self, fromPosition, fromSize, Library._radius(10))
    ghost.BackgroundTransparency = fromAlpha
    ghostStroke.Transparency = fromAlpha
    tween(ghost, { BackgroundTransparency = 0 }, 0.11, Enum.EasingStyle.Quad)
    tween(ghostStroke, { Transparency = 0 }, 0.11, Enum.EasingStyle.Quad)
    tween(self.Scale, { Scale = (self._fitScale or 1) * 0.985 }, 0.11, Enum.EasingStyle.Quad)
    tween(self.Shadow, { ImageTransparency = 1 }, 0.2)
    bar.Visible = true
    bar.GroupTransparency = 1

    task.delay(0.11, function()
        if self._minimizeGeneration ~= generation or self._destroyed then
            return
        end
        -- 2. Covered by the ghost, the window is hidden and the ghost folds
        -- down into the island.
        self.Root.Visible = false
        self.Scale.Scale = self._fitScale or 1
        local target, size = self:_miniLand(fromPosition + fromSize / 2)
        morphGhost(ghost, ghostCorner, target, size, math.floor(size.Y / 2), 0.36)
        task.delay(0.3, function()
            if self._minimizeGeneration ~= generation or self._destroyed then
                return
            end
            -- 3. The island fades in on top as the ghost lands.
            self._miniScale.Scale = 0.9
            tween(self._miniScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Quint)
            tween(bar, { GroupTransparency = 0 }, 0.18, Enum.EasingStyle.Quad)
            dissolve(self, ghost, ghostStroke, 0.2)
            -- Always Show: once landed as the pill, swell open into the card.
            if self.IslandStyle == "Always Show" then
                task.delay(0.22, function()
                    if self._minimizeGeneration == generation and self._islandSettle then
                        self._islandSettle()
                    end
                end)
            end
        end)
    end)

    task.spawn(function()
        while self.Minimized and self._minimizeGeneration == generation and not self._destroyed do
            self:_refreshMini()
            task.wait(0.5)
        end
    end)
end

function Window:Restore()
    if not self.Minimized or self._destroyed then
        return
    end
    self.Minimized = false
    self._minimizeGeneration = (self._minimizeGeneration or 0) + 1
    local generation = self._minimizeGeneration
    self:_refreshToggleButton()
    self:_refreshBackdrop(true)
    local gui = self.Gui
    local bar = self.MiniBar
    local fit = self._fitScale or 1
    local size = Vector2.new(self.Root.Size.X.Offset, self.Root.Size.Y.Offset) * fit
    local centre = self.Root.AbsolutePosition + self.Root.AbsoluteSize / 2 - gui.AbsolutePosition
    local target = centre - size / 2

    -- Picks up from whatever is on screen: a ghost still mid-flight if
    -- minimize was interrupted, otherwise the island.
    local fromPosition, fromSize = target, size
    local fromAlpha = 1
    if self._ghost then
        fromPosition = self._ghost.AbsolutePosition - gui.AbsolutePosition
        fromSize = self._ghost.AbsoluteSize
        fromAlpha = self._ghost.BackgroundTransparency
    elseif bar and bar.Visible then
        fromPosition = self._miniOrb.AbsolutePosition - gui.AbsolutePosition
        fromSize = self._miniOrb.AbsoluteSize
    end
    if bar and bar.Visible then
        if self._miniUnhover then
            self._miniUnhover()
        end
        tween(bar, { GroupTransparency = 1 }, 0.12, Enum.EasingStyle.Quad)
        task.delay(0.12, function()
            if self._minimizeGeneration == generation then
                bar.Visible = false
            end
        end)
    end

    local ghost, ghostStroke, ghostCorner = makeGhost(self, fromPosition, fromSize, math.floor(math.min(fromSize.X, fromSize.Y) / 2))
    ghost.BackgroundTransparency = fromAlpha
    ghostStroke.Transparency = fromAlpha
    tween(ghost, { BackgroundTransparency = 0 }, 0.1, Enum.EasingStyle.Quad)
    tween(ghostStroke, { Transparency = 0 }, 0.1, Enum.EasingStyle.Quad)
    morphGhost(ghost, ghostCorner, target, size, Library._radius(10), 0.4)
    tween(self.Shadow, { ImageTransparency = self._shadowRest }, 0.45)

    -- Shown under the ghost a little early so its first frames are drawn
    -- while still covered, then the ghost clears to reveal it.
    task.delay(0.3, function()
        if self._minimizeGeneration ~= generation or self._destroyed then
            return
        end
        self.Scale.Scale = fit
        self.BodyStroke.Transparency = 0
        self.Root.Visible = true
    end)
    task.delay(0.4, function()
        if self._ghost == ghost and self._minimizeGeneration == generation then
            dissolve(self, ghost, ghostStroke, 0.22)
        end
    end)
end

-- The minimized island can be dragged anywhere; its spot is remembered in
-- the config folder. These lock it in place or send it back to the top.
function Window:SetIslandDraggable(enabled)
    self._islandLocked = enabled == false
end

function Window:ResetIslandPosition()
    self._islandAnchor = nil
    if self._islandReset then
        self._islandReset()
    end
    self:_writeConfigSettings({ IslandPosition = false })
end

function Window:SetMinimized(minimized)
    if minimized then
        self:Minimize()
    else
        self:Restore()
    end
end

function Window:Toggle(open)
    if not self._introDone then
        return
    end
    if self.Minimized then
        if open ~= false then
            self:Restore()
        end
        return
    end
    if open == nil then
        open = not self.Open
    end
    if open == self.Open then
        return
    end
    self.Open = open
    self:_refreshToggleButton()
    self:_refreshBackdrop(open)
    -- Like minimize, a plain ghost panel carries the scale and fade. The body
    -- is never reparented into the fader or rescaled, which relaid out the
    -- whole window and stuttered on the keypress frame.
    self._minimizeGeneration = (self._minimizeGeneration or 0) + 1
    local generation = self._minimizeGeneration
    local gui = self.Gui
    local fit = self._fitScale or 1
    local size = Vector2.new(self.Root.Size.X.Offset, self.Root.Size.Y.Offset) * fit
    local centre = self.Root.AbsolutePosition + self.Root.AbsoluteSize / 2 - gui.AbsolutePosition
    local shrunk = size * 0.94
    local fromPosition, fromSize, fromAlpha
    if self._ghost then
        fromPosition = self._ghost.AbsolutePosition - gui.AbsolutePosition
        fromSize = self._ghost.AbsoluteSize
        fromAlpha = self._ghost.BackgroundTransparency
    end
    if open then
        local ghost, ghostStroke, ghostCorner = makeGhost(self, fromPosition or centre - shrunk / 2, fromSize or shrunk, Library._radius(10))
        ghost.BackgroundTransparency = fromAlpha or 1
        ghostStroke.Transparency = fromAlpha or 1
        tween(ghost, { BackgroundTransparency = 0 }, 0.12, Enum.EasingStyle.Quad)
        tween(ghostStroke, { Transparency = 0 }, 0.12, Enum.EasingStyle.Quad)
        morphGhost(ghost, ghostCorner, centre - size / 2, size, Library._radius(10), 0.3)
        tween(self.Shadow, { ImageTransparency = self._shadowRest }, 0.3)
        -- Shown under the ghost once it covers the spot, then revealed.
        task.delay(0.2, function()
            if self._minimizeGeneration ~= generation or self._destroyed then
                return
            end
            self.Scale.Scale = fit
            self.BodyStroke.Transparency = 0
            self.Root.Visible = true
        end)
        task.delay(0.3, function()
            if self._ghost == ghost and self._minimizeGeneration == generation then
                dissolve(self, ghost, ghostStroke, 0.18)
            end
        end)
    else
        self:_closePopups()
        local position = fromPosition or self.Root.AbsolutePosition - gui.AbsolutePosition
        local current = fromSize or self.Root.AbsoluteSize
        local ghost, ghostStroke, ghostCorner = makeGhost(self, position, current, Library._radius(10))
        ghost.BackgroundTransparency = fromAlpha or 1
        ghostStroke.Transparency = fromAlpha or 1
        tween(ghost, { BackgroundTransparency = 0 }, 0.08, Enum.EasingStyle.Quad)
        tween(ghostStroke, { Transparency = 0 }, 0.08, Enum.EasingStyle.Quad)
        tween(self.Shadow, { ImageTransparency = 1 }, 0.16)
        task.delay(0.08, function()
            if self._minimizeGeneration ~= generation or self._destroyed then
                return
            end
            self.Root.Visible = false
            morphGhost(ghost, ghostCorner, centre - shrunk / 2, shrunk, Library._radius(10), 0.2)
            dissolve(self, ghost, ghostStroke, 0.16)
        end)
    end
end

function Window:SetKeepOnScreen(enabled)
    self.KeepOnScreen = enabled ~= false
    if self.KeepOnScreen then
        self:_clampToScreen()
    end
end

function Window:SetKeybind(keyCode)
    self.Keybind = keyCode
    if self._keyChipLabel then
        self._keyChipLabel.Text = keyName(keyCode)
    end
end

function Window:Notify(opts)
    opts = normalize(opts, { Text = "Content", Message = "Content", Image = "Icon" })
    if self.Minimized and self._islandActivity then
        self._islandActivity(opts)
    end
    local duration = opts.Duration or 4
    local titleColor = NOTIFY_COLORS[opts.Type] or Theme.Text

    self._notifyOrder = self._notifyOrder + 1
    local outer = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        LayoutOrder = self._notifyOrder,
        Parent = self.NotifyHolder,
    })
    local slide = create("Frame", {
        Position = UDim2.fromOffset(320, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = outer,
    })
    local shadow = create("ImageLabel", {
        Position = UDim2.fromOffset(-20, -20),
        Size = UDim2.new(1, 40, 1, 40),
        BackgroundTransparency = 1,
        Image = Assets.Shadow,
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 0,
        Parent = slide,
    })
    local toast = create("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Parent = slide,
    })
    corner(toast, UDim.new(0, 10))
    local toastStroke = stroke(toast, Theme.Stroke)
    edgeHighlight(toast)
    glow(toast, UDim2.fromOffset(260, 120), UDim2.new(1, -10, 0, -10), 0.86, 90)

    local inner = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = toast,
    })
    padding(inner, 16, 16, 14, 24)

    local titleOffset = 0
    if opts.Icon then
        glowIcon(inner, opts.Icon, titleColor == Theme.Text and Theme.Accent or titleColor, UDim2.new(0, 0, 0, 8))
        titleOffset = 24
    end
    label({
        Position = UDim2.fromOffset(titleOffset, 0),
        Size = UDim2.new(1, -28 - titleOffset, 0, 16),
        Text = opts.Title or "Notification",
        TextSize = 14,
        TextColor3 = titleColor,
        Parent = inner,
    })
    local closeButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 6, 0, -5),
        Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = Theme.Muted,
        TextSize = 22,
        FontFace = Fonts.Bold,
        AutoButtonColor = false,
        Parent = inner,
    })
    closeButton.MouseEnter:Connect(function()
        tween(closeButton, { TextColor3 = Theme.Text }, 0.15)
    end)
    closeButton.MouseLeave:Connect(function()
        tween(closeButton, { TextColor3 = Theme.Muted }, 0.2)
    end)
    if opts.Content then
        label({
            Position = UDim2.fromOffset(titleOffset, 21),
            Size = UDim2.new(1, -titleOffset, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = opts.Content,
            TextSize = 13,
            FontFace = Fonts.Regular,
            TextColor3 = Theme.Muted,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = inner,
        })
    end

    local track = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 16, 1, -8),
        Size = UDim2.new(1, -32, 0, 3),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Parent = toast,
    })
    corner(track, UDim.new(1, 0))
    local progress = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(progress, UDim.new(1, 0))

    task.defer(function()
        if outer.Parent then
            tween(outer, { Size = UDim2.new(1, 0, 0, toast.AbsoluteSize.Y) }, 0.3, Enum.EasingStyle.Quint)
        end
    end)
    tween(slide, { Position = UDim2.fromOffset(0, 0) }, 0.5, Enum.EasingStyle.Back)
    tween(toast, { GroupTransparency = 0 }, 0.3)
    tween(shadow, { ImageTransparency = 0.6 }, 0.4)
    tween(progress, { Size = UDim2.fromScale(0, 1) }, duration, Enum.EasingStyle.Linear)

    local dismissed = false
    local function dismiss()
        if dismissed then
            return
        end
        dismissed = true
        for index, entry in ipairs(self._toasts) do
            if entry == dismiss then
                table.remove(self._toasts, index)
                break
            end
        end
        tween(slide, { Position = UDim2.fromOffset(320, 0) }, 0.3, Enum.EasingStyle.Quint)
        tween(toast, { GroupTransparency = 1 }, 0.2)
        tween(toastStroke, { Transparency = 1 }, 0.15)
        tween(shadow, { ImageTransparency = 1 }, 0.2)
        task.delay(0.22, function()
            outer.ClipsDescendants = true
            tween(outer, { Size = UDim2.new(1, 0, 0, -4) }, 0.22, Enum.EasingStyle.Quint)
            task.delay(0.24, function()
                outer:Destroy()
            end)
        end)
    end

    task.delay(duration, dismiss)
    closeButton.MouseButton1Click:Connect(dismiss)

    table.insert(self._toasts, dismiss)
    while #self._toasts > self.MaxNotifications do
        local oldest = table.remove(self._toasts, 1)
        oldest()
    end

    return { Dismiss = dismiss }
end

function Window:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    for index, entry in ipairs(Library.Windows) do
        if entry == self then
            table.remove(Library.Windows, index)
            break
        end
    end
    for _, connection in ipairs(self._connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    self._connections = {}
    self._inputListeners = { Began = {}, Changed = {}, Ended = {}, Render = {} }
    self._frameSteps = {}

    local gui = self.Gui
    local removed = false
    local function remove()
        if removed then
            return
        end
        removed = true
        if not pcall(gui.Destroy, gui) then
            pcall(function()
                gui.Enabled = false
            end)
        end
    end
    -- The fade out is decoration only. Input is already cut at this point, so
    -- if any of it fails the gui is removed straight away instead of being
    -- left frozen on screen.
    local ok, err = pcall(function()
        if self._dialog then
            self._dialog.Close()
        end
        self:_closePopups()
        local fit = self._fitScale or 1
        tween(self.Scale, { Scale = fit * 0.92 }, 0.22, Enum.EasingStyle.Quint)
        self:_fade(1, 0.2)
        tween(self.BodyStroke, { Transparency = 1 }, 0.12)
        tween(self.Shadow, { ImageTransparency = 1 }, 0.2)
        if self.MiniBar and self.MiniBar.Visible then
            tween(self.MiniBar, { GroupTransparency = 1 }, 0.18)
        end
        if self._backdrop then
            -- Frame steps are already cut, so the weather stops where it is.
            self._weatherField.Visible = false
            tween(self._backdropTintFrame, { BackgroundTransparency = 1 }, 0.2)
            tween(self._backdropHeat, { BackgroundTransparency = 1 }, 0.2)
        end
        for _, button in ipairs({ self.ToggleButton, self.OpenButton }) do
            if typeof(button) == "Instance" and button:IsA("GuiObject") then
                tween(button, { Size = UDim2.fromOffset(0, 0) }, 0.2, Enum.EasingStyle.Quint)
            end
        end
    end)
    if not ok then
        warn("[AirFlow] unload animation failed, removing the window directly: " .. tostring(err))
        remove()
        return
    end
    task.delay(0.24, remove)
end

Window.Unload = Window.Destroy

-- Unloads every window the library created.
function Library:Destroy()
    for index = #Library.Windows, 1, -1 do
        local window = Library.Windows[index]
        if window then
            window:Destroy()
        end
    end
end

Library.Unload = Library.Destroy

-- A script thread that yielded inside an engine call (InvokeServer and the
-- like) resumes at game identity and can no longer touch the GUI in CoreGui.
-- Every public call checks for that: it raises the thread back to the identity
-- the library loaded at, or, when the executor cannot, runs the call on a
-- trusted Heartbeat thread and waits for its result.
local getIdentity = getthreadidentity or getidentity or get_thread_identity or (syn and syn.get_thread_identity)
local setIdentity = setthreadidentity or setidentity or set_thread_identity or (syn and syn.set_thread_identity)
local loadIdentity = nil
if getIdentity then
    local ok, identity = pcall(getIdentity)
    if ok and type(identity) == "number" then
        loadIdentity = identity
    end
end

local function threadLowered()
    local window = Library.Windows[#Library.Windows]
    local probe = window and window.Gui
    if typeof(probe) ~= "Instance" then
        return false
    end
    return not pcall(function()
        return probe.Name
    end)
end

local trustedQueue = {}
RunService.Heartbeat:Connect(function()
    if #trustedQueue == 0 then
        return
    end
    local queue = trustedQueue
    trustedQueue = {}
    for _, job in ipairs(queue) do
        job()
    end
end)

local function runTrusted(fn, ...)
    local args = table.pack(...)
    local result = nil
    table.insert(trustedQueue, function()
        result = table.pack(pcall(fn, table.unpack(args, 1, args.n)))
    end)
    while result == nil do
        task.wait()
    end
    if not result[1] then
        error(result[2], 0)
    end
    return table.unpack(result, 2, result.n)
end

local guardedObjects = setmetatable({}, { __mode = "k" })
local guardObject

local function guarded(fn)
    return function(...)
        if threadLowered() then
            if setIdentity then
                pcall(setIdentity, loadIdentity or 8)
            end
            if threadLowered() then
                return guardObject(runTrusted(fn, ...))
            end
        end
        return guardObject(fn(...))
    end
end

-- Elements carry their methods as closures, so each returned object gets its
-- public functions wrapped too; windows and tabs share the guarded metatables.
function guardObject(...)
    for index = 1, select("#", ...) do
        local object = select(index, ...)
        if type(object) == "table" and not guardedObjects[object] then
            local meta = getmetatable(object)
            if meta ~= Window and meta ~= Tab then
                guardedObjects[object] = true
                for key, value in pairs(object) do
                    if type(key) == "string" and type(value) == "function" and key:sub(1, 1) ~= "_" then
                        object[key] = guarded(value)
                    elseif type(key) == "number" and type(value) == "table" then
                        guardObject(value)
                    end
                end
            end
        end
    end
    return ...
end

for _, class in ipairs({ Library, Window, Tab }) do
    for key, value in pairs(class) do
        if type(key) == "string" and type(value) == "function" and key:sub(1, 1) ~= "_" then
            class[key] = guarded(value)
        end
    end
end

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
    CastDelay = 1,
    AutoReel = false,
    AutoMiniGame = false,
    BossMode = "Normal",
    AutoBoss = false,
    AutoSecretBoss = false,
    AutoSkill = false,
    SkillOrder = {"Z", "X", "C", "V"},
    AutoSell = false,
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
    AutoFarmIsland = false,
    SelectedFarmIsland = "Beginning Isle",
    AutoTicketQuest = false,
    TicketQuestMode = "Hard",
    AutoZengTianguoQuest = false,
    AutoEquipBestBait = false
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
    local allow = true
    pcall(function()
        if isfile then
            if isfile("UzexHub/HeavyweighFishingConfig.json") then
                local dec = HttpService:JSONDecode(readfile("UzexHub/HeavyweighFishingConfig.json"))
                allow = (type(dec) == "table" and dec.AutoExecute == true)
            else
                allow = false
            end
        end
    end)
    if allow then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/NoahTyrant/StarCrow/refs/heads/main/Loader"))()
    end
end)
]]

local function QueueAutoExecute()
    if not Config.AutoExecute or autoExecQueued or not queueTeleport then return end
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

local lastAfkTick = os.clock()

LocalPlayer.Idled:Connect(function()
    if not Config.AntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

task.spawn(function()
    while true do
        task.wait(1)
        if Config.AntiAFK then
            local now = os.clock()
            if now - lastAfkTick >= 600 then
                lastAfkTick = now
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
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

if getconnections then
    for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
        if conn.Disable then
            conn:Disable()
        elseif conn.Disconnect then
            conn:Disconnect()
        end
    end
end

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

local function IsGameAllowingSkill(char)
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

local function IsSkillSlotAvailable(char, key)
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

local function IsSkillOnCooldown(char, key)
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

local function IsSkillKeyReady(char, key)
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

local function LockFishingBar()
    if isLockingBar then return end
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

local function TriggerGuiButton(btn)
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

local function GetModelPart(obj)
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

local function FindBossTarget(wantSecret)
    local npcFolder = workspace:FindFirstChild("NPC")
    local bossFolder = npcFolder and npcFolder:FindFirstChild("Boss")

    if bossFolder then
        for _, boss in ipairs(bossFolder:GetChildren()) do
            local part = GetModelPart(boss)
            if part then
                local isSec = IsSecretBossEntity(boss)
                if wantSecret and isSec then
                    return boss, part
                elseif not wantSecret and not isSec then
                    return boss, part
                end
            end
        end
    end

    if not wantSecret then
        local wsBoss = workspace:FindFirstChild("Boss") or workspace:FindFirstChild("BossZone")
        if wsBoss then
            local part = GetModelPart(wsBoss)
            if part then
                return wsBoss, part
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

local function GetButtonLabelText(obj)
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

local function FindBossMenuFrame()
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

local function CheckBossStatusOnToggle(wantSecret)
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
        task.wait(0.15)
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
                if ev:IsA("RemoteEvent") then
                    ev:FireServer(targetMode)
                    if bossName then
                        ev:FireServer(bossName, targetMode)
                        ev:FireServer(targetMode, bossName)
                    end
                elseif ev:IsA("RemoteFunction") then
                    ev:InvokeServer(targetMode)
                    if bossName then
                        ev:InvokeServer(bossName, targetMode)
                        ev:InvokeServer(targetMode, bossName)
                    end
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
    while task.wait(0.08) do
        local now = os.clock()
        RefreshGuiCache()
        local isMinigame = FishingGui and FishingGui.Visible or false
        if wasMinigameActive and not isMinigame then
            lastMinigameEndTick = now
        end
        wasMinigameActive = isMinigame
        local activeReel = Config.AutoReel or Config.AutoMiniGame or Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland
        local activeCast = Config.AutoCast or Config.AutoFarmIsland
        local activeSkill = Config.AutoSkill or Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland

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
                            lastCastTry = now
                            pcall(function()
                                ToggleHotbar:InvokeServer("1")
                            end)
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
    if (Config.AutoMiniGame or Config.AutoReel or Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland) and remote then
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
    if (Config.AutoMiniGame or Config.AutoReel or Config.AutoBoss or Config.AutoSecretBoss or Config.AutoFarmIsland) and remote then
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

local function clearPlayerESP()
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

task.spawn(function()
    while task.wait(0.8) do
        if Config.AutoSell then
            local delaySec = math.clamp(tonumber(Config.SellDelay) or 1, 1, 10) * 60
            local now = os.clock()
            if now - lastSellTime >= delaySec then
                lastSellTime = now
                pcall(function()
                    SellFish:FireServer("All")
                end)
            end
        end
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

local lastTicketQuestTime = 0
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


local StepAutoEquipBestBait
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
                        Title = "Auto Equip Bait",
                        Content = "No bait found in inventory",
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
                Title = "Auto Equip Bait",
                Content = "Equipped " .. bestBait .. " - Luck " .. bestLuck .. "%",
                Duration = 3
            })
        end)
    end

    LocalPlayer.CharacterAdded:Connect(function()
        lastEquipTime = 0
    end)
end

task.spawn(function()
    while task.wait(1) do
        if Config.AutoTicketQuest then
            StepSmartTicketQuest()
        end
        if Config.AutoZengTianguoQuest then
            StepSmartZengTianguoQuest()
        end
        if Config.AutoEquipBestBait then
            StepAutoEquipBestBait()
        end
    end
end)

local function GetBuyableBaits()
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
        pcall(function()
            Library:Notify({
                Title = "Teleport NPC",
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
                Title = "Teleport Player",
                Content = "Player " .. tostring(targetName) .. " not found!",
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
                Title = "Teleport Player",
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

-- Native window from the supplied UI library. The existing JSON config
-- remains authoritative; the library's example/config-manager is not loaded.
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
        Name = "Home",
        Title = "Uzex Hub",
        Desc = "Heavyweigh Fishing",
        Discord = DISCORD_INVITE,
        DiscordTitle = "Uzex Hub Discord",
        DiscordIcon = "message-circle",
        Features = false,
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
-- go through the new library, including restoring a minimized window.
do
    local LogoGui = Instance.new("ScreenGui")
    LogoGui.Name = "UzexHubLogoGui"
    LogoGui.ResetOnSpawn = false
    LogoGui.DisplayOrder = 10000
    pcall(function() LogoGui.Parent = game:GetService("CoreGui") end)
    if not LogoGui.Parent then LogoGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local LogoFrame = Instance.new("Frame")
    LogoFrame.Size = UDim2.new(0, 46, 0, 46)
    LogoFrame.Position = UDim2.new(0, 8, 0.5, -23)
    LogoFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    LogoFrame.BorderSizePixel = 0
    LogoFrame.Parent = LogoGui
    Instance.new("UICorner", LogoFrame).CornerRadius = UDim.new(0.2, 0)

    local logoStroke = Instance.new("UIStroke", LogoFrame)
    logoStroke.Thickness = 1.8
    logoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local logoGrad = Instance.new("UIGradient", logoStroke)
    logoGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 70, 70)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(244, 244, 244)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 70, 70)),
    })
    task.spawn(function() TweenService:Create(logoGrad, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 180}):Play() end)

    local LogoImg = Instance.new("ImageLabel")
    LogoImg.Size = UDim2.new(1, -6, 1, -6)
    LogoImg.Position = UDim2.new(0, 3, 0, 3)
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

    do
        local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
        LogoBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragInput, dragStart, startPos = true, input, input.Position, LogoFrame.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                LogoFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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
    LogoBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            clickStartPos = Vector2.new(input.Position.X, input.Position.Y)
        end
    end)
    LogoBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local dist = (Vector2.new(input.Position.X, input.Position.Y) - clickStartPos).Magnitude
            local now = tick()
            if dist < 10 and now - lastToggleTime >= 0.3 then
                lastToggleTime = now
                Window:Toggle()
            end
        end
    end)
    Window.Gui.Destroying:Connect(function()
        LogoGui:Destroy()
    end)
end

local Tabs = {
    Main = Window:CreateTab({ Name = "Main", Icon = "home" }),
    Player = Window:CreateTab({ Name = "Player", Icon = "user" }),
    Teleport = Window:CreateTab({ Name = "Teleport", Icon = "map-pin" }),
    Shop = Window:CreateTab({ Name = "Shop", Icon = "shopping-cart" }),
    ESP = Window:CreateTab({ Name = "ESP", Icon = "eye" }),
    Misc = Window:CreateTab({ Name = "Misc", Icon = "layers" }),
    Settings = Window:CreateTab({ Name = "Settings", Icon = "settings" })
}

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

Tabs.Main:CreateSection("Auto Ticket Quest")

Tabs.Main:CreateToggle({
    Flag = "AutoTicketQuestToggle",
    Name = "Auto Claim Quest Ticket",
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
    Name = "Quest Mode",
    Options = {"Hard", "Easy"},
    CurrentOption = Config.TicketQuestMode or "Hard",
    MultipleOptions = false,
    AllowNone = false,
    Callback = function(Value)
        Config.TicketQuestMode = Value or "Hard"
        SaveConfig()
    end
})

Tabs.Main:CreateSection("Zeng Tianguo Quest")

Tabs.Main:CreateToggle({
    Flag = "AutoZengTianguoQuestToggle",
    Name = "Auto Claim Zeng Tianguo Quest",
    CurrentValue = Config.AutoZengTianguoQuest,
    Callback = function(Value)
        Config.AutoZengTianguoQuest = Value
        SaveConfig()
    end
})

Tabs.Main:CreateSection("Auto Farm Fish")

do
    local farmIslandList = GetIslandList()
    if (Config.SelectedFarmIsland == "" or not table.find(farmIslandList, Config.SelectedFarmIsland)) and #farmIslandList > 0 then
        Config.SelectedFarmIsland = farmIslandList[1]
    end

    Tabs.Main:CreateDropdown({
        Flag = "SelectIslandFarmDropdown",
        Name = "Select Island",
        Options = farmIslandList,
        CurrentOption = Config.SelectedFarmIsland ~= "" and Config.SelectedFarmIsland or farmIslandList[1],
        MultipleOptions = false,
        AllowNone = false,
        Callback = function(Value)
            Config.SelectedFarmIsland = Value or ""
            SaveConfig()
            if Config.AutoFarmIsland then
                StepAutoFarmIsland(LocalPlayer.Character)
            end
        end
    })
end

Tabs.Main:CreateToggle({
    Flag = "AutoFarmIslandToggle",
    Name = "Auto Farm",
    CurrentValue = Config.AutoFarmIsland,
    Callback = function(Value)
        Config.AutoFarmIsland = Value
        SaveConfig()
        if Value then
            StepAutoFarmIsland(LocalPlayer.Character)
            if LocalPlayer.Character then
                ApplyAntiConfuse(LocalPlayer.Character)
            end
        end
    end
})

Tabs.Main:CreateToggle({
    Flag = "AutoExecuteToggle",
    Name = "Auto Execute",
    CurrentValue = Config.AutoExecute,
    Callback = function(Value)
        Config.AutoExecute = Value
        SaveConfig()
        if Value then
            QueueAutoExecute()
        end
    end
})

Tabs.Main:CreateSection("Fishing")

Tabs.Main:CreateToggle({
    Flag = "AutoCastToggle",
    Name = "Auto Cast",
    CurrentValue = Config.AutoCast,
    Callback = function(Value)
        Config.AutoCast = Value
        SaveConfig()
    end
})

Tabs.Main:CreateDropdown({
    Flag = "AutoCastMethodDropdown",
    Name = "Cast Method",
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
    Name = "Cast Delay",
    CurrentValue = Config.CastDelay or 1,
    Range = {1, 10},
    Increment = 0.1,
    Callback = function(Value)
        Config.CastDelay = Value
        SaveConfig()
    end
})

Tabs.Main:CreateToggle({
    Flag = "AutoReelToggle",
    Name = "Auto Reel",
    CurrentValue = Config.AutoReel,
    Callback = function(Value)
        Config.AutoReel = Value
        SaveConfig()
    end
})

Tabs.Main:CreateToggle({
    Flag = "AutoEquipBestBaitToggle",
    Name = "Auto Equip Best Bait",
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


Tabs.Main:CreateSection("Skill")

Tabs.Main:CreateToggle({
    Flag = "AutoSkillToggle",
    Name = "Auto Skill",
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
        Name = "Select Skill",
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
        Name = "Select Boss Mode",
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
    Name = "Auto Enzo",
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
    Name = "Auto Long DiaoHai",
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
    Name = "Auto Mini Game",
    CurrentValue = Config.AutoMiniGame,
    Callback = function(Value)
        Config.AutoMiniGame = Value
        if Value and LocalPlayer.Character then
            ApplyAntiConfuse(LocalPlayer.Character)
        end
        SaveConfig()
    end
})

Tabs.Main:CreateSection("Position")

Tabs.Main:CreateButton({
    Name = "Save Position",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = (char and char:FindFirstChild("HumanoidRootPart")) or cachedHrp
        if hrp then
            Config.SavedPos = {hrp.CFrame:GetComponents()}
            SaveConfig()
            pcall(function()
                Library:Notify({
                    Title = "Position",
                    Content = "Saved Position!",
                    Duration = 3
                })
            end)
        end
    end
})

Tabs.Main:CreateToggle({
    Flag = "AutoTPPosToggle",
    Name = "Auto TP Position",
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
    Name = "Delete Position",
    Callback = function()
        Config.SavedPos = false
        SaveConfig()
        pcall(function()
            Library:Notify({
                Title = "Position",
                Content = "Deleted Position!",
                Duration = 3
            })
        end)
    end
})

Tabs.Player:CreateSection("Movement")

Tabs.Player:CreateToggle({
    Flag = "LoopSpeedToggle",
    Name = "Walk Speed",
    CurrentValue = Config.LoopSpeedEnabled,
    Callback = function(Value)
        Config.LoopSpeedEnabled = Value
        SaveConfig()
    end
})

Tabs.Player:CreateSlider({
    Flag = "WalkSpeedSlider",
    Name = "Speed",
    CurrentValue = Config.WalkSpeed,
    Range = {16, 250},
    Increment = 1,
    Callback = function(Value)
        Config.WalkSpeed = Value
        SaveConfig()
    end
})

FlyToggleObj = Tabs.Player:CreateToggle({
    Flag = "FlyToggle",
    Name = "Fly",
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

Tabs.Player:CreateSlider({
    Flag = "FlySpeedSlider",
    Name = "Fly Speed",
    CurrentValue = Config.FlySpeed,
    Range = {1, 20},
    Increment = 0.1,
    Callback = function(Value)
        Config.FlySpeed = Value
        SaveConfig()
    end
})

NoclipToggleObj = Tabs.Player:CreateToggle({
    Flag = "NoclipToggle",
    Name = "Noclip",
    CurrentValue = Config.NoclipEnabled,
    Callback = function(Value)
        Config.NoclipEnabled = Value
        SaveConfig()
    end
})

Tabs.Player:CreateToggle({
    Flag = "InfJumpToggle",
    Name = "Infinite Jump",
    CurrentValue = Config.InfJumpEnabled,
    Callback = function(Value)
        Config.InfJumpEnabled = Value
        SaveConfig()
    end
})

Tabs.Teleport:CreateSection("Island")

do
    local islandList = GetIslandList()
    if (Config.SelectedIsland == "" or not table.find(islandList, Config.SelectedIsland)) and #islandList > 0 then
        Config.SelectedIsland = islandList[1]
    end

    Tabs.Teleport:CreateDropdown({
        Flag = "SelectIslandDropdown",
        Name = "Select Island",
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
    Name = "Teleport To Island",
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
        Name = "Select NPC",
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
        Name = "Teleport To NPC",
        Callback = function()
            local chosen = (NPCDropdown and NPCDropdown:Get()) or Config.SelectedNPC
            TeleportToNPC(chosen)
        end
    })
end

Tabs.Teleport:CreateSection("Player")

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
        Name = "Select Player",
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
        Name = "Teleport To Player",
        Callback = function()
            local chosen = (PlayerDropdown and PlayerDropdown:Get()) or Config.SelectedPlayer
            if chosen and chosen ~= "None" then
                TeleportToPlayer(chosen)
            end
        end
    })
end

Tabs.Shop:CreateSection("Selling")

Tabs.Shop:CreateToggle({
    Flag = "AutoSellToggle",
    Name = "Auto Sell All",
    CurrentValue = Config.AutoSell,
    Callback = function(Value)
        Config.AutoSell = Value
        if not Value then
            lastSellTime = 0
        end
        SaveConfig()
    end
})

Tabs.Shop:CreateInput({
    Flag = "AutoSellDelayInput",
    Name = "Sell Delay Min",
    CurrentValue = tostring(Config.SellDelay or 1),
    Numeric = true,
    Finished = false,
    Placeholder = "1",
    Callback = function(Value)
        Config.SellDelay = math.clamp(math.floor(tonumber(Value) or 1), 1, 60)
        SaveConfig()
    end
})

Tabs.Shop:CreateButton({
    Name = "Sell All Fish",
    Callback = function()
        SellFish:FireServer("All")
    end
})

Tabs.Shop:CreateButton({
    Name = "Sell One Fish",
    Callback = function()
        SellFish:FireServer("One")
    end
})

Tabs.Shop:CreateSection("Buy Bait")

do
    local buyBaitList = GetBuyableBaits()
    if Config.SelectedBuyBait == "" and #buyBaitList > 0 then
        Config.SelectedBuyBait = buyBaitList[1]
    end

    Tabs.Shop:CreateDropdown({
        Flag = "SelectBuyBaitDropdown",
        Name = "Select Bait",
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
    Name = "Buy Amount",
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
    Name = "Buy Delay Min",
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
    Name = "Auto Buy Bait",
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
    Name = "Buy Bait",
    Callback = function()
        DoBuyBait(Config.SelectedBuyBait, Config.BuyBaitAmount)
    end
})

Tabs.Shop:CreateSection("Craft Bait")

do
    local baitList = GetCraftableBaits()
    if Config.SelectedBait == "" and #baitList > 0 then
        Config.SelectedBait = baitList[1]
    end

    Tabs.Shop:CreateDropdown({
        Flag = "SelectBaitDropdown",
        Name = "Select Bait",
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
    Name = "Craft Amount",
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
    Name = "Auto Craft Bait",
    CurrentValue = Config.AutoCraftBait,
    Callback = function(Value)
        Config.AutoCraftBait = Value
        SaveConfig()
    end
})

Tabs.Shop:CreateButton({
    Name = "Craft Bait",
    Callback = function()
        if Config.SelectedBait ~= "" then
            CraftBaitEvent:FireServer(Config.SelectedBait, math.max(1, math.floor(tonumber(Config.BaitAmount) or 1)))
        end
    end
})

Tabs.Shop:CreateSection("Craft Rod")

do
    local rodList = GetCraftableRods()
    if Config.SelectedRod == "" and #rodList > 0 then
        Config.SelectedRod = rodList[1]
    end

    Tabs.Shop:CreateDropdown({
        Flag = "SelectRodDropdown",
        Name = "Select Rod",
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
    Name = "Auto Craft Rod",
    CurrentValue = Config.AutoCraftRod,
    Callback = function(Value)
        Config.AutoCraftRod = Value
        SaveConfig()
    end
})

Tabs.Shop:CreateButton({
    Name = "Craft Rod",
    Callback = function()
        if Config.SelectedRod ~= "" then
            CraftRodEvent:FireServer(Config.SelectedRod)
        end
    end
})

Tabs.ESP:CreateToggle({
    Flag = "ESPPlayers",
    Name = "ESP Players",
    CurrentValue = Config.ESPEnabled,
    Callback = function(Value)
        Config.ESPEnabled = Value
        SaveConfig()
        if not Value then
            clearPlayerESP()
        end
    end
})

Tabs.Misc:CreateSection("Visual")

Tabs.Misc:CreateToggle({
    Flag = "AntiAFKToggle",
    Name = "Anti AFK",
    CurrentValue = Config.AntiAFK,
    Callback = function(Value)
        Config.AntiAFK = Value
        SaveConfig()
    end
})

Tabs.Misc:CreateToggle({
    Flag = "FullBrightToggle",
    Name = "FullBright",
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
    Name = "No Fog",
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

Tabs.Misc:CreateSection("Codes")

Tabs.Misc:CreateButton({
    Name = "Redeem All Codes",
    Callback = function()
        RedeemAllCodes()
    end
})

Tabs.Misc:CreateSection("Remote Menus")

Tabs.Misc:CreateButton({
    Name = "Open Skill Upgrade",
    Callback = function()
        local state = OpenMenuFrameRemotely("SkillUpgrade")
        Library:Notify({
            Title = "Remote UI",
            Content = state and "Opened Skill Upgrade" or "Closed Skill Upgrade",
            Duration = 2
        })
    end
})

Tabs.Misc:CreateButton({
    Name = "Open Learn Skill",
    Callback = function()
        local state = OpenMenuFrameRemotely("LearnSkill")
        Library:Notify({
            Title = "Remote UI",
            Content = state and "Opened Learn Skill" or "Closed Learn Skill",
            Duration = 2
        })
    end
})

Tabs.Misc:CreateButton({
    Name = "Open Exchange UI",
    Callback = function()
        local state = OpenMenuFrameRemotely("Exchange")
        Library:Notify({
            Title = "Remote UI",
            Content = state and "Opened Item Exchange" or "Closed Item Exchange",
            Duration = 2
        })
    end
})

Tabs.Misc:CreateButton({
    Name = "Open Trait",
    Callback = function()
        local state = OpenMenuFrameRemotely("Trait")
        Library:Notify({
            Title = "Remote UI",
            Content = state and "Opened Trait" or "Closed Trait",
            Duration = 2
        })
    end
})

Tabs.Settings:CreateKeybind({
    Flag = "ToggleUIKeybind",
    Name = "Minimize UI Keybind",
    CurrentKeybind = "LeftControl",
    OnChanged = function(NewKey)
        local keyCode = typeof(NewKey) == "EnumItem" and NewKey or Enum.KeyCode[tostring(NewKey)] or Enum.KeyCode.LeftControl
        Window:SetKeybind(keyCode)
    end
})

Tabs.Settings:CreateSection("Keybinds")

Tabs.Settings:CreateToggle({
    Flag = "DisableAllKeybindsToggle",
    Name = "Disable Keybinds",
    CurrentValue = Config.DisableAllKeybinds or false,
    Callback = function(Value)
        Config.DisableAllKeybinds = Value
        SaveConfig()
    end
})

Tabs.Settings:CreateKeybind({
    Flag = "FlyKeybind",
    Name = "Fly Keybind",
    CurrentKeybind = Config.FlyKeybind or "F",
    Callback = function()
        if not UserInputService:GetFocusedTextBox() and not Config.DisableAllKeybinds and Config.FlyKeybindEnabled ~= false then
            toggleFly()
        end
    end,
    OnChanged = function(NewKey)
        local keyCode = typeof(NewKey) == "EnumItem" and NewKey or Enum.KeyCode[tostring(NewKey):gsub("Enum%.KeyCode%.", "")]
        if keyCode then
            Config.FlyKeybind = keyCode.Name
            SaveConfig()
        end
    end
})

Tabs.Settings:CreateKeybind({
    Flag = "NoclipKeybind",
    Name = "Noclip Keybind",
    CurrentKeybind = Config.NoclipKeybind or "J",
    Callback = function()
        if not UserInputService:GetFocusedTextBox() and not Config.DisableAllKeybinds and Config.NoclipKeybindEnabled ~= false then
            toggleNoclip()
        end
    end,
    OnChanged = function(NewKey)
        local keyCode = typeof(NewKey) == "EnumItem" and NewKey or Enum.KeyCode[tostring(NewKey):gsub("Enum%.KeyCode%.", "")]
        if keyCode then
            Config.NoclipKeybind = keyCode.Name
            SaveConfig()
        end
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
                    Title = "Server Hop",
                    Content = "Searching for low player server...",
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
                        Title = "Server Hop",
                        Content = "Found server with " .. tostring(targetServer.playing) .. " players! Teleporting...",
                        Duration = 4
                    })
                end)
                task.wait(0.5)
                TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, LocalPlayer)
            else
                pcall(function()
                    Library:Notify({
                        Title = "Server Hop",
                        Content = "Couldn't find low player server. Teleporting to random server...",
                        Duration = 4
                    })
                end)
                task.wait(0.5)
                TeleportService:Teleport(placeId, LocalPlayer)
            end
        end)
    end

    Tabs.Misc:CreateSection("Server")

    Tabs.Misc:CreateButton({
        Name = "Rejoin",
        Callback = function()
            pcall(function()
                Library:Notify({
                    Title = "Rejoin",
                    Content = "Rejoining current server...",
                    Duration = 3
                })
            end)
            task.wait(0.3)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    })

    Tabs.Misc:CreateButton({
        Name = "Server Hop Low Players",
        Callback = function()
            HopLowServer()
        end
    })
end

Window:SelectTab(Tabs.Main)
