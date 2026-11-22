-- UZEX Hub - Kaiju Universe (1 file, chạy bằng executor, chỉ chạy phía client)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local player = Players.LocalPlayer
-- Điện thoại / máy cảm ứng không có chuột. Trên máy này TUYỆT ĐỐI không gửi chuột/phím ảo:
-- game thấy "đang dùng chuột" sẽ chuyển sang điều khiển PC và ẨN joystick + nút nhảy.
local function isTouchOnly() return UserInputService.TouchEnabled and not UserInputService.MouseEnabled end

-- ===== CẤU HÌNH =====
local FOLLOW_OFFSET = CFrame.new(0, 0, 3)          -- vị trí so với người được bám (đứng sau lưng 3 stud)
local TOGGLE_UI_KEY = Enum.KeyCode.RightShift      -- phím ẩn/hiện bảng (PC)
local FOLLOW_KEY = Enum.KeyCode.K                  -- phím bật/tắt bám theo (PC)
local RESPAWN_KEY = Enum.KeyCode.J                 -- phím bật/tắt auto hồi sinh (PC)
local NOCLIP_KEY = Enum.KeyCode.N                  -- phím bật/tắt noclip (PC)
local TWEEN_KEY = Enum.KeyCode.T                  -- phím bật/tắt chế độ tween tới người chơi (PC)
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
local FOLLOW_SLACK = 4                             -- bám theo: chỉ kéo lại khi cách điểm đứng > chừng này stud (để còn tự đi được)
local USER_PAUSE = 0.35                            -- vừa tự di chuyển/nhảy xong thì script nhường quyền điều khiển chừng này giây
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

-- ===== Logo UZEX (ảnh PNG nhúng sẵn trong script, không cần upload asset) =====
local LOGO_B64 = [[
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
]]
local logoAsset = nil
local logoTried = false
local function getLogoAsset()
	if logoTried then return logoAsset end
	logoTried = true
	pcall(function()
		if not (writefile and getcustomasset) then return end
		local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
		local map = {}
		for i = 1, #alphabet do map[alphabet:byte(i)] = i - 1 end
		local data = LOGO_B64:gsub("%s", "")
		local out, n = {}, 0
		for i = 1, #data, 4 do
			local a, b, c, d = data:byte(i, i + 3)
			local v = (map[a] or 0) * 262144 + (map[b] or 0) * 4096 + (map[c] or 0) * 64 + (map[d] or 0)
			n = n + 1
			local s1 = string.char(math.floor(v / 65536) % 256)
			local s2 = (c ~= 61) and string.char(math.floor(v / 256) % 256) or ""
			local s3 = (d ~= 61) and string.char(v % 256) or ""
			out[n] = s1 .. s2 .. s3
		end
		local fname = "uzex_logo.png"
		writefile(fname, table.concat(out))
		logoAsset = getcustomasset(fname)
	end)
	return logoAsset
end

-- Logo vẽ bằng code (không cần upload ảnh / asset id): ghim vị trí + vòng sóng dịch chuyển trên nền gradient tím-xanh
local function makeLogo(parent, s, props)
	local asset = getLogoAsset()
	if asset then
		local img = make("ImageLabel", { Size = UDim2.fromOffset(s, s), BackgroundTransparency = 1, BorderSizePixel = 0,
			Image = asset, ScaleType = Enum.ScaleType.Fit }, nil)
		for k, v in pairs(props or {}) do img[k] = v end
		img.Parent = parent
		img:SetAttribute("img", true)
		return img
	end
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
local antiAfkOn = true        -- chống bị kick vì đứng im (AFK) lâu
local tweenMode = false     -- chế độ: chọn người chơi thì tween (bay mượt) tới
local tweening = false
local tweenToken = 0
local tweenConn = nil
local customSpeed = DEFAULT_SPEED -- tốc độ chạy hiện tại (chỉnh được trên bảng, 0 = mặc định)
local mapIdx = 0            -- 0 = mặc định (bấm nút RESPAWN), 1.. = chọn map trong MAPS
local respawnMap = nil      -- tên map đã chọn để hồi sinh (hiện trên nút)
local respawnNames = nil    -- tập các tên (đã chuẩn hoá) để nhận diện map trên màn hình game
local noclipChanged = {}    -- các part do script này tắt va chạm (để trả lại khi tắt noclip)
local F = { farm = false, build = false, active = false, dist = 30, enemyKw = "", buildKw = "", range = 180, densityR = 250,
	mobDist = 28, mobSpeed = 150, orbitSpeed = 1.8, retargetDelay = 0.35, mobRange = 800, retreatPct = 35 } -- auto farm / Auto Farm City

local dragConn = nil         -- kết nối kéo bảng (huỷ khi dựng lại UI)
local savedLauncherPos = nil -- nhớ vị trí logo khi bị kéo
local launcherConn = nil
local savedFramePos = nil   -- nhớ vị trí bảng khi bị kéo, để UI dựng lại vẫn giữ chỗ cũ
local rebuildList, setFollowUI, setVisible, toggleFollow, buildUI
local setRespawnUI, toggleRespawn
local setNoclipUI, toggleNoclip
local setTweenUI, toggleTweenMode, stopTween, startTween
local setStatus
local diagMsg = nil -- lý do chức năng dịch chuyển chưa chạy (hiện ở dòng trạng thái)
local setMapUI, cycleMap
local setAntiAfkUI, toggleAntiAfk

-- Người chơi ở xa có thể bị game "unload" (StreamingEnabled) nên không thấy nhân vật của họ.
-- Script nhớ vị trí cuối cùng thấy được, đi/teleport tới đó và xin game tải khu vực đó; thấy người rồi thì dùng vị trí thật.
local lastKnownCF = {}
local lastKnownVel = {}      -- [Player] = vận tốc lần cuối thấy (để đoán vị trí khi người chơi bị unload)
local lastKnownT = {}        -- [Player] = os.clock() lần cuối thấy thật
local lastStream = 0
local function requestStream(pos)
	if os.clock() - lastStream < 0.6 then return end
	lastStream = os.clock()
	task.spawn(function() pcall(function() workspace:RequestStreamAroundAsync(pos, 1) end) end)
end

local function rootOf(char)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart", true)
end
local function myRoot()
	return rootOf(player.Character)
end

-- Một số game (kaiju...) để nhân vật thật ở thư mục khác, plr.Character có thể trống hoặc là nhân vật sảnh:
-- nếu không thấy thì tìm model mang tên người chơi trong workspace (có cache, quét tối đa mỗi 1.5 giây)
local modelCache, modelScanT = {}, {}
local function findModelByName(plr)
	local m = modelCache[plr]
	if m and m.Parent and rootOf(m) then return m end
	modelCache[plr] = nil
	if os.clock() - (modelScanT[plr] or 0) < 4 then return nil end
	modelScanT[plr] = os.clock()
	local n1, n2 = string.lower(plr.Name), string.lower(plr.DisplayName)
	local found
	pcall(function()
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("Model") and d ~= player.Character then
				local ln = string.lower(d.Name)
				local own = d:GetAttribute("Owner") or d:GetAttribute("Player") or d:GetAttribute("UserId")
				if ln == n1 or ln == n2 or own == plr.Name or own == plr.UserId or own == plr.DisplayName then
					if rootOf(d) then found = d break end
				end
			end
		end
	end)
	modelCache[plr] = found
	return found
end

local function playerCF(plr)
	if not plr then return nil end
	local char = plr.Character
	local r = rootOf(char)
	if not r then
		local m = findModelByName(plr)
		r = m and rootOf(m)
	end
	if r then
		lastKnownCF[plr] = r.CFrame
		local v = r.AssemblyLinearVelocity
		if v.Magnitude > STALE_MAX_VEL then v = v.Unit * STALE_MAX_VEL end
		lastKnownVel[plr] = v
		lastKnownT[plr] = os.clock()
		return r.CFrame
	end
	return nil
end


-- trả về (CFrame, đang_thấy_thật)
-- Khi người chơi ở quá xa bị game unload: KHÔNG quay về vị trí cũ nữa mà đoán tiếp vị trí theo vận tốc lần cuối thấy,
-- đồng thời xin game tải khu vực đó; thấy lại người rồi thì dùng vị trí thật.
local function targetCF(plr)
	local cf = playerCF(plr)
	if cf then return cf, true end
	local last = plr and lastKnownCF[plr]
	if not last then return nil, false end
	local age = os.clock() - (lastKnownT[plr] or os.clock())
	local pred = last + (lastKnownVel[plr] or Vector3.zero) * math.min(age, STALE_EXTRAPOLATE)
	requestStream(pred.Position)
	return pred, false
end

local tpToken = 0
local tpNote = nil -- {msg, t}: thông báo tạm thời khi dịch chuyển 1 lần thất bại
local function teleportToPlayer(plr)
	tpToken = tpToken + 1
	local token = tpToken
	tpNote = nil
	task.spawn(function()
		local t0 = os.clock()
		local done = false
		local why = nil
		-- Đặt vị trí liên tục ~1 giây: game kéo nhân vật về / chưa kịp tải thì vẫn ăn
		while os.clock() - t0 < 1 and tpToken == token do
			local cf = targetCF(plr)
			local root = myRoot()
			if not root then
				local m = findModelByName(player)
				root = m and rootOf(m)
			end
			if not root then
				why = "Không thấy nhân vật của mình"
			elseif not cf then
				why = "Chưa thấy nhân vật của " .. plr.DisplayName .. " (khác map / chưa tải)"
			else
				why = nil
				done = true
				root.CFrame = cf + Vector3.new(0, 3, 0)
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
			RunService.Heartbeat:Wait()
		end
		if not done and tpToken == token then
			tpNote = { msg = why or "Không dịch chuyển được", t = os.clock() + 4 }
		end
	end)
end

-- Người chơi đang tự điều khiển (đi/nhảy)? => script nhường, không ép vị trí nữa
local lastUserInput = 0
local function userActive(hum)
	if hum and (hum.MoveDirection.Magnitude > 0.05 or hum.Jump or UserInputService:IsKeyDown(Enum.KeyCode.Space)
		or hum:GetState() == Enum.HumanoidStateType.Jumping) then
		lastUserInput = os.clock()
	end
	return os.clock() - lastUserInput < USER_PAUSE
end

-- (đã bỏ PlatformStand: nó làm nhân vật không đi/nhảy được) chỉ còn trả lại trạng thái bình thường nếu lỡ bị bật
local holdHum = nil
local function setHold(on)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum.PlatformStand then pcall(function() hum.PlatformStand = false end) end
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
		local root = rootOf(char)
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if cf and root and (not hum or hum.Health > 0) then
			setHold(true)
			if userActive(hum) then return end -- đang tự đi/nhảy: không kéo lại
			local goal = cf * FOLLOW_OFFSET
			local dist = (root.Position - goal.Position).Magnitude
			-- thấy người chơi thật: bám khi cách > FOLLOW_SLACK. Mất dấu (ở rất xa): bay tới chỗ đoán, tới gần rồi thì đứng chờ game tải
			if (live and dist > FOLLOW_SLACK) or (not live and dist > HOLD_RADIUS) then
				root.CFrame = goal
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

-- ===== Noclip (tắt va chạm; tự bật trong lúc đang đi bộ tới người chơi) =====
do
	local ncParts, ncT, ncChar = {}, 0, nil
	RunService.Stepped:Connect(function()
		local char = player.Character
		if not char then return end
		if noclipOn or tweening or F.active then
			if char ~= ncChar or os.clock() - ncT > 0.7 then
				ncChar, ncT = char, os.clock()
				ncParts = {}
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") then ncParts[#ncParts + 1] = p end
				end
			end
			for i = 1, #ncParts do
				local p = ncParts[i]
				if p.Parent and p.CanCollide then
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
end

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
		local root = rootOf(char)
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (tcf and root and (not hum or hum.Health > 0)) then return end -- đang chết/hồi sinh: chờ
		dt = math.min(dt, 0.1)
		setHold(true)
		if userActive(hum) then angle = nil return end -- đang tự đi/nhảy: nhường
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
		if selectedPlayer and not followOn then startTween() end
	else
		stopTween()
	end
	setTweenUI()
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
		if isTouchOnly() then -- điện thoại: cảm ứng ảo, không dùng chuột ảo (tránh mất nút di chuyển)
			VIM:SendTouchEvent(1, 0, pos.X, pos.Y)
			task.wait(0.05)
			VIM:SendTouchEvent(1, 2, pos.X, pos.Y)
		else
			VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
			task.wait(0.05)
			VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
		end
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
		r.confirmObj = r.confirmObj or o
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
	elseif key == "defeated" or key:find("eliminatedby", 1, true) then
		r.defeated = true
		r.anchorObj = r.anchorObj or o
	elseif key == "menu" or (#key <= 10 and key:sub(1, 4) == "menu") then
		local mc = clickableOf(o, pg)
		r.menu = r.menu or mc
		r.menus = r.menus or {}
		table.insert(r.menus, { txt = o, btn = mc }) -- nhớ cả chữ "MENU" để bấm ĐÚNG chỗ chữ đó
	elseif #key <= 20 and key:sub(1, 7) == "respawn" then
		r.death = r.death or clickableOf(o, pg)
		r.anchorObj = o -- ưu tiên neo vào nút RESPAWN (cùng hàng với MENU)
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
				if (matchesMap(nk, names) or nk == "menu" or nk == "menubutton" or nk == "menubtn" or nk == "play" or nk == "spawn" or nk == "respawn") and isShown(o) then
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
	local s = txt or diagMsg
	if not s then
		s = (selectedPlayer and selectedPlayer.Parent == Players) and ("Đang chọn: " .. selectedPlayer.DisplayName)
			or "Chọn một người chơi để dịch chuyển"
	end
	if ui.sub.Text ~= s then ui.sub.Text = s end
	ui.sub.TextColor3 = (txt or diagMsg) and C.accent2 or C.muted
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





-- ===== Hồi sinh theo map đã chọn: MENU -> Play -> chọn map -> SPAWN =====
-- (mapIdx == 0: không chọn map => chỉ bấm RESPAWN, không đụng tới MENU)

-- Danh sách map thường nằm trong ScrollingFrame: map ở dưới bị che nhưng vẫn "nằm trong màn hình",
-- bấm vào sẽ trúng chỗ khác. Cuộn danh sách để nút map hiện ra trước khi bấm.
local function scrollIntoView(obj)
	local cur = obj.Parent
	while cur and cur ~= game do
		if cur:IsA("ScrollingFrame") then
			pcall(function()
				local sp, ss = cur.AbsolutePosition, cur.AbsoluteSize
				local c = obj.AbsolutePosition + obj.AbsoluteSize / 2
				local pad = 6
				if c.Y < sp.Y + pad or c.Y > sp.Y + ss.Y - pad or c.X < sp.X + pad or c.X > sp.X + ss.X - pad then
					local want = cur.CanvasPosition + (c - (sp + ss / 2))
					local maxp = cur.AbsoluteCanvasSize - cur.AbsoluteWindowSize
					cur.CanvasPosition = Vector2.new(
						math.clamp(want.X, 0, math.max(0, maxp.X)),
						math.clamp(want.Y, 0, math.max(0, maxp.Y)))
					task.wait(0.15)
				end
			end)
		end
		cur = cur.Parent
	end
end

-- Bấm ĐÚNG 1 lần (không lặp nhiều kiểu như press) để nút chọn map không bị bật/tắt lại
local function clickOnce(obj)
	scrollIntoView(obj)
	if obj:IsA("GuiButton") and (firesignal or getconnections) then
		pcall(fireSignals, obj)
	end
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		vimTap(obj)
	else
		vimClick(obj)
	end
end

-- Bấm đúng tâm của chữ (vd "MENU"), không bấm tâm của khung nút bọc ngoài (có thể lệch chỗ)
local function pressText(txt, btn)
	local methods = {}
	if btn and btn:IsA("GuiButton") and (firesignal or getconnections) then
		table.insert(methods, function() fireSignals(btn) end)
	end
	table.insert(methods, function() vimTap(txt) end)
	table.insert(methods, function() vimClick(txt) end)
	for _, m in ipairs(methods) do
		pcall(m)
		task.wait(0.12)
		if not (txt.Parent and isShown(txt)) then return end
	end
end

local mapClickedAt = 0
-- Theo dõi bước hồi sinh đang làm: lặp lại cùng 1 bước nhiều lần = đang bị kẹt -> đổi cách bấm / chọn lại map
local rs = { step = nil, n = 0 }
local function stepTrack(name)
	if rs.step == name then rs.n += 1 else rs.step, rs.n = name, 1 end
	return rs.n
end
local function mapRespawnStep(names)
	local ok, r = pcall(scanScreens, names)
	if not (ok and r) then return end
	local function yn(v) return v and "Y" or "N" end
	local isDead = r.defeated or r.death
	if not isDead then
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		isDead = h and h.Health <= 0
	end
	local flags = "map=" .. yn(r.map) .. " spawn=" .. yn(r.respawn) .. " dead=" .. yn(isDead) .. " play=" .. yn(r.play)
		.. " menu=" .. yn(r.menu) .. (r.confirm and " confirm=Y" or "")

	-- Chọn đúng chữ MENU: gần hộp thoại confirm nhất (nếu có), không thì gần nút RESPAWN/DEFEATED nhất
	local menuEntry = r.menus and r.menus[1]
	local anchor = (r.confirm and r.confirmObj) or r.anchorObj
	if anchor and r.menus and #r.menus > 1 then
		local cc, best = centerOf(anchor), math.huge
		for _, m in ipairs(r.menus) do
			local d = (centerOf(m.txt) - cc).Magnitude
			if d < best then best, menuEntry = d, m end
		end
	end
	local menuBtn = menuEntry and menuEntry.txt

	if r.map and r.respawn then
		-- Màn hình Locations (có cả danh sách map lẫn nút SPAWN)
		if os.clock() - mapClickedAt > 4 then
			stepTrack("map")
			setStatus("Chọn map " .. tostring(respawnMap) .. ": " .. flags)
			clickOnce(r.map)
			mapClickedAt = os.clock()
			task.wait(0.7)
		else
			local n = stepTrack("spawn")
			setStatus("SPAWN " .. tostring(respawnMap) .. ": " .. flags)
			local ok3, r3 = pcall(scanScreens, names)
			local sp = (ok3 and r3 and r3.respawn) or r.respawn
			if n >= 3 then press("spawn", sp) else clickOnce(sp) end -- kẹt: thử đủ kiểu bấm
			if n >= 6 then mapClickedAt = 0; rs.n = 0 end        -- kẹt lâu: chọn lại map rồi SPAWN lại
			task.wait(1)
		end
	elseif r.play then
		mapClickedAt = 0
		stepTrack("play")
		setStatus("Bấm Play: " .. flags)
		press("play", r.play)
		task.wait(0.4)
	elseif isDead and menuBtn then
		-- Màn hình DEFEATED: bấm MENU (bỏ qua chữ tên map lẻ trên HUD)
		mapClickedAt = 0
		local n = stepTrack("menu")
		setStatus("Bấm MENU: " .. flags)
		if n >= 3 and n % 2 == 0 then
			press("menu", menuEntry.btn or menuEntry.txt) -- kẹt: thử bấm cả khung nút bằng đủ kiểu
		else
			pressText(menuEntry.txt, menuEntry.btn)
		end
		task.wait(0.45)
	elseif r.map and not isDead then
		-- Có danh sách map nhưng không có nút SPAWN: chọn map luôn
		if os.clock() - mapClickedAt > 4 then
			setStatus("Chọn map " .. tostring(respawnMap) .. ": " .. flags)
			clickOnce(r.map)
			mapClickedAt = os.clock()
		end
		task.wait(0.3)
	else
		rs.step, rs.n = nil, 0
		setStatus("Đang chờ: " .. flags)
	end
end


-- ===== PHẦN MỚI: Auto skill + Fix lag + Tab =====
local X = {
	tab = 1, auto = false, silent = true, mode = 1, interval = 0.3, lag = false,
	skillOn = { true, true, true, true, true, true, true },
	skills = {
		{ "1", Enum.KeyCode.One }, { "2", Enum.KeyCode.Two }, { "3", Enum.KeyCode.Three },
		{ "4", Enum.KeyCode.Four }, { "5", Enum.KeyCode.Five }, { "V", Enum.KeyCode.V }, { "P", Enum.KeyCode.P },
	},
	modes = { "Phím", "Nút UI" },
	btnCache = {}, btnTry = {},
	lagSaved = setmetatable({}, { __mode = "k" }), lagOrig = {}, lagG = {}, lagSA = {},
	lagClasses = {
		ParticleEmitter = true, Trail = true, Beam = true, Smoke = true, Fire = true, Sparkles = true,
		PointLight = true, SpotLight = true, SurfaceLight = true,
		BlurEffect = true, BloomEffect = true, SunRaysEffect = true, ColorCorrectionEffect = true, DepthOfFieldEffect = true,
		Highlight = true, Clouds = true,
	},
}

-- Tìm nút skill trên màn hình (chế độ "Nút UI"): nhãn chữ trùng phím (1,2,3,4,5,V,P) nằm trong ô vuông ở nửa dưới màn hình
function X.findBtn(i)
	local c = X.btnCache[i]
	if c and c.Parent and isShown(c) then return c end
	X.btnCache[i] = nil
	if os.clock() - (X.btnTry[i] or 0) < 2 then return nil end
	X.btnTry[i] = os.clock()
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then return nil end
	local cam = workspace.CurrentCamera
	local vpY = cam and cam.ViewportSize.Y or 0
	local want = string.lower(X.skills[i][1])
	local best
	for _, o in ipairs(pg:GetDescendants()) do
		if (o:IsA("TextLabel") or o:IsA("TextButton")) and norm(o.Text) == want
			and not (ui and ui.gui and o:IsDescendantOf(ui.gui)) and isShown(o) then
			local slot = o.Parent
			if slot and slot:IsA("GuiObject") then
				local s = slot.AbsoluteSize
				if s.X >= 40 and s.X <= 160 and s.Y >= 40 and s.Y <= 160
					and (vpY == 0 or slot.AbsolutePosition.Y > vpY * 0.55) then
					best = clickableOf(slot, pg)
					break
				end
			end
		end
	end
	X.btnCache[i] = best
	return best
end

-- Điện thoại / máy không có bàn phím: gửi phím ảo không ăn => tự dùng bấm nút skill trên màn hình
local function effectiveMode()
	if X.mode == 1 and (isTouchOnly() or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)) then return 2 end
	return X.mode
end
-- Chế độ ẨN click ảo: bắn thẳng signal của nút skill trên màn hình, KHÔNG có chuột/phím/chạm ảo nào
local function canSignal() return (firesignal ~= nil) or (getconnections ~= nil) end
local function castSilent(i)
	if not canSignal() then return false end
	local b = X.findBtn(i)
	if b and b:IsA("GuiButton") and b.Parent and isShown(b) then
		fireSignals(b)
		return true
	end
	return false
end
function X.cast(i)
	if X.silent and castSilent(i) then return end
	local kc = X.skills[i][2]
	if effectiveMode() == 1 and VIM then
		pcall(function()
			VIM:SendKeyEvent(true, kc, false, game)
			task.wait(0.04)
			VIM:SendKeyEvent(false, kc, false, game)
		end)
	else
		local b = X.findBtn(i)
		if b then pcall(clickOnce, b) end
	end
end

-- Vòng auto skill: mỗi lượt bấm lần lượt các skill đã chọn, rồi chờ X.interval giây
task.spawn(function()
	while true do
		task.wait(math.max(0.05, X.interval))
		if X.auto and not UserInputService:GetFocusedTextBox() then
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health > 0 then
				for i = 1, #X.skills do
					if not X.auto then break end
					if X.skillOn[i] then
						pcall(X.cast, i)
						task.wait(0.1)
					end
				end
			end
		end
	end
end)

function X.refreshUI()
	local w = X.w
	if not w then return end
	if w.autoBtn then w.autoBtn.set(X.auto) end
	if w.lagBtn then w.lagBtn.set(X.lag) end
	if w.modePill then w.modePill.Text = X.modes[X.mode] end
	for i, c in ipairs(w.chips or {}) do c.set(X.skillOn[i]) end
end

function X.toggleAuto() X.auto = not X.auto; X.refreshUI() end
function X.cycleMode() X.mode = X.mode % #X.modes + 1; X.btnCache = {}; X.refreshUI() end
function X.toggleSkill(i) X.skillOn[i] = not X.skillOn[i]; X.refreshUI() end
function X.allSkills()
	local anyOff = false
	for i = 1, #X.skills do if not X.skillOn[i] then anyOff = true end end
	for i = 1, #X.skills do X.skillOn[i] = anyOff end
	X.refreshUI()
end

-- ===== Fast Mode / Low GFX (Fix lag): tắt hiệu ứng ánh sáng, bóng đổ, hiệu ứng, texture/material, đồ hoạ thấp nhất =====
-- Tắt công tắc là trả lại đúng như cũ.
local function setHidden(inst, prop, val)
	if sethiddenproperty then
		local ok = pcall(sethiddenproperty, inst, prop, val)
		if ok then return true end
	end
	return (pcall(function() inst[prop] = val end))
end

-- Đổi 1 thuộc tính "toàn cục" (Lighting, settings, Terrain...) và nhớ giá trị cũ để trả lại
local function lagGlobal(inst, prop, val)
	local ok, cur = pcall(function() return inst[prop] end)
	if not ok and gethiddenproperty then ok, cur = pcall(gethiddenproperty, inst, prop) end
	if not ok then return end
	local saved = false
	for _, e in ipairs(X.lagG) do
		if e[1] == inst and e[2] == prop then saved = true break end
	end
	if not saved then table.insert(X.lagG, { inst, prop, cur }) end
	setHidden(inst, prop, val)
end

-- Đổi 1 thuộc tính của object trong workspace/Lighting và nhớ giá trị cũ
local function lagSet(o, prop, val)
	local ok, cur = pcall(function() return o[prop] end)
	if not ok or cur == val then return end
	local s = X.lagSaved[o]
	if not s then s = {}; X.lagSaved[o] = s end
	if s[prop] == nil then s[prop] = cur end
	pcall(function() o[prop] = val end)
end

local function lagTouch(o)
	local cls = o.ClassName
	if X.lagClasses[cls] then                       -- particle, trail, beam, đèn, blur/bloom/sunrays/colorcorrection/DOF...
		lagSet(o, "Enabled", false)
	elseif cls == "Explosion" then
		lagSet(o, "Visible", false)
	elseif cls == "Atmosphere" then                 -- sương mù / ánh sáng khí quyển
		lagSet(o, "Density", 0); lagSet(o, "Haze", 0); lagSet(o, "Glare", 0)
	elseif cls == "Decal" or cls == "Texture" then  -- texture dán
		lagSet(o, "Transparency", 1)
	elseif cls == "SurfaceAppearance" then          -- material PBR: gỡ ra, tắt thì gắn lại
		if o.Parent and not X.lagSA[o] then
			X.lagSA[o] = o.Parent
			pcall(function() o.Parent = nil end)
		end
	elseif o:IsA("BasePart") and not o:IsA("Terrain") then
		lagSet(o, "CastShadow", false)              -- tắt bóng đổ
		lagSet(o, "Material", Enum.Material.SmoothPlastic) -- tắt material
		lagSet(o, "Reflectance", 0)
		if cls == "MeshPart" then lagSet(o, "TextureID", "") end -- tắt texture của mesh
	end
end

function X.setLag(on)
	X.lag = on
	local Lighting = game:GetService("Lighting")
	if on then
		X.lagG = X.lagG or {}
		X.lagSA = X.lagSA or {}
		-- Bóng đổ + đồ hoạ thấp nhất
		lagGlobal(Lighting, "GlobalShadows", false)
		lagGlobal(Lighting, "ShadowSoftness", 0)
		lagGlobal(Lighting, "EnvironmentDiffuseScale", 0)
		lagGlobal(Lighting, "EnvironmentSpecularScale", 0)
		-- Voxel / ShadowMap -> Compatibility
		lagGlobal(Lighting, "Technology", Enum.Technology.Compatibility)
		-- Chất lượng (texture/mesh) thấp nhất
		pcall(function()
			local r = settings().Rendering
			lagGlobal(r, "QualityLevel", Enum.QualityLevel.Level01)
			lagGlobal(r, "MeshPartDetailLevel", Enum.MeshPartDetailLevel.Level04)
		end)
		-- Material mới 2022 + nước + cỏ
		pcall(function() lagGlobal(game:GetService("MaterialService"), "Use2022Materials", false) end)
		pcall(function()
			local t = workspace.Terrain
			lagGlobal(t, "Decoration", false)
			lagGlobal(t, "WaterWaveSize", 0)
			lagGlobal(t, "WaterWaveSpeed", 0)
			lagGlobal(t, "WaterReflectance", 0)
		end)
		for _, o in ipairs(Lighting:GetDescendants()) do pcall(lagTouch, o) end
		if X.lagConn then X.lagConn:Disconnect() end
		if X.lagConn2 then X.lagConn2:Disconnect() end
		X.lagConn = workspace.DescendantAdded:Connect(function(o) pcall(lagTouch, o) end)
		X.lagConn2 = Lighting.DescendantAdded:Connect(function(o) pcall(lagTouch, o) end)
		task.spawn(function() -- quét dần workspace, không làm đứng hình
			local n = 0
			for _, o in ipairs(workspace:GetDescendants()) do
				if not X.lag then return end
				pcall(lagTouch, o)
				n = n + 1
				if n % 200 == 0 then task.wait() end
			end
		end)
	else
		if X.lagConn then X.lagConn:Disconnect(); X.lagConn = nil end
		if X.lagConn2 then X.lagConn2:Disconnect(); X.lagConn2 = nil end
		for o, props in pairs(X.lagSaved) do
			for k, v in pairs(props) do pcall(function() o[k] = v end) end
		end
		X.lagSaved = setmetatable({}, { __mode = "k" })
		for o, parent in pairs(X.lagSA or {}) do
			pcall(function() if parent and parent.Parent then o.Parent = parent end end)
		end
		X.lagSA = {}
		for i = #(X.lagG or {}), 1, -1 do
			local e = X.lagG[i]
			setHidden(e[1], e[2], e[3])
		end
		X.lagG = {}
	end
	X.refreshUI()
end
function X.toggleLag() X.setLag(not X.lag) end


-- ===== AUTO FARM + AUTO PHÁ NHÀ =====
local BUILD_DEFAULT = { "city" } -- tên model toà nhà trong game Kaiju Universe là "City"
local FARM_TIMEOUT_BUILD = 120 -- toà nhà: giới hạn cứng, quá lâu vẫn chưa xong thì bỏ qua (mob thì KHÔNG có giới hạn: phải hạ xong con đó mới đổi)
local STALL_BUILD = 4          -- toà nhà: đang ở sát mà không thay đổi chừng này giây -> coi như xong, đổi toà khác
F.cacheE, F.cacheB = {}, {}
F.bad = setmetatable({}, { __mode = "k" }) -- [model] = thời điểm hết hạn bỏ qua
local BAD_DONE, BAD_STUCK = 240, 30              -- nhà đã phá: bỏ qua 240s (game xây lại sau vài phút); kẹt/timeout: chỉ 30s rồi thử lại
local MOB_PRIORITY_RANGE = 300                   -- bật cả farm lẫn phá nhà: mob chỉ được ưu tiên khi ở trong tầm này, xa hơn thì phá nhà gần trước
local function markBad(m, secs) F.bad[m] = os.clock() + secs end
local function isBad(m) local t = F.bad[m]; return t ~= nil and t > os.clock() end
-- yêu cầu quét lại danh sách mục tiêu (giới hạn tần suất để không quét toàn map liên tục)
local function requestScan()
	if os.clock() - (F.scanReq or 0) > 2 then F.scanReq = os.clock(); F.scanNow = true end
end
F.cur, F.curKind, F.curT = nil, nil, 0

local function splitKw(str)
	local t = {}
	for w in string.gmatch(string.lower(str or ""), "[^,]+") do
		w = w:gsub("^%s+", ""):gsub("%s+$", "")
		if w ~= "" then t[#t + 1] = w end
	end
	return t
end
local function matchKw(name, kws)
	if #kws == 0 then return true end
	name = string.lower(name)
	for _, k in ipairs(kws) do
		if string.find(name, k, 1, true) then return true end
	end
	return false
end
-- Mob thêm sẵn vào auto farm dù KHÔNG có Humanoid (Wyrmite...). Khớp theo tên model, không phân biệt hoa/thường.
local EXTRA_ENEMY = { "wyrmite" }
-- Mob bị LOẠI khỏi auto farm (tên chứa từ này): Arctic Wyrmite level cao, đánh không lại
-- Theo wiki: Arctic (đánh từ xa, level 75+), Glacialith (~8000 HP), Incineros/Ramthor NPC ở Costa Sierpe (hội đồng solo) => bỏ qua
local EXCLUDE_ENEMY = { "arctic", "glacialith", "incineros", "ramthor" }
local function nameHas(name, list)
	local n = string.lower(name or "")
	for _, k in ipairs(list) do
		if n:find(k, 1, true) then return true end
	end
	return false
end
-- Đúng "Wyrmite" (cho phép thêm số/khoảng trắng phía sau: Wyrmite1, Wyrmite 2), KHÔNG khớp "Arctic Wyrmite"
local function isPlainWyrmite(name)
	local n = string.lower(name or "")
	return n:match("^%s*wyrmite[%s%d_%-]*$") ~= nil
end
local function anyPart(m) return m:FindFirstChildWhichIsA("BasePart", true) end
-- Còn sống? Có Humanoid: theo máu. Không có: theo thuộc tính Health (nếu có), không thì coi như còn sống khi model còn tồn tại
local function enemyAlive(m, h)
	if h then return h.Health > 0 end
	local a = m:GetAttribute("Health")
	if type(a) == "number" then return a > 0 end
	return m.Parent ~= nil
end
local function isMine(m)
	local ch = player.Character
	return ch and (m == ch or m:IsDescendantOf(ch))
end
local function pivotPos(m)
	local ok, cf = pcall(function() return m:GetPivot() end)
	return ok and cf.Position or nil
end
-- Vị trí để bay tới: mob lấy theo thân thật (RootPart), KHÔNG dùng pivot của model vì pivot NPC có thể lệch/nằm trên trời
local function targetPos(m, enemy)
	if enemy then
		local hum = m:FindFirstChildOfClass("Humanoid")
		local r = (hum and hum.RootPart) or rootOf(m)
		if r then return r.Position end
	end
	return pivotPos(m)
end
local SKY_DIFF = 300 -- mob cao/thấp hơn mình quá chừng này stud = nghi là mục tiêu ảo/trên trời -> bỏ qua

-- ===== Chia toà nhà theo ĐẢO =====
-- Hai toà nhà cách nhau <= ISLAND_LINK stud (theo mặt phẳng ngang) cùng chuỗi liên kết => cùng 1 đảo.
-- Đảo hiện tại = đảo của toà nhà gần mình nhất, và phải nằm trong ISLAND_REACH stud (xa hơn = đang ở đảo không có nhà).
local ISLAND_LINK, ISLAND_REACH = 600, 800
local function clusterBuildings(B)
	local pos, parent, grid = {}, {}, {}
	local function find(i)
		while parent[i] ~= i do parent[i] = parent[parent[i]]; i = parent[i] end
		return i
	end
	local function cellOf(p) return math.floor(p.X / ISLAND_LINK), math.floor(p.Z / ISLAND_LINK) end
	for i, m in ipairs(B) do
		local p = pivotPos(m)
		if p then
			pos[i], parent[i] = p, i
			local cx, cz = cellOf(p)
			local key = cx .. "," .. cz
			grid[key] = grid[key] or {}
			table.insert(grid[key], i)
		end
	end
	local steps = 0
	for i, p in pairs(pos) do
		local cx, cz = cellOf(p)
		for dx = -1, 1 do
			for dz = -1, 1 do
				local cell = grid[(cx + dx) .. "," .. (cz + dz)]
				if cell then
					for _, j in ipairs(cell) do
						local ri, rj = find(i), find(j)
						if ri ~= rj then
							local q = pos[j]
							local ddx, ddz = p.X - q.X, p.Z - q.Z
							if ddx * ddx + ddz * ddz <= ISLAND_LINK * ISLAND_LINK then parent[ri] = rj end
						end
						steps += 1
						if steps % 20000 == 0 then task.wait() end
					end
				end
			end
		end
	end
	local islandOf = setmetatable({}, { __mode = "k" })
	for i, m in ipairs(B) do
		if parent[i] then islandOf[m] = find(i) end
	end
	return islandOf
end

-- Quét quái / toà nhà nền (có nhường frame) để không đứng hình
task.spawn(function()
	while true do
		local waited = 0
		while waited < 3 and not F.scanNow do task.wait(0.25) waited += 0.25 end
		F.scanNow = false
		if F.farm or F.build then
			local bK = splitKw(F.buildKw)
			if #bK == 0 then bK = BUILD_DEFAULT end
			local eK = splitKw(F.enemyKw)
			local E, B, seen, n = {}, {}, {}, 0
			for _, d in ipairs(workspace:GetDescendants()) do
				n += 1
				if n % 1500 == 0 then task.wait() end
				pcall(function()
					if F.farm and d:IsA("Model") and not seen[d] and isPlainWyrmite(d.Name)
						and (#eK == 0 or matchKw(d.Name, eK)) and not d:FindFirstChildOfClass("Humanoid")
						and not isMine(d) and not Players:GetPlayerFromCharacter(d)
						and not (d.Parent and d.Parent:IsA("Model") and isPlainWyrmite(d.Parent.Name))
						and anyPart(d) then
						seen[d] = true
						E[#E + 1] = { m = d, h = nil }
					end
					if F.farm and d:IsA("Humanoid") and d.Health > 0 then
						local m = d.Parent
						if m and m:IsA("Model") and not isMine(m) and not Players:GetPlayerFromCharacter(m)
							and rootOf(m) and matchKw(m.Name, eK)
							and not nameHas(m.Name, EXCLUDE_ENEMY) and not nameHas(d.DisplayName, EXCLUDE_ENEMY) then
							E[#E + 1] = { m = m, h = d }
						end
					elseif F.build then
						if d:IsA("Model") and not d:FindFirstChildOfClass("Humanoid") and not isMine(d)
							and matchKw(d.Name, bK) and not seen[d]
							and not (d.Parent and d.Parent:IsA("Model") and matchKw(d.Parent.Name, bK)) then
							seen[d] = true
							B[#B + 1] = d
						elseif d:IsA("Folder") and matchKw(d.Name, bK) then -- thư mục "Buildings": mỗi model con là 1 toà nhà
							for _, c in ipairs(d:GetChildren()) do
								if c:IsA("Model") and not seen[c] then seen[c] = true; B[#B + 1] = c end
							end
						end
					end
				end)
			end
			local islandOf = F.build and clusterBuildings(B) or {}
			F.cacheE, F.cacheB, F.islandOf = E, B, islandOf
		end
	end
end)

-- Chọn City để farm trên ĐẢO ĐANG ĐỨNG:
--  * Building Search Range (F.range): chỉ xét các City trong tầm này quanh nhân vật
--  * Density Area Size (F.densityR): trong số đó chọn City có NHIỀU City khác xung quanh nhất (khu dày đặc), hoà thì chọn gần hơn
--  * Hết City trong tầm: nhảy sang City gần nhất còn lại trên đảo để farm tiếp
local function nearestOnIsland(root)
	local nb, nd
	for _, m in ipairs(F.cacheB) do
		if m.Parent then
			local p = pivotPos(m)
			if p then
				local d = (p - root.Position).Magnitude
				if not nd or d < nd then nb, nd = m, d end
			end
		end
	end
	if not nb or nd > ISLAND_REACH then F.noIsland = true; return nil end
	F.noIsland = false
	local islandOf = F.islandOf or {}
	local id = islandOf[nb]
	local list = {}
	for _, m in ipairs(F.cacheB) do
		if m.Parent and not isBad(m) and (id == nil or islandOf[m] == id) then
			local p = pivotPos(m)
			if p then list[#list + 1] = { m = m, p = p, d = (p - root.Position).Magnitude } end
		end
	end
	if #list == 0 then return nil end
	table.sort(list, function(a, b) return a.d < b.d end)
	local cands = {}
	for _, e in ipairs(list) do
		if e.d > F.range or #cands >= 60 then break end
		cands[#cands + 1] = e
	end
	if #cands == 0 then return list[1].m end
	local r2 = F.densityR * F.densityR
	local best, bestN, bestD
	for _, c in ipairs(cands) do
		local n = 0
		for _, e in ipairs(list) do
			local dx, dz = c.p.X - e.p.X, c.p.Z - e.p.Z
			if dx * dx + dz * dz <= r2 then n += 1 end
		end
		if not bestN or n > bestN or (n == bestN and c.d < bestD) then best, bestN, bestD = c.m, n, c.d end
	end
	return best
end

local function pickTarget(root)
	local function nearest(list, enemy)
		local best, bd
		for _, e in ipairs(list) do
			local m = enemy and e.m or e
			if m.Parent and not isBad(m) and (not enemy or enemyAlive(m, e.h)) then
				local p = targetPos(m, enemy)
				if p and enemy and math.abs(p.Y - root.Position.Y) > SKY_DIFF then p = nil end
				if p then
					local d = (p - root.Position).Magnitude
					if (not enemy or d <= F.mobRange) and (not bd or d < bd) then best, bd = e, d end
				end
			end
		end
		return best, bd
	end
	local e, ed, b
	if F.farm then e, ed = nearest(F.cacheE, true) end
	if F.build then b = nearestOnIsland(root) end
	if e and (not b or ed <= MOB_PRIORITY_RANGE) then return e.m, "enemy", e.h end
	if b then return b, "build", nil end
	if e then return e.m, "enemy", e.h end
	return nil
end

-- Chữ ký trạng thái toà nhà: đổi khi bị phá (part bị xoá / mờ đi / thu nhỏ / máu giảm). n = số part còn lại
local function buildSig(m)
	local n, tr, hp = 0, 0, ""
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			n += 1; tr += p.Transparency
		elseif p:IsA("NumberValue") or p:IsA("IntValue") then
			hp ..= tostring(p.Value) .. ","
		end
	end
	for k, v in pairs(m:GetAttributes()) do
		if type(v) == "number" then hp ..= k .. "=" .. tostring(v) .. "," end
	end
	local sz = ""
	local ok, s = pcall(function() return m:GetExtentsSize() end)
	if ok and s then sz = string.format("%.1f,%.1f,%.1f", s.X, s.Y, s.Z) end
	return n, string.format("%d|%.2f|%s|%s", n, tr, sz, hp)
end

-- Điện thoại: ẩn mũi tên chuột ảo khi farm, trả lại khi tắt farm
local iconOrig = nil
local function setFarmCursor(hide)
	if not isTouchOnly() then return end
	pcall(function()
		if hide then
			if iconOrig == nil then iconOrig = UserInputService.MouseIconEnabled end
			UserInputService.MouseIconEnabled = false
		elseif iconOrig ~= nil then
			UserInputService.MouseIconEnabled = iconOrig
			iconOrig = nil
		end
	end)
end
-- Bật lại nút di chuyển (joystick / nhảy) của game nếu bị tắt
local function ensureControls()
	pcall(function() GuiService.TouchControlsEnabled = true end)
	pcall(function()
		local ps = player:FindFirstChild("PlayerScripts")
		local pm = ps and ps:FindFirstChild("PlayerModule")
		if pm then require(pm):GetControls():Enable() end
	end)
end
-- Chiều cao thân kaiju: khoảng cách từ RootPart xuống chân (lấy số nhỏ nhất đo được = lúc đang đứng trên đất)
local function measureStandH(root)
	local cands = {}
	pcall(function()
		local p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Exclude
		p.FilterDescendantsInstances = { player.Character }
		local r = workspace:Raycast(root.Position, Vector3.new(0, -300, 0), p)
		if r then cands[#cands + 1] = root.Position.Y - r.Position.Y end
	end)
	pcall(function()
		local cf, size = player.Character:GetBoundingBox()
		cands[#cands + 1] = root.Position.Y - (cf.Position.Y - size.Y / 2)
	end)
	local best
	for _, h in ipairs(cands) do
		if h >= 2 and (not best or h < best) then best = h end
	end
	if best then
		best = math.min(best, 80)
		F.standH = F.standH and math.min(F.standH, best) or best
	end
end
-- Độ cao RootPart để chân đứng đúng trên mặt đất tại vị trí pos (bắn tia từ ngay trên mob xuống)
local function standY(pos, ignoreModel, mobY)
	local ok, y = pcall(function()
		local p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Exclude
		p.FilterDescendantsInstances = { player.Character, ignoreModel }
		local r = workspace:Raycast(Vector3.new(pos.X, mobY + 15, pos.Z), Vector3.new(0, -400, 0), p)
		if r then
			local ground = math.clamp(r.Position.Y, mobY - 40, mobY + 40)
			return ground + (F.standH or 6) + 1
		end
	end)
	if ok and y then return y end
	return mobY + 4
end

pcall(function() RunService:UnbindFromRenderStep("UZEXAim") end) -- dọn bản cũ nếu còn

local attacking = false

-- Các khung của script đang hiện trên màn hình (bảng chính + logo): click giả phải tránh những vùng này
local function scriptRects()
	local rects = {}
	local g = ui and ui.gui
	if g and g.Parent then
		for _, o in ipairs(g:GetChildren()) do
			if o:IsA("GuiObject") and o.Visible then
				rects[#rects + 1] = { o.AbsolutePosition, o.AbsoluteSize }
			end
		end
	end
	return rects
end

-- Chọn điểm click đánh thường: ưu tiên giữa màn hình, nếu bị bảng script che thì dời sang chỗ trống
local function attackClickPoint()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 400)
	local rects = scriptRects()
	local function free(p)
		for _, r in ipairs(rects) do
			local a, sz = r[1], r[2]
			local m = 24 -- chừa lề cho chắc
			if p.X >= a.X - m and p.X <= a.X + sz.X + m and p.Y >= a.Y - m and p.Y <= a.Y + sz.Y + m then return false end
		end
		return true
	end
	local spots = { {0.5, 0.5}, {0.62, 0.45}, {0.72, 0.4}, {0.5, 0.32}, {0.82, 0.35}, {0.38, 0.32}, {0.9, 0.5} }
	if isTouchOnly() then -- joystick động nằm ở nửa trái, nút skill ở dưới phải => chạm vùng phải-trên
		spots = { {0.62, 0.38}, {0.72, 0.34}, {0.55, 0.3}, {0.8, 0.4}, {0.66, 0.46} }
	end
	for _, sp in ipairs(spots) do
		local p = Vector2.new(vp.X * sp[1], vp.Y * sp[2])
		if free(p) then return p end
	end
	return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end

local function attackBurst()
	if attacking then return end
	attacking = true
	task.spawn(function()
		-- Auto phá nhà / auto mob tự đánh, KHÔNG cần bật Auto skill: bấm các skill đang chọn rồi đánh thường
		for i = 1, #X.skills do
			if not (F.farm or F.build) then break end
			if X.skillOn[i] then pcall(X.cast, i) task.wait(0.08) end
		end
		if VIM then -- đánh thường: click chỗ trống (không trúng bảng script)
			pcall(function()
				local c = attackClickPoint()
				if isTouchOnly() then
					VIM:SendTouchEvent(5, 0, c.X, c.Y)
					task.wait(0.03)
					VIM:SendTouchEvent(5, 2, c.X, c.Y)
				else
					VIM:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 0)
					task.wait(0.03)
					VIM:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 0)
				end
			end)
		end
		attacking = false
	end)
end

task.spawn(function()
	local lastAtk = 0
	while true do
		local dt = math.min(RunService.Heartbeat:Wait(), 0.1)
		if not (F.farm or F.build) then
			F.active, F.cur = false, nil
			setFarmCursor(false)
			task.wait(0.2)
		else
			local char = player.Character
			local root, hum = rootOf(char), char and char:FindFirstChildOfClass("Humanoid")
			if not root or (hum and hum.Health <= 0) then
				F.active, F.cur = false, nil
			else
				-- giữ nút di chuyển (joystick / nhảy) luôn bật khi đang farm
				if os.clock() - (F.ctrlT or 0) > 3 then F.ctrlT = os.clock(); ensureControls() end
				setFarmCursor(true)
				-- kiểm tra mục tiêu hiện tại còn hợp lệ
				local hadCur = F.cur
				local m = F.cur
				if m then
					local dead = not m.Parent or (F.curKind == "enemy" and not enemyAlive(m, F.curHum))
					local timeout = F.curKind ~= "enemy" and os.clock() - F.curT > FARM_TIMEOUT_BUILD -- mob: không bao giờ bỏ giữa chừng, phải hạ xong mới đổi
					if dead then
						if F.curKind ~= "enemy" then markBad(m, BAD_DONE) end
						F.cur = nil
					elseif timeout then markBad(m, BAD_STUCK); F.cur = nil
					elseif os.clock() - (F.sigT or 0) >= 1 then
						-- mỗi giây kiểm tra tiến triển: xong rồi (hết part) hoặc không thay đổi gì khi đã đứng sát -> đổi mục tiêu
						F.sigT = os.clock()
						local sig, empty
						if F.curKind == "enemy" and F.curHum then
							sig = tostring(F.curHum.Health)
						else
							local ok, n, s = pcall(buildSig, m)
							if ok then sig, empty = s, (n == 0) end
						end
						local mp = targetPos(m, F.curKind == "enemy")
						local near = mp and (root.Position - mp).Magnitude <= (F.curKind == "enemy" and F.mobDist or F.dist) + 30
						if F.curKind == "enemy" then
							if near then F.farSince = nil
							else
								F.farSince = F.farSince or os.clock()
								if os.clock() - F.farSince > 12 then -- 12s vẫn chưa lại gần được = mục tiêu không tới được
									markBad(m, 60); F.cur = nil; F.farSince = nil
									empty = nil
								end
							end
						end
						if not F.cur then
							-- đã bỏ mục tiêu không tới được
						elseif empty then
							markBad(m, F.curKind == "enemy" and BAD_STUCK or BAD_DONE); F.cur = nil
						elseif sig ~= F.curSig or not near then
							F.curSig = sig; F.curChg = os.clock()
						elseif (F.curKind ~= "enemy" or not F.curHum) and os.clock() - (F.curChg or os.clock()) > (F.curKind == "enemy" and STALL_BUILD * 2 or STALL_BUILD) then
							markBad(m, F.curKind == "enemy" and BAD_STUCK or BAD_DONE); F.cur = nil
						end
					end
				end
				if hadCur and not F.cur then -- vừa xong 1 mục tiêu: mob thì nghỉ Retarget Delay rồi mới đổi con khác
					F.pickAfter = os.clock() + (F.curKind == "enemy" and F.retargetDelay or 0)
				end
				if not F.cur and os.clock() >= (F.pickAfter or 0) then
					F.cur, F.curKind, F.curHum = pickTarget(root)
					F.curT = os.clock()
					F.curSig, F.curChg, F.sigT, F.farSince = nil, os.clock(), 0, nil
					if not F.cur then requestScan() end -- hết mục tiêu: quét lại tìm cái mới
				end
				local tgt = F.cur
				local tpos = tgt and targetPos(tgt, F.curKind == "enemy")
				if tgt and tpos then
					-- Retreat HP: máu thấp hơn mức đặt thì bay lên cao (mob đất không với tới) hồi máu, đủ 85% mới đánh tiếp
					if F.retreatPct > 0 and F.curKind == "enemy" then
						local frac = hum.Health / math.max(1, hum.MaxHealth)
						if F.retreating then
							if frac >= 0.85 then F.retreating = false end
						elseif frac * 100 < F.retreatPct then
							F.retreating = true
							F.retreatY = root.Position.Y + 250
						end
					else
						F.retreating = false
					end
					-- di chuyển tới điểm đứng (nhường khi người chơi tự đi/nhảy)
					if F.retreating then
						F.active = true
						if not userActive(hum) then
							root.CFrame = CFrame.new(root.Position.X, F.retreatY, root.Position.Z)
							root.AssemblyLinearVelocity = Vector3.zero
						end
					elseif not userActive(hum) then
						local flat = Vector3.new(root.Position.X - tpos.X, 0, root.Position.Z - tpos.Z)
						local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, 1)
						local goal
						if F.curKind == "enemy" then -- Auto Farm Mob: đứng cách mob Target Distance và quay quanh mob theo Orbit Speed
							if F.orbitTgt ~= tgt or F.orbitAng == nil then
								F.orbitTgt = tgt
								F.orbitAng = math.atan2(root.Position.Z - tpos.Z, root.Position.X - tpos.X)
							end
							if F.orbitSpeed > 0 then F.orbitAng += F.orbitSpeed * dt end
							if os.clock() - (F.standT or 0) > 0.5 then F.standT = os.clock(); measureStandH(root) end
							local gp = tpos + Vector3.new(math.cos(F.orbitAng), 0, math.sin(F.orbitAng)) * F.mobDist
							goal = Vector3.new(gp.X, standY(gp, tgt, tpos.Y), gp.Z)
						else
							goal = tpos + dir * F.dist + Vector3.new(0, 8, 0)
						end
						local off = goal - root.Position
						local d = off.Magnitude
						F.active = true
						if d > ((F.curKind == "enemy" and F.orbitSpeed > 0) and 0.5 or 4) then
							if F.curKind == "build" then -- phá nhà: teleport thẳng tới nhà (cùng đảo)
								pcall(requestStream, goal)
								root.CFrame = CFrame.lookAt(goal, Vector3.new(tpos.X, goal.Y, tpos.Z))
								root.AssemblyLinearVelocity = Vector3.zero
							else
								local speed = math.clamp(d * TWEEN_FAR_FACTOR, F.mobSpeed, TWEEN_MAX_SPEED)
								local np = root.Position + off.Unit * math.min(d, speed * dt)
								root.CFrame = CFrame.lookAt(np, Vector3.new(tpos.X, np.Y, tpos.Z))
								root.AssemblyLinearVelocity = Vector3.zero
							end
						end
					end
					if not F.retreating and os.clock() - lastAtk >= math.max(0.1, X.interval) and not UserInputService:GetFocusedTextBox() then
						lastAtk = os.clock()
						attackBurst()
					end
				else
					F.active = false
				end
			end
		end
	end
end)

-- Luôn cho phép nhảy/đi khi đang dùng các chức năng (một số game đặt JumpPower = 0 hoặc để PlatformStand)
RunService.Heartbeat:Connect(function()
	if not (followOn or tweenMode or F.farm or F.build or noclipOn) then return end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	pcall(function()
		if hum.PlatformStand then hum.PlatformStand = false end
		if hum.UseJumpPower then
			if hum.JumpPower <= 0 then hum.JumpPower = 50 end
		elseif hum.JumpHeight <= 0 then
			hum.JumpHeight = 7.2
		end
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end)
end)

function F.refreshUI()
	local w = F.w
	if not w then return end
	if w.farmBtn then w.farmBtn.set(F.farm) end
	if w.buildBtn then w.buildBtn.set(F.build) end
end
local function farmPrep()
	ensureControls()
	F.standH = nil
	F.retreating = false
	if followOn then stopFollow(); setFollowUI() end
	if tweenMode then tweenMode = false; stopTween(); setTweenUI() end
	F.scanNow = true
end
function F.toggleFarm()
	F.farm = not F.farm
	if F.farm then farmPrep() end
	if not (F.farm or F.build) then F.cur = nil end
	F.refreshUI()
end
function F.toggleBuild()
	F.build = not F.build
	if F.build then farmPrep() end
	if not (F.farm or F.build) then F.cur = nil end
	F.refreshUI()
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
	-- Modal chỉ cần cho máy có chuột; trên điện thoại Modal làm MẤT nút di chuyển nên không bật
	ui.modal.Modal = v and not isTouchOnly()
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
					if tweenMode and not followOn then
						startTween()
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
	local old = parent:FindFirstChild("UZEXHubUI")
	if old then pcall(function() old:Destroy() end) end

	-- Kích thước bảng tự co theo màn hình (điện thoại nằm ngang ~ 390px cao)
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 400)
	local W = math.clamp(math.floor(vp.X * 0.9), 320, 520)
	local H = math.clamp(math.floor(vp.Y * 0.88), 260, 350)
	local hasKeys = UserInputService.KeyboardEnabled
	local LW = 0.4 -- độ rộng cột trái (danh sách người chơi)

	local gui = make("ScreenGui", {
		Name = "UZEXHubUI", ResetOnSpawn = false, DisplayOrder = 999999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
	}, parent)

	-- Nút logo mở/đóng bảng
	local launcher = makeLogo(gui, 36, { Position = savedLauncherPos or UDim2.new(0, 12, 0.5, -18) })
	if not launcher:GetAttribute("img") then make("UIStroke", { Color = C.white, Thickness = 1.5, Transparency = 0.7 }, launcher) end
	local lscale = make("UIScale", {}, launcher)
	local hit = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 10 }, launcher)
	-- Kéo logo đi chỗ khác (kéo > 15px thì không tính là bấm mở bảng)
	do
		if launcherConn then launcherConn:Disconnect(); launcherConn = nil end
		local ld, lStart, lPos = false, nil, nil
		hit.InputBegan:Connect(function(input)
			if isPointer(input) then
				ld, lStart, lPos = true, input.Position, launcher.Position
				UI.ldMoved = false -- lần bấm mới: chưa kéo
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						ld = false
						UI.ldEnd = os.clock()
					end
				end)
			end
		end)
		launcherConn = UserInputService.InputChanged:Connect(function(input)
			if ld and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - lStart
				if d.Magnitude > 8 then UI.ldMoved = true end -- đã kéo: thả tay ra KHÔNG được tính là bấm mở/đóng bảng
				local pos = UDim2.new(lPos.X.Scale, lPos.X.Offset + d.X, lPos.Y.Scale, lPos.Y.Offset + d.Y)
				launcher.Position = pos
				savedLauncherPos = pos
			end
		end)
	end
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
		Text = "UZEX Hub", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.text,
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

	-- Thanh tab: Dịch chuyển / Skill / Khác
	local TOP = 90
	local TABS = { "Dịch chuyển", "Skill", "Khác", "Farm" }
	local tabBar = make("Frame", { Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, frame)
	make("Frame", { Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.stroke, BorderSizePixel = 0 }, frame)
	local pages, tabBtns = {}, {}
	for i = 1, #TABS do
		pages[i] = make("Frame", {
			Position = UDim2.fromOffset(0, TOP + 2), Size = UDim2.new(1, 0, 1, -(TOP + 2)),
			BackgroundTransparency = 1, Visible = (X.tab == i),
		}, frame)
	end
	local function selectTab(i)
		X.tab = i
		for k = 1, #TABS do
			pages[k].Visible = (k == i)
			tw(tabBtns[k], 0.15, { BackgroundColor3 = (k == i) and C.accent or C.row, TextColor3 = (k == i) and C.white or C.muted })
		end
	end
	for i = 1, #TABS do
		local b = make("TextButton", {
			Position = UDim2.new((i - 1) / #TABS, 6, 0, 4), Size = UDim2.new(1 / #TABS, -10, 0, 28),
			BackgroundColor3 = (X.tab == i) and C.accent or C.row, Text = TABS[i], Font = Enum.Font.GothamBold, TextSize = 11,
			TextColor3 = (X.tab == i) and C.white or C.muted, AutoButtonColor = false,
		}, tabBar)
		round(b, 8)
		tabBtns[i] = b
		tap(b, function() selectTab(i) end)
	end

	-- ===== TAB 1: Dịch chuyển =====
	local searchBox = make("TextBox", {
		Size = UDim2.new(LW, -14, 0, 32), Position = UDim2.fromOffset(10, 4), BackgroundColor3 = C.row,
		Text = filterText, PlaceholderText = "Tìm người chơi...", Font = Enum.Font.Gotham, TextSize = 13,
		TextColor3 = C.text, PlaceholderColor3 = C.muted, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
	}, pages[1])
	round(searchBox, 9)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8) }, searchBox)
	local searchStroke = make("UIStroke", { Color = C.stroke, Thickness = 1 }, searchBox)
	searchBox.Focused:Connect(function() tw(searchStroke, 0.15, { Color = C.accent }) end)
	searchBox.FocusLost:Connect(function() tw(searchStroke, 0.2, { Color = C.stroke }) end)

	local list = make("ScrollingFrame", {
		Size = UDim2.new(LW, -14, 1, -44), Position = UDim2.fromOffset(10, 42), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.stroke,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, pages[1])
	make("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	make("UIPadding", { PaddingRight = UDim.new(0, 5) }, list)

	local function mkCtrl(par, pos, size)
		local c = make("ScrollingFrame", {
			Size = size, Position = pos, BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = C.stroke,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, par)
		make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, c)
		make("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10) }, c)
		return c
	end
	local ctrl = mkCtrl(pages[1], UDim2.new(LW, 4, 0, 4), UDim2.new(1 - LW, -14, 1, -4))

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

	local function mkToggle(order, text, key)
		local row = mkRow(order, text, (hasKeys and key) and 98 or 70)
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

	local function mkPill(row, text)
		local pill = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(96, 24),
			BackgroundColor3 = C.panel, Text = text, Font = Enum.Font.GothamBold, TextSize = 12,
			TextColor3 = C.muted, TextScaled = true,
		}, row)
		round(pill, 8)
		make("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 8 }, pill)
		make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, pill)
		return pill
	end

	local function mkInputRow(order, text, init, placeholder)
		local row = make("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.row, LayoutOrder = order }, ctrl)
		round(row, 10)
		local lbl = make("TextLabel", {
			Size = UDim2.new(1, -110, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1,
			Text = text, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text, TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		make("UITextSizeConstraint", { MaxTextSize = 13, MinTextSize = 8 }, lbl)
		local box = make("TextBox", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(96, 26),
			BackgroundColor3 = C.panel, Text = init, PlaceholderText = placeholder,
			Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.text, PlaceholderColor3 = C.muted, ClearTextOnFocus = false,
		}, row)
		round(box, 8)
		local stroke = make("UIStroke", { Color = C.panel, Thickness = 1 }, box)
		box.Focused:Connect(function() tw(stroke, 0.15, { Color = C.accent }) end)
		return row, box, stroke
	end

	-- Hàng thanh trượt: kéo để chỉnh, hoặc gõ số vào ô bên phải
	local function mkSliderRow(order, text, minV, maxV, init, onChange, step)
		local scroller = ctrl
		local row = make("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.row, LayoutOrder = order }, ctrl)
		round(row, 10)
		make("TextLabel", {
			Size = UDim2.new(1, -90, 0, 24), Position = UDim2.fromOffset(12, 4), BackgroundTransparency = 1,
			Text = text, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		local box = make("TextBox", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 5), Size = UDim2.fromOffset(62, 24),
			BackgroundColor3 = C.panel, Text = tostring(init), Font = Enum.Font.GothamBold, TextSize = 12,
			TextColor3 = C.text, ClearTextOnFocus = false,
		}, row)
		round(box, 8)
		local track = make("Frame", { Position = UDim2.new(0, 14, 0, 41), Size = UDim2.new(1, -28, 0, 6), BackgroundColor3 = C.panel, BorderSizePixel = 0 }, row)
		round(track, 3)
		local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.accent, BorderSizePixel = 0 }, track)
		round(fill, 3)
		local knob = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = C.white, BorderSizePixel = 0, ZIndex = 3,
		}, track)
		round(knob, 9)
		local hit = make("TextButton", {
			Position = UDim2.new(0, 4, 0, 30), Size = UDim2.new(1, -8, 0, 26), BackgroundTransparency = 1, Text = "", ZIndex = 5,
		}, row)
		step = step or 1
		local function setValue(v, fire)
			v = math.clamp(math.floor(v / step + 0.5) * step, minV, maxV)
			v = tonumber(string.format("%.3f", v))
			local a = (v - minV) / (maxV - minV)
			fill.Size = UDim2.fromScale(a, 1)
			knob.Position = UDim2.fromScale(a, 0.5)
			box.Text = tostring(v)
			if fire then onChange(v) end
		end
		local dragging = false
		local function fromX(x)
			local w = math.max(1, track.AbsoluteSize.X)
			setValue(minV + math.clamp((x - track.AbsolutePosition.X) / w, 0, 1) * (maxV - minV), true)
		end
		local function stop()
			dragging = false
			if scroller then scroller.ScrollingEnabled = true end
		end
		hit.InputBegan:Connect(function(input)
			if isPointer(input) then
				dragging = true
				if scroller then scroller.ScrollingEnabled = false end -- kéo thanh trượt không làm cuộn trang
				fromX(input.Position.X)
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then stop() end
				end)
			end
		end)
		local conn = UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				fromX(input.Position.X)
			end
		end)
		gui.Destroying:Connect(function() conn:Disconnect() end)
		box.FocusLost:Connect(function()
			local n = tonumber(box.Text)
			if n then setValue(n, true) else setValue(init, false) end
		end)
		setValue(init, false)
		return row, setValue
	end

	mkSection(1, "DỊCH CHUYỂN")
	local autoRow, autoBtn = mkToggle(2, "Teleport player", "K")
	local tweenRow, tweenBtn = mkToggle(4, "Tween player", "T")

	-- ===== TAB 2: Skill =====
	ctrl = mkCtrl(pages[2], UDim2.fromOffset(10, 4), UDim2.new(1, -20, 1, -4))
	mkSection(1, "AUTO SKILL")
	local skillAutoRow, skillAutoBtn = mkToggle(2, "Auto skill (bật/tắt)", nil)
	local modeRow = mkRow(3, "Kiểu bấm skill", 110)
	local modePill = mkPill(modeRow, X.modes[X.mode])
	modePill.TextColor3 = C.accent2
	local _, ivBox, ivStroke = mkInputRow(4, "Chờ giữa các lượt (giây)", tostring(X.interval), "0.3")
	mkSection(5, "CHỌN SKILL (bấm để chọn / bỏ)")
	local grid = make("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 6 }, ctrl)
	make("UIGridLayout", {
		CellSize = UDim2.new(0.25, -5, 0, 36), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	local chips = {}
	for i, s in ipairs(X.skills) do
		local b = make("TextButton", {
			BackgroundColor3 = C.row, Text = s[1], Font = Enum.Font.GothamBold, TextSize = 15,
			TextColor3 = C.muted, AutoButtonColor = false, LayoutOrder = i,
		}, grid)
		round(b, 9)
		local st = make("UIStroke", { Color = C.accent, Thickness = 1.5, Transparency = 1 }, b)
		chips[i] = { set = function(on)
			tw(b, 0.15, { BackgroundColor3 = on and C.sel or C.row, TextColor3 = on and C.white or C.muted })
			tw(st, 0.15, { Transparency = on and 0 or 1 })
		end }
		tap(b, function() X.toggleSkill(i) end)
	end
	local allRow = mkRow(7, "Chọn tất cả / Bỏ chọn tất cả", 12)
	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 8, TextWrapped = true,
		Text = "Kiểu \"Phím\": gửi phím 1-5, V, P. Nếu không ăn thì đổi sang \"Nút UI\" (bấm thẳng vào ô skill).",
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left,
	}, ctrl)

	-- ===== TAB 3: Khác =====
	ctrl = mkCtrl(pages[3], UDim2.fromOffset(10, 4), UDim2.new(1, -20, 1, -4))
	mkSection(1, "HỒI SINH")
	local respawnRow, respawnBtn = mkToggle(2, "Auto hồi sinh", "J")
	local mapRow = mkRow(3, "Map hồi sinh", 110)
	local mapPill = mkPill(mapRow, "Mặc định")
	local mapBtn = { set = function(name)
		mapPill.Text = name or "Mặc định"
		tw(mapPill, 0.2, { TextColor3 = name and C.accent2 or C.muted })
	end }
	mkSection(4, "KHÁC")
	local noclipRow, noclipBtn = mkToggle(5, "Noclip", "N")
	local afkRow, afkBtn = mkToggle(6, "Anti AFK", "U")
	local lagRow, lagBtn = mkToggle(7, "Fast Mode", nil)
	local _, speedBox, speedStroke = mkInputRow(8, "Tốc độ chạy", customSpeed > 0 and tostring(customSpeed) or "", "mặc định")

	if hasKeys then
		make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "RightShift: ẩn / hiện bảng",
			Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.muted, LayoutOrder = 9,
		}, ctrl)
	end

	-- ===== TAB 4: Farm =====
	ctrl = mkCtrl(pages[4], UDim2.fromOffset(10, 4), UDim2.new(1, -20, 1, -4))
	mkSection(1, "AUTO FARM MOB")
	local farmRow, farmBtn = mkToggle(2, "Auto Farm Mob", "F")
	mkSliderRow(3, "Target Distance", 5, 100, F.mobDist, function(v) F.mobDist = v end)
	mkSliderRow(4, "Tween Speed", 20, 400, F.mobSpeed, function(v) F.mobSpeed = v end)
	mkSliderRow(5, "Orbit Speed", 0, 5, F.orbitSpeed, function(v) F.orbitSpeed = v end, 0.01)
	mkSliderRow(6, "Retarget Delay", 0, 2, F.retargetDelay, function(v) F.retargetDelay = v end, 0.05)
	mkSliderRow(7, "Mob Search Range", 100, 2000, F.mobRange, function(v) F.mobRange = v end)
	mkSliderRow(8, "Retreat HP % (0 = tắt)", 0, 80, F.retreatPct, function(v) F.retreatPct = v end)
	mkSection(9, "AUTO FARM CITY")
	local buildRow, buildBtn = mkToggle(10, "Auto Farm City", "B")
	mkSliderRow(11, "Building Search Range", 50, 1000, F.range, function(v) F.range = v end)
	mkSliderRow(12, "Density Area Size", 50, 600, F.densityR, function(v) F.densityR = v end)
	local _, distBox, distStroke = mkInputRow(13, "Khoảng cách đứng City", tostring(F.dist), "30")
	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 72), BackgroundTransparency = 1, LayoutOrder = 14, TextWrapped = true,
		Text = "Farm Mob: bay tới mob, quay quanh mob (Orbit). Mob Search Range = chỉ đánh mob trong tầm này (tránh bay sang đảo khác). Retreat HP = máu thấp hơn mức này thì bay lên cao hồi máu rồi đánh tiếp. Retarget Delay = nghỉ bao lâu trước khi đổi mob. Farm City: teleport tới City trên đảo đang đứng; Search Range = tầm tìm City, Density Area Size = chọn khu nhiều City nhất. Cả hai dùng skill đã chọn ở tab Skill + đánh thường.",
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left,
	}, ctrl)

	-- Nút ẩn dùng để bật Modal (mở khoá con trỏ chuột khi bảng đang hiện)
	local modal = make("TextButton", { Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "", Modal = uiVisible and not isTouchOnly() }, frame)

	ui = { gui = gui, frame = frame, scale = scale, list = list, autoBtn = autoBtn, respawnBtn = respawnBtn,
		noclipBtn = noclipBtn, tweenBtn = tweenBtn, afkBtn = afkBtn, mapBtn = mapBtn,
		sub = sub, modal = modal, rows = {}, rowMap = {} }
	X.w = { autoBtn = skillAutoBtn, lagBtn = lagBtn, modePill = modePill, chips = chips }

	F.w = { farmBtn = farmBtn, buildBtn = buildBtn }
	tap(farmRow, function() F.toggleFarm() end)
	tap(buildRow, function() F.toggleBuild() end)
	distBox.FocusLost:Connect(function()
		local n = tonumber(distBox.Text)
		if n then F.dist = math.clamp(n, 5, 300) end
		distBox.Text = tostring(F.dist)
	end)
	tap(skillAutoRow, X.toggleAuto)
	tap(modeRow, X.cycleMode)
	tap(allRow, X.allSkills)
	tap(lagRow, X.toggleLag)
	ivBox.FocusLost:Connect(function()
		tw(ivStroke, 0.2, { Color = C.panel })
		local n = tonumber(ivBox.Text)
		if n then X.interval = math.clamp(n, 0.05, 10) end
		ivBox.Text = tostring(X.interval)
	end)

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

	tap(hit, function()
		-- kéo logo (kể cả kéo siêu nhanh) rồi thả tay thì bỏ qua, chỉ chạm nhẹ mới mở/đóng bảng
		if UI.ldMoved then UI.ldMoved = false; return end
		setVisible(not uiVisible)
	end)
	tap(closeBtn, function() setVisible(false) end)
	tap(autoRow, toggleFollow)
	tap(respawnRow, toggleRespawn)
	tap(noclipRow, toggleNoclip)
	tap(tweenRow, toggleTweenMode)
	tap(afkRow, toggleAntiAfk)
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
	setTweenUI()
	setAntiAfkUI()
	setMapUI()
	setStatus(nil)
	X.refreshUI()
	if F.refreshUI then F.refreshUI() end
end

-- ===== Sự kiện =====
Players.PlayerAdded:Connect(function() rebuildList() end)
Players.PlayerRemoving:Connect(function(plr)
	lastKnownCF[plr] = nil
	lastKnownVel[plr] = nil
	lastKnownT[plr] = nil
	if selectedPlayer == plr then
		selectedPlayer = nil
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
	elseif input.KeyCode == ANTIAFK_KEY then
		toggleAntiAfk()
	elseif input.KeyCode == TWEEN_KEY then
		toggleTweenMode()
	elseif input.KeyCode == Enum.KeyCode.F then
		F.toggleFarm()
	elseif input.KeyCode == Enum.KeyCode.B then
		F.toggleBuild()
	end
end)

buildUI()

-- Vòng auto hồi sinh:
--  • Chưa chọn map (Mặc định): thấy nút RESPAWN thì bấm RESPAWN, KHÔNG bấm MENU
--  • Đã chọn map: MENU -> Play -> chọn map -> SPAWN
task.spawn(function()
	while true do
		task.wait((respawnOn and mapIdx > 0) and 0.3 or 0.5)
		if respawnOn then
			if mapIdx > 0 and respawnNames then
				pcall(mapRespawnStep, respawnNames)
			else
				local ok, btn = pcall(findRespawnButton)
				if ok and btn then
					press("default", btn)
					task.wait(0.8) -- chờ game hồi sinh rồi mới kiểm tra tiếp
				end
				pcall(setStatus, nil)
			end
		else
			pcall(setStatus, nil)
		end
	end
end)

-- Chẩn đoán: khi bật Bám theo / Đi bộ / Bay mà chưa chạy được thì ghi rõ lý do lên bảng
task.spawn(function()
	while true do
		task.wait(0.5)
		local msg = nil
		if (followOn or tweenMode) and selectedPlayer and selectedPlayer.Parent == Players then
			local char = player.Character
			local root = rootOf(char)
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not root then
				msg = "Không thấy nhân vật của mình"
			elseif hum and hum.Health <= 0 then
				msg = "Đang chết, chờ hồi sinh"
			elseif not playerCF(selectedPlayer) then
				if lastKnownCF[selectedPlayer] then
					msg = selectedPlayer.DisplayName .. " ở xa/chưa tải: đang bay tới vị trí cuối"
				else
					msg = "Chưa thấy nhân vật của " .. selectedPlayer.DisplayName .. " (khác map / chưa tải)"
				end
			end
		end
		if not msg and (F.farm or F.build) and rootOf(player.Character) then
			if F.cur and F.cur.Parent then
				local rt = rootOf(player.Character)
				local tp = targetPos(F.cur, F.curKind == "enemy")
				local dd = (rt and tp) and math.floor((rt.Position - tp).Magnitude) or 0
				msg = (F.curKind == "enemy" and "Đang đánh mob: " or "Đang farm City: ") .. F.cur.Name .. " (" .. dd .. " stud)"
			else
				msg = (F.build and F.noIsland and not F.farm) and "Không có City nào ở đảo này" or "Đang tìm mục tiêu..."
			end
		end
		if not msg and tpNote and os.clock() < tpNote.t then msg = tpNote.msg end
		diagMsg = msg
		pcall(setStatus, nil)
	end
end)

-- Ghi nhớ vị trí mọi người chơi đang thấy được (để còn biết đường tới khi họ ở xa bị game unload)
task.spawn(function()
	while true do
		task.wait(1)
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
