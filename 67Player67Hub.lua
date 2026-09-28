--[[
    MultiTool GUI v5
    Starts small — expandable & resizable
    Place in StarterGui as LocalScript
]]

-- ===== SERVICES =====
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ===== COLORS =====
local C = {
	bg = Color3.fromRGB(18, 18, 26),
	bg2 = Color3.fromRGB(28, 28, 38),
	side = Color3.fromRGB(22, 22, 32),
	accent = Color3.fromRGB(139, 92, 246),
	accent2 = Color3.fromRGB(165, 120, 255),
	text = Color3.fromRGB(235, 235, 245),
	text2 = Color3.fromRGB(150, 150, 165),
	green = Color3.fromRGB(46, 204, 113),
	red = Color3.fromRGB(231, 76, 60),
	yellow = Color3.fromRGB(241, 196, 15),
	blue = Color3.fromRGB(52, 152, 219),
}

-- ===== STATE =====
local expanded = false
local flyOn = false
local noclipOn = false
local infJumpOn = false
local dayNightOn = false
local flySpeed = 50
local flyBV = nil
local flyConn = nil
local noclipConn = nil
local jumpConn = nil
local dayNightTask = nil
local savedSize = UDim2.new(0, 600, 0, 420)

-- ===== HELPERS =====

local function notify(text, color)
	color = color or C.accent2
	local sg = player:WaitForChild("PlayerGui"):FindFirstChild("MultiTool")
	if not sg then return end
	local n = Instance.new("TextLabel")
	n.Size = UDim2.new(0, 240, 0, 30)
	n.Position = UDim2.new(0.5, -120, 0, -40)
	n.BackgroundColor3 = C.bg2
	n.Text = "  " .. text
	n.TextColor3 = color
	n.Font = Enum.Font.GothamBold
	n.TextSize = 13
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.Parent = sg
	local nc = Instance.new("UICorner")
	nc.CornerRadius = UDim.new(0, 6)
	nc.Parent = n
	local ns = Instance.new("UIStroke")
	ns.Color = color
	ns.Thickness = 1
	ns.Parent = n
	TweenService:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -120, 0, 10)}):Play()
	task.delay(2.5, function()
		TweenService:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -120, 0, -40)}):Play()
		task.wait(0.3)
		n:Destroy()
	end)
end

local function makeBtn(text, parent, height)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -10, 0, height or 30)
	b.BackgroundColor3 = C.bg2
	b.Text = text
	b.TextColor3 = C.text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.AutoButtonColor = true
	b.Parent = parent
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = b
	b.MouseEnter:Connect(function()
		b.BackgroundColor3 = C.accent
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundColor3 = C.bg2
	end)
	return b
end

local function makeSlider(text, parent, minVal, maxVal, default, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -10, 0, 46)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.7, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = C.text
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0.3, -5, 0, 18)
	valLabel.Position = UDim2.new(0.7, 0, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.Text = tostring(default)
	valLabel.TextColor3 = C.accent2
	valLabel.Font = Enum.Font.GothamBold
	valLabel.TextSize = 12
	valLabel.TextXAlignment = Enum.TextXAlignment.Right
	valLabel.Parent = container

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 12)
	bar.Position = UDim2.new(0, 0, 0, 22)
	bar.BackgroundColor3 = C.bg2
	bar.Parent = container
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(1, 0)
	bc.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BackgroundColor3 = C.accent
	fill.Parent = bar
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1, 0)
	fc.Parent = fill

	local dragging = false
	local function update(x)
		local rel = (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
		rel = math.clamp(rel, 0, 1)
		local val = minVal + (maxVal - minVal) * rel
		if maxVal - minVal >= 10 then
			val = math.floor(val + 0.5)
		elseif maxVal - minVal >= 1 then
			val = math.floor(val * 10 + 0.5) / 10
		end
		fill.Size = UDim2.new(rel, 0, 1, 0)
		valLabel.Text = tostring(val)
		callback(val)
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			update(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			update(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	return container
end

local function makeToggle(text, parent, default, callback)
	local state = default
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -10, 0, 32)
	b.BackgroundColor3 = C.bg2
	b.Text = ""
	b.Parent = parent
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = b

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = C.text
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = b

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 44, 0, 20)
	knob.Position = UDim2.new(1, -52, 0.5, -10)
	knob.BackgroundColor3 = state and C.green or Color3.fromRGB(60, 60, 70)
	knob.Parent = b
	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(1, 0)
	kc.Parent = knob

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 16, 0, 16)
	dot.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
	dot.BackgroundColor3 = Color3.new(1, 1, 1)
	dot.Parent = knob
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(1, 0)
	dc.Parent = dot

	b.MouseButton1Click:Connect(function()
		state = not state
		if state then
			knob.BackgroundColor3 = C.green
			TweenService:Create(dot, TweenInfo.new(0.15), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
		else
			knob.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			TweenService:Create(dot, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
		end
		callback(state)
	end)

	return b
end

local function makeTextBox(text, parent, default)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -10, 0, 46)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 16)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = C.text2
	label.Font = Enum.Font.Gotham
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 26)
	box.Position = UDim2.new(0, 0, 0, 18)
	box.BackgroundColor3 = C.bg2
	box.Text = default or ""
	box.TextColor3 = C.text
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.PlaceholderText = text
	box.PlaceholderColor3 = C.text2
	box.ClearTextOnFocus = false
	box.Parent = container
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = box

	return box, container
end

local function section(text, parent)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 0, 22)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = C.accent2
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function getTarget()
	return mouse.Target
end

local function getChar()
	local char = player.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	return char, hrp, hum
end

-- ===== SCREEN GUI =====
local sg = Instance.new("ScreenGui")
sg.Name = "MultiTool"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Parent = player:WaitForChild("PlayerGui")

-- Main frame (starts SMALL)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 140, 0, 36)
mainFrame.Position = UDim2.new(0, 15, 0.5, -18)
mainFrame.BackgroundColor3 = C.bg
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = sg

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 8)
mc.Parent = mainFrame

local ms = Instance.new("UIStroke")
ms.Color = C.accent
ms.Thickness = 1.5
ms.Parent = mainFrame

-- Shadow
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.Position = UDim2.new(0, -15, 0, -15)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6014261993"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.4
shadow.ZIndex = mainFrame.ZIndex - 1
shadow.Parent = mainFrame

-- ===== HEADER (always visible) =====
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundTransparency = 1
header.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.BackgroundTransparency = 1
title.Text = "  ⚡ MultiTool"
title.TextColor3 = C.text
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local expandBtn = Instance.new("TextButton")
expandBtn.Size = UDim2.new(0, 32, 0, 28)
expandBtn.Position = UDim2.new(1, -70, 0.5, -14)
expandBtn.BackgroundColor3 = C.accent
expandBtn.Text = "▢"
expandBtn.TextColor3 = Color3.new(1, 1, 1)
expandBtn.Font = Enum.Font.GothamBold
expandBtn.TextSize = 14
expandBtn.Parent = header
local ec = Instance.new("UICorner")
ec.CornerRadius = UDim.new(0, 6)
ec.Parent = expandBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
closeBtn.BackgroundColor3 = C.red
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = header
local cc2 = Instance.new("UICorner")
cc2.CornerRadius = UDim.new(0, 6)
cc2.Parent = closeBtn

-- ===== SIDEBAR (hidden when collapsed) =====
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 120, 1, -40)
sidebar.Position = UDim2.new(0, 0, 0, 38)
sidebar.BackgroundColor3 = C.side
sidebar.BorderSizePixel = 0
sidebar.Visible = false
sidebar.Parent = mainFrame

local sidebarScroll = Instance.new("ScrollingFrame")
sidebarScroll.Size = UDim2.new(1, -4, 1, -4)
sidebarScroll.Position = UDim2.new(0, 2, 0, 2)
sidebarScroll.BackgroundTransparency = 1
sidebarScroll.ScrollBarThickness = 3
sidebarScroll.ScrollBarImageColor3 = C.accent
sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
sidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebarScroll.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 4)
sidebarLayout.Parent = sidebarScroll

-- ===== CONTENT AREA (hidden when collapsed) =====
local contentArea = Instance.new("Frame")
contentArea.Name = "Content"
contentArea.Size = UDim2.new(1, -122, 1, -40)
contentArea.Position = UDim2.new(0, 122, 0, 38)
contentArea.BackgroundTransparency = 1
contentArea.Visible = false
contentArea.Parent = mainFrame

-- Separator
local sep = Instance.new("Frame")
sep.Size = UDim2.new(0, 1, 1, -40)
sep.Position = UDim2.new(0, 120, 0, 38)
sep.BackgroundColor3 = C.bg2
sep.BorderSizePixel = 0
sep.Visible = false
sep.Parent = mainFrame

-- ===== RESIZE GRIP (hidden when collapsed) =====
local resizeGrip = Instance.new("TextButton")
resizeGrip.Size = UDim2.new(0, 16, 0, 16)
resizeGrip.Position = UDim2.new(1, -16, 1, -16)
resizeGrip.BackgroundTransparency = 1
resizeGrip.Text = "⇲"
resizeGrip.TextColor3 = C.text2
resizeGrip.Font = Enum.Font.GothamBold
resizeGrip.TextSize = 14
resizeGrip.Visible = false
resizeGrip.Parent = mainFrame

-- ===== TAB SYSTEM =====
local tabs = {}

local function createTab(name, icon)
	local idx = #tabs + 1

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -6, 0, 32)
	btn.BackgroundColor3 = idx == 1 and C.accent or C.bg2
	btn.Text = "  " .. icon .. " " .. name
	btn.TextColor3 = C.text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = sidebarScroll
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = btn

	local content = Instance.new("ScrollingFrame")
	content.Size = UDim2.new(1, -10, 1, -10)
	content.Position = UDim2.new(0, 5, 0, 5)
	content.BackgroundTransparency = 1
	content.ScrollBarThickness = 4
	content.ScrollBarImageColor3 = C.accent
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.Visible = idx == 1
	content.Parent = contentArea

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = content

	tabs[idx] = {btn = btn, content = content, name = name}

	btn.MouseButton1Click:Connect(function()
		for _, t in ipairs(tabs) do
			t.btn.BackgroundColor3 = C.bg2
			t.content.Visible = false
		end
		btn.BackgroundColor3 = C.accent
		content.Visible = true
	end)

	return content
end

-- ===== DRAG LOGIC =====
local dragging = false
local dragStart = Vector3.zero
local frameStart = Vector3.zero

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = UserInputService:GetMouseLocation()
		frameStart = Vector3.new(mainFrame.AbsolutePosition.X, mainFrame.AbsolutePosition.Y, 0)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = UserInputService:GetMouseLocation() - dragStart
		local newX = frameStart.X + delta.X
		local newY = frameStart.Y + delta.Y
		newX = math.clamp(newX, 0, math.max(0, sg.AbsoluteSize.X - 60))
		newY = math.clamp(newY, 0, math.max(0, sg.AbsoluteSize.Y - 40))
		mainFrame.Position = UDim2.new(0, newX, 0, newY)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

-- ===== RESIZE LOGIC =====
local resizing = false
local resizeStart = Vector2.zero
local resizeStartSize = Vector2.zero

resizeGrip.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = true
		resizeStart = UserInputService:GetMouseLocation()
		resizeStartSize = Vector2.new(mainFrame.AbsoluteSize.X, mainFrame.AbsoluteSize.Y)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = UserInputService:GetMouseLocation() - resizeStart
		local newW = math.clamp(resizeStartSize.X + delta.X, 400, 900)
		local newH = math.clamp(resizeStartSize.Y + delta.Y, 300, 700)
		mainFrame.Size = UDim2.new(0, newW, 0, newH)
		savedSize = mainFrame.Size
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = false
	end
end)

-- ===== EXPAND / COLLAPSE =====
local function toggleExpand()
	if not expanded then
		expanded = true
		sidebar.Visible = true
		contentArea.Visible = true
		sep.Visible = true
		resizeGrip.Visible = true
		title.Text = "  ⚡ MultiTool"
		TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = savedSize}):Play()
		expandBtn.Text = "▬"
		notify("GUI развёрнут", C.green)
	else
		expanded = false
		savedSize = mainFrame.Size
		TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 140, 0, 36)}):Play()
		task.wait(0.25)
		sidebar.Visible = false
		contentArea.Visible = false
		sep.Visible = false
		resizeGrip.Visible = false
		expandBtn.Text = "▢"
		title.Text = "  ⚡ MultiTool"
	end
end

expandBtn.MouseButton1Click:Connect(toggleExpand)

closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	notify("GUI скрыт. Нажми Insert чтобы открыть", C.yellow)
end)

-- Key to reopen
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Insert then
		mainFrame.Visible = true
		if not expanded then
			toggleExpand()
		end
	end
end)

-- ===== TAB 1: OBJECTS =====
local p1 = createTab("Объекты", "📦")

section("Клонирование", p1)
local cloneN = 5
local cloneOff = 4
makeSlider("Количество", p1, 1, 50, 5, function(v) cloneN = v end)
makeSlider("Отступ", p1, 1, 20, 4, function(v) cloneOff = v end)
makeBtn("Клонировать (на курсор)", p1).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then notify("Наведи курсор на объект", C.red) return end
	for i = 1, cloneN do
		local c = t:Clone()
		c.Position = t.Position + Vector3.new(cloneOff * i, 0, 0)
		c.Parent = t.Parent
	end
	notify("Клонировано: " .. cloneN, C.green)
end)

section("Переименование", p1)
local renameBox = makeTextBox("Новое имя (# = номер)", p1, "Part_#")
makeBtn("Переименовать (на курсор)", p1).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then notify("Наведи курсор на объект", C.red) return end
	local name = renameBox.Text
	if name == "" or name == "Part_#" then name = "Part_#" end
	if name:find("#") then
		local parent = t.Parent
		local i = 1
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("BasePart") or child:IsA("Model") then
				child.Name = name:gsub("#", tostring(i))
				i = i + 1
			end
		end
	else
		t.Name = name
	end
	notify("Переименовано", C.green)
end)

section("Быстрое создание", p1)
local spawns = {
	{"Part", "Part"},
	{"Spawn", "SpawnLocation"},
	{"Folder", "Folder"},
	{"Script", "Script"},
	{"LocScr", "LocalScript"},
	{"ModScr", "ModuleScript"}
}
for i, s in ipairs(spawns) do
	local b = makeBtn(s[1], p1, 28)
	b.MouseButton1Click:Connect(function()
		local obj = Instance.new(s[2])
		obj.Parent = Workspace
		if s[2] == "Part" then
			obj.Size = Vector3.new(4, 1, 2)
			obj.Position = Vector3.new(math.random(-50, 50), 5, math.random(-50, 50))
			obj.Anchored = true
			obj.BrickColor = BrickColor.Random()
		end
		notify("Создан: " .. s[1], C.green)
	end)
end

section("Действия", p1)
makeBtn("Сгруппировать в Model (курсор)", p1).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then notify("Наведи на объект", C.red) return end
	local m = Instance.new("Model")
	m.Parent = t.Parent
	t.Parent = m
	notify("Сгруппировано", C.green)
end)
makeBtn("Разгруппировать (курсор)", p1).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t or not t:IsA("Model") then notify("Наведи на Model", C.red) return end
	local p = t.Parent
	for _, c in ipairs(t:GetChildren()) do
		c.Parent = p
	end
	t:Destroy()
	notify("Разгруппировано", C.green)
end)
makeBtn("Случайный цвет (курсор)", p1).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then notify("Наведи на объект", C.red) return end
	pcall(function() t.BrickColor = BrickColor.Random() end)
	notify("Цвет изменён", C.green)
end)
makeBtn("Удалить (курсор)", p1).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then notify("Наведи на объект", C.red) return end
	t:Destroy()
	notify("Удалено", C.red)
end)

-- ===== TAB 2: PHYSICS =====
local p2 = createTab("Физика", "⚙️")

section("Свойства (на курсор)", p2)
makeToggle("Anchored", p2, false, function(v)
	local t = getTarget()
	if t then pcall(function() t.Anchored = v end) end
end)
makeToggle("CanCollide", p2, true, function(v)
	local t = getTarget()
	if t then pcall(function() t.CanCollide = v end) end
end)
makeToggle("CanTouch", p2, true, function(v)
	local t = getTarget()
	if t then pcall(function() t.CanTouch = v end) end
end)

section("Масштаб", p2)
local scaleVal = 1
makeSlider("Множитель", p2, 0.1, 5, 1, function(v) scaleVal = v end)
makeBtn("Применить масштаб (курсор)", p2).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then notify("Наведи на объект", C.red) return end
	pcall(function() t.Size = t.Size * scaleVal end)
	notify("Масштаб: " .. scaleVal, C.green)
end)

section("Установка свойства", p2)
local propName = makeTextBox("Имя свойства", p2, "Transparency")
local propVal = makeTextBox("Значение (число)", p2, "0.5")
makeBtn("Установить (курсор)", p2).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then notify("Наведи на объект", C.red) return end
	local n = propName.Text
	local v = tonumber(propVal.Text)
	if not n or not v then notify("Проверь имя и значение", C.red) return end
	local ok = pcall(function() t[n] = v end)
	if ok then notify(n .. " = " .. v, C.green) else notify("Ошибка свойства", C.red) end
end)

section("Гравитация", p2)
makeSlider("Гравитация Workspace", p2, 0, 200, 196.2, function(v)
	Workspace.Gravity = v
end)

-- ===== TAB 3: VISUAL =====
local p3 = createTab("Вид", "🎨")

section("Цвет (на курсор)", p3)
local rVal, gVal, bVal = 200, 200, 200
makeSlider("R", p3, 0, 255, 200, function(v) rVal = v end)
makeSlider("G", p3, 0, 255, 200, function(v) gVal = v end)
makeSlider("B", p3, 0, 255, 200, function(v) bVal = v end)
makeBtn("Применить цвет (курсор)", p3).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then notify("Наведи на объект", C.red) return end
	pcall(function() t.Color = Color3.fromRGB(rVal, gVal, bVal) end)
	notify("Цвет применён", C.green)
end)

section("Быстрые цвета", p3)
local colors = {
	{"Красный", Color3.fromRGB(231, 76, 60)},
	{"Зелёный", Color3.fromRGB(46, 204, 113)},
	{"Синий", Color3.fromRGB(52, 152, 219)},
	{"Жёлтый", Color3.fromRGB(241, 196, 15)},
	{"Фиолет", Color3.fromRGB(155, 89, 182)},
	{"Оранж", Color3.fromRGB(230, 126, 34)},
	{"Белый", Color3.fromRGB(255, 255, 255)},
	{"Чёрный", Color3.fromRGB(20, 20, 20)},
}
for _, c in ipairs(colors) do
	local b = makeBtn(c[1], p3, 26)
	b.MouseButton1Click:Connect(function()
		local t = getTarget()
		if t then pcall(function() t.Color = c[2] end) notify("Цвет: " .. c[1], C.green) end
	end)
end

section("Материал (на курсор)", p3)
local mats = {
	{"Plastic", Enum.Material.Plastic},
	{"Neon", Enum.Material.Neon},
	{"Metal", Enum.Material.Metal},
	{"Glass", Enum.Material.Glass},
	{"Wood", Enum.Material.Wood},
	{"Concrete", Enum.Material.Concrete},
	{"Ice", Enum.Material.Ice},
	{"Sand", Enum.Material.Sand},
	{"Granite", Enum.Material.Granite},
	{"Slate", Enum.Material.Slate},
	{"Foil", Enum.Material.Foil},
	{"ForceField", Enum.Material.ForceField},
}
for _, m in ipairs(mats) do
	local b = makeBtn(m[1], p3, 26)
	b.MouseButton1Click:Connect(function()
		local t = getTarget()
		if t then pcall(function() t.Material = m[2] end) notify("Материал: " .. m[1], C.green) end
	end)
end

section("Прозрачность и отражение", p3)
local transpVal = 0
makeSlider("Transparency", p3, 0, 1, 0, function(v)
	transpVal = v
	local t = getTarget()
	if t then pcall(function() t.Transparency = v end) end
end)
local reflVal = 0
makeSlider("Reflectance", p3, 0, 1, 0, function(v)
	reflVal = v
	local t = getTarget()
	if t then pcall(function() t.Reflectance = v end) end
end)

-- ===== TAB 4: LIGHT =====
local p4 = createTab("Свет", "💡")

section("Технология освещения", p4)
local techs = {
	{"Future", Enum.Technology.Future},
	{"ShadowMap", Enum.Technology.ShadowMap},
	{"Voxel", Enum.Technology.Voxel},
	{"Legacy", Enum.Technology.Legacy},
}
for _, t in ipairs(techs) do
	local b = makeBtn(t[1], p4, 28)
	b.MouseButton1Click:Connect(function()
		Lighting.Technology = t[2]
		notify("Освещение: " .. t[1], C.green)
	end)
end

section("Параметры", p4)
makeSlider("Brightness", p4, 0, 5, 2, function(v) Lighting.Brightness = v end)
makeSlider("ClockTime", p4, 0, 24, 14, function(v) Lighting.ClockTime = v end)
makeSlider("FogEnd", p4, 0, 1000, 100000, function(v) Lighting.FogEnd = v end)
makeSlider("ExposureCompensation", p4, -3, 3, 0, function(v)
	pcall(function() Lighting.ExposureCompensation = v end)
end)

section("Эффекты", p4)
makeBtn("Добавить Atmosphere", p4).MouseButton1Click:Connect(function()
	local a = Lighting:FindFirstChildOfClass("Atmosphere")
	if not a then
		a = Instance.new("Atmosphere")
		a.Parent = Lighting
	end
	a.Density = 0.3
	a.Color = Color3.fromRGB(199, 170, 107)
	a.Decay = Color3.fromRGB(106, 112, 148)
	notify("Atmosphere добавлена", C.green)
end)
makeBtn("Добавить Sky", p4).MouseButton1Click:Connect(function()
	local s = Lighting:FindFirstChildOfClass("Sky")
	if not s then
		s = Instance.new("Sky")
		s.Parent = Lighting
	end
	s.SkyboxBk = "rbxassetid://1644783798"
	s.SkyboxDn = "rbxassetid://1644783955"
	s.SkyboxFt = "rbxassetid://1644783716"
	s.SkyboxLf = "rbxassetid://1644783770"
	s.SkyboxRt = "rbxassetid://1644783849"
	s.SkyboxUp = "rbxassetid://1644783886"
	notify("Sky добавлен", C.green)
end)
makeToggle("Цикл День/Ночь", p4, false, function(v)
	dayNightOn = v
	if v then
		dayNightTask = task.spawn(function()
			while dayNightOn do
				Lighting.ClockTime = (Lighting.ClockTime + 0.05) % 24
				task.wait(0.1)
			end
		end)
		notify("Цикл запущен", C.green)
	else
		notify("Цикл остановлен", C.yellow)
	end
end)
makeBtn("Удалить Atmosphere/Sky", p4).MouseButton1Click:Connect(function()
	local a = Lighting:FindFirstChildOfClass("Atmosphere")
	if a then a:Destroy() end
	local s = Lighting:FindFirstChildOfClass("Sky")
	if s then s:Destroy() end
	notify("Очищено", C.green)
end)

-- ===== TAB 5: SCRIPTS =====
local p5 = createTab("Скрипты", "📜")

section("Шаблоны (вставка в курсор)", p5)

local function insertScript(codeStr, isLocal)
	local t = getTarget()
	local parent = t or Workspace
	local s = Instance.new(isLocal and "LocalScript" or "Script")
	s.Source = codeStr
	s.Parent = parent
	return s
end

local templates = {
	{"Teleport Pad", [[
local pad = script.Parent
pad.Touched:Connect(function(hit)
    local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = 100
        local root = hit.Parent:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(0, 50, 0)
        end
    end
end)
]]},
	{"Leaderstats", [[
game.Players.PlayerAdded:Connect(function(plr)
    local ls = Instance.new("Folder")
    ls.Name = "leaderstats"
    ls.Parent = plr
    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = ls
end)
]]},
	{"RemoteEvent", [[
local re = Instance.new("RemoteEvent")
re.Name = "Event"
re.Parent = game.ReplicatedStorage
re.OnServerEvent:Connect(function(plr, msg)
    print(plr.Name .. ": " .. tostring(msg))
end)
]]},
	{"Kill Brick", [[
local brick = script.Parent
brick.Touched:Connect(function(hit)
    local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = 0
    end
end)
]]},
	{"Heal Brick", [[
local brick = script.Parent
brick.Touched:Connect(function(hit)
    local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = hum.MaxHealth
    end
end)
]]},
	{"Door (Toggle)", [[
local door = script.Parent
local open = false
local origin = door.CFrame
door.Touched:Connect(function(hit)
    local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
    if hum then
        open = not open
        if open then
            door.CFrame = origin * CFrame.new(0, 10, 0)
        else
            door.CFrame = origin
        end
        task.wait(0.5)
    end
end)
]]},
	{"Anti-Fall", [[
local pad = script.Parent
pad.Touched:Connect(function(hit)
    local root = hit.Parent:FindFirstChild("HumanoidRootPart")
    if root and root.Position.Y < -20 then
        root.CFrame = CFrame.new(0, 10, 0)
    end
end)
]]},
	{"Rotator", [[
local part = script.Parent
local rs = game:GetService("RunService")
rs.Heartbeat:Connect(function(dt)
    part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(90 * dt), 0)
end)
]]},
}

for _, tmpl in ipairs(templates) do
	local b = makeBtn(tmpl[1], p5, 30)
	b.MouseButton1Click:Connect(function()
		local ok = pcall(function()
			insertScript(tmpl[2], false)
		end)
		if ok then
			notify("Вставлен: " .. tmpl[1], C.green)
		else
			notify("Ошибка вставки (нужен плагин)", C.red)
		end
	end)
end

section("Действия со скриптами", p5)
makeBtn("Удалить все Script (курсор)", p5).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then notify("Наведи на объект", C.red) return end
	local count = 0
	for _, c in ipairs(t:GetDescendants()) do
		if c:IsA("Script") then c:Destroy() count = count + 1 end
	end
	notify("Удалено скриптов: " .. count, C.green)
end)
makeBtn("Удалить все LocalScript (курсор)", p5).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then notify("Наведи на объект", C.red) return end
	local count = 0
	for _, c in ipairs(t:GetDescendants()) do
		if c:IsA("LocalScript") then c:Destroy() count = count + 1 end
	end
	notify("Удалено LocalScript: " .. count, C.green)
end)

-- ===== TAB 6: PLAYER =====
local p6 = createTab("Игрок", "🎮")

section("Характеристики", p6)
makeSlider("WalkSpeed", p6, 1, 500, 16, function(v)
	local _, _, hum = getChar()
	if hum then hum.WalkSpeed = v end
end)
makeSlider("JumpPower", p6, 0, 500, 50, function(v)
	local _, _, hum = getChar()
	if hum then hum.JumpPower = v end
end)
makeSlider("Health", p6, 1, 10000, 100, function(v)
	local _, _, hum = getChar()
	if hum then hum.Health = v end
end)
makeSlider("HipHeight", p6, 0, 20, 2, function(v)
	local _, _, hum = getChar()
	if hum then hum.HipHeight = v end
end)

section("Полёт", p6)
makeSlider("Скорость полёта", p6, 10, 300, 50, function(v) flySpeed = v end)
makeToggle("Включить полёт", p6, false, function(v)
	flyOn = v
	local char, hrp, hum = getChar()
	if not char or not hrp or not hum then return end
	if v then
		hum.PlatformStand = true
		flyBV = Instance.new("BodyVelocity")
		flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		flyBV.Velocity = Vector3.zero
		flyBV.Parent = hrp
		flyConn = RunService.RenderStepped:Connect(function()
			if not flyOn or not flyBV or not flyBV.Parent then
				if flyConn then flyConn:Disconnect() end
				return
			end
			local cam = Workspace.CurrentCamera
			local dir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
			if dir.Magnitude > 0 then
				flyBV.Velocity = dir.Unit * flySpeed
			else
				flyBV.Velocity = Vector3.zero
			end
		end)
		notify("Полёт включён (WASD+Space/Shift)", C.green)
	else
		hum.PlatformStand = false
		if flyConn then flyConn:Disconnect() end
		if flyBV then flyBV:Destroy() flyBV = nil end
		notify("Полёт выключен", C.yellow)
	end
end)

section("Прочее", p6)
makeToggle("Noclip", p6, false, function(v)
	noclipOn = v
	if v then
		noclipConn = RunService.Stepped:Connect(function()
			if not noclipOn then
				if noclipConn then noclipConn:Disconnect() end
				return
			end
			local char = player.Character
			if char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
						p.CanCollide = false
					end
				end
			end
		end)
		notify("Noclip включён", C.green)
	else
		if noclipConn then noclipConn:Disconnect() end
		local char = player.Character
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
					p.CanCollide = true
				end
			end
		end
		notify("Noclip выключен", C.yellow)
	end
end)

makeToggle("Бесконечный прыжок", p6, false, function(v)
	infJumpOn = v
	if v then
		jumpConn = UserInputService.JumpRequest:Connect(function()
			local _, _, hum = getChar()
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
		notify("Беск. прыжок вкл", C.green)
	else
		if jumpConn then jumpConn:Disconnect() end
		notify("Беск. прыжок выкл", C.yellow)
	end
end)

makeBtn("Телепорт к спавну", p6).MouseButton1Click:Connect(function()
	local _, hrp = getChar()
	if hrp then
		hrp.CFrame = CFrame.new(0, 50, 0)
		notify("Телепорт", C.green)
	end
end)
makeBtn("Телепорт к курсору", p6).MouseButton1Click:Connect(function()
	local _, hrp = getChar()
	local t = getTarget()
	if hrp and t then
		hrp.CFrame = t.CFrame + Vector3.new(0, 3, 0)
		notify("Телепорт к курсору", C.green)
	end
end)
makeBtn("Сброс персонажа", p6).MouseButton1Click:Connect(function()
	local _, _, hum = getChar()
	if hum then hum.Health = 0 notify("Сброс", C.red) end
end)

-- ===== TAB 7: BUILD =====
local p7 = createTab("Билд", "🏠")

section("Генераторы", p7)
local buildSize = 4
makeSlider("Размер части", p7, 1, 20, 4, function(v) buildSize = v end)
local buildCount = 5
makeSlider("Количество", p7, 1, 50, 5, function(v) buildCount = v end)

local function makePart(pos, sz)
	local p = Instance.new("Part")
	p.Size = Vector3.new(sz, sz, sz)
	p.Position = pos
	p.Anchored = true
	p.BrickColor = BrickColor.Random()
	p.Parent = Workspace
	return p
end

makeBtn("Сетка NxN", p7).MouseButton1Click:Connect(function()
	local t = getTarget()
	local cx = t and t.Position.X or 0
	local cy = t and t.Position.Y + buildSize or buildSize
	local cz = t and t.Position.Z or 0
	for i = 0, buildCount - 1 do
		for j = 0, buildCount - 1 do
			makePart(Vector3.new(cx + i * buildSize, cy, cz + j * buildSize), buildSize)
		end
	end
	notify("Сетка " .. buildCount .. "x" .. buildCount, C.green)
end)
makeBtn("Линия", p7).MouseButton1Click:Connect(function()
	local t = getTarget()
	local cx = t and t.Position.X or 0
	local cy = t and t.Position.Y + buildSize or buildSize
	local cz = t and t.Position.Z or 0
	for i = 0, buildCount - 1 do
		makePart(Vector3.new(cx + i * buildSize, cy, cz), buildSize)
	end
	notify("Линия: " .. buildCount, C.green)
end)
makeBtn("Круг", p7).MouseButton1Click:Connect(function()
	local t = getTarget()
	local cx = t and t.Position.X or 0
	local cy = t and t.Position.Y + buildSize or buildSize
	local cz = t and t.Position.Z or 0
	local radius = buildCount * buildSize * 0.3
	for i = 0, buildCount - 1 do
		local angle = (i / buildCount) * math.pi * 2
		makePart(Vector3.new(cx + math.cos(angle) * radius, cy, cz + math.sin(angle) * radius), buildSize)
	end
	notify("Круг: " .. buildCount, C.green)
end)
makeBtn("Сфера", p7).MouseButton1Click:Connect(function()
	local t = getTarget()
	local cx = t and t.Position.X or 0
	local cy = t and t.Position.Y + buildSize * 2 or buildSize * 2
	local cz = t and t.Position.Z or 0
	local radius = buildCount * buildSize * 0.3
	for i = 1, buildCount do
		local phi = math.acos(1 - 2 * i / buildCount)
		local theta = math.pi * (1 + math.sqrt(5)) * i
		makePart(Vector3.new(
			cx + radius * math.sin(phi) * math.cos(theta),
			cy + radius * math.cos(phi),
			cz + radius * math.sin(phi) * math.sin(theta)
			), buildSize)
	end
	notify("Сфера: " .. buildCount, C.green)
end)
makeBtn("Спираль", p7).MouseButton1Click:Connect(function()
	local t = getTarget()
	local cx = t and t.Position.X or 0
	local cy = t and t.Position.Y or 0
	local cz = t and t.Position.Z or 0
	for i = 0, buildCount - 1 do
		local angle = i * 0.5
		local r = buildSize * (i * 0.3 + 1)
		makePart(Vector3.new(cx + math.cos(angle) * r, cy + i * buildSize * 0.5, cz + math.sin(angle) * r), buildSize)
	end
	notify("Спираль: " .. buildCount, C.green)
end)
makeBtn("Пирамида", p7).MouseButton1Click:Connect(function()
	local t = getTarget()
	local cx = t and t.Position.X or 0
	local cy = t and t.Position.Y or 0
	local cz = t and t.Position.Z or 0
	for row = 0, buildCount - 1 do
		for col = 0, buildCount - 1 - row do
			makePart(Vector3.new(
				cx + col * buildSize + row * buildSize * 0.5,
				cy + row * buildSize,
				cz
				), buildSize)
		end
	end
	notify("Пирамида", C.green)
end)

section("Зеркалирование", p7)
makeBtn("Зеркало по X (курсор)", p7).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then return end
	local c = t:Clone()
	c.Position = Vector3.new(-t.Position.X, t.Position.Y, t.Position.Z)
	c.Parent = t.Parent
	notify("Зеркало X", C.green)
end)
makeBtn("Зеркало по Z (курсор)", p7).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then return end
	local c = t:Clone()
	c.Position = Vector3.new(t.Position.X, t.Position.Y, -t.Position.Z)
	c.Parent = t.Parent
	notify("Зеркало Z", C.green)
end)

-- ===== TAB 8: UTILS =====
local p8 = createTab("Утилиты", "🔧")

section("Статистика", p8)
makeBtn("Подсчитать в Workspace", p8).MouseButton1Click:Connect(function()
	local parts, models, scripts = 0, 0, 0
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("BasePart") then parts = parts + 1 end
		if d:IsA("Model") then models = models + 1 end
		if d:IsA("Script") or d:IsA("LocalScript") then scripts = scripts + 1 end
	end
	notify("Parts: " .. parts .. " | Models: " .. models .. " | Scripts: " .. scripts, C.blue)
end)

section("Поиск", p8)
local searchBox = makeTextBox("Имя объекта", p8, "Part")
makeBtn("Найти и показать путь", p8).MouseButton1Click:Connect(function()
	local name = searchBox.Text
	if name == "" then return end
	local found = 0
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d.Name:lower():find(name:lower()) then
			found = found + 1
			print("[MultiTool] " .. d:GetFullName())
		end
	end
	notify("Найдено: " .. found .. " (см. Output)", C.green)
end)
makeBtn("Найти и удалить", p8).MouseButton1Click:Connect(function()
	local name = searchBox.Text
	if name == "" then return end
	local count = 0
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d.Name:lower() == name:lower() and d ~= Workspace then
			d:Destroy()
			count = count + 1
		end
	end
	notify("Удалено: " .. count, C.red)
end)

section("Иерархия", p8)
makeBtn("Дамп в Output", p8).MouseButton1Click:Connect(function()
	local t = getTarget() or Workspace
	for _, d in ipairs(t:GetDescendants()) do
		print("[MultiTool] " .. string.rep("  ", d:GetAttribute("depth") or 0) .. d.Name .. " [" .. d.ClassName .. "]")
	end
	notify("Дамп в Output", C.green)
end)

section("Очистка", p8)
makeBtn("Удалить все Parts в Workspace", p8).MouseButton1Click:Connect(function()
	local count = 0
	for _, d in ipairs(Workspace:GetChildren()) do
		if d:IsA("BasePart") then d:Destroy() count = count + 1 end
	end
	notify("Удалено Parts: " .. count, C.red)
end)
makeBtn("Очистить Workspace (кроме Terrain)", p8).MouseButton1Click:Connect(function()
	local count = 0
	for _, d in ipairs(Workspace:GetChildren()) do
		if not d:IsA("Terrain") and not d:IsA("Camera") then
			d:Destroy()
			count = count + 1
		end
	end
	notify("Очищено: " .. count, C.red)
end)

-- ===== TAB 9: TERRAIN =====
local p9 = createTab("Террайн", "🌍")

local Terrain = Workspace:FindFirstChildOfClass("Terrain")

section("Генерация", p9)
local terrainSize = 100
makeSlider("Размер", p9, 50, 500, 100, function(v) terrainSize = v end)
local terrainHeight = 20
makeSlider("Высота холмов", p9, 5, 80, 20, function(v) terrainHeight = v end)

makeBtn("Плоский террайн", p9).MouseButton1Click:Connect(function()
	if not Terrain then notify("Terrain не найден", C.red) return end
	local region = Region3.new(
		Vector3.new(-terrainSize, 0, -terrainSize),
		Vector3.new(terrainSize, 4, terrainSize)
	)
	Terrain:FillBlock(region, 4, Enum.Material.Grass)
	notify("Плоский террайн создан", C.green)
end)

makeBtn("Холмы (шум Перлина)", p9).MouseButton1Click:Connect(function()
	if not Terrain then notify("Terrain не найден", C.red) return end
	local res = 4
	local size = terrainSize
	local height = terrainHeight
	local seed = math.random(1, 9999)
	local offsetX = math.random(0, 10000)
	local offsetZ = math.random(0, 10000)
	for x = -size, size, res do
		for z = -size, size, res do
			local nx = (x + offsetX) / 100
			local nz = (z + offsetZ) / 100
			local h = (math.noise(nx, nz, seed) + 1) * 0.5
			h = math.max(0, h) * height
			if h > 1 then
				local region = Region3.new(
					Vector3.new(x, 0, z),
					Vector3.new(x + res, h, z + res)
				)
				Terrain:FillBlock(region, res, Enum.Material.Grass)
			end
		end
	end
	notify("Холмы сгенерированы", C.green)
end)

makeBtn("Озеро", p9).MouseButton1Click:Connect(function()
	if not Terrain then notify("Terrain не найден", C.red) return end
	local region = Region3.new(
		Vector3.new(-terrainSize * 0.5, 0, -terrainSize * 0.5),
		Vector3.new(terrainSize * 0.5, 8, terrainSize * 0.5)
	)
	Terrain:FillBlock(region, 4, Enum.Material.Water)
	notify("Озеро создано", C.blue)
end)

section("Материал заливки", p9)
local terrainMats = {
	{"Grass", Enum.Material.Grass},
	{"Water", Enum.Material.Water},
	{"Sand", Enum.Material.Sand},
	{"Rock", Enum.Material.Rock},
	{"Snow", Enum.Material.Snow},
	{"Lava", Enum.Material.Lava},
	{"Wood", Enum.Material.WoodPlanks},
	{"Ice", Enum.Material.Ice},
}
for _, m in ipairs(terrainMats) do
	local b = makeBtn(m[1], p9, 26)
	b.MouseButton1Click:Connect(function()
		if not Terrain then return end
		local region = Region3.new(
			Vector3.new(-terrainSize * 0.3, 0, -terrainSize * 0.3),
			Vector3.new(terrainSize * 0.3, 4, terrainSize * 0.3)
		)
		Terrain:FillBlock(region, 4, m[2])
		notify("Залито: " .. m[1], C.green)
	end)
end

section("Действия", p9)
makeBtn("Очистить террайн", p9).MouseButton1Click:Connect(function()
	if Terrain then
		Terrain:Clear()
		notify("Террайн очищен", C.red)
	end
end)

-- ===== TAB 10: EFFECTS =====
local p10 = createTab("Эффекты", "✨")

section("Эффекты (на курсор)", p10)

makeBtn("Огонь", p10).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then return end
	local f = Instance.new("Fire")
	f.Size = 10
	f.Parent = t
	notify("Огонь добавлен", C.red)
end)
makeBtn("Дым", p10).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then return end
	local s = Instance.new("Smoke")
	s.Size = 8
	s.Parent = t
	notify("Дым добавлен", C.yellow)
end)
makeBtn("Искры", p10).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then return end
	local s = Instance.new("Sparkles")
	s.SparkleColor = Color3.new(1, 1, 0)
	s.Parent = t
	notify("Искры добавлены", C.yellow)
end)
makeBtn("Частицы", p10).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then return end
	local p = Instance.new("ParticleEmitter")
	p.Rate = 50
	p.Lifetime = NumberRange.new(2, 4)
	p.Speed = NumberRange.new(5, 10)
	p.SpreadAngle = Vector2.new(45, 45)
	p.Parent = t
	notify("Частицы добавлены", C.green)
end)

makeToggle("PointLight (курсор)", p10, false, function(v)
	local t = getTarget()
	if not t then return end
	if v then
		local l = Instance.new("PointLight")
		l.Brightness = 2
		l.Range = 15
		l.Color = Color3.new(1, 1, 1)
		l.Parent = t
		t:SetAttribute("MT_Light", true)
		notify("Свет включён", C.green)
	else
		local l = t:FindFirstChildOfClass("PointLight")
		if l then l:Destroy() end
		notify("Свет выключен", C.yellow)
	end
end)

section("Trail (на курсор)", p10)
makeBtn("Добавить Trail", p10).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then return end
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, t.Size.Y * 0.5, 0)
	a0.Parent = t
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -t.Size.Y * 0.5, 0)
	a1.Parent = t
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Lifetime = 1
	tr.Color = ColorSequence.new(C.accent, C.accent2)
	tr.Parent = t
	notify("Trail добавлен", C.green)
end)

section("BillboardGui (на курсор)", p10)
local bbText = makeTextBox("Текст", p10, "Hello!")
makeBtn("Добавить BillboardGui", p10).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then return end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 200, 0, 50)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Parent = t
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = bbText.Text
	lbl.TextColor3 = C.text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 18
	lbl.Parent = bb
	notify("Billboard добавлен", C.green)
end)

section("Взрыв и звук", p10)
makeBtn("Взрыв на курсоре", p10).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then return end
	local e = Instance.new("Explosion")
	e.Position = t.Position
	e.BlastRadius = 15
	e.Parent = Workspace
	notify("Взрыв!", C.red)
end)
makeBtn("Звук на курсоре", p10).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then return end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://9113724446"
	s.Volume = 1
	s.Parent = t
	s:Play()
	notify("Звук добавлен", C.green)
end)

section("Очистка эффектектов", p10)
makeBtn("Убрать все эффекты (курсор)", p10).MouseButton1Click:Connect(function()
	local t = getTarget()
	if not t then return end
	for _, c in ipairs(t:GetChildren()) do
		if c:IsA("Fire") or c:IsA("Smoke") or c:IsA("Sparkles") or
			c:IsA("ParticleEmitter") or c:IsA("Trail") or c:IsA("PointLight") or
			c:IsA("BillboardGui") then
			c:Destroy()
		end
	end
	notify("Эффекты удалены", C.green)
end)

-- ===== INIT =====
notify("MultiTool загружен! Нажми ▢ для раскрытия", C.accent2)
