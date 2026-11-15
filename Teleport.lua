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
local WALK_KEY = Enum.KeyCode.B                    -- phím bật/tắt chế độ đi bộ tới người chơi (PC)
local WALK_STOP_DIST = 4                           -- dừng lại khi cách người chơi chừng này stud
local DEFAULT_SPEED = 0                            -- tốc độ chạy (WalkSpeed). 0 = giữ mặc định của game
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

-- Gắn hành động cho nút: nhận chạm/click ổn định trên điện thoại (nhả tay trong ~15px là tính 1 lần bấm)
local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
end
local function tap(btn, fn)
	local last, downPos = 0, nil
	local function fire()
		if os.clock() - last < 0.3 then return end -- tránh chạy 2 lần (Activated + InputEnded)
		last = os.clock()
		fn()
	end
	btn.InputBegan:Connect(function(input)
		if isPointer(input) then downPos = input.Position end
	end)
	btn.InputEnded:Connect(function(input)
		if isPointer(input) and downPos then
			local moved = (input.Position - downPos).Magnitude
			downPos = nil
			if moved < 15 then fire() end
		end
	end)
	btn.Activated:Connect(fire)
end

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
local walkMode = false      -- chế độ: chọn người chơi thì đi bộ tới (thay vì teleport tức thì)
local walking = false       -- đang đi bộ
local walkToken = 0         -- đổi số này để dừng vòng đi bộ cũ
local customSpeed = DEFAULT_SPEED -- tốc độ chạy hiện tại (chỉnh được trên bảng, 0 = mặc định)
local mapIdx = 0            -- 0 = mặc định (bấm nút RESPAWN), 1.. = chọn map trong MAPS
local respawnMap = nil      -- tên map đã chọn để hồi sinh (hiện trên nút)
local respawnNames = nil    -- tập các tên (đã chuẩn hoá) để nhận diện map trên màn hình game
local noclipChanged = {}    -- các part do script này tắt va chạm (để trả lại khi tắt noclip)

local dragConn = nil         -- kết nối kéo bảng (huỷ khi dựng lại UI)
local savedFramePos = nil   -- nhớ vị trí bảng khi bị kéo, để UI dựng lại vẫn giữ chỗ cũ
local rebuildList, setFollowUI, setVisible, toggleFollow, buildUI
local setRespawnUI, toggleRespawn
local setNoclipUI, toggleNoclip, setWalkUI, toggleWalkMode, stopWalk, startWalk
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

-- ===== Noclip (tắt va chạm; tự bật trong lúc đang đi bộ tới người chơi) =====
RunService.Stepped:Connect(function()
	local char = player.Character
	if not char then return end
	if noclipOn or walking then
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

-- ===== Tốc độ chạy (WalkSpeed) =====
RunService.Heartbeat:Connect(function()
	if customSpeed > 0 then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.WalkSpeed ~= customSpeed then hum.WalkSpeed = customSpeed end
	end
end)

-- ===== Đi bộ tới người chơi (dùng Pathfinding, tự nhảy khi bị kẹt) =====
function stopWalk()
	walking = false
	walkToken = walkToken + 1
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if root and hum then pcall(function() hum:MoveTo(root.Position) end) end
end

function startWalk()
	if followOn then return end -- đang bám theo thì không cần đi bộ
	walkToken = walkToken + 1
	local token = walkToken
	walking = true -- walking = true => tự bật noclip nên đi thẳng, không bị vật cản làm khựng
	task.spawn(function()
		local lastPos, stuckT = nil, 0
		while walking and walkToken == token do
			if not (selectedPlayer and selectedPlayer.Parent == Players) then break end
			local tcf = playerCF(selectedPlayer)
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if tcf and root and hum and hum.Health > 0 then
				local flat = Vector3.new(tcf.Position.X - root.Position.X, 0, tcf.Position.Z - root.Position.Z)
				if flat.Magnitude <= WALK_STOP_DIST then break end -- tới nơi
				hum:MoveTo(tcf.Position)
				-- dưới nước thì nhảy liên tục để bơi lên / trèo lên bờ
				if hum:GetState() == Enum.HumanoidStateType.Swimming then hum.Jump = true end
				-- kẹt (gần như không nhúc nhích) thì nhảy
				if lastPos and (root.Position - lastPos).Magnitude < 0.2 then stuckT = stuckT + 0.1 else stuckT = 0 end
				lastPos = root.Position
				if stuckT > 0.5 then hum.Jump = true end
			end
			task.wait(0.1) -- đang chết/hồi sinh thì chờ rồi đi tiếp
		end
		if walkToken == token then stopWalk() end
	end)
end

function setWalkUI()
	if not (ui and ui.walkBtn) then return end
	ui.walkBtn.Text = walkMode and "Đi bộ tới người: BẬT" or "Đi bộ tới người: TẮT"
	ui.walkBtn.BackgroundColor3 = walkMode and ON or OFF
end

function toggleWalkMode()
	walkMode = not walkMode
	if not walkMode then stopWalk() end
	setWalkUI()
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
		stopWalk()
		followOn = true
		startFollow()
	end
	setFollowUI()
end

-- ===== Auto hồi sinh: tự tìm & bấm nút RESPAWN của game =====
local function onScreen(o)
	if not o:IsA("GuiObject") then return true end
	if o.AbsoluteSize.X <= 0 or o.AbsoluteSize.Y <= 0 then return false end
	local cam = workspace.CurrentCamera
	if not cam then return true end
	local vp = cam.ViewportSize
	local sg = o:FindFirstAncestorOfClass("ScreenGui")
	local inset = (sg and sg.IgnoreGuiInset) and Vector2.zero or GuiService:GetGuiInset()
	local c = o.AbsolutePosition + o.AbsoluteSize / 2 + inset
	return c.X >= 0 and c.Y >= 0 and c.X <= vp.X and c.Y <= vp.Y
end

local function isShown(obj)
	if not onScreen(obj) then return false end
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

-- ===== Hồi sinh theo map: MENU -> Chơi/Play -> chọn map -> Hồi sinh/SPAWN =====
-- Chuẩn hoá chữ: bỏ thẻ RichText, bỏ khoảng trắng, hạ chữ thường
local function norm(t) return (string.lower(t):gsub("<[^>]*>", ""):gsub("%s", "")) end

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

local function matchesMap(t, names)
	if names[t] then return true end
	if #t > 30 then return false end
	for n in pairs(names) do
		if #n >= 4 and t:find(n, 1, true) then return true end
	end
	return false
end

local function consider(r, o, pg, names, key)
	if matchesMap(key, names) then
		local c = clickableOf(o, pg)
		local isBtn = c:IsA("GuiButton")
		local area = o.AbsoluteSize.X * o.AbsoluteSize.Y
		-- ưu tiên nút bấm được; nếu cùng loại thì lấy chữ nhỏ hơn (dòng trong danh sách, không phải tiêu đề to bên phải)
		if not r.map or (isBtn and not r.mapBtn) or (isBtn == (r.mapBtn or false) and area < (r.mapArea or math.huge)) then
			r.map, r.mapBtn, r.mapArea = c, isBtn, area
		end
	elseif key == "menu" then
		r.menu = r.menu or clickableOf(o, pg)
	elseif isPlayText(key) then
		r.play = r.play or clickableOf(o, pg)
	elseif isRespawnText(key) then
		if key == "respawn" then
			r.death = r.death or clickableOf(o, pg)     -- nút RESPAWN ở màn hình DEFEATED
		else
			r.respawn = r.respawn or clickableOf(o, pg) -- nút SPAWN ở màn hình Locations
		end
	end
end

-- Quét các màn hình của game (theo chữ hiển thị VÀ theo tên đối tượng), trả về nút: map / play / menu / respawn
local function scanScreens(names)
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then return nil end
	local r = {}
	for _, o in ipairs(pg:GetDescendants()) do
		if o:IsA("GuiObject") and not (ui and ui.gui and o:IsDescendantOf(ui.gui)) then
			if (o:IsA("TextButton") or o:IsA("TextLabel")) and o.Text ~= "" and isShown(o) then
				consider(r, o, pg, names, norm(o.Text))
			end
			local nk = norm(o.Name)
			if o:IsA("GuiButton") then
				if (matchesMap(nk, names) or nk == "menu" or nk == "play" or nk == "spawn" or nk == "respawn") and isShown(o) then
					consider(r, o, pg, names, nk)
				end
			elseif names[nk] and o.AbsoluteSize.X > 0 and isShown(o) then
				r.map = r.map or o
			end
		end
	end
	return r
end

local function setStatus(txt)
	if not (ui and ui.title and ui.title.Parent) then return end
	ui.title.Text = txt or "Teleport tới người chơi"
	ui.title.TextSize = txt and 11 or 16
end

local function centerOf(obj)
	local sg = obj:FindFirstAncestorOfClass("ScreenGui")
	local inset = (sg and sg.IgnoreGuiInset) and Vector2.zero or GuiService:GetGuiInset()
	return obj.AbsolutePosition + obj.AbsoluteSize / 2 + inset
end

local function vimTap(obj)
	if not VIM then return end
	local pos = centerOf(obj)
	pcall(function()
		VIM:SendTouchEvent(1, 0, pos.X, pos.Y)
		task.wait(0.05)
		VIM:SendTouchEvent(1, 2, pos.X, pos.Y)
	end)
end

local tries = {}
-- Thử lần lượt: bắn signal -> chạm màn hình ảo -> click chuột ảo.
-- Nút biến mất / màn hình đổi nghĩa là đã bấm được => dừng ngay (không phải bấm 2-3 vòng mới ăn).
local function press(name, btn)
	local methods = {}
	if btn:IsA("GuiButton") and (firesignal or getconnections) then table.insert(methods, fireSignals) end
	table.insert(methods, vimTap)
	table.insert(methods, vimClick)
	for _, m in ipairs(methods) do
		pcall(m, btn)
		task.wait(0.12)
		if not (btn.Parent and isShown(btn)) then return end
	end
end

local function mapRespawnStep()
	local ok, r = pcall(scanScreens, respawnNames)
	if not (ok and r) then return end
	local function yn(v) return v and "Y" or "N" end
	local flags = "map=" .. yn(r.map) .. " spawn=" .. yn(r.respawn) .. " dead=" .. yn(r.death) .. " play=" .. yn(r.play) .. " menu=" .. yn(r.menu)
	if r.map and r.respawn then
		setStatus("Chọn map: " .. flags)
		press("map", r.map)
		task.wait(0.1)
		press("respawn", r.respawn)
		task.wait(0.9)
	elseif r.play then
		setStatus("Bấm Play: " .. flags)
		press("play", r.play)
		task.wait(0.4)
	elseif r.menu and (r.death or r.respawn) then
		setStatus("Bấm MENU: " .. flags)
		press("menu", r.menu)
		task.wait(0.4)
	else
		setStatus("Đang chờ: " .. flags)
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
					Size = UDim2.new(1, 0, 0, 38),
					BackgroundColor3 = (selectedPlayer == plr) and ACCENT or BG,
					Text = label, Font = Enum.Font.Gotham, TextSize = 13,
					TextColor3 = WHITE, TextTruncate = Enum.TextTruncate.AtEnd,
				}, ui.list)
				round(btn, 6)
				tap(btn, function()
					selectedPlayer = plr
					if walkMode and not followOn then
						startWalk()
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

	-- Kích thước bảng tự co theo màn hình (điện thoại nằm ngang ~ 390px cao)
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 400)
	local W = math.clamp(math.floor(vp.X * 0.85), 300, 480)
	local H = math.clamp(math.floor(vp.Y * 0.85), 220, 320)

	local gui = make("ScreenGui", {
		Name = "TeleportExecUI", ResetOnSpawn = false, DisplayOrder = 999999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
	}, parent)

	local toggleBtn = make("TextButton", {
		Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 10, 0.5, -23),
		BackgroundColor3 = ACCENT, Text = "📍", TextSize = 22,
	}, gui)
	round(toggleBtn, 23)

	local frame = make("Frame", {
		Size = UDim2.fromOffset(W, H),
		Position = savedFramePos or UDim2.new(0, math.clamp(64, 0, math.max(0, vp.X - W)), 0.5, -math.floor(H / 2)),
		BackgroundColor3 = BG, Visible = uiVisible, Active = true,
	}, gui)
	round(frame, 12)

	-- Thanh tiêu đề: kéo để di chuyển bảng, nút ✕ để đóng
	local titleBar = make("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Active = true }, frame)
	local titleLbl = make("TextLabel", {
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -56, 1, 0), Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1, Text = "Teleport tới người chơi", Font = Enum.Font.GothamBold,
		TextSize = 16, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left,
	}, titleBar)
	local closeBtn = make("TextButton", {
		Size = UDim2.fromOffset(34, 28), Position = UDim2.new(1, -40, 0, 5),
		BackgroundColor3 = OFF, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = WHITE,
	}, titleBar)
	round(closeBtn, 6)

	-- Cột trái: tìm kiếm + danh sách người chơi
	local searchBox = make("TextBox", {
		Size = UDim2.new(0.42, -12, 0, 34), Position = UDim2.fromOffset(8, 40),
		BackgroundColor3 = PANEL, Text = filterText, PlaceholderText = "Tìm tên...",
		Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = WHITE,
		PlaceholderColor3 = Color3.fromRGB(150, 150, 160), ClearTextOnFocus = false,
	}, frame)
	round(searchBox, 8)

	local list = make("ScrollingFrame", {
		Size = UDim2.new(0.42, -12, 1, -86), Position = UDim2.fromOffset(8, 78),
		BackgroundColor3 = PANEL, BorderSizePixel = 0, ScrollBarThickness = 4,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, frame)
	round(list, 8)
	make("UIListLayout", { Padding = UDim.new(0, 4) }, list)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
	}, list)

	-- Cột phải: các nút điều khiển (cuộn được, nút to dễ chạm)
	local ctrl = make("Frame", {
		Size = UDim2.new(0.58, -10, 1, -48), Position = UDim2.new(0.42, 2, 0, 40),
		BackgroundTransparency = 1, BorderSizePixel = 0,
	}, frame)
	make("UIGridLayout", {
		CellSize = UDim2.new(0.5, -3, 0, 38), CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, ctrl)

	local function mkBtn(text, order, color)
		local b = make("TextButton", {
			Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = color or OFF, Text = text,
			Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = WHITE,
			TextScaled = true, LayoutOrder = order,
		}, ctrl)
		round(b, 8)
		make("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 9 }, b)
		make("UIPadding", {
			PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
		}, b)
		return b
	end

	local autoBtn = mkBtn("Bám theo: TẮT", 1)
	local walkBtn = mkBtn("Đi bộ tới người: TẮT", 2)
	local respawnBtn = mkBtn("Auto hồi sinh: TẮT", 4)
	local mapBtn = mkBtn("Map hồi sinh: Mặc định", 5, PANEL)
	local noclipBtn = mkBtn("Noclip: TẮT", 6)

	local speedBox = make("TextBox", {
		LayoutOrder = 7,
		BackgroundColor3 = PANEL, Text = customSpeed > 0 and tostring(customSpeed) or "",
		PlaceholderText = "Tốc độ (trống = mặc định)",
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = WHITE, TextScaled = true,
		PlaceholderColor3 = Color3.fromRGB(150, 150, 160), ClearTextOnFocus = false,
	}, ctrl)
	round(speedBox, 8)
	make("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 9 }, speedBox)
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
	}, speedBox)

	-- Nút ẩn dùng để bật Modal (mở khoá con trỏ chuột khi bảng đang hiện)
	local modal = make("TextButton", {
		Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "",
		Modal = uiVisible,
	}, frame)

	ui = { gui = gui, frame = frame, list = list, autoBtn = autoBtn, respawnBtn = respawnBtn,
		noclipBtn = noclipBtn, walkBtn = walkBtn, mapBtn = mapBtn,
		title = titleLbl, modal = modal, rows = {} }

	-- Kéo bảng bằng thanh tiêu đề (chuột hoặc cảm ứng)
	if dragConn then dragConn:Disconnect(); dragConn = nil end
	local dragging, dragStart, startPos = false, nil, nil
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, input.Position, frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	dragConn = UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			local pos = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			frame.Position = pos
			savedFramePos = pos
		end
	end)

	tap(toggleBtn, function() setVisible(not uiVisible) end)
	tap(closeBtn, function() setVisible(false) end)
	tap(autoBtn, toggleFollow)
	tap(respawnBtn, toggleRespawn)
	tap(noclipBtn, toggleNoclip)
	tap(walkBtn, toggleWalkMode)
	tap(mapBtn, cycleMap)
	speedBox.FocusLost:Connect(function()
		local n = tonumber(speedBox.Text)
		if n and n > 0 then
			customSpeed = math.clamp(n, 1, 500)
		elseif speedBox.Text == "" or n == 0 then
			if customSpeed > 0 then -- tắt speed: trả về tốc độ mặc định
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if hum then hum.WalkSpeed = 16 end
			end
			customSpeed = 0
		end
		speedBox.Text = customSpeed > 0 and tostring(customSpeed) or ""
	end)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		filterText = searchBox.Text
		rebuildList()
	end)

	rebuildList()
	setFollowUI()
	setRespawnUI()
	setNoclipUI()
	setWalkUI()
	setMapUI()
end

-- ===== Sự kiện =====
Players.PlayerAdded:Connect(function() rebuildList() end)
Players.PlayerRemoving:Connect(function(plr)
	if selectedPlayer == plr then
		selectedPlayer = nil
		stopWalk()
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
	elseif input.KeyCode == WALK_KEY then
		toggleWalkMode()
	end
end)

buildUI()

-- Vòng auto hồi sinh: thấy nút RESPAWN đang hiện thì tự bấm
task.spawn(function()
	while true do
		task.wait(0.25)
		if respawnOn then
			if respawnNames then
				pcall(mapRespawnStep)
			else
				local ok, btn = pcall(findRespawnButton)
				if ok and btn then
					press("default", btn)
					task.wait(0.8) -- chờ game hồi sinh rồi mới kiểm tra tiếp
				end
			end
		end
		if not (respawnOn and respawnNames) then pcall(setStatus, nil) end
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
