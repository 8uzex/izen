local globalEnv = (getgenv and getgenv()) or _G
_G.NNVN_IsPremium = true
_G.SCRIPT_IsPremium = true
globalEnv.NNVN_IsPremium = true
globalEnv.SCRIPT_IsPremium = true
globalEnv.NNVN_IsPremiumAccess = true
globalEnv.NNVN_AccessTier = "PREMIUM"

print("[NNVN Hub by n0namevnek] Key verified. Loading main script...")
local hubVersion = "4.6.7"
if _G.SCRIPT_LOADED and getgenv().NNVN_Loaded == true then
    warn("[NNVN Hub] Already loaded — skip re-exec")
    return
end
_G.SCRIPT_LOADED = true
getgenv().NNVN_Loaded = false
local targetPlaceId = 98502499119821
local targetPlaceId2 = 98502499119821
if game.PlaceId ~= targetPlaceId then
    warn("[NNVN Hub] Wrong game PlaceId=" .. tostring(game.PlaceId) .. " — expected " .. tostring(targetPlaceId))
    return
end
local isAllowed = not (function()
    local function executeAction(inputValue)
        local ok, result = pcall(function()
            return workspace:GetAttribute(inputValue)
        end)
        if not ok then
            local ok2, result2 = pcall(function()
                return game:GetService("Workspace"):GetAttribute(inputValue)
            end)
            ok = ok2
            result = result2
        end
        return ok and result == true
    end
    if executeAction("PVP") or executeAction("pvp") then
        return true
    end
    return executeAction("PVPServer")
end)()
local isEnabled = true
if not isAllowed then
    local ok, result = pcall(function()
        loadstring(game:HttpGet("https://raw.soteria.rip/972faf0b538cea2defc1f63af3d7eaca"))()
    end)
    if not ok then
        warn("[NNVN Hub] Failed to load external PVP script: " .. tostring(result))
    else
        print("[NNVN Hub] External PVP script loaded · PlaceId=" .. tostring(game.PlaceId) .. " · PVP=true")
    end
    return
end
getgenv().NNVN_SkillsESP = getgenv().NNVN_SkillsESP or false
getgenv().NNVN_SkillsESPGuis = getgenv().NNVN_SkillsESPGuis or {}
getgenv().NNVN_SkillsESPLoop = getgenv().NNVN_SkillsESPLoop or 0
local function getCoreServices()
    return game:GetService("Players"), game:GetService("ReplicatedStorage")
end

local function getPlayerRodSkills(inputValue)
    local playersService, replicatedStorage = getCoreServices()
    local data = replicatedStorage:FindFirstChild("Data")
    if not data then
        return {}
    end
    local playerData = data:FindFirstChild(tostring(inputValue))
    if not playerData then
        return {}
    end
    local fishingRod = playerData:FindFirstChild("FishingRod")
    local valueText = fishingRod and tostring(fishingRod.Value or "") or ""
    if valueText == "" then
        return {}
    end
    local fishingRodInventory = playerData:FindFirstChild("FishingRodInventory")
    if not fishingRodInventory then
        return {}
    end
    local rodEntry = fishingRodInventory:FindFirstChild(valueText)
    if not rodEntry then
        return {}
    end
    local skill = rodEntry:FindFirstChild("Skill")
    if not skill then
        return {}
    end
    local lookupMap = {}
    for _, item in ipairs(skill:GetChildren()) do
        if item:IsA("StringValue") then
            lookupMap[item.Name] = tostring(item.Value or "")
        end
    end
    return lookupMap, valueText
end

local function formatSkillSummary(inputValue)
    if not inputValue then
        return ""
    end
    local stateMap = {}
    for _, item in ipairs({ "Z", "X", "C", "V" }) do
        local inputValueEntry = inputValue[item]
        if not inputValueEntry or inputValueEntry == "" then
            continue
        end
        table.insert(stateMap, string.format("%s: %s", item, inputValueEntry))
    end
    for key, entry in pairs(inputValue) do
        if key == "Z" or key == "X" or key == "C" or key == "V" or entry == "" then
            continue
        end
        table.insert(stateMap, string.format("%s: %s", key, entry))
    end
    return table.concat(stateMap, "  |  ")
end

local function updateSkillEspBillboard(player)
    local LocalPlayer = game:GetService("Players").LocalPlayer
    if not player or player == LocalPlayer then
        return
    end
    local character = player.Character
    if not character then
        local skillsEspGui = getgenv().NNVN_SkillsESPGuis[player]
        if skillsEspGui then
            pcall(function()
                skillsEspGui:Destroy()
            end)
            getgenv().NNVN_SkillsESPGuis[player] = nil
        end
        return
    end
    local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    if not head then
        return
    end
    local skillSummary = formatSkillSummary(getPlayerRodSkills(player.UserId))
    if skillSummary == "" then
        local skillsEspGui2 = getgenv().NNVN_SkillsESPGuis[player]
        if skillsEspGui2 then
            skillsEspGui2.Enabled = false
        end
        return
    end
    local skillsEspGui3 = getgenv().NNVN_SkillsESPGuis[player]
    if not skillsEspGui3 or not skillsEspGui3.Parent then
        skillsEspGui3 = Instance.new("BillboardGui")
        skillsEspGui3.Name = "NNVN_SkillsESP_" .. player.Name
        skillsEspGui3.Size = UDim2.new(0, 420, 0, 60)
        skillsEspGui3.StudsOffset = Vector3.new(0, 3.5, 0)
        skillsEspGui3.AlwaysOnTop = true
        skillsEspGui3.ResetOnSpawn = false
        skillsEspGui3.Parent = head
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "SkillLabel"
        textLabel.BackgroundTransparency = 1
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 14
        textLabel.TextColor3 = Color3.fromRGB(0, 255, 180)
        textLabel.TextStrokeTransparency = 0.4
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.TextWrapped = true
        textLabel.Text = skillSummary
        textLabel.Parent = skillsEspGui3
        getgenv().NNVN_SkillsESPGuis[player] = skillsEspGui3
    else
        if skillsEspGui3.Parent ~= head then
            skillsEspGui3.Parent = head
        end
        local skillLabel = skillsEspGui3:FindFirstChild("SkillLabel")
        if skillLabel then
            skillLabel.Text = skillSummary
        end
        skillsEspGui3.Enabled = true
    end
end

local function resolveSkillsEspGuis(inputValue)
    local skillsEspGui = getgenv().NNVN_SkillsESPGuis[inputValue]
    if skillsEspGui then
        pcall(function()
            skillsEspGui:Destroy()
        end)
        getgenv().NNVN_SkillsESPGuis[inputValue] = nil
    end
end

local function resolveSkillsEspGuis2()
    for _, entry in pairs(getgenv().NNVN_SkillsESPGuis) do
        if entry then
            pcall(function()
                entry:Destroy()
            end)
        end
    end
    getgenv().NNVN_SkillsESPGuis = {}
    getgenv().NNVN_SkillsESPLoop = (getgenv().NNVN_SkillsESPLoop or 0) + 1
end

function NNVN_SetSkillsESP(inputValue)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    getgenv().NNVN_SkillsESP = inputValue and true or false
    resolveSkillsEspGuis2()
    if not getgenv().NNVN_SkillsESP then
        return
    end
    local skillsEspLoop = getgenv().NNVN_SkillsESPLoop
    task.spawn(function()
        while getgenv().NNVN_SkillsESP and skillsEspLoop == getgenv().NNVN_SkillsESPLoop do
            pcall(function()
                for _, item in ipairs(Players:GetPlayers()) do
                    if item ~= LocalPlayer then
                        updateSkillEspBillboard(item)
                    end
                end
                for key, entry in pairs(getgenv().NNVN_SkillsESPGuis) do
                    if not key.Parent then
                        resolveSkillsEspGuis(key)
                    end
                end
            end)
            task.wait(0.5)
        end
        resolveSkillsEspGuis2()
    end)
    if not getgenv()._NNVN_SkillsESPLeaveConn then
        getgenv()._NNVN_SkillsESPLeaveConn = Players.PlayerRemoving:Connect(function(player)
            resolveSkillsEspGuis(player)
        end)
    end
end

local function resolveGetService(inputValue)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        return
    end
    getgenv().NNVN_Anchor = getgenv().NNVN_Anchor or false
    getgenv().NNVN_AutoSkill = getgenv().NNVN_AutoSkill or false
    getgenv().NNVN_AutoSkillMethod = getgenv().NNVN_AutoSkillMethod or "Skill Event"
    getgenv().NNVN_Skills = getgenv().NNVN_Skills or { Z = true, X = true, C = true, V = true }
    getgenv().NNVN_SkillOrder = getgenv().NNVN_SkillOrder or { "Z", "X", "C", "V" }
    getgenv().NNVN_SupportSkill = getgenv().NNVN_SupportSkill or "R"
    getgenv().NNVN_TriggerSkill = getgenv().NNVN_TriggerSkill or "Z"
    getgenv().NNVN_AutoUseSupport = getgenv().NNVN_AutoUseSupport or false
    getgenv().NNVN_Notify = getgenv().NNVN_Notify ~= false
    local mainGui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainGui")
    pcall(function()
        mainGui = LocalPlayer.PlayerGui:WaitForChild("MainGui", 5)
    end)
    local function executeAction(inputValue)
        local ok, result = pcall(function()
            local frameEntry = mainGui and mainGui:FindFirstChild("Fishing") and mainGui.Fishing:FindFirstChild("SkillButton") and mainGui.Fishing.SkillButton:FindFirstChild("Frame") and mainGui.Fishing.SkillButton.Frame:FindFirstChild(inputValue)
            if not frameEntry then
                return true
            end
            local cd = frameEntry:FindFirstChild("CD")
            if not cd then
                return false
            end
            return cd.Visible == true
        end)
        return ok and result == true
    end
    if not getgenv()._NNVN_PvpSkillLoop then
        getgenv()._NNVN_PvpSkillLoop = true
        task.spawn(function()
            local counter = 0
            while task.wait(1) do
                if not getgenv().NNVN_AutoSkill then
                    counter = 0
                else
                    local events = ReplicatedStorage:FindFirstChild("Events")
                    local useSkill = events and events:FindFirstChild("UseSkill")
                    local skillOrder = getgenv().NNVN_SkillOrder or { "Z", "X", "C", "V" }
                    local skills = getgenv().NNVN_Skills or { Z = true, X = true, C = true, V = true }
                    local counter2 = 0
                    while counter2 < 4 do
                        counter = counter + 1
                        if counter > 4 then
                            counter = 1
                        end
                        counter2 = counter2 + 1
                        local skillKey = skillOrder[counter]
                        if skillKey and skills[skillKey] and not executeAction(skillKey) then
                            if getgenv().NNVN_AutoSkillMethod == "Skill Event" then
                                if useSkill then
                                    pcall(function()
                                        useSkill:FireServer(skillKey)
                                    end)
                                end
                            else
                                local skillFlag = ({
                                    Z = Enum.KeyCode.Z,
                                    X = Enum.KeyCode.X,
                                    C = Enum.KeyCode.C,
                                    V = Enum.KeyCode.V
                                })[skillKey]
                                if skillFlag then
                                    VirtualInputManager:SendKeyEvent(true, skillFlag, false, game)
                                    task.wait(0.05)
                                    VirtualInputManager:SendKeyEvent(false, skillFlag, false, game)
                                end
                            end
                            break
                        end
                    end
                end
            end
        end)
    end
    if not getgenv()._NNVN_PvpSupportHook then
        getgenv()._NNVN_PvpSupportHook = true
        task.spawn(function()
            local events = ReplicatedStorage:WaitForChild("Events", 10)
            if not events then
                return
            end
            local useSkill = events:WaitForChild("UseSkill", 10)
            local useSupportSkill = events:FindFirstChild("UseSupportSkill") or events:WaitForChild("UseSupportSkill", 10)
            if not useSkill or not useSupportSkill then
                return
            end
            if not hookmetamethod then
                return
            end
            local item
            item = hookmetamethod(game, "__namecall", function(selfTarget, ...)
                local namecallmethod = getnamecallmethod()
                if selfTarget == useSkill and namecallmethod == "FireServer" and getgenv().NNVN_AutoUseSupport and ({ ... })[1] == getgenv().NNVN_TriggerSkill then
                    pcall(function()
                        useSupportSkill:FireServer(getgenv().NNVN_SupportSkill)
                    end)
                    task.wait(0.05)
                    return item(selfTarget, ...)
                end
                return item(selfTarget, ...)
            end)
        end)
    end
    if not getgenv()._NNVN_PvpAnchorConn then
        getgenv()._NNVN_PvpAnchorConn = true
        local counter = 0
        RunService.RenderStepped:Connect(function()
            if not getgenv().NNVN_Anchor then
                return
            end
            pcall(function()
                local mainGui = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
                local fishing = mainGui and mainGui:FindFirstChild("Fishing")
                if fishing and fishing.Visible then
                    local barFrame = fishing:FindFirstChild("BarFrame")
                    local bar = barFrame and barFrame:FindFirstChild("Bar")
                    if bar then
                        bar.Position = UDim2.new(0.5, 0, bar.Position.Y.Scale, 0)
                    end
                    local nowTime = os.clock()
                    if nowTime - counter >= 0.12 then
                        counter = nowTime
                        local fishing2 = ReplicatedStorage:FindFirstChild("Fishing")
                        if fishing2 then
                            fishing2:FireServer("1")
                        end
                    end
                end
            end)
        end)
    end
    if not inputValue then
        return
    end
    local item
    pcall(function()
        local ultraObsidianSource = getgenv()._NNVN_UltraObsidianSource
        if type(ultraObsidianSource) ~= "string" or #ultraObsidianSource < 100 then
            ultraObsidianSource = game:HttpGet("https://raw.githubusercontent.com/n0namevnnek-web/UltraObsidian/refs/heads/main/Library.lua")
            getgenv()._NNVN_UltraObsidianSource = ultraObsidianSource
        end
        item = loadstring(ultraObsidianSource)()
    end)
    if not item then
        warn("[NNVN Hub] PVP Lite: WindUI failed")
        return
    end
    local Window = item:CreateWindow({
        Title = "NNVN Hub",
        Author = "By N0NAMEVN · PVP Lite",
        Icon = "rbxassetid://138952058031836",
        Folder = "NNVN_Hub_PVP_Lite",
        Size = UDim2.fromOffset(420, 380),
        MinSize = Vector2.new(350, 300),
        MaxSize = Vector2.new(560, 480),
        Transparent = true,
        Theme = "Dark",
        SideBarWidth = 160,
        HideSearchBar = true,
        ScrollBarEnabled = false,
        User = { Enabled = true, Anonymous = true }
    })
    if not Window then
        return
    end
    pcall(function()
        Window:EditOpenButton({
            Title = "Open Menu",
            Icon = "rbxassetid://138952058031836",
            CornerRadius = UDim.new(0, 10),
            StrokeThickness = 1.5,
            Color = ColorSequence.new(Color3.fromHex("0A1128"), Color3.fromHex("1E90FF")),
            OnlyMobile = false,
            Enabled = true,
            Draggable = true
        })
    end)
    local pvpCombatSection = Window:Tab({ Title = "PVP", Icon = "swords" }):Section({ Title = "PVP Combat", Icon = "swords" })
    pvpCombatSection:Toggle({
        Title = "Anchor Bar",
        Default = getgenv().NNVN_Anchor == true,
        Callback = function(enabled)
            getgenv().NNVN_Anchor = enabled
        end
    })
    pvpCombatSection:Toggle({
        Title = "Auto Use Skills",
        Default = getgenv().NNVN_AutoSkill == true,
        Callback = function(selected)
            getgenv().NNVN_AutoSkill = selected
        end
    })
    pvpCombatSection:Dropdown({
        Title = "Auto Skills Method",
        Values = { "Keyboard", "Skill Event" },
        Default = getgenv().NNVN_AutoSkillMethod or "Skill Event",
        Callback = function(selectedValue)
            getgenv().NNVN_AutoSkillMethod = selectedValue
        end
    })
    for i = 1, 4 do
        pvpCombatSection:Dropdown({
            Title = "Skill Order " .. i,
            Values = { "Z", "X", "C", "V" },
            Default = (getgenv().NNVN_SkillOrder or { "Z", "X", "C", "V" })[i] or "Z",
            Callback = function(selected)
                local skillOrder = getgenv().NNVN_SkillOrder or { "Z", "X", "C", "V" }
                for i2 = 1, 4 do
                    if i2 ~= i and skillOrder[i2] == selected then
                        skillOrder[i2] = skillOrder[i]
                        skillOrder[i] = selected
                        return
                    end
                end
                skillOrder[i] = selected
            end
        })
    end
    pvpCombatSection:Dropdown({
        Title = "Select Skills to Auto-Press",
        Values = { "Z", "X", "C", "V" },
        Multi = true,
        Default = { "Z", "X", "C", "V" },
        Callback = function(selected)
            local skillFlags = { Z = false, X = false, C = false, V = false }
            if type(selected) == "table" then
                for key, entry in pairs(selected) do
                    if type(key) == "string" and skillFlags[key] ~= nil then
                        if entry == true then
                            skillFlags[key] = true
                        end
                    elseif type(key) == "number" and type(entry) == "string" and skillFlags[entry] ~= nil then
                        skillFlags[entry] = true
                    end
                end
            end
            getgenv().NNVN_Skills = skillFlags
        end
    })
    pvpCombatSection:Dropdown({
        Title = "Select Support Skill",
        Values = { "R", "T" },
        Default = getgenv().NNVN_SupportSkill or "R",
        Callback = function(selected)
            getgenv().NNVN_SupportSkill = selected
        end
    })
    pvpCombatSection:Dropdown({
        Title = "Use Support Skill when use skill",
        Values = { "Z", "X", "C", "V" },
        Default = getgenv().NNVN_TriggerSkill or "Z",
        Callback = function(enabled)
            getgenv().NNVN_TriggerSkill = enabled
        end
    })
    pvpCombatSection:Toggle({
        Title = "Auto Use SK when use selected skill",
        Default = getgenv().NNVN_AutoUseSupport == true,
        Callback = function(enabled)
            getgenv().NNVN_AutoUseSupport = enabled
        end
    })
    pvpCombatSection:Toggle({
        Title = "Skills ESP",
        Description = "Show equipped rod skills above all other players' heads.",
        Default = getgenv().NNVN_SkillsESP == true,
        Callback = function(selectedValue)
            if type(NNVN_SetSkillsESP) == "function" then
                NNVN_SetSkillsESP(selectedValue == true)
            else
                getgenv().NNVN_SkillsESP = selectedValue == true
            end
        end
    })
    pcall(function()
        Window:SelectTab(1)
    end)
    pcall(function()
        item:Notify({
            Title = "NNVN Hub · PVP Lite",
            Description = "PVP server detected — only PVP tools loaded",
            Time = 4
        })
    end)
    print("[NNVN Hub] PVP Lite loaded · PlaceId=" .. tostring(game.PlaceId))
end

getgenv().NNVN_Loaded = false
getgenv().NNVN_AutoTicket = false
getgenv().NNVN_TicketDifficulty = "Easy"
getgenv().NNVN_TicketFarmMode = getgenv().NNVN_TicketFarmMode or "Tween [Safe]"
getgenv().NNVN_TicketHardLocation = getgenv().NNVN_TicketHardLocation or "Sky"
getgenv().NNVN_TicketRandomSkyHeight = getgenv().NNVN_TicketRandomSkyHeight ~= false
getgenv().NNVN_TicketSkyChosenHeight = tonumber(getgenv().NNVN_TicketSkyChosenHeight)
getgenv().NNVN_SkyFarm = false
getgenv().NNVN_SkyFarmHeight = math.clamp(tonumber(getgenv().NNVN_SkyFarmHeight) or 609, 100, 1000)
getgenv().NNVN_TicketAcceptDelay = math.max(1, tonumber(getgenv().NNVN_TicketAcceptDelay) or 2)
getgenv().NNVN_TicketFishWhileWaiting = getgenv().NNVN_TicketFishWhileWaiting ~= false
getgenv().NNVN_TicketWaitNearNpcSeconds = math.clamp(tonumber(getgenv().NNVN_TicketWaitNearNpcSeconds) or 120, 60, 120)
getgenv().NNVN_TicketDailyLimitReached = false
getgenv().NNVN_AutoBuyBait = false
getgenv().NNVN_BaitQuantity = math.max(1, tonumber(getgenv().NNVN_BaitQuantity) or 1)
getgenv().NNVN_SelectedBait = "Basic Bait"
getgenv().NNVN_AutoBuyBaitDelay = math.max(1, tonumber(getgenv().NNVN_AutoBuyBaitDelay) or 3)
getgenv().NNVN_AutoPhase2 = false
getgenv().NNVN_AutoTurnIn = false
getgenv().NNVN_AutoGodSpirit = false
getgenv()._uiHideCount = getgenv()._uiHideCount or 0
getgenv().NNVN_AutoHopGod = false
getgenv().NNVN_AutoHopMaoshan = false
getgenv().NNVN_AutoHopTaoist = false
getgenv().NNVN_NoClip = false
getgenv().NNVN_NoFog = false
getgenv().NNVN_AutoExecuteScript = true
getgenv()._keyLoaded = false
getgenv().NNVN_AutoClaimDaily = false
getgenv().NNVN_ClaimDailyDelay = 1
getgenv().NNVN_AutoUseBait = false
getgenv().NNVN_AutoAcceptQuest = false
getgenv().NNVN_AutoFavoriteFish = false
getgenv().NNVN_SelectedFavoriteFish = nil
getgenv().NNVN_FavoriteFishLoopId = 0
getgenv().NNVN_SkipFishList = getgenv().NNVN_SkipFishList or {}
getgenv().NNVN_AutoSkipFish = false
getgenv().NNVN_SkipFishConnection = nil
getgenv().NNVN_SkipFishRequestId = getgenv().NNVN_SkipFishRequestId or 0
getgenv().NNVN_HidePlayerName = getgenv().NNVN_HidePlayerName ~= false
getgenv().NNVN_HidePlayerNameText = getgenv().NNVN_HidePlayerNameText
getgenv().NNVN_AutoBossFishing = false
getgenv().NNVN_BossFishingSkipAt = 0
getgenv().NNVN_BossFarmState = getgenv().NNVN_BossFarmState or {
    CurrentTarget = nil,
    CurrentType = nil,
    CurrentToken = nil,
    CurrentRunId = 0,
    HasHooked = false,
    PendingCancel = false,
    LastCast = 0,
    LastCancel = 0,
    LastFastCancel = 0,
    LastProgress = 0,
    LastNotify = ""
}
getgenv().NNVN_WhiteScreen = false
getgenv().NNVN_DarkScreen = false
getgenv().NNVN_Anchor = false
getgenv().NNVN_AutoCast = false
getgenv().NNVN_AutoCastDelay = math.max(0.5, tonumber(getgenv().NNVN_AutoCastDelay) or 3)
getgenv().NNVN_SafetyMode = getgenv().NNVN_SafetyMode ~= false
getgenv().NNVN_RemoteSafetyTimes = getgenv().NNVN_RemoteSafetyTimes or {}
getgenv().NNVN_RemoteMinInterval = math.max(0.5, tonumber(getgenv().NNVN_RemoteMinInterval) or 0.75)
getgenv().NNVN_TweenStartDelay = math.max(0, tonumber(getgenv().NNVN_TweenStartDelay) or 0.2)
getgenv().NNVN_BlockDuplicateTween = getgenv().NNVN_BlockDuplicateTween ~= false
getgenv().NNVN_LastSafetyTweenAt = tonumber(getgenv().NNVN_LastSafetyTweenAt) or 0
getgenv().NNVN_LastSafetyTweenTarget = getgenv().NNVN_LastSafetyTweenTarget
getgenv().NNVN_AutoSell = false
getgenv().NNVN_AutoSellNormalFish = false
getgenv().NNVN_AutoSellOnlyBoss = false
getgenv().NNVN_AutoSellOnlySecretBoss = false
getgenv().NNVN_AutoSellWhenFull = false
getgenv().NNVN_SellDelay = 5
getgenv().NNVN_SellDelayMinutes = getgenv().NNVN_SellDelayMinutes or 0
getgenv().NNVN_SellDelaySeconds = getgenv().NNVN_SellDelaySeconds or tonumber(getgenv().NNVN_SellDelay) or 5
getgenv().NNVN_SellActionMethod = getgenv().NNVN_SellActionMethod or "Tween [Safe]"
getgenv().NNVN_DisableUltraFPSPrompt = true
getgenv().NNVN_LowFPSPromptShown = getgenv().NNVN_LowFPSPromptShown == true
getgenv().NNVN_AutoSkill = false
getgenv().NNVN_Skills = { Z = true, X = true, C = true, V = true }
getgenv().NNVN_AutoSkillMethod = getgenv().NNVN_AutoSkillMethod or "Skill Event"
getgenv().NNVN_SkillOrder = getgenv().NNVN_SkillOrder or { "Z", "X", "C", "V" }
getgenv().NNVN_SupportSkill = getgenv().NNVN_SupportSkill or "R"
getgenv().NNVN_TriggerSkill = getgenv().NNVN_TriggerSkill or "Z"
getgenv().NNVN_AutoUseSupport = getgenv().NNVN_AutoUseSupport or false
getgenv().NNVN_SkillsESP = getgenv().NNVN_SkillsESP or false
getgenv().NNVN_SkillsESPGuis = getgenv().NNVN_SkillsESPGuis or {}
getgenv().NNVN_SkillsESPLoop = getgenv().NNVN_SkillsESPLoop or 0
getgenv().NNVN_Invisible = false
if getgenv()._NNVN_InvisibleConn then
    pcall(function()
        getgenv()._NNVN_InvisibleConn:Disconnect()
    end)
    getgenv()._NNVN_InvisibleConn = nil
end
getgenv()._NNVN_InvisibleConn = getgenv()._NNVN_InvisibleConn or nil
getgenv().NNVN_AutoGiveFish = false
getgenv().NNVN_DumpGuyHotbarSlot = getgenv().NNVN_DumpGuyHotbarSlot or 4
getgenv().NNVN_AutoFarm2MFish = false
getgenv().NNVN_2MFishThreshold = 2000000
getgenv().NNVN_2MFishPrevFlags = nil
getgenv().NNVN_2MFishFarmCFrame = CFrame.new(1655.73901, 8.66194057, -155.14827, 0.782916069, 1.7383087e-08, -0.622127354, 1.4318406e-08, 1, 4.59603626e-08, 0.622127354, -4.4890978e-08, 0.782916069)
getgenv().NNVN_AntiAFK = true
getgenv().NNVN_AllowAutomaticServerHop = false
getgenv().NNVN_ServerHopArmed = false
getgenv().NNVN_IsApplyingConfig = false
getgenv().NNVN_ScriptBootTime = os.clock()
getgenv().NNVN_HopGraceSeconds = 25
getgenv().NNVN_HopBootLocked = true
getgenv().NNVN_AntiStaff = false
getgenv().NNVN_ServerHopArmed = false
getgenv().NNVN_AntiStaff = false
getgenv().NNVN_AntiStaffAction = "Notify"
getgenv().NNVN_AntiStaffUserIds = {
    3207980523,
    680393079,
    710850460,
    3382466488,
    2455864347
}
getgenv().NNVN_AntiStaffCooldown = 0
getgenv().NNVN_AutoRejoin = false
getgenv().NNVN_Notify = true
getgenv().NNVN_Watermark = getgenv().NNVN_Watermark ~= false
getgenv().NNVN_WalkSpeed = 16
getgenv().NNVN_AutoBoss = false
getgenv().NNVN_BossDifficulty = "Normal"
getgenv().NNVN_AutoFarmSecretBoss = false
getgenv().NNVN_AutoSecretBossMode = getgenv().NNVN_AutoSecretBossMode or "Always Active"
getgenv().NNVN_AutoEquipBestBait = false
getgenv().NNVN_AutoEquipRod = false
getgenv().NNVN_AutoEquipBestOrb = false
getgenv().NNVN_AutoBuyBaitThreshold = 5
getgenv().NNVN_AutoCraftBait = false
getgenv().NNVN_CraftBaitName = "Rainbow Bait"
getgenv().NNVN_CraftBaitQuantity = 1
getgenv().NNVN_AutoCraftRod = false
getgenv().NNVN_CraftRodName = "Heavenpiercer Rod"
getgenv().NNVN_CraftRodQuantity = 1
getgenv().NNVN_GachaAmount = 1
getgenv().NNVN_AutoRebirth = false
getgenv().NNVN_RebirthOptions = { "Cash", "Level" }
getgenv().NNVN_MaterialFarming = false
getgenv().NNVN_MaterialBait = "Rainbow Bait"
getgenv().NNVN_MaterialRodFarming = false
getgenv().NNVN_MaterialRod = "Heavenpiercer Rod"
getgenv().NNVN_ReturnAfterQuestTP = true
getgenv().NNVN_SelectedAutoQuest = getgenv().NNVN_SelectedAutoQuest or "Zeng Tianguo Quest - Perch Isle"
getgenv().NNVN_AutoSelectedQuest = getgenv().NNVN_AutoSelectedQuest == true
getgenv().NNVN_ActionMethod = getgenv().NNVN_ActionMethod or "Tween [Safe]"
getgenv().NNVN_TweenSpeed = getgenv().NNVN_TweenSpeed or 300
getgenv().NNVN_FlyMode = false
getgenv().NNVN_FlySpeed = 50
getgenv().NNVN_InfiniteJump = false
getgenv().NNVN_WalkOnWater = false
getgenv().NNVN_FullBright = false
getgenv().NNVN_PerformanceMod = false
getgenv().NNVN_TraitReroll = false
getgenv().NNVN_RerollSkill = nil
getgenv().NNVN_RerollTargetTrait = nil
getgenv().NNVN_RerollIgnoreLocked = false
getgenv().NNVN_JobIdInput = ""
getgenv().NNVN_LastWeatherReportKey = getgenv().NNVN_LastWeatherReportKey or nil
getgenv().NNVN_AutoNamelessMinigame = false
getgenv().NNVN_AutoBlackTortoiseMinigame = false
getgenv().NNVN_BlackTortoiseBand = getgenv().NNVN_BlackTortoiseBand or 0.12
getgenv().NNVN_NamelessMinigameMode = "Safe"
getgenv().NNVN_NamelessBand = 0.17
getgenv().NNVN_NamelessLag = 0.03
getgenv().NNVN_CustomPositions = getgenv().NNVN_CustomPositions or {}
getgenv().NNVN_PositionNameInput = getgenv().NNVN_PositionNameInput or "Position 1"
getgenv().NNVN_SelectedPosition = getgenv().NNVN_SelectedPosition or "No Position"
getgenv().NNVN_PositionTeleportMode = getgenv().NNVN_PositionTeleportMode or "No Teleport"
getgenv().NNVN_PositionLock = false
getgenv().NNVN_PositionLockLoopId = getgenv().NNVN_PositionLockLoopId or 0
getgenv().NNVN_PositionLockDistance = 3
getgenv().NNVN_Language = "English"
getgenv().NNVN_HidePlayerId = getgenv().NNVN_HidePlayerId == true
getgenv().NNVN_BlankPlayerId = getgenv().NNVN_BlankPlayerId == true
getgenv().NNVN_CustomPlayerId = tostring(getgenv().NNVN_CustomPlayerId or "")
getgenv().NNVN_FakeVisualsEnabled = getgenv().NNVN_FakeVisualsEnabled or false
getgenv().NNVN_FakeLevelText = getgenv().NNVN_FakeLevelText or "100"
getgenv().NNVN_FakeMoneyText = getgenv().NNVN_FakeMoneyText or "999999999"
getgenv().NNVN_FakeGemText = getgenv().NNVN_FakeGemText or "9999"
getgenv().NNVN_FakeTicketText = getgenv().NNVN_FakeTicketText or "999"
getgenv().NNVN_FakeOrbText = getgenv().NNVN_FakeOrbText or "999"
getgenv().NNVN_FakeNameEnabled = getgenv().NNVN_FakeNameEnabled or false
getgenv().NNVN_FakeNameText = getgenv().NNVN_FakeNameText or "NNVN Premium"
getgenv().NNVN_FakeHeadless = getgenv().NNVN_FakeHeadless or false
getgenv().NNVN_FakeKorblox = getgenv().NNVN_FakeKorblox or false
getgenv().NNVN_FakeSkinEnabled = getgenv().NNVN_FakeSkinEnabled or false
getgenv().NNVN_FakeSkinPlayerName = getgenv().NNVN_FakeSkinPlayerName or ""
getgenv().NNVN_FakeSkinTone = getgenv().NNVN_FakeSkinTone or "Pastel brown"
getgenv().NNVN_PremiumWeatherEnabled = false
getgenv().NNVN_PremiumSpiritEnabled = false
getgenv().NNVN_PremiumTaoistEnabled = false
getgenv().NNVN_PremiumMaoshanEnabled = false
getgenv().NNVN_PremiumSelectedWeather = getgenv().NNVN_PremiumSelectedWeather or "Blazing Sun"
getgenv().NNVN_ShowPremiumRelayMenu = getgenv().NNVN_ShowPremiumRelayMenu or false
getgenv().NNVN_HideUI = getgenv().NNVN_HideUI or false
getgenv().NNVN_IsPremiumAccess = getgenv().NNVN_IsPremium == true
getgenv().NNVN_WebhookEnabled = getgenv().NNVN_WebhookEnabled == true
getgenv().NNVN_WebhookUrl = getgenv().NNVN_WebhookUrl or ""
getgenv().NNVN_WebhookWeather = getgenv().NNVN_WebhookWeather == true
getgenv().NNVN_WebhookSpirit = getgenv().NNVN_WebhookSpirit == true
getgenv().NNVN_WebhookMaoshan = getgenv().NNVN_WebhookMaoshan == true
getgenv().NNVN_WebhookTaoist = getgenv().NNVN_WebhookTaoist == true
getgenv().NNVN_WebhookCatchFish = getgenv().NNVN_WebhookCatchFish == true
getgenv().NNVN_WebhookCatchBoss = getgenv().NNVN_WebhookCatchBoss == true
getgenv().NNVN_WebhookCatchSecretBoss = getgenv().NNVN_WebhookCatchSecretBoss == true
getgenv().NNVN_WebhookSell = getgenv().NNVN_WebhookSell == true
getgenv().NNVN_LegacyNetworkTracker = true
getgenv().NNVN_WebhookCooldown = getgenv().NNVN_WebhookCooldown or 20
getgenv().NNVN_WebhookScanInterval = getgenv().NNVN_WebhookScanInterval or 45
NNVN_SYSTEM_WEBHOOK_URLS = {
    weather = "https://discord.com/api/webhooks/1543925558193168414/ihmpPwJfvlhgDXeX8s4MiAo8og0F7Z8HG-HiXs2DwLb0g3SIIs6QJWbjzy4FJbH3Vf64",
    spirit = "https://discord.com/api/webhooks/1543926566244057159/vMvkh_TtVpjueWNAy0PRsyPBC-ZMbCLhl2xNZ-xiKqR63PuI8DrYwDL-TPBlpxnfHbVZ",
    maoshan = "https://discord.com/api/webhooks/1543926717025095731/tVYehqWWI6DmewDIeCB1h2344_39H9hxBJf_7l0CkTlHOms6nrBMQmerBsmny94Vuv9j",
    taoist = "https://discord.com/api/webhooks/1543927038879080602/IWS4gOABiqLomGGoB_Nt5LTqIzUgCtPjpJi_UmrirmbBRNfOvlI_1m-RdbQlmByVBZjG"
}
NNVN_SYSTEM_WEBHOOK_URLS.vermilion = "https://discord.com/api/webhooks/1559193471972151368/9pthg8Uzj6k49KWon-IuK6jINXm2E3U2wv7nIBZgo9O_VEdNgC4lfrb-S5rw1Efg1oXl"
NNVN_SYSTEM_WEBHOOK_URLS.blacktortoise = "https://discord.com/api/webhooks/1561002385655201935/-qhIA6eO5oAs_SWmBDy5111g3mH9ANr84iJcq1NdEA1wj1Z8GVsHV47pn5k3jSP2CCyn"
NNVN_BACKUP_WEBHOOK_URLS = {}
getgenv().NNVN_WebhookWeatherUrl = ""
getgenv().NNVN_WebhookMaoshanUrl = ""
getgenv().NNVN_WebhookSpiritUrl = ""
getgenv().NNVN_WebhookTaoistUrl = ""
getgenv().NNVN_WebhookVermilionUrl = ""
getgenv().NNVN_WebhookBlacktortoiseUrl = ""
getgenv().NNVN_WebhookWeatherUrlBackup = NNVN_BACKUP_WEBHOOK_URLS.weather
getgenv().NNVN_WebhookMaoshanUrlBackup = NNVN_BACKUP_WEBHOOK_URLS.maoshan
getgenv().NNVN_WebhookSpiritUrlBackup = NNVN_BACKUP_WEBHOOK_URLS.spirit
getgenv().NNVN_WebhookTaoistUrlBackup = NNVN_BACKUP_WEBHOOK_URLS.taoist
getgenv().NNVN_WebhookVermilionUrlBackup = NNVN_BACKUP_WEBHOOK_URLS.vermilion
getgenv().NNVN_WebhookBlacktortoiseUrlBackup = NNVN_BACKUP_WEBHOOK_URLS.blacktortoise
getgenv().NNVN_UserWebhookEnabled = getgenv().NNVN_UserWebhookEnabled == true
getgenv().NNVN_UserWebhookBoss = getgenv().NNVN_UserWebhookBoss == true
getgenv().NNVN_UserWebhookBossUrl = getgenv().NNVN_UserWebhookBossUrl or ""
getgenv().NNVN_UserWebhookCustom = getgenv().NNVN_UserWebhookCustom == true
getgenv().NNVN_UserWebhookCustomUrl = getgenv().NNVN_UserWebhookCustomUrl or ""
getgenv().NNVN_UserWebhookCustomName = getgenv().NNVN_UserWebhookCustomName or "Custom Alert"
getgenv().NNVN_Backflip = getgenv().NNVN_Backflip or false
getgenv().NNVN_BackflipDistance = getgenv().NNVN_BackflipDistance or 8
getgenv().NNVN_BackflipLoopId = getgenv().NNVN_BackflipLoopId or 0
getgenv().NNVN_AutoFarmWeatherEvent = getgenv().NNVN_AutoFarmWeatherEvent or false
getgenv().NNVN_WeatherFarmLoopId = getgenv().NNVN_WeatherFarmLoopId or 0
getgenv().NNVN_WeatherFarmIsland = getgenv().NNVN_WeatherFarmIsland or "Auto"
getgenv().NNVN_WeatherFarmPrevPos = getgenv().NNVN_WeatherFarmPrevPos or nil
getgenv().NNVN_WeatherFarmActive = getgenv().NNVN_WeatherFarmActive or false
getgenv().NNVN_WeatherFarmPrevFlags = getgenv().NNVN_WeatherFarmPrevFlags or nil
getgenv().NNVN_AutoLongDiaohai = getgenv().NNVN_AutoLongDiaohai or false
getgenv().NNVN_LongDiaohaiDifficulty = getgenv().NNVN_LongDiaohaiDifficulty or "Normal"
getgenv().NNVN_AutoLongDiaohaiPhase2 = getgenv().NNVN_AutoLongDiaohaiPhase2 or false
getgenv().NNVN_AutoLongDiaohaiMinigame = false
getgenv().NNVN_AutoHopFightLongDiaohai = getgenv().NNVN_AutoHopFightLongDiaohai or false
getgenv().NNVN_AutoHopLongDiaohaiPrevFlags = nil
local item
pcall(function()
    local ultraObsidianSource = getgenv()._NNVN_UltraObsidianSource
    if type(ultraObsidianSource) ~= "string" or #ultraObsidianSource < 100 then
        ultraObsidianSource = game:HttpGet("https://raw.githubusercontent.com/n0namevnnek-web/UltraObsidian/refs/heads/main/Library.lua")
        getgenv()._NNVN_UltraObsidianSource = ultraObsidianSource
    end
    item = loadstring(ultraObsidianSource)()
end)
if not item then
    warn("[NNVN Hub] Failed to load WindUI")
    return
end
local item2 = item
pcall(function()
    if type(item2.SetIconModule) ~= "function" then
        return
    end
    local lucideIconModule = getgenv()._NNVN_LucideIconModule
    if type(lucideIconModule) ~= "table" or type(lucideIconModule.GetAsset) ~= "function" then
        lucideIconModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"))()
        getgenv()._NNVN_LucideIconModule = lucideIconModule
    end
    item2:SetIconModule(lucideIconModule)
end)
pcall(function()
    item2:SetTheme("Midnight")
end)
item2.ShowCustomCursor = false
function NNVN_ColorFromHex(inputValue, secondValue)
    local formattedText = tostring(inputValue or ""):gsub("#", ""):gsub("0x", "")
    if #formattedText ~= 6 or not formattedText:match("^[%da-fA-F]+$") then
        return secondValue
    end
    return Color3.fromRGB(tonumber(formattedText:sub(1, 2), 16) or 255, tonumber(formattedText:sub(3, 4), 16) or 255, tonumber(formattedText:sub(5, 6), 16) or 255)
end

local function applyWindowScheme()
    if type(item2.Scheme) == "table" then
        local colorFromHexResult = NNVN_ColorFromHex(getgenv().NNVN_AccentColorHex, Color3.fromRGB(86, 140, 255))
        item2.Scheme.BackgroundColor = Color3.fromRGB(16, 17, 20)
        item2.Scheme.MainColor = Color3.fromRGB(27, 29, 34)
        item2.Scheme.AccentColor = colorFromHexResult
        item2.Scheme.OutlineColor = Color3.fromRGB(53, 57, 66)
        item2.Scheme.FontColor = Color3.fromRGB(245, 247, 250)
        item2.Scheme.DarkColor = Color3.fromRGB(9, 10, 12)
        item2.Scheme.WhiteColor = Color3.fromRGB(255, 255, 255)
        item2.Scheme.BackgroundImage = getgenv().NNVN_BackgroundImage or ""
    end
    if type(item2.UpdateColors) == "function" then
        item2:UpdateColors()
    end
end

pcall(applyWindowScheme)
local stateMap = {}
local stateMap2 = {}
function registerControl(inputValue, secondValue)
    if type(inputValue) == "string" and inputValue ~= "" and secondValue then
        stateMap2[inputValue] = secondValue
    end
    return secondValue
end

function normalizeDesc(options)
    if options and options.Content ~= nil and options.Desc == nil then
        options.Desc = options.Content
    end
    return options
end

function addDefaultTooltip(options, secondValue)
    options = options or {}
    if options.Tooltip == nil then
        local titleText = tostring(options.Title or secondValue or "Feature")
        options.Tooltip = tostring(options.Description or options.Content or "Use this control to configure or run " .. titleText .. ".")
    end
    return options
end

function attachSetValue(control)
    if control and not control.SetValue then
        control.SetValue = function(selfControl, newValue)
            selfControl.Value = newValue
            if selfControl.Set then
                return selfControl:Set(newValue)
            end
            if selfControl.Select then
                return selfControl:Select(newValue)
            end
        end
    end
    return control
end

function normalizeMultiDropdownValue(inputValue)
    if type(inputValue) ~= "table" then
        return inputValue
    end
    local stateMap = {}
    local hasTriggered = false
    for key, entry in pairs(inputValue) do
        if type(key) == "string" then
            hasTriggered = true
            if entry then
                table.insert(stateMap, key)
            end
        end
    end
    if hasTriggered then
        return stateMap
    end
    return inputValue
end

function toFluentMultiMap(inputValue)
    local lookupMap = {}
    if type(inputValue) ~= "table" then
        return lookupMap
    end
    for key, entry in pairs(inputValue) do
        if type(key) == "string" then
            lookupMap[key] = entry and true or false
        else
            local title = typeof(entry) == "table" and entry.Title or entry
            if title then
                lookupMap[title] = true
            end
        end
    end
    return lookupMap
end

function patchContainer(control)
    if not control or control.__NNVN_WindCompat then
        return control
    end
    control.__NNVN_WindCompat = true
    local addSection = control.AddSection
    if addSection then
        control.AddSection = function(selfContainer, ...)
            return patchContainer(addSection(selfContainer, ...))
        end
    end
    local section = control.Section
    if section then
        control.Section = function(selfContainer, ...)
            return patchContainer(section(selfContainer, ...))
        end
    end
    if not control.__NNVN_TooltipCompat then
        control.__NNVN_TooltipCompat = true
        local addToggle = control.AddToggle
        local addDropdown = control.AddDropdown
        local addSlider = control.AddSlider
        local addInput = control.AddInput
        local addButton = control.AddButton
        local addParagraph = control.AddParagraph
        if addToggle then
            control.AddToggle = function(selfContainer, configArg, extraOpt)
                return registerControl(configArg, attachSetValue(addToggle(selfContainer, configArg, addDefaultTooltip(extraOpt, configArg))))
            end
        end
        if addDropdown then
            control.AddDropdown = function(selfContainer, configArg, extraOpt)
                return registerControl(configArg, attachSetValue(addDropdown(selfContainer, configArg, addDefaultTooltip(extraOpt, configArg))))
            end
        end
        if addSlider then
            control.AddSlider = function(selfContainer, configArg, extraOpt)
                extraOpt = extraOpt or {}
                if extraOpt.AllowRightClickInput == nil then
                    extraOpt.AllowRightClickInput = true
                end
                return registerControl(configArg, attachSetValue(addSlider(selfContainer, configArg, addDefaultTooltip(extraOpt, configArg))))
            end
        end
        if addInput then
            control.AddInput = function(selfContainer, configArg, extraOpt)
                return registerControl(configArg, attachSetValue(addInput(selfContainer, configArg, addDefaultTooltip(extraOpt, configArg))))
            end
        end
        if addButton then
            control.AddButton = function(selfContainer, configArg, extraOpt)
                return addButton(selfContainer, addDefaultTooltip(configArg, "Button"), extraOpt)
            end
        end
        if addParagraph then
            control.AddParagraph = function(selfContainer, configArg)
                return addParagraph(selfContainer, addDefaultTooltip(normalizeDesc(configArg or {}), "Information"))
            end
        end
        if not control.Toggle and control.AddToggle then
            control.Toggle = function(selfContainer, configArg)
                return selfContainer:AddToggle(configArg and (configArg.Flag or configArg.Title) or "Toggle", configArg)
            end
        end
        if not control.Dropdown and control.AddDropdown then
            control.Dropdown = function(selfContainer, configArg)
                return selfContainer:AddDropdown(configArg and (configArg.Flag or configArg.Title) or "Dropdown", configArg)
            end
        end
        if not control.Slider and control.AddSlider then
            control.Slider = function(selfContainer, configArg)
                return selfContainer:AddSlider(configArg and (configArg.Flag or configArg.Title) or "Slider", configArg)
            end
        end
        if not control.Input and control.AddInput then
            control.Input = function(selfContainer, configArg)
                return selfContainer:AddInput(configArg and (configArg.Flag or configArg.Title) or "Input", configArg)
            end
        end
        if not control.Button and control.AddButton then
            control.Button = function(selfContainer, configArg, extraOpt)
                return selfContainer:AddButton(configArg, extraOpt)
            end
        end
        if not control.Paragraph and control.AddParagraph then
            control.Paragraph = function(selfContainer, configArg)
                return selfContainer:AddParagraph(configArg)
            end
        end
    end
    if not control.AddSection and control.Section then
        control.AddSection = function(selfContainer, configArg)
            local configArg2 = type(configArg) == "table" and configArg or { Title = configArg }
            configArg2.Opened = true
            if configArg2.TextSize == nil then
                configArg2.TextSize = 16
            end
            if configArg2.DescTextSize == nil then
                configArg2.DescTextSize = 13
            end
            return patchContainer(selfContainer:Section(configArg2))
        end
    end
    if not control.AddToggle and control.Toggle then
        control.AddToggle = function(selfContainer, configArg, extraOpt)
            extraOpt = addDefaultTooltip(extraOpt, configArg)
            extraOpt.Flag = extraOpt.Flag or configArg
            if extraOpt.Default ~= nil and extraOpt.Value == nil then
                extraOpt.Value = extraOpt.Default
            end
            return registerControl(configArg, attachSetValue(selfContainer:Toggle(extraOpt)))
        end
    end
    if not control.AddDropdown and control.Dropdown then
        control.AddDropdown = function(selfContainer, configArg, extraOpt)
            extraOpt = addDefaultTooltip(extraOpt, configArg)
            extraOpt.Flag = extraOpt.Flag or configArg
            if extraOpt.Default ~= nil and extraOpt.Value == nil then
                extraOpt.Value = extraOpt.Default
            end
            if extraOpt.Multi then
                extraOpt.Multi = true
                extraOpt.Value = normalizeMultiDropdownValue(extraOpt.Value)
                local callback = extraOpt.Callback
                if callback then
                    extraOpt.Callback = function(selectedValue)
                        return callback(toFluentMultiMap(selectedValue))
                    end
                end
            end
            if extraOpt.SearchBarEnabled == nil and type(extraOpt.Values) == "table" and #extraOpt.Values >= 10 then
                extraOpt.SearchBarEnabled = true
            end
            local dropdown = attachSetValue(selfContainer:Dropdown(extraOpt))
            if dropdown and not dropdown.SetValue then
                dropdown.SetValue = function(selfControl, newValue)
                    local multiDropdownValue = selfControl.Multi and normalizeMultiDropdownValue(newValue) or newValue
                    selfControl.Value = multiDropdownValue
                    if selfControl.Select then
                        selfControl:Select(multiDropdownValue)
                    end
                    if selfControl.Callback then
                        pcall(selfControl.Callback, multiDropdownValue)
                    end
                end
            end
            return registerControl(configArg, dropdown)
        end
    end
    if not control.AddSlider and control.Slider then
        control.AddSlider = function(selfContainer, configArg, extraOpt)
            extraOpt = addDefaultTooltip(extraOpt, configArg)
            extraOpt.Flag = extraOpt.Flag or configArg
            if extraOpt.Min ~= nil or extraOpt.Max ~= nil or extraOpt.Default ~= nil then
                extraOpt.Value = extraOpt.Value or {
                    Min = extraOpt.Min or 0,
                    Max = extraOpt.Max or 100,
                    Default = extraOpt.Default or extraOpt.Min or 0
                }
            end
            return registerControl(configArg, attachSetValue(selfContainer:Slider(extraOpt)))
        end
    end
    if not control.AddInput and control.Input then
        control.AddInput = function(selfContainer, configArg, extraOpt)
            extraOpt = addDefaultTooltip(extraOpt, configArg)
            extraOpt.Flag = extraOpt.Flag or configArg
            if extraOpt.Default ~= nil and extraOpt.Value == nil then
                extraOpt.Value = extraOpt.Default
            end
            return registerControl(configArg, attachSetValue(selfContainer:Input(extraOpt)))
        end
    end
    if not control.AddButton and control.Button then
        control.AddButton = function(selfContainer, configArg)
            return selfContainer:Button(addDefaultTooltip(configArg, "Button"))
        end
    end
    if not control.AddParagraph and control.Paragraph then
        control.AddParagraph = function(selfContainer, configArg)
            local paragraph = selfContainer:Paragraph(addDefaultTooltip(normalizeDesc(configArg or {}), "Information"))
            if paragraph and not paragraph.SetDesc then
                paragraph.SetDesc = function(inputValue, secondValue)
                    inputValue.Desc = secondValue
                    if inputValue.ParagraphFrame and inputValue.ParagraphFrame.SetDesc then
                        return inputValue.ParagraphFrame:SetDesc(secondValue)
                    end
                end
            end
            if paragraph and not paragraph.SetTitle then
                paragraph.SetTitle = function(inputValue, secondValue)
                    inputValue.Title = secondValue
                    if inputValue.ParagraphFrame and inputValue.ParagraphFrame.SetTitle then
                        return inputValue.ParagraphFrame:SetTitle(secondValue)
                    end
                end
            end
            return paragraph
        end
    end
    return control
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local currentCamera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local item3
local playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
if playerGui then
    item3 = playerGui:FindFirstChild("MainGui") or playerGui:WaitForChild("MainGui", 15)
end
if not item3 then
    warn("[NNVN Hub] MainGui not found within 15s — waiting for it in background")
    task.spawn(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 60)
        if not playerGui then
            return
        end
        item3 = playerGui:WaitForChild("MainGui", 60)
    end)
    item3 = Instance.new("ScreenGui")
    item3.Name = "MainGui_Placeholder"
    item3.Parent = playerGui or LocalPlayer
end
pcall(function()
    getgenv().NNVN_FlyMode = false
    getgenv().NNVN_PositionLock = false
    getgenv().NNVN_PositionLockLoopId = (getgenv().NNVN_PositionLockLoopId or 0) + 1
    getgenv().NNVN_Anchor = false
    getgenv().NNVN_NoClip = false
    getgenv().NNVN_Invisible = false
    if flyState then
        flyState.flying = false
        if flyState.bg then
            pcall(function()
                flyState.bg:Destroy()
            end)
        end
        if flyState.bv then
            pcall(function()
                flyState.bv:Destroy()
            end)
        end
        flyState.bg = nil
        flyState.bv = nil
    end
    local character = LocalPlayer.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            for _, item in ipairs(rootPart:GetChildren()) do
                if (item:IsA("BodyVelocity") or item:IsA("BodyGyro") or item:IsA("LinearVelocity") or item:IsA("AngularVelocity")) and (string.find(string.lower(item.Name), "fly") or string.find(string.lower(item.Name), "nnvn") or item.Name == "BodyVelocity" or item.Name == "BodyGyro") then
                    pcall(function()
                        item:Destroy()
                    end)
                end
            end
        end
        local currentCamera = workspace.CurrentCamera
        if currentCamera and currentCamera.CameraSubject and currentCamera.CameraSubject.Name == "NNVN_InvisibleFocus" then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                currentCamera.CameraSubject = humanoid
            end
            currentCamera.CameraType = Enum.CameraType.Custom
        end
    end
end)
local placeId = game.PlaceId
getgenv().NNVN_TrackerBaseUrl = getgenv().NNVN_TrackerBaseUrl or rawget(_G, "NNVN_TrackerBaseUrl") or getgenv().reporter_url or rawget(_G, "reporter_url") or getgenv().bot_base_url or rawget(_G, "bot_base_url") or "https://nnvn-tracker-relay.nnvn-hub.workers.dev/api"
local formattedText = tostring(getgenv().NNVN_TrackerBaseUrl):gsub("/+$", "")
local relayKey = "f6fb1020de488d3f070e2cd84b8675bd94ddcfb793429bbb595853d5bcf95657"
local weatherLookup = {
    foggy = true,
    ["blazing sun"] = true,
    snowy = true,
    windy = true,
    rainy = true,
    thunderstorm = true
}
getgenv().NNVN_LastTrackerReportKeys = getgenv().NNVN_LastTrackerReportKeys or {}
local uiStrings = {
    win_title = "NNVN Hub",
    win_sub = "By N0NAMEVN | Heavyweight Fishing v" .. hubVersion,
    tab_fishing = "Main",
    tab_boss = "Boss",
    tab_quest = "Quest",
    tab_upgrade = "Upgrade",
    tab_materials = "Craft Bait",
    tab_sell = "Auto Sell",
    tab_tp = "Teleport",
    tab_buyrod = "Rod",
    tab_learn = "Learn Skill",
    tab_bait = "Bait",
    tab_visual = "Visual",
    tab_extra = "Extra",
    tab_hop = "Server Hop",
    tab_esp = "ESP",
    tab_info = "Info",
    tab_settings = "Settings",
    auto_phase2 = "Auto Phase 2",
    loaded = "Loaded! By N0NAMEVN"
}
local languageOptions = { "English", "Vietnamese" }
local languageDict = {
    Vietnamese = {
        English = "Tiếng Anh",
        Vietnamese = "Tiếng Việt",
        Spanish = "Tiếng Tây Ban Nha",
        Portuguese = "Tiếng Bồ Đào Nha",
        Japanese = "Tiếng Nhật",
        Main = "Chính",
        ["Auto Fight Enzo"] = "Tự động đánh Enzo",
        ["Start Enzo Fight Now"] = "Bắt đầu đánh Enzo",
        Quest = "Nhiệm vụ",
        ["Craft Bait"] = "Chế tạo mồi",
        ["Auto Sell"] = "Tự động bán",
        Teleport = "Dịch chuyển",
        ["Buy Rod"] = "Cần câu",
        Rod = "Cần câu",
        ["Learn Skill"] = "Học kỹ năng",
        Bait = "Mồi câu",
        Visual = "Hiển thị",
        Extra = "Tiện ích",
        ["Server Hop"] = "Chuyển server",
        Premium = "Premium",
        ESP = "ESP",
        Info = "Thông tin",
        Settings = "Cài đặt",
        Fishing = "Câu cá",
        Configuration = "Cấu hình",
        ["Position Name"] = "Tên vị trí",
        ["Type position name"] = "Nhập tên vị trí",
        ["Create Position"] = "Tạo vị trí",
        ["Select Position"] = "Chọn vị trí",
        ["Teleport Mode"] = "Chế độ dịch chuyển",
        ["No Teleport"] = "Không dịch chuyển",
        ["Save Position"] = "Vị trí đã lưu",
        ["Position Lock"] = "Giữ vị trí",
        Language = "Ngôn ngữ",
        ["Select Language"] = "Chọn ngôn ngữ",
        ["Language changes are runtime only. Default language is English."] = "Ngôn ngữ chỉ đổi trong phiên hiện tại. Mặc định là English.",
        ["Operation Method"] = "Phương thức hoạt động",
        ["Instant [Risk]"] = "Tức thì [Rủi ro]",
        ["Teleport [Risk]"] = "Dịch chuyển [Rủi ro]",
        ["Tween [Safe]"] = "Tween [An toàn]",
        ["Instant sends the remote directly. Teleport moves first. Tween is safer."] = "Tức thì gửi remote trực tiếp. Dịch chuyển sẽ đến nơi trước. Tween an toàn hơn.",
        ["Farm Movement"] = "Cách di chuyển farm",
        ["Ticket Quest always moves to the fishing spot or NPC before sending remotes."] = "Nhiệm vụ vé luôn đến điểm câu hoặc NPC trước khi gửi remote.",
        ["Anchor Bar"] = "Giữ thanh cân bằng",
        ["Auto Cast Rod"] = "Tự động quăng cần",
        ["Auto Use Skills"] = "Tự động dùng kỹ năng",
        ["Select Skills to Auto-Press"] = "Chọn kỹ năng tự động dùng",
        ["Auto Equip"] = "Tự động trang bị",
        ["Auto Equip Best Bait (by Luck)"] = "Tự trang bị mồi tốt nhất theo Luck",
        ["Auto Equip Rod"] = "Tự trang bị cần câu",
        ["Auto Equip Best Orb (by stats)"] = "Tự trang bị orb tốt nhất theo chỉ số",
        ["Equip Best Rod Now"] = "Trang bị cần tốt nhất ngay",
        ["Equip Best Orb Now"] = "Trang bị orb tốt nhất ngay",
        Config = "Cấu hình",
        ["Config Name"] = "Tên cấu hình",
        ["Type config name"] = "Nhập tên cấu hình",
        ["Create Config"] = "Tạo cấu hình",
        ["Select Config"] = "Chọn cấu hình",
        ["Auto Load Config"] = "Tự tải cấu hình",
        ["Auto Save Config"] = "Tự lưu cấu hình",
        ["Load Config"] = "Tải cấu hình",
        ["Overwrite Config"] = "Ghi đè cấu hình",
        ["Delete Config"] = "Xóa cấu hình",
        ["Refresh Config List"] = "Làm mới danh sách cấu hình",
        ["Boss Fishing"] = "Câu Boss",
        ["Favourite Fish"] = "Cá yêu thích",
        ["Auto Skip Fish"] = "Tự bỏ qua cá",
        ["Fishes to Skip"] = "Cá cần bỏ qua",
        ["Select Fish"] = "Chọn cá",
        ["Auto Ticket Quest"] = "Nhiệm vụ vé tự động",
        ["Manual Turn In"] = "Nộp thủ công",
        ["Dump Guy"] = "Dump Guy",
        ["Auto Claim Daily Reward"] = "Tự nhận thưởng hàng ngày",
        ["Daily Quests (Auto)"] = "Nhiệm vụ ngày (Tự động)",
        ["God Spirit"] = "Thần Linh",
        ["Auto Deposit"] = "Tự gửi tiền",
        ["Auto Gacha"] = "Tự quay Gacha",
        ["Tickets per roll"] = "Vé mỗi lần quay",
        PVP = "PVP",
        ["PVP Combat"] = "Chiến đấu PVP",
        ["Auto Skills Method"] = "Cách dùng skill",
        ["Skill Order 1"] = "Thứ tự skill 1",
        ["Skill Order 2"] = "Thứ tự skill 2",
        ["Skill Order 3"] = "Thứ tự skill 3",
        ["Skill Order 4"] = "Thứ tự skill 4",
        ["Select Support Skill"] = "Chọn Support Skill",
        ["Use Support Skill when use skill"] = "Dùng Support khi dùng skill",
        ["Auto Use SK when use selected skill"] = "Tự dùng SK khi dùng skill đã chọn",
        Weather = "Thời tiết",
        ["Weather Farm"] = "Farm thời tiết",
        ["Weather Info"] = "Thông tin thời tiết",
        ["Weather Teleport"] = "Dịch chuyển theo thời tiết",
        Webhook = "Webhook",
        ["Network Trackers"] = "Tracker mạng",
        ["Anti AFK"] = "Chống AFK",
        ["Anti Staff"] = "Chống Staff",
        ["Auto Rejoin"] = "Tự vào lại",
        Notifications = "Thông báo",
        Watermark = "Watermark",
        WalkSpeed = "Tốc độ đi",
        ["No Clip"] = "Xuyên tường",
        ["No Fog"] = "Tắt sương",
        ["Full Bright"] = "Sáng tối đa",
        ["White Screen"] = "Màn hình trắng",
        ["Dark Screen"] = "Màn hình tối",
        ["Hide Game UI"] = "Ẩn UI game",
        ["Hide Player Name"] = "Ẩn tên người chơi",
        ["Auto Evolve Skill"] = "Tự tiến hoá kỹ năng",
        ["Select Skill Slot"] = "Chọn ô kỹ năng",
        ["Auto Teleport + Auto Farm Skill To Evolve"] = "Tự dịch chuyển + Tự farm skill để tiến hoá",
        ["Evolve Skill"] = "Tiến hoá kỹ năng",
        ["Stopped. Previous Anchor / AutoCast states restored."] = "Đã dừng. Đã khôi phục trạng thái Anchor / AutoCast trước đó.",
        ["Events folder not found!"] = "Không tìm thấy thư mục Events!",
        ["FishingMinigame / UseSkill remote not found!"] = "Không tìm thấy remote FishingMinigame / UseSkill!",
        ["Farming on %s with skill [%s]. Waiting for fish..."] = "Đang farm tại %s với skill [%s]. Đang chờ cá...",
        ["Hide Player ID"] = "Ẩn ID người chơi",
        ["Infinite Jump"] = "Nhảy vô hạn",
        ["Fly Mode"] = "Chế độ bay",
        ["Fly Speed"] = "Tốc độ bay",
        ["Walk on Water"] = "Đi trên nước",
        ["Performance Mod"] = "Chế độ hiệu năng",
        Backflip = "Lộn ngược",
        ["Backflip Once"] = "Lộn một lần",
        Troll = "Troll",
        ["Fake Stats"] = "Chỉ số giả",
        ["Fake Level"] = "Level giả",
        ["Fake Money"] = "Tiền giả",
        ["Fake Gems"] = "Gem giả",
        ["Fake Tickets"] = "Vé giả",
        ["Fake Orbs"] = "Orb giả",
        ["Fake Name"] = "Tên giả",
        ["Fake Headless"] = "Headless giả",
        ["Fake Korblox"] = "Korblox giả",
        ["Fake Skin"] = "Skin giả",
        ["Apply Fake Stats"] = "Áp dụng chỉ số giả",
        ["Reset Fake Stats"] = "Reset chỉ số giả",
        ["Apply Fake Skin"] = "Áp dụng skin giả",
        ["Identity Spoof"] = "Giả danh tính",
        ["Avatar Visuals"] = "Hình ảnh avatar",
        ["Skin Tone"] = "Màu da",
        ["Skin Player Name"] = "Tên người chơi lấy skin",
        ["Refresh Visuals"] = "Làm mới hiển thị",
        ["Auto Buy Bait"] = "Tự mua mồi",
        ["Select Bait"] = "Chọn mồi",
        ["Select Bait Type"] = "Chọn loại mồi",
        ["Buy When Below"] = "Mua khi còn dưới",
        ["Quantity per Buy"] = "Số lượng mỗi lần mua",
        ["Auto Craft Bait"] = "Tự chế mồi",
        ["Craft Once"] = "Chế một lần",
        ["Craft Quantity"] = "Số lượng chế",
        ["Auto Craft Rod"] = "Tự chế cần",
        ["Select Rod"] = "Chọn cần",
        ["Material Farming"] = "Farm nguyên liệu",
        ["Material Rod"] = "Farm nguyên liệu cần",
        ["Auto Farm Boss"] = "Tự farm Boss",
        ["Auto Sell Fish"] = "Tự bán cá",
        ["Auto Sell Normal Fish"] = "Chỉ bán cá thường",
        ["Auto Sell Only Boss"] = "Chỉ bán Boss",
        ["Auto Sell Only Secret Boss"] = "Chỉ bán Secret Boss",
        ["Auto Sell When Full"] = "Bán khi đầy túi",
        ["Sell Movement Method"] = "Phương thức bán",
        ["Tween travels to the NPC. Instant sends the sell remote directly."] = "Tween tới NPC. Tức thì gửi remote bán trực tiếp.",
        ["Sell Delay"] = "Độ trễ bán",
        ["Island Teleport"] = "Dịch chuyển đảo",
        ["Select Island"] = "Chọn đảo",
        ["NPC Teleport"] = "Dịch chuyển NPC",
        ["Player Teleport"] = "Dịch chuyển người chơi",
        ["Select Player"] = "Chọn người chơi",
        ["Teleport Player"] = "Dịch chuyển tới người chơi",
        ["Enter Job ID"] = "Nhập Job ID",
        ["Find Match"] = "Tìm trận",
        ["Hop Now"] = "Chuyển ngay",
        ["Auto Hop Enzo"] = "Tự hop Enzo",
        ["Auto Nameless"] = "Tự Nameless",
        ["Auto Minigame"] = "Tự minigame",
        ["Minigame Mode"] = "Chế độ minigame",
        Nameless = "Nameless",
        ["Nameless Octoparasite"] = "Nameless Octoparasite",
        ["Select Skill"] = "Chọn kỹ năng",
        ["Upgrade Skill"] = "Nâng cấp kỹ năng",
        ["Refresh Skills"] = "Làm mới kỹ năng",
        ["Select Method"] = "Chọn phương thức",
        Difficulty = "Độ khó",
        Easy = "Dễ",
        Hard = "Khó",
        ["Hard Farm Location"] = "Vị trí farm nhiệm vụ Khó",
        ["Choose the new sky farm or the original ground farm."] = "Chọn farm trên trời mới hoặc vị trí dưới mặt đất cũ.",
        ["Farm Location"] = "Vị trí farm",
        ["Choose Sky or the original ground position for Easy and Hard."] = "Chọn vị trí trên trời hoặc mặt đất gốc cho cả Dễ và Khó.",
        Sky = "Trên trời",
        Ground = "Mặt đất",
        ["Random Sky Height"] = "Chiều cao ngẫu nhiên",
        ["Uses a moderate random height while keeping X/Z and facing unchanged."] = "Dùng độ cao ngẫu nhiên vừa phải, giữ nguyên X/Z và hướng nhìn.",
        Normal = "Thường",
        ["Phase 2"] = "Giai đoạn 2",
        ["Auto Phase 2"] = "Tự động Phase 2",
        Status = "Trạng thái",
        Runtime = "Runtime",
        Trackers = "Tracker",
        Author = "Tác giả",
        Version = "Phiên bản",
        Discord = "Discord",
        Invite = "Lời mời",
        Refresh = "Làm mới",
        Copy = "Sao chép",
        World = "Thế giới",
        Utilities = "Tiện ích",
        Display = "Hiển thị",
        ["Secret Rod"] = "Cần bí ẩn",
        Locations = "Vị trí",
        Island = "Đảo",
        Player = "Người chơi",
        Daily = "Hàng ngày",
        Reward = "Phần thưởng",
        Delay = "Độ trễ",
        Start = "Bắt đầu",
        Manual = "Thủ công",
        All = "Tất cả",
        Enabled = "Đã bật",
        Disabled = "Đã tắt",
        Quantity = "Số lượng",
        ["Deposit Now"] = "Gửi ngay",
        ["Upgrade Stat"] = "Nâng chỉ số",
        Exchange = "Đổi",
        ["Exchange Now"] = "Đổi ngay",
        ["Redeem Codes"] = "Nhập code",
        ["Redeem All Codes"] = "Nhập tất cả code",
        ["Open Menu"] = "Mở menu",
        ["ESP Objects"] = "Đối tượng ESP",
        ["Clear All ESP"] = "Xóa hết ESP",
        ["Weather ESP"] = "ESP thời tiết",
        ["Skills ESP"] = "Skills ESP",
        ["Show equipped rod skills above all other players' heads."] = "Hiển thị skill của cần đang cầm lên đầu TẤT CẢ người chơi khác.",
        ["Current Status"] = "Trạng thái hiện tại",
        ["How it works"] = "Cách hoạt động",
        Note = "Ghi chú",
        AFK = "AFK",
        Rejoin = "Vào lại",
        Sell = "Bán",
        ["Buy Bait"] = "Mua mồi",
        ["Craft Rod"] = "Chế cần",
        Gacha = "Gacha",
        Index = "Index",
        Skill = "Kỹ năng",
        Material = "Nguyên liệu",
        ["Always Active"] = "Luôn bật",
        ["Only When Weather"] = "Chỉ khi có thời tiết",
        Keyboard = "Bàn phím",
        ["Skill Event"] = "Skill Event",
        Safe = "An toàn",
        ["No Position"] = "Không có vị trí",
        Cash = "Tiền",
        Level = "Cấp",
        Crystal = "Crystal",
        Exp = "Exp",
        ["Loaded! By N0NAMEVN"] = "Đã tải! By N0NAMEVN",
        ["Enter the number only"] = "Chỉ nhập số",
        ["Enter quantity"] = "Nhập số lượng",
        ["Disabled: each execute always starts clean (no previous config)."] = "Đã tắt: mỗi lần chạy luôn bắt đầu sạch (không tải config cũ).",
        ["Disabled permanently. Use Create / Overwrite Config to save manually."] = "Tắt vĩnh viễn. Dùng Tạo / Ghi đè Config để lưu thủ công.",
        ["Client-side click timing only. No remote is fired by Auto Phase 2."] = "Chỉ canh thời gian click ở client. Auto Phase 2 không gọi remote.",
        ["Language changes apply only in the current session."] = "Ngôn ngữ chỉ áp dụng trong phiên hiện tại.",
        ["Default language is English."] = "Ngôn ngữ mặc định là English.",
        ["Hides the top-right player ID label in MainGui."] = "Ẩn nhãn ID góc trên phải trong MainGui.",
        ["Clears workspace.LocalPlayer.HumanoidRootPart.EquippedTitle.PlayerName."] = "Xóa tên trên nhân vật (EquippedTitle.PlayerName).",
        ["Client-side only. Edits level, money, and gem text in your UI."] = "Chỉ phía client. Sửa text level, tiền, gem trên UI của bạn.",
        ["Optional. Leave blank to use the tone dropdown only."] = "Tùy chọn. Để trống nếu chỉ dùng dropdown màu da.",
        ["Flip forward repeatedly. Adjust distance below."] = "Lộn về phía trước liên tục. Chỉnh khoảng cách bên dưới.",
        ["Auto Load is disabled. Script always starts clean each execute."] = "Auto Load đã tắt. Script luôn bắt đầu sạch mỗi lần chạy.",
        ["Auto Save is disabled. Use Create or Overwrite Config manually."] = "Auto Save đã tắt. Hãy dùng Tạo / Ghi đè Config thủ công.",
        ["Native config is ready. Background auto-save is OFF — save only via Create/Overwrite."] = "Config native sẵn sàng. Auto-save nền đã TẮT — chỉ lưu bằng Tạo/Ghi đè.",
        ["Native config unavailable; legacy config storage is active (manual save only)."] = "Config native không khả dụng; đang dùng lưu legacy (chỉ lưu thủ công).",
        ["WindUI-V2 ConfigManager"] = "WindUI-V2 ConfigManager",
        ["Match place detected — only PVP tools loaded"] = "Phát hiện map trận — chỉ tải công cụ PVP",
        ["NNVN Hub · PVP Lite"] = "NNVN Hub · PVP Lite",
        Tween = "Tween",
        Instant = "Tức thì",
        ["Tween Speed"] = "Tốc độ Tween",
        ["NPC interaction"] = "Tương tác NPC",
        ["Accept / Turn-in Ticket Quest uses the selected movement mode before sending remotes."] = "Nhận/nộp Ticket dùng chế độ di chuyển đã chọn rồi mới gửi remote.",
        Chinese = "Tiếng Trung",
        Korean = "Tiếng Hàn",
        Thai = "Tiếng Thái",
        Indonesian = "Tiếng Indonesia",
        French = "Tiếng Pháp",
        German = "Tiếng Đức",
        Russian = "Tiếng Nga",
        Arabic = "Tiếng Ả Rập",
        Hindi = "Tiếng Hindi",
        Turkish = "Tiếng Thổ Nhĩ Kỳ",
        Italian = "Tiếng Ý",
        Polish = "Tiếng Ba Lan"
    }
}
local languageDict2 = {
    Vietnamese = {
        ["Loading runtime info..."] = "Đang tải thông tin runtime...",
        ["Loading tracker info..."] = "Đang tải thông tin tracker...",
        ["Loading invite info..."] = "Đang tải thông tin lời mời...",
        ["Script made by "] = "Script được tạo bởi ",
        Runtime = "Runtime",
        Trackers = "Tracker",
        Author = "Tác giả",
        Version = "Phiên bản",
        ["Phase 2"] = "Giai đoạn 2",
        Status = "Trạng thái",
        Offline = "Ngoại tuyến",
        Online = "Trực tuyến",
        ["Update "] = "Cập nhật ",
        ["Refresh "] = "Làm mới ",
        ["Copy "] = "Sao chép ",
        [" copied!"] = " đã được sao chép!",
        Invite = "Lời mời",
        ["Language changes apply only in the current session."] = "Ngôn ngữ chỉ áp dụng trong phiên hiện tại.",
        ["Default language is English."] = "Ngôn ngữ mặc định là English.",
        ["Client-side click timing only. No remote is fired by Auto Phase 2."] = "Chỉ canh thời gian click ở client. Auto Phase 2 không gọi remote.",
        ["Loading "] = "Đang tải ",
        Main = "Chính",
        Fight = "Đánh",
        Boss = "Boss",
        Quest = "Nhiệm vụ",
        Upgrade = "Nâng cấp",
        Craft = "Chế tạo",
        Bait = "Mồi",
        Sell = "Bán",
        Buy = "Mua",
        Learn = "Học",
        Visual = "Hiển thị",
        Extra = "Tiện ích",
        Weather = "Thời tiết",
        Webhook = "Webhook",
        Info = "Thông tin",
        Settings = "Cài đặt",
        ["Auto "] = "Tự động ",
        ["Select "] = "Chọn ",
        ["Create "] = "Tạo ",
        ["Delete "] = "Xóa ",
        ["Apply "] = "Áp dụng ",
        ["Load "] = "Tải ",
        ["Save "] = "Lưu ",
        ["Claim "] = "Nhận ",
        ["Turn In"] = "Nộp",
        Accept = "Nhận",
        Check = "Kiểm tra",
        ["Teleport to "] = "Dịch chuyển đến ",
        Teleport = "Dịch chuyển",
        Position = "Vị trí",
        Mode = "Chế độ",
        Config = "Cấu hình",
        Theme = "Giao diện",
        Background = "Hình nền",
        Notifications = "Thông báo",
        Watermark = "Watermark",
        Display = "Hiển thị",
        ["Executor Compatibility"] = "Tương thích executor",
        ["Compatibility Report"] = "Báo cáo tương thích",
        ["Check Executor"] = "Kiểm tra executor",
        ["Checks UNC/SUNC capabilities and lists unsupported hub features."] = "Kiểm tra khả năng UNC/SUNC và liệt kê chức năng hub không được hỗ trợ.",
        ["Background Asset"] = "Ảnh nền",
        ["Supports rbxassetid://123456789 and direct image URLs."] = "Hỗ trợ rbxassetid://123456789 và URL ảnh trực tiếp.",
        ["Background Transparency"] = "Độ trong suốt ảnh nền",
        ["Higher values keep controls easier to read."] = "Giá trị cao giúp các nút dễ đọc hơn.",
        ["Clear Background"] = "Xóa ảnh nền",
        World = "Thế giới",
        Utilities = "Tiện ích",
        ["Secret Rod"] = "Cần câu bí ẩn",
        Locations = "Vị trí",
        Island = "Đảo",
        Player = "Người chơi",
        Daily = "Hàng ngày",
        Reward = "Phần thưởng",
        Difficulty = "Độ khó",
        Delay = "Độ trễ",
        Easy = "Dễ",
        Hard = "Khó",
        Start = "Bắt đầu",
        Manual = "Thủ công",
        All = "Tất cả",
        Enabled = "Đã bật",
        Disabled = "Đã tắt",
        ["No "] = "Không ",
        Found = "Tìm thấy",
        here = "tại đây",
        seconds = "giây",
        ["Bought "] = "Đã mua ",
        ["Crafted "] = "Đã chế ",
        ["Sold all fish!"] = "Đã bán hết cá!",
        ["Teleported to "] = "Đã dịch chuyển đến ",
        ["Cannot find "] = "Không tìm thấy ",
        ["Failed: "] = "Thất bại: ",
        ["Farming "] = "Đang farm ",
        ["Joining "] = "Đang vào ",
        Stopped = "Đã dừng",
        ["Premium required"] = "Cần Premium",
        ["ESP refreshed!"] = "ESP đã làm mới!",
        ["All ESP cleared!"] = "Đã xóa hết ESP!",
        ["Invite copied!"] = "Đã sao chép lời mời!",
        ["Best bait: "] = "Mồi tốt nhất: ",
        ["Character not found!"] = "Không tìm thấy nhân vật!",
        ["Enabled [Safe]. Waiting for RhythmStart from server."] = "Đã bật [An toàn]. Đang chờ RhythmStart từ server.",
        ["Disabled | hits "] = "Đã tắt | hits ",
        ["Weather cleared — returning to previous position."] = "Thời tiết hết — đang về vị trí cũ.",
        ["Stopped. Previous feature states restored."] = "Đã dừng. Khôi phục trạng thái tính năng trước đó.",
        ["Disabled. Previous Auto Cast / Anchor / Skills states restored."] = "Đã tắt. Khôi phục Auto Cast / Anchor / Skills trước đó.",
        ["Auto Load is disabled. Script always starts clean each execute."] = "Auto Load đã tắt. Script luôn bắt đầu sạch mỗi lần chạy.",
        ["Auto Save is disabled. Use Create or Overwrite Config manually."] = "Auto Save đã tắt. Hãy dùng Tạo / Ghi đè Config thủ công.",
        ["Match place detected — only PVP tools loaded"] = "Phát hiện map trận — chỉ tải công cụ PVP",
        ["Created config: "] = "Đã tạo cấu hình: ",
        ["Loaded config: "] = "Đã tải cấu hình: ",
        ["Overwrote config: "] = "Đã ghi đè cấu hình: ",
        ["Deleted config: "] = "Đã xóa cấu hình: ",
        ["Config list refreshed."] = "Đã làm mới danh sách cấu hình.",
        ["Applied theme: "] = "Đã áp dụng giao diện: ",
        ["Applied background."] = "Đã áp dụng hình nền.",
        ["Enter an asset ID number first."] = "Hãy nhập ID asset trước.",
        ["This WindUI build cannot change background at runtime."] = "Bản WindUI này không đổi hình nền lúc chạy.",
        ["Create failed"] = "Tạo thất bại",
        ["Overwrite failed"] = "Ghi đè thất bại",
        ["Delete failed"] = "Xóa thất bại",
        ["Could not load config: "] = "Không tải được cấu hình: ",
        ["Farming Boss: "] = "Đang farm Boss: ",
        ["Farming Secret Boss: "] = "Đang farm Secret Boss: ",
        ["Stopped. Previous Anchor / AutoCast states restored."] = "Đã dừng. Đã khôi phục trạng thái Anchor / AutoCast trước đó.",
        ["Events folder not found!"] = "Không tìm thấy thư mục Events!",
        ["FishingMinigame / UseSkill remote not found!"] = "Không tìm thấy remote FishingMinigame / UseSkill!",
        ["Farming on %s with skill [%s]. Waiting for fish..."] = "Đang farm tại %s với skill [%s]. Đang chờ cá...",
        ["Auto Evolve Skill"] = "Tự tiến hoá kỹ năng",
        ["Select Skill Slot"] = "Chọn ô kỹ năng",
        ["Auto Teleport + Auto Farm Skill To Evolve"] = "Tự dịch chuyển + Tự farm skill để tiến hoá",
        ["Evolve Skill"] = "Tiến hoá kỹ năng"
    }
}
local skipTranslationSet = {
    Z = true,
    X = true,
    C = true,
    V = true,
    R = true,
    T = true,
    ["Skill Event"] = true,
    Keyboard = true,
    Dark = true,
    Light = true,
    Rose = true,
    Plant = true,
    Red = true,
    Indigo = true,
    Sky = true,
    Violet = true,
    Amber = true,
    Emerald = true,
    Midnight = true,
    Crimson = true,
    MonokaiPro = true,
    CottonCandy = true,
    Mellowsi = true,
    Rainbow = true,
    ["Blazing Sun"] = true,
    Foggy = true,
    Snowy = true,
    Windy = true,
    Rainy = true,
    Thunderstorm = true,
    Clear = true,
    ["-- no config --"] = true,
    ["No Position"] = true,
    Auto = true
}
local stateMap3 = {}
local function escapePattern(inputValue)
    return tostring(inputValue):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

local function resolveGsub(inputValue, secondValue)
    local languageDict2Entry = languageDict2[secondValue]
    local stateMap3Entry = stateMap3[secondValue]
    if not languageDict2Entry or not stateMap3Entry or inputValue == "" then
        return inputValue
    end
    local inputValue2 = inputValue
    local hasTriggered = false
    for _, item in ipairs(stateMap3Entry) do
        local replacedText, replaceCount = inputValue2:gsub(escapePattern(item), languageDict2Entry[item])
        if replaceCount > 0 then
            inputValue2 = replacedText
            hasTriggered = true
        end
    end
    return hasTriggered and inputValue2 or inputValue
end

(function()
    for key, entry in pairs(languageDict2) do
        local stateMap = {}
        for entryKey in pairs(entry) do
            table.insert(stateMap, entryKey)
        end
        table.sort(stateMap, function(leftItem, rightItem)
            return #rightItem < #leftItem
        end)
        stateMap3[key] = stateMap
    end
end)()
function ShouldSkipUITranslation(text)
    if type(text) ~= "string" or text == "" then
        return true
    end
    if skipTranslationSet[text] then
        return true
    end
    if #text <= 2 and text:match("^[A-Za-z0-9]+$") then
        return true
    end
    if text:match("^[%d%.]+$") then
        return true
    end
    if text:find("rbxassetid://", 1, true) or text:find("https://", 1, true) or text:find("http://", 1, true) then
        return true
    end
    if text:find("|", 1, true) then
        return true
    end
    return false
end

function TranslateText(inputValue)
    if type(inputValue) ~= "string" then
        return inputValue
    end
    if ShouldSkipUITranslation(inputValue) then
        return inputValue
    end
    local language = getgenv().NNVN_Language or "English"
    if language == "English" then
        return inputValue
    end
    local languageDictEntry = languageDict[language]
    if languageDictEntry and languageDictEntry[inputValue] then
        return languageDictEntry[inputValue]
    end
    return resolveGsub(inputValue, language)
end

function NormalizeTranslatedChoice(inputValue, secondValue)
    inputValue = tostring(inputValue or secondValue or "")
    if inputValue == secondValue then
        return inputValue
    end
    for _, entry in pairs(languageDict) do
        for key, entry2 in pairs(entry) do
            if inputValue == entry2 then
                return key
            end
        end
    end
    return inputValue
end

function ApplyUILanguage()
    if (getgenv().NNVN_Language or "English") == "English" then
        return
    end
    local lookupMap = {}
    for _, entry in pairs(languageDict) do
        for key, entry2 in pairs(entry) do
            lookupMap[entry2] = key
        end
    end
    local function resolveLower(instance)
        if not instance then
            return false
        end
        local formattedText = string.lower(tostring(instance.Name or ""))
        if formattedText:find("wind", 1, true) or formattedText:find("nnvn", 1, true) or formattedText:find("hub", 1, true) then
            return true
        end
        return false
    end
    local function checkAttribute(instance)
        if not instance:IsA("TextLabel") and not instance:IsA("TextButton") and not instance:IsA("TextBox") then
            return
        end
        local formattedText = instance.Parent and string.lower(tostring(instance.Parent.Name or "")) or ""
        if formattedText:find("option", 1, true) or formattedText:find("dropdownitem", 1, true) then
            local text = instance.Text or ""
            if (ShouldSkipUITranslation(text) or #text <= 24 and not languageDict[getgenv().NNVN_Language or "English"]) and ShouldSkipUITranslation(text) then
                return
            end
        end
        local englishTextAttr = instance:GetAttribute("NNVN_EnglishText")
        if not englishTextAttr then
            englishTextAttr = lookupMap[instance.Text] or instance.Text
            instance:SetAttribute("NNVN_EnglishText", englishTextAttr)
        end
        if ShouldSkipUITranslation(englishTextAttr) then
            return
        end
        local translateTextResult = TranslateText(englishTextAttr)
        if instance.Text ~= translateTextResult then
            instance.Text = translateTextResult
        end
        if instance:IsA("TextBox") then
            local englishPlaceholderAttr = instance:GetAttribute("NNVN_EnglishPlaceholder")
            if not englishPlaceholderAttr then
                englishPlaceholderAttr = instance.PlaceholderText or ""
                instance:SetAttribute("NNVN_EnglishPlaceholder", englishPlaceholderAttr)
            end
            if not ShouldSkipUITranslation(englishPlaceholderAttr) then
                local translateTextResult2 = TranslateText(englishPlaceholderAttr)
                if instance.PlaceholderText ~= translateTextResult2 then
                    instance.PlaceholderText = translateTextResult2
                end
            end
        end
    end
    local itemList = { CoreGui }
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        table.insert(itemList, LocalPlayer.PlayerGui)
    end
    for _, item in ipairs(itemList) do
        for _, item2 in ipairs(item:GetChildren()) do
            if not item2:IsA("ScreenGui") or not resolveLower(item2) then
                continue
            end
            for _, item3 in ipairs(item2:GetDescendants()) do
                pcall(checkAttribute, item3)
            end
        end
    end
end

if item and type(item.Notify) == "function" and not item.__NNVN_NotifyPatched then
    local notify2 = item.Notify
    item.__NNVN_NotifyPatched = true
    item.Notify = function(inputValue, options)
        options = type(options) == "table" and options or {}
        local function resolveLower(inputValue)
            if inputValue == nil then
                return ""
            end
            local inputValueText = tostring(inputValue)
            local matchedText = string.lower(inputValueText):match("^%s*(.-)%s*$")
            if matchedText == "nil" or matchedText == "null" then
                return ""
            end
            return inputValueText
        end
        local lower = resolveLower(options.Title)
        local lower2 = resolveLower(options.Description ~= nil and options.Description or options.Content)
        if lower ~= "" then
            lower = TranslateText(lower)
        end
        if lower2 ~= "" then
            lower2 = TranslateText(lower2)
        end
        local parsedNum = tonumber(options.Time or options.Duration) or 4
        options.Title = lower
        options.Content = lower2
        options.Description = lower2
        options.Time = parsedNum
        options.Duration = parsedNum
        return notify2(inputValue, options)
    end
end
local phiThien1Map = {
    ["Phi Thien 1"] = CFrame.new(-1339.64441, 9.16392136, -1474.99878, 0, 0, -1, 0, 1, 0, 1, 0, 0),
    ["Phi Thien 2"] = CFrame.new(-262.254364, 9.76392174, 98.6261902, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    ["Phi Thien 3"] = CFrame.new(1471.94446, 9.17344284, -1453.31006, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Phi Thien 4"] = CFrame.new(-1266.40442, 9.16392136, -11.1238098, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Phi Thien 5"] = CFrame.new(-56.2965813, 9.26392174, -1303.23645, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    ["Phi Thien 6"] = CFrame.new(1221.60815, 9.15180397, 1408.77698, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    ["Phi Thien 7"] = CFrame.new(50.6459999, 9.16400051, 1135.42603, 0, 0, -1, 0, 1, 0, 1, 0, 0),
    ["Phi Thien 8"] = CFrame.new(-1247.3999, 9.25, 1257.20007, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    ["Battlefield Isle's Phi Thien"] = CFrame.new(1520.50647, 46.9576187, -46.7681236),
    ["Mistpeak Isle's Phi Thien"] = CFrame.new(2621.07202, 9.23625088, -86.6871414),
    ["Sage Yijiu"] = CFrame.new(-163.967422, 7.28192425, -9.39642334, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Zeng Tianguo"] = CFrame.new(145.217529, 6.72139692, 1371.89539),
    ["Nameless Bait Farm"] = CFrame.new(3013.14722, 15.525135, -124.574158, 0.541496873, 3.77300111e-08, -0.840702772, 1.24950628e-08, 1, 5.29272057e-08, 0.840702772, -3.91645507e-08, 0.541496873),
    ["World Angler Isle"] = CFrame.new(-2411.90649, 7.6426816, -202.059006, 1.49011612e-08, -3.41527056e-08, -1, -1.08602682e-09, 1, -3.41527056e-08, 1, 1.08602738e-09, 1.49011612e-08)
}
local delaySeconds = 0.38
local delaySeconds2 = 3.5
local nameList = {
    "Ba Chang",
    "Ba Thuong",
    "Bait Seller",
    "AmberIsle's Ba Thuong",
    "Coconut Isle's Ba Thuong",
    "Frost Isle's Ba Thuong",
    "Perch Isle's Ba Thuong",
    "Sovereign Isle's Ba Thuong"
}
local nameList2 = {
    "Gacha NPC",
    "Gacha",
    "Banner NPC",
    "Wish NPC",
    "Roll NPC",
    "Lucky Chest",
    "Gacha Machine"
}
local nameList3 = {
    "Daily Reward",
    "Daily NPC",
    "Daily",
    "Claim Daily",
    "Chest Daily",
    "Daily Chest"
}
local nameList4 = {
    "Rebirth NPC",
    "Upgrade NPC",
    "Zeng Tianguo",
    "Rebirth",
    "Upgrade",
    "Ascend NPC"
}
local item4
function NormalizeNPCName(inputValue)
    return string.lower(tostring(inputValue or "")):gsub("[^%w]", "")
end

function FindBestNPCMatch(instance, secondValue)
    if not instance or not secondValue or secondValue == "" then
        return nil
    end
    local npcName = NormalizeNPCName(secondValue)
    local item
    local negValue = -math.huge
    consider = function(instance2)
        if not instance2:IsA("Model") and not instance2:IsA("BasePart") then
            return
        end
        local item2
        local name = instance2.Name
        local npcName2 = NormalizeNPCName(name)
        if name == secondValue then
            item2 = 400
        elseif npcName2 == npcName then
            item2 = 320
        elseif string.find(npcName2, npcName, 1, true) then
            item2 = 220
        elseif string.find(npcName, npcName2, 1, true) then
            item2 = 180
        end
        if not item2 then
            return
        end
        if item4(instance2) then
            item2 = item2 + 50
        end
        if instance2.Parent == instance then
            item2 = item2 + 10
        end
        if negValue < item2 then
            negValue = item2
            item = instance2
        end
    end
    local instanceEntry = instance:FindFirstChild(secondValue, true)
    if instanceEntry and (instanceEntry:IsA("Model") or instanceEntry:IsA("BasePart")) then
        return instanceEntry
    end
    for _, item2 in ipairs(instance:GetDescendants()) do
        consider(item2)
    end
    return item
end

function FindNPCByName(inputValue)
    if not inputValue or inputValue == "" then
        return nil
    end
    local npcFolder = Workspace:FindFirstChild("NPC")
    if npcFolder then
        local bestNpcMatch = FindBestNPCMatch(npcFolder, inputValue)
        if bestNpcMatch then
            return bestNpcMatch
        end
    end
    for _, item in ipairs(Workspace:GetDescendants()) do
        local npcName = NormalizeNPCName(item.Name)
        local npcName2 = NormalizeNPCName(inputValue)
        if (item:IsA("Model") or item:IsA("BasePart")) and (item.Name == inputValue or npcName == npcName2) then
            return item
        end
    end
    return nil
end

function FindNPCFromList(inputValue)
    for _, item in ipairs(inputValue) do
        local npcByName = FindNPCByName(item)
        if npcByName then
            return npcByName
        end
    end
    return nil
end

function item4(instance)
    if not instance then
        return nil
    end
    if instance:IsA("BasePart") then
        return instance
    end
    return instance:FindFirstChild("HumanoidRootPart", true) or instance:FindFirstChild("RootPart", true) or instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
end

function TPNear(inputValue, secondValue)
    secondValue = secondValue or delaySeconds2
    if type(NNVN_MoveNear) ~= "function" then
        return false
    end
    return NNVN_MoveNear(inputValue, secondValue, GetActionMethod())
end

function WithSavedPosition(inputValue)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local cFrame = rootPart and rootPart.CFrame
    local ok, result = pcall(inputValue, rootPart, cFrame)
    if rootPart and cFrame then
        task.wait(0.2)
        pcall(function()
            NNVN_TweenTo(cFrame)
        end)
    end
    return ok, result
end

local tweenAnchor = workspace:FindFirstChild("NNVN_TweenAnchor")
if not tweenAnchor then
    tweenAnchor = Instance.new("Part")
    tweenAnchor.Name = "NNVN_TweenAnchor"
    tweenAnchor.Size = Vector3.new(1, 1, 1)
    tweenAnchor.Anchored = true
    tweenAnchor.CanCollide = false
    tweenAnchor.CanTouch = false
    tweenAnchor.Transparency = 1
    tweenAnchor.Parent = workspace
end
local hasTriggered = false
local item5
local item6
function NNVN_StopTween()
    hasTriggered = false
    if item5 then
        pcall(function()
            item5:Cancel()
        end)
        item5 = nil
    end
    if item6 then
        pcall(function()
            item6:Disconnect()
        end)
        item6 = nil
    end
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local bodyClip = character.HumanoidRootPart:FindFirstChild("NNVN_BodyClip")
        if bodyClip then
            bodyClip:Destroy()
        end
    end
end

function NNVN_ResolveMoveCF(inputValue, secondValue)
    secondValue = secondValue or delaySeconds2
    if typeof(inputValue) == "CFrame" then
        return inputValue
    elseif typeof(inputValue) == "Vector3" then
        return CFrame.new(inputValue)
    end
    local item
    if type(inputValue) == "string" then
        item = FindNPCByName(inputValue)
        if not item then
            local phiThien1Entry = phiThien1Map and phiThien1Map[inputValue]
            if phiThien1Entry then
                return phiThien1Entry + Vector3.new(0, 2, 0)
            end
            return nil
        end
    else
        item = inputValue
    end
    if not item then
        return nil
    end
    local item4Result = item4(item)
    if not item4Result then
        return nil
    end
    return CFrame.new(item4Result.Position - item4Result.CFrame.LookVector * secondValue + Vector3.new(0, 2, 0), item4Result.Position)
end

function NNVN_TweenToRaw(target, secondValue)
    secondValue = tonumber(secondValue) or getgenv().NNVN_TweenSpeed or 300
    local character = LocalPlayer.Character
    if not character then
        return false
    end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid or humanoid.Health <= 0 then
        return false
    end
    if typeof(target) == "Vector3" then
        target = CFrame.new(target)
    elseif typeof(target) ~= "CFrame" then
        return false
    end
    if getgenv().NNVN_SafetyMode then
        local computedValue = math.max(0, tonumber(getgenv().NNVN_TweenStartDelay) or 0.2) - (os.clock() - (tonumber(getgenv().NNVN_LastSafetyTweenAt) or 0))
        if computedValue > 0 then
            task.wait(computedValue)
        end
        local nowTime = os.clock()
        local lastSafetyTweenTarget = getgenv().NNVN_LastSafetyTweenTarget
        if getgenv().NNVN_BlockDuplicateTween and typeof(lastSafetyTweenTarget) == "CFrame" and (lastSafetyTweenTarget.Position - target.Position).Magnitude <= 1 and nowTime - (tonumber(getgenv().NNVN_LastSafetyTweenAt) or 0) < 1 and (rootPart.Position - target.Position).Magnitude <= 9 then
            return true
        end
        getgenv().NNVN_LastSafetyTweenAt = nowTime
        getgenv().NNVN_LastSafetyTweenTarget = target
    end
    local magnitude = (rootPart.Position - target.Position).Magnitude
    if magnitude <= 0.5 then
        rootPart.CFrame = target
        return true
    end
    NNVN_StopTween()
    hasTriggered = true
    tweenAnchor.CFrame = rootPart.CFrame
    if not rootPart:FindFirstChild("NNVN_BodyClip") then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "NNVN_BodyClip"
        bodyVelocity.MaxForce = Vector3.new(1000000000, 1000000000, 1000000000)
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.Parent = rootPart
    end
    for _, item in ipairs(character:GetDescendants()) do
        if item:IsA("BasePart") then
            item.CanCollide = false
        end
    end
    local createResult = TweenService:Create(tweenAnchor, TweenInfo.new(math.clamp(magnitude / secondValue, 0.08, 40), Enum.EasingStyle.Linear), { CFrame = target })
    item5 = createResult
    createResult:Play()
    local hasTriggered2 = false
    item6 = RunService.Heartbeat:Connect(function()
        if not hasTriggered or not rootPart or not rootPart.Parent then
            return
        end
        rootPart.CFrame = tweenAnchor.CFrame
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        if (rootPart.Position - target.Position).Magnitude <= 5.5 then
            hasTriggered2 = true
        end
    end)
    pcall(function()
        createResult.Completed:Wait()
    end)
    if item6 then
        pcall(function()
            item6:Disconnect()
        end)
        item6 = nil
    end
    if rootPart and rootPart.Parent then
        rootPart.CFrame = target
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end
    NNVN_StopTween()
    return hasTriggered2 or rootPart and (rootPart.Position - target.Position).Magnitude <= 9
end

function NormalizeActionMethodName(text)
    text = tostring(text or "Tween [Safe]")
    if text:find("Instant", 1, true) then
        return "Instant"
    end
    if text:find("Teleport", 1, true) then
        return "Teleport"
    end
    return "Tween"
end

function NNVN_SetRootCFrame(target)
    if typeof(target) == "Vector3" then
        target = CFrame.new(target)
    end
    if typeof(target) ~= "CFrame" then
        return false
    end
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end
    NNVN_StopTween()
    rootPart.CFrame = target
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.08)
    return rootPart.Parent ~= nil and (rootPart.Position - target.Position).Magnitude <= 10
end

function NNVN_MoveToCFrame(inputValue, secondValue, thirdValue)
    local actionMethodName = NormalizeActionMethodName(secondValue or getgenv().NNVN_ActionMethod)
    if actionMethodName == "Teleport" or actionMethodName == "Instant" then
        return NNVN_SetRootCFrame(inputValue)
    end
    return NNVN_TweenToRaw(inputValue, thirdValue)
end

function NNVN_TweenTo(inputValue, secondValue)
    return NNVN_MoveToCFrame(inputValue, getgenv().NNVN_ActionMethod, secondValue)
end

function NNVN_MoveNear(inputValue, secondValue, thirdValue)
    local actionMethodName = NormalizeActionMethodName(thirdValue or getgenv().NNVN_ActionMethod)
    if actionMethodName == "Instant" then
        return true
    end
    local moveCf = NNVN_ResolveMoveCF(inputValue, secondValue)
    if not moveCf then
        if type(inputValue) == "function" then
            return inputValue() ~= false
        end
        return false
    end
    local hasTriggered = false
    if actionMethodName == "Teleport" then
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = moveCf
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            task.wait(0.12)
            hasTriggered = (rootPart.Position - moveCf.Position).Magnitude <= 10
        end
    else
        hasTriggered = NNVN_MoveToCFrame(moveCf, actionMethodName) == true
    end
    task.wait(0.12)
    return hasTriggered
end

getgenv().NNVN_TweenTo = NNVN_TweenTo
getgenv().NNVN_TweenToRaw = NNVN_TweenToRaw
getgenv().NNVN_MoveToCFrame = NNVN_MoveToCFrame
getgenv().NNVN_StopTween = NNVN_StopTween
getgenv().NNVN_MoveNear = NNVN_MoveNear
function GetActionMethod()
    return NormalizeActionMethodName(getgenv().NNVN_ActionMethod)
end

function NNVN_RemoteAllowed(inputValue, secondValue)
    if not getgenv().NNVN_SafetyMode then
        return true
    end
    local remoteSafetyTimes = getgenv().NNVN_RemoteSafetyTimes or {}
    getgenv().NNVN_RemoteSafetyTimes = remoteSafetyTimes
    local nowTime = os.clock()
    if nowTime - (tonumber(remoteSafetyTimes[inputValue]) or 0) < math.max(tonumber(getgenv().NNVN_RemoteMinInterval) or 0.75, tonumber(secondValue) or 0) then
        return false
    end
    remoteSafetyTimes[inputValue] = nowTime
    return true
end

function RunActionWithMethod(inputValue, secondValue)
    inputValue = inputValue or {}
    local actionMethodName = NormalizeActionMethodName(inputValue.forceMethod or GetActionMethod())
    local item
    if inputValue.returnAfter then
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        item = rootPart and rootPart.CFrame
    end
    local ok, result = pcall(function()
        if actionMethodName ~= "Instant" then
            local isEnabled = true
            if inputValue.target then
                isEnabled = NNVN_MoveNear(inputValue.target, inputValue.offsetDist, actionMethodName)
            elseif type(inputValue.teleport) == "function" then
                isEnabled = inputValue.teleport()
            end
            if isEnabled == false and inputValue.requireTeleport ~= false then
                return
            end
        end
        return secondValue()
    end)
    if inputValue.returnAfter and item then
        local character2 = LocalPlayer.Character
        if character2 and character2:FindFirstChild("HumanoidRootPart") then
            NNVN_MoveToCFrame(item, actionMethodName)
        end
    end
    return ok, result
end

function ProxFire(inputValue, secondValue, ...)
    local itemList = { ... }
    RunActionWithMethod({ target = secondValue, returnAfter = getgenv().NNVN_ReturnAfterQuestTP }, function()
        inputValue:FireServer(table.unpack(itemList))
    end)
end

function ProxInvoke(inputValue, secondValue, ...)
    local itemList = { ... }
    local item
    RunActionWithMethod({ target = secondValue, returnAfter = getgenv().NNVN_ReturnAfterQuestTP }, function()
        item = inputValue:InvokeServer(table.unpack(itemList))
    end)
    return item
end

function TPNearBaitSeller()
    local buyBait = Workspace:FindFirstChild("NPC") and Workspace.NPC:FindFirstChild("BuyBait")
    local bestNpcMatch = buyBait and (FindBestNPCMatch(buyBait, "Ba Chang") or FindBestNPCMatch(buyBait, "Ba Thuong") or FindBestNPCMatch(buyBait, "Bait Seller"))
    if not bestNpcMatch then
        bestNpcMatch = FindNPCFromList(nameList)
    end
    if bestNpcMatch then
        TPNear(bestNpcMatch)
        return true
    end
    return false
end

function TPNearGachaNPC()
    local npcFromList = FindNPCFromList(nameList2)
    if npcFromList then
        TPNear(npcFromList)
        return true
    end
    return false
end

function TPNearDailyNPC()
    local npcFromList = FindNPCFromList(nameList3)
    if npcFromList then
        TPNear(npcFromList)
        return true
    end
    return false
end

function TPNearRebirthNPC()
    local npcFromList = FindNPCFromList(nameList4)
    if npcFromList then
        TPNear(npcFromList)
        return true
    end
    local zengTianguo = phiThien1Map["Zeng Tianguo"]
    if zengTianguo then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                NNVN_TweenTo(zengTianguo + Vector3.new(0, 2, 0))
            end)
            task.wait(delaySeconds)
            return true
        end
    end
    return false
end

function TPNearRodSeller(inputValue)
    local npcByName = FindNPCByName(inputValue)
    if npcByName then
        TPNear(npcByName)
        return true
    end
    return false
end

function ProxEquipBait(inputValue)
    return ProxInvoke(ReplicatedStorage.Events.EquipBait, nil, inputValue)
end

function ProxEquipRod(inputValue)
    return ProxInvoke(ReplicatedStorage.Events.EquipFishingRod, nil, inputValue)
end

function ProxEquipOrb(inputValue)
    return ProxInvoke(ReplicatedStorage.Events.EquipOrb, nil, inputValue)
end

getgenv().NNVN_TPNear = TPNear
getgenv().NNVN_FindNPCByName = FindNPCByName
getgenv().NNVN_ProxFire = ProxFire
getgenv().NNVN_ProxInvoke = ProxInvoke
function GetPlayerData()
    return ReplicatedStorage.Data:FindFirstChild(tostring(LocalPlayer.UserId))
end

local dumbGuyLabel = "Dumb guy"
local maxLimit = 2000000
function getFishWeightFromInventoryName(inputValue)
    local matchedText = tostring(inputValue or ""):match("|%s*([%d,.]+)%s*$")
    if not matchedText then
        return nil
    end
    return tonumber(matchedText:gsub(",", ""))
end

function getFishOverWeight(inputValue)
    local playerData = GetPlayerData()
    local inventory = playerData and playerData:FindFirstChild("Inventory")
    local stateMap = {}
    inputValue = tonumber(inputValue) or maxLimit
    if not inventory then
        return stateMap
    end
    for _, item in ipairs(inventory:GetChildren()) do
        local fishWeightFromInventory = getFishWeightFromInventoryName(item.Name)
        if item:IsA("NumberValue") and fishWeightFromInventory and inputValue < fishWeightFromInventory and item.Value > 0 then
            table.insert(stateMap, { Name = item.Name, Weight = fishWeightFromInventory })
        end
    end
    table.sort(stateMap, function(leftItem, rightItem)
        return rightItem.Weight < leftItem.Weight
    end)
    return stateMap
end

function getDumpGuySlotState(inputValue)
    local playerData = GetPlayerData()
    local hotbar = playerData and playerData:FindFirstChild("Hotbar")
    local hotbarEntry = hotbar and hotbar:FindFirstChild(tostring(inputValue))
    local valueName = hotbarEntry and hotbarEntry:FindFirstChild("ValueName")
    local quantity = hotbarEntry and hotbarEntry:FindFirstChild("Quantity")
    if not valueName or not quantity then
        return nil
    end
    return {
        Name = tostring(valueName.Value or ""),
        Quantity = tonumber(quantity.Value) or 0,
        Weight = getFishWeightFromInventoryName(valueName.Value)
    }
end

function getHotbarSlotWeight(inputValue)
    local dumpGuySlotState = getDumpGuySlotState(inputValue)
    return dumpGuySlotState and dumpGuySlotState.Weight
end

function getHotbarSlotFishName(inputValue)
    local dumpGuySlotState = getDumpGuySlotState(inputValue)
    return dumpGuySlotState and dumpGuySlotState.Name
end

function getSelectedFishHotbarSlot()
    local clampResult = math.clamp(math.floor(tonumber(getgenv().NNVN_DumpGuyHotbarSlot) or 4), 1, 10)
    if not getDumpGuySlotState(clampResult) then
        return nil, "Hotbar data was not found."
    end
    return tostring(clampResult)
end

function moveFishToInventory(inputValue)
    local events = ReplicatedStorage:FindFirstChild("Events")
    local moveItems = events and events:FindFirstChild("MoveItems")
    if not moveItems then
        return false
    end
    if not pcall(function()
        moveItems:FireServer("Hotbar", tonumber(inputValue))
    end) then
        return false
    end
    for i = 1, 20 do
        task.wait(0.1)
        local dumpGuySlotState = getDumpGuySlotState(inputValue)
        if dumpGuySlotState and dumpGuySlotState.Quantity <= 0 and (dumpGuySlotState.Name == "" or dumpGuySlotState.Name == "Inventory") then
            return true
        end
    end
    return false
end

function notifyDumpGuySlotIssue(inputValue)
    local nowTime = tick()
    if nowTime - (getgenv().NNVN_DumpGuyLastSlotWarning or 0) < 3 then
        return
    end
    getgenv().NNVN_DumpGuyLastSlotWarning = nowTime
    if getgenv().NNVN_Notify and item then
        item:Notify({
            Title = "Dump Guy",
            Content = inputValue,
            Duration = 4,
            Icon = "circle-alert"
        })
    end
end

function moveFishToEmptyHotbarSlot(inputValue, secondValue)
    local moveItems = ReplicatedStorage.Events:FindFirstChild("MoveItems")
    if not moveItems or not inputValue or not secondValue then
        return false
    end
    if not pcall(function()
        moveItems:FireServer("Inventory", inputValue, secondValue)
    end) then
        return false
    end
    for i = 1, 10 do
        task.wait(0.15)
        local playerData = GetPlayerData()
        local hotbarEntry = playerData and playerData:FindFirstChild("Hotbar") and playerData.Hotbar:FindFirstChild(secondValue)
        local valueName = hotbarEntry and hotbarEntry:FindFirstChild("ValueName")
        local quantity = hotbarEntry and hotbarEntry:FindFirstChild("Quantity")
        if valueName and quantity and tostring(valueName.Value) == tostring(inputValue) and tonumber(quantity.Value) and tonumber(quantity.Value) > 0 then
            return true
        end
    end
    return false
end

function isHoldingFish()
    local character = LocalPlayer.Character
    if not character then
        return false
    end
    return character:GetAttribute("Type") == "Fish"
end

function selectFishHotbarSlot(inputValue, secondValue)
    local toggleHotbar = ReplicatedStorage.Events:FindFirstChild("ToggleHotbar")
    if not toggleHotbar or not inputValue then
        return false
    end
    if not pcall(function()
        toggleHotbar:InvokeServer(tonumber(inputValue), nil)
    end) then
        return false
    end
    for i = 1, 12 do
        task.wait(0.1)
        if not isHoldingFish() then
            continue
        end
        local character = LocalPlayer.Character
        local tool = character and character:FindFirstChildOfClass("Tool")
        if tool then
            if not secondValue or tool.Name == secondValue or tool:GetAttribute("ValueName") == secondValue or tostring(tool:GetAttribute("FishName") or "") == secondValue then
                return true
            end
        else
            return true
        end
    end
    return false
end

function TeleportToDumpGuyExact()
    local npcByName = FindNPCByName(dumbGuyLabel)
    local rootPart = npcByName and npcByName:FindFirstChild("HumanoidRootPart", true)
    local rootPart2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart or not rootPart2 then
        return false
    end
    local callOk = pcall(function()
        NNVN_TweenTo(rootPart.CFrame)
    end)
    if callOk then
        task.wait(delaySeconds)
    end
    return callOk
end

function interactWithDumpGuy()
    local chooseDialogueOption = ReplicatedStorage.Events:FindFirstChild("ChooseDialogueOption")
    if not chooseDialogueOption then
        if getgenv().NNVN_Notify and item then
            item:Notify({
                Title = "Dump Guy",
                Content = "Remote ChooseDialogueOption not found!",
                Duration = 3,
                Icon = "circle-alert"
            })
        end
        return false
    end
    local npcFolder = Workspace:FindFirstChild("NPC")
    local functionValue = npcFolder and npcFolder:FindFirstChild("Function")
    local dumbGuy = functionValue and functionValue:FindFirstChild("Dumb guy")
    if not dumbGuy then
        dumbGuy = FindNPCByName(dumbGuyLabel)
    end
    if not dumbGuy then
        if getgenv().NNVN_Notify and item then
            item:Notify({
                Title = "Dump Guy",
                Content = "Dumb guy function not found in workspace!",
                Duration = 3,
                Icon = "circle-alert"
            })
        end
        return false
    end
    if pcall(function()
        chooseDialogueOption:FireServer("Dumb guy", 1, "GiveFish", { dumbGuy })
    end) then
        return true
    end
    local proximityPrompt = dumbGuy:FindFirstChild("ProximityPrompt", true)
    if proximityPrompt and fireproximityprompt then
        pcall(function()
            fireproximityprompt(proximityPrompt)
        end)
        return true
    end
    return false
end

function giveFishToDumpGuy()
    local clampResult = math.clamp(math.floor(tonumber(getgenv().NNVN_DumpGuyHotbarSlot) or 4), 1, 10)
    local clampResultText = tostring(clampResult)
    local hotbarSlotWeight = getHotbarSlotWeight(clampResult)
    if hotbarSlotWeight and maxLimit <= hotbarSlotWeight then
        if not selectFishHotbarSlot(clampResultText) then
            return false, "Could not equip fish from hotbar slot " .. clampResultText
        end
        task.wait(0.3)
        if not isHoldingFish() then
            return false, "Not holding a fish!"
        end
        if not TeleportToDumpGuyExact() then
            return false, "Could not reach Dump Guy."
        end
        if not interactWithDumpGuy() then
            return false, "Could not interact with Dump Guy."
        end
        return true, getHotbarSlotFishName(clampResult) or "Fish"
    end
    local hotbarSlotFishName = getHotbarSlotFishName(clampResult)
    if hotbarSlotFishName and hotbarSlotFishName ~= "" and hotbarSlotFishName ~= "Inventory" then
        moveFishToInventory(clampResult)
        task.wait(0.3)
    end
    local fishOverWeight = getFishOverWeight(maxLimit - 1)
    if #fishOverWeight == 0 then
        return false, "No fish at least 2,000,000 kg found."
    end
    local fishOverWeightEntry = fishOverWeight[1]
    if not moveFishToEmptyHotbarSlot(fishOverWeightEntry.Name, clampResultText) then
        return false, "Could not move " .. fishOverWeightEntry.Name .. " to hotbar"
    end
    task.wait(0.3)
    if not selectFishHotbarSlot(clampResultText, fishOverWeightEntry.Name) then
        return false, "Could not equip " .. fishOverWeightEntry.Name
    end
    task.wait(0.3)
    if not isHoldingFish() then
        return false, "Not holding a fish!"
    end
    if not TeleportToDumpGuyExact() then
        return false, "Could not reach Dump Guy."
    end
    if not interactWithDumpGuy() then
        return false, "Could not interact with Dump Guy."
    end
    return true, fishOverWeightEntry.Name
end

function dumpGuyLoop()
    while getgenv().NNVN_AutoGiveFish do
        pcall(function()
            local clampResult = math.clamp(math.floor(tonumber(getgenv().NNVN_DumpGuyHotbarSlot) or 4), 1, 10)
            local clampResultText = tostring(clampResult)
            local hotbarSlotWeight = getHotbarSlotWeight(clampResult)
            if hotbarSlotWeight and maxLimit <= hotbarSlotWeight then
                if not selectFishHotbarSlot(clampResultText) then
                    notifyDumpGuySlotIssue("Could not equip fish from hotbar slot " .. clampResultText)
                    return
                end
                task.wait(0.3)
                if not isHoldingFish() then
                    notifyDumpGuySlotIssue("Not holding a fish!")
                    return
                end
                if TeleportToDumpGuyExact() then
                    interactWithDumpGuy()
                end
                task.wait(1)
            else
                local hotbarSlotFishName = getHotbarSlotFishName(clampResult)
                if hotbarSlotFishName and hotbarSlotFishName ~= "" and hotbarSlotFishName ~= "Inventory" then
                    moveFishToInventory(clampResult)
                    task.wait(0.3)
                end
                local fishOverWeight = getFishOverWeight(maxLimit - 1)
                if #fishOverWeight > 0 then
                    local fishOverWeightEntry = fishOverWeight[1]
                    if not moveFishToEmptyHotbarSlot(fishOverWeightEntry.Name, clampResultText) then
                        notifyDumpGuySlotIssue("Could not move " .. fishOverWeightEntry.Name .. " to hotbar")
                        return
                    end
                    task.wait(0.3)
                    if not selectFishHotbarSlot(clampResultText, fishOverWeightEntry.Name) then
                        notifyDumpGuySlotIssue("Could not equip " .. fishOverWeightEntry.Name)
                        return
                    end
                    task.wait(0.3)
                    if not isHoldingFish() then
                        notifyDumpGuySlotIssue("Not holding a fish!")
                        return
                    end
                    if TeleportToDumpGuyExact() then
                        interactWithDumpGuy()
                    end
                    task.wait(1)
                end
            end
        end)
        task.wait(1)
    end
end

function startAutoGiveFishLoop()
    if getgenv().NNVN_AutoGiveFishLoop then
        return
    end
    getgenv().NNVN_AutoGiveFishLoop = true
    task.spawn(function()
        while getgenv().NNVN_AutoGiveFishLoop do
            if getgenv().NNVN_AutoGiveFish then
                dumpGuyLoop()
            end
            task.wait(1)
        end
    end)
end

function setAutoGiveFishEnabled(inputValue)
    getgenv().NNVN_AutoGiveFish = inputValue == true
    if inputValue then
        startAutoGiveFishLoop()
    end
end

function setAutoFarm2MFish(inputValue)
    if inputValue then
        if not getgenv().NNVN_2MFishPrevFlags then
            getgenv().NNVN_2MFishPrevFlags = {
                Anchor = getgenv().NNVN_Anchor,
                AutoCast = getgenv().NNVN_AutoCast,
                AutoSkill = getgenv().NNVN_AutoSkill
            }
        end
        if not getgenv().NNVN_2MFishPrevPos then
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                getgenv().NNVN_2MFishPrevPos = rootPart.CFrame
            end
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                NNVN_TweenTo(getgenv().NNVN_2MFishFarmCFrame)
            end)
        end
        getgenv().NNVN_Anchor = true
        getgenv().NNVN_AutoCast = true
        getgenv().NNVN_AutoSkill = true
        if not HasFishingRod() then
            pcall(EquipSlot1)
        end
    else
        local rootPart2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local fieldValue = getgenv().NNVN_2MFishPrevPos
        if rootPart2 and typeof(fieldValue) == "CFrame" then
            pcall(function()
                NNVN_TweenTo(fieldValue)
            end)
        end
        getgenv().NNVN_2MFishPrevPos = nil
        local fieldValue2 = getgenv().NNVN_2MFishPrevFlags
        if fieldValue2 then
            getgenv().NNVN_Anchor = fieldValue2.Anchor and true or false
            getgenv().NNVN_AutoCast = fieldValue2.AutoCast and true or false
            getgenv().NNVN_AutoSkill = fieldValue2.AutoSkill and true or false
        else
            getgenv().NNVN_Anchor = false
            getgenv().NNVN_AutoCast = false
            getgenv().NNVN_AutoSkill = false
        end
        getgenv().NNVN_2MFishPrevFlags = nil
    end
end

startAutoGiveFishLoop()
task.spawn(function()
    while task.wait(2) do
        if getgenv().NNVN_AutoFarm2MFish then
            pcall(function()
                local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local fieldValue = getgenv().NNVN_2MFishFarmCFrame
                if rootPart and fieldValue and (rootPart.Position - fieldValue.Position).Magnitude > 8 then
                    NNVN_TweenTo(fieldValue)
                end
                getgenv().NNVN_Anchor = true
                getgenv().NNVN_AutoCast = true
                getgenv().NNVN_AutoSkill = true
            end)
        end
    end
end)
function GetAvailableBaits()
    local playerData = GetPlayerData()
    if not playerData then
        return {}
    end
    local stateMap = {}
    local bait = playerData:FindFirstChild("Bait")
    if not bait then
        return {}
    end
    for _, entry in pairs(bait:GetChildren()) do
        if entry:IsA("NumberValue") and entry.Value > 0 then
            table.insert(stateMap, entry.Name)
        end
    end
    return stateMap
end

function GetBaitStats(inputValue)
    local baitInfo = ReplicatedStorage.Info.Bait:FindFirstChild(inputValue)
    if baitInfo then
        local ok, result = pcall(require, baitInfo)
        if ok and result then
            return { Luck = result.Luck or 0 }
        end
    end
    return { Luck = 0 }
end

function GetBestBait()
    local availableBaits = GetAvailableBaits()
    local item
    local negValue = -1
    for _, item2 in ipairs(availableBaits) do
        local baitStats = GetBaitStats(item2)
        if negValue < baitStats.Luck then
            negValue = baitStats.Luck
            item = item2
        end
    end
    return item
end

function EquipBait(inputValue)
    if not inputValue then
        return false
    end
    return ProxEquipBait(inputValue)
end

function GetOwnedRods()
    local playerData = GetPlayerData()
    if not playerData then
        return {}
    end
    local stateMap = {}
    local fishingRodInventory = playerData:FindFirstChild("FishingRodInventory")
    if not fishingRodInventory then
        return {}
    end
    for _, entry in pairs(fishingRodInventory:GetChildren()) do
        if entry:IsA("Folder") and entry:FindFirstChild("Owned") and entry.Owned.Value == true then
            table.insert(stateMap, entry.Name)
        end
    end
    return stateMap
end

function GetRodStats(inputValue)
    local inventoryEntry = ReplicatedStorage.Info.Inventory:FindFirstChild(inputValue)
    if inventoryEntry then
        local ok, result = pcall(require, inventoryEntry)
        if ok and result then
            return { Power = result.Power or 0, Luck = result.Luck or 0 }
        end
    end
    return { Power = 0, Luck = 0 }
end

function GetBestRod()
    local ownedRods = GetOwnedRods()
    local item
    local negValue = -1
    for _, item2 in ipairs(ownedRods) do
        local rodStats = GetRodStats(item2)
        local computedValue = rodStats.Power + rodStats.Luck
        if negValue < computedValue then
            negValue = computedValue
            item = item2
        end
    end
    return item
end

function EquipRod(inputValue)
    if not inputValue then
        return false
    end
    return ProxEquipRod(inputValue)
end

function GetAvailableOrbs()
    local playerData = GetPlayerData()
    if not playerData then
        return {}
    end
    local stateMap = {}
    local orb = playerData:FindFirstChild("Orb")
    if not orb then
        return {}
    end
    for _, entry in pairs(orb:GetChildren()) do
        if not entry:IsA("Folder") then
            continue
        end
        local equipping = entry:FindFirstChild("Equipping")
        if equipping and equipping.Value == false then
            table.insert(stateMap, entry.Name)
        end
    end
    return stateMap
end

function GetOrbStats(inputValue)
    local playerData = GetPlayerData()
    if not playerData then
        return {}
    end
    local orbEntry = playerData.Orb and playerData.Orb:FindFirstChild(inputValue)
    if not orbEntry then
        return {}
    end
    local lookupMap = {}
    for _, entry in pairs(orbEntry:GetChildren()) do
        if entry:IsA("NumberValue") and entry.Name ~= "Equipping" and entry.Name ~= "Favorite" then
            lookupMap[entry.Name] = entry.Value
        end
    end
    return lookupMap
end

function GetBestOrb()
    local availableOrbs = GetAvailableOrbs()
    local item
    local negValue = -1
    for _, item2 in ipairs(availableOrbs) do
        local orbStats = GetOrbStats(item2)
        local computedValue = (orbStats.Damage or 0) * 2 + (orbStats.Luck or 0) * 1.5 + (orbStats.Cash or 0) * 0.5
        if negValue < computedValue then
            negValue = computedValue
            item = item2
        end
    end
    return item
end

function EquipOrb(inputValue)
    if not inputValue then
        return false
    end
    return ProxEquipOrb(inputValue)
end

function isHoldingFishingRod()
    local character = LocalPlayer.Character
    if not character then
        return false
    end
    local typeAttr = character:GetAttribute("Type")
    if typeAttr and string.lower(tostring(typeAttr)) == "fishing rod" then
        return true
    end
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") and (item.Name:find("Rod") or item.Name:find("Fishing")) then
            return true
        end
    end
    return false
end

function HasFishingRod()
    return isHoldingFishingRod()
end

function ToggleHotbarSlot1()
    local toggleHotbar = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("ToggleHotbar")
    if toggleHotbar then
        pcall(function()
            toggleHotbar:InvokeServer("1", nil)
        end)
    end
end

function EquipSlot1()
    ToggleHotbarSlot1()
end

function TeleportToCFrame(inputValue)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    pcall(function()
        NNVN_TweenTo(inputValue + Vector3.new(0, 5, 0))
    end)
end

function getCharacterRoot()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

function trimText(text)
    text = tostring(text or "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

function numericOnlyText(inputValue, secondValue)
    local formattedText = tostring(inputValue or ""):gsub("[^%d]", "")
    if formattedText == "" then
        formattedText = tostring(secondValue or 0)
    end
    return formattedText
end

getgenv().NNVN_FakeLevelText = numericOnlyText(getgenv().NNVN_FakeLevelText, 100)
getgenv().NNVN_FakeMoneyText = numericOnlyText(getgenv().NNVN_FakeMoneyText, 999999999)
getgenv().NNVN_FakeGemText = numericOnlyText(getgenv().NNVN_FakeGemText, 9999)
getgenv().NNVN_FakeTicketText = numericOnlyText(getgenv().NNVN_FakeTicketText, 999)
getgenv().NNVN_FakeOrbText = numericOnlyText(getgenv().NNVN_FakeOrbText, 999)
function buildCustomPositionNames()
    local stateMap = {}
    for entryKey in pairs(getgenv().NNVN_CustomPositions or {}) do
        table.insert(stateMap, entryKey)
    end
    table.sort(stateMap)
    if #stateMap == 0 then
        table.insert(stateMap, "No Position")
    end
    return stateMap
end

function hasCustomPosition(inputValue)
    return type(getgenv().NNVN_CustomPositions) == "table" and getgenv().NNVN_CustomPositions[inputValue] ~= nil
end

function refreshPositionDropdown()
    local customPositionNames = buildCustomPositionNames()
    local selectedPosition = getgenv().NNVN_SelectedPosition
    if not hasCustomPosition(selectedPosition) then
        selectedPosition = customPositionNames[1] or "No Position"
        getgenv().NNVN_SelectedPosition = selectedPosition
    end
    if PositionDropdown and PositionDropdown.SetValues then
        pcall(function()
            PositionDropdown:SetValues(customPositionNames)
        end)
    end
    if PositionDropdown and PositionDropdown.SetValue then
        pcall(function()
            PositionDropdown:SetValue(selectedPosition)
        end)
    elseif PositionDropdown and PositionDropdown.Set then
        pcall(function()
            PositionDropdown:Set(selectedPosition)
        end)
    end
    task.defer(ApplyUILanguage)
end

function notifyPosition(inputValue)
    if getgenv().NNVN_Notify then
        item:Notify({
            Title = TranslateText("Configuration"),
            Content = inputValue,
            Duration = 2,
            Icon = "map-pin"
        })
    end
end

function createSavedPosition()
    local characterRoot = getCharacterRoot()
    if not characterRoot then
        notifyPosition("Character not found.")
        return
    end
    local trimTextResult = trimText(getgenv().NNVN_PositionNameInput)
    if trimTextResult == "" then
        trimTextResult = "Position"
    end
    local trimTextResult2 = trimTextResult
    local stepIndex = 2
    while hasCustomPosition(trimTextResult2) do
        trimTextResult2 = trimTextResult .. " " .. tostring(stepIndex)
        stepIndex = stepIndex + 1
    end
    getgenv().NNVN_CustomPositions[trimTextResult2] = characterRoot.CFrame
    getgenv().NNVN_SelectedPosition = trimTextResult2
    refreshPositionDropdown()
    notifyPosition("Created position: " .. trimTextResult2)
end

function teleportToSelectedSavedPosition()
    local selectedPosition = getgenv().NNVN_SelectedPosition
    local customPosition = getgenv().NNVN_CustomPositions and getgenv().NNVN_CustomPositions[selectedPosition]
    if not getCharacterRoot() or typeof(customPosition) ~= "CFrame" then
        return false
    end
    pcall(function()
        NNVN_TweenTo(customPosition)
    end)
    return true
end

function startPositionLock()
    getgenv().NNVN_PositionLockLoopId = (getgenv().NNVN_PositionLockLoopId or 0) + 1
    local positionLockLoopId = getgenv().NNVN_PositionLockLoopId
    if not getgenv().NNVN_PositionLock then
        return
    end
    task.spawn(function()
        while getgenv().NNVN_PositionLock and positionLockLoopId == getgenv().NNVN_PositionLockLoopId do
            if NormalizeTranslatedChoice(getgenv().NNVN_PositionTeleportMode, "No Teleport") == "Save Position" then
                local selectedPosition = getgenv().NNVN_SelectedPosition
                local customPosition = getgenv().NNVN_CustomPositions and getgenv().NNVN_CustomPositions[selectedPosition]
                local characterRoot = getCharacterRoot()
                if characterRoot and typeof(customPosition) == "CFrame" and (getgenv().NNVN_PositionLockDistance or 3) < (characterRoot.Position - customPosition.Position).Magnitude then
                    pcall(function()
                        NNVN_TweenTo(customPosition)
                    end)
                end
            end
            task.wait(0.25)
        end
    end)
end

function serializeCustomPositions()
    local lookupMap = {}
    for key, entry in pairs(getgenv().NNVN_CustomPositions or {}) do
        if typeof(entry) == "CFrame" then
            lookupMap[key] = { entry:GetComponents() }
        end
    end
    return lookupMap
end

function applyCustomPositions(inputValue)
    if type(inputValue) ~= "table" then
        return
    end
    local stateMap = {}
    local unpack2 = table.unpack or unpack
    for key, entry in pairs(inputValue) do
        if type(key) == "string" and type(entry) == "table" and #entry >= 12 then
            local ok, result = pcall(function()
                return CFrame.new(unpack2(entry))
            end)
            if ok and typeof(result) == "CFrame" then
                stateMap[key] = result
            end
        end
    end
    getgenv().NNVN_CustomPositions = stateMap
    refreshPositionDropdown()
end

function TeleportToNPC(inputValue)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    local npcByName = FindNPCByName(inputValue)
    if not npcByName then
        return false
    end
    local item4Result = item4(npcByName)
    if not item4Result then
        return false
    end
    local computedValue = item4Result.Position - item4Result.CFrame.LookVector * (delaySeconds2 or 3.5) + Vector3.new(0, 2, 0)
    pcall(function()
        NNVN_TweenTo(CFrame.new(computedValue, item4Result.Position))
    end)
    task.wait(delaySeconds or 0.35)
    return true
end

function TeleportToNPCWithFallback(inputValue)
    if TeleportToNPC(inputValue) then
        return true
    end
    local phiThien1Entry = phiThien1Map[inputValue]
    if phiThien1Entry then
        TeleportToCFrame(phiThien1Entry)
        return true
    end
    return false
end

function HoldE(inputValue)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(inputValue)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

function GetTicketCount()
    local playerData = ReplicatedStorage.Data:FindFirstChild(tostring(LocalPlayer.UserId))
    if not playerData then
        return 0
    end
    local gacha = playerData:FindFirstChild("Gacha")
    if not gacha then
        return 0
    end
    local tickets = gacha:FindFirstChild("Tickets")
    if tickets and tickets:IsA("NumberValue") then
        return tickets.Value
    end
    return 0
end

function GetCrystals()
    local playerData = ReplicatedStorage.Data:FindFirstChild(tostring(LocalPlayer.UserId))
    if not playerData then
        return 0
    end
    local nameList = {
        "Crystals",
        "Gems",
        "Diamonds",
        "Crystal",
        "Gem"
    }
    for _, item in ipairs(nameList) do
        local playerData2 = playerData:FindFirstChild(item)
        if playerData2 and playerData2:IsA("NumberValue") then
            return playerData2.Value
        end
    end
    local currency = playerData:FindFirstChild("Currency")
    if currency then
        for _, item2 in ipairs(nameList) do
            local currencyEntry = currency:FindFirstChild(item2)
            if currencyEntry and currencyEntry:IsA("NumberValue") then
                return currencyEntry.Value
            end
        end
    end
    return 0
end

function ObjectExists(inputValue)
    local workspace2 = Workspace
    for _, item in ipairs(inputValue) do
        workspace2 = workspace2:FindFirstChild(item)
        if not workspace2 then
            return false
        end
    end
    return true
end

getgenv().NNVN_ObjectExists = ObjectExists
function getQuestDisplayName(inputValue)
    return inputValue == "Easy" and "Easy Ticket Quest" or "Hard Ticket Quest"
end

function getMainQuestGui(inputValue)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
    local menu = mainGui and mainGui:FindFirstChild("Menu")
    local quest = menu and menu:FindFirstChild("Quest")
    local menu2 = quest and quest:FindFirstChild("Menu")
    local mainQuest = menu2 and menu2:FindFirstChild("Main_Quest")
    return mainQuest and mainQuest:FindFirstChild(getQuestDisplayName(inputValue))
end

function isGuiTreeVisible(inputValue)
    local inputValue2 = inputValue
    while inputValue2 do
        if inputValue2:IsA("GuiObject") and inputValue2.Visible == false then
            return false
        end
        inputValue2 = inputValue2.Parent
    end
    return inputValue ~= nil
end

function isQuestGuiVisible(inputValue)
    local mainQuestGui = getMainQuestGui(inputValue)
    return mainQuestGui ~= nil and mainQuestGui.Visible == true and isGuiTreeVisible(mainQuestGui)
end

function getQuestFolder(inputValue)
    local data = ReplicatedStorage:FindFirstChild("Data")
    local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
    local quest = playerData and playerData:FindFirstChild("Quest")
    local main = quest and quest:FindFirstChild("Main")
    return main and main:FindFirstChild(getQuestDisplayName(inputValue))
end

function isQuestActive(inputValue)
    if isQuestGuiVisible(inputValue) then
        return true
    end
    return getQuestFolder(inputValue) ~= nil
end

function getActiveTicketDifficulty(inputValue)
    inputValue = inputValue == "Hard" and "Hard" or "Easy"
    if isQuestActive(inputValue) then
        return inputValue
    end
    local easyLabel = inputValue == "Hard" and "Easy" or "Hard"
    if isQuestActive(easyLabel) then
        return easyLabel
    end
    return nil
end

function getTicketMovementMethod()
    return GetActionMethod() == "Tween" and "Tween" or "Teleport"
end

function getTicketCooldownSeconds()
    local data = ReplicatedStorage:FindFirstChild("Data")
    local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
    local ticketQuestCooldown = playerData and playerData:FindFirstChild("TicketQuestCooldown")
    return math.max(0, (ticketQuestCooldown and tonumber(ticketQuestCooldown.Value) or 0) - Workspace:GetServerTimeNow())
end

function getTicketDialogueText()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
    local menu = mainGui and mainGui:FindFirstChild("Menu")
    local dialogue = menu and menu:FindFirstChild("Dialogue")
    if not dialogue then
        return ""
    end
    local stateMap = {}
    for _, item in ipairs(dialogue:GetDescendants()) do
        if (item:IsA("TextLabel") or item:IsA("TextButton")) and item.Text ~= "" then
            table.insert(stateMap, item.Text)
        end
    end
    return table.concat(stateMap, " ")
end

function updateTicketDailyLimitFromDialogue()
    local formattedText = string.lower(getTicketDialogueText())
    local isMatched = formattedText:find("limit", 1, true) ~= nil and formattedText:find("20", 1, true) ~= nil
    if isMatched then
        getgenv().NNVN_TicketDailyLimitReached = true
        getgenv().NNVN_TicketDailyLimitDay = math.floor(Workspace:GetServerTimeNow() / 86400)
    end
    return isMatched, formattedText
end

function getQuestProgress(inputValue)
    local questFolder = getQuestFolder(inputValue)
    local objective = questFolder and questFolder:FindFirstChild("Objective")
    if not objective then
        return nil
    end
    local stateMap = {}
    for _, item in ipairs(objective:GetChildren()) do
        if not item:IsA("StringValue") then
            continue
        end
        local firstMatch, secondMatch, thirdMatch = item.Value:match("^(.-),(%d+),(.+)$")
        local questEntry = questFolder:FindFirstChild(item.Name)
        if not firstMatch or not questEntry or not questEntry:IsA("NumberValue") and not questEntry:IsA("IntValue") then
            continue
        end
        secondMatch = tonumber(secondMatch)
        table.insert(stateMap, {
            id = item.Name,
            name = firstMatch,
            type = thirdMatch,
            current = questEntry.Value,
            total = secondMatch,
            completed = secondMatch <= questEntry.Value
        })
    end
    table.sort(stateMap, function(leftItem, rightItem)
        return (tonumber(leftItem.id) or math.huge) < (tonumber(rightItem.id) or math.huge)
    end)
    return stateMap
end

function isQuestCompleted(inputValue)
    local questProgress = getQuestProgress(inputValue)
    if not questProgress or #questProgress == 0 then
        return false
    end
    for _, item in ipairs(questProgress) do
        if not item.completed then
            return false
        end
    end
    return true
end

function notify(inputValue, secondValue, thirdValue)
    local windUiRef = getgenv().NNVN_WindUIRef or getgenv().NNVN_FluentRef
    if not getgenv().NNVN_Notify or not windUiRef or type(windUiRef.Notify) ~= "function" then
        return
    end
    pcall(function()
        windUiRef:Notify({
            Title = inputValue or "Ticket Quest",
            Content = secondValue or "",
            Duration = thirdValue or 3
        })
    end)
end

function getQuestNpc()
    local npcFolder = Workspace:FindFirstChild("NPC")
    local functionValue = npcFolder and npcFolder:FindFirstChild("Function")
    if functionValue and functionValue:FindFirstChild("Ticket Quest Giver") then
        return functionValue["Ticket Quest Giver"]
    end
    if npcFolder then
        return npcFolder:FindFirstChild("Ticket Quest Giver", true)
    end
    return Workspace:FindFirstChild("Ticket Quest Giver", true)
end

local easyMap = {
    Easy = CFrame.new(-46.1795769, 6.76193953, -151.819046, 0.968147457, 7.89805767e-08, 0.250380754, -8.1948329e-08, 1, 1.42775824e-09, -0.250380754, -2.19005631e-08, 0.968147457),
    Hard = CFrame.new(1513.67114, 609.375854, -167.350845, 0.994521856, -0.00476903142, 0.104419708, -7.84444065e-09, 0.998958647, 0.045624271, -0.104528554, -0.0453743376, 0.993486285)
}
local cFrame = CFrame.new(1678.84241, 12.0619411, -106.830734, 0.374605805, -8.96978314e-09, -0.927184165, -2.73463936e-08, 1, -2.07228528e-08, 0.927184165, 3.31180452e-08, 0.374605805)
local stepIndex = 595
local stepIndex2 = 625
local ticketSkyPlatform = "NNVN_TicketSkyPlatform"
local ticketSkyLockConnection = getgenv()._NNVN_TicketSkyLockConnection
if ticketSkyLockConnection then
    pcall(function()
        ticketSkyLockConnection:Disconnect()
    end)
end
getgenv()._NNVN_TicketSkyLockConnection = nil
local ticketSkyHumanoidState = getgenv()._NNVN_TicketSkyHumanoidState
if ticketSkyHumanoidState and ticketSkyHumanoidState.Humanoid and ticketSkyHumanoidState.Humanoid.Parent then
    pcall(function()
        ticketSkyHumanoidState.Humanoid.AutoRotate = ticketSkyHumanoidState.AutoRotate
        ticketSkyHumanoidState.Humanoid.JumpPower = ticketSkyHumanoidState.JumpPower
        ticketSkyHumanoidState.Humanoid.JumpHeight = ticketSkyHumanoidState.JumpHeight
        ticketSkyHumanoidState.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    end)
end
getgenv()._NNVN_TicketSkyHumanoidState = nil
local platformPart = Workspace:FindFirstChild(ticketSkyPlatform)
if platformPart then
    platformPart:Destroy()
end
local item7
local item8
local item9
local item10
local function resolveRandom(inputValue)
    if getgenv().NNVN_TicketRandomSkyHeight == true then
        local parsedNum = tonumber(getgenv().NNVN_TicketSkyChosenHeight)
        if inputValue or not parsedNum or parsedNum < stepIndex or stepIndex2 < parsedNum then
            getgenv().NNVN_TicketSkyChosenHeight = math.random(stepIndex * 10, stepIndex2 * 10) / 10
        end
    else
        getgenv().NNVN_TicketSkyChosenHeight = easyMap.Hard.Position.Y
    end
    return tonumber(getgenv().NNVN_TicketSkyChosenHeight) or easyMap.Hard.Position.Y
end

function isTicketSkyMode(inputValue)
    if getgenv().NNVN_TicketHardLocation == "Ground" then
        return false
    end
    if inputValue == "Easy" then
        local questCustomIsland = getgenv().NNVN_QuestCustomIsland
        if questCustomIsland and questCustomIsland ~= "" and questCustomIsland ~= "No Selection" then
            return false
        end
    end
    return true
end

local function resolveTicketHardLocation(inputValue)
    if getgenv().NNVN_TicketHardLocation == "Ground" then
        return inputValue == "Hard" and cFrame or easyMap.Easy
    end
    local easyEntry = easyMap[inputValue] or easyMap.Easy
    return CFrame.new(easyEntry.Position.X, resolveRandom(false), easyEntry.Position.Z) * easyEntry.Rotation
end

local function resolveParent()
    if item9 and item9.Parent and item10 then
        pcall(function()
            item9.AutoRotate = item10.AutoRotate
            item9.JumpPower = item10.JumpPower
            item9.JumpHeight = item10.JumpHeight
            item9:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end)
    end
    item9 = nil
    item10 = nil
    getgenv()._NNVN_TicketSkyHumanoidState = nil
end

local function cleanupResource(inputValue, target)
    if not inputValue then
        if item8 then
            item8:Disconnect()
            item8 = nil
            getgenv()._NNVN_TicketSkyLockConnection = nil
        end
        if item7 then
            item7:Destroy()
            item7 = nil
        end
        local platformPart = Workspace:FindFirstChild(ticketSkyPlatform)
        if platformPart then
            platformPart:Destroy()
        end
        resolveParent()
        return
    end
    target = target or resolveTicketHardLocation(getgenv().NNVN_TicketDifficulty)
    if not item7 or not item7.Parent then
        local platformPart2 = Workspace:FindFirstChild(ticketSkyPlatform)
        if platformPart2 then
            platformPart2:Destroy()
        end
        item7 = Instance.new("Part")
        item7.Name = ticketSkyPlatform
        item7.Anchored = true
        item7.CanCollide = true
        item7.CanTouch = false
        item7.CanQuery = false
        item7.Transparency = 1
        item7.CastShadow = false
        item7.Size = Vector3.new(2048, 1, 2048)
        item7.Parent = Workspace
    end
    item7.CFrame = CFrame.new(target.Position.X, target.Position.Y - 3.5, target.Position.Z)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid ~= item9 then
        resolveParent()
        item9 = humanoid
        item10 = {
            AutoRotate = humanoid.AutoRotate,
            JumpPower = humanoid.JumpPower,
            JumpHeight = humanoid.JumpHeight
        }
        getgenv()._NNVN_TicketSkyHumanoidState = {
            Humanoid = humanoid,
            AutoRotate = item10.AutoRotate,
            JumpPower = item10.JumpPower,
            JumpHeight = item10.JumpHeight
        }
        pcall(function()
            humanoid.AutoRotate = false
            humanoid.JumpPower = 0
            humanoid.JumpHeight = 0
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        end)
    end
    if not item8 then
        local counter = 0
        item8 = RunService.Heartbeat:Connect(function(deltaTime)
            counter = counter + deltaTime
            if counter < 0.1 then
                return
            end
            counter = 0
            if getgenv().NNVN_AutoTicket ~= true or not isTicketSkyMode(getgenv().NNVN_TicketDifficulty) then
                task.defer(function()
                    cleanupResource(false)
                end)
                return
            end
            local ticketHardLocation = resolveTicketHardLocation(getgenv().NNVN_TicketDifficulty)
            local character = LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid ~= item9 then
                cleanupResource(true, ticketHardLocation)
            end
            if rootPart then
                rootPart.CFrame = CFrame.new(rootPart.Position) * ticketHardLocation.Rotation
                rootPart.AssemblyAngularVelocity = Vector3.zero
            end
        end)
        getgenv()._NNVN_TicketSkyLockConnection = item8
    end
end

local mainSkyFarmPlatform = "NNVN_MainSkyFarmPlatform"
local item11
local item12
local item13
local counter = 0
local function resolveFindFirstChild()
    if item12 then
        pcall(function()
            item12:Disconnect()
        end)
        item12 = nil
    end
    if item11 then
        pcall(function()
            item11:Destroy()
        end)
        item11 = nil
    end
    local platformPart = Workspace:FindFirstChild(mainSkyFarmPlatform)
    if platformPart then
        pcall(function()
            platformPart:Destroy()
        end)
    end
end

local function cleanupResource2()
    if item11 and item11.Parent then
        return item11
    end
    local platformPart = Workspace:FindFirstChild(mainSkyFarmPlatform)
    if platformPart then
        platformPart:Destroy()
    end
    item11 = Instance.new("Part")
    item11.Name = mainSkyFarmPlatform
    item11.Anchored = true
    item11.CanCollide = true
    item11.CanTouch = false
    item11.CanQuery = false
    item11.Transparency = 1
    item11.CastShadow = false
    item11.Size = Vector3.new(320, 1, 320)
    item11.Parent = Workspace
    return item11
end

local function resolveSpawn(inputValue)
    counter = counter + 1
    local counter2 = counter
    task.spawn(function()
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart or counter2 ~= counter then
            return
        end
        inputValue = math.clamp(tonumber(inputValue) or 609, 100, 1000)
        NNVN_MoveToCFrame(CFrame.new(rootPart.Position.X, inputValue, rootPart.Position.Z) * rootPart.CFrame.Rotation, "Tween [Safe]")
        if counter2 ~= counter or getgenv().NNVN_SkyFarm ~= true then
            return
        end
        local rootPart2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart2 then
            cleanupResource2().CFrame = CFrame.new(rootPart2.Position.X, inputValue - 3.5, rootPart2.Position.Z)
        end
    end)
end

function NNVN_SetSkyFarm(inputValue)
    inputValue = inputValue == true
    getgenv().NNVN_SkyFarm = inputValue
    counter = counter + 1
    if not inputValue then
        resolveFindFirstChild()
        local item132 = item13
        item13 = nil
        if item132 then
            task.spawn(function()
                local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not rootPart then
                    return
                end
                NNVN_MoveToCFrame(CFrame.new(rootPart.Position.X, item132, rootPart.Position.Z) * rootPart.CFrame.Rotation, "Tween [Safe]")
            end)
        end
        return
    end
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        getgenv().NNVN_SkyFarm = false
        return
    end
    item13 = rootPart.Position.Y
    resolveSpawn(getgenv().NNVN_SkyFarmHeight)
    if not item12 then
        item12 = RunService.Heartbeat:Connect(function()
            if getgenv().NNVN_SkyFarm ~= true then
                task.defer(resolveFindFirstChild)
                return
            end
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if rootPart and item11 and item11.Parent then
                item11.CFrame = CFrame.new(rootPart.Position.X, (tonumber(getgenv().NNVN_SkyFarmHeight) or 609) - 3.5, rootPart.Position.Z)
            end
        end)
    end
end

function NNVN_SetSkyFarmHeight(inputValue)
    getgenv().NNVN_SkyFarmHeight = math.clamp(tonumber(inputValue) or 609, 100, 1000)
    if getgenv().NNVN_SkyFarm == true then
        resolveSpawn(getgenv().NNVN_SkyFarmHeight)
    end
end

resolveFindFirstChild()
function getAnchor(instance)
    if not instance then
        return nil
    end
    if instance:IsA("BasePart") then
        return instance
    end
    return instance:FindFirstChild("HumanoidRootPart", true) or instance:FindFirstChild("RootPart", true) or instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
end

local beginningIsleMap = {
    ["Beginning Isle"] = CFrame.new(-213.939972, 6.76193953, 33.2846527),
    ["Bamboo Isle"] = CFrame.new(-1184.15674, 10.6356201, -84.3372498),
    ["Fallout Isle"] = CFrame.new(-6.55301952, 6.24169779, 1185.16528),
    ["Sovereign Isle"] = CFrame.new(-1248.17249, 7.31857586, 1208.54199),
    ["Perch Isle"] = CFrame.new(-61.9632416, -8.2120657, -1310.39124),
    ["Frost Isle"] = CFrame.new(-1328.79614, 7.63562012, -1488.55383),
    ["Coconut Isle"] = CFrame.new(1429.93628, 7.63562012, -1478.6311),
    ["Amber Isle"] = CFrame.new(1239.81299, 10.6663065, 1335.96521),
    ["Battlefield Isle"] = CFrame.new(1394.1842, 9.27561855, 200.794785),
    ["Mistpeak Isle"] = CFrame.new(2611.62134, 9.27561855, -81.6781845),
    ["World Angler Isle"] = CFrame.new(-2347.00684, 9.27561855, -202.806244, 0.026177302, 3.14691704e-08, -0.999657333, -8.0341195e-08, 1, 2.93761193e-08, 0.999657333, 7.95446766e-08, 0.026177302),
    ["Weather Isle"] = CFrame.new(-3037.28516, 13.5158062, 1093.56641, 0.515039563, -1.36549962e-08, 0.857166409, -4.1359467e-08, 1, 4.07817637e-08, -0.857166409, -5.64561695e-08, 0.515039563),
    ["Mystic Reef Isle"] = CFrame.new(-2576.95435, 11.4712849, -1382.04016, 0.0436187349, 3.68163491e-08, -0.999048233, -5.86042326e-08, 1, 3.42927429e-08, 0.999048233, 5.70526488e-08, 0.0436187349)
}
getgenv().NNVN_QuestCustomIsland = getgenv().NNVN_QuestCustomIsland or "No Selection"
getgenv().NNVN_QuestIslandCFrames = beginningIsleMap
local beginningIsleMap2 = {
    ["Beginning Isle"] = CFrame.new(-258.208893, 9.11978817, -19.8347473, -0.246991977, -3.27293002e-08, 0.969017506, 3.21653388e-08, 1, 4.19743493e-08, -0.969017506, 4.15361043e-08, -0.246991977),
    ["Bamboo Isle"] = CFrame.new(-1311.76624, 9.27561855, 27.1021328, -0.500000834, 1.25569045e-07, 0.866024911, 6.772337e-08, 1, -1.05894529e-07, -0.866024911, 5.70277159e-09, -0.500000834),
    ["Fallout Isle"] = CFrame.new(-59.322361, 7.85093975, 1677.86523, -0.986285627, 7.78200082e-09, 0.165047333, 5.75186698e-09, 1, -1.27782531e-08, -0.165047333, -1.16536771e-08, -0.986285627),
    ["Sovereign Isle"] = CFrame.new(-1625.88428, 11.5350533, 1622.09692, 0.224939391, 2.13587512e-08, 0.974372745, -1.33935529e-08, 1, -1.8828537e-08, -0.974372745, -8.81503315e-09, 0.224939391),
    ["Perch Isle"] = CFrame.new(163.3638, 22.5489426, -1667.12549, 0.983254969, -3.53700691e-09, -0.182235256, 4.94177976e-10, 1, -1.67426659e-08, 0.182235256, 1.63722529e-08, 0.983254969),
    ["Frost Isle"] = CFrame.new(-1127.12732, 13.5423517, -1541.1759, 0.104531832, -4.09007654e-08, -0.994521558, -2.8796185e-08, 1, -4.41527703e-08, 0.994521558, 3.32537944e-08, 0.104531832),
    ["Coconut Isle"] = CFrame.new(1107.87634, 12.6112461, -1587.43188, 0.147807002, 1.36995144e-08, 0.989016235, 7.73164857e-08, 1, -2.54064911e-08, -0.989016235, 8.02225202e-08, 0.147807002),
    ["Amber Isle"] = CFrame.new(1599.42798, 13.1691341, 1605.98767, 0.309020549, -1.65723772e-08, -0.951055348, 2.77578049e-08, 1, -8.40607761e-09, 0.951055348, -2.38015581e-08, 0.309020549),
    ["Battlefield Isle"] = CFrame.new(1678.84241, 12.0619411, -106.830734, 0.374605805, -8.96978314e-09, -0.927184165, -2.73463936e-08, 1, -2.07228528e-08, 0.927184165, 3.31180452e-08, 0.374605805),
    ["Mistpeak Isle"] = CFrame.new(3036.31909, 9.82965088, 113.750557, -0.913545489, 6.75575151e-08, -0.406736642, 4.33373195e-08, 1, 6.8759249e-08, 0.406736642, 4.5187825e-08, -0.913545489),
    ["Weather Isle"] = CFrame.new(-3005.76025, 9.27561855, 1352.46362, -0.999928296, 4.86433382e-09, 0.0119756758, 4.84810281e-09, 1, -1.38436151e-09, -0.0119756758, -1.32620293e-09, -0.999928296),
    ["Mystic Reef Isle"] = CFrame.new(-2606.94629, 9.27561855, -1509.54138, 0.0229267217, -8.13015788e-09, -0.999737144, 8.40814849e-08, 1, -6.20407592e-09, 0.999737144, -8.39171435e-08, 0.0229267217)
}
function teleportToFishingSpot(inputValue)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end
    local item
    if inputValue == "Hard" then
        item = resolveTicketHardLocation("Hard")
    else
        local questCustomIsland = getgenv().NNVN_QuestCustomIsland
        if questCustomIsland and questCustomIsland ~= "" and questCustomIsland ~= "No Selection" then
            item = beginningIsleMap[questCustomIsland] or getgenv().NNVN_QuestIslandCFrames and getgenv().NNVN_QuestIslandCFrames[questCustomIsland] or beginningIsleMap2[questCustomIsland]
        else
            item = resolveTicketHardLocation("Easy")
        end
    end
    if not item then
        item = easyMap[inputValue]
    end
    if not item then
        return false
    end
    local isTicketSkyMode2 = getgenv().NNVN_AutoTicket == true and isTicketSkyMode(inputValue)
    cleanupResource(false)
    if (rootPart.Position - item.Position).Magnitude <= 8 then
        if isTicketSkyMode2 and getgenv().NNVN_AutoTicket == true then
            cleanupResource(true, item)
        end
        return true
    end
    local ticketMovementMethod = getTicketMovementMethod()
    local hasTriggered = false
    if ticketMovementMethod == "Tween" then
        hasTriggered = NNVN_MoveToCFrame(item, "Tween") == true and rootPart.Parent ~= nil and (rootPart.Position - item.Position).Magnitude <= 9
    else
        hasTriggered = NNVN_MoveToCFrame(item, "Teleport") == true
    end
    if hasTriggered and isTicketSkyMode2 and getgenv().NNVN_AutoTicket == true then
        cleanupResource(true, item)
    else
        cleanupResource(false)
    end
    return hasTriggered
end

function shouldReturnToFishingAfterAccept()
    return getgenv().NNVN_AutoCast == true
end

function saveTicketFlags()
    if getgenv().NNVN_TicketPrevFlags then
        return
    end
    getgenv().NNVN_TicketPrevFlags = {
        AutoCast = getgenv().NNVN_AutoCast,
        Anchor = getgenv().NNVN_Anchor,
        AutoSkill = getgenv().NNVN_AutoSkill
    }
end

function restoreTicketFlags()
    local ticketPrevFlags = getgenv().NNVN_TicketPrevFlags
    if ticketPrevFlags then
        getgenv().NNVN_AutoCast = ticketPrevFlags.AutoCast and true or false
        getgenv().NNVN_Anchor = ticketPrevFlags.Anchor and true or false
        getgenv().NNVN_AutoSkill = ticketPrevFlags.AutoSkill and true or false
    else
        getgenv().NNVN_AutoCast = false
        getgenv().NNVN_Anchor = false
        getgenv().NNVN_AutoSkill = false
    end
    getgenv().NNVN_TicketPrevFlags = nil
end

function enableTicketFarmAfterArrival(inputValue)
    if not teleportToFishingSpot(inputValue) then
        return false
    end
    if getgenv().NNVN_AutoTicket ~= true then
        cleanupResource(false)
        return false
    end
    getgenv().NNVN_Anchor = true
    getgenv().NNVN_AutoCast = true
    getgenv().NNVN_AutoSkill = true
    if not HasFishingRod() then
        pcall(EquipSlot1)
    end
    return true
end

function setTicketFishingEnabled(inputValue)
    getgenv().NNVN_Anchor = inputValue == true
    getgenv().NNVN_AutoCast = inputValue == true
    getgenv().NNVN_AutoSkill = inputValue == true
    if inputValue and not HasFishingRod() then
        pcall(EquipSlot1)
    end
end

function moveToTicketOriginalAndFish()
    local ticketOriginalCFrame = getgenv().NNVN_TicketOriginalCFrame
    if typeof(ticketOriginalCFrame) ~= "CFrame" then
        return false
    end
    cleanupResource(false)
    if NNVN_MoveToCFrame(ticketOriginalCFrame, getTicketMovementMethod()) == true and getgenv().NNVN_AutoTicket then
        setTicketFishingEnabled(true)
        return true
    end
    return false
end

function moveToTicketNpcOnly()
    local questNpc = getQuestNpc()
    local anchor = questNpc and getAnchor(questNpc)
    if not anchor then
        return false
    end
    cleanupResource(false)
    setTicketFishingEnabled(false)
    return NNVN_MoveToCFrame(CFrame.new(anchor.Position - anchor.CFrame.LookVector * (rawget(getgenv(), "PROX_OFFSET") or delaySeconds2 or 3.5) + Vector3.new(0, 2, 0), anchor.Position), getTicketMovementMethod()) == true
end

function handleTicketWaitingState()
    local ticketCooldownSeconds = getTicketCooldownSeconds()
    local floorResult = math.floor(Workspace:GetServerTimeNow() / 86400)
    if getgenv().NNVN_TicketDailyLimitReached and tonumber(getgenv().NNVN_TicketDailyLimitDay) and tonumber(getgenv().NNVN_TicketDailyLimitDay) ~= floorResult then
        getgenv().NNVN_TicketDailyLimitReached = false
        getgenv().NNVN_TicketDailyLimitDay = nil
    end
    local isMatched = getgenv().NNVN_TicketDailyLimitReached == true
    if not isMatched and ticketCooldownSeconds <= 0 then
        getgenv()._NNVN_TicketWaitState = nil
        return false
    end
    local clampResult = math.clamp(tonumber(getgenv().NNVN_TicketWaitNearNpcSeconds) or 120, 60, 120)
    local dailyLabel = isMatched and "daily" or ticketCooldownSeconds <= clampResult and "near" or "farm"
    if dailyLabel ~= getgenv()._NNVN_TicketWaitState then
        getgenv()._NNVN_TicketWaitState = dailyLabel
        if dailyLabel == "daily" then
            notify("Ticket Quest", "Daily limit 20/20 reached.", 4)
        elseif dailyLabel == "near" then
            notify("Ticket Quest", "Cooldown under 2 minutes. Waiting at NPC.", 4)
        else
            notify("Ticket Quest", "Cooldown active. Fishing at the saved position.", 4)
        end
    end
    if getgenv().NNVN_TicketFishWhileWaiting and (isMatched or clampResult < ticketCooldownSeconds) then
        moveToTicketOriginalAndFish()
        task.wait(1)
        return true
    end
    moveToTicketNpcOnly()
    task.wait(ticketCooldownSeconds > 0 and math.min(1, ticketCooldownSeconds) or 1)
    return true
end

function returnToFishingSpot(inputValue, secondValue)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    if typeof(getgenv().NNVN_TeleportToFishSpot) == "function" then
        pcall(function()
            getgenv().NNVN_TeleportToFishSpot(inputValue)
        end)
        return
    end
    if secondValue then
        pcall(function()
            NNVN_TweenTo(secondValue)
        end)
    end
end

function withQuestTravel(inputValue, secondValue)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local cFrame = rootPart and rootPart.CFrame
    local ok, result = pcall(secondValue)
    local ticketCooldownSeconds = getTicketCooldownSeconds()
    local isMatched = getgenv().NNVN_TicketDailyLimitReached == true
    local clampResult = math.clamp(tonumber(getgenv().NNVN_TicketWaitNearNpcSeconds) or 120, 60, 120)
    if isMatched or ticketCooldownSeconds > 0 then
        if getgenv().NNVN_TicketFishWhileWaiting and (isMatched or clampResult < ticketCooldownSeconds) then
            moveToTicketOriginalAndFish()
        else
            setTicketFishingEnabled(false)
        end
        return ok, result
    end
    if getgenv().NNVN_ReturnAfterQuestTP ~= false then
        task.wait(0.2)
        returnToFishingSpot(inputValue, cFrame)
    end
    return ok, result
end

function openQuestDialogue(inputValue)
    local events = ReplicatedStorage:FindFirstChild("Events")
    local startDialogue = events and events:FindFirstChild("StartDialogue")
    if not inputValue or not startDialogue then
        return false
    end
    local anchor = getAnchor(inputValue)
    local rawgetResult = rawget(getgenv(), "PROX_OFFSET") or delaySeconds2 or 3.5
    if not anchor then
        return false
    end
    local cFrame = CFrame.new(anchor.Position - anchor.CFrame.LookVector * rawgetResult + Vector3.new(0, 2, 0), anchor.Position)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end
    local isMatched = NNVN_MoveToCFrame(cFrame, getTicketMovementMethod()) == true
    task.wait(rawget(getgenv(), "PROX_WAIT") or delaySeconds or 0.38)
    if not isMatched or not rootPart.Parent or (rootPart.Position - cFrame.Position).Magnitude > 10 then
        return false
    end
    startDialogue:FireServer(inputValue)
    task.wait(0.4)
    return true
end

function clickLeaveButton()
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
        local menu = mainGui and mainGui:FindFirstChild("Menu")
        local dialogue = menu and menu:FindFirstChild("Dialogue")
        local buttonFrame = dialogue and dialogue:FindFirstChild("ButtonFrame")
        local child = buttonFrame and buttonFrame:FindFirstChild("1")
        if child and child:IsA("GuiButton") and child.Visible then
            child:Activate()
        end
    end)
end

function acceptTicketQuest(inputValue)
    if isQuestActive(inputValue) then
        return true
    end
    if getgenv().NNVN_TicketDailyLimitReached or getTicketCooldownSeconds() > 0 then
        return false
    end
    local hasTriggered = false
    withQuestTravel(inputValue, function()
        local questNpc = getQuestNpc()
        local events = ReplicatedStorage:FindFirstChild("Events")
        local chooseDialogueOption = events and events:FindFirstChild("ChooseDialogueOption")
        if not questNpc or not chooseDialogueOption then
            return
        end
        local easyAcceptQuestLabel = inputValue == "Easy" and "EasyAcceptQuest" or "HardAcceptQuest"
        local itemList = { questNpc, "Ticket Quest" }
        for i = 1, 4 do
            if getgenv().NNVN_TicketDailyLimitReached then
                break
            end
            if getTicketCooldownSeconds() > 0 then
                break
            end
            if isQuestActive(inputValue) then
                hasTriggered = true
                break
            end
            if not openQuestDialogue(questNpc) then
                break
            end
            if updateTicketDailyLimitFromDialogue() or getTicketCooldownSeconds() > 0 then
                clickLeaveButton()
                break
            end
            chooseDialogueOption:FireServer("Ticket Quest Giver", 1, easyAcceptQuestLabel, itemList)
            task.wait(0.75)
            local updateTicketDailyLimit = updateTicketDailyLimitFromDialogue()
            clickLeaveButton()
            task.wait(0.25)
            if updateTicketDailyLimit then
                break
            end
            if getTicketCooldownSeconds() > 0 then
                break
            end
            if isQuestActive(inputValue) then
                hasTriggered = true
                break
            end
        end
    end)
    if hasTriggered or isQuestActive(inputValue) then
        task.wait(0.35)
        if shouldReturnToFishingAfterAccept() and typeof(getgenv().NNVN_TeleportToFishSpot) == "function" then
            pcall(function()
                getgenv().NNVN_TeleportToFishSpot(inputValue)
            end)
        end
        return true
    end
    return false
end

function turnInTicketQuest(inputValue)
    local hasTriggered = false
    withQuestTravel(inputValue, function()
        local questNpc = getQuestNpc()
        local events = ReplicatedStorage:FindFirstChild("Events")
        local chooseDialogueOption = events and events:FindFirstChild("ChooseDialogueOption")
        local claimQuest = events and events:FindFirstChild("ClaimQuest")
        if not questNpc or not chooseDialogueOption or not claimQuest then
            return
        end
        for i = 1, 4 do
            if not isQuestActive(inputValue) then
                hasTriggered = true
                break
            end
            if not openQuestDialogue(questNpc) then
                break
            end
            chooseDialogueOption:FireServer("Ticket Quest Giver", 1, "Quest", { questNpc })
            task.wait(0.35)
            local questFolder = getQuestFolder(inputValue)
            if questFolder then
                claimQuest:FireServer(questFolder.Name)
                task.wait(0.75)
            end
            clickLeaveButton()
            task.wait(0.35)
            if not isQuestActive(inputValue) then
                hasTriggered = true
                break
            end
        end
    end)
    if hasTriggered and getgenv().NNVN_AutoTicket then
        task.wait(0.3)
        getgenv()._NNVN_TicketWaitState = nil
    end
    return hasTriggered or not isQuestActive(inputValue)
end

function completeTurnIn(inputValue)
    for i = 1, 6 do
        if not isQuestActive(inputValue) then
            return true
        end
        if not isQuestCompleted(inputValue) then
            return false
        end
        if turnInTicketQuest(inputValue) then
            return true
        end
        task.wait(0.8)
    end
    return not isQuestActive(inputValue)
end

function startTicketLoop()
    local ticketCoroutine = getgenv().NNVN_TicketCoroutine
    if ticketCoroutine then
        pcall(coroutine.close, ticketCoroutine)
        getgenv().NNVN_TicketCoroutine = nil
    end
    getgenv().NNVN_TicketCoroutine = coroutine.create(function()
        local counter = 0
        while getgenv().NNVN_AutoTicket do
            local hardLabel = getgenv().NNVN_TicketDifficulty == "Hard" and "Hard" or "Easy"
            local activeTicketDifficulty = getActiveTicketDifficulty(hardLabel)
            local hardLabel2 = hardLabel
            if activeTicketDifficulty ~= nil then
                getgenv().NNVN_TicketDailyLimitReached = false
                getgenv()._NNVN_TicketWaitState = nil
                pcall(function()
                    enableTicketFarmAfterArrival(hardLabel2)
                end)
                if isQuestCompleted(activeTicketDifficulty) then
                    notify("Ticket Quest", activeTicketDifficulty .. " quest done, turning in...", 3)
                    completeTurnIn(activeTicketDifficulty)
                    task.wait(1)
                else
                    task.wait(1)
                end
            elseif handleTicketWaitingState() then
            else
                local maxResult = math.max(0.5, tonumber(getgenv().NNVN_TicketAcceptDelay) or 2)
                local nowTime = os.clock()
                if maxResult <= nowTime - counter then
                    counter = nowTime
                    notify("Ticket Quest", hardLabel2 .. " quest not found in menu, trying to accept...", 3)
                    if acceptTicketQuest(hardLabel2) then
                        task.wait(0.8)
                    else
                        task.wait(0.5)
                    end
                else
                    task.wait(0.2)
                end
            end
        end
        restoreTicketFlags()
    end)
    coroutine.resume(getgenv().NNVN_TicketCoroutine)
end

getgenv().NNVN_IsQuestActive = isQuestActive
getgenv().NNVN_GetQuestProgress = getQuestProgress
getgenv().NNVN_IsQuestCompleted = isQuestCompleted
getgenv().NNVN_TeleportToFishSpot = teleportToFishingSpot
getgenv().NNVN_SaveTicketFlags = saveTicketFlags
getgenv().NNVN_RestoreTicketFlags = restoreTicketFlags
getgenv().NNVN_CanAcceptTicketQuest = function(inputValue)
    return not isQuestActive(inputValue)
end

getgenv().NNVN_ClickLeaveButton = clickLeaveButton
getgenv().NNVN_AcceptTicketQuest = acceptTicketQuest
getgenv().NNVN_TurnInTicketQuest = turnInTicketQuest
getgenv().NNVN_CompleteTicketQuestTurnIn = completeTurnIn
getgenv().NNVN_StartTicketLoop = startTicketLoop
if getgenv().NNVN_AutoTicket then
    task.wait(0.2)
    startTicketLoop()
end
function GodExists()
    local god = Workspace:FindFirstChild("NPC") and Workspace.NPC:FindFirstChild("God")
    if god then
        for entryKey in pairs(god:GetChildren()) do
            return true
        end
    end
    return false
end

getgenv().NNVN_GodExists = GodExists
function InteractWithGodNPC(inputValue)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end
    local item4Result = item4(inputValue)
    if not item4Result then
        return false
    end
    local hasTriggered = false
    RunActionWithMethod({ target = inputValue, returnAfter = true }, function()
        local item
        local talk = item4Result:FindFirstChild("Talk")
        if talk then
            item = talk:FindFirstChildWhichIsA("ProximityPrompt")
        end
        if not item then
            item = item4Result:FindFirstChildWhichIsA("ProximityPrompt", true)
        end
        if not item then
            if fireproximityprompt then
                for _, item2 in ipairs(inputValue:GetDescendants()) do
                    if not item2:IsA("ProximityPrompt") then
                        continue
                    end
                    pcall(fireproximityprompt, item2)
                    task.wait(0.5)
                    pcall(function()
                        ReplicatedStorage.Events.ChooseDialogueOption:FireServer(inputValue.Name, 1, "Pray", { inputValue })
                    end)
                    hasTriggered = true
                    return
                end
            end
            HoldE(3)
            task.wait(0.5)
            pcall(function()
                ReplicatedStorage.Events.ChooseDialogueOption:FireServer(inputValue.Name, 1, "Pray", { inputValue })
            end)
            hasTriggered = true
            return
        end
        if fireproximityprompt then
            pcall(fireproximityprompt, item)
        elseif firetouchinterest then
            pcall(firetouchinterest, rootPart, item4Result, 0)
        end
        task.wait(0.4)
        pcall(function()
            ReplicatedStorage.Events.ChooseDialogueOption:FireServer(inputValue.Name, 1, "Pray", { inputValue })
        end)
        task.wait(0.5)
        pcall(function()
            getgenv().NNVN_ClickLeaveButton()
        end)
        hasTriggered = true
    end)
    return hasTriggered
end

local isAllowed2 = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local viewportSize = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
local maxResult = math.max(420, math.floor(viewportSize.X - 72))
local maxResult2 = math.max(320, math.floor(viewportSize.Y - 88))
local isMatched = viewportSize.X < 650
local discordUrl = "https://discord.gg/5JJAuHRUgJ"
local function resolveUnknown()
    local defaultStatus = "Unknown"
    pcall(function()
        defaultStatus = tostring(getCurrentIslandName() or "Unknown")
    end)
    return {
        { Text = "NNVN Hub", Copyable = false },
        { Text = "|", Copyable = false },
        { Text = "Heavyweight Fishing", Copyable = false },
        { Text = "|", Copyable = false },
        { Text = "Island: " .. defaultStatus, Copyable = false },
        { Text = "|", Copyable = false },
        { Text = "discord.gg/5JJAuHRUgJ", Copyable = true, CopyText = discordUrl }
    }
end

pcall(function()
    if item2.SetDPIScale then
        item2:SetDPIScale(100)
    end
end)
local Window = item2:CreateWindow({
    Title = uiStrings.win_title,
    Author = uiStrings.win_sub,
    Icon = "rbxassetid://138952058031836",
    Folder = "NNVN_Hub",
    Footer = resolveUnknown(),
    CopyableFooter = true,
    Size = isAllowed2 and UDim2.fromOffset(maxResult, maxResult2) or UDim2.fromOffset(760, 520),
    MinSize = isAllowed2 and Vector2.new(500, 360) or Vector2.new(560, 340),
    MaxSize = isAllowed2 and Vector2.new(650, 500) or Vector2.new(940, 640),
    SideBarWidth = isAllowed2 and (isMatched and 56 or 156) or 220,
    SidebarWidth = isAllowed2 and (isMatched and 56 or 156) or 220,
    MinSidebarWidth = isAllowed2 and 132 or 220,
    Accent = NNVN_ColorFromHex(getgenv().NNVN_AccentColorHex, Color3.fromRGB(86, 140, 255)),
    BackgroundColor = Color3.fromRGB(16, 17, 20),
    Acrylic = false,
    Transparent = true,
    Theme = "Dark",
    BackgroundImage = getgenv().NNVN_BackgroundImage or "",
    BackgroundImageTransparency = tonumber(getgenv().NNVN_BackgroundTransparency) or 0.72,
    BackgroundImageScaleType = Enum.ScaleType.Crop,
    HideSearchBar = false,
    ScrollBarEnabled = true,
    ToggleKey = Enum.KeyCode.K,
    ShowCustomCursor = false,
    Minimizable = true,
    MinimizedWidth = 300,
    ShowMobileButtons = true,
    UnlockMouseWhileOpen = not isAllowed2,
    Resizable = true,
    EnableSidebarResize = true,
    SidebarCompactWidth = 48,
    CompactWidthActivation = 128,
    SidebarCompacted = isAllowed2 and isMatched,
    EnableCompacting = true,
    DisableCompactingSnap = false,
    MobileOptimized = true,
    CornerRadius = 10,
    Font = Enum.Font.Gotham,
    User = { Enabled = true, Anonymous = false }
})
if not Window then
    warn("[NNVN Hub] UltraObsidian window failed to initialize")
    return
end
local mainMap
do
    pcall(applyWindowScheme)
    pcall(function()
        if Window.SetCompact then
            Window:SetCompact(false)
        end
    end)
    Window:EditOpenButton({
        Title = "NNVN Hub",
        Icon = "rbxassetid://138952058031836",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromHex("0A1128"), Color3.fromHex("4B0082")),
        OnlyMobile = false,
        Enabled = true,
        Draggable = true
    })
    getgenv().NNVN_StatusFPS = tonumber(getgenv().NNVN_StatusFPS) or 0
    local item14
    local function resolveParent2()
        if item14 and item14.Parent then
            return item14
        end
        for _, item in ipairs({ Workspace, ReplicatedStorage }) do
            for _, item2 in ipairs({ "ServerStartTime", "ServerStartedAt", "ServerStart", "ServerCreatedAt" }) do
                local itemEntry = item:FindFirstChild(item2)
                if itemEntry and (itemEntry:IsA("NumberValue") or itemEntry:IsA("IntValue")) then
                    item14 = itemEntry
                    return itemEntry
                end
            end
        end
        return nil
    end
    NNVN_GetServerNow = function()
        local item
        pcall(function()
            item = Workspace:GetServerTimeNow()
        end)
        return tonumber(item)
    end
    NNVN_GetServerUptimeSeconds = function()
        local serverNow = NNVN_GetServerNow()
        if not serverNow then
            return nil
        end
        for _, item in ipairs({ Workspace, ReplicatedStorage }) do
            for _, item2 in ipairs({ "ServerStartTime", "ServerStartedAt", "ServerStart", "ServerCreatedAt" }) do
                local parsedNum = tonumber(item:GetAttribute(item2))
                if parsedNum and parsedNum > 1000000000 and parsedNum <= serverNow then
                    return math.floor(serverNow - parsedNum)
                end
            end
        end
        local parent2 = resolveParent2()
        local parsedNum2 = parent2 and tonumber(parent2.Value)
        if parsedNum2 and parsedNum2 > 1000000000 and parsedNum2 <= serverNow then
            return math.floor(serverNow - parsedNum2)
        end
        return nil
    end
    NNVN_FormatServerTime = function(inputValue)
        inputValue = math.max(0, math.floor(tonumber(inputValue) or 0))
        return string.format("%02d:%02d:%02d", math.floor(inputValue / 3600), math.floor(inputValue % 3600 / 60), inputValue % 60)
    end
    NNVN_FormatServerClock = function()
        local serverNow = NNVN_GetServerNow()
        if not serverNow then
            return "--:--:--"
        end
        return os.date("!%H:%M:%S", math.floor(serverNow))
    end
    local function resolveIcon()
        local function resolveUnknown()
            local defaultStatus = "Unknown"
            pcall(function()
                defaultStatus = tostring(getCurrentIslandName() or "Unknown")
            end)
            return defaultStatus:gsub("%s+Island$", "")
        end
        local function resolveIsPremium()
            return (rawget(_G, "NNVN_IsPremium") == true or getgenv().NNVN_IsPremium == true or rawget(_G, "SCRIPT_IsPremium") == true or getgenv().SCRIPT_IsPremium == true) and "PREMIUM" or "FREE"
        end
        local itemList = {
            {
                Icon = "fish",
                Text = function()
                    return "NNVN Hub · Heavyweight Fishing " .. tostring(hubVersion)
                end,
                Accent = true
            },
            {
                Icon = "cloud-sun",
                Text = function()
                    local defaultStatus = "Clear"
                    pcall(function()
                        defaultStatus = tostring(getCurrentWeather() or "Clear")
                    end)
                    return defaultStatus
                end
            }
        }
        if not isAllowed2 then
            itemList[#itemList + 1] = {
                Icon = "gauge",
                Text = function()
                    return tostring(getgenv().NNVN_StatusFPS or 0) .. " FPS"
                end
            }
            itemList[#itemList + 1] = {
                Icon = "wifi",
                Text = function()
                    local pingLabel = "-- ms"
                    pcall(function()
                        pingLabel = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
                    end)
                    return tostring(pingLabel)
                end
            }
        end
        itemList[#itemList + 1] = { Icon = "map-pin", Text = resolveUnknown }
        itemList[#itemList + 1] = { Icon = "badge-check", Text = resolveIsPremium }
        return itemList
    end
    local item15
    if item2.AddWatermark then
        item15 = item2:AddWatermark(resolveIcon())
        pcall(function()
            local uiScale = item15 and item15.Holder and item15.Holder:FindFirstChildOfClass("UIScale")
            if uiScale then
                uiScale.Scale = 0.88
            end
        end)
    end
    NNVN_SetWatermarkVisible = function(inputValue)
        getgenv().NNVN_Watermark = inputValue == true
        pcall(function()
            if item15 and item15.SetVisible then
                item15:SetVisible(inputValue == true)
            elseif item15 and item15.Holder then
                item15.Holder.Visible = inputValue == true
            end
        end)
    end
    NNVN_SetWatermarkVisible(getgenv().NNVN_Watermark)
    task.spawn(function()
        while task.wait(1) do
            if Window and Window.SetFooter then
                pcall(function()
                    Window:SetFooter(resolveUnknown())
                end)
            end
        end
    end)
    applyWindUIGlassStyle = function()
        if getgenv()._NNVN_GlassApplied then
            return
        end
        getgenv()._NNVN_GlassApplied = true
        local delaySeconds = 0.72
        local delaySeconds2 = 0.64
        local delaySeconds3 = 0.76
        local delaySeconds4 = 0.55
        isHubGui = function(instance)
            if not instance then
                return false
            end
            local formattedText = string.lower(instance.Name or "")
            return formattedText:find("wind") or formattedText:find("nnvn") or formattedText:find("hub")
        end
        shouldSoften = function(instance)
            if not instance:IsA("GuiObject") then
                return false
            end
            if instance.BackgroundTransparency >= 0.94 then
                return false
            end
            local backgroundColor3 = instance.BackgroundColor3
            local computedValue = (backgroundColor3.R + backgroundColor3.G + backgroundColor3.B) / 3
            local isMatched = backgroundColor3.R <= backgroundColor3.G and backgroundColor3.B <= backgroundColor3.G and backgroundColor3.G > 0.18
            return computedValue < 0.78 or isMatched
        end
        local viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1366, 768)
        for _, item in ipairs(CoreGui:GetChildren()) do
            if not item:IsA("ScreenGui") or not isHubGui(item) then
                continue
            end
            for _, item2 in ipairs(item:GetDescendants()) do
                if shouldSoften(item2) then
                    local absoluteSize = item2.AbsoluteSize
                    if viewportSize.X * 0.82 < absoluteSize.X and viewportSize.Y * 0.82 < absoluteSize.Y then
                        item2.BackgroundTransparency = 1
                    else
                        local formattedText = string.lower(item2.Name or "")
                        if formattedText:find("sidebar") or formattedText:find("tab") or formattedText:find("navigation") then
                            item2.BackgroundTransparency = math.max(item2.BackgroundTransparency, delaySeconds3)
                        elseif formattedText:find("dropdown") or formattedText:find("slider") or formattedText:find("toggle") or formattedText:find("input") then
                            item2.BackgroundTransparency = math.max(item2.BackgroundTransparency, delaySeconds2)
                        else
                            item2.BackgroundTransparency = math.max(item2.BackgroundTransparency, delaySeconds)
                        end
                    end
                elseif item2:IsA("UIStroke") then
                    item2.Transparency = math.max(item2.Transparency, delaySeconds4)
                end
            end
        end
    end
    getgenv().NNVN_WindUIGlassLoop = true
    patchContainer(Window)
    if not Window.AddTab and Window.Tab then
        Window.AddTab = function(inputValue, secondValue)
            local tab = inputValue:Tab(secondValue)
            table.insert(stateMap, tab)
            return patchContainer(tab)
        end
    end
    local selectTab = Window.SelectTab
    Window.SelectTab = function(inputValue, secondValue)
        if type(secondValue) == "table" and secondValue.Index then
            secondValue = secondValue.Index
        end
        if selectTab and secondValue then
            return selectTab(inputValue, secondValue)
        end
    end
    mainMap = {
        Main = Window:AddTab({ Title = "Home", Icon = "house", Order = 1 }),
        Fishing = Window:AddTab({ Title = uiStrings.tab_fishing, Icon = "fish" }),
        Boss = Window:AddTab({ Title = uiStrings.tab_boss, Icon = "swords" }),
        Quest = Window:AddTab({ Title = uiStrings.tab_quest, Icon = "clipboard-list" }),
        Sell = Window:AddTab({ Title = "Sell", Icon = "coins" }),
        Weather = Window:AddTab({ Title = "Weather", Icon = "cloud-sun" }),
        Teleport = Window:AddTab({ Title = uiStrings.tab_tp, Icon = "map-pin" }),
        BuyRod = Window:AddTab({ Title = "Rod", Icon = "shopping-cart" }),
        Learn = Window:AddTab({ Title = "Learn Skill", Icon = "book-open" }),
        Bait = Window:AddTab({ Title = uiStrings.tab_bait, Icon = "worm" }),
        Visual = Window:AddTab({ Title = "Visual", Icon = "eye" }),
        Hop = Window:AddTab({ Title = "Server Hop", Icon = "server" }),
        Webhook = Window:AddTab({ Title = "Webhook", Icon = "webhook" }),
        Extra = Window:AddTab({ Title = uiStrings.tab_extra, Icon = "sparkles" }),
        Settings = Window:AddTab({ Title = uiStrings.tab_settings, Icon = "settings" })
    }
    patchContainer(mainMap.Main)
    patchContainer(mainMap.Fishing)
    patchContainer(mainMap.Boss)
    patchContainer(mainMap.Quest)
    patchContainer(mainMap.Sell)
    patchContainer(mainMap.Weather)
    patchContainer(mainMap.Teleport)
    patchContainer(mainMap.BuyRod)
    patchContainer(mainMap.Learn)
    patchContainer(mainMap.Bait)
    patchContainer(mainMap.Visual)
    patchContainer(mainMap.Hop)
    patchContainer(mainMap.Extra)
    patchContainer(mainMap.Settings)
    patchContainer(mainMap.Webhook)
    local item16
    local item17
    local item18
    local function resolveSetDisabled(inputValue)
        for _, item in ipairs({ item16, item17, item18 }) do
            if item and item.SetDisabled then
                item:SetDisabled(not inputValue)
            end
        end
    end
    local safetyControlsSection = mainMap.Main:AddSection({ Title = "Safety Controls", Icon = "shield-check" })
    safetyControlsSection:AddParagraph({
        Title = "Safety Mode",
        Content = "Limits repeated remotes and rapid movement. It reduces spam but cannot guarantee protection from game moderation."
    })
    safetyControlsSection:AddToggle("NNVN_SafetyMode", {
        Title = "Enable Safety Mode",
        Default = getgenv().NNVN_SafetyMode ~= false,
        Callback = function(amount)
            getgenv().NNVN_SafetyMode = amount == true
            getgenv().NNVN_RemoteSafetyTimes = {}
            resolveSetDisabled(amount == true)
        end
    })
    item16 = safetyControlsSection:AddSlider("NNVN_RemoteMinInterval", {
        Title = "Remote Minimum Interval",
        Description = "Minimum seconds between repeated protected remotes. Recommended: 0.75 or higher.",
        Default = tonumber(getgenv().NNVN_RemoteMinInterval) or 0.75,
        Min = 0.5,
        Max = 3,
        Rounding = 2,
        Disabled = getgenv().NNVN_SafetyMode == false,
        Callback = function(amount)
            getgenv().NNVN_RemoteMinInterval = math.max(0.5, tonumber(amount) or 0.75)
            getgenv().NNVN_RemoteSafetyTimes = {}
        end
    })
    item17 = safetyControlsSection:AddSlider("NNVN_TweenStartDelay", {
        Title = "Tween Start Delay",
        Description = "Small pause between automatic Tween trips. Recommended: 0.20 seconds or higher.",
        Default = tonumber(getgenv().NNVN_TweenStartDelay) or 0.2,
        Min = 0,
        Max = 2,
        Rounding = 2,
        Disabled = getgenv().NNVN_SafetyMode == false,
        Callback = function(enabled)
            getgenv().NNVN_TweenStartDelay = math.max(0, tonumber(enabled) or 0.2)
        end
    })
    item18 = safetyControlsSection:AddToggle("NNVN_BlockDuplicateTween", {
        Title = "Block Duplicate Tween",
        Description = "Skips repeated movement to the same destination when already there.",
        Default = getgenv().NNVN_BlockDuplicateTween ~= false,
        Disabled = getgenv().NNVN_SafetyMode == false,
        Callback = function(selectedValue)
            getgenv().NNVN_BlockDuplicateTween = selectedValue == true
        end
    })
    resolveSetDisabled(getgenv().NNVN_SafetyMode ~= false)
    for _, entry in pairs(mainMap) do
        local function resolveOpened(inputValue)
            if type(inputValue) == "table" then
                inputValue.Opened = true
                inputValue.Collapsed = false
            end
            return inputValue
        end
        local section = entry.Section
        if section and not entry.__NNVN_SectionCompat then
            entry.__NNVN_SectionCompat = true
            entry.Section = function(selfContainer, configArg)
                return section(selfContainer, resolveOpened(configArg))
            end
        end
        local addSection = entry.AddSection
        if addSection and not entry.__NNVN_AddSectionCompat then
            entry.__NNVN_AddSectionCompat = true
            entry.AddSection = function(selfContainer, configArg)
                return addSection(selfContainer, resolveOpened(configArg))
            end
        end
    end
    GetAllFishNames = function()
        local stateMap = {}
        local lookupMap = {}
        local info = ReplicatedStorage:FindFirstChild("Info")
        local inventory = info and info:FindFirstChild("Inventory")
        if inventory then
            for _, item in ipairs(inventory:GetChildren()) do
                if item:IsA("ModuleScript") and not lookupMap[item.Name] then
                    lookupMap[item.Name] = true
                    table.insert(stateMap, item.Name)
                end
            end
        end
        if #stateMap == 0 then
            local data = ReplicatedStorage:FindFirstChild("Data")
            local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
            local index = playerData and playerData:FindFirstChild("Index")
            if index then
                for _, item2 in ipairs(index:GetChildren()) do
                    if not lookupMap[item2.Name] then
                        lookupMap[item2.Name] = true
                        table.insert(stateMap, item2.Name)
                    end
                end
            end
        end
        table.sort(stateMap)
        return stateMap
    end
    GetFishNamesForSelection = function()
        local allFishNames = GetAllFishNames()
        if #allFishNames == 0 then
            allFishNames = {
                "Rainbow Dragonfish",
                "Frost Queenfish",
                "Nameless Octoparasite",
                "Colossal Tigerfish",
                "Heavenpiercer Turtle",
                "Golden Guardian Fish",
                "Crimson Electric Eel",
                "Frost Kingfish",
                "Ascended Perch",
                "Primordial Kunfish Overlord",
                "Warbringer Shark",
                "Flying Fish Emperor",
                "Flying Fish Empress",
                "Sanguine Fish",
                "Draconic Koi",
                "Reborn Puffer Beast"
            }
        end
        return allFishNames
    end
    FavoriteSelectedFish = function()
        local selectedFavoriteFish = getgenv().NNVN_SelectedFavoriteFish
        if not selectedFavoriteFish or selectedFavoriteFish == "" or selectedFavoriteFish == "No Selection" then
            return 0
        end
        local data = ReplicatedStorage:FindFirstChild("Data")
        local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
        local inventory = playerData and playerData:FindFirstChild("Inventory")
        local favoriteItem = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("FavoriteItem")
        if not inventory or not favoriteItem then
            return 0
        end
        local combinedText = selectedFavoriteFish .. " | "
        local counter = 0
        for _, item in ipairs(inventory:GetChildren()) do
            if item.Name:sub(1, #combinedText) == combinedText and not item.Name:match(" | Favorite$") then
                favoriteItem:FireServer(item.Name)
                counter = counter + 1
                task.wait(0.12)
            end
        end
        return counter
    end
    fishSec = mainMap.Fishing:AddSection({ Title = "Fishing", Icon = "fish" })
    fishSec:AddDropdown("NNVN_ActionMethod", {
        Title = "Operation Method",
        Description = "Instant sends the remote directly. Teleport moves first. Tween is safer.",
        Values = { "Instant [Risk]", "Teleport [Risk]", "Tween [Safe]" },
        Default = NormalizeActionMethodName(getgenv().NNVN_ActionMethod) == "Instant" and "Instant [Risk]" or NormalizeActionMethodName(getgenv().NNVN_ActionMethod) == "Teleport" and "Teleport [Risk]" or "Tween [Safe]",
        Callback = function(amount)
            local actionMethodName = NormalizeActionMethodName(NormalizeTranslatedChoice(amount, "Tween [Safe]"))
            getgenv().NNVN_ActionMethod = actionMethodName == "Instant" and "Instant [Risk]" or actionMethodName == "Teleport" and "Teleport [Risk]" or "Tween [Safe]"
            getgenv().NNVN_TicketFarmMode = actionMethodName == "Tween" and "Tween [Safe]" or "Teleport [Risk]"
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Operation Method",
                    Content = "Selected: " .. getgenv().NNVN_ActionMethod,
                    Duration = 3
                })
            end
        end
    })
    fishSec:AddSlider("NNVN_TweenSpeed", {
        Title = "Tween Speed",
        Default = getgenv().NNVN_TweenSpeed or 300,
        Min = 80,
        Max = 600,
        Rounding = 10,
        Callback = function(enabled)
            getgenv().NNVN_TweenSpeed = tonumber(enabled) or 300
        end
    })
    local item19
    fishSec:AddToggle("NNVN_SkyFarm", {
        Title = "Sky Farm",
        Description = "Moves only the Y axis to Ticket Quest sky height and keeps the current X/Z.",
        Default = getgenv().NNVN_SkyFarm == true,
        Callback = function(amount)
            if item19 and item19.SetVisible then
                item19:SetVisible(amount == true)
            end
            NNVN_SetSkyFarm(amount == true)
        end
    })
    item19 = fishSec:AddSlider("NNVN_SkyFarmHeight", {
        Title = "Sky Farm Height",
        Description = "Default matches the Ticket Quest sky height.",
        Default = tonumber(getgenv().NNVN_SkyFarmHeight) or 609,
        Min = 100,
        Max = 1000,
        Rounding = 1,
        Visible = getgenv().NNVN_SkyFarm == true,
        Callback = function(selectedValue)
            NNVN_SetSkyFarmHeight(selectedValue)
        end
    })
    fishSec:AddToggle("NNVN_Anchor", {
        Title = "Anchor Bar",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_Anchor = enabled
        end
    })
    local item20
    fishSec:AddToggle("NNVN_AutoCast", {
        Title = "Auto Cast Rod",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoCast = enabled == true
            if item20 and item20.SetVisible then
                item20:SetVisible(enabled == true)
            end
            if enabled and not HasFishingRod() then
                pcall(EquipSlot1)
            end
        end
    })
    item20 = fishSec:AddSlider("NNVN_AutoCastDelay", {
        Title = "Auto Cast Delay",
        Description = "Not recommended below 3 seconds.",
        Default = tonumber(getgenv().NNVN_AutoCastDelay) or 3,
        Min = 0.5,
        Max = 10,
        Rounding = 1,
        Visible = getgenv().NNVN_AutoCast == true,
        Callback = function(enabled)
            getgenv().NNVN_AutoCastDelay = math.max(0.5, tonumber(enabled) or 3)
        end
    })
    fishSec:AddToggle("NNVN_AutoSkill", {
        Title = "Auto Use Skills",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoSkill = enabled
        end
    })
    fishSec:AddDropdown("NNVN_AutoSkillMethod", {
        Title = "Auto Skills Method",
        Values = { "Keyboard", "Skill Event", "Mobile (Click)" },
        Default = getgenv().NNVN_AutoSkillMethod or "Skill Event",
        Callback = function(selectedValue)
            getgenv().NNVN_AutoSkillMethod = selectedValue == "Skill Event" and "Skill Event" or selectedValue == "Mobile (Click)" and "Mobile (Click)" or "Keyboard"
        end
    })
    for i = 1, 4 do
        local i2 = i
        fishSec:AddDropdown("NNVN_SkillOrder" .. i2, {
            Title = "Skill Order " .. i2,
            Values = { "Z", "X", "C", "V" },
            Default = getgenv().NNVN_SkillOrder[i2] or ({ "Z", "X", "C", "V" })[i2],
            Callback = function(selectedValue)
                local skillOrder = getgenv().NNVN_SkillOrder
                for i = 1, 4 do
                    if i ~= i2 and skillOrder[i] == selectedValue then
                        skillOrder[i] = skillOrder[i2]
                        skillOrder[i2] = selectedValue
                        return
                    end
                end
                skillOrder[i2] = selectedValue
            end
        })
    end
    fishSec:AddDropdown("NNVN_SkillPick", {
        Title = "Select Skills to Auto-Press",
        Values = { "Z", "X", "C", "V" },
        Multi = true,
        Default = { "Z", "X", "C", "V" },
        Callback = function(selectedValue)
            local skillFlags = { Z = false, X = false, C = false, V = false }
            for key, entry in pairs(selectedValue) do
                if skillFlags[key] ~= nil then
                    skillFlags[key] = entry
                end
            end
            getgenv().NNVN_Skills = skillFlags
        end
    })
    configMainSec = mainMap.Fishing:AddSection({ Title = "Configuration", Icon = "settings-2" })
    configMainSec:AddInput("NNVN_PositionNameInput", {
        Title = "Position Name",
        Placeholder = "Type position name",
        Default = getgenv().NNVN_PositionNameInput,
        Callback = function(inputText)
            local trimTextResult = trimText(inputText)
            getgenv().NNVN_PositionNameInput = trimTextResult ~= "" and trimTextResult or "Position 1"
        end
    })
    configMainSec:AddButton({
        Title = "Create Position",
        Icon = "map-pin",
        Callback = function()
            createSavedPosition()
        end
    })
    PositionDropdown = configMainSec:AddDropdown("NNVN_SelectedPosition", {
        Title = "Select Position",
        Values = buildCustomPositionNames(),
        Default = getgenv().NNVN_SelectedPosition,
        Searchable = true,
        Callback = function(selectedValue)
            getgenv().NNVN_SelectedPosition = NormalizeTranslatedChoice(selectedValue, "No Position")
            if getgenv().NNVN_PositionLock and getgenv().NNVN_PositionTeleportMode == "Save Position" then
                teleportToSelectedSavedPosition()
            end
        end
    })
    configMainSec:AddButton({
        Title = "Teleport To Selected Position",
        Description = "Teleports directly to the currently selected saved position.",
        Icon = "map-pin",
        Callback = function()
            if not teleportToSelectedSavedPosition() then
                notifyPosition("Create and select a position first.")
            end
        end
    })
    configMainSec:AddDropdown("NNVN_PositionTeleportMode", {
        Title = "Teleport Mode",
        Values = { "No Teleport", "Save Position" },
        Default = getgenv().NNVN_PositionTeleportMode,
        Callback = function(enabled)
            getgenv().NNVN_PositionTeleportMode = NormalizeTranslatedChoice(enabled, "No Teleport")
            if getgenv().NNVN_PositionLock then
                if getgenv().NNVN_PositionTeleportMode == "Save Position" then
                    teleportToSelectedSavedPosition()
                end
                startPositionLock()
            end
        end
    })
    configMainSec:AddToggle("NNVN_PositionLock", {
        Title = "Position Lock",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_PositionLock = enabled and true or false
            if getgenv().NNVN_PositionLock then
                if getgenv().NNVN_PositionTeleportMode == "Save Position" and not teleportToSelectedSavedPosition() then
                    notifyPosition("Create and select a position first.")
                end
                startPositionLock()
            else
                getgenv().NNVN_PositionLockLoopId = (getgenv().NNVN_PositionLockLoopId or 0) + 1
            end
        end
    })
    equipSec = mainMap.Fishing:AddSection({ Title = "Auto Equip", Icon = "package" })
    equipSec:AddToggle("NNVN_AutoEquipBestBait", {
        Title = "Auto Equip Best Bait (by Luck)",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoEquipBestBait = enabled
        end
    })
    autoEquipRodToggle = equipSec:AddToggle("NNVN_AutoEquipRod", {
        Title = "Auto Equip Rod",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoEquipRod = enabled
        end
    })
    activateAutoEquipRodForFarm = function()
        if not getgenv().NNVN_AutoEquipRod then
            getgenv().NNVN_AutoEquipRod = true
            if autoEquipRodToggle and type(autoEquipRodToggle.SetValue) == "function" then
                pcall(function()
                    autoEquipRodToggle:SetValue(true)
                end)
            end
        end
        pcall(EquipSlot1)
    end
    equipSec:AddToggle("NNVN_AutoEquipBestOrb", {
        Title = "Auto Equip Best Orb (by stats)",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoEquipBestOrb = enabled
        end
    })
    equipSec:AddButton({
        Title = "Equip Best Rod Now",
        Callback = function()
            local bestRod = GetBestRod()
            if bestRod then
                item:Notify({
                    Title = "",
                    Content = EquipRod(bestRod) and "Equipped: " .. bestRod or "Failed to equip rod",
                    Duration = 2
                })
            else
                item:Notify({ Title = "", Content = "No rod available", Duration = 2 })
            end
        end
    })
    equipSec:AddButton({
        Title = "Equip Best Orb Now",
        Callback = function()
            local bestOrb = GetBestOrb()
            if bestOrb then
                item:Notify({
                    Title = "",
                    Content = EquipOrb(bestOrb) and "Equipped: " .. bestOrb or "Failed to equip orb",
                    Duration = 2
                })
            else
                item:Notify({ Title = "", Content = "No orb available", Duration = 2 })
            end
        end
    })
    bossFishSec = mainMap.Fishing:AddSection({ Title = "Boss Fishing", Icon = "swords" })
    bossFishSec:AddToggle("NNVN_AutoBossFishing", {
        Title = "Auto Farm Boss",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoBossFishing = enabled
            if enabled then
                getgenv().NNVN_AutoCast = false
            end
            if not enabled and not getgenv().NNVN_AutoFarmSecretBoss then
                local bossFarmState = getgenv().NNVN_BossFarmState
                if bossFarmState then
                    bossFarmState.CurrentTarget = nil
                    bossFarmState.CurrentType = nil
                    bossFarmState.CurrentToken = nil
                    bossFarmState.HasHooked = false
                    bossFarmState.PendingCancel = false
                    bossFarmState.CurrentRunId = (bossFarmState.CurrentRunId or 0) + 1
                end
            end
        end
    })
    bossFishSec:AddToggle("NNVN_AutoFarmSecretBoss", {
        Title = "Auto Farm Secret Boss",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoFarmSecretBoss = enabled
            if enabled then
                getgenv().NNVN_AutoCast = false
            end
            if not enabled and not getgenv().NNVN_AutoBossFishing then
                local bossFarmState = getgenv().NNVN_BossFarmState
                if bossFarmState then
                    bossFarmState.CurrentTarget = nil
                    bossFarmState.CurrentType = nil
                    bossFarmState.CurrentToken = nil
                    bossFarmState.HasHooked = false
                    bossFarmState.PendingCancel = false
                    bossFarmState.CurrentRunId = (bossFarmState.CurrentRunId or 0) + 1
                end
            end
        end
    })
    bossFishSec:AddDropdown("NNVN_AutoSecretBossMode", {
        Title = "Secret Boss Activation",
        Values = { "Always Active", "Only When Weather" },
        Default = getgenv().NNVN_AutoSecretBossMode or "Always Active",
        Callback = function(selectedValue)
            getgenv().NNVN_AutoSecretBossMode = selectedValue == "Only When Weather" and selectedValue or "Always Active"
        end
    })
end

local lookupMap, enzoSection, weatherMap, executeAction, resolveAnchor
do
    favSec = mainMap.Fishing:AddSection({ Title = "Favourite Fish", Icon = "heart" })
    favSec:AddDropdown("NNVN_SelectedFavoriteFish", {
        Title = "Select Fish",
        Values = (function()
            local fishNamesForSelection = GetFishNamesForSelection()
            table.insert(fishNamesForSelection, 1, "No Selection")
            return fishNamesForSelection
        end)(),
        Multi = false,
        Default = "No Selection",
        Callback = function(enabled)
            getgenv().NNVN_SelectedFavoriteFish = enabled == "No Selection" and nil or enabled
        end
    })
    favSec:AddToggle("NNVN_AutoFavoriteFish", {
        Title = "Auto Favourite Selected Fish",
        Default = false,
        SearchBarEnabled = true,
        Callback = function(enabled)
            getgenv().NNVN_AutoFavoriteFish = enabled
            getgenv().NNVN_FavoriteFishLoopId = getgenv().NNVN_FavoriteFishLoopId + 1
            local favoriteFishLoopId = getgenv().NNVN_FavoriteFishLoopId
            if enabled then
                task.spawn(function()
                    while getgenv().NNVN_AutoFavoriteFish and favoriteFishLoopId == getgenv().NNVN_FavoriteFishLoopId do
                        FavoriteSelectedFish()
                        task.wait(1)
                    end
                end)
            end
        end
    })
    skipSec = mainMap.Fishing:AddSection({ Title = "Auto Skip Fish", Icon = "skip-forward" })
    skipSec:AddDropdown("NNVN_SkipFishList", {
        Title = "Fishes to Skip",
        Values = GetFishNamesForSelection(),
        Multi = true,
        SearchBarEnabled = true,
        Default = {},
        Callback = function(enabled)
            getgenv().NNVN_SkipFishList = enabled or {}
        end
    })
    skipSec:AddToggle("NNVN_AutoSkipFish", {
        Title = "Auto Skip Selected Fish",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoSkipFish = enabled
            getgenv().NNVN_SkipFishRequestId = (getgenv().NNVN_SkipFishRequestId or 0) + 1
            local skipFishConnection = getgenv().NNVN_SkipFishConnection
            if skipFishConnection then
                skipFishConnection:Disconnect()
            end
            getgenv().NNVN_SkipFishConnection = nil
            if not enabled then
                return
            end
            local events = ReplicatedStorage:FindFirstChild("Events")
            local fishingMinigame = events and events:FindFirstChild("FishingMinigame")
            if not fishingMinigame then
                item:Notify({
                    Title = "Auto Skip Fish",
                    Content = "FishingMinigame event not found",
                    Duration = 3
                })
                return
            end
            getgenv().NNVN_SkipFishConnection = fishingMinigame.OnClientEvent:Connect(function(inputValue, secondValue, thirdValue)
                if not getgenv().NNVN_AutoSkipFish then
                    return
                end
                local fishName = inputValue and inputValue.FishName
                local skipFishList = getgenv().NNVN_SkipFishList or {}
                if not fishName or type(skipFishList) ~= "table" or not skipFishList[fishName] then
                    return
                end
                getgenv().NNVN_SkipFishRequestId = (getgenv().NNVN_SkipFishRequestId or 0) + 1
                local skipFishRequestId = getgenv().NNVN_SkipFishRequestId
                task.delay(3, function()
                    if getgenv().NNVN_AutoSkipFish and skipFishRequestId == getgenv().NNVN_SkipFishRequestId and thirdValue ~= nil then
                        pcall(function()
                            fishingMinigame:FireServer(false, thirdValue)
                        end)
                    end
                end)
            end)
        end
    })
    skipSec:AddToggle("NNVN_HidePlayerName", {
        Title = "Hide Player Name",
        Description = "Clears workspace.LocalPlayer.HumanoidRootPart.EquippedTitle.PlayerName.",
        Default = getgenv().NNVN_HidePlayerName,
        Callback = function(selectedValue)
            getgenv().NNVN_HidePlayerName = selectedValue
            if not selectedValue then
                getgenv().NNVN_HidePlayerNameText = nil
            end
            applyHidePlayerName()
        end
    })
    lookupMap = {}
    local stateMap4 = {}
    for _, item21 in ipairs({
        { label = "Đảo 1", name = "Beginning Isle" },
        { label = "Đảo 2", name = "Bamboo Isle" },
        { label = "Đảo 3", name = "Fallout Isle" },
        { label = "Đảo 4", name = "Sovereign Isle" },
        { label = "Đảo 5", name = "Perch Isle" },
        { label = "Đảo 6", name = "Frost Isle" },
        { label = "Đảo 7", name = "Coconut Isle" },
        { label = "Đảo 8", name = "Amber Isle" },
        { label = "Đảo 9", name = "Battlefield Isle" },
        { label = "Đảo 10", name = "Mistpeak Isle" }
    }) do
        lookupMap[item21.label] = item21.name
        table.insert(stateMap4, item21.label)
    end
    getgenv().NNVN_EvolveIsland = getgenv().NNVN_EvolveIsland or "Đảo 1"
    getgenv().NNVN_EvolveSkillSlot = getgenv().NNVN_EvolveSkillSlot or "Z"
    getgenv().NNVN_AutoEvolveSkill = false
    getgenv().NNVN_EvolveConn = nil
    getgenv().NNVN_EvolvePrevFlags = nil
    getgenv().NNVN_EvolveLoopId = 0
    getgenv().NNVN_EvolveBusy = false
    local function resolveEvolveIsland()
        local lookupEntry = lookupMap[getgenv().NNVN_EvolveIsland]
        if not lookupEntry then
            return false
        end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            return false
        end
        local beginningIsleMap22 = beginningIsleMap2 and beginningIsleMap2[lookupEntry]
        if beginningIsleMap22 then
            pcall(function()
                NNVN_TweenTo(beginningIsleMap22)
            end)
            return true
        end
        for _, item in ipairs(TeleportList or {}) do
            if item.name == lookupEntry then
                pcall(function()
                    NNVN_TweenTo(CFrame.new(item.cf.Position) + Vector3.new(0, 5, 0))
                end)
                return true
            end
        end
        return false
    end
    evolveSkillSec = mainMap.Fishing:AddSection({ Title = "Auto Evolve Skill", Icon = "zap" })
    evolveSkillSec:AddDropdown("NNVN_EvolveIsland", {
        Title = "Select Island",
        Values = stateMap4,
        Default = "Đảo 1",
        Callback = function(selected)
            getgenv().NNVN_EvolveIsland = selected or "Đảo 1"
            if getgenv().NNVN_AutoEvolveSkill then
                task.spawn(resolveEvolveIsland)
            end
        end
    })
    evolveSkillSec:AddDropdown("NNVN_EvolveSkillSlot", {
        Title = "Select Skill Slot",
        Values = { "Z", "X", "C", "V" },
        Default = "Z",
        Callback = function(enabled)
            getgenv().NNVN_EvolveSkillSlot = enabled or "Z"
        end
    })
    evolveSkillSec:AddToggle("NNVN_AutoEvolveSkill", {
        Title = "Auto Teleport + Auto Farm Skill To Evolve",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoEvolveSkill = enabled and true or false
            if getgenv().NNVN_EvolveConn then
                pcall(function()
                    getgenv().NNVN_EvolveConn:Disconnect()
                end)
                getgenv().NNVN_EvolveConn = nil
            end
            getgenv().NNVN_EvolveLoopId = (getgenv().NNVN_EvolveLoopId or 0) + 1
            getgenv().NNVN_EvolveBusy = false
            if not getgenv().NNVN_AutoEvolveSkill then
                local evolvePrevFlags = getgenv().NNVN_EvolvePrevFlags
                if evolvePrevFlags then
                    getgenv().NNVN_Anchor = evolvePrevFlags.Anchor and true or false
                    getgenv().NNVN_AutoCast = evolvePrevFlags.AutoCast and true or false
                end
                getgenv().NNVN_EvolvePrevFlags = nil
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Evolve Skill",
                        Content = "Stopped. Previous Anchor / AutoCast states restored.",
                        Duration = 3,
                        Icon = "square"
                    })
                end
                return
            end
            getgenv().NNVN_EvolvePrevFlags = { Anchor = getgenv().NNVN_Anchor, AutoCast = getgenv().NNVN_AutoCast }
            getgenv().NNVN_Anchor = true
            getgenv().NNVN_AutoCast = true
            if not HasFishingRod() then
                pcall(EquipSlot1)
            end
            task.spawn(function()
                resolveEvolveIsland()
            end)
            local evolveLoopId = getgenv().NNVN_EvolveLoopId
            task.spawn(function()
                while getgenv().NNVN_AutoEvolveSkill and evolveLoopId == getgenv().NNVN_EvolveLoopId do
                    pcall(resolveEvolveIsland)
                    task.wait(3)
                end
            end)
            task.spawn(function()
                local events = ReplicatedStorage:WaitForChild("Events", 10)
                if not events then
                    if getgenv().NNVN_Notify then
                        item:Notify({
                            Title = "Evolve Skill",
                            Content = "Events folder not found!",
                            Duration = 4,
                            Icon = "circle-alert"
                        })
                    end
                    return
                end
                local fishingMinigame = events:WaitForChild("FishingMinigame", 10)
                local useSkill = events:WaitForChild("UseSkill", 10)
                if not fishingMinigame or not useSkill then
                    if getgenv().NNVN_Notify then
                        item:Notify({
                            Title = "Evolve Skill",
                            Content = "FishingMinigame / UseSkill remote not found!",
                            Duration = 4,
                            Icon = "circle-alert"
                        })
                    end
                    return
                end
                getgenv().NNVN_EvolveConn = fishingMinigame.OnClientEvent:Connect(function(inputValue, secondValue, thirdValue)
                    if not getgenv().NNVN_AutoEvolveSkill then
                        return
                    end
                    if not thirdValue or thirdValue == "" then
                        return
                    end
                    if getgenv().NNVN_EvolveBusy then
                        return
                    end
                    getgenv().NNVN_EvolveBusy = true
                    local evolveSkillSlot = getgenv().NNVN_EvolveSkillSlot or "Z"
                    task.spawn(function()
                        task.wait(3.5)
                        pcall(function()
                            useSkill:FireServer(evolveSkillSlot)
                        end)
                        task.wait(0.5)
                        pcall(function()
                            fishingMinigame:FireServer(false, thirdValue)
                        end)
                        getgenv().NNVN_EvolveBusy = false
                    end)
                end)
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Evolve Skill",
                        Content = string.format("Farming on %s with skill [%s]. Waiting for fish...", tostring(getgenv().NNVN_EvolveIsland), tostring(getgenv().NNVN_EvolveSkillSlot)),
                        Duration = 4,
                        Icon = "zap"
                    })
                end
            end)
        end
    })
    enzoSection = mainMap.Boss:AddSection({ Title = "Enzo", Icon = "swords" })
    enzoSection:AddToggle("NNVN_AutoBoss", {
        Title = "Auto Fight Enzo",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoBoss = enabled
        end
    })
    enzoSection:AddDropdown("NNVN_BossDifficulty", {
        Title = "Difficulty",
        Values = { "Normal", "Hard", "Nightmare" },
        Default = "Normal",
        Callback = function(selectedValue)
            getgenv().NNVN_BossDifficulty = selectedValue
        end
    })
    enzoSection:AddButton({
        Title = "Start Enzo Fight Now",
        Callback = function()
            task.spawn(function()
                pcall(equipRodBeforeBossFight)
                local npcByName = FindNPCByName("Enzo") or FindNPCByName("Boss NPC") or FindNPCByName("BossNPC")
                RunActionWithMethod({
                    target = npcByName,
                    forceMethod = "Teleport",
                    teleport = function()
                        if not npcByName then
                            return false
                        end
                        return NNVN_MoveNear(npcByName, delaySeconds2, "Teleport")
                    end,
                    returnAfter = false
                }, function()
                    equipRodBeforeBossFight()
                    pcall(function()
                        ReplicatedStorage.Events.StartBossFight:FireServer("Enzo", getgenv().NNVN_BossDifficulty)
                        if getgenv().NNVN_Notify then
                            item:Notify({
                                Title = "",
                                Content = "Enzo fight started (" .. getgenv().NNVN_BossDifficulty .. ")",
                                Duration = 3
                            })
                        end
                    end)
                end)
            end)
        end
    })
    enzoSection:AddToggle("NNVN_AutoPhase2", {
        Title = uiStrings.auto_phase2,
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoPhase2 = enabled
        end
    })
    weatherMap = {
        weather = true,
        spirit = true,
        maoshan = true,
        taoist = true,
        vermilion = true,
        blacktortoise = true,
        serverage = true
    }
    isGreenBossHitbox = function(inputValue)
        if not inputValue then
            return false
        end
        local function resolveColor3(inputValue)
            return typeof(inputValue) == "Color3" and inputValue.G > 0.35 and inputValue.R * 1.15 < inputValue.G and inputValue.B * 1.05 < inputValue.G
        end
        local function executeAction(inputValue)
            local ok, result = pcall(function()
                return inputValue.BackgroundColor3
            end)
            if ok and resolveColor3(result) then
                return true
            end
            local ok2, result2 = pcall(function()
                return inputValue.ImageColor3
            end)
            return ok2 and resolveColor3(result2)
        end
        local function executeAction2(inputValue)
            local function resolveColor3(inputValue)
                return typeof(inputValue) == "Color3" and inputValue.R > 0.35 and inputValue.G * 1.15 < inputValue.R and inputValue.B * 1.05 < inputValue.R
            end
            local ok, result = pcall(function()
                return inputValue.BackgroundColor3
            end)
            if ok and resolveColor3(result) then
                return true
            end
            local ok2, result2 = pcall(function()
                return inputValue.ImageColor3
            end)
            return ok2 and resolveColor3(result2)
        end
        local ok, result = pcall(function()
            if executeAction2(inputValue) then
                return false
            end
            if executeAction(inputValue) then
                return true
            end
            for _, item in ipairs(inputValue:GetDescendants()) do
                if item:IsA("GuiObject") and executeAction(item) then
                    return true
                end
            end
            return false
        end)
        return ok and result == true
    end
    NNVN_ShouldHitBossPhase2 = function(inputValue, instance)
        local bar = instance and instance:FindFirstChild("Bar")
        local hitbox = instance and instance:FindFirstChild("Hitbox")
        if not instance or not instance.Visible or not bar or not hitbox then
            table.clear(inputValue.history)
            return false
        end
        local nowTime = os.clock()
        local computedValue = bar.Position.X.Scale + bar.Size.X.Scale * (0.5 - bar.AnchorPoint.X)
        local scale = hitbox.Size.X.Scale
        local computedValue2 = hitbox.Position.X.Scale - scale * hitbox.AnchorPoint.X
        local history = inputValue.history
        history[#history + 1] = { t = nowTime, x = computedValue }
        while #history > 1 and nowTime - history[1].t > 0.15 do
            table.remove(history, 1)
        end
        local mobile = item3 and item3:FindFirstChild("Mobile")
        local fishing = mobile and mobile:FindFirstChild("Fishing")
        local getupvalue2 = debug and debug.getupvalue or getupvalue
        local hasTriggered = false
        local item
        if getconnections and getupvalue2 and fishing then
            pcall(function()
                for _, entry in pairs(getconnections(fishing.MouseButton1Down)) do
                    local upvalue2 = entry.Function and getupvalue2(entry.Function, 1)
                    if type(upvalue2) ~= "function" then
                        continue
                    end
                    item = upvalue2
                    local upvalue22 = getupvalue2(upvalue2, 1)
                    local upvalue23 = getupvalue2(upvalue2, 2)
                    local upvalue24 = getupvalue2(upvalue2, 3)
                    local upvalue25 = getupvalue2(upvalue2, 4)
                    local upvalue26 = getupvalue2(upvalue2, 5)
                    local upvalue27 = getupvalue2(upvalue2, 6)
                    local upvalue28 = getupvalue2(upvalue2, 7)
                    local upvalue29 = getupvalue2(upvalue2, 8)
                    local upvalue210 = getupvalue2(upvalue2, 9)
                    if upvalue22 ~= true or type(upvalue23) ~= "number" or type(upvalue24) ~= "number" or type(upvalue25) ~= "number" or type(upvalue26) ~= "number" or type(upvalue27) ~= "number" or type(upvalue28) ~= "number" or type(upvalue29) ~= "number" or type(upvalue210) ~= "number" or math.abs(upvalue29 - scale) >= 0.005 or math.abs(upvalue210 - computedValue2) >= 0.005 then
                        continue
                    end
                    hasTriggered = true
                    if nowTime - upvalue23 < 0.035 or nowTime - (inputValue.lastHit or 0) < 0.035 then
                        break
                    end
                    local computedValue = (nowTime - 0.025 - upvalue24) % upvalue25 * upvalue26
                    if upvalue27 < computedValue then
                        computedValue = upvalue27 * 2 - computedValue
                    end
                    local computedValue3 = upvalue28 + computedValue
                    local computedValue4 = upvalue29 * 0.3
                    if upvalue210 - computedValue4 * 0.8 > computedValue3 or computedValue3 > upvalue210 + upvalue29 + computedValue4 * 0.8 then
                        break
                    end
                    inputValue.lastHit = nowTime
                    upvalue2(false)
                    break
                end
            end)
        end
        if hasTriggered then
            return false
        end
        if nowTime - (inputValue.lastHit or 0) < 0.04 then
            return false
        end
        local computedValue3 = computedValue
        local computedValue4 = nowTime - 0.041
        for i = #history, 1, -1 do
            if history[i].t <= computedValue4 then
                computedValue3 = history[i].x
                break
            end
        end
        local hitboxBad = instance:FindFirstChild("HitboxBad")
        if hitboxBad and hitboxBad.Visible then
            local scale2 = hitboxBad.Size.X.Scale
            local computedValue5 = hitboxBad.Position.X.Scale - scale2 * hitboxBad.AnchorPoint.X
            if computedValue5 - 0.01 <= computedValue3 and computedValue3 <= computedValue5 + scale2 + 0.01 then
                return false
            end
        end
        local computedValue6 = scale * 0.2
        if computedValue3 < computedValue2 - computedValue6 or computedValue2 + scale + computedValue6 < computedValue3 then
            return false
        end
        inputValue.lastHit = nowTime
        if item and pcall(item, false) then
            return false
        end
        return true
    end
    NNVN_FireBossPhase2Input = function()
        local mobile = item3 and item3:FindFirstChild("Mobile")
        local fishing = mobile and mobile:FindFirstChild("Fishing")
        local hasTriggered = false
        if fishing and getconnections then
            pcall(function()
                for _, entry in pairs(getconnections(fishing.MouseButton1Down)) do
                    if entry.Function then
                        task.spawn(entry.Function)
                        hasTriggered = true
                    elseif entry.Fire then
                        entry:Fire()
                        hasTriggered = true
                    end
                end
            end)
        end
        if not hasTriggered and fishing and firesignal then
            pcall(function()
                firesignal(fishing.MouseButton1Down)
                hasTriggered = true
            end)
        end
        if not hasTriggered then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.delay(0.01, function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end)
                hasTriggered = true
            end)
        end
        return hasTriggered
    end
    startLongDiaohaiFightNow = function()
        local npcFolder = Workspace:FindFirstChild("NPC")
        local boss = npcFolder and npcFolder:FindFirstChild("Boss")
        local longDiaohai = boss and boss:FindFirstChild("Long Diaohai")
        if not longDiaohai then
            return false
        end
        pcall(equipRodBeforeBossFight)
        RunActionWithMethod({
            target = longDiaohai,
            forceMethod = "Teleport",
            teleport = function()
                return NNVN_MoveNear(longDiaohai, delaySeconds2, "Teleport")
            end,
            returnAfter = false
        }, function()
            local events = ReplicatedStorage:FindFirstChild("Events")
            local startBossFight = events and events:FindFirstChild("StartBossFight")
            if startBossFight then
                startBossFight:FireServer("Long Diaohai", getgenv().NNVN_LongDiaohaiDifficulty or "Normal")
            end
        end)
        return true
    end
    local longDiaoHaiSection = mainMap.Boss:AddSection({ Title = "Long Diao Hai", Icon = "swords" })
    longDiaoHaiSection:AddDropdown("NNVN_LongDiaohaiDifficulty", {
        Title = "Long Diaohai Difficulty",
        Values = { "Normal", "Hard", "Nightmare" },
        Default = getgenv().NNVN_LongDiaohaiDifficulty or "Normal",
        Callback = function(selectedValue)
            getgenv().NNVN_LongDiaohaiDifficulty = selectedValue
        end
    })
    longDiaoHaiSection:AddButton({
        Title = "Start Fight Long Diaohai Now",
        Description = "Teleport to Long Diaohai and send the selected difficulty remote.",
        Callback = function()
            task.spawn(function()
                local ok, result = pcall(startLongDiaohaiFightNow)
                if ok and result and getgenv().NNVN_Notify then
                    item:Notify({ Title = "Long Diaohai", Content = "Fight started.", Duration = 3 })
                end
            end)
        end
    })
    longDiaoHaiSection:AddToggle("NNVN_AutoLongDiaohai", {
        Title = "Auto Fight Long Diaohai",
        Description = "Equips the rod, teleports to workspace.NPC.Boss[Long Diaohai], enables only the helpers it needs, then fires the selected difficulty.",
        Default = getgenv().NNVN_AutoLongDiaohai == true,
        Callback = function(enabled)
            getgenv().NNVN_AutoLongDiaohai = enabled == true
        end
    })
    longDiaoHaiSection:AddToggle("NNVN_AutoLongDiaohaiPhase2", {
        Title = "Auto Phase 2",
        Description = "Uses the same green-zone timing and prediction as Enzo Auto Phase 2.",
        Default = getgenv().NNVN_AutoLongDiaohaiPhase2 == true,
        Callback = function(enabled)
            getgenv().NNVN_AutoLongDiaohaiPhase2 = enabled == true
        end
    })
    local item22
    item22 = longDiaoHaiSection:AddToggle("NNVN_AutoHopFightLongDiaohai", {
        Title = "Auto Hop & Fight Long Diaohai",
        Description = "Premium only. Hops while the BossFight title is not Fight, then starts the selected difficulty.",
        Default = getgenv().NNVN_AutoHopFightLongDiaohai == true,
        Locked = not (rawget(_G, "NNVN_IsPremium") == true or getgenv().NNVN_IsPremium == true or getgenv().NNVN_IsPremiumAccess == true),
        Callback = function(selectedValue)
            if getgenv().NNVN_IsApplyingConfig then
                return
            end
            if selectedValue and not ensurePremiumAccess("Auto Hop & Fight Long Diaohai") then
                getgenv().NNVN_AutoHopFightLongDiaohai = false
                task.defer(function()
                    pcall(function()
                        if item22 and item22.SetValue then
                            item22:SetValue(false)
                        end
                    end)
                end)
                return
            end
            getgenv().NNVN_AutoHopFightLongDiaohai = selectedValue == true and refreshPremiumAccess()
            getgenv().NNVN_AllowAutomaticServerHop = getgenv().NNVN_AutoHopFightLongDiaohai
            getgenv().NNVN_ServerHopArmed = getgenv().NNVN_AutoHopFightLongDiaohai
            if not selectedValue and getgenv().NNVN_AutoHopLongDiaohaiPrevFlags then
                local autoHopLongDiaohai = getgenv().NNVN_AutoHopLongDiaohaiPrevFlags
                getgenv().NNVN_Anchor = autoHopLongDiaohai.Anchor
                getgenv().NNVN_AutoSkill = autoHopLongDiaohai.AutoSkill
                getgenv().NNVN_AutoHopLongDiaohaiPrevFlags = nil
            end
        end
    })
    executeAction = function()
        local ok, result = pcall(function()
            local playerGui = LocalPlayer.PlayerGui
            local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
            local menu = mainGui and mainGui:FindFirstChild("Menu")
            local bossFight = menu and menu:FindFirstChild("BossFight")
            local frame = bossFight and bossFight:FindFirstChild("Frame")
            local info = frame and frame:FindFirstChild("Info")
            local fight = info and info:FindFirstChild("Fight")
            local title = fight and fight:FindFirstChild("Title")
            return title and title.Text == "Fight"
        end)
        return ok and result == true
    end
    local function resolveFindFirstChild2()
        local npcFolder = Workspace:FindFirstChild("NPC")
        local boss = npcFolder and npcFolder:FindFirstChild("Boss")
        return boss and boss:FindFirstChild("Long Diaohai")
    end
    equipRodBeforeBossFight = function()
        pcall(function()
            if type(EquipSlot1) == "function" then
                EquipSlot1()
            elseif type(EquipRod) == "function" then
                EquipRod()
            else
                local events = ReplicatedStorage:FindFirstChild("Events")
                local toggleHotbar = events and events:FindFirstChild("ToggleHotbar")
                if toggleHotbar and toggleHotbar:IsA("RemoteFunction") then
                    toggleHotbar:InvokeServer("1", nil)
                end
            end
        end)
    end
    resolveAnchor = function(inputValue)
        if inputValue then
            if not getgenv().NNVN_AutoHopLongDiaohaiPrevFlags then
                getgenv().NNVN_AutoHopLongDiaohaiPrevFlags = {
                    Anchor = getgenv().NNVN_Anchor == true,
                    AutoSkill = getgenv().NNVN_AutoSkill == true
                }
            end
            if not getgenv().NNVN_Anchor then
                getgenv().NNVN_Anchor = true
            end
            if not getgenv().NNVN_AutoSkill then
                getgenv().NNVN_AutoSkill = true
            end
        elseif getgenv().NNVN_AutoHopLongDiaohaiPrevFlags then
            local autoHopLongDiaohai = getgenv().NNVN_AutoHopLongDiaohaiPrevFlags
            getgenv().NNVN_Anchor = autoHopLongDiaohai.Anchor
            getgenv().NNVN_AutoSkill = autoHopLongDiaohai.AutoSkill
            getgenv().NNVN_AutoHopLongDiaohaiPrevFlags = nil
        end
    end
    local function resolveTarget()
        local findFirstChild2 = resolveFindFirstChild2()
        if not findFirstChild2 then
            return false
        end
        equipRodBeforeBossFight()
        local hasTriggered = false
        RunActionWithMethod({
            target = findFirstChild2,
            teleport = function()
                return TPNear(findFirstChild2, delaySeconds2)
            end,
            returnAfter = false
        }, function()
            local events = ReplicatedStorage:FindFirstChild("Events")
            local startBossFight = events and events:FindFirstChild("StartBossFight")
            if startBossFight then
                startBossFight:FireServer("Long Diaohai", getgenv().NNVN_LongDiaohaiDifficulty or "Normal")
                hasTriggered = true
            end
        end)
        return hasTriggered
    end
    task.spawn(function()
        local item
        while task.wait(0.35) do
            local isMatched = getgenv().NNVN_AutoLongDiaohai == true
            if isMatched == item then
                continue
            end
            item = isMatched
            if isMatched then
                resolveAnchor(true)
                pcall(resolveTarget)
            else
                resolveAnchor(false)
            end
        end
    end)
    task.spawn(function()
        while task.wait(1) do
            if not getgenv().NNVN_AutoHopFightLongDiaohai or not canAutoServerHop() then
                continue
            end
            if executeAction() then
                resolveAnchor(true)
                pcall(resolveTarget)
                task.wait(8)
            else
                pcall(function()
                    ServerHop:Teleport(placeId)
                end)
                task.wait(15)
            end
        end
    end)
end

local counter2, computedValue, events
do
    task.spawn(function()
        local historyMap = { history = {} }
        local function resolveClear()
            table.clear(historyMap.history)
            historyMap.lastHit = 0
        end
        if getgenv()._LongDiaohaiPhase2Conn then
            pcall(function()
                getgenv()._LongDiaohaiPhase2Conn:Disconnect()
            end)
        end
        if getgenv()._LongDiaohaiPhase2Heartbeat then
            pcall(function()
                getgenv()._LongDiaohaiPhase2Heartbeat:Disconnect()
            end)
        end
        getgenv()._LongDiaohaiPhase2Conn = RunService.RenderStepped:Connect(function()
            if not getgenv().NNVN_AutoLongDiaohaiPhase2 then
                resolveClear()
                return
            end
            pcall(function()
                local fishing = item3:FindFirstChild("Fishing")
                local bossFightBar = fishing and fishing:FindFirstChild("BossFightBar")
                if not bossFightBar or not bossFightBar.Visible then
                    resolveClear()
                    return
                end
                if NNVN_ShouldHitBossPhase2(historyMap, bossFightBar) then
                    NNVN_FireBossPhase2Input()
                end
            end)
        end)
    end)
    getgenv().NNVN_AutoHopFightEnzo = false
    getgenv().NNVN_AutoHopEnzoPrevFlags = nil
    counter2 = 0
    local function executeAction2()
        local ok, result = pcall(function()
            local mainGui = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
            local menu = mainGui and mainGui:FindFirstChild("Menu")
            local bossFight = menu and menu:FindFirstChild("BossFight")
            local frame = bossFight and bossFight:FindFirstChild("Frame")
            local info = frame and frame:FindFirstChild("Info")
            local fight = info and info:FindFirstChild("Fight")
            local title = fight and fight:FindFirstChild("Title")
            return title and title.Text == "Fight"
        end)
        return ok and result == true
    end
    local function resolveAutoHopEnzo()
        if getgenv().NNVN_AutoHopEnzoPrevFlags then
            return
        end
        getgenv().NNVN_AutoHopEnzoPrevFlags = {
            AutoCast = getgenv().NNVN_AutoCast,
            Anchor = getgenv().NNVN_Anchor,
            AutoPhase2 = getgenv().NNVN_AutoPhase2
        }
    end
    local function resolveAutoHopEnzo2()
        local autoHopEnzoPrev = getgenv().NNVN_AutoHopEnzoPrevFlags
        if not autoHopEnzoPrev then
            return
        end
        if not autoHopEnzoPrev.AutoCast then
            getgenv().NNVN_AutoCast = false
        end
        if not autoHopEnzoPrev.Anchor then
            getgenv().NNVN_Anchor = false
        end
        if not autoHopEnzoPrev.AutoPhase2 then
            getgenv().NNVN_AutoPhase2 = false
        end
        getgenv().NNVN_AutoHopEnzoPrevFlags = nil
    end
    refreshPremiumAccess = function()
        local isMatched = rawget(_G, "NNVN_IsPremium") == true or getgenv().NNVN_IsPremium == true or getgenv().NNVN_IsPremiumAccess == true
        getgenv().NNVN_IsPremiumAccess = isMatched
        return isMatched
    end
    ensurePremiumAccess = function(inputValue)
        if refreshPremiumAccess() then
            return true
        end
        if getgenv().NNVN_Notify and item then
            pcall(function()
                item:Notify({
                    Title = "Premium required",
                    Content = tostring(inputValue or "This feature") .. " is available for Premium users only.",
                    Duration = 3,
                    Icon = "lock"
                })
            end)
        end
        return false
    end
    local item23
    item23 = enzoSection:AddToggle("NNVN_AutoHopFightEnzo", {
        Title = "Auto Hop & Fight Enzo",
        Description = "Hops servers until Enzo is off-cooldown, then starts the fight. Premium only.",
        Default = false,
        Locked = not refreshPremiumAccess(),
        Callback = function(selectedValue)
            if getgenv().NNVN_IsApplyingConfig then
                return
            end
            if selectedValue and not ensurePremiumAccess("Auto Hop & Fight Enzo") then
                getgenv().NNVN_AutoHopFightEnzo = false
                task.defer(function()
                    pcall(function()
                        if item23 and item23.SetValue then
                            item23:SetValue(false)
                        end
                    end)
                end)
                return
            end
            if selectedValue and not refreshPremiumAccess() then
                getgenv().NNVN_AutoHopFightEnzo = false
                getgenv().NNVN_AllowAutomaticServerHop = false
                getgenv().NNVN_ServerHopArmed = false
                return
            end
            getgenv().NNVN_AutoHopFightEnzo = selectedValue == true and refreshPremiumAccess()
            getgenv().NNVN_AllowAutomaticServerHop = getgenv().NNVN_AutoHopFightEnzo
            getgenv().NNVN_ServerHopArmed = getgenv().NNVN_AutoHopFightEnzo
            getgenv().NNVN_ServerHopArmed = selectedValue == true
            counter2 = counter2 + 1
            local counter22 = counter2
            if selectedValue then
                resolveAutoHopEnzo()
                if not getgenv().NNVN_AutoCast then
                    getgenv().NNVN_AutoCast = true
                end
                if not getgenv().NNVN_Anchor then
                    getgenv().NNVN_Anchor = true
                end
                if not getgenv().NNVN_AutoPhase2 then
                    getgenv().NNVN_AutoPhase2 = true
                end
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Auto Hop Enzo",
                        Content = "Started. Will hop until Enzo is available, then fight on " .. (getgenv().NNVN_BossDifficulty or "Normal") .. ".",
                        Duration = 4,
                        Icon = "swords"
                    })
                end
                task.spawn(function()
                    while canAutoServerHop() and getgenv().NNVN_AutoHopFightEnzo and counter22 == counter2 do
                        local ok, result = pcall(function()
                            if executeAction2() then
                                local bossDifficulty = getgenv().NNVN_BossDifficulty or "Normal"
                                local npcByName = FindNPCByName("Enzo") or FindNPCByName("Boss NPC") or FindNPCByName("BossNPC")
                                equipRodBeforeBossFight()
                                RunActionWithMethod({
                                    teleport = function()
                                        if not npcByName then
                                            return false
                                        end
                                        return TPNear(npcByName, delaySeconds2)
                                    end,
                                    returnAfter = false
                                }, function()
                                    ReplicatedStorage.Events.StartBossFight:FireServer("Enzo", bossDifficulty)
                                end)
                                if getgenv().NNVN_Notify then
                                    item:Notify({
                                        Title = "Auto Hop Enzo",
                                        Content = "Enzo available — fight started on " .. bossDifficulty .. ".",
                                        Duration = 3,
                                        Icon = "swords"
                                    })
                                end
                                task.wait(8)
                            else
                                if getgenv().NNVN_Notify then
                                    item:Notify({
                                        Title = "Auto Hop Enzo",
                                        Content = "Enzo on cooldown — hopping server...",
                                        Duration = 2,
                                        Icon = "server"
                                    })
                                end
                                if canAutoServerHop() then
                                    pcall(function()
                                        ServerHop:Teleport(placeId)
                                    end)
                                end
                                task.wait(15)
                            end
                        end)
                        if not ok and getgenv().NNVN_Notify then
                            item:Notify({
                                Title = "Auto Hop Enzo",
                                Content = "Loop error: " .. tostring(result),
                                Duration = 3
                            })
                        end
                        task.wait(1)
                    end
                end)
            else
                resolveAutoHopEnzo2()
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Auto Hop Enzo",
                        Content = "Stopped. Previous feature states restored.",
                        Duration = 3,
                        Icon = "square"
                    })
                end
            end
        end
    })
    task.spawn(function()
        while task.wait(10) do
            if item23 then
                local refreshPremiumAccessResult = refreshPremiumAccess()
                pcall(function()
                    if item23.SetLocked then
                        item23:SetLocked(not refreshPremiumAccessResult)
                    end
                end)
            end
        end
    end)
    local namelessOctoparasiteLabel = "Nameless Octoparasite"
    local nameList5 = { "A", "S", "D" }
    local aMap = { A = Enum.KeyCode.A, S = Enum.KeyCode.S, D = Enum.KeyCode.D }
    local delaySeconds3 = 0.22
    computedValue = 1.15 / 1.4
    local delaySeconds4 = 0.85
    local enabledMap = {
        Enabled = false,
        Band = 0.17,
        Lag = 0.03,
        Active = false,
        SignalUntil = 0,
        Config = nil,
        IsHard = false,
        Seen = setmetatable({}, { __mode = "k" }),
        LastPress = { A = 0, S = 0, D = 0 },
        PressBusy = { A = false, S = false, D = false },
        Stats = { hit = 0 }
    }
    rhyFindNameless = function()
        local stateMap = {}
        local ocean = Workspace:FindFirstChild("Ocean")
        if ocean then
            local boss = ocean:FindFirstChild("Boss")
            if boss then
                local fishName = boss:FindFirstChild("FishName")
                if fishName then
                    table.insert(stateMap, fishName)
                end
                table.insert(stateMap, boss)
            end
            table.insert(stateMap, ocean)
        end
        local fishes = Workspace:FindFirstChild("Fishes")
        if fishes then
            table.insert(stateMap, fishes)
        end
        for _, item in ipairs(stateMap) do
            local ok, result = pcall(function()
                return item:FindFirstChild(namelessOctoparasiteLabel, true)
            end)
            if ok and result then
                return result
            end
        end
        local item2
        pcall(function()
            if ocean then
                for _, item in ipairs(ocean:GetDescendants()) do
                    if (item:IsA("BasePart") or item:IsA("Model")) and item:GetAttribute("FishName") == namelessOctoparasiteLabel then
                        item2 = item
                        break
                    end
                end
            end
        end)
        return item2
    end
    rhyPivotOf = function(inputValue)
        if not inputValue then
            return nil
        end
        local ok, result = pcall(function()
            if inputValue:IsA("BasePart") then
                return inputValue.CFrame
            end
            if inputValue:IsA("Model") then
                if inputValue.PrimaryPart then
                    return inputValue.PrimaryPart.CFrame
                end
                return inputValue:GetPivot()
            end
            local basePart = inputValue:FindFirstChildWhichIsA("BasePart", true)
            if basePart then
                return basePart.CFrame
            end
            return nil
        end)
        if ok and result then
            return result
        end
        return nil
    end
    rhyTeleportToNameless = function()
        local rhyFindNamelessResult = rhyFindNameless()
        if not rhyFindNamelessResult then
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Nameless",
                    Content = "Cannot find " .. namelessOctoparasiteLabel .. " in Workspace (boss not spawned yet?)",
                    Duration = 3
                })
            end
            return false
        end
        local rhyPivotOfResult = rhyPivotOf(rhyFindNamelessResult)
        if not rhyPivotOfResult then
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Nameless",
                    Content = "Found boss but could not get its position!",
                    Duration = 3
                })
            end
            return false
        end
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") and not character.PrimaryPart then
            if getgenv().NNVN_Notify then
                item:Notify({ Title = "Nameless", Content = "Character not found!", Duration = 2 })
            end
            return false
        end
        NNVN_TweenTo(rhyPivotOfResult + Vector3.new(0, 12, 0))
        if getgenv().NNVN_Notify then
            item:Notify({
                Title = "Nameless",
                Content = "Teleported to " .. namelessOctoparasiteLabel,
                Duration = 2
            })
        end
        return true
    end
    rhyPress = function(inputValue, secondValue)
        if enabledMap.PressBusy[secondValue] then
            return false
        end
        local aEntry = aMap[secondValue]
        if not aEntry then
            return false
        end
        enabledMap.PressBusy[secondValue] = true
        if not pcall(function()
            game:GetService("VirtualInputManager"):SendKeyEvent(true, aEntry, false, game)
        end) then
            enabledMap.PressBusy[secondValue] = false
            return false
        end
        task.delay(0.025, function()
            pcall(function()
                game:GetService("VirtualInputManager"):SendKeyEvent(false, aEntry, false, game)
            end)
            enabledMap.PressBusy[secondValue] = false
        end)
        return true
    end
    rhyGui = function()
        local fishing = item3 and item3:FindFirstChild("Fishing")
        if not fishing then
            return nil, nil
        end
        return fishing:FindFirstChild("Rhythm"), fishing
    end
    rhyUiActive = function()
        local guiFrame, guiBar = rhyGui()
        if not guiFrame or not guiBar then
            return false
        end
        return guiFrame.Visible == true and guiBar.Visible == true
    end
    rhyMaxBand = function()
        local computedValue2 = delaySeconds3 - computedValue * (enabledMap.Lag or 0) - 0.02
        if computedValue2 < 0.01 then
            computedValue2 = 0.01
        end
        return computedValue2
    end
    rhyScan = function(inputValue)
        local rhyGuiResult = rhyGui()
        if not rhyGuiResult then
            return
        end
        for _, item in ipairs(nameList5) do
            local rhyGuiResultEntry = rhyGuiResult:FindFirstChild("Progression" .. item)
            if not rhyGuiResultEntry then
                continue
            end
            local delaySeconds42 = delaySeconds4
            local barFrame = rhyGuiResultEntry:FindFirstChild("BarFrame")
            if barFrame then
                local ok, result = pcall(function()
                    return barFrame.Position.Y.Scale
                end)
                if ok and type(result) == "number" then
                    delaySeconds42 = result
                end
            end
            local clampResult = math.clamp(enabledMap.Band, 0.01, rhyMaxBand())
            local item2
            local huge = math.huge
            for _, item3 in ipairs(rhyGuiResultEntry:GetChildren()) do
                if item3.Name == "Note_FX" and item3:IsA("GuiObject") and item3.Visible and not enabledMap.Seen[item3] then
                    local ok2, result2 = pcall(function()
                        return item3.Position.Y.Scale
                    end)
                    if ok2 and type(result2) == "number" then
                        local absResult = math.abs(result2 + computedValue * enabledMap.Lag - delaySeconds42)
                        if absResult <= clampResult and absResult < huge then
                            item2 = item3
                            huge = absResult
                        end
                    end
                end
            end
            if item2 and inputValue - (enabledMap.LastPress[item] or 0) >= 0.15 and rhyPress(rhyGuiResultEntry, item) then
                enabledMap.Seen[item2] = true
                enabledMap.LastPress[item] = inputValue
                enabledMap.Stats.hit = enabledMap.Stats.hit + 1
            end
        end
    end
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("Events")
        if not events then
            return
        end
        local rhythmStart = events:FindFirstChild("RhythmStart")
        if rhythmStart then
            if getgenv()._NNVN_RhyStart then
                pcall(function()
                    getgenv()._NNVN_RhyStart:Disconnect()
                end)
            end
            getgenv()._NNVN_RhyStart = rhythmStart.OnClientEvent:Connect(function(inputValue)
                enabledMap.Config = inputValue
                enabledMap.IsHard = type(inputValue) == "table" and tostring(inputValue.Mode):lower() == "hard"
                enabledMap.Active = not enabledMap.IsHard
                enabledMap.SignalUntil = tick() + 8
                enabledMap.Stats = { hit = 0 }
                enabledMap.Seen = setmetatable({}, { __mode = "k" })
                enabledMap.LastPress = { A = 0, S = 0, D = 0 }
                enabledMap.PressBusy = { A = false, S = false, D = false }
                if enabledMap.Enabled and not enabledMap.IsHard and getgenv().NNVN_Notify then
                    local finalMaxHp = inputValue and (inputValue.FinalMaxHP or inputValue.HPFinalPhase)
                    item:Notify({
                        Title = "Auto Nameless",
                        Content = "Rhythm started [Safe]" .. (finalMaxHp and " | HP " .. tostring(finalMaxHp) or ""),
                        Duration = 3
                    })
                end
            end)
        end
        local rhythmStop = events:FindFirstChild("RhythmStop")
        if rhythmStop then
            if getgenv()._NNVN_RhyStop then
                pcall(function()
                    getgenv()._NNVN_RhyStop:Disconnect()
                end)
            end
            getgenv()._NNVN_RhyStop = rhythmStop.OnClientEvent:Connect(function()
                enabledMap.Active = false
                enabledMap.IsHard = false
                enabledMap.SignalUntil = 0
            end)
        end
    end)
    if getgenv()._NNVN_RhyLoop then
        pcall(function()
            getgenv()._NNVN_RhyLoop:Disconnect()
        end)
    end
    local counter3 = 0
    getgenv()._NNVN_RhyLoop = RunService.Heartbeat:Connect(function(deltaTime)
        if not enabledMap.Enabled then
            return
        end
        if enabledMap.IsHard then
            return
        end
        local nowTime = tick()
        enabledMap.Active = rhyUiActive() or nowTime < (enabledMap.SignalUntil or 0)
        if not enabledMap.Active then
            return
        end
        if getgenv().NNVN_NamelessMinigameMode ~= "Safe" then
            return
        end
        counter3 = counter3 + deltaTime
        if counter3 < 1 / 10 then
            return
        end
        counter3 = 0
        rhyScan(nowTime)
    end)
    getgenv().NNVN_TeleportToNameless = rhyTeleportToNameless
    namelessBossSec = mainMap.Boss:AddSection({ Title = "Nameless Octoparasite", Icon = "bug" })
    namelessBossSec:AddButton({
        Title = "Teleport to Nameless Octoparasite",
        Icon = "map-pin",
        Callback = function()
            pcall(rhyTeleportToNameless)
        end
    })
    namelessBossSec:AddDropdown("NNVN_NamelessMinigameMode", {
        Title = "Minigame Mode",
        Values = { "Safe" },
        Default = "Safe",
        Callback = function(inputText)
            getgenv().NNVN_NamelessMinigameMode = inputText or "Safe"
        end
    })
    namelessBossSec:AddInput("NNVN_NamelessBand", {
        Title = "Safe Band (0.01 - 0.17)",
        Placeholder = "0.17",
        Default = "0.17",
        Callback = function(inputText)
            local parsedNum = tonumber(inputText)
            if parsedNum then
                enabledMap.Band = math.clamp(parsedNum, 0.01, rhyMaxBand())
                getgenv().NNVN_NamelessBand = enabledMap.Band
            else
                enabledMap.Band = 0.17
                getgenv().NNVN_NamelessBand = 0.17
            end
        end
    })
    namelessBossSec:AddToggle("NNVN_AutoNamelessMinigame", {
        Title = "Auto Minigame",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoNamelessMinigame = enabled
            enabledMap.Enabled = enabled
            enabledMap.Band = getgenv().NNVN_NamelessBand or 0.17
            enabledMap.Lag = getgenv().NNVN_NamelessLag or 0.03
            if enabled then
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Auto Nameless",
                        Content = "Enabled [Safe]. Waiting for RhythmStart from server.",
                        Duration = 3
                    })
                end
            else
                enabledMap.Active = false
                enabledMap.SignalUntil = 0
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Auto Nameless",
                        Content = "Disabled | hits " .. tostring(enabledMap.Stats.hit),
                        Duration = 3
                    })
                end
            end
        end
    })
    namelessBossSec:AddToggle("ESP_Nameless", {
        Title = "Nameless Octoparasite ESP",
        Description = "Highlights the Nameless Octoparasite when it is spawned.",
        Default = getgenv().NNVN_ESP and getgenv().NNVN_ESP.Nameless or false,
        Callback = function(selectedValue)
            getgenv().NNVN_ESP = getgenv().NNVN_ESP or {}
            getgenv().NNVN_ESP.Nameless = selectedValue
            if selectedValue then
                task.defer(function()
                    if type(applyESP_Nameless) == "function" then
                        pcall(applyESP_Nameless)
                    end
                end)
            elseif type(clearESP) == "function" then
                clearESP("Nameless")
            end
        end
    })
    local blackTortoiseBloodlineLabel = "Black Tortoise Bloodline"
    local enabledMap2 = {
        enabled = false,
        active = false,
        seen = setmetatable({}, { __mode = "k" }),
        lastPress = { A = 0, S = 0, D = 0 },
        pressBusy = { A = false, S = false, D = false },
        connections = {},
        generation = 0,
        hits = 0,
        badSkipped = 0,
        errorStreak = 0
    }
    blackFindBoss = function()
        local blackTortoiseInstance = getgenv().NNVN_BlackTortoiseInstance
        if blackTortoiseInstance and blackTortoiseInstance.Parent and (blackTortoiseInstance:IsA("Model") or blackTortoiseInstance:IsA("BasePart")) then
            return blackTortoiseInstance
        end
        local ocean = Workspace:FindFirstChild("Ocean")
        local lookupMap = {}
        local worldBoss = Workspace:FindFirstChild("WorldBoss")
        local boss = Workspace:FindFirstChild("Boss")
        local boss2 = ocean and ocean:FindFirstChild("Boss")
        if worldBoss then
            lookupMap[#lookupMap + 1] = worldBoss
        end
        if boss then
            lookupMap[#lookupMap + 1] = boss
        end
        if boss2 then
            lookupMap[#lookupMap + 1] = boss2
        end
        for _, item in ipairs(lookupMap) do
            if (item:IsA("Model") or item:IsA("BasePart")) and (item.Name == blackTortoiseBloodlineLabel or item:GetAttribute("FishName") == blackTortoiseBloodlineLabel) then
                return item
            end
            for _, item2 in ipairs(item:GetDescendants()) do
                if (item2:IsA("Model") or item2:IsA("BasePart")) and (item2.Name == blackTortoiseBloodlineLabel or item2:GetAttribute("FishName") == blackTortoiseBloodlineLabel) then
                    return item2
                end
            end
        end
        return nil
    end
    local function resolveCharacter()
        local blackFindBossResult = blackFindBoss()
        local rhyPivotOfResult = blackFindBossResult and rhyPivotOf(blackFindBossResult)
        local character = LocalPlayer.Character
        local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
        if not rhyPivotOfResult or not rootPart then
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = blackTortoiseBloodlineLabel,
                    Content = blackFindBossResult and "Character unavailable" or "Boss has not spawned",
                    Duration = 3
                })
            end
            return false
        end
        NNVN_TweenTo(rhyPivotOfResult + Vector3.new(0, 12, 0))
        return true
    end
    local function resolveBackgroundColor3(inputValue)
        local backgroundColor3 = inputValue.BackgroundColor3
        return backgroundColor3.R > 0.65 and backgroundColor3.G * 1.5 < backgroundColor3.R and backgroundColor3.B * 1.5 < backgroundColor3.R
    end
    local function resolvePressBusy(inputValue)
        if enabledMap2.pressBusy[inputValue] then
            return false
        end
        local aEntry = aMap[inputValue]
        if not aEntry then
            return false
        end
        enabledMap2.pressBusy[inputValue] = true
        local callOk = pcall(function()
            game:GetService("VirtualInputManager"):SendKeyEvent(true, aEntry, false, game)
        end)
        if not callOk then
            enabledMap2.pressBusy[inputValue] = false
            return false
        end
        task.delay(0.025, function()
            pcall(function()
                game:GetService("VirtualInputManager"):SendKeyEvent(false, aEntry, false, game)
            end)
            enabledMap2.pressBusy[inputValue] = false
        end)
        return callOk
    end
    local function resolveName(inputValue, secondValue, thirdValue, instance, fifthValue)
        if not instance or instance.Name ~= "Note_FX" or not instance:IsA("GuiObject") then
            return
        end
        if enabledMap2.seen[instance] then
            return
        end
        enabledMap2.seen[instance] = true
        if resolveBackgroundColor3(instance) then
            enabledMap2.badSkipped = enabledMap2.badSkipped + 1
            return
        end
        local ok, result = pcall(function()
            return instance.Position.Y.Scale
        end)
        local ok2, result2 = pcall(function()
            return secondValue.Position.Y.Scale
        end)
        if not ok or not ok2 or type(result) ~= "number" or type(result2) ~= "number" then
            return
        end
        local clampResult = math.clamp((result2 - math.min(0.04, math.clamp(tonumber(getgenv().NNVN_BlackTortoiseBand) or 0.12, 0.03, 0.17) * 0.35) - result) / computedValue, 0, 2)
        local function resolveGeneration(inputValue2)
            if fifthValue ~= enabledMap2.generation or not enabledMap2.active or not enabledMap2.enabled then
                return
            end
            if instance.Parent ~= inputValue or not instance.Visible or not inputValue.Parent then
                return
            end
            if result2 + delaySeconds3 < instance.Position.Y.Scale then
                return
            end
            local item
            local huge = math.huge
            for _, item2 in ipairs(inputValue:GetChildren()) do
                if item2.Name ~= "Note_FX" or not item2:IsA("GuiObject") or not item2.Visible then
                    continue
                end
                local absResult = math.abs(item2.Position.Y.Scale - result2)
                if absResult <= delaySeconds3 and absResult < huge then
                    item = item2
                    huge = absResult
                end
            end
            if item == instance and not resolveBackgroundColor3(item) then
                local nowTime = os.clock()
                if nowTime - (enabledMap2.lastPress[thirdValue] or 0) >= 0.12 and resolvePressBusy(thirdValue) then
                    enabledMap2.lastPress[thirdValue] = nowTime
                    enabledMap2.hits = enabledMap2.hits + 1
                end
            elseif inputValue2 > 0 then
                task.delay(0.04, resolveGeneration, inputValue2 - 1)
            end
        end
        task.delay(clampResult, resolveGeneration, 5)
    end
    local function resolveActive()
        enabledMap2.active = false
        enabledMap2.generation = enabledMap2.generation + 1
        enabledMap2.seen = setmetatable({}, { __mode = "k" })
        enabledMap2.pressBusy = { A = false, S = false, D = false }
        for _, item in ipairs(enabledMap2.connections) do
            pcall(function()
                item:Disconnect()
            end)
        end
        table.clear(enabledMap2.connections)
        if getgenv()._NNVN_BlackRhythmLoop then
            pcall(function()
                getgenv()._NNVN_BlackRhythmLoop:Disconnect()
            end)
            getgenv()._NNVN_BlackRhythmLoop = nil
        end
    end
    local function resolveMode(inputValue)
        resolveActive()
        local isMatched = type(inputValue) == "table" and tostring(inputValue.Mode):lower() == "hard"
        if isMatched then
            enabledMap.IsHard = true
        end
        if not enabledMap2.enabled or not isMatched then
            return
        end
        enabledMap2.active = true
        enabledMap2.hits = 0
        enabledMap2.badSkipped = 0
        enabledMap2.errorStreak = 0
        local generation = enabledMap2.generation
        task.defer(function()
            if generation ~= enabledMap2.generation or not enabledMap2.active then
                return
            end
            local rhyGuiResult = rhyGui()
            if not rhyGuiResult then
                return
            end
            for _, item in ipairs(nameList5) do
                local rhyGuiResultEntry = rhyGuiResult:FindFirstChild("Progression" .. item)
                local barFrame = rhyGuiResultEntry and rhyGuiResultEntry:FindFirstChild("BarFrame")
                if rhyGuiResultEntry and barFrame then
                    table.insert(enabledMap2.connections, rhyGuiResultEntry.ChildAdded:Connect(function(child)
                        local ok, result = pcall(resolveName, rhyGuiResultEntry, barFrame, item, child, generation)
                        if not ok then
                            getgenv().NNVN_BlackTortoiseMinigameError = tostring(result)
                        end
                    end))
                    for _, item2 in ipairs(rhyGuiResultEntry:GetChildren()) do
                        pcall(resolveName, rhyGuiResultEntry, barFrame, item, item2, generation)
                    end
                end
            end
        end)
    end
    events = ReplicatedStorage:FindFirstChild("Events")
    local rhythmStart = events and events:FindFirstChild("RhythmStart")
    local rhythmStop = events and events:FindFirstChild("RhythmStop")
    if getgenv()._NNVN_BlackRhythmStart then
        getgenv()._NNVN_BlackRhythmStart:Disconnect()
    end
    if getgenv()._NNVN_BlackRhythmStop then
        getgenv()._NNVN_BlackRhythmStop:Disconnect()
    end
    if getgenv()._NNVN_BlackRhythmLoop then
        getgenv()._NNVN_BlackRhythmLoop:Disconnect()
    end
    if rhythmStart then
        getgenv()._NNVN_BlackRhythmStart = rhythmStart.OnClientEvent:Connect(resolveMode)
    end
    if rhythmStop then
        getgenv()._NNVN_BlackRhythmStop = rhythmStop.OnClientEvent:Connect(resolveActive)
    end
    getgenv().NNVN_TeleportToBlackTortoise = resolveCharacter
    local section2 = mainMap.Boss:AddSection({ Title = blackTortoiseBloodlineLabel, Icon = "shield" })
    section2:AddButton({
        Title = "Teleport to Boss",
        Icon = "map-pin",
        Callback = function()
            pcall(resolveCharacter)
        end
    })
    getgenv().NNVN_BlackTortoiseTrackerStatus = section2:AddParagraph({ Title = "Spawn Tracker", Desc = "Checking this server..." })
    section2:AddDropdown("NNVN_BlackTortoiseMinigameMode", {
        Title = "Minigame Mode",
        Values = { "Safe (avoid Bad)" },
        Default = "Safe (avoid Bad)",
        Callback = function() end
    })
    section2:AddInput("NNVN_BlackTortoiseBand", {
        Title = "Safe Band (0.03 - 0.17)",
        Placeholder = "0.12",
        Default = tostring(getgenv().NNVN_BlackTortoiseBand),
        Callback = function(enabled)
            local parsedNum = tonumber(enabled)
            if parsedNum then
                getgenv().NNVN_BlackTortoiseBand = math.clamp(parsedNum, 0.03, 0.17)
            end
        end
    })
    section2:AddToggle("NNVN_AutoBlackTortoiseMinigame", {
        Title = "Auto Minigame (avoid Bad)",
        Default = false,
        Callback = function(enabled)
            enabledMap2.enabled = enabled == true
            getgenv().NNVN_AutoBlackTortoiseMinigame = enabledMap2.enabled
            if not enabledMap2.enabled then
                resolveActive()
            end
        end
    })
    section2:AddToggle("ESP_BlackTortoise", {
        Title = "Boss ESP",
        Default = getgenv().NNVN_ESP and getgenv().NNVN_ESP.BlackTortoise or false,
        Callback = function(selectedValue)
            getgenv().NNVN_ESP = getgenv().NNVN_ESP or {}
            getgenv().NNVN_ESP.BlackTortoise = selectedValue == true
            if selectedValue then
                task.defer(function()
                    if type(applyESP_BlackTortoise) == "function" then
                        pcall(applyESP_BlackTortoise)
                    end
                end)
            elseif type(clearESP) == "function" then
                clearESP("BlackTortoise")
            end
        end
    })
    vermilionNameMatches = function(inputValue)
        local formattedText = string.lower(tostring(inputValue or "")):gsub("[_%-]+", " "):gsub("%s+", " ")
        return formattedText:find("vermilion birdblood", 1, true) ~= nil or formattedText:find("vermillion birdblood", 1, true) ~= nil
    end
    vermilionObjectMatches = function(instance)
        if not instance then
            return false
        end
        if vermilionNameMatches(instance.Name) or vermilionNameMatches(instance:GetAttribute("FishName")) then
            return true
        end
        local fishName = instance:FindFirstChild("FishName")
        return fishName and fishName:IsA("StringValue") and vermilionNameMatches(fishName.Value) or false
    end
    vermilionFindBoss = function()
        local vermilionInstance = getgenv().NNVN_VermilionInstance
        if vermilionInstance and vermilionInstance.Parent and vermilionObjectMatches(vermilionInstance) then
            return vermilionInstance
        end
        local ocean = Workspace:FindFirstChild("Ocean")
        for _, item in ipairs({
            Workspace:FindFirstChild("WorldBoss"),
            Workspace:FindFirstChild("Boss"),
            ocean and ocean:FindFirstChild("Boss")
        }) do
            if not item then
                continue
            end
            if vermilionObjectMatches(item) then
                return item
            end
            for _, item2 in ipairs(item:GetDescendants()) do
                if vermilionObjectMatches(item2) then
                    return item2
                end
            end
        end
        local fishes = Workspace:FindFirstChild("Fishes")
        if fishes then
            for _, item3 in ipairs(fishes:GetChildren()) do
                if vermilionObjectMatches(item3) then
                    return item3
                end
            end
        end
        return nil
    end
    vermilionTeleport = function()
        local vermilionFindBossResult = vermilionFindBoss()
        local rhyPivotOfResult = vermilionFindBossResult and rhyPivotOf(vermilionFindBossResult)
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rhyPivotOfResult or not rootPart then
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Vermilion Birdblood",
                    Content = vermilionFindBossResult and "Live encounter found, but no world model is available." or "Boss has not spawned.",
                    Duration = 3
                })
            end
            return false
        end
        NNVN_TweenTo(rhyPivotOfResult + Vector3.new(0, 12, 0))
        return true
    end
    if getgenv().NNVN_NotifyVermilionSpawn == nil then
        getgenv().NNVN_NotifyVermilionSpawn = true
    end
    vermilionBossSec = mainMap.Boss:AddSection({ Title = "Vermilion Birdblood", Icon = "flame" })
    getgenv().NNVN_VermilionBossStatus = vermilionBossSec:AddParagraph({
        Title = "Spawn Tracker",
        Desc = vermilionFindBoss() and "Detected in this server" or "Not detected in this server"
    })
    vermilionBossSec:AddButton({
        Title = "Teleport to Boss",
        Icon = "map-pin",
        Callback = function()
            pcall(vermilionTeleport)
        end
    })
    vermilionBossSec:AddToggle("ESP_Vermilion", {
        Title = "Boss ESP",
        Default = getgenv().NNVN_ESP and getgenv().NNVN_ESP.Vermilion or false,
        Callback = function(enabled)
            getgenv().NNVN_ESP = getgenv().NNVN_ESP or {}
            getgenv().NNVN_ESP.Vermilion = enabled == true
            if enabled and type(applyESP_Vermilion) == "function" then
                pcall(applyESP_Vermilion)
            elseif not enabled and type(clearESP) == "function" then
                clearESP("Vermilion")
            end
        end
    })
    vermilionBossSec:AddToggle("NNVN_NotifyVermilionSpawn", {
        Title = "Notify on Spawn",
        Default = getgenv().NNVN_NotifyVermilionSpawn == true,
        Callback = function(selectedValue)
            getgenv().NNVN_NotifyVermilionSpawn = selectedValue == true
        end
    })
end

do
    tickSec = mainMap.Quest:AddSection({ Title = "Auto Ticket Quest", Icon = "ticket" })
    tickSec:AddParagraph({
        Title = "NPC interaction",
        Content = "Uses Farm Movement for both the fishing spot and NPC before sending remotes."
    })
    local item24
    local item25
    local function resolveTicketHardLocation2()
        local isMatched = getgenv().NNVN_TicketHardLocation ~= "Ground"
        if item24 and item24.SetVisible then
            item24:SetVisible(true)
        end
        if item25 and item25.SetVisible then
            item25:SetVisible(isMatched)
        end
    end
    tickSec:AddDropdown("TicketDifficulty", {
        Title = "Difficulty",
        Values = { "Easy", "Hard" },
        Default = getgenv().NNVN_TicketDifficulty or "Easy",
        Callback = function(selected)
            selected = NormalizeTranslatedChoice(selected, "Easy")
            getgenv().NNVN_TicketDifficulty = selected == "Hard" and "Hard" or "Easy"
            if getgenv().NNVN_TicketDifficulty ~= "Hard" then
                cleanupResource(false)
            end
            resolveTicketHardLocation2()
            if getgenv().NNVN_AutoTicket and getgenv().NNVN_TeleportToFishSpot then
                pcall(function()
                    getgenv().NNVN_TeleportToFishSpot(getgenv().NNVN_TicketDifficulty)
                end)
            end
        end
    })
    item24 = tickSec:AddDropdown("NNVN_TicketHardLocation", {
        Title = "Farm Location",
        Description = "Choose Sky or the original ground position for Easy and Hard.",
        Values = { "Sky", "Ground" },
        Default = getgenv().NNVN_TicketHardLocation or "Sky",
        Visible = true,
        Callback = function(enabled)
            enabled = NormalizeTranslatedChoice(enabled, "Sky")
            getgenv().NNVN_TicketHardLocation = enabled == "Ground" and "Ground" or "Sky"
            if getgenv().NNVN_TicketHardLocation == "Sky" then
                resolveRandom(getgenv().NNVN_TicketRandomSkyHeight == true)
            else
                cleanupResource(false)
            end
            resolveTicketHardLocation2()
            if getgenv().NNVN_AutoTicket then
                pcall(function()
                    getgenv().NNVN_TeleportToFishSpot(getgenv().NNVN_TicketDifficulty)
                end)
            end
        end
    })
    item25 = tickSec:AddToggle("NNVN_TicketRandomSkyHeight", {
        Title = "Random Sky Height",
        Description = "Uses a moderate random height while keeping X/Z and facing unchanged.",
        Default = getgenv().NNVN_TicketRandomSkyHeight == true,
        Visible = getgenv().NNVN_TicketHardLocation ~= "Ground",
        Callback = function(selectedValue)
            getgenv().NNVN_TicketRandomSkyHeight = selectedValue == true
            resolveRandom(selectedValue == true)
            if getgenv().NNVN_AutoTicket and getgenv().NNVN_TicketHardLocation ~= "Ground" then
                pcall(function()
                    getgenv().NNVN_TeleportToFishSpot(getgenv().NNVN_TicketDifficulty)
                end)
            end
        end
    })
    resolveTicketHardLocation2()
    tickSec:AddDropdown("NNVN_TicketFarmMode", {
        Title = "Farm Movement",
        Description = "Uses the global Operation Method. Ticket Instant is treated as direct Teleport.",
        Values = { "Teleport [Risk]", "Tween [Safe]" },
        Default = GetActionMethod() == "Tween" and "Tween [Safe]" or "Teleport [Risk]",
        Callback = function(selected)
            selected = NormalizeTranslatedChoice(selected, "Tween [Safe]")
            local teleportRiskLabel = tostring(selected):find("Teleport", 1, true) and "Teleport [Risk]" or "Tween [Safe]"
            getgenv().NNVN_TicketFarmMode = teleportRiskLabel
            getgenv().NNVN_ActionMethod = teleportRiskLabel
            if getgenv().NNVN_AutoTicket and getgenv().NNVN_TeleportToFishSpot then
                pcall(function()
                    getgenv().NNVN_TeleportToFishSpot(getgenv().NNVN_TicketDifficulty or "Easy")
                end)
            end
        end
    })
    tickSec:AddDropdown("NNVN_QuestCustomIsland", {
        Title = "Custom Island - Leave Empty To Ignore",
        Values = {
            "No Selection",
            "Beginning Isle",
            "Bamboo Isle",
            "Fallout Isle",
            "Sovereign Isle",
            "Perch Isle",
            "Frost Isle",
            "Coconut Isle",
            "Amber Isle",
            "Battlefield Isle",
            "Mistpeak Isle",
            "World Angler Isle",
            "Weather Isle",
            "Mystic Reef Isle"
        },
        Default = "No Selection",
        Callback = function(amount)
            getgenv().NNVN_QuestCustomIsland = amount or "No Selection"
            if getgenv().NNVN_AutoTicket and getgenv().NNVN_TeleportToFishSpot then
                local ticketDifficulty = getgenv().NNVN_TicketDifficulty or "Easy"
                pcall(function()
                    getgenv().NNVN_TeleportToFishSpot(ticketDifficulty)
                end)
            end
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Quest Island",
                    Content = amount == "No Selection" and "Using built-in Easy/Hard CFrame." or "Farming on: " .. tostring(amount),
                    Duration = 3,
                    Icon = "map-pin"
                })
            end
        end
    })
    tickSec:AddSlider("TicketAcceptDelay", {
        Title = "Delay retry accept quest (seconds)",
        Default = math.max(1, tonumber(getgenv().NNVN_TicketAcceptDelay) or 2),
        Min = 1,
        Max = 20,
        Rounding = 1,
        AllowRightClickInput = true,
        Callback = function(inputText)
            getgenv().NNVN_TicketAcceptDelay = math.max(1, tonumber(inputText) or 2)
        end
    })
    tickSec:AddInput("TicketAcceptDelayInput", {
        Title = "Quest Retry Delay Input",
        Placeholder = "Seconds (1 - 20)",
        Default = tostring(math.max(1, tonumber(getgenv().NNVN_TicketAcceptDelay) or 2)),
        Numeric = true,
        Finished = true,
        Callback = function(enabled)
            local clampResult = math.clamp(math.floor(tonumber(enabled) or 2), 1, 20)
            getgenv().NNVN_TicketAcceptDelay = clampResult
            local ticketAcceptDelay = stateMap2 and stateMap2.TicketAcceptDelay
            if ticketAcceptDelay and ticketAcceptDelay.SetValue then
                pcall(function()
                    ticketAcceptDelay:SetValue(clampResult)
                end)
            end
        end
    })
    tickSec:AddToggle("NNVN_TicketFishWhileWaiting", {
        Title = "Fish While Waiting",
        Description = "Returns to the saved starting position during long cooldowns or the daily 20/20 limit. At 2 minutes or less, waits beside the NPC.",
        Default = getgenv().NNVN_TicketFishWhileWaiting == true,
        Callback = function(enabled)
            getgenv().NNVN_TicketFishWhileWaiting = enabled == true
            getgenv()._NNVN_TicketWaitState = nil
            if not enabled and getgenv().NNVN_AutoTicket and not getActiveTicketDifficulty(getgenv().NNVN_TicketDifficulty) then
                task.spawn(moveToTicketNpcOnly)
            end
        end
    })
    tickSec:AddToggle("StartAutoTicket", {
        Title = "Start Auto Ticket Quest",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoTicket = enabled
            if enabled then
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                getgenv().NNVN_TicketOriginalCFrame = rootPart and rootPart.CFrame or getgenv().NNVN_TicketOriginalCFrame
                getgenv().NNVN_TicketDailyLimitReached = false
                getgenv()._NNVN_TicketWaitState = nil
                local hardLabel = getgenv().NNVN_TicketDifficulty == "Hard" and "Hard" or "Easy"
                local hardLabel2 = hardLabel
                if isTicketSkyMode(hardLabel2) then
                    resolveRandom(getgenv().NNVN_TicketRandomSkyHeight == true)
                end
                if getgenv().NNVN_SaveTicketFlags then
                    getgenv().NNVN_SaveTicketFlags()
                end
                getgenv().NNVN_Anchor = false
                getgenv().NNVN_AutoCast = false
                getgenv().NNVN_AutoSkill = false
                local hasTriggered = false
                if getActiveTicketDifficulty(hardLabel) then
                    hasTriggered = enableTicketFarmAfterArrival(hardLabel2)
                elseif getTicketCooldownSeconds() > 0 then
                    handleTicketWaitingState()
                    hasTriggered = getgenv().NNVN_TicketFishWhileWaiting == true
                elseif acceptTicketQuest(hardLabel) then
                    hasTriggered = enableTicketFarmAfterArrival(hardLabel2)
                end
                if not hasTriggered then
                    notify("Ticket Quest", "Waiting to reach the farm position before enabling fishing functions.", 4)
                end
                if getgenv().NNVN_StartTicketLoop then
                    getgenv().NNVN_StartTicketLoop()
                end
            else
                getgenv()._NNVN_TicketWaitState = nil
                cleanupResource(false)
                if type(NNVN_StopTween) == "function" then
                    pcall(NNVN_StopTween)
                end
                if getgenv().NNVN_TicketCoroutine then
                    pcall(coroutine.close, getgenv().NNVN_TicketCoroutine)
                    getgenv().NNVN_TicketCoroutine = nil
                end
                if getgenv().NNVN_RestoreTicketFlags then
                    getgenv().NNVN_RestoreTicketFlags()
                end
                getgenv().NNVN_AutoUseBait = false
                getgenv().NNVN_AutoBoss = false
                getgenv().NNVN_AutoFarmSecretBoss = false
                getgenv().NNVN_AutoBossFishing = false
            end
        end
    })
    tickSec:AddToggle("AutoAcceptQuest", {
        Title = "Auto Accept Quest (when inactive)",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoAcceptQuest = enabled
        end
    })
    TurnInCo = nil
    tickSec:AddToggle("AutoTurnInQuest", {
        Title = "Auto Turn In Quest (every 10s)",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoTurnIn = enabled
            if enabled then
                if TurnInCo then
                    coroutine.close(TurnInCo)
                    TurnInCo = nil
                end
                TurnInCo = coroutine.create(function()
                    while getgenv().NNVN_AutoTurnIn do
                        pcall(function()
                            local ticketDifficulty = getgenv().NNVN_TicketDifficulty or "Easy"
                            if getgenv().NNVN_TurnInTicketQuest then
                                getgenv().NNVN_TurnInTicketQuest(ticketDifficulty)
                            end
                            if getgenv().NNVN_ClickLeaveButton then
                                getgenv().NNVN_ClickLeaveButton()
                            end
                        end)
                        for i = 1, 10 do
                            if not getgenv().NNVN_AutoTurnIn then
                                break
                            end
                            task.wait(1)
                        end
                    end
                end)
                coroutine.resume(TurnInCo)
            elseif TurnInCo then
                coroutine.close(TurnInCo)
                TurnInCo = nil
            end
        end
    })
    manSec = mainMap.Quest:AddSection({ Title = "Manual Turn In", Icon = "hand" })
    manSec:AddButton({
        Title = "Turn In Easy Quest",
        Callback = function()
            if getgenv().NNVN_TurnInTicketQuest then
                getgenv().NNVN_TurnInTicketQuest("Easy")
            end
            if getgenv().NNVN_ClickLeaveButton then
                getgenv().NNVN_ClickLeaveButton()
            end
        end
    })
    manSec:AddButton({
        Title = "Turn In Hard Quest",
        Callback = function()
            if getgenv().NNVN_TurnInTicketQuest then
                getgenv().NNVN_TurnInTicketQuest("Hard")
            end
            if getgenv().NNVN_ClickLeaveButton then
                getgenv().NNVN_ClickLeaveButton()
            end
        end
    })
    dumpGuySec = mainMap.Quest:AddSection({ Title = "Dump Guy", Icon = "fish" })
    dumpGuySec:AddParagraph({
        Title = "Give fish at least 2,000,000 kg",
        Content = "Uses eligible fish already in the selected slot, or moves a fish of at least 2M kg from inventory. Existing slot items return to inventory when a replacement is available. Default: slot 4."
    })
    dumpGuySec:AddSlider("NNVN_DumpGuyHotbarSlot", {
        Title = "Hotbar slot for fish",
        Default = getgenv().NNVN_DumpGuyHotbarSlot or 4,
        Min = 1,
        Max = 10,
        Rounding = 1,
        Callback = function(selectedValue)
            getgenv().NNVN_DumpGuyHotbarSlot = math.clamp(math.floor(tonumber(selectedValue) or 4), 1, 10)
        end
    })
    dumpGuySec:AddButton({
        Title = "Give 1 Fish >= 2M kg",
        Icon = "send",
        Callback = function()
            local primaryValue, secondaryValue = giveFishToDumpGuy()
            item:Notify({
                Title = "Dump Guy",
                Content = primaryValue and "Fish removed from hotbar: " .. tostring(secondaryValue) or tostring(secondaryValue or "Could not give fish."),
                Duration = 4,
                Icon = primaryValue and "check" or "circle-alert"
            })
        end
    })
    dumpGuySec:AddButton({
        Title = "Teleport to Dump Guy",
        Icon = "map-pin",
        Callback = function()
            local teleportToDumpGuy = TeleportToDumpGuyExact()
            item:Notify({
                Title = "Dump Guy",
                Content = teleportToDumpGuy and "Teleported to Dump Guy." or "Dump Guy NPC was not found.",
                Duration = 3,
                Icon = teleportToDumpGuy and "check" or "circle-alert"
            })
        end
    })
    dumpGuySec:AddToggle("NNVN_AutoGiveFish", {
        Title = "Auto Give Fish >= 2M kg",
        Default = false,
        Callback = function(enabled)
            setAutoGiveFishEnabled(enabled)
        end
    })
    dumpGuySec:AddToggle("NNVN_AutoFarm2MFish", {
        Title = "Auto Farm 2M+ kg Fish",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoFarm2MFish = enabled
            setAutoFarm2MFish(enabled)
        end
    })
    dailySec = mainMap.Quest:AddSection({ Title = "Auto Claim Daily Reward", Icon = "calendar-check" })
    dailyCo = nil
    dailySec:AddToggle("AutoClaimDaily", {
        Title = "Auto Claim Daily Reward (1-7)",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoClaimDaily = enabled
            if enabled then
                if dailyCo then
                    coroutine.close(dailyCo)
                    dailyCo = nil
                end
                dailyCo = coroutine.create(function()
                    while getgenv().NNVN_AutoClaimDaily do
                        pcall(function()
                            RunActionWithMethod({ teleport = TPNearDailyNPC, returnAfter = true }, function()
                                for i = 1, 7 do
                                    if not getgenv().NNVN_AutoClaimDaily then
                                        break
                                    end
                                    ReplicatedStorage.Events.DailyReward:FireServer(i)
                                    task.wait(getgenv().NNVN_ClaimDailyDelay or 1)
                                end
                            end)
                        end)
                        task.wait(5)
                    end
                end)
                coroutine.resume(dailyCo)
            elseif dailyCo then
                coroutine.close(dailyCo)
                dailyCo = nil
            end
        end
    })
    dailySec:AddSlider("ClaimDailyDelay", {
        Title = "Delay between claims (seconds)",
        Default = 1,
        Min = 0.5,
        Max = 5,
        Rounding = 0.5,
        Callback = function(selectedValue)
            getgenv().NNVN_ClaimDailyDelay = selectedValue
        end
    })
    dailyQuestSec = mainMap.Quest:AddSection({ Title = "Daily Quests (Auto)", Icon = "list-checks" })
    dailyQuestSec:AddParagraph({
        Title = "Quest types detected",
        Content = "Fishing | BossQuest | Bait | PlayTime\nBoss ticket objectives are skipped and notified."
    })
    dailyQuestSec:AddButton({
        Title = "Claim All Daily Quest Rewards",
        Callback = function()
            task.spawn(function()
                pcall(function()
                    RunActionWithMethod({ teleport = TPNearDailyNPC, returnAfter = true }, function()
                        local data = ReplicatedStorage:FindFirstChild("Data")
                        local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
                        local daily = playerData and playerData:FindFirstChild("Quest") and playerData.Quest:FindFirstChild("Daily")
                        if not daily then
                            if getgenv().NNVN_Notify then
                                item:Notify({ Title = "", Content = "No daily quests found", Duration = 2 })
                            end
                            return
                        end
                        local counter = 0
                        for _, item2 in ipairs(daily:GetChildren()) do
                            pcall(function()
                                ReplicatedStorage.Events.DailyReward:FireServer(tonumber(item2.Name))
                                counter = counter + 1
                            end)
                            task.wait(0.3)
                        end
                        if getgenv().NNVN_Notify then
                            item:Notify({
                                Title = "",
                                Content = "Sent " .. counter .. " daily reward claims!",
                                Duration = 3
                            })
                        end
                    end)
                end)
            end)
        end
    })
    local zengTianguoQuestPerch = {
        ["Zeng Tianguo Quest - Perch Isle"] = {
            questName = "Zeng Tianguo Quest",
            island = "Perch Isle",
            objectiveType = "FishAtZoneForTimesBoss",
            cframe = CFrame.new(163.3638, 22.5489426, -1667.12549, 0.983254969, -3.53700691e-09, -0.182235256, 4.94177976e-10, 1, -1.67426659e-08, 0.182235256, 1.63722529e-08, 0.983254969)
        },
        ["Frost Isle Quest - Frost Isle"] = {
            questName = "Frost Isle Quest",
            island = "Frost Isle",
            objectiveType = "FishAtZoneForTimes",
            cframe = CFrame.new(-1127.12732, 13.5423517, -1541.1759, 0.104531832, -4.09007654e-08, -0.994521558, -2.8796185e-08, 1, -4.41527703e-08, 0.994521558, 3.32537944e-08, 0.104531832)
        },
        ["Perch Isle Quest - Perch Isle"] = {
            questName = "Perch Isle Quest",
            fishNames = { "Ascended Perch", "Trueform Perch" },
            objectiveType = "FishingSpecific",
            cframe = CFrame.new(163.3638, 22.5489426, -1667.12549, 0.983254969, -3.53700691e-09, -0.182235256, 4.94177976e-10, 1, -1.67426659e-08, 0.182235256, 1.63722529e-08, 0.983254969)
        },
        ["Orb Claw - Sovereign Isle"] = {
            questName = "Claw Orb quest",
            fishNames = { "Trueform Jiaolongfish" },
            objectiveType = "FishingSpecific",
            useOperationMethod = true,
            cframe = CFrame.new(-1625.88428, 11.5350533, 1622.09692, 0.224939391, 2.13587512e-08, 0.974372745, -1.33935529e-08, 1, -1.8828537e-08, -0.974372745, -8.81503315e-09, 0.224939391)
        }
    }
    getgenv().NNVN_QuestFarmSession = (getgenv().NNVN_QuestFarmSession or 0) + 1
    local previousMap = { previous = nil, lastTeleport = 0 }
    local function resolveFindFirstChild3(inputValue)
        local data = ReplicatedStorage:FindFirstChild("Data")
        local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
        local main = playerData and playerData:FindFirstChild("Quest") and playerData.Quest:FindFirstChild("Main")
        local mainEntry = main and main:FindFirstChild(inputValue.questName)
        local objective = mainEntry and mainEntry:FindFirstChild("Objective")
        local stateMap = {}
        if objective then
            for _, item in ipairs(objective:GetChildren()) do
                if not item:IsA("StringValue") then
                    continue
                end
                table.insert(stateMap, {
                    text = tostring(item.Value),
                    progress = mainEntry:FindFirstChild(item.Name)
                })
            end
        end
        return mainEntry, stateMap
    end
    local function resolveInactive(inputValue)
        local primaryValue, secondaryValue = resolveFindFirstChild3(inputValue)
        if not primaryValue then
            return "inactive"
        end
        local counter = 0
        local hasTriggered = false
        for _, item in ipairs(secondaryValue) do
            local text = item.text
            local isMatched = text:find(inputValue.objectiveType, 1, true) ~= nil
            if isMatched and inputValue.island then
                isMatched = text:find(inputValue.island, 1, true) ~= nil
            end
            if isMatched and inputValue.fishNames then
                isMatched = false
                for _, item2 in ipairs(inputValue.fishNames) do
                    if text:find(item2, 1, true) then
                        isMatched = true
                        break
                    end
                end
            end
            if not isMatched then
                continue
            end
            counter = counter + 1
            local parsedNum = tonumber(text:match(",(%d+),"))
            local progress = item.progress
            if not parsedNum or not progress or not tonumber(progress.Value) or parsedNum > progress.Value then
                hasTriggered = true
            end
        end
        if counter == 0 then
            return "inactive"
        end
        return hasTriggered and "active" or "complete"
    end
    local function resolvePrevious()
        local previous = previousMap.previous
        if not previous then
            return
        end
        getgenv().NNVN_Anchor = previous.Anchor
        getgenv().NNVN_AutoCast = previous.AutoCast
        getgenv().NNVN_AutoSkill = previous.AutoSkill
        previousMap.previous = nil
    end
    local function resolveCharacter2(inputValue)
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            return false
        end
        local computedValue = inputValue.cframe + Vector3.new(0, 3, 0)
        if inputValue.useOperationMethod and type(GetActionMethod) == "function" and GetActionMethod() == "Tween" and type(NNVN_TweenTo) == "function" then
            return NNVN_TweenTo(computedValue) == true
        end
        NNVN_TweenTo(computedValue)
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        previousMap.lastTeleport = os.clock()
        return true
    end
    local function resolveAutoSelectedQuest(inputValue)
        getgenv().NNVN_AutoSelectedQuest = inputValue == true
        getgenv().NNVN_QuestFarmSession = (getgenv().NNVN_QuestFarmSession or 0) + 1
        local questFarmSession = getgenv().NNVN_QuestFarmSession
        if not inputValue then
            resolvePrevious()
            return
        end
        resolvePrevious()
        local zengTianguoQuestPerch2 = zengTianguoQuestPerch[getgenv().NNVN_SelectedAutoQuest]
        local inactive = zengTianguoQuestPerch2 and resolveInactive(zengTianguoQuestPerch2) or "inactive"
        if inactive ~= "active" then
            getgenv().NNVN_AutoSelectedQuest = false
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Quest Farm",
                    Content = inactive == "complete" and "Quest complete — nothing to farm." or "Selected quest is not active or its objective changed.",
                    Duration = 4
                })
            end
            return
        end
        previousMap.previous = {
            Anchor = getgenv().NNVN_Anchor == true,
            AutoCast = getgenv().NNVN_AutoCast == true,
            AutoSkill = getgenv().NNVN_AutoSkill == true
        }
        getgenv().NNVN_Anchor = true
        getgenv().NNVN_AutoCast = true
        getgenv().NNVN_AutoSkill = true
        pcall(EquipSlot1)
        pcall(resolveCharacter2, zengTianguoQuestPerch2)
        task.spawn(function()
            while getgenv().NNVN_AutoSelectedQuest and questFarmSession == getgenv().NNVN_QuestFarmSession do
                local inactive = resolveInactive(zengTianguoQuestPerch2)
                if inactive ~= "active" then
                    getgenv().NNVN_AutoSelectedQuest = false
                    resolvePrevious()
                    if not getgenv().NNVN_Notify then
                        break
                    end
                    item:Notify({
                        Title = "Quest Farm",
                        Content = inactive == "complete" and "Quest complete — farm stopped." or "Quest is no longer active.",
                        Duration = 4
                    })
                    break
                end
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                local character2 = character and character:GetAttribute("Fishing") == true
                if rootPart and not character2 and (rootPart.Position - zengTianguoQuestPerch2.cframe.Position).Magnitude > 90 then
                    pcall(resolveCharacter2, zengTianguoQuestPerch2)
                end
                if not HasFishingRod() then
                    pcall(EquipSlot1)
                end
                task.wait(3)
            end
        end)
    end
    questFarmSec = mainMap.Quest:AddSection({ Title = "Quest Farm [BETA]", Icon = "route" })
    questFarmSec:AddParagraph({
        Title = "Verified quest data",
        Content = "Supported: Zeng Tianguo (25 bosses, Perch), Frost Isle (100 catches), Perch Isle (Ascended/Trueform Perch), Orb Claw (25 Trueform Jiaolongfish).\nA quest stops and notifies at its target, including values above target."
    })
    questFarmSec:AddDropdown("NNVN_SelectedAutoQuest", {
        Title = "Select Quest",
        Values = {
            "Zeng Tianguo Quest - Perch Isle",
            "Frost Isle Quest - Frost Isle",
            "Perch Isle Quest - Perch Isle",
            "Orb Claw - Sovereign Isle"
        },
        Default = getgenv().NNVN_SelectedAutoQuest,
        Callback = function(enabled)
            getgenv().NNVN_SelectedAutoQuest = enabled
            if getgenv().NNVN_AutoSelectedQuest then
                resolveAutoSelectedQuest(true)
            end
        end
    })
    questFarmSec:AddToggle("NNVN_AutoSelectedQuest", {
        Title = "Auto Do Selected Quest",
        Description = "Teleports to the verified island, then enables Anchor Bar, Auto Cast and Auto Skills.",
        Default = false,
        Callback = resolveAutoSelectedQuest
    })
    godSec = mainMap.Quest:AddSection({ Title = "God Spirit", Icon = "sparkles" })
    godStatusLabel = godSec:AddParagraph({ Title = "Status", Content = "🔴 Offline" })
    godStatusCo = nil
    godSec:AddToggle("AutoCheckGodStatus", {
        Title = "Auto Check Status",
        Default = false,
        Callback = function(enabled)
            if enabled then
                if godStatusCo then
                    coroutine.close(godStatusCo)
                    godStatusCo = nil
                end
                godStatusCo = coroutine.create(function()
                    while true do
                        local godExistsResult = GodExists()
                        pcall(function()
                            godStatusLabel:SetDesc(godExistsResult and "🟢 Online - God Spirit in this server!" or "🔴 Offline")
                        end)
                        task.wait(3)
                    end
                end)
                coroutine.resume(godStatusCo)
            else
                if godStatusCo then
                    coroutine.close(godStatusCo)
                    godStatusCo = nil
                end
                pcall(function()
                    godStatusLabel:SetDesc("🔴 Offline")
                end)
            end
        end
    })
    GodSpiritCo = nil
    godSec:AddToggle("AutoGodSpirit", {
        Title = "Auto God Spirit (Teleport + Interact + Pray)",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoGodSpirit = enabled
            if enabled then
                if GodSpiritCo then
                    coroutine.close(GodSpiritCo)
                    GodSpiritCo = nil
                end
                GodSpiritCo = coroutine.create(function()
                    while getgenv().NNVN_AutoGodSpirit do
                        local god = Workspace:FindFirstChild("NPC") and Workspace.NPC:FindFirstChild("God")
                        if god and #god:GetChildren() > 0 then
                            for _, item2 in ipairs(god:GetChildren()) do
                                if not getgenv().NNVN_AutoGodSpirit then
                                    break
                                end
                                if not item2:IsA("Model") then
                                    continue
                                end
                                local data = ReplicatedStorage:FindFirstChild("Data")
                                local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
                                local godSpirit = playerData and playerData:FindFirstChild("GodSpirit")
                                if not godSpirit or not godSpirit:FindFirstChild(item2.Name) or not godSpirit[item2.Name]:IsA("BoolValue") or not godSpirit[item2.Name].Value then
                                    InteractWithGodNPC(item2)
                                    task.wait(1.5)
                                    if getgenv().NNVN_Notify then
                                        item:Notify({
                                            Title = "God Spirit",
                                            Content = "Prayed to " .. item2.Name,
                                            Duration = 3
                                        })
                                    end
                                elseif getgenv().NNVN_Notify then
                                    item:Notify({
                                        Title = "God Spirit",
                                        Content = item2.Name .. " already prayed today",
                                        Duration = 2
                                    })
                                end
                                task.wait(0.5)
                            end
                            task.wait(5)
                        else
                            task.wait(5)
                        end
                    end
                end)
                coroutine.resume(GodSpiritCo)
            elseif GodSpiritCo then
                coroutine.close(GodSpiritCo)
                GodSpiritCo = nil
            end
        end
    })
    godSec:AddButton({
        Title = "Pray to All God Spirits Now",
        Callback = function()
            task.spawn(function()
                local god = Workspace:FindFirstChild("NPC") and Workspace.NPC:FindFirstChild("God")
                if not god or #god:GetChildren() == 0 then
                    if getgenv().NNVN_Notify then
                        item:Notify({ Title = "", Content = "No God Spirits in this server!", Duration = 2 })
                    end
                    return
                end
                for _, item2 in ipairs(god:GetChildren()) do
                    if item2:IsA("Model") then
                        InteractWithGodNPC(item2)
                        task.wait(1)
                    end
                end
                if getgenv().NNVN_Notify then
                    item:Notify({ Title = "", Content = "Prayed to all God Spirits!", Duration = 3 })
                end
            end)
        end
    })
    TeleportList = {
        {
            name = "Beginning Isle",
            cf = CFrame.new(-213.939972, 6.76193953, 33.2846527)
        },
        {
            name = "Bamboo Isle",
            cf = CFrame.new(-1184.15674, 10.6356201, -84.3372498)
        },
        {
            name = "Fallout Isle",
            cf = CFrame.new(-6.55301952, 6.24169779, 1185.16528)
        },
        {
            name = "Sovereign Isle",
            cf = CFrame.new(-1248.17249, 7.31857586, 1208.54199)
        },
        {
            name = "Perch Isle",
            cf = CFrame.new(-61.9632416, -8.2120657, -1310.39124)
        },
        {
            name = "Frost Isle",
            cf = CFrame.new(-1328.79614, 7.63562012, -1488.55383)
        },
        {
            name = "Coconut Isle",
            cf = CFrame.new(1429.93628, 7.63562012, -1478.6311)
        },
        {
            name = "Amber Isle",
            cf = CFrame.new(1239.81299, 10.6663065, 1335.96521)
        },
        {
            name = "Battlefield Isle",
            cf = CFrame.new(1394.1842, 9.27561855, 200.794785)
        },
        {
            name = "Mistpeak Isle",
            cf = CFrame.new(2611.62134, 9.27561855, -81.6781845)
        },
        {
            name = "Weather Isle",
            cf = CFrame.new(-3005.76025, 9.27561855, 1352.46362, -0.999928296, 4.86433382e-09, 0.0119756758, 4.84810281e-09, 1, -1.38436151e-09, -0.0119756758, -1.32620293e-09, -0.999928296)
        },
        {
            name = "Mystic Reef Isle",
            cf = CFrame.new(-2606.94629, 9.27561855, -1509.54138, 0.0229267217, -8.13015788e-09, -0.999737144, 8.40814849e-08, 1, -6.20407592e-09, 0.999737144, -8.39171435e-08, 0.0229267217)
        },
        {
            name = "World Angler Isle",
            cf = CFrame.new(-2411.90649, 7.6426816, -202.059006, 1.49011612e-08, -3.41527056e-08, -1, -1.08602682e-09, 1, -3.41527056e-08, 1, 1.08602738e-09, 1.49011612e-08)
        }
    }
    PREMIUM_WEATHER_OPTIONS = {
        "Clear",
        "Blazing Sun",
        "Foggy",
        "Rainy",
        "Snowy",
        "Thunderstorm",
        "Windy"
    }
    VISUAL_SKIN_TONES = {
        "Pastel brown",
        "Nougat",
        "Brown",
        "Reddish brown",
        "Cool yellow",
        "Light orange"
    }
    visualLabelCache = setmetatable({}, { __mode = "k" })
    playerIdLabelState = { label = nil, originalText = nil }
    premiumStateCache = { checked = true, value = true }
    getSimpleRoot = function()
        local character = LocalPlayer.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end
    identifyExecutorName = function()
        for _, item in ipairs({ identifyexecutor, getexecutorname }) do
            if type(item) ~= "function" then
                continue
            end
            local ok, result = pcall(item)
            if ok and result and tostring(result) ~= "" then
                return tostring(result)
            end
        end
        return "Unknown Executor"
    end
    refreshPremiumAccess = function()
        local isMatched = rawget(_G, "NNVN_IsPremium") == true or getgenv().NNVN_IsPremium == true or getgenv().NNVN_IsPremiumAccess == true
        premiumStateCache.checked = true
        premiumStateCache.value = isMatched
        getgenv().NNVN_IsPremiumAccess = isMatched
        return isMatched
    end
    ensurePremiumAccess = function(inputValue)
        if refreshPremiumAccess() then
            return true
        end
        if getgenv().NNVN_Notify and item then
            item:Notify({
                Title = "Premium required",
                Content = tostring(inputValue or "This feature") .. " is available for Premium users only.",
                Duration = 3,
                Icon = "lock"
            })
        end
        return false
    end
    formatStatusDot = function(inputValue, secondValue, thirdValue)
        return inputValue and "🟢 " .. tostring(secondValue or "Online") or "🔴 " .. tostring(thirdValue or "Offline")
    end
    formatTrackerDot = function(inputValue, secondValue)
        return string.format("%s %s", ({
            weather = secondValue and "🟢" or "🔴",
            spirit = secondValue and "🟢" or "🔴",
            taoist = secondValue and "🟢" or "🔴",
            maoshan = secondValue and "🟢" or "🔴"
        })[inputValue] or "⚪", secondValue and "Detected" or "Not detected")
    end
    getCurrentIslandName = function()
        local simpleRoot = getSimpleRoot()
        if not simpleRoot then
            return "Unknown", math.huge
        end
        local defaultStatus = "Unknown"
        local huge = math.huge
        for _, item in ipairs(TeleportList or {}) do
            local magnitude = (simpleRoot.Position - item.cf.Position).Magnitude
            if magnitude < huge then
                huge = magnitude
                defaultStatus = item.name
            end
        end
        return defaultStatus, huge
    end
    getWorldPosition = function(instance)
        if typeof(instance) == "Instance" then
            if instance:IsA("Model") then
                local pivot = instance:GetPivot()
                return pivot and pivot.Position or nil
            end
            if instance:IsA("BasePart") then
                return instance.Position
            end
        end
        return nil
    end
    getIslandForTarget = function(inputValue)
        local worldPosition = getWorldPosition(inputValue)
        if not worldPosition then
            return "Unknown"
        end
        local defaultStatus = "Unknown"
        local huge = math.huge
        for _, item in ipairs(TeleportList or {}) do
            local magnitude = (worldPosition - item.cf.Position).Magnitude
            if magnitude < huge then
                huge = magnitude
                defaultStatus = item.name
            end
        end
        return defaultStatus
    end
    findPlayerIdLabel = function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
        if not mainGui then
            return nil
        end
        local textLabel = mainGui:FindFirstChild("TextLabel")
        if textLabel and textLabel:IsA("TextLabel") then
            return textLabel
        end
        for _, item in ipairs(mainGui:GetDescendants()) do
            if item:IsA("TextLabel") and item.Name == "TextLabel" then
                return item
            end
        end
        return nil
    end
    applyHidePlayerId = function()
        local label = playerIdLabelState.label
        if not label or not label.Parent then
            label = findPlayerIdLabel()
            playerIdLabelState.label = label
            if label and playerIdLabelState.originalText == nil then
                playerIdLabelState.originalText = label.Text
            end
        end
        local StarterGui = game:GetService("StarterGui")
        local mainGui = StarterGui and StarterGui:FindFirstChild("MainGui")
        local textLabel = mainGui and mainGui:FindFirstChild("TextLabel")
        if textLabel and textLabel:IsA("TextLabel") and playerIdLabelState.originalStarterText == nil then
            playerIdLabelState.originalStarterText = textLabel.Text
        end
        if getgenv().NNVN_BlankPlayerId then
            if label then
                label.Visible = true
                label.Text = ""
            end
            if textLabel and textLabel:IsA("TextLabel") then
                textLabel.Text = ""
            end
        elseif getgenv().NNVN_HidePlayerId then
            local customPlayerIdText = tostring(getgenv().NNVN_CustomPlayerId or "")
            if customPlayerIdText == "" then
                customPlayerIdText = tostring(LocalPlayer.UserId)
            end
            if label then
                label.Visible = true
                label.Text = customPlayerIdText
            end
            if textLabel and textLabel:IsA("TextLabel") then
                textLabel.Text = customPlayerIdText
            end
        else
            if label then
                label.Visible = true
                if playerIdLabelState.originalText ~= nil then
                    label.Text = playerIdLabelState.originalText
                end
            end
            if textLabel and textLabel:IsA("TextLabel") and playerIdLabelState.originalStarterText ~= nil then
                textLabel.Text = playerIdLabelState.originalStarterText
            end
        end
    end
    applyHidePlayerName = function()
        local localPlayer = Workspace:FindFirstChild("LocalPlayer") or LocalPlayer.Character
        local rootPart = localPlayer and localPlayer:FindFirstChild("HumanoidRootPart")
        local equippedTitle = rootPart and rootPart:FindFirstChild("EquippedTitle")
        local playerName = equippedTitle and equippedTitle:FindFirstChild("PlayerName")
        if not playerName or not playerName:IsA("TextLabel") then
            return
        end
        if getgenv().NNVN_HidePlayerName then
            if getgenv().NNVN_HidePlayerNameText == nil then
                getgenv().NNVN_HidePlayerNameText = playerName.Text
            end
            playerName.Text = ""
            playerName.Visible = false
        else
            playerName.Visible = true
            if getgenv().NNVN_HidePlayerNameText ~= nil then
                playerName.Text = getgenv().NNVN_HidePlayerNameText
            end
        end
    end
    gameUiHideState = gameUiHideState or { items = {} }
    rememberGameUiState = function(instance)
        if not instance or gameUiHideState.items[instance] then
            return
        end
        gameUiHideState.items[instance] = {
            visible = instance:IsA("GuiObject") and instance.Visible or nil,
            enabled = instance:IsA("LayerCollector") and instance.Enabled or nil
        }
    end
    RequestHideUI = function()
        getgenv().NNVN_HideUI = true
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
        if not mainGui then
            return
        end
        for _, item in ipairs(mainGui:GetChildren()) do
            if item.Name == "Fishing" then
                continue
            end
            rememberGameUiState(item)
            if item:IsA("GuiObject") then
                item.Visible = false
            end
            if item:IsA("LayerCollector") then
                item.Enabled = false
            end
        end
    end
    RequestShowUI = function()
        getgenv().NNVN_HideUI = false
        for key, entry in pairs(gameUiHideState.items) do
            if not key or not key.Parent then
                continue
            end
            if key:IsA("GuiObject") and entry.visible ~= nil then
                key.Visible = entry.visible
            end
            if key:IsA("LayerCollector") and entry.enabled ~= nil then
                key.Enabled = entry.enabled
            end
        end
    end
    maybeRewriteLabel = function(instance, secondValue)
        if not instance or not instance:IsA("TextLabel") then
            return
        end
        if visualLabelCache[instance] == nil then
            visualLabelCache[instance] = instance.Text
        end
        instance.Text = secondValue
    end
    restoreFakeVisuals = function()
        for key, entry in pairs(visualLabelCache) do
            if key and key.Parent then
                key.Text = entry
            end
        end
    end
    applyFakeVisuals = function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
        if not mainGui then
            return
        end
        if not getgenv().NNVN_FakeVisualsEnabled then
            restoreFakeVisuals()
            return
        end
        for _, item in ipairs(mainGui:GetDescendants()) do
            if not item:IsA("TextLabel") then
                continue
            end
            local formattedText = string.lower(item:GetFullName() or "")
            local textText = tostring(item.Text or "")
            local formattedText2 = string.lower((item.Name or "") .. " " .. textText .. " " .. formattedText)
            local isMatched = item.AbsolutePosition.X <= 420 and item.AbsolutePosition.Y <= 220
            local isMatched2 = textText:match("%d") ~= nil
            local findResult = formattedText2:find("friend") or formattedText2:find("boost")
            if formattedText2:find("level") or formattedText2:find("lvl") then
                maybeRewriteLabel(item, tostring(getgenv().NNVN_FakeLevelText))
            elseif not findResult and (formattedText2:find("money") or formattedText2:find("cash") or formattedText2:find("coin") or (formattedText:find("money") or formattedText:find("cash") or formattedText:find("coin")) and isMatched) then
                maybeRewriteLabel(item, tostring(getgenv().NNVN_FakeMoneyText))
            elseif not findResult and (formattedText2:find("gem") or formattedText2:find("diamond") or formattedText2:find("crystal") or (formattedText:find("gem") or formattedText:find("diamond") or formattedText:find("crystal")) and isMatched) then
                maybeRewriteLabel(item, tostring(getgenv().NNVN_FakeGemText))
            elseif not findResult and formattedText2:find("ticket") then
                maybeRewriteLabel(item, tostring(getgenv().NNVN_FakeTicketText))
            elseif not findResult and formattedText2:find("orb") then
                maybeRewriteLabel(item, tostring(getgenv().NNVN_FakeOrbText))
            elseif not findResult and isMatched and isMatched2 and not formattedText2:find("friend") and not formattedText2:find("boost") and not formattedText2:find("luck") then
                if textText:find("%$") or formattedText:find("money") or formattedText:find("cash") or formattedText:find("coin") then
                    maybeRewriteLabel(item, tostring(getgenv().NNVN_FakeMoneyText))
                elseif formattedText:find("gem") or formattedText:find("diamond") or formattedText:find("crystal") then
                    maybeRewriteLabel(item, tostring(getgenv().NNVN_FakeGemText))
                elseif formattedText:find("ticket") then
                    maybeRewriteLabel(item, tostring(getgenv().NNVN_FakeTicketText))
                elseif formattedText:find("orb") then
                    maybeRewriteLabel(item, tostring(getgenv().NNVN_FakeOrbText))
                end
            elseif getgenv().NNVN_FakeNameEnabled and (formattedText2:find(string.lower(LocalPlayer.Name)) or formattedText2:find(string.lower(LocalPlayer.DisplayName))) then
                maybeRewriteLabel(item, tostring(getgenv().NNVN_FakeNameText))
            end
        end
    end
    getLocalHumanoid = function()
        local character = LocalPlayer.Character
        return character and character:FindFirstChildOfClass("Humanoid")
    end
    applyFakeHeadless = function()
        local character = LocalPlayer.Character
        if not character then
            return
        end
        local isMatched = getgenv().NNVN_FakeHeadless == true
        for _, item in ipairs(character:GetDescendants()) do
            local formattedText = string.lower(item.Name or "")
            if not formattedText:find("head") and not formattedText:find("face") then
                continue
            end
            if item:IsA("BasePart") then
                item.LocalTransparencyModifier = isMatched and 1 or 0
                item.Transparency = isMatched and 1 or 0
            elseif item:IsA("Decal") then
                item.Transparency = isMatched and 1 or 0
            else
                if not item:IsA("SpecialMesh") then
                    continue
                end
                item.Scale = isMatched and Vector3.new(0.001, 0.001, 0.001) or Vector3.new(1, 1, 1)
            end
        end
    end
    applyFakeKorblox = function()
        local character = LocalPlayer.Character
        if not character then
            return
        end
        local isMatched = getgenv().NNVN_FakeKorblox == true
        for _, item in ipairs(character:GetDescendants()) do
            local formattedText = string.lower(item.Name or "")
            if formattedText == "rightlowerleg" or formattedText == "rightupperleg" or formattedText == "rightfoot" or formattedText == "right leg" or formattedText == "right lower leg" or formattedText == "right upper leg" then
                if item:IsA("BasePart") then
                    item.LocalTransparencyModifier = isMatched and 1 or 0
                    item.Transparency = isMatched and 1 or 0
                elseif item:IsA("SpecialMesh") then
                    item.Scale = isMatched and Vector3.new(0.001, 0.001, 0.001) or Vector3.new(1, 1, 1)
                end
            end
            if not isMatched or not item:IsA("Accessory") or not formattedText:find("korblox") then
                continue
            end
            local handle = item:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                handle.LocalTransparencyModifier = 0
                handle.Transparency = 0
            end
        end
    end
    applyFakeSkinTone = function()
        if not getgenv().NNVN_FakeSkinEnabled then
            return
        end
        local character = LocalPlayer.Character
        if not character then
            return
        end
        local bodyColors = character:FindFirstChildOfClass("BodyColors")
        if not bodyColors then
            bodyColors = Instance.new("BodyColors")
            bodyColors.Parent = character
        end
        local brickColor = BrickColor.new(tostring(getgenv().NNVN_FakeSkinTone or "Pastel brown"))
        bodyColors.HeadColor3 = brickColor.Color
        bodyColors.LeftArmColor3 = brickColor.Color
        bodyColors.RightArmColor3 = brickColor.Color
        bodyColors.LeftLegColor3 = brickColor.Color
        bodyColors.RightLegColor3 = brickColor.Color
        bodyColors.TorsoColor3 = brickColor.Color
    end
    applyFakeSkinFromPlayer = function()
        local trimTextResult = trimText(getgenv().NNVN_FakeSkinPlayerName)
        if trimTextResult == "" then
            applyFakeSkinTone()
            return true
        end
        local localHumanoid = getLocalHumanoid()
        if not localHumanoid then
            return false
        end
        local ok, result = pcall(Players.GetUserIdFromNameAsync, Players, trimTextResult)
        if not ok or not result then
            return false
        end
        local ok2, result2 = pcall(Players.GetHumanoidDescriptionFromUserId, Players, result)
        if not ok2 or not result2 then
            return false
        end
        return pcall(function()
            localHumanoid:ApplyDescription(result2)
        end)
    end
end

do
    matSec = mainMap.Bait:AddSection({ Title = "Material Farming", Icon = "pickaxe" })
    matSec:AddParagraph({
        Title = "Info",
        Content = "Farm the required fish weights for bait crafting."
    })
    matBaitOptions = { "Rainbow Bait", "Frost Bait", "Nameless Bait" }
    selectedMatBait = getgenv().NNVN_MaterialBait or "Rainbow Bait"
    if selectedMatBait == "Heavenpiercer Rod" or selectedMatBait == "Pure Diamond Rod" or selectedMatBait == "Sacred Bamboo Rod" then
        selectedMatBait = "Rainbow Bait"
        getgenv().NNVN_MaterialBait = selectedMatBait
    end
    matSec:AddDropdown("NNVN_MaterialBait", {
        Title = "Select Bait to Craft",
        Values = matBaitOptions,
        Default = selectedMatBait,
        Callback = function(selected)
            getgenv().NNVN_MaterialBait = selected
            selectedMatBait = selected
        end
    })
    BAIT_RECIPES = {
        ["Rainbow Bait"] = {
            { name = "Colossal Tigerfish", minKg = 3000000, maxKg = 6000000 },
            { name = "Heavenpiercer Turtle", minKg = 3000000, maxKg = 6000000 },
            { name = "Golden Guardian Fish", minKg = 1000000, maxKg = 3000000 },
            { name = "Crimson Electric Eel", minKg = 3000000, maxKg = 4000000 }
        },
        ["Frost Bait"] = {
            { name = "Frost Kingfish", minKg = 4000000, maxKg = 7000000 },
            { name = "Ascended Perch", minKg = 900000, maxKg = 1000000 },
            { name = "Primordial Kunfish Overlord", minKg = 1000000, maxKg = 1600000 },
            { name = "Warbringer Shark", minKg = 500000, maxKg = 800000 }
        },
        ["Heavenpiercer Rod"] = {
            { name = "Flying Fish Emperor", minKg = 1000000, maxKg = 3000000 },
            { name = "Flying Fish Empress", minKg = 1000000, maxKg = 3000000 },
            { name = "Heavenpiercer Turtle", minKg = 3000000, maxKg = 6000000 },
            { name = "Rainbow Dragonfish", minKg = 5000000, maxKg = 8000000 }
        },
        ["Pure Diamond Rod"] = {
            { name = "Frost Kingfish", minKg = 4000000, maxKg = 7000000 },
            { name = "Frost Queenfish", minKg = 4000000, maxKg = 8000000 },
            { name = "Sanguine Fish", minKg = 3000000, maxKg = 6000000 },
            { name = "Draconic Koi", minKg = 1000000, maxKg = 3000000 }
        },
        ["Sacred Bamboo Rod"] = {
            { name = "Nameless Octoparasite", minKg = 6000000, maxKg = 9000000 },
            { name = "Reborn Puffer Beast", minKg = 4000000, maxKg = 6000000 },
            { name = "Ascended Perch", minKg = 3000000, maxKg = 6000000 },
            { name = "Rainbow Dragonfish", minKg = 900000, maxKg = 1000000 }
        }
    }
    MAT_WEATHER_REQUIRED = {
        ["Frost Kingfish"] = {
            weathers = { snowy = true, frost = true },
            island = "Frost Isle",
            label = "Snowy"
        },
        ["Heavenpiercer Turtle"] = { weathers = { foggy = true }, island = "Coconut Isle", label = "Foggy" },
        ["Crimson Electric Eel"] = {
            weathers = { thunderstorm = true },
            island = "Bamboo Isle",
            label = "Thunderstorm"
        },
        ["Flying Fish Emperor"] = { weathers = { windy = true }, island = "Perch Isle", label = "Windy" },
        ["Flying Fish Empress"] = { weathers = { windy = true }, island = "Perch Isle", label = "Windy" },
        ["Sanguine Fish"] = {
            weathers = { blazingsun = true },
            island = "Amber Isle",
            label = "Blazing Sun"
        },
        ["Draconic Koi"] = {
            weathers = { blazingsun = true },
            island = "Amber Isle",
            label = "Blazing Sun"
        },
        ["Reborn Puffer Beast"] = { weathers = { snowy = true }, island = "Frost Isle", label = "Snowy" }
    }
    MAT_FISH_CFRAME = {
        ["Crimson Electric Eel"] = CFrame.new(-1311.6228, 9.27561855, -17.8612099),
        ["Heavenpiercer Turtle"] = CFrame.new(1372.05164, 9.27561855, -1458.41187)
    }
    BAIT_TO_FISH = {
        ["Rainbow Bait"] = "Rainbow Dragonfish",
        ["Frost Bait"] = "Frost Queenfish",
        ["Nameless Bait"] = "Nameless Octoparasite"
    }
    USE_BAIT_FISHES = {
        ["Rainbow Dragonfish"] = "Rainbow Bait",
        ["Frost Queenfish"] = "Frost Bait",
        ["Nameless Octoparasite"] = "Nameless Bait"
    }
    MAT_FISH_CFRAME["Rainbow Dragonfish"] = CFrame.new(1655, 9, -162)
    MAT_FISH_CFRAME["Frost Queenfish"] = CFrame.new(1655, 9, -162)
    MAT_FISH_CFRAME["Nameless Octoparasite"] = CFrame.new(1655, 9, -162)
    NAMELESS_BAIT_FARM_CFRAME = phiThien1Map["Nameless Bait Farm"]
    matIslandNameToIsland = {}
    for _, item26 in ipairs(TeleportList) do
        matIslandNameToIsland[item26.name] = item26
    end
    matGetIslandsForFish = function(inputValue)
        local stateMap = {}
        local ok, result = pcall(require, ReplicatedStorage.Info.FishingAreaRarity)
        if not ok then
            return stateMap
        end
        for _, item in ipairs({
            "Beginning Isle",
            "Bamboo Isle",
            "Fallout Isle",
            "Sovereign Isle",
            "Perch Isle",
            "Frost Isle",
            "Coconut Isle",
            "Amber Isle",
            "Battlefield Isle",
            "Mistpeak Isle"
        }) do
            local resultEntry = result[item]
            if resultEntry and resultEntry[inputValue] then
                table.insert(stateMap, item)
            end
        end
        return stateMap
    end
    matGetMaterialCount = function(inputValue, secondValue, thirdValue)
        local playerData = ReplicatedStorage.Data:FindFirstChild(tostring(LocalPlayer.UserId))
        if not playerData then
            return 0
        end
        local inventory = playerData:FindFirstChild("Inventory")
        if not inventory then
            return 0
        end
        local counter = 0
        for _, entry in pairs(inventory:GetChildren()) do
            if entry.Name ~= inputValue then
                continue
            end
            local item
            if entry:IsA("StringValue") then
                local stateMap = {}
                for entryKey in string.gmatch(entry.Value, "[^|]+") do
                    table.insert(stateMap, entryKey)
                end
                if #stateMap >= 2 then
                    item = stateMap[2]:gsub("^%s+", ""):gsub("%s+$", "")
                end
            elseif entry:IsA("NumberValue") or entry:IsA("IntValue") then
                item = tostring(entry.Value)
            end
            if item then
                local parsedNum = tonumber(item)
                if parsedNum and secondValue <= parsedNum and parsedNum <= thirdValue then
                    counter = counter + 1
                end
            end
        end
        return counter
    end
    matTeleportToIsland = function(inputValue)
        local matIslandNameTo = matIslandNameToIsland[inputValue]
        if not matIslandNameTo then
            return false
        end
        local character = LocalPlayer.Character
        if not character then
            return false
        end
        if character:FindFirstChild("HumanoidRootPart") then
            NNVN_TweenTo(CFrame.new(matIslandNameTo.cf.Position) + Vector3.new(0, 5, 0))
            return true
        end
        return false
    end
    matCancelFishing = function()
        local character = LocalPlayer.Character
        if not character then
            return
        end
        if not character:GetAttribute("Fishing") then
            return
        end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            pcall(function()
                ReplicatedStorage.Events.Fishing:FireServer(rootPart.CFrame)
            end)
        end
    end
    matEnableFishing = function()
        if not getgenv().NNVN_MaterialPrevFlags then
            getgenv().NNVN_MaterialPrevFlags = {
                AutoCast = getgenv().NNVN_AutoCast,
                Anchor = getgenv().NNVN_Anchor,
                AutoSkill = getgenv().NNVN_AutoSkill
            }
        end
        getgenv().NNVN_AutoCast = true
        getgenv().NNVN_Anchor = true
        getgenv().NNVN_AutoSkill = true
    end
    matEquipBait = function(inputValue)
        local equipBait = ReplicatedStorage.Events:FindFirstChild("EquipBait")
        if not equipBait then
            warn("[Material] Remote EquipBait không tồn tại")
            return false
        end
        local ok, result = pcall(function()
            equipBait:InvokeServer(inputValue)
        end)
        if ok then
            print("[Material] Đã trang bị mồi:", inputValue)
            return true
        else
            warn("[Material] Lỗi equip bait:", result)
            return false
        end
    end
    matHandleSpecialBait = function(inputValue)
        local fishEntry = BAIT_TO_FISH[inputValue]
        if not fishEntry then
            return false
        end
        local cframeEntry = MAT_FISH_CFRAME[fishEntry]
        if not cframeEntry then
            return false
        end
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            NNVN_TweenTo(cframeEntry + Vector3.new(0, 5, 0))
            print("[Material] Đã teleport đến khu vực đặc biệt cho", fishEntry)
        end
        matEquipBait(inputValue)
        matEnableFishing()
        return true
    end
    matDisableFishing = function()
        local materialPrevFlags = getgenv().NNVN_MaterialPrevFlags
        if materialPrevFlags then
            getgenv().NNVN_AutoCast = materialPrevFlags.AutoCast and true or false
            getgenv().NNVN_Anchor = materialPrevFlags.Anchor and true or false
            getgenv().NNVN_AutoSkill = materialPrevFlags.AutoSkill and true or false
        else
            getgenv().NNVN_AutoCast = false
            getgenv().NNVN_Anchor = false
            getgenv().NNVN_AutoSkill = false
        end
        getgenv().NNVN_MaterialPrevFlags = nil
    end
    getCurrentWeather = function()
        local info = item3:FindFirstChild("Info")
        if info then
            local info2 = info:FindFirstChild("Info")
            if info2 then
                local weather = info2:FindFirstChild("Weather")
                if weather then
                    local value = weather:FindFirstChild("Value")
                    if value then
                        return (value:IsA("TextLabel") and value.Text or value.Value):gsub("Weather:%s*", "")
                    end
                end
            end
        end
        return "Clear"
    end
    matCo = coroutine.create(function()
        while getgenv().NNVN_MaterialFarming do
            pcall(function()
                if matHandleSpecialBait(selectedMatBait) then
                    task.wait(1)
                    return
                end
                local recipe = BAIT_RECIPES[selectedMatBait]
                if not recipe then
                    return
                end
                for _, item in ipairs(recipe) do
                    local name = item.name
                    local minKg = item.minKg
                    local maxKg = item.maxKg
                    local matGetIslandsFor = matGetIslandsForFish(name)
                    local requiredEntry = MAT_WEATHER_REQUIRED[name]
                    local currentWeather = getCurrentWeather()
                    local isEnabled = true
                    if requiredEntry then
                        isEnabled = requiredEntry.weathers[string.lower(currentWeather)] or false
                    end
                    if not isEnabled or #matGetIslandsFor <= 0 then
                        continue
                    end
                    matTeleportToIsland(matGetIslandsFor[1])
                    task.wait(1)
                    matCancelFishing()
                    task.wait(0.5)
                    local cframeEntry = MAT_FISH_CFRAME[name]
                    if cframeEntry then
                        local character = LocalPlayer.Character
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            NNVN_TweenTo(cframeEntry + Vector3.new(0, 5, 0))
                        end
                    end
                    matEnableFishing()
                    while getgenv().NNVN_MaterialFarming do
                        if matGetMaterialCount(name, minKg, maxKg) >= 100 then
                            break
                        end
                        task.wait(2)
                    end
                    matCancelFishing()
                    task.wait(1)
                end
            end)
            task.wait(0.5)
        end
        matDisableFishing()
    end)
    coroutine.resume(matCo)
    normalizeWeatherReporterName = function(inputValue)
        return string.lower(tostring(inputValue or "")):gsub("^weather:%s*", ""):gsub("^weather%s*:%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
    end
    local weatherLookup2 = {
        thunderstorm = "Bamboo Isle",
        foggy = "Coconut Isle",
        snowy = "Frost Isle",
        rainy = "Perch Isle",
        windy = "Mistpeak Isle",
        ["blazing sun"] = "Amber Isle"
    }
    local weatherLookup3 = {
        thunderstorm = "⛈️",
        foggy = "🌫️",
        snowy = "❄️",
        rainy = "🌧️",
        windy = "💨",
        ["blazing sun"] = "☀️",
        clear = "🟢"
    }
    isSpecialWeatherName = function(inputValue)
        local weatherReporterName = normalizeWeatherReporterName(inputValue)
        return weatherLookup[weatherReporterName] == true, weatherReporterName
    end
    getRecommendedWeatherIsland = function(inputValue)
        local weatherFarmIslandText = tostring(getgenv().NNVN_WeatherFarmIsland or "Auto")
        if weatherFarmIslandText ~= "" and weatherFarmIslandText ~= "Auto" then
            return weatherFarmIslandText
        end
        return weatherLookup2[normalizeWeatherReporterName(inputValue)]
    end
    teleportToIslandByName = function(inputValue)
        if not inputValue or inputValue == "" then
            return false
        end
        for _, item in ipairs(TeleportList or {}) do
            if item.name == inputValue then
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    return false
                end
                pcall(function()
                    NNVN_TweenTo(CFrame.new(item.cf.Position) + Vector3.new(0, 5, 0))
                end)
                return true
            end
        end
        if type(matTeleportToIsland) == "function" then
            return matTeleportToIsland(inputValue) == true
        end
        return false
    end
    getWeatherIslandPosition = function(inputValue)
        for _, item in ipairs(TeleportList or {}) do
            if item.name == inputValue and item.cf then
                return item.cf.Position
            end
        end
        return nil
    end
    isVisibleWeatherWater = function(rayResult)
        if not rayResult or not rayResult.Instance then
            return false
        end
        if rayResult.Material == Enum.Material.Water then
            return true
        end
        local formattedText = rayResult.Instance.Name:lower()
        local formattedText2 = rayResult.Instance:GetFullName():lower()
        return formattedText:find("water") ~= nil or formattedText:find("ocean") ~= nil or formattedText2:find("workspace.ocean.water", 1, true) ~= nil
    end
    findNearbyWeatherWater = function(inputValue, secondValue)
        if typeof(inputValue) ~= "Vector3" then
            return nil
        end
        secondValue = tonumber(secondValue) or 180
        local character = LocalPlayer.Character
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = character and { character } or {}
        raycastParams.IgnoreWater = false
        local itemList = { Vector3.new(0, 0, 0) }
        for _, item in ipairs({
            16,
            32,
            48,
            64,
            80,
            100,
            125,
            150,
            180
        }) do
            if item > secondValue then
                continue
            end
            table.insert(itemList, Vector3.new(item, 0, 0))
            table.insert(itemList, Vector3.new(-item, 0, 0))
            table.insert(itemList, Vector3.new(0, 0, item))
            table.insert(itemList, Vector3.new(0, 0, -item))
            local computedValue = item * 0.707
            table.insert(itemList, Vector3.new(computedValue, 0, computedValue))
            table.insert(itemList, Vector3.new(-computedValue, 0, computedValue))
            table.insert(itemList, Vector3.new(computedValue, 0, -computedValue))
            table.insert(itemList, Vector3.new(-computedValue, 0, -computedValue))
        end
        local item2
        local item3
        for _, item4 in ipairs(itemList) do
            local rayHit = Workspace:Raycast(inputValue + item4 + Vector3.new(0, 180, 0), Vector3.new(0, -420, 0), raycastParams)
            if isVisibleWeatherWater(rayHit) then
                local magnitude = item4.Magnitude
                if not item3 or magnitude < item3 then
                    item2 = rayHit.Position
                    item3 = magnitude
                end
            end
        end
        if item2 then
            return item2
        end
        return nil
    end
    teleportNearWeatherWater = function(inputValue)
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local beginningIsleMap22 = beginningIsleMap2[inputValue]
        if rootPart and beginningIsleMap22 and pcall(function()
            NNVN_TweenTo(beginningIsleMap22)
        end) then
            return true
        end
        local weatherIslandPosition = getWeatherIslandPosition(inputValue)
        if rootPart and weatherIslandPosition then
            local nearbyWeatherWater = findNearbyWeatherWater(weatherIslandPosition, 180)
            if nearbyWeatherWater then
                local computedValue = nearbyWeatherWater + Vector3.new(0, 4, 0)
                if pcall(function()
                    NNVN_TweenTo(CFrame.new(computedValue, computedValue + Vector3.new(0, 0, -1)))
                end) then
                    return true
                end
            end
        end
        return teleportToIslandByName(inputValue)
    end
    saveWeatherFarmPosition = function()
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            getgenv().NNVN_WeatherFarmPrevPos = rootPart.CFrame
            return true
        end
        return false
    end
    restoreWeatherFarmPosition = function()
        local weatherFarmPrevPos = getgenv().NNVN_WeatherFarmPrevPos
        if typeof(weatherFarmPrevPos) ~= "CFrame" then
            return false
        end
        for i = 1, 12 do
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and pcall(function()
                NNVN_TweenTo(weatherFarmPrevPos)
            end) then
                return true
            end
            task.wait(0.25)
        end
        return false
    end
    enableWeatherFarmFishing = function()
        if not getgenv().NNVN_WeatherFarmPrevFlags then
            getgenv().NNVN_WeatherFarmPrevFlags = {
                AutoCast = getgenv().NNVN_AutoCast,
                Anchor = getgenv().NNVN_Anchor,
                AutoSkill = getgenv().NNVN_AutoSkill
            }
        end
        getgenv().NNVN_AutoCast = true
        getgenv().NNVN_Anchor = true
        getgenv().NNVN_AutoSkill = true
        if type(activateAutoEquipRodForFarm) == "function" then
            activateAutoEquipRodForFarm()
        else
            getgenv().NNVN_AutoEquipRod = true
            pcall(EquipSlot1)
        end
    end
    disableWeatherFarmFishing = function(inputValue)
        if inputValue then
            getgenv().NNVN_AutoCast = false
            getgenv().NNVN_Anchor = false
            getgenv().NNVN_AutoSkill = false
            getgenv().NNVN_WeatherFarmPrevFlags = nil
            return
        end
        local weatherFarmPrevFlags = getgenv().NNVN_WeatherFarmPrevFlags
        if weatherFarmPrevFlags then
            getgenv().NNVN_AutoCast = weatherFarmPrevFlags.AutoCast and true or false
            getgenv().NNVN_Anchor = weatherFarmPrevFlags.Anchor and true or false
            getgenv().NNVN_AutoSkill = weatherFarmPrevFlags.AutoSkill and true or false
        end
        getgenv().NNVN_WeatherFarmPrevFlags = nil
    end
    refreshWeatherFarmRestoredFeatures = function(inputValue)
        if not inputValue then
            return
        end
        task.spawn(function()
            task.wait(0.35)
            local function resolveWait(inputValue, secondValue)
                if not secondValue or getgenv()[inputValue] ~= true then
                    return
                end
                getgenv()[inputValue] = false
                task.wait(0.1)
                getgenv()[inputValue] = true
            end
            resolveWait("NNVN_AutoCast", inputValue.AutoCast)
            resolveWait("NNVN_Anchor", inputValue.Anchor)
            resolveWait("NNVN_AutoSkill", inputValue.AutoSkill)
        end)
    end
    stopWeatherFarmSession = function(inputValue)
        local weatherFarmPrevFlags = getgenv().NNVN_WeatherFarmPrevFlags
        local restoreWeatherFarmPosition2 = inputValue == false or restoreWeatherFarmPosition()
        if getgenv().NNVN_WeatherFarmActive then
            disableWeatherFarmFishing(false)
            getgenv().NNVN_WeatherFarmActive = false
        else
            disableWeatherFarmFishing(false)
        end
        if restoreWeatherFarmPosition2 then
            getgenv().NNVN_WeatherFarmPrevPos = nil
            refreshWeatherFarmRestoredFeatures(weatherFarmPrevFlags)
        end
    end
    startWeatherFarmSession = function(inputValue)
        local recommendedWeatherIsland = getRecommendedWeatherIsland(inputValue)
        if not recommendedWeatherIsland then
            if getgenv().NNVN_Notify and item then
                item:Notify({
                    Title = "Weather Farm",
                    Content = "No recommended island for: " .. tostring(inputValue),
                    Duration = 3
                })
            end
            return false
        end
        if not getgenv().NNVN_WeatherFarmActive then
            saveWeatherFarmPosition()
        end
        teleportNearWeatherWater(recommendedWeatherIsland)
        enableWeatherFarmFishing()
        getgenv().NNVN_WeatherFarmActive = true
        if getgenv().NNVN_Notify and item then
            item:Notify({
                Title = "Weather Farm",
                Content = string.format("Farming %s @ %s", tostring(inputValue), recommendedWeatherIsland),
                Duration = 3,
                Icon = "cloud-sun"
            })
        end
        return true
    end
    getgenv().NNVN_IsSpecialWeather = isSpecialWeatherName
    getgenv().NNVN_GetRecommendedWeatherIsland = getRecommendedWeatherIsland
    getgenv().NNVN_TeleportToWeatherIsland = function()
        local currentWeather = getCurrentWeather()
        local recommendedWeatherIsland = getRecommendedWeatherIsland(currentWeather)
        if not recommendedWeatherIsland then
            return false, currentWeather, nil
        end
        return teleportNearWeatherWater(recommendedWeatherIsland), currentWeather, recommendedWeatherIsland
    end
    startAutoFarmWeatherLoop = function()
        if not ensurePremiumAccess("Auto Farm Weather Event") then
            getgenv().NNVN_AutoFarmWeatherEvent = false
            stopWeatherFarmSession(true)
            return
        end
        getgenv().NNVN_WeatherFarmLoopId = (getgenv().NNVN_WeatherFarmLoopId or 0) + 1
        local weatherFarmLoopId = getgenv().NNVN_WeatherFarmLoopId
        if not getgenv().NNVN_AutoFarmWeatherEvent then
            stopWeatherFarmSession(true)
            return
        end
        task.spawn(function()
            while getgenv().NNVN_AutoFarmWeatherEvent and weatherFarmLoopId == getgenv().NNVN_WeatherFarmLoopId do
                local currentWeather = getCurrentWeather()
                local isMatched, matchedDetail = isSpecialWeatherName(currentWeather)
                if isMatched then
                    if not getgenv().NNVN_WeatherFarmActive then
                        startWeatherFarmSession(currentWeather)
                    else
                        enableWeatherFarmFishing()
                        local recommendedWeatherIsland = getRecommendedWeatherIsland(currentWeather)
                        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if recommendedWeatherIsland and rootPart then
                            local beginningIsleMap22 = beginningIsleMap2[recommendedWeatherIsland]
                            if beginningIsleMap22 and (rootPart.Position - beginningIsleMap22.Position).Magnitude > 180 then
                                teleportNearWeatherWater(recommendedWeatherIsland)
                            elseif not beginningIsleMap22 then
                                for _, item2 in ipairs(TeleportList or {}) do
                                    if item2.name ~= recommendedWeatherIsland then
                                        continue
                                    end
                                    if (rootPart.Position - item2.cf.Position).Magnitude <= 180 then
                                        break
                                    end
                                    teleportNearWeatherWater(recommendedWeatherIsland)
                                    break
                                end
                            end
                        end
                    end
                elseif getgenv().NNVN_WeatherFarmActive then
                    if getgenv().NNVN_Notify and item then
                        item:Notify({
                            Title = "Weather Farm",
                            Content = "Weather cleared — returning to previous position.",
                            Duration = 3,
                            Icon = "cloud"
                        })
                    end
                    stopWeatherFarmSession(true)
                end
                pcall(function()
                    if weatherStatusParagraph and weatherStatusParagraph.SetDesc then
                        weatherStatusParagraph:SetDesc(string.format("%s Weather: %s\nIsland: %s\nRecommended: %s\nFarm session: %s\nAuto Farm: %s", weatherLookup3[matchedDetail or "clear"] or "🔴", tostring(currentWeather), tostring(getCurrentIslandName and getCurrentIslandName() or "?"), tostring(getRecommendedWeatherIsland(currentWeather) or "N/A"), getgenv().NNVN_WeatherFarmActive and "ACTIVE" or "idle", getgenv().NNVN_AutoFarmWeatherEvent and "ON" or "OFF"))
                    end
                end)
                task.wait(2)
            end
            if weatherFarmLoopId == getgenv().NNVN_WeatherFarmLoopId then
                stopWeatherFarmSession(true)
            end
        end)
    end
    getgenv().NNVN_StartAutoFarmWeather = startAutoFarmWeatherLoop
    getgenv().NNVN_StopWeatherFarm = function()
        getgenv().NNVN_AutoFarmWeatherEvent = false
        getgenv().NNVN_WeatherFarmLoopId = (getgenv().NNVN_WeatherFarmLoopId or 0) + 1
        stopWeatherFarmSession(true)
    end
    getWeatherReportRequestFunction = function()
        return syn and syn.request or http_request or request or fluxus and fluxus.request
    end
    getWeatherReporterPing = function()
        local ok, result = pcall(function()
            local dataPing = Stats.Network.ServerStatsItem["Data Ping"]
            return dataPing and dataPing:GetValueString() or ""
        end)
        if not ok then
            return nil
        end
        local parsedNum = tonumber(tostring(result):match("[%d%.]+"))
        if not parsedNum then
            return nil
        end
        return math.floor(parsedNum + 0.5)
    end
    buildWeatherReportPayload = function(inputValue)
        return {
            key = relayKey,
            placeId = placeId,
            jobId = game.JobId,
            weather = inputValue,
            players = #Players:GetPlayers(),
            maxPlayers = Players.MaxPlayers,
            ping = getWeatherReporterPing(),
            island = type(getCurrentIslandName) == "function" and getCurrentIslandName() or "Unknown",
            source = "NNVN Hub client"
        }
    end
    postHeavyweightTracker = function(inputValue, secondValue, thirdValue)
        if os.clock() < (tonumber(getgenv().NNVN_TrackerReportRetryAfter) or 0) then
            return false, "Cloudflare backoff active"
        end
        local weatherReportRequestFunction = getWeatherReportRequestFunction()
        if type(weatherReportRequestFunction) ~= "function" then
            return false, "No supported request function"
        end
        local weatherReportPayload = buildWeatherReportPayload(secondValue)
        if tonumber(weatherReportPayload.maxPlayers) and tonumber(weatherReportPayload.maxPlayers) > 0 and tonumber(weatherReportPayload.players) and tonumber(weatherReportPayload.maxPlayers) <= tonumber(weatherReportPayload.players) then
            return false, "Server full"
        end
        weatherReportPayload.tracker = inputValue
        weatherReportPayload.value = secondValue
        if type(thirdValue) == "table" then
            for key, entry in pairs(thirdValue) do
                weatherReportPayload[key] = entry
            end
        end
        local formattedText2 = string.format("%s:%s:%s", weatherReportPayload.jobId, tostring(inputValue), inputValue == "weather" and normalizeWeatherReporterName(secondValue) or string.lower(tostring(secondValue or inputValue)))
        if os.clock() - (tonumber(getgenv().NNVN_LastTrackerReportKeys[formattedText2]) or 0) < 600 then
            return true, "Already reported"
        end
        local ok, result = pcall(weatherReportRequestFunction, {
            Url = string.format("%s/heavyweight-%s", formattedText, tostring(inputValue or "tracker")),
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", ["x-weather-key"] = relayKey },
            Body = HttpService:JSONEncode(weatherReportPayload)
        })
        if not ok or type(result) ~= "table" then
            return false, "Request failed"
        end
        local parsedNum = tonumber(result.StatusCode or result.Status or result.status_code or result.statusCode) or 0
        local bodyText = tostring(result.Body or result.body or "")
        if parsedNum >= 200 and parsedNum < 300 then
            getgenv().NNVN_LastTrackerReportKeys[formattedText2] = os.clock()
            return true, "Reported"
        end
        if parsedNum == 429 or bodyText:find("error code: 1027", 1, true) then
            getgenv().NNVN_TrackerReportRetryAfter = os.clock() + 900
            return false, "Cloudflare quota exceeded (1027/429)"
        end
        return false, "HTTP " .. tostring(parsedNum)
    end
    clearTrackerReportKeys = function(inputValue)
        local lastTrackerReportKeys = getgenv().NNVN_LastTrackerReportKeys
        for entryKey in pairs(lastTrackerReportKeys) do
            if string.sub(entryKey, 1, #inputValue) == inputValue then
                lastTrackerReportKeys[entryKey] = nil
            end
        end
    end
    local taoistMap = {
        taoist = {
            { "NPC", "Function", "Taoist" },
            { "NPC", "Taoist" },
            { "world", "NPC", "Taoist" }
        },
        maoshan = {
            { "NPC", "Function", "Maoshan" },
            { "NPC", "Maoshan" },
            { "world", "NPC", "Maoshan" }
        }
    }
    findObjectAtPath = function(inputValue)
        local workspace2 = Workspace
        for _, item in ipairs(inputValue) do
            workspace2 = workspace2 and workspace2:FindFirstChild(item)
            if not workspace2 then
                return nil
            end
        end
        return workspace2
    end
    local stateMap5 = {}
    local stateMap6 = {}
    local counter4 = 0
    local counter5 = 0
    local stepIndex3 = 30
    findTrackerObject = function(inputValue)
        local nowTime = os.clock()
        if stateMap6[inputValue] and nowTime - stateMap6[inputValue] < stepIndex3 then
            local stateMap5Entry = stateMap5[inputValue]
            if stateMap5Entry == false then
                return nil
            end
            if stateMap5Entry and stateMap5Entry.Parent then
                return stateMap5Entry
            end
        end
        local item
        for _, item2 in ipairs(taoistMap[inputValue] or {}) do
            local objectAtPath = findObjectAtPath(item2)
            if objectAtPath then
                item = objectAtPath
                break
            end
        end
        if not item then
            local taoistMap2 = inputValue == "taoist" and { taoist = true } or inputValue == "maoshan" and { maoshan = true, ["mao shan"] = true } or {}
            local stateMap = {}
            local npcFolder = Workspace:FindFirstChild("NPC")
            if npcFolder then
                table.insert(stateMap, npcFolder)
            end
            local map = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("World")
            if map then
                table.insert(stateMap, map)
            end
            if #stateMap == 0 then
                table.insert(stateMap, Workspace)
            end
            for _, item3 in ipairs(stateMap) do
                if item then
                    break
                end
                for _, item4 in ipairs(item3:GetDescendants()) do
                    if taoistMap2[string.lower(item4.Name):gsub("[_%-]+", " "):gsub("%s+", " ")] then
                        item = item4
                        break
                    end
                end
            end
        end
        stateMap5[inputValue] = item or false
        stateMap6[inputValue] = nowTime
        return item
    end
    getGodSpiritCount = function()
        local nowTime = os.clock()
        if nowTime - counter5 < stepIndex3 then
            return counter4
        end
        local npcFolder = Workspace:FindFirstChild("NPC")
        local god = npcFolder and npcFolder:FindFirstChild("God")
        if god then
            local objectListCount = #god:GetChildren()
            if objectListCount > 0 then
                counter4 = objectListCount
                counter5 = nowTime
                return objectListCount
            end
        end
        local counter = 0
        local stateMap = {}
        local npcFolder2 = Workspace:FindFirstChild("NPC")
        if npcFolder2 then
            table.insert(stateMap, npcFolder2)
        end
        local characters = Workspace:FindFirstChild("Characters")
        if characters then
            table.insert(stateMap, characters)
        end
        if #stateMap == 0 then
            table.insert(stateMap, Workspace)
        end
        for _, item in ipairs(stateMap) do
            for _, item2 in ipairs(item:GetDescendants()) do
                local formattedText = string.lower(item2.Name):gsub("[_%-]+", " "):gsub("%s+", " ")
                if formattedText == "god spirit" or formattedText == "spirit god" then
                    counter = counter + 1
                end
            end
        end
        counter4 = counter
        counter5 = nowTime
        return counter
    end
end

local resolveFindFirstChild4, hasTriggered2, counter6, checkAttribute, resolveClock, executeAction3, blackTortoiseTrackerGeneration, setmetatableResult
local startDialogue
do
    resolveFindFirstChild4 = function()
        local npcFolder = Workspace:FindFirstChild("NPC")
        local god = npcFolder and npcFolder:FindFirstChild("God")
        if not god then
            return "Unknown", 10070709
        end
        for _, item in ipairs(god:GetChildren()) do
            local formattedText = string.lower(tostring(item.Name or ""))
            if string.find(formattedText, "blue", 1, true) then
                return "Blue", 3447003
            elseif string.find(formattedText, "green", 1, true) then
                return "Green", 5763719
            elseif string.find(formattedText, "yellow", 1, true) then
                return "Yellow", 16705372
            end
        end
        return "Unknown", 10070709
    end
    local blackTortoiseBloodlineLabel2 = "Black Tortoise Bloodline"
    hasTriggered2 = false
    counter6 = 0
    getgenv().NNVN_BlackTortoiseAnnounced = false
    getgenv().NNVN_BlackTortoiseAnnouncementUntil = 0
    local function resolveLower(inputValue)
        return string.lower(tostring(inputValue or "")) == string.lower(blackTortoiseBloodlineLabel2)
    end
    checkAttribute = function(instance)
        if not instance then
            return false
        end
        if resolveLower(instance.Name) or resolveLower(instance:GetAttribute("FishName")) then
            return true
        end
        local fishName = instance:FindFirstChild("FishName")
        return fishName and fishName:IsA("StringValue") and resolveLower(fishName.Value) or false
    end
    local function resolveFindFirstChild5()
        local lookupMap = {}
        local ocean = Workspace:FindFirstChild("Ocean")
        local worldBoss = Workspace:FindFirstChild("WorldBoss")
        local boss = Workspace:FindFirstChild("Boss")
        local boss2 = ocean and ocean:FindFirstChild("Boss")
        if worldBoss then
            lookupMap[#lookupMap + 1] = worldBoss
        end
        if boss then
            lookupMap[#lookupMap + 1] = boss
        end
        if boss2 then
            lookupMap[#lookupMap + 1] = boss2
        end
        return lookupMap
    end
    local function resolveWorldBoss()
        for _, item in ipairs(resolveFindFirstChild5()) do
            if checkAttribute(item) then
                return item, "WorldBoss"
            end
            for _, item2 in ipairs(item:GetDescendants()) do
                if checkAttribute(item2) then
                    return item2, "WorldBoss"
                end
            end
        end
        local fishes = Workspace:FindFirstChild("Fishes")
        if fishes then
            for _, item3 in ipairs(fishes:GetChildren()) do
                if checkAttribute(item3) then
                    return item3, "Fishes"
                end
            end
        end
        return nil, nil
    end
    local function resolveLower2(inputValue)
        local formattedText = string.lower(tostring(inputValue or ""))
        local item
        local counter = 0
        for _, item2 in ipairs(TeleportList or {}) do
            local nameText = tostring(item2.name or "")
            if counter < #nameText and nameText ~= "" and formattedText:find(string.lower(nameText), 1, true) then
                item = nameText
                counter = #nameText
            end
        end
        return item or "Unknown"
    end
    local function resolveLower3(inputValue)
        return string.lower(tostring(inputValue or "")):find("chu tianjiao", 1, true) ~= nil
    end
    local function resolveLower4(inputValue, secondValue, thirdValue)
        local formattedText = string.lower(tostring(inputValue or ""))
        local isMatched = formattedText:find("black tortoise", 1, true) ~= nil
        local lower3 = formattedText:find("hurry", 1, true) ~= nil and formattedText:find("appeared", 1, true) ~= nil and (resolveLower3(thirdValue) or resolveLower3(inputValue))
        if not lower3 and (not isMatched or not formattedText:find("appeared", 1, true) and not formattedText:find("spawn", 1, true) and not formattedText:find("hurry", 1, true)) then
            return
        end
        if getgenv().NNVN_BlackTortoiseAnnounced then
            return
        end
        local lower2 = resolveLower2(inputValue)
        if lower2 == "Unknown" and lower3 then
            lower2 = "Random Isle 1-13 (Chu Tianjiao signal)"
        end
        getgenv().NNVN_BlackTortoiseAnnounced = true
        getgenv().NNVN_BlackTortoiseAnnouncementUntil = os.clock() + 600
        getgenv().NNVN_BlackTortoiseAnnouncedIsland = lower2
        getgenv().NNVN_BlackTortoiseAnnouncementText = tostring(inputValue)
        local blackTortoiseTrackerStatus = getgenv().NNVN_BlackTortoiseTrackerStatus
        if blackTortoiseTrackerStatus and blackTortoiseTrackerStatus.SetDesc then
            blackTortoiseTrackerStatus:SetDesc("Announced | " .. lower2 .. " | waiting for boss")
        end
        if getgenv().NNVN_Notify then
            item:Notify({
                Title = blackTortoiseBloodlineLabel2,
                Content = "Announced at " .. lower2,
                Duration = 6
            })
        end
        local onBlackTortoiseAnnounced = getgenv().NNVN_OnBlackTortoiseAnnounced
        if type(onBlackTortoiseAnnounced) == "function" then
            task.defer(onBlackTortoiseAnnounced, lower2, secondValue, tostring(inputValue))
        end
    end
    getgenv().NNVN_ReportBlackTortoiseAnnouncement = resolveLower4
    resolveClock = function(instance, secondValue)
        local nowTime = os.clock()
        if instance then
            local defaultStatus = "Unknown"
            if instance:IsA("Model") or instance:IsA("BasePart") then
                local ok, result = pcall(getIslandForTarget, instance)
                if ok and result then
                    defaultStatus = tostring(result)
                end
            end
            if defaultStatus == "Unknown" and getgenv().NNVN_BlackTortoiseAnnounced then
                local blackTortoiseAnnouncedIsland = tostring(getgenv().NNVN_BlackTortoiseAnnouncedIsland or "Unknown")
                if blackTortoiseAnnouncedIsland ~= "" and blackTortoiseAnnouncedIsland ~= "Unknown" then
                    defaultStatus = blackTortoiseAnnouncedIsland
                end
            end
            if defaultStatus == "Unknown" and secondValue == "Fishes" and LocalPlayer.Character then
                local ok2, result2 = pcall(getIslandForTarget, LocalPlayer.Character)
                if ok2 and result2 and tostring(result2) ~= "Unknown" then
                    defaultStatus = tostring(result2)
                end
            end
            getgenv().NNVN_BlackTortoisePresent = true
            getgenv().NNVN_BlackTortoiseSource = secondValue
            getgenv().NNVN_BlackTortoiseIsland = defaultStatus
            getgenv().NNVN_BlackTortoiseInstance = instance
            if not hasTriggered2 then
                hasTriggered2 = true
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = blackTortoiseBloodlineLabel2,
                        Content = (secondValue == "Fishes" and "Fishing encounter detected" or "World boss visible") .. " | " .. defaultStatus,
                        Duration = 5
                    })
                end
                local onBlackTortoiseSpawn = getgenv().NNVN_OnBlackTortoiseSpawn
                if type(onBlackTortoiseSpawn) == "function" then
                    task.defer(onBlackTortoiseSpawn, instance, secondValue, defaultStatus)
                end
            end
            local blackTortoiseTrackerStatus = getgenv().NNVN_BlackTortoiseTrackerStatus
            if blackTortoiseTrackerStatus and blackTortoiseTrackerStatus.SetDesc then
                blackTortoiseTrackerStatus:SetDesc((secondValue == "Fishes" and "Encounter" or "Visible boss") .. " | " .. defaultStatus)
            end
        else
            hasTriggered2 = false
            getgenv().NNVN_BlackTortoisePresent = false
            getgenv().NNVN_BlackTortoiseSource = nil
            getgenv().NNVN_BlackTortoiseIsland = nil
            getgenv().NNVN_BlackTortoiseInstance = nil
            if (getgenv().NNVN_BlackTortoiseAnnouncementUntil or 0) <= os.clock() then
                getgenv().NNVN_BlackTortoiseAnnounced = false
            end
            local blackTortoiseTrackerStatus2 = getgenv().NNVN_BlackTortoiseTrackerStatus
            if blackTortoiseTrackerStatus2 and blackTortoiseTrackerStatus2.SetDesc then
                if getgenv().NNVN_BlackTortoiseAnnounced then
                    blackTortoiseTrackerStatus2:SetDesc("Announced | " .. tostring(getgenv().NNVN_BlackTortoiseAnnouncedIsland or "Unknown") .. " | waiting for boss")
                else
                    blackTortoiseTrackerStatus2:SetDesc("Not detected in this server")
                end
            end
        end
        counter6 = nowTime
    end
    executeAction3 = function()
        local primaryValue, secondaryValue = resolveWorldBoss()
        resolveClock(primaryValue, secondaryValue)
        return primaryValue ~= nil, primaryValue, secondaryValue
    end
    getgenv().NNVN_CheckBlackTortoise = executeAction3
    getgenv()._NNVN_BlackTortoiseTrackerGeneration = (getgenv()._NNVN_BlackTortoiseTrackerGeneration or 0) + 1
    blackTortoiseTrackerGeneration = getgenv()._NNVN_BlackTortoiseTrackerGeneration
    for _, item27 in ipairs(getgenv()._NNVN_BlackTortoiseTrackerConnections or {}) do
        pcall(function()
            item27:Disconnect()
        end)
    end
    local stateMap7 = {}
    getgenv()._NNVN_BlackTortoiseTrackerConnections = stateMap7
    setmetatableResult = setmetatable({}, { __mode = "k" })
    local function resolveDescendantAdded(inputValue)
        if not inputValue or setmetatableResult[inputValue] then
            return
        end
        setmetatableResult[inputValue] = true
        local function checkAttribute(instance)
            if resolveLower(instance.Name) or instance.Name == "FishName" or resolveLower(instance:GetAttribute("FishName")) then
                task.defer(executeAction3)
            end
        end
        stateMap7[#stateMap7 + 1] = inputValue.DescendantAdded:Connect(checkAttribute)
        stateMap7[#stateMap7 + 1] = inputValue.DescendantRemoving:Connect(checkAttribute)
    end
    local ocean = Workspace:FindFirstChild("Ocean")
    resolveDescendantAdded(Workspace:FindFirstChild("WorldBoss"))
    resolveDescendantAdded(Workspace:FindFirstChild("Boss"))
    resolveDescendantAdded(Workspace:FindFirstChild("Fishes"))
    resolveDescendantAdded(ocean and ocean:FindFirstChild("Boss"))
    stateMap7[#stateMap7 + 1] = Workspace.ChildAdded:Connect(function(child)
        if child.Name == "WorldBoss" or child.Name == "Boss" or child.Name == "Fishes" then
            resolveDescendantAdded(child)
            task.defer(executeAction3)
        end
    end)
    if ocean then
        stateMap7[#stateMap7 + 1] = ocean.ChildAdded:Connect(function(child)
            if child.Name == "Boss" then
                resolveDescendantAdded(child)
                task.defer(executeAction3)
            end
        end)
    end
    local events2 = ReplicatedStorage:FindFirstChild("Events")
    local notification = events2 and events2:FindFirstChild("Notification")
    if notification then
        stateMap7[#stateMap7 + 1] = notification.OnClientEvent:Connect(function(inputValue)
            resolveLower4(inputValue, "Notification")
        end)
    end
    startDialogue = events2 and events2:FindFirstChild("StartDialogue")
    if startDialogue then
        stateMap7[#stateMap7 + 1] = startDialogue.OnClientEvent:Connect(function(inputValue, instance, thirdValue)
            if type(thirdValue) == "table" then
                resolveLower4(thirdValue[1], "NPC", instance and (instance:GetAttribute("Name") or instance.Name) or "")
            end
        end)
    end
end

local resolveInsert
do
    task.spawn(function()
        executeAction3()
        while getgenv().NNVN_Loaded ~= true do
            task.wait(0.5)
        end
        while getgenv().NNVN_Loaded == true and blackTortoiseTrackerGeneration == getgenv()._NNVN_BlackTortoiseTrackerGeneration do
            task.wait(12)
            if os.clock() - counter6 >= 10 then
                executeAction3()
            end
        end
    end)
    local stateMap8 = {}
    local weatherMap2 = {
        weather = 5793266,
        maoshan = 16098851,
        spirit = 5763719,
        taoist = 15418782,
        serverage = 3447003,
        vermilion = 16721408,
        blacktortoise = 3407793,
        premium = 15381256
    }
    local weatherLookup4 = {
        thunderstorm = { emoji = "🌩️", label = "Thunderstorm" },
        ["blazing sun"] = { emoji = "☀️", label = "Blazing Sun" },
        foggy = { emoji = "🌫️", label = "Foggy" },
        snowy = { emoji = "❄️", label = "Snowy" },
        windy = { emoji = "💨", label = "Windy" },
        rainy = { emoji = "🌧️", label = "Rainy" }
    }
    local stateMap9 = {}
    local item28
    local maoshanMap = {
        maoshan = false,
        spirit = false,
        taoist = false,
        vermilion = false,
        blacktortoise = false
    }
    whGetRequestFn = function()
        return syn and syn.request or http_request or request or fluxus and fluxus.request or http and http.request
    end
    whGetPing = function()
        local ok, result = pcall(function()
            local dataPing = Stats.Network.ServerStatsItem["Data Ping"]
            return dataPing and dataPing:GetValueString() or ""
        end)
        if ok then
            local parsedNum = tonumber(tostring(result):match("[%d%.]+"))
            if parsedNum then
                return tostring(math.floor(parsedNum + 0.5)) .. "ms"
            end
        end
        local ok2, result2 = pcall(function()
            return math.floor(Players.LocalPlayer:GetNetworkPing() * 1000)
        end)
        return ok2 and result2 and tostring(result2) .. "ms" or "N/A"
    end
    whServerInfo = function()
        local hasTriggered = false
        pcall(function()
            hasTriggered = game.PrivateServerOwnerId ~= 0 or tostring(game.VIPServerId or "") ~= ""
        end)
        local defaultStatus = "Unknown"
        pcall(function()
            if type(getCurrentIslandName) == "function" then
                defaultStatus = getCurrentIslandName() or "Unknown"
            end
        end)
        return {
            playerCount = #Players:GetPlayers(),
            maxPlayers = Players.MaxPlayers,
            serverType = hasTriggered and "Private" or "Public",
            jobId = tostring(game.JobId),
            placeId = tostring(placeId),
            ping = whGetPing(),
            island = defaultStatus
        }
    end
    whOnCooldown = function(inputValue)
        local parsedNum = tonumber(getgenv().NNVN_WebhookCooldown) or 300
        if not stateMap9[inputValue] then
            return false
        end
        return os.time() - stateMap9[inputValue] < parsedNum
    end
    whSetCooldown = function(inputValue)
        stateMap9[inputValue] = os.time()
    end
    whHttpPost = function(inputValue, secondValue)
        if not inputValue or inputValue == "" or not string.find(inputValue, "discord.com/api/webhooks") then
            return false, "invalid webhook url"
        end
        local whGetRequestFn2 = whGetRequestFn()
        if not whGetRequestFn2 then
            return false, "no http function"
        end
        local ok, result = pcall(whGetRequestFn2, {
            Url = inputValue,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(secondValue)
        })
        return ok, result
    end
    whHttpPostWithFallback = function(inputValue, secondValue, thirdValue)
        local hasTriggered = false
        local item
        local hasTriggered2 = false
        local item2
        if inputValue and inputValue ~= "" then
            local requestOk, responseBody = whHttpPost(inputValue, thirdValue)
            hasTriggered = requestOk
            item = responseBody
        end
        if secondValue and secondValue ~= "" then
            local requestOk2, responseBody2 = whHttpPost(secondValue, thirdValue)
            hasTriggered2 = requestOk2
            item2 = responseBody2
        end
        if hasTriggered or hasTriggered2 then
            return true, { primary = item, backup = item2 }
        end
        return false, { primary = item, backup = item2 }
    end
    whIsPremium = function()
        return rawget(_G, "NNVN_IsPremium") == true or getgenv().NNVN_IsPremiumAccess == true or getgenv().NNVN_IsPremium == true
    end
    whSend = function(text, secondValue, thirdValue)
        secondValue = secondValue or {}
        thirdValue = thirdValue or secondValue.force
        local weatherMap3 = weatherMap and weatherMap[text] == true
        if not weatherMap3 and getgenv().NNVN_WebhookEnabled == false and not thirdValue then
            return
        end
        if not thirdValue and whOnCooldown(text) then
            return
        end
        local globalEnvEntry = getgenv()["NNVN_Webhook" .. text:gsub("^%l", string.upper) .. "Url"]
        local globalEnvEntry2 = getgenv()["NNVN_Webhook" .. text:gsub("^%l", string.upper) .. "UrlBackup"]
        local urlsEntry = weatherMap[text] and (NNVN_SYSTEM_WEBHOOK_URLS[text] or NNVN_SYSTEM_WEBHOOK_URLS[text:gsub("^%l", string.upper)])
        local urlsEntry2 = NNVN_BACKUP_WEBHOOK_URLS[text] or NNVN_BACKUP_WEBHOOK_URLS[text:gsub("^%l", string.upper)]
        local urlsEntry3 = weatherMap3 and (urlsEntry or globalEnvEntry) or secondValue.url or globalEnvEntry or getgenv().NNVN_WebhookUrl
        local urlsEntry22 = weatherMap3 and (urlsEntry2 or globalEnvEntry2) or secondValue.backupUrl or globalEnvEntry2
        if not urlsEntry3 or urlsEntry3 == "" then
            return
        end
        local whServerInfoResult = whServerInfo()
        if tonumber(whServerInfoResult.maxPlayers) and tonumber(whServerInfoResult.maxPlayers) > 0 and tonumber(whServerInfoResult.playerCount) and tonumber(whServerInfoResult.maxPlayers) <= tonumber(whServerInfoResult.playerCount) then
            return false, "Server full"
        end
        if secondValue.island and secondValue.island ~= "" then
            whServerInfoResult.island = tostring(secondValue.island)
        end
        local whIsPremiumResult = whIsPremium()
        local embedColor = secondValue.embedColor or whIsPremiumResult and weatherMap2.premium or weatherMap2[text] or 10070709
        local nowTime = os.time()
        local stateMap = {}
        if secondValue.extraFields then
            for _, item in ipairs(secondValue.extraFields) do
                table.insert(stateMap, item)
            end
        end
        table.insert(stateMap, {
            name = "👥 Players",
            value = string.format("**%d / %d** • %s", whServerInfoResult.playerCount, whServerInfoResult.maxPlayers, whServerInfoResult.serverType),
            inline = true
        })
        table.insert(stateMap, {
            name = "📶 Ping",
            value = "**" .. tostring(whServerInfoResult.ping or "N/A") .. "**",
            inline = true
        })
        table.insert(stateMap, {
            name = "🏝️ Island",
            value = "**" .. tostring(whServerInfoResult.island) .. "**",
            inline = true
        })
        table.insert(stateMap, { name = "🕘 Detected", value = "<t:" .. nowTime .. ":R>", inline = true })
        table.insert(stateMap, {
            name = "📍 Place ID",
            value = "`" .. tostring(whServerInfoResult.placeId or placeId or "") .. "`",
            inline = true
        })
        if whIsPremiumResult then
            table.insert(stateMap, { name = "🔑 Access", value = "**PREMIUM Reporter**", inline = true })
            local defaultStatus = "Unknown"
            pcall(function()
                if type(identifyExecutorName) == "function" then
                    defaultStatus = identifyExecutorName()
                elseif identifyexecutor then
                    defaultStatus = tostring(identifyexecutor())
                end
            end)
            table.insert(stateMap, {
                name = "⚙️ Executor",
                value = "**" .. tostring(defaultStatus) .. "**",
                inline = true
            })
        end
        table.insert(stateMap, {
            name = "🔑 Job ID (PC) • triple-click to copy",
            value = "```\n" .. tostring(whServerInfoResult.jobId or game.JobId or "") .. "\n```",
            inline = false
        })
        table.insert(stateMap, {
            name = "🔑 Job ID (Mobile) • tap & hold to copy",
            value = "`" .. tostring(whServerInfoResult.jobId or game.JobId or "") .. "`",
            inline = false
        })
        table.insert(stateMap, { name = "How to use", value = "`Tab Teleport → Job ID`", inline = false })
        local nnvnHubTrackerPremiumLabel = whIsPremiumResult and "NNVN Hub Tracker ⭐ PREMIUM" or "NNVN Hub Tracker"
        local nnvnHubPremiumByLabel = whIsPremiumResult and "NNVN Hub Premium • By N0NAMEVN" or "NNVN Hub • By N0NAMEVN"
        local description = secondValue.description or ""
        if whIsPremiumResult then
            description = description .. "\n\n⭐ *Reported by a Premium NNVN Hub client — priority signal.*"
        end
        local whHttpPostWith = whHttpPostWithFallback(urlsEntry3, urlsEntry22, {
            username = nnvnHubTrackerPremiumLabel,
            avatar_url = "https://i.imgur.com/wSTFkRM.png",
            embeds = {
                {
                    title = (secondValue.eventEmoji or "📡") .. "  " .. (secondValue.title or "Tracker Alert"),
                    description = description,
                    color = embedColor,
                    fields = stateMap,
                    footer = { text = nnvnHubPremiumByLabel },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", nowTime)
                }
            }
        })
        if whHttpPostWith then
            whSetCooldown(text)
        end
        return whHttpPostWith
    end
    getgenv().NNVN_OnBlackTortoiseAnnounced = function(inputValue, secondValue, thirdValue)
        postHeavyweightTracker("blacktortoise", "Black Tortoise Bloodline Announced", {
            island = inputValue,
            source = secondValue or "NPC",
            announcement = tostring(thirdValue or "Detected")
        })
        whSend("blacktortoise", {
            eventEmoji = "🐢",
            title = "Black Tortoise Bloodline Incoming",
            description = "**Black Tortoise Bloodline** has been announced. Waiting for a live boss or fishing encounter confirmation.",
            island = inputValue,
            extraFields = {
                { name = "🐟 Fish", value = "`Black Tortoise Bloodline`", inline = true },
                {
                    name = "📡 Source",
                    value = "`" .. tostring(secondValue or "Unknown") .. "`",
                    inline = true
                },
                {
                    name = "📣 Announcement",
                    value = tostring(thirdValue or "Detected"),
                    inline = false
                }
            }
        }, true)
    end
    getgenv().NNVN_OnBlackTortoiseSpawn = function(inputValue, secondValue, thirdValue)
        maoshanMap.blacktortoise = true
        local isMatched = secondValue == "Fishes"
        postHeavyweightTracker("blacktortoise", "Black Tortoise Bloodline", { island = thirdValue, source = secondValue or "WorldBoss", live = true })
        whSend("blacktortoise", {
            eventEmoji = "🐢",
            title = isMatched and "Black Tortoise Encounter" or "Black Tortoise Bloodline Alert",
            description = isMatched and "A live **Black Tortoise Bloodline** fishing encounter was found in this server." or "A live **Black Tortoise Bloodline** boss was found in this server.",
            island = thirdValue,
            extraFields = {
                { name = "🐟 Fish", value = "`Black Tortoise Bloodline`", inline = true },
                {
                    name = "📡 Source",
                    value = "`" .. tostring(secondValue or "Unknown") .. "`",
                    inline = true
                }
            }
        }, true)
    end
    startServerAgeTracker = function()
        if getgenv()._NNVN_ServerAgeTrackerStarted then
            return
        end
        getgenv()._NNVN_ServerAgeTrackerStarted = true
        getgenv().NNVN_ServerAgeSignals = getgenv().NNVN_ServerAgeSignals or {}
        task.spawn(function()
            while getgenv()._NNVN_ServerAgeTrackerStarted do
                local serverUptimeSeconds = NNVN_GetServerUptimeSeconds()
                local floorResult = serverUptimeSeconds and math.floor(serverUptimeSeconds / 10800) or 0
                if serverUptimeSeconds and floorResult >= 1 then
                    local combinedText = tostring(game.JobId) .. ":" .. tostring(floorResult)
                    if not getgenv().NNVN_ServerAgeSignals[combinedText] and whSend("serverage", {
                        eventEmoji = "⏱️",
                        title = "Long-Running Server Alert",
                        description = "This server has reached the **" .. NNVN_FormatServerTime(serverUptimeSeconds) .. "** runtime milestone.",
                        extraFields = {
                            {
                                name = "🕒 Server Uptime",
                                value = "**" .. NNVN_FormatServerTime(serverUptimeSeconds) .. "**",
                                inline = true
                            },
                            {
                                name = "🎯 Milestone",
                                value = "**" .. tostring(floorResult * 3) .. " Hours**",
                                inline = true
                            }
                        }
                    }, true) then
                        getgenv().NNVN_ServerAgeSignals[combinedText] = true
                    end
                end
                task.wait(10)
            end
        end)
    end
    whStartAll = function()
        if getgenv()._NNVN_DiscordWebhookStarted then
            return
        end
        getgenv()._NNVN_DiscordWebhookStarted = true
        task.spawn(function()
            while true do
                task.wait(math.max(5, tonumber(getgenv().NNVN_WebhookScanInterval) or 12))
                local ok, result = pcall(getCurrentWeather)
                if ok and result then
                    local weatherReporterName = normalizeWeatherReporterName(result)
                    local weatherLookup4Entry = weatherLookup4[weatherReporterName]
                    if (weatherMap.weather or getgenv().NNVN_WebhookWeather) and weatherLookup4Entry and weatherReporterName ~= item28 then
                        item28 = weatherReporterName
                        whSend("weather", {
                            eventEmoji = weatherLookup4Entry.emoji,
                            title = weatherLookup4Entry.label .. " Weather Alert",
                            description = string.format("Special weather **%s** detected on a live Heavyweight Fishing server.\nJoin quickly to take advantage.", weatherLookup4Entry.label),
                            extraFields = {
                                {
                                    name = "🌤️ Weather",
                                    value = weatherLookup4Entry.emoji .. "  **" .. weatherLookup4Entry.label .. "**",
                                    inline = true
                                }
                            }
                        })
                    elseif not weatherLookup4Entry then
                        item28 = nil
                    end
                end
                local ok2, result2 = pcall(function()
                    return findTrackerObject("maoshan") ~= nil
                end)
                if (weatherMap.maoshan or getgenv().NNVN_WebhookMaoshan) and ok2 and result2 then
                    if not maoshanMap.maoshan then
                        maoshanMap.maoshan = true
                        whSend("maoshan", {
                            eventEmoji = "⭐ ",
                            title = "Maoshan Tracker Alert",
                            description = "A **Maoshan** event has been detected in a live server.",
                            extraFields = {
                                {
                                    name = "⭐  Tracker",
                                    value = "**Maoshan** is present in this server.",
                                    inline = true
                                }
                            }
                        })
                    end
                else
                    maoshanMap.maoshan = false
                end
                local ok3, result3 = pcall(getGodSpiritCount)
                result3 = tonumber(result3) or 0
                if (weatherMap.spirit or getgenv().NNVN_WebhookSpirit) and ok3 and result3 > 0 then
                    if not maoshanMap.spirit then
                        maoshanMap.spirit = true
                        local primaryValue, secondaryValue = resolveFindFirstChild4()
                        whSend("spirit", {
                            eventEmoji = "👻",
                            title = "God Spirit Tracker Alert",
                            description = "A **" .. primaryValue .. " God Spirit** event has been detected in a live server.",
                            embedColor = secondaryValue,
                            extraFields = {
                                {
                                    name = "👻 Spirits Found",
                                    value = "**" .. tostring(result3) .. "** God Spirit(s) in this server",
                                    inline = true
                                },
                                { name = "Color", value = "**" .. primaryValue .. "**", inline = true }
                            }
                        })
                    end
                else
                    maoshanMap.spirit = false
                end
                local ok4, result4 = pcall(function()
                    return findTrackerObject("taoist") ~= nil
                end)
                if (weatherMap.taoist or getgenv().NNVN_WebhookTaoist) and ok4 and result4 then
                    if not maoshanMap.taoist then
                        maoshanMap.taoist = true
                        whSend("taoist", {
                            eventEmoji = "🛡️",
                            title = "Taoist Tracker Alert",
                            description = "A **Taoist** event has been detected in a live server.",
                            extraFields = {
                                {
                                    name = "🛡️ Tracker",
                                    value = "**Taoist** is present in this server.",
                                    inline = true
                                }
                            }
                        })
                    end
                else
                    maoshanMap.taoist = false
                end
            end
        end)
    end
    local vermilionBirdbloodLabel = "Vermilion Birdblood"
    local hasTriggered3 = false
    getgenv().NNVN_VermilionAnnouncementSent = false
    local stateMap10 = {}
    local function resolveLower5(inputValue)
        local formattedText = string.lower(tostring(inputValue or ""))
        return formattedText:find("vermilion", 1, true) ~= nil and formattedText:find("birdblood", 1, true) ~= nil
    end
    local function resolveLower6(inputValue)
        local formattedText = string.lower(tostring(inputValue or ""))
        local item
        local counter = 0
        for _, item2 in ipairs(TeleportList or {}) do
            local nameText = tostring(item2.name or "")
            if counter < #nameText and nameText ~= "" and formattedText:find(string.lower(nameText), 1, true) then
                item = nameText
                counter = #nameText
            end
        end
        return item
    end
    local function resolveParent3(instance)
        local stateMap = {}
        local parent = instance.Parent
        local instance2 = instance
        for i = 1, 4 do
            instance2 = instance2 and instance2.Parent
            if not instance2 then
                break
            end
            parent = instance2
            local formattedText = string.lower(tostring(instance2.Name or ""))
            if formattedText:find("dialog", 1, true) then
                break
            end
            if formattedText:find("talk", 1, true) then
                break
            end
        end
        if parent then
            local counter = 0
            for _, item in ipairs(parent:GetDescendants()) do
                counter = counter + 1
                if counter > 80 then
                    break
                end
                if item:IsA("TextLabel") or item:IsA("TextButton") then
                    table.insert(stateMap, tostring(item.Text or ""))
                end
            end
        end
        return table.concat(stateMap, " ")
    end
    local function resolveLower7(inputValue, secondValue)
        local formattedText = string.lower(tostring(inputValue or ""))
        local formattedText2 = string.lower(tostring(secondValue or ""))
        local isMatched = formattedText:find("chu tianjiao", 1, true) ~= nil or formattedText2:find("chu tianjiao", 1, true) ~= nil
        return formattedText:find("hurry", 1, true) ~= nil and formattedText:find("appeared", 1, true) ~= nil and (isMatched or resolveLower5(formattedText))
    end
    local function resolveFindFirstChild6()
        local vermilionFindBossResult = type(vermilionFindBoss) == "function" and vermilionFindBoss() or nil
        if vermilionFindBossResult then
            return vermilionFindBossResult
        end
        for _, item in ipairs({
            Workspace:FindFirstChild("NPC"),
            Workspace:FindFirstChild("Boss"),
            Workspace:FindFirstChild("Characters"),
            Workspace:FindFirstChild("WorldBoss")
        }) do
            if not item then
                continue
            end
            if resolveLower5(item.Name) then
                return item
            end
            for _, item2 in ipairs(item:GetDescendants()) do
                if resolveLower5(item2.Name) then
                    return item2
                end
            end
        end
        return nil
    end
    local function resolveUnknown2(inputValue, secondValue, thirdValue)
        if hasTriggered3 then
            return
        end
        local islandForTarget = inputValue and getIslandForTarget(inputValue) or nil
        if not islandForTarget or islandForTarget == "Unknown" then
            islandForTarget = resolveLower6(thirdValue)
        end
        islandForTarget = islandForTarget or "Unknown"
        hasTriggered3 = true
        getgenv().NNVN_VermilionInstance = inputValue
        maoshanMap.vermilion = true
        local vermilionBossStatus = getgenv().NNVN_VermilionBossStatus
        if vermilionBossStatus and vermilionBossStatus.SetDesc then
            vermilionBossStatus:SetDesc("Detected | " .. tostring(secondValue or "WorldBoss"))
        end
        if getgenv().NNVN_NotifyVermilionSpawn and getgenv().NNVN_Notify then
            item:Notify({
                Title = "Vermilion Birdblood",
                Content = "Boss detected in this server.",
                Duration = 5
            })
        end
        if getgenv().NNVN_ESP and getgenv().NNVN_ESP.Vermilion and type(applyESP_Vermilion) == "function" then
            task.defer(function()
                pcall(applyESP_Vermilion)
            end)
        end
        postHeavyweightTracker("vermilion", "Vermilion Birdblood", {
            island = islandForTarget,
            source = secondValue or "WorldBoss",
            live = true
        })
        whSend("vermilion", {
            eventEmoji = "🔥",
            title = "Vermilion Birdblood Alert",
            description = "**Vermilion Birdblood** has spawned in a live server.",
            island = islandForTarget,
            extraFields = {
                {
                    name = "🐟 Fish",
                    value = "**" .. vermilionBirdbloodLabel .. "**",
                    inline = true
                },
                {
                    name = "🏝️ Spawn Island",
                    value = "**" .. tostring(islandForTarget) .. "**",
                    inline = true
                },
                {
                    name = "📡 Source",
                    value = "**" .. tostring(secondValue) .. "**",
                    inline = true
                }
            }
        }, true)
    end
    local function resolveClock2(inputValue)
        if getgenv().NNVN_VermilionAnnouncementSent or hasTriggered3 then
            return
        end
        getgenv().NNVN_VermilionAnnouncementSent = true
        getgenv().NNVN_VermilionAnnouncementUntil = os.clock() + 600
        local lower6 = resolveLower6(inputValue) or "Random Isle 1-13 (pending WorldBoss)"
        postHeavyweightTracker("vermilion", "Vermilion Birdblood Announced", {
            island = lower6,
            source = "NPC",
            announcement = tostring(inputValue or "Hurry! Appeared.")
        })
        whSend("vermilion", {
            eventEmoji = "🔥",
            title = "Vermilion Birdblood Incoming",
            description = "**Chu Tianjiao** announced: **Hurry! Appeared.** Waiting for the WorldBoss model to confirm the exact spawn island.",
            island = lower6,
            extraFields = {
                {
                    name = "🐟 Fish",
                    value = "**" .. vermilionBirdbloodLabel .. "**",
                    inline = true
                },
                { name = "🏝️ Island", value = "**" .. lower6 .. "**", inline = true },
                { name = "📡 Source", value = "**NPC**", inline = true }
            }
        }, true)
    end
    resolveInsert = function()
        if getgenv()._NNVN_VermilionTrackerStarted then
            return
        end
        getgenv()._NNVN_VermilionTrackerStarted = true
        table.insert(stateMap10, Workspace.DescendantAdded:Connect(function(instance)
            if instance and resolveLower5(instance.Name) then
                task.defer(resolveUnknown2, instance, "WorldBoss", nil)
            end
        end))
        local events = ReplicatedStorage:FindFirstChild("Events")
        local startDialogue = events and events:FindFirstChild("StartDialogue")
        if startDialogue then
            table.insert(stateMap10, startDialogue.OnClientEvent:Connect(function(inputValue, instance, thirdValue)
                if type(thirdValue) ~= "table" then
                    return
                end
                if resolveLower7(thirdValue[1], instance and (instance:GetAttribute("Name") or instance.Name) or "") then
                    task.defer(resolveClock2, tostring(thirdValue[1] or "Hurry! Appeared."))
                end
            end))
        end
        task.spawn(function()
            local item
            local function checkAttribute()
                if item and item.Parent then
                    return item
                end
                local npcFolder = Workspace:FindFirstChild("NPC")
                if not npcFolder then
                    return nil
                end
                for _, item2 in ipairs(npcFolder:GetDescendants()) do
                    if not item2:IsA("ProximityPrompt") then
                        continue
                    end
                    local model = item2:FindFirstAncestorOfClass("Model")
                    if string.lower(model and tostring(model:GetAttribute("Name") or model.Name) or ""):find("chu tianjiao", 1, true) or string.lower(tostring(item2.ObjectText or "")):find("chu tianjiao", 1, true) then
                        item = item2
                        return item2
                    end
                end
                return nil
            end
            local function resolveFindFirstChild()
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
                local menu = mainGui and mainGui:FindFirstChild("Menu")
                local dialogue = menu and menu:FindFirstChild("Dialogue")
                local fishing = mainGui and mainGui:FindFirstChild("Fishing")
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                return not (dialogue and dialogue.Visible == true) and not (fishing and fishing.Visible == true) and humanoid and humanoid.Health > 0 and humanoid.SeatPart == nil
            end
            local function resolveHuge(inputValue)
                getgenv().NNVN_ChuTianjiaoLastResponse = tostring(inputValue or "")
                getgenv().NNVN_ChuTianjiaoNextCheckAt = math.huge
                getgenv().NNVN_ChuTianjiaoNextCheckDelay = 0
                getgenv().NNVN_ChuTianjiaoNextCheckReason = "One-time startup check completed"
            end
            local function teleportCharacter(inputValue)
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                local model = inputValue and inputValue:FindFirstAncestorOfClass("Model")
                local rootPart2 = model and model:FindFirstChild("HumanoidRootPart")
                if not rootPart or not rootPart2 or not startDialogue or type(getconnections) ~= "function" then
                    return
                end
                local cFrame = rootPart.CFrame
                local assemblyLinearVelocity = rootPart.AssemblyLinearVelocity
                local assemblyAngularVelocity = rootPart.AssemblyAngularVelocity
                if type(NNVN_StopTween) == "function" then
                    pcall(NNVN_StopTween)
                end
                local currentCamera = Workspace.CurrentCamera
                local cameraType = currentCamera and currentCamera.CameraType
                local cameraSubject = currentCamera and currentCamera.CameraSubject
                local cFrame2 = currentCamera and currentCamera.CFrame
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
                local menu = mainGui and mainGui:FindFirstChild("Menu")
                local lookupMap = {}
                if menu then
                    for _, item in ipairs(menu:GetChildren()) do
                        if item:IsA("GuiObject") then
                            lookupMap[item] = item.Visible
                        end
                    end
                end
                local item2
                local item3
                local connection = startDialogue.OnClientEvent:Connect(function(inputValue, instance, thirdValue)
                    local nameAttrText = instance and tostring(instance:GetAttribute("Name") or instance.Name) or ""
                    if string.lower(nameAttrText):find("chu tianjiao", 1, true) then
                        item3 = nameAttrText
                        item2 = type(thirdValue) == "table" and tostring(thirdValue[1] or "") or ""
                    end
                end)
                local hasTriggered = false
                local function resolveFindFirstChild()
                    local dialogue = menu and menu:FindFirstChild("Dialogue")
                    if not dialogue then
                        return
                    end
                    dialogue.Visible = false
                    local buttonFrame = dialogue:FindFirstChild("ButtonFrame")
                    if not buttonFrame then
                        return
                    end
                    for _, item in ipairs(buttonFrame:GetChildren()) do
                        if not item:IsA("GuiButton") or item.Name == "Template" then
                            continue
                        end
                        local title = item:FindFirstChild("Title")
                        if not string.lower(tostring(title and title:IsA("TextLabel") and title.Text or item.Text or "")):find("close", 1, true) then
                            continue
                        end
                        if not hasTriggered then
                            hasTriggered = true
                            local hasTriggered2 = false
                            if type(getconnections) == "function" then
                                for _, item2 in ipairs(getconnections(item.MouseButton1Click)) do
                                    if item2.Function then
                                        hasTriggered2 = true
                                        task.spawn(function()
                                            pcall(item2.Function)
                                        end)
                                    end
                                end
                            end
                            if not hasTriggered2 and type(firesignal) == "function" then
                                pcall(firesignal, item.MouseButton1Click)
                            end
                        end
                        return
                    end
                end
                local ok, result = pcall(function()
                    if currentCamera then
                        currentCamera.CameraType = Enum.CameraType.Scriptable
                        currentCamera.CFrame = cFrame2
                    end
                    NNVN_TweenTo(rootPart2.CFrame * CFrame.new(0, 0, -5))
                    rootPart.AssemblyLinearVelocity = Vector3.zero
                    rootPart.AssemblyAngularVelocity = Vector3.zero
                    RunService.Heartbeat:Wait()
                    fireproximityprompt(inputValue)
                    local computedValue = os.clock() + 0.8
                    repeat
                        resolveFindFirstChild()
                        if item2 ~= nil then
                            break
                        end
                        task.wait(0.02)
                        local nowTime = os.clock()
                    until computedValue <= nowTime
                    resolveFindFirstChild()
                end)
                NNVN_TweenTo(cFrame)
                rootPart.AssemblyLinearVelocity = assemblyLinearVelocity
                rootPart.AssemblyAngularVelocity = assemblyAngularVelocity
                if connection then
                    connection:Disconnect()
                end
                if currentCamera then
                    currentCamera.CameraSubject = cameraSubject
                    currentCamera.CameraType = cameraType
                    currentCamera.CFrame = cFrame2
                end
                if menu then
                    for key, entry in pairs(lookupMap) do
                        if key.Parent then
                            key.Visible = entry
                        end
                    end
                    local dialogue = menu:FindFirstChild("Dialogue")
                    if dialogue then
                        dialogue.Visible = false
                    end
                end
                task.spawn(function()
                    local computedValue = os.clock() + 1
                    repeat
                        resolveFindFirstChild()
                        task.wait(0.03)
                        local nowTime = os.clock()
                    until computedValue <= nowTime
                end)
                if item2 ~= nil then
                    resolveHuge(item2)
                    local reportBlackTortoiseAnnouncement = getgenv().NNVN_ReportBlackTortoiseAnnouncement
                    if type(reportBlackTortoiseAnnouncement) == "function" then
                        reportBlackTortoiseAnnouncement(item2, "NPC", item3)
                    end
                    if resolveLower7(item2, item3) then
                        resolveClock2(item2)
                    end
                else
                    resolveHuge(nil)
                end
                if not ok then
                    getgenv().NNVN_ChuTianjiaoPollError = tostring(result)
                end
            end
            task.wait(30)
            if not getgenv()._NNVN_VermilionTrackerStarted then
                return
            end
            if whIsPremium() then
                getgenv().NNVN_ChuTianjiaoNextCheckAt = math.huge
                getgenv().NNVN_ChuTianjiaoNextCheckReason = "Premium auto NPC check disabled"
                return
            end
            getgenv().NNVN_ChuTianjiaoNextCheckAt = math.huge
            local checkAttributeResult = checkAttribute()
            if checkAttributeResult and checkAttributeResult.Enabled and type(fireproximityprompt) == "function" then
                getgenv().NNVN_ChuTianjiaoNextCheckReason = "One-time startup check running"
                teleportCharacter(checkAttributeResult)
            else
                getgenv().NNVN_ChuTianjiaoNextCheckReason = "One-time startup check failed: prompt unavailable"
            end
        end)
        local setmetatableResult = setmetatable({}, { __mode = "k" })
        local function resolveIsA(instance)
            if not instance or not instance:IsA("TextLabel") then
                return
            end
            local parent3 = resolveParent3(instance)
            local reportBlackTortoiseAnnouncement = getgenv().NNVN_ReportBlackTortoiseAnnouncement
            if type(reportBlackTortoiseAnnouncement) == "function" then
                reportBlackTortoiseAnnouncement(parent3, "NPC")
            end
            if resolveLower7(parent3) then
                task.defer(resolveClock2, parent3)
            elseif resolveLower5(parent3) then
                local findFirstChild6 = resolveFindFirstChild6()
                if findFirstChild6 then
                    task.defer(resolveUnknown2, findFirstChild6, "Chu Tianjiao Dialogue", parent3)
                end
            end
        end
        local function resolveIsA2(instance)
            if not instance:IsA("TextLabel") or setmetatableResult[instance] then
                return
            end
            setmetatableResult[instance] = true
            resolveIsA(instance)
            table.insert(stateMap10, instance:GetPropertyChangedSignal("Text"):Connect(function()
                resolveIsA(instance)
            end))
        end
        task.spawn(function()
            local playerGui = LocalPlayer:WaitForChild("PlayerGui", 20)
            if not playerGui then
                return
            end
            for _, item in ipairs(playerGui:GetDescendants()) do
                resolveIsA2(item)
            end
            table.insert(stateMap10, playerGui.DescendantAdded:Connect(resolveIsA2))
        end)
        task.spawn(function()
            while getgenv()._NNVN_VermilionTrackerStarted do
                local findFirstChild6 = resolveFindFirstChild6()
                if findFirstChild6 then
                    resolveUnknown2(findFirstChild6, "WorldBoss", nil)
                else
                    hasTriggered3 = false
                    getgenv().NNVN_VermilionInstance = nil
                    local vermilionBossStatus = getgenv().NNVN_VermilionBossStatus
                    if vermilionBossStatus and vermilionBossStatus.SetDesc then
                        vermilionBossStatus:SetDesc("Not detected in this server")
                    end
                    if (tonumber(getgenv().NNVN_VermilionAnnouncementUntil) or 0) <= os.clock() then
                        getgenv().NNVN_VermilionAnnouncementSent = false
                        maoshanMap.vermilion = false
                    end
                end
                task.wait(15)
            end
        end)
    end
    getgenv().NNVN_SendDiscordWebhook = whSend
    getgenv().NNVN_StartDiscordWebhooks = whStartAll
    stateMap8.Send = whSend
    stateMap8.Start = whStartAll
    local function resolveMatch(inputValue)
        local formattedText = (tostring(inputValue or ""):match("^([^|]+)") or tostring(inputValue or "")):gsub("^%s+", ""):gsub("%s+$", "")
        local formattedText2 = string.lower(formattedText)
        local secretBossNameSet = BossRegistry and BossRegistry.SecretBossNameSet and BossRegistry.SecretBossNameSet[formattedText2] or textHasKeyword(formattedText2, SecretBossKeywords)
        local secretBossNameSet2 = secretBossNameSet or BossRegistry and BossRegistry.BossNameSet and BossRegistry.BossNameSet[formattedText2] or textHasKeyword(formattedText2, BossKeywords)
        return formattedText, secretBossNameSet and "secret_boss" or secretBossNameSet2 and "boss" or "fish"
    end
    local function checkAttribute2()
        local data = ReplicatedStorage:FindFirstChild("Data")
        local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
        local inventory = playerData and playerData:FindFirstChild("Inventory")
        if not inventory or inventory:GetAttribute("NNVN_WebhookWatching") then
            return
        end
        inventory:SetAttribute("NNVN_WebhookWatching", true)
        inventory.ChildAdded:Connect(function(child)
            task.delay(0.35, function()
                if not child or child:GetAttribute("NNVN_VirtualDupe") == true then
                    return
                end
                if not getgenv().NNVN_WebhookEnabled or not child.Parent then
                    return
                end
                local primaryValue, secondaryValue = resolveMatch(child.Name)
                if (secondaryValue ~= "secret_boss" or not getgenv().NNVN_WebhookCatchSecretBoss) and (secondaryValue ~= "boss" or not getgenv().NNVN_WebhookCatchBoss) and (secondaryValue ~= "fish" or not getgenv().NNVN_WebhookCatchFish) then
                    return
                end
                whSend("catch:" .. secondaryValue .. ":" .. string.lower(primaryValue), {
                    eventEmoji = secondaryValue == "secret_boss" and "🌟" or secondaryValue == "boss" and "👑" or "🎣",
                    title = secondaryValue == "secret_boss" and "Secret Boss Caught" or secondaryValue == "boss" and "Boss Fish Caught" or "Fish Caught",
                    description = "Caught **" .. primaryValue .. "**.",
                    extraFields = { { name = "Fish", value = "**" .. primaryValue .. "**", inline = true } }
                })
            end)
        end)
    end
    task.defer(function()
        task.wait(2)
        pcall(whStartAll)
        pcall(startServerAgeTracker)
        pcall(resolveInsert)
        task.spawn(function()
            for i = 1, 10 do
                pcall(checkAttribute2)
                local data = ReplicatedStorage:FindFirstChild("Data")
                local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
                local inventory = playerData and playerData:FindFirstChild("Inventory")
                if inventory and inventory:GetAttribute("NNVN_WebhookWatching") then
                    return
                end
                task.wait(3)
            end
        end)
    end)
    task.spawn(function()
        local item
        while task.wait(30) do
            if not getgenv().NNVN_LegacyNetworkTracker then
            else
                local currentWeather = getCurrentWeather()
                local weatherReporterName = normalizeWeatherReporterName(currentWeather)
                if weatherReporterName == "" or weatherReporterName == "unknown" or weatherReporterName == "n/a" then
                    clearTrackerReportKeys(tostring(game.JobId) .. ":weather:")
                    item = nil
                else
                    if item ~= weatherReporterName then
                        clearTrackerReportKeys(tostring(game.JobId) .. ":weather:")
                        item = weatherReporterName
                    end
                    postHeavyweightTracker("weather", currentWeather, { source = "Weather" })
                end
                if findTrackerObject("taoist") then
                    postHeavyweightTracker("taoist", "Taoist", { source = "Workspace" })
                else
                    clearTrackerReportKeys(tostring(game.JobId) .. ":taoist:")
                end
                if findTrackerObject("maoshan") then
                    postHeavyweightTracker("maoshan", "Maoshan", { source = "Workspace" })
                else
                    clearTrackerReportKeys(tostring(game.JobId) .. ":maoshan:")
                end
                local godSpiritCount = getGodSpiritCount()
                if godSpiritCount > 0 then
                    postHeavyweightTracker("god-spirit", "God Spirit", { count = godSpiritCount, source = "Workspace" })
                else
                    clearTrackerReportKeys(tostring(game.JobId) .. ":god-spirit:")
                end
            end
        end
    end)
    premiumSignalBoardCache = {
        weather = nil,
        spirit = nil,
        taoist = nil,
        maoshan = nil,
        blacktortoise = nil,
        vermilion = nil,
        lastRefreshClock = 0,
        lastRefreshText = "Never",
        lastError = nil,
        refreshClocks = {},
        retryAfterClock = 0
    }
    premiumSignalParagraphs = {}
    premiumTrackerStatus = premiumTrackerStatus
    premiumNetworkStatusParagraph = premiumNetworkStatusParagraph
    premiumJoinCooldownAt = premiumJoinCooldownAt or 0
    premiumRelayMenuState = premiumRelayMenuState or { gui = nil, cards = {} }
    PREMIUM_SIGNAL_ORDER = {
        "weather",
        "spirit",
        "taoist",
        "maoshan",
        "blacktortoise",
        "vermilion"
    }
    PREMIUM_SIGNAL_CONFIG = {
        weather = {
            endpoint = "weather",
            title = "Weather Relay",
            feature = "Weather Tracker"
        },
        spirit = {
            endpoint = "god-spirit",
            title = "Spirit Relay",
            feature = "Spirit Tracker"
        },
        taoist = {
            endpoint = "taoist",
            title = "Taoist Relay",
            feature = "Taoist Tracker"
        },
        maoshan = {
            endpoint = "maoshan",
            title = "Maoshan Relay",
            feature = "Maoshan Tracker"
        },
        blacktortoise = {
            endpoint = "blacktortoise",
            title = "Black Tortoise Relay",
            feature = "Black Tortoise Tracker"
        },
        vermilion = {
            endpoint = "vermilion",
            title = "Vermilion Relay",
            feature = "Vermilion Tracker"
        }
    }
    getPremiumRelayTheme = function(inputValue)
        if inputValue == "weather" then
            return Color3.fromRGB(214, 219, 226), "Weather"
        elseif inputValue == "spirit" then
            return Color3.fromRGB(228, 232, 238), "Spirit"
        elseif inputValue == "taoist" then
            return Color3.fromRGB(244, 246, 248), "Taoist"
        elseif inputValue == "maoshan" then
            return Color3.fromRGB(203, 210, 219), "Maoshan"
        elseif inputValue == "blacktortoise" then
            return Color3.fromRGB(51, 255, 177), "Black Tortoise"
        elseif inputValue == "vermilion" then
            return Color3.fromRGB(255, 96, 64), "Vermilion"
        end
        return Color3.fromRGB(203, 213, 225), tostring(inputValue or "Signal")
    end
    ensurePremiumRelayMenu = function()
        if premiumRelayMenuState.gui and premiumRelayMenuState.gui.Parent then
            return premiumRelayMenuState.gui
        end
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "NNVN_PremiumRelayMenu"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.DisplayOrder = 9998
        screenGui.Enabled = false
        screenGui.Parent = CoreGui
        local frame = Instance.new("Frame")
        frame.Name = "Window"
        frame.Size = UDim2.new(0, 360, 0, 372)
        frame.Position = UDim2.new(1, -380, 0.5, -186)
        frame.BackgroundColor3 = Color3.fromRGB(236, 239, 243)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
        local uiStroke = Instance.new("UIStroke", frame)
        uiStroke.Color = Color3.fromRGB(148, 163, 184)
        uiStroke.Thickness = 1.2
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "Header"
        textLabel.BackgroundTransparency = 1
        textLabel.Position = UDim2.new(0, 16, 0, 12)
        textLabel.Size = UDim2.new(1, -96, 0, 28)
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 18
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.TextColor3 = Color3.fromRGB(32, 38, 46)
        textLabel.Text = "NNVN Premium Relay"
        textLabel.Parent = frame
        local textButton = Instance.new("TextButton")
        textButton.Name = "Close"
        textButton.Size = UDim2.new(0, 32, 0, 32)
        textButton.Position = UDim2.new(1, -44, 0, 10)
        textButton.BackgroundColor3 = Color3.fromRGB(214, 219, 226)
        textButton.TextColor3 = Color3.fromRGB(51, 65, 85)
        textButton.Text = "X"
        textButton.Font = Enum.Font.GothamBold
        textButton.TextSize = 14
        textButton.Parent = frame
        Instance.new("UICorner", textButton).CornerRadius = UDim.new(0, 10)
        textButton.MouseButton1Click:Connect(function()
            getgenv().NNVN_ShowPremiumRelayMenu = false
            screenGui.Enabled = false
        end)
        local textLabel2 = Instance.new("TextLabel")
        textLabel2.Name = "Sub"
        textLabel2.BackgroundTransparency = 1
        textLabel2.Position = UDim2.new(0, 16, 0, 42)
        textLabel2.Size = UDim2.new(1, -32, 0, 18)
        textLabel2.Font = Enum.Font.Gotham
        textLabel2.TextSize = 12
        textLabel2.TextXAlignment = Enum.TextXAlignment.Left
        textLabel2.TextColor3 = Color3.fromRGB(100, 116, 139)
        textLabel2.Text = "Waiting for live tracker data..."
        textLabel2.Parent = frame
        local scrollingFrame = Instance.new("ScrollingFrame")
        scrollingFrame.Name = "Cards"
        scrollingFrame.BackgroundTransparency = 1
        scrollingFrame.BorderSizePixel = 0
        scrollingFrame.ScrollBarThickness = 4
        scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
        scrollingFrame.Position = UDim2.new(0, 14, 0, 72)
        scrollingFrame.Size = UDim2.new(1, -28, 1, -86)
        scrollingFrame.Parent = frame
        local uiListLayout = Instance.new("UIListLayout", scrollingFrame)
        uiListLayout.Padding = UDim.new(0, 10)
        uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        premiumRelayMenuState.gui = screenGui
        premiumRelayMenuState.header = textLabel
        premiumRelayMenuState.sub = textLabel2
        premiumRelayMenuState.cards = {}
        for index, item in ipairs(PREMIUM_SIGNAL_ORDER) do
            local themeColor, themeBadge = getPremiumRelayTheme(item)
            local frame2 = Instance.new("Frame")
            frame2.Name = item
            frame2.Size = UDim2.new(1, 0, 0, 66)
            frame2.BackgroundColor3 = Color3.fromRGB(248, 250, 252)
            frame2.BorderSizePixel = 0
            frame2.LayoutOrder = index
            frame2.Parent = scrollingFrame
            Instance.new("UICorner", frame2).CornerRadius = UDim.new(0, 14)
            local uiStroke2 = Instance.new("UIStroke", frame2)
            uiStroke2.Color = themeColor
            uiStroke2.Transparency = 0.35
            uiStroke2.Thickness = 1
            local textLabel3 = Instance.new("TextLabel")
            textLabel3.BackgroundTransparency = 1
            textLabel3.Position = UDim2.new(0, 12, 0, 8)
            textLabel3.Size = UDim2.new(1, -108, 0, 18)
            textLabel3.Font = Enum.Font.GothamBold
            textLabel3.TextSize = 14
            textLabel3.TextXAlignment = Enum.TextXAlignment.Left
            textLabel3.TextColor3 = Color3.fromRGB(30, 41, 59)
            textLabel3.Text = themeBadge
            textLabel3.Parent = frame2
            local textLabel4 = Instance.new("TextLabel")
            textLabel4.BackgroundTransparency = 1
            textLabel4.Position = UDim2.new(0, 12, 0, 28)
            textLabel4.Size = UDim2.new(1, -108, 0, 28)
            textLabel4.Font = Enum.Font.Gotham
            textLabel4.TextSize = 11
            textLabel4.TextWrapped = true
            textLabel4.TextYAlignment = Enum.TextYAlignment.Top
            textLabel4.TextXAlignment = Enum.TextXAlignment.Left
            textLabel4.TextColor3 = Color3.fromRGB(100, 116, 139)
            textLabel4.Text = "Waiting for relay data..."
            textLabel4.Parent = frame2
            local textButton2 = Instance.new("TextButton")
            textButton2.Size = UDim2.new(0, 86, 0, 30)
            textButton2.Position = UDim2.new(1, -96, 0.5, -15)
            textButton2.BackgroundColor3 = themeColor
            textButton2.TextColor3 = Color3.fromRGB(35, 41, 49)
            textButton2.Text = "Join"
            textButton2.Font = Enum.Font.GothamBold
            textButton2.TextSize = 12
            textButton2.Parent = frame2
            Instance.new("UICorner", textButton2).CornerRadius = UDim.new(0, 10)
            textButton2.MouseButton1Click:Connect(function()
                joinPremiumSignal(item)
            end)
            premiumRelayMenuState.cards[item] = { detail = textLabel4, join = textButton2, accent = themeColor }
        end
        return screenGui
    end
    updatePremiumRelayMenu = function()
        local ensurePremiumRelayMenu2 = ensurePremiumRelayMenu()
        local refreshPremiumAccessResult = getgenv().NNVN_ShowPremiumRelayMenu == true and refreshPremiumAccess()
        ensurePremiumRelayMenu2.Enabled = refreshPremiumAccessResult
        if not refreshPremiumAccessResult then
            return
        end
        premiumRelayMenuState.sub.Text = string.format("Current island: %s | Weather: %s", tostring(getCurrentIslandName()), tostring(getCurrentWeather()))
        for _, item in ipairs(PREMIUM_SIGNAL_ORDER) do
            local card = premiumRelayMenuState.cards[item]
            local premiumSignalBoardCache2 = premiumSignalBoardCache[item]
            if not card then
                continue
            end
            local lookupMap = {}
            if premiumSignalBoardCache2 and trimText(premiumSignalBoardCache2.jobId) ~= "" then
                lookupMap[#lookupMap + 1] = "Job ID: " .. tostring(premiumSignalBoardCache2.jobId)
                lookupMap[#lookupMap + 1] = string.format("%s | %s/%s", tostring(premiumSignalBoardCache2.island or "Unknown"), tostring(premiumSignalBoardCache2.players or "?"), tostring(premiumSignalBoardCache2.maxPlayers or "?"))
                if item == "weather" then
                    lookupMap[#lookupMap + 1] = "Weather: " .. tostring(premiumSignalBoardCache2.weather or getgenv().NNVN_PremiumSelectedWeather)
                elseif item == "spirit" then
                    lookupMap[#lookupMap + 1] = "Spirit: " .. tostring(premiumSignalBoardCache2.count or 1)
                end
                card.join.Text = "Join"
                card.join.BackgroundColor3 = card.accent
            else
                lookupMap[#lookupMap + 1] = "No live server found yet."
                lookupMap[#lookupMap + 1] = "Waiting for users running the script."
                card.join.Text = "Waiting"
                card.join.BackgroundColor3 = Color3.fromRGB(203, 213, 225)
            end
            card.detail.Text = table.concat(lookupMap, "\n")
        end
    end
    firstNonEmptyString = function(...)
        for i = 1, select("#", ...) do
            local selectResult = select(i, ...)
            if selectResult ~= nil then
                local trimTextResult = trimText(tostring(selectResult))
                if trimTextResult ~= "" then
                    return trimTextResult
                end
            end
        end
        return nil
    end
    parseTrackerTimestamp = function(text)
        if type(text) == "number" then
            if text > 1000000000000 then
                text = text / 1000
            end
            return math.floor(text)
        end
        if type(text) == "string" then
            local parsedNum = tonumber(text)
            if parsedNum then
                if parsedNum > 1000000000000 then
                    parsedNum = parsedNum / 1000
                end
                return math.floor(parsedNum)
            end
            local ok, result = pcall(function()
                return DateTime.fromIsoDate(text)
            end)
            if ok and result then
                return result.UnixTimestamp
            end
            local yearStr, monthStr, dayStr, hourStr, minStr, secStr = text:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)[Tt ](%d%d):(%d%d):(%d%d)")
            if yearStr then
                return os.time({
                    year = tonumber(yearStr),
                    month = tonumber(monthStr),
                    day = tonumber(dayStr),
                    hour = tonumber(hourStr),
                    min = tonumber(minStr),
                    sec = tonumber(secStr)
                })
            end
        end
        return nil
    end
    isValidRelayJobId = function(inputValue)
        return trimText(inputValue):match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
    end
    formatTrackerAge = function(inputValue)
        if type(inputValue) ~= "number" then
            return "unknown"
        end
        local maxResult = math.max(0, os.time() - inputValue)
        if maxResult < 60 then
            return tostring(maxResult) .. "s ago"
        end
        if maxResult < 3600 then
            return tostring(math.floor(maxResult / 60)) .. "m ago"
        end
        return tostring(math.floor(maxResult / 3600)) .. "h ago"
    end
    extractTrackerEntries = function(inputValue)
        if type(inputValue) ~= "table" then
            return {}
        end
        if inputValue[1] ~= nil then
            return inputValue
        end
        for _, item in ipairs({
            "data",
            "items",
            "results",
            "entries",
            "reports",
            "servers",
            "active"
        }) do
            local inputValueEntry = inputValue[item]
            if type(inputValueEntry) ~= "table" then
                continue
            end
            if inputValueEntry[1] ~= nil then
                return inputValueEntry
            end
            for _, item2 in ipairs({
                "items",
                "results",
                "entries",
                "reports",
                "servers"
            }) do
                local inputValueEntryEntry = inputValueEntry[item2]
                if type(inputValueEntryEntry) == "table" and inputValueEntryEntry[1] ~= nil then
                    return inputValueEntryEntry
                end
            end
        end
        if inputValue.jobId or inputValue.JobId or inputValue.serverId or inputValue.ServerId then
            return { inputValue }
        end
        return {}
    end
    normalizeTrackerEntry = function(inputValue, secondValue)
        if type(secondValue) ~= "table" then
            return nil
        end
        local firstNonEmptyString2 = firstNonEmptyString(secondValue.jobId, secondValue.JobId, secondValue.serverId, secondValue.ServerId, secondValue.id, secondValue.ID)
        if not firstNonEmptyString2 or not isValidRelayJobId(firstNonEmptyString2) then
            return nil
        end
        return {
            signal = inputValue,
            title = PREMIUM_SIGNAL_CONFIG[inputValue] and PREMIUM_SIGNAL_CONFIG[inputValue].title or inputValue,
            jobId = firstNonEmptyString2,
            placeId = tonumber(secondValue.placeId or secondValue.PlaceId or secondValue.gameId or secondValue.GameId) or placeId,
            players = tonumber(secondValue.players or secondValue.playerCount or secondValue.currentPlayers or secondValue.onlinePlayers),
            maxPlayers = tonumber(secondValue.maxPlayers or secondValue.max_players or secondValue.serverCap or secondValue.capacity),
            ping = tonumber(secondValue.ping or secondValue.latency or secondValue.ms),
            island = firstNonEmptyString(secondValue.island, secondValue.islandName, secondValue.location, secondValue.area) or "Unknown",
            weather = firstNonEmptyString(secondValue.weather, secondValue.weatherName, secondValue.value, secondValue.name),
            value = firstNonEmptyString(secondValue.value, secondValue.event, secondValue.fish, secondValue.fishName, secondValue.name),
            count = tonumber(secondValue.count or secondValue.amount or secondValue.spiritCount),
            updatedAt = parseTrackerTimestamp(secondValue.updatedAt or secondValue.createdAt or secondValue.reportedAt or secondValue.lastSeen or secondValue.timestamp or secondValue.ts or secondValue.time),
            source = firstNonEmptyString(secondValue.source, secondValue.reportedBy, secondValue.reporter, secondValue.username) or "Network relay",
            announcement = firstNonEmptyString(secondValue.announcement, secondValue.message, secondValue.dialogue),
            live = secondValue.live == true
        }
    end
    buildLocalTrackerEntry = function(inputValue)
        local currentIslandName = getCurrentIslandName()
        local signalMap = {
            signal = inputValue,
            title = PREMIUM_SIGNAL_CONFIG[inputValue] and PREMIUM_SIGNAL_CONFIG[inputValue].title or inputValue,
            jobId = tostring(game.JobId),
            placeId = placeId,
            players = #Players:GetPlayers(),
            maxPlayers = Players.MaxPlayers,
            ping = getWeatherReporterPing(),
            island = currentIslandName,
            updatedAt = os.time(),
            source = "Current server"
        }
        if inputValue == "weather" then
            local currentWeather = getCurrentWeather()
            if normalizeWeatherReporterName(currentWeather) ~= normalizeWeatherReporterName(getgenv().NNVN_PremiumSelectedWeather) then
                return nil
            end
            signalMap.weather = currentWeather
            signalMap.value = currentWeather
            return signalMap
        end
        if inputValue == "spirit" then
            local godSpiritCount = getGodSpiritCount()
            if godSpiritCount <= 0 then
                return nil
            end
            signalMap.count = godSpiritCount
            signalMap.value = "God Spirit"
            return signalMap
        end
        if inputValue == "taoist" then
            if not findTrackerObject("taoist") then
                return nil
            end
            signalMap.value = "Taoist"
            return signalMap
        end
        if inputValue == "maoshan" then
            if not findTrackerObject("maoshan") then
                return nil
            end
            signalMap.value = "Maoshan"
            return signalMap
        end
        if inputValue == "blacktortoise" then
            local blackFindBossResult = type(blackFindBoss) == "function" and blackFindBoss() or nil
            if not blackFindBossResult and not getgenv().NNVN_BlackTortoisePresent then
                return nil
            end
            signalMap.island = tostring(getgenv().NNVN_BlackTortoiseIsland or currentIslandName)
            signalMap.value = "Black Tortoise Bloodline"
            signalMap.live = blackFindBossResult ~= nil
            return signalMap
        end
        if inputValue == "vermilion" then
            local findFirstChild6 = type(resolveFindFirstChild6) == "function" and resolveFindFirstChild6() or nil
            if not findFirstChild6 and not getgenv().NNVN_VermilionInstance then
                return nil
            end
            signalMap.value = "Vermilion Birdblood"
            signalMap.live = findFirstChild6 ~= nil
            return signalMap
        end
        return nil
    end
    fetchTrackerResponseBody = function(inputValue)
        local weatherReportRequestFunction = getWeatherReportRequestFunction()
        if type(weatherReportRequestFunction) == "function" then
            local ok, result = pcall(weatherReportRequestFunction, {
                Url = inputValue,
                Method = "GET",
                Headers = { ["Content-Type"] = "application/json", ["x-weather-key"] = relayKey }
            })
            if ok and type(result) == "table" then
                local parsedNum = tonumber(result.StatusCode or result.Status or result.status_code or result.statusCode) or 0
                local body = result.Body or result.body or result.ResponseBody
                if parsedNum >= 200 and parsedNum < 300 and type(body) == "string" then
                    return body, nil
                end
                local bodyText = tostring(body or "")
                if parsedNum == 429 or bodyText:find("error code: 1027", 1, true) then
                    return nil, "Cloudflare quota exceeded (1027/429)"
                end
                return nil, "HTTP " .. tostring(parsedNum > 0 and parsedNum or "error")
            end
            return nil, "Request failed"
        end
        return nil, "Executor request API unavailable"
    end
    fetchPremiumSignalEntries = function(inputValue)
        local configEntry = PREMIUM_SIGNAL_CONFIG[inputValue]
        if not configEntry then
            return nil, "Unknown signal"
        end
        local requestOk, responseBody = fetchTrackerResponseBody(string.format("%s/heavyweight-%s", formattedText, configEntry.endpoint))
        if not requestOk or requestOk == "" then
            return nil, responseBody or "No response"
        end
        local ok, result = pcall(function()
            return HttpService:JSONDecode(requestOk)
        end)
        if not ok then
            return nil, "Invalid tracker JSON response"
        end
        return extractTrackerEntries(result), nil
    end
    pickPremiumSignalEntry = function(inputValue, secondValue)
        local stateMap = {}
        local weatherReporterName = normalizeWeatherReporterName(getgenv().NNVN_PremiumSelectedWeather)
        for _, item in ipairs(secondValue or {}) do
            local trackerEntry = normalizeTrackerEntry(inputValue, item)
            local isAllowed = not (trackerEntry and trackerEntry.players and trackerEntry.maxPlayers and trackerEntry.maxPlayers > 0 and trackerEntry.maxPlayers <= trackerEntry.players)
            if not trackerEntry or not isAllowed or trackerEntry.placeId ~= nil and tonumber(trackerEntry.placeId) ~= tonumber(placeId) or inputValue == "weather" and normalizeWeatherReporterName(trackerEntry.weather) ~= weatherReporterName then
                continue
            end
            local computedValue = trackerEntry.updatedAt and os.time() - trackerEntry.updatedAt or nil
            if computedValue and -60 <= computedValue and computedValue <= 900 then
                table.insert(stateMap, trackerEntry)
            end
        end
        table.sort(stateMap, function(leftItem, rightItem)
            local updatedAt = leftItem.updatedAt or 0
            local updatedAt2 = rightItem.updatedAt or 0
            if updatedAt == updatedAt2 then
                return (leftItem.players or math.huge) < (rightItem.players or math.huge)
            end
            return updatedAt2 < updatedAt
        end)
        return stateMap[1]
    end
    buildPremiumSignalText = function(inputValue, secondValue)
        if not refreshPremiumAccess() then
            return table.concat({ "Status: Locked", "Premium access is required to view tracker data." }, "\n")
        end
        if not secondValue then
            return table.concat({
                "Status: No active server",
                "Filter: non-full servers, reports within 15 minutes",
                "Action: press Find Latest Server to check again"
            }, "\n")
        end
        local itemList = {
            "Status: " .. (secondValue.relayStale and "Cached report (relay retrying)" or secondValue.live and "Live spawn" or "Active report")
        }
        if inputValue == "weather" then
            itemList[#itemList + 1] = "Weather: " .. tostring(secondValue.weather or getgenv().NNVN_PremiumSelectedWeather)
        elseif inputValue == "spirit" then
            itemList[#itemList + 1] = "Name: " .. tostring(secondValue.value or "God Spirit")
            itemList[#itemList + 1] = "Spirit count: " .. tostring(secondValue.count or 1)
        elseif inputValue == "blacktortoise" then
            itemList[#itemList + 1] = "Fish: " .. tostring(secondValue.value or "Black Tortoise Bloodline")
        elseif inputValue == "vermilion" then
            itemList[#itemList + 1] = "Fish: " .. tostring(secondValue.value or "Vermilion Birdblood")
        else
            itemList[#itemList + 1] = "Name: " .. tostring(secondValue.value or secondValue.title or inputValue)
        end
        if secondValue.players and secondValue.maxPlayers then
            itemList[#itemList + 1] = string.format("Players: %d/%d", secondValue.players, secondValue.maxPlayers)
        elseif secondValue.players then
            itemList[#itemList + 1] = "Players: " .. tostring(secondValue.players)
        end
        itemList[#itemList + 1] = "Island: " .. tostring(secondValue.island or "Unknown")
        if secondValue.ping then
            itemList[#itemList + 1] = "Ping: " .. tostring(secondValue.ping) .. " ms"
        end
        if secondValue.announcement then
            itemList[#itemList + 1] = "NPC: " .. tostring(secondValue.announcement):sub(1, 140)
        end
        itemList[#itemList + 1] = "Source: " .. tostring(secondValue.source or "Network relay")
        itemList[#itemList + 1] = "Detected: " .. formatTrackerAge(secondValue.updatedAt)
        itemList[#itemList + 1] = "Place ID: " .. tostring(secondValue.placeId or placeId)
        itemList[#itemList + 1] = "Job ID: " .. tostring(secondValue.jobId)
        return table.concat(itemList, "\n")
    end
    updatePremiumSignalBoardUI = function()
        if not refreshPremiumAccess() then
            if premiumStatusParagraph then
                premiumStatusParagraph:SetDesc("Tier: FREE\nAccess: Premium required\nAll Premium tracker controls are locked")
            end
            if premiumNetworkStatusParagraph then
                premiumNetworkStatusParagraph:SetDesc("Relay Status: Locked\nUpgrade to Premium to view live server data")
            end
            if premiumTrackerStatus then
                premiumTrackerStatus:SetDesc("Current Server: Hidden\nPremium access is required")
            end
            for _, item in ipairs(PREMIUM_SIGNAL_ORDER) do
                premiumSignalBoardCache[item] = nil
                local premiumSignalParagraph = premiumSignalParagraphs[item]
                if premiumSignalParagraph then
                    premiumSignalParagraph:SetDesc(buildPremiumSignalText(item, nil))
                end
            end
            getgenv().NNVN_ShowPremiumRelayMenu = false
            pcall(updatePremiumRelayMenu)
            return
        end
        if premiumStatusParagraph then
            local refreshPremiumAccessResult = refreshPremiumAccess()
            premiumStatusParagraph:SetDesc(table.concat({
                "Tier: " .. (refreshPremiumAccessResult and "PREMIUM" or "FREE"),
                "Board: weather, spirit, taoist, maoshan, black tortoise, vermilion",
                "Join: " .. (refreshPremiumAccessResult and "enabled" or "locked")
            }, "\n"))
        end
        if premiumVipParagraph then
            local refreshPremiumAccessResult2 = refreshPremiumAccess()
            premiumVipParagraph:SetDesc(table.concat({
                refreshPremiumAccessResult2 and "Unlocked: relay menu, quick join, live signal cards" or "Locked: premium relay menu and quick join",
                refreshPremiumAccessResult2 and "Access: VIP active on this key" or "Access: FREE key detected",
                "Tracker source: live reports from users running the script"
            }, "\n"))
        end
        if premiumTrackerStatus then
            premiumTrackerStatus:SetDesc(table.concat({
                "Current island: " .. tostring(getCurrentIslandName()),
                "Current weather: " .. tostring(getCurrentWeather()),
                "Target weather: " .. tostring(getgenv().NNVN_PremiumSelectedWeather),
                "Current job: " .. tostring(game.JobId)
            }, "\n"))
        end
        if premiumNetworkStatusParagraph then
            local counter = 0
            for _, item2 in ipairs(PREMIUM_SIGNAL_ORDER) do
                if premiumSignalBoardCache[item2] then
                    counter = counter + 1
                end
            end
            local itemList = {
                "Relay refresh: " .. tostring(premiumSignalBoardCache.lastRefreshText or "Never"),
                "Signal cards online: " .. tostring(counter) .. "/" .. tostring(#PREMIUM_SIGNAL_ORDER)
            }
            if premiumSignalBoardCache.lastError then
                itemList[#itemList + 1] = "Network note: " .. tostring(premiumSignalBoardCache.lastError)
            else
                itemList[#itemList + 1] = "Network note: ok"
            end
            premiumNetworkStatusParagraph:SetDesc(table.concat(itemList, "\n"))
        end
        for _, item3 in ipairs(PREMIUM_SIGNAL_ORDER) do
            local premiumSignalParagraph2 = premiumSignalParagraphs[item3]
            if premiumSignalParagraph2 then
                premiumSignalParagraph2:SetDesc(buildPremiumSignalText(item3, premiumSignalBoardCache[item3]))
            end
        end
        pcall(updatePremiumRelayMenu)
    end
    refreshPremiumSignalBoard = function(inputValue)
        if not refreshPremiumAccess() then
            updatePremiumSignalBoardUI()
            return false
        end
        if os.clock() < (premiumSignalBoardCache.retryAfterClock or 0) then
            premiumSignalBoardCache.lastError = "Cloudflare is rate limited; waiting before retry"
            for _, item in ipairs(PREMIUM_SIGNAL_ORDER) do
                if premiumSignalBoardCache[item] then
                    premiumSignalBoardCache[item].relayStale = true
                end
            end
            updatePremiumSignalBoardUI()
            return false
        end
        if not inputValue and os.clock() - (premiumSignalBoardCache.lastRefreshClock or 0) < 75 then
            updatePremiumSignalBoardUI()
            return true
        end
        premiumSignalBoardCache.lastRefreshClock = os.clock()
        premiumSignalBoardCache.lastRefreshText = os.date("%H:%M:%S")
        premiumSignalBoardCache.lastError = nil
        local stateMap = {}
        local item2
        local isEnabled = true
        for _, item3 in ipairs(PREMIUM_SIGNAL_ORDER) do
            local primaryValue, secondaryValue = fetchPremiumSignalEntries(item3)
            local item4
            if primaryValue then
                item4 = pickPremiumSignalEntry(item3, primaryValue)
                if item4 then
                    item4.relayStale = false
                end
            elseif secondaryValue then
                stateMap[#stateMap + 1] = item3 .. ": " .. tostring(secondaryValue)
                if not item2 then
                    item2 = tostring(secondaryValue)
                elseif item2 ~= tostring(secondaryValue) then
                    isEnabled = false
                end
                if tostring(secondaryValue):find("1027/429", 1, true) then
                    premiumSignalBoardCache.retryAfterClock = os.clock() + 900
                end
            end
            if primaryValue then
                premiumSignalBoardCache[item3] = item4 or buildLocalTrackerEntry(item3)
            else
                local premiumSignalBoardCache2 = premiumSignalBoardCache[item3]
                if premiumSignalBoardCache2 then
                    premiumSignalBoardCache2.relayStale = true
                end
                premiumSignalBoardCache[item3] = premiumSignalBoardCache2 or buildLocalTrackerEntry(item3)
            end
            if os.clock() < (premiumSignalBoardCache.retryAfterClock or 0) then
                break
            end
        end
        if #stateMap > 0 then
            premiumSignalBoardCache.lastError = #stateMap == #PREMIUM_SIGNAL_ORDER and isEnabled and "All trackers: " .. tostring(item2) or table.concat(stateMap, " | ")
            if tostring(premiumSignalBoardCache.lastError):find("1027/429", 1, true) then
                premiumSignalBoardCache.retryAfterClock = os.clock() + 900
            end
        end
        updatePremiumSignalBoardUI()
        return true
    end
    refreshPremiumSignalEntry = function(inputValue, secondValue)
        if not refreshPremiumAccess() then
            updatePremiumSignalBoardUI()
            return false
        end
        if not PREMIUM_SIGNAL_CONFIG[inputValue] then
            return false
        end
        if os.clock() < (premiumSignalBoardCache.retryAfterClock or 0) then
            premiumSignalBoardCache.lastError = "Cloudflare is rate limited; waiting before retry"
            if premiumSignalBoardCache[inputValue] then
                premiumSignalBoardCache[inputValue].relayStale = true
            end
            updatePremiumSignalBoardUI()
            return false
        end
        local refreshClocks = premiumSignalBoardCache.refreshClocks
        local parsedNum = tonumber(refreshClocks[inputValue]) or 0
        if not secondValue and os.clock() - parsedNum < 120 then
            updatePremiumSignalBoardUI()
            return premiumSignalBoardCache[inputValue] ~= nil
        end
        refreshClocks[inputValue] = os.clock()
        local primaryValue, secondaryValue = fetchPremiumSignalEntries(inputValue)
        if not primaryValue then
            premiumSignalBoardCache.lastError = inputValue .. ": " .. tostring(secondaryValue or "Request failed")
            if tostring(secondaryValue):find("1027/429", 1, true) then
                premiumSignalBoardCache.retryAfterClock = os.clock() + 900
            end
            local premiumSignalBoardCache2 = premiumSignalBoardCache[inputValue]
            if premiumSignalBoardCache2 then
                premiumSignalBoardCache2.relayStale = true
            end
            updatePremiumSignalBoardUI()
            return false
        end
        local pickPremiumSignalEntry2 = pickPremiumSignalEntry(inputValue, primaryValue)
        if pickPremiumSignalEntry2 then
            pickPremiumSignalEntry2.relayStale = false
        end
        premiumSignalBoardCache[inputValue] = pickPremiumSignalEntry2 or buildLocalTrackerEntry(inputValue)
        premiumSignalBoardCache.lastRefreshClock = os.clock()
        premiumSignalBoardCache.lastRefreshText = os.date("%H:%M:%S")
        premiumSignalBoardCache.lastError = nil
        updatePremiumSignalBoardUI()
        return premiumSignalBoardCache[inputValue] ~= nil
    end
    joinPremiumSignal = function(inputValue)
        local configEntry = PREMIUM_SIGNAL_CONFIG[inputValue]
        if not configEntry then
            return false
        end
        if not ensurePremiumAccess(configEntry.feature) then
            return false
        end
        if not refreshPremiumSignalEntry(inputValue, true) then
            return false
        end
        local premiumSignalBoardCache2 = premiumSignalBoardCache[inputValue]
        if not premiumSignalBoardCache2 or premiumSignalBoardCache2.relayStale or not isValidRelayJobId(premiumSignalBoardCache2.jobId) then
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Premium",
                    Content = "No relay server found for " .. tostring(configEntry.title) .. ".",
                    Duration = 3,
                    Icon = "radar"
                })
            end
            return false
        end
        if tostring(premiumSignalBoardCache2.jobId) == tostring(game.JobId) then
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Premium",
                    Content = "You are already in that server.",
                    Duration = 2,
                    Icon = "shield-check"
                })
            end
            return true
        end
        if tick() - premiumJoinCooldownAt < 8 then
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Premium",
                    Content = "Join cooldown active. Wait a moment.",
                    Duration = 2,
                    Icon = "timer-reset"
                })
            end
            return false
        end
        premiumJoinCooldownAt = tick()
        getgenv().NNVN_JobIdInput = tostring(premiumSignalBoardCache2.jobId)
        if getgenv().NNVN_Notify then
            item:Notify({
                Title = "Premium",
                Content = "Joining " .. tostring(configEntry.title) .. "...",
                Duration = 3,
                Icon = "log-in"
            })
        end
        local ok, result = pcall(function()
            TeleportService:TeleportToPlaceInstance(tonumber(premiumSignalBoardCache2.placeId) or placeId, tostring(premiumSignalBoardCache2.jobId), LocalPlayer)
        end)
        if not ok then
            premiumJoinCooldownAt = 0
            premiumSignalBoardCache.lastError = "Teleport failed: " .. tostring(result)
            updatePremiumSignalBoardUI()
            return false
        end
        return true
    end
    premiumOverviewSec = mainMap.Hop:AddSection({ Title = "[PREMIUM] Premium Relay", Icon = "crown" })
    premiumStatusParagraph = premiumOverviewSec:AddParagraph({ Title = "Access", Content = "Checking premium access..." })
    premiumNetworkStatusParagraph = premiumOverviewSec:AddParagraph({ Title = "Relay Status", Content = "Waiting for the first refresh..." })
    premiumTrackerStatus = premiumOverviewSec:AddParagraph({
        Title = "Current Server",
        Content = "Collecting local server information..."
    })
    premiumOverviewSec:AddButton({
        Title = "Refresh All Trackers",
        Icon = "refresh-cw",
        Locked = not refreshPremiumAccess(),
        Callback = function()
            if not ensurePremiumAccess("Premium Relay") then
                return
            end
            refreshPremiumSignalBoard(true)
        end
    })
    addPremiumTrackerSection = function(inputValue, secondValue, thirdValue, fourthValue, fifthValue)
        local section = mainMap.Hop:AddSection({ Title = "[PREMIUM] " .. secondValue, Icon = thirdValue })
        premiumSignalParagraphs[inputValue] = section:AddParagraph({
            Title = "Latest Server",
            Content = buildPremiumSignalText(inputValue, premiumSignalBoardCache[inputValue])
        })
        if inputValue == "weather" then
            section:AddDropdown("NNVN_PremiumWeatherDropdown", {
                Title = "Weather",
                Values = PREMIUM_WEATHER_OPTIONS,
                Default = getgenv().NNVN_PremiumSelectedWeather,
                Locked = not refreshPremiumAccess(),
                Callback = function(enabled)
                    if not ensurePremiumAccess("Weather Tracker") then
                        return
                    end
                    getgenv().NNVN_PremiumSelectedWeather = tostring(enabled or "Clear")
                    premiumSignalBoardCache.weather = nil
                    refreshPremiumSignalEntry("weather", true)
                end
            })
        end
        if fourthValue then
            section:AddToggle(fourthValue, {
                Title = fifthValue,
                Default = getgenv()[fourthValue] == true and refreshPremiumAccess() or false,
                Locked = not refreshPremiumAccess(),
                Callback = function(selectedValue)
                    if selectedValue and not ensurePremiumAccess(secondValue) then
                        getgenv()[fourthValue] = false
                        return
                    end
                    getgenv()[fourthValue] = selectedValue == true
                end
            })
        end
        section:AddButton({
            Title = "Find Latest Server",
            Icon = "search",
            Locked = not refreshPremiumAccess(),
            Callback = function()
                if not ensurePremiumAccess(secondValue) then
                    return
                end
                refreshPremiumSignalEntry(inputValue, true)
            end
        })
        section:AddButton({
            Title = "Join Latest Server",
            Icon = "log-in",
            Locked = not refreshPremiumAccess(),
            Callback = function()
                if not ensurePremiumAccess(secondValue) then
                    return
                end
                joinPremiumSignal(inputValue)
            end
        })
        return section
    end
    premiumWeatherSec = addPremiumTrackerSection("weather", "Weather", "cloud-sun", "NNVN_PremiumWeatherEnabled", "Auto Join Selected Weather")
    premiumSpiritSec = addPremiumTrackerSection("spirit", "God Spirit", "sparkles", "NNVN_PremiumSpiritEnabled", "Auto Join God Spirit")
    premiumTaoistSec = addPremiumTrackerSection("taoist", "Taoist", "user-round-search", "NNVN_PremiumTaoistEnabled", "Auto Join Taoist")
    premiumMaoshanSec = addPremiumTrackerSection("maoshan", "Maoshan", "scan-search", "NNVN_PremiumMaoshanEnabled", "Auto Join Maoshan")
    premiumBlackTortoiseSec = addPremiumTrackerSection("blacktortoise", "Black Tortoise Bloodline", "shield", nil, nil)
    premiumVermilionSec = addPremiumTrackerSection("vermilion", "Vermilion Birdblood", "flame", nil, nil)
    task.defer(function()
        task.wait(1)
        pcall(updatePremiumSignalBoardUI)
    end)
    matCo = nil
    materialCurrentTarget = nil
    matSec:AddToggle("NNVN_MaterialFarming", {
        Title = "Auto Farm Materials",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_MaterialFarming = enabled
            if enabled then
                getgenv().NNVN_MaterialRodFarming = false
                if matCo then
                    coroutine.close(matCo)
                    matCo = nil
                end
                matCo = coroutine.create(function()
                    while getgenv().NNVN_MaterialFarming do
                        pcall(function()
                            if selectedMatBait == "Nameless Bait" then
                                local character = LocalPlayer.Character
                                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                                if rootPart and NAMELESS_BAIT_FARM_CFRAME and (rootPart.Position - NAMELESS_BAIT_FARM_CFRAME.Position).Magnitude > 5 then
                                    if character:GetAttribute("Fishing") then
                                        matCancelFishing()
                                        task.wait(0.1)
                                    end
                                    NNVN_TweenTo(NAMELESS_BAIT_FARM_CFRAME)
                                end
                                matEnableFishing()
                                materialCurrentTarget = "Nameless Bait"
                                return
                            end
                            local recipe = BAIT_RECIPES[selectedMatBait]
                            if not recipe or #recipe == 0 then
                                return
                            end
                            local item2
                            local huge = math.huge
                            for _, item3 in ipairs(recipe) do
                                local matGetMaterialCount2 = matGetMaterialCount(item3.name, item3.minKg, item3.maxKg)
                                if matGetMaterialCount2 < huge then
                                    huge = matGetMaterialCount2
                                    item2 = item3
                                end
                            end
                            if not item2 then
                                return
                            end
                            local name = item2.name
                            local formattedText = string.lower(getCurrentWeather())
                            local requiredEntry = MAT_WEATHER_REQUIRED[name]
                            if requiredEntry then
                                local hasTriggered = false
                                for entryKey in pairs(requiredEntry.weathers) do
                                    if formattedText == entryKey then
                                        hasTriggered = true
                                    end
                                end
                                if not hasTriggered then
                                    materialCurrentTarget = nil
                                    item:Notify({
                                        Title = "Material",
                                        Content = name .. " requires " .. requiredEntry.label .. ". Waiting...",
                                        Duration = 3
                                    })
                                    task.wait(5)
                                    return
                                end
                                local cframeEntry = MAT_FISH_CFRAME[name]
                                local character2 = LocalPlayer.Character
                                local rootPart2 = character2 and character2:FindFirstChild("HumanoidRootPart")
                                if cframeEntry and rootPart2 then
                                    if (rootPart2.Position - cframeEntry.Position).Magnitude > 5 then
                                        if character2:GetAttribute("Fishing") then
                                            matCancelFishing()
                                            task.wait(0.1)
                                        end
                                        NNVN_TweenTo(cframeEntry)
                                    end
                                else
                                    matTeleportToIsland(requiredEntry.island)
                                end
                                matEnableFishing()
                                materialCurrentTarget = name
                                return
                            end
                            local matGetIslandsFor = matGetIslandsForFish(name)
                            if #matGetIslandsFor == 0 then
                                return
                            end
                            local matIslandNameTo = matIslandNameToIsland[matGetIslandsFor[1]]
                            if not matIslandNameTo then
                                return
                            end
                            local character3 = LocalPlayer.Character
                            local rootPart3 = character3 and character3:FindFirstChild("HumanoidRootPart")
                            if not rootPart3 then
                                return
                            end
                            if (rootPart3.Position - matIslandNameTo.cf.Position).Magnitude > 5 then
                                if character3:GetAttribute("Fishing") then
                                    matCancelFishing()
                                    task.wait(0.1)
                                end
                                matTeleportToIsland(matGetIslandsFor[1])
                            end
                            matEnableFishing()
                            materialCurrentTarget = name
                        end)
                        task.wait(0.5)
                    end
                    matDisableFishing()
                end)
                coroutine.resume(matCo)
            else
                if matCo then
                    coroutine.close(matCo)
                    matCo = nil
                end
                matDisableFishing()
                materialCurrentTarget = nil
                item:Notify({ Title = "Material", Content = "Stopped", Duration = 2 })
            end
        end
    })
end

do
    rodMatSec = mainMap.Bait:AddSection({ Title = "Craft Rod", Icon = "anvil" })
    rodMatSec:AddParagraph({
        Title = "Info",
        Content = "Farm the required fish weights for rod crafting."
    })
    matRodOptions = { "Heavenpiercer Rod", "Pure Diamond Rod", "Sacred Bamboo Rod" }
    selectedMatRod = getgenv().NNVN_MaterialRod or "Heavenpiercer Rod"
    rodMatSec:AddDropdown("NNVN_MaterialRod", {
        Title = "Select Rod to Craft",
        Values = matRodOptions,
        Default = selectedMatRod,
        Callback = function(selected)
            getgenv().NNVN_MaterialRod = selected or "Heavenpiercer Rod"
            selectedMatRod = getgenv().NNVN_MaterialRod
        end
    })
    rodMatSec:AddToggle("NNVN_MaterialRodFarming", {
        Title = "Auto Farm Materials",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_MaterialRodFarming = enabled
            if enabled then
                getgenv().NNVN_MaterialFarming = false
                local selectedMatRod2 = selectedMatRod or getgenv().NNVN_MaterialRod or "Heavenpiercer Rod"
                selectedMatBait = selectedMatRod2
                getgenv().NNVN_MaterialBait = selectedMatRod2
                if matCo then
                    coroutine.close(matCo)
                    matCo = nil
                end
                matCo = coroutine.create(function()
                    while getgenv().NNVN_MaterialRodFarming do
                        pcall(function()
                            local selectedMatRod2 = selectedMatRod or getgenv().NNVN_MaterialRod or "Heavenpiercer Rod"
                            selectedMatBait = selectedMatRod2
                            getgenv().NNVN_MaterialBait = selectedMatRod2
                            local recipe = BAIT_RECIPES[selectedMatBait]
                            if not recipe or #recipe == 0 then
                                return
                            end
                            local item2
                            local huge = math.huge
                            for _, item3 in ipairs(recipe) do
                                local matGetMaterialCount2 = matGetMaterialCount(item3.name, item3.minKg, item3.maxKg)
                                if matGetMaterialCount2 < huge then
                                    huge = matGetMaterialCount2
                                    item2 = item3
                                end
                            end
                            if not item2 then
                                return
                            end
                            local name = item2.name
                            local formattedText = string.lower(getCurrentWeather())
                            local requiredEntry = MAT_WEATHER_REQUIRED[name]
                            if requiredEntry then
                                local hasTriggered = false
                                for entryKey in pairs(requiredEntry.weathers) do
                                    if formattedText == entryKey then
                                        hasTriggered = true
                                    end
                                end
                                if not hasTriggered then
                                    materialCurrentTarget = nil
                                    item:Notify({
                                        Title = "Material Rod",
                                        Content = name .. " requires " .. requiredEntry.label .. ". Waiting...",
                                        Duration = 3
                                    })
                                    task.wait(5)
                                    return
                                end
                                local cframeEntry = MAT_FISH_CFRAME[name]
                                local character = LocalPlayer.Character
                                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                                if cframeEntry and rootPart then
                                    if (rootPart.Position - cframeEntry.Position).Magnitude > 5 then
                                        if character:GetAttribute("Fishing") then
                                            matCancelFishing()
                                            task.wait(0.1)
                                        end
                                        NNVN_TweenTo(cframeEntry)
                                    end
                                else
                                    matTeleportToIsland(requiredEntry.island)
                                end
                                matEnableFishing()
                                materialCurrentTarget = name
                                return
                            end
                            local matGetIslandsFor = matGetIslandsForFish(name)
                            if #matGetIslandsFor == 0 then
                                return
                            end
                            local matIslandNameTo = matIslandNameToIsland[matGetIslandsFor[1]]
                            if not matIslandNameTo then
                                return
                            end
                            local character2 = LocalPlayer.Character
                            local rootPart2 = character2 and character2:FindFirstChild("HumanoidRootPart")
                            if not rootPart2 then
                                return
                            end
                            if (rootPart2.Position - matIslandNameTo.cf.Position).Magnitude > 5 then
                                if character2:GetAttribute("Fishing") then
                                    matCancelFishing()
                                    task.wait(0.1)
                                end
                                matTeleportToIsland(matGetIslandsFor[1])
                            end
                            matEnableFishing()
                            materialCurrentTarget = name
                        end)
                        task.wait(0.5)
                    end
                    matDisableFishing()
                end)
                coroutine.resume(matCo)
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Material Rod",
                        Content = "Auto farm materials for rod enabled",
                        Duration = 2
                    })
                end
            else
                if matCo then
                    coroutine.close(matCo)
                    matCo = nil
                end
                matDisableFishing()
                materialCurrentTarget = nil
                if getgenv().NNVN_Notify then
                    item:Notify({ Title = "Material Rod", Content = "Stopped", Duration = 2 })
                end
            end
        end
    })
    craftSec = mainMap.Bait:AddSection({ Title = "Craft Bait", Icon = "hammer" })
    craftSec:AddParagraph({
        Title = "Info",
        Content = "Craft selected bait at the bait seller. Quantity is clamped from 1 to 100."
    })
    craftBaitOptions = { "Rainbow Bait", "Frost Bait", "Nameless Bait" }
    selectedCraftBait = getgenv().NNVN_CraftBaitName or "Rainbow Bait"
    craftSec:AddDropdown("NNVN_CraftBaitName", {
        Title = "Select Bait",
        Values = craftBaitOptions,
        Default = selectedCraftBait,
        Callback = function(selected)
            selectedCraftBait = selected or "Rainbow Bait"
            getgenv().NNVN_CraftBaitName = selectedCraftBait
        end
    })
    craftSec:AddInput("NNVN_CraftBaitQuantityInput", {
        Title = "Craft Quantity",
        Placeholder = "1 - 100",
        Default = tostring(getgenv().NNVN_CraftBaitQuantity or 1),
        Callback = function(selectedValue)
            craftAmount = math.clamp(math.floor(tonumber(selectedValue) or 1), 1, 100)
            getgenv().NNVN_CraftBaitQuantity = craftAmount
        end
    })
    CraftSelectedBait = function(inputValue)
        craftAmount = math.clamp(math.floor(tonumber(inputValue) or getgenv().NNVN_CraftBaitQuantity or 1), 1, 100)
        craftName = selectedCraftBait or getgenv().NNVN_CraftBaitName or "Rainbow Bait"
        RunActionWithMethod({ teleport = TPNearBaitSeller, returnAfter = true }, function()
            task.wait(0.25)
            ReplicatedStorage.Events.CraftBait:FireServer(craftName, craftAmount)
            task.wait(0.25)
        end)
    end
    craftSec:AddButton({
        Title = "Craft Once",
        Callback = function()
            CraftSelectedBait(getgenv().NNVN_CraftBaitQuantity or 1)
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Craft Bait",
                    Content = "Crafted " .. tostring(getgenv().NNVN_CraftBaitQuantity or 1) .. "x " .. tostring(selectedCraftBait or "Rainbow Bait"),
                    Duration = 2
                })
            end
        end
    })
    craftSec:AddToggle("NNVN_AutoCraftBait", {
        Title = "Auto Craft Bait",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoCraftBait = enabled
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Craft Bait",
                    Content = enabled and "Auto craft enabled" or "Auto craft disabled",
                    Duration = 2
                })
            end
        end
    })
    if not getgenv().NNVN_AutoCraftBaitLoop then
        getgenv().NNVN_AutoCraftBaitLoop = true
        task.spawn(function()
            while task.wait(3) do
                if getgenv().NNVN_AutoCraftBait then
                    CraftSelectedBait(getgenv().NNVN_CraftBaitQuantity or 1)
                end
            end
        end)
    end
    sellSec = mainMap.Sell:AddSection({ Title = "Auto Sell Fish", Icon = "shopping-bag" })
    sellSec:AddToggle("NNVN_AutoSell", {
        Title = "Auto Sell All Fish",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoSell = enabled
            if enabled and type(getgenv().NNVN_RequestAutoSellCheck) == "function" then
                getgenv().NNVN_RequestAutoSellCheck(true)
            end
            if enabled and getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Auto Sell",
                    Content = "Enabled (every " .. (getgenv().NNVN_SellDelay or 5) .. "s)",
                    Duration = 2
                })
            end
        end
    })
    sellSec:AddToggle("NNVN_AutoSellNormalFish", {
        Title = "Auto Sell Normal Fish",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoSellNormalFish = enabled
        end
    })
    sellSec:AddToggle("NNVN_AutoSellOnlyBoss", {
        Title = "Auto Sell Only Boss",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoSellOnlyBoss = enabled
        end
    })
    sellSec:AddToggle("NNVN_AutoSellOnlySecretBoss", {
        Title = "Auto Sell Only Secret Boss",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoSellOnlySecretBoss = enabled
        end
    })
    sellSec:AddToggle("NNVN_AutoSellWhenFull", {
        Title = "Auto Sell When Full Backpack",
        Description = "Checks the backpack counter and inventory data, then sells only after capacity is full.",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoSellWhenFull = enabled
            if enabled and type(getgenv().NNVN_RequestAutoSellCheck) == "function" then
                getgenv().NNVN_RequestAutoSellCheck(false)
            end
        end
    })
    sellSec:AddDropdown("NNVN_SellActionMethod", {
        Title = "Sell Movement Method",
        Description = "Tween travels to the NPC. Instant sends the sell remote directly.",
        Values = { "Tween [Safe]", "Instant [Risk]" },
        Default = tostring(getgenv().NNVN_SellActionMethod):find("Instant", 1, true) and "Instant [Risk]" or "Tween [Safe]",
        Callback = function(amount)
            amount = NormalizeTranslatedChoice(amount, "Tween [Safe]")
            getgenv().NNVN_SellActionMethod = tostring(amount):find("Instant", 1, true) and "Instant [Risk]" or "Tween [Safe]"
        end
    })
    sellSec:AddSlider("NNVN_SellDelayMinutes", {
        Title = "Sell Interval Minutes",
        Description = "Minutes to wait between auto-sell checks. Right-click or double-tap the slider value to type a number.",
        Default = tonumber(getgenv().NNVN_SellDelayMinutes) or 0,
        Min = 0,
        Max = 60,
        Rounding = 1,
        AllowRightClickInput = true,
        Callback = function(amount)
            getgenv().NNVN_SellDelayMinutes = math.max(0, math.floor(tonumber(amount) or 0))
        end
    })
    sellSec:AddSlider("NNVN_SellDelaySeconds", {
        Title = "Sell Interval Seconds",
        Description = "Extra seconds to wait. Right-click or double-tap the slider value to type a number.",
        Default = tonumber(getgenv().NNVN_SellDelaySeconds) or 5,
        Min = 0,
        Max = 59,
        Rounding = 1,
        AllowRightClickInput = true,
        Callback = function(selectedValue)
            getgenv().NNVN_SellDelaySeconds = math.max(0, math.floor(tonumber(selectedValue) or 0))
        end
    })
    sellSec:AddButton({
        Title = "Sell All Fish Now",
        Callback = function()
            task.spawn(function()
                if type(getgenv().NNVN_SellFishMode) == "function" then
                    getgenv().NNVN_SellFishMode("All")
                end
                if getgenv().NNVN_Notify then
                    item:Notify({ Title = "Sell", Content = "Sold all fish!", Duration = 2 })
                end
            end)
        end
    })
    sellSec:AddButton({
        Title = "Teleport to Nana (Sell NPC)",
        Callback = function()
            pcall(function()
                TeleportToNPCWithFallback("Nana")
            end)
        end
    })
    weatherIslands = {
        foggy = "Coconut Isle",
        ["blazing sun"] = "Amber Isle",
        snowy = "Frost Isle",
        windy = "Perch Isle",
        rainy = "Fallout Isle",
        thunderstorm = "Bamboo Isle"
    }
    islandTpSec = mainMap.Teleport:AddSection({ Title = "Island Teleport", Icon = "map" })
    islandNames = {}
    for _, item29 in ipairs(TeleportList) do
        table.insert(islandNames, item29.name)
    end
    selectedIslandName = islandNames[1] or "Beginning Isle"
    islandTpSec:AddDropdown("NNVN_IslandTeleport", {
        Title = "Select Island",
        Values = islandNames,
        Default = selectedIslandName,
        Callback = function(selected)
            selectedIslandName = selected or selectedIslandName
        end
    })
    islandTpSec:AddButton({
        Title = "Teleport to Selected Island",
        Callback = function()
            if not selectedIslandName then
                return
            end
            matTeleportToIsland(selectedIslandName)
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Teleport",
                    Content = "Teleported to " .. selectedIslandName,
                    Duration = 2
                })
            end
        end
    })
    islandTpSec:AddButton({
        Title = "Teleport To Current Weather Island",
        Callback = function()
            local currentWeather = getCurrentWeather()
            local weatherIsland = weatherIslands[currentWeather:lower()]
            if not weatherIsland then
                item:Notify({ Title = "", Content = "No special weather active", Duration = 2 })
                return
            end
            for _, item2 in ipairs(TeleportList) do
                if item2.name:lower() ~= weatherIsland:lower() then
                    continue
                end
                TeleportToCFrame(item2.cf)
                item:Notify({
                    Title = "",
                    Content = "Teleported to " .. weatherIsland .. " for " .. currentWeather,
                    Duration = 3
                })
                return
            end
            item:Notify({ Title = "", Content = "Unknown weather mapping", Duration = 2 })
        end
    })
    jobIdSec = mainMap.Teleport:AddSection({ Title = "Server Hop by Job ID", Icon = "server" })
    lastHopAt = 0
    jobIdSec:AddButton({
        Title = "Copy Current Job ID",
        Icon = "copy",
        Callback = function()
            local callOk = pcall(function()
                setclipboard(tostring(game.JobId))
            end)
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Job ID",
                    Content = callOk and "Copied current server Job ID." or "Clipboard is unavailable.",
                    Duration = 2
                })
            end
        end
    })
    jobIdSec:AddInput("NNVN_JobIdInput", {
        Title = "Enter Job ID",
        Placeholder = "Paste Job ID here...",
        Default = "",
        Callback = function(inputText)
            if not inputText or inputText == "" then
                return
            end
            local inputText2 = inputText
            local abcdefghijklmnopqrstuvwxyZabcdefghijklmnopqrstuvwxyz0123456789Label = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
            local function resolveGsub(text)
                text = string.gsub(text, "[^" .. abcdefghijklmnopqrstuvwxyZabcdefghijklmnopqrstuvwxyz0123456789Label .. "=]", "")
                return text:gsub(".", function(inputValue)
                    if inputValue == "=" then
                        return ""
                    end
                    local labelText = ""
                    local computedValue = abcdefghijklmnopqrstuvwxyZabcdefghijklmnopqrstuvwxyz0123456789Label:find(inputValue, 1, true) - 1
                    for i = 6, 1, -1 do
                        labelText = labelText .. (computedValue % 2 ^ i - computedValue % 2 ^ (i - 1) > 0 and "1" or "0")
                    end
                    return labelText
                end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(text)
                    if #text ~= 8 then
                        return ""
                    end
                    local counter = 0
                    for i = 1, 8 do
                        counter = counter + (text:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
                    end
                    return string.char(counter)
                end)
            end
            local matchedText = string.match(inputText, "NNVNHUB|([^%s]+)")
            if matchedText then
                local ok, result = pcall(resolveGsub, matchedText)
                if ok and type(result) == "string" and result ~= "" then
                    inputText2 = result
                end
            end
            if inputText2 == game.JobId then
                item:Notify({ Title = "", Content = "Already in this server.", Duration = 2 })
                return
            end
            if tick() - lastHopAt < 30 then
                item:Notify({ Title = "", Content = "Hop cooldown (30s)", Duration = 2 })
                return
            end
            lastHopAt = tick()
            item:Notify({ Title = "", Content = "Joining server...", Duration = 3 })
            TeleportService:TeleportToPlaceInstance(placeId, inputText2, LocalPlayer)
        end
    })
    secretRodData = {
        {
            name = "Ascendant Bamboo Rod",
            price = 15,
            cf = CFrame.new(-1360.65027, 140.561218, 31.0494728)
        },
        {
            name = "Blazeshark Rod",
            price = 35,
            cf = CFrame.new(-8.43965149, 53.8742065, 6.65357065)
        },
        {
            name = "Lifebloom Rod",
            price = 75,
            cf = CFrame.new(-114.889297, 74.8509827, -1533.19177)
        },
        {
            name = "Anchorbound Rod",
            price = 200,
            cf = CFrame.new(-1208.55396, 56.3270988, 1646.20764)
        },
        {
            name = "Demonic Rod",
            price = 300,
            cf = CFrame.new(1181.90454, 82.8990021, -1243.75549)
        },
        {
            name = "Kraken Rod",
            price = 500,
            cf = CFrame.new(1543.79529, 73.4329834, 1490.93457)
        }
    }
    secretRodTpSec = mainMap.Teleport:AddSection({ Title = "Secret Rod Locations", Icon = "key" })
    for _, item30 in ipairs(secretRodData) do
        secretRodTpSec:AddButton({
            Title = "" .. item30.name,
            Callback = function()
                pcall(function()
                    TeleportToCFrame(item30.cf)
                end)
            end
        })
    end
    npcSection = mainMap.Teleport:AddSection({ Title = "NPC Teleport", Icon = "users" })
    selectedNPCs = {}
    NPCGroupDefinitions = {
        { title = "Spawn Boat", folder = "SetSpawn" },
        { title = "Sell Fish", folder = "SellFish" },
        { title = "Buy Fishing Rod", folder = "BuyFishingRod" },
        { title = "Boss", folder = "Boss" },
        { title = "Buy Bait", folder = "BuyBait" },
        { title = "Misc NPCs", folder = "Function" }
    }
    NPCGroupInstances = {}
    NPCGroupDropdowns = {}
    GetNPCFolderChoices = function(inputValue, secondValue)
        local nameList = { "Select..." }
        local stateMap = {}
        NPCGroupInstances[inputValue] = stateMap
        local npcFolder = Workspace:FindFirstChild("NPC")
        local npcFolderEntry = npcFolder and npcFolder:FindFirstChild(secondValue)
        if not npcFolderEntry then
            return nameList
        end
        local stateMap2 = {}
        for _, item in ipairs(npcFolderEntry:GetChildren()) do
            local rootPart = item:FindFirstChild("HumanoidRootPart", true)
            if rootPart and rootPart:IsA("BasePart") then
                table.insert(stateMap2, item)
            end
        end
        table.sort(stateMap2, function(leftItem, rightItem)
            if string.lower(leftItem.Name) == string.lower(rightItem.Name) then
                return leftItem:GetFullName() < rightItem:GetFullName()
            end
            return string.lower(leftItem.Name) < string.lower(rightItem.Name)
        end)
        local stateMap3 = {}
        for _, item2 in ipairs(stateMap2) do
            local name = item2.Name
            local islandForTarget = type(getIslandForTarget) == "function" and getIslandForTarget(item2) or nil
            if islandForTarget and islandForTarget ~= "" and islandForTarget ~= "Unknown" then
                name = name .. " • " .. islandForTarget
            end
            local name2 = name
            local stepIndex = 2
            while stateMap3[name] do
                name = name2 .. " #" .. stepIndex
                stepIndex = stepIndex + 1
            end
            stateMap3[name] = true
            stateMap[name] = item2
            table.insert(nameList, name)
        end
        return nameList
    end
    TeleportToNPCFolderItem = function(inputValue, secondValue)
        local npcGroupInstanceEntry = NPCGroupInstances[inputValue] and NPCGroupInstances[inputValue][secondValue]
        local rootPart = npcGroupInstanceEntry and npcGroupInstanceEntry:FindFirstChild("HumanoidRootPart", true)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") or not rootPart or not rootPart:IsA("BasePart") then
            return false
        end
        NNVN_TweenTo(rootPart.CFrame * CFrame.new(0, 2, 3))
        return true
    end
    GetOtherPlayerNames = function()
        local stateMap = {}
        for _, item in ipairs(Players:GetPlayers()) do
            if item ~= LocalPlayer then
                table.insert(stateMap, item.Name)
            end
        end
        table.sort(stateMap, function(leftItem, rightItem)
            return string.lower(leftItem) < string.lower(rightItem)
        end)
        if #stateMap == 0 then
            table.insert(stateMap, "No Players")
        end
        return stateMap
    end
    TeleportToPlayerByName = function(inputValue)
        if not inputValue or inputValue == "" or inputValue == "No Players" then
            return false
        end
        local playersEntry = Players:FindFirstChild(inputValue)
        local character = playersEntry and playersEntry.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local character2 = LocalPlayer.Character
        if not character2 or not character2:FindFirstChild("HumanoidRootPart") or not rootPart then
            return false
        end
        pcall(function()
            NNVN_TweenTo(rootPart.CFrame * CFrame.new(0, 0, 3) + Vector3.new(0, 2, 0))
        end)
        return true
    end
    for _, item31 in ipairs(NPCGroupDefinitions) do
        local title = item31.title
        NPCGroupDropdowns[title] = npcSection:AddDropdown("NPC_" .. title, {
            Title = title,
            Values = GetNPCFolderChoices(title, item31.folder),
            Default = "Select...",
            Callback = function(selectedValue)
                selectedNPCs[title] = selectedValue
            end
        })
        npcSection:AddButton({
            Title = "Teleport to Select NPC",
            Callback = function()
                local selectedNpC = selectedNPCs[title]
                if selectedNpC and selectedNpC ~= "Select..." and not TeleportToNPCFolderItem(title, selectedNpC) and getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "NPC Teleport",
                        Content = "NPC is no longer available.",
                        Duration = 2
                    })
                end
            end
        })
    end
    npcSection:AddButton({
        Title = "Refresh NPC Lists",
        Icon = "refresh-cw",
        Callback = function()
            for _, item in ipairs(NPCGroupDefinitions) do
                local npcFolderChoices = GetNPCFolderChoices(item.title, item.folder)
                selectedNPCs[item.title] = "Select..."
                local npcGroupDropdown = NPCGroupDropdowns[item.title]
                if npcGroupDropdown and npcGroupDropdown.Refresh then
                    npcGroupDropdown:Refresh(npcFolderChoices)
                elseif npcGroupDropdown and npcGroupDropdown.SetValues then
                    npcGroupDropdown:SetValues(npcFolderChoices)
                end
                if npcGroupDropdown and npcGroupDropdown.SetValue then
                    npcGroupDropdown:SetValue("Select...")
                end
            end
        end
    })
    local playerTeleportSection = mainMap.Teleport:AddSection({ Title = "Player Teleport", Icon = "user" })
    local noPlayersLabel = "No Players"
    local teleportplayertargetDropdown = playerTeleportSection:AddDropdown("NNVN_TeleportPlayerTarget", {
        Title = "Select Player",
        Values = GetOtherPlayerNames(),
        Default = "No Players",
        Callback = function(selected)
            noPlayersLabel = selected
        end
    })
    playerTeleportSection:AddButton({
        Title = "Refresh Player List",
        Callback = function()
            local otherPlayerNames = GetOtherPlayerNames()
            if teleportplayertargetDropdown and teleportplayertargetDropdown.Refresh then
                teleportplayertargetDropdown:Refresh(otherPlayerNames)
            end
            if #otherPlayerNames > 0 then
                noPlayersLabel = otherPlayerNames[1]
            end
        end
    })
    playerTeleportSection:AddButton({
        Title = "Teleport to Selected Player",
        Callback = function()
            local teleportToPlayerBy = TeleportToPlayerByName(noPlayersLabel)
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Teleport Player",
                    Content = teleportToPlayerBy and "Teleported to " .. noPlayersLabel or "Could not teleport to that player",
                    Duration = 3
                })
            end
        end
    })
    addSpecialTeleportSection = function(control, secondValue, thirdValue, fourthValue)
        local section = control:AddSection({ Title = "" .. secondValue .. " Teleport", Icon = "map-pin" })
        local statusParagraph = section:AddParagraph({ Title = "Status", Content = "🔴 Offline" })
        local item
        section:AddToggle("AutoCheck" .. secondValue, {
            Title = "Auto Check Status",
            Default = false,
            Callback = function(enabled)
                if enabled then
                    if item then
                        coroutine.close(item)
                        item = nil
                    end
                    item = coroutine.create(function()
                        while true do
                            local fourthValueResult = fourthValue and fourthValue() or ObjectExists(thirdValue)
                            pcall(function()
                                statusParagraph:SetDesc(fourthValueResult and "🟢 Online - " .. secondValue .. " is here!" or "🔴 Offline")
                            end)
                            task.wait(3)
                        end
                    end)
                    coroutine.resume(item)
                else
                    if item then
                        coroutine.close(item)
                        item = nil
                    end
                    pcall(function()
                        statusParagraph:SetDesc("🔴 Offline")
                    end)
                end
            end
        })
        section:AddButton({
            Title = "Teleport to " .. secondValue,
            Callback = function()
                TeleportToNPCWithFallback(secondValue)
            end
        })
    end
    addSpecialTeleportSection(mainMap.Teleport, "Maoshan", { "NPC", "Function", "Maoshan" }, function()
        return findTrackerObject("maoshan") ~= nil
    end)
    addSpecialTeleportSection(mainMap.Teleport, "Taoist", { "NPC", "Function", "Taoist" }, function()
        return findTrackerObject("taoist") ~= nil
    end)
    pvpSec = mainMap.Teleport:AddSection({ Title = "PVP", Icon = "swords" })
    pvpSec:AddButton({
        Title = "Find Match",
        Icon = "search",
        Callback = function()
            local ok, result = pcall(function()
                local events = ReplicatedStorage:FindFirstChild("Events")
                local pvpQueue = events and events:FindFirstChild("PVPQueue")
                if not pvpQueue then
                    error("Remote PVPQueue not found!")
                end
                pvpQueue:FireServer()
            end)
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "PVP",
                    Content = ok and "Finding match..." or "Failed: " .. tostring(result),
                    Duration = 3,
                    Icon = ok and "swords" or "circle-alert"
                })
            end
        end
    })
    formatPrice = function(inputValue)
        local reverseResult = tostring(inputValue):reverse():gsub("(%d%d%d)", "%1,"):reverse()
        if reverseResult:sub(1, 1) == "," then
            reverseResult = reverseResult:sub(2)
        end
        return reverseResult
    end
    craftRodSec = mainMap.BuyRod:AddSection({ Title = "Auto Craft Rod", Icon = "hammer" })
    craftRodSec:AddParagraph({
        Title = "Info",
        Content = "Craft selected rod. Quantity is clamped from 1 to 100."
    })
    craftRodOptions = { "Heavenpiercer Rod", "Pure Diamond Rod", "Sacred Bamboo Rod" }
    selectedCraftRod = getgenv().NNVN_CraftRodName or "Heavenpiercer Rod"
    craftRodSec:AddDropdown("NNVN_CraftRodName", {
        Title = "Select Rod",
        Values = craftRodOptions,
        Default = selectedCraftRod,
        Callback = function(selected)
            selectedCraftRod = selected or "Heavenpiercer Rod"
            getgenv().NNVN_CraftRodName = selectedCraftRod
        end
    })
    craftRodSec:AddInput("NNVN_CraftRodQuantityInput", {
        Title = "Craft Quantity",
        Placeholder = "1 - 100",
        Default = tostring(getgenv().NNVN_CraftRodQuantity or 1),
        Callback = function(selectedValue)
            getgenv().NNVN_CraftRodQuantity = math.clamp(math.floor(tonumber(selectedValue) or 1), 1, 100)
        end
    })
    CraftSelectedRod = function(inputValue)
        local clampResult = math.clamp(math.floor(tonumber(inputValue) or getgenv().NNVN_CraftRodQuantity or 1), 1, 100)
        local selectedCraftRod2 = selectedCraftRod or getgenv().NNVN_CraftRodName or "Heavenpiercer Rod"
        RunActionWithMethod({ teleport = TPNearBaitSeller, returnAfter = true }, function()
            task.wait(0.25)
            ReplicatedStorage.Events.CraftBait:FireServer(selectedCraftRod2, clampResult)
            task.wait(0.25)
        end)
    end
    craftRodSec:AddButton({
        Title = "Craft Once",
        Callback = function()
            CraftSelectedRod(getgenv().NNVN_CraftRodQuantity or 1)
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Craft Rod",
                    Content = "Crafted " .. tostring(getgenv().NNVN_CraftRodQuantity or 1) .. "x " .. tostring(selectedCraftRod or "Heavenpiercer Rod"),
                    Duration = 2
                })
            end
        end
    })
    craftRodSec:AddToggle("NNVN_AutoCraftRod", {
        Title = "Auto Craft Rod",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoCraftRod = enabled
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Craft Rod",
                    Content = enabled and "Auto craft rod enabled" or "Auto craft rod disabled",
                    Duration = 2
                })
            end
        end
    })
    if not getgenv().NNVN_AutoCraftRodLoop then
        getgenv().NNVN_AutoCraftRodLoop = true
        task.spawn(function()
            while task.wait(3) do
                if getgenv().NNVN_AutoCraftRod then
                    CraftSelectedRod(getgenv().NNVN_CraftRodQuantity or 1)
                end
            end
        end)
    end
    rodData = {
        {
            name = "Bamboo Rod",
            price = 100,
            seller = "Beginning Isle's Rod Seller"
        },
        {
            name = "Iron Hook Rod",
            price = 500,
            seller = "Beginning Isle's Rod Seller"
        },
        {
            name = "Steel Rod",
            price = 1000,
            seller = "Beginning Isle's Rod Seller"
        },
        {
            name = "Enchanted Steel Rod",
            price = 2000,
            seller = "Beginning Isle's Rod Seller"
        },
        { name = "Alloy Rod", price = 5000, seller = "Bamboo Isle's Rod Seller" },
        {
            name = "Emerald Rod",
            price = 10000,
            seller = "Bamboo Isle's Rod Seller"
        },
        {
            name = "Bloodfire Rod",
            price = 20000,
            seller = "Bamboo Isle's Rod Seller"
        },
        {
            name = "Triple Steel Rod",
            price = 100000,
            seller = "Fallout Isle's Rod Seller"
        },
        {
            name = "Golden Rod",
            price = 200000,
            seller = "Fallout Isle's Rod Seller"
        },
        {
            name = "Grandmaster Steel Rod",
            price = 250000,
            seller = "Sovereign Isle's Rod Seller"
        },
        {
            name = "Grandmaster Emerald Rod",
            price = 500000,
            seller = "Sovereign Isle's Rod Seller"
        },
        {
            name = "Grandmaster Golden Rod",
            price = 1000000,
            seller = "Sovereign Isle's Rod Seller"
        },
        {
            name = "Inferno Rod",
            price = 1500000,
            seller = "Sovereign Isle's Rod Seller"
        },
        {
            name = "Steel Spine Rod",
            price = 1500000,
            seller = "Frost Isle's Rod Seller"
        },
        {
            name = "Golden Spine Rod",
            price = 2000000,
            seller = "Frost Isle's Rod Seller"
        },
        {
            name = "Platinum Spine Rod",
            price = 3000000,
            seller = "Frost Isle's Rod Seller"
        },
        {
            name = "Diamond Spine Rod",
            price = 4000000,
            seller = "Frost Isle's Rod Seller"
        },
        {
            name = "Gravisteel Rod",
            price = 5000000,
            seller = "Frost Isle's Rod Seller"
        },
        {
            name = "Auric Gravity Rod",
            price = 6000000,
            seller = "Frost Isle's Rod Seller"
        },
        {
            name = "Inferno Gravity Rod",
            price = 7000000,
            seller = "Frost Isle's Rod Seller"
        },
        {
            name = "Cryo Gravity Rod",
            price = 8000000,
            seller = "Frost Isle's Rod Seller"
        },
        {
            name = "Thunder Thorn Rod",
            price = 10000000,
            seller = "Coconut Isle's Rod Dealer"
        },
        {
            name = "Soul Thorn Rod",
            price = 20000000,
            seller = "Coconut Isle's Rod Dealer"
        },
        {
            name = "Starlight Rod",
            price = 60000000,
            seller = "Amber Isle's Rod Seller"
        }
    }
    table.sort(rodData, function(leftItem, rightItem)
        return leftItem.price < rightItem.price
    end)
    rodGroups = {}
    for _, item32 in ipairs(rodData) do
        if not rodGroups[item32.seller] then
            rodGroups[item32.seller] = {}
        end
        table.insert(rodGroups[item32.seller], item32)
    end
    sortedSellers = {}
    for key, entry2 in pairs(rodGroups) do
        table.sort(entry2, function(leftItem, rightItem)
            return leftItem.price < rightItem.price
        end)
        table.insert(sortedSellers, { seller = key, minPrice = entry2[1].price })
    end
    table.sort(sortedSellers, function(leftItem, rightItem)
        return leftItem.minPrice < rightItem.minPrice
    end)
    for _, item33 in ipairs(sortedSellers) do
        local section3 = mainMap.BuyRod:AddSection({ Title = "" .. item33.seller, Icon = "shopping-cart" })
        for _, item34 in ipairs(rodGroups[item33.seller]) do
            local item342 = item34
            section3:AddButton({
                Title = "" .. item342.name .. " - $" .. formatPrice(item342.price),
                Callback = function()
                    task.spawn(function()
                        RunActionWithMethod({
                            teleport = function()
                                return TPNearRodSeller(item342.seller)
                            end,
                            returnAfter = true
                        }, function()
                            pcall(function()
                                ReplicatedStorage.Events.BuyFishingRod:FireServer(item342.name)
                            end)
                        end)
                        if getgenv().NNVN_Notify then
                            item:Notify({ Title = "Buy Rod", Content = "Bought " .. item342.name, Duration = 2 })
                        end
                    end)
                end
            })
        end
    end
end

local data
do
    secSec = mainMap.BuyRod:AddSection({ Title = "Secret Rod", Icon = "key-round" })
    for _, item35 in ipairs(secretRodData) do
        local item352 = item35
        secSec:AddButton({
            Title = "" .. item352.name .. " - " .. formatPrice(item352.price) .. " gem",
            Callback = function()
                task.spawn(function()
                    RunActionWithMethod({
                        teleport = function()
                            TeleportToCFrame(item352.cf)
                            task.wait(delaySeconds)
                            return true
                        end,
                        returnAfter = true
                    }, function()
                        pcall(function()
                            ReplicatedStorage.Events.BuyFishingRod:FireServer(item352.name)
                        end)
                    end)
                    if getgenv().NNVN_Notify then
                        item:Notify({ Title = "Buy Rod", Content = "Bought " .. item352.name, Duration = 2 })
                    end
                end)
            end
        })
    end
    skillData = {
        { name = "Skyfall Stomp", price = 100 },
        { name = "Infinite Sky Ascension", price = 500 },
        { name = "Unshake Stance", price = 1000 },
        { name = "Swift Reel", price = 1200 },
        { name = "Demonfall Technique", price = 1400 },
        { name = "Reel Machine", price = 1600 },
        { name = "Reel Sprint", price = 2000 },
        { name = "Dragonfish Vitality", price = 5000 },
        { name = "Skybreaker Technique", price = 16000 },
        { name = "Aerial Rod Throw", price = 35000 },
        { name = "Thousand Enemy Sweep", price = 40000 },
        { name = "One-Strike Heaven Gate", price = 50000 },
        { name = "Rolling Chaos", price = 50000 },
        { name = "Rooster Strike", price = 60000 },
        { name = "Phoenix Strike Art", price = 100000 }
    }
    skillDisplayNames = {}
    for _, item36 in ipairs(skillData) do
        table.insert(skillDisplayNames, item36.name .. " - $" .. formatPrice(item36.price))
    end
    learnSec = mainMap.Learn:AddSection({ Title = "Sage Yijiu", Icon = "book-open" })
    selSkillName = skillData[1].name
    learnSec:AddDropdown("SkillSelection", {
        Title = "Select Skill",
        Values = skillDisplayNames,
        Default = skillDisplayNames[1],
        Callback = function(selected)
            for _, item in ipairs(skillData) do
                if selected == item.name .. " - $" .. formatPrice(item.price) then
                    selSkillName = item.name
                    break
                end
            end
        end
    })
    learnSec:AddButton({
        Title = "Buy Selected Skill",
        Callback = function()
            task.spawn(function()
                RunActionWithMethod({ target = "Sage Yijiu", returnAfter = true }, function()
                    pcall(function()
                        ReplicatedStorage.Events.BuySkill:FireServer(selSkillName)
                    end)
                end)
                if getgenv().NNVN_Notify then
                    item:Notify({ Title = "Skill", Content = "Bought " .. selSkillName, Duration = 2 })
                end
            end)
        end
    })
    learnSec:AddButton({
        Title = "Teleport to Sage Yijiu",
        Callback = function()
            TeleportToNPCWithFallback("Sage Yijiu")
        end
    })
    getgenv().NNVN_SelectedSkill = getgenv().NNVN_SelectedSkill or nil
    getgenv().NNVN_UpgradeMethod = getgenv().NNVN_UpgradeMethod or "Instant"
    local function resolveData()
        local stateMap = {}
        local playerData = ReplicatedStorage.Data:FindFirstChild(tostring(LocalPlayer.UserId))
        if not playerData then
            return stateMap
        end
        local skill = playerData:FindFirstChild("Skill")
        if not skill then
            return stateMap
        end
        for _, item in ipairs(skill:GetChildren()) do
            if not item:IsA("Folder") then
                continue
            end
            local owned = item:FindFirstChild("Owned")
            if owned and owned:IsA("BoolValue") and owned.Value == true then
                table.insert(stateMap, item.Name)
            end
        end
        table.sort(stateMap)
        return stateMap
    end
    local function checkAttribute3()
        local playerData = ReplicatedStorage.Data:FindFirstChild(tostring(LocalPlayer.UserId))
        if not playerData then
            return 0
        end
        local essenceOrb = playerData:FindFirstChild("EssenceOrb")
        if essenceOrb then
            if essenceOrb:IsA("NumberValue") or essenceOrb:IsA("IntValue") then
                return essenceOrb.Value
            elseif essenceOrb:IsA("StringValue") then
                return tonumber(essenceOrb.Value) or 0
            end
        end
        return tonumber(playerData:GetAttribute("EssenceOrb")) or 0
    end
    upgradeSkillSec = mainMap.Learn:AddSection({ Title = "Upgrade Skill", Icon = "arrow-up" })
    data = resolveData()
    if #data == 0 then
        data = { "No owned skills" }
    end
    skillUpgradeDropdown = upgradeSkillSec:AddDropdown("NNVN_SelectedSkill", {
        Title = "Select Skill",
        Values = data,
        Default = data[1],
        SearchBarEnabled = true,
        Callback = function(selected)
            if selected == "No owned skills" then
                getgenv().NNVN_SelectedSkill = nil
            else
                getgenv().NNVN_SelectedSkill = selected
            end
        end
    })
    upgradeSkillSec:AddDropdown("NNVN_UpgradeMethod", {
        Title = "Select Method",
        Values = { "Instant", "Teleport" },
        Default = getgenv().NNVN_UpgradeMethod or "Instant",
        Callback = function(selectedValue)
            getgenv().NNVN_UpgradeMethod = selectedValue
        end
    })
    upgradeSkillSec:AddButton({
        Title = "Upgrade Selected Skill",
        Callback = function()
            local selectedSkill = getgenv().NNVN_SelectedSkill
            if not selectedSkill or selectedSkill == "" or selectedSkill == "No owned skills" then
                if getgenv().NNVN_Notify and item then
                    item:Notify({
                        Title = "Upgrade",
                        Content = "Please select a skill first.",
                        Duration = 3
                    })
                end
                return
            end
            if checkAttribute3() <= 0 then
                if getgenv().NNVN_Notify and item then
                    item:Notify({ Title = "Upgrade", Content = "Not Enough EssenceOrb", Duration = 3 })
                end
                return
            end
            local upgradeMethod = getgenv().NNVN_UpgradeMethod or "Instant"
            local upgradeSkill = ReplicatedStorage.Events:FindFirstChild("UpgradeSkill")
            if not upgradeSkill then
                if getgenv().NNVN_Notify and item then
                    item:Notify({
                        Title = "Upgrade",
                        Content = "UpgradeSkill event not found",
                        Duration = 3
                    })
                end
                return
            end
            local function resolveNotify()
                local ok, result = pcall(function()
                    upgradeSkill:InvokeServer(selectedSkill)
                end)
                if ok then
                    if getgenv().NNVN_Notify and item then
                        item:Notify({
                            Title = "Upgrade",
                            Content = "Skill upgraded successfully!",
                            Duration = 3
                        })
                    end
                    local data = resolveData()
                    if #data == 0 then
                        data = { "No owned skills" }
                    end
                    if skillUpgradeDropdown and skillUpgradeDropdown.Refresh then
                        pcall(function()
                            skillUpgradeDropdown:Refresh(data)
                        end)
                    end
                elseif getgenv().NNVN_Notify and item then
                    item:Notify({
                        Title = "Upgrade",
                        Content = "Failed: " .. tostring(result),
                        Duration = 4
                    })
                end
            end
            if upgradeMethod == "Instant" then
                resolveNotify()
            else
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if not rootPart then
                    if getgenv().NNVN_Notify and item then
                        item:Notify({ Title = "Upgrade", Content = "Character not found.", Duration = 3 })
                    end
                    return
                end
                local cFrame = rootPart.CFrame
                local item2
                pcall(function()
                    local npcFolder = Workspace:FindFirstChild("NPC")
                    local functionValue = npcFolder and npcFolder:FindFirstChild("Function")
                    item2 = functionValue and functionValue:FindFirstChild("Zeng Tianguo")
                end)
                if not item2 then
                    item2 = FindNPCByName("Zeng Tianguo")
                end
                if not item2 then
                    if getgenv().NNVN_Notify and item then
                        item:Notify({
                            Title = "Upgrade",
                            Content = "NPC Zeng Tianguo not found.",
                            Duration = 3
                        })
                    end
                    return
                end
                local item3
                if item2:IsA("BasePart") then
                    item3 = item2.CFrame
                elseif item2:IsA("Model") then
                    local primaryPart = item2.PrimaryPart
                    if primaryPart then
                        item3 = primaryPart.CFrame
                    else
                        for _, item4 in ipairs(item2:GetDescendants()) do
                            if item4:IsA("BasePart") then
                                item3 = item4.CFrame
                                break
                            end
                        end
                    end
                end
                if not item3 then
                    if getgenv().NNVN_Notify and item then
                        item:Notify({ Title = "Upgrade", Content = "Cannot get NPC CFrame.", Duration = 3 })
                    end
                    return
                end
                pcall(function()
                    NNVN_TweenTo(item3 + Vector3.new(0, 5, 0))
                end)
                task.wait(0.5)
                resolveNotify()
                pcall(function()
                    NNVN_TweenTo(cFrame)
                end)
            end
        end
    })
    upgradeSkillSec:AddButton({
        Title = "Refresh Skills",
        Callback = function()
            local data = resolveData()
            if #data == 0 then
                data = { "No owned skills" }
                if getgenv().NNVN_Notify and item then
                    item:Notify({ Title = "Refresh", Content = "No owned skills found.", Duration = 3 })
                end
            elseif getgenv().NNVN_Notify and item then
                item:Notify({
                    Title = "Refresh",
                    Content = "Skill list refreshed. (" .. #data .. " skills)",
                    Duration = 3
                })
            end
            if skillUpgradeDropdown and skillUpgradeDropdown.Refresh then
                pcall(function()
                    skillUpgradeDropdown:Refresh(data)
                end)
            end
        end
    })
    getgenv().NNVN_ExchangeMethod = getgenv().NNVN_ExchangeMethod or "Instant"
    getgenv().NNVN_ExchangeObject = getgenv().NNVN_ExchangeObject or "EssenceOrb"
    getgenv().NNVN_ExchangeQuantity = getgenv().NNVN_ExchangeQuantity or "1"
    local function resolveExchangeMethod()
        return getgenv().NNVN_ExchangeMethod or "Instant"
    end
    local function resolveExchangeObject()
        return getgenv().NNVN_ExchangeObject or "EssenceOrb"
    end
    local function resolveExchangeQuantity()
        return tonumber(getgenv().NNVN_ExchangeQuantity) or 1
    end
    exchangeSec = mainMap.Learn:AddSection({ Title = "Exchange", Icon = "repeat" })
    exchangeSec:AddDropdown("NNVN_ExchangeMethod", {
        Title = "Select Method",
        Values = { "Instant", "Teleport" },
        Default = getgenv().NNVN_ExchangeMethod or "Instant",
        Callback = function(selected)
            getgenv().NNVN_ExchangeMethod = selected
        end
    })
    exchangeSec:AddDropdown("NNVN_ExchangeObject", {
        Title = "Select Objects That Need To Exchange",
        Values = { "EssenceOrb", "Trait Reroll" },
        Default = getgenv().NNVN_ExchangeObject or "EssenceOrb",
        Callback = function(inputText)
            getgenv().NNVN_ExchangeObject = inputText
        end
    })
    exchangeSec:AddInput("NNVN_ExchangeQuantity", {
        Title = "Quantity",
        Placeholder = "Enter quantity",
        Default = tostring(getgenv().NNVN_ExchangeQuantity or "1"),
        Callback = function(selectedValue)
            local parsedNum = tonumber(selectedValue)
            if parsedNum and parsedNum > 0 then
                getgenv().NNVN_ExchangeQuantity = tostring(math.floor(parsedNum))
            else
                getgenv().NNVN_ExchangeQuantity = "1"
            end
        end
    })
    exchangeSec:AddButton({
        Title = "Exchange Now",
        Callback = function()
            local exchangeMethod = resolveExchangeMethod()
            local exchangeObject = resolveExchangeObject()
            local exchangeQuantity = resolveExchangeQuantity()
            if exchangeQuantity < 1 then
                if getgenv().NNVN_Notify and item then
                    item:Notify({
                        Title = "Exchange",
                        Content = "Quantity must be at least 1.",
                        Duration = 3
                    })
                end
                return
            end
            local exchange = ReplicatedStorage.Events:FindFirstChild("Exchange")
            if not exchange then
                if getgenv().NNVN_Notify and item then
                    item:Notify({
                        Title = "Exchange",
                        Content = "Exchange event not found.",
                        Duration = 3
                    })
                end
                return
            end
            local function resolveNotify()
                local ok, result = pcall(function()
                    exchange:FireServer(exchangeObject, exchangeQuantity)
                end)
                if ok then
                    if getgenv().NNVN_Notify and item then
                        item:Notify({ Title = "Exchange", Content = "Exchange successful!", Duration = 3 })
                    end
                elseif getgenv().NNVN_Notify and item then
                    item:Notify({
                        Title = "Exchange",
                        Content = "Exchange failed: " .. tostring(result),
                        Duration = 4
                    })
                end
            end
            if exchangeMethod == "Instant" then
                resolveNotify()
            else
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if not rootPart then
                    if getgenv().NNVN_Notify and item then
                        item:Notify({ Title = "Exchange", Content = "Character not found.", Duration = 3 })
                    end
                    return
                end
                local cFrame = rootPart.CFrame
                local item2
                pcall(function()
                    local npcFolder = Workspace:FindFirstChild("NPC")
                    local functionValue = npcFolder and npcFolder:FindFirstChild("Function")
                    item2 = functionValue and functionValue:FindFirstChild("Nanjiang")
                end)
                if not item2 then
                    item2 = FindNPCByName("Nanjiang")
                end
                if not item2 then
                    if getgenv().NNVN_Notify and item then
                        item:Notify({ Title = "Exchange", Content = "NPC Nanjiang not found.", Duration = 3 })
                    end
                    return
                end
                local item3
                if item2:IsA("BasePart") then
                    item3 = item2.CFrame
                elseif item2:IsA("Model") then
                    local primaryPart = item2.PrimaryPart
                    if primaryPart then
                        item3 = primaryPart.CFrame
                    else
                        for _, item4 in ipairs(item2:GetDescendants()) do
                            if item4:IsA("BasePart") then
                                item3 = item4.CFrame
                                break
                            end
                        end
                    end
                end
                if not item3 then
                    if getgenv().NNVN_Notify and item then
                        item:Notify({ Title = "Exchange", Content = "Cannot get NPC CFrame.", Duration = 3 })
                    end
                    return
                end
                pcall(function()
                    NNVN_TweenTo(item3 + Vector3.new(0, 5, 0))
                end)
                task.wait(0.5)
                resolveNotify()
                pcall(function()
                    NNVN_TweenTo(cFrame)
                end)
            end
        end
    })
    baitData = {
        { name = "Basic Bait", price = 100 },
        { name = "Crude Mash Bait", price = 10000 },
        { name = "Corrupted Essence Bait", price = 15000 },
        { name = "Elite Bait", price = 50000 },
        { name = "Ancestral Bait", price = 100000 }
    }
    baitDisplayNames = {}
    for _, item37 in ipairs(baitData) do
        table.insert(baitDisplayNames, item37.name .. " - $" .. formatPrice(item37.price))
    end
    NNVN_FireBuyBait = function(inputValue, secondValue)
        inputValue = tostring(inputValue or "Basic Bait")
        secondValue = math.clamp(math.floor(tonumber(secondValue) or 1), 1, 999)
        local events = ReplicatedStorage:FindFirstChild("Events")
        local buyBait = events and events:FindFirstChild("BuyBait")
        if not buyBait then
            local ok, result = pcall(function()
                return ReplicatedStorage:WaitForChild("Events", 5):WaitForChild("BuyBait", 5)
            end)
            buyBait = ok and result or nil
        end
        if not buyBait then
            return false, "BuyBait remote was not found."
        end
        local ok2, result2 = pcall(function()
            if buyBait:IsA("RemoteFunction") then
                buyBait:InvokeServer(inputValue, secondValue)
            else
                buyBait:FireServer(inputValue, secondValue)
            end
        end)
        return ok2, result2
    end
    baitSec = mainMap.Bait:AddSection({ Title = "Buy Bait", Icon = "worm" })
    baitSec:AddDropdown("BaitSelection", {
        Title = "Select Bait Type",
        Values = baitDisplayNames,
        Default = baitDisplayNames[1],
        Callback = function(selected)
            if type(selected) == "table" then
                selected = selected[1] or next(selected)
            end
            selected = tostring(selected or "")
            for _, item in ipairs(baitData) do
                if selected == item.name .. " - $" .. formatPrice(item.price) then
                    getgenv().NNVN_SelectedBait = item.name
                    break
                end
            end
        end
    })
    baitSec:AddToggle("AutoBuyBait", {
        Title = "Auto Buy Bait",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoBuyBait = enabled == true
            if enabled then
                task.defer(function()
                    NNVN_FireBuyBait(getgenv().NNVN_SelectedBait or "Basic Bait", getgenv().NNVN_BaitQuantity)
                end)
            end
        end
    })
    baitSec:AddSlider("AutoBuyBaitDelay", {
        Title = "Buy Delay (seconds)",
        Default = 3,
        Min = 1,
        Max = 60,
        Rounding = 1,
        Callback = function(amount)
            getgenv().NNVN_AutoBuyBaitDelay = amount
        end
    })
    baitSec:AddSlider("BaitQuantity", {
        Title = "Quantity per Buy",
        Default = getgenv().NNVN_BaitQuantity,
        Min = 1,
        Max = 999,
        Rounding = 1,
        AllowRightClickInput = true,
        Callback = function(inputText)
            getgenv().NNVN_BaitQuantity = math.max(1, math.floor(tonumber(inputText) or 1))
        end
    })
    baitSec:AddInput("BaitQuantityInput", {
        Title = "Bait Quantity Input",
        Placeholder = "Quantity to buy",
        Default = tostring(getgenv().NNVN_BaitQuantity),
        Numeric = true,
        Finished = true,
        Callback = function(selectedValue)
            local clampResult = math.clamp(math.floor(tonumber(selectedValue) or 1), 1, 999)
            getgenv().NNVN_BaitQuantity = clampResult
            local baitQuantity = stateMap2 and stateMap2.BaitQuantity
            if baitQuantity and baitQuantity.SetValue then
                pcall(function()
                    baitQuantity:SetValue(clampResult)
                end)
            end
        end
    })
    baitSec:AddButton({
        Title = "Buy Selected Bait Now",
        Description = "Sends BuyBait with the selected bait and Quantity per Buy.",
        Callback = function()
            local selectedBait = getgenv().NNVN_SelectedBait or "Basic Bait"
            local maxResult = math.max(1, math.floor(tonumber(getgenv().NNVN_BaitQuantity) or 1))
            local primaryValue, secondaryValue = NNVN_FireBuyBait(selectedBait, maxResult)
            if primaryValue and getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Buy Bait",
                    Content = "Bought " .. maxResult .. "x " .. selectedBait,
                    Duration = 2
                })
            elseif not primaryValue and getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Buy Bait",
                    Content = tostring(secondaryValue or "Remote failed."),
                    Duration = 3
                })
            end
        end
    })
    baitSec:AddSlider("NNVN_AutoBuyBaitThreshold", {
        Title = "Buy When Below",
        Default = 5,
        Min = 0,
        Max = 50,
        Rounding = 1,
        Callback = function(selectedValue)
            getgenv().NNVN_AutoBuyBaitThreshold = selectedValue
        end
    })
    visualStatsSec = mainMap.Visual:AddSection({ Title = "Fake Stats", Icon = "badge-dollar-sign" })
    visualStatsSec:AddToggle("NNVN_FakeVisualsEnabled", {
        Title = "Enable Fake Visual Stats",
        Description = "Client-side only. Edits level, money, and gem text in your UI.",
        Default = getgenv().NNVN_FakeVisualsEnabled,
        Callback = function(inputText)
            getgenv().NNVN_FakeVisualsEnabled = inputText
            applyFakeVisuals()
        end
    })
    visualStatsSec:AddInput("NNVN_FakeLevelText", {
        Title = "Fake Level",
        Default = tostring(getgenv().NNVN_FakeLevelText),
        Callback = function(inputText)
            getgenv().NNVN_FakeLevelText = numericOnlyText(inputText, 100)
            applyFakeVisuals()
        end
    })
    visualStatsSec:AddInput("NNVN_FakeMoneyText", {
        Title = "Fake Money",
        Default = tostring(getgenv().NNVN_FakeMoneyText),
        Callback = function(inputText)
            getgenv().NNVN_FakeMoneyText = numericOnlyText(inputText, 999999999)
            applyFakeVisuals()
        end
    })
    visualStatsSec:AddInput("NNVN_FakeGemText", {
        Title = "Fake Gems",
        Default = tostring(getgenv().NNVN_FakeGemText),
        Callback = function(inputText)
            getgenv().NNVN_FakeGemText = numericOnlyText(inputText, 9999)
            applyFakeVisuals()
        end
    })
    visualStatsSec:AddInput("NNVN_FakeTicketText", {
        Title = "Fake Tickets",
        Default = tostring(getgenv().NNVN_FakeTicketText),
        Callback = function(inputText)
            getgenv().NNVN_FakeTicketText = numericOnlyText(inputText, 999)
            applyFakeVisuals()
        end
    })
    visualStatsSec:AddInput("NNVN_FakeOrbText", {
        Title = "Fake Orbs",
        Default = tostring(getgenv().NNVN_FakeOrbText),
        Callback = function(selectedValue)
            getgenv().NNVN_FakeOrbText = numericOnlyText(selectedValue, 999)
            applyFakeVisuals()
        end
    })
    visualStatsSec:AddButton({
        Title = "Apply Fake Stats",
        Icon = "wand-2",
        Callback = function()
            getgenv().NNVN_FakeVisualsEnabled = true
            applyFakeVisuals()
        end
    })
    visualStatsSec:AddButton({
        Title = "Reset Fake Stats",
        Icon = "rotate-ccw",
        Callback = function()
            getgenv().NNVN_FakeVisualsEnabled = false
            restoreFakeVisuals()
        end
    })
    dupeSec = mainMap.Visual:AddSection({ Title = "Dupe (Visual Only)", Icon = "copy" })
    getgenv().NNVN_VirtualDupeAmount = math.clamp(math.floor(tonumber(getgenv().NNVN_VirtualDupeAmount) or 1), 1, 100)
    virtualDupeSources = {}
    selectedVirtualDupe = nil
    GetLocalInventory = function()
        local data = ReplicatedStorage:FindFirstChild("Data")
        local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
        return playerData and playerData:FindFirstChild("Inventory")
    end
    GetVirtualDupeChoices = function()
        virtualDupeSources = {}
        local nameList = { "Select an item..." }
        local localInventory = GetLocalInventory()
        if not localInventory then
            return nameList
        end
        local counter = 0
        for _, item in ipairs(localInventory:GetChildren()) do
            if item:GetAttribute("NNVN_VirtualDupe") == true then
                continue
            end
            counter = counter + 1
            local formattedText = string.format("[%d] %s", counter, item.Name)
            virtualDupeSources[formattedText] = item
            table.insert(nameList, formattedText)
        end
        return nameList
    end
    RefreshVirtualDupeDropdown = function()
        local virtualDupeChoices = GetVirtualDupeChoices()
        selectedVirtualDupe = nil
        if virtualDupeDropdown and virtualDupeDropdown.Refresh then
            virtualDupeDropdown:Refresh(virtualDupeChoices)
        elseif virtualDupeDropdown and virtualDupeDropdown.SetValues then
            virtualDupeDropdown:SetValues(virtualDupeChoices)
        end
        if virtualDupeDropdown and virtualDupeDropdown.SetValue then
            virtualDupeDropdown:SetValue("Select an item...")
        end
    end
    dupeSec:AddParagraph({
        Title = "Local inventory preview",
        Content = "Copies only appear on this client and disappear after rejoin. They cannot be sold or traded."
    })
    virtualDupeDropdown = dupeSec:AddDropdown("NNVN_VirtualDupeItem", {
        Title = "Inventory Item",
        Values = GetVirtualDupeChoices(),
        Default = "Select an item...",
        Callback = function(selected)
            selectedVirtualDupe = virtualDupeSources[selected]
        end
    })
    dupeSec:AddSlider("NNVN_VirtualDupeAmount", {
        Title = "Number of Visual Copies",
        Default = getgenv().NNVN_VirtualDupeAmount,
        Min = 1,
        Max = 100,
        Rounding = 1,
        Callback = function(selectedValue)
            getgenv().NNVN_VirtualDupeAmount = math.clamp(math.floor(tonumber(selectedValue) or 1), 1, 100)
        end
    })
    dupeSec:AddButton({
        Title = "Create Visual Copies",
        Icon = "copy-plus",
        Callback = function()
            local selectedVirtualDupe2 = selectedVirtualDupe
            local localInventory = GetLocalInventory()
            if not localInventory or not selectedVirtualDupe2 or selectedVirtualDupe2.Parent ~= localInventory then
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Visual Dupe",
                        Content = "Select an inventory item first.",
                        Duration = 2
                    })
                end
                return
            end
            local counter = 0
            for i = 1, getgenv().NNVN_VirtualDupeAmount do
                local ok, result = pcall(function()
                    return selectedVirtualDupe2:Clone()
                end)
                if not ok or not result then
                    continue
                end
                result:SetAttribute("NNVN_VirtualDupe", true)
                result:SetAttribute("NNVN_VirtualDupeSource", selectedVirtualDupe2.Name)
                result.Parent = localInventory
                counter = counter + 1
            end
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Visual Dupe",
                    Content = "Created " .. counter .. " local visual copy/copies.",
                    Duration = 2
                })
            end
        end
    })
    dupeSec:AddButton({
        Title = "Refresh Inventory List",
        Icon = "refresh-cw",
        Callback = RefreshVirtualDupeDropdown
    })
    dupeSec:AddButton({
        Title = "Remove All Visual Copies",
        Icon = "trash-2",
        Callback = function()
            local localInventory = GetLocalInventory()
            local counter = 0
            if localInventory then
                for _, item2 in ipairs(localInventory:GetChildren()) do
                    if item2:GetAttribute("NNVN_VirtualDupe") == true then
                        item2:Destroy()
                        counter = counter + 1
                    end
                end
            end
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Visual Dupe",
                    Content = "Removed " .. counter .. " local visual copy/copies.",
                    Duration = 2
                })
            end
        end
    })
    visualIdentitySec = mainMap.Visual:AddSection({ Title = "Identity Spoof", Icon = "masks" })
    visualIdentitySec:AddToggle("NNVN_FakeNameEnabled", {
        Title = "Fake Name",
        Default = getgenv().NNVN_FakeNameEnabled,
        Callback = function(enabled)
            getgenv().NNVN_FakeNameEnabled = enabled
            applyFakeVisuals()
        end
    })
    visualIdentitySec:AddInput("NNVN_FakeNameText", {
        Title = "Fake Display Name",
        Default = tostring(getgenv().NNVN_FakeNameText),
        Callback = function(selectedValue)
            getgenv().NNVN_FakeNameText = trimText(selectedValue)
            applyFakeVisuals()
            local localHumanoid = getLocalHumanoid()
            if localHumanoid and getgenv().NNVN_FakeNameEnabled then
                pcall(function()
                    localHumanoid.DisplayName = getgenv().NNVN_FakeNameText
                end)
            end
        end
    })
    visualAvatarSec = mainMap.Visual:AddSection({ Title = "Avatar Visuals", Icon = "shirt" })
    visualAvatarSec:AddToggle("NNVN_FakeHeadless", {
        Title = "Fake Headless",
        Default = getgenv().NNVN_FakeHeadless,
        Callback = function(enabled)
            getgenv().NNVN_FakeHeadless = enabled
            applyFakeHeadless()
        end
    })
    visualAvatarSec:AddToggle("NNVN_FakeKorblox", {
        Title = "Fake Korblox",
        Default = getgenv().NNVN_FakeKorblox,
        Callback = function(enabled)
            getgenv().NNVN_FakeKorblox = enabled
            applyFakeKorblox()
        end
    })
    visualAvatarSec:AddToggle("NNVN_FakeSkinEnabled", {
        Title = "Fake Skin",
        Default = getgenv().NNVN_FakeSkinEnabled,
        Callback = function(enabled)
            getgenv().NNVN_FakeSkinEnabled = enabled
            if enabled then
                applyFakeSkinFromPlayer()
            end
        end
    })
    visualAvatarSec:AddInput("NNVN_FakeSkinPlayerName", {
        Title = "Skin Player Name",
        Description = "Optional. Leave blank to use the tone dropdown only.",
        Default = tostring(getgenv().NNVN_FakeSkinPlayerName),
        Callback = function(selected)
            getgenv().NNVN_FakeSkinPlayerName = trimText(selected)
        end
    })
    visualAvatarSec:AddDropdown("NNVN_FakeSkinTone", {
        Title = "Skin Tone",
        Values = VISUAL_SKIN_TONES,
        Default = getgenv().NNVN_FakeSkinTone,
        Callback = function(selectedValue)
            getgenv().NNVN_FakeSkinTone = selectedValue or getgenv().NNVN_FakeSkinTone
            if getgenv().NNVN_FakeSkinEnabled then
                applyFakeSkinTone()
            end
        end
    })
    visualAvatarSec:AddButton({
        Title = "Apply Fake Skin",
        Icon = "paintbrush",
        Callback = function()
            getgenv().NNVN_FakeSkinEnabled = true
            local applyFakeSkinFrom = applyFakeSkinFromPlayer()
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Fake Skin",
                    Content = applyFakeSkinFrom and "Fake skin applied." or "Could not load that player skin. Using tone only if available.",
                    Duration = 3,
                    Icon = "paintbrush"
                })
            end
        end
    })
    visualAvatarSec:AddButton({
        Title = "Refresh Visuals",
        Icon = "refresh-cw",
        Callback = function()
            applyFakeVisuals()
            applyFakeHeadless()
            applyFakeKorblox()
            if getgenv().NNVN_FakeSkinEnabled then
                applyFakeSkinFromPlayer()
            end
        end
    })
    weatherInfoSec = mainMap.Weather:AddSection({ Title = "Weather Info", Icon = "cloud-sun" })
    weatherStatusParagraph = weatherInfoSec:AddParagraph({
        Title = "Current Status",
        Content = "🔴 Offline - Loading weather info..."
    })
    weatherInfoSec:AddButton({
        Title = "Refresh Weather Info",
        Icon = "refresh-cw",
        Callback = function()
            local currentWeather = getCurrentWeather()
            local currentIslandName = getCurrentIslandName and getCurrentIslandName() or "?"
            local recommendedWeatherIsland = getgenv().NNVN_GetRecommendedWeatherIsland and getgenv().NNVN_GetRecommendedWeatherIsland(currentWeather) or "N/A"
            local isMatched = weatherLookup[normalizeWeatherReporterName(currentWeather)] == true
            weatherStatusParagraph:SetDesc(string.format("%s Weather: %s%s\nIsland: %s\nRecommended farm island: %s\nSpecial event: %s\nFarm session: %s", formatStatusDot(true, "Online", "Offline"), tostring(currentWeather), isMatched and " ?" or "", tostring(currentIslandName), tostring(recommendedWeatherIsland), isMatched and "YES" or "NO", getgenv().NNVN_WeatherFarmActive and "ACTIVE" or "idle"))
        end
    })
    weatherTpSec = mainMap.Weather:AddSection({ Title = "Teleport", Icon = "map-pin" })
    weatherTpSec:AddDropdown("NNVN_WeatherFarmIsland", {
        Title = "Farm Island Override",
        Values = {
            "Auto",
            "Beginning Isle",
            "Bamboo Isle",
            "Fallout Isle",
            "Sovereign Isle",
            "Perch Isle",
            "Frost Isle",
            "Coconut Isle",
            "Amber Isle",
            "Battlefield Isle",
            "Mistpeak Isle"
        },
        Default = getgenv().NNVN_WeatherFarmIsland or "Auto",
        Callback = function(selectedValue)
            getgenv().NNVN_WeatherFarmIsland = selectedValue or "Auto"
        end
    })
    weatherTpSec:AddButton({
        Title = "Teleport to Current Weather Island",
        Icon = "cloud-sun",
        Callback = function()
            local hasTriggered = false
            local currentWeather = getCurrentWeather()
            local item2
            if type(getgenv().NNVN_TeleportToWeatherIsland) == "function" then
                local primaryValue, secondaryValue, thirdValue = getgenv().NNVN_TeleportToWeatherIsland()
                hasTriggered = primaryValue
                currentWeather = secondaryValue
                item2 = thirdValue
            end
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Weather Teleport",
                    Content = hasTriggered and string.format("Teleported for %s ? %s", tostring(currentWeather), tostring(item2)) or "No island mapped for weather: " .. tostring(currentWeather),
                    Duration = 3,
                    Icon = "map-pin"
                })
            end
        end
    })
    weatherTpSec:AddButton({
        Title = "Teleport to Selected Override Island",
        Icon = "map",
        Callback = function()
            local weatherFarmIsland = getgenv().NNVN_WeatherFarmIsland
            if not weatherFarmIsland or weatherFarmIsland == "Auto" then
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Weather",
                        Content = "Pick an island override first (not Auto).",
                        Duration = 3
                    })
                end
                return
            end
            local hasTriggered = false
            for _, item2 in ipairs(TeleportList or {}) do
                if item2.name == weatherFarmIsland then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        pcall(function()
                            NNVN_TweenTo(CFrame.new(item2.cf.Position) + Vector3.new(0, 5, 0))
                        end)
                        hasTriggered = true
                    end
                    break
                end
            end
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Weather Teleport",
                    Content = hasTriggered and "Teleported to " .. weatherFarmIsland or "Could not teleport to " .. tostring(weatherFarmIsland),
                    Duration = 3
                })
            end
        end
    })
end

do
    weatherPremiumSec = mainMap.Weather:AddSection({ Title = "Premium", Icon = "crown" })
    weatherPremiumSec:AddParagraph({
        Title = "How it works",
        Content = "Premium required. When special weather is active, this enables Auto Cast + Anchor Bar + Auto Skills. When it ends or this toggle is OFF, it returns to your old position and restores your previous toggle states."
    })
    weatherFarmToggle = weatherPremiumSec:AddToggle("NNVN_AutoFarmWeatherEvent", {
        Title = "Auto Farm Weather Event",
        Default = getgenv().NNVN_AutoFarmWeatherEvent == true and refreshPremiumAccess() or false,
        Locked = not refreshPremiumAccess(),
        Callback = function(selectedValue)
            if selectedValue and not ensurePremiumAccess("Auto Farm Weather Event") then
                getgenv().NNVN_AutoFarmWeatherEvent = false
                if type(getgenv().NNVN_StopWeatherFarm) == "function" then
                    getgenv().NNVN_StopWeatherFarm()
                end
                pcall(function()
                    weatherFarmToggle:SetValue(false)
                end)
                return
            end
            getgenv().NNVN_AutoFarmWeatherEvent = selectedValue and true or false
            if getgenv().NNVN_AutoFarmWeatherEvent then
                if type(getgenv().NNVN_StartAutoFarmWeather) == "function" then
                    getgenv().NNVN_StartAutoFarmWeather()
                end
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Weather Farm",
                        Content = "Auto Farm Weather Event enabled.",
                        Duration = 3,
                        Icon = "cloud-sun"
                    })
                end
            else
                if type(getgenv().NNVN_StopWeatherFarm) == "function" then
                    getgenv().NNVN_StopWeatherFarm()
                else
                    getgenv().NNVN_AutoCast = false
                    getgenv().NNVN_Anchor = false
                    getgenv().NNVN_AutoSkill = false
                    getgenv().NNVN_WeatherFarmActive = false
                end
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Weather Farm",
                        Content = "Disabled. Previous Auto Cast / Anchor / Skills states restored.",
                        Duration = 3,
                        Icon = "cloud"
                    })
                end
            end
        end
    })
    task.spawn(function()
        while task.wait(10) do
            local refreshPremiumAccessResult = refreshPremiumAccess()
            if weatherFarmToggle then
                pcall(function()
                    if weatherFarmToggle.SetLocked then
                        weatherFarmToggle:SetLocked(not refreshPremiumAccessResult)
                    end
                    if not refreshPremiumAccessResult and getgenv().NNVN_AutoFarmWeatherEvent then
                        getgenv().NNVN_AutoFarmWeatherEvent = false
                        if type(getgenv().NNVN_StopWeatherFarm) == "function" then
                            getgenv().NNVN_StopWeatherFarm()
                        end
                        if weatherFarmToggle.SetValue then
                            weatherFarmToggle:SetValue(false)
                        end
                    end
                end)
            end
        end
    end)
    weatherPremiumSec:AddButton({
        Title = "Stop Weather Farm Now",
        Icon = "square",
        Callback = function()
            if type(getgenv().NNVN_StopWeatherFarm) == "function" then
                getgenv().NNVN_StopWeatherFarm()
            end
            getgenv().NNVN_AutoFarmWeatherEvent = false
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Weather Farm",
                    Content = "Stopped. Returned home flags cleared.",
                    Duration = 3
                })
            end
        end
    })
    weatherMapSec = mainMap.Weather:AddSection({ Title = "Weather -> Island Map", Icon = "book-open" })
    weatherMapSec:AddParagraph({
        Title = "Default Mapping",
        Content = "Thunderstorm -> Bamboo Isle\nFoggy -> Coconut Isle\nSnowy -> Frost Isle\nRainy -> Perch Isle\nWindy -> Mistpeak Isle\nBlazing Sun -> Amber Isle\n\nUse Farm Island Override = Auto to follow this map."
    })
    weatherEspSec = mainMap.Weather:AddSection({ Title = "Weather ESP", Icon = "eye" })
    weatherEspSec:AddToggle("ESP_Weather_WeatherTab", {
        Title = "Weather ESP",
        Description = "Highlights the island recommended for the current special weather.",
        Default = getgenv().NNVN_ESP and getgenv().NNVN_ESP.Weather or false,
        Callback = function(selectedValue)
            getgenv().NNVN_ESP = getgenv().NNVN_ESP or {}
            getgenv().NNVN_ESP.Weather = selectedValue
            if selectedValue then
                task.defer(function()
                    if type(applyESP_Weather) == "function" then
                        pcall(applyESP_Weather)
                    end
                end)
            elseif type(clearESP) == "function" then
                clearESP("Weather")
            end
        end
    })
    if not getgenv()._NNVN_WeatherStatusLoop then
        getgenv()._NNVN_WeatherStatusLoop = true
        task.spawn(function()
            while task.wait(3) do
                pcall(function()
                    if not weatherStatusParagraph or not weatherStatusParagraph.SetDesc then
                        return
                    end
                    local currentWeather = getCurrentWeather()
                    weatherStatusParagraph:SetDesc(string.format("%s Weather: %s\nIsland: %s\nRecommended: %s\nSpecial: %s\nFarm session: %s | Auto: %s", formatStatusDot(true, "Online", "Offline"), tostring(currentWeather), tostring(getCurrentIslandName and getCurrentIslandName() or "?"), tostring(getgenv().NNVN_GetRecommendedWeatherIsland and getgenv().NNVN_GetRecommendedWeatherIsland(currentWeather) or "N/A"), weatherLookup[normalizeWeatherReporterName(currentWeather)] and "YES" or "NO", getgenv().NNVN_WeatherFarmActive and "ACTIVE" or "idle", getgenv().NNVN_AutoFarmWeatherEvent and "ON" or "OFF"))
                end)
            end
        end)
    end
    getgenv().NNVN_ESP = {
        GodSpirit = false,
        SecretRod = false,
        Boats = false,
        Maoshan = false,
        Taoist = false,
        Boss = false,
        Players = false,
        Weather = false,
        Nameless = false,
        BlackTortoise = false
    }
    espHighlights = {}
    clearESP = function(inputValue)
        if espHighlights[inputValue] then
            for _, item in ipairs(espHighlights[inputValue]) do
                pcall(function()
                    item:Destroy()
                end)
            end
            espHighlights[inputValue] = nil
        end
    end
    makeHighlight = function(inputValue, secondValue, thirdValue, fourthValue, fifthValue)
        local highlight = Instance.new("Highlight")
        highlight.FillColor = secondValue or Color3.fromRGB(255, 255, 0)
        highlight.OutlineColor = thirdValue or Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = fourthValue or 0.5
        highlight.OutlineTransparency = fifthValue or 0
        highlight.Parent = inputValue
        return highlight
    end
    addBillboard = function(inputValue, secondValue, thirdValue, fourthValue)
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Size = UDim2.new(0, 240, 0, 54)
        billboardGui.StudsOffset = fourthValue or Vector3.new(0, 3, 0)
        billboardGui.AlwaysOnTop = true
        billboardGui.Parent = inputValue
        local textLabel = Instance.new("TextLabel", billboardGui)
        textLabel.Size = UDim2.new(1, 0, 0, 24)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = thirdValue or Color3.new(1, 1, 1)
        textLabel.TextStrokeTransparency = 0.75
        textLabel.Text = type(secondValue) == "table" and tostring(secondValue.title or "") or tostring(secondValue)
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 13
        local textLabel2 = Instance.new("TextLabel", billboardGui)
        textLabel2.Position = UDim2.new(0, 0, 0, 22)
        textLabel2.Size = UDim2.new(1, 0, 0, 24)
        textLabel2.BackgroundTransparency = 1
        textLabel2.TextColor3 = Color3.fromRGB(220, 225, 235)
        textLabel2.TextStrokeTransparency = 0.85
        textLabel2.Font = Enum.Font.Gotham
        textLabel2.TextSize = 11
        local subtitle = type(secondValue) == "table" and secondValue.subtitle or nil
        if not subtitle then
            local worldPosition = getWorldPosition(inputValue)
            local islandForTarget = getIslandForTarget(inputValue)
            local simpleRoot = getSimpleRoot()
            local floorResult = simpleRoot and worldPosition and math.floor((simpleRoot.Position - worldPosition).Magnitude + 0.5) or nil
            subtitle = islandForTarget
            if floorResult then
                subtitle = string.format("%s • %dm", islandForTarget, floorResult)
            end
        end
        textLabel2.Text = tostring(subtitle or "")
        return billboardGui
    end
    applyESP_GodSpirit = function()
        clearESP("GodSpirit")
        espHighlights.GodSpirit = {}
        local god = Workspace:FindFirstChild("NPC") and Workspace.NPC:FindFirstChild("God")
        if not god then
            return
        end
        for _, item in ipairs(god:GetChildren()) do
            if not item:IsA("Model") then
                continue
            end
            local addBillboardResult = addBillboard(item, "God Spirit: " .. item.Name, Color3.fromRGB(255, 215, 0), Vector3.new(0, 5, 0))
            table.insert(espHighlights.GodSpirit, makeHighlight(item, Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 165, 0), 0.4, 0))
            table.insert(espHighlights.GodSpirit, addBillboardResult)
        end
    end
    applyESP_SecretRod = function()
        clearESP("SecretRod")
        espHighlights.SecretRod = {}
        local secretRod = Workspace:FindFirstChild("SecretRod")
        if not secretRod then
            return
        end
        for _, item in ipairs(secretRod:GetChildren()) do
            local addBillboardResult = addBillboard(item, "" .. item.Name, Color3.fromRGB(255, 200, 0))
            table.insert(espHighlights.SecretRod, makeHighlight(item, Color3.fromRGB(255, 50, 50), Color3.fromRGB(255, 200, 0), 0.3, 0))
            table.insert(espHighlights.SecretRod, addBillboardResult)
        end
    end
    applyESP_Boats = function()
        clearESP("Boats")
        espHighlights.Boats = {}
        local boat = Workspace:FindFirstChild("Boat")
        if not boat then
            return
        end
        for _, item in ipairs(boat:GetChildren()) do
            for _, item2 in ipairs(item:GetChildren()) do
                if not item2:IsA("Model") then
                    continue
                end
                local addBillboardResult = addBillboard(item2, "Boat @" .. item.Name, Color3.fromRGB(0, 200, 255))
                table.insert(espHighlights.Boats, makeHighlight(item2, Color3.fromRGB(0, 200, 255), Color3.fromRGB(255, 255, 255), 0.5, 0))
                table.insert(espHighlights.Boats, addBillboardResult)
            end
        end
    end
    applyESP_Maoshan = function()
        clearESP("Maoshan")
        espHighlights.Maoshan = {}
        local maoshan = Workspace:FindFirstChild("NPC") and Workspace.NPC:FindFirstChild("Function") and Workspace.NPC.Function:FindFirstChild("Maoshan")
        if not maoshan then
            return
        end
        local addBillboardResult = addBillboard(maoshan, "Maoshan", Color3.fromRGB(180, 0, 255))
        table.insert(espHighlights.Maoshan, makeHighlight(maoshan, Color3.fromRGB(180, 0, 255), Color3.fromRGB(255, 255, 255), 0.4, 0))
        table.insert(espHighlights.Maoshan, addBillboardResult)
    end
    applyESP_Taoist = function()
        clearESP("Taoist")
        espHighlights.Taoist = {}
        local taoist = Workspace:FindFirstChild("NPC") and Workspace.NPC:FindFirstChild("Function") and Workspace.NPC.Function:FindFirstChild("Taoist")
        if not taoist then
            return
        end
        local addBillboardResult = addBillboard(taoist, "Taoist", Color3.fromRGB(255, 120, 0))
        table.insert(espHighlights.Taoist, makeHighlight(taoist, Color3.fromRGB(255, 120, 0), Color3.fromRGB(255, 255, 255), 0.4, 0))
        table.insert(espHighlights.Taoist, addBillboardResult)
    end
    applyESP_Boss = function()
        clearESP("Boss")
        espHighlights.Boss = {}
        local boss = Workspace:FindFirstChild("NPC") and Workspace.NPC:FindFirstChild("Boss")
        if not boss then
            return
        end
        for _, item in ipairs(boss:GetChildren()) do
            if not item:IsA("Model") then
                continue
            end
            local addBillboardResult = addBillboard(item, "BOSS: " .. item.Name, Color3.fromRGB(255, 80, 80), Vector3.new(0, 7, 0))
            table.insert(espHighlights.Boss, makeHighlight(item, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 0), 0.3, 0))
            table.insert(espHighlights.Boss, addBillboardResult)
        end
    end
    applyESP_Players = function()
        clearESP("Players")
        espHighlights.Players = {}
        for _, item in ipairs(Players:GetPlayers()) do
            if item == LocalPlayer or not item.Character then
                continue
            end
            local addBillboardResult = addBillboard(item.Character, "" .. item.Name, Color3.fromRGB(0, 255, 100))
            table.insert(espHighlights.Players, makeHighlight(item.Character, Color3.fromRGB(0, 255, 100), Color3.fromRGB(255, 255, 255), 0.5, 0))
            table.insert(espHighlights.Players, addBillboardResult)
        end
    end
    applyESP_Nameless = function()
        clearESP("Nameless")
        espHighlights.Nameless = {}
        local rhyFindNamelessResult = type(rhyFindNameless) == "function" and rhyFindNameless() or nil
        if not rhyFindNamelessResult then
            return
        end
        local addBillboardResult = addBillboard(rhyFindNamelessResult, "Nameless Octoparasite", Color3.fromRGB(255, 100, 220), Vector3.new(0, 6, 0))
        table.insert(espHighlights.Nameless, makeHighlight(rhyFindNamelessResult, Color3.fromRGB(255, 80, 220), Color3.fromRGB(255, 255, 255), 0.35, 0))
        table.insert(espHighlights.Nameless, addBillboardResult)
    end
    applyESP_BlackTortoise = function()
        clearESP("BlackTortoise")
        espHighlights.BlackTortoise = {}
        local blackFindBossResult = blackFindBoss()
        if not blackFindBossResult then
            return
        end
        local colorValue = Color3.fromRGB(70, 230, 175)
        table.insert(espHighlights.BlackTortoise, makeHighlight(blackFindBossResult, colorValue, Color3.fromRGB(255, 255, 255), 0.35, 0))
        table.insert(espHighlights.BlackTortoise, addBillboard(blackFindBossResult, "Black Tortoise Bloodline", colorValue, Vector3.new(0, 6, 0)))
    end
    applyESP_Vermilion = function()
        clearESP("Vermilion")
        espHighlights.Vermilion = {}
        local vermilionFindBossResult = type(vermilionFindBoss) == "function" and vermilionFindBoss() or nil
        if not vermilionFindBossResult or not vermilionFindBossResult:IsA("Model") and not vermilionFindBossResult:IsA("BasePart") then
            return
        end
        local colorValue = Color3.fromRGB(255, 80, 45)
        table.insert(espHighlights.Vermilion, makeHighlight(vermilionFindBossResult, colorValue, Color3.fromRGB(255, 220, 80), 0.3, 0))
        table.insert(espHighlights.Vermilion, addBillboard(vermilionFindBossResult, "Vermilion Birdblood", colorValue, Vector3.new(0, 6, 0)))
    end
    applyESP_Weather = function()
        clearESP("Weather")
        espHighlights.Weather = {}
        local currentWeather = type(getCurrentWeather) == "function" and getCurrentWeather() or ""
        local recommendedWeatherIsland = type(getRecommendedWeatherIsland) == "function" and getRecommendedWeatherIsland(currentWeather) or nil
        if not recommendedWeatherIsland then
            return
        end
        local item
        local stateMap = {}
        for _, item2 in ipairs({
            "Islands",
            "Map",
            "World",
            "Locations",
            "Areas"
        }) do
            local workspaceEntry = Workspace:FindFirstChild(item2)
            if workspaceEntry then
                table.insert(stateMap, workspaceEntry)
            end
        end
        if #stateMap == 0 then
            table.insert(stateMap, Workspace)
        end
        for _, item3 in ipairs(stateMap) do
            if item then
                break
            end
            local item3Entry = item3:FindFirstChild(recommendedWeatherIsland)
            if item3Entry and (item3Entry:IsA("Model") or item3Entry:IsA("BasePart")) then
                item = item3Entry
                break
            end
            for _, item4 in ipairs(item3:GetDescendants()) do
                if item4.Name == recommendedWeatherIsland and (item4:IsA("Model") or item4:IsA("BasePart")) then
                    item = item4
                    break
                end
            end
        end
        if not item then
            return
        end
        local addBillboardResult = addBillboard(item, "Weather: " .. tostring(currentWeather), Color3.fromRGB(255, 220, 80), Vector3.new(0, 6, 0))
        table.insert(espHighlights.Weather, makeHighlight(item, Color3.fromRGB(255, 210, 40), Color3.fromRGB(255, 255, 255), 0.55, 0))
        table.insert(espHighlights.Weather, addBillboardResult)
    end
    espApplyFns = {
        GodSpirit = applyESP_GodSpirit,
        SecretRod = applyESP_SecretRod,
        Boats = applyESP_Boats,
        Maoshan = applyESP_Maoshan,
        Taoist = applyESP_Taoist,
        Boss = applyESP_Boss,
        Players = applyESP_Players,
        Weather = applyESP_Weather,
        Nameless = applyESP_Nameless,
        BlackTortoise = applyESP_BlackTortoise,
        Vermilion = applyESP_Vermilion
    }
    task.spawn(function()
        while true do
            task.wait(10)
            for key, entry in pairs(getgenv().NNVN_ESP) do
                if entry then
                    pcall(espApplyFns[key] or function() end)
                end
            end
        end
    end)
    espSec = mainMap.Visual:AddSection({ Title = "ESP Objects", Icon = "eye" })
    espDefs = {
        { key = "GodSpirit", title = "God Spirit ESP", desc = "Gold highlight" },
        { key = "SecretRod", title = "Secret Rod ESP", desc = "Red highlight" },
        { key = "Boats", title = "Boats ESP", desc = "Cyan highlight" },
        { key = "Maoshan", title = "Maoshan ESP", desc = "Purple highlight" },
        { key = "Taoist", title = "Taoist ESP", desc = "Orange highlight" },
        { key = "Boss", title = "Boss ESP", desc = "Red highlight" },
        { key = "Players", title = "Players ESP", desc = "Green highlight" },
        {
            key = "Weather",
            title = "Weather ESP",
            desc = "Highlights the recommended weather island"
        },
        {
            key = "Nameless",
            title = "Nameless Octoparasite ESP",
            desc = "Pink highlight"
        },
        {
            key = "BlackTortoise",
            title = "Black Tortoise Bloodline ESP",
            desc = "Green highlight"
        },
        {
            key = "Vermilion",
            title = "Vermilion Birdblood ESP",
            desc = "Orange highlight"
        }
    }
    for _, item38 in ipairs(espDefs) do
        espSec:AddToggle("ESP_" .. item38.key, {
            Title = item38.title,
            Description = item38.desc,
            Default = false,
            Callback = function(selectedValue)
                getgenv().NNVN_ESP[item38.key] = selectedValue
                if selectedValue then
                    pcall(espApplyFns[item38.key] or function() end)
                else
                    clearESP(item38.key)
                end
            end
        })
    end
    espSec:AddToggle("NNVN_SkillsESP_ESP", {
        Title = "Skills ESP",
        Description = "Show equipped rod skills above all other players' heads.",
        Default = getgenv().NNVN_SkillsESP == true,
        Callback = function(selectedValue)
            if type(NNVN_SetSkillsESP) == "function" then
                NNVN_SetSkillsESP(selectedValue == true)
            else
                getgenv().NNVN_SkillsESP = selectedValue == true
            end
        end
    })
    espSec:AddButton({
        Title = "Refresh All Active ESP",
        Callback = function()
            for key, entry in pairs(getgenv().NNVN_ESP) do
                if entry then
                    pcall(espApplyFns[key] or function() end)
                end
            end
            if getgenv().NNVN_Notify then
                item:Notify({ Title = "", Content = "ESP refreshed!", Duration = 2 })
            end
        end
    })
    espSec:AddButton({
        Title = "Clear All ESP",
        Callback = function()
            for entryKey in pairs(getgenv().NNVN_ESP) do
                getgenv().NNVN_ESP[entryKey] = false
                clearESP(entryKey)
            end
            if getgenv().NNVN_Notify then
                item:Notify({ Title = "", Content = "All ESP cleared!", Duration = 2 })
            end
        end
    })
    GetIndexRemoteCandidates = function()
        local events = ReplicatedStorage:FindFirstChild("Events")
        if not events then
            return {}
        end
        local stateMap = {}
        for _, item in ipairs(events:GetDescendants()) do
            local formattedText = string.lower(item.Name or "")
            if (item:IsA("RemoteEvent") or item:IsA("RemoteFunction")) and (formattedText:find("index") or formattedText:find("unlock") or formattedText:find("discover") or formattedText:find("journal") or formattedText:find("bestiary") or formattedText:find("collection")) then
                table.insert(stateMap, item)
            end
        end
        return stateMap
    end
    TryUnlockAllIndexRisk = function()
        local allFishNames = GetAllFishNames()
        local indexRemoteCandidates = GetIndexRemoteCandidates()
        if #allFishNames == 0 then
            return false, "No fish/index names found in client."
        end
        if #indexRemoteCandidates == 0 then
            return false, "No unlock/index remote exposed to client."
        end
        local counter = 0
        for _, item in ipairs(indexRemoteCandidates) do
            for _, item2 in ipairs(allFishNames) do
                pcall(function()
                    if item:IsA("RemoteEvent") then
                        item:FireServer(item2)
                        item:FireServer("Fish", item2)
                        item:FireServer({ Name = item2 })
                    else
                        item:InvokeServer(item2)
                        item:InvokeServer("Fish", item2)
                        item:InvokeServer({ Name = item2 })
                    end
                end)
                counter = counter + 1
                task.wait(0.05)
            end
        end
        return counter > 0, "Tried " .. tostring(counter) .. " index unlock calls on " .. tostring(#indexRemoteCandidates) .. " remote(s)."
    end
    afkSec = mainMap.Extra:AddSection({ Title = "AFK", Icon = "timer" })
    afkSec:AddToggle("NNVN_AntiAFK", {
        Title = "Anti AFK",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AntiAFK = enabled
        end
    })
    afkSec:AddToggle("NNVN_AntiStaff", {
        Title = "Anti Staff",
        Description = "Anti-staff disabled.",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AntiStaff = false
        end
    })
    afkSec:AddDropdown("NNVN_AntiStaffAction", {
        Title = "Anti Staff Action",
        Description = "What to do when staff is detected",
        Values = { "Notify", "Kick", "ServerHop" },
        Value = "Notify",
        Callback = function(selectedValue)
            getgenv().NNVN_AntiStaffAction = "Notify"
        end
    })
    NNVN_SetInvisible = function(inputValue)
        local isMatched = inputValue == true
        local character = LocalPlayer.Character
        if isMatched and getgenv().NNVN_Invisible and getgenv()._NNVN_InvisibleSaved and getgenv()._NNVN_InvisibleCharacter == character then
            return
        end
        getgenv().NNVN_Invisible = isMatched
        local invisibleCamFocus = workspace:FindFirstChild("NNVN_InvisibleCamFocus")
        local invisibleFloor = workspace:FindFirstChild("NNVN_InvisibleFloor")
        if invisibleCamFocus and currentCamera.CameraSubject == invisibleCamFocus then
            local character2 = LocalPlayer.Character
            local humanoid = character2 and character2:FindFirstChildOfClass("Humanoid")
            if humanoid then
                currentCamera.CameraSubject = humanoid
            end
            currentCamera.CameraType = Enum.CameraType.Custom
        end
        if invisibleCamFocus then
            invisibleCamFocus:Destroy()
        end
        if invisibleFloor then
            invisibleFloor:Destroy()
        end
        if getgenv()._NNVN_InvisibleConn then
            pcall(function()
                getgenv()._NNVN_InvisibleConn:Disconnect()
            end)
            getgenv()._NNVN_InvisibleConn = nil
        end
        for _, item in ipairs(getgenv()._NNVN_InvisibleConnections or {}) do
            pcall(function()
                item:Disconnect()
            end)
        end
        getgenv()._NNVN_InvisibleConnections = {}
        if getgenv().NNVN_Invisible then
            local character3 = LocalPlayer.Character
            if not character3 then
                getgenv().NNVN_Invisible = false
                return
            end
            getgenv()._NNVN_InvisibleSaved = {}
            getgenv()._NNVN_InvisibleCharacter = character3
            local invisibleConnections = getgenv()._NNVN_InvisibleConnections
            local function updateBillboard(instance)
                if instance:IsA("BasePart") then
                    instance.LocalTransparencyModifier = 1
                    instance.CastShadow = false
                elseif instance:IsA("Decal") or instance:IsA("Texture") then
                    instance.Transparency = 1
                elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") or instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles") then
                    instance.Enabled = false
                elseif instance:IsA("BillboardGui") then
                    instance.Enabled = false
                elseif instance:IsA("ForceField") then
                    instance.Visible = false
                end
            end
            local function updateBillboard2(instance)
                local invisibleSaved = getgenv()._NNVN_InvisibleSaved
                if not invisibleSaved then
                    return
                end
                if instance:IsA("BasePart") then
                    if not invisibleSaved[instance] then
                        invisibleSaved[instance] = {
                            kind = "part",
                            localTransparency = instance.LocalTransparencyModifier,
                            castShadow = instance.CastShadow
                        }
                    end
                elseif instance:IsA("Decal") or instance:IsA("Texture") then
                    if not invisibleSaved[instance] then
                        invisibleSaved[instance] = { kind = "transparency", value = instance.Transparency }
                    end
                elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") or instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles") then
                    if not invisibleSaved[instance] then
                        invisibleSaved[instance] = { kind = "enabled", value = instance.Enabled }
                    end
                elseif instance:IsA("BillboardGui") then
                    if not invisibleSaved[instance] then
                        invisibleSaved[instance] = { kind = "enabled", value = instance.Enabled }
                    end
                elseif instance:IsA("ForceField") and not invisibleSaved[instance] then
                    invisibleSaved[instance] = { kind = "visible", value = instance.Visible }
                end
                pcall(updateBillboard, instance)
            end
            for _, item2 in ipairs(character3:GetDescendants()) do
                pcall(updateBillboard2, item2)
            end
            local humanoid2 = character3:FindFirstChildOfClass("Humanoid")
            if humanoid2 then
                getgenv()._NNVN_InvisibleHumanoid = {
                    object = humanoid2,
                    display = humanoid2.DisplayDistanceType,
                    health = humanoid2.HealthDisplayDistance,
                    name = humanoid2.NameDisplayDistance
                }
                humanoid2.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                humanoid2.HealthDisplayDistance = 0
                humanoid2.NameDisplayDistance = 0
            end
            getgenv()._NNVN_InvisibleConn = character3.DescendantAdded:Connect(function(child)
                if getgenv().NNVN_Invisible then
                    task.delay(0.12, function()
                        if getgenv().NNVN_Invisible and LocalPlayer.Character == character3 and child.Parent then
                            pcall(updateBillboard2, child)
                        end
                    end)
                end
            end)
        else
            for key, entry in pairs(getgenv()._NNVN_InvisibleSaved or {}) do
                if key and key.Parent then
                    pcall(function()
                        if entry.kind == "part" then
                            key.LocalTransparencyModifier = entry.localTransparency
                            key.CastShadow = entry.castShadow
                        elseif entry.kind == "transparency" then
                            key.Transparency = entry.value
                        elseif entry.kind == "enabled" then
                            key.Enabled = entry.value
                        elseif entry.kind == "visible" then
                            key.Visible = entry.value
                        end
                    end)
                end
            end
            getgenv()._NNVN_InvisibleSaved = nil
            getgenv()._NNVN_InvisibleCharacter = nil
            local invisibleHumanoid = getgenv()._NNVN_InvisibleHumanoid
            if invisibleHumanoid and invisibleHumanoid.object and invisibleHumanoid.object.Parent then
                pcall(function()
                    invisibleHumanoid.object.DisplayDistanceType = invisibleHumanoid.display
                    invisibleHumanoid.object.HealthDisplayDistance = invisibleHumanoid.health
                    invisibleHumanoid.object.NameDisplayDistance = invisibleHumanoid.name
                end)
            end
            getgenv()._NNVN_InvisibleHumanoid = nil
        end
    end
    getgenv().NNVN_NormalFPSBoost = getgenv().NNVN_NormalFPSBoost == true
    getgenv().NNVN_UltraFPSBoost = getgenv().NNVN_UltraFPSBoost == true
    local stateMap11 = {}
    local stateMap12 = {}
    local hasTriggered4 = false
    local function executeAction4(inputValue, secondValue)
        stateMap11[inputValue] = stateMap11[inputValue] or {}
        if stateMap11[inputValue][secondValue] == nil then
            local ok, result = pcall(function()
                return inputValue[secondValue]
            end)
            if ok then
                stateMap11[inputValue][secondValue] = result
            end
        end
    end
    local function executeAction5(inputValue, secondValue, thirdValue)
        executeAction4(inputValue, secondValue)
        pcall(function()
            inputValue[secondValue] = thirdValue
        end)
    end
    local function executeAction6()
        for _, item in ipairs(stateMap12) do
            pcall(function()
                item:Disconnect()
            end)
        end
        stateMap12 = {}
    end
    restoreNNVNFPSBoost = function()
        executeAction6()
        for key, entry in pairs(stateMap11) do
            if key then
                for key2, entry2 in pairs(entry) do
                    pcall(function()
                        key[key2] = entry2
                    end)
                end
            end
        end
        stateMap11 = {}
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        end)
    end
    local function applyHighlight(instance, secondValue)
        if instance:IsA("BasePart") then
            executeAction5(instance, "Material", Enum.Material.SmoothPlastic)
            executeAction5(instance, "Reflectance", 0)
            if secondValue then
                executeAction5(instance, "CastShadow", false)
                executeAction5(instance, "Color", Color3.fromRGB(245, 245, 245))
                executeAction5(instance, "MaterialVariant", "")
                if instance:IsA("MeshPart") then
                    executeAction5(instance, "TextureID", "")
                end
            end
        elseif instance:IsA("Decal") or instance:IsA("Texture") then
            executeAction5(instance, "Transparency", secondValue and 1 or 0.65)
            if secondValue then
                executeAction5(instance, "Texture", "")
            end
        elseif secondValue and instance:IsA("SpecialMesh") then
            executeAction5(instance, "TextureId", "")
            executeAction5(instance, "VertexColor", Vector3.new(1, 1, 1))
        elseif secondValue and instance:IsA("SurfaceAppearance") then
            executeAction5(instance, "ColorMap", "")
            executeAction5(instance, "MetalnessMap", "")
            executeAction5(instance, "NormalMap", "")
            executeAction5(instance, "RoughnessMap", "")
        elseif secondValue and instance:IsA("Sky") then
            executeAction5(instance, "SkyboxBk", "")
            executeAction5(instance, "SkyboxDn", "")
            executeAction5(instance, "SkyboxFt", "")
            executeAction5(instance, "SkyboxLf", "")
            executeAction5(instance, "SkyboxRt", "")
            executeAction5(instance, "SkyboxUp", "")
            executeAction5(instance, "CelestialBodiesShown", false)
        elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") or instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles") or instance:IsA("Highlight") then
            executeAction5(instance, "Enabled", false)
        elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
            executeAction5(instance, "Enabled", false)
        elseif secondValue and instance:IsA("PostEffect") then
            executeAction5(instance, "Enabled", false)
        elseif secondValue and (instance:IsA("Atmosphere") or instance:IsA("Clouds")) then
            executeAction5(instance, "Parent", nil)
        end
    end
    applyNNVNFPSBoost = function(inputValue)
        if hasTriggered4 then
            getgenv().NNVN_PendingFPSMode = inputValue
            return
        end
        hasTriggered4 = true
        task.spawn(function()
            local isMatched = tostring(inputValue) == "Ultra"
            getgenv().NNVN_NormalFPSBoost = not isMatched
            getgenv().NNVN_UltraFPSBoost = isMatched
            executeAction6()
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
            executeAction5(Lighting, "GlobalShadows", false)
            executeAction5(Lighting, "FogEnd", 1000000)
            executeAction5(Lighting, "EnvironmentDiffuseScale", 0)
            executeAction5(Lighting, "EnvironmentSpecularScale", 0)
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                executeAction5(terrain, "Decoration", false)
                executeAction5(terrain, "WaterWaveSize", 0)
                executeAction5(terrain, "WaterWaveSpeed", 0)
                executeAction5(terrain, "WaterReflectance", 0)
                executeAction5(terrain, "WaterTransparency", isMatched and 1 or 0.75)
                if isMatched then
                    executeAction5(terrain, "WaterColor", Color3.fromRGB(245, 245, 245))
                end
            end
            local counter = 0
            for _, item in ipairs({ Workspace, Lighting }) do
                for _, item2 in ipairs(item:GetDescendants()) do
                    pcall(applyHighlight, item2, isMatched)
                    counter = counter + 1
                    if counter % 250 == 0 then
                        task.wait()
                    end
                end
            end
            local function resolveInsert(inputValue)
                table.insert(stateMap12, inputValue.DescendantAdded:Connect(function(child)
                    if getgenv().NNVN_NormalFPSBoost or getgenv().NNVN_UltraFPSBoost then
                        task.defer(function()
                            pcall(applyHighlight, child, getgenv().NNVN_UltraFPSBoost == true)
                        end)
                    end
                end))
            end
            resolveInsert(Workspace)
            resolveInsert(Lighting)
            hasTriggered4 = false
            local pendingFpsMode = getgenv().NNVN_PendingFPSMode
            getgenv().NNVN_PendingFPSMode = nil
            if pendingFpsMode and tostring(pendingFpsMode) ~= tostring(inputValue) then
                applyNNVNFPSBoost(pendingFpsMode)
            end
        end)
    end
    local performanceSection = mainMap.Visual:AddSection({ Title = "Performance", Icon = "gauge" })
    performanceSection:AddDropdown("NNVN_PerformanceMode", {
        Title = "Performance Mode",
        Description = "Off restores graphics. Normal reduces effects. Ultra applies the strongest FPS reduction.",
        Values = { "Off", "Normal", "Ultra" },
        Default = getgenv().NNVN_UltraFPSBoost and "Ultra" or getgenv().NNVN_NormalFPSBoost and "Normal" or "Off",
        Callback = function(enabled)
            if enabled == "Ultra" then
                getgenv().NNVN_NormalFPSBoost = false
                applyNNVNFPSBoost("Ultra")
            elseif enabled == "Normal" then
                getgenv().NNVN_UltraFPSBoost = false
                applyNNVNFPSBoost("Normal")
            else
                getgenv().NNVN_NormalFPSBoost = false
                getgenv().NNVN_UltraFPSBoost = false
                restoreNNVNFPSBoost()
            end
        end
    })
    performanceSection:AddToggle("NNVN_NormalFPSBoost", {
        Title = "Normal FPS Boost",
        Description = "Reduces shadows, effects, textures, and water detail.",
        Default = getgenv().NNVN_NormalFPSBoost,
        Callback = function(enabled)
            if enabled then
                getgenv().NNVN_UltraFPSBoost = false
                applyNNVNFPSBoost("Normal")
            elseif not getgenv().NNVN_UltraFPSBoost then
                restoreNNVNFPSBoost()
            end
        end
    })
    performanceSection:AddToggle("NNVN_UltraFPSBoost", {
        Title = "Ultra FPS Boost",
        Description = "More aggressive rendering reduction; visuals may become very basic.",
        Default = getgenv().NNVN_UltraFPSBoost,
        Callback = function(selectedValue)
            if selectedValue then
                getgenv().NNVN_NormalFPSBoost = false
                applyNNVNFPSBoost("Ultra")
            elseif not getgenv().NNVN_NormalFPSBoost then
                restoreNNVNFPSBoost()
            end
        end
    })
    pcall(function()
        local lowFpsWarning = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("NNVN_LowFPSWarning")
        if lowFpsWarning then
            lowFpsWarning:Destroy()
        end
        local lowFpsBlur = Lighting:FindFirstChild("NNVN_LowFPSBlur")
        if lowFpsBlur then
            lowFpsBlur:Destroy()
        end
    end)
    local item39
    local counter7 = 0
    local huge = math.huge
    local function cleanupResource3()
        counter7 = counter7 + 1
        if not item39 then
            return
        end
        local lowFpsBlur = Lighting:FindFirstChild("NNVN_LowFPSBlur")
        if lowFpsBlur then
            lowFpsBlur:Destroy()
        end
        item39.Enabled = false
    end
    local function resolveUltraFpsBoost(inputValue)
        if getgenv().NNVN_UltraFPSBoost or getgenv().NNVN_LowFPSPromptShown or item39 and item39.Enabled then
            return
        end
        getgenv().NNVN_LowFPSPromptShown = true
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then
            return
        end
        if not item39 then
            item39 = Instance.new("ScreenGui")
            item39.Name = "NNVN_LowFPSWarning"
            item39.ResetOnSpawn = false
            item39.DisplayOrder = 1000
            item39.Parent = playerGui
            local frame = Instance.new("Frame")
            frame.Name = "Backdrop"
            frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            frame.BackgroundTransparency = 1
            frame.BorderSizePixel = 0
            frame.Size = UDim2.fromScale(1, 1)
            frame.Visible = false
            frame.Parent = item39
            local frame2 = Instance.new("Frame")
            frame2.Name = "Card"
            frame2.AnchorPoint = Vector2.new(1, 1)
            frame2.Position = UDim2.new(1, -18, 1, -18)
            frame2.Size = UDim2.fromOffset(360, 148)
            frame2.BackgroundColor3 = Color3.fromRGB(8, 13, 29)
            frame2.BorderSizePixel = 0
            frame2.ZIndex = 2
            frame2.Parent = item39
            Instance.new("UICorner", frame2).CornerRadius = UDim.new(0, 10)
            Instance.new("UIScale", frame2).Scale = 1
            local uiStroke = Instance.new("UIStroke", frame2)
            uiStroke.Color = Color3.fromRGB(38, 91, 160)
            uiStroke.Transparency = 0.25
            local textLabel = Instance.new("TextLabel")
            textLabel.Name = "Message"
            textLabel.BackgroundTransparency = 1
            textLabel.Position = UDim2.fromOffset(14, 10)
            textLabel.Size = UDim2.new(1, -28, 0, 45)
            textLabel.Font = Enum.Font.GothamMedium
            textLabel.TextColor3 = Color3.fromRGB(235, 242, 255)
            textLabel.TextSize = 14
            textLabel.TextWrapped = true
            textLabel.ZIndex = 3
            textLabel.Parent = frame2
            local textButton = Instance.new("TextButton")
            textButton.Name = "Yes"
            textButton.Text = "Yes"
            textButton.Font = Enum.Font.GothamBold
            textButton.TextSize = 13
            textButton.TextColor3 = Color3.new(1, 1, 1)
            textButton.BackgroundColor3 = Color3.fromRGB(26, 87, 153)
            textButton.Size = UDim2.fromOffset(145, 32)
            textButton.Position = UDim2.fromOffset(14, 66)
            textButton.ZIndex = 3
            textButton.Parent = frame2
            Instance.new("UICorner", textButton).CornerRadius = UDim.new(0, 7)
            textButton.Activated:Connect(function()
                getgenv().NNVN_UltraFPSBoost = true
                getgenv().NNVN_NormalFPSBoost = false
                applyNNVNFPSBoost("Ultra")
                cleanupResource3()
            end)
            local textButton2 = Instance.new("TextButton")
            textButton2.Name = "No"
            textButton2.Text = "No"
            textButton2.Font = Enum.Font.GothamBold
            textButton2.TextSize = 13
            textButton2.TextColor3 = Color3.fromRGB(220, 228, 245)
            textButton2.BackgroundColor3 = Color3.fromRGB(24, 31, 50)
            textButton2.Size = UDim2.fromOffset(145, 32)
            textButton2.Position = UDim2.fromOffset(201, 66)
            textButton2.ZIndex = 3
            textButton2.Parent = frame2
            Instance.new("UICorner", textButton2).CornerRadius = UDim.new(0, 7)
            textButton2.Activated:Connect(cleanupResource3)
            local textButton3 = Instance.new("TextButton")
            textButton3.Name = "Never"
            textButton3.Text = "Do not show again"
            textButton3.Font = Enum.Font.GothamMedium
            textButton3.TextSize = 12
            textButton3.TextColor3 = Color3.fromRGB(175, 190, 220)
            textButton3.BackgroundTransparency = 1
            textButton3.Size = UDim2.new(1, -28, 0, 24)
            textButton3.Position = UDim2.fromOffset(14, 112)
            textButton3.ZIndex = 3
            textButton3.Parent = frame2
            textButton3.Activated:Connect(function()
                getgenv().NNVN_DisableUltraFPSPrompt = true
                cleanupResource3()
            end)
        end
        local card = item39:FindFirstChild("Card")
        local message = card and card:FindFirstChild("Message")
        if message then
            message.Text = string.format("Your FPS is unstable (%d FPS). Enable Ultra FPS Boost?", math.floor(inputValue))
        end
        item39.Enabled = true
        counter7 = counter7 + 1
        local counter72 = counter7
        task.delay(10, function()
            if counter72 == counter7 then
                cleanupResource3()
            end
        end)
    end
    task.spawn(function()
        while getgenv().NNVN_Loaded ~= true do
            task.wait(0.25)
        end
        huge = os.clock() + 8
    end)
    task.spawn(function()
        local counter = 0
        local counter2 = 0
        local connection = RunService.RenderStepped:Connect(function(deltaTime)
            counter = counter + 1
            counter2 = counter2 + deltaTime
            if counter2 < 1 then
                return
            end
            local computedValue = counter / counter2
            getgenv().NNVN_StatusFPS = math.floor(computedValue + 0.5)
            counter = 0
            counter2 = 0
            if getgenv().NNVN_Loaded == true and huge <= os.clock() and not getgenv().NNVN_DisableUltraFPSPrompt and not getgenv().NNVN_LowFPSPromptShown and computedValue <= 20 and not getgenv().NNVN_UltraFPSBoost then
                resolveUltraFpsBoost(computedValue)
            end
        end)
        task.wait(7200)
        if connection then
            connection:Disconnect()
        end
    end)
    utilSec = mainMap.Extra:AddSection({ Title = "Utilities", Icon = "wrench" })
    utilSec:AddToggle("NNVN_AutoRejoin", {
        Title = "Auto Rejoin",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_AutoRejoin = enabled
        end
    })
    utilSec:AddToggle("NNVN_Notify", {
        Title = "Notifications",
        Default = true,
        Callback = function(enabled)
            getgenv().NNVN_Notify = enabled
        end
    })
    utilSec:AddToggle("NNVN_Watermark", {
        Title = "Show Watermark",
        Description = "Shows or hides the hub status watermark.",
        Default = getgenv().NNVN_Watermark == true,
        Callback = function(enabled)
            NNVN_SetWatermarkVisible(enabled == true)
        end
    })
    local item40
    utilSec:AddToggle("NNVN_BlankPlayerId", {
        Title = "Hide Player ID",
        Description = "Sets the top-right player ID text to blank.",
        Default = getgenv().NNVN_BlankPlayerId == true,
        Callback = function(enabled)
            getgenv().NNVN_BlankPlayerId = enabled == true
            applyHidePlayerId()
        end
    })
    utilSec:AddToggle("NNVN_HidePlayerId", {
        Title = "Custom Player ID",
        Description = "Replaces the top-right player ID text.",
        Default = getgenv().NNVN_HidePlayerId,
        Callback = function(inputText)
            getgenv().NNVN_HidePlayerId = inputText == true
            if item40 and item40.SetVisible then
                item40:SetVisible(inputText == true)
            end
            applyHidePlayerId()
        end
    })
    item40 = utilSec:AddInput("NNVN_CustomPlayerId", {
        Title = "Custom ID",
        Placeholder = tostring(LocalPlayer.UserId),
        Default = getgenv().NNVN_CustomPlayerId,
        Finished = true,
        Visible = getgenv().NNVN_HidePlayerId == true,
        Callback = function(amount)
            getgenv().NNVN_CustomPlayerId = tostring(amount or "")
            if getgenv().NNVN_HidePlayerId then
                applyHidePlayerId()
            end
        end
    })
    utilSec:AddSlider("NNVN_WalkSpeed", {
        Title = "WalkSpeed",
        Default = 16,
        Min = 8,
        Max = 100,
        Rounding = 1,
        Callback = function(selectedValue)
            getgenv().NNVN_WalkSpeed = selectedValue
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = selectedValue
                end
            end
        end
    })
    utilSec:AddButton({
        Title = "Redeem All Codes",
        Description = "Try Data.Code (Khfresh style) first, then fallback old list",
        Callback = function()
            task.spawn(function()
                local counter = 0
                local stateMap = {}
                local hasTriggered = false
                local function resolveGsub(inputValue)
                    inputValue = tostring(inputValue or ""):gsub("^%s+", ""):gsub("%s+$", "")
                    if inputValue == "" or stateMap[inputValue] then
                        return
                    end
                    stateMap[inputValue] = true
                    pcall(function()
                        ReplicatedStorage.Events.RedeemCode:FireServer(inputValue)
                    end)
                    counter = counter + 1
                    task.wait(0.25)
                end
                pcall(function()
                    local data = ReplicatedStorage:FindFirstChild("Data")
                    if not data then
                        return
                    end
                    local code = data:FindFirstChild("Code", true)
                    if not code then
                        return
                    end
                    local objectList = code:GetChildren()
                    if #objectList == 0 then
                        return
                    end
                    hasTriggered = true
                    for _, entry in pairs(objectList) do
                        resolveGsub(entry.Name)
                    end
                end)
                for _, item2 in ipairs({
                    "UIBUG",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "Taiji",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    ""
                }) do
                    resolveGsub(item2)
                end
                if getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Redeem Codes",
                        Content = string.format("Sent %d code(s)! Mode: %s", counter, hasTriggered and "Dynamic+Fallback" or "Fallback only"),
                        Duration = 3
                    })
                end
            end)
        end
    })
    utilSec:AddButton({
        Title = "Rejoin",
        Callback = function()
            if getgenv().NNVN_Notify then
                item:Notify({ Title = "", Content = "Rejoining in 3 seconds...", Duration = 3 })
            end
            task.wait(3)
            TeleportService:TeleportToPlaceInstance(placeId, game.JobId, LocalPlayer)
        end
    })
    indexRiskSec = mainMap.Extra:AddSection({ Title = "Index", Icon = "book-open" })
    indexRiskSec:AddButton({
        Title = "Unlock all fish (Risk)",
        Callback = function()
            local data = ReplicatedStorage:FindFirstChild("Data")
            local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
            if not playerData then
                if getgenv().NNVN_Notify then
                    item:Notify({ Title = "Index", Content = "User data not found!", Duration = 2 })
                end
                return
            end
            local index = playerData:FindFirstChild("Index")
            if not index then
                if getgenv().NNVN_Notify then
                    item:Notify({ Title = "Index", Content = "Index folder not found!", Duration = 2 })
                end
                return
            end
            local counter = 0
            for _, item2 in ipairs(index:GetChildren()) do
                if item2:IsA("NumberValue") or item2:IsA("IntValue") then
                    item2.Value = 1
                    counter = counter + 1
                elseif item2:IsA("BoolValue") then
                    item2.Value = true
                    counter = counter + 1
                end
            end
            if getgenv().NNVN_Notify then
                item:Notify({
                    Title = "Index",
                    Content = "Unlocked " .. counter .. " fish!",
                    Duration = 3
                })
            end
        end
    })
    flyState = {
        flying = false,
        bg = nil,
        bv = nil,
        flyKeys = { Up = false, Down = false },
        speed = 50
    }
    startFly = function()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end
        if flyState.flying then
            return
        end
        if flyState.bg then
            flyState.bg:Destroy()
        end
        if flyState.bv then
            flyState.bv:Destroy()
        end
        local humanoidRootPart = character.HumanoidRootPart
        flyState.bg = Instance.new("BodyGyro", humanoidRootPart)
        flyState.bg.P = 90000
        flyState.bg.maxTorque = Vector3.new(9000000000, 9000000000, 9000000000)
        flyState.bg.cframe = humanoidRootPart.CFrame
        flyState.bv = Instance.new("BodyVelocity", humanoidRootPart)
        flyState.bv.velocity = Vector3.new(0, 0, 0)
        flyState.bv.maxForce = Vector3.new(9000000000, 9000000000, 9000000000)
        flyState.flying = true
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
        end
    end
    stopFly = function()
        flyState.flying = false
        flyState.flyKeys.Up = false
        flyState.flyKeys.Down = false
        if flyState.bg then
            flyState.bg:Destroy()
            flyState.bg = nil
        end
        if flyState.bv then
            flyState.bv:Destroy()
            flyState.bv = nil
        end
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end
    flyInputCon = nil
    flyInputEndCon = nil
    utilSec:AddToggle("NNVN_FlyMode", {
        Title = "Fly Mode",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_FlyMode = enabled
            if enabled then
                startFly()
                if flyInputCon then
                    flyInputCon:Disconnect()
                end
                if flyInputEndCon then
                    flyInputEndCon:Disconnect()
                end
                flyInputCon = UserInputService.InputBegan:Connect(function(input)
                    if input.KeyCode == Enum.KeyCode.Space then
                        flyState.flyKeys.Up = true
                    end
                    if input.KeyCode == Enum.KeyCode.LeftControl then
                        flyState.flyKeys.Down = true
                    end
                end)
                flyInputEndCon = UserInputService.InputEnded:Connect(function(input)
                    if input.KeyCode == Enum.KeyCode.Space then
                        flyState.flyKeys.Up = false
                    end
                    if input.KeyCode == Enum.KeyCode.LeftControl then
                        flyState.flyKeys.Down = false
                    end
                end)
            else
                stopFly()
                if flyInputCon then
                    flyInputCon:Disconnect()
                    flyInputCon = nil
                end
                if flyInputEndCon then
                    flyInputEndCon:Disconnect()
                    flyInputEndCon = nil
                end
            end
        end
    })
    utilSec:AddSlider("NNVN_FlySpeed", {
        Title = "Fly Speed",
        Default = 50,
        Min = 10,
        Max = 200,
        Rounding = 1,
        Callback = function(enabled)
            getgenv().NNVN_FlySpeed = enabled
            flyState.speed = enabled
        end
    })
    utilSec:AddToggle("NNVN_InfiniteJump", {
        Title = "Infinite Jump",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_InfiniteJump = enabled
        end
    })
end

do
    trollSec = mainMap.Extra:AddSection({ Title = "Backflip", Icon = "rotate-cw" })
    trollSec:AddToggle("NNVN_Backflip", {
        Title = "Backflip",
        Description = "Flip forward repeatedly. Adjust distance below.",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_Backflip = enabled and true or false
            getgenv().NNVN_BackflipLoopId = (getgenv().NNVN_BackflipLoopId or 0) + 1
            local backflipLoopId = getgenv().NNVN_BackflipLoopId
            if not getgenv().NNVN_Backflip then
                return
            end
            task.spawn(function()
                while getgenv().NNVN_Backflip and backflipLoopId == getgenv().NNVN_BackflipLoopId do
                    pcall(function()
                        if type(getgenv().NNVN_DoBackflip) == "function" then
                            getgenv().NNVN_DoBackflip()
                        end
                    end)
                    task.wait(1.15)
                end
            end)
        end
    })
    trollSec:AddSlider("NNVN_BackflipDistance", {
        Title = "Backflip Distance",
        Default = tonumber(getgenv().NNVN_BackflipDistance) or 8,
        Min = 1,
        Max = 15,
        Rounding = 1,
        Callback = function(selectedValue)
            getgenv().NNVN_BackflipDistance = math.clamp(tonumber(selectedValue) or 8, 1, 15)
        end
    })
    trollSec:AddButton({
        Title = "Backflip Once",
        Icon = "rotate-cw",
        Callback = function()
            pcall(function()
                if type(getgenv().NNVN_DoBackflip) == "function" then
                    getgenv().NNVN_DoBackflip()
                end
            end)
        end
    })
    waterWalk = {
        enabled = false,
        waterPart = nil,
        waterY = 0,
        connection = nil,
        waterPartsList = {}
    }
    findWaterParts = function()
        local stateMap = {}
        for _, entry in pairs(Workspace:GetDescendants()) do
            if not entry:IsA("BasePart") then
                continue
            end
            local formattedText = entry.Name:lower()
            if formattedText:match("water") or formattedText:match("ocean") or entry.Material == Enum.Material.Water then
                table.insert(stateMap, entry)
            end
        end
        return stateMap
    end
    enableWaterWalk = function()
        if waterWalk.enabled then
            return
        end
        waterWalk.enabled = true
        waterWalk.waterPartsList = findWaterParts()
        for _, item in ipairs(waterWalk.waterPartsList) do
            item.CanCollide = true
        end
        waterWalk.waterPart = Instance.new("Part")
        waterWalk.waterPart.Size = Vector3.new(16, 1, 16)
        waterWalk.waterPart.Transparency = 1
        waterWalk.waterPart.Anchored = true
        waterWalk.waterPart.CanCollide = true
        waterWalk.waterPart.Name = "WaterWalkPart"
        waterWalk.waterPart.Parent = Workspace
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            waterWalk.waterY = character.HumanoidRootPart.Position.Y - 3.2
        else
            waterWalk.waterY = 0
        end
        if waterWalk.connection then
            waterWalk.connection:Disconnect()
        end
        waterWalk.connection = RunService.RenderStepped:Connect(function()
            if not waterWalk.enabled then
                return
            end
            local character = LocalPlayer.Character
            if not character then
                return
            end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then
                return
            end
            if waterWalk.waterPart then
                waterWalk.waterPart.Position = Vector3.new(rootPart.Position.X, waterWalk.waterY, rootPart.Position.Z)
            end
        end)
    end
    disableWaterWalk = function()
        if not waterWalk.enabled then
            return
        end
        waterWalk.enabled = false
        if waterWalk.connection then
            waterWalk.connection:Disconnect()
            waterWalk.connection = nil
        end
        if waterWalk.waterPart then
            waterWalk.waterPart:Destroy()
            waterWalk.waterPart = nil
        end
        for _, item in ipairs(waterWalk.waterPartsList) do
            if item and item.Parent then
                item.CanCollide = false
            end
        end
        waterWalk.waterPartsList = {}
    end
    utilSec:AddToggle("NNVN_WalkOnWater", {
        Title = "Walk on Water",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_WalkOnWater = enabled
            if enabled then
                enableWaterWalk()
            else
                disableWaterWalk()
            end
        end
    })
    worldSec = mainMap.Extra:AddSection({ Title = "World", Icon = "globe" })
    worldSec:AddToggle("NNVN_NoClip", {
        Title = "No Clip",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_NoClip = enabled
            local character = LocalPlayer.Character
            if not character then
                return
            end
            for _, item in ipairs(character:GetChildren()) do
                if item:IsA("BasePart") then
                    item.CanCollide = not enabled
                    item.CanTouch = not enabled
                end
            end
        end
    })
    origFogEnd = Lighting.FogEnd
    origFogStart = Lighting.FogStart
    worldSec:AddToggle("NNVN_NoFog", {
        Title = "No Fog",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_NoFog = enabled
            pcall(function()
                if enabled then
                    Lighting.FogEnd = 100000
                    Lighting.FogStart = 0
                    local atmosphere = Lighting:FindFirstChild("Atmosphere")
                    if atmosphere then
                        atmosphere.FogDensity = 0
                        atmosphere.Density = 0
                    end
                else
                    Lighting.FogEnd = origFogEnd
                    Lighting.FogStart = origFogStart
                end
            end)
        end
    })
    local colorShiftBottom = Lighting.ColorShift_Bottom
    local colorShiftTop = Lighting.ColorShift_Top
    local brightness = Lighting.Brightness
    local outdoorAmbient = Lighting.OutdoorAmbient
    origA = Lighting.Ambient
    origB = colorShiftBottom
    origT = colorShiftTop
    origBr = brightness
    origOA = outdoorAmbient
    worldSec:AddToggle("NNVN_FullBright", {
        Title = "Full Bright",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_FullBright = enabled
            if not enabled then
                Lighting.Ambient = origA
                Lighting.ColorShift_Bottom = origB
                Lighting.ColorShift_Top = origT
                Lighting.Brightness = origBr
                Lighting.OutdoorAmbient = origOA
            end
        end
    })
    worldSec:AddButton({
        Title = "Performance Mod",
        Callback = function()
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                local terrain = Workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                    terrain.WaterReflectance = 0
                    terrain.WaterTransparency = 1
                end
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9000000000
                Lighting.ShadowSoftness = 0
                Lighting.EnvironmentDiffuseScale = 0
                Lighting.EnvironmentSpecularScale = 0
                for _, entry in pairs(Lighting:GetChildren()) do
                    if entry:IsA("BlurEffect") or entry:IsA("SunRaysEffect") or entry:IsA("ColorCorrectionEffect") or entry:IsA("BloomEffect") or entry:IsA("DepthOfFieldEffect") then
                        entry:Destroy()
                    end
                end
                for _, entry2 in pairs(Workspace:GetDescendants()) do
                    if entry2:IsA("BasePart") then
                        entry2.Material = Enum.Material.SmoothPlastic
                        entry2.Reflectance = 0
                        entry2.CastShadow = false
                    elseif entry2:IsA("Decal") or entry2:IsA("Texture") or entry2:IsA("ParticleEmitter") or entry2:IsA("Trail") or entry2:IsA("Fire") or entry2:IsA("Smoke") or entry2:IsA("Sparkles") then
                        entry2:Destroy()
                    end
                end
                item:Notify({ Title = "", Content = "Performance optimized!", Duration = 2 })
            end)
        end
    })
    screenOverlay = CoreGui:FindFirstChild("NNVN_PerformanceOverlay")
    if screenOverlay then
        screenOverlay:Destroy()
    end
    screenOverlay = Instance.new("ScreenGui")
    screenOverlay.Name = "NNVN_PerformanceOverlay"
    screenOverlay.IgnoreGuiInset = true
    screenOverlay.ResetOnSpawn = false
    screenOverlay.DisplayOrder = 0
    screenOverlay.Enabled = false
    screenOverlay.Parent = CoreGui
    screenFrame = Instance.new("Frame", screenOverlay)
    screenFrame.Size = UDim2.fromScale(1, 1)
    screenFrame.BackgroundTransparency = 0
    screenFrame.BorderSizePixel = 0
    screenFrame.Active = false
    displaySec = mainMap.Extra:AddSection({ Title = "Display", Icon = "monitor" })
    whiteToggle = nil
    darkToggle = nil
    updateScreenOverlay = function()
        if getgenv().NNVN_WhiteScreen then
            screenFrame.BackgroundColor3 = Color3.new(1, 1, 1)
            screenOverlay.Enabled = true
        elseif getgenv().NNVN_DarkScreen then
            screenFrame.BackgroundColor3 = Color3.new(0, 0, 0)
            screenOverlay.Enabled = true
        else
            screenOverlay.Enabled = false
        end
    end
    whiteToggle = displaySec:AddToggle("NNVN_WhiteScreen", {
        Title = "White Screen",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_WhiteScreen = enabled
            if enabled and darkToggle then
                darkToggle:SetValue(false)
            end
            updateScreenOverlay()
        end
    })
    darkToggle = displaySec:AddToggle("NNVN_DarkScreen", {
        Title = "Dark Screen",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_DarkScreen = enabled
            if enabled and whiteToggle then
                whiteToggle:SetValue(false)
            end
            updateScreenOverlay()
        end
    })
    displaySec:AddToggle("NNVN_HideUI", {
        Title = "Hide Game UI",
        Default = false,
        Callback = function(enabled)
            getgenv().NNVN_HideUI = enabled
            if enabled then
                RequestHideUI()
            else
                RequestShowUI()
            end
        end
    })
    startupSec = mainMap.Extra:AddSection({ Title = "Startup", Icon = "play" })
    startupSec:AddToggle("NNVN_AutoExecuteScript", {
        Title = "Auto Execute Script on Join",
        Default = true,
        Callback = function(enabled)
            getgenv().NNVN_AutoExecuteScript = enabled
        end
    })
    local stateMap13 = {}
    local labelText = ""
    local hour = os.date("!*t").hour
    pcall(function()
        stateMap13 = HttpService:JSONDecode(readfile("server-hop-temp.json"))
    end)
    if #stateMap13 == 0 then
        table.insert(stateMap13, hour)
        pcall(function()
            writefile("server-hop-temp.json", HttpService:JSONEncode(stateMap13))
        end)
    end
    local function resolveJsonDecode(inputValue)
        local item
        if labelText == "" then
            item = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. inputValue .. "/servers/Public?sortOrder=Asc&limit=100"))
        else
            item = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. inputValue .. "/servers/Public?sortOrder=Asc&limit=100&cursor=" .. labelText))
        end
        if not item or not item.data then
            return false
        end
        if item.nextPageCursor and item.nextPageCursor ~= "null" and item.nextPageCursor ~= nil then
            labelText = item.nextPageCursor
        end
        local counter = 0
        for _, entry in pairs(item.data) do
            local isEnabled = true
            local idText = tostring(entry.id)
            if tonumber(entry.playing) < tonumber(entry.maxPlayers) then
                for _, entry2 in pairs(stateMap13) do
                    if counter ~= 0 then
                        if idText == tostring(entry2) then
                            isEnabled = false
                        end
                    elseif tonumber(hour) ~= tonumber(entry2) then
                        pcall(function()
                            delfile("server-hop-temp.json")
                            stateMap13 = {}
                            table.insert(stateMap13, hour)
                        end)
                    end
                    counter = counter + 1
                end
                if isEnabled then
                    table.insert(stateMap13, idText)
                    pcall(function()
                        writefile("server-hop-temp.json", HttpService:JSONEncode(stateMap13))
                        TeleportService:TeleportToPlaceInstance(inputValue, idText, LocalPlayer)
                    end)
                    task.wait(4)
                    return true
                end
            end
        end
        return false
    end
    canAutoServerHop = function()
        if getgenv().NNVN_IsApplyingConfig then
            return false
        end
        if getgenv().NNVN_HopBootLocked then
            return false
        end
        if os.clock() - (tonumber(getgenv().NNVN_ScriptBootTime) or 0) < (tonumber(getgenv().NNVN_HopGraceSeconds) or 20) then
            return false
        end
        if not getgenv().NNVN_Loaded then
            return false
        end
        if getgenv().NNVN_AutoHopFightEnzo ~= true and getgenv().NNVN_PremiumWeatherEnabled ~= true and getgenv().NNVN_PremiumSpiritEnabled ~= true and getgenv().NNVN_PremiumTaoistEnabled ~= true and getgenv().NNVN_PremiumMaoshanEnabled ~= true and getgenv().NNVN_AutoHopGod ~= true and getgenv().NNVN_AutoHopMaoshan ~= true and getgenv().NNVN_AutoHopTaoist ~= true then
            return false
        end
        return getgenv().NNVN_AllowAutomaticServerHop == true and getgenv().NNVN_ServerHopArmed == true
    end
    disarmAutomaticServerHop = function(inputValue)
        getgenv().NNVN_AllowAutomaticServerHop = false
        getgenv().NNVN_ServerHopArmed = false
        getgenv().NNVN_AutoHopFightEnzo = false
        getgenv().NNVN_AutoHopGod = false
        getgenv().NNVN_AutoHopMaoshan = false
        getgenv().NNVN_AutoHopTaoist = false
        if inputValue == "config" or inputValue == "boot" then
            getgenv().NNVN_PremiumWeatherEnabled = false
            getgenv().NNVN_PremiumSpiritEnabled = false
            getgenv().NNVN_PremiumTaoistEnabled = false
            getgenv().NNVN_PremiumMaoshanEnabled = false
        end
    end
    local autoHopGodSpirit = {
        AutoHopGodSpirit = true,
        AutoHopMaoshan = true,
        AutoHopTaoist = true,
        ["AutoHopGod Spirit"] = true,
        NNVN_AutoHopFightEnzo = true,
        NNVN_PremiumWeatherEnabled = true,
        NNVN_PremiumSpiritEnabled = true,
        NNVN_PremiumTaoistEnabled = true,
        NNVN_PremiumMaoshanEnabled = true,
        NNVN_AllowAutomaticServerHop = true,
        NNVN_ServerHopArmed = true,
        NNVN_AutoHopGod = true,
        NNVN_AutoHopMaoshan = true,
        NNVN_AutoHopTaoist = true,
        NNVN_AntiStaff = true
    }
    isHopRelatedFlag = function(inputValue)
        if not inputValue then
            return false
        end
        if autoHopGodSpirit[inputValue] then
            return true
        end
        local formattedText = string.lower(tostring(inputValue))
        if formattedText:find("autohop", 1, true) then
            return true
        end
        if formattedText:find("serverhop", 1, true) then
            return true
        end
        if formattedText:find("premiumweather", 1, true) then
            return true
        end
        if formattedText:find("premiumspirit", 1, true) then
            return true
        end
        if formattedText:find("premiumtaoist", 1, true) then
            return true
        end
        if formattedText:find("premiummaoshan", 1, true) then
            return true
        end
        if formattedText:find("antistaff", 1, true) then
            return true
        end
        return false
    end
    ServerHop = {}
    ServerHop.Teleport = function(inputValue, secondValue)
        if not canAutoServerHop() then
            warn("[NNVN Hub] Server hop blocked — not armed / boot lock / config apply")
            return false
        end
        local hasTriggered = false
        while not hasTriggered do
            if not canAutoServerHop() then
                warn("[NNVN Hub] Server hop aborted mid-loop — disarmed")
                return false
            end
            pcall(function()
                hasTriggered = resolveJsonDecode(secondValue)
            end)
            if not hasTriggered then
                task.wait(1)
            end
        end
    end
    ServerHop.TeleportManual = function(inputValue, secondValue)
        if getgenv().NNVN_IsApplyingConfig or getgenv().NNVN_HopBootLocked then
            warn("[NNVN Hub] Manual hop blocked during boot/config")
            return false
        end
        local allowAutomaticServerHop = getgenv().NNVN_AllowAutomaticServerHop
        local serverHopArmed = getgenv().NNVN_ServerHopArmed
        getgenv().NNVN_AllowAutomaticServerHop = true
        getgenv().NNVN_ServerHopArmed = true
        local autoHopGod = getgenv().NNVN_AutoHopGod
        getgenv().NNVN_AutoHopGod = true
        local hasTriggered = false
        pcall(function()
            local hasTriggered2 = false
            local counter = 0
            while not hasTriggered2 and counter < 8 do
                counter = counter + 1
                pcall(function()
                    hasTriggered2 = resolveJsonDecode(secondValue)
                end)
                if not hasTriggered2 then
                    task.wait(1)
                end
            end
            hasTriggered = hasTriggered2
        end)
        getgenv().NNVN_AutoHopGod = autoHopGod
        getgenv().NNVN_AllowAutomaticServerHop = allowAutomaticServerHop and true or false
        getgenv().NNVN_ServerHopArmed = serverHopArmed and true or false
        return hasTriggered
    end
    addHopSection = function(control, secondValue, thirdValue)
        local section = control:AddSection({ Title = "" .. secondValue, Icon = "server" })
        local statusParagraph = section:AddParagraph({ Title = "Status", Content = "🔴 Offline" })
        local item2
        local item3
        local item4
        section:AddToggle("AutoCheck" .. secondValue .. "Hop", {
            Title = "Auto Check Status",
            Default = false,
            Callback = function(enabled)
                if enabled then
                    if item2 then
                        coroutine.close(item2)
                        item2 = nil
                    end
                    item2 = coroutine.create(function()
                        while true do
                            local thirdValueResult = thirdValue()
                            pcall(function()
                                statusParagraph:SetDesc(thirdValueResult and "🟢 Online - " .. secondValue .. " in this server!" or "🔴 Offline")
                            end)
                            task.wait(3)
                        end
                    end)
                    coroutine.resume(item2)
                else
                    if item2 then
                        coroutine.close(item2)
                        item2 = nil
                    end
                    pcall(function()
                        statusParagraph:SetDesc("🔴 Offline")
                    end)
                end
            end
        })
        item4 = section:AddToggle("AutoHop" .. secondValue, {
            Title = "Auto Hop to " .. secondValue .. " Server",
            Default = false,
            Callback = function(selectedValue)
                if getgenv().NNVN_IsApplyingConfig then
                    return
                end
                local combinedText = "NNVN_AutoHop" .. secondValue:gsub("%s+", "")
                if secondValue == "God Spirit" then
                    combinedText = "NNVN_AutoHopGod"
                elseif secondValue == "Maoshan" then
                    combinedText = "NNVN_AutoHopMaoshan"
                elseif secondValue == "Taoist" then
                    combinedText = "NNVN_AutoHopTaoist"
                end
                if selectedValue then
                    if not getgenv().NNVN_Loaded or getgenv().NNVN_HopBootLocked then
                        task.defer(function()
                            pcall(function()
                                if item4 and item4.SetValue then
                                    item4:SetValue(false)
                                end
                            end)
                        end)
                        return
                    end
                    getgenv()[combinedText] = true
                    getgenv().NNVN_AllowAutomaticServerHop = true
                    getgenv().NNVN_ServerHopArmed = true
                    if item3 then
                        coroutine.close(item3)
                        item3 = nil
                    end
                    item3 = coroutine.create(function()
                        while getgenv()[combinedText] do
                            if not canAutoServerHop() then
                                break
                            end
                            if thirdValue() then
                                pcall(function()
                                    item4:SetValue(false)
                                end)
                                getgenv()[combinedText] = false
                                getgenv().NNVN_ServerHopArmed = false
                                getgenv().NNVN_AllowAutomaticServerHop = false
                                if not getgenv().NNVN_Notify then
                                    break
                                end
                                item:Notify({
                                    Title = secondValue .. " Found!",
                                    Content = "Auto-hop stopped -> " .. secondValue .. " is here!",
                                    Duration = 6
                                })
                                break
                            else
                                if getgenv().NNVN_Notify then
                                    item:Notify({
                                        Title = "",
                                        Content = secondValue .. " not found. Hopping...",
                                        Duration = 2
                                    })
                                end
                                getgenv().NNVN_ServerHopArmed = true
                                getgenv().NNVN_AllowAutomaticServerHop = true
                                pcall(function()
                                    ServerHop:Teleport(placeId)
                                end)
                                getgenv().NNVN_ServerHopArmed = false
                                break
                            end
                        end
                    end)
                    coroutine.resume(item3)
                else
                    getgenv()[combinedText] = false
                    getgenv().NNVN_ServerHopArmed = false
                    getgenv().NNVN_AllowAutomaticServerHop = false
                    if item3 then
                        coroutine.close(item3)
                        item3 = nil
                    end
                end
            end
        })
        section:AddButton({
            Title = "Hop Now (" .. secondValue .. ")",
            Callback = function()
                if not thirdValue() then
                    pcall(function()
                        ServerHop:TeleportManual(placeId)
                    end)
                elseif getgenv().NNVN_Notify then
                    item:Notify({ Title = "", Content = secondValue .. " already here!", Duration = 2 })
                end
            end
        })
    end
    addHopSection(mainMap.Hop, "God Spirit", function()
        return getGodSpiritCount() > 0
    end)
    addHopSection(mainMap.Hop, "Maoshan", function()
        return findTrackerObject("maoshan") ~= nil
    end)
    addHopSection(mainMap.Hop, "Taoist", function()
        return findTrackerObject("taoist") ~= nil
    end)
    webhookMainSec = mainMap.Webhook:AddSection({ Title = "Discord Webhook", Icon = "webhook" })
    webhookMainSec:AddInput("NNVN_WebhookUrl", {
        Title = "Webhook URL",
        Default = getgenv().NNVN_WebhookUrl or "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback = function(enabled)
            getgenv().NNVN_WebhookUrl = tostring(enabled or "")
        end
    })
    webhookMainSec:AddToggle("NNVN_WebhookEnabled", {
        Title = "Enable Webhook",
        Default = getgenv().NNVN_WebhookEnabled == true,
        Callback = function(selectedValue)
            getgenv().NNVN_WebhookEnabled = selectedValue == true
        end
    })
end

do
    webhookEventsSec = mainMap.Webhook:AddSection({ Title = "Webhook Events", Icon = "bell" })
    webhookEventsSec:AddToggle("NNVN_WebhookCatchFish", {
        Title = "Normal Fish Caught",
        Default = getgenv().NNVN_WebhookCatchFish == true,
        Callback = function(enabled)
            getgenv().NNVN_WebhookCatchFish = enabled == true
        end
    })
    webhookEventsSec:AddToggle("NNVN_WebhookCatchBoss", {
        Title = "Boss Fish Caught",
        Default = getgenv().NNVN_WebhookCatchBoss == true,
        Callback = function(enabled)
            getgenv().NNVN_WebhookCatchBoss = enabled == true
        end
    })
    webhookEventsSec:AddToggle("NNVN_WebhookCatchSecretBoss", {
        Title = "Secret Boss Caught",
        Default = getgenv().NNVN_WebhookCatchSecretBoss == true,
        Callback = function(enabled)
            getgenv().NNVN_WebhookCatchSecretBoss = enabled == true
        end
    })
    webhookEventsSec:AddToggle("NNVN_WebhookSell", {
        Title = "Fish Sold",
        Default = getgenv().NNVN_WebhookSell == true,
        Callback = function(enabled)
            getgenv().NNVN_WebhookSell = enabled == true
        end
    })
    webhookEventsSec:AddToggle("NNVN_WebhookWeather", {
        Title = "Weather and Island",
        Default = getgenv().NNVN_WebhookWeather == true,
        Callback = function(enabled)
            getgenv().NNVN_WebhookWeather = enabled == true
        end
    })
    webhookEventsSec:AddToggle("NNVN_WebhookSpirit", {
        Title = "God Spirit",
        Default = getgenv().NNVN_WebhookSpirit == true,
        Callback = function(enabled)
            getgenv().NNVN_WebhookSpirit = enabled == true
        end
    })
    webhookEventsSec:AddToggle("NNVN_WebhookMaoshan", {
        Title = "Maoshan",
        Default = getgenv().NNVN_WebhookMaoshan == true,
        Callback = function(enabled)
            getgenv().NNVN_WebhookMaoshan = enabled == true
        end
    })
    webhookEventsSec:AddToggle("NNVN_WebhookTaoist", {
        Title = "Taoist",
        Default = getgenv().NNVN_WebhookTaoist == true,
        Callback = function(selectedValue)
            getgenv().NNVN_WebhookTaoist = selectedValue == true
        end
    })
    webhookMainSec:AddParagraph({
        Title = "How It Sends",
        Content = "Every alert uses only the webhook URL entered above. Events include the current island, weather, ping, server and Job ID."
    })
    local function resolveGmatch(...)
        local globalEnv = getgenv()
        for i = 1, select("#", ...) do
            local selectResult = select(i, ...)
            local globalEnv2 = globalEnv
            for entryKey in tostring(selectResult):gmatch("[^%.]+") do
                globalEnv2 = type(globalEnv2) == "table" and rawget(globalEnv2, entryKey) or nil
                if globalEnv2 == nil then
                    break
                end
            end
            if type(globalEnv2) == "function" then
                return globalEnv2
            end
        end
        return nil
    end
    local function resolveIdentifyexecutor()
        local gmatch = resolveGmatch("identifyexecutor", "getexecutorname")
        if gmatch then
            local ok, result, extraResult = pcall(gmatch)
            if ok and result then
                return tostring(result) .. (extraResult and extraResult ~= "" and " · " .. tostring(extraResult) or "")
            end
        end
        return "Unknown Executor"
    end
    local function resolveEliteCompatibility(inputValue)
        if inputValue >= 98 then
            return "Elite Compatibility"
        end
        if inputValue >= 95 then
            return "Excellent Compatibility"
        end
        if inputValue >= 90 then
            return "Great Compatibility"
        end
        if inputValue >= 80 then
            return "Limited Compatibility"
        end
        if inputValue >= 75 then
            return "Poor Compatibility"
        end
        return "Unsupported"
    end
    local function resolveRequest()
        local function executeAction(...)
            return resolveGmatch(...) ~= nil
        end
        local executeActionResult = executeAction("request", "http_request", "syn.request", "http.request")
        local executeActionResult2 = executeAction("readfile") and executeAction("writefile") and executeAction("isfile")
        local executeActionResult3 = executeAction("isfolder") and executeAction("makefolder") and executeAction("listfiles")
        local executeActionResult4 = executeAction("setclipboard", "toclipboard", "syn.write_clipboard")
        local executeActionResult5 = executeAction("keypress") and executeAction("keyrelease") or pcall(function()
            return game:GetService("VirtualInputManager")
        end)
        local itemList = {
            executeAction("loadstring"),
            executeAction("getgenv"),
            executeAction("getgc"),
            executeAction("getconnections"),
            executeAction("hookfunction"),
            executeAction("hookmetamethod"),
            executeAction("newcclosure"),
            executeAction("checkcaller"),
            executeAction("getnamecallmethod"),
            executeAction("cloneref"),
            executeAction("clonefunction"),
            executeAction("gethui"),
            executeAction("getinstances"),
            executeAction("getnilinstances"),
            executeAction("firesignal"),
            executeAction("fireproximityprompt"),
            executeActionResult,
            executeActionResult2,
            executeActionResult4,
            executeActionResult5
        }
        local itemList2 = {
            executeAction("cloneref"),
            executeAction("clonefunction"),
            executeAction("hookfunction"),
            executeAction("hookmetamethod"),
            executeAction("newcclosure"),
            executeAction("checkcaller"),
            executeAction("getnamecallmethod"),
            executeAction("getgc"),
            executeAction("getconnections"),
            executeAction("getinstances"),
            executeAction("getnilinstances"),
            executeAction("firesignal"),
            executeAction("fireproximityprompt"),
            executeAction("queue_on_teleport", "syn.queue_on_teleport"),
            executeActionResult,
            executeActionResult2
        }
        local function resolveFloor(inputValue)
            local counter = 0
            for _, item in ipairs(inputValue) do
                if item then
                    counter = counter + 1
                end
            end
            return math.floor(counter / #inputValue * 100 + 0.5)
        end
        local stateMap = {}
        local stateMap2 = {}
        local function resolveInsert(inputValue, secondValue, thirdValue)
            if inputValue then
                return
            end
            table.insert(stateMap, secondValue)
            table.insert(stateMap2, thirdValue)
        end
        resolveInsert(executeActionResult, "HTTP request", "Webhooks and relay trackers")
        resolveInsert(executeActionResult2 and executeActionResult3, "File system", "Config save and auto load")
        resolveInsert(executeActionResult4, "Clipboard", "Copy Job ID and links")
        resolveInsert(executeActionResult5, "Input simulation", "Keyboard minigames and skills")
        resolveInsert(executeAction("fireproximityprompt"), "fireproximityprompt", "Prompt interaction fallback")
        resolveInsert(executeAction("queue_on_teleport", "syn.queue_on_teleport"), "queue_on_teleport", "Auto resume after server hop")
        local itemList3 = {
            executeActionResult,
            executeActionResult2,
            executeActionResult3,
            executeActionResult4,
            executeActionResult5,
            executeAction("fireproximityprompt"),
            executeAction("queue_on_teleport", "syn.queue_on_teleport"),
            executeAction("hookmetamethod"),
            executeAction("newcclosure"),
            executeAction("gethui") or executeAction("protectgui")
        }
        local floor = resolveFloor(itemList)
        local floor2 = resolveFloor(itemList2)
        local floor3 = resolveFloor(itemList3)
        local isMatched = floor2 >= 75 and floor3 >= 75
        return table.concat({
            "Executor: " .. resolveIdentifyexecutor(),
            "UNC Compatibility: " .. floor .. "%",
            "SUNC Compatibility: " .. floor2 .. "% (capability estimate)",
            "Script Support: " .. floor3 .. "%",
            "Tier: " .. resolveEliteCompatibility(floor2),
            "Status: " .. (isMatched and "SUPPORTED" or "UNSUPPORTED"),
            "Missing APIs: " .. (#stateMap > 0 and table.concat(stateMap, ", ") or "None"),
            "Affected Features: " .. (#stateMap2 > 0 and table.concat(stateMap2, ", ") or "None")
        }, "\n"), isMatched, floor3
    end
    local executorCompatibilitySection = mainMap.Main:AddSection({ Title = "Executor Compatibility", Icon = "shield-check" })
    local compatibilityReportParagraph = executorCompatibilitySection:AddParagraph({
        Title = "Compatibility Report",
        Content = "Press Check Executor to run a safe capability scan."
    })
    executorCompatibilitySection:AddButton({
        Title = "Check Executor",
        Description = "Checks UNC/SUNC capabilities and lists unsupported hub features.",
        Callback = function()
            task.spawn(function()
                if compatibilityReportParagraph and compatibilityReportParagraph.SetDesc then
                    compatibilityReportParagraph:SetDesc("Scanning executor capabilities...")
                end
                task.wait()
                local requestOk, responseBody, statusCode = resolveRequest()
                if compatibilityReportParagraph and compatibilityReportParagraph.SetDesc then
                    compatibilityReportParagraph:SetDesc(requestOk)
                end
                item:Notify({
                    Title = responseBody and "Executor Supported" or "Executor Unsupported",
                    Content = "Script compatibility: " .. tostring(statusCode) .. "%",
                    Duration = 5,
                    Icon = responseBody and "shield-check" or "shield-alert"
                })
            end)
        end
    })
    DISCORD_INVITE = "https://discord.gg/5JJAuHRUgJ"
    DISCORD_CODE = "5JJAuHRUgJ"
    infoSec = mainMap.Main:AddSection({ Title = "NNVN Hub", Icon = "home" })
    hubRuntimeStatus = infoSec:AddParagraph({ Title = "Status", Content = "Loading hub info..." })
    discordStatus = infoSec:AddParagraph({ Title = "Discord", Content = "Loading invite info..." })
    infoSec:AddParagraph({
        Title = "Update Log",
        Content = "NNVN Hub v" .. hubVersion .. "\n• Restore Methods" .. "\n• Arrival Gating" .. "\n• Quest Guard" .. "\n• Sky Lock Fix" .. "\n• Executor Check" .. "\n• Mobile UI" .. "\n• Midnight Theme" .. "\n• Image Background" .. "\n• Auto Cast Delay" .. "\n• Safety Controls" .. "\n• Remote Spam Guard" .. "\n• One-Time NPC Check" .. "\n• Hard Sky Farm"
    })
    if infoSec.AddDiscordBox then
        infoSec:AddDiscordBox("NNVN_DiscordBox", {
            Title = "NNVN Hub",
            Subtitle = "Join Discord for updates and support",
            Banner = "rbxassetid://138952058031836",
            Avatar = "rbxassetid://138952058031836",
            Status = "online",
            Accent = Color3.fromRGB(88, 101, 242),
            Link = DISCORD_INVITE,
            BannerHeight = 64,
            AvatarSize = 56,
            Buttons = {
                {
                    Text = "Copy Discord Invite",
                    Icon = "copy",
                    Copy = true,
                    CopiedText = "Copied",
                    Func = function()
                        pcall(function()
                            setclipboard(DISCORD_INVITE)
                        end)
                    end
                }
            }
        })
    end
    local playerStatsParagraph = infoSec:AddParagraph({
        Title = "Player Stats",
        Content = "Cash: --\nGems: --\nTicket: --\nEssence Orbs: --"
    })
    local function checkAttribute4(inputValue)
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
        local main = mainGui and mainGui:FindFirstChild("Main")
        local stats = main and main:FindFirstChild("Stats")
        local statsEntry = stats and stats:FindFirstChild(inputValue)
        local value = statsEntry and statsEntry:FindFirstChild("Value")
        if value then
            local item
            if value:IsA("TextLabel") or value:IsA("TextButton") or value:IsA("TextBox") then
                item = value.Text
            elseif value:IsA("ValueBase") then
                item = value.Value
            end
            if item ~= nil and tostring(item) ~= "" then
                return tostring(item)
            end
        end
        local data = ReplicatedStorage:FindFirstChild("Data")
        local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
        local playerData2 = playerData and playerData:FindFirstChild(inputValue)
        if playerData2 then
            if playerData2:IsA("ValueBase") then
                return tostring(playerData2.Value)
            end
            local value2 = playerData2:FindFirstChild("Value")
            if value2 and value2:IsA("ValueBase") then
                return tostring(value2.Value)
            end
        end
        if playerData then
            local attribute = playerData:GetAttribute(inputValue)
            if attribute ~= nil then
                return tostring(attribute)
            end
        end
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local leaderstatsEntry = leaderstats and leaderstats:FindFirstChild(inputValue)
        if leaderstatsEntry and leaderstatsEntry:IsA("ValueBase") then
            return tostring(leaderstatsEntry.Value)
        end
        return "--"
    end
    UpdatePlayerStats = function()
        if not playerStatsParagraph or not playerStatsParagraph.SetDesc then
            return
        end
        local checkAttribute4Result = checkAttribute4("Cash")
        local checkAttribute4Result2 = checkAttribute4("Crystal")
        local checkAttribute4Result3 = checkAttribute4("Ticket")
        local checkAttribute4Result4 = checkAttribute4("EssenceOrb")
        getgenv().NNVN_MainEssenceOrbValue = checkAttribute4Result4
        playerStatsParagraph:SetDesc(string.format("Cash: %s\nGems: %s\nTicket: %s\nEssence Orbs: %s", checkAttribute4Result, checkAttribute4Result2, checkAttribute4Result3, checkAttribute4Result4))
        if hubRuntimeStatus and type(UpdateHubRuntimeInfo) == "function" then
            UpdateHubRuntimeInfo()
        end
    end
    UpdateHubRuntimeInfo = function()
        hubRuntimeStatus:SetDesc(string.format("NNVN Hub v%s\nIsland: %s\nWeather: %s\nEssence Orbs: %s", tostring(hubVersion), getCurrentIslandName(), getCurrentWeather(), tostring(getgenv().NNVN_MainEssenceOrbValue or checkAttribute4("EssenceOrb"))))
    end
    UpdateDiscordInfo = function()
        task.spawn(function()
            local ok, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet("https://discord.com/api/v10/invites/" .. DISCORD_CODE .. "?with_counts=true&with_expiration=true"))
            end)
            if ok and result then
                local name = result.guild and result.guild.name or "NNVN Discord"
                local parsedNum = tonumber(result.approximate_member_count) or 0
                local parsedNum2 = tonumber(result.approximate_presence_count) or 0
                discordStatus:SetDesc(string.format("%s\n🟢 Online Members: %d\n🔴 Offline Members: %d\nInvite: %s", name, parsedNum2, math.max(0, parsedNum - parsedNum2), DISCORD_INVITE))
            else
                discordStatus:SetDesc("🔴 Offline - Unable to fetch live info right now.\nInvite: " .. DISCORD_INVITE)
            end
        end)
    end
    infoSec:AddButton({
        Title = "Refresh Info",
        Icon = "refresh-cw",
        Callback = function()
            UpdateHubRuntimeInfo()
            UpdateDiscordInfo()
        end
    })
    infoSec:AddButton({
        Title = "Copy Discord Invite",
        Icon = "copy",
        Callback = function()
            pcall(function()
                setclipboard(DISCORD_INVITE)
            end)
            if getgenv().NNVN_Notify then
                item:Notify({ Title = "Discord", Content = "Invite copied!", Duration = 2 })
            end
        end
    })
    UpdateHubRuntimeInfo()
    UpdateDiscordInfo()
    UpdatePlayerStats()
    task.spawn(function()
        while task.wait(2) do
            UpdatePlayerStats()
        end
    end)
    task.spawn(function()
        while task.wait(60) do
            UpdateHubRuntimeInfo()
            UpdateDiscordInfo()
        end
    end)
    SettingsTab = mainMap.Settings
    LanguageSection = patchContainer(SettingsTab:Section({ Title = "Language", Icon = "languages", Opened = true }))
    LanguageSection:AddParagraph({
        Title = "Language",
        Content = "Language changes are runtime only. Default language is English."
    })
    LanguageSection:Dropdown({
        Title = "Select Language",
        Values = languageOptions,
        Value = getgenv().NNVN_Language,
        Callback = function(selected)
            local translatedChoice = NormalizeTranslatedChoice(selected, "English")
            getgenv().NNVN_Language = languageDict[translatedChoice] and translatedChoice or "English"
            task.defer(function()
                pcall(ApplyUILanguage)
            end)
            task.delay(0.8, function()
                pcall(ApplyUILanguage)
            end)
            task.defer(function()
                if getgenv().NNVN_Loaded and getgenv().NNVN_Notify then
                    item:Notify({
                        Title = TranslateText("Language"),
                        Content = TranslateText("Select Language") .. ": " .. getgenv().NNVN_Language,
                        Duration = 2,
                        Icon = "languages"
                    })
                end
            end)
        end
    })
    DisplaySection = patchContainer(SettingsTab:Section({ Title = "Display", Icon = "monitor", Opened = true }))
    DisplaySection:AddToggle("NNVN_WatermarkSettings", {
        Title = "Show Watermark",
        Description = "Shows or hides the hub status watermark.",
        Default = getgenv().NNVN_Watermark == true,
        Callback = function(inputText)
            NNVN_SetWatermarkVisible(inputText == true)
        end
    })
    DisplaySection:AddInput("NNVN_AccentColorHex", {
        Title = "Accent Color",
        Description = "Hex color for highlights and effects. Default: #568CFF.",
        Placeholder = "#568CFF",
        Default = tostring(getgenv().NNVN_AccentColorHex or "#568CFF"),
        Finished = true,
        Callback = function(selectedValue)
            local selectedValueText = tostring(selectedValue or "#568CFF")
            if not selectedValueText:match("^#?[%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F]$") then
                selectedValueText = "#568CFF"
            elseif selectedValueText:sub(1, 1) ~= "#" then
                selectedValueText = "#" .. selectedValueText
            end
            getgenv().NNVN_AccentColorHex = selectedValueText:upper()
            pcall(applyWindowScheme)
        end
    })
    BackgroundInputValue = getgenv().NNVN_BackgroundImage or ""
    DisplaySection:AddInput("NNVN_BackgroundImage", {
        Title = "Background Asset",
        Description = "Supports rbxassetid://123456789 and direct image URLs.",
        Placeholder = "rbxassetid://123456789",
        Default = BackgroundInputValue,
        Finished = true,
        Callback = function(amount)
            BackgroundInputValue = tostring(amount or "")
            getgenv().NNVN_BackgroundImage = BackgroundInputValue
            if Window.SetBackgroundImage then
                pcall(function()
                    Window:SetBackgroundImage(BackgroundInputValue)
                end)
            end
        end
    })
    DisplaySection:AddSlider("NNVN_BackgroundTransparency", {
        Title = "Background Transparency",
        Description = "Higher values keep controls easier to read.",
        Default = tonumber(getgenv().NNVN_BackgroundTransparency) or 0.72,
        Min = 0,
        Max = 0.95,
        Rounding = 2,
        Callback = function(selectedValue)
            getgenv().NNVN_BackgroundTransparency = tonumber(selectedValue) or 0.72
            if Window.SetBackgroundImageTransparency then
                pcall(function()
                    Window:SetBackgroundImageTransparency(getgenv().NNVN_BackgroundTransparency)
                end)
            end
        end
    })
    DisplaySection:AddButton({
        Title = "Clear Background",
        Callback = function()
            BackgroundInputValue = ""
            getgenv().NNVN_BackgroundImage = ""
            if Window.SetBackgroundImage then
                pcall(function()
                    Window:SetBackgroundImage("")
                end)
            end
        end
    })
end

do
    ConfigSection = SettingsTab:Section({ Title = "Config", Icon = "database", Opened = true })
    ConfigName = "default"
    SelectedConfigName = "default"
    AutoLoadConfig = false
    AutoSaveConfig = false
    ConfigUIReady = false
    WindUIConfigManager = nil
    WindUIConfigFile = nil
    NotifySettings = function(inputValue, secondValue)
        if getgenv().NNVN_Notify then
            item:Notify({
                Title = inputValue or "Settings",
                Content = secondValue or "",
                Duration = 3,
                Icon = "settings"
            })
        end
    end
    ConfigFolder = "NNVN_HeavyweightFishing/configs"
    AutoLoadMetaPath = "NNVN_HeavyweightFishing/autoload.txt"
    KnownConfigNames = {}
    initWindUIConfig = function()
        local configManager = Window and Window.ConfigManager
        if not configManager then
            configManager = item and item.ConfigManager
        end
        if not configManager or type(configManager.CreateConfig) ~= "function" then
            return false
        end
        local ok, result = pcall(function()
            if not configManager.Folder and type(configManager.Init) == "function" then
                configManager:Init(Window)
            end
            local config = type(configManager.GetConfig) == "function" and configManager:GetConfig("default") or nil or configManager:CreateConfig("default", true)
            if not config then
                return nil
            end
            for key, entry in pairs(stateMap2) do
                if entry then
                    pcall(function()
                        config:Register(key, entry)
                    end)
                end
            end
            return config
        end)
        if ok and result then
            WindUIConfigManager = configManager
            WindUIConfigFile = result
            return true
        end
        return false
    end
    saveWindUIConfig = function()
        if not WindUIConfigFile or type(WindUIConfigFile.Save) ~= "function" then
            return false
        end
        return pcall(function()
            WindUIConfigFile:Save()
        end)
    end
    loadWindUIConfig = function()
        if not WindUIConfigFile or type(WindUIConfigFile.Load) ~= "function" then
            return false
        end
        return pcall(function()
            WindUIConfigFile:Load()
        end)
    end
    executorFilesReady = function()
        return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    end
    ensureConfigFolder = function()
        if type(makefolder) == "function" then
            pcall(function()
                if type(isfolder) ~= "function" or not isfolder("NNVN_HeavyweightFishing") then
                    makefolder("NNVN_HeavyweightFishing")
                end
                if type(isfolder) ~= "function" or not isfolder(ConfigFolder) then
                    makefolder(ConfigFolder)
                end
            end)
        end
    end
    cleanConfigName = function(text)
        text = tostring(text or "default")
        text = text:gsub("[^%w%-%_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then
            text = "default"
        end
        return text
    end
    configPath = function(inputValue)
        return ConfigFolder .. "/" .. cleanConfigName(inputValue) .. ".json"
    end
    listConfigs = function()
        ensureConfigFolder()
        local stateMap = {}
        local stateMap2 = {}
        if type(listfiles) == "function" then
            local ok, result = pcall(function()
                return listfiles(ConfigFolder)
            end)
            if ok and type(result) == "table" then
                for _, item in ipairs(result) do
                    local matchedText = tostring(item):match("([^/\\]+)%.json$")
                    if matchedText and not stateMap2[matchedText] then
                        table.insert(stateMap, matchedText)
                        stateMap2[matchedText] = true
                    end
                end
            end
        end
        for entryKey in pairs(KnownConfigNames) do
            if not stateMap2[entryKey] then
                table.insert(stateMap, entryKey)
                stateMap2[entryKey] = true
            end
        end
        table.sort(stateMap)
        if #stateMap == 0 then
            table.insert(stateMap, "-- no config --")
        end
        return stateMap
    end
    NNVN_ConfigJSONValue = function(inputValue, secondValue)
        local typeofResult = typeof(inputValue)
        if typeofResult == "string" or typeofResult == "number" or typeofResult == "boolean" then
            return inputValue
        end
        if typeofResult ~= "table" then
            return nil
        end
        secondValue = secondValue or {}
        if secondValue[inputValue] then
            return nil
        end
        secondValue[inputValue] = true
        local lookupMap = {}
        for key, entry in pairs(inputValue) do
            local isMatched = type(key) == "string" or type(key) == "number"
            local configJsonValueResult = NNVN_ConfigJSONValue(entry, secondValue)
            if isMatched and configJsonValueResult ~= nil then
                lookupMap[key] = configJsonValueResult
            end
        end
        secondValue[inputValue] = nil
        return lookupMap
    end
    captureConfig = function()
        local themeMap = {
            __theme = SelectedTheme or "Dark",
            __background = BackgroundInputValue or "",
            __background_transparency = tonumber(getgenv().NNVN_BackgroundTransparency) or 0.72,
            __auto_load = AutoLoadConfig == true,
            __auto_save = AutoSaveConfig == true,
            __custom_positions = serializeCustomPositions()
        }
        for key, entry in pairs(stateMap2) do
            if isHopRelatedFlag(key) then
                themeMap[key] = false
            else
                local configJsonValueResult = NNVN_ConfigJSONValue(entry and entry.Value)
                if configJsonValueResult ~= nil then
                    themeMap[key] = configJsonValueResult
                end
            end
        end
        return themeMap
    end
    applySavedConfig = function(inputValue)
        if type(inputValue) ~= "table" then
            return false
        end
        getgenv().NNVN_IsApplyingConfig = true
        local ok, result = pcall(function()
            if type(inputValue.__custom_positions) == "table" then
                applyCustomPositions(inputValue.__custom_positions)
            end
            for key, entry in pairs(inputValue) do
                if isHopRelatedFlag(key) then
                    entry = false
                end
                local stateMap2Entry = stateMap2[key]
                if stateMap2Entry and stateMap2Entry.SetValue then
                    pcall(function()
                        stateMap2Entry:SetValue(entry)
                    end)
                elseif stateMap2Entry then
                    stateMap2Entry.Value = entry
                end
            end
            if inputValue.__theme then
                SelectedTheme = inputValue.__theme
                pcall(function()
                    item:SetTheme(SelectedTheme)
                end)
                pcall(applyWindowScheme)
            end
            if inputValue.__background then
                BackgroundInputValue = inputValue.__background
                if Window.SetBackgroundImage then
                    pcall(function()
                        Window:SetBackgroundImage(BackgroundInputValue)
                    end)
                end
            end
            if inputValue.__background_transparency ~= nil then
                getgenv().NNVN_BackgroundTransparency = tonumber(inputValue.__background_transparency) or 0.72
                if Window.SetBackgroundImageTransparency then
                    pcall(function()
                        Window:SetBackgroundImageTransparency(getgenv().NNVN_BackgroundTransparency)
                    end)
                end
            end
            AutoLoadConfig = inputValue.__auto_load == true
            AutoSaveConfig = inputValue.__auto_save == true
        end)
        disarmAutomaticServerHop("config")
        getgenv().NNVN_AllowAutomaticServerHop = false
        getgenv().NNVN_ServerHopArmed = false
        getgenv().NNVN_AutoHopFightEnzo = false
        getgenv().NNVN_AutoHopGod = false
        getgenv().NNVN_AutoHopMaoshan = false
        getgenv().NNVN_AutoHopTaoist = false
        getgenv().NNVN_PremiumWeatherEnabled = false
        getgenv().NNVN_PremiumSpiritEnabled = false
        getgenv().NNVN_PremiumTaoistEnabled = false
        getgenv().NNVN_PremiumMaoshanEnabled = false
        getgenv().NNVN_AntiStaff = false
        getgenv().NNVN_IsApplyingConfig = false
        if not ok then
            warn("[NNVN Hub] applySavedConfig error: " .. tostring(result))
            return false
        end
        return true
    end
    saveConfig = function(inputValue)
        if not executorFilesReady() then
            return false, "Executor file APIs are not available."
        end
        ensureConfigFolder()
        local ok, result = pcall(function()
            return HttpService:JSONEncode(captureConfig())
        end)
        if not ok then
            return false, "Could not encode config."
        end
        local callOk = pcall(function()
            writefile(configPath(inputValue), result)
        end)
        if callOk then
            KnownConfigNames[cleanConfigName(inputValue)] = true
        end
        if callOk and cleanConfigName(inputValue) == "default" then
            saveWindUIConfig()
        end
        return callOk, callOk and nil or "Could not write config file."
    end
    saveAutoLoadMeta = function()
        if not executorFilesReady() then
            return
        end
        ensureConfigFolder()
        if AutoLoadConfig then
            pcall(function()
                writefile(AutoLoadMetaPath, cleanConfigName(SelectedConfigName or ConfigName))
            end)
        elseif type(delfile) == "function" and type(isfile) == "function" and isfile(AutoLoadMetaPath) then
            pcall(function()
                delfile(AutoLoadMetaPath)
            end)
        end
    end
    readAutoLoadMeta = function()
        if not executorFilesReady() then
            return nil
        end
        if type(isfile) == "function" and isfile(AutoLoadMetaPath) then
            local ok, result = pcall(function()
                return readfile(AutoLoadMetaPath)
            end)
            if ok and result and result ~= "" then
                return cleanConfigName(result)
            end
        end
        return nil
    end
    loadConfig = function(inputValue)
        if not executorFilesReady() then
            return false, "Executor file APIs are not available."
        end
        local configPathResult = configPath(inputValue)
        if not isfile(configPathResult) then
            if cleanConfigName(inputValue) == "default" and loadWindUIConfig() then
                return true, nil
            end
            return false, "Config file does not exist."
        end
        local ok, result = pcall(function()
            return readfile(configPathResult)
        end)
        if not ok then
            return false, "Could not read config file."
        end
        local ok2, result2 = pcall(function()
            return HttpService:JSONDecode(result)
        end)
        if not ok2 then
            return false, "Config file is not valid JSON."
        end
        return applySavedConfig(result2), nil
    end
    deleteConfig = function(inputValue)
        if type(delfile) ~= "function" then
            return false, "Executor delfile API is not available."
        end
        local configPathResult = configPath(inputValue)
        if type(isfile) == "function" and not isfile(configPathResult) then
            return false, "Config file does not exist."
        end
        local callOk = pcall(function()
            delfile(configPathResult)
        end)
        if callOk then
            KnownConfigNames[cleanConfigName(inputValue)] = nil
        end
        return callOk, callOk and nil or "Could not delete config file."
    end
    AllConfigNames = listConfigs()
    RefreshConfigDropdown = function(inputValue)
        AllConfigNames = listConfigs()
        if ConfigDropdown and ConfigDropdown.SetValues then
            pcall(function()
                ConfigDropdown:SetValues(AllConfigNames)
            end)
        elseif ConfigDropdown and ConfigDropdown.Refresh then
            pcall(function()
                ConfigDropdown:Refresh(AllConfigNames)
            end)
        end
        local cleanConfigNameResult = inputValue and cleanConfigName(inputValue) or nil
        if cleanConfigNameResult and ConfigDropdown then
            if type(ConfigDropdown.SetValue) == "function" then
                pcall(function()
                    ConfigDropdown:SetValue(cleanConfigNameResult)
                end)
            elseif type(ConfigDropdown.Select) == "function" then
                pcall(function()
                    ConfigDropdown:Select(cleanConfigNameResult)
                end)
            else
                ConfigDropdown.Value = cleanConfigNameResult
            end
        end
    end
    InitialAutoLoadName = readAutoLoadMeta()
    ConfigNameInput = ConfigSection:Input({
        Title = "Config Name",
        Placeholder = "Type config name",
        Value = ConfigName,
        Callback = function(inputText)
            ConfigName = inputText and inputText ~= "" and inputText or "default"
        end
    })
    ConfigSection:Button({
        Title = "Create Config",
        Icon = "sparkles",
        Callback = function()
            ConfigName = cleanConfigName(ConfigNameInput and ConfigNameInput.Value or ConfigName)
            local primaryValue, secondaryValue = saveConfig(ConfigName)
            if primaryValue then
                SelectedConfigName = ConfigName
                saveAutoLoadMeta()
            end
            NotifySettings("Config", primaryValue and "Created config: " .. ConfigName or secondaryValue or "Create failed")
            RefreshConfigDropdown(primaryValue and ConfigName or nil)
        end
    })
    ConfigDropdown = ConfigSection:Dropdown({
        Title = "Select Config",
        Values = AllConfigNames,
        Value = AllConfigNames[1],
        Callback = function(selected)
            if selected and selected ~= "-- no config --" then
                SelectedConfigName = selected
                ConfigName = selected
                if ConfigNameInput and type(ConfigNameInput.SetValue) == "function" then
                    ConfigNameInput:SetValue(selected)
                elseif ConfigNameInput and type(ConfigNameInput.Set) == "function" then
                    ConfigNameInput:Set(selected)
                end
                saveAutoLoadMeta()
            end
        end
    })
    AutoLoadConfigToggle = ConfigSection:Toggle({
        Title = "Auto Load Config",
        Description = "Automatically loads the selected config on the next execute.",
        Value = InitialAutoLoadName ~= nil,
        Callback = function(enabled)
            AutoLoadConfig = enabled == true
            if ConfigUIReady then
                saveAutoLoadMeta()
            end
        end
    })
    AutoSaveConfigToggle = ConfigSection:Toggle({
        Title = "Auto Save Config",
        Description = "Automatically overwrites the selected config every 30 seconds.",
        Value = false,
        Callback = function(enabled)
            AutoSaveConfig = enabled == true
            if ConfigUIReady and AutoSaveConfig then
                saveConfig(SelectedConfigName ~= "-- no config --" and SelectedConfigName or ConfigName)
            end
        end
    })
    SyncConfigToggle = function(control, secondValue)
        if not control then
            return
        end
        control.Value = secondValue == true
        if type(control.SetValue) == "function" then
            pcall(function()
                control:SetValue(secondValue == true)
            end)
        elseif type(control.Set) == "function" then
            pcall(function()
                control:Set(secondValue == true)
            end)
        end
    end
    ConfigSection:Button({
        Title = "Load Config",
        Icon = "sparkles",
        Callback = function()
            local selectedConfigName = SelectedConfigName ~= "-- no config --" and SelectedConfigName or ConfigName
            local primaryValue, secondaryValue = loadConfig(selectedConfigName)
            if primaryValue then
                SyncConfigToggle(AutoLoadConfigToggle, AutoLoadConfig)
                SyncConfigToggle(AutoSaveConfigToggle, AutoSaveConfig)
                saveAutoLoadMeta()
            end
            NotifySettings("Config", primaryValue and "Loaded config: " .. selectedConfigName or secondaryValue or "Could not load config: " .. tostring(selectedConfigName))
        end
    })
    ConfigSection:Button({
        Title = "Overwrite Config",
        Icon = "sparkles",
        Callback = function()
            local selectedConfigName = SelectedConfigName ~= "-- no config --" and SelectedConfigName or ConfigName
            local primaryValue, secondaryValue = saveConfig(selectedConfigName)
            if primaryValue then
                saveAutoLoadMeta()
            end
            NotifySettings("Config", primaryValue and "Overwrote config: " .. selectedConfigName or secondaryValue or "Overwrite failed")
            RefreshConfigDropdown(primaryValue and selectedConfigName or nil)
        end
    })
    ConfigSection:Button({
        Title = "Delete Config",
        Icon = "sparkles",
        Callback = function()
            local selectedConfigName = SelectedConfigName ~= "-- no config --" and SelectedConfigName or ConfigName
            local primaryValue, secondaryValue = deleteConfig(selectedConfigName)
            NotifySettings("Config", primaryValue and "Deleted config: " .. selectedConfigName or secondaryValue or "Delete failed")
            if primaryValue and SelectedConfigName == selectedConfigName then
                SelectedConfigName = "default"
                saveAutoLoadMeta()
            end
            RefreshConfigDropdown(primaryValue and SelectedConfigName or nil)
        end
    })
    ConfigSection:Button({
        Title = "Refresh Config List",
        Icon = "sparkles",
        Callback = function()
            RefreshConfigDropdown()
            NotifySettings("Config", "Config list refreshed.")
        end
    })
    initWindUIConfig()
    ConfigSection:Paragraph({
        Title = "WindUI-V2 ConfigManager",
        Content = WindUIConfigFile and "Native config is ready. Manual save, auto load, and auto save are available." or "Legacy config storage is active. Manual save, auto load, and auto save are available."
    })
    pcall(function()
        item:SetTheme("Dark")
    end)
    pcall(applyWindowScheme)
    ConfigUIReady = true
    task.defer(function()
        if InitialAutoLoadName then
            local cleanConfigNameResult = cleanConfigName(InitialAutoLoadName)
            SelectedConfigName = cleanConfigNameResult
            ConfigName = cleanConfigNameResult
            local primaryValue, secondaryValue = loadConfig(cleanConfigNameResult)
            if primaryValue then
                AutoLoadConfig = true
                saveAutoLoadMeta()
                SyncConfigToggle(AutoLoadConfigToggle, true)
                SyncConfigToggle(AutoSaveConfigToggle, AutoSaveConfig)
                if ConfigNameInput and type(ConfigNameInput.SetValue) == "function" then
                    pcall(function()
                        ConfigNameInput:SetValue(cleanConfigNameResult)
                    end)
                elseif ConfigNameInput and type(ConfigNameInput.Set) == "function" then
                    pcall(function()
                        ConfigNameInput:Set(cleanConfigNameResult)
                    end)
                end
                RefreshConfigDropdown(cleanConfigNameResult)
                NotifySettings("Config", "Loaded config: " .. cleanConfigNameResult)
            else
                AutoLoadConfig = false
                saveAutoLoadMeta()
                NotifySettings("Config", secondaryValue or "Could not load config: " .. cleanConfigNameResult)
            end
        end
    end)
    local stateMap14 = {}
    getgenv().NNVN_ConfigAutoSaveToken = stateMap14
    task.spawn(function()
        while getgenv().NNVN_ConfigAutoSaveToken == stateMap14 do
            task.wait(30)
            if not AutoSaveConfig or getgenv().NNVN_IsApplyingConfig then
                continue
            end
            saveConfig(SelectedConfigName ~= "-- no config --" and SelectedConfigName or ConfigName)
        end
    end)
    task.spawn(function()
        while true do
            task.wait(math.max(0.5, tonumber(getgenv().NNVN_AutoCastDelay) or 3))
            if not getgenv().NNVN_AutoCast then
            else
                pcall(function()
                    local character = LocalPlayer.Character
                    if character and not character:GetAttribute("Fishing") and not item3.Fishing.Visible and NNVN_RemoteAllowed("AutoCast", getgenv().NNVN_AutoCastDelay) then
                        ReplicatedStorage.Events.Fishing:FireServer()
                    end
                end)
            end
        end
    end)
end

do
    task.spawn(function()
        local toggleHotbar = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("ToggleHotbar")
        if not toggleHotbar then
            return
        end
        while task.wait(1) do
            local autoCast = getgenv().NNVN_AutoCast or getgenv().NNVN_AutoBossFishing or getgenv().NNVN_AutoFarmSecretBoss or getgenv().NNVN_AutoTicket or getgenv().NNVN_AutoFarm2MFish or getgenv().NNVN_MaterialFarming or getgenv().NNVN_MaterialRodFarming or getgenv().NNVN_AutoFarmWeatherEvent
            if autoCast and not getgenv().NNVN_AutoEquipRod then
                activateAutoEquipRodForFarm()
            end
            if getgenv().NNVN_AutoEquipRod or autoCast then
                pcall(function()
                    if not isHoldingFishingRod() then
                        toggleHotbar:InvokeServer("1", nil)
                    end
                end)
            end
        end
    end)
    BossFarmState = getgenv().NNVN_BossFarmState
    BossKeywords = {
        "boss",
        "raid",
        "giant",
        "king",
        "lord"
    }
    SecretBossKeywords = {
        "secret",
        "hidden",
        "mythic",
        "event",
        "rare"
    }
    local bossNameSetMap = { BossNameSet = {}, SecretBossNameSet = {} }
    loadBossNameSets = function()
        table.clear(bossNameSetMap.BossNameSet)
        table.clear(bossNameSetMap.SecretBossNameSet)
        local info = ReplicatedStorage:FindFirstChild("Info")
        if not info then
            return
        end
        pcall(function()
            local fishingAreaRarity = info:FindFirstChild("FishingAreaRarity")
            if fishingAreaRarity then
                local requireResult = require(fishingAreaRarity)
                if type(requireResult) == "table" and type(requireResult["Secret Boss"]) == "table" then
                    for entryKey in pairs(requireResult["Secret Boss"]) do
                        local formattedText = string.lower(tostring(entryKey))
                        bossNameSetMap.SecretBossNameSet[formattedText] = true
                        bossNameSetMap.BossNameSet[formattedText] = true
                    end
                end
            end
        end)
        pcall(function()
            local inventory = info:FindFirstChild("Inventory")
            if inventory then
                for _, entry in pairs(inventory:GetChildren()) do
                    if not entry:IsA("ModuleScript") then
                        continue
                    end
                    local ok, result = pcall(require, entry)
                    if not ok or type(result) ~= "table" then
                        continue
                    end
                    local formattedText = string.lower(tostring(result.FishName or entry.Name))
                    if result.Boss == true or result.SpecialBoss == true or result.SecretBoss == true then
                        bossNameSetMap.BossNameSet[formattedText] = true
                    end
                    if result.SecretBoss == true then
                        bossNameSetMap.SecretBossNameSet[formattedText] = true
                    end
                end
            end
        end)
    end
    loadBossNameSets()
    task.spawn(function()
        while task.wait(30) do
            loadBossNameSets()
        end
    end)
    secretBossWeatherAllowed = function()
        if not getgenv().NNVN_AutoFarmSecretBoss then
            return false
        end
        if getgenv().NNVN_AutoSecretBossMode ~= "Only When Weather" then
            return true
        end
        if type(getCurrentWeather) ~= "function" or type(isSpecialWeatherName) ~= "function" then
            return false
        end
        return isSpecialWeatherName(getCurrentWeather()) == true
    end
    bossFarmEnabled = function()
        return getgenv().NNVN_AutoBossFishing or secretBossWeatherAllowed()
    end
    textHasKeyword = function(inputValue, secondValue)
        inputValue = string.lower(tostring(inputValue or ""))
        for _, item in ipairs(secondValue) do
            if string.find(inputValue, item, 1, true) then
                return true
            end
        end
        return false
    end
    getCurrentHookTarget = function()
        local currentTarget = BossFarmState.CurrentTarget
        local nameMap = {
            Name = nil,
            Data = nil,
            Instance = nil,
            Boss = false,
            SecretBoss = false
        }
        if type(currentTarget) == "table" then
            nameMap.Data = currentTarget
            nameMap.Name = currentTarget.FishName or currentTarget.Name or currentTarget.fishName
            nameMap.Boss = currentTarget.Boss == true or currentTarget.SpecialBoss == true or currentTarget.SecretBoss == true
            nameMap.SecretBoss = currentTarget.SecretBoss == true
        elseif typeof and typeof(currentTarget) == "Instance" then
            nameMap.Instance = currentTarget
            nameMap.Name = currentTarget:GetAttribute("FishName") or currentTarget.Name
            nameMap.Boss = currentTarget:GetAttribute("Boss") == true or currentTarget:GetAttribute("SpecialBoss") == true or currentTarget:GetAttribute("SecretBoss") == true
            nameMap.SecretBoss = currentTarget:GetAttribute("SecretBoss") == true
        elseif type(currentTarget) == "string" then
            nameMap.Name = currentTarget
        end
        local fishIdAttr = LocalPlayer:GetAttribute("FishID")
        local fishes = Workspace:FindFirstChild("Fishes")
        local fishesEntry = fishIdAttr and fishes and fishes:FindFirstChild(tostring(fishIdAttr))
        if fishesEntry then
            nameMap.Instance = fishesEntry
            nameMap.Name = nameMap.Name or fishesEntry:GetAttribute("FishName") or fishesEntry.Name
            nameMap.Boss = nameMap.Boss or fishesEntry:GetAttribute("Boss") == true or fishesEntry:GetAttribute("SpecialBoss") == true or fishesEntry:GetAttribute("SecretBoss") == true
            nameMap.SecretBoss = nameMap.SecretBoss or fishesEntry:GetAttribute("SecretBoss") == true
        end
        local fishing = item3:FindFirstChild("Fishing")
        local progressionBar = fishing and fishing:FindFirstChild("ProgressionBar")
        local fishName = progressionBar and progressionBar:FindFirstChild("FishName")
        if (not nameMap.Name or nameMap.Name == "" or nameMap.Name == "???") and fishName and fishName.Text ~= "" then
            nameMap.Name = fishName.Text
        end
        return nameMap
    end
    isSecretBossTarget = function(inputValue)
        local inputValue2 = inputValue or getCurrentHookTarget()
        local formattedText = string.lower(tostring(inputValue2.Name or ""))
        return inputValue2.SecretBoss or bossNameSetMap.SecretBossNameSet[formattedText] or textHasKeyword(formattedText, SecretBossKeywords)
    end
    isBossTarget = function(inputValue)
        local inputValue2 = inputValue or getCurrentHookTarget()
        local formattedText = string.lower(tostring(inputValue2.Name or ""))
        if isSecretBossTarget(inputValue2) then
            return true
        end
        return inputValue2.Boss or bossNameSetMap.BossNameSet[formattedText] or textHasKeyword(formattedText, BossKeywords)
    end
    shouldFarmBossTarget = function(inputValue)
        local inputValue2 = inputValue or getCurrentHookTarget()
        if isSecretBossTarget(inputValue2) then
            if getgenv().NNVN_AutoBossFishing or secretBossWeatherAllowed() then
                return true, "Secret Boss"
            end
            return false, "Normal"
        end
        if secretBossWeatherAllowed() and not getgenv().NNVN_AutoBossFishing then
            return false, "Normal"
        end
        if getgenv().NNVN_AutoBossFishing and isBossTarget(inputValue2) then
            return true, "Boss"
        end
        return false, "Normal"
    end
    resetBossFarmTarget = function()
        BossFarmState.CurrentTarget = nil
        BossFarmState.CurrentType = nil
        BossFarmState.CurrentToken = nil
        BossFarmState.HasHooked = false
        BossFarmState.PendingCancel = false
    end
    castRodBossFarm = function()
        if not bossFarmEnabled() or tick() - BossFarmState.LastCast < 0.35 then
            return false
        end
        local character = LocalPlayer.Character
        if not character then
            return false
        end
        if character:GetAttribute("Fishing") and not character:GetAttribute("Retractable") then
            return false
        end
        BossFarmState.LastCast = tick()
        resetBossFarmTarget()
        pcall(function()
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                ReplicatedStorage.Events.Fishing:FireServer(rootPart.CFrame)
            else
                ReplicatedStorage.Events.Fishing:FireServer()
            end
        end)
        return true
    end
    cancelOrReleaseNormalFish = function()
        if not bossFarmEnabled() then
            return false
        end
        local character = LocalPlayer.Character
        if not character then
            return false
        end
        if not character:GetAttribute("Fishing") then
            resetBossFarmTarget()
            return true
        end
        BossFarmState.PendingCancel = true
        pcall(function()
            local fishing = item3:FindFirstChild("Fishing")
            local barFrame = fishing and fishing:FindFirstChild("BarFrame")
            local bar = barFrame and barFrame:FindFirstChild("Bar")
            if bar then
                bar.Position = UDim2.new(-0.15, 0, bar.Position.Y.Scale, bar.Position.Y.Offset)
            end
        end)
        if BossFarmState.CurrentToken and tick() - BossFarmState.LastFastCancel > 0.5 then
            BossFarmState.LastFastCancel = tick()
            pcall(function()
                ReplicatedStorage.Events.FishingMinigame:FireServer(false, BossFarmState.CurrentToken)
            end)
        end
        if not character:GetAttribute("Retractable") then
            return false
        end
        if tick() - BossFarmState.LastCancel < 0.35 then
            return false
        end
        BossFarmState.LastCancel = tick()
        pcall(function()
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                ReplicatedStorage.Events.Fishing:FireServer(rootPart.CFrame)
            else
                ReplicatedStorage.Events.Fishing:FireServer()
            end
        end)
        return false
    end
    farmHookedBoss = function(instance)
        if not bossFarmEnabled() then
            return
        end
        local primaryValue, secondaryValue = shouldFarmBossTarget(instance)
        if not primaryValue then
            return
        end
        BossFarmState.CurrentType = secondaryValue
        local combinedText = secondaryValue .. tostring(instance.Name)
        if BossFarmState.LastNotify ~= combinedText then
            BossFarmState.LastNotify = combinedText
            if getgenv().NNVN_Notify and item then
                item:Notify({
                    Title = "Boss Farm",
                    Content = "Farming " .. secondaryValue .. ": " .. tostring(instance.Name or "Unknown"),
                    Duration = 3
                })
            end
        end
        if tick() - BossFarmState.LastProgress > 0.04 then
            BossFarmState.LastProgress = tick()
            pcall(function()
                ReplicatedStorage.Events.UpdateFishProgression:FireServer()
            end)
        end
    end
    task.spawn(function()
        while true do
            if not bossFarmEnabled() then
                task.wait(1.5)
            else
                task.wait(0.2)
                pcall(function()
                    local character = LocalPlayer.Character
                    local fishing = item3:FindFirstChild("Fishing")
                    if character and character:GetAttribute("Fishing") then
                        if BossFarmState.PendingCancel then
                            cancelOrReleaseNormalFish()
                        elseif BossFarmState.HasHooked and fishing and fishing.Visible then
                            local currentHookTarget = getCurrentHookTarget()
                            if shouldFarmBossTarget(currentHookTarget) then
                                BossFarmState.PendingCancel = false
                                farmHookedBoss(currentHookTarget)
                            elseif currentHookTarget.Name and currentHookTarget.Name ~= "???" then
                                BossFarmState.PendingCancel = true
                                cancelOrReleaseNormalFish()
                            end
                        end
                    else
                        resetBossFarmTarget()
                        if not isHoldingFishingRod() then
                            ToggleHotbarSlot1()
                            task.wait(0.15)
                        end
                        castRodBossFarm()
                    end
                end)
            end
        end
    end)
    pcall(function()
        local fishingMinigame = ReplicatedStorage.Events:FindFirstChild("FishingMinigame")
        if not fishingMinigame then
            return
        end
        fishingMinigame.OnClientEvent:Connect(function(inputValue, secondValue, thirdValue)
            if not inputValue or not secondValue then
                return
            end
            BossFarmState.CurrentTarget = inputValue
            BossFarmState.CurrentToken = thirdValue
            BossFarmState.HasHooked = true
            BossFarmState.PendingCancel = false
            BossFarmState.CurrentRunId = BossFarmState.CurrentRunId + 1
            local currentRunId = BossFarmState.CurrentRunId
            local currentHookTarget = getCurrentHookTarget()
            local shouldFarmBossTarget2 = shouldFarmBossTarget(currentHookTarget)
            if bossFarmEnabled() and not shouldFarmBossTarget2 then
                BossFarmState.PendingCancel = true
                task.delay(0.15, cancelOrReleaseNormalFish)
                return
            end
            if getgenv().NNVN_AutoCast or bossFarmEnabled() and shouldFarmBossTarget2 then
                task.spawn(function()
                    local isEnabled = true
                    local item
                    local fishing = item3:FindFirstChild("Fishing")
                    if fishing then
                        item = fishing:GetPropertyChangedSignal("Visible"):Connect(function()
                            if not fishing.Visible then
                                isEnabled = false
                                if item then
                                    item:Disconnect()
                                end
                            end
                        end)
                    end
                    while isEnabled do
                        if bossFarmEnabled() then
                            if currentRunId ~= BossFarmState.CurrentRunId then
                                break
                            end
                            currentHookTarget = getCurrentHookTarget()
                            shouldFarmBossTarget2 = shouldFarmBossTarget(currentHookTarget)
                            if not shouldFarmBossTarget2 then
                                BossFarmState.PendingCancel = true
                                cancelOrReleaseNormalFish()
                                break
                            end
                            farmHookedBoss(currentHookTarget)
                            task.wait(0.05)
                        else
                            pcall(function()
                                ReplicatedStorage.Events.UpdateFishProgression:FireServer()
                            end)
                            task.wait(0.05)
                        end
                    end
                    if bossFarmEnabled() and currentRunId == BossFarmState.CurrentRunId then
                        resetBossFarmTarget()
                    end
                end)
            end
        end)
    end)
    local function resolveFindFirstChild7()
        local data = ReplicatedStorage:FindFirstChild("Data")
        local playerData = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
        if not playerData then
            return nil
        end
        return playerData:FindFirstChild("Inventory")
    end
    local function resolveName2(instance)
        local nameText = tostring(instance and instance.Name or "")
        return (nameText:match("^([^|]+)") or nameText):gsub("^%s+", ""):gsub("%s+$", "")
    end
    local function resolveLower8(instance, secondValue)
        if not instance then
            return nil
        end
        local lookupMap = {}
        for _, item in ipairs(secondValue) do
            lookupMap[string.lower(item)] = true
        end
        local itemList = { instance }
        for _, item2 in ipairs(instance:GetDescendants()) do
            table.insert(itemList, item2)
        end
        for _, item3 in ipairs(itemList) do
            if lookupMap[string.lower(item3.Name)] then
                local ok, result = pcall(function()
                    return item3.Value
                end)
                local parsedNum = ok and tonumber(result) or nil
                if parsedNum then
                    return parsedNum
                end
            end
            for _, item4 in ipairs(secondValue) do
                local ok2, result2 = pcall(function()
                    return item3:GetAttribute(item4)
                end)
                local parsedNum2 = ok2 and tonumber(result2) or nil
                if parsedNum2 then
                    return parsedNum2
                end
            end
        end
        return nil
    end
    local labelMap = { label = nil, nextScan = 0 }
    local function resolveClock3()
        local nowTime = os.clock()
        local label = labelMap.label
        if not label or not label.Parent or labelMap.nextScan <= nowTime then
            labelMap.label = nil
            labelMap.nextScan = nowTime + 2
            local negValue = -math.huge
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local findFirstChild7 = resolveFindFirstChild7()
            local objectListCount = findFirstChild7 and #findFirstChild7:GetChildren() or 0
            for _, item in ipairs(playerGui and playerGui:GetDescendants() or {}) do
                if not item:IsA("TextLabel") and not item:IsA("TextButton") then
                    continue
                end
                local firstMatch, secondMatch = tostring(item.Text or ""):match("([%d,]+)%s*/%s*([%d,]+)")
                local parsedNum = tonumber((firstMatch or ""):gsub(",", ""))
                local parsedNum2 = tonumber((secondMatch or ""):gsub(",", ""))
                if not parsedNum or not parsedNum2 or parsedNum2 < 5 or parsedNum2 > 2000 or parsedNum > parsedNum2 then
                    continue
                end
                local stateMap = {}
                local item2 = item
                for i = 1, 7 do
                    if not item2 then
                        break
                    end
                    if item2 == playerGui then
                        break
                    end
                    table.insert(stateMap, string.lower(tostring(item2.Name or "")))
                    item2 = item2.Parent
                end
                local formattedText = table.concat(stateMap, ".")
                local findResult = formattedText:find("inventory", 1, true) or formattedText:find("backpack", 1, true) or formattedText:find("capacity", 1, true) or formattedText:find("storage", 1, true) or formattedText:find("bag", 1, true)
                local findResult2 = formattedText:find("health", 1, true) or formattedText:find("stamina", 1, true) or formattedText:find("energy", 1, true) or formattedText:find("experience", 1, true) or formattedText:find("level", 1, true) or formattedText:find("boss", 1, true)
                local counter = 0
                if findResult then
                    counter = counter + 1000000
                end
                if findResult2 then
                    counter = counter - 1000000
                end
                if parsedNum2 <= 500 then
                    counter = counter + 5000
                end
                if objectListCount > 0 then
                    counter = counter + math.max(0, 2500 - math.abs(parsedNum - objectListCount) * 250)
                end
                counter = counter - parsedNum2 * 0.01
                if negValue < counter then
                    labelMap.label = item
                    negValue = counter
                end
            end
            label = labelMap.label
        end
        if not label then
            return nil, nil
        end
        local firstMatch2, secondMatch2 = tostring(label.Text or ""):match("([%d,]+)%s*/%s*([%d,]+)")
        firstMatch2 = tonumber((firstMatch2 or ""):gsub(",", ""))
        secondMatch2 = tonumber((secondMatch2 or ""):gsub(",", ""))
        if not firstMatch2 or not secondMatch2 or secondMatch2 < 5 then
            return nil, nil
        end
        return firstMatch2, secondMatch2
    end
    local function checkAttribute5()
        local findFirstChild7 = resolveFindFirstChild7()
        local parent = findFirstChild7 and findFirstChild7.Parent
        local nameList = {
            "InventoryLimit",
            "BackpackLimit",
            "MaxInventory",
            "InventorySize",
            "MaxBackpack",
            "BackpackSize",
            "Capacity",
            "InventoryCapacity",
            "MaxInventorySlots",
            "MaxSlots",
            "SlotLimit",
            "StorageLimit",
            "MaxStorage",
            "BagLimit",
            "BagSize",
            "MaxFish",
            "FishLimit"
        }
        local nameList2 = {
            "InventoryCount",
            "BackpackCount",
            "InventoryUsed",
            "UsedSlots",
            "UsedCapacity",
            "CurrentInventory",
            "CurrentBackpack",
            "CurrentSlots",
            "OccupiedSlots",
            "FishCount",
            "StorageUsed",
            "BagCount",
            "CurrentFish"
        }
        local lower8 = resolveLower8(parent, nameList) or resolveLower8(findFirstChild7, nameList)
        local lower82 = resolveLower8(parent, nameList2) or resolveLower8(findFirstChild7, nameList2)
        if (findFirstChild7 and findFirstChild7:GetAttribute("Full")) == true then
            return 1, 1
        end
        if (parent and parent:GetAttribute("BackpackFull")) == true then
            return 1, 1
        end
        for _, item in ipairs({ findFirstChild7, parent }) do
            if not item then
                continue
            end
            for _, item2 in ipairs({ "Full", "IsFull", "BackpackFull", "InventoryFull" }) do
                local itemEntry = item:FindFirstChild(item2, true)
                if itemEntry and itemEntry:IsA("BoolValue") and itemEntry.Value == true then
                    return 1, 1
                end
            end
        end
        if not lower82 and findFirstChild7 then
            lower82 = 0
            local inventoryLimitMap = {
                InventoryLimit = true,
                BackpackLimit = true,
                MaxInventory = true,
                InventorySize = true,
                MaxBackpack = true,
                BackpackSize = true,
                Capacity = true,
                InventoryCount = true,
                BackpackCount = true,
                InventoryUsed = true,
                UsedSlots = true,
                UsedCapacity = true
            }
            for _, item3 in ipairs(findFirstChild7:GetChildren()) do
                if not inventoryLimitMap[item3.Name] and tostring(item3.Name or "") ~= "" then
                    lower82 = lower82 + 1
                end
            end
        end
        local primaryValue, secondaryValue = resolveClock3()
        if primaryValue and secondaryValue and secondaryValue > 0 then
            return primaryValue, secondaryValue
        end
        return tonumber(lower82), tonumber(lower8)
    end
    local function resolveMax()
        local primaryValue, secondaryValue = checkAttribute5()
        if not primaryValue or not secondaryValue then
            return false
        end
        return math.max(1, math.floor(secondaryValue)) <= primaryValue
    end
    local function resolveSellActionMethod()
        local sellActionMethodText = tostring(getgenv().NNVN_SellActionMethod or "Tween [Safe]")
        if sellActionMethodText:find("Instant", 1, true) then
            return "Instant"
        end
        if sellActionMethodText:find("Teleport", 1, true) then
            return "Teleport"
        end
        return "Tween"
    end
    local function resolveMax2()
        getgenv().NNVN_SellDelay = math.max(1, math.max(0, math.floor(tonumber(getgenv().NNVN_SellDelayMinutes) or 0)) * 60 + math.max(0, math.floor(tonumber(getgenv().NNVN_SellDelaySeconds) or 0)))
        return getgenv().NNVN_SellDelay
    end
    local function checkAttribute6(inputValue)
        local findFirstChild7 = resolveFindFirstChild7()
        if not findFirstChild7 then
            return {}
        end
        local stateMap = {}
        for _, item in ipairs(findFirstChild7:GetChildren()) do
            if item:GetAttribute("NNVN_VirtualDupe") == true then
            else
                local name2 = resolveName2(item)
                local formattedText = string.lower(name2)
                local nameMap = {
                    Name = name2,
                    Boss = false,
                    SecretBoss = false,
                    SecretBoss = bossNameSetMap and bossNameSetMap.SecretBossNameSet[formattedText] or textHasKeyword(formattedText, SecretBossKeywords)
                }
                nameMap.Boss = nameMap.SecretBoss or bossNameSetMap and bossNameSetMap.BossNameSet[formattedText] or textHasKeyword(formattedText, BossKeywords)
                if inputValue == "Normal" and not nameMap.Boss or inputValue == "Boss" and nameMap.Boss or inputValue == "SecretBoss" and nameMap.SecretBoss then
                    table.insert(stateMap, item.Name)
                end
            end
        end
        return stateMap
    end
    local function resolveFindFirstChild8()
        local npcFolder = Workspace:FindFirstChild("NPC")
        local sellFish = npcFolder and npcFolder:FindFirstChild("SellFish")
        if not sellFish then
            return nil
        end
        local item4Result = LocalPlayer.Character and item4(LocalPlayer.Character)
        if not item4Result then
            return sellFish:FindFirstChild("Nana")
        end
        local item
        local item2
        for _, item3 in ipairs(sellFish:GetChildren()) do
            local item4Result2 = item4(item3)
            if not item4Result2 then
                continue
            end
            local magnitude = (item4Result2.Position - item4Result.Position).Magnitude
            if not item2 or magnitude < item2 then
                item = item3
                item2 = magnitude
            end
        end
        return item or sellFish:FindFirstChild("Nana")
    end
    local hasTriggered5 = false
    local function resolveFindFirstChild9(inputValue)
        local events = ReplicatedStorage:FindFirstChild("Events")
        local sellFish = events and events:FindFirstChild("SellFish", true)
        if not sellFish then
            return false
        end
        if sellFish:IsA("RemoteEvent") then
            return pcall(function()
                sellFish:FireServer(inputValue)
            end)
        end
        if sellFish:IsA("RemoteFunction") then
            return pcall(function()
                sellFish:InvokeServer(inputValue)
            end)
        end
        return false
    end
    local function checkAttribute7()
        local stateMap = {}
        local findFirstChild7 = resolveFindFirstChild7()
        for _, item in ipairs(findFirstChild7 and findFirstChild7:GetChildren() or {}) do
            if item:GetAttribute("NNVN_VirtualDupe") ~= true then
                table.insert(stateMap, item.Name)
            end
        end
        return stateMap
    end
    local function resolveAll()
        local checkAttribute7Result = checkAttribute7()
        if #checkAttribute7Result == 0 then
            return true
        end
        local findFirstChild9 = resolveFindFirstChild9("All")
        task.wait(0.45)
        local checkAttribute7Result2 = checkAttribute7()
        if #checkAttribute7Result <= #checkAttribute7Result2 then
            for _, item in ipairs(checkAttribute7Result2) do
                resolveFindFirstChild9(item)
                task.wait(0.1)
            end
        end
        return findFirstChild9
    end
    local function runWarn(inputValue)
        if hasTriggered5 then
            return
        end
        hasTriggered5 = true
        local ok, result = pcall(function()
            local findFirstChild8 = resolveFindFirstChild8()
            RunActionWithMethod({
                target = findFirstChild8 or "Nana",
                forceMethod = resolveSellActionMethod(),
                teleport = function()
                    return findFirstChild8 and TPNear(findFirstChild8, delaySeconds2) or TPNear("Nana", delaySeconds2)
                end,
                returnAfter = true,
                requireTeleport = false
            }, function()
                if inputValue == "All" then
                    resolveAll()
                    if getgenv().NNVN_WebhookSell then
                        whSend("sell", {
                            eventEmoji = "💰",
                            title = "Fish Sold",
                            description = "Sold all fish from the backpack."
                        })
                    end
                    return
                end
                for _, item in ipairs(checkAttribute6(inputValue)) do
                    resolveFindFirstChild9(item)
                    task.wait(0.08)
                end
                if getgenv().NNVN_WebhookSell then
                    whSend("sell:" .. string.lower(inputValue), {
                        eventEmoji = "💰",
                        title = "Fish Sold",
                        description = "Sold fish using the **" .. tostring(inputValue) .. "** filter."
                    })
                end
            end)
        end)
        hasTriggered5 = false
        if not ok then
            warn("[NNVN Auto Sell] " .. tostring(result))
        end
    end
    getgenv().NNVN_SellFishMode = runWarn
    local hasTriggered6 = false
    local function resolveDelay(inputValue)
        if hasTriggered6 then
            return
        end
        hasTriggered6 = true
        task.delay(0.25, function()
            hasTriggered6 = false
            if inputValue and getgenv().NNVN_AutoSell then
                runWarn("All")
                return
            end
            if getgenv().NNVN_AutoSellWhenFull and resolveMax() then
                runWarn("All")
            end
        end)
    end
    getgenv().NNVN_RequestAutoSellCheck = resolveDelay
    task.spawn(function()
        local item
        while not item do
            item = resolveFindFirstChild7()
            if not item then
                task.wait(1)
            end
        end
        item.ChildAdded:Connect(function()
            labelMap.nextScan = 0
            if getgenv().NNVN_AutoSellWhenFull then
                resolveDelay(false)
            end
        end)
        item.ChildRemoved:Connect(function()
            labelMap.nextScan = 0
        end)
    end)
    task.spawn(function()
        while true do
            task.wait(resolveMax2())
            local autoSell = getgenv().NNVN_AutoSell
            local max = getgenv().NNVN_AutoSellWhenFull and resolveMax()
            local secretBossLabel = getgenv().NNVN_AutoSellOnlySecretBoss and "SecretBoss"
            if not secretBossLabel then
                secretBossLabel = getgenv().NNVN_AutoSellOnlyBoss and "Boss"
            end
            if not secretBossLabel then
                secretBossLabel = getgenv().NNVN_AutoSellNormalFish and "Normal"
            end
            if not autoSell and not max and not secretBossLabel then
            else
                pcall(function()
                    runWarn((autoSell or max) and "All" or secretBossLabel)
                end)
            end
        end
    end)
    NNVN_GetSkillButton = function(inputValue)
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainGui = playerGui and playerGui:FindFirstChild("MainGui") or item3
        local fishing = mainGui and mainGui:FindFirstChild("Fishing")
        local skillButton = fishing and fishing:FindFirstChild("SkillButton")
        local frame = skillButton and skillButton:FindFirstChild("Frame")
        return frame and frame:FindFirstChild(tostring(inputValue))
    end
    local function executeAction7(inputValue)
        local ok, result = pcall(function()
            local skillButton = NNVN_GetSkillButton(inputValue)
            if not skillButton then
                return nil
            end
            local cd = skillButton:FindFirstChild("CD") or skillButton:FindFirstChild("CD", true)
            if not cd then
                return 0
            end
            if cd:IsA("GuiObject") and cd.Visible == false then
                return 0
            end
            local cd2 = (cd:IsA("TextLabel") or cd:IsA("TextButton")) and cd or cd:FindFirstChildWhichIsA("TextLabel", true) or cd:FindFirstChildWhichIsA("TextButton", true)
            local parsedNum = tonumber((cd2 and tostring(cd2.Text or "") or ""):match("%-?%d+%.?%d*"))
            if parsedNum then
                return math.max(0, parsedNum)
            end
            for _, item in ipairs({ "Cooldown", "TimeLeft", "Remaining", "Duration" }) do
                local parsedNum2 = tonumber(cd:GetAttribute(item))
                if parsedNum2 then
                    return math.max(0, parsedNum2)
                end
            end
            return 999
        end)
        if not ok then
            return nil
        end
        return result
    end
    task.spawn(function()
        local skillFlags = {
            Z = Enum.KeyCode.Z,
            X = Enum.KeyCode.X,
            C = Enum.KeyCode.C,
            V = Enum.KeyCode.V
        }
        local skillFlags2 = { Z = 90, X = 88, C = 67, V = 86 }
        local counter = 0
        local function resolveSkillOrder()
            local stateMap = {}
            local lookupMap = {}
            for _, item in ipairs(getgenv().NNVN_SkillOrder or {}) do
                item = string.upper(tostring(item))
                if skillFlags[item] and not lookupMap[item] then
                    lookupMap[item] = true
                    table.insert(stateMap, item)
                end
            end
            for _, item2 in ipairs({ "Z", "X", "C", "V" }) do
                if not lookupMap[item2] then
                    table.insert(stateMap, item2)
                end
            end
            return stateMap
        end
        local function resolveAutoSkillMethod(inputValue)
            local autoSkillMethod = getgenv().NNVN_AutoSkillMethod
            if autoSkillMethod == "Skill Event" then
                local events = ReplicatedStorage:FindFirstChild("Events")
                local useSkill = events and events:FindFirstChild("UseSkill")
                if not useSkill then
                    return false
                end
                local nowTime = os.clock()
                if nowTime - (tonumber(getgenv().NNVN_AutoSkillLastRemote) or 0) < 0.9 or not NNVN_RemoteAllowed("AutoSkill:" .. inputValue, 0.9) then
                    return false
                end
                local hasTriggered = false
                if useSkill:IsA("RemoteEvent") then
                    hasTriggered = pcall(function()
                        useSkill:FireServer(inputValue)
                    end)
                elseif useSkill:IsA("RemoteFunction") then
                    hasTriggered = pcall(function()
                        useSkill:InvokeServer(inputValue)
                    end)
                end
                if hasTriggered then
                    getgenv().NNVN_AutoSkillLastRemote = nowTime
                end
                return hasTriggered
            end
            if autoSkillMethod == "Mobile (Click)" then
                local skillButton = NNVN_GetSkillButton(inputValue)
                local skillButton2 = skillButton
                if skillButton2 then
                    skillButton2 = skillButton:IsA("GuiButton") and skillButton or skillButton:FindFirstChildWhichIsA("GuiButton", true)
                end
                if not skillButton2 or not skillButton2.Visible then
                    return false
                end
                if pcall(function()
                    skillButton2:Activate()
                end) then
                    return true
                end
                local absolutePosition = skillButton2.AbsolutePosition
                local absoluteSize = skillButton2.AbsoluteSize
                return pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(absolutePosition.X + absoluteSize.X / 2, absolutePosition.Y + absoluteSize.Y / 2, 0, true, game, 0)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(absolutePosition.X + absoluteSize.X / 2, absolutePosition.Y + absoluteSize.Y / 2, 0, false, game, 0)
                end)
            end
            local rawgetResult = rawget(getgenv(), "keypress") or rawget(_G, "keypress")
            local rawgetResult2 = rawget(getgenv(), "keyrelease") or rawget(_G, "keyrelease")
            if type(rawgetResult) == "function" and type(rawgetResult2) == "function" and pcall(function()
                rawgetResult(skillFlags2[inputValue])
                task.wait(0.05)
                rawgetResult2(skillFlags2[inputValue])
            end) then
                return true
            end
            local skillFlag = skillFlags[inputValue]
            if not skillFlag then
                return false
            end
            return pcall(function()
                VirtualInputManager:SendKeyEvent(true, skillFlag, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, skillFlag, false, game)
            end)
        end
        while true do
            if not getgenv().NNVN_AutoSkill then
                counter = 0
                task.wait(1.5)
            else
                task.wait(0.35)
                local skillOrder = resolveSkillOrder()
                local skills = getgenv().NNVN_Skills or { Z = true, X = true, C = true, V = true }
                for i = 1, #skillOrder do
                    if not getgenv().NNVN_AutoSkill then
                        break
                    end
                    local computedValue = (counter + i - 1) % #skillOrder + 1
                    local skillKey = skillOrder[computedValue]
                    if skills[skillKey] and executeAction7(skillKey) == 0 then
                        counter = computedValue
                        resolveAutoSkillMethod(skillKey)
                        break
                    end
                end
            end
        end
    end)
    local counter8 = 0
    local counter9 = 0
    RunService.RenderStepped:Connect(function()
        if not getgenv().NNVN_Anchor then
            return
        end
        local nowTime = os.clock()
        if nowTime - counter9 < 1 / 30 then
            return
        end
        counter9 = nowTime
        pcall(function()
            local fishing = item3.Fishing
            if fishing.Visible then
                local bar = fishing.BarFrame.Bar
                bar.Position = UDim2.new(0.5, 0, bar.Position.Y.Scale, 0)
                if nowTime - counter8 >= 0.65 and NNVN_RemoteAllowed("AnchorBar", 0.65) then
                    counter8 = nowTime
                    ReplicatedStorage.Fishing:FireServer("1")
                end
            end
        end)
    end)
    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = getgenv().NNVN_WalkSpeed
        end
        if getgenv().NNVN_AutoCast and not HasFishingRod() then
            pcall(EquipSlot1)
        end
        if getgenv().NNVN_NoClip then
            for _, item in ipairs(character:GetChildren()) do
                if item:IsA("BasePart") then
                    item.CanCollide = false
                    item.CanTouch = false
                end
            end
        end
        if getgenv().NNVN_AutoEquipRod then
            pcall(EquipSlot1)
        end
        task.defer(applyHidePlayerId)
        task.defer(applyHidePlayerName)
        task.defer(applyFakeVisuals)
        task.defer(applyFakeHeadless)
        task.defer(applyFakeKorblox)
        if getgenv().NNVN_FakeSkinEnabled then
            task.defer(applyFakeSkinFromPlayer)
        end
    end)
    if not getgenv()._NNVN_AntiAfkIdledHooked then
        getgenv()._NNVN_AntiAfkIdledHooked = true
        pcall(function()
            LocalPlayer.Idled:Connect(function()
                if not getgenv().NNVN_AntiAFK then
                    return
                end
                pcall(function()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
                pcall(function()
                    local events = ReplicatedStorage:FindFirstChild("Events")
                    local afk = events and events:FindFirstChild("AFK")
                    if afk then
                        afk:FireServer("Stay Active")
                    end
                end)
            end)
        end)
    end
    task.spawn(function()
        while true do
            if getgenv().NNVN_AntiAFK then
                pcall(function()
                    local events = ReplicatedStorage:FindFirstChild("Events")
                    local afk = events and events:FindFirstChild("AFK")
                    if afk then
                        pcall(function()
                            afk:FireServer("Stay Active")
                        end)
                        pcall(function()
                            afk:FireServer()
                        end)
                    end
                end)
            end
            task.wait(55)
        end
    end)
    task.spawn(function()
        local function resolveAntiStaffUser()
            local lookupMap = {}
            for _, item in ipairs(getgenv().NNVN_AntiStaffUserIds or {}) do
                local parsedNum = tonumber(item)
                if parsedNum then
                    lookupMap[parsedNum] = true
                    lookupMap[tostring(parsedNum)] = true
                end
            end
            return lookupMap
        end
        local function resolveUserId(player)
            if not player or player == LocalPlayer then
                return false
            end
            local antiStaffUser = resolveAntiStaffUser()
            local userId = player.UserId
            if antiStaffUser[userId] or antiStaffUser[tostring(userId)] then
                return true, "UserId", userId
            end
            return false
        end
        local function executeAction()
            pcall(function()
                local httpPayload = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"))
                local data = httpPayload and httpPayload.data
                if type(data) == "table" then
                    for _, item in ipairs(data) do
                        if item.id and tostring(item.id) ~= tostring(game.JobId) and (item.playing or 0) < (item.maxPlayers or 10) then
                            TeleportService:TeleportToPlaceInstance(placeId, item.id, LocalPlayer)
                            return
                        end
                    end
                end
                TeleportService:Teleport(placeId, LocalPlayer)
            end)
        end
        local function resolveClock(player, secondValue, thirdValue)
            local nowTime = os.clock()
            if nowTime - (tonumber(getgenv().NNVN_AntiStaffCooldown) or 0) < 8 then
                return
            end
            getgenv().NNVN_AntiStaffCooldown = nowTime
            local formattedText = string.format("Staff detected: %s (@%s) | %s=%s", tostring(player.DisplayName or player.Name), tostring(player.Name), tostring(secondValue or "?"), tostring(thirdValue or ""))
            if getgenv().NNVN_Notify then
                pcall(function()
                    item:Notify({ Title = "Anti Staff", Content = formattedText, Duration = 6 })
                end)
            end
            getgenv().NNVN_AutoCast = false
            getgenv().NNVN_AutoBossFishing = false
            getgenv().NNVN_AutoFarmSecretBoss = false
            getgenv().NNVN_AutoBoss = false
            local antiStaffActionText = tostring(getgenv().NNVN_AntiStaffAction or "ServerHop")
            if antiStaffActionText == "Kick" then
                pcall(function()
                    LocalPlayer:Kick("Staff Detected: " .. tostring(player.Name))
                end)
            elseif antiStaffActionText == "ServerHop" and canAutoServerHop() then
                task.delay(0.35, executeAction)
            end
        end
        task.spawn(function()
            while task.wait(4) do
                if not getgenv().NNVN_AntiStaff then
                else
                    pcall(function()
                        for _, item in ipairs(Players:GetPlayers()) do
                            local primaryValue, secondaryValue, thirdValue = resolveUserId(item)
                            if primaryValue then
                                resolveClock(item, secondaryValue, thirdValue)
                                break
                            end
                        end
                    end)
                end
            end
        end)
        Players.PlayerAdded:Connect(function(player)
            if not getgenv().NNVN_AntiStaff then
                return
            end
            task.delay(1.5, function()
                local primaryValue, secondaryValue, thirdValue = resolveUserId(player)
                if primaryValue then
                    resolveClock(player, secondaryValue, thirdValue)
                end
            end)
        end)
    end)
    LocalPlayer.CharacterRemoving:Connect(function()
        if not getgenv().NNVN_AutoRejoin then
            return
        end
        task.delay(3, function()
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, game.JobId, LocalPlayer)
            end)
        end)
    end)
    task.spawn(function()
        local counter = 0
        while true do
            local isAllowed = (getgenv().NNVN_BlankPlayerId == true or getgenv().NNVN_HidePlayerId ~= false or getgenv().NNVN_HidePlayerName ~= false) and not getgenv().NNVN_HideUI and not getgenv().NNVN_FakeVisualsEnabled and not getgenv().NNVN_FakeHeadless and not getgenv().NNVN_FakeKorblox and not getgenv().NNVN_FakeSkinEnabled and not getgenv().NNVN_ShowPremiumRelayMenu
            local hideUi = getgenv().NNVN_HideUI or getgenv().NNVN_FakeVisualsEnabled or getgenv().NNVN_FakeHeadless or getgenv().NNVN_FakeKorblox or getgenv().NNVN_FakeSkinEnabled or getgenv().NNVN_ShowPremiumRelayMenu
            if isAllowed then
                pcall(applyHidePlayerId)
                pcall(applyHidePlayerName)
                task.wait(10)
            elseif hideUi then
                pcall(applyHidePlayerId)
                pcall(applyHidePlayerName)
                if getgenv().NNVN_HideUI then
                    pcall(RequestHideUI)
                else
                    pcall(RequestShowUI)
                end
                if getgenv().NNVN_FakeVisualsEnabled then
                    pcall(applyFakeVisuals)
                end
                if getgenv().NNVN_FakeHeadless then
                    pcall(applyFakeHeadless)
                end
                if getgenv().NNVN_FakeKorblox then
                    pcall(applyFakeKorblox)
                end
                if getgenv().NNVN_FakeSkinEnabled then
                    pcall(applyFakeSkinTone)
                end
                pcall(updatePremiumRelayMenu)
                task.wait(10)
            else
                task.wait(20)
            end
        end
    end)
    getgenv().NNVN_PremiumRelayLoopId = (tonumber(getgenv().NNVN_PremiumRelayLoopId) or 0) + 1
    task.spawn(function(inputValue)
        local counter = 0
        while task.wait(6) and inputValue == getgenv().NNVN_PremiumRelayLoopId do
            local weatherReporterName = normalizeWeatherReporterName(getCurrentWeather())
            local weatherReporterName2 = normalizeWeatherReporterName(getgenv().NNVN_PremiumSelectedWeather)
            local isMatched = getGodSpiritCount() > 0
            local isMatched2 = findTrackerObject("taoist") ~= nil
            local isMatched3 = findTrackerObject("maoshan") ~= nil
            if not refreshPremiumAccess() then
                getgenv().NNVN_PremiumWeatherEnabled = false
                getgenv().NNVN_PremiumSpiritEnabled = false
                getgenv().NNVN_PremiumTaoistEnabled = false
                getgenv().NNVN_PremiumMaoshanEnabled = false
                if premiumStatusParagraph then
                    premiumStatusParagraph:SetDesc(table.concat({
                        "Tier: FREE",
                        "Board: weather, spirit, taoist, maoshan, black tortoise, vermilion",
                        "Join: locked"
                    }, "\n"))
                end
            else
                updatePremiumSignalBoardUI()
            end
            local hasTriggered = false
            local item
            if refreshPremiumAccess() then
                if getgenv().NNVN_PremiumWeatherEnabled and weatherReporterName ~= weatherReporterName2 then
                    hasTriggered = true
                    item = "weather"
                elseif getgenv().NNVN_PremiumSpiritEnabled and not isMatched then
                    hasTriggered = true
                    item = "spirit"
                elseif getgenv().NNVN_PremiumTaoistEnabled and not isMatched2 then
                    hasTriggered = true
                    item = "taoist"
                elseif getgenv().NNVN_PremiumMaoshanEnabled and not isMatched3 then
                    hasTriggered = true
                    item = "maoshan"
                end
            end
            if not getgenv().NNVN_IsApplyingConfig and canAutoServerHop() and hasTriggered and os.clock() - counter >= 8 then
                pcall(refreshPremiumSignalEntry, item, false)
                local premiumSignalBoardCache2 = item and premiumSignalBoardCache[item] or nil
                if premiumSignalBoardCache2 and not premiumSignalBoardCache2.relayStale and isValidRelayJobId(premiumSignalBoardCache2.jobId) and tostring(premiumSignalBoardCache2.jobId) ~= tostring(game.JobId) then
                    counter = os.clock()
                    pcall(function()
                        getgenv().NNVN_JobIdInput = tostring(premiumSignalBoardCache2.jobId)
                        TeleportService:TeleportToPlaceInstance(tonumber(premiumSignalBoardCache2.placeId) or placeId, tostring(premiumSignalBoardCache2.jobId), LocalPlayer)
                    end)
                end
            end
            if type(UpdateHubRuntimeInfo) == "function" then
                pcall(UpdateHubRuntimeInfo)
            end
        end
    end, getgenv().NNVN_PremiumRelayLoopId)
    task.spawn(function()
        local item
        local function resolveSetValue(inputValue, secondValue)
            local stateMap2Entry = stateMap2 and stateMap2[inputValue]
            if stateMap2Entry and stateMap2Entry.SetValue and pcall(function()
                stateMap2Entry:SetValue(secondValue)
            end) then
                return
            end
            getgenv()[inputValue] = secondValue
        end
        local function resolveEnzo()
            local npcByName = FindNPCByName("Enzo") or FindNPCByName("Boss NPC") or FindNPCByName("BossNPC")
            if not npcByName then
                return false
            end
            equipRodBeforeBossFight()
            local hasTriggered = false
            RunActionWithMethod({
                target = npcByName,
                teleport = function()
                    return TPNear(npcByName, delaySeconds2)
                end,
                returnAfter = false
            }, function()
                local events = ReplicatedStorage:FindFirstChild("Events")
                local startBossFight = events and events:FindFirstChild("StartBossFight")
                if startBossFight then
                    startBossFight:FireServer("Enzo", getgenv().NNVN_BossDifficulty)
                    hasTriggered = true
                end
            end)
            return hasTriggered
        end
        local function resolveAnchor(inputValue)
            if inputValue then
                if item then
                    return
                end
                if not resolveEnzo() then
                    return
                end
                item = {
                    Anchor = getgenv().NNVN_Anchor == true,
                    AutoSkill = getgenv().NNVN_AutoSkill == true
                }
                if not getgenv().NNVN_Anchor then
                    resolveSetValue("NNVN_Anchor", true)
                end
                if not getgenv().NNVN_AutoSkill then
                    resolveSetValue("NNVN_AutoSkill", true)
                end
                return
            end
            if item then
                resolveSetValue("NNVN_Anchor", item.Anchor)
                resolveSetValue("NNVN_AutoSkill", item.AutoSkill)
                item = nil
            end
        end
        task.spawn(function()
            local item
            while task.wait(0.35) do
                local isMatched = getgenv().NNVN_AutoBoss == true
                if isMatched ~= item then
                    item = isMatched
                    pcall(resolveAnchor, isMatched)
                end
            end
        end)
        local historyMap = { history = {} }
        local function resolveClear()
            table.clear(historyMap.history)
            historyMap.lastHit = 0
        end
        if getgenv()._EnzoP2ClickConn then
            pcall(function()
                getgenv()._EnzoP2ClickConn:Disconnect()
            end)
        end
        if getgenv()._EnzoP2Heartbeat then
            pcall(function()
                getgenv()._EnzoP2Heartbeat:Disconnect()
            end)
        end
        getgenv()._EnzoP2ClickConn = RunService.RenderStepped:Connect(function()
            if not getgenv().NNVN_AutoPhase2 then
                resolveClear()
                return
            end
            pcall(function()
                local fishing = item3:FindFirstChild("Fishing")
                local bossFightBar = fishing and fishing:FindFirstChild("BossFightBar")
                if not bossFightBar or not bossFightBar.Visible then
                    resolveClear()
                    return
                end
                if NNVN_ShouldHitBossPhase2(historyMap, bossFightBar) then
                    NNVN_FireBossPhase2Input()
                end
            end)
        end)
    end)
    task.spawn(function()
        while task.wait(3) do
            if not getgenv().NNVN_AutoEquipBestBait then
            else
                pcall(function()
                    local playerData = GetPlayerData()
                    if not playerData then
                        return
                    end
                    local equippedBait = playerData:FindFirstChild("EquippedBait")
                    if not equippedBait then
                        return
                    end
                    local value = equippedBait.Value or ""
                    local bestBait = GetBestBait()
                    if bestBait and bestBait ~= value then
                        EquipBait(bestBait)
                        item:Notify({
                            Title = "Auto Equip",
                            Content = "Best bait: " .. bestBait,
                            Duration = 2
                        })
                    end
                end)
            end
        end
    end)
    task.spawn(function()
        while task.wait(5) do
            if not getgenv().NNVN_AutoEquipBestOrb then
            else
                pcall(function()
                    local bestOrb = GetBestOrb()
                    if bestOrb then
                        EquipOrb(bestOrb)
                    end
                end)
            end
        end
    end)
    getgenv().NNVN_AutoBuyBaitLoopId = (getgenv().NNVN_AutoBuyBaitLoopId or 0) + 1
    task.spawn(function()
        local autoBuyBaitLoop = getgenv().NNVN_AutoBuyBaitLoopId
        while autoBuyBaitLoop == getgenv().NNVN_AutoBuyBaitLoopId do
            if not getgenv().NNVN_AutoBuyBait then
                task.wait(0.5)
            else
                local selectedBait = getgenv().NNVN_SelectedBait or "Basic Bait"
                local maxResult = math.max(1, math.floor(tonumber(getgenv().NNVN_BaitQuantity) or 1))
                if NNVN_FireBuyBait(selectedBait, maxResult) and getgenv().NNVN_Notify then
                    item:Notify({
                        Title = "Auto Buy",
                        Content = "Bought " .. maxResult .. "x " .. selectedBait,
                        Duration = 2
                    })
                end
                task.wait(math.max(1, tonumber(getgenv().NNVN_AutoBuyBaitDelay) or 3))
            end
        end
    end)
    UserInputService.JumpRequest:Connect(function()
        if getgenv().NNVN_InfiniteJump and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    doBackflip = function()
        local character = LocalPlayer.Character
        if not character then
            return
        end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not rootPart or not humanoid then
            return
        end
        if humanoid.Sit then
            return
        end
        local clampResult = math.clamp(tonumber(getgenv().NNVN_BackflipDistance) or 8, 1, 15)
        local cFrame = rootPart.CFrame
        local lookVector = cFrame.LookVector
        local vector3 = Vector3.new(0, 1, 0)
        local rightVector = cFrame.RightVector
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
        local stepIndex = 18
        local computedValue = 0.55 / stepIndex
        local computedValue2 = 6 + clampResult * 0.35
        for i = 1, stepIndex do
            if not rootPart then
                break
            end
            if not rootPart.Parent then
                break
            end
            local computedValue3 = i / stepIndex
            local computedValue4 = cFrame.Position + lookVector * clampResult * computedValue3 + vector3 * math.sin(math.pi * computedValue3) * computedValue2
            local fromAxisAngleResult = CFrame.fromAxisAngle(rightVector, -math.rad(360 * computedValue3))
            local lookAtResult = CFrame.lookAt(computedValue4, computedValue4 + lookVector, vector3)
            rootPart.CFrame = CFrame.new(computedValue4) * (lookAtResult - lookAtResult.Position) * fromAxisAngleResult
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            task.wait(computedValue)
        end
        if rootPart and rootPart.Parent then
            local computedValue5 = cFrame.Position + lookVector * clampResult
            rootPart.CFrame = CFrame.new(computedValue5, computedValue5 + lookVector)
            rootPart.AssemblyLinearVelocity = lookVector * 8 + Vector3.new(0, 2, 0)
            rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            pcall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            end)
        end
    end
    getgenv().NNVN_DoBackflip = doBackflip
    task.spawn(function()
        local hasTriggered = false
        RunService.Heartbeat:Connect(function()
            if getgenv().NNVN_FlyMode and flyState and flyState.flying and flyState.bg and flyState.bv and LocalPlayer.Character then
                local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if rootPart and humanoid then
                    local moveDirection = humanoid.MoveDirection
                    flyState.bv.Velocity = Vector3.new(moveDirection.X, 0, moveDirection.Z) * flyState.speed + Vector3.new(0, ((flyState.flyKeys.Up and 1 or 0) - (flyState.flyKeys.Down and 1 or 0)) * flyState.speed, 0)
                    local vector3 = Vector3.new(currentCamera.CFrame.LookVector.X, 0, currentCamera.CFrame.LookVector.Z)
                    if vector3.Magnitude > 0.01 then
                        flyState.bg.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + vector3.Unit)
                    end
                end
            end
            if getgenv().NNVN_FullBright then
                if not hasTriggered then
                    Lighting.Ambient = Color3.new(1, 1, 1)
                    Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
                    Lighting.ColorShift_Top = Color3.new(1, 1, 1)
                    Lighting.Brightness = 2
                    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                    hasTriggered = true
                end
            else
                hasTriggered = false
            end
        end)
    end)
    task.spawn(function()
        local stateMap = {}
        local item
        local counter = 0
        local function resolveClear(instance)
            table.clear(stateMap)
            if not instance then
                return
            end
            for _, item2 in ipairs(instance:GetDescendants()) do
                if item2:IsA("BasePart") then
                    table.insert(stateMap, item2)
                end
            end
            item = instance
            counter = os.clock()
        end
        RunService.Heartbeat:Connect(function()
            if not getgenv().NNVN_NoClip then
                return
            end
            local character = LocalPlayer.Character
            if not character then
                return
            end
            if character ~= item or os.clock() - counter > 2 then
                resolveClear(character)
            end
            for i = 1, #stateMap do
                local stateEntry = stateMap[i]
                if stateEntry and stateEntry.Parent and stateEntry.CanCollide then
                    stateEntry.CanCollide = false
                end
            end
        end)
    end)
    task.spawn(function()
        getgenv().NNVN_AllowAutomaticServerHop = false
        getgenv().NNVN_ServerHopArmed = false
        getgenv().NNVN_AutoHopFightEnzo = false
        getgenv().NNVN_AutoRejoin = false
        getgenv().NNVN_PremiumWeatherEnabled = false
        getgenv().NNVN_PremiumSpiritEnabled = false
        getgenv().NNVN_PremiumTaoistEnabled = false
        getgenv().NNVN_PremiumMaoshanEnabled = false
        refreshPremiumAccess = function()
            local isMatched = rawget(_G, "NNVN_IsPremium") == true or getgenv().NNVN_IsPremium == true or rawget(_G, "SCRIPT_IsPremium") == true or getgenv().SCRIPT_IsPremium == true
            getgenv().NNVN_IsPremiumAccess = isMatched
            return isMatched
        end
        getgenv().NNVN_IsPremiumAccess = refreshPremiumAccess()
        if type(updatePremiumSignalBoardUI) == "function" then
            pcall(updatePremiumSignalBoardUI)
        end
        task.spawn(function()
            task.wait(tonumber(getgenv().NNVN_HopGraceSeconds) or 20)
            getgenv().NNVN_HopBootLocked = false
            getgenv().NNVN_AllowAutomaticServerHop = false
            getgenv().NNVN_ServerHopArmed = false
        end)
    end)
    Window:SelectTab(1)
    if getgenv().NNVN_Notify then
        item:Notify({
            Title = "🎣 NNVN Hub v" .. hubVersion .. " [UltraObsidian]",
            Content = uiStrings.loaded .. "\ndiscord.gg/5JJAuHRUgJ\nUltraObsidian loaded",
            Duration = 3
        })
    end
    getgenv().NNVN_Loaded = true
    if (getgenv().NNVN_Language or "English") ~= "English" then
        task.delay(2, function()
            pcall(ApplyUILanguage)
        end)
    end
end
