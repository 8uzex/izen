--[[
          __      __      __      __      __      __
     ____/  \____/  \____/  \____/  \____/  \____
   /  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  \
  /   Uzex Guard | FAST Protection | Build f454e1b52475
 /    https://uzex.izen-ws.workers.dev/uzexhub/
 \  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  /
  \____  ____  ____  ____  ____  ____  ____  ____  ____/
       \/    \/    \/    \/    \/    \/    \/
]]
local _W={SecretKey="2009",HubName="UZEX Hub"}
pcall(function()local _F=(type(getgenv)=="function"and getgenv())or getfenv(0)
local function _m(_j,_k)if _F[_j]==nil and _k~=nil then _F[_j]=_k
end
end
_m("request",http_request or(syn and syn.request)or(fluxus and fluxus.request)or(http and http.request))
_m("http_request",request)
_m("setclipboard",toclipboard or(Clipboard and Clipboard.set)or set_clipboard)
_m("queue_on_teleport",queueonteleport or(syn and syn.queue_on_teleport)or(fluxus and fluxus.queue_on_teleport))
if _F.firesignal==nil and type(getconnections)=="function"then _F.firesignal=function(_J,...)for _D,_S in ipairs(getconnections(_J))do if _S.Fire then _S:Fire(...)
elseif _S.Function then task.spawn(_S.Function,...)
end
end
end
end
if _F.fireproximityprompt==nil then _F.fireproximityprompt=function(_I)if _I and _I:IsA("ProximityPrompt")then _I:InputHoldBegin()
task.wait((_I.HoldDuration or 0)+0.05)
_I:InputHoldEnd()
end
end
end
local _i=(type(identifyexecutor)=="function"and select(1,identifyexecutor()))or"Unknown"
print(("[Uzex] Executor: %s | file=%s | getconnections=%s | request=%s"):format(tostring(_i),tostring(type(writefile)=="function"),tostring(type(getconnections)=="function"),tostring(type(_F.request)=="function")))
end)
print(_W.HubName.." Loaded Successfully!")
local _hz=(function()local _P={}
local _q=game:GetService("TweenService")
local _T=game:GetService("UserInputService")
local _A=game:GetService("Players")
local _f={Bg=Color3.fromRGB(12,12,12),Sidebar=Color3.fromRGB(8,8,8),Element=Color3.fromRGB(24,24,24),ElementHover=Color3.fromRGB(36,36,36),Accent=Color3.fromRGB(255,255,255),OnAccent=Color3.fromRGB(10,10,10),Text=Color3.fromRGB(240,240,240),SubText=Color3.fromRGB(140,140,140),Stroke=Color3.fromRGB(50,50,50),}
local _R=_P
_R.Language="English"
_R._TextObjects=setmetatable({},{__mode="k"})
local _x={["Hop thời tiết"]="Weather Hop",["Tự động chuyển server tìm thời tiết"]="Auto Hop Weather",["Chọn thời tiết"]="Select Weather",["Độ trễ chuyển server"]="Hop Delay",["Job ID"]="Job ID",["Nhập Job ID..."]="Enter Job ID...",["Vào server theo Job ID"]="Join Job ID",["Sao chép Job ID hiện tại"]="Copy Current Job ID",["Sự kiện giới hạn"]="Limited Event",["Tự động đưa cá"]="Auto Give Fish",["Chọn cá boss"]="Select Boss Fish",["Tự dịch chuyển tới NPC"]="Auto Teleport to NPC",["UZEX Hub"]="UZEX Hub",["Trang chủ"]="Home",["Chính"]="Main",["Dịch chuyển"]="Teleport",["Cửa hàng"]="Shop",["Nâng cấp"]="Upgrade",["Khác"]="Misc",["Cài đặt"]="Settings",["Bán cá"]="Sell Fish",["Tự động bán cá"]="Auto Sell Fish",["Cách bán cá #1"]="Sell Method #1",["Nhiệm vụ vé tự động"]="Auto Ticket Quest",["Tự nhận vé nhiệm vụ"]="Auto Claim Quest Tickets",["Chế độ nhiệm vụ"]="Quest Mode",["Chung"]="General",["Di chuyển"]="Movement",["Tốc độ đi bộ"]="Walk Speed",["Tốc độ"]="Speed",["Tốc độ bay"]="Fly Speed",["Đi xuyên vật thể"]="Noclip",["Nhảy vô hạn"]="Infinite Jump",["Đảo"]="Islands",["Chọn đảo"]="Select Island",["Dịch chuyển đến đảo"]="Teleport to Island",["NPC"]="NPCs",["Chọn NPC"]="Select NPC",["Dịch chuyển đến NPC"]="Teleport to NPC",["Người chơi"]="Players",["Chọn người chơi"]="Select Player",["Dịch chuyển đến người chơi"]="Teleport to Player",["Mua mồi"]="Buy Bait",["Chọn mồi"]="Select Bait",["Số lượng mua"]="Purchase Amount",["Độ trễ mua (phút)"]="Purchase Delay (minutes)",["Tự động mua mồi"]="Auto Buy Bait",["Chế tạo mồi"]="Craft Bait",["Số lượng chế tạo"]="Craft Amount",["Tự động chế tạo mồi"]="Auto Craft Bait",["Chế tạo cần câu"]="Craft Rod",["Chọn cần câu"]="Select Rod",["Tự động chế tạo cần câu"]="Auto Craft Rod",["ESP người chơi"]="Player ESP",["Nâng cấp nhân vật"]="Character Upgrade",["Chọn 2 mục nâng cấp"]="Select 2 Upgrade Stats",["Phương thức nâng cấp"]="Upgrade Method",["Tự động tái sinh"]="Auto Rebirth",["Kiểm tra tài nguyên"]="Check Resources",["Hiển thị"]="Visuals",["Chống AFK"]="Anti-AFK",["Chống quản trị viên"]="Anti-Admin",["Tăng sáng tối đa"]="Full Bright",["Tắt sương mù"]="Disable Fog",["Chế độ hiệu năng"]="Performance Mode",["Bật thông báo"]="Enable Notifications",["Thông báo"]="Notification",["Đã bật thông báo"]="Notifications enabled",["Câu cá"]="Fishing",["Khóa thanh bắt cá"]="Lock Catch Bar",["Tự động thả câu"]="Auto Cast",["Tự động câu cá Boss"]="Auto Farm Boss",["Tự động câu cá Secret Boss"]="Auto Farm Secret Boss",["Kích hoạt Secret Boss"]="Secret Boss Activation",["Chuyển server"]="Server Hop",["Tự động kiểm tra trạng thái"]="Auto Check Status",["Tự động chuyển server tìm God Spirit"]="Auto Hop to God Spirit Server",["Tự động chuyển server tìm Maoshan"]="Auto Hop to Maoshan Server",["Tự động chuyển server tìm Taoist"]="Auto Hop to Taoist Server",["Chuyển server ngay (God Spirit)"]="Hop Now (God Spirit)",["Chuyển server ngay (Maoshan)"]="Hop Now (Maoshan)",["Chuyển server ngay (Taoist)"]="Hop Now (Taoist)",["Tìm cá"]="Search Fish",["Kiểm tra thời tiết hiện tại"]="Check Current Weather",["Cá yêu thích"]="Favourite Fish",["Chọn cá"]="Select Fish",["Tự động yêu thích cá đã chọn"]="Auto Favourite Selected Fish",["Tự động bỏ qua cá"]="Auto Skip Fish",["Cá cần bỏ qua"]="Fishes to Skip",["Tự động bỏ qua cá đã chọn"]="Auto Skip Selected Fish",["Black Tortoise Bloodline - vùng an toàn"]="Black Tortoise Bloodline - Safe Band",["Cách thả câu"]="Cast Method",["Độ trễ thả câu"]="Cast Delay",["Tự trang bị mồi tốt nhất"]="Auto Equip Best Bait",["Tự trang bị cần câu"]="Auto Equip Rod",["Kỹ năng"]="Skills",["Tự động dùng kỹ năng"]="Auto Use Skills",["Chọn kỹ năng"]="Select Skills",["Boss"]="Boss",["Chọn chế độ Boss"]="Select Boss Mode",["Tự động Enzo"]="Auto Enzo",["Tự động Long DiaoHai"]="Auto Long DiaoHai",["Tự động chơi mini game"]="Auto Play Minigame",["Vị trí"]="Position",["Lưu vị trí"]="Save Position",["Đã lưu vị trí!"]="Position saved!",["Tự dịch chuyển đến vị trí"]="Auto Teleport to Position",["Xóa vị trí"]="Delete Position",["Đã xóa vị trí!"]="Position deleted!",["Mã quà tặng"]="Gift Codes",["Nhập tất cả mã"]="Redeem All Codes",["Menu tiện ích"]="Utility Menu",["Mở nâng cấp kỹ năng"]="Open Skill Upgrade",["Mở học kỹ năng"]="Open Skill Learning",["Mở giao diện trao đổi"]="Open Trade UI",["Mở đặc tính"]="Open Traits",["Phím tắt"]="Hotkeys",["Tắt phím tắt"]="Disable Hotkeys",["Phím bật bay"]="Fly Toggle Key",["Phím bật xuyên vật thể"]="Noclip Toggle Key",["Máy chủ"]="Server",["Vào lại máy chủ"]="Rejoin Server",["Đổi máy chủ ít người"]="Join Low-Population Server",["Tự vào lại"]="Auto Rejoin",["Tự vào lại khi mất kết nối"]="Auto Rejoin on Disconnect",["Thông báo Discord Webhook"]="Discord Webhook Notifications",["Thông báo qua Webhook"]="Webhook Notifications",["Đường dẫn Webhook"]="Webhook URL",["Gửi thử Webhook"]="Test Webhook",["Quyền riêng tư"]="Privacy",["Ẩn ID của tôi (góc trên phải)"]="Hide My ID (top-right)",["ID giả"]="Fake ID",["Số ID giả"]="Fake ID Number",["Ẩn tên"]="Hide Name",["Tên giả"]="Fake Name",["Nội dung tên giả"]="Fake Name Text",["Language / Ngôn ngữ"]="Language / Ngôn ngữ",["Tiếng Việt"]="Tiếng Việt",["English"]="English",["None"]="None",["Không có"]="None",["Bật"]="Enabled",["Tắt"]="Disabled",["Đang tải..."]="Loading...",["Đang tìm máy chủ ít người..."]="Searching for a low-population server...",["Đang tự động kết nối lại..."]="Reconnecting automatically...",["Đã lưu URL Webhook."]="Webhook URL saved.",["Đây không phải liên kết Discord Webhook."]="This is not a Discord Webhook URL.",}
local _w={["Đã ẩn"]="Hidden",["Hãy đặt liên kết script trong autoExecPayload trước."]="Set the script link in autoExecPayload first.",["Nhập tên cá..."]="Enter fish name...",["Bỏ qua cá"]="Skip Fish",["Bộ lọc cá"]="Fish Filter",["Không đọc được sức chứa túi cá, phương thức này sẽ bán cá mỗi 60 giây."]="Could not read fish bag capacity; this method will sell fish every 60 seconds.",["Tự trang bị mồi"]="Auto Equip Bait",["Không tìm thấy mồi trong túi đồ"]="No bait found in inventory",["Dịch chuyển người chơi"]="Teleport Player",["Không tìm được server phù hợp, thử lại sau."]="No suitable server found, try again later.",["Thời tiết"]="Weather",["không có"]="none",["KHÔNG KHỚP"]="NO MATCH",["KHỚP"]="MATCH",["Hãy nhập Job ID hợp lệ."]="Enter a valid Job ID.",["Không vào được server này."]="Could not join this server.",["Nhiệm vụ hàng ngày"]="Daily Quest",["Tự nhận nhiệm vụ hàng ngày"]="Auto Claim Daily Quest",["Tự tương tác với NPC nhiệm vụ hàng ngày và nhận thưởng"]="Automatically interact with the daily quest NPC and claim rewards",["Không tìm thấy NPC Noro Derasu."]="Noro Derasu NPC not found.",["Không đưa được cá cho Noro Derasu, tạm dừng 60 giây."]="Could not give the fish to Noro Derasu, pausing for 60 seconds.",["Tự chạy script"]="Auto Execute",["Tài nguyên"]="Resources",["Không tìm thấy chức năng tái sinh trong game này"]="Rebirth feature not found in this game",["Giao diện tiện ích"]="Utility UI",["Phím thu nhỏ giao diện"]="UI Minimize Key",["Đổi máy chủ"]="Change Server",["Không tìm thấy máy chủ ít người. Đang chuyển đến máy chủ ngẫu nhiên..."]="No low-population server found. Moving to a random server...",["Đang vào lại máy chủ hiện tại..."]="Rejoining the current server...",["Tạm dừng tự vào lại"]="Auto Rejoin Paused",["Đã vào lại quá nhiều lần trong 10 phút. Vui lòng vào lại thủ công."]="Rejoined too many times in 10 minutes. Please rejoin manually.",["Mất kết nối"]="Disconnected",["Báo cáo trạng thái (phút, 0 = tắt)"]="Status Report (minutes, 0 = off)",["Thông báo mỗi lần câu được cá"]="Notify on Every Catch",["Danh sách Server Hop"]="List Server Hop",["Loại sự kiện"]="Event Type",["Mục tiêu thời tiết"]="Weather Target",["Tự động hop server sự kiện đã xác nhận"]="Auto Hop Confirmed Events",["Làm mới danh sách server"]="Refresh Server List",["Chia sẻ sự kiện server của bạn"]="Share Your Server Events",["Đường dẫn Feed"]="Feed URL",["Dán đường dẫn Feed..."]="Paste Feed URL...",}
for _z,_Q in pairs(_w)do if _x[_z]==nil then _x[_z]=_Q
end
end
local _d={{"Gửi cá cho Noro Derasu chưa thành công (","Giving the fish to Noro Derasu was not successful ("},{"Đã dừng tự động chuyển server - ","Auto hop stopped - "},{"! Đã dừng tự động chuyển server.","! Auto hop stopped."},{" hoặc chạm vào logo để mở lại."," or tap the logo to show it again."},{" người chơi! Đang dịch chuyển..."," players! Teleporting..."},{"Tự động chuyển server tìm ","Auto Hop Server to find "},{"Tiếp tục tìm thời tiết: ","Continuing weather search: "},{"Không cầm được cá ở ô ","Could not hold the fish in slot "},{"Phát hiện quản trị viên: ","Admin detected: "},{"Đã tìm thấy máy chủ có ","Found a server with "},{"Đã tìm thấy thời tiết ","Found weather "},{" đã có trong server này!"," is already in this server!"},{". Đang chuyển server...",". Hopping server..."},{" - đang rời máy chủ"," - leaving the server"},{"Đang farm Secret Boss: ","Farming Secret Boss: "},{"Chuyển server ngay (","Hop Now ("},{". Chuyển server sau ",". Hopping server in "},{" không tìm thấy!"," not found!"},{"Đã tìm thấy: ","Found: "},{"Đang vào server ","Joining server "},{" đang ở đây!"," is here!"},{"Đọc được: ","Read: "},{"Đang bỏ qua: ","Skipping: "},{"Đã trang bị ","Equipped "},{"Đã sao chép: ","Copied: "},{"Đã bỏ qua: ","Skipped: "},{"Người chơi ","Player "},{". Mục tiêu: ",". Target: "},{"Không thấy ","Not seeing "},{"Hiện tại: ","Current: "},{"KHÔNG KHỚP","NO MATCH"},{" (bí mật)"," (secret)"},{"Không có ","No "},{"không có","none"},{"Nhấn ","Press "},{"KHỚP","MATCH"},}
for _e,_v in ipairs(_d)do _v[3]=(_v[1]:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]","%%%0"))
_v[4]=(_v[2]:gsub("%%","%%%%"))
end
local function _Y(_E)if type(_E)~="string"then return _E
end
local _u=_R._ReverseTranslations
if not _u then _u={}
for _p,_c in pairs(_x)do if _u[_c]==nil then _u[_c]=_p
end
end
_R._ReverseTranslations=_u
end
local _N=(_R.Language=="English")and _x or _u
local _b=_N[_E]
if _b then return _b
end
local _s=string.upper(_E)
for _X,_t in pairs(_N)do if string.upper(_X)==_s then return string.upper(_t)
end
end
if _R.Language=="English"then local _h=_E
for _L,_r in ipairs(_d)do if string.find(_h,_r[1],1,true)then _h=string.gsub(_h,_r[3],_r[4])
end
end
return _h
end
return _E
end
function _R:SetLanguage(_o)self.Language=(_o=="English")and"English"or"Tiếng Việt"
for _O,_y in pairs(self._TextObjects)do if _O and _O.Parent then _y.updating=true
_O.Text=_Y(_y.source)
task.defer(function()_y.updating=false
end)
else self._TextObjects[_O]=nil
end
end
end
_x["Chạy"]="Run"
_x["Chọn..."]=_x["Chọn..."]or"Select..."
local function _K(_Z)local _C=_Z.Text
if _C==""then return
end
local _n={source=_C,updating=false}
_P._TextObjects[_Z]=_n
_Z:GetPropertyChangedSignal("Text"):Connect(function()if not _n.updating then _n.source=_Z.Text
end
end)
local _M=_Y(_C)
if _M~=_C then _n.updating=true
_Z.Text=_M
task.defer(function()_n.updating=false
end)
end
end
local _B=TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local function _g(_l,_U,_H)local _a=Instance.new(_l)
local _V
for _WM,_FM in pairs(_U or{})do if _WM=="Parent"then _V=_FM
else _a[_WM]=_FM
end
end
for _mM,_jM in ipairs(_H or{})do _jM.Parent=_a
end
if _V then _a.Parent=_V
end
if _l=="TextLabel"or _l=="TextButton"then _K(_a)
elseif _l=="TextBox"and _a.PlaceholderText~=""then _a.PlaceholderText=_Y(_a.PlaceholderText)
end
return _a
end
local function _kM(_JM,_DM)return _g("UICorner",{CornerRadius=UDim.new(0,_DM or 8),Parent=_JM})
end
local function _SM(_IM,_iM,_PM)return _g("UIStroke",{Color=_iM or _f.Stroke,Thickness=_PM or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=_IM,})
end
local _qM=false
local function _TM(_AM,_fM)_kM(_AM,_fM or 9)
if _qM then _AM.BackgroundTransparency=0.25
end
local _RM=_SM(_AM,Color3.fromRGB(255,255,255),1)
_RM.Transparency=0.93
return _RM
end
local function _xM(_wM,_zM,_QM)_q:Create(_wM,_QM or _B,_zM):Play()
end
local function _dM(_eM)_eM.BackgroundTransparency=1
_eM.Font=_eM.Font or Enum.Font.GothamMedium
_eM.TextSize=_eM.TextSize or 13
_eM.TextColor3=_eM.TextColor3 or _f.Text
_eM.TextXAlignment=_eM.TextXAlignment or Enum.TextXAlignment.Left
return _g("TextLabel",_eM)
end
local function _vM(_YM)return _YM.UserInputType==Enum.UserInputType.MouseButton1 or _YM.UserInputType==Enum.UserInputType.Touch
end
local function _EM(_uM)return _uM.UserInputType==Enum.UserInputType.MouseMovement or _uM.UserInputType==Enum.UserInputType.Touch
end
local _pM={}
local function _cM(_NM,_bM)local _sM=_NM:Connect(_bM)
table.insert(_pM,_sM)
return _sM
end
local function _XM(_tM,_hM)local _LM,_rM,_oM
local _OM={moved=false}
_tM.InputBegan:Connect(function(_yM)if _vM(_yM)then _LM,_rM,_oM=true,_yM.Position,_hM.Position
_OM.moved=false
_yM.Changed:Connect(function()if _yM.UserInputState==Enum.UserInputState.End then _LM=false
end
end)
end
end)
_cM(_T.InputChanged,function(_KM)if _LM and _EM(_KM)then local _ZM=_KM.Position-_rM
if _ZM.Magnitude>4 then _OM.moved=true
end
_hM.Position=UDim2.new(_oM.X.Scale,_oM.X.Offset+_ZM.X,_oM.Y.Scale,_oM.Y.Offset+_ZM.Y)
end
end)
return _OM
end
local function _CM()local _nM,_MM=pcall(function()return gethui and gethui()
end)
if _nM and _MM then return _MM
end
_nM,_MM=pcall(function()return game:GetService("CoreGui")
end)
if _nM and _MM then return _MM
end
return _A.LocalPlayer:WaitForChild("PlayerGui")
end
local _GM="uzex_logo_v2.png"
local _BM=[[
iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAWfmNhQlgAABZ+anVtYgAAAB5qdW1kYzJwYQARABCAAACqADibcQNjMnBhAAAAFlhqdW1iAAAA
R2p1bWRjMm1hABEAEIAAAKoAOJtxA3VybjpjMnBhOjhmZWQ0N2I4LTdhZmItNDc1MC1hNDI4LWQxMDY2ZDdiZWM4MQAAAAOTanVtYgAAAClqdW1kYzJhcwAR
ABCAAACqADibcQNjMnBhLmFzc2VydGlvbnMAAAAAuGp1bWIAAABEanVtZGNib3IAEQAQgAAAqgA4m3ETYzJwYS5pbmdyZWRpZW50LnYzAAAAABhjMnNoSQLh
yXJ0ToZ28cLCXQERyQAAAGxjYm9yo2lkYzpmb3JtYXRpaW1hZ2UvcG5namluc3RhbmNlSUR4LHhtcDppaWQ6MzNkMjc5ZmYtYzE0Yy00Zjc3LWExZTQtN2Iy
YWM0ZWRmN2MzbHJlbGF0aW9uc2hpcGhwYXJlbnRPZgAAAeJqdW1iAAAAQWp1bWRjYm9yABEAEIAAAKoAOJtxE2MycGEuYWN0aW9ucy52MgAAAAAYYzJzaPsm
X+5oSSPOaCFV++gUa28AAAGZY2JvcqJnYWN0aW9uc4KiZmFjdGlvbmtjMnBhLm9wZW5lZGpwYXJhbWV0ZXJzoWtpbmdyZWRpZW50c4GiY3VybHgtc2VsZiNq
dW1iZj1jMnBhLmFzc2VydGlvbnMvYzJwYS5pbmdyZWRpZW50LnYzZGhhc2hYINlLO1vOwpmzR1w3pWjqOdPdbjfpwWq+GX5THYbhTc9tpGZhY3Rpb254HWNv
bS5hbnRocm9waWMuY2xhdWRlLnByb3ZpZGVkanBhcmFtZXRlcnOheB9jb20uYW50aHJvcGljLm9yaWdpbi1jb25maWRlbmNlZ3Vua25vd25rZGVzY3JpcHRp
b254ZkNsYXVkZSBwcm92aWRlZCB0aGlzIGZpbGUgYXQgdGhlIHJlcXVlc3Qgb2YgYSB1c2VyIGFuZCBtYXkgaGF2ZSBjcmVhdGVkIG9yIG1vZGlmaWVkIHRo
ZSBmaWxlIGNvbnRlbnRzLm1zb2Z0d2FyZUFnZW50oWRuYW1lZkNsYXVkZXJhbGxBY3Rpb25zSW5jbHVkZWT1AAAAyGp1bWIAAABAanVtZGNib3IAEQAQgAAA
qgA4m3ETYzJwYS5oYXNoLmRhdGEAAAAAGGMyc2jgPYD1GREGdlX9K61Wl4k7AAAAgGNib3KlY2FsZ2ZzaGEyNTZjcGFkTQAAAAAAAAAAAAAAAABkaGFzaFgg
u8qEz/eVIsqSVYj0ND0Dv6lmLBw+oARM2JdtBbH4NWxkbmFtZW5qdW1iZiBtYW5pZmVzdGpleGNsdXNpb25zgaJlc3RhcnQYIWZsZW5ndGgZFooAAAI+anVt
YgAAACdqdW1kYzJjbAARABCAAACqADibcQNjMnBhLmNsYWltLnYyAAAAAg9jYm9ypWNhbGdmc2hhMjU2aXNpZ25hdHVyZXhNc2VsZiNqdW1iZj0vYzJwYS91
cm46YzJwYTo4ZmVkNDdiOC03YWZiLTQ3NTAtYTQyOC1kMTA2NmQ3YmVjODEvYzJwYS5zaWduYXR1cmVqaW5zdGFuY2VJRHgseG1wOmlpZDowNDZhZjNhNS04
MjFiLTQxMzktOWEwMC1lNDZjYWQ0YjU5OGFyY3JlYXRlZF9hc3NlcnRpb25zg6JjdXJseC1zZWxmI2p1bWJmPWMycGEuYXNzZXJ0aW9ucy9jMnBhLmluZ3Jl
ZGllbnQudjNkaGFzaFgg2Us7W87CmbNHXDelaOo5091uN+nBar4ZflMdhuFNz22iY3VybHgqc2VsZiNqdW1iZj1jMnBhLmFzc2VydGlvbnMvYzJwYS5hY3Rp
b25zLnYyZGhhc2hYINNpeLGAwPhH3mi4lxdjlQGFSuAjKXqU6SSAlVkssnBtomN1cmx4KXNlbGYjanVtYmY9YzJwYS5hc3NlcnRpb25zL2MycGEuaGFzaC5k
YXRhZGhhc2hYIIf+H/StsJR3XaaLfCNNQfdTb05vmupSX8gCSs4z3PxBdGNsYWltX2dlbmVyYXRvcl9pbmZvo2RuYW1lb0FudGhyb3BpYyBGaWxlc2d2ZXJz
aW9uZTEuMC4wa3NwZWNWZXJzaW9uZTIuNC4wAAAQOGp1bWIAAAAoanVtZGMyY3MAEQAQgAAAqgA4m3EDYzJwYS5zaWduYXR1cmUAAAAQCGNib3LShFkCEqIB
JhghWQIKMIICBjCCAY2gAwIBAgIUQOWgCu7COdC+uIP6BkIFPWdVEwAwCgYIKoZIzj0EAwMwSTEXMBUGA1UEChMOQW50aHJvcGljLCBQQkMxLjAsBgNVBAMT
JUFudGhyb3BpYyBDb250ZW50IENyZWRlbnRpYWxzIFJvb3QgQ0EwHhcNMjYwODA3MTg0MzU2WhcNMjgwODA2MTk0MzU2WjBEMRcwFQYDVQQKEw5BbnRocm9w
aWMsIFBCQzEpMCcGA1UEAxMgQW50aHJvcGljIENsYXVkZSBDb250ZW50IFNpZ25pbmcwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAASYegpry1AYBRTVNL1C
pTlbROnY3dey+UrsF9C3phYrATN3ZHf93Mo8RQN0KOUuOn19P4oWNFWe5n2/She9N7eTo1gwVjAOBgNVHQ8BAf8EBAMCB4AwFQYDVR0lBA4wDAYKKwYBBAGD
6F4CATAMBgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFM5R4gSBTmRbI/jjxM+aPpzB11zCMAoGCCqGSM49BAMDA2cAMGQCMDFzHRSeAXrSy1WOzkbhPZ6Km2wG
TmZ/2gK18k8BQGXyqz88Rdrz6CTX9flAnYNVxgIwcF9c3fVhqmJKpi+UhasNUMko69cyX6STPfta3Q8EjyzDjzoyrol46FP6VFHhvUcJoWNwYWRZDZ4AAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
]]
local _gM="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function _lM(_UM)_UM=_UM:gsub("[^%w%+/=]","")
local _HM={}
for _aM=1,#_gM do _HM[_gM:sub(_aM,_aM)]=_aM-1
end
local _VM,_Wv={},0
for _Fv=1,#_UM,4 do local _mv,_jv=_UM:sub(_Fv,_Fv),_UM:sub(_Fv+1,_Fv+1)
local _kv,_Jv=_UM:sub(_Fv+2,_Fv+2),_UM:sub(_Fv+3,_Fv+3)
local _Dv=(_HM[_mv]or 0)*262144+(_HM[_jv]or 0)*4096+(_HM[_kv]or 0)*64+(_HM[_Jv]or 0)
local _Sv,_Iv,_iv=math.floor(_Dv/65536)%256,math.floor(_Dv/256)%256,_Dv%256
_Wv=_Wv+1
if _kv=="="then _VM[_Wv]=string.char(_Sv)
elseif _Jv=="="then _VM[_Wv]=string.char(_Sv,_Iv)
else _VM[_Wv]=string.char(_Sv,_Iv,_iv)
end
end
return table.concat(_VM)
end
local function _Pv(_qv)if _qv and _qv~=""then return _qv
end
local _Tv,_Av=pcall(function()if not(isfile and isfile(_GM))then writefile(_GM,_lM(_BM))
end
return getcustomasset(_GM)
end)
if _Tv and _Av and _Av~=""then return _Av
end
return nil
end
local _fv="uzex_bg_v1.jpg"
local _Rv=""
local function _xv(_wv)if type(_wv)=="string"and _wv~=""then if _wv:find("^rbxasset")then return _wv
end
local _zv,_Qv=pcall(function()return getcustomasset(_wv)
end)
return _zv and _Qv or nil
end
return nil
end
function _P:CreateWindow(_dv)_dv=_dv or{}
local _ev=_dv.Name or"UzexUI"
local _vv=_CM()
if _P._current then _P._current:Destroy()
end
local _Yv=_vv:FindFirstChild(_ev)
if _Yv then _Yv:Destroy()
end
local _Ev=_g("ScreenGui",{Name=_ev,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true,Parent=_vv,})
local _uv=_g("Frame",{Name="Main",Size=UDim2.fromOffset(600,390),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ClipsDescendants=true,Parent=_Ev,})
_kM(_uv,14)
_g("UIGradient",{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(22,22,22),Color3.fromRGB(9,9,9)),Parent=_uv,})
local _pv=_SM(_uv,Color3.new(1,1,1),1)
_g("UIGradient",{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.55),NumberSequenceKeypoint.new(1,0.9),}),Parent=_pv,})
local function _cv()local _Nv=workspace.CurrentCamera
if not _Nv then return 1
end
local _bv=_Nv.ViewportSize
return math.clamp(math.min(_bv.X*0.94/600,_bv.Y*0.88/390),0.5,1)
end
local _sv=_g("UIScale",{Scale=0.92*_cv(),Parent=_uv})
local _Xv=_g("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=100,Visible=false,Parent=_uv,})
_kM(_Xv,14)
do local _tv=workspace.CurrentCamera
if _tv then _tv:GetPropertyChangedSignal("ViewportSize"):Connect(function()if _uv.Visible and not _Xv.Visible then _sv.Scale=_cv()
end
end)
end
end
_xM(_sv,{Scale=_cv()},TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out))
_qM=false
local _hv=_xv(_dv.Background)
if _hv then _qM=true
local _Lv=_g("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=_hv,ScaleType=Enum.ScaleType.Crop,Parent=_uv,})
_kM(_Lv,14)
local _rv=_g("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0,BorderSizePixel=0,Parent=_uv,})
_kM(_rv,14)
_g("UIGradient",{Rotation=90,Transparency=NumberSequence.new(0.35,0.6),Parent=_rv})
end
local _ov=_g("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=_f.Sidebar,BorderSizePixel=0,Parent=_uv,})
_kM(_ov,12)
_g("Frame",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-12),BackgroundColor3=_f.Sidebar,BorderSizePixel=0,Parent=_ov,})
_g("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=_f.Stroke,BorderSizePixel=0,Parent=_ov,})
local _Ov=_Pv(_dv.Logo)
_g("Frame",{Size=UDim2.fromOffset(4,16),Position=UDim2.fromOffset(14,12),BackgroundColor3=_f.Accent,BorderSizePixel=0,Parent=_ov,},{_g("UICorner",{CornerRadius=UDim.new(1,0)})})
_dM({Text=_dv.Title or"UZEX Hub",Font=Enum.Font.GothamBold,TextSize=15,Position=UDim2.fromOffset(26,0),Size=UDim2.new(0.5,0,1,0),Parent=_ov,})
_dM({Text=_dv.Subtitle or"",TextSize=12,TextColor3=_f.SubText,TextXAlignment=Enum.TextXAlignment.Right,Position=UDim2.new(0.4,0,0,0),Size=UDim2.new(0.6,-84,1,0),Parent=_ov,})
local function _yv(_Kv,_Zv,_Cv)local _nv=_g("TextButton",{Text=_Kv,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=_f.Text,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,_Zv,0.5,0),Size=UDim2.fromOffset(26,26),BackgroundColor3=_f.Element,AutoButtonColor=false,Parent=_ov,})
_kM(_nv,7)
_nv.MouseEnter:Connect(function()_xM(_nv,{BackgroundColor3=_Cv})
end)
_nv.MouseLeave:Connect(function()_xM(_nv,{BackgroundColor3=_f.Element})
end)
return _nv
end
local _Mv=_yv("×",-10,Color3.fromRGB(220,70,80))
local _Gv=_yv("–",-42,_f.ElementHover)
_XM(_ov,_uv)
local _Bv=_g("ScrollingFrame",{Position=UDim2.fromOffset(0,46),Size=UDim2.new(0,150,1,-92),BackgroundColor3=_f.Sidebar,BorderSizePixel=0,ScrollBarThickness=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=_uv,})
_g("UIListLayout",{Padding=UDim.new(0,6),Parent=_Bv})
_g("UIPadding",{PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,8),Parent=_Bv,})
local _gv=_g("Frame",{Position=UDim2.fromOffset(150,46),Size=UDim2.new(1,-150,1,-46),BackgroundTransparency=1,Parent=_uv,})
local _lv=_g("Frame",{Position=UDim2.new(0,0,1,-46),Size=UDim2.fromOffset(150,46),BackgroundColor3=_f.Sidebar,BorderSizePixel=0,Parent=_uv,})
_kM(_lv,14)
_g("Frame",{Size=UDim2.new(1,0,0,16),BackgroundColor3=_f.Sidebar,BorderSizePixel=0,Parent=_lv,})
_g("Frame",{Size=UDim2.new(0,16,1,0),Position=UDim2.new(1,-16,0,0),BackgroundColor3=_f.Sidebar,BorderSizePixel=0,Parent=_lv,})
_g("Frame",{Size=UDim2.new(1,-16,0,1),Position=UDim2.fromOffset(8,0),BackgroundColor3=_f.Stroke,BorderSizePixel=0,Parent=_lv,})
local _Uv=_A.LocalPlayer
local _Hv=_g("ImageLabel",{Size=UDim2.fromOffset(32,32),AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,12,0.5,1),BackgroundColor3=_f.Element,BorderSizePixel=0,Parent=_lv,})
_kM(_Hv,16)
task.spawn(function()if not _Uv then return
end
local _av,_Vv=pcall(function()return _A:GetUserThumbnailAsync(_Uv.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
end)
if _av and _Hv.Parent then _Hv.Image=_Vv
end
end)
if _qM then _ov.BackgroundTransparency=0.35
for _Wq,_Fq in ipairs(_ov:GetChildren())do if _Fq:IsA("Frame")and _Fq.BackgroundColor3==_f.Sidebar then _Fq.BackgroundTransparency=0.35
end
end
_Bv.BackgroundTransparency=0.45
_lv.BackgroundTransparency=0.45
end
local _mq=_g("Frame",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-14,1,-14),Size=UDim2.fromOffset(250,300),BackgroundTransparency=1,Parent=_Ev,})
_g("UIListLayout",{Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Bottom,HorizontalAlignment=Enum.HorizontalAlignment.Right,SortOrder=Enum.SortOrder.LayoutOrder,Parent=_mq,})
local _jq={Gui=_Ev,Main=_uv,Tabs={},Active=nil,ToggleList={}}
_P._current=_jq
function _jq:Destroy()if _jq.Destroyed then return
end
_jq.Destroyed=true
for _kq,_Jq in ipairs(_jq.ToggleList)do if _Jq.get()and _Jq.cb then task.spawn(_Jq.cb,false)
end
end
for _Dq,_Sq in ipairs(_pM)do pcall(function()_Sq:Disconnect()
end)
end
table.clear(_pM)
if _P._current==_jq then _P._current=nil
end
_Ev:Destroy()
if _dv.OnClose then task.spawn(_dv.OnClose)
end
end
function _jq:Notify(_Iq)if _P.NotificationsEnabled==false then return
end
_Iq=type(_Iq)=="table"and _Iq or{Title=tostring(_Iq)}
local _iq=string.lower(tostring(_Iq.Type or""))
local _Pq=(_iq=="error"and Color3.fromRGB(232,92,92))or(_iq=="warning"and Color3.fromRGB(236,190,80))or(_iq=="success"and Color3.fromRGB(110,200,120))or _f.Accent
local _qq=_Y(tostring(_Iq.Content or""))
local _Tq,_Aq=pcall(function()return game:GetService("TextService"):GetTextSize(_qq,12,Enum.Font.GothamMedium,Vector2.new(246,1000))
end)
local _fq=math.max(16,_Tq and _Aq.Y or 16)
local _Rq=_g("Frame",{Size=UDim2.fromOffset(270,math.max(52,32+_fq+6)),BackgroundColor3=_f.Bg,BackgroundTransparency=1,Parent=_mq,})
_kM(_Rq,9)
local _xq=_SM(_Rq,_Pq)
_xq.Transparency=1
local _wq=_g("Frame",{Size=UDim2.new(0,3,1,-16),Position=UDim2.fromOffset(0,8),BackgroundColor3=_Pq,BackgroundTransparency=1,BorderSizePixel=0,Parent=_Rq,})
local _zq=_dM({Text=_Iq.Title or"Thông báo",Font=Enum.Font.GothamBold,TextSize=13,Position=UDim2.fromOffset(12,7),Size=UDim2.new(1,-24,0,16),TextTransparency=1,Parent=_Rq,})
local _Qq=_dM({Text=_Iq.Content or"",TextSize=12,TextColor3=_f.SubText,Position=UDim2.fromOffset(12,27),Size=UDim2.new(1,-24,0,_fq),TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top,TextTransparency=1,Parent=_Rq,})
_xM(_Rq,{BackgroundTransparency=0.05})
_xM(_wq,{BackgroundTransparency=0})
_xM(_xq,{Transparency=0})
_xM(_zq,{TextTransparency=0})
_xM(_Qq,{TextTransparency=0})
task.delay(_Iq.Duration or 3,function()if not _Rq.Parent then return
end
_xM(_Rq,{BackgroundTransparency=1})
_xM(_wq,{BackgroundTransparency=1})
_xM(_xq,{Transparency=1})
_xM(_zq,{TextTransparency=1})
_xM(_Qq,{TextTransparency=1})
task.wait(0.2)
_Rq:Destroy()
end)
end
local _dq=true
local _eq=0
local _vq=TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
local _Yq=TweenInfo.new(0.14,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
function _jq:Toggle(_Eq)if _Eq==nil then _Eq=not _dq
end
if _Eq==_dq then return
end
_dq=_Eq
_eq=_eq+1
local _uq=_eq
if _Eq then _uv.Visible=true
_sv.Scale=0.8*_cv()
_Xv.BackgroundTransparency=0.4
_Xv.Visible=true
_xM(_sv,{Scale=_cv()},_vq)
_xM(_Xv,{BackgroundTransparency=1},TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out))
task.delay(0.22,function()if _eq==_uq and not _jq.Destroyed then _Xv.Visible=false
end
end)
else if _jq.OpenDD then _jq.OpenDD(true)
end
_Xv.BackgroundTransparency=1
_Xv.Visible=true
_xM(_sv,{Scale=0.8*_cv()},_Yq)
_xM(_Xv,{BackgroundTransparency=0.35},_Yq)
task.delay(0.14,function()if _eq~=_uq or _jq.Destroyed then return
end
_uv.Visible=false
_Xv.Visible=false
_Xv.BackgroundTransparency=1
if _jq.Fab then _jq.Fab.Visible=true
if _jq.FabPop then _jq.FabPop()
end
end
end)
end
end
_Gv.MouseButton1Click:Connect(function()_jq:Toggle(false)
end)
_Mv.MouseButton1Click:Connect(function()if _jq.Destroyed then return
end
_Xv.BackgroundTransparency=1
_Xv.Visible=true
_xM(_sv,{Scale=0.8*_cv()},_Yq)
_xM(_Xv,{BackgroundTransparency=0.35},_Yq)
task.delay(0.14,function()_jq:Destroy()
end)
end)
_jq.ToggleKey=_dv.ToggleKey or Enum.KeyCode.RightShift
_cM(_T.InputBegan,function(_pq,_cq)if not _cq and _pq.KeyCode==_jq.ToggleKey then _jq:Toggle()
end
end)
function _jq:SetKeybind(_Nq)if typeof(_Nq)=="EnumItem"then _jq.ToggleKey=_Nq
end
end
function _jq:SelectTab(_bq)if not _bq or _jq.Active==_bq then return
end
if _jq.Active then _jq.Active.SetActive(false)
end
_jq.Active=_bq
_bq.SetActive(true)
end
do local _sq
if _Ov then _sq=_g("ImageButton",{Size=UDim2.fromOffset(34,34),Position=UDim2.new(0,14,0.5,-17),BackgroundTransparency=1,Image=_Ov,AutoButtonColor=false,Visible=true,Parent=_Ev,})
_kM(_sq,9)
else _sq=_g("TextButton",{Text="U",Font=Enum.Font.GothamBold,TextSize=18,TextColor3=_f.OnAccent,Size=UDim2.fromOffset(40,40),Position=UDim2.new(0,14,0.5,-20),BackgroundColor3=_f.Accent,AutoButtonColor=false,Visible=true,Parent=_Ev,})
_kM(_sq,20)
end
_jq.Fab=_sq
local _Xq=_XM(_sq,_sq)
local _tq=_g("UIScale",{Scale=1,Parent=_sq})
local _hq=_SM(_sq,Color3.new(1,1,1),1.5)
_hq.Transparency=0.8
_xM(_hq,{Transparency=0.15},TweenInfo.new(1.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true))
function _jq.FabPop()_tq.Scale=0
_xM(_tq,{Scale=1},TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out))
end
_sq.MouseEnter:Connect(function()_xM(_tq,{Scale=1.12})
end)
_sq.MouseLeave:Connect(function()_xM(_tq,{Scale=1})
end)
local _Lq
_sq.InputBegan:Connect(function(_rq)if _vM(_rq)then _Lq=_rq.Position
_xM(_tq,{Scale=0.88},TweenInfo.new(0.08))
end
end)
_sq.InputEnded:Connect(function(_oq)if _vM(_oq)then _xM(_tq,{Scale=1},TweenInfo.new(0.15,Enum.EasingStyle.Back,Enum.EasingDirection.Out))
if _Lq and not _Xq.moved and(_oq.Position-_Lq).Magnitude<6 then _jq:Toggle()
end
end
_Lq=nil
end)
end
function _jq:AddTab(_Oq)local _yq={}
local _Kq=_g("TextButton",{Size=UDim2.new(1,0,0,32),BackgroundColor3=_f.Element,Text="",AutoButtonColor=false,Parent=_Bv,})
_kM(_Kq,8)
local _Zq=_dM({Text=_Oq,TextColor3=Color3.fromRGB(140,140,140),Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-16,1,0),Parent=_Kq,})
local _Cq=_g("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=_f.Accent,ScrollBarImageTransparency=0.6,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=_gv,})
_g("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,Parent=_Cq})
_g("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,12),PaddingBottom=UDim.new(0,10),Parent=_Cq,})
_yq.Page=_Cq
_dM({Text=_Oq,Font=Enum.Font.GothamBold,TextSize=18,LayoutOrder=-10,Size=UDim2.new(1,0,0,28),Parent=_Cq,})
local function _nq(_Mq)_Cq.Visible=_Mq
if not _Mq and _jq.OpenDD then _jq.OpenDD(true)
end
_xM(_Kq,{BackgroundColor3=_Mq and _f.Accent or _f.Element})
_xM(_Zq,{TextColor3=_Mq and _f.OnAccent or Color3.fromRGB(140,140,140)})
_Zq.Font=_Mq and Enum.Font.GothamBold or Enum.Font.GothamMedium
end
_yq.SetActive=_nq
_Kq.MouseButton1Click:Connect(function()if _jq.Active==_yq then return
end
if _jq.Active then _jq.Active.SetActive(false)
end
_jq.Active=_yq
_nq(true)
end)
_Kq.MouseEnter:Connect(function()if _jq.Active~=_yq then _xM(_Kq,{BackgroundColor3=_f.ElementHover})
end
end)
_Kq.MouseLeave:Connect(function()if _jq.Active~=_yq then _xM(_Kq,{BackgroundColor3=_f.Element})
end
end)
if not _jq.Active then _jq.Active=_yq
_nq(true)
end
local function _Gq(_Bq)local _gq=_g("Frame",{Size=UDim2.new(1,0,0,_Bq or 36),BackgroundColor3=_f.Element,BorderSizePixel=0,Parent=_Cq,})
_TM(_gq)
return _gq
end
function _yq:AddSection(_lq)local _Uq=_g("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Parent=_Cq})
local _Hq=_g("Frame",{Size=UDim2.fromOffset(5,5),Position=UDim2.new(0,2,0.5,-2),BackgroundColor3=_f.Accent,BorderSizePixel=0,Parent=_Uq,})
_kM(_Hq,3)
_dM({Text=string.upper(_lq),Font=Enum.Font.GothamBold,TextSize=11,TextColor3=_f.SubText,Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-14,1,0),Parent=_Uq,})
end
function _yq:AddLabel(_aq)local _Vq=_Gq(30)
local _WT=_dM({Text=_aq,TextColor3=_f.SubText,TextSize=12,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-24,1,0),Parent=_Vq,})
return{Set=function(_FT,_mT)_WT.Text=_mT
end}
end
function _yq:AddButton(_jT)local _kT=_g("TextButton",{Size=UDim2.new(1,0,0,36),BackgroundColor3=_f.Element,Text="",AutoButtonColor=false,Parent=_Cq,})
_TM(_kT)
_dM({Text=_jT.Name,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-86,1,0),TextTruncate=Enum.TextTruncate.AtEnd,Parent=_kT,})
local _JT=_g("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),Size=UDim2.fromOffset(0,24),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=_f.Accent,BorderSizePixel=0,Parent=_kT,})
_kM(_JT,6)
_g("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),Parent=_JT})
_dM({Text="Chạy",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=_f.OnAccent,Size=UDim2.fromOffset(0,24),AutomaticSize=Enum.AutomaticSize.X,TextXAlignment=Enum.TextXAlignment.Center,Parent=_JT,})
_kT.MouseEnter:Connect(function()_xM(_kT,{BackgroundColor3=_f.ElementHover})
end)
_kT.MouseLeave:Connect(function()_xM(_kT,{BackgroundColor3=_f.Element})
end)
_kT.MouseButton1Click:Connect(function()_xM(_JT,{BackgroundColor3=Color3.fromRGB(190,190,190)})
task.delay(0.12,function()_xM(_JT,{BackgroundColor3=_f.Accent})
end)
if _jT.Callback then task.spawn(_jT.Callback)
end
end)
end
function _yq:AddToggle(_DT)local _ST=_DT.Default==true
local _IT=_g("TextButton",{Size=UDim2.new(1,0,0,36),BackgroundColor3=_f.Element,Text="",AutoButtonColor=false,Parent=_Cq,})
_TM(_IT)
_dM({Text=_DT.Name,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-70,1,0),Parent=_IT,})
local _iT=_g("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),Size=UDim2.fromOffset(36,18),BackgroundColor3=_f.Stroke,BorderSizePixel=0,Parent=_IT,})
_kM(_iT,9)
local _PT=_g("Frame",{Size=UDim2.fromOffset(14,14),Position=UDim2.new(0,2,0.5,-7),BackgroundColor3=_f.Text,BorderSizePixel=0,Parent=_iT,})
_kM(_PT,7)
local function _qT(_TT)local _AT=_ST and UDim2.new(1,-16,0.5,-7)or UDim2.new(0,2,0.5,-7)
local _fT=_ST and _f.Accent or _f.Stroke
local _RT=_ST and _f.OnAccent or _f.Text
if _TT then _xM(_PT,{Position=_AT,BackgroundColor3=_RT})
_xM(_iT,{BackgroundColor3=_fT})
else _PT.Position,_PT.BackgroundColor3,_iT.BackgroundColor3=_AT,_RT,_fT
end
end
_qT(false)
local _xT={}
table.insert(_jq.ToggleList,{get=function()return _ST
end,cb=_DT.Callback})
function _xT:Set(_wT,_zT)_ST=_wT and true or false
_qT(true)
if _zT~=false and _DT.Callback then task.spawn(_DT.Callback,_ST)
end
end
function _xT:Get()return _ST
end
_IT.MouseButton1Click:Connect(function()_xT:Set(not _ST)
end)
_IT.MouseEnter:Connect(function()_xM(_IT,{BackgroundColor3=_f.ElementHover})
end)
_IT.MouseLeave:Connect(function()_xM(_IT,{BackgroundColor3=_f.Element})
end)
if _ST and _DT.Callback then task.spawn(_DT.Callback,_ST)
end
return _xT
end
function _yq:AddSlider(_QT)local _dT,_eT,_vT=_QT.Min or 0,_QT.Max or 100,_QT.Step or 1
local _YT=math.clamp(_QT.Default or _dT,_dT,_eT)
local _ET=tostring(_QT.Suffix or"")
local function _uT(_pT)local _cT=tostring(math.floor(_pT*1000+0.5)/1000)
return _ET~=""and(_cT.." ".._ET)or _cT
end
local _NT=_Gq(36)
_dM({Text=_QT.Name,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-216,1,0),TextTruncate=Enum.TextTruncate.AtEnd,Parent=_NT,})
local _bT=_dM({Text=_uT(_YT),TextColor3=_f.SubText,TextSize=12,TextXAlignment=Enum.TextXAlignment.Right,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-144,0.5,0),Size=UDim2.fromOffset(60,16),Parent=_NT,})
local _sT=_g("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-12,0.5,0),Size=UDim2.fromOffset(120,6),BackgroundColor3=_f.Stroke,BorderSizePixel=0,Parent=_NT,})
_kM(_sT,3)
local _XT=_g("Frame",{Size=UDim2.new((_YT-_dT)/(_eT-_dT),0,1,0),BackgroundColor3=_f.Accent,BorderSizePixel=0,Parent=_sT,})
_kM(_XT,3)
local _tT=_g("Frame",{Visible=false,Size=UDim2.fromOffset(0,0),Parent=_sT})
local _hT={}
function _hT:Set(_LT,_rT)_LT=math.clamp(math.floor((_LT-_dT)/_vT+0.5)*_vT+_dT,_dT,_eT)
if _LT==_YT then return
end
_YT=_LT
_bT.Text=_uT(_LT)
_XT.Size=UDim2.new((_LT-_dT)/(_eT-_dT),0,1,0)
_tT.Position=UDim2.new((_LT-_dT)/(_eT-_dT),0,0.5,0)
if _rT~=false and _QT.Callback then task.spawn(_QT.Callback,_LT)
end
end
function _hT:Get()return _YT
end
local _oT=false
local function _OT(_yT)local _KT=math.clamp((_yT-_sT.AbsolutePosition.X)/_sT.AbsoluteSize.X,0,1)
_hT:Set(_dT+(_eT-_dT)*_KT)
end
local _ZT=_g("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-6,0.5,0),Size=UDim2.fromOffset(132,30),BackgroundTransparency=1,Parent=_NT,})
_ZT.InputBegan:Connect(function(_CT)if _vM(_CT)then _oT=true
_OT(_CT.Position.X)
_CT.Changed:Connect(function()if _CT.UserInputState==Enum.UserInputState.End then _oT=false
end
end)
end
end)
_cM(_T.InputChanged,function(_nT)if _oT and _EM(_nT)then _OT(_nT.Position.X)
end
end)
return _hT
end
function _yq:AddDropdown(_MT)local _GT=table.clone(_MT.Options or{})
local _BT=_MT.Multi==true
local _gT,_lT,_UT,_HT=30,4,5,190
local _aT,_VT=false,0
local _W8,_F8={},nil
local function _m8(_j8,_k8)for _J8,_D8 in ipairs(_j8)do if _D8==_k8 then return true
end
end
return false
end
local _S8=_MT.Default
if _BT then if type(_S8)=="table"then for _I8,_i8 in ipairs(_S8)do _W8[_i8]=true
end
elseif _S8~=nil then _W8[_S8]=true
end
else if type(_S8)=="table"then _S8=_S8[1]
end
if _S8==nil or not _m8(_GT,_S8)then _S8=_GT[1]
end
_F8=_S8
end
local function _P8()local _q8={}
for _T8,_A8 in ipairs(_GT)do if _W8[_A8]then table.insert(_q8,_A8)
end
end
return _q8
end
local function _f8()if _BT then local _R8=_P8()
if#_R8==0 then return"Chọn..."
end
local _x8={}
for _w8,_z8 in ipairs(_R8)do _x8[#_x8+1]=tostring(_z8)
end
return table.concat(_x8,", ")
end
return _F8~=nil and tostring(_F8)or"Chọn..."
end
local _Q8=_Gq(36)
_dM({Text=_MT.Name,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-176,1,0),TextTruncate=Enum.TextTruncate.AtEnd,Parent=_Q8,})
local _d8=_g("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),Size=UDim2.fromOffset(150,26),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.93,Text="",AutoButtonColor=false,Parent=_Q8,})
_kM(_d8,8)
_SM(_d8,Color3.new(1,1,1)).Transparency=0.88
local _e8=_dM({Text=_f8(),TextSize=12,TextColor3=Color3.fromRGB(232,232,232),TextTruncate=Enum.TextTruncate.AtEnd,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-32,1,0),Parent=_d8,})
local _v8=_g("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(1,-14,0.5,0),Size=UDim2.fromOffset(14,14),BackgroundTransparency=1,Parent=_d8,})
for _Y8,_E8 in ipairs({{4.2,45},{9.8,-45}})do local _u8=_g("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset(_E8[1],6.3),Size=UDim2.fromOffset(8,2),Rotation=_E8[2],BackgroundColor3=Color3.fromRGB(190,190,190),BorderSizePixel=0,Parent=_v8,})
_kM(_u8,1)
end
local _p8=_g("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=49,Visible=false,Parent=_uv,})
local _c8=_g("Frame",{AnchorPoint=Vector2.new(1,0),Size=UDim2.fromOffset(_HT,100),BackgroundColor3=Color3.fromRGB(15,15,15),BorderSizePixel=0,ZIndex=50,Visible=false,Parent=_uv,})
_kM(_c8,12)
local _N8=_SM(_c8,Color3.fromRGB(42,42,42))
local _b8=_g("UIScale",{Scale=1,Parent=_c8})
local _s8=_g("ScrollingFrame",{Position=UDim2.fromOffset(5,5),Size=UDim2.new(1,-10,1,-10),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=_f.Accent,ScrollBarImageTransparency=0.6,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=_c8,})
_g("UIListLayout",{Padding=UDim.new(0,_lT),SortOrder=Enum.SortOrder.LayoutOrder,Parent=_s8})
local _X8={}
local function _t8(_h8)local _L8=_GT[_h8]
return(_BT and _W8[_L8]==true)or(not _BT and _L8==_F8)
end
local function _r8()_e8.Text=_f8()
for _o8,_O8 in pairs(_X8)do _O8.bar.BackgroundTransparency=_t8(_o8)and 0 or 1
end
end
local function _y8()local _K8=math.max(1,math.min(#_GT,_UT))
local _Z8=_K8*_gT+(_K8-1)*_lT+10
local _C8=_sv.Scale
if _C8<=0 then _C8=1
end
local _n8=_uv.AbsolutePosition
local _M8,_G8=_d8.AbsolutePosition,_d8.AbsoluteSize
local _B8=math.clamp((_M8.X+_G8.X-_n8.X)/_C8,_HT+8,592)
local _g8=(_M8.Y+_G8.Y-_n8.Y)/_C8+6
if _g8+_Z8>386 then _g8=(_M8.Y-_n8.Y)/_C8-_Z8-6
end
_c8.Size=UDim2.fromOffset(_HT,_Z8)
_c8.Position=UDim2.fromOffset(_B8,math.max(4,_g8))
end
local _l8={}
local function _U8()if _MT.Callback then task.spawn(_MT.Callback,_BT and _P8()or _F8)
end
end
local _H8
local function _a8(_V8)_H8(false,_V8)
end
_H8=function(_Wo,_Fo)if _Wo==_aT then return
end
_aT=_Wo
_VT=_VT+1
local _mo=_VT
_xM(_v8,{Rotation=_Wo and 180 or 0},TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out))
if _Wo then if _jq.OpenDD and _jq.OpenDD~=_a8 then _jq.OpenDD()
end
_jq.OpenDD=_a8
_y8()
_p8.Visible=true
_c8.Visible=true
_c8.BackgroundTransparency=1
_N8.Transparency=1
_b8.Scale=0.9
_xM(_c8,{BackgroundTransparency=0},TweenInfo.new(0.15))
_xM(_N8,{Transparency=0},TweenInfo.new(0.15))
_xM(_b8,{Scale=1},TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out))
for _jo,_ko in ipairs(_X8)do _ko.btn.BackgroundTransparency=1
_ko.lbl.TextTransparency=1
_ko.bar.BackgroundTransparency=1
task.delay(math.min(_jo-1,6)*0.03,function()if _VT~=_mo then return
end
_xM(_ko.btn,{BackgroundTransparency=0},TweenInfo.new(0.18))
_xM(_ko.lbl,{TextTransparency=0},TweenInfo.new(0.18))
_xM(_ko.bar,{BackgroundTransparency=_t8(_jo)and 0 or 1},TweenInfo.new(0.18))
end)
end
else if _jq.OpenDD==_a8 then _jq.OpenDD=nil
end
_p8.Visible=false
if _Fo then _c8.Visible=false
return
end
for _Jo,_Do in ipairs(_X8)do _xM(_Do.btn,{BackgroundTransparency=1},TweenInfo.new(0.11))
_xM(_Do.bar,{BackgroundTransparency=1},TweenInfo.new(0.11))
end
task.delay(0.11,function()if _VT~=_mo then return
end
_xM(_c8,{BackgroundTransparency=1},TweenInfo.new(0.13))
_xM(_N8,{Transparency=1},TweenInfo.new(0.13))
_xM(_b8,{Scale=0.95},TweenInfo.new(0.13))
for _So,_Io in ipairs(_X8)do _xM(_Io.lbl,{TextTransparency=1},TweenInfo.new(0.13))
end
task.delay(0.13,function()if _VT==_mo then _c8.Visible=false
end
end)
end)
end
end
local function _io()for _Po,_qo in ipairs(_s8:GetChildren())do if _qo:IsA("TextButton")then _qo:Destroy()
end
end
table.clear(_X8)
for _To,_Ao in ipairs(_GT)do local _fo=_g("TextButton",{Size=UDim2.new(1,0,0,_gT),BackgroundColor3=Color3.fromRGB(28,28,28),Text="",AutoButtonColor=false,LayoutOrder=_To,Parent=_s8,})
_kM(_fo,8)
local _Ro=_g("Frame",{Size=UDim2.fromOffset(3,16),Position=UDim2.new(0,0,0.5,-8),BackgroundColor3=_f.Accent,BackgroundTransparency=1,BorderSizePixel=0,Parent=_fo,})
_kM(_Ro,2)
local _xo=_dM({Text=tostring(_Ao),TextSize=13,TextColor3=Color3.new(1,1,1),TextTruncate=Enum.TextTruncate.AtEnd,Position=UDim2.fromOffset(16,0),Size=UDim2.new(1,-24,1,0),Parent=_fo,})
_X8[_To]={btn=_fo,bar=_Ro,lbl=_xo}
_fo.MouseEnter:Connect(function()_xM(_fo,{BackgroundColor3=Color3.fromRGB(40,40,40)})
end)
_fo.MouseLeave:Connect(function()_xM(_fo,{BackgroundColor3=Color3.fromRGB(28,28,28)})
end)
_fo.MouseButton1Click:Connect(function()if _BT then _W8[_Ao]=(not _W8[_Ao])or nil
_r8()
_U8()
else _H8(false)
if _Ao~=_F8 then _F8=_Ao
_r8()
_U8()
end
end
end)
end
_r8()
end
_io()
function _l8:Get()if _BT then return _P8()
end
return _F8
end
function _l8:Set(_wo,_zo)if _BT then _W8={}
if type(_wo)=="table"then for _Qo,_do in ipairs(_wo)do _W8[_do]=true
end
end
else _F8=_wo
end
_r8()
if _zo~=false then _U8()
end
end
function _l8:Refresh(_eo,_vo,_Yo)_GT=table.clone(_eo or{})
if _BT then local _Eo={}
if _vo then for _uo in pairs(_W8)do if _m8(_GT,_uo)then _Eo[_uo]=true
end
end
end
_W8=_Eo
elseif not(_vo and _F8~=nil and _m8(_GT,_F8))then _F8=_GT[1]
end
_io()
if _aT then _y8()
end
if _Yo~=false then _U8()
end
end
_d8.MouseButton1Click:Connect(function()_H8(not _aT)
end)
_p8.MouseButton1Click:Connect(function()_H8(false)
end)
_d8.MouseEnter:Connect(function()_xM(_d8,{BackgroundTransparency=0.88})
end)
_d8.MouseLeave:Connect(function()_xM(_d8,{BackgroundTransparency=0.93})
end)
return _l8
end
function _yq:AddInput(_po)local _co=_Gq(36)
_dM({Text=_po.Name,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-170,1,0),TextTruncate=Enum.TextTruncate.AtEnd,Parent=_co,})
local _No=_g("TextBox",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),Size=UDim2.fromOffset(140,24),BackgroundColor3=_f.ElementHover,BorderSizePixel=0,Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=_f.Text,PlaceholderText=tostring(_po.Placeholder or""),PlaceholderColor3=_f.SubText,ClearTextOnFocus=false,ClipsDescendants=true,TextXAlignment=Enum.TextXAlignment.Left,Text=_po.Default~=nil and tostring(_po.Default)or"",Parent=_co,})
_kM(_No,6)
_g("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),Parent=_No})
local _bo=_No.Text
_No.FocusLost:Connect(function()_bo=_No.Text
if _po.Finished~=false and _po.Callback then task.spawn(_po.Callback,_bo)
end
end)
_No:GetPropertyChangedSignal("Text"):Connect(function()if _po.Numeric==true then local _so=_No.Text:gsub("[^%d%.]","")
if _so~=_No.Text then _No.Text=_so
return
end
end
_bo=_No.Text
if _po.Finished==false and _po.Callback then task.spawn(_po.Callback,_bo)
end
end)
local _Xo={}
function _Xo:Get()return _bo
end
function _Xo:Set(_to,_ho)_bo=tostring(_to)
_No.Text=_bo
if _ho~=false and _po.Finished~=false and _po.Callback then task.spawn(_po.Callback,_bo)
end
end
return _Xo
end
function _yq:AddKeybind(_Lo)local function _ro(_oo)if typeof(_oo)=="EnumItem"then return _oo
end
local _Oo,_yo=pcall(function()return Enum.KeyCode[tostring(_oo)]
end)
return(_Oo and _yo)or Enum.KeyCode.Unknown
end
local _Ko=_ro(_Lo.Default)
local _Zo,_Co=false,0
local function _no()return _Ko==Enum.KeyCode.Unknown and"None"or _Ko.Name
end
local _Mo=_Gq(36)
_dM({Text=_Lo.Name,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-120,1,0),TextTruncate=Enum.TextTruncate.AtEnd,Parent=_Mo,})
local _Go=_g("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),Size=UDim2.fromOffset(90,24),BackgroundColor3=_f.ElementHover,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=_f.Text,AutoButtonColor=false,Text=_no(),Parent=_Mo,})
_kM(_Go,6)
_Go.MouseButton1Click:Connect(function()if _Zo then return
end
_Zo=true
_Go.Text="..."
local _Bo
_Bo=_T.InputBegan:Connect(function(_go)if _go.UserInputType~=Enum.UserInputType.Keyboard then return
end
_Bo:Disconnect()
_Zo=false
_Co=os.clock()
if _go.KeyCode~=Enum.KeyCode.Escape and _go.KeyCode~=_Ko then _Ko=_go.KeyCode
if _Lo.OnChanged then task.spawn(_Lo.OnChanged,_Ko.Name)
end
end
_Go.Text=_no()
end)
end)
_cM(_T.InputBegan,function(_lo)if _Zo or _lo.UserInputType~=Enum.UserInputType.Keyboard then return
end
if _Ko~=Enum.KeyCode.Unknown and _lo.KeyCode==_Ko and not _T:GetFocusedTextBox()then local _Uo=os.clock()
if _Uo-_Co>0.15 then _Co=_Uo
if _Lo.Callback then task.spawn(_Lo.Callback)
end
end
end
end)
local _Ho={}
function _Ho:Get()return _Ko.Name
end
function _Ho:Set(_ao)_Ko=_ro(_ao)
;
_Go.Text=_no()
end
return _Ho
end
function _yq:AddParagraph(_Vo)local _Wx=_g("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=_f.Element,BorderSizePixel=0,Parent=_Cq,})
_TM(_Wx)
_g("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),Parent=_Wx,})
_g("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder,Parent=_Wx})
_dM({Text=tostring(_Vo.Title or""),Font=Enum.Font.GothamBold,TextSize=14,Size=UDim2.new(1,0,0,18),LayoutOrder=1,Parent=_Wx,})
if _Vo.Content and _Vo.Content~=""then _dM({Text=tostring(_Vo.Content),TextColor3=_f.SubText,TextSize=12,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top,AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,0,0,0),LayoutOrder=2,Parent=_Wx,})
end
end
function _yq:AddStatGrid(_Fx)local _mx=_Fx.Items or{}
local _jx=math.max(1,tonumber(_Fx.Columns)or 3)
local _kx=math.max(1,math.ceil(#_mx/_jx))
local _Jx,_Dx=46,6
local _Sx=_g("Frame",{Size=UDim2.new(1,0,0,_kx*_Jx+(_kx-1)*_Dx),BackgroundTransparency=1,Parent=_Cq,})
_g("UIGridLayout",{CellSize=UDim2.new(1/_jx,-_Dx,0,_Jx),CellPadding=UDim2.fromOffset(_Dx,_Dx),SortOrder=Enum.SortOrder.LayoutOrder,Parent=_Sx,})
local _Ix={}
for _ix,_Px in ipairs(_mx)do local _qx=_g("Frame",{BackgroundColor3=_f.Element,BorderSizePixel=0,LayoutOrder=_ix,Parent=_Sx,})
_TM(_qx)
_dM({Text=tostring(_Px.Label or _Px.Key),TextColor3=_f.SubText,TextSize=11,TextTruncate=Enum.TextTruncate.AtEnd,Position=UDim2.fromOffset(10,5),Size=UDim2.new(1,-20,0,14),Parent=_qx,})
_Ix[_Px.Key]=_dM({Text=tostring(_Px.Value or"-"),Font=Enum.Font.GothamBold,TextSize=14,TextColor3=_Px.Color or _f.Text,TextTruncate=Enum.TextTruncate.AtEnd,Position=UDim2.fromOffset(10,22),Size=UDim2.new(1,-20,0,18),Parent=_qx,})
end
local _Tx={}
function _Tx:Set(_Ax,_fx)local _Rx=_Ix[_Ax]
if _Rx then _Rx.Text=tostring(_fx)
end
end
return _Tx
end
function _yq:AddServerList(_xx)_xx=_xx or{}
local _wx=math.max(1,tonumber(_xx.Max)or 12)
local _zx=_g("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Parent=_Cq,})
_g("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,Parent=_zx})
local _Qx,_dx={},{}
for _ex=1,_wx do local _vx=_g("TextButton",{Size=UDim2.new(1,0,0,36),BackgroundColor3=_f.Element,Text="",AutoButtonColor=false,Visible=false,LayoutOrder=_ex,Parent=_zx,})
_TM(_vx)
local _Yx=_dM({Text="",Font=Enum.Font.GothamBold,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-36,1,0),TextTruncate=Enum.TextTruncate.AtEnd,Parent=_vx,})
local _Ex=_dM({Text=">",TextColor3=_f.SubText,TextXAlignment=Enum.TextXAlignment.Center,Position=UDim2.new(1,-26,0,0),Size=UDim2.fromOffset(18,36),Parent=_vx,})
_vx.MouseEnter:Connect(function()if _dx[_ex]then _xM(_vx,{BackgroundColor3=_f.ElementHover})
end
end)
_vx.MouseLeave:Connect(function()_xM(_vx,{BackgroundColor3=_f.Element})
end)
_vx.MouseButton1Click:Connect(function()local _ux=_dx[_ex]
if _ux then task.spawn(_ux)
end
end)
_Qx[_ex]={btn=_vx,text=_Yx,arrow=_Ex}
end
local _px={}
function _px:Set(_cx,_Nx)_cx=_cx or{}
for _bx=1,_wx do local _sx,_Xx=_Qx[_bx],_cx[_bx]
if _Xx then _sx.text.Text=tostring(_Xx.Text or"")
_sx.text.TextColor3=_f.Text
_sx.arrow.Visible=true
_dx[_bx]=_Xx.Callback
_sx.btn.Visible=true
elseif _bx==1 and#_cx==0 and _Nx then _sx.text.Text=tostring(_Nx)
_sx.text.TextColor3=_f.SubText
_sx.arrow.Visible=false
_dx[_bx]=nil
_sx.btn.Visible=true
else _dx[_bx]=nil
_sx.btn.Visible=false
end
end
end
return _px
end
return _yq
end
return _jq
end
_P.Flags={}
_P.Assets={Logo="",Background=""}
_P.NotificationsEnabled=true
local function _tx(_hx)if type(_hx)=="string"then return{Name=_hx}
end
return type(_hx)=="table"and _hx or{}
end
local function _Lx(_rx)return tostring(_rx.Name or _rx.Title or _rx.Text or"")
end
local function _ox(_Ox,_yx)if _Ox.Flag then _P.Flags[_Ox.Flag]=_yx
end
return _yx
end
local function _Kx(_Zx)function _Zx:CreateSection(_Cx)return _Zx:AddSection(type(_Cx)=="table"and _Lx(_Cx)or tostring(_Cx))
end
function _Zx:CreateParagraph(_nx)_nx=_tx(_nx)
_Zx:AddParagraph({Title=tostring(_nx.Title or _nx.Name or _nx.Text or""),Content=tostring(_nx.Content or"")})
return _ox(_nx,{})
end
_Zx.CreateLabel=_Zx.CreateParagraph
function _Zx:CreateStatGrid(_Mx)_Mx=_tx(_Mx)
return _ox(_Mx,_Zx:AddStatGrid({Items=_Mx.Items or{},Columns=_Mx.Columns}))
end
function _Zx:CreateButton(_Gx)_Gx=_tx(_Gx)
_Zx:AddButton({Name=_Lx(_Gx),Callback=_Gx.Callback})
return _ox(_Gx,{})
end
function _Zx:CreateToggle(_Bx)_Bx=_tx(_Bx)
local _gx=_Zx:AddToggle({Name=_Lx(_Bx),Default=_Bx.CurrentValue==true,Callback=_Bx.Callback})
local _lx={}
function _lx:Get()return _gx:Get()
end
function _lx:Set(_Ux,_Hx)_Ux=_Ux==true
if _Ux==_gx:Get()then return
end
_gx:Set(_Ux,not _Hx)
end
return _ox(_Bx,_lx)
end
function _Zx:CreateSlider(_ax)_ax=_tx(_ax)
local _Vx=_ax.Range
local _Wz=_Zx:AddSlider({Name=_Lx(_ax),Min=_ax.Min or(_Vx and _Vx[1])or 0,Max=_ax.Max or(_Vx and _Vx[2])or 100,Step=_ax.Increment or _ax.Step or 1,Default=_ax.CurrentValue or _ax.Default,Suffix=_ax.Suffix or _ax.Unit,Callback=_ax.Callback,})
local _Fz={}
function _Fz:Get()return _Wz:Get()
end
function _Fz:Set(_mz,_jz)_mz=tonumber(_mz)
if _mz==nil then return
end
_Wz:Set(_mz,not _jz)
end
return _ox(_ax,_Fz)
end
function _Zx:CreateDropdown(_kz)_kz=_tx(_kz)
local _Jz=_kz.CurrentOption
if _Jz==nil then _Jz=_kz.Default
end
local _Dz=_Zx:AddDropdown({Name=_Lx(_kz),Options=_kz.Options or _kz.Values or _kz.Items or{},Default=_Jz,Multi=(_kz.MultipleOptions or _kz.Multi)==true,Callback=_kz.Callback,})
local _Sz={}
function _Sz:Get()return _Dz:Get()
end
function _Sz:Set(_Iz,_iz)_Dz:Set(_Iz,not _iz)
end
function _Sz:Refresh(_Pz,_qz,_Tz)_Dz:Refresh(_Pz,_qz,not _Tz)
end
return _ox(_kz,_Sz)
end
function _Zx:CreateInput(_Az)_Az=_tx(_Az)
local _fz=_Az.CurrentValue
if _fz==nil then _fz=_Az.Default
end
if _fz==nil then _fz=_Az.Value
end
local _Rz=_Zx:AddInput({Name=_Lx(_Az),Default=_fz,Placeholder=_Az.Placeholder or _Az.PlaceholderText,Numeric=_Az.Numeric,Finished=_Az.Finished,Callback=_Az.Callback,})
local _xz={}
function _xz:Get()return _Rz:Get()
end
function _xz:Set(_wz,_zz)_Rz:Set(_wz,not _zz)
end
return _ox(_Az,_xz)
end
function _Zx:CreateServerList(_Qz)return _Zx:AddServerList(_Qz or{})
end
function _Zx:CreateKeybind(_dz)_dz=_tx(_dz)
local _ez=_Zx:AddKeybind({Name=_Lx(_dz),Default=_dz.CurrentKeybind or _dz.Default,OnChanged=_dz.OnChanged,Callback=_dz.Callback,})
local _vz={}
function _vz:Get()return _ez:Get()
end
function _vz:Set(_Yz)_ez:Set(_Yz)
end
return _ox(_dz,_vz)
end
return _Zx
end
function _P:Notify(_Ez)local _uz=_P._current
if _uz then _uz:Notify(_Ez)
end
end
local _pz=_P.CreateWindow
function _P:CreateWindow(_cz)_cz=_tx(_cz)
local _Nz=_pz(self,{Name=_cz.Name,Title=_cz.Name,Subtitle=_cz.Subtitle,Logo=(type(_cz.Icon)=="string"and _cz.Icon~="")and _cz.Icon or nil,ToggleKey=_cz.ToggleUIKeybind,})
function _Nz:CreateTab(_bz)_bz=_tx(_bz)
return _Kx(_Nz:AddTab(_Lx(_bz)~=""and _Lx(_bz)or"Tab"))
end
local _sz=_cz.Home
if type(_sz)=="table"then local _Xz=_Nz:CreateTab({Name=_sz.Name or"Home"})
if type(_sz.Stats)=="table"then _Xz:CreateSection(tostring(_sz.StatsTitle or"Session"))
_Nz.Stats=_Xz:CreateStatGrid({Items=_sz.Stats,Columns=3})
end
_Xz:CreateParagraph({Title=tostring(_sz.Title or _cz.Name or""),Content=tostring(_sz.Desc or _cz.Subtitle or""),})
if _sz.Discord then _Xz:CreateButton({Name=tostring(_sz.DiscordTitle or"Discord"),Callback=function()local _tz=false
if type(setclipboard)=="function"then _tz=pcall(setclipboard,tostring(_sz.Discord))
end
_P:Notify({Title=tostring(_sz.DiscordTitle or"Discord"),Content=_tz and"Invite link copied to clipboard"or tostring(_sz.Discord),Duration=3,})
end,})
end
end
return _Nz
end
_P.Window=_P.CreateWindow
return _P
end)()
local _Lz=game:GetService("Players")
local _rz=game:GetService("UserInputService")
local _oz=game:GetService("TweenService")
local _Oz=game:GetService("RunService")
local _yz=game:GetService("ReplicatedStorage")
local _Kz=game:GetService("HttpService")
local _Zz=game:GetService("TeleportService")
local _Cz=game:GetService("Lighting")
local _nz=game:GetService("VirtualInputManager")
local _Mz=game:GetService("VirtualUser")
local _Gz=_Lz.LocalPlayer
local _Bz=_yz:WaitForChild("Events")
local _gz=_yz:WaitForChild("Info")
local _lz=_yz:WaitForChild("Data")
local _Uz=_lz:WaitForChild(_Gz.UserId)
local _Hz=_Bz:WaitForChild("ToggleHotbar")
local _az=_Bz:WaitForChild("Fishing")
local _Vz=_Bz:WaitForChild("UpdateFishProgression")
local _WV=_Bz:WaitForChild("UseSkill")
local _FV=_Bz:WaitForChild("SellFish")
local _mV=_Bz:WaitForChild("CraftBait")
local _jV=_Bz:WaitForChild("CraftRod")
local _kV=_Bz:WaitForChild("RedeemCode")
local _JV=_Bz:WaitForChild("EquipBait",9e9)
local _DV={AutoCast=false,AutoCastMethod="Instant",AntiStaff=false,HideName=false,NotificationsEnabled=true,PerformanceMode=false,UpgradeOptions={"Cash","Level"},UpgradeMethod="Instant",AutoRebirth=false,FilterBossFish=false,AutoFarmSecretBoss=false,AutoSecretBossMode="Always Active",FavoriteFish="",AutoFavoriteFish=false,SkipFishList={},AutoSkipFish=false,BlackTortoiseBand=0.12,DumpGuyHotbarSlot=4,AutoGiveFish=false,AutoGiveEventFish=false,AutoGiveEventFishTarget={},EventGiveTeleport=true,HopAutoCheck=false,AutoHopGodSpirit=false,AutoHopMaoshan=false,AutoHopTaoist=false,AutoHopVermilion=false,AutoHopTortoise=false,AutoHopWeather=false,SelectedWeather="Thunderstorm",HopWeatherDelay=5,HopWeatherResumeAt=0,HopListEvent="Taoist",HopListWeather="Thunderstorm",AutoHopConfirmed=false,HopFeedReport=true,HopFeedUrl="http://78.154.103.15:17017",CastDelay=1,AutoReel=false,AutoMiniGame=false,BossHitDelay=35,BossMode="Normal",AutoBoss=false,AutoSecretBoss=false,AutoSkill=false,SkillOrder={"Z","X","C","V"},AutoSell=false,AutoSellMethod="Spam",SellDelay=1,SelectedBuyBait="",BuyBaitAmount=1,BuyBaitDelay=1,AutoBuyBait=false,SelectedBait="",BaitAmount=1,AutoCraftBait=false,SelectedRod="",AutoCraftRod=false,SelectedIsland="",SelectedNPC="",SelectedPlayer="",ESPEnabled=false,AntiAFK=true,FullBright=false,NoFog=false,LoopSpeedEnabled=false,WalkSpeed=30,NoclipEnabled=false,InfJumpEnabled=false,FlyEnabled=false,FlySpeed=2,FlyKeybind="F",FlyKeybindEnabled=true,NoclipKeybind="J",NoclipKeybindEnabled=true,DisableAllKeybinds=false,SavedPos=false,AutoTPPos=false,AutoExecute=false,AutoRejoin=true,WebhookEnabled=false,WebhookUrl="",WebhookInterval=0,WebhookOnCatch=false,HideId=true,FakeNameEnabled=false,FakeName="Player",FakeIdEnabled=false,FakeId="",AutoFarmIsland=false,SelectedFarmIsland="Beginning Isle",AutoTicketQuest=false,AutoDailyQuest=false,TicketQuestMode="Hard",AutoEquipBestBait=false,AutoEquipRod=false,Language="English"}
local _SV="UZEXHub"
local _IV=_SV.."/HeavyweighFishingConfig.json"
local function _iV()pcall(function()if not isfolder(_SV)then makefolder(_SV)
end
local _PV=table.clone(_DV)
_PV.AutoHopWeather=false
writefile(_IV,_Kz:JSONEncode(_PV))
end)
end
local function _qV()pcall(function()if isfile(_IV)then local _TV=_Kz:JSONDecode(readfile(_IV))
for _AV,_fV in pairs(_TV)do if _DV[_AV]~=nil then _DV[_AV]=_fV
end
end
end
end)
end
_qV()
do local _RV=tonumber(_DV.HopWeatherResumeAt)or 0
_DV.AutoHopWeather=_RV>0 and(os.time()-_RV)>=0 and(os.time()-_RV)<120
if not _DV.AutoHopWeather then _DV.HopWeatherResumeAt=0
end
end
if type(_DV.AutoGiveEventFishTarget)=="string"then _DV.AutoGiveEventFishTarget=_DV.AutoGiveEventFishTarget~=""and{_DV.AutoGiveEventFishTarget}or{}
elseif type(_DV.AutoGiveEventFishTarget)~="table"then _DV.AutoGiveEventFishTarget={}
end
_DV.AutoFarmIsland=false
_hz.NotificationsEnabled=_DV.NotificationsEnabled~=false
_hz.Language=(_DV.Language=="Tiếng Việt")and"Tiếng Việt"or"English"
if type(_DV.SkillOrder)~="table"then _DV.SkillOrder={"Z","X","C","V"}
else local _xV={Z=true,X=true,C=true,V=true}
local _wV={}
for _zV,_QV in ipairs(_DV.SkillOrder)do if _xV[_QV]and not table.find(_wV,_QV)then table.insert(_wV,_QV)
end
end
_DV.SkillOrder=_wV
end
local _dV=queue_on_teleport or(syn and syn.queue_on_teleport)or(fluxus and fluxus.queue_on_teleport)or queueonteleport
local _eV=false
local _vV=[[
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
    local allow = false
    pcall(function()
        if isfile then
            allow = false
            if isfile("UZEXHub/rejoin.flag") and delfile then
                pcall(delfile, "UZEXHub/rejoin.flag")
            end
            -- only run when Auto Execute is ON in the saved config
            if isfile("UZEXHub/HeavyweighFishingConfig.json") then
                local dec = HttpService:JSONDecode(readfile("UZEXHub/HeavyweighFishingConfig.json"))
                allow = (type(dec) == "table" and dec.AutoExecute == true)
                -- a weather hop that is in progress must carry on in the next server
                if type(dec) == "table" and not allow then
                    local at = tonumber(dec.HopWeatherResumeAt) or 0
                    if at > 0 and (os.time() - at) >= 0 and (os.time() - at) < 180 then
                        allow = true
                    end
                end
            end
        end
    end)
    if not allow then
        return
    end
    local env = (getgenv and getgenv()) or _G
    if env.UzexBootLock and (os.clock() - env.UzexBootLock) < 90 then
        return
    end
    env.UzexBootLock = os.clock()
    local source
    for _ = 1, 3 do
        local ok, body = pcall(game.HttpGet, game, "]].."https://raw.githubusercontent.com/8uzex/izen/refs/heads/main/script.lua"..[[")
        if ok and type(body) == "string" and #body > 0 then
            source = body
            break
        end
        task.wait(3)
    end
    if source then
        local fn = loadstring(source)
        if fn then
            fn()
        end
    end
end)
]]
local function _YV(_EV,_uV)if not _dV then return
end
if not _DV.AutoExecute and not _uV then return
end
if _eV and not _EV then return
end
if _vV:find("YOUR-USER",1,true)then pcall(function()_hz:Notify({Title="Auto Execute ",Content="Hãy đặt liên kết script trong autoExecPayload trước.",Type="warning",Duration=6,})
end)
return
end
_eV=true
pcall(function()_dV(_vV)
end)
end
if _DV.AutoExecute then _YV()
end
pcall(function()_Gz.OnTeleport:Connect(function()if _DV.AutoExecute then _YV()
end
end)
end)
local function _pV()if type(_DV.SavedPos)=="table"and#_DV.SavedPos>=3 then local _cV,_NV=pcall(CFrame.new,unpack(_DV.SavedPos))
if _cV and _NV then return _NV
end
end
return nil
end
local _bV={["Beginning Isle"]=CFrame.new(-297.48,9.28,58.78,0.00,0.00,1.00,-0.00,1.00,-0.00,-1.00,-0.00,0.00),["Bamboo Isle"]=CFrame.new(-1310.04,9.28,29.79,-0.28,-0.00,0.96,-0.00,1.00,0.00,-0.96,-0.00,-0.28),["Fallout Isle"]=CFrame.new(76.47,9.28,1265.92,-1.00,0.00,0.01,0.00,1.00,-0.00,-0.01,-0.00,-1.00),["Sovereign Isle"]=CFrame.new(-1254.18,9.28,1301.79,-1.00,0.00,-0.07,0.00,1.00,-0.00,0.07,-0.00,-1.00),["Perch Isle"]=CFrame.new(-38.55,9.28,-1343.82,0.99,-0.00,-0.12,0.00,1.00,0.00,0.12,-0.00,0.99),["Frost Isle"]=CFrame.new(-1348.71,9.28,-1446.51,-1.00,-0.00,-0.03,-0.00,1.00,0.00,0.03,0.00,-1.00),["Coconut Isle"]=CFrame.new(1431.00,9.28,-1430.22,-0.17,0.00,0.98,-0.00,1.00,-0.00,-0.98,-0.00,-0.17),["Amber Isle"]=CFrame.new(1122.07,9.28,1414.54,0.03,-0.00,1.00,-0.00,1.00,0.00,-1.00,-0.00,0.03),["Battlefield Isle"]=CFrame.new(1249.73,19.56,68.87,0.01,0.00,1.00,0.00,1.00,-0.00,-1.00,0.00,0.01),["Mistpeak Isle"]=CFrame.new(2549.02,9.28,-80.77,-0.03,0.00,1.00,0.00,1.00,-0.00,-1.00,0.00,-0.03),["World Angler Isle"]=CFrame.new(-2345.67,9.28,-203.65,-0.09,-0.00,-1.00,0.00,1.00,-0.00,1.00,-0.00,-0.09),["Weather Isle"]=CFrame.new(-2886.12,6.76,1199.79,-0.04,-0.00,-1.00,-0.00,1.00,-0.00,1.00,0.00,-0.04),["Mystic Reef Isle"]=CFrame.new(-2561.58,9.28,-1288.64,-0.07,-0.00,-1.00,0.00,1.00,-0.00,1.00,-0.00,-0.07)}
local function _sV(_XV)local _tV=_XV or _DV.SelectedFarmIsland or""
if _bV[_tV]then return _bV[_tV]
end
local _hV=tostring(_tV):gsub("%s*|%s*%d+",""):gsub("^%s+",""):gsub("%s+$","")
if _bV[_hV]then return _bV[_hV]
end
local _LV=string.lower(_hV)
for _rV,_oV in pairs(_bV)do local _OV=string.lower(_rV)
if _LV==_OV or string.find(_LV,_OV,1,true)or string.find(_OV,_LV,1,true)then return _oV
end
end
return nil
end
local _yV={}
local function _KV(_ZV)if not _ZV or not _ZV:IsA("ModuleScript")then return nil
end
local _CV=_yV[_ZV]
if _CV~=nil then return _CV~=false and _CV or nil
end
local _nV,_MV=pcall(require,_ZV)
if _nV and type(_MV)=="table"then _yV[_ZV]=_MV
return _MV
end
_yV[_ZV]=false
return nil
end
if getconnections then pcall(function()for _GV,_BV in pairs(getconnections(_Gz.Idled))do if _BV.Disable then _BV:Disable()
elseif _BV.Disconnect then _BV:Disconnect()
end
end
end)
end
local _gV=os.clock()
local function _lV()pcall(function()_Mz:CaptureController()
_Mz:ClickButton2(Vector2.new(0,0))
end)
pcall(function()_nz:SendMouseMoveEvent(1,1,game)
_nz:SendKeyEvent(true,Enum.KeyCode.LeftShift,false,game)
task.wait(0.05)
_nz:SendKeyEvent(false,Enum.KeyCode.LeftShift,false,game)
end)
end
_Gz.Idled:Connect(function()if not _DV.AntiAFK then return
end
_lV()
end)
task.spawn(function()while true do task.wait(1)
if _DV.AntiAFK then local _UV=os.clock()
if _UV-_gV>=240 then _gV=_UV
_lV()
end
pcall(function()local _HV=_Uz and _Uz:FindFirstChild("AFK")
if _HV and _HV.Value==true then local _aV=_Bz:FindFirstChild("AFK")
if _aV then _aV:FireServer()
end
end
end)
else _gV=os.clock()
end
end
end)
local _VV=_Gz.Character
local _WY=_VV and _VV:FindFirstChildOfClass("Humanoid")
local _FY=_VV and _VV:FindFirstChild("HumanoidRootPart")
local _mY=_VV and _VV:FindFirstChild("Skills")
local _jY=_VV and _VV:FindFirstChild("Stats")
local _kY=workspace:FindFirstChild("Fishes")
local _JY=_Gz:WaitForChild("PlayerGui"):WaitForChild("MainGui")
local _DY=_JY:WaitForChild("Fishing")
local _SY=_DY:WaitForChild("BarFrame")
local _IY=_SY:WaitForChild("Bar")
local _iY=_DY:WaitForChild("SkillButton"):WaitForChild("Frame")
local _PY=_DY:FindFirstChild("Rhythm")
local _qY=_DY:FindFirstChild("BossFightBar")
local _TY=_JY:FindFirstChild("Mobile")
local _AY=_TY and _TY:FindFirstChild("Fishing")
local _fY=_Bz:FindFirstChild("RhythmHit")
local function _RY()if not _JY or not _JY.Parent then local _xY=_Gz:FindFirstChild("PlayerGui")
_JY=_xY and _xY:FindFirstChild("MainGui")
_DY=_JY and _JY:FindFirstChild("Fishing")
_SY=_DY and _DY:FindFirstChild("BarFrame")
_IY=_SY and _SY:FindFirstChild("Bar")
local _wY=_DY and _DY:FindFirstChild("SkillButton")
_iY=_wY and _wY:FindFirstChild("Frame")
_PY=_DY and _DY:FindFirstChild("Rhythm")
_qY=_DY and _DY:FindFirstChild("BossFightBar")
_TY=_JY and _JY:FindFirstChild("Mobile")
_AY=_TY and _TY:FindFirstChild("Fishing")
else if not _PY or not _PY.Parent then _PY=_DY and _DY:FindFirstChild("Rhythm")
end
if not _qY or not _qY.Parent then _qY=_DY and _DY:FindFirstChild("BossFightBar")
end
if not _AY or not _AY.Parent then _TY=_JY and _JY:FindFirstChild("Mobile")
_AY=_TY and _TY:FindFirstChild("Fishing")
end
end
if not _fY then _fY=_Bz:FindFirstChild("RhythmHit")
end
if not _kY or not _kY.Parent then _kY=workspace:FindFirstChild("Fishes")
end
end
local _zY=0
_Oz.Stepped:Connect(function(_QY,_dY)if not _DV.NoclipEnabled and not _DV.LoopSpeedEnabled then return
end
_zY=_zY+_dY
if _zY<0.08 then return
end
_zY=0
local _eY=_VV
if not _eY or not _eY.Parent then return
end
if _DV.NoclipEnabled then for _vY,_YY in ipairs(_eY:GetChildren())do if _YY:IsA("BasePart")and _YY.CanCollide then _YY.CanCollide=false
end
end
end
if _DV.LoopSpeedEnabled and _WY and _WY.WalkSpeed~=_DV.WalkSpeed then _WY.WalkSpeed=_DV.WalkSpeed
end
end)
local _EY=0
local function _uY(_pY)if not _pY then return false
end
local _cY=workspace:FindFirstChild("Ocean")
if not _cY then return false
end
local _NY=_pY.Position
for _bY,_sY in ipairs(_cY:GetChildren())do if _sY.Name=="Water"and _sY:IsA("BasePart")then local _XY=_sY.Size*0.5
local _tY=_sY.Position-_NY
if math.abs(_tY.X)<=_XY.X and math.abs(_tY.Y)<=_XY.Y and math.abs(_tY.Z)<=_XY.Z then return true
end
end
end
return false
end
_rz.JumpRequest:Connect(function()if not _DV.InfJumpEnabled then return
end
local _hY=os.clock()
if _hY-_EY<0.18 then return
end
local _LY=_VV or _Gz.Character
local _rY=_WY or(_LY and _LY:FindFirstChildOfClass("Humanoid"))
local _oY=_FY or(_LY and _LY:FindFirstChild("HumanoidRootPart"))
if not _LY or not _rY or not _oY or _rY.Health<=0 then return
end
if _LY:GetAttribute("Swimming")==true or _oY:FindFirstChildOfClass("BodyPosition")or _uY(_oY)then return
end
_EY=_hY
_rY:ChangeState(Enum.HumanoidStateType.Jumping)
end)
local _OY=nil
local _yY=nil
local function _KY()local _ZY=_Gz.Character
if not _ZY then return
end
local _CY=_ZY:FindFirstChild("HumanoidRootPart")
local _nY=_ZY:FindFirstChildOfClass("Humanoid")
if not _CY or not _nY then return
end
_nY.PlatformStand=true
local _MY=Instance.new("BodyVelocity")
_MY.MaxForce=Vector3.new(9e9,9e9,9e9)
_MY.Velocity=Vector3.zero
_MY.Parent=_CY
local _GY=Instance.new("BodyGyro")
_GY.MaxTorque=Vector3.new(9e9,9e9,9e9)
_GY.P=1e7
_GY.D=12000
_GY.CFrame=_CY.CFrame
_GY.Parent=_CY
_yY=_nY.StateChanged:Connect(function(_BY,_gY)if _gY==Enum.HumanoidStateType.Jumping or _gY==Enum.HumanoidStateType.Freefall then _nY.PlatformStand=true
end
end)
_OY=_Oz.RenderStepped:Connect(function()local _lY=workspace.CurrentCamera
local _UY=Vector3.zero
local _HY=_nY.MoveDirection
if _HY.Magnitude>0 then local _aY=Vector3.new(_lY.CFrame.LookVector.X,0,_lY.CFrame.LookVector.Z)
local _VY=Vector3.new(_lY.CFrame.RightVector.X,0,_lY.CFrame.RightVector.Z)
if _aY.Magnitude>0.01 and _VY.Magnitude>0.01 then local _W6=_HY:Dot(_aY.Unit)
local _F6=_HY:Dot(_VY.Unit)
_UY+=_lY.CFrame.LookVector*_W6
_UY+=_lY.CFrame.RightVector*_F6
end
end
if _UY.Magnitude>0 then _UY=_UY.Unit
end
_MY.Velocity=_UY*_DV.FlySpeed*50
local _m6=_lY.CFrame.LookVector
_GY.CFrame=CFrame.lookAt(_CY.Position,_CY.Position+_m6,Vector3.new(0,1,0))
end)
end
local function _j6()local _k6=_Gz.Character
if not _k6 then return
end
local _J6=_k6:FindFirstChild("HumanoidRootPart")
local _D6=_k6:FindFirstChildOfClass("Humanoid")
if _D6 then _D6.PlatformStand=false
end
if _yY then _yY:Disconnect()
_yY=nil
end
if _OY then _OY:Disconnect()
_OY=nil
end
if _J6 then for _S6,_I6 in pairs(_J6:GetChildren())do if _I6:IsA("BodyVelocity")or _I6:IsA("BodyGyro")then _I6:Destroy()
end
end
end
end
local function _i6()return _DV.AutoSkill or _DV.AutoMiniGame or _DV.AutoBoss or _DV.AutoSecretBoss or _DV.AutoFarmIsland
end
local function _P6(_q6)if not _i6()then return
end
if _q6 then if _q6:GetAttribute("Confused")==true then pcall(function()_q6:SetAttribute("Confused",false)
end)
end
if _q6:GetAttribute("SkillLocked")==true then pcall(function()_q6:SetAttribute("SkillLocked",false)
end)
end
end
if _iY then for _T6,_A6 in ipairs(_iY:GetChildren())do if _A6:IsA("TextButton")then local _f6=_A6:FindFirstChild("Lock")
if _f6 and _f6.Visible then _f6.Visible=false
end
end
end
end
if _DY then local _R6=_DY:FindFirstChild("HPPlayer")
local _x6=_R6 and _R6:FindFirstChild("Debuff")
local _w6=_x6 and _x6:FindFirstChild("Confused")
if _w6 then pcall(function()_w6:Destroy()
end)
end
end
end
local _z6={}
local function _Q6(_d6)for _e6,_v6 in ipairs(_z6)do pcall(function()_v6:Disconnect()
end)
end
table.clear(_z6)
if not _d6 then return
end
table.insert(_z6,_d6:GetAttributeChangedSignal("Confused"):Connect(function()if _i6()and _d6:GetAttribute("Confused")==true then _P6(_d6)
end
end))
table.insert(_z6,_d6:GetAttributeChangedSignal("SkillLocked"):Connect(function()if _i6()and _d6:GetAttribute("SkillLocked")==true then _P6(_d6)
end
end))
if _i6()then _P6(_d6)
end
end
local function _Y6(_E6)if not _DV.AutoTPPos then return
end
if _DV.AutoBoss or _DV.AutoSecretBoss then return
end
local _u6=_pV()
if not _u6 then return
end
local _p6=_E6 or _VV or _Gz.Character
local _c6=(_p6 and _p6:FindFirstChild("HumanoidRootPart"))or _FY
if _c6 and(_c6.Position-_u6.Position).Magnitude>5 then _c6.CFrame=_u6
end
end
local function _N6(_b6)if not _DV.AutoFarmIsland then return
end
if _DV.AutoBoss or _DV.AutoSecretBoss then return
end
local _s6=_sV()
if not _s6 then return
end
local _X6=_b6 or _VV or _Gz.Character
local _t6=(_X6 and _X6:FindFirstChild("HumanoidRootPart"))or _FY
if _t6 and(_t6.Position-_s6.Position).Magnitude>5 then _t6.CFrame=_s6
end
end
if _VV then _Q6(_VV)
task.spawn(function()_Y6(_VV)
_N6(_VV)
end)
end
_Gz.CharacterAdded:Connect(function(_h6)_VV=_h6
_WY=_h6:WaitForChild("Humanoid",5)
_FY=_h6:WaitForChild("HumanoidRootPart",5)
_mY=_h6:WaitForChild("Skills",5)
_jY=_h6:WaitForChild("Stats",5)
_Q6(_h6)
task.wait(0.3)
_Y6(_h6)
_N6(_h6)
if _DV.FlyEnabled then _KY()
end
end)
local _L6=0
local _r6=false
local _o6=0
do local _O6=_Bz:FindFirstChild("BossPhase2Setup")
if _O6 and _O6:IsA("RemoteEvent")then _O6.OnClientEvent:Connect(function()_o6=os.clock()+5
end)
end
end
local _y6,_K6,_Z6,_C6,_n6,_M6
do local function _G6(_B6,_g6)local _l6=_mY or(_B6 and _B6:FindFirstChild("Skills"))
if not _l6 then return nil,nil
end
for _U6,_H6 in ipairs(_l6:GetChildren())do if _H6:IsA("NumberValue")then local _a6=_H6:GetAttribute("Key")or _H6.Name
if tostring(_a6)==_g6 then return _H6,_l6
end
end
end
return nil,_l6
end
local function _V6(_WZ)if not _iY then return nil
end
local _FZ=_iY:FindFirstChild(_WZ)
if _FZ then return _FZ
end
for _mZ,_jZ in ipairs(_iY:GetChildren())do if _jZ:IsA("GuiObject")then if tostring(_jZ:GetAttribute("Key")or"")==_WZ then return _jZ
end
for _kZ,_JZ in ipairs(_jZ:GetDescendants())do if _JZ:IsA("TextLabel")and _JZ.Name~="CD"and _JZ.Text==_WZ then return _jZ
end
end
end
end
return nil
end
function _y6(_DZ)if not _DY or not _DY.Visible then _r6=false
return false
end
if not _r6 then _r6=true
_L6=os.clock()
end
if(_PY and _PY.Visible)or(_qY and _qY.Visible)then return false
end
if _DZ:GetAttribute("Phase2")==true then _o6=0
return false
end
if _o6>0 and os.clock()<_o6 then return false
end
if not _i6()then if _DZ:GetAttribute("SkillLocked")or _DZ:GetAttribute("Confused")then return false
end
else _P6(_DZ)
end
local _SZ=_jY or _DZ:FindFirstChild("Stats")
if _SZ and _SZ:FindFirstChild("Stun")and _SZ.Stun.Value==true then return false
end
local _IZ=_Gz:GetAttribute("FishID")
local _iZ=(_IZ and _kY)and _kY:FindFirstChild(tostring(_IZ))or nil
if _iZ then local _PZ=_iZ:FindFirstChild("Ready")
if _PZ then if _PZ.Value~=true then return false
end
elseif os.clock()-_L6<3.1 then return false
end
if _iZ:GetAttribute("FinalPhase")==true or _iZ:GetAttribute("PreFinalPhase")==true then return false
end
elseif os.clock()-_L6<3.1 then return false
end
local _qZ=_mY or _DZ:FindFirstChild("Skills")
if _qZ then for _TZ,_AZ in ipairs(_qZ:GetChildren())do if _AZ:IsA("NumberValue")and(_AZ:GetAttribute("UsingSkill")or 0)>0 then return false
end
end
end
return true
end
function _K6(_fZ,_RZ)if _Uz then local _xZ=_Uz:FindFirstChild("FishingRod")
local _wZ=_Uz:FindFirstChild("FishingRodInventory")
local _zZ=(_xZ and _xZ.Value~=""and _wZ)and _wZ:FindFirstChild(_xZ.Value)or nil
local _QZ=_zZ and _zZ:FindFirstChild("Skill")
local _dZ=_QZ and _QZ:FindFirstChild(_RZ)
if _dZ and _dZ:IsA("StringValue")then return _dZ.Value~=""
end
end
local _eZ=_V6(_RZ)
if _eZ then return _eZ.Visible==true
end
local _vZ=_G6(_fZ,_RZ)
return _vZ~=nil
end
function _Z6(_YZ,_EZ)local _uZ=_V6(_EZ)
if _uZ then local _pZ=_uZ:FindFirstChild("CD")
if _pZ and _pZ.Visible then local _cZ=_pZ.Text or""
local _NZ=tonumber(string.match(_cZ,"%d+%.?%d*"))
if _NZ and _NZ>0 then return true
end
end
end
local _bZ=_G6(_YZ,_EZ)
if _bZ and(_bZ.Value>0 or(_bZ:GetAttribute("UsingSkill")or 0)>0)then return true
end
return false
end
local function _sZ(_XZ,_tZ)return _Z6(_XZ,_tZ)
end
function _C6(_hZ,_LZ)if not _K6(_hZ,_LZ)then return false
end
if _Z6(_hZ,_LZ)then return false
end
local _rZ=_V6(_LZ)
if _rZ then if not _rZ.Visible then return false
end
local _oZ=_rZ:FindFirstChild("Lock")
if _oZ and _oZ.Visible then if _i6()then _oZ.Visible=false
else return false
end
end
end
local _OZ,_yZ=_G6(_hZ,_LZ)
if _OZ then return true
end
if _yZ and#_yZ:GetChildren()>0 then return false
end
return _rZ~=nil and _rZ.Visible==true
end
local _KZ={"A","S","D"}
local _ZZ={A=Enum.KeyCode.A,S=Enum.KeyCode.S,D=Enum.KeyCode.D}
local _CZ={A=0,S=0,D=0}
local _nZ=0
local _MZ=0
local _GZ={}
local _BZ=UDim2.new(0.5,0,0.5,0)
local _gZ=false
local _lZ=nil
local _UZ=nil
_n6={Skip=false,Cache={},LastNotify=0,AntiChecked={}}
_n6.SecretFarmAllowed=function()return false
end
local function _HZ()if _gZ then return
end
if _n6.Skip or _n6.SkippingFish then return
end
if _n6.SecretFarmAllowed()then return
end
if not _DY or not _DY.Visible or not _IY then return
end
if not(_DV.AutoReel or _DV.AutoMiniGame or _DV.AutoBoss or _DV.AutoSecretBoss or _DV.AutoFarmIsland)then return
end
_gZ=true
local _aZ=_VV
if _aZ and(tonumber(_aZ:GetAttribute("GuildPower"))or 0)<99999999 then pcall(function()_aZ:SetAttribute("GuildPower",99999999)
local _VZ=_jY or _aZ:FindFirstChild("Stats")
local _WE=_VZ and _VZ:FindFirstChild("RodPower")
if _WE then local _FE=_WE.Value
_WE.Value=_FE+1
_WE.Value=_FE
end
end)
end
pcall(function()_IY:TweenPosition(_BZ,Enum.EasingDirection.InOut,Enum.EasingStyle.Linear,0,true)
_IY.Position=_BZ
end)
_gZ=false
end
local function _mE()if _IY and _IY~=_UZ then if _lZ then pcall(function()_lZ:Disconnect()
end)
_lZ=nil
end
_UZ=_IY
_lZ=_IY:GetPropertyChangedSignal("Position"):Connect(function()if not _gZ and _IY.Position.X.Scale~=0.5 then _HZ()
end
end)
end
end
_mE()
function _M6(_jE)if not _jE then return false
end
if not _jE:IsA("GuiButton")then _jE=_jE:FindFirstChildWhichIsA("GuiButton",true)or(_jE.Parent and _jE.Parent:IsA("GuiButton")and _jE.Parent)or nil
if not _jE then return false
end
end
local _kE=false
local _JE={"MouseButton1Click","Activated","MouseButton1Down","MouseButton1Up"}
if getconnections then for _DE,_SE in ipairs(_JE)do local _IE,_iE=pcall(function()return _jE[_SE]
end)
if _IE and _iE then pcall(function()for _PE,_qE in pairs(getconnections(_iE))do if _qE.Function then task.spawn(_qE.Function)
_kE=true
elseif _qE.Fire then _qE:Fire()
_kE=true
end
end
end)
end
end
end
if firesignal then for _TE,_AE in ipairs(_JE)do pcall(function()firesignal(_jE[_AE])
_kE=true
end)
end
end
return _kE
end
local _fE=(debug and debug.getupvalue)or getupvalue
local function _RE()if not _qY or not _qY.Visible then if#_GZ>0 then table.clear(_GZ)
end
_n6.P2Locked=false
return
end
local _xE=_qY:FindFirstChild("Bar")
local _wE=_qY:FindFirstChild("Hitbox")
if not _xE or not _wE then return
end
local _zE=_xE.Size.X.Scale
local _QE=_xE.Position.X.Scale+_zE*(0.5-_xE.AnchorPoint.X)
local _dE=_wE.Size.X.Scale
local _eE=_wE.Position.X.Scale-_dE*_wE.AnchorPoint.X
local _vE=os.clock()
table.insert(_GZ,{t=_vE,x=_QE})
while#_GZ>1 and(_vE-_GZ[1].t)>0.15 do table.remove(_GZ,1)
end
local _YE=math.max(tonumber(_DV.BossHitDelay)or 35,35)/1000
local _EE=false
local _uE=nil
if getconnections and _fE and _AY then pcall(function()for _pE,_cE in pairs(getconnections(_AY.MouseButton1Down))do local _NE=_cE.Function and _fE(_cE.Function,1)
if type(_NE)=="function"then _uE=_NE
local _bE=_fE(_NE,1)
local _sE=_fE(_NE,2)
local _XE=_fE(_NE,3)
local _tE=_fE(_NE,4)
local _hE=_fE(_NE,5)
local _LE=_fE(_NE,6)
local _rE=_fE(_NE,7)
local _oE=_fE(_NE,8)
local _OE=_fE(_NE,9)
if _bE==true and type(_sE)=="number"and type(_XE)=="number"and type(_tE)=="number"and type(_hE)=="number"and type(_LE)=="number"and type(_rE)=="number"and type(_oE)=="number"and type(_OE)=="number"then if math.abs(_oE-_dE)<0.005 and math.abs(_OE-_eE)<0.005 then _EE=true
local _yE=(_vE-0.025-_XE)%_tE*_hE
if _LE<_yE then _yE=_LE*2-_yE
end
local _KE=_rE+_yE
local _ZE=_oE*0.3
local _CE=_KE>=(_OE-_ZE*0.8)and _KE<=(_OE+_oE+_ZE*0.8)
if _n6.P2Locked and(not _CE or _vE-_n6.P2LockTick>0.6)then _n6.P2Locked=false
end
if _CE and not _n6.P2Locked and(_vE-_sE>=_YE or _sE==0)and _vE-_MZ>=_YE then _MZ=_vE
_n6.P2Locked=true
_n6.P2LockTick=_vE
_NE(false)
end
end
break
end
end
end
end)
end
if _EE then return
end
if _vE-_MZ<_YE then return
end
local _nE=_QE
local _ME=_vE-0.041
for _GE=#_GZ,1,-1 do if _GZ[_GE].t<=_ME then _nE=_GZ[_GE].x
break
end
end
local _BE=_dE*0.2
local _gE=_qY:FindFirstChild("HitboxBad")
if _gE and _gE.Visible then local _lE=_gE.Size.X.Scale
local _UE=_gE.Position.X.Scale-_lE*_gE.AnchorPoint.X
if _nE>=(_UE-0.01)and _nE<=(_UE+_lE+0.01)then return
end
end
local _HE=_nE>=(_eE-_BE)and _nE<=(_eE+_dE+_BE)
if _n6.P2Locked and(not _HE or _vE-_n6.P2LockTick>0.6)then _n6.P2Locked=false
end
if _HE and not _n6.P2Locked then _MZ=_vE
_n6.P2Locked=true
_n6.P2LockTick=_vE
local _aE=false
if _uE then pcall(function()_uE(false)
_aE=true
end)
end
if not _aE and _AY then if getconnections then pcall(function()for _VE,_WK in pairs(getconnections(_AY.MouseButton1Down))do if _WK.Function then task.spawn(_WK.Function)
_aE=true
elseif _WK.Fire then _WK:Fire()
_aE=true
end
end
end)
end
if not _aE and firesignal then pcall(function()firesignal(_AY.MouseButton1Down)
_aE=true
end)
end
end
if not _aE then pcall(function()_nz:SendMouseButtonEvent(0,0,0,true,game,0)
task.delay(0.01,function()_nz:SendMouseButtonEvent(0,0,0,false,game,0)
end)
end)
end
end
end
local function _FK(_mK)if not _mK or not _mK:IsA("GuiObject")then return false
end
if _mK:GetAttribute("Trap")==true or _mK:GetAttribute("trap")==true or _mK:GetAttribute("IsTrap")==true then return true
end
if string.find(string.lower(_mK.Name),"trap",1,true)then return true
end
local function _jK(_kK)return _kK and _kK.R>0.65 and _kK.G<0.45 and _kK.B<0.45 and _kK.R>_kK.G*1.8 and _kK.R>_kK.B*1.8
end
if _jK(_mK.BackgroundColor3)then return true
end
if(_mK:IsA("ImageLabel")or _mK:IsA("ImageButton"))and _jK(_mK.ImageColor3)then return true
end
for _JK,_DK in ipairs(_mK:GetDescendants())do if _DK:IsA("GuiObject")then if _jK(_DK.BackgroundColor3)then return true
end
if(_DK:IsA("ImageLabel")or _DK:IsA("ImageButton"))and _jK(_DK.ImageColor3)then return true
end
end
end
return false
end
local function _SK()if not _PY or not _PY.Visible then return
end
local _IK=os.clock()
if _IK-_nZ<0.025 then return
end
_nZ=_IK
for _iK,_PK in ipairs(_KZ)do if _IK-(_CZ[_PK]or 0)>=0.05 then local _qK=_PY:FindFirstChild("Progression".._PK)
if _qK then local _TK=_qK:FindFirstChild("BarFrame")
local _AK=_TK and _TK.Position.Y.Scale or 0.85
local _fK=nil
local _RK=999
for _xK,_wK in ipairs(_qK:GetChildren())do if _wK.Name=="Note_FX"and _wK:IsA("GuiObject")and _wK.Visible then local _zK=math.abs(_wK.Position.Y.Scale-_AK)
if _zK<_RK then _RK=_zK
_fK=_wK
end
end
end
if _fK and not _FK(_fK)and _RK<=0.18 then _CZ[_PK]=_IK
local _QK=_qK:FindFirstChild("Button")
if _QK then _M6(_QK)
end
if _fK.Parent~=nil then local _dK=_ZZ[_PK]
if _dK then pcall(function()_nz:SendKeyEvent(true,_dK,false,game)
task.delay(0.02,function()_nz:SendKeyEvent(false,_dK,false,game)
end)
end)
end
end
if _fK.Parent~=nil and _RK<=0.1 and _fY then pcall(function()_fK:Destroy()
_fY:FireServer("hit")
end)
end
end
end
end
end
end
local function _eK(_vK)if not _DY or not _DY.Visible then return
end
_mE()
_HZ()
if _DV.AutoMiniGame then _RE()
if _vK and not _n6.BTActive then _SK()
end
end
end
_Oz.RenderStepped:Connect(function()_eK(false)
end)
_Oz.Stepped:Connect(function()_eK(false)
end)
_Oz.Heartbeat:Connect(function()_eK(true)
end)
end
local _YK,_EK,_uK,_pK,_cK,_NK
do function _YK(_bK)if not _bK then return nil
end
if _bK:IsA("BasePart")then return _bK
end
if _bK:IsA("Model")then return _bK:FindFirstChild("HumanoidRootPart")or _bK:FindFirstChild("Head")or _bK.PrimaryPart or _bK:FindFirstChildWhichIsA("BasePart",true)
end
return _bK:FindFirstChildWhichIsA("BasePart",true)
end
local function _sK(_XK)if not _XK then return false
end
if _XK:GetAttribute("Secret")==true or _XK:GetAttribute("Rarity")=="Secret"then return true
end
local _tK=tostring(_XK:GetAttribute("Name")or _XK:GetAttribute("FishName")or _XK.Name)
local _hK=string.lower(_tK)
if string.find(_hK,"secret")or string.find(_hK,"long diaohai")or string.find(_hK,"longdiaohai")or string.find(_hK,"diaohai")or string.find(_hK,"wuzhi")then return true
end
local _LK=_gz:FindFirstChild("Inventory")
local _rK=_LK and _LK:FindFirstChild(_tK)
local _oK=_KV(_rK)
if _oK and(_oK.Secret==true or _oK.Rarity=="Secret"or(_oK.Boss==true and(tonumber(_oK.Chance)or 100)<=1))then return true
end
return false
end
local function _OK(_yK)_yK=tostring(_yK or"")
_yK=string.gsub(_yK,"<[^>]+>","")
_yK=string.gsub(_yK,"%s*[xX]%s*%d+$","")
_yK=string.gsub(_yK,"^%s+","")
_yK=string.gsub(_yK,"%s+$","")
return _yK
end
local function _KK(_ZK)local _CK=string.lower(_ZK)
if _CK==""then return nil
end
local _nK=_n6.Cache[_CK]
if _nK~=nil then return _nK or nil
end
local _MK=_gz:FindFirstChild("Inventory")
local _GK=_MK and _MK:FindFirstChild(_ZK)
if not _GK and _MK then for _BK,_gK in ipairs(_MK:GetChildren())do if string.lower(_gK.Name)==_CK then _GK=_gK
break
end
end
end
local _lK=_GK and _KV(_GK)or nil
_n6.Cache[_CK]=_lK or false
return _lK
end
function _n6.SecretSet()local _UK=os.clock()
if _n6.SecretSetData and _UK-(_n6.SecretSetAt or 0)<30 then return _n6.SecretSetData
end
local _HK={}
pcall(function()local _aK=_gz:FindFirstChild("FishingAreaRarity")
local _VK=_aK and require(_aK)
local _WO=type(_VK)=="table"and _VK["Secret Boss"]
if type(_WO)=="table"then for _FO,_mO in pairs(_WO)do if type(_FO)=="string"then _HK[string.lower(_FO)]=true
end
if type(_mO)=="string"then _HK[string.lower(_mO)]=true
end
end
end
end)
_n6.SecretSetData=_HK
_n6.SecretSetAt=_UK
return _HK
end
function _n6.Classify()local _jO,_kO,_JO,_DO=false,false,"",false
pcall(function()local _SO={}
local _IO=_Gz:GetAttribute("FishID")
local _iO=(_IO and _kY)and _kY:FindFirstChild(tostring(_IO))or nil
if _iO then table.insert(_SO,_iO.Name)
for _PO,_qO in pairs(_iO:GetAttributes())do local _TO=string.lower(tostring(_PO))
if type(_qO)=="string"then table.insert(_SO,_qO)
if _TO=="rarity"then local _AO=string.lower(_qO)
if _AO=="secret"then _kO=true
end
if _AO=="boss"then _jO=true
end
end
elseif _qO==true then if _TO=="boss"or _TO=="isboss"then _jO=true
end
if _TO=="secret"or _TO=="issecret"then _kO=true
end
end
end
end
local _fO=_DY and _DY:FindFirstChild("ProgressionBar")
if _fO then for _RO,_xO in ipairs(_fO:GetDescendants())do if _xO:IsA("TextLabel")and _xO.Text~=""then table.insert(_SO,_xO.Text)
end
end
end
for _wO,_zO in ipairs(_SO)do local _QO=_OK(_zO)
if _QO~=""then if _JO==""then _JO=_QO
end
local _dO=_KK(_QO)
if _dO then _JO=_QO
_DO=true
if _dO.Boss==true then _jO=true
end
if _dO.Secret==true or _dO.SecretBoss==true or _dO.Rarity=="Secret"then _kO=true
end
if _dO.SpecialBoss==true then _jO=true
end
if type(_dO.Rarity)=="string"and string.lower(_dO.Rarity)=="boss"then _jO=true
end
end
local _eO=string.lower(_QO)
if _n6.SecretSet()[_eO]then _kO=true
_DO=true
end
if string.find(_eO,"secret",1,true)or string.find(_eO,"diaohai",1,true)or string.find(_eO,"wuzhi",1,true)then _kO=true
end
end
end
end)
return _jO,_kO,_JO,_DO
end
function _n6.HoldingRod()local _vO=_Gz.Character
return _vO~=nil and _vO:GetAttribute("Type")=="Fishing Rod"
end
function _n6.Recycle()if _n6.Busy then return
end
_n6.Busy=true
_n6.NeedRod=true
task.spawn(function()local function _YO()pcall(function()_Hz:InvokeServer("1")
end)
end
local function _EO(_uO,_pO)local _cO=0
while _n6.HoldingRod()~=_uO and _cO<_pO do task.wait(0.01)
_cO=_cO+0.01
end
return _n6.HoldingRod()==_uO
end
if _n6.HoldingRod()then _YO()
_EO(false,0.6)
end
for _NO=1,4 do if _n6.HoldingRod()then break
end
_YO()
if _EO(true,0.5)then break
end
end
local _bO=_Gz.Character
local _sO=_bO and _bO:FindFirstChild("HumanoidRootPart")
if _bO and _sO and _n6.HoldingRod()then local _XO=0
while _bO:GetAttribute("Fishing")and _XO<0.4 do task.wait(0.01)
_XO=_XO+0.01
end
if _n6.HoldingRod()and not _bO:GetAttribute("Fishing")then pcall(function()_az:FireServer(_sO.CFrame)
end)
end
end
if _n6.HoldingRod()then _n6.NeedRod=false
end
_n6.Busy=false
end)
end
local function _tO(_hO)local _LO=string.lower(tostring(_hO:GetAttribute("Name")or _hO:GetAttribute("FishName")or _hO.Name))
_LO=string.gsub(_LO,"%s+","")
return string.find(_LO,"diaohai",1,true)~=nil or string.find(_LO,"longdiao",1,true)~=nil
end
function _EK(_rO)local _oO=workspace:FindFirstChild("NPC")
local _OO=_oO and _oO:FindFirstChild("Boss")
if not _rO then if _OO then for _yO,_KO in ipairs(_OO:GetChildren())do local _ZO=_YK(_KO)
if _ZO and not _sK(_KO)and not _tO(_KO)then return _KO,_ZO
end
end
end
local _CO=workspace:FindFirstChild("Boss")or workspace:FindFirstChild("BossZone")
if _CO then local _nO=_YK(_CO)
if _nO then return _CO,_nO
end
end
return nil,nil
end
local _MO={}
if _OO then table.insert(_MO,_OO)
end
if _oO then local _GO=_oO:FindFirstChild("God")
if _GO then table.insert(_MO,_GO)
end
end
for _BO,_gO in ipairs({"God","BossSetUp"})do local _lO=workspace:FindFirstChild(_gO)
if _lO then table.insert(_MO,_lO)
end
end
for _UO,_HO in ipairs(_MO)do for _aO,_VO in ipairs(_HO:GetChildren())do if _tO(_VO)or _sK(_VO)then local _Wl=_YK(_VO)
if _Wl then return _VO,_Wl
end
end
end
end
for _Fl,_ml in ipairs({"NPC","God","BossSetUp"})do local _jl=workspace:FindFirstChild(_ml)
if _jl then for _kl,_Jl in ipairs(_jl:GetDescendants())do if _Jl:IsA("Model")and _tO(_Jl)then local _Dl=_YK(_Jl)
if _Dl then return _Jl,_Dl
end
end
end
end
end
return nil,nil
end
local _Sl={Enzo=CFrame.new(-114.81,9.28,1356.67,0.05,-0.00,-1.00,-0.00,1.00,-0.00,1.00,0.00,0.05),LongDiaoHai=CFrame.new(-2873.62,32.17,1337.38,-0.09,0.00,-1.00,0.00,1.00,0.00,1.00,-0.00,-0.09)}
local function _Il(_il)return _il and _Sl.LongDiaoHai or _Sl.Enzo
end
local _Pl=0
local _ql=""
local _Tl=0
local function _Al(_fl,_Rl,_xl,_wl)end
function _uK(_zl)if not _zl then return""
end
if _zl:IsA("TextButton")or _zl:IsA("TextLabel")then if _zl.Text and _zl.Text~=""then return _zl.Text
end
end
local _Ql=_zl:FindFirstChild("Title")or _zl:FindFirstChild("TextLabel")or _zl:FindFirstChildWhichIsA("TextLabel",true)
if _Ql and _Ql.Text then return _Ql.Text
end
return""
end
local function _dl(_el)if not _el then return false
end
if not _el:IsA("GuiButton")then _el=_el:FindFirstChildWhichIsA("GuiButton",true)or(_el.Parent and _el.Parent:IsA("GuiButton")and _el.Parent)or nil
if not _el then return false
end
end
local _vl=false
pcall(function()if _el.AbsolutePosition and _el.AbsoluteSize then local _Yl=_el.AbsolutePosition+(_el.AbsoluteSize/2)
_nz:SendMouseButtonEvent(_Yl.X,_Yl.Y,0,true,game,0)
task.wait(0.02)
_nz:SendMouseButtonEvent(_Yl.X,_Yl.Y,0,false,game,0)
_vl=true
end
end)
local _El={"MouseButton1Click","Activated","MouseButton1Down","MouseButton1Up"}
if getconnections then for _ul,_pl in ipairs(_El)do local _cl,_Nl=pcall(function()return _el[_pl]
end)
if _cl and _Nl then pcall(function()for _bl,_sl in pairs(getconnections(_Nl))do if _sl.Function then task.spawn(_sl.Function)
_vl=true
elseif _sl.Fire then _sl:Fire()
_vl=true
end
end
end)
end
end
end
if firesignal then for _Xl,_tl in ipairs(_El)do pcall(function()firesignal(_el[_tl])
_vl=true
end)
end
end
return _vl
end
function _pK()if not _JY then return nil
end
local _hl=_JY:FindFirstChild("Menu")
if not _hl then return nil
end
for _Ll,_rl in ipairs({"BossFight","Boss","BossMenu","Raid","SecretBoss"})do local _ol=_hl:FindFirstChild(_rl)
if _ol and _ol:IsA("GuiObject")then return _ol
end
end
for _Ol,_yl in ipairs(_hl:GetChildren())do if _yl:IsA("Frame")and _yl.Name~="Info"and _yl.Name~="Black"and _yl.Name~="Dialogue"then local _Kl=_yl:FindFirstChild("Title")
if _Kl and _Kl:IsA("TextLabel")and string.find(string.lower(_Kl.Text),"boss")then return _yl
end
if _yl:FindFirstChild("Normal",true)and _yl:FindFirstChild("Hard",true)and _yl:FindFirstChild("Nightmare",true)then return _yl
end
end
end
return nil
end
local function _Zl(_Cl,_nl)local _Ml={}
local _Gl=_Uz and _Uz:FindFirstChild("FishingRod")
local _Bl=_Gl and _Gl.Value or""
if _Bl==""then table.insert(_Ml,"No Fishing Rod equipped")
end
local _gl=_Gz.Character
local _ll=_gl and _gl:FindFirstChild("Stats")
local _Ul=_gz:FindFirstChild("Inventory")
if _Ul and _nl then local _Hl=_Ul:FindFirstChild(_nl)
local _al=_KV(_Hl)
local _Vl=_Bl~=""and _Ul:FindFirstChild(_Bl)or nil
local _W1=_KV(_Vl)
if _al and tonumber(_al.Power)and _W1 and tonumber(_W1.Power)then local _F1=_ll and _ll:FindFirstChild("RodPower")and tonumber(_ll.RodPower.Value)or 0
local _m1=_ll and _ll:FindFirstChild("FishPower")and tonumber(_ll.FishPower.Value)or 0
local _j1=tonumber(_W1.Power)+_F1
local _k1=math.max(1,tonumber(_al.Power)-_m1+4)
if(_j1/_k1)<=0.5 then table.insert(_Ml,string.format("Low Power (%d/%d)",math.floor(_j1),math.floor(_k1)))
end
end
end
if _Cl then for _J1,_D1 in ipairs(_Cl:GetDescendants())do if _D1:IsA("TextLabel")and _D1.Visible then local _S1=_D1.Text or""
local _I1,_i1=string.match(_S1,"^%s*(%d+)%s*/%s*(%d+)%s*$")
if _I1 and _i1 then local _P1=tonumber(_I1)
local _q1=tonumber(_i1)
if _P1 and _q1 and _P1<_q1 then table.insert(_Ml,_I1.."/".._i1)
end
end
end
end
end
return _Ml
end
local _T1=false
local _A1=0
local function _f1(_R1)if not _R1 or not _R1.Visible then return
end
local _x1=false
for _w1,_z1 in ipairs(_R1:GetDescendants())do if _z1:IsA("GuiButton")and _z1.Visible then local _Q1=string.lower(_z1.Name)
local _d1=string.lower(_uK(_z1))
local _e1=_z1.Parent and string.lower(_z1.Parent.Name)or""
if _Q1=="close"or _d1=="x"or _e1=="close"then if _dl(_z1)then _x1=true
break
end
end
end
end
if not _x1 then pcall(function()_R1.Visible=false
end)
end
end
function _cK(_v1)_T1=false
_A1=0
local _Y1=_Uz and _Uz:FindFirstChild("FishingRod")
if not _Y1 or _Y1.Value==""then return
end
local _E1=_EK(_v1)
if not _E1 then return
end
local _u1=_FY or(_Gz.Character and _Gz.Character:FindFirstChild("HumanoidRootPart"))
local _p1=_Il(_v1)
if _u1 and _p1 then _u1.CFrame=_p1
end
local _c1=_VV or _Gz.Character
if _c1 and _c1:GetAttribute("Type")~="Fishing Rod"then pcall(function()_Hz:InvokeServer("1")
end)
end
end
local function _N1(_b1)if not _b1 then return false
end
if not _b1:IsA("GuiButton")then _b1=_b1:FindFirstChildWhichIsA("GuiButton",true)or(_b1.Parent and _b1.Parent:IsA("GuiButton")and _b1.Parent)or nil
if not _b1 then return false
end
end
local _s1=false
local _X1={"MouseButton1Click","Activated"}
if firesignal then for _t1,_h1 in ipairs(_X1)do pcall(function()firesignal(_b1[_h1])
_s1=true
end)
end
end
if getconnections then for _L1,_r1 in ipairs(_X1)do local _o1,_O1=pcall(function()return _b1[_r1]
end)
if _o1 and _O1 then pcall(function()for _y1,_K1 in pairs(getconnections(_O1))do if _K1.Function then task.spawn(_K1.Function)
_s1=true
elseif _K1.Fire then _K1:Fire()
_s1=true
end
end
end)
end
end
end
return _s1
end
local function _Z1(_C1,_n1,_M1,_G1)local _B1=_M1 or"Normal"
local _g1=_C1:FindFirstChild("Select",true)
local _l1=(_g1 and _g1:FindFirstChild("button"))or _g1 or _C1
local _U1=nil
if _l1 then _U1=_l1:FindFirstChild(_B1)
if not _U1 then for _H1,_a1 in ipairs(_l1:GetChildren())do if _a1:IsA("GuiButton")and string.lower(_a1.Name)==string.lower(_B1)then _U1=_a1
break
end
end
end
end
if not _U1 then for _V1,_W9 in ipairs(_C1:GetDescendants())do if _W9:IsA("GuiButton")then local _F9=string.lower(_W9.Name)
local _m9=string.lower(_uK(_W9))
if _F9==string.lower(_B1)or _m9==string.lower(_B1)then _U1=_W9
break
end
end
end
end
if _U1 then _N1(_U1)
task.wait(0.6)
end
local _j9=_C1:FindFirstChild("Fight",true)
if not _j9 then for _k9,_J9 in ipairs(_C1:GetDescendants())do if _J9:IsA("GuiButton")then local _D9=string.lower(_J9.Name)
local _S9=string.lower(_uK(_J9))
if _D9=="fight"or _S9=="fight"or string.find(_D9,"fight")or string.find(_S9,"fight")then _j9=_J9
break
end
end
end
end
if _j9 then _N1(_j9)
end
local _I9={}
local function _i9(_P9)if not _P9 then return
end
for _q9,_T9 in ipairs(_P9:GetChildren())do if _T9:IsA("RemoteEvent")or _T9:IsA("RemoteFunction")then table.insert(_I9,_T9)
end
end
end
_i9(_Bz)
local _A9=_yz:FindFirstChild("Remotes")
_i9(_A9)
local _f9={["bossfight"]=true,["startbossfight"]=true,["startboss"]=true,["boss"]=true,["challengeboss"]=true,["fightboss"]=true,["choosedialogueoption"]=true}
for _R9,_x9 in ipairs(_I9)do local _w9=string.lower(_x9.Name)
if _f9[_w9]or string.find(_w9,"boss")then pcall(function()if _x9:IsA("RemoteEvent")then _x9:FireServer(_B1)
elseif _x9:IsA("RemoteFunction")then _x9:InvokeServer(_B1)
end
end)
end
end
task.wait(0.25)
if _DY and _DY.Visible then _T1=true
_A1=os.clock()
if _C1 then _f1(_C1)
end
return true
end
return false
end
local _z9=0
local _Q9=""
do local _d9=_Bz:FindFirstChild("ReplicateFishCaught")
if _d9 and _d9:IsA("RemoteEvent")then _d9.OnClientEvent:Connect(function(_e9,_v9)if _e9==_Gz.Character then _z9=os.clock()
_Q9=tostring(_v9 or"")
_T1=false
_A1=0
end
end)
end
end
local _Y9=false
local function _E9()if _Y9 then return
end
local _u9=_Gz:GetAttribute("FishID")
local _p9=workspace:FindFirstChild("Fishes")
local _c9=(_u9 and _p9)and _p9:FindFirstChild(tostring(_u9))or nil
if not _c9 then return
end
_Y9=true
task.spawn(function()local _N9=_DY and _DY:FindFirstChild("ProgressionBar")
local _b9=_N9 and _N9:FindFirstChild("FishName")
local _s9=(_b9 and _b9.Text~=""and _b9.Text)or"Boss"
local _X9=_c9:FindFirstChild(_Gz.UserId.."_PlayerHealth")
local _t9=tonumber(_c9:GetAttribute("MaxHealth"))or 100
local _h9=0.5
local _L9=_X9 and _X9.Value or 100
local _r9=_c9:IsA("ValueBase")and _c9.Value or 0
local _o9=false
local _O9=1
while _c9.Parent and(_DY and _DY.Visible)do _A1=os.clock()
if _X9 then _L9=_X9.Value
end
if _c9:IsA("ValueBase")then _r9=_c9.Value
end
if _c9:GetAttribute("FinalPhase")==true then _o9=true
end
if _c9:GetAttribute("FinalPhaseHP")~=nil then _O9=tonumber(_c9:GetAttribute("FinalPhaseHP"))or _O9
end
if _IY then _h9=_IY.Position.X.Scale
end
task.wait(0.1)
end
task.wait(0.35)
_T1=false
_A1=0
_Y9=false
end)
end
local function _y9(_K9,_Z9)if _Z9 then _T1=true
_A1=os.clock()
_E9()
return
end
local _C9=os.clock()
if _C9-_Pl<0.8 then return
end
_Pl=_C9
if _T1 and(_C9-_A1>45)then _T1=false
end
local _n9=_DV.AutoSecretBoss
local _M9=_Uz and _Uz:FindFirstChild("FishingRod")
if not _M9 or _M9.Value==""then return
end
local _G9,_B9=_EK(_n9)
local _g9=_Il(_n9)
if not _G9 and not _g9 then return
end
local _l9=_FY or(_K9 and _K9:FindFirstChild("HumanoidRootPart"))
local _U9=_G9 and(_G9:GetAttribute("Name")or _G9.Name)or(_n9 and"Long DiaoHai"or"Enzo")
if _l9 then if _g9 then if(_l9.Position-_g9.Position).Magnitude>5 then _l9.CFrame=_g9
end
elseif _B9 then local _H9=(_l9.Position-_B9.Position).Magnitude
if _H9>12 then _l9.CFrame=_B9.CFrame*CFrame.new(0,3,-5)
end
end
end
if _K9 and _K9:GetAttribute("Type")~="Fishing Rod"then pcall(function()_Hz:InvokeServer("1")
end)
end
local _a9=_pK()
if not _T1 then if _B9 and _l9 then local _V9=_G9 and _G9:FindFirstChildWhichIsA("ProximityPrompt",true)
if not _V9 and _B9 then _V9=_B9:FindFirstChildWhichIsA("ProximityPrompt",true)
end
if _V9 and fireproximityprompt then pcall(function()fireproximityprompt(_V9)
end)
end
end
if _a9 and _a9.Visible then _Z1(_a9,_U9,_DV.BossMode,_n9)
end
if _JY and not _T1 then local _Wb=_JY:FindFirstChild("Menu")
local _Fb=_Wb and _Wb:FindFirstChild("Dialogue")
if _Fb and _Fb.Visible then local _mb=_Fb:FindFirstChild("ButtonFrame")
if _mb then local _jb=nil
local _kb=string.lower(_DV.BossMode or"Normal")
for _Jb,_Db in ipairs(_mb:GetChildren())do if _Db:IsA("TextButton")and _Db.Name~="Template"and _Db.Visible then local _Sb=_Db:FindFirstChild("Title")
local _Ib=_Sb and string.lower(_Sb.Text)or""
if string.find(_Ib,_kb)then _jb=_Db
break
elseif not _jb and not string.find(_Ib,"close")and not string.find(_Ib,"cancel")and not string.find(_Ib,"nevermind")and not string.find(_Ib,"leave")then _jb=_Db
end
end
end
if _jb then _dl(_jb)
end
end
end
end
else if _a9 and _a9.Visible then _f1(_a9)
end
if _K9 and _K9:GetAttribute("Type")~="Fishing Rod"then pcall(function()_Hz:InvokeServer("1")
end)
elseif _K9 and not _K9:GetAttribute("Fishing")then local _ib=_FY or _K9:FindFirstChild("HumanoidRootPart")
if _ib then pcall(function()_az:FireServer(_ib.CFrame)
end)
end
end
end
end
do local _Pb
local _qb={CurrentTarget=nil,CurrentToken=nil,CurrentRunId=0,HasHooked=false,PendingCancel=false,LastCast=0,LastCancel=0,LastFastCancel=0,LastProgress=0,LastNotify="",}
local _Tb={"secret","hidden","mythic","event","rare"}
local _Ab={foggy=true,["blazing sun"]=true,snowy=true,windy=true,rainy=true,thunderstorm=true,}
local _fb={}
local function _Rb(_xb)_xb=string.lower(tostring(_xb or""))
for _wb,_zb in ipairs(_Tb)do if string.find(_xb,_zb,1,true)then return true
end
end
return false
end
local function _Qb()local _db={}
pcall(function()local _eb=_gz:FindFirstChild("FishingAreaRarity")
if _eb then local _vb=require(_eb)
if type(_vb)=="table"and type(_vb["Secret Boss"])=="table"then for _Yb in pairs(_vb["Secret Boss"])do _db[string.lower(tostring(_Yb))]=true
end
end
end
end)
pcall(function()local _Eb=_gz:FindFirstChild("Inventory")
if _Eb then for _ub,_pb in ipairs(_Eb:GetChildren())do if _pb:IsA("ModuleScript")then local _cb,_Nb=pcall(require,_pb)
if _cb and type(_Nb)=="table"and _Nb.SecretBoss==true then _db[string.lower(tostring(_Nb.FishName or _pb.Name))]=true
end
end
end
end
end)
_fb=_db
end
task.spawn(function()while true do _Qb()
task.wait(30)
end
end)
local function _bb()local _sb="Clear"
pcall(function()local _Xb=_JY and _JY.Parent and _JY or _Gz.PlayerGui:FindFirstChild("MainGui")
local _tb=_Xb and _Xb:FindFirstChild("Info")
local _hb=_tb and _tb:FindFirstChild("Info")
local _Lb=_hb and _hb:FindFirstChild("Weather")
local _rb=_Lb and _Lb:FindFirstChild("Value")
if _rb then local _ob=_rb:IsA("TextLabel")and _rb.Text or _rb.Value
_sb=tostring(_ob):gsub("Weather:%s*","")
end
end)
return _sb
end
_Pb=function()if not _DV.AutoFarmSecretBoss then return false
end
if _DV.AutoBoss or _DV.AutoSecretBoss then return false
end
if _DV.AutoSecretBossMode~="Only When Weather"then return true
end
local _Ob=string.lower(_bb())
_Ob=_Ob:gsub("^weather:%s*",""):gsub("^%s+",""):gsub("%s+$","")
return _Ab[_Ob]==true
end
_n6.SecretFarmAllowed=_Pb
local function _yb()local _Kb=_qb.CurrentTarget
local _Zb={Name=nil,SecretBoss=false}
if type(_Kb)=="table"then _Zb.Name=_Kb.FishName or _Kb.Name or _Kb.fishName
_Zb.SecretBoss=_Kb.SecretBoss==true
elseif typeof(_Kb)=="Instance"then _Zb.Name=_Kb:GetAttribute("FishName")or _Kb.Name
_Zb.SecretBoss=_Kb:GetAttribute("SecretBoss")==true
elseif type(_Kb)=="string"then _Zb.Name=_Kb
end
local _Cb=_Gz:GetAttribute("FishID")
local _nb=workspace:FindFirstChild("Fishes")
local _Mb=_Cb and _nb and _nb:FindFirstChild(tostring(_Cb))
if _Mb then _Zb.Name=_Zb.Name or _Mb:GetAttribute("FishName")or _Mb.Name
_Zb.SecretBoss=_Zb.SecretBoss or _Mb:GetAttribute("SecretBoss")==true
end
local _Gb=_JY and _JY:FindFirstChild("Fishing")
local _Bb=_Gb and _Gb:FindFirstChild("ProgressionBar")
local _gb=_Bb and _Bb:FindFirstChild("FishName")
if(not _Zb.Name or _Zb.Name==""or _Zb.Name=="???")and _gb and _gb.Text~=""then _Zb.Name=_gb.Text
end
return _Zb
end
local function _lb(_Ub)_Ub=_Ub or _yb()
local _Hb=string.lower(tostring(_Ub.Name or""))
return _Ub.SecretBoss==true or _fb[_Hb]==true or _Rb(_Hb)
end
local function _ab()_qb.CurrentTarget=nil
_qb.CurrentToken=nil
_qb.HasHooked=false
_qb.PendingCancel=false
end
local function _Vb()if not _Pb()or os.clock()-_qb.LastCast<0.35 then return false
end
local _WC=_Gz.Character
if not _WC then return false
end
if _WC:GetAttribute("Fishing")and not _WC:GetAttribute("Retractable")then return false
end
_qb.LastCast=os.clock()
_ab()
pcall(function()local _FC=_WC:FindFirstChild("HumanoidRootPart")
if _FC then _az:FireServer(_FC.CFrame)
else _az:FireServer()
end
end)
return true
end
local function _mC()if not _Pb()then return false
end
local _jC=_Gz.Character
if not _jC then return false
end
if not _jC:GetAttribute("Fishing")then _ab()
return true
end
_qb.PendingCancel=true
pcall(function()local _kC=_JY and _JY:FindFirstChild("Fishing")
local _JC=_kC and _kC:FindFirstChild("BarFrame")
local _DC=_JC and _JC:FindFirstChild("Bar")
if _DC then _DC.Position=UDim2.new(-0.15,0,_DC.Position.Y.Scale,_DC.Position.Y.Offset)
end
end)
if _qb.CurrentToken and os.clock()-_qb.LastFastCancel>0.5 then _qb.LastFastCancel=os.clock()
pcall(function()_Bz.FishingMinigame:FireServer(false,_qb.CurrentToken)
end)
end
if not _jC:GetAttribute("Retractable")then return false
end
if os.clock()-_qb.LastCancel<0.35 then return false
end
_qb.LastCancel=os.clock()
pcall(function()local _SC=_jC:FindFirstChild("HumanoidRootPart")
if _SC then _az:FireServer(_SC.CFrame)
else _az:FireServer()
end
end)
return false
end
local function _IC(_iC)if not _Pb()or not _lb(_iC)then return
end
local _PC="Secret Boss"..tostring(_iC.Name)
if _qb.LastNotify~=_PC then _qb.LastNotify=_PC
pcall(function()_hz:Notify({Title="Secret Boss",Content="Đang farm Secret Boss: "..tostring(_iC.Name or"Unknown"),Duration=3,})
end)
end
if os.clock()-_qb.LastProgress>0.04 then _qb.LastProgress=os.clock()
pcall(function()_Vz:FireServer()
end)
end
end
task.spawn(function()while true do if not _Pb()then task.wait(1.5)
else task.wait(0.2)
pcall(function()local _qC=_Gz.Character
local _TC=_JY and _JY:FindFirstChild("Fishing")
if _qC and _qC:GetAttribute("Fishing")then if _qb.PendingCancel then _mC()
elseif _qb.HasHooked and _TC and _TC.Visible then local _AC=_yb()
if _lb(_AC)then _qb.PendingCancel=false
_IC(_AC)
elseif _AC.Name and _AC.Name~="???"then _qb.PendingCancel=true
_mC()
end
end
else _ab()
if not _n6.HoldingRod()and not _n6.Busy then local _fC=0
while not _n6.HoldingRod()and _fC<4 and _Pb()do _fC=_fC+1
pcall(function()_Hz:InvokeServer("1")
end)
local _RC=0
while not _n6.HoldingRod()and _RC<0.6 do task.wait(0.05)
_RC=_RC+0.05
end
end
end
if _n6.HoldingRod()then task.wait(0.1)
_Vb()
end
end
end)
end
end
end)
pcall(function()local _xC=_Bz:FindFirstChild("FishingMinigame")
if not _xC then return
end
_xC.OnClientEvent:Connect(function(_wC,_zC,_QC)if not _wC or not _zC then return
end
_qb.CurrentTarget=_wC
_qb.CurrentToken=_QC
_qb.HasHooked=true
_qb.PendingCancel=false
_qb.CurrentRunId=_qb.CurrentRunId+1
local _dC=_qb.CurrentRunId
if not _Pb()then return
end
local _eC=_yb()
if not _lb(_eC)then _qb.PendingCancel=true
task.delay(0.15,_mC)
return
end
task.spawn(function()local _vC=true
local _YC
local _EC=_JY and _JY:FindFirstChild("Fishing")
if _EC then _YC=_EC:GetPropertyChangedSignal("Visible"):Connect(function()if not _EC.Visible then _vC=false
if _YC then _YC:Disconnect()
end
end
end)
end
while _vC do if not _Pb()or _dC~=_qb.CurrentRunId then break
end
local _uC=_yb()
if not _lb(_uC)then _qb.PendingCancel=true
_mC()
break
end
_IC(_uC)
task.wait(0.05)
end
if _YC then _YC:Disconnect()
end
if _Pb()and _dC==_qb.CurrentRunId then _ab()
end
end)
end)
end)
end
do function _n6.FishNames()local _pC,_cC={},{}
pcall(function()local _NC=_gz:FindFirstChild("Inventory")
if _NC then for _bC,_sC in ipairs(_NC:GetChildren())do if _sC:IsA("ModuleScript")and not _cC[_sC.Name]then _cC[_sC.Name]=true
table.insert(_pC,_sC.Name)
end
end
end
end)
if#_pC==0 then pcall(function()local _XC=_Uz:FindFirstChild("Index")
if _XC then for _tC,_hC in ipairs(_XC:GetChildren())do if not _cC[_hC.Name]then _cC[_hC.Name]=true
table.insert(_pC,_hC.Name)
end
end
end
end)
end
if#_pC==0 then _pC={"Rainbow Dragonfish","Frost Queenfish","Nameless Octoparasite","Colossal Tigerfish","Heavenpiercer Turtle","Golden Guardian Fish","Crimson Electric Eel","Frost Kingfish","Ascended Perch","Primordial Kunfish Overlord","Warbringer Shark","Flying Fish Emperor","Flying Fish Empress","Sanguine Fish","Draconic Koi","Reborn Puffer Beast",}
end
table.sort(_pC)
return _pC
end
function _n6.CreateFishSearchDropdown(_LC)local _rC=_LC.Options
local _oC=""
local _OC
local function _yC(_KC)local _ZC={}
if type(_KC)=="table"then for _CC,_nC in ipairs(_KC)do _ZC[#_ZC+1]=_nC
end
elseif type(_KC)=="string"and _KC~=""then _ZC[1]=_KC
end
return _ZC
end
local function _MC()if _oC==""then return _rC
end
local _GC,_BC={},{}
for _gC,_lC in ipairs(_LC.Pinned or{})do _GC[_lC]=true
end
for _UC,_HC in ipairs(_rC)do if _GC[_HC]or string.find(string.lower(_HC),_oC,1,true)then _BC[#_BC+1]=_HC
end
end
return _BC
end
_LC.Tab:CreateInput({Flag=_LC.Flag.."Search",Name="Tìm cá",Placeholder="Nhập tên cá...",Finished=false,Callback=function(_aC)_oC=string.lower((tostring(_aC or""):gsub("^%s+",""):gsub("%s+$","")))
if not _OC then return
end
local _VC=_MC()
_OC:Refresh(_VC,true,true)
local _W5,_F5={},{}
for _m5,_j5 in ipairs(_VC)do _F5[_j5]=true
end
for _k5,_J5 in ipairs(_LC.GetSelected())do if _F5[_J5]then _W5[#_W5+1]=_J5
end
end
if _LC.Multi then _OC:Set(_W5,true)
else _OC:Set(_W5[1]or _VC[1],true)
end
end})
_OC=_LC.Tab:CreateDropdown({Flag=_LC.Flag,Name=_LC.Name,Options=_rC,CurrentOption=_LC.Current,MultipleOptions=_LC.Multi==true,AllowNone=false,Callback=function(_D5)local _S5=_yC(_D5)
if _LC.Multi then local _I5={}
for _i5,_P5 in ipairs(_MC())do _I5[_P5]=true
end
local _q5={}
for _T5,_A5 in ipairs(_LC.GetSelected())do if not _I5[_A5]then _q5[#_q5+1]=_A5
end
end
for _f5,_R5 in ipairs(_S5)do _q5[#_q5+1]=_R5
end
_S5=_q5
end
_LC.SetSelected(_S5)
end})
return _OC
end
local function _x5()local _w5=_DV.FavoriteFish
if type(_w5)~="string"or _w5==""or _w5=="No Selection"then return 0
end
local _z5=_Uz:FindFirstChild("Inventory")
local _Q5=_Bz:FindFirstChild("FavoriteItem")
if not _z5 or not _Q5 then return 0
end
local _d5=_w5.." | "
local _e5=0
for _v5,_Y5 in ipairs(_z5:GetChildren())do if not _DV.AutoFavoriteFish then break
end
if _Y5.Name:sub(1,#_d5)==_d5 and not _Y5.Name:match(" | Favorite$")then _Q5:FireServer(_Y5.Name)
_e5=_e5+1
task.wait(0.12)
end
end
return _e5
end
task.spawn(function()while true do if _DV.AutoFavoriteFish then pcall(_x5)
end
task.wait(1)
end
end)
local _E5=0
local _u5=""
local function _p5()local _c5={}
if type(_DV.SkipFishList)=="table"then for _N5,_b5 in ipairs(_DV.SkipFishList)do _c5[string.lower(_OK(_b5))]=true
end
end
return _c5
end
local function _s5(_X5)local _t5={}
local function _h5(_L5)if _L5~=nil and tostring(_L5)~=""and tostring(_L5)~="???"then table.insert(_t5,tostring(_L5))
end
end
if type(_X5)=="table"then _h5(_X5.FishName)
;
_h5(_X5.Name)
;
_h5(_X5.Fish)
;
_h5(_X5.fishName)
elseif typeof(_X5)=="Instance"then _h5(_X5:GetAttribute("FishName"))
;
_h5(_X5.Name)
elseif type(_X5)=="string"then _h5(_X5)
end
pcall(function()local _r5=_Gz:GetAttribute("FishID")
local _o5=workspace:FindFirstChild("Fishes")
local _O5=_r5 and _o5 and _o5:FindFirstChild(tostring(_r5))
if _O5 then _h5(_O5:GetAttribute("FishName"))
;
_h5(_O5.Name)
end
end)
pcall(function()local _y5=_DY and _DY:FindFirstChild("ProgressionBar")
local _K5=_y5 and _y5:FindFirstChild("FishName")
if _K5 and _K5:IsA("TextLabel")then _h5(_K5.Text)
end
end)
return _t5
end
local function _Z5(_C5,_n5)for _M5,_G5 in ipairs(_C5)do local _B5=string.lower(_OK(_G5))
if _n5[_B5]then return _B5
end
local _g5=string.gsub(_B5,"%s*[%(%[|].-$","")
_g5=string.gsub(_g5,"%s+$","")
if _g5~=""and _n5[_g5]then return _g5
end
end
return nil
end
pcall(function()local _l5=_Bz:FindFirstChild("FishingMinigame")
if not _l5 then return
end
_l5.OnClientEvent:Connect(function(_U5,_H5,_a5)local _V5=type(_U5)=="table"and(_U5.FishName or _U5.Name or _U5.Fish)or nil
_u5=tostring(_V5 or"")
if not _DV.AutoSkipFish or _a5==nil then return
end
_E5=_E5+1
local _WW=_E5
task.spawn(function()local _FW=_p5()
if next(_FW)==nil then return
end
local _mW
for _jW=1,20 do if not _DV.AutoSkipFish or _WW~=_E5 then return
end
_mW=_Z5(_s5(_U5),_FW)
if _mW then break
end
task.wait(0.03)
end
if not _mW then return
end
pcall(function()_hz:Notify({Title="Bỏ qua cá",Content="Đang bỏ qua: ".._mW,Duration=2})
end)
_n6.SkippingFish=true
local _kW=0
for _JW=1,60 do if not _DV.AutoSkipFish or _WW~=_E5 then break
end
pcall(function()local _DW=_JY and _JY:FindFirstChild("Fishing")
local _SW=_DW and _DW:FindFirstChild("BarFrame")
local _IW=_SW and _SW:FindFirstChild("Bar")
if _IW then _IW.Position=UDim2.new(-0.15,0,_IW.Position.Y.Scale,_IW.Position.Y.Offset)
end
end)
pcall(function()_l5:FireServer(false,_a5)
end)
local _iW=_Gz.Character
if _iW and _iW:GetAttribute("Retractable")and os.clock()-_kW>0.12 then _kW=os.clock()
pcall(function()local _PW=_iW:FindFirstChild("HumanoidRootPart")
if _PW then _az:FireServer(_PW.CFrame)
else _az:FireServer()
end
end)
end
task.wait(0.08)
if not(_DY and _DY.Visible)then break
end
end
_n6.SkippingFish=false
end)
end)
end)
local _qW=1.15/1.4
local _TW=0.22
local _AW={"A","S","D"}
local _fW={A=Enum.KeyCode.A,S=Enum.KeyCode.S,D=Enum.KeyCode.D}
local _RW={active=false,generation=0,seen=setmetatable({},{__mode="k"}),lastPress={A=0,S=0,D=0},pressBusy={A=false,S=false,D=false},connections={},}
local function _xW(_wW)return string.find(string.lower(tostring(_wW or"")),"black tortoise",1,true)~=nil
end
local function _zW(_QW)local _dW=_QW.BackgroundColor3
return _dW.R>0.65 and _dW.G*1.5<_dW.R and _dW.B*1.5<_dW.R
end
local function _eW(_vW)if _RW.pressBusy[_vW]then return false
end
local _YW=_fW[_vW]
if not _YW then return false
end
_RW.pressBusy[_vW]=true
local _EW=pcall(function()_nz:SendKeyEvent(true,_YW,false,game)
end)
if not _EW then _RW.pressBusy[_vW]=false
return false
end
task.delay(0.025,function()pcall(function()_nz:SendKeyEvent(false,_YW,false,game)
end)
_RW.pressBusy[_vW]=false
end)
return true
end
local function _uW(_pW,_cW,_NW,_bW,_sW)if not _bW or _bW.Name~="Note_FX"or not _bW:IsA("GuiObject")then return
end
if _RW.seen[_bW]then return
end
_RW.seen[_bW]=true
if _zW(_bW)then return
end
local _XW,_tW=pcall(function()return _bW.Position.Y.Scale
end)
local _hW,_LW=pcall(function()return _cW.Position.Y.Scale
end)
if not _XW or not _hW or type(_tW)~="number"or type(_LW)~="number"then return
end
local _rW=math.clamp(tonumber(_DV.BlackTortoiseBand)or 0.12,0.03,0.17)
local _oW=math.clamp((_LW-math.min(0.04,_rW*0.35)-_tW)/_qW,0,2)
local function _OW(_yW)if _sW~=_RW.generation or not _RW.active or not _DV.AutoMiniGame then return
end
if _bW.Parent~=_pW or not _bW.Visible or not _pW.Parent then return
end
if _LW+_TW<_bW.Position.Y.Scale then return
end
local _KW,_ZW=nil,math.huge
for _CW,_nW in ipairs(_pW:GetChildren())do if _nW.Name=="Note_FX"and _nW:IsA("GuiObject")and _nW.Visible then local _MW=math.abs(_nW.Position.Y.Scale-_LW)
if _MW<=_TW and _MW<_ZW then _KW,_ZW=_nW,_MW
end
end
end
if _KW==_bW and not _zW(_KW)then local _GW=os.clock()
if _GW-(_RW.lastPress[_NW]or 0)>=0.12 and _eW(_NW)then _RW.lastPress[_NW]=_GW
end
elseif _yW>0 then task.delay(0.04,_OW,_yW-1)
end
end
task.delay(_oW,_OW,5)
end
local function _BW()_RW.active=false
_n6.BTActive=false
_RW.generation=_RW.generation+1
_RW.seen=setmetatable({},{__mode="k"})
_RW.pressBusy={A=false,S=false,D=false}
for _gW,_lW in ipairs(_RW.connections)do pcall(function()_lW:Disconnect()
end)
end
table.clear(_RW.connections)
end
local function _UW(_HW)_BW()
if type(_HW)~="table"or tostring(_HW.Mode):lower()~="hard"then return
end
if not _DV.AutoMiniGame then return
end
local _aW=_RW.generation
task.defer(function()if _aW~=_RW.generation then return
end
local _VW=_xW(_u5)
if not _VW then local _WX,_FX,_mX,_jX=pcall(_n6.Classify)
_VW=_WX and _xW(_jX)
end
if not _VW then return
end
local _kX=_DY and _DY:FindFirstChild("Rhythm")
if not _kX then return
end
_RW.active=true
_n6.BTActive=true
for _JX,_DX in ipairs(_AW)do local _SX=_kX:FindFirstChild("Progression".._DX)
local _IX=_SX and _SX:FindFirstChild("BarFrame")
if _SX and _IX then table.insert(_RW.connections,_SX.ChildAdded:Connect(function(_iX)pcall(_uW,_SX,_IX,_DX,_iX,_aW)
end))
for _PX,_qX in ipairs(_SX:GetChildren())do pcall(_uW,_SX,_IX,_DX,_qX,_aW)
end
end
end
end)
end
pcall(function()local _TX=_Bz:FindFirstChild("RhythmStart")
local _AX=_Bz:FindFirstChild("RhythmStop")
if _TX then _TX.OnClientEvent:Connect(_UW)
end
if _AX then _AX.OnClientEvent:Connect(_BW)
end
end)
end
local _fX=0
task.spawn(function()local _RX=0
local _xX=0
local _wX=1
local _zX=nil
local _QX=false
local _dX=false
local _eX=nil
local _vX=0
local _YX=nil
while task.wait(0.08)do local _EX=os.clock()
_RY()
local _uX=_DY and _DY.Visible or false
if _QX and not _uX then _fX=_EX
end
_QX=_uX
local _pX=_DV.FilterBossFish and not(_DV.AutoBoss or _DV.AutoSecretBoss or _DV.AutoFarmIsland or _n6.SecretFarmAllowed())
local _cX=_Gz:GetAttribute("FishID")
if _pX and(_uX or _cX~=nil)then local _NX=tostring(_cX or"gui")
if _NX~=_YX then _YX=_NX
_eX=_EX
_dX=false
_vX=0
end
if not _dX and _vX==0 then local _bX,_sX,_XX,_tX=_n6.Classify()
local _hX=_EX-_eX
if _DV.FilterBossFish and _bX and not _sX then _dX=true
pcall(function()_hz:Notify({Title="Bộ lọc cá",Content="Đã tìm thấy: "..(_XX~=""and _XX or"boss fish")..(_sX and" (bí mật)"or" (boss)"),Duration=4,})
end)
elseif(_tX and _hX>0.15)or _hX>3.0 then _vX=1
if _EX-_n6.LastNotify>3 then _n6.LastNotify=_EX
pcall(function()_hz:Notify({Title="Bộ lọc cá",Content="Đã bỏ qua: "..(_XX~=""and _XX or"unknown fish")..(_sX and" [secret]"or(_bX and" [boss]"or" [normal]")),Duration=2,})
end)
end
_n6.Recycle()
end
elseif _vX==1 and _uX and(_EX-_eX)>4 then _vX=2
end
_n6.Skip=not _dX
else _dX=false
_eX=nil
_YX=nil
_vX=0
_n6.Skip=false
end
if _n6.NeedRod and not _n6.Busy then if not _DV.FilterBossFish or _n6.HoldingRod()then _n6.NeedRod=false
elseif _EX-(_n6.LastEquip or 0)>0.3 then _n6.LastEquip=_EX
task.spawn(function()pcall(function()_Hz:InvokeServer("1")
end)
end)
end
end
local _LX=(_DV.AutoReel or _DV.AutoMiniGame or _DV.AutoBoss or _DV.AutoSecretBoss or _DV.AutoFarmIsland)and not _n6.Skip and not _n6.SkippingFish and not secretFarmOn
local _rX=_n6.SecretFarmAllowed()
local _oX=(_DV.AutoCast or _DV.AutoFarmIsland or _DV.FilterBossFish)and not _rX and not(_n6.HasPendingEventFish and _n6.HasPendingEventFish())
local _OX=(_DV.AutoSkill or _DV.AutoBoss or _DV.AutoSecretBoss or _DV.AutoFarmIsland)and not _n6.Skip
if not _uX then _wX=1
_zX=nil
end
if _LX and _uX then pcall(function()_Vz:FireServer()
end)
end
if _OX and _uX then local _yX=_VV
local _KX=_DV.SkillOrder
local _ZX=type(_KX)=="table"and#_KX or 0
if _yX and _ZX>0 then if _wX<1 or _wX>_ZX then _wX=1
end
local _CX=nil
for _nX=1,_ZX do local _MX=((_wX-1+(_nX-1))%_ZX)+1
local _GX=_KX[_MX]
if _C6(_yX,_GX)then _CX=_MX
break
end
end
if _CX then _wX=_CX
local _BX=_KX[_wX]
if _y6(_yX)and(_EX-_xX>=0.25)then _xX=os.clock()
_zX=_BX
pcall(function()_WV:FireServer(_BX)
end)
_wX=(_wX%_ZX)+1
end
else for _gX=1,_ZX do local _lX=((_wX-1+(_gX-1))%_ZX)+1
if _K6(_yX,_KX[_lX])and not _Z6(_yX,_KX[_lX])then _wX=_lX
break
end
end
end
end
end
if _DV.AutoBoss or _DV.AutoSecretBoss then _y9(_VV,_uX)
else if not _uX then _Y6(_VV)
_N6(_VV)
end
if _oX and not _uX then local _UX=(_DV.AutoCastMethod=="Instant")and 0.05 or math.clamp(tonumber(_DV.CastDelay)or 1,0,10)
if(_EX-_fX>=_UX)and(_EX-_RX>=_UX)then local _HX=_VV
if _HX then if _HX:GetAttribute("Type")~="Fishing Rod"then if _DV.AutoFarmIsland then _RX=_EX
pcall(function()_Hz:InvokeServer("1")
end)
end
elseif not _HX:GetAttribute("Fishing")then local _aX=_FY or _HX:FindFirstChild("HumanoidRootPart")
if _aX then _RX=_EX
pcall(function()_az:FireServer(_aX.CFrame)
end)
end
end
end
end
end
end
end
end)
_Bz:WaitForChild("Slam").OnClientEvent:Connect(function(_VX)if(_DV.AutoMiniGame or _DV.AutoReel or _DV.AutoBoss or _DV.AutoSecretBoss or _DV.AutoFarmIsland)and not _n6.Skip and _VX then task.wait(0.05)
local _We=false
pcall(function()local _Fe=_DY and _DY:FindFirstChild("TrashCan")
local _me=_Fe and _Fe:FindFirstChild("Slam")
local _je=_me and _me:FindFirstChild("Button")
local _ke=_je and _je:FindFirstChild("Line")
if _ke then _ke.Size=UDim2.new(1,0,1,0)
end
if _je then _dl(_je)
if not _me.Parent then _We=true
end
end
if not _We then _VX:FireServer("Perfect")
if _me and _me.Parent then _me:Destroy()
end
end
end)
end
end)
_Bz:WaitForChild("Charge").OnClientEvent:Connect(function(_Je)if(_DV.AutoMiniGame or _DV.AutoReel or _DV.AutoBoss or _DV.AutoSecretBoss or _DV.AutoFarmIsland)and not _n6.Skip and _Je then task.wait(1.05)
pcall(function()local _De=_DY and _DY:FindFirstChild("TrashCan")
local _Se=_De and _De:FindFirstChild("Charge")
local _Ie=_Se and _Se:FindFirstChild("Button")
if _Ie and _Se.Parent then _dl(_Ie)
end
if _Se and _Se.Parent then _Je:FireServer()
_Se:Destroy()
end
end)
end
end)
function _NK()for _ie,_Pe in ipairs(_Lz:GetPlayers())do local _qe=_Pe.Character
if _qe then local _Te=_qe:FindFirstChild("Head")
if _Te then local _Ae=_Te:FindFirstChild("UZEXHubESP")
if _Ae then _Ae:Destroy()
end
end
end
end
end
end
local function _fe()if not _DV.ESPEnabled then return
end
for _Re,_xe in ipairs(_Lz:GetPlayers())do if _xe~=_Gz then local _we=_xe.Character
if _we then local _ze=_we:FindFirstChild("Head")
local _Qe=_we:FindFirstChildOfClass("Humanoid")
if _ze and _Qe then local _de=_ze:FindFirstChild("UZEXHubESP")
if _Qe.Health>0 then if not _de then _de=Instance.new("BillboardGui")
_de.Name="UZEXHubESP"
_de.Adornee=_ze
_de.Size=UDim2.new(0,200,0,25)
_de.StudsOffset=Vector3.new(0,2.5,0)
_de.AlwaysOnTop=true
_de.MaxDistance=math.huge
local _ee=Instance.new("TextLabel")
_ee.Name="NameText"
_ee.Parent=_de
_ee.Size=UDim2.new(1,0,1,0)
_ee.BackgroundTransparency=1
_ee.TextScaled=false
_ee.TextSize=13
_ee.Font=Enum.Font.GothamBold
_ee.TextColor3=Color3.fromRGB(255,255,255)
_ee.TextStrokeTransparency=0
_ee.TextStrokeColor3=Color3.fromRGB(0,0,0)
_ee.TextXAlignment=Enum.TextXAlignment.Center
_de.Parent=_ze
end
_de.NameText.Text=_xe.DisplayName
else if _de then _de:Destroy()
end
end
end
end
end
end
end
task.spawn(function()while task.wait(0.4)do if _DV.ESPEnabled then _fe()
end
end
end)
local _ve=0
local _Ye=0
local _Ee
local _ue=_yz:FindFirstChild("Remotes")
local function _pe(_ce)return _Bz:FindFirstChild(_ce)or(_ue and _ue:FindFirstChild(_ce))
end
local function _Ne(_be,...)if not _be then return false
end
local _se={...}
local _Xe=pcall(function()if _be:IsA("RemoteEvent")then _be:FireServer(unpack(_se))
elseif _be:IsA("RemoteFunction")then _be:InvokeServer(unpack(_se))
end
end)
return _Xe
end
local function _te(_he,_Le)if not _he or _he==""then return
end
local _re=math.max(1,math.floor(tonumber(_Le)or 1))
local _oe=_pe("BuyBait")or _pe("Bait")or _pe("PurchaseBait")or _pe("BaitShop")or _pe("BuyItem")
if _oe then _Ne(_oe,_he,_re)
else pcall(function()_mV:FireServer(_he,_re)
end)
end
end
do local _Oe=0.5
local _ye=2
local _Ke=60
local _Ze={"inventory","backpack","bag","storage","capacity"}
local _Ce=nil
local _ne=0
local _Me=0
local _Ge=false
local _Be=false
local function _ge()_ve=os.clock()
pcall(function()_FV:FireServer("All")
end)
end
local function _le(_Ue)local _He,_ae=string.match(tostring(_Ue or""),"([%d%.,]+)%s*/%s*([%d%.,]+)")
_He=tonumber((tostring(_He or""):gsub(",","")))
_ae=tonumber((tostring(_ae or""):gsub(",","")))
if _He and _ae and _ae>0 then return _He,_ae
end
return nil
end
local function _Ve(_WN)_WN=string.lower(tostring(_WN or""))
for _FN,_mN in ipairs(_Ze)do if string.find(_WN,_mN,1,true)then return true
end
end
return false
end
local function _jN(_kN)local _JN=_kN
while _JN do if _JN:IsA("GuiObject")and not _JN.Visible then return false
end
if _JN:IsA("ScreenGui")and not _JN.Enabled then return false
end
_JN=_JN.Parent
end
return true
end
local function _DN(_SN,_IN)local _iN,_PN=_SN,0
while _iN and _iN~=_IN and _PN<6 do if _Ve(_iN.Name)then return true
end
_iN=_iN.Parent
_PN=_PN+1
end
return false
end
local function _qN(_TN)for _AN,_fN in ipairs(_TN:GetDescendants())do if(_fN:IsA("TextLabel")or _fN:IsA("TextButton"))and _fN.Text~=""and _le(_fN.Text)and _DN(_fN,_TN)and not(_DY and _fN:IsDescendantOf(_DY))then return _fN
end
end
return nil
end
local function _RN(_xN)for _wN,_zN in ipairs(_xN:GetDescendants())do if _zN:IsA("TextLabel")and _zN.Text~=""and _zN.TextTransparency<0.9 then local _QN=string.lower(_zN.Text)
if string.find(_QN,"full",1,true)and _Ve(_QN)and _jN(_zN)then return true
end
end
end
return false
end
local function _dN()local _eN=_Gz:FindFirstChild("PlayerGui")
if not _eN then return nil
end
local _vN=os.clock()
if not(_Ce and _Ce.Parent)and _vN-_ne>=5 then _ne=_vN
_Ce=_qN(_eN)
end
if _Ce and _Ce.Parent then local _YN,_EN=_le(_Ce.Text)
if _YN and _EN then return _YN>=math.max(1,_EN-1)
end
end
if _vN-_Me>=1 then _Me=_vN
_Ge=_RN(_eN)
end
if _Ge then return true
end
return nil
end
task.spawn(function()while task.wait(0.5)do if _DV.AutoSell then local _uN=os.clock()
if _DV.AutoSellMethod=="When full"then if _uN-_ve>=_ye then local _pN,_cN=pcall(_dN)
if not _pN then _cN=nil
end
if _cN==true then _ge()
elseif _cN==nil then if not _Be then _Be=true
_hz:Notify({Title="Tự động bán cá",Content="Không đọc được sức chứa túi cá, phương thức này sẽ bán cá mỗi 60 giây.",Type="warning",Duration=6,})
end
if _uN-_ve>=_Ke then _ge()
end
end
end
elseif _uN-_ve>=_Oe then _ge()
end
end
end
end)
end
task.spawn(function()while task.wait(0.8)do if _DV.AutoBuyBait and _DV.SelectedBuyBait~=""then local _NN=math.max(1,tonumber(_DV.BuyBaitDelay)or 1)*60
local _bN=os.clock()
if _bN-_Ye>=_NN then _Ye=_bN
_te(_DV.SelectedBuyBait,_DV.BuyBaitAmount)
end
end
if _DV.AutoCraftBait and _DV.SelectedBait~=""then pcall(function()_mV:FireServer(_DV.SelectedBait,math.max(1,math.floor(tonumber(_DV.BaitAmount)or 1)))
end)
end
if _DV.AutoCraftRod and _DV.SelectedRod~=""then pcall(function()_jV:FireServer(_DV.SelectedRod)
end)
end
end
end)
local _sN,_XN
do _sN=0
local _tN=_Bz:WaitForChild("ChooseDialogueOption",9e9)
local function _hN()local _LN=_Gz:FindFirstChild("PlayerGui")
local _rN=_LN and _LN:FindFirstChild("MainGui")
local _oN=_rN and _rN:FindFirstChild("Menu")
local _ON=_oN and _oN:FindFirstChild("Dialogue")
if _ON and _ON.Visible then local _yN=_ON:FindFirstChild("Name",true)or _ON:FindFirstChild("NPCName",true)or _ON:FindFirstChild("Title",true)
local _KN=_yN and tostring(_yN.Text)or""
if _KN==""or string.find(_KN,"Ticket",1,true)or string.find(_KN,"Giver",1,true)then _ON.Visible=false
end
end
end
local function _ZN()local _CN=workspace:FindFirstChild("NPC")
local _nN=_CN and _CN:FindFirstChild("Function")
local _MN=_nN and _nN:FindFirstChild("Ticket Quest Giver")
if _MN then return _MN
end
return workspace:WaitForChild("NPC",9e9):WaitForChild("Function",9e9):WaitForChild("Ticket Quest Giver",9e9)
end
local function _GN()local _BN=_Uz
if not _BN then return nil
end
local _gN=_BN:FindFirstChild("Quest")
local _lN=_gN and _gN:FindFirstChild("Main")
if _lN then local _UN=_lN:FindFirstChild("Hard Ticket Quest")or _lN:FindFirstChild("Easy Ticket Quest")or _lN:FindFirstChild("Ticket Quest")
if _UN then return _UN
end
end
for _HN,_aN in ipairs(_BN:GetChildren())do if _aN:IsA("Folder")and(_aN.Name=="Hard Ticket Quest"or _aN.Name=="Easy Ticket Quest"or _aN.Name=="Ticket Quest")then return _aN
end
end
return nil
end
local function _VN(_Wc)if not _Wc then return false
end
local _Fc=_gz and _gz:FindFirstChild("MainQuest")
local _mc=nil
if _Fc and _Fc:FindFirstChild(_Wc.Name)then pcall(function()_mc=require(_Fc[_Wc.Name])
end)
end
local _jc=false
for _kc,_Jc in ipairs(_Wc:GetChildren())do if _Jc:IsA("NumberValue")then _jc=true
local _Dc=nil
if _mc and _mc[tonumber(_Jc.Name)]then _Dc=tonumber(_mc[tonumber(_Jc.Name)][2])
elseif _Wc:FindFirstChild("Objective")then local _Sc=_Wc.Objective:FindFirstChild(_Jc.Name)
if _Sc and _Sc:IsA("StringValue")then local _Ic=string.split(_Sc.Value,",")
_Dc=tonumber(_Ic[2])
end
end
if _Dc and _Jc.Value<_Dc then return false
end
end
end
return _jc
end
local function _ic()local _Pc=_GN()
if not _Pc then return"none"
end
if _VN(_Pc)then return"completed"
else return"in_progress"
end
end
local _qc
do local _Tc=0
local _Ac=0
local _fc=0
local _Rc=""
local function _xc(_wc)if not _wc or _wc==""then return nil
end
local _zc=string.lower(_wc)
if string.find(_zc,"another quest in")or string.find(_zc,"take another quest in")then local _Qc,_dc=string.match(_zc,"(%d+)%s*:%s*(%d+)")
if _Qc and _dc then return(tonumber(_Qc)or 0)*60+(tonumber(_dc)or 0)
end
local _ec=string.match(_zc,"(%d+)%s*m")
local _vc=string.match(_zc,"(%d+)%s*s")
if _ec or _vc then return(tonumber(_ec)or 0)*60+(tonumber(_vc)or 0)
end
end
return nil
end
local function _Yc(_Ec)if not _Ec or _Ec==""then return
end
if _Ec==_Rc then return
end
local _uc=_xc(_Ec)
if _uc and _uc>0 and _uc<=3600 then _Rc=_Ec
_Tc=os.clock()+_uc
end
end
local function _pc(_cc)local _Nc=_cc or _ZN()
if not _Nc then return
end
local _bc={[1]="Ticket Quest Giver",[2]=1,[3]="Quest",[4]={[1]=_Nc}}
pcall(function()_tN:FireServer(unpack(_bc))
end)
_hN()
_fc=os.clock()
end
local function _sc(_Xc)local _tc=_Xc or _ZN()
if not _tc then return
end
local _hc=(_DV.TicketQuestMode=="Easy")and"EasyAcceptQuest"or"HardAcceptQuest"
local _Lc=(_DV.TicketQuestMode=="Easy")and 1 or 2
local _rc={[1]="Ticket Quest Giver",[2]=_Lc,[3]=_hc,[4]={[1]=_tc,[2]="Ticket Quest"}}
pcall(function()_tN:FireServer(unpack(_rc))
end)
_hN()
_Ac=os.clock()
end
local function _oc()task.spawn(function()task.wait(0.6)
if _DV.SelectedBuyBait~=""then _te(_DV.SelectedBuyBait,_DV.BuyBaitAmount)
end
task.wait(0.8)
if _Ee then pcall(_Ee,true)
end
end)
end
function _qc()local _Oc=os.clock()
if _Oc<_Tc then return
end
local _yc=_ZN()
if not _yc then return
end
local _Kc=_ic()
if _Kc=="completed"then if _Oc-_fc>=1.5 then _pc(_yc)
_oc()
task.wait(0.5)
_sc(_yc)
end
elseif _Kc=="in_progress"then return
else if _Oc>=_Tc and(_Oc-_Ac>=2)then _pc(_yc)
task.wait(0.4)
_sc(_yc)
end
end
end
pcall(function()local _Zc=_Gz and _Gz:FindFirstChild("PlayerGui")
if _Zc then _Zc.DescendantAdded:Connect(function(_Cc)if _Cc:IsA("TextLabel")then _Yc(_Cc.Text)
_Cc:GetPropertyChangedSignal("Text"):Connect(function()_Yc(_Cc.Text)
end)
end
end)
end
end)
pcall(function()for _nc,_Mc in ipairs(_Bz:GetChildren())do if _Mc:IsA("RemoteEvent")then _Mc.OnClientEvent:Connect(function(...)local _Gc={...}
for _Bc,_gc in ipairs(_Gc)do if type(_gc)=="string"then _Yc(_gc)
elseif type(_gc)=="table"then for _lc,_Uc in pairs(_gc)do if type(_Uc)=="string"then _Yc(_Uc)
end
end
end
end
end)
end
end
end)
pcall(function()local _Hc=_Bz:FindFirstChild("StartDialogue")
if _Hc and _Hc:IsA("RemoteEvent")then _Hc.OnClientEvent:Connect(function(_ac,_Vc,_WJ)if not _DV.AutoTicketQuest then return
end
if tostring(_ac)=="Ticket Quest Giver"or(_Vc and _Vc.Name=="Ticket Quest Giver")then _hN()
if type(_WJ)=="table"and type(_WJ[1])=="string"then _Yc(_WJ[1])
end
end
end)
end
end)
end
local function _FJ()local _mJ=workspace:FindFirstChild("NPC")
local _jJ=_mJ and _mJ:FindFirstChild("Function")
local _kJ=_jJ and _jJ:FindFirstChild("Zeng Tianguo")
if _kJ then return _kJ
end
return workspace:WaitForChild("NPC",9e9):WaitForChild("Function",9e9):WaitForChild("Zeng Tianguo",9e9)
end
local function _JJ()local _DJ=_Uz or(_lz and _lz:FindFirstChild(tostring(_Gz.UserId)))
if not _DJ then return nil
end
local _SJ=_DJ:FindFirstChild("Quest")
local _IJ=_SJ and _SJ:FindFirstChild("Main")
local _iJ={_IJ,_SJ,_DJ}
for _PJ,_qJ in ipairs(_iJ)do if _qJ then for _TJ,_AJ in ipairs(_qJ:GetChildren())do if _AJ:IsA("Folder")or _AJ:IsA("Configuration")then local _fJ=string.lower(_AJ.Name)
if string.find(_fJ,"zeng",1,true)and string.find(_fJ,"tianguo",1,true)then return _AJ
end
end
end
end
end
local _RJ=_Gz:FindFirstChild("PlayerGui")and _Gz.PlayerGui:FindFirstChild("MainGui")
local _xJ=_RJ and _RJ:FindFirstChild("Menu")and _RJ.Menu:FindFirstChild("Quest")and _RJ.Menu.Quest:FindFirstChild("Menu")and _RJ.Menu.Quest.Menu:FindFirstChild("Main_Quest")
if _xJ then for _wJ,_zJ in ipairs(_xJ:GetChildren())do if _zJ:IsA("GuiObject")and _zJ.Visible and _zJ.Name~="Template"then local _QJ=string.lower(_zJ.Name)
if string.find(_QJ,"zeng",1,true)and string.find(_QJ,"tianguo",1,true)then if _IJ then return _IJ:FindFirstChild(_zJ.Name)or _zJ
end
return _zJ
end
end
end
end
return nil
end
local function _dJ(_eJ)if not _eJ then return false
end
local _vJ=_gz and _gz:FindFirstChild("MainQuest")
local _YJ=nil
if _vJ then local _EJ=_vJ:FindFirstChild(_eJ.Name)or _vJ:FindFirstChild("Zeng Tianguo")or _vJ:FindFirstChild("Zeng Tianguo Quest")
if _EJ then pcall(function()_YJ=require(_EJ)
end)
end
end
local _uJ=false
for _pJ,_cJ in ipairs(_eJ:GetChildren())do if _cJ:IsA("NumberValue")then _uJ=true
local _NJ=nil
if _YJ and _YJ[tonumber(_cJ.Name)]then _NJ=tonumber(_YJ[tonumber(_cJ.Name)][2])
elseif _eJ:FindFirstChild("Objective")then local _bJ=_eJ.Objective:FindFirstChild(_cJ.Name)
if _bJ and _bJ:IsA("StringValue")then local _sJ=string.split(_bJ.Value,",")
_NJ=tonumber(_sJ[2])
end
end
if _NJ and _cJ.Value<_NJ then return false
end
end
end
if not _uJ then local _XJ=_Gz:FindFirstChild("PlayerGui")and _Gz.PlayerGui:FindFirstChild("MainGui")
local _tJ=_XJ and _XJ:FindFirstChild("Menu")and _XJ.Menu:FindFirstChild("Quest")and _XJ.Menu.Quest:FindFirstChild("Menu")and _XJ.Menu.Quest.Menu:FindFirstChild("Main_Quest")
local _hJ=_tJ and(_tJ:FindFirstChild(_eJ.Name)or _tJ:FindFirstChild("Zeng Tianguo")or _tJ:FindFirstChild("Zeng Tianguo Quest"))
if _hJ then local _LJ=_hJ:FindFirstChild("Quest")
if _LJ then local _rJ=true
local _oJ=false
for _OJ,_yJ in ipairs(_LJ:GetChildren())do if _yJ:IsA("TextLabel")and _yJ.Name~="Title"and _yJ.Visible then _oJ=true
if _yJ.TextColor3~=Color3.fromRGB(144,255,110)then _rJ=false
break
end
end
end
if _oJ then return _rJ
end
end
end
end
return _uJ
end
local function _KJ()local _ZJ=_Gz:FindFirstChild("PlayerGui")
local _CJ=_ZJ and _ZJ:FindFirstChild("MainGui")
local _nJ=_CJ and _CJ:FindFirstChild("Menu")
local _MJ=_nJ and _nJ:FindFirstChild("Dialogue")
if _MJ and _MJ.Visible then local _GJ=_MJ:FindFirstChild("Name",true)or _MJ:FindFirstChild("NPCName",true)or _MJ:FindFirstChild("Title",true)
local _BJ=_GJ and tostring(_GJ.Text)or""
if _BJ==""or string.find(_BJ,"Zeng",1,true)or string.find(_BJ,"Tianguo",1,true)then _MJ.Visible=false
end
end
end
local _gJ
do local _lJ=0
local function _UJ(_HJ)local _aJ=_HJ or _FJ()
if not _aJ then return
end
local _VJ={[1]="Zeng Tianguo",[2]=1,[3]="Quest",[4]={[1]=_aJ}}
local _Wt={[1]="Zeng Tianguo",[2]=1,[3]="AcceptQuest",[4]={[1]=_aJ,[2]="Zeng Tianguo Quest"}}
pcall(function()_tN:FireServer(unpack(_VJ))
end)
task.wait(0.3)
pcall(function()_tN:FireServer(unpack(_Wt))
end)
_KJ()
_lJ=os.clock()
end
function _gJ()local _Ft=os.clock()
if _Ft-_lJ<3 then return
end
local _mt=_JJ()
if _mt then if _dJ(_mt)then local _jt=_FJ()
if _jt then _UJ(_jt)
end
end
return
end
local _kt=_FJ()
if _kt then _UJ(_kt)
end
end
pcall(function()local _Jt=_Bz:FindFirstChild("StartDialogue")
if _Jt and _Jt:IsA("RemoteEvent")then _Jt.OnClientEvent:Connect(function(_Dt,_St)if not _DV.AutoZengTianguoQuest then return
end
if tostring(_Dt)=="Zeng Tianguo"or(_St and _St.Name=="Zeng Tianguo")then _KJ()
end
end)
end
end)
end
do local function _It(_it)if not _it or _it==""then return""
end
local _Pt=string.split(_it,"|")[1]or _it
return string.gsub(_Pt,"^%s*(.-)%s*$","%1")
end
local function _qt(_Tt)if not _Tt then return 0
end
local _At=0
pcall(function()if _Tt:IsA("ValueBase")then _At=tonumber(_Tt.Value)or 0
end
end)
if _At and _At>0 then return _At
end
pcall(function()local _ft=_Tt:FindFirstChild("Quantity")or _Tt:FindFirstChild("Count")or _Tt:FindFirstChild("Value")or _Tt:FindFirstChild("Amount")
if _ft and _ft:IsA("ValueBase")then _At=tonumber(_ft.Value)or 0
end
end)
if _At and _At>0 then return _At
end
pcall(function()local _Rt=_Tt:GetAttribute("Quantity")or _Tt:GetAttribute("Count")or _Tt:GetAttribute("Amount")or _Tt:GetAttribute("Value")
if _Rt then _At=tonumber(_Rt)or 0
end
end)
if _At and _At>0 then return _At
end
pcall(function()if _Tt:IsA("BoolValue")and _Tt.Value==true then _At=1
end
end)
return _At or 0
end
local function _xt(_wt)local _zt=_gz and _gz:FindFirstChild("Bait")
if not _zt or not _wt or _wt==""then return 0
end
local _Qt=_zt:FindFirstChild(_wt)
if not _Qt or not _Qt:IsA("ModuleScript")then return 0
end
local _dt=0
local _et,_vt=pcall(require,_Qt)
if _et and type(_vt)=="table"and _vt.Luck~=nil then local _Yt=tonumber(_vt.Luck)
if not _Yt then local _Et=tostring(_vt.Luck)
local _ut=string.match(_Et,"%d+%.?%d*")
_Yt=tonumber(_ut)
end
_dt=_Yt or 0
end
return _dt
end
local function _pt()local _ct=_Uz
if not _ct then return nil
end
local _Nt=_gz and _gz:FindFirstChild("Bait")
if not _Nt then return nil
end
local _bt=nil
local _st=nil
local _Xt=-1
local _tt=0
local _ht=nil
local _Lt=nil
local function _rt(_ot,_Ot,_yt,_Kt)local _Zt=tonumber(_Ot)or 0
if _Zt>0 then local _Ct=_It(_ot)
if _Nt:FindFirstChild(_Ct)then local _nt=_xt(_Ct)
if _nt>_Xt then _Xt=_nt
_bt=_Ct
_st=_ot
_tt=_Zt
_ht=_Kt
_Lt=_yt
elseif not _bt then _bt=_Ct
_st=_ot
_tt=_Zt
_ht=_Kt
_Lt=_yt
end
end
end
end
local _Mt=_ct:FindFirstChild("Bait")
if _Mt then for _Gt,_Bt in ipairs(_Mt:GetChildren())do local _gt=_qt(_Bt)
if _gt>0 then _rt(_Bt.Name,_gt,_Bt,"Bait")
end
end
end
local _lt=_ct:FindFirstChild("Inventory")
if _lt then for _Ut,_Ht in ipairs(_lt:GetChildren())do local _at=_It(_Ht.Name)
if _Nt:FindFirstChild(_at)then local _Vt=_qt(_Ht)
if _Vt<=0 then _Vt=1
end
_rt(_Ht.Name,_Vt,_Ht,"Inventory")
end
end
end
return _bt,_st,_Xt,_tt,_ht,_Lt
end
local _Wf={}
local function _Ff()local _mf=_gz and _gz:FindFirstChild("Bait")
if not _mf then return
end
for _jf,_kf in ipairs(_mf:GetChildren())do if _kf:IsA("ModuleScript")then local _Jf,_Df=pcall(require,_kf)
if _Jf and type(_Df)=="table"and _Df.Image then local _Sf=tostring(_Df.Image)
_Wf[_Sf]=_kf.Name
_Wf[string.lower(_Sf)]=_kf.Name
local _If=string.match(_Sf,"%d+")
if _If then _Wf[_If]=_kf.Name
end
end
end
end
end
_Ff()
local function _if()local _Pf=-1
pcall(function()local _qf=_Gz and _Gz:FindFirstChild("PlayerGui")and _Gz.PlayerGui:FindFirstChild("MainGui")
local _Tf=_qf and _qf:FindFirstChild("Main")and _qf.Main:FindFirstChild("Hotbar")and _qf.Main.Hotbar:FindFirstChild("List")
local _Af=_Tf and _Tf:FindFirstChild("2")
if _Af then local _ff=_Af:FindFirstChild("Quantity")or(_Af:FindFirstChild("Quantity_BG")and _Af.Quantity_BG:FindFirstChild("Quantity"))or(_Af:FindFirstChild("Detail")and _Af.Detail:FindFirstChild("Quantity"))or(_Af:FindFirstChild("Inner")and _Af.Inner:FindFirstChild("Quantity"))
if _ff and _ff:IsA("TextLabel")then if not _ff.Visible or _ff.Text==""then _Pf=0
else local _Rf=string.match(_ff.Text,"%d+")
_Pf=tonumber(_Rf)or 0
end
end
end
end)
if _Pf==-1 and _Uz then pcall(function()local _xf=_Uz:FindFirstChild("Hotbar")
local _wf=_xf and _xf:FindFirstChild("2")
if _wf then local _zf=_wf:FindFirstChild("Quantity")
if _zf and _zf:IsA("ValueBase")then _Pf=tonumber(_zf.Value)or 0
end
end
end)
end
return math.max(0,_Pf)
end
local function _Qf()if not next(_Wf)then _Ff()
end
local _df=nil
pcall(function()local _ef=_Gz and _Gz:FindFirstChild("PlayerGui")and _Gz.PlayerGui:FindFirstChild("MainGui")
local _vf=_ef and _ef:FindFirstChild("Main")and _ef.Main:FindFirstChild("Hotbar")and _ef.Main.Hotbar:FindFirstChild("List")
local _Yf=_vf and _vf:FindFirstChild("2")
if _Yf then local _Ef=_Yf:FindFirstChild("Image")or(_Yf:FindFirstChild("Inner")and _Yf.Inner:FindFirstChild("Image"))
if not _Ef then _Ef=_Yf:FindFirstChildWhichIsA("ImageLabel",true)
end
if _Ef and _Ef.Visible and _Ef.Image~=""then local _uf=tostring(_Ef.Image)
local _pf=string.match(_uf,"%d+")
if _pf and _Wf[_pf]then _df=_Wf[_pf]
elseif _Wf[_uf]then _df=_Wf[_uf]
elseif _Wf[string.lower(_uf)]then _df=_Wf[string.lower(_uf)]
end
end
if not _df then for _cf,_Nf in ipairs(_Yf:GetDescendants())do if _Nf:IsA("TextLabel")and _Nf.Text~=""then local _bf=_It(_Nf.Text)
if _gz and _gz:FindFirstChild("Bait")and _gz.Bait:FindFirstChild(_bf)then _df=_bf
break
end
end
local _sf=_Nf:GetAttribute("ItemName")or _Nf:GetAttribute("Bait")
if _sf and tostring(_sf)~=""then local _Xf=_It(tostring(_sf))
if _gz and _gz:FindFirstChild("Bait")and _gz.Bait:FindFirstChild(_Xf)then _df=_Xf
break
end
end
end
end
local _tf=_Yf:FindFirstChild("Quantity")or(_Yf:FindFirstChild("Quantity_BG")and _Yf.Quantity_BG:FindFirstChild("Quantity"))or(_Yf:FindFirstChild("Detail")and _Yf.Detail:FindFirstChild("Quantity"))or(_Yf:FindFirstChild("Inner")and _Yf.Inner:FindFirstChild("Quantity"))
if _tf and _tf:IsA("TextLabel")then if not _tf.Visible or _tf.Text==""or _tf.Text=="x0"or _tf.Text=="0"then _df=nil
end
end
end
end)
if not _df and _Uz then pcall(function()local _hf=_Uz:FindFirstChild("Hotbar")
local _Lf=_hf and _hf:FindFirstChild("2")
if _Lf then local _rf=_Lf:FindFirstChild("ValueName")
local _of=_Lf:FindFirstChild("Quantity")
local _Of=_of and tonumber(_of.Value)or 0
if _rf and _rf.Value~=""and _Of>0 then local _yf=_It(_rf.Value)
if _gz and _gz:FindFirstChild("Bait")and _gz.Bait:FindFirstChild(_yf)then _df=_yf
end
end
end
if not _df then local _Kf=_Uz:FindFirstChild("EquippedBait")or _Uz:FindFirstChild("CurrentBait")
if _Kf and _Kf:IsA("StringValue")and _Kf.Value~=""then _df=_It(_Kf.Value)
end
end
if not _df then local _Zf=_Uz:GetAttribute("EquippedBait")or _Uz:GetAttribute("Bait")
if _Zf and tostring(_Zf)~=""then _df=_It(tostring(_Zf))
end
end
end)
end
return _df
end
local _Cf=0
function _Ee(_nf)if not _DV.AutoEquipBestBait and not _nf then return
end
local _Mf=os.clock()
if not _nf and _Mf-_Cf<2 then return
end
local _Gf,_Bf,_gf,_lf=_pt()
if not _Gf or _lf<=0 then if _nf then pcall(function()_hz:Notify({Title="Tự trang bị mồi",Content="Không tìm thấy mồi trong túi đồ",Duration=3})
end)
end
return
end
local _Uf=_Qf()
local _Hf=_if()
if not _nf and _Uf==_Gf and _Hf>0 then return
end
_Cf=_Mf
local _af=_JV or(_Bz and _Bz:FindFirstChild("EquipBait"))or(_Bz and _Bz:WaitForChild("EquipBait",9e9))
if _af then pcall(function()if _af:IsA("RemoteFunction")then _af:InvokeServer(_Gf)
elseif _af:IsA("RemoteEvent")then _af:FireServer(_Gf)
else _af:InvokeServer(_Gf)
end
end)
task.delay(0.3,function()local _Vf=_Qf()
local _WI=_if()
if _WI<=0 and _Vf~=_Gf then pcall(function()if _af:IsA("RemoteFunction")then _af:InvokeServer(_Gf)
elseif _af:IsA("RemoteEvent")then _af:FireServer(_Gf)
else _af:InvokeServer(_Gf)
end
end)
end
end)
end
pcall(function()_hz:Notify({Title="Tự trang bị mồi",Content="Đã trang bị ".._Gf.." - Luck ".._gf.."%",Duration=3})
end)
end
_Gz.CharacterAdded:Connect(function()_Cf=0
end)
end
do local _FI=0
local _mI=30
local function _jI(_kI)for _JI,_DI in ipairs(_kI)do local _SI=_Bz:FindFirstChild(_DI)
if _SI then return _SI
end
end
for _II,_iI in ipairs(_kI)do local _PI=_yz:FindFirstChild(_iI,true)
if _PI then return _PI
end
end
return nil
end
local function _qI()local _TI=_jI({"ClaimDailyQuest","ClaimDailyReward","ClaimDaily","DailyQuestClaim","DailyRewardClaim","ClaimDailyTask","DailyQuest","DailyReward",})
if _TI then if _TI:IsA("RemoteFunction")then pcall(function()_TI:InvokeServer()
end)
else pcall(function()_TI:FireServer()
end)
end
end
local _AI=_Gz:FindFirstChild("PlayerGui")
local _fI=_AI and _AI:FindFirstChild("MainGui")
local _RI=_fI and _fI:FindFirstChild("Menu")
local _xI=_RI and _RI:FindFirstChild("Quest")
if not _xI then return
end
local function _wI(_zI,_QI)for _dI,_eI in ipairs(_QI)do local _vI=_zI:FindFirstChild(_eI,true)
if _vI and _vI:IsA("GuiButton")and _vI.Visible then local _YI=_vI.MouseButton1Click
if _YI then pcall(function()_YI:Fire()
end)
task.wait(0.15)
end
end
end
end
_wI(_xI,{"DailyQuest","Daily Quest","Daily","DailyTab"})
task.wait(0.3)
local function _EI(_uI)if not _uI then return
end
local _pI=0
for _cI,_NI in ipairs(_uI:GetDescendants())do if _NI:IsA("GuiButton")and _NI.Visible then local _bI=string.lower(_NI.Name)
if _bI=="claim"or _bI=="claimbtn"or _bI=="claimbutton"or _bI=="checkmark"or _bI=="done"or _bI=="collect"or _bI=="collectbtn"or _bI=="completebtn"or string.find(_bI,"claim",1,true)or string.find(_bI,"collect",1,true)then local _sI=_NI.Parent
local _XI=false
if _sI then for _tI,_hI in ipairs(_sI:GetDescendants())do if _hI:IsA("TextLabel")then local _LI=_hI.Text
local _rI,_oI=_LI:match("(%d+)/(%d+)")
if _rI and _oI and tonumber(_rI)>=tonumber(_oI)then _XI=true
break
end
end
end
end
if _XI or _NI.BackgroundTransparency<0.9 then pcall(function()_NI.MouseButton1Click:Fire()
end)
_pI=_pI+1
task.wait(0.2)
end
end
end
end
return _pI
end
local _OI=_xI:FindFirstChild("DailyQuest",true)or _xI:FindFirstChild("Daily Quest",true)or _xI:FindFirstChild("Daily",true)
_EI(_OI or _xI)
local _yI=_xI:FindFirstChild("DailyReward",true)or _xI:FindFirstChild("Daily Reward",true)
if _yI then local _KI=_yI:FindFirstChild("Claim",true)or _yI:FindFirstChild("ClaimBtn",true)or _yI:FindFirstChild("CollectBtn",true)
if _KI and _KI:IsA("GuiButton")and _KI.Visible then pcall(function()_KI.MouseButton1Click:Fire()
end)
end
end
end
_G.StepDailyQuest=function()if not _DV.AutoDailyQuest then return
end
if os.clock()-_FI<_mI then return
end
_FI=os.clock()
task.spawn(_qI)
end
end
task.spawn(function()while task.wait(1)do if _DV.AutoTicketQuest then _qc()
end
if type(_G.StepDailyQuest)=="function"then _G.StepDailyQuest()
end
if _DV.AutoEquipBestBait then _Ee()
end
end
end)
function _XN()local _ZI={}
local _CI={}
local _nI=_gz:FindFirstChild("Bait")
if _nI then for _MI,_GI in ipairs(_nI:GetChildren())do local _BI=_KV(_GI)
if _BI and not _BI.Ingredient then _CI[_GI.Name]=true
table.insert(_ZI,_GI.Name)
end
end
end
local _gI=_gz:FindFirstChild("Item")
if _gI then for _lI,_UI in ipairs(_gI:GetChildren())do if not _CI[_UI.Name]then local _HI=_KV(_UI)
if _HI and _HI.Type=="Bait"and not _HI.Ingredient then _CI[_UI.Name]=true
table.insert(_ZI,_UI.Name)
end
end
end
end
table.sort(_ZI)
return _ZI
end
end
local function _aI()local _VI={}
local _Wk=_gz:FindFirstChild("Bait")
if _Wk then for _Fk,_mk in ipairs(_Wk:GetChildren())do local _jk=_KV(_mk)
if _jk and _jk.Ingredient then table.insert(_VI,_mk.Name)
end
end
end
table.sort(_VI)
return _VI
end
local function _kk()local _Jk={}
local _Dk=_gz:FindFirstChild("Inventory")
if _Dk then for _Sk,_Ik in ipairs(_Dk:GetChildren())do local _ik=_KV(_Ik)
if _ik and _ik.Ingredient and _ik.Type=="Fishing Rod"then table.insert(_Jk,_Ik.Name)
end
end
end
table.sort(_Jk)
return _Jk
end
local _Pk={}
local _qk={["Beginning Isle"]=1,["Bamboo Isle"]=2,["Fallout Isle"]=3,["Sovereign Isle"]=4,["Perch Isle"]=5,["Frost Isle"]=6,["Coconut Isle"]=7,["Amber Isle"]=8,["Battlefield Isle"]=9,["Mistpeak Isle"]=10,["World Angler Isle"]=11,["Weather Isle"]=12,["Mystic Reef Isle"]=13}
local _Tk={["Beginning Isle"]=1,["Bamboo Isle"]=19,["Fallout Isle"]=32,["Sovereign Isle"]=39,["Perch Isle"]=48,["Frost Isle"]=55,["Coconut Isle"]=65,["Amber Isle"]=75,["Battlefield Isle"]=90,["Mistpeak Isle"]=100,["World Angler Isle"]=100,["Weather Isle"]=100,["Mystic Reef Isle"]=100}
local function _Ak(_fk)if _qk[_fk]then return _qk[_fk]
end
local _Rk=string.lower(_fk)
for _xk,_wk in pairs(_qk)do local _zk=string.lower(_xk)
if _Rk==_zk or string.find(_Rk,_zk,1,true)or string.find(_zk,_Rk,1,true)then return _wk
end
end
return nil
end
local function _Qk(_dk)if _Tk[_dk]then return _Tk[_dk]
end
local _ek=string.lower(_dk)
for _vk,_Yk in pairs(_Tk)do local _Ek=string.lower(_vk)
if _ek==_Ek or string.find(_ek,_Ek,1,true)or string.find(_Ek,_ek,1,true)then return _Yk
end
end
return nil
end
local function _uk()local _pk={}
local _ck={}
table.clear(_Pk)
local _Nk=workspace:FindFirstChild("Spawnpoint")
if not _Nk then return{}
end
local _bk=_Nk:FindFirstChild("Beginning Isle")
local _sk=_bk and _YK(_bk)and _YK(_bk).Position or Vector3.zero
local _Xk={}
local _tk={}
if _JY then local _hk=_JY:FindFirstChild("Menu")
local _Lk=_hk and _hk:FindFirstChild("Compass")
local _rk=_Lk and _Lk:FindFirstChild("AreaList")
if _rk then for _ok,_Ok in ipairs(_rk:GetChildren())do if _Ok:IsA("GuiObject")and _Ok:FindFirstChild("Track")then local _yk=nil
for _Kk,_Zk in ipairs(_Ok:GetDescendants())do if _Zk:IsA("TextLabel")and _Zk.Text then local _Ck=string.match(_Zk.Text,"Power:%s*(%d+)")
if _Ck then _yk=tonumber(_Ck)
break
end
end
end
if _yk then _tk[_Ok.Name]=_yk
end
local _nk=(_yk or 999)*1000+(_Ok.LayoutOrder or 0)
_Xk[_Ok.Name]=_nk
end
end
end
end
for _Mk,_Gk in ipairs(_Nk:GetChildren())do local _Bk=_YK(_Gk)
if _Bk and not _ck[_Gk.Name]then _ck[_Gk.Name]=true
local _gk=_Ak(_Gk.Name)
local _lk
if _gk then _lk=_gk
elseif _Xk[_Gk.Name]then _lk=1000+_Xk[_Gk.Name]
else _lk=1e7+(_Bk.Position-_sk).Magnitude
end
local _Uk=_tk[_Gk.Name]or _Qk(_Gk.Name)
table.insert(_pk,{name=_Gk.Name,part=_Bk,weight=_lk,power=_Uk})
end
end
table.sort(_pk,function(_Hk,_ak)if _Hk.weight~=_ak.weight then return _Hk.weight<_ak.weight
end
return _Hk.name<_ak.name
end)
local _Vk={}
for _Wr,_Fr in ipairs(_pk)do local _mr=_Fr.power and(_Fr.name.." | "..tostring(_Fr.power))or _Fr.name
_Pk[_mr]=_Fr.part
_Pk[_Fr.name]=_Fr.part
table.insert(_Vk,_mr)
end
return _Vk
end
local function _jr(_kr)if not _kr or _kr==""then return
end
if not _Pk[_kr]then _uk()
end
local _Jr=_Pk[_kr]
local _Dr=_Gz.Character
local _Sr=_Dr and _Dr:FindFirstChild("HumanoidRootPart")
if _Sr and _Jr then _Sr.CFrame=_Jr.CFrame+Vector3.new(0,5,0)
end
end
local function _Ir(_ir)if not _ir or _ir==""then return
end
if not _Pk[_ir]then _uk()
end
local _Pr=_Pk[_ir]
if not _Pr then return
end
local _qr=_Gz.Character or _VV
local _Tr=(_qr and _qr:FindFirstChild("HumanoidRootPart"))or _FY
if not _Tr then return
end
local _Ar=-25
local _fr=workspace:FindFirstChild("Ocean")
if _fr then for _Rr,_xr in ipairs(_fr:GetChildren())do if _xr.Name=="Water"and _xr:IsA("BasePart")then local _wr=_xr.Position.Y+(_xr.Size.Y*0.5)
_Ar=_wr-12
break
end
end
end
local _zr=Vector3.new(_Pr.Position.X,math.min(_Ar,_Pr.Position.Y-15),_Pr.Position.Z)
_Tr.CFrame=CFrame.new(_zr)
end
local _Qr={}
local function _dr()local _er={}
local _vr={}
table.clear(_Qr)
local function _Yr(_Er,_ur)if not _Er or _Er==""then return
end
local _pr=string.lower(string.gsub(_Er,"%s+",""))
if _pr=="longdiaohai"then _Er="Long DiaoHai"
end
if _ur and _ur:IsDescendantOf(workspace)then _Qr[_Er]=_ur
_Qr[_pr]=_ur
end
if not _vr[_pr]then _vr[_pr]=true
table.insert(_er,_Er)
end
end
for _cr,_Nr in ipairs({"Merchant","NPCDialogue","NPCPVP","NPC","BossSetUp"})do local _br=workspace:FindFirstChild(_Nr)or _yz:FindFirstChild(_Nr)
if _br then for _sr,_Xr in ipairs(_br:GetChildren())do local _tr=tostring(_Xr.Name)
if _tr~=""and _tr~="Lamp"and _tr~="Boss"and _tr~="God"then local _hr=workspace:FindFirstChild(_Nr)
local _Lr=_hr and _hr:FindFirstChild(_tr)
local _rr=_Lr and _YK(_Lr)
_Yr(_tr,_rr)
elseif _tr=="Boss"or _tr=="God"then for _or,_Or in ipairs(_Xr:GetChildren())do local _yr=tostring(_Or.Name)
if _yr~=""and _yr~="God"then local _Kr=workspace:FindFirstChild(_Nr)
local _Zr=_Kr and _Kr:FindFirstChild(_tr)
local _Cr=_Zr and _Zr:FindFirstChild(_yr)
local _nr=_Cr and _YK(_Cr)
_Yr(_yr,_nr)
end
end
end
end
end
end
local _Mr=workspace:FindFirstChild("God")or _yz:FindFirstChild("God")
if _Mr then for _Gr,_Br in ipairs(_Mr:GetChildren())do local _gr=tostring(_Br.Name)
if _gr~=""and _gr~="Lamp"and _gr~="God"then local _lr=workspace:FindFirstChild("God")and workspace.God:FindFirstChild(_gr)
local _Ur=_lr and _YK(_lr)
_Yr(_gr,_Ur)
end
end
end
_Yr("Long DiaoHai")
local _Hr={"The Shadow","TheShadow","Shadow","???","Taoist","Taosi","Maoshan","Maosan","Long DiaoHai","LongDiaoHai","Longdiaohai","Enzo","Blue","Green","Yellow","Nanjiang","Zeng Tianguo"}
local _ar={}
for _Vr,_WS in ipairs(_Hr)do local _FS=string.lower(string.gsub(_WS,"%s+",""))
if not _ar[_FS]then _ar[_FS]=_Vr
end
end
local function _mS(_jS)local _kS=string.lower(string.gsub(tostring(_jS),"%s+",""))
return _ar[_kS]or 9999
end
table.sort(_er,function(_JS,_DS)local _SS=_mS(_JS)
local _IS=_mS(_DS)
if _SS~=_IS then return _SS<_IS
end
return tostring(_JS):lower()<tostring(_DS):lower()
end)
return _er
end
local function _iS(_PS,_qS)local function _TS(_AS)return string.lower((string.gsub(tostring(_AS or""),"[%s_%-]+","")))
end
local _fS=_TS(_PS)
if _fS==""then return nil
end
local _RS
for _xS,_wS in ipairs({"blue","green","yellow"})do if string.find(_fS,_wS,1,true)then _RS=_wS
break
end
end
local _zS=string.find(_fS,"spirit",1,true)~=nil or _fS=="god"or _fS=="gods"
local _QS=_Gz.Character or _VV
local _dS=(_QS and _QS:FindFirstChild("HumanoidRootPart"))or _FY
local _eS,_vS
local function _YS(_ES,_uS)if not(_ES:IsA("Model")or _ES:IsA("BasePart"))then return
end
local _pS=_TS(_ES.Name)
local _cS=_TS(_ES:GetAttribute("Name"))
local _NS=(_pS==_fS or _cS==_fS)
if not _NS and _RS and(_pS==_RS or _cS==_RS)then _NS=true
end
if not _NS and _zS and not _RS then _NS=_uS and(_ES.Parent and _ES.Parent.Name=="God")or string.find(_pS,"spirit",1,true)~=nil
end
if not _NS and#_fS>=4 then _NS=string.find(_pS,_fS,1,true)~=nil or(#_pS>=4 and string.find(_fS,_pS,1,true)~=nil)
end
if not _NS then return
end
local _bS=_YK(_ES)
if _bS and _bS:IsDescendantOf(workspace)then local _sS=_dS and(_bS.Position-_dS.Position).Magnitude or 0
if not _eS or _sS<_vS then _eS,_vS=_bS,_sS
end
end
end
local _XS=workspace:FindFirstChild("God")
if _XS then for _tS,_hS in ipairs(_XS:GetDescendants())do _YS(_hS,true)
end
end
if not _eS then for _LS,_rS in ipairs(workspace:GetDescendants())do _YS(_rS,false)
end
end
return _eS
end
local function _oS(_OS)if not _OS or _OS==""then return
end
local _yS=string.lower(string.gsub(tostring(_OS),"%s+",""))
local _KS=nil
if _yS=="blue"or _yS=="green"or _yS=="yellow"then local _ZS=workspace:FindFirstChild("God")
if _ZS then for _CS,_nS in ipairs(_ZS:GetChildren())do local _MS=string.lower(string.gsub(tostring(_nS.Name),"%s+",""))
if _MS==_yS then _KS=_YK(_nS)
if _KS and _KS:IsDescendantOf(workspace)then break
end
end
end
end
if not _KS then for _GS,_BS in ipairs(workspace:GetChildren())do local _gS=string.lower(string.gsub(tostring(_BS.Name),"%s+",""))
if _gS==_yS then local _lS=_YK(_BS)
if _lS and _lS:IsDescendantOf(workspace)then _KS=_lS
break
end
end
end
end
elseif string.find(_yS,"longdiaohai")or _yS=="enzo"then local _US=GetBossFarmCFrame(string.find(_yS,"longdiaohai")~=nil)
local _HS=_Gz.Character or _VV
local _aS=(_HS and _HS:FindFirstChild("HumanoidRootPart"))or _FY
if _aS and _US then _aS.AssemblyLinearVelocity=Vector3.zero
_aS.AssemblyAngularVelocity=Vector3.zero
_aS.CFrame=_US
return
end
end
local _VS={}
if not _KS then for _W0,_F0 in ipairs({"NPC","Merchant","NPCDialogue","NPCPVP","God","BossSetUp"})do local _m0=workspace:FindFirstChild(_F0)
if _m0 then for _j0,_k0 in ipairs(_m0:GetDescendants())do if(_k0:IsA("Model")or _k0:IsA("BasePart"))and not _k0:IsA("Folder")and(_k0.Name==_OS or _k0:GetAttribute("Name")==_OS)and _k0.Name~="God"then local _J0=_YK(_k0)
if _J0 and _J0:IsDescendantOf(workspace)then table.insert(_VS,{folder=_F0,part=_J0})
end
end
end
end
end
end
if not _KS and#_VS==0 then local _D0=workspace:FindFirstChild(_OS)
if _D0 then local _S0=_YK(_D0)
if _S0 and _S0:IsDescendantOf(workspace)then _KS=_S0
end
end
end
if#_VS>0 then if(_OS=="Maoshan"or _OS=="Taoist")and#_VS>1 then local _I0=workspace:FindFirstChild("Da Shixiong",true)
local _i0=_I0 and _YK(_I0)
for _P0,_q0 in ipairs(_VS)do if _q0.folder=="NPC"then _KS=_q0.part
break
end
if _i0 and(_q0.part.Position-_i0.Position).Magnitude>15 then _KS=_q0.part
break
end
end
end
if not _KS then _KS=_VS[1].part
end
end
if not _KS or not _KS:IsDescendantOf(workspace)then local _T0=_Qr[_OS]or _Qr[_yS]
if _T0 and _T0:IsDescendantOf(workspace)then _KS=_T0
end
end
if not _KS or not _KS:IsDescendantOf(workspace)then _KS=_iS(_OS,_yS)
end
if not _KS or not _KS:IsDescendantOf(workspace)then pcall(function()_hz:Notify({Title="Dịch chuyển đến NPC",Content=_OS.." has not spawned on the map yet!",Duration=4})
end)
return
end
local _A0=_Gz.Character or _VV
local _f0=(_A0 and _A0:FindFirstChild("HumanoidRootPart"))or _FY
if _f0 and _KS then _f0.CFrame=_KS.CFrame*CFrame.new(0,3,-4)
end
end
local function _R0()local _x0={}
for _w0,_z0 in ipairs(_Lz:GetPlayers())do if _z0~=_Gz then table.insert(_x0,_z0.Name)
end
end
table.sort(_x0,function(_Q0,_d0)return string.lower(_Q0)<string.lower(_d0)
end)
return _x0
end
local function _e0(_v0)if not _v0 or _v0==""then return
end
local _Y0=_Lz:FindFirstChild(_v0)
if not _Y0 then for _E0,_u0 in ipairs(_Lz:GetPlayers())do if _u0~=_Gz and(string.lower(_u0.Name)==string.lower(_v0)or string.lower(_u0.DisplayName)==string.lower(_v0))then _Y0=_u0
break
end
end
end
if not _Y0 then pcall(function()_hz:Notify({Title="Dịch chuyển người chơi",Content="Người chơi "..tostring(_v0).." không tìm thấy!",Duration=3})
end)
return
end
local _p0=_Y0.Character
local _c0=_p0 and(_p0:FindFirstChild("HumanoidRootPart")or _p0:FindFirstChild("Torso")or _p0:FindFirstChild("UpperTorso"))
if not _c0 then pcall(function()_hz:Notify({Title="Dịch chuyển người chơi",Content=_Y0.Name.." has no character spawned!",Duration=3})
end)
return
end
local _N0=_Gz.Character or _VV
local _b0=(_N0 and _N0:FindFirstChild("HumanoidRootPart"))or _FY
if _b0 then _b0.CFrame=_c0.CFrame*CFrame.new(0,2,3)
end
end
local _s0={"HWF","Welcome","80KLikes","55MVisits","VermilionBird","23KActives"}
local function _X0()task.spawn(function()local _t0={}
for _h0,_L0 in ipairs(_s0)do _t0[_L0]=true
end
local function _r0(_o0)if not _o0 then return
end
if _o0:IsA("ModuleScript")then local _O0,_y0=pcall(require,_o0)
if _O0 and type(_y0)=="table"then for _K0,_Z0 in pairs(_y0)do if type(_K0)=="string"then _t0[_K0]=true
end
if type(_Z0)=="string"then _t0[_Z0]=true
end
end
end
end
for _C0,_n0 in ipairs(_o0:GetChildren())do _t0[_n0.Name]=true
if _n0:IsA("StringValue")and _n0.Value~=""then _t0[_n0.Value]=true
end
end
end
_r0(_gz:FindFirstChild("Code"))
_r0(_gz:FindFirstChild("Codes"))
_r0(_Uz:FindFirstChild("Code"))
_r0(_Uz:FindFirstChild("Codes"))
for _M0 in pairs(_t0)do pcall(function()_kV:FireServer(_M0)
end)
task.wait(0.15)
end
end)
end
local function _G0(_B0)local _g0=_Gz:FindFirstChild("PlayerGui")
local _l0=(_g0 and _g0:FindFirstChild("MainGui"))or _JY
local _U0=_l0 and _l0:FindFirstChild("Menu")
if not _U0 then return false
end
local _H0=_U0:FindFirstChild(_B0)
if not _H0 and(string.lower(_B0)=="trait"or string.find(string.lower(_B0),"trait"))then for _a0,_V0 in pairs(_U0:GetChildren())do local _WU=string.lower(_V0.Name)
if string.find(_WU,"trait")or string.find(_WU,"reroll")then _H0=_V0
_B0=_V0.Name
break
end
end
if not _H0 then for _FU,_mU in pairs(_l0:GetDescendants())do if _mU:IsA("Frame")then local _jU=string.lower(_mU.Name)
if string.find(_jU,"trait")or string.find(_jU,"reroll")then _H0=_mU
break
end
end
end
end
end
if not _H0 then return false
end
for _kU,_JU in pairs(_U0:GetChildren())do if _JU:IsA("Frame")and _JU.Name~="Info"and _JU.Name~="Black"and _JU.Name~="Dialogue"then if _JU==_H0 or _JU.Name==_B0 then _JU.Visible=not _JU.Visible
else _JU.Visible=false
end
end
end
if _H0.Parent~=_U0 then _H0.Visible=not _H0.Visible
end
return _H0.Visible
end
local _DU={Brightness=_Cz.Brightness,ClockTime=_Cz.ClockTime,FogEnd=_Cz.FogEnd,FogStart=_Cz.FogStart,GlobalShadows=_Cz.GlobalShadows,Ambient=_Cz.Ambient,OutdoorAmbient=_Cz.OutdoorAmbient}
local _SU={}
for _IU,_iU in ipairs(_Cz:GetChildren())do if _iU:IsA("Atmosphere")then _SU[_iU]={Density=_iU.Density,Haze=_iU.Haze,Glare=_iU.Glare}
end
end
local _PU=false
local function _qU()if _PU then return
end
_PU=true
pcall(function()if _DV.FullBright then _Cz.Brightness=2
_Cz.ClockTime=14
_Cz.GlobalShadows=false
_Cz.Ambient=Color3.fromRGB(255,255,255)
_Cz.OutdoorAmbient=Color3.fromRGB(255,255,255)
end
if _DV.NoFog then _Cz.FogStart=100000
_Cz.FogEnd=100000
for _TU,_AU in ipairs(_Cz:GetChildren())do if _AU:IsA("Atmosphere")then if not _SU[_AU]then _SU[_AU]={Density=_AU.Density,Haze=_AU.Haze,Glare=_AU.Glare}
end
_AU.Density=0
_AU.Haze=0
_AU.Glare=0
end
end
end
end)
_PU=false
end
local function _fU()_PU=true
pcall(function()_Cz.Brightness=_DU.Brightness
_Cz.ClockTime=_DU.ClockTime
_Cz.GlobalShadows=_DU.GlobalShadows
_Cz.Ambient=_DU.Ambient
_Cz.OutdoorAmbient=_DU.OutdoorAmbient
end)
_PU=false
end
local function _RU()_PU=true
pcall(function()_Cz.FogStart=_DU.FogStart
_Cz.FogEnd=_DU.FogEnd
for _xU,_wU in pairs(_SU)do if _xU and _xU.Parent then _xU.Density=_wU.Density
_xU.Haze=_wU.Haze
_xU.Glare=_wU.Glare
end
end
end)
_PU=false
end
_Cz.Changed:Connect(function()if _DV.FullBright or _DV.NoFog then _qU()
end
end)
_qU()
local _zU="https://discord.gg/QPux5hHVY"
local _QU=_hz:CreateWindow({Name="UZEX Hub",Subtitle="Heavyweigh Fishing",Icon=_hz.Assets.Logo,Size=UDim2.fromOffset(640,460),MinSize=Vector2.new(480,360),SidebarWidth=170,DefaultTheme="Taichi",ToggleUIKeybind=Enum.KeyCode.LeftControl,ConfigurationSaving={Enabled=false,FolderName=_SV},SaveSize=false,Home={Name="Trang chủ",Title="UZEX Hub",Desc="Heavyweigh Fishing",Discord=_zU,DiscordTitle="UZEX Hub Discord",DiscordIcon="message-circle",Features=false,Stats={{Key="Level",Label="Level",Value="-",Color=Color3.fromRGB(206,172,108)},{Key="Balance",Label="Balance",Value="-",Color=Color3.fromRGB(130,172,178)},{Key="Session",Label="Session",Value="-",Color=Color3.fromRGB(150,182,150)},{Key="Rod",Label="Rod",Value="-",Color=Color3.fromRGB(240,212,60)},{Key="Crystal",Label="Crystal",Value="-",Color=Color3.fromRGB(92,190,240)},{Key="Essence",Label="Essence",Value="-",Color=Color3.fromRGB(240,100,190)},{Key="Bait",Label="Bait",Value="-",Color=Color3.fromRGB(120,200,120)},{Key="FishCaught",Label="Fish Caught",Value="-",Color=Color3.fromRGB(212,170,72)},{Key="Ticket",Label="Ticket",Value="-",Color=Color3.fromRGB(172,132,222)},{Key="TraitReroll",Label="Trait Reroll",Value="-",Color=Color3.fromRGB(232,132,132)},{Key="HeaviestFish",Label="Heaviest Fish",Value="-",Color=Color3.fromRGB(236,166,50)},{Key="BaseHP",Label="Base HP",Value="-",Color=Color3.fromRGB(226,90,90)},},StatsTitle="Session",},Backdrop={Weather="Snow",Mode="Screen",Tint=0.65,Dim=true,Density=1,Speed=1,},Loading=false,UnsupportedExecutor=false,ToggleButton=false,OpenButton=false})
local _dU={Main=_QU:CreateTab({Name="Chính",Icon="home"}),LimitedEvent=_QU:CreateTab({Name="Sự kiện giới hạn",Icon="gift"}),Teleport=_QU:CreateTab({Name="Dịch chuyển",Icon="map-pin"}),Hop=_QU:CreateTab({Name="Chuyển server",Icon="server"}),Shop=_QU:CreateTab({Name="Cửa hàng",Icon="shopping-cart"}),Upgrade=_QU:CreateTab({Name="Nâng cấp",Icon="arrow-up"}),Misc=_QU:CreateTab({Name="Khác",Icon="layers"}),Settings=_QU:CreateTab({Name="Cài đặt",Icon="settings"})}
do local _eU=os.clock()
local _vU=false
local _YU=0
local _EU="UZEXHub/server-hop-visited.json"
local function _uU(_pU,_cU,_NU)pcall(function()_hz:Notify({Title=_pU,Content=_cU,Duration=_NU or 3})
end)
end
local function _bU(_sU)return(string.lower(tostring(_sU or"")):gsub("[_%-]+"," "):gsub("%s+"," "))
end
local _XU={taoist={{"NPC","Function","Taoist"},{"NPC","Taoist"},{"world","NPC","Taoist"}},maoshan={{"NPC","Function","Maoshan"},{"NPC","Maoshan"},{"world","NPC","Maoshan"}},}
local _tU={taoist={taoist=true},maoshan={maoshan=true,["mao shan"]=true},}
local _hU,_LU={},{}
local function _rU(_oU)local _OU=workspace
for _yU,_KU in ipairs(_oU)do _OU=_OU and _OU:FindFirstChild(_KU)
if not _OU then return nil
end
end
return _OU
end
local function _ZU(_CU)local _nU=os.clock()
if _LU[_CU]and _nU-_LU[_CU]<10 then local _MU=_hU[_CU]
if _MU==false then return nil
end
if _MU and _MU.Parent then return _MU
end
end
local _GU
for _BU,_gU in ipairs(_XU[_CU])do _GU=_rU(_gU)
if _GU then break
end
end
if not _GU then local _lU={}
local _UU=workspace:FindFirstChild("NPC")
if _UU then table.insert(_lU,_UU)
end
local _HU=workspace:FindFirstChild("Map")or workspace:FindFirstChild("World")
if _HU then table.insert(_lU,_HU)
end
if#_lU==0 then table.insert(_lU,workspace)
end
for _aU,_VU in ipairs(_lU)do for _WB,_FB in ipairs(_VU:GetDescendants())do if _tU[_CU][_bU(_FB.Name)]then _GU=_FB
break
end
end
if _GU then break
end
end
end
_hU[_CU]=_GU or false
_LU[_CU]=_nU
return _GU
end
local _mB,_jB=0,0
local function _kB()local _JB=os.clock()
if _JB-_jB<10 then return _mB
end
local _DB=0
local _SB={workspace:FindFirstChild("God")}
local _IB=workspace:FindFirstChild("NPC")
if _IB then table.insert(_SB,_IB:FindFirstChild("God"))
end
for _iB,_PB in pairs(_SB)do if _PB then _DB=math.max(_DB,#_PB:GetChildren())
end
end
if _DB==0 then local _qB={}
if _IB then table.insert(_qB,_IB)
end
local _TB=workspace:FindFirstChild("Characters")
if _TB then table.insert(_qB,_TB)
end
if#_qB==0 then table.insert(_qB,workspace)
end
for _AB,_fB in ipairs(_qB)do for _RB,_xB in ipairs(_fB:GetDescendants())do local _wB=_bU(_xB.Name)
if _wB=="god spirit"or _wB=="spirit god"then _DB=_DB+1
end
end
end
end
_mB,_jB=_DB,_JB
return _DB
end
local _zB
local _QB={["God Spirit"]=function()return _kB()>0
end,["Maoshan"]=function()return _ZU("maoshan")~=nil
end,["Taoist"]=function()return _ZU("taoist")~=nil
end,["Vermilion Birdblood"]=function()return _zB("vermilion")
end,["Black Tortoise Bloodline"]=function()return _zB("tortoise")
end,}
local _dB={["God Spirit"]="AutoHopGodSpirit",["Maoshan"]="AutoHopMaoshan",["Taoist"]="AutoHopTaoist",["Vermilion Birdblood"]="AutoHopVermilion",["Black Tortoise Bloodline"]="AutoHopTortoise",}
local _eB={["God Spirit"]="AutoHopGodSpiritToggle",["Maoshan"]="AutoHopMaoshanToggle",["Taoist"]="AutoHopTaoistToggle",["Vermilion Birdblood"]="AutoHopVermilionToggle",["Black Tortoise Bloodline"]="AutoHopTortoiseToggle",}
local _vB={"God Spirit","Maoshan","Taoist","Vermilion Birdblood","Black Tortoise Bloodline"}
local function _YB()local _EB={hour=os.date("!*t").hour,ids={}}
pcall(function()if isfile and isfile(_EU)then local _uB=_Kz:JSONDecode(readfile(_EU))
if type(_uB)=="table"and _uB.hour==_EB.hour and type(_uB.ids)=="table"then _EB=_uB
end
end
end)
return _EB
end
local function _pB(_cB)pcall(function()if writefile then writefile(_EU,_Kz:JSONEncode(_cB))
end
end)
end
local function _NB()local _bB=game.PlaceId
local _sB=_YB()
local _XB={}
for _tB,_hB in ipairs(_sB.ids)do _XB[tostring(_hB)]=true
end
local _LB=(syn and syn.request)or(http and http.request)or http_request or(fluxus and fluxus.request)or request
local _rB=""
for _oB=1,8 do local _OB="https://games.roblox.com/v1/games/"..tostring(_bB).."/servers/Public?sortOrder=Asc&limit=100"
if _rB~=""then _OB=_OB.."&cursor=".._rB
end
local _yB
if _LB then local _KB,_ZB=pcall(_LB,{Url=_OB,Method="GET"})
_yB=_KB and _ZB and _ZB.Body or nil
else local _CB,_nB=pcall(game.HttpGet,game,_OB)
_yB=_CB and _nB or nil
end
local _MB
if _yB then pcall(function()_MB=_Kz:JSONDecode(_yB)
end)
end
if type(_MB)~="table"or type(_MB.data)~="table"then task.wait(1)
else for _GB,_BB in ipairs(_MB.data)do local _gB=tostring(_BB.id)
if _gB~=game.JobId and not _XB[_gB]and(tonumber(_BB.playing)or 0)<(tonumber(_BB.maxPlayers)or 0)then table.insert(_sB.ids,_gB)
_pB(_sB)
pcall(function()_Zz:TeleportToPlaceInstance(_bB,_gB,_Gz)
end)
task.wait(4)
return true
end
end
if _MB.nextPageCursor and _MB.nextPageCursor~=""then _rB=_MB.nextPageCursor
else break
end
end
end
return false
end
local function _lB()local _UB={}
pcall(function()local _HB=_yz:FindFirstChild("ClientModule")
local _aB=_HB and _HB:FindFirstChild("Weather")
local _VB=_aB and _aB:FindFirstChild("Weather")
if not _VB then return
end
for _Wg,_Fg in ipairs(_VB:GetChildren())do if _Fg:IsA("ModuleScript")or _Fg:IsA("Folder")then local _mg=string.lower(_Fg.Name)
if _mg~="clear"and not string.find(_mg,"blood",1,true)then table.insert(_UB,_Fg.Name)
end
end
end
end)
if#_UB==0 then _UB={"Rain","Thunderstorm","Snow","Fog","Windy","Cloudy","Solar Eclipse"}
else table.sort(_UB)
end
return _UB
end
local function _jg(_kg)_kg=tostring(_kg or""):gsub("<[^>]+>","")
_kg=_kg:gsub("^%s*[Ww]eather%s*:?%s*","")
return(_kg:gsub("^%s+",""):gsub("%s+$",""))
end
local function _Jg()local _Dg={}
local _Sg=workspace:GetAttribute("Weather")
if _Sg~=nil and tostring(_Sg)~=""then table.insert(_Dg,_jg(_Sg))
end
pcall(function()local _Ig=_Gz.PlayerGui:FindFirstChild("MainGui")
local _ig=_Ig and _Ig:FindFirstChild("Info")
local _Pg=_ig and _ig:FindFirstChild("Info")
local _qg=_Pg and _Pg:FindFirstChild("Weather")
local _Tg=_qg and _qg:FindFirstChild("Value")
if not _Tg then return
end
local _Ag
if _Tg:IsA("TextLabel")or _Tg:IsA("TextButton")then _Ag=_Tg.Text
else _Ag=_Tg.Value
end
local _fg=_jg(_Ag)
if _fg~=""and not table.find(_Dg,_fg)then table.insert(_Dg,_fg)
end
end)
return _Dg
end
local function _Rg(_xg)return(string.lower(tostring(_xg or"")):gsub("[^%a]",""))
end
local _wg=_lB()
local function _zg(_Qg)local _dg=string.lower(tostring(_Qg or""))
_dg=_dg:gsub("%b()"," "):gsub("%b[]"," ")
_dg=_dg:gsub("[^%a]+"," ")
_dg=_dg:gsub("^%s+",""):gsub("%s+$","")
return _dg
end
local _eg={}
for _vg,_Yg in ipairs(_wg)do local _Eg=_zg(_Yg)
if _Eg~=""then table.insert(_eg,{words=_Eg,key=(_Eg:gsub("%s+",""))})
end
end
table.sort(_eg,function(_ug,_pg)return#_ug.words>#_pg.words
end)
local function _cg(_Ng)local _bg=_zg(_Ng)
if _bg==""then return""
end
for _sg,_Xg in ipairs(_eg)do if _bg==_Xg.words or string.sub(_bg,1,#_Xg.words+1)==_Xg.words.." "then return _Xg.key
end
end
local _tg=_bg:match("^(%a+)")
for _hg,_Lg in ipairs(_eg)do if not _Lg.words:find(" ",1,true)and#_Lg.words>=3 and _tg and(_tg==_Lg.words.."y"or _tg==_Lg.words.."gy"or _tg==_Lg.words.."ing")then return _Lg.key
end
end
return(_bg:gsub("%s+",""))
end
local function _rg(_og,_Og)local _yg=_cg(_Og)
if#_yg<3 then return false
end
local _Kg=false
for _Zg,_Cg in ipairs(_og)do local _ng=_cg(_Cg)
if _ng~=""then _Kg=true
if _ng~=_yg then return false
end
end
end
return _Kg
end
local function _Mg(_Gg,_Bg)return(_hz.Language=="English")and _Bg or _Gg
end
local _gg={"Taoist","Maoshan","Spirit","Weather","Vermilion Birdblood","Black Tortoise Bloodline"}
local function _lg(_Ug)return table.find(_gg,_Ug)~=nil
end
if string.find(tostring(_DV.HopFeedUrl or""),"ngrok",1,true)then _DV.HopFeedUrl="http://78.154.103.15:17017"
_iV()
end
if not _lg(_DV.HopListEvent)then _DV.HopListEvent="Taoist"
end
local _Hg={}
for _ag,_Vg in ipairs(_wg)do _Hg[(_zg(_Vg):gsub("%s+",""))]=_Vg
end
local function _W2()return(syn and syn.request)or(http and http.request)or http_request or(fluxus and fluxus.request)or request
end
local function _F2()local _m2=(tostring(_DV.HopFeedUrl or""):gsub("%s+",""))
_m2=(_m2:gsub("/+$",""))
if not _m2:match("^https?://")then return nil
end
return _m2
end
local function _j2(_k2,_J2,_D2)local _S2,_I2=_F2(),_W2()
if not _S2 or not _I2 then return nil
end
local _i2,_P2=pcall(_I2,{Url=_S2.._J2,Method=_k2,Headers={["Content-Type"]="application/json",["ngrok-skip-browser-warning"]="1"},Body=_D2 and _Kz:JSONEncode(_D2)or nil,})
if not _i2 or type(_P2)~="table"then return nil
end
local _q2=tonumber(_P2.StatusCode or _P2.Status)
if _q2 and(_q2<200 or _q2>=300)then return nil
end
local _T2
pcall(function()_T2=_Kz:JSONDecode(_P2.Body)
end)
return type(_T2)=="table"and _T2 or nil
end
local function _A2(_f2)local _R2,_x2=pcall(_f2)
return _R2 and _x2 or false
end
_zB=function(_w2)local _z2=false
for _Q2,_d2 in ipairs(_Jg())do local _e2=_cg(_d2)
if _e2~=""then if not string.find(_e2,_w2,1,true)then return false
end
_z2=true
end
end
return _z2
end
local function _v2()local _Y2={}
if _A2(_QB["Taoist"])then table.insert(_Y2,{event="Taoist"})
end
if _A2(_QB["Maoshan"])then table.insert(_Y2,{event="Maoshan"})
end
if _A2(_QB["God Spirit"])then table.insert(_Y2,{event="Spirit"})
end
local _E2,_u2=nil,true
for _p2,_c2 in ipairs(_Jg())do local _N2=_cg(_c2)
if _N2~=""then if _E2==nil then _E2=_N2
elseif _E2~=_N2 then _u2=false
end
end
end
if _E2 and _u2 then if string.find(_E2,"vermilion",1,true)then table.insert(_Y2,{event="Vermilion Birdblood"})
elseif string.find(_E2,"tortoise",1,true)then table.insert(_Y2,{event="Black Tortoise Bloodline"})
elseif _E2~="clear"and#_E2>=3 then table.insert(_Y2,{event="Weather",detail=_Hg[_E2]or _E2})
end
end
return _Y2
end
local function _b2(_s2,_X2)for _t2,_h2 in ipairs(_v2())do if _h2.event==_s2 then if _s2~="Weather"then return true
end
return _cg(_h2.detail)==_cg(_X2)
end
end
return false
end
local function _L2(_r2)local _o2=_j2("GET","/hop/list?place="..tostring(game.PlaceId).."&event=".._Kz:UrlEncode(_r2))
if not _o2 or type(_o2.servers)~="table"then return nil
end
return _o2.servers
end
local function _O2(_y2,_K2,_Z2)local _C2={}
for _n2,_M2 in ipairs(_y2)do if type(_M2)=="table"and tostring(_M2.event)==_K2 and tostring(_M2.job or"")~=""then if _K2~="Weather"or _cg(_M2.detail)==_cg(_Z2)then table.insert(_C2,_M2)
end
end
end
table.sort(_C2,function(_G2,_B2)local _g2,_l2=tonumber(_G2.players)or 0,tonumber(_B2.players)or 0
if _g2~=_l2 then return _g2<_l2
end
return(tonumber(_G2.age)or 0)<(tonumber(_B2.age)or 0)
end)
return _C2
end
local function _U2(_H2)_H2=tostring(_H2)
if _H2==tostring(game.JobId)then _uU("Server Hop",_Mg("Bạn đang ở server này rồi.","You are already in this server."),3)
return
end
_uU("Server Hop",_Mg("Đang vào server ","Joining server ")..string.sub(_H2,1,8).."...",3)
local _a2=pcall(function()_Zz:TeleportToPlaceInstance(game.PlaceId,_H2,_Gz)
end)
if not _a2 then _uU("Server Hop",_Mg("Không vào được server này.","Could not join this server."),4)
end
end
local _V2,_W7
local _F7=false
local function _m7()if _F7 then return
end
_F7=true
task.spawn(function()local _j7=_DV.HopListEvent
local _k7=_DV.HopListWeather
local _J7=_L2(_j7)
_F7=false
if not(_W7 and _V2)then return
end
if _J7==nil then _V2:Set(_Mg("Trạng thái: feed lỗi | ","Status: feed offline | ").._j7)
_W7:Set({},_Mg("Không kết nối được feed danh sách server. Kiểm tra Feed URL.","Could not reach the server list feed. Check the Feed URL."))
return
end
local _D7=_O2(_J7,_j7,_k7)
local _S7={}
for _I7,_i7 in ipairs(_D7)do local _P7=tostring(_i7.job)
local _q7=(_j7=="Weather")and("Weather: "..tostring(_i7.detail or _k7))or _j7
table.insert(_S7,{Text=string.format("%s | %d/%d | %s",_q7,tonumber(_i7.players)or 0,tonumber(_i7.max)or 0,string.sub(_P7,1,8)),Callback=function()_U2(_P7)
end,})
end
_V2:Set(string.format(_Mg("Trạng thái: %d server | %s","Status: %d server(s) | %s"),#_D7,_j7))
_W7:Set(_S7,string.format(_Mg("%s chưa có server nào. Bấm Làm mới.","%s has no active server. Press Refresh."),_j7))
end)
end
_dU.Hop:CreateSection("Danh sách Server Hop")
_dU.Hop:CreateDropdown({Flag="HopListEventDropdown",Name="Loại sự kiện",Options=_gg,CurrentOption=_DV.HopListEvent,MultipleOptions=false,AllowNone=false,Callback=function(_T7)if type(_T7)=="table"then _T7=_T7[1]
end
if not _lg(_T7)or _T7==_DV.HopListEvent then return
end
_DV.HopListEvent=_T7
_iV()
_m7()
end})
_dU.Hop:CreateDropdown({Flag="HopListWeatherDropdown",Name="Mục tiêu thời tiết",Options=_wg,CurrentOption=tostring(_DV.HopListWeather or"Thunderstorm"),MultipleOptions=false,AllowNone=false,Callback=function(_A7)if type(_A7)=="table"then _A7=_A7[1]
end
if not _A7 or _A7==_DV.HopListWeather then return
end
_DV.HopListWeather=_A7
_iV()
if _DV.HopListEvent=="Weather"then _m7()
end
end})
_V2=_dU.Hop:AddLabel(_Mg("Trạng thái: chưa làm mới | ","Status: not refreshed | ").._DV.HopListEvent)
_dU.Hop:CreateToggle({Flag="AutoHopConfirmedToggle",Name="Tự động hop server sự kiện đã xác nhận",CurrentValue=_DV.AutoHopConfirmed,Callback=function(_f7)_DV.AutoHopConfirmed=_f7
_iV()
end})
_dU.Hop:CreateButton({Name="Làm mới danh sách server",Callback=_m7})
_W7=_dU.Hop:AddServerList({Max=12})
_W7:Set({},_Mg("Bấm Làm mới để tải danh sách server.","Press Refresh to load the server list."))
_DV.HopFeedReport=true
local _R7,_x7=0,0
task.spawn(function()while true do task.wait(3)
if _DV.AutoHopConfirmed and not _vU and os.clock()-_eU>20 and _Gz.Character and game:IsLoaded()then local _w7,_z7=_DV.HopListEvent,_DV.HopListWeather
if _b2(_w7,_z7)then _DV.AutoHopConfirmed=false
_iV()
local _Q7=_hz.Flags["AutoHopConfirmedToggle"]
if _Q7 and _Q7.Set then pcall(_Q7.Set,_Q7,false,true)
end
_uU(_w7.." Found!",_Mg("Đã dừng tự động hop - ","Auto hop stopped - ").._w7.._Mg(" đang ở đây!"," is here!"),6)
elseif os.clock()-_R7>8 then _R7=os.clock()
local _d7=_L2(_w7)
local _e7=_YB()
local _v7={}
for _Y7,_E7 in ipairs(_e7.ids)do _v7[tostring(_E7)]=true
end
local _u7
for _p7,_c7 in ipairs(_d7 and _O2(_d7,_w7,_z7)or{})do local _N7=tostring(_c7.job)
if _N7~=tostring(game.JobId)and not _v7[_N7]then _u7=_N7
break
end
end
if _u7 then table.insert(_e7.ids,_u7)
_pB(_e7)
_vU=true
_uU("Server Hop",_Mg("Đang vào server ","Joining server ")..string.sub(_u7,1,8).."...",3)
pcall(function()_Zz:TeleportToPlaceInstance(game.PlaceId,_u7,_Gz)
end)
task.wait(8)
_vU=false
elseif os.clock()-_x7>30 then _x7=os.clock()
_uU("Server Hop",_Mg("Chưa có server xác nhận cho ","No confirmed server yet for ").._w7.._Mg(", đang chờ...",", waiting..."),4)
end
end
end
end
end)
task.spawn(function()task.wait(25)
while true do if _DV.HopFeedReport and _Gz.Character and game:IsLoaded()and game.PrivateServerId==""and tostring(game.JobId)~=""then local _b7,_s7=pcall(_v2)
if _b7 and#_s7>0 then _j2("POST","/hop/report",{place=tostring(game.PlaceId),job=tostring(game.JobId),events=_s7,players=#_Lz:GetPlayers(),max=_Lz.MaxPlayers,})
end
end
task.wait(45)
end
end)
_dU.Hop:CreateSection("Job ID")
local _X7=""
_dU.Hop:CreateInput({Flag="JobIdInput",Name="Job ID",Placeholder="Nhập Job ID...",Finished=false,Callback=function(_t7)_X7=(tostring(_t7 or""):gsub("%s+",""))
end})
_dU.Hop:CreateButton({Name="Vào server theo Job ID",Callback=function()if _X7==""then _uU("Job ID","Hãy nhập Job ID hợp lệ.",3)
return
end
_uU("Job ID","Đang vào server ".._X7.."...",3)
task.wait(0.3)
local _h7=pcall(function()_Zz:TeleportToPlaceInstance(game.PlaceId,_X7,_Gz)
end)
if not _h7 then _uU("Job ID","Không vào được server này.",4)
end
end})
_dU.Hop:CreateButton({Name="Sao chép Job ID hiện tại",Callback=function()local _L7=tostring(game.JobId or"")
local _r7=false
pcall(function()if setclipboard then setclipboard(_L7)
_r7=true
elseif toclipboard then toclipboard(_L7)
_r7=true
elseif syn and syn.write_clipboard then syn.write_clipboard(_L7)
_r7=true
end
end)
_uU("Job ID",(_r7 and"Đã sao chép: "or"Job ID: ").._L7,4)
end})
end
_dU.Settings:CreateSection("Language / Ngôn ngữ")
local _o7
_o7=_dU.Settings:CreateDropdown({Flag="LanguageDropdown",Name="Language / Ngôn ngữ",Options={"Tiếng Việt","English"},CurrentOption=_hz.Language,MultipleOptions=false,AllowNone=false,Callback=function(_O7)if type(_O7)=="table"then _O7=_O7[1]
end
_hz:SetLanguage(_O7)
_DV.Language=_hz.Language
_iV()
task.defer(function()if _o7 then _o7:Set(_hz.Language,true)
end
end)
end})
local _y7,_K7
local _Z7=0
local function _C7()local _n7=tick()
if _n7-_Z7<0.25 then return
end
_Z7=_n7
if _y7 then _y7:Set(not _DV.FlyEnabled)
else _DV.FlyEnabled=not _DV.FlyEnabled
_iV()
if _DV.FlyEnabled then _KY()
else _j6()
end
end
end
local _M7=0
local function _G7()local _B7=tick()
if _B7-_M7<0.25 then return
end
_M7=_B7
if _K7 then _K7:Set(not _DV.NoclipEnabled)
else _DV.NoclipEnabled=not _DV.NoclipEnabled
_iV()
end
end
_dU.Main:CreateSection("Bán cá")
_dU.Main:CreateToggle({Flag="AutoSellToggle",Name="Tự động bán cá",CurrentValue=_DV.AutoSell,Callback=function(_g7)_DV.AutoSell=_g7
if not _g7 then _ve=0
end
_iV()
end})
_dU.Main:CreateDropdown({Flag="AutoSellMethodDropdown",Name="Cách bán cá #1",Options={"Spam","When full"},CurrentOption=_DV.AutoSellMethod or"Spam",MultipleOptions=false,AllowNone=false,Callback=function(_l7)_DV.AutoSellMethod=_l7 or"Spam"
_iV()
end})
_dU.Main:CreateSection("Nhiệm vụ hàng ngày")
_dU.Main:CreateToggle({Flag="AutoDailyQuestToggle",Name="Tự nhận nhiệm vụ hàng ngày",Description="Tự tương tác với NPC nhiệm vụ hàng ngày và nhận thưởng",CurrentValue=_DV.AutoDailyQuest,Callback=function(_U7)_DV.AutoDailyQuest=_U7
_iV()
end})
_dU.Main:CreateSection("Nhiệm vụ vé tự động")
_dU.Main:CreateToggle({Flag="AutoTicketQuestToggle",Name="Tự nhận vé nhiệm vụ",CurrentValue=_DV.AutoTicketQuest,Callback=function(_H7)_DV.AutoTicketQuest=_H7
if not _H7 then _sN=0
end
_iV()
end})
_dU.Main:CreateDropdown({Flag="TicketQuestModeDropdown",Name="Chế độ nhiệm vụ",Options={"Hard","Easy"},CurrentOption=_DV.TicketQuestMode or"Hard",MultipleOptions=false,AllowNone=false,Callback=function(_a7)_DV.TicketQuestMode=_a7 or"Hard"
_iV()
end})
do local _V7=2000000
local _WQ="Dumb guy"
local function _FQ(_mQ,_jQ)pcall(function()_hz:Notify({Title="Dump Guy",Content=_mQ,Duration=_jQ or 4})
end)
end
local _kQ=0
local function _JQ(_DQ)if os.clock()-_kQ<3 then return
end
_kQ=os.clock()
_FQ(_DQ,4)
end
local function _SQ()return math.clamp(math.floor(tonumber(_DV.DumpGuyHotbarSlot)or 4),1,10)
end
local function _IQ(_iQ)local _PQ=tostring(_iQ or""):match("|%s*([%d,.]+)%s*$")
if not _PQ then return nil
end
return tonumber((_PQ:gsub(",","")))
end
local function _qQ(_TQ)local _AQ=_Uz:FindFirstChild("Hotbar")
local _fQ=_AQ and _AQ:FindFirstChild(tostring(_TQ))
local _RQ=_fQ and _fQ:FindFirstChild("ValueName")
local _xQ=_fQ and _fQ:FindFirstChild("Quantity")
if not _RQ or not _xQ then return nil
end
return{Name=tostring(_RQ.Value or""),Quantity=tonumber(_xQ.Value)or 0,Weight=_IQ(_RQ.Value),}
end
local function _wQ(_zQ)local _QQ={}
local _dQ=_Uz:FindFirstChild("Inventory")
if not _dQ then return _QQ
end
for _eQ,_vQ in ipairs(_dQ:GetChildren())do local _YQ=_IQ(_vQ.Name)
if _vQ:IsA("NumberValue")and _YQ and _zQ<_YQ and _vQ.Value>0 then table.insert(_QQ,{Name=_vQ.Name,Weight=_YQ})
end
end
table.sort(_QQ,function(_EQ,_uQ)return _EQ.Weight>_uQ.Weight
end)
return _QQ
end
local function _pQ(_cQ)local _NQ=_Bz:FindFirstChild("MoveItems")
if not _NQ then return false
end
if not pcall(function()_NQ:FireServer("Hotbar",tonumber(_cQ))
end)then return false
end
for _bQ=1,20 do task.wait(0.1)
local _sQ=_qQ(_cQ)
if _sQ and _sQ.Quantity<=0 and(_sQ.Name==""or _sQ.Name=="Inventory")then return true
end
end
return false
end
local function _XQ(_tQ,_hQ)local _LQ=_Bz:FindFirstChild("MoveItems")
if not _LQ or not _tQ or not _hQ then return false
end
if not pcall(function()_LQ:FireServer("Inventory",_tQ,_hQ)
end)then return false
end
for _rQ=1,10 do task.wait(0.15)
local _oQ=_Uz:FindFirstChild("Hotbar")
local _OQ=_oQ and _oQ:FindFirstChild(_hQ)
local _yQ=_OQ and _OQ:FindFirstChild("ValueName")
local _KQ=_OQ and _OQ:FindFirstChild("Quantity")
if _yQ and _KQ and tostring(_yQ.Value)==tostring(_tQ)and(tonumber(_KQ.Value)or 0)>0 then return true
end
end
return false
end
local function _ZQ()local _CQ=_Gz.Character
return _CQ~=nil and _CQ:GetAttribute("Type")=="Fish"
end
local function _nQ(_MQ,_GQ)if not pcall(function()_Hz:InvokeServer(tonumber(_MQ),nil)
end)then return false
end
for _BQ=1,12 do task.wait(0.1)
if _ZQ()then local _gQ=_Gz.Character
local _lQ=_gQ and _gQ:FindFirstChildOfClass("Tool")
if not _lQ or not _GQ or _lQ.Name==_GQ or _lQ:GetAttribute("ValueName")==_GQ or tostring(_lQ:GetAttribute("FishName")or"")==_GQ then return true
end
end
end
return false
end
local function _UQ()local _HQ=workspace:FindFirstChild("NPC")
local _aQ=_HQ and _HQ:FindFirstChild("Function")
local _VQ=_aQ and _aQ:FindFirstChild(_WQ)
if _VQ then return _VQ
end
local function _W3(_F3)return string.lower((tostring(_F3 or""):gsub("[%s_%-]+","")))
end
local _m3={dumbguy=true,dumpguy=true}
for _j3,_k3 in ipairs({_HQ,workspace})do if _k3 then for _J3,_D3 in ipairs(_k3:GetDescendants())do if(_D3:IsA("Model")or _D3:IsA("BasePart"))and _m3[_W3(_D3.Name)]then return _D3
end
end
end
end
return nil
end
local function _S3()local _I3=_UQ()
local _i3=_I3 and _YK(_I3)
local _P3=_Gz.Character
local _q3=(_P3 and _P3:FindFirstChild("HumanoidRootPart"))or _FY
if not _i3 or not _q3 then return false
end
_q3.CFrame=_i3.CFrame+Vector3.new(0,2,0)
task.wait(0.4)
return true
end
local function _T3()local _A3=_Bz:FindFirstChild("ChooseDialogueOption")
if not _A3 then _FQ("Remote ChooseDialogueOption not found!",3)
return false
end
local _f3=_UQ()
if not _f3 then _FQ("Dumb guy not found in workspace!",3)
return false
end
if pcall(function()_A3:FireServer(_WQ,1,"GiveFish",{_f3})
end)then return true
end
local _R3=_f3:FindFirstChild("ProximityPrompt",true)
if _R3 and fireproximityprompt then pcall(fireproximityprompt,_R3)
return true
end
return false
end
local function _x3()local _w3=_SQ()
local _z3=tostring(_w3)
local _Q3=_qQ(_w3)
if _Q3 and _Q3.Weight and _V7<=_Q3.Weight then if not _nQ(_z3)then return false,"Could not equip fish from hotbar slot ".._z3
end
task.wait(0.3)
if not _ZQ()then return false,"Not holding a fish!"
end
if not _S3()then return false,"Could not reach Dump Guy."
end
if not _T3()then return false,"Could not interact with Dump Guy."
end
return true,_Q3.Name~=""and _Q3.Name or"Fish"
end
if _Q3 and _Q3.Name~=""and _Q3.Name~="Inventory"then _pQ(_w3)
task.wait(0.3)
end
local _d3=_wQ(_V7-1)
if#_d3==0 then return false,"No fish at least 2,000,000 kg found."
end
local _e3=_d3[1]
if not _XQ(_e3.Name,_z3)then return false,"Could not move ".._e3.Name.." to hotbar"
end
task.wait(0.3)
if not _nQ(_z3,_e3.Name)then return false,"Could not equip ".._e3.Name
end
task.wait(0.3)
if not _ZQ()then return false,"Not holding a fish!"
end
if not _S3()then return false,"Could not reach Dump Guy."
end
if not _T3()then return false,"Could not interact with Dump Guy."
end
return true,_e3.Name
end
task.spawn(function()while true do if _DV.AutoGiveFish then local _v3,_Y3,_E3=pcall(_x3)
if _v3 and _Y3 then task.wait(1)
elseif _v3 and _E3 and not string.find(_E3,"No fish at least",1,true)then _JQ(_E3)
end
end
task.wait(1)
end
end)
_dU.Main:CreateSection("Dump Guy")
_dU.Main:CreateParagraph({Title="Give fish at least 2,000,000 kg",Content="Uses an eligible fish already in the selected slot, or moves a fish of at least 2M kg from the inventory. Default: slot 4."})
_dU.Main:CreateSlider({Flag="DumpGuyHotbarSlotSlider",Name="Hotbar slot for fish",CurrentValue=_SQ(),Range={1,10},Increment=1,Callback=function(_u3)_DV.DumpGuyHotbarSlot=math.clamp(math.floor(tonumber(_u3)or 4),1,10)
_iV()
end})
_dU.Main:CreateButton({Name="Give 1 Fish >= 2M kg",Callback=function()task.spawn(function()local _p3,_c3,_N3=pcall(_x3)
if _p3 and _c3 then _FQ("Fish removed from hotbar: "..tostring(_N3),4)
else _FQ(tostring(_p3 and _N3 or"Could not give fish."),4)
end
end)
end})
_dU.Main:CreateButton({Name="Teleport to Dump Guy",Callback=function()task.spawn(function()_FQ(_S3()and"Teleported to Dump Guy."or"Dump Guy NPC was not found.",3)
end)
end})
_dU.Main:CreateToggle({Flag="AutoGiveFishToggle",Name="Auto Give Fish >= 2M kg",CurrentValue=_DV.AutoGiveFish,Callback=function(_b3)_DV.AutoGiveFish=_b3
_iV()
end})
end
do local _s3={"Azure Carp","Jiaolong Dragonfish","Chainbound Shark","Adult Jiaolong Dragonfish","Elder Chainbound Shark","Elder Jiaolong Dragonfish","Trueform Jiaolongfish","Trueform Perch","Ascended Perch","Primordial Kunfish","Primordial Kunfish Overlord","Warbringer Shark","Dreadscale Grouper","Mutated Koid Whale","Radiant Goldfish","Serpent Fish","Dreadmare Eel","Chromatic Koi","Toxic Chromatic Koi","Crimson Bream Sovereign","Silver Bream Sovereign","Golden Guardian Fish","Colossal Tigerfish","Mountain Fish","Tiger Mirefish","Octoparasitic Fish","Dark kingfish","Golden Shark","Darkness Shark","White Heaven Kunfish","Crimson Bonefiend","Dragonfish Devourer","Yangfish Sovereign","Yangfish Empress","Yinfish Sovereign","Demon Bladefish","Apollo Swordfish","Killer Sawshark","Thunder Fish","Wind Fish","Intuitive Fish King","Aquatic Fish","Flame Fish","Verdant Alligator Gar","Verdant Grouper","Verdant Bonefang","Scarlet Fish","Mountain Dragonwhale","Flying Fish Emperor","Crimson Bonefang","Elder ScarletFish","Colossal Bull Shark","Flying Fish Empress","Draconic Koi","Tigerfang Whale","Golden Dragonfish","Crimson Electric Eel","Reborn Puffer Beast","Heavenpiercer Turtle","Sanguine Fish","Frost Kingfish","Dark Lionfish","Rainbow Dragonfish","Mirage lanternfish","Nameless Octoparasite","Frost QueenFish","Thunder Bull Shark","Black Tortoise Bloodline","Vermilion Birdblood"}
local function _X3(_t3)return(tostring(_t3 or""):gsub("^%s*(.-)%s*$","%1"))
end
local function _h3(_L3)if not _L3 or _L3==""then return""
end
local _r3=string.split(tostring(_L3),"| Favorite")[1]
_r3=string.split(_r3,"|")[1]
_r3=_X3(_r3)
local _o3=_yz:FindFirstChild("ClientModule")
local _O3=_o3 and _o3:FindFirstChild("GameService")
if _O3 then local _K3,_Z3=pcall(function()local _y3=require(_O3)
return _y3 and _y3.DestringFish and _y3.DestringFish(_r3)
end)
if _K3 and _Z3 and _Z3.FishName then return _Z3.FishName
end
end
local _C3=string.split(_r3,",")
if#_C3>=1 and _C3[1]~=""then return _C3[1]
end
return _r3
end
local function _n3()local _M3,_G3={},{}
pcall(function()local _B3=_gz:FindFirstChild("Inventory")
if not _B3 then return
end
for _g3,_l3 in ipairs(_B3:GetChildren())do if not _G3[_l3.Name]then local _U3=_KV(_l3)
if _U3 and _U3.Boss==true then _G3[_l3.Name]=true
table.insert(_M3,_l3.Name)
end
end
end
end)
if#_M3==0 then for _H3,_a3 in ipairs(_s3)do if not _G3[_a3]then _G3[_a3]=true
table.insert(_M3,_a3)
end
end
end
table.sort(_M3)
return _M3
end
local _V3=_n3()
local function _WA(_FA)local _mA={}
if type(_FA)=="table"then for _jA,_kA in pairs(_FA)do local _JA
if type(_jA)=="string"and _kA==true then _JA=_jA
elseif type(_kA)=="string"and _kA~=""then _JA=_kA
end
if _JA and table.find(_V3,_JA)and not table.find(_mA,_JA)then table.insert(_mA,_JA)
end
end
elseif type(_FA)=="string"and table.find(_V3,_FA)then table.insert(_mA,_FA)
end
return _mA
end
_DV.AutoGiveEventFishTarget=_WA(_DV.AutoGiveEventFishTarget)
local function _DA()local _SA,_IA={},false
local _iA=_DV.AutoGiveEventFishTarget
if type(_iA)=="table"then for _PA,_qA in pairs(_iA)do local _TA
if type(_PA)=="string"and _qA==true then _TA=_PA
elseif type(_qA)=="string"and _qA~=""then _TA=_qA
end
if _TA then local _AA=string.lower(_X3(_TA))
if _AA~=""then _SA[_AA]=true
_IA=true
end
end
end
end
return _SA,_IA
end
local _fA,_RA=nil,0
local function _xA(_wA)return string.lower((tostring(_wA or""):gsub("[%s_%-]+","")))
end
local function _zA()if _fA and _fA.Parent then return _fA
end
_fA=nil
local _QA=workspace:FindFirstChild("NPC")
local _dA=_QA and _QA:FindFirstChild("Function")
local _eA=_dA and _dA:FindFirstChild("Noro Derasu")
if not _eA and os.clock()-_RA>3 then _RA=os.clock()
_eA=workspace:FindFirstChild("Noro Derasu",true)
if not _eA then for _vA,_YA in ipairs(workspace:GetDescendants())do if(_YA:IsA("Model")or _YA:IsA("BasePart"))and _xA(_YA.Name)=="noroderasu"then _eA=_YA
break
end
end
end
end
_fA=_eA
return _eA
end
local function _EA(_uA,_pA)if not _uA or _uA==""then return false
end
if string.find(_uA,"Favorite",1,true)or string.find(_uA,"Lock",1,true)then return false
end
if not _pA or next(_pA)==nil then return false
end
local _cA=string.lower(_X3(_h3(_uA)))
if _cA~=""and _pA[_cA]then return true
end
local _NA=_X3(string.gsub(_cA,"%s*[%(%[].-$",""))
return _NA~=""and _pA[_NA]==true
end
local function _bA()local _sA=_Uz:FindFirstChild("Hotbar")
if not _sA then return"4"
end
for _XA=4,10 do local _tA=_sA:FindFirstChild(tostring(_XA))
if _tA then local _hA=_tA:FindFirstChild("ValueName")
local _LA=_tA:FindFirstChild("Quantity")
if(not _hA or _hA.Value=="")or(_LA and _LA.Value<=0)then return tostring(_XA)
end
end
end
return"4"
end
local function _rA(_oA)local _OA=_Uz:FindFirstChild("Hotbar")
if _OA then for _yA=2,10 do local _KA=_OA:FindFirstChild(tostring(_yA))
local _ZA=_KA and _KA:FindFirstChild("ValueName")
local _CA=_KA and _KA:FindFirstChild("Quantity")
if _ZA and _ZA.Value~=""and(not _CA or(tonumber(_CA.Value)or 0)>0)and _EA(_ZA.Value,_oA)then return tostring(_yA),nil,"H".._yA.._ZA.Value.."#"..tostring(_CA and _CA.Value or 1)
end
end
end
local _nA=_Uz:FindFirstChild("Inventory")
if _nA then for _MA,_GA in ipairs(_nA:GetChildren())do if _GA.Name~=""and(not _GA:IsA("ValueBase")or(tonumber(_GA.Value)or 0)>0)and _EA(_GA.Name,_oA)then local _BA=_GA:IsA("ValueBase")and tostring(_GA.Value)or"1"
return nil,_GA,"I".._GA.Name.."#".._BA
end
end
end
return nil
end
local function _gA(_lA)if not _lA then return nil
end
if _lA:IsA("BasePart")then return _lA
end
return _lA.PrimaryPart or _lA:FindFirstChild("HumanoidRootPart")or _lA:FindFirstChildWhichIsA("BasePart",true)
end
local function _UA()local _HA=_Gz.Character
return _HA~=nil and _HA:GetAttribute("Type")=="Fish"
end
local _aA=0
local function _VA(_Wy)if os.clock()-_aA<6 then return
end
_aA=os.clock()
pcall(function()_hz:Notify({Title="Limited Event",Content=_Wy,Duration=4})
end)
end
local _Fy=0
local _my,_jy=false,0
function _n6.HasPendingEventFish()if not _DV.AutoGiveEventFish then return false
end
local _ky=os.clock()
if _ky<_Fy then return false
end
if _ky-_jy<0.5 then return _my
end
_jy=_ky
_my=false
local _Jy,_Dy=_DA()
if _Dy and _zA()then local _Sy,_Iy,_iy=_rA(_Jy)
_my=_iy~=nil
end
return _my
end
local _Py,_qy,_Ty=0,nil,0
local function _Ay()if not _DV.AutoGiveEventFish then return
end
local _fy=os.clock()
if _fy<_Fy or _fy-_Py<1.5 then return
end
local _Ry,_xy=_DA()
if not _xy then return
end
local _wy,_zy,_Qy=_rA(_Ry)
if not _Qy then _qy,_Ty=nil,0
return
end
local _dy=_zA()
if not _dy then _VA("Không tìm thấy NPC Noro Derasu.")
return
end
if _Qy==_qy then _Ty=_Ty+1
else _qy,_Ty=_Qy,1
end
if _Ty>4 then _qy,_Ty=nil,0
_Fy=os.clock()+60
_VA("Không đưa được cá cho Noro Derasu, tạm dừng 60 giây.")
return
end
_Py=_fy
if not _wy then local _ey=_bA()
local _vy=_Bz:FindFirstChild("MoveItems")
if not _vy then return
end
pcall(function()_vy:FireServer("Inventory",_zy.Name,_ey)
end)
for _Yy=1,10 do task.wait(0.15)
local _Ey=_Uz:FindFirstChild("Hotbar")
local _uy=_Ey and _Ey:FindFirstChild(_ey)
local _py=_uy and _uy:FindFirstChild("ValueName")
local _cy=_uy and _uy:FindFirstChild("Quantity")
if _py and tostring(_py.Value)==_zy.Name and(not _cy or(tonumber(_cy.Value)or 0)>0)then _wy=_ey
break
end
end
if not _wy then return
end
end
do local _Ny,_by,_sy=_rA(_Ry)
if _sy then _Qy=_sy
end
end
local _Xy
local _ty=_Gz.Character
local _hy=_ty and _ty:FindFirstChild("HumanoidRootPart")
local _Ly=_gA(_dy)
if _DV.EventGiveTeleport~=false and _hy and _Ly and(_hy.Position-_Ly.Position).Magnitude>8 then _Xy=_hy.CFrame
_hy.CFrame=_Ly.CFrame+Vector3.new(0,3,0)
task.wait(0.5)
end
local function _ry()if _Xy then local _oy=_Gz.Character
local _Oy=_oy and _oy:FindFirstChild("HumanoidRootPart")
if _Oy then _Oy.CFrame=_Xy
end
end
end
for _yy=1,2 do pcall(function()_Hz:InvokeServer(tonumber(_wy),nil)
end)
for _Ky=1,12 do task.wait(0.1)
if _UA()then break
end
end
if _UA()then break
end
end
if not _UA()then _VA("Không cầm được cá ở ô "..tostring(_wy)..".")
_ry()
return
end
local function _Zy()local _Cy,_ny,_My=_rA(_Ry)
return _My~=_Qy
end
local _Gy=ChooseDialogueOption or _Bz:FindFirstChild("ChooseDialogueOption")
local _By=false
if _Gy then pcall(function()_Gy:FireServer("Noro Derasu",1,"GiveFish",{_dy})
end)
for _gy=1,8 do task.wait(0.1)
if _Zy()then _By=true
break
end
end
if not _By and _dy.Name~="Noro Derasu"then pcall(function()_Gy:FireServer(_dy.Name,1,"GiveFish",{_dy})
end)
for _ly=1,8 do task.wait(0.1)
if _Zy()then _By=true
break
end
end
end
end
if not _By then local _Uy=_dy:FindFirstChildWhichIsA("ProximityPrompt",true)
if _Uy and fireproximityprompt then pcall(fireproximityprompt,_Uy)
for _Hy=1,10 do task.wait(0.1)
if _Zy()then _By=true
break
end
end
end
end
if not _By then print("[Uzex] Noro Derasu: GiveFish did not remove the fish. NPC =",_dy:GetFullName(),"| slot =",_wy)
_VA("Gửi cá cho Noro Derasu chưa thành công (".._dy:GetFullName()..").")
end
_ry()
end
task.spawn(function()while task.wait(0.25)do if _DV.AutoGiveEventFish then pcall(_Ay)
end
end
end)
_dU.LimitedEvent:CreateSection("Tự động đưa cá")
_dU.LimitedEvent:CreateToggle({Flag="AutoGiveEventFishToggle",Name="Tự động đưa cá",CurrentValue=_DV.AutoGiveEventFish,Callback=function(_ay)_DV.AutoGiveEventFish=_ay
_iV()
end})
_dU.LimitedEvent:CreateToggle({Flag="EventGiveTeleportToggle",Name="Tự dịch chuyển tới NPC",CurrentValue=_DV.EventGiveTeleport~=false,Callback=function(_Vy)_DV.EventGiveTeleport=_Vy
_iV()
end})
_n6.CreateFishSearchDropdown({Tab=_dU.LimitedEvent,Flag="AutoGiveEventFishDropdown",Name="Chọn cá boss",Options=_V3,Multi=true,Current=table.clone(_DV.AutoGiveEventFishTarget),GetSelected=function()return _DV.AutoGiveEventFishTarget
end,SetSelected=function(_WP)_DV.AutoGiveEventFishTarget=_WA(_WP)
_iV()
end,})
end
_dU.Settings:CreateSection("Chung")
_dU.Settings:CreateToggle({Flag="AutoExecuteToggle",Name="Tự chạy script",CurrentValue=_DV.AutoExecute,Callback=function(_FP)_DV.AutoExecute=_FP
_iV()
if _FP then _YV()
end
end})
_dU.Settings:CreateSection("Di chuyển")
_dU.Settings:CreateToggle({Flag="LoopSpeedToggle",Name="Tốc độ đi bộ",CurrentValue=_DV.LoopSpeedEnabled,Callback=function(_mP)_DV.LoopSpeedEnabled=_mP
_iV()
end})
_dU.Settings:CreateSlider({Flag="WalkSpeedSlider",Name="Tốc độ",CurrentValue=_DV.WalkSpeed,Range={16,250},Increment=1,Callback=function(_jP)_DV.WalkSpeed=_jP
_iV()
end})
_y7=_dU.Settings:CreateToggle({Flag="FlyToggle",Name="Bay",CurrentValue=_DV.FlyEnabled,Callback=function(_kP)_DV.FlyEnabled=_kP
_iV()
if _kP then _KY()
else _j6()
end
end})
_dU.Settings:CreateSlider({Flag="FlySpeedSlider",Name="Tốc độ bay",CurrentValue=_DV.FlySpeed,Range={1,20},Increment=0.1,Callback=function(_JP)_DV.FlySpeed=_JP
_iV()
end})
_K7=_dU.Settings:CreateToggle({Flag="NoclipToggle",Name="Đi xuyên vật thể",CurrentValue=_DV.NoclipEnabled,Callback=function(_DP)_DV.NoclipEnabled=_DP
_iV()
end})
_dU.Settings:CreateToggle({Flag="InfJumpToggle",Name="Nhảy vô hạn",CurrentValue=_DV.InfJumpEnabled,Callback=function(_SP)_DV.InfJumpEnabled=_SP
_iV()
end})
_dU.Teleport:CreateSection("Đảo")
do local _IP=_uk()
if(_DV.SelectedIsland==""or not table.find(_IP,_DV.SelectedIsland))and#_IP>0 then _DV.SelectedIsland=_IP[1]
end
_dU.Teleport:CreateDropdown({Flag="SelectIslandDropdown",Name="Chọn đảo",Options=_IP,CurrentOption=_DV.SelectedIsland~=""and _DV.SelectedIsland or _IP[1],MultipleOptions=false,AllowNone=false,Callback=function(_iP)_DV.SelectedIsland=_iP or""
_iV()
end})
end
_dU.Teleport:CreateButton({Name="Dịch chuyển đến đảo",Callback=function()_jr(_DV.SelectedIsland)
end})
_dU.Teleport:CreateSection("NPC")
do local _PP=_dr()
if(_DV.SelectedNPC==""or not table.find(_PP,_DV.SelectedNPC))and#_PP>0 then _DV.SelectedNPC=_PP[1]
end
local _TP=_dU.Teleport:CreateDropdown({Flag="SelectNPCDropdown",Name="Chọn NPC",Options=_PP,CurrentOption=_DV.SelectedNPC~=""and _DV.SelectedNPC or _PP[1],MultipleOptions=false,AllowNone=false,Callback=function(_qP)_DV.SelectedNPC=_qP or""
_iV()
end})
_dU.Teleport:CreateButton({Name="Dịch chuyển đến NPC",Callback=function()local _AP=(_TP and _TP:Get())or _DV.SelectedNPC
_oS(_AP)
end})
end
_dU.Teleport:CreateSection("Người chơi")
do local _fP=_R0()
if#_fP==0 then _fP={"None"}
end
if(_DV.SelectedPlayer==""or not table.find(_fP,_DV.SelectedPlayer))and#_fP>0 then _DV.SelectedPlayer=_fP[1]
end
local _xP=_dU.Teleport:CreateDropdown({Flag="SelectPlayerDropdown",Name="Chọn người chơi",Options=_fP,CurrentOption=_DV.SelectedPlayer~=""and _DV.SelectedPlayer or _fP[1],MultipleOptions=false,AllowNone=false,Callback=function(_RP)_DV.SelectedPlayer=_RP or""
_iV()
end})
local function _wP()local _zP=_R0()
if#_zP==0 then _zP={"None"}
end
if _xP then _xP:Refresh(_zP,true,true)
if not table.find(_zP,_DV.SelectedPlayer)then _xP:Set(_zP[1])
end
end
end
_Lz.PlayerAdded:Connect(function()task.wait(0.5)
_wP()
end)
_Lz.PlayerRemoving:Connect(function()task.wait(0.5)
_wP()
end)
_dU.Teleport:CreateButton({Name="Dịch chuyển đến người chơi",Callback=function()local _QP=(_xP and _xP:Get())or _DV.SelectedPlayer
if _QP and _QP~="None"then _e0(_QP)
end
end})
end
_dU.Shop:CreateSection("Index")
_dU.Shop:CreateButton({Name="Unlock all fish (Risk)",Description="Sets every fish in your Index data to unlocked",Callback=function()local _dP=_Uz and _Uz:FindFirstChild("Index")
if not _dP then pcall(function()_hz:Notify({Title="Index",Content="Index folder not found!",Type="warning",Duration=2,})
end)
return
end
local _eP=0
for _vP,_YP in ipairs(_dP:GetChildren())do if _YP:IsA("NumberValue")or _YP:IsA("IntValue")then _YP.Value=1
_eP=_eP+1
elseif _YP:IsA("BoolValue")then _YP.Value=true
_eP=_eP+1
end
end
pcall(function()_hz:Notify({Title="Index",Content="Unlocked ".._eP.." fish!",Type="success",Duration=3,})
end)
end})
_dU.Shop:CreateSection("Mua mồi")
do local _EP=_XN()
if _DV.SelectedBuyBait==""and#_EP>0 then _DV.SelectedBuyBait=_EP[1]
end
_dU.Shop:CreateDropdown({Flag="SelectBuyBaitDropdown",Name="Chọn mồi",Options=_EP,CurrentOption=_DV.SelectedBuyBait~=""and _DV.SelectedBuyBait or _EP[1],MultipleOptions=false,AllowNone=false,Callback=function(_uP)_DV.SelectedBuyBait=_uP or""
_iV()
end})
end
_dU.Shop:CreateInput({Flag="BuyBaitAmountInput",Name="Số lượng mua",CurrentValue=tostring(_DV.BuyBaitAmount or 1),Numeric=true,Finished=false,Placeholder="1",Callback=function(_pP)_DV.BuyBaitAmount=math.max(1,math.floor(tonumber(_pP)or 1))
_iV()
end})
_dU.Shop:CreateInput({Flag="BuyBaitDelayInput",Name="Độ trễ mua (phút)",CurrentValue=tostring(_DV.BuyBaitDelay or 1),Numeric=true,Finished=false,Placeholder="1",Callback=function(_cP)_DV.BuyBaitDelay=math.max(1,math.floor(tonumber(_cP)or 1))
_iV()
end})
_dU.Shop:CreateToggle({Flag="AutoBuyBaitToggle",Name="Tự động mua mồi",CurrentValue=_DV.AutoBuyBait,Callback=function(_NP)_DV.AutoBuyBait=_NP
if not _NP then _Ye=0
end
_iV()
end})
_dU.Shop:CreateButton({Name="Mua mồi",Callback=function()_te(_DV.SelectedBuyBait,_DV.BuyBaitAmount)
end})
_dU.Shop:CreateSection("Chế tạo mồi")
do local _bP=_aI()
if _DV.SelectedBait==""and#_bP>0 then _DV.SelectedBait=_bP[1]
end
_dU.Shop:CreateDropdown({Flag="SelectBaitDropdown",Name="Chọn mồi",Options=_bP,CurrentOption=_DV.SelectedBait~=""and _DV.SelectedBait or _bP[1],MultipleOptions=false,AllowNone=false,Callback=function(_sP)_DV.SelectedBait=_sP or""
_iV()
end})
end
_dU.Shop:CreateInput({Flag="BaitAmountInput",Name="Số lượng chế tạo",CurrentValue=tostring(_DV.BaitAmount or 1),Numeric=true,Finished=false,Placeholder="1",Callback=function(_XP)_DV.BaitAmount=math.max(1,math.floor(tonumber(_XP)or 1))
_iV()
end})
_dU.Shop:CreateToggle({Flag="AutoCraftBaitToggle",Name="Tự động chế tạo mồi",CurrentValue=_DV.AutoCraftBait,Callback=function(_tP)_DV.AutoCraftBait=_tP
_iV()
end})
_dU.Shop:CreateButton({Name="Chế tạo mồi",Callback=function()if _DV.SelectedBait~=""then _mV:FireServer(_DV.SelectedBait,math.max(1,math.floor(tonumber(_DV.BaitAmount)or 1)))
end
end})
_dU.Shop:CreateSection("Chế tạo cần câu")
do local _hP=_kk()
if _DV.SelectedRod==""and#_hP>0 then _DV.SelectedRod=_hP[1]
end
_dU.Shop:CreateDropdown({Flag="SelectRodDropdown",Name="Chọn cần câu",Options=_hP,CurrentOption=_DV.SelectedRod~=""and _DV.SelectedRod or _hP[1],MultipleOptions=false,AllowNone=false,Callback=function(_LP)_DV.SelectedRod=_LP or""
_iV()
end})
end
_dU.Shop:CreateToggle({Flag="AutoCraftRodToggle",Name="Tự động chế tạo cần câu",CurrentValue=_DV.AutoCraftRod,Callback=function(_rP)_DV.AutoCraftRod=_rP
_iV()
end})
_dU.Shop:CreateButton({Name="Chế tạo cần câu",Callback=function()if _DV.SelectedRod~=""then _jV:FireServer(_DV.SelectedRod)
end
end})
_dU.Settings:CreateSection("ESP")
_dU.Settings:CreateToggle({Flag="ESPPlayers",Name="ESP người chơi",CurrentValue=_DV.ESPEnabled,Callback=function(_oP)_DV.ESPEnabled=_oP
_iV()
if not _oP then _NK()
end
end})
do local _OP={}
local function _yP(_KP,_ZP)local _CP=table.concat(_KP,"|")
local _nP=_OP[_CP]
if _nP and _nP.Parent then return _nP
end
for _MP,_GP in ipairs({_Bz,game:GetService("ReplicatedStorage")})do for _BP,_gP in ipairs(_GP:GetDescendants())do if _gP:IsA("RemoteEvent")or _gP:IsA("RemoteFunction")then local _lP=string.lower(_gP.Name)
local _UP=false
for _HP,_aP in ipairs(_ZP or{})do if string.find(_lP,_aP,1,true)then _UP=true
end
end
if not _UP then for _VP,_Wj in ipairs(_KP)do if string.find(_lP,_Wj,1,true)then _OP[_CP]=_gP
return _gP
end
end
end
end
end
end
return nil
end
local function _Fj(_mj,...)local _jj=table.pack(...)
pcall(function()if _mj:IsA("RemoteFunction")then _mj:InvokeServer(table.unpack(_jj,1,_jj.n))
else _mj:FireServer(table.unpack(_jj,1,_jj.n))
end
end)
end
local _kj={cash={"cash","balance","money","coins"},level={"level","lvl"},crystal={"crystal","crystals","gem","gems"},ticket={"ticket","tickets"},}
local function _Jj(_Dj)local _Sj=_kj[string.lower(_Dj)]or{string.lower(_Dj)}
local _Ij={_Uz,_Gz:FindFirstChild("leaderstats"),_Gz}
for _ij,_Pj in ipairs(_Ij)do if _Pj then for _qj,_Tj in ipairs(_Pj:GetChildren())do if _Tj:IsA("ValueBase")then local _Aj=string.lower(_Tj.Name)
for _fj,_Rj in ipairs(_Sj)do if _Aj==_Rj then return _Tj.Value
end
end
end
end
local _xj=_Pj:GetAttribute(_Dj)
if _xj~=nil then return _xj
end
end
end
return nil
end
_dU.Upgrade:CreateSection("Nâng cấp nhân vật")
_dU.Upgrade:CreateDropdown({Flag="UpgradeOptionsDropdown",Name="Chọn 2 mục nâng cấp",Options={"Cash","Level","Crystal","Ticket"},CurrentOption=table.clone(type(_DV.UpgradeOptions)=="table"and _DV.UpgradeOptions or{"Cash","Level"}),MultipleOptions=true,Callback=function(_wj)if type(_wj)~="table"then return
end
local _zj={}
for _Qj,_dj in ipairs(_wj)do if _Qj<=2 then table.insert(_zj,_dj)
end
end
_DV.UpgradeOptions=_zj
_iV()
end})
_dU.Upgrade:CreateDropdown({Flag="UpgradeMethodDropdown",Name="Phương thức nâng cấp",Options={"Instant"},CurrentOption="Instant",MultipleOptions=false,AllowNone=false,Callback=function(_ej)_DV.UpgradeMethod="Instant"
_iV()
end})
_dU.Upgrade:CreateToggle({Flag="AutoRebirthToggle",Name="Tự động tái sinh",CurrentValue=_DV.AutoRebirth,Callback=function(_vj)_DV.AutoRebirth=_vj
_iV()
end})
_dU.Upgrade:CreateButton({Name="Kiểm tra tài nguyên",Callback=function()local _Yj={}
for _Ej,_uj in ipairs({"Cash","Level","Crystal","Ticket"})do local _pj=_Jj(_uj)
table.insert(_Yj,_uj..": "..(_pj~=nil and tostring(_pj)or"?"))
end
pcall(function()_hz:Notify({Title="Tài nguyên",Content=#_Yj>0 and table.concat(_Yj,"  |  ")or"No upgrade option selected",Duration=5,})
end)
end})
task.spawn(function()local _cj=false
while true do task.wait(0.5)
if _DV.AutoRebirth then local _Nj=_yP({"rebirth"})
if _Nj then local _bj=_yP({"upgrade"},{"skill"})
if _bj then for _sj,_Xj in ipairs(_DV.UpgradeOptions or{})do _Fj(_bj,_Xj)
end
end
_Fj(_Nj)
elseif not _cj then _cj=true
pcall(function()_hz:Notify({Title="Tự động tái sinh",Content="Không tìm thấy chức năng tái sinh trong game này",Type="warning",Duration=5,})
end)
end
else _cj=false
end
end
end)
end
_dU.Misc:CreateSection("Hiển thị")
_dU.Misc:CreateToggle({Flag="AntiAFKToggle",Name="Chống AFK",CurrentValue=_DV.AntiAFK,Callback=function(_tj)_DV.AntiAFK=_tj
_iV()
end})
_dU.Misc:CreateToggle({Flag="AntiStaffToggle",Name="Chống quản trị viên",Description="Leaves the server when a staff member is in it",CurrentValue=_DV.AntiStaff,Callback=function(_hj)_DV.AntiStaff=_hj
if _hj then table.clear(_n6.AntiChecked)
end
_iV()
end})
do local _Lj={}
function _n6.ApplyHideName()local _rj=_Gz.Character
if not _rj then return
end
local _oj=_rj:FindFirstChildOfClass("Humanoid")
if _oj then _oj.DisplayDistanceType=_DV.HideName and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Viewer
end
for _Oj,_yj in ipairs(_rj:GetDescendants())do if _yj:IsA("BillboardGui")then if _DV.HideName then if _Lj[_yj]==nil then _Lj[_yj]=_yj.Enabled
end
_yj.Enabled=false
elseif _Lj[_yj]~=nil then _yj.Enabled=_Lj[_yj]
_Lj[_yj]=nil
end
end
end
end
_Gz.CharacterAdded:Connect(function()task.wait(1)
if _DV.HideName then pcall(_n6.ApplyHideName)
end
end)
task.spawn(function()while task.wait(2)do if _DV.HideName then pcall(_n6.ApplyHideName)
end
end
end)
end
_dU.Misc:CreateToggle({Flag="FullBrightToggle",Name="Tăng sáng tối đa",CurrentValue=_DV.FullBright,Callback=function(_Kj)_DV.FullBright=_Kj
_iV()
if _Kj then _qU()
else _fU()
if _DV.NoFog then _qU()
end
end
end})
_dU.Misc:CreateToggle({Flag="NoFogToggle",Name="Tắt sương mù",CurrentValue=_DV.NoFog,Callback=function(_Zj)_DV.NoFog=_Zj
_iV()
if _Zj then _qU()
else _RU()
if _DV.FullBright then _qU()
end
end
end})
do local _Cj={__mode="k"}
local _nj=setmetatable({},_Cj)
local _Mj=setmetatable({},_Cj)
local _Gj=setmetatable({},_Cj)
local _Bj=setmetatable({},_Cj)
local _gj=setmetatable({},_Cj)
local _lj={}
local _Uj=nil
local _Hj=nil
local _aj=0
local _Vj={ParticleEmitter=true,Trail=true,Beam=true,Smoke=true,Fire=true,Sparkles=true,BloomEffect=true,BlurEffect=true,SunRaysEffect=true,DepthOfFieldEffect=true,Clouds=true,PointLight=true,SpotLight=true,SurfaceLight=true,Highlight=true,ColorCorrectionEffect=true,}
local _Wa=8
local _Fa=120
local function _ma(_ja)local _ka=0
local _Ja=os.clock()
local _Da=_Oz.Heartbeat:Connect(function()_ka=_ka+1
end)
task.wait(_ja)
_Da:Disconnect()
return _ka/math.max(os.clock()-_Ja,0.01)
end
local function _Sa(_Ia)local _ia=_Ia.ClassName
if _Vj[_ia]then if _Ia.Enabled then _Gj[_Ia]=true
_Ia.Enabled=false
_aj=_aj+1
end
elseif _Ia:IsA("BasePart")then if _nj[_Ia]==nil then local _Pa,_qa
if _Ia:IsA("MeshPart")then _Pa=_Ia.RenderFidelity
_qa=_Ia.TextureID
end
_nj[_Ia]={_Ia.Material,_Ia.Reflectance,_Ia.CastShadow,_Pa,_qa}
_Ia.Material=Enum.Material.SmoothPlastic
_Ia.Reflectance=0
_Ia.CastShadow=false
if _Pa then _Ia.RenderFidelity=Enum.RenderFidelity.Performance
if _qa and _qa~=""then _Ia.TextureID=""
end
end
_aj=_aj+1
end
elseif _ia=="Explosion"then if _gj[_Ia]==nil then _gj[_Ia]=_Ia.Visible
_Ia.Visible=false
_aj=_aj+1
end
elseif _Ia:IsA("Decal")then if _Mj[_Ia]==nil then _Mj[_Ia]=_Ia.Transparency
_Ia.Transparency=1
_aj=_aj+1
end
elseif _ia=="SurfaceAppearance"then if _lj[_Ia]==nil and _Ia.Parent then _lj[_Ia]=_Ia.Parent
_Ia.Parent=nil
_aj=_aj+1
end
elseif _ia=="Atmosphere"then if _Bj[_Ia]==nil then _Bj[_Ia]=_Ia.Density
_Ia.Density=0
_aj=_aj+1
end
end
end
local function _Ta(_Aa)if _Aa then if _Uj then return
end
local _fa={}
_Uj=_fa
_aj=0
task.spawn(function()local _Ra=_ma(1)
if _Uj~=_fa then return
end
pcall(function()local _xa=settings().Rendering
_fa.quality=_xa.QualityLevel
_fa.meshDetail=_xa.MeshPartDetailLevel
_xa.QualityLevel=Enum.QualityLevel:FromValue(_Wa)
_xa.MeshPartDetailLevel=Enum.MeshPartDetailLevel.Level04
end)
pcall(function()local _wa=UserSettings():GetService("UserGameSettings")
_fa.saved=_wa.SavedQualityLevel
_wa.SavedQualityLevel=Enum.SavedQualitySetting["QualityLevel".._Wa]
end)
pcall(function()if type(setfpscap)=="function"then _fa.fpsCap=(type(getfpscap)=="function"and getfpscap())or 60
setfpscap(_Fa)
end
end)
pcall(function()_fa.lighting={_Cz.GlobalShadows,_Cz.EnvironmentDiffuseScale,_Cz.EnvironmentSpecularScale,_Cz.ShadowSoftness,_Cz.Technology,}
_Cz.GlobalShadows=false
_Cz.EnvironmentDiffuseScale=0
_Cz.EnvironmentSpecularScale=0
_Cz.ShadowSoftness=0
_Cz.Technology=Enum.Technology.Compatibility
end)
pcall(function()local _za=game:GetService("MaterialService")
_fa.materials2022=_za.Use2022Materials
_za.Use2022Materials=false
end)
pcall(function()local _Qa=workspace:FindFirstChildOfClass("Terrain")
if _Qa then _fa.terrain={_Qa.WaterWaveSize,_Qa.WaterWaveSpeed,_Qa.WaterReflectance,_Qa.Decoration,}
_Qa.WaterWaveSize=0
_Qa.WaterWaveSpeed=0
_Qa.WaterReflectance=0
_Qa.Decoration=false
end
end)
_Hj=workspace.DescendantAdded:Connect(function(_da)pcall(_Sa,_da)
end)
local _ea=0
for _va,_Ya in ipairs({workspace,_Cz})do for _Ea,_ua in ipairs(_Ya:GetDescendants())do if _Uj~=_fa then return
end
pcall(_Sa,_ua)
_ea=_ea+1
if _ea%300==0 then task.wait()
end
end
end
task.wait(1.5)
local _pa=_ma(2)
if _Uj~=_fa then return
end
local _ca
if _Ra>=58 then _ca=string.format("%d objects optimized. FPS is at the cap (%d), so only GPU load and heat drop.",_aj,math.floor(_pa+0.5))
elseif _pa>_Ra+1 then _ca=string.format("FPS %d -> %d (%d objects optimized)",math.floor(_Ra+0.5),math.floor(_pa+0.5),_aj)
else _ca=string.format("%d objects optimized. FPS stayed near %d, the limit is elsewhere (CPU or network).",_aj,math.floor(_pa+0.5))
end
pcall(function()_hz:Notify({Title="Chế độ hiệu năng",Content=_ca,Type="success",Duration=5})
end)
end)
else if not _Uj then return
end
if _Hj then _Hj:Disconnect()
_Hj=nil
end
local _Na=_Uj
_Uj=nil
pcall(function()if _Na.quality then settings().Rendering.QualityLevel=_Na.quality
end
if _Na.meshDetail then settings().Rendering.MeshPartDetailLevel=_Na.meshDetail
end
end)
pcall(function()if _Na.fpsCap and type(setfpscap)=="function"then setfpscap(_Na.fpsCap)
end
end)
pcall(function()if _Na.materials2022~=nil then game:GetService("MaterialService").Use2022Materials=_Na.materials2022
end
end)
pcall(function()if _Na.saved then UserSettings():GetService("UserGameSettings").SavedQualityLevel=_Na.saved
end
end)
pcall(function()local _ba=_Na.lighting
if _ba then _Cz.GlobalShadows,_Cz.EnvironmentDiffuseScale=_ba[1],_ba[2]
_Cz.EnvironmentSpecularScale,_Cz.ShadowSoftness=_ba[3],_ba[4]
if _ba[5]then _Cz.Technology=_ba[5]
end
end
end)
pcall(function()local _sa=workspace:FindFirstChildOfClass("Terrain")
local _Xa=_Na.terrain
if _sa and _Xa then _sa.WaterWaveSize,_sa.WaterWaveSpeed=_Xa[1],_Xa[2]
_sa.WaterReflectance,_sa.Decoration=_Xa[3],_Xa[4]
end
end)
task.spawn(function()local _ta=0
for _ha,_La in pairs(_nj)do pcall(function()_ha.Material,_ha.Reflectance,_ha.CastShadow=_La[1],_La[2],_La[3]
if _La[4]then _ha.RenderFidelity=_La[4]
end
if _La[5]then _ha.TextureID=_La[5]
end
end)
_nj[_ha]=nil
_ta=_ta+1
if _ta%300==0 then task.wait()
end
end
for _ra,_oa in pairs(_Mj)do pcall(function()_ra.Transparency=_oa
end)
_Mj[_ra]=nil
end
for _Oa in pairs(_Gj)do pcall(function()_Oa.Enabled=true
end)
_Gj[_Oa]=nil
end
for _ya,_Ka in pairs(_gj)do pcall(function()_ya.Visible=_Ka
end)
_gj[_ya]=nil
end
for _Za,_Ca in pairs(_Bj)do pcall(function()_Za.Density=_Ca
end)
_Bj[_Za]=nil
end
for _na,_Ma in pairs(_lj)do pcall(function()if _Ma and _Ma.Parent then _na.Parent=_Ma
end
end)
_lj[_na]=nil
end
end)
end
end
_dU.Misc:CreateToggle({Flag="PerformanceModeToggle",Name="Chế độ hiệu năng",Description="Fast Mode: quality level 8, FPS cap 120, flat materials, no shadows/effects/lights/textures",CurrentValue=_DV.PerformanceMode,Callback=function(_Ga)_DV.PerformanceMode=_Ga
_iV()
_Ta(_Ga)
end})
end
_dU.Misc:CreateToggle({Flag="EnableNotificationsToggle",Name="Bật thông báo",Description="Show or hide the pop-up notifications",CurrentValue=_DV.NotificationsEnabled,Callback=function(_Ba)_DV.NotificationsEnabled=_Ba
_hz.NotificationsEnabled=_Ba
_iV()
if _Ba then pcall(function()_hz:Notify({Title="Thông báo",Content="Đã bật thông báo",Type="success",Duration=2,})
end)
end
end})
_dU.Main:CreateSection("Câu cá")
_dU.Main:CreateToggle({Flag="AutoReelToggle",Name="Khóa thanh bắt cá",CurrentValue=_DV.AutoReel,Callback=function(_ga)_DV.AutoReel=_ga
_iV()
end})
_dU.Main:CreateToggle({Flag="AutoCastToggle",Name="Tự động thả câu",CurrentValue=_DV.AutoCast,Callback=function(_la)_DV.AutoCast=_la
_iV()
end})
_dU.Main:CreateToggle({Flag="FilterBossFishToggle",Name="Tự động câu cá Boss",CurrentValue=_DV.FilterBossFish,Callback=function(_Ua)_DV.FilterBossFish=_Ua
_iV()
end})
_dU.Main:CreateToggle({Flag="AutoFarmSecretBossToggle",Name="Tự động câu cá Secret Boss",CurrentValue=_DV.AutoFarmSecretBoss,Callback=function(_Ha)_DV.AutoFarmSecretBoss=_Ha
if _Ha then _DV.AutoCast=false
end
_iV()
end})
_dU.Main:CreateDropdown({Flag="AutoSecretBossModeDropdown",Name="Kích hoạt Secret Boss",Options={"Always Active","Only When Weather"},CurrentOption=_DV.AutoSecretBossMode=="Only When Weather"and"Only When Weather"or"Always Active",MultipleOptions=false,AllowNone=false,Callback=function(_aa)_DV.AutoSecretBossMode=_aa=="Only When Weather"and _aa or"Always Active"
_iV()
end})
_dU.Main:CreateDropdown({Flag="AutoCastMethodDropdown",Name="Cách thả câu",Options={"Instant","Delay"},CurrentOption=_DV.AutoCastMethod or"Instant",MultipleOptions=false,AllowNone=false,Callback=function(_Va)_DV.AutoCastMethod=_Va or"Instant"
_iV()
end})
_dU.Main:CreateSlider({Flag="CastDelaySlider",Name="Độ trễ thả câu",CurrentValue=_DV.CastDelay or 1,Range={1,10},Increment=0.1,Callback=function(_Wi)_DV.CastDelay=_Wi
_iV()
end})
_dU.Main:CreateToggle({Flag="AutoEquipBestBaitToggle",Name="Tự trang bị mồi tốt nhất",CurrentValue=_DV.AutoEquipBestBait,Callback=function(_Fi)_DV.AutoEquipBestBait=_Fi
if _Fi then task.spawn(function()_Ee(true)
end)
end
_iV()
end})
do local _mi=0
local function _ji()_mi=os.clock()
pcall(function()_Hz:InvokeServer("1")
end)
end
task.spawn(function()while task.wait(0.5)do if _DV.AutoEquipRod and not _n6.Busy and not _n6.NeedRod then local _ki=_Gz.Character
if _ki and _ki:FindFirstChild("HumanoidRootPart")and _ki:GetAttribute("Type")~="Fishing Rod"and os.clock()-_mi>1.5 then _ji()
end
end
end
end)
_dU.Main:CreateToggle({Flag="AutoEquipRodToggle",Name="Tự trang bị cần câu",CurrentValue=_DV.AutoEquipRod,Callback=function(_Ji)_DV.AutoEquipRod=_Ji
_iV()
if _Ji then task.spawn(function()local _Di=_Gz.Character
if _Di and _Di:GetAttribute("Type")~="Fishing Rod"then _ji()
end
end)
end
end})
end
_dU.Main:CreateSection("Cá yêu thích")
do local _Si=_n6.FishNames()
table.insert(_Si,1,"No Selection")
_n6.CreateFishSearchDropdown({Tab=_dU.Main,Flag="FavoriteFishDropdown",Name="Chọn cá",Options=_Si,Pinned={"No Selection"},Multi=false,Current=(type(_DV.FavoriteFish)=="string"and _DV.FavoriteFish~="")and _DV.FavoriteFish or"No Selection",GetSelected=function()local _Ii=(type(_DV.FavoriteFish)=="string"and _DV.FavoriteFish~="")and _DV.FavoriteFish or"No Selection"
return{_Ii}
end,SetSelected=function(_ii)local _Pi=_ii[1]
_DV.FavoriteFish=(_Pi==nil or _Pi=="No Selection")and""or _Pi
_iV()
end,})
end
_dU.Main:CreateToggle({Flag="AutoFavoriteFishToggle",Name="Tự động yêu thích cá đã chọn",CurrentValue=_DV.AutoFavoriteFish,Callback=function(_qi)_DV.AutoFavoriteFish=_qi
_iV()
end})
_dU.Main:CreateSection("Tự động bỏ qua cá")
_n6.CreateFishSearchDropdown({Tab=_dU.Main,Flag="SkipFishListDropdown",Name="Cá cần bỏ qua",Options=_n6.FishNames(),Multi=true,Current=table.clone(type(_DV.SkipFishList)=="table"and _DV.SkipFishList or{}),GetSelected=function()return type(_DV.SkipFishList)=="table"and _DV.SkipFishList or{}
end,SetSelected=function(_Ti)_DV.SkipFishList=_Ti
_iV()
end,})
_dU.Main:CreateToggle({Flag="AutoSkipFishToggle",Name="Tự động bỏ qua cá đã chọn",CurrentValue=_DV.AutoSkipFish,Callback=function(_Ai)_DV.AutoSkipFish=_Ai
_iV()
end})
_dU.Main:CreateSection("Kỹ năng")
_dU.Main:CreateToggle({Flag="AutoSkillToggle",Name="Tự động dùng kỹ năng",CurrentValue=_DV.AutoSkill,Callback=function(_fi)_DV.AutoSkill=_fi
if _fi and _Gz.Character then _P6(_Gz.Character)
end
_iV()
end})
do local _Ri={"Z","X","C","V"}
local _xi
local function _wi()local _zi=table.clone(_DV.SkillOrder)
for _Qi,_di in ipairs(_Ri)do if not table.find(_zi,_di)then table.insert(_zi,_di)
end
end
return _zi
end
_xi=_dU.Main:CreateDropdown({Flag="SelectSkillDropdown",Name="Chọn kỹ năng",Options=_wi(),CurrentOption=table.clone(_DV.SkillOrder),MultipleOptions=true,Callback=function(_ei)if type(_ei)~="table"then return
end
local _vi={}
for _Yi,_Ei in ipairs(_ei)do _vi[_Ei]=true
end
for _ui=#_DV.SkillOrder,1,-1 do if not _vi[_DV.SkillOrder[_ui]]then table.remove(_DV.SkillOrder,_ui)
end
end
for _pi,_ci in ipairs(_Ri)do if _vi[_ci]and not table.find(_DV.SkillOrder,_ci)then table.insert(_DV.SkillOrder,_ci)
end
end
if _xi then _xi:Refresh(_wi(),true,true)
end
_iV()
end})
end
_dU.Main:CreateSection("Boss")
do local _Ni={"Normal","Hard","Nightmare"}
if not table.find(_Ni,_DV.BossMode)then _DV.BossMode="Normal"
end
_dU.Main:CreateDropdown({Flag="SelectBossModeDropdown",Name="Chọn chế độ Boss",Options=_Ni,CurrentOption=_DV.BossMode,MultipleOptions=false,AllowNone=false,Callback=function(_bi)_DV.BossMode=_bi or"Normal"
_iV()
end})
end
_dU.Main:CreateToggle({Flag="AutoBossToggle",Name="Tự động Enzo",CurrentValue=_DV.AutoBoss,Callback=function(_si)_DV.AutoBoss=_si
_iV()
if _si then task.spawn(function()_cK(false)
end)
end
end})
_dU.Main:CreateToggle({Flag="AutoSecretBossToggle",Name="Tự động Long DiaoHai",CurrentValue=_DV.AutoSecretBoss,Callback=function(_Xi)_DV.AutoSecretBoss=_Xi
_iV()
if _Xi then task.spawn(function()_cK(true)
end)
end
end})
_dU.Main:CreateToggle({Flag="AutoMiniGameToggle",Name="Tự động chơi mini game",CurrentValue=_DV.AutoMiniGame,Callback=function(_ti)_DV.AutoMiniGame=_ti
if _ti and _Gz.Character then _P6(_Gz.Character)
end
_iV()
end})
_dU.Main:CreateSlider({Flag="BlackTortoiseBandSlider",Name="Black Tortoise Bloodline - vùng an toàn",CurrentValue=tonumber(_DV.BlackTortoiseBand)or 0.12,Range={0.03,0.17},Increment=0.01,Callback=function(_hi)_DV.BlackTortoiseBand=math.clamp(tonumber(_hi)or 0.12,0.03,0.17)
_iV()
end})
_dU.Main:CreateSection("Vị trí")
_dU.Main:CreateButton({Name="Lưu vị trí",Callback=function()local _Li=_Gz.Character
local _ri=(_Li and _Li:FindFirstChild("HumanoidRootPart"))or _FY
if _ri then _DV.SavedPos={_ri.CFrame:GetComponents()}
_iV()
pcall(function()_hz:Notify({Title="Vị trí",Content="Đã lưu vị trí!",Duration=3})
end)
end
end})
_dU.Main:CreateToggle({Flag="AutoTPPosToggle",Name="Tự dịch chuyển đến vị trí",CurrentValue=_DV.AutoTPPos,Callback=function(_oi)_DV.AutoTPPos=_oi
_iV()
if _oi then _Y6(_Gz.Character)
end
end})
_dU.Main:CreateButton({Name="Xóa vị trí",Callback=function()_DV.SavedPos=false
_iV()
pcall(function()_hz:Notify({Title="Vị trí",Content="Đã xóa vị trí!",Duration=3})
end)
end})
_dU.Misc:CreateSection("Mã quà tặng")
_dU.Misc:CreateButton({Name="Nhập tất cả mã",Callback=function()_X0()
end})
_dU.Misc:CreateSection("Menu tiện ích")
_dU.Misc:CreateButton({Name="Mở nâng cấp kỹ năng",Callback=function()local _Oi=_G0("SkillUpgrade")
_hz:Notify({Title="Giao diện tiện ích",Content=_Oi and"Opened Skill Upgrade"or"Closed Skill Upgrade",Duration=2})
end})
_dU.Misc:CreateButton({Name="Mở học kỹ năng",Callback=function()local _yi=_G0("LearnSkill")
_hz:Notify({Title="Giao diện tiện ích",Content=_yi and"Opened Learn Skill"or"Closed Learn Skill",Duration=2})
end})
_dU.Misc:CreateButton({Name="Mở giao diện trao đổi",Callback=function()local _Ki=_G0("Exchange")
_hz:Notify({Title="Giao diện tiện ích",Content=_Ki and"Opened Item Exchange"or"Closed Item Exchange",Duration=2})
end})
_dU.Misc:CreateButton({Name="Mở đặc tính",Callback=function()local _Zi=_G0("Trait")
_hz:Notify({Title="Giao diện tiện ích",Content=_Zi and"Opened Trait"or"Closed Trait",Duration=2})
end})
_dU.Settings:CreateKeybind({Flag="ToggleUIKeybind",Name="Phím thu nhỏ giao diện",CurrentKeybind="LeftControl",OnChanged=function(_Ci)local _ni=typeof(_Ci)=="EnumItem"and _Ci or Enum.KeyCode[tostring(_Ci)]or Enum.KeyCode.LeftControl
_QU:SetKeybind(_ni)
end})
do local function _Mi()task.spawn(function()local _Gi=game.PlaceId
local _Bi=game.JobId
local _gi=(syn and syn.request)or(http and http.request)or http_request or(fluxus and fluxus.request)or request
local _li=nil
pcall(function()_hz:Notify({Title="Đổi máy chủ",Content="Đang tìm máy chủ ít người...",Duration=4})
end)
local _Ui=""
local _Hi=0
while _Hi<5 and not _li do _Hi=_Hi+1
local _ai="https://games.roblox.com/v1/games/"..tostring(_Gi).."/servers/Public?sortOrder=Asc&limit=100"
if _Ui~=""then _ai=_ai.."&cursor=".._Ui
end
local _Vi=nil
if _gi then local _Ww=_gi({Url=_ai,Method="GET"})
if _Ww and _Ww.Body then _Vi=_Ww.Body
end
else local _Fw,_mw=pcall(game.HttpGet,game,_ai)
if _Fw then _Vi=_mw
end
end
if _Vi then local _jw=nil
pcall(function()_jw=_Kz:JSONDecode(_Vi)
end)
if _jw and _jw.data then local _kw={}
for _Jw,_Dw in ipairs(_jw.data)do if type(_Dw)=="table"and _Dw.id and _Dw.id~=_Bi then local _Sw=tonumber(_Dw.playing)or 0
local _Iw=tonumber(_Dw.maxPlayers)or 1
if _Sw<_Iw and _Sw>0 then table.insert(_kw,_Dw)
end
end
end
table.sort(_kw,function(_iw,_Pw)return(tonumber(_iw.playing)or 0)<(tonumber(_Pw.playing)or 0)
end)
if#_kw>0 then _li=_kw[1]
break
end
if _jw.nextPageCursor and _jw.nextPageCursor~=""then _Ui=_jw.nextPageCursor
else break
end
else break
end
else break
end
task.wait(0.5)
end
if _li and _li.id then pcall(function()_hz:Notify({Title="Đổi máy chủ",Content="Đã tìm thấy máy chủ có "..tostring(_li.playing).." người chơi! Đang dịch chuyển...",Duration=4})
end)
task.wait(0.5)
_Zz:TeleportToPlaceInstance(_Gi,_li.id,_Gz)
else pcall(function()_hz:Notify({Title="Đổi máy chủ",Content="Không tìm thấy máy chủ ít người. Đang chuyển đến máy chủ ngẫu nhiên...",Duration=4})
end)
task.wait(0.5)
_Zz:Teleport(_Gi,_Gz)
end
end)
end
_dU.Misc:CreateSection("Máy chủ")
_dU.Misc:CreateButton({Name="Vào lại máy chủ",Callback=function()pcall(function()_hz:Notify({Title="Rejoin",Content="Đang vào lại máy chủ hiện tại...",Duration=3})
end)
task.wait(0.3)
_Zz:TeleportToPlaceInstance(game.PlaceId,game.JobId,_Gz)
end})
_dU.Misc:CreateButton({Name="Đổi máy chủ ít người",Callback=function()_Mi()
end})
end
do local _qw=game:GetService("CoreGui")
local _Tw=game:GetService("MarketplaceService")
local _Aw=os.time()
local _fw=0
local _Rw=""
local _xw=os.clock()
local _ww=0
local _zw=tostring(game.PlaceId)
task.spawn(function()pcall(function()_zw=_Tw:GetProductInfo(game.PlaceId).Name
end)
end)
local _Qw=14083839
local _dw=8574880
local _ew=15773804
local function _vw(_Yw)_Yw=tostring(_Yw or"")
for _Ew,_uw in ipairs({"discord.com","discordapp.com","ptb.discord.com","canary.discord.com"})do local _pw="https://".._uw.."/api/webhooks/"
if _Yw:sub(1,#_pw)==_pw and _Yw:match("^%d+/[%w%-_]+",#_pw+1)then return true
end
end
return false
end
local function _cw()local _Nw=os.time()-_Aw
return string.format("%dh %dm",_Nw//3600,(_Nw%3600)//60)
end
local _bw={}
local function _sw(_Xw,_tw)local _hw,_Lw
for _rw,_ow in ipairs({_Uz,_Gz:FindFirstChild("leaderstats")})do if _ow then for _Ow,_yw in ipairs(_ow:GetDescendants())do if _yw:IsA("ValueBase")then local _Kw=string.lower((string.gsub(_yw.Name,"[%s_%-]","")))
local _Zw
for _Cw,_nw in ipairs(_Xw)do if _Kw==_nw then _Zw=_Cw
break
end
end
if not _Zw then for _Mw,_Gw in ipairs(_Xw)do if string.find(_Kw,_Gw,1,true)and not(_tw and string.find(_Kw,_tw,1,true))then _Zw=100+_Mw
break
end
end
end
if _Zw then local _Bw,_gw=0,_yw.Parent
while _gw and _gw~=_ow do _Bw=_Bw+1
_gw=_gw.Parent
end
local _lw=_Zw*100+_Bw
if not _Lw or _lw<_Lw then _hw,_Lw=_yw,_lw
end
end
end
end
end
end
return _hw
end
local function _Uw(_Hw,_aw,_Vw)local _Wd=_bw[_Hw]
if not(_Wd and _Wd.Parent)then _Wd=_sw(_aw,_Vw)
_bw[_Hw]=_Wd
end
local _Fd=_Wd and tonumber(_Wd.Value)
if not _Fd then return"-"
end
local _md,_jd=string.format("%d",math.floor(_Fd+0.5)),nil
repeat _md,_jd=_md:gsub("^(-?%d+)(%d%d%d)","%1,%2")
until _jd==0
return _md
end
local function _kd(_Jd,_Dd,_Sd,_Id,_id)if not(_DV.WebhookEnabled or _id)then return false,"disabled"
end
local _Pd=_DV.WebhookUrl
if not _vw(_Pd)then return false,"invalid"
end
local _qd=request or http_request or(syn and syn.request)or(fluxus and fluxus.request)
if not _qd then return false,"no request function"
end
local _Td=1.2-(os.clock()-_ww)
if _Td>0 then task.wait(_Td)
end
_ww=os.clock()
local _Ad={{name="Player",value=_Gz.DisplayName.." (@".._Gz.Name..")",inline=true},{name="Uptime",value=_cw(),inline=true},}
if _hz.Tier then table.insert(_Ad,2,{name="Tier",value=tostring(_hz.Tier),inline=true})
end
pcall(function()_Ad[#_Ad+1]={name="Money",value=_Uw("cash",{"cash","money","balance","coins","gold"}),inline=true}
_Ad[#_Ad+1]={name="Tickets",value=_Uw("ticket",{"tickets","ticket"},"quest"),inline=true}
_Ad[#_Ad+1]={name="Gems",value=_Uw("gem",{"gems","gem","crystals","crystal"}),inline=true}
end)
for _fd,_Rd in ipairs(_Id or{})do _Ad[#_Ad+1]=_Rd
end
local _xd,_wd=pcall(function()return _qd({Url=_Pd,Method="POST",Headers={["Content-Type"]="application/json"},Body=_Kz:JSONEncode({username="UZEX Hub",embeds={{title=_Jd,description=_Dd,color=_Sd or _Qw,fields=_Ad,footer={text="UZEX Hub"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ"),},},}),})
end)
local _zd=_xd and type(_wd)=="table"and(_wd.StatusCode or _wd.status_code)or nil
return _xd and(_zd==nil or(_zd>=200 and _zd<300)),_zd
end
pcall(function()local _Qd=_Bz:FindFirstChild("ReplicateFishCaught")
if _Qd and _Qd:IsA("RemoteEvent")then _Qd.OnClientEvent:Connect(function(_dd,_ed)if _dd~=_Gz.Character then return
end
_fw=_fw+1
_hz.Session=_hz.Session or{}
_hz.Session.fish=_fw
_Rw=tostring(_ed or"")
if _DV.WebhookOnCatch then task.spawn(_kd,"Fish caught",_Rw~=""and _Rw or"A fish",_dw,{{name="Total this session",value=tostring(_fw),inline=true}})
end
end)
end
end)
task.spawn(function()task.wait(4)
_kd("UZEX Hub","The script is running.",_Qw,{})
end)
task.spawn(function()while true do task.wait(30)
local _vd=tonumber(_DV.WebhookInterval)or 0
if _DV.WebhookEnabled and _vd>=1 and os.clock()-_xw>=_vd*60 then _xw=os.clock()
_kd(_zw,"",_Qw,{{name="Fish caught",value=tostring(_fw),inline=true},})
end
end
end)
local _Yd=_SV.."/rejoin.log"
local _Ed=_SV.."/rejoin.flag"
local _ud=4
local _pd=false
local function _cd()local _Nd={}
pcall(function()if isfile and isfile(_Yd)then for _bd in readfile(_Yd):gmatch("%d+")do local _sd=tonumber(_bd)
if _sd and os.time()-_sd<600 then _Nd[#_Nd+1]=_sd
end
end
end
end)
return _Nd
end
local function _Xd(_td)_td[#_td+1]=os.time()
pcall(function()if not isfolder(_SV)then makefolder(_SV)
end
writefile(_Yd,table.concat(_td,","))
end)
end
local function _hd(_Ld)if _pd or not _DV.AutoRejoin then return
end
local _rd=_cd()
if#_rd>=_ud then pcall(function()_hz:Notify({Title="Tạm dừng tự vào lại",Content="Đã vào lại quá nhiều lần trong 10 phút. Vui lòng vào lại thủ công.",Type="error",Duration=8,})
end)
return
end
_pd=true
_Xd(_rd)
task.spawn(function()_Ld=tostring(_Ld or"")
if _Ld==""then _Ld="Disconnected from the server."
end
pcall(function()_hz:Notify({Title="Mất kết nối",Content="Đang tự động kết nối lại...",Type="warning",Duration=6,})
end)
local _od=false
task.spawn(function()_kd("Mất kết nối",_Ld,_ew,{{name="Action",value="Rejoining",inline=true},})
_od=true
end)
local _Od=0
while not _od and _Od<4 do task.wait(0.25)
_Od=_Od+0.25
end
pcall(function()if not isfolder(_SV)then makefolder(_SV)
end
writefile(_Ed,tostring(os.time()))
end)
_YV(true)
task.wait(2)
for _yd=1,4 do pcall(function()if _yd==1 then _Zz:TeleportToPlaceInstance(game.PlaceId,game.JobId,_Gz)
else _Zz:Teleport(game.PlaceId,_Gz)
end
end)
task.wait(10)
end
_pd=false
end)
end
task.spawn(function()pcall(function()local _Kd=_qw:WaitForChild("RobloxPromptGui",60)
local _Zd=_Kd and _Kd:WaitForChild("promptOverlay",60)
if not _Zd then return
end
_Zd.ChildAdded:Connect(function(_Cd)if _Cd.Name~="ErrorPrompt"then return
end
local _nd=""
pcall(function()_nd=_Cd.MessageArea.ErrorFrame.ErrorMessage.Text
end)
_hd(_nd)
end)
end)
end)
local _Md=200
local _Gd=_n6.AntiChecked
local _Bd=false
local function _gd(_ld)if _ld==_Gz then return false
end
local _Ud=false
pcall(function()for _Hd,_ad in ipairs({"Staff","IsStaff","Admin","IsAdmin","Moderator","IsModerator"})do if _ld:GetAttribute(_ad)==true then _Ud=true
end
end
end)
if _Ud then return true
end
pcall(function()if game.CreatorType==Enum.CreatorType.Group and _ld:GetRankInGroup(game.CreatorId)>=_Md then _Ud=true
end
end)
return _Ud
end
local function _Vd(_W4)if _Bd or not _DV.AntiStaff then return
end
_Bd=true
pcall(function()_hz:Notify({Title="Anti Staff",Content="Phát hiện quản trị viên: ".._W4.Name.." - đang rời máy chủ",Type="warning",Duration=6,})
end)
local _F4=false
task.spawn(function()_kd("Staff detected",_W4.Name.." is in the server.",_ew,{{name="Action",value="Leaving server",inline=true},})
_F4=true
end)
local _m4=0
while not _F4 and _m4<3 do task.wait(0.25)
_m4=_m4+0.25
end
_pd=true
_YV(true)
pcall(function()_Zz:Teleport(game.PlaceId,_Gz)
end)
task.wait(8)
pcall(function()_Gz:Kick("Anti Staff: ".._W4.Name)
end)
_Bd=false
end
local function _j4(_k4)if _Gd[_k4]then return
end
_Gd[_k4]=true
task.spawn(function()if _DV.AntiStaff and _gd(_k4)then _Vd(_k4)
end
end)
end
game:GetService("Players").PlayerAdded:Connect(_j4)
task.spawn(function()while task.wait(5)do if _DV.AntiStaff then for _J4,_D4 in ipairs(game:GetService("Players"):GetPlayers())do _j4(_D4)
end
end
end
end)
_dU.Settings:CreateSection("Tự vào lại")
_dU.Settings:CreateToggle({Flag="AutoRejoinToggle",Name="Tự vào lại khi mất kết nối",Description="Rejoins and restarts the hub after a disconnect or kick",CurrentValue=_DV.AutoRejoin,Callback=function(_S4)_DV.AutoRejoin=_S4
_iV()
end})
_dU.Settings:CreateSection("Thông báo Discord Webhook")
_dU.Settings:CreateToggle({Flag="WebhookEnabledToggle",Name="Thông báo qua Webhook",CurrentValue=_DV.WebhookEnabled,Callback=function(_I4)_DV.WebhookEnabled=_I4
_iV()
end})
_dU.Settings:CreateInput({Flag="WebhookUrlInput",Name="Đường dẫn Webhook",CurrentValue=_DV.WebhookUrl,PlaceholderText="https://discord.com/api/webhooks/...",Callback=function(_i4)local _P4=(tostring(_i4 or""):gsub("%s+",""))
if _P4==""then _DV.WebhookUrl=""
_iV()
elseif _vw(_P4)then _DV.WebhookUrl=_P4
_iV()
_hz:Notify({Title="Webhook",Content="Đã lưu URL Webhook.",Type="success",Duration=3})
else _hz:Notify({Title="Webhook",Content="Đây không phải liên kết Discord Webhook.",Type="error",Duration=4})
end
end})
_dU.Settings:CreateInput({Flag="WebhookIntervalInput",Name="Báo cáo trạng thái (phút, 0 = tắt)",CurrentValue=tostring(_DV.WebhookInterval or 0),PlaceholderText="0",Numeric=true,Callback=function(_q4)_DV.WebhookInterval=math.max(0,math.floor(tonumber(_q4)or 0))
_iV()
end})
_dU.Settings:CreateToggle({Flag="WebhookOnCatchToggle",Name="Thông báo mỗi lần câu được cá",Description="Sends a message for each fish caught",CurrentValue=_DV.WebhookOnCatch,Callback=function(_T4)_DV.WebhookOnCatch=_T4
_iV()
end})
_dU.Settings:CreateButton({Name="Gửi thử Webhook",Callback=function()task.spawn(function()local _A4,_f4=_kd("Test message","Your webhook is working.",_dw,nil,true)
_hz:Notify({Title="Webhook",Content=_A4 and"Test message sent."or(_f4=="invalid"and"Set a valid webhook URL first."or"Could not send the message."),Type=_A4 and"success"or"error",Duration=4,})
end)
end})
end
do local _R4=game:GetService("CoreGui")
local _x4=_Gz.Name
local _w4=_Gz.DisplayName
local _z4=tostring(_Gz.UserId)
local function _Q4(_d4)return(tostring(_d4 or""):gsub("%D",""))
end
if _Q4(_DV.FakeId)==""then local _e4={"1"}
for _v4=1,10 do _e4[#_e4+1]=tostring(math.random(0,9))
end
_DV.FakeId=table.concat(_e4)
_iV()
end
local function _Y4()local _E4=tostring(_DV.FakeName or"")
return _E4~=""and _E4 or"Player"
end
local function _u4()local _p4=_Q4(_DV.FakeId)
return _p4~=""and _p4 or"10000000001"
end
local function _c4(_N4,_b4,_s4)local _X4,_t4={},1
while true do local _h4,_L4=string.find(_N4,_b4,_t4,true)
if not _h4 then break
end
_X4[#_X4+1]=string.sub(_N4,_t4,_h4-1)
_X4[#_X4+1]=_s4
_t4=_L4+1
end
_X4[#_X4+1]=string.sub(_N4,_t4)
return table.concat(_X4)
end
local _r4={_x4,_w4}
if#_w4>#_x4 then _r4={_w4,_x4}
end
local function _o4(_O4)local _y4=_O4
if _DV.FakeNameEnabled then local _K4=_Y4()
for _Z4,_C4 in ipairs(_r4)do if _C4~=""and _C4~=_K4 and not string.find(_K4,_C4,1,true)then _y4=_c4(_y4,_C4,_K4)
end
end
end
if _DV.FakeIdEnabled then local _n4=_u4()
if _z4~=_n4 and not string.find(_n4,_z4,1,true)then _y4=_c4(_y4,_z4,_n4)
end
end
return _y4
end
local _M4=setmetatable({},{__mode="k"})
local _G4=setmetatable({},{__mode="k"})
local _B4=setmetatable({},{__mode="k"})
local _g4=setmetatable({},{__mode="k"})
local function _l4(_U4)local _H4=_M4[_U4]
local _a4=_U4.Text
if _H4 and _a4==_H4.shown then _a4=_H4.original
end
local _V4=string.find(_a4,_z4,1,true)~=nil
if _DV.HideId and _V4 then if _G4[_U4]==nil then _G4[_U4]=_U4.Visible
end
if _U4.Visible then _U4.Visible=false
end
elseif _G4[_U4]~=nil then _U4.Visible=_G4[_U4]
_G4[_U4]=nil
end
local _Wh=_a4
if _DV.FakeNameEnabled or _DV.FakeIdEnabled then _Wh=_o4(_a4)
end
if _Wh~=_a4 then if _H4 and _H4.original==_a4 then _H4.shown=_Wh
else _M4[_U4]={original=_a4,shown=_Wh}
end
if _U4.Text~=_Wh then _U4.Text=_Wh
end
else if _H4 and _U4.Text==_H4.shown then _U4.Text=_H4.original
end
_M4[_U4]=nil
end
end
local function _Fh(_mh)return _mh:FindFirstAncestor("UZEXHubUI")~=nil or _mh:FindFirstAncestor("UzexKeyPrompt")~=nil
end
local function _jh(_kh)if _B4[_kh]or not(_kh:IsA("TextLabel")or _kh:IsA("TextButton"))or _Fh(_kh)then return
end
_B4[_kh]=true
_l4(_kh)
_kh:GetPropertyChangedSignal("Text"):Connect(function()_l4(_kh)
end)
_kh:GetPropertyChangedSignal("Visible"):Connect(function()if _G4[_kh]~=nil and _kh.Visible then _l4(_kh)
end
end)
end
local function _Jh(_Dh)if not _Dh or _g4[_Dh]then return
end
_g4[_Dh]=true
for _Sh,_Ih in ipairs(_Dh:GetDescendants())do _jh(_Ih)
end
_Dh.DescendantAdded:Connect(_jh)
end
local function _ih(_Ph)local _qh=_Ph and _Ph:FindFirstChildOfClass("Humanoid")
if _qh then pcall(function()_qh.DisplayName=_DV.FakeNameEnabled and _Y4()or _w4
end)
end
end
local function _Th()for _Ah in pairs(_B4)do if _Ah.Parent then _l4(_Ah)
end
end
_ih(_Gz.Character)
end
pcall(function()_Jh(_Gz:WaitForChild("PlayerGui"))
end)
task.spawn(function()pcall(function()_Jh(_R4:WaitForChild("PlayerList",60))
end)
end)
task.spawn(function()pcall(function()_Jh(_R4:WaitForChild("ExperienceChat",60))
end)
end)
local function _fh(_Rh)_Jh(_Rh)
task.wait(0.5)
_ih(_Rh)
end
_Gz.CharacterAdded:Connect(function(_xh)task.spawn(_fh,_xh)
end)
if _Gz.Character then task.spawn(_fh,_Gz.Character)
end
_dU.Settings:CreateSection("Quyền riêng tư")
_dU.Settings:CreateToggle({Flag="HideIdToggle",Name="Ẩn ID của tôi (góc trên phải)",Description="Hides the number that shows your user ID",CurrentValue=_DV.HideId,Callback=function(_wh)_DV.HideId=_wh
_iV()
_Th()
end})
_dU.Settings:CreateToggle({Flag="FakeIdToggle",Name="ID giả",Description="Shows another number instead of your ID (turn Hide off to see it)",CurrentValue=_DV.FakeIdEnabled,Callback=function(_zh)_DV.FakeIdEnabled=_zh
_iV()
_Th()
end})
_dU.Settings:CreateInput({Flag="FakeIdInput",Name="Số ID giả",CurrentValue=_u4(),PlaceholderText="12345678901",Numeric=true,Callback=function(_Qh)local _dh=string.sub(_Q4(_Qh),1,16)
if _dh~=""then _DV.FakeId=_dh
_iV()
_Th()
end
end})
_dU.Settings:CreateToggle({Flag="HideNameToggle",Name="Ẩn tên",Description="Hides your name tag above your character",CurrentValue=_DV.HideName,Callback=function(_eh)_DV.HideName=_eh
_iV()
pcall(_n6.ApplyHideName)
end})
_dU.Settings:CreateToggle({Flag="FakeNameToggle",Name="Tên giả",Description="Shows another name for you on your own screen",CurrentValue=_DV.FakeNameEnabled,Callback=function(_vh)_DV.FakeNameEnabled=_vh
_iV()
_Th()
end})
_dU.Settings:CreateInput({Flag="FakeNameInput",Name="Nội dung tên giả",CurrentValue=_DV.FakeName,PlaceholderText="Player",Callback=function(_Yh)local _Eh=(tostring(_Yh or""):gsub("^%s+",""):gsub("%s+$",""))
_DV.FakeName=string.sub(_Eh,1,20)
_iV()
_Th()
end})
end
do local _uh=os.time()
local _ph={}
local _ch=-1e9
local function _Nh(_bh)return(string.lower(tostring(_bh)):gsub("[%s_%-]",""))
end
local function _sh()_ch=os.clock()
local _Xh={}
if _Uz then for _th,_hh in ipairs(_Uz:GetDescendants())do if _hh:IsA("ValueBase")then local _Lh,_rh=0,_hh.Parent
while _rh and _rh~=_Uz do _Lh=_Lh+1
_rh=_rh.Parent
end
_Xh[#_Xh+1]={inst=_hh,depth=_Lh,name=_Nh(_hh.Name)}
end
end
end
table.sort(_Xh,function(_oh,_Oh)return _oh.depth<_Oh.depth
end)
_ph=_Xh
end
local function _yh(_Kh,_Zh)for _Ch,_nh in ipairs(_Kh)do for _Mh,_Gh in ipairs(_ph)do if _Gh.name==_nh and _Gh.inst.Parent then return _Gh.inst
end
end
end
for _Bh,_gh in ipairs(_Kh)do for _lh,_Uh in ipairs(_ph)do if _Uh.inst.Parent and string.find(_Uh.name,_gh,1,true)and not(_Zh and string.find(_Uh.name,_Zh,1,true))then return _Uh.inst
end
end
end
return nil
end
local function _Hh(_ah)_ah=tonumber(_ah)
if not _ah then return nil
end
if _ah~=math.floor(_ah)then return string.format("%.1f",_ah)
end
local _Vh,_WR=string.format("%d",_ah),nil
repeat _Vh,_WR=_Vh:gsub("^(-?%d+)(%d%d%d)","%1,%2")
until _WR==0
return _Vh
end
local function _FR(_mR)return string.format("%02d:%02d:%02d",_mR//3600,(_mR%3600)//60,_mR%60)
end
local _jR={{key="Level",keys={"level"}},{key="Balance",keys={"cash","money","balance","coins","gold"}},{key="Crystal",keys={"crystals","crystal"}},{key="Essence",keys={"essence"}},{key="Ticket",keys={"tickets","ticket"},exclude="quest"},{key="TraitReroll",keys={"traitrerolls","traitreroll","reroll"}},{key="FishCaught",keys={"fishcaught","totalfishcaught","caught","fishcount"}},{key="HeaviestFish",keys={"heaviestfish","heaviest","biggestfish","maxfishweight"}},{key="BaseHP",keys={"basehp","basehealth"}},}
local function _kR()local _JR=_Uz and _Uz:FindFirstChild("Hotbar")
local _DR=_gz and _gz:FindFirstChild("Bait")
if _JR then for _SR,_IR in ipairs(_JR:GetChildren())do local _iR=_IR:FindFirstChild("ValueName")
local _PR=_iR and tostring(_iR.Value)or""
if _PR~=""and((_DR and _DR:FindFirstChild(_PR))or string.find(string.lower(_PR),"bait",1,true))then local _qR=_IR:FindFirstChild("Quantity")
local _TR=_qR and _Hh(_qR.Value)
return _TR and(_PR.." x".._TR)or _PR
end
end
end
local _AR=_Uz and(_Uz:FindFirstChild("EquippedBait")or _Uz:FindFirstChild("CurrentBait"))
if _AR and tostring(_AR.Value)~=""then return tostring(_AR.Value)
end
return"None"
end
local function _fR()local _RR=_QU.Stats
if not _RR then return
end
if os.clock()-_ch>20 then _sh()
end
_RR:Set("Session",_FR(os.time()-_uh))
for _xR,_wR in ipairs(_jR)do local _zR=_yh(_wR.keys,_wR.exclude)
local _QR="-"
if _zR then _QR=_Hh(_zR.Value)or tostring(_zR.Value)
end
_RR:Set(_wR.key,_QR)
end
local _dR=_hz.Session
if _dR and _dR.fish and not _yh(_jR[7].keys)then _RR:Set("FishCaught",_Hh(_dR.fish))
end
if not _yh(_jR[9].keys)then local _eR=_Gz.Character
local _vR=_eR and _eR:FindFirstChildOfClass("Humanoid")
if _vR then _RR:Set("BaseHP",_Hh(_vR.MaxHealth))
end
end
local _YR=_Uz and _Uz:FindFirstChild("FishingRod")
_RR:Set("Rod",(_YR and tostring(_YR.Value)~="")and tostring(_YR.Value)or"None")
_RR:Set("Bait",_kR())
end
task.spawn(function()while true do pcall(_fR)
task.wait(1)
end
end)
end
_QU:SelectTab(_dU.Main)
n)
