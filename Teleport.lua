-- Teleport tới người chơi + bám theo (1 file, chạy bằng executor, chỉ chạy phía client)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local player = Players.LocalPlayer

-- ===== CẤU HÌNH =====
local FOLLOW_OFFSET = CFrame.new(0, 0, 3)          -- vị trí so với người được bám (đứng sau lưng 3 stud)
local TOGGLE_UI_KEY = Enum.KeyCode.RightShift      -- phím ẩn/hiện bảng (PC)
local FOLLOW_KEY = Enum.KeyCode.K                  -- phím bật/tắt bám theo (PC)
local RESPAWN_KEY = Enum.KeyCode.J                 -- phím bật/tắt auto hồi sinh (PC)
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

local function make(class, props, par)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = par
	return o
end
local function round(o, r) make("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o) end

-- ===== Trạng thái (giữ nguyên kể cả khi UI bị dựng lại) =====
local selectedPlayer = nil
local followOn = false
local followConn = nil
local filterText = ""
local uiVisible = false
local respawnOn = false
local cachedRespawn = nil
local ui = nil

local rebuildList, setFollowUI, setVisible, toggleFollow, buildUI
local setRespawnUI, toggleRespawn

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
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if cf and root and hum and hum.Health > 0 then
			root.CFrame = cf * FOLLOW_OFFSET
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end)
end

function setFollowUI()
	if not (ui and ui.autoBtn) then return end
	ui.autoBtn.Text = followOn and "Bám theo: BẬT" or "Bám theo: TẮT"
	ui.autoBtn.BackgroundColor3 = followOn and ON or OFF
end

function toggleFollow()
	if followOn then
		stopFollow()
	elseif selectedPlayer then
		followOn = true
		startFollow()
	end
	setFollowUI()
end

-- ===== Auto hồi sinh: tự tìm & bấm nút RESPAWN của game =====
local function isShown(obj)
	local cur = obj
	while cur and cur ~= game do
		if cur:IsA("GuiObject") and not cur.Visible then return false end
		if cur:IsA("ScreenGui") and not cur.Enabled then return false end
		cur = cur.Parent
	end
	return true
end

-- Nhận cả tiếng Anh ("RESPAWN") lẫn tiếng Việt ("Hồi sinh" / "HỒI SINH")
local function isRespawnText(text)
	local t = string.lower(text):gsub("%s", "")
	if t == "respawn" then return true end
	return #t <= 16 and t:sub(1, 1) == "h" and t:sub(-4) == "sinh"
end

local function findRespawnButton()
	if cachedRespawn and cachedRespawn.Parent and isShown(cachedRespawn) then
		return cachedRespawn
	end
	cachedRespawn = nil
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then return nil end
	for _, o in ipairs(pg:GetDescendants()) do
		if o:IsA("TextButton") or o:IsA("TextLabel") then
			if isRespawnText(o.Text) and isShown(o) then
				local target, cur = o, o
				while cur and cur ~= pg do
					if cur:IsA("GuiButton") then target = cur; break end
					cur = cur.Parent
				end
				cachedRespawn = target
				return target
			end
		end
	end
	return nil
end

local function vimClick(obj)
	if not VIM then return end
	local sg = obj:FindFirstAncestorOfClass("ScreenGui")
	local inset = (sg and sg.IgnoreGuiInset) and Vector2.zero or GuiService:GetGuiInset()
	local pos = obj.AbsolutePosition + obj.AbsoluteSize / 2 + inset
	pcall(function()
		VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
		task.wait(0.05)
		VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
	end)
end

local function pressButton(btn)
	if btn:IsA("GuiButton") then
		local sigs = { "Activated", "MouseButton1Down", "MouseButton1Up", "MouseButton1Click" }
		for _, name in ipairs(sigs) do
			if firesignal then
				pcall(function() firesignal(btn[name]) end)
			elseif getconnections then
				pcall(function()
					for _, c in ipairs(getconnections(btn[name])) do c:Fire() end
				end)
			end
		end
	end
	vimClick(btn)
end

function setRespawnUI()
	if not (ui and ui.respawnBtn) then return end
	ui.respawnBtn.Text = respawnOn and "Auto hồi sinh: BẬT" or "Auto hồi sinh: TẮT"
	ui.respawnBtn.BackgroundColor3 = respawnOn and ON or OFF
end

function toggleRespawn()
	respawnOn = not respawnOn
	setRespawnUI()
end

function setVisible(v)
	uiVisible = v
	if not ui then return end
	ui.frame.Visible = v
	ui.modal.Modal = v -- Modal = true giúp con trỏ không bị game khoá, luôn bấm được nút
end

function rebuildList()
	if not (ui and ui.list and ui.list.Parent) then return end
	for _, r in ipairs(ui.rows) do r:Destroy() end
	ui.rows = {}
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
				}, ui.list)
				round(btn, 6)
				btn.Activated:Connect(function()
					selectedPlayer = plr
					teleportToPlayer(plr)
					rebuildList()
				end)
				table.insert(ui.rows, btn)
			end
		end
	end
end

function buildUI()
	local parent = getParent()
	local old = parent:FindFirstChild("TeleportExecUI")
	if old then pcall(function() old:Destroy() end) end

	local gui = make("ScreenGui", {
		Name = "TeleportExecUI", ResetOnSpawn = false, DisplayOrder = 999999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
	}, parent)

	local toggleBtn = make("TextButton", {
		Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0, 12, 0.5, -22),
		BackgroundColor3 = ACCENT, Text = "📍", TextSize = 22,
	}, gui)
	round(toggleBtn, 22)

	local frame = make("Frame", {
		Size = UDim2.fromOffset(260, 390), Position = UDim2.new(0, 64, 0.5, -195),
		BackgroundColor3 = BG, Visible = uiVisible, Active = true, Draggable = true,
	}, gui)
	round(frame, 12)

	make("TextLabel", {
		Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1, Text = "Teleport tới người chơi", Font = Enum.Font.GothamBold,
		TextSize = 16, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left,
	}, frame)

	local searchBox = make("TextBox", {
		Size = UDim2.new(1, -16, 0, 32), Position = UDim2.fromOffset(8, 40),
		BackgroundColor3 = PANEL, Text = filterText, PlaceholderText = "Tìm tên người chơi...",
		Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = WHITE,
		PlaceholderColor3 = Color3.fromRGB(150, 150, 160), ClearTextOnFocus = false,
	}, frame)
	round(searchBox, 8)

	local list = make("ScrollingFrame", {
		Size = UDim2.new(1, -16, 1, -184), Position = UDim2.fromOffset(8, 80),
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

	local respawnBtn = make("TextButton", {
		Size = UDim2.new(1, -16, 0, 40), Position = UDim2.new(0, 8, 1, -92),
		BackgroundColor3 = OFF, Text = "Auto hồi sinh: TẮT",
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = WHITE,
	}, frame)
	round(respawnBtn, 8)

	-- Nút ẩn dùng để bật Modal (mở khoá con trỏ chuột khi bảng đang hiện)
	local modal = make("TextButton", {
		Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "",
		Modal = uiVisible,
	}, frame)

	ui = { gui = gui, frame = frame, list = list, autoBtn = autoBtn, respawnBtn = respawnBtn, modal = modal, rows = {} }

	toggleBtn.Activated:Connect(function() setVisible(not uiVisible) end)
	autoBtn.Activated:Connect(toggleFollow)
	respawnBtn.Activated:Connect(toggleRespawn)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		filterText = searchBox.Text
		rebuildList()
	end)

	rebuildList()
	setFollowUI()
	setRespawnUI()
end

-- ===== Sự kiện =====
Players.PlayerAdded:Connect(function() rebuildList() end)
Players.PlayerRemoving:Connect(function(plr)
	if selectedPlayer == plr then
		selectedPlayer = nil
		stopFollow()
		setFollowUI()
	end
	task.defer(rebuildList)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == TOGGLE_UI_KEY then
		setVisible(not uiVisible)
	elseif input.KeyCode == FOLLOW_KEY then
		toggleFollow()
	elseif input.KeyCode == RESPAWN_KEY then
		toggleRespawn()
	end
end)

buildUI()

-- Vòng auto hồi sinh: thấy nút RESPAWN đang hiện thì tự bấm
task.spawn(function()
	while true do
		task.wait(0.7)
		if respawnOn then
			local ok, btn = pcall(findRespawnButton)
			if ok and btn then
				pressButton(btn)
				task.wait(1.5) -- chờ game hồi sinh rồi mới kiểm tra tiếp
			end
		end
	end
end)

-- Giữ UI luôn sống: nếu game xoá/tắt UI khi chết hoặc hồi sinh thì tự dựng lại
task.spawn(function()
	while true do
		task.wait(0.5)
		local ok = pcall(function()
			if not (ui and ui.gui and ui.gui.Parent) then error("gone") end
			ui.gui.Enabled = true
			ui.gui.DisplayOrder = 999999
		end)
		if not ok then pcall(buildUI) end
	end
end)
