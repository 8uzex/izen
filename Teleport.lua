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

local dragConn = nil         -- kết nối kéo bảng (huỷ khi dựng lại UI)
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
	if os.clock() - (modelScanT[plr] or 0) < 1.5 then return nil end
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

local function teleportToPlayer(plr)
	local cf = targetCF(plr)
	local root = myRoot()
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
		local root = rootOf(char)
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if cf and root and (not hum or hum.Health > 0) then
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
	if noclipOn or tweening then
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
	elseif key == "defeated" or key:find("eliminatedby", 1, true) then
		r.defeated = true
	elseif key == "menu" or (#key <= 10 and key:sub(1, 4) == "menu") then
		r.menu = r.menu or clickableOf(o, pg)
	elseif #key <= 20 and key:sub(1, 7) == "respawn" then
		r.death = r.death or clickableOf(o, pg)
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

local mapClickedAt = 0
local function mapRespawnStep(names)
	local ok, r = pcall(scanScreens, names)
	if not (ok and r) then return end
	local function yn(v) return v and "Y" or "N" end
	local flags = "map=" .. yn(r.map) .. " spawn=" .. yn(r.respawn) .. " dead=" .. yn(r.death) .. " play=" .. yn(r.play) .. " menu=" .. yn(r.menu) .. " defeated=" .. yn(r.defeated)
	if r.map then
		-- Thấy map là chọn luôn (không cần chờ nút SPAWN). Có SPAWN thì bấm tiếp sau khi chọn map.
		if os.clock() - mapClickedAt > 4 then
			setStatus("Chọn map " .. tostring(respawnMap) .. ": " .. flags)
			clickOnce(r.map)
			mapClickedAt = os.clock()
			task.wait(0.7)
		elseif r.respawn then
			setStatus("SPAWN " .. tostring(respawnMap) .. ": " .. flags)
			local ok3, r3 = pcall(scanScreens, names)
			clickOnce((ok3 and r3 and r3.respawn) or r.respawn)
			task.wait(1)
		else
			task.wait(0.3)
		end
	elseif r.play then
		mapClickedAt = 0
		setStatus("Bấm Play: " .. flags)
		press("play", r.play)
		task.wait(0.5)
	elseif r.menu and (r.death or r.respawn or r.defeated or (function()
			local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			return h and h.Health <= 0
		end)()) then
		mapClickedAt = 0
		setStatus("Bấm MENU: " .. flags)
		press("menu", r.menu)
		task.wait(0.6)
	else
		setStatus("Đang chờ: " .. flags)
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
	if not launcher:GetAttribute("img") then make("UIStroke", { Color = C.white, Thickness = 1.5, Transparency = 0.7 }, launcher) end
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
		noclipBtn = noclipBtn, tweenBtn = tweenBtn, afkBtn = afkBtn, mapBtn = mapBtn,
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
	end
end)

buildUI()

-- Vòng auto hồi sinh:
--  • Chưa chọn map (Mặc định): thấy nút RESPAWN thì bấm RESPAWN, KHÔNG bấm MENU
--  • Đã chọn map: MENU -> Play -> chọn map -> SPAWN
task.spawn(function()
	while true do
		task.wait(0.25)
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
		diagMsg = msg
		pcall(setStatus, nil)
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
