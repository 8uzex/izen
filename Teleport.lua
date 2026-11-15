-- Teleport tới người chơi (1 file, chạy bằng executor, chỉ chạy phía client)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ===== CẤU HÌNH =====
local FOLLOW_OFFSET = CFrame.new(0, 0, 3) -- vị trí so với người được bám (0,0,3 = đứng sau lưng 3 stud)
-- ====================

local BG = Color3.fromRGB(25, 27, 34)
local PANEL = Color3.fromRGB(38, 41, 52)
local ACCENT = Color3.fromRGB(88, 130, 255)
local ON = Color3.fromRGB(60, 190, 110)
local OFF = Color3.fromRGB(200, 70, 70)
local WHITE = Color3.new(1, 1, 1)

local function getParent()
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and h then return h end
	ok, h = pcall(function() return game:GetService("CoreGui") end)
	if ok and h then return h end
	return player:WaitForChild("PlayerGui")
end

local parent = getParent()
local old = parent:FindFirstChild("TeleportExecUI")
if old then old:Destroy() end

local function make(class, props, par)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = par
	return o
end
local function round(o, r) make("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o) end

local selectedPlayer = nil
local followOn = false
local followConn = nil
local filterText = ""

local function playerCF(plr)
	local r = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	return r and r.CFrame or nil
end

local function teleportToPlayer(plr)
	local cf = playerCF(plr)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if cf and root then root.CFrame = cf + Vector3.new(0, 3, 0) end
end

local function stopFollow()
	followOn = false
	if followConn then followConn:Disconnect(); followConn = nil end
end

local function startFollow()
	if followConn then followConn:Disconnect() end
	followConn = RunService.Heartbeat:Connect(function()
		local cf = playerCF(selectedPlayer)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if cf and root then
			root.CFrame = cf * FOLLOW_OFFSET
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end)
end

-- UI
local gui = make("ScreenGui", { Name = "TeleportExecUI", ResetOnSpawn = false }, parent)

local toggleBtn = make("TextButton", {
	Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0, 12, 0.5, -22),
	BackgroundColor3 = ACCENT, Text = "📍", TextSize = 22,
}, gui)
round(toggleBtn, 22)

local frame = make("Frame", {
	Size = UDim2.fromOffset(260, 350), Position = UDim2.new(0, 64, 0.5, -175),
	BackgroundColor3 = BG, Visible = false, Active = true, Draggable = true,
}, gui)
round(frame, 12)

make("TextLabel", {
	Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 6),
	BackgroundTransparency = 1, Text = "Teleport tới người chơi", Font = Enum.Font.GothamBold,
	TextSize = 16, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left,
}, frame)

local searchBox = make("TextBox", {
	Size = UDim2.new(1, -16, 0, 32), Position = UDim2.fromOffset(8, 40),
	BackgroundColor3 = PANEL, Text = "", PlaceholderText = "Tìm tên người chơi...",
	Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = WHITE,
	PlaceholderColor3 = Color3.fromRGB(150, 150, 160), ClearTextOnFocus = false,
}, frame)
round(searchBox, 8)

local list = make("ScrollingFrame", {
	Size = UDim2.new(1, -16, 1, -136), Position = UDim2.fromOffset(8, 80),
	BackgroundColor3 = PANEL, BorderSizePixel = 0, ScrollBarThickness = 4,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, frame)
round(list, 8)
make("UIListLayout", { Padding = UDim.new(0, 4) }, list)
make("UIPadding", {
	PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
	PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
}, list)

local autoBtn = make("TextButton", {
	Size = UDim2.new(1, -16, 0, 40), Position = UDim2.new(0, 8, 1, -48),
	BackgroundColor3 = OFF, Text = "Bám theo: TẮT",
	Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = WHITE,
}, frame)
round(autoBtn, 8)

local rows = {}
local function rebuild()
	for _, r in ipairs(rows) do r:Destroy() end
	rows = {}
	local q = filterText:lower()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local label = plr.DisplayName .. " (@" .. plr.Name .. ")"
			if q == "" or label:lower():find(q, 1, true) then
				local btn = make("TextButton", {
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundColor3 = (selectedPlayer == plr) and ACCENT or BG,
					Text = label, Font = Enum.Font.Gotham, TextSize = 13,
					TextColor3 = WHITE, TextTruncate = Enum.TextTruncate.AtEnd,
				}, list)
				round(btn, 6)
				btn.MouseButton1Click:Connect(function()
					selectedPlayer = plr
					teleportToPlayer(plr)
					rebuild()
				end)
				table.insert(rows, btn)
			end
		end
	end
end
rebuild()

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	filterText = searchBox.Text
	rebuild()
end)

Players.PlayerAdded:Connect(rebuild)
Players.PlayerRemoving:Connect(function(plr)
	if selectedPlayer == plr then
		selectedPlayer = nil
		stopFollow()
		autoBtn.Text = "Bám theo: TẮT"
		autoBtn.BackgroundColor3 = OFF
	end
	task.defer(rebuild)
end)

toggleBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

autoBtn.MouseButton1Click:Connect(function()
	if followOn then
		stopFollow()
	elseif selectedPlayer then
		followOn = true
		startFollow()
	end
	autoBtn.Text = followOn and "Bám theo: BẬT" or "Bám theo: TẮT"
	autoBtn.BackgroundColor3 = followOn and ON or OFF
end)
