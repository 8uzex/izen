-- Teleport tới người chơi + bám theo (1 file, chạy bằng executor, chỉ chạy phía client)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local player = Players.LocalPlayer

-- ===== CẤU HÌNH =====
local FOLLOW_OFFSET = CFrame.new(0, 0, 3)          -- vị trí so với người được bám (đứng sau lưng 3 stud)
local TOGGLE_UI_KEY = Enum.KeyCode.RightShift      -- phím ẩn/hiện bảng (PC)
local FOLLOW_KEY = Enum.KeyCode.K                  -- phím bật/tắt bám theo (PC)
local RESPAWN_KEY = Enum.KeyCode.J                 -- phím bật/tắt auto hồi sinh (PC)
local NOCLIP_KEY = Enum.KeyCode.N                  -- phím bật/tắt noclip (PC)
local TWEEN_KEY = Enum.KeyCode.T                  -- phím bật/tắt chế độ tween tới người chơi (PC)
local WALK_KEY = Enum.KeyCode.B                    -- phím bật/tắt chế độ đi bộ tới người chơi (PC)
local SPAWNMAP_KEY = Enum.KeyCode.M                -- phím bật/tắt "spawn đúng map của người chơi đã chọn" (PC)
local ANTIAFK_KEY = Enum.KeyCode.U                -- phím bật/tắt anti AFK (PC)
local FLY_UP_SPEED = 30                            -- tốc độ bay (chậm) khi người chơi ở trên cao (stud/giây)
local FLY_START_HEIGHT = 6                         -- người chơi cao hơn mình chừng này stud thì bật bay
local TWEEN_TARGET_DISTANCE = 28                  -- Target Distance: khoảng cách giữ với người chơi (stud)
local TWEEN_SPEED = 150                          -- Tween Speed: tốc độ bay (stud/giây)
local TWEEN_ORBIT_SPEED = 1.799                  -- Orbit Speed: tốc độ quay quanh người chơi (rad/giây), 0 = đứng yên
local TWEEN_RETARGET_DELAY = 0.35                -- (không còn dùng: tween giờ tính lại điểm tới MỖI FRAME nên không bị giật)
local TWEEN_FAR_FACTOR = 1.5                       -- càng xa càng bay nhanh: tốc độ = khoảng cách x hệ số này (kẹp trong TWEEN_SPEED..TWEEN_MAX_SPEED)
local TWEEN_MAX_SPEED = 2000                       -- tốc độ bay tối đa khi ở rất xa (stud/giây)
local HOLD_RADIUS = 6                              -- người chơi bị unload (không thấy): tới gần chỗ đoán này thì đứng chờ game tải, không giật qua lại
local STALE_EXTRAPOLATE = 2                        -- khi mất dấu người chơi, đoán tiếp vị trí theo vận tốc cũ tối đa chừng này giây
local STALE_MAX_VEL = 120                          -- giới hạn vận tốc dùng để đoán (stud/giây)
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

local C = {
	bg = Color3.fromRGB(16, 18, 25),
	panel = Color3.fromRGB(24, 27, 37),
	row = Color3.fromRGB(30, 34, 46),
	rowHover = Color3.fromRGB(39, 44, 60),
	sel = Color3.fromRGB(44, 40, 84),
	stroke = Color3.fromRGB(48, 54, 72),
	accent = Color3.fromRGB(124, 92, 255),
	accent2 = Color3.fromRGB(56, 189, 248),
	off = Color3.fromRGB(62, 68, 90),
	danger = Color3.fromRGB(239, 84, 100),
	white = Color3.new(1, 1, 1),
	text = Color3.fromRGB(236, 239, 247),
	muted = Color3.fromRGB(139, 148, 170),
}

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

-- ===== Giao diện: bảng màu, hiệu ứng, logo =====
local function tw(o, t, props, style, dir)
	local ok, tween = pcall(function()
		return TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	end)
	if ok and tween then tween:Play() end
	return tween
end

-- Logo vẽ bằng code (không cần upload ảnh / asset id): ghim vị trí + vòng sóng dịch chuyển trên nền gradient tím-xanh
local function makeLogo(parent, s, props)
	local root = make("Frame", { Size = UDim2.fromOffset(s, s), BackgroundColor3 = C.accent, BorderSizePixel = 0 }, nil)
	for k, v in pairs(props or {}) do root[k] = v end
	root.Parent = parent
	round(root, s * 0.3)
	make("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2), Rotation = 45 }, root)

	local function ring(wf, tr)
		local w = s * wf
		local f = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(s * 0.5, s * 0.74),
			Size = UDim2.fromOffset(w, w * 0.36), BackgroundTransparency = 1, ZIndex = 1,
		}, root)
		make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
		make("UIStroke", { Color = C.white, Thickness = math.max(1, s * 0.035), Transparency = tr }, f)
	end
	ring(0.66, 0.55)
	ring(0.40, 0.2)

	local r, cy = s * 0.19, s * 0.37
	local h = r * 0.65
	local side = h * math.sqrt(2)
	local tail = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(s * 0.5, cy + r * 1.414 - h),
		Size = UDim2.fromOffset(side, side), Rotation = 45, BackgroundColor3 = C.white, BorderSizePixel = 0, ZIndex = 2,
	}, root)
	round(tail, math.max(1, s * 0.015))
	local head = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(s * 0.5, cy),
		Size = UDim2.fromOffset(r * 2, r * 2), BackgroundColor3 = C.white, BorderSizePixel = 0, ZIndex = 3,
	}, root)
	round(head, r)
	local hole = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(s * 0.5, cy),
		Size = UDim2.fromOffset(r * 0.84, r * 0.84), BackgroundColor3 = Color3.fromRGB(90, 140, 251), BorderSizePixel = 0, ZIndex = 4,
	}, root)
	round(hole, r)
	return root
end

local UI = { visToken = 0 }

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
local spawnAtPlayerMap = false -- hồi sinh thì tự chọn map mà người chơi đã chọn đang ở
local playerMapIdx = {}      -- [Player] = số thứ tự map (MAPS) nhận diện lần gần nhất
local playerMapExplicit = {} -- [Player] = true nếu map nhận diện từ thuộc tính/giá trị/thư mục (chắc chắn), false nếu đoán theo vị trí
local playerMapStable = {}   -- [Player] = số lần nhận diện liên tiếp ra cùng 1 map
local myMapIdx = nil         -- map mình đang ở (đọc từ chữ tên map trên HUD)
local lastSwitchT = -1000    -- lần cuối tự thoát/đổi map (chống đổi qua đổi lại)
local selectT = 0              -- lúc chọn người chơi gần nhất
local probeDone = {}           -- [Player] = true: đã vào màn Locations 1 lần để đọc map của người này
local probeActive, probeIdx, probeT = false, nil, 0 -- đang đi vòng qua Locations để đọc map (probeIdx = map mình vừa rời)
local exitPending = -1000    -- lần cuối script bấm nút thoát (chờ hộp thoại "Return to main menu?")
local antiAfkOn = true        -- chống bị kick vì đứng im (AFK) lâu
local tweenMode = false     -- chế độ: chọn người chơi thì tween (bay mượt) tới
local tweening = false
local tweenToken = 0
local tweenConn = nil
local walkMode = false      -- chế độ: chọn người chơi thì đi bộ tới (thay vì teleport tức thì)
local walking = false       -- đang đi bộ
local flyConn = nil           -- vòng bay lên (chỉ chạy khi đang đi bộ tới người ở trên cao)
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
local setTweenUI, toggleTweenMode, stopTween, startTween
local setStatus
local setMapUI, cycleMap
local setSpawnMapUI, toggleSpawnMap
local setAntiAfkUI, toggleAntiAfk

-- Người chơi ở xa có thể bị game "unload" (StreamingEnabled) nên không thấy nhân vật của họ.
-- Script nhớ vị trí cuối cùng thấy được, đi/teleport tới đó và xin game tải khu vực đó; thấy người rồi thì dùng vị trí thật.
local lastKnownCF = {}
local lastKnownVel = {}      -- [Player] = vận tốc lần cuối thấy (để đoán vị trí khi người chơi bị unload)
local lastKnownT = {}        -- [Player] = os.clock() lần cuối thấy thật
local lastKnownMap = {}      -- [Player] = map mình đang ở lúc thấy họ lần cuối (vị trí cuối còn hợp lệ nếu mình chưa đổi map)
local lastStream = 0
local function requestStream(pos)
	if os.clock() - lastStream < 0.6 then return end
	lastStream = os.clock()
	task.spawn(function() pcall(function() workspace:RequestStreamAroundAsync(pos, 1) end) end)
end

local function playerCF(plr)
	if not plr then return nil end
	local char = plr.Character
	local r = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
	if r then
		lastKnownCF[plr] = r.CFrame
		local v = r.AssemblyLinearVelocity
		if v.Magnitude > STALE_MAX_VEL then v = v.Unit * STALE_MAX_VEL end
		lastKnownVel[plr] = v
		lastKnownT[plr] = os.clock()
		lastKnownMap[plr] = myMapIdx
		return r.CFrame
	end
	return nil
end

-- người chơi đã chọn đang ở map khác với map của mình (nhận diện ổn định) -> không đi/tele/bám theo vị trí cũ
local function otherMap(plr)
	if not spawnAtPlayerMap then return false end
	local t = playerMapIdx[plr]
	if not (t ~= nil and myMapIdx ~= nil and t ~= myMapIdx and (playerMapStable[plr] or 0) >= 3) then return false end
	if not playerMapExplicit[plr] and lastKnownCF[plr] and lastKnownMap[plr] == myMapIdx then return false end
	return true
end

-- trả về (CFrame, đang_thấy_thật)
-- Khi người chơi ở quá xa bị game unload: KHÔNG quay về vị trí cũ nữa mà đoán tiếp vị trí theo vận tốc lần cuối thấy,
-- đồng thời xin game tải khu vực đó; thấy lại người rồi thì dùng vị trí thật.
local function targetCF(plr)
	if otherMap(plr) then return nil, false end
	local cf = playerCF(plr)
	if cf then return cf, true end
	local last = plr and lastKnownCF[plr]
	if not last then return nil, false end
	local age = os.clock() - (lastKnownT[plr] or os.clock())
	local pred = last + (lastKnownVel[plr] or Vector3.zero) * math.min(age, STALE_EXTRAPOLATE)
	requestStream(pred.Position)
	return pred, false
end

local function teleportToPlayer(plr)
	local cf = targetCF(plr)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if cf and root then root.CFrame = cf + Vector3.new(0, 3, 0) end
end

-- Giữ nhân vật không bị Humanoid/trọng lực kéo lại (PlatformStand) khi đang bám/tween
local holdHum = nil
local function setHold(on)
	if on then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		if holdHum and holdHum ~= hum then pcall(function() holdHum.PlatformStand = false end) end
		holdHum = hum
		if not hum.PlatformStand then pcall(function() hum.PlatformStand = true end) end
	elseif holdHum then
		pcall(function() holdHum.PlatformStand = false end)
		holdHum = nil
	end
end

local function stopFollow()
	followOn = false
	if followConn then followConn:Disconnect(); followConn = nil end
	setHold(false)
end

local function startFollow()
	if followConn then followConn:Disconnect() end
	followConn = RunService.Heartbeat:Connect(function()
		local cf, live = targetCF(selectedPlayer)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if cf and root and hum and hum.Health > 0 then
			setHold(true)
			local goal = cf * FOLLOW_OFFSET
			-- thấy người chơi thật: bám sát. Mất dấu (ở rất xa): bay tới chỗ đoán, tới gần rồi thì đứng chờ game tải (không giật)
			if live or (root.Position - goal.Position).Magnitude > HOLD_RADIUS then
				root.CFrame = goal
			end
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end)
end

-- ===== Noclip (tắt va chạm; tự bật trong lúc đang đi bộ tới người chơi) =====
RunService.Stepped:Connect(function()
	local char = player.Character
	if not char then return end
	if noclipOn or walking or tweening then
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
	ui.noclipBtn.set(noclipOn)
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
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if root and hum then pcall(function() hum:MoveTo(root.Position) end) end
end

function startWalk(continuous)
	if followOn then return end -- đang bám theo thì không cần đi bộ
	walkToken = walkToken + 1
	local token = walkToken
	walking = true -- walking = true => tự bật noclip nên đi thẳng, không bị vật cản làm khựng
	local hovering = false -- đang bay lên để theo độ cao của người chơi
	if flyConn then flyConn:Disconnect() end
	flyConn = RunService.Heartbeat:Connect(function()
		if not (walking and walkToken == token) then return end
		local cf = targetCF(selectedPlayer)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (cf and root and hum and hum.Health > 0) then return end
		local dy = cf.Position.Y - root.Position.Y
		if dy > FLY_START_HEIGHT then hovering = true end
		if hovering and dy < -3 then hovering = false end -- người chơi xuống thấp hơn hẳn: thả xuống đi bộ bình thường
		if hovering then
			-- bay chậm lên (và giữ độ cao bằng người chơi) trong lúc đi bộ tới
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X, math.clamp(dy * 2, -FLY_UP_SPEED, FLY_UP_SPEED), v.Z)
		end
	end)
	task.spawn(function()
		local lastPos, stuckT = nil, 0
		local arrived = false -- (đi bộ bám theo) đã tới gần: đứng chờ, người chơi đi xa thì đi tiếp
		while walking and walkToken == token do
			if not (selectedPlayer and selectedPlayer.Parent == Players) then break end
			local tcf, live = targetCF(selectedPlayer)
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if tcf and root and hum and hum.Health > 0 then
				local flat = Vector3.new(tcf.Position.X - root.Position.X, 0, tcf.Position.Z - root.Position.Z)
				local dist = flat.Magnitude
				if live and dist <= WALK_STOP_DIST then
					if not continuous then break end -- tới nơi (chỉ khi thấy người chơi thật)
					arrived = true
				elseif arrived and dist > WALK_STOP_DIST + 3 then
					arrived = false -- người chơi đi xa rồi: đi bộ theo tiếp
				end
				if arrived or dist <= WALK_STOP_DIST then
					lastPos, stuckT = nil, 0 -- đã tới (hoặc tới chỗ cuối cùng thấy họ mà họ chưa tải): đứng chờ
					if arrived then hum:MoveTo(root.Position) end
				else
				hum:MoveTo(tcf.Position)
				-- dưới nước thì nhảy liên tục để bơi lên / trèo lên bờ
				if not hovering and hum:GetState() == Enum.HumanoidStateType.Swimming then hum.Jump = true end
				-- kẹt (gần như không nhúc nhích) thì nhảy
				if lastPos and (root.Position - lastPos).Magnitude < 0.2 then stuckT = stuckT + 0.1 else stuckT = 0 end
				lastPos = root.Position
				if stuckT > 0.5 and not hovering then hum.Jump = true end
				end
			end
			task.wait(0.1) -- đang chết/hồi sinh thì chờ rồi đi tiếp
		end
		if walkToken == token then stopWalk() end
	end)
end

-- ===== Tween tới người chơi: tự di chuyển MỖI FRAME (không dùng TweenService nữa nên không bị hủy/tạo lại gây giật về chỗ cũ) =====
-- Tính lại điểm tới mỗi frame => đuổi kịp cả khi người chơi đứng yên hoặc đang chạy; càng xa càng bay nhanh nên tới được rất xa.
function stopTween()
	tweening = false
	tweenToken = tweenToken + 1
	if tweenConn then tweenConn:Disconnect(); tweenConn = nil end
	setHold(false)
end

function startTween()
	if followOn then return end
	stopWalk()
	stopTween()
	local token = tweenToken
	tweening = true
	local angle = nil
	tweenConn = RunService.Heartbeat:Connect(function(dt)
		if not (tweening and tweenToken == token) then return end
		if not (selectedPlayer and selectedPlayer.Parent == Players) then -- người chơi rời game => tắt
			stopTween()
			tweenMode = false
			setTweenUI()
			return
		end
		local tcf, live = targetCF(selectedPlayer)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (tcf and root and hum and hum.Health > 0) then return end -- đang chết/hồi sinh: chờ
		dt = math.min(dt, 0.1)
		setHold(true)
		local tpos = tcf.Position
		local cur = root.Position
		local goal
		if live then
			-- quay quanh người chơi: bán kính = Target Distance, góc tăng dần theo Orbit Speed
			if not angle then
				local d = cur - tpos
				angle = math.atan2(d.Z, d.X)
			end
			angle = angle + TWEEN_ORBIT_SPEED * dt
			goal = Vector3.new(tpos.X + math.cos(angle) * TWEEN_TARGET_DISTANCE, tpos.Y, tpos.Z + math.sin(angle) * TWEEN_TARGET_DISTANCE)
		else
			-- mất dấu (người chơi ở rất xa, bị unload): bay thẳng tới chỗ đoán, tới gần thì đứng chờ game tải
			if (tpos - cur).Magnitude <= HOLD_RADIUS then
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				return
			end
			goal = tpos
		end
		local offset = goal - cur
		local dist = offset.Magnitude
		local speed = math.clamp(dist * TWEEN_FAR_FACTOR, TWEEN_SPEED, TWEEN_MAX_SPEED)
		local newPos = cur
		if dist > 1e-3 then newPos = cur + offset.Unit * math.min(dist, speed * dt) end
		local look = Vector3.new(tpos.X, newPos.Y, tpos.Z)
		if live and (look - newPos).Magnitude > 0.1 then
			root.CFrame = CFrame.lookAt(newPos, look)
		else
			root.CFrame = root.CFrame.Rotation + newPos
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
end

function setTweenUI()
	if not (ui and ui.tweenBtn) then return end
	ui.tweenBtn.set(tweenMode)
end

function toggleTweenMode()
	tweenMode = not tweenMode
	if tweenMode then
		if walkMode then walkMode = false; stopWalk(); setWalkUI() end
		if selectedPlayer and not followOn then startTween() end
	else
		stopTween()
	end
	setTweenUI()
end

function setWalkUI()
	if not (ui and ui.walkBtn) then return end
	ui.walkBtn.set(walkMode)
end

function toggleWalkMode()
	walkMode = not walkMode
	if walkMode and tweenMode then tweenMode = false; stopTween(); setTweenUI() end
	if not walkMode then
		stopWalk()
	elseif selectedPlayer and not followOn then
		startWalk() -- đã chọn người từ trước thì đi luôn
	end
	setWalkUI()
end

-- ===== Anti AFK: Roblox kick người chơi đứng im ~20 phút; giả lập thao tác nhẹ mỗi khi bị báo "Idled" =====
local VirtualUser = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

local function pokeAfk()
	if not VirtualUser then return end
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0, 0))
	end)
end

player.Idled:Connect(function()
	if antiAfkOn then pokeAfk() end
end)

task.spawn(function() -- dự phòng: cứ ~1 phút chạm nhẹ 1 lần
	while true do
		task.wait(60)
		if antiAfkOn then pokeAfk() end
	end
end)

function setAntiAfkUI()
	if not (ui and ui.afkBtn) then return end
	ui.afkBtn.set(antiAfkOn)
end

function toggleAntiAfk()
	antiAfkOn = not antiAfkOn
	setAntiAfkUI()
end

function setFollowUI()
	if not (ui and ui.autoBtn) then return end
	ui.autoBtn.set(followOn)
end

function toggleFollow()
	if followOn then
		stopFollow()
	else
		stopWalk()
		stopTween()
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
	if #key >= 12 and key:find("returntomainmenu", 1, true) then
		r.confirm = true -- hộp thoại "Return to main menu?" (nút CANCEL / MENU)
		return
	end
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

function setStatus(txt)
	if not (ui and ui.sub and ui.sub.Parent) then return end
	local s = txt
	if not s then
		s = (selectedPlayer and selectedPlayer.Parent == Players) and ("Đang chọn: " .. selectedPlayer.DisplayName)
			or "Chọn một người chơi để dịch chuyển"
	end
	if ui.sub.Text ~= s then ui.sub.Text = s end
	ui.sub.TextColor3 = txt and C.accent2 or C.muted
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

-- ===== Spawn đúng map của người chơi đã chọn =====
-- Đoán người chơi đang ở map nào theo thứ tự: (1) thuộc tính/giá trị chữ có tên map trên Player/nhân vật,
-- (2) thư mục/model chứa nhân vật có tên map, (3) vị trí gần nơi chính mình từng spawn vào map đó (tự học),
-- (4) gần model/thư mục map trong workspace. Chưa chắc game nào cũng nhận diện được => xem dòng trạng thái.
local mapSamples = {}     -- [idx] = { Vector3 } vị trí của chính mình ngay sau khi spawn vào map đó
local pendingLearn = nil  -- { idx, t }: vừa bấm SPAWN vào map idx, nhân vật mới hiện ra thì ghi nhớ vị trí

local namesCache = {}
local function namesOf(idx)
	local set = namesCache[idx]
	if not set then
		set = {}
		for _, n in ipairs(MAPS[idx]) do set[norm(n)] = true end
		namesCache[idx] = set
	end
	return set
end

local function mapIndexFromText(text)
	local t = norm(tostring(text))
	if t == "" or #t > 40 then return nil end
	for i = 1, #MAPS do
		if matchesMap(t, namesOf(i)) then return i end
	end
	return nil
end

local function detectByValues(plr)
	local function attrs(inst)
		for _, v in pairs(inst:GetAttributes()) do
			if type(v) == "string" then
				local i = mapIndexFromText(v)
				if i then return i end
			end
		end
	end
	local i = attrs(plr)
	if i then return i, "thuộc tính Player" end
	for _, d in ipairs(plr:GetDescendants()) do
		if d:IsA("StringValue") then
			i = mapIndexFromText(d.Value)
			if i then return i, "giá trị " .. d.Name end
		end
		i = attrs(d)
		if i then return i, "thuộc tính " .. d.Name end
	end
	local char = plr.Character
	if char then
		i = attrs(char)
		if i then return i, "thuộc tính nhân vật" end
		for _, d in ipairs(char:GetChildren()) do
			if d:IsA("StringValue") then
				i = mapIndexFromText(d.Value)
				if i then return i, "giá trị " .. d.Name end
			end
		end
		local cur = char.Parent -- thư mục/model chứa nhân vật (vd Workspace.Atlas.Players)
		while cur and cur ~= workspace and cur ~= game do
			i = mapIndexFromText(cur.Name)
			if i then return i, "thư mục " .. cur.Name end
			cur = cur.Parent
		end
	end
	return nil
end

-- Màn Locations hiện hình đại diện (avatar) của người chơi ở ngay dòng map họ đang ở (vd bạn bè):
-- tìm ảnh có UserId của người đã chọn, leo lên dòng chứa nó, dòng đó chứa đúng 1 tên map => map của họ.
local function idInImage(img, id)
	local a, b = img:find(id, 1, true)
	while a do
		local before, after = img:sub(a - 1, a - 1), img:sub(b + 1, b + 1)
		if not before:match("%d") and not after:match("%d") then return true end
		a, b = img:find(id, b + 1, true)
	end
	return false
end

local function locationsMapOf(plr)
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not (pg and plr) then return nil end
	local id = tostring(plr.UserId)
	for _, o in ipairs(pg:GetDescendants()) do
		if (o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Image ~= "" and idInImage(o.Image, id)
			and not (ui and ui.gui and o:IsDescendantOf(ui.gui)) and isShown(o) then
			local cur = o.Parent
			for _ = 1, 6 do
				if not cur or cur == pg then break end
				local found, cnt, seen = nil, 0, {}
				for _, d in ipairs(cur:GetDescendants()) do
					if d:IsA("TextLabel") and d.Text ~= "" then
						local t = norm(d.Text)
						for i = 1, #MAPS do
							if namesOf(i)[t] and not seen[i] then
								seen[i] = true
								found, cnt = i, cnt + 1
							end
						end
					end
				end
				if cnt == 1 then return found end
				if cnt > 1 then break end -- đã leo quá cao (chứa nhiều dòng map)
				cur = cur.Parent
			end
		end
	end
	return nil
end

-- Đọc HUD khi đang trong game: trả về (map mình đang ở, nút "thoát" – hình cánh cửa mũi tên dưới bảng map)
local function scanHud()
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then return nil, nil end
	local myIdx, hudLbl, count = nil, nil, 0
	local hints, btns, imgs = {}, {}, {}
	for _, o in ipairs(pg:GetDescendants()) do
		if o:IsA("GuiObject") and not (ui and ui.gui and o:IsDescendantOf(ui.gui)) then
			if o:IsA("TextLabel") and o.Text ~= "" then
				local t = norm(o.Text)
				for i = 1, #MAPS do
					if namesOf(i)[t] and isShown(o) then
						count = count + 1
						myIdx, hudLbl = i, o
					end
				end
			end
			if o:IsA("GuiButton") and isShown(o) then
				local nk = norm(o.Name)
				if nk:find("exit", 1, true) or nk:find("leave", 1, true) or nk:find("logout", 1, true) or nk:find("quit", 1, true) then
					table.insert(hints, o)
				end
				table.insert(btns, o)
			elseif (o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Image ~= "" and isShown(o) then
				table.insert(imgs, o) -- icon không phải nút (nút thật có thể là lớp trong suốt phủ lên) -> bấm theo toạ độ
			end
		end
	end
	if count ~= 1 then return nil, nil end -- chỉ 1 nhãn tên map = đang trong game (màn Locations có nhiều tên map)
	local lp = hudLbl.AbsolutePosition + hudLbl.AbsoluteSize / 2
	local sg = hudLbl:FindFirstAncestorOfClass("ScreenGui")
	local exitBtn, bestD = nil, math.huge
	for _, b in ipairs(hints) do
		local d = (b.AbsolutePosition - hudLbl.AbsolutePosition).Magnitude
		if b:FindFirstAncestorOfClass("ScreenGui") == sg and d < bestD then exitBtn, bestD = b, d end
	end
	local function pick(list)
		local bestX = -math.huge
		local found = nil
		for _, b in ipairs(list) do
			if b:FindFirstAncestorOfClass("ScreenGui") == sg and b.AbsoluteSize.X <= 120 and b.AbsoluteSize.Y <= 120 then
				local c = b.AbsolutePosition + b.AbsoluteSize / 2
				local dy = c.Y - (hudLbl.AbsolutePosition.Y + hudLbl.AbsoluteSize.Y)
				if dy > 0 and dy < 260 and math.abs(c.X - lp.X) < 220 and c.X > bestX then
					found, bestX = b, c.X
				end
			end
		end
		return found
	end
	if not exitBtn then
		-- không có tên gợi ý: lấy icon nhỏ nằm ngay dưới bảng map, ở phía phải nhất (hàng icon: kaiju / shop / thoát)
		exitBtn = pick(btns) or pick(imgs)
	end
	return myIdx, exitBtn
end

local function nearestSample(pos)
	local best, bi = 2500, nil
	for i, list in pairs(mapSamples) do
		for _, sp in ipairs(list) do
			local d = (sp - pos).Magnitude
			if d < best then best, bi = d, i end
		end
	end
	return bi
end

local anchors, anchorsT = nil, 0
local function buildAnchors()
	if anchors and os.clock() - anchorsT < 20 then return anchors end
	anchors, anchorsT = {}, os.clock()
	local function consider(inst)
		if Players:GetPlayerFromCharacter(inst) then return end
		local i = mapIndexFromText(inst.Name)
		if not i then return end
		local pos
		if inst:IsA("Model") then
			pos = inst:GetPivot().Position
		elseif inst:IsA("BasePart") then
			pos = inst.Position
		elseif inst:IsA("Folder") then
			local sum, n = Vector3.zero, 0
			for _, d in ipairs(inst:GetDescendants()) do
				if d:IsA("BasePart") then
					sum = sum + d.Position
					n = n + 1
					if n >= 100 then break end
				end
			end
			if n > 0 then pos = sum / n end
		end
		if pos then table.insert(anchors, { idx = i, pos = pos }) end
	end
	for _, c in ipairs(workspace:GetChildren()) do
		pcall(consider, c)
		if c:IsA("Folder") or c:IsA("Model") then -- thêm 1 tầng (vd Workspace.Maps.Atlas)
			for _, cc in ipairs(c:GetChildren()) do pcall(consider, cc) end
		end
	end
	return anchors
end

local function detectMapOf(plr)
	if not plr then return nil end
	local i, src = detectByValues(plr)
	if i then return i, src end
	local live = playerCF(plr)
	local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if live and me and myMapIdx and (live.Position - me.Position).Magnitude < 1500 then
		return myMapIdx, "cùng khu vực với mình"
	end
	local cf = live or lastKnownCF[plr]
	if cf then
		i = nearestSample(cf.Position)
		if i then return i, "vị trí đã học" end
		local best, bi = 1200, nil
		for _, a in ipairs(buildAnchors()) do
			local d = (a.pos - cf.Position).Magnitude
			if d < best then best, bi = d, a.idx end
		end
		if bi then return bi, "model map" end
	end
	return nil
end

-- Tên map + nguồn nhận diện lần gần nhất (hiện trên tiêu đề bảng để biết đang đoán đúng không)
local lastDetectInfo = nil
local function respawnTarget()
	if mapIdx > 0 and respawnNames then
		return respawnNames, mapIdx, false -- đã chọn map thủ công => ưu tiên tuyệt đối, không đoán theo người chơi
	end
	if spawnAtPlayerMap and selectedPlayer and selectedPlayer.Parent == Players then
		local i = playerMapIdx[selectedPlayer] or detectMapOf(selectedPlayer)
		if i then return namesOf(i), i, true end
	end
	if not respawnNames and probeActive and probeIdx and os.clock() - probeT < 90 then
		return namesOf(probeIdx), probeIdx, true -- chưa biết map người chơi: nếu không đọc được thì quay lại map vừa rời
	end
	return respawnNames, (mapIdx > 0) and mapIdx or nil, false
end

-- Nhận diện nền mỗi giây: map mình đang ở (HUD), học vị trí của mình ở map đó, và map của người chơi đã chọn
task.spawn(function()
	while true do
		task.wait(1)
		if spawnAtPlayerMap then
			local ok0, cur = pcall(scanHud)
			myMapIdx = ok0 and cur or nil
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if myMapIdx and root then
				local list = mapSamples[myMapIdx] or {}
				mapSamples[myMapIdx] = list
				local near = false
				for _, sp in ipairs(list) do
					if (sp - root.Position).Magnitude < 150 then near = true break end
				end
				if not near then
					table.insert(list, root.Position)
					if #list > 10 then table.remove(list, 1) end
				end
			end
			local sel = selectedPlayer
			if sel and sel.Parent == Players then
				local ok, i, src = pcall(detectMapOf, sel)
				if ok and i then
					if playerMapIdx[sel] == i then
						playerMapStable[sel] = (playerMapStable[sel] or 0) + 1
					else
						playerMapStable[sel] = 1
					end
					playerMapIdx[sel] = i
					local ssrc = tostring(src)
					playerMapExplicit[sel] = (ssrc:find("thuộc tính", 1, true) or ssrc:find("giá trị", 1, true) or ssrc:find("thư mục", 1, true)) ~= nil
					lastDetectInfo = MAPS[i][1] .. " (" .. tostring(src) .. ")"
				end
			end
		end
	end
end)

-- Có cần rời map hiện tại không: người chơi đã chọn đang ở map khác (nhận diện ổn định) và không vừa mới đổi map
-- Chỉ bạn bè mới hiện hình đại diện ở màn Locations => chỉ bạn bè mới đáng vào Locations để đọc map
local friendCache = {}
local function isFriend(plr)
	local v = friendCache[plr]
	if v ~= nil then return v end
	friendCache[plr] = false -- tạm false trong lúc chờ kết quả
	task.spawn(function()
		local ok, res = pcall(function() return player:IsFriendsWith(plr.UserId) end)
		friendCache[plr] = (ok and res == true) or false
	end)
	return false
end

local function wantExit()
	if not spawnAtPlayerMap then return false end
	if os.clock() - lastSwitchT < 60 then return false end
	local sel = selectedPlayer
	if not (sel and sel.Parent == Players and myMapIdx) then return false end
	-- chưa biết chắc map của họ và không thấy họ quanh mình: vào màn Locations 1 lần để đọc (rồi quay lại map nếu không thấy)
	if not playerMapExplicit[sel] and not probeDone[sel] and os.clock() - selectT > 8 and not playerCF(sel) and isFriend(sel) then
		return true
	end
	local t = playerMapIdx[sel]
	if not (t and (playerMapStable[sel] or 0) >= 3) then return false end
	return t ~= myMapIdx
end

-- Tự học: spawn vào map nào xong thì nhớ vị trí của mình ở map đó
player.CharacterAdded:Connect(function(char)
	local pl = pendingLearn
	if not (pl and os.clock() - pl.t < 25) then return end
	pendingLearn = nil
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not root then return end
	task.wait(2)
	if player.Character ~= char then return end
	local list = mapSamples[pl.idx] or {}
	mapSamples[pl.idx] = list
	local pos = root.Position
	for _, sp in ipairs(list) do
		if (sp - pos).Magnitude < 150 then return end
	end
	table.insert(list, pos)
	if #list > 6 then table.remove(list, 1) end
end)

function setSpawnMapUI()
	if not (ui and ui.spawnMapBtn) then return end
	ui.spawnMapBtn.set(spawnAtPlayerMap)
end

function toggleSpawnMap()
	spawnAtPlayerMap = not spawnAtPlayerMap
	setSpawnMapUI()
end

local function mapRespawnStep(names, idx, leaveMap)
	local ok, r = pcall(scanScreens, names)
	if not (ok and r) then return end
	if mapIdx == 0 and spawnAtPlayerMap and selectedPlayer and r.respawn then -- đang ở màn Locations (có nút SPAWN)
		local okL, li = pcall(locationsMapOf, selectedPlayer)
		if okL and li then
			playerMapIdx[selectedPlayer], playerMapExplicit[selectedPlayer], playerMapStable[selectedPlayer] = li, true, 3
			lastDetectInfo = MAPS[li][1] .. " (hình đại diện)"
			if li ~= idx then
				idx, names = li, namesOf(li)
				local ok2, r2 = pcall(scanScreens, names)
				if ok2 and r2 then r = r2 end
			end
		end
	end
	local function yn(v) return v and "Y" or "N" end
	local flags = "map=" .. yn(r.map) .. " spawn=" .. yn(r.respawn) .. " dead=" .. yn(r.death) .. " play=" .. yn(r.play) .. " menu=" .. yn(r.menu) .. " conf=" .. yn(r.confirm)
	if r.confirm and r.menu and os.clock() - exitPending < 12 then
		setStatus("Xác nhận MENU: " .. flags)
		press("menu", r.menu)
		task.wait(0.4)
	elseif r.map and r.respawn then
		setStatus((lastDetectInfo and spawnAtPlayerMap) and ("Map người chơi: " .. lastDetectInfo) or ("Chọn map: " .. flags))
		press("map", r.map)
		task.wait(0.5) -- chờ game nhận map đã chọn (nếu bấm SPAWN quá sớm game dùng map mặc định = Atlas)
		local ok3, r3 = pcall(scanScreens, names)
		if ok3 and r3 and r3.map and r3.map.Parent then press("map", r3.map); task.wait(0.3) end
		press("respawn", (ok3 and r3 and r3.respawn) or r.respawn)
		pendingLearn = idx and { idx = idx, t = os.clock() } or nil
		probeActive = false
		lastSwitchT = os.clock()
		task.wait(0.9)
	elseif r.play then
		setStatus("Bấm Play: " .. flags)
		press("play", r.play)
		task.wait(0.4)
	elseif r.menu and (r.death or r.respawn) then
		setStatus("Bấm MENU: " .. flags)
		press("menu", r.menu)
		task.wait(0.4)
	elseif leaveMap then
		-- người chơi ở map khác: bấm nút thoát (hình cánh cửa) -> hộp thoại "Return to main menu?" -> MENU -> Play -> chọn map -> SPAWN
		local curIdx, exitBtn = scanHud()
		if exitBtn then
			if selectedPlayer then probeDone[selectedPlayer] = true end
			probeActive, probeIdx, probeT = true, curIdx or myMapIdx, os.clock()
			setStatus("Rời map: " .. (lastDetectInfo and ("người chơi ở " .. lastDetectInfo) or "đọc map người chơi ở màn Locations"))
			exitPending, lastSwitchT = os.clock(), os.clock()
			press("exit", exitBtn)
			task.wait(0.5)
		else
			setStatus("Không thấy nút thoát map")
		end
	else
		setStatus("Đang chờ: " .. flags)
		tries = {}
	end
end

function setRespawnUI()
	if not (ui and ui.respawnBtn) then return end
	ui.respawnBtn.set(respawnOn)
end

function toggleRespawn()
	respawnOn = not respawnOn
	setRespawnUI()
end

function setMapUI()
	if not (ui and ui.mapBtn) then return end
	ui.mapBtn.set(respawnMap)
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
	ui.modal.Modal = v -- Modal = true giúp con trỏ không bị game khoá, luôn bấm được nút
	UI.visToken = UI.visToken + 1
	local token, frame, scale = UI.visToken, ui.frame, ui.scale
	if v then
		frame.Visible = true
		tw(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		tw(frame, 0.2, { GroupTransparency = 0 })
	else
		tw(scale, 0.18, { Scale = 0.92 })
		tw(frame, 0.18, { GroupTransparency = 1 })
		task.delay(0.2, function()
			if UI.visToken == token and ui and ui.frame == frame then frame.Visible = false end
		end)
	end
end

-- Cập nhật màu dòng đang chọn (có hiệu ứng, không dựng lại danh sách nên không bị giật/mất vị trí cuộn)
function UI.refresh()
	if not (ui and ui.rowMap) then return end
	for plr, e in pairs(ui.rowMap) do
		local sel = plr == selectedPlayer
		tw(e.row, 0.18, { BackgroundColor3 = sel and C.sel or C.row })
		tw(e.stroke, 0.18, { Transparency = sel and 0 or 1 })
	end
	setStatus(nil)
end

function rebuildList()
	if not (ui and ui.list and ui.list.Parent) then return end
	for _, r in ipairs(ui.rows) do r:Destroy() end
	ui.rows, ui.rowMap = {}, {}
	local q = filterText:lower()
	local n = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local label = plr.DisplayName .. " (@" .. plr.Name .. ")"
			if q == "" or label:lower():find(q, 1, true) then
				n = n + 1
				local sel = selectedPlayer == plr
				local row = make("TextButton", {
					Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = sel and C.sel or C.row,
					Text = "", AutoButtonColor = false, LayoutOrder = n,
				}, ui.list)
				round(row, 10)
				local stroke = make("UIStroke", { Color = C.accent, Thickness = 1.5, Transparency = sel and 0 or 1 }, row)
				local av = make("ImageLabel", {
					Position = UDim2.fromOffset(7, 7), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = C.panel,
					Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=60&h=60", BorderSizePixel = 0,
				}, row)
				round(av, 15)
				make("TextLabel", {
					Position = UDim2.fromOffset(44, 6), Size = UDim2.new(1, -50, 0, 17), BackgroundTransparency = 1,
					Text = plr.DisplayName, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text,
					TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				}, row)
				make("TextLabel", {
					Position = UDim2.fromOffset(44, 23), Size = UDim2.new(1, -50, 0, 14), BackgroundTransparency = 1,
					Text = "@" .. plr.Name, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.muted,
					TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				}, row)
				row.MouseEnter:Connect(function()
					if selectedPlayer ~= plr then tw(row, 0.12, { BackgroundColor3 = C.rowHover }) end
				end)
				row.MouseLeave:Connect(function()
					tw(row, 0.15, { BackgroundColor3 = selectedPlayer == plr and C.sel or C.row })
				end)
				tap(row, function()
					selectedPlayer = plr
					selectT = os.clock()
					if tweenMode and not followOn then
						startTween()
					elseif walkMode and not followOn then
						startWalk()
					else
						teleportToPlayer(plr)
					end
					UI.refresh()
				end)
				table.insert(ui.rows, row)
				ui.rowMap[plr] = { row = row, stroke = stroke }
			end
		end
	end
	if n == 0 then
		local e = make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Text = "Không có người chơi nào",
			Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.muted,
		}, ui.list)
		table.insert(ui.rows, e)
	end
end

function buildUI()
	local parent = getParent()
	local old = parent:FindFirstChild("TeleportExecUI")
	if old then pcall(function() old:Destroy() end) end

	-- Kích thước bảng tự co theo màn hình (điện thoại nằm ngang ~ 390px cao)
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 400)
	local W = math.clamp(math.floor(vp.X * 0.9), 320, 520)
	local H = math.clamp(math.floor(vp.Y * 0.88), 240, 330)
	local hasKeys = UserInputService.KeyboardEnabled
	local LW = 0.4 -- độ rộng cột trái (danh sách người chơi)

	local gui = make("ScreenGui", {
		Name = "TeleportExecUI", ResetOnSpawn = false, DisplayOrder = 999999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
	}, parent)

	-- Nút logo mở/đóng bảng
	local launcher = makeLogo(gui, 52, { Position = UDim2.new(0, 12, 0.5, -26) })
	make("UIStroke", { Color = C.white, Thickness = 1.5, Transparency = 0.7 }, launcher)
	local lscale = make("UIScale", {}, launcher)
	local hit = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 10 }, launcher)
	hit.MouseEnter:Connect(function() tw(lscale, 0.15, { Scale = 1.08 }) end)
	hit.MouseLeave:Connect(function() tw(lscale, 0.15, { Scale = 1 }) end)
	hit.InputBegan:Connect(function(i) if isPointer(i) then tw(lscale, 0.1, { Scale = 0.92 }) end end)
	hit.InputEnded:Connect(function(i) if isPointer(i) then tw(lscale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back) end end)

	-- Bảng chính
	local frame = make("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(W, H),
		Position = savedFramePos or UDim2.new(0, math.clamp(76 + W / 2, W / 2, math.max(W / 2, vp.X - W / 2)), 0.5, 0),
		BackgroundColor3 = C.bg, BorderSizePixel = 0, Active = true,
		Visible = uiVisible, GroupTransparency = uiVisible and 0 or 1,
	}, gui)
	round(frame, 14)
	local scale = make("UIScale", { Scale = uiVisible and 1 or 0.92 }, frame)
	local border = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 50 }, frame)
	round(border, 14)
	make("UIStroke", { Color = C.stroke, Thickness = 1 }, border)

	-- Thanh tiêu đề: kéo để di chuyển bảng
	local header = make("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = C.panel, BorderSizePixel = 0, Active = true }, frame)
	makeLogo(header, 32, { Position = UDim2.fromOffset(12, 10) })
	make("TextLabel", {
		Position = UDim2.fromOffset(54, 8), Size = UDim2.new(1, -110, 0, 19), BackgroundTransparency = 1,
		Text = "Teleport", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)
	local sub = make("TextLabel", {
		Position = UDim2.fromOffset(54, 27), Size = UDim2.new(1, -110, 0, 15), BackgroundTransparency = 1,
		Text = "Chọn một người chơi để dịch chuyển", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, header)
	local closeBtn = make("TextButton", {
		Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -42, 0, 11), BackgroundColor3 = C.row,
		Text = "✕", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.muted, AutoButtonColor = false,
	}, header)
	round(closeBtn, 15)
	closeBtn.MouseEnter:Connect(function() tw(closeBtn, 0.12, { BackgroundColor3 = C.danger, TextColor3 = C.white }) end)
	closeBtn.MouseLeave:Connect(function() tw(closeBtn, 0.15, { BackgroundColor3 = C.row, TextColor3 = C.muted }) end)
	make("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = C.stroke, BorderSizePixel = 0 }, header)

	-- Cột trái: tìm kiếm + danh sách người chơi
	local searchBox = make("TextBox", {
		Size = UDim2.new(LW, -14, 0, 32), Position = UDim2.fromOffset(10, 62), BackgroundColor3 = C.row,
		Text = filterText, PlaceholderText = "Tìm người chơi...", Font = Enum.Font.Gotham, TextSize = 13,
		TextColor3 = C.text, PlaceholderColor3 = C.muted, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
	}, frame)
	round(searchBox, 9)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8) }, searchBox)
	local searchStroke = make("UIStroke", { Color = C.stroke, Thickness = 1 }, searchBox)
	searchBox.Focused:Connect(function() tw(searchStroke, 0.15, { Color = C.accent }) end)
	searchBox.FocusLost:Connect(function() tw(searchStroke, 0.2, { Color = C.stroke }) end)

	local list = make("ScrollingFrame", {
		Size = UDim2.new(LW, -14, 1, -104), Position = UDim2.fromOffset(10, 100), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.stroke,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, frame)
	make("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	make("UIPadding", { PaddingRight = UDim.new(0, 5) }, list)

	-- Cột phải: công tắc điều khiển
	local ctrl = make("ScrollingFrame", {
		Size = UDim2.new(1 - LW, -14, 1, -62), Position = UDim2.new(LW, 4, 0, 62), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.stroke,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, frame)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, ctrl)
	make("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10) }, ctrl)

	local function mkSection(order, text)
		make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamBold,
			TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order,
		}, ctrl)
	end

	local function mkRow(order, text, rightPad)
		local row = make("TextButton", {
			Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.row, Text = "", AutoButtonColor = false, LayoutOrder = order,
		}, ctrl)
		round(row, 10)
		local lbl = make("TextLabel", {
			Size = UDim2.new(1, -rightPad, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1,
			Text = text, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text, TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		make("UITextSizeConstraint", { MaxTextSize = 13, MinTextSize = 8 }, lbl)
		row.MouseEnter:Connect(function() tw(row, 0.12, { BackgroundColor3 = C.rowHover }) end)
		row.MouseLeave:Connect(function() tw(row, 0.15, { BackgroundColor3 = C.row }) end)
		return row
	end

	-- Dòng công tắc: chữ + (phím tắt trên PC) + switch trượt mượt. Trả về nút bấm + đối tượng có :set(bật/tắt)
	local function mkToggle(order, text, key)
		local row = mkRow(order, text, hasKeys and 98 or 70)
		if hasKeys and key then
			local tag = make("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -60, 0.5, 0), Size = UDim2.fromOffset(22, 20),
				BackgroundColor3 = C.panel, Text = key, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.muted,
			}, row)
			round(tag, 6)
		end
		local track = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(40, 22),
			BackgroundColor3 = C.off, BorderSizePixel = 0,
		}, row)
		round(track, 11)
		local knob = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = C.white, BorderSizePixel = 0,
		}, track)
		round(knob, 8)
		local obj = { state = nil }
		function obj.set(on)
			on = on and true or false
			if obj.state == on then return end
			local first = obj.state == nil
			obj.state = on
			local col = on and C.accent or C.off
			local pos = on and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
			if first then
				track.BackgroundColor3, knob.Position = col, pos
			else
				tw(track, 0.18, { BackgroundColor3 = col })
				tw(knob, 0.22, { Position = pos }, Enum.EasingStyle.Back)
			end
		end
		return row, obj
	end

	mkSection(1, "DỊCH CHUYỂN")
	local autoRow, autoBtn = mkToggle(2, "Bám theo", "K")
	local walkRow, walkBtn = mkToggle(3, "Đi bộ tới người", "B")
	local tweenRow, tweenBtn = mkToggle(4, "Bay (tween) tới người", "T")
	mkSection(5, "HỒI SINH")
	local respawnRow, respawnBtn = mkToggle(6, "Auto hồi sinh", "J")
	local mapRow = mkRow(7, "Map hồi sinh", 110)
	local mapPill = make("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(96, 24),
		BackgroundColor3 = C.panel, Text = "Mặc định", Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = C.muted, TextScaled = true,
	}, mapRow)
	round(mapPill, 8)
	make("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 8 }, mapPill)
	make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, mapPill)
	local mapBtn = { set = function(name)
		mapPill.Text = name or "Mặc định"
		tw(mapPill, 0.2, { TextColor3 = name and C.accent2 or C.muted })
	end }
	local spawnMapRow, spawnMapBtn = mkToggle(8, "Spawn map người chơi", "M")
	mkSection(9, "KHÁC")
	local noclipRow, noclipBtn = mkToggle(10, "Noclip", "N")
	local afkRow, afkBtn = mkToggle(11, "Anti AFK", "U")

	local speedRow = make("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.row, LayoutOrder = 12 }, ctrl)
	round(speedRow, 10)
	local speedLbl = make("TextLabel", {
		Size = UDim2.new(1, -110, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1,
		Text = "Tốc độ chạy", Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text, TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, speedRow)
	make("UITextSizeConstraint", { MaxTextSize = 13, MinTextSize = 8 }, speedLbl)
	local speedBox = make("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(96, 26),
		BackgroundColor3 = C.panel, Text = customSpeed > 0 and tostring(customSpeed) or "", PlaceholderText = "mặc định",
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.text, PlaceholderColor3 = C.muted, ClearTextOnFocus = false,
	}, speedRow)
	round(speedBox, 8)
	local speedStroke = make("UIStroke", { Color = C.panel, Thickness = 1 }, speedBox)
	speedBox.Focused:Connect(function() tw(speedStroke, 0.15, { Color = C.accent }) end)

	if hasKeys then
		make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "RightShift: ẩn / hiện bảng",
			Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.muted, LayoutOrder = 13,
		}, ctrl)
	end

	-- Nút ẩn dùng để bật Modal (mở khoá con trỏ chuột khi bảng đang hiện)
	local modal = make("TextButton", { Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "", Modal = uiVisible }, frame)

	ui = { gui = gui, frame = frame, scale = scale, list = list, autoBtn = autoBtn, respawnBtn = respawnBtn,
		noclipBtn = noclipBtn, walkBtn = walkBtn, tweenBtn = tweenBtn, afkBtn = afkBtn, spawnMapBtn = spawnMapBtn, mapBtn = mapBtn,
		sub = sub, modal = modal, rows = {}, rowMap = {} }

	-- Kéo bảng bằng thanh tiêu đề (chuột hoặc cảm ứng)
	if dragConn then dragConn:Disconnect(); dragConn = nil end
	local dragging, dragStart, startPos = false, nil, nil
	header.InputBegan:Connect(function(input)
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

	tap(hit, function() setVisible(not uiVisible) end)
	tap(closeBtn, function() setVisible(false) end)
	tap(autoRow, toggleFollow)
	tap(respawnRow, toggleRespawn)
	tap(noclipRow, toggleNoclip)
	tap(walkRow, toggleWalkMode)
	tap(tweenRow, toggleTweenMode)
	tap(afkRow, toggleAntiAfk)
	tap(spawnMapRow, toggleSpawnMap)
	tap(mapRow, cycleMap)
	speedBox.FocusLost:Connect(function()
		tw(speedStroke, 0.2, { Color = C.panel })
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
	setTweenUI()
	setAntiAfkUI()
	setSpawnMapUI()
	setMapUI()
	setStatus(nil)
end

-- ===== Sự kiện =====
Players.PlayerAdded:Connect(function() rebuildList() end)
Players.PlayerRemoving:Connect(function(plr)
	lastKnownCF[plr] = nil
	lastKnownVel[plr] = nil
	lastKnownT[plr] = nil
	lastKnownMap[plr] = nil
	friendCache[plr] = nil
	if selectedPlayer == plr then
		selectedPlayer = nil
		stopWalk()
		stopTween()
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
	elseif input.KeyCode == SPAWNMAP_KEY then
		toggleSpawnMap()
	elseif input.KeyCode == ANTIAFK_KEY then
		toggleAntiAfk()
	elseif input.KeyCode == TWEEN_KEY then
		toggleTweenMode()
	elseif input.KeyCode == WALK_KEY then
		toggleWalkMode()
	end
end)

buildUI()

-- Vòng auto hồi sinh: thấy nút RESPAWN đang hiện thì tự bấm
task.spawn(function()
	while true do
		task.wait(0.25)
		local active = respawnOn or spawnAtPlayerMap
		local names, idx
		if active then names, idx = respawnTarget() end
		if active then
			if names then
				pcall(mapRespawnStep, names, idx, mapIdx == 0 and wantExit())
			elseif respawnOn then
				local ok, btn = pcall(findRespawnButton)
				if ok and btn then
					press("default", btn)
					task.wait(0.8) -- chờ game hồi sinh rồi mới kiểm tra tiếp
				end
			end
		end
		if not (active and names) then pcall(setStatus, nil) end
	end
end)

-- Ghi nhớ vị trí mọi người chơi đang thấy được (để còn biết đường tới khi họ ở xa bị game unload)
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then pcall(playerCF, plr) end
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
