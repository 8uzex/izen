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
local NOCLIP_KEY = Enum.KeyCode.N                  -- phím bật/tắt noclip (PC)
local FLY_KEY = Enum.KeyCode.B                     -- phím bật/tắt chế độ tự bay tới người chơi (PC)
local FLY_SPEED = 120                              -- tốc độ bay (stud/giây)
-- Danh sách map ở màn hình LOCATIONS / Địa điểm. Mỗi map có tên tiếng Anh + tiếng Việt (không phân biệt hoa/thường).
-- Phần tử đầu tiên là tên hiện trên nút của bảng.
local MAPS = {
	{ "New York" },
	{ "Atlas" },
	{ "Pirate Island", "Hòn đảo cướp biển" },
	{ "Prometia" },
	{ "Tokyo" },
	{ "Costa Sierpe" },
	{ "Arctic", "Vùng Bắc Cực" },
}
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
local noclipOn = false      -- noclip bật thủ công
local flyMode = false       -- chế độ: chọn người chơi thì tự bay tới (thay vì teleport tức thì)
local flying = false        -- đang bay (tự bật noclip trong lúc bay)
local flyConn = nil
local flySpeed = FLY_SPEED  -- tốc độ bay hiện tại (chỉnh được trên bảng)
local mapIdx = 0            -- 0 = mặc định (bấm nút RESPAWN), 1.. = chọn map trong MAPS
local respawnMap = nil      -- tên map đã chọn để hồi sinh (hiện trên nút)
local respawnNames = nil    -- tập các tên (đã chuẩn hoá) để nhận diện map trên màn hình game
local noclipChanged = {}    -- các part do script này tắt va chạm (để trả lại khi tắt noclip)

local rebuildList, setFollowUI, setVisible, toggleFollow, buildUI
local setRespawnUI, toggleRespawn
local setNoclipUI, toggleNoclip, setFlyUI, toggleFlyMode, stopFly, startFly
local setMapUI, cycleMap

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

-- ===== Noclip (tắt va chạm; tự bật khi đang bay) =====
RunService.Stepped:Connect(function()
	local char = player.Character
	if not char then return end
	if noclipOn or flying then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then
				p.CanCollide = false
				noclipChanged[p] = true
			end
		end
	elseif next(noclipChanged) then
		for p in pairs(noclipChanged) do
			if p.Parent then p.CanCollide = true end
		end
		noclipChanged = {}
	end
end)

function setNoclipUI()
	if not (ui and ui.noclipBtn) then return end
	ui.noclipBtn.Text = noclipOn and "Noclip: BẬT" or "Noclip: TẮT"
	ui.noclipBtn.BackgroundColor3 = noclipOn and ON or OFF
end

function toggleNoclip()
	noclipOn = not noclipOn
	setNoclipUI()
end

-- ===== Tự bay tới người chơi (xuyên vật cản nhờ noclip) =====
function stopFly()
	flying = false
	if flyConn then flyConn:Disconnect(); flyConn = nil end
end

function startFly()
	if followOn then return end -- đang bám theo thì không cần bay
	if flyConn then flyConn:Disconnect() end
	flying = true
	flyConn = RunService.Heartbeat:Connect(function(dt)
		local cf = playerCF(selectedPlayer)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (selectedPlayer and selectedPlayer.Parent == Players) then stopFly() return end
		if not (cf and root and hum) then return end -- đang chết/hồi sinh: chờ rồi bay tiếp
		if hum.Health <= 0 then return end
		local goal = (cf * FOLLOW_OFFSET).Position
		local delta = goal - root.Position
		local step = flySpeed * dt
		if delta.Magnitude <= step + 0.5 then
			root.CFrame = cf * FOLLOW_OFFSET
			root.AssemblyLinearVelocity = Vector3.zero
			stopFly()
		else
			root.CFrame = root.CFrame.Rotation + (root.Position + delta.Unit * step)
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end)
end

function setFlyUI()
	if not (ui and ui.flyBtn) then return end
	ui.flyBtn.Text = flyMode and "Tự bay tới người: BẬT" or "Tự bay tới người: TẮT"
	ui.flyBtn.BackgroundColor3 = flyMode and ON or OFF
end

function toggleFlyMode()
	flyMode = not flyMode
	if not flyMode then stopFly() end
	setFlyUI()
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
		stopFly()
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
	if t == "respawn" or t == "spawn" then return true end
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

local function fireSignals(btn)
	if not btn:IsA("GuiButton") then return end
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

local function pressButton(btn)
	fireSignals(btn)
	vimClick(btn)
end

-- ===== Hồi sinh theo map: MENU -> Chơi -> chọn map -> Hồi sinh =====
local function norm(t) return (string.lower(t):gsub("%s", "")) end

local function clickableOf(o, pg)
	local cur = o
	while cur and cur ~= pg do
		if cur:IsA("GuiButton") then return cur end
		cur = cur.Parent
	end
	return o
end

local function isPlayText(t)
	if t == "play" or t == "chơi" then return true end
	return #t >= 5 and #t <= 7 and t:sub(1, 2) == "ch" and t:sub(-1) == "i"
end

-- Quét các màn hình của game, trả về nút đang hiện: map / play / menu / respawn
local function scanScreens(names)
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then return nil end
	local r = {}
	for _, o in ipairs(pg:GetDescendants()) do
		if (o:IsA("TextButton") or o:IsA("TextLabel")) and o.Text ~= ""
			and not (ui and ui.gui and o:IsDescendantOf(ui.gui)) and isShown(o) then
			local t = norm(o.Text)
			if names[t] then
				if not r.map or (o:IsA("GuiButton") and not r.map:IsA("GuiButton")) then r.map = clickableOf(o, pg) end
			elseif t == "menu" then
				r.menu = r.menu or clickableOf(o, pg)
			elseif isPlayText(t) then
				r.play = r.play or clickableOf(o, pg)
			elseif isRespawnText(o.Text) then
				r.respawn = r.respawn or clickableOf(o, pg)
			end
		end
	end
	return r
end

local tries = {}
local function press(name, btn)
	tries[name] = (tries[name] or 0) + 1
	-- lần lẻ: bắn signal (nếu executor hỗ trợ); lần chẵn: click chuột ảo
	if tries[name] % 2 == 1 and btn:IsA("GuiButton") and (firesignal or getconnections) then
		fireSignals(btn)
	else
		vimClick(btn)
	end
end

local function mapRespawnStep()
	local ok, r = pcall(scanScreens, respawnNames)
	if not (ok and r) then return end
	if r.map and r.respawn then
		-- màn hình "Địa điểm": chọn map rồi bấm Hồi sinh
		press("map", r.map)
		task.wait(0.6)
		press("respawn", r.respawn)
		task.wait(2)
	elseif r.play then
		press("play", r.play) -- màn hình chính: bấm Chơi
		task.wait(1.5)
	elseif r.menu and r.respawn then
		press("menu", r.menu) -- màn hình DEFEATED: bấm MENU
		task.wait(1.5)
	else
		tries = {}
	end
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

function setMapUI()
	if not (ui and ui.mapBtn) then return end
	ui.mapBtn.Text = respawnMap and ("Map hồi sinh: " .. respawnMap) or "Map hồi sinh: Mặc định"
	ui.mapBtn.BackgroundColor3 = respawnMap and ACCENT or PANEL
end

function cycleMap()
	mapIdx = (mapIdx + 1) % (#MAPS + 1)
	respawnMap, respawnNames = nil, nil
	if mapIdx > 0 then
		respawnMap = MAPS[mapIdx][1]
		respawnNames = {}
		for _, n in ipairs(MAPS[mapIdx]) do respawnNames[norm(n)] = true end
	end
	tries = {}
	setMapUI()
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
					if flyMode and not followOn then
						startFly()
					else
						teleportToPlayer(plr)
					end
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
		Size = UDim2.fromOffset(260, 566), Position = UDim2.new(0, 64, 0.5, -283),
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
		Size = UDim2.new(1, -16, 1, -360), Position = UDim2.fromOffset(8, 80),
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

	local noclipBtn = make("TextButton", {
		Size = UDim2.new(1, -16, 0, 40), Position = UDim2.new(0, 8, 1, -136),
		BackgroundColor3 = OFF, Text = "Noclip: TẮT",
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = WHITE,
	}, frame)
	round(noclipBtn, 8)

	local flyBtn = make("TextButton", {
		Size = UDim2.new(1, -16, 0, 40), Position = UDim2.new(0, 8, 1, -180),
		BackgroundColor3 = OFF, Text = "Tự bay tới người: TẮT",
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = WHITE,
	}, frame)
	round(flyBtn, 8)

	local speedBox = make("TextBox", {
		Size = UDim2.new(1, -16, 0, 36), Position = UDim2.new(0, 8, 1, -224),
		BackgroundColor3 = PANEL, Text = tostring(flySpeed), PlaceholderText = "Tốc độ bay (1-1000)",
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = WHITE,
		PlaceholderColor3 = Color3.fromRGB(150, 150, 160), ClearTextOnFocus = false,
	}, frame)
	round(speedBox, 8)
	make("TextLabel", {
		Size = UDim2.new(0, 90, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1,
		Text = "Tốc độ:", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.fromRGB(170, 170, 180),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, speedBox)
	speedBox.TextXAlignment = Enum.TextXAlignment.Right

	local mapBtn = make("TextButton", {
		Size = UDim2.new(1, -16, 0, 36), Position = UDim2.new(0, 8, 1, -268),
		BackgroundColor3 = PANEL, Text = "Map hồi sinh: Mặc định",
		Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = WHITE, TextTruncate = Enum.TextTruncate.AtEnd,
	}, frame)
	round(mapBtn, 8)

	-- Nút ẩn dùng để bật Modal (mở khoá con trỏ chuột khi bảng đang hiện)
	local modal = make("TextButton", {
		Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "",
		Modal = uiVisible,
	}, frame)

	ui = { gui = gui, frame = frame, list = list, autoBtn = autoBtn, respawnBtn = respawnBtn,
		noclipBtn = noclipBtn, flyBtn = flyBtn, mapBtn = mapBtn, modal = modal, rows = {} }

	toggleBtn.Activated:Connect(function() setVisible(not uiVisible) end)
	autoBtn.Activated:Connect(toggleFollow)
	respawnBtn.Activated:Connect(toggleRespawn)
	noclipBtn.Activated:Connect(toggleNoclip)
	flyBtn.Activated:Connect(toggleFlyMode)
	mapBtn.Activated:Connect(cycleMap)
	speedBox.FocusLost:Connect(function()
		local n = tonumber(speedBox.Text)
		if n then flySpeed = math.clamp(n, 1, 1000) end
		speedBox.Text = tostring(flySpeed)
	end)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		filterText = searchBox.Text
		rebuildList()
	end)

	rebuildList()
	setFollowUI()
	setRespawnUI()
	setNoclipUI()
	setFlyUI()
	setMapUI()
end

-- ===== Sự kiện =====
Players.PlayerAdded:Connect(function() rebuildList() end)
Players.PlayerRemoving:Connect(function(plr)
	if selectedPlayer == plr then
		selectedPlayer = nil
		stopFly()
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
	elseif input.KeyCode == NOCLIP_KEY then
		toggleNoclip()
	elseif input.KeyCode == FLY_KEY then
		toggleFlyMode()
	end
end)

buildUI()

-- Vòng auto hồi sinh: thấy nút RESPAWN đang hiện thì tự bấm
task.spawn(function()
	while true do
		task.wait(0.7)
		if respawnOn then
			if respawnNames then
				mapRespawnStep()
			else
				local ok, btn = pcall(findRespawnButton)
				if ok and btn then
					pressButton(btn)
					task.wait(1.5) -- chờ game hồi sinh rồi mới kiểm tra tiếp
				end
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
