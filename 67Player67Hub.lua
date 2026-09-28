-- PlayerHub v2 — Premium Player Utility GUI
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local killed = false
local allConnections = {}

-- Safe parent
local safeParent
pcall(function() safeParent = game:GetService("CoreGui") end)
if not safeParent then safeParent = player:WaitForChild("PlayerGui") end

-- Theme
local T = {
	bg = Color3.fromRGB(10, 10, 16),
	bg2 = Color3.fromRGB(22, 22, 32),
	bg3 = Color3.fromRGB(36, 36, 50),
	bg4 = Color3.fromRGB(50, 50, 68),
	accent = Color3.fromRGB(100, 200, 255),
	accent2 = Color3.fromRGB(180, 100, 255),
	text = Color3.fromRGB(240, 240, 245),
	dim = Color3.fromRGB(140, 140, 160),
	green = Color3.fromRGB(80, 200, 120),
	red = Color3.fromRGB(230, 70, 70),
	yellow = Color3.fromRGB(255, 210, 80),
	orange = Color3.fromRGB(255, 150, 60),
}

-- Instance creation helper
local function s(class, props)
	local obj
	local ok = pcall(function() obj = Instance.new(class) end)
	if not ok or not obj then return nil end
	if props then
		for k, v in pairs(props) do
			pcall(function() obj[k] = v end)
		end
	end
	return obj
end

-- Connection tracker
local function conn(c)
	if killed then
		pcall(function() c:Disconnect() end)
		return nil
	end
	table.insert(allConnections, c)
	return c
end

-- Character helpers
local function getHum()
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local nGui = s("ScreenGui", {
	Name = "PHN_" .. tostring(math.random(10000, 99999)),
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = safeParent,
})
local nContainer = s("Frame", {
	Name = "C",
	Size = UDim2.new(0.9, 0, 1, -20),
	Position = UDim2.new(0.5, 0, 0, 10),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	Parent = nGui,
})
s("UISizeConstraint", { MaxSize = Vector2.new(320, math.huge), Parent = nContainer })
s("UIListLayout", {
	Padding = UDim.new(0, 6),
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Parent = nContainer,
})

local function notify(text, color)
	if killed then return end
	color = color or T.accent
	local n = s("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = T.bg2,
		BorderSizePixel = 0,
		Parent = nContainer,
	})
	s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = n })
	s("UIStroke", { Color = color, Thickness = 1, Transparency = 0.5, Parent = n })
	local bar = s("Frame", {
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = n,
	})
	s("UICorner", { CornerRadius = UDim.new(0, 2), Parent = bar })
	local lbl = s("TextLabel", {
		Size = UDim2.new(1, -16, 1, -12),
		Position = UDim2.fromOffset(12, 6),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = T.text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = n,
	})
	n.BackgroundTransparency = 1
	bar.BackgroundTransparency = 1
	lbl.TextTransparency = 1
	local st = n:FindFirstChild("UIStroke")
	if st then st.Transparency = 1 end
	TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 0,
	}):Play()
	TweenService:Create(bar, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(lbl, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	if st then TweenService:Create(st, TweenInfo.new(0.3), { Transparency = 0.5 }):Play() end
	task.delay(3, function()
		if killed then return end
		TweenService:Create(n, TweenInfo.new(0.3), {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(bar, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(lbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		if st then TweenService:Create(st, TweenInfo.new(0.3), { Transparency = 1 }):Play() end
		task.wait(0.35)
		if n and n.Parent then n:Destroy() end
	end)
end

-- ============================================================
-- MAIN GUI WINDOW
-- ============================================================
local gui = s("ScreenGui", {
	Name = "PHM_" .. tostring(math.random(10000, 99999)),
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Enabled = false,
	Parent = safeParent,
})

local frame = s("Frame", {
	Size = UDim2.fromOffset(340, 480),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = T.bg,
	BorderSizePixel = 0,
	Parent = gui,
})
s("UICorner", { CornerRadius = UDim.new(0, 14), Parent = frame })
s("UIStroke", { Color = T.accent, Thickness = 1.5, Transparency = 0.3, Parent = frame })
s("UIGradient", {
	Color = ColorSequence.new(T.bg, Color3.fromRGB(16, 12, 24)),
	Rotation = 90,
	Parent = frame,
})

-- Title bar
local titleBar = s("Frame", {
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundTransparency = 1,
	Parent = frame,
})
local titleIcon = s("TextLabel", {
	Size = UDim2.fromOffset(28, 28),
	Position = UDim2.fromOffset(10, 8),
	BackgroundTransparency = 1,
	Text = "\u25C8",
	TextColor3 = T.accent,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	Parent = titleBar,
})
s("TextLabel", {
	Size = UDim2.new(1, -90, 1, 0),
	Position = UDim2.fromOffset(40, 0),
	BackgroundTransparency = 1,
	Text = "PlayerHub",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = titleBar,
})
local closeBtn = s("TextButton", {
	Size = UDim2.fromOffset(30, 30),
	Position = UDim2.new(1, -37, 0.5, -15),
	BackgroundColor3 = T.red,
	Text = "\u2715",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	AutoButtonColor = false,
	Parent = titleBar,
})
s("UICorner", { CornerRadius = UDim.new(1, 0), Parent = closeBtn })

-- Tab bar (horizontal scroll)
local tabBar = s("ScrollingFrame", {
	Size = UDim2.new(1, -16, 0, 32),
	Position = UDim2.fromOffset(8, 46),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	ScrollingDirection = Enum.ScrollingDirection.X,
	Parent = frame,
})
s("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 4),
	Parent = tabBar,
})

-- Content area
local content = s("Frame", {
	Size = UDim2.new(1, -16, 1, -86),
	Position = UDim2.fromOffset(8, 82),
	BackgroundTransparency = 1,
	Parent = frame,
})

-- ============================================================
-- TOGGLE BUTTON (floating)
-- ============================================================
local tGui = s("ScreenGui", {
	Name = "PHT_" .. tostring(math.random(10000, 99999)),
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = safeParent,
})
local tBtn = s("TextButton", {
	Size = UDim2.fromOffset(48, 48),
	Position = UDim2.new(0, 8, 0.5, -24),
	BackgroundColor3 = T.accent,
	Text = "\u25C8",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	AutoButtonColor = false,
	Parent = tGui,
})
s("UICorner", { CornerRadius = UDim.new(1, 0), Parent = tBtn })
s("UIGradient", { Color = ColorSequence.new(T.accent, T.accent2), Rotation = 90, Parent = tBtn })
s("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.5, Parent = tBtn })

-- State
local tabs = {}
local animating = false
local dragging = false
local dragStart
local startPos

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local function createTab(name, icon)
	local btn = s("TextButton", {
		Size = UDim2.new(0, 64, 1, 0),
		BackgroundColor3 = T.bg2,
		Text = (icon or "") .. " " .. name,
		TextColor3 = T.dim,
		Font = Enum.Font.GothamMedium,
		TextSize = 10,
		AutoButtonColor = false,
		Parent = tabBar,
	})
	s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
	local page = s("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.dim,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = content,
	})
	s("UIListLayout", { Padding = UDim.new(0, 6), Parent = page })
	s("UIPadding", {
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 4),
		Parent = page,
	})
	local td = { button = btn, page = page, name = name }
	table.insert(tabs, td)
	conn(btn.MouseButton1Click:Connect(function()
		for _, t in ipairs(tabs) do
			if t == td then
				t.page.Visible = true
				t.button.BackgroundColor3 = T.accent
				t.button.TextColor3 = T.text
				TweenService:Create(t.button, TweenInfo.new(0.15), { BackgroundColor3 = T.accent }):Play()
			else
				t.page.Visible = false
				t.button.BackgroundColor3 = T.bg2
				t.button.TextColor3 = T.dim
				TweenService:Create(t.button, TweenInfo.new(0.15), { BackgroundColor3 = T.bg2 }):Play()
			end
		end
	end))
	return td
end

-- ============================================================
-- UI HELPERS
-- ============================================================
local function toggle(parent, label, default, cb)
	local row = s("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = T.bg2,
		BorderSizePixel = 0,
		Parent = parent,
	})
	s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
	s("TextLabel", {
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = T.text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local bg = s("Frame", {
		Size = UDim2.fromOffset(44, 24),
		Position = UDim2.new(1, -52, 0.5, -12),
		BackgroundColor3 = default and T.green or Color3.fromRGB(60, 60, 70),
		BorderSizePixel = 0,
		Parent = row,
	})
	s("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bg })
	local knob = s("Frame", {
		Size = UDim2.fromOffset(18, 18),
		Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = bg,
	})
	s("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	local st = default
	local b = s("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = row,
	})
	conn(b.MouseButton1Click:Connect(function()
		st = not st
		TweenService:Create(bg, TweenInfo.new(0.2), {
			BackgroundColor3 = st and T.green or Color3.fromRGB(60, 60, 70),
		}):Play()
		TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = st and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
		}):Play()
		pcall(cb, st)
	end))
	return row
end

local function button(parent, label, cb)
	local b = s("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = T.accent,
		Text = label,
		TextColor3 = T.text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		AutoButtonColor = false,
		Parent = parent,
	})
	s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = b })
	s("UIGradient", { Color = ColorSequence.new(T.accent, T.accent2), Rotation = 90, Parent = b })
	local d = false
	conn(b.MouseButton1Click:Connect(function()
		if d then return end
		d = true
		TweenService:Create(b, TweenInfo.new(0.08), {
			Size = UDim2.new(1, -4, 0, 32),
			Position = UDim2.new(0, 2, 0, 2),
		}):Play()
		task.wait(0.08)
		TweenService:Create(b, TweenInfo.new(0.08), {
			Size = UDim2.new(1, 0, 0, 36),
			Position = UDim2.new(0, 0, 0, 0),
		}):Play()
		pcall(cb)
		d = false
	end))
	return b
end

local function slider(parent, label, min, max, default, cb)
	local row = s("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = T.bg2,
		BorderSizePixel = 0,
		Parent = parent,
	})
	s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
	local lbl = s("TextLabel", {
		Size = UDim2.new(1, -12, 0, 18),
		Position = UDim2.fromOffset(10, 4),
		BackgroundTransparency = 1,
		Text = label .. ": " .. tostring(default),
		TextColor3 = T.text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local input = s("TextBox", {
		Size = UDim2.new(1, -16, 0, 28),
		Position = UDim2.fromOffset(8, 24),
		BackgroundColor3 = T.bg3,
		Text = tostring(default),
		TextColor3 = T.text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		ClearTextOnFocus = false,
		Parent = row,
	})
	s("UICorner", { CornerRadius = UDim.new(0, 4), Parent = input })
	s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.7, Parent = input })
	conn(input.FocusLost:Connect(function()
		local v = tonumber(input.Text)
		if v then
			v = math.clamp(v, min, max)
			input.Text = tostring(v)
			lbl.Text = label .. ": " .. tostring(v)
			pcall(cb, v)
		else
			input.Text = tostring(default)
		end
	end))
	return row
end

local function header(parent, text)
	local h = s("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = T.accent,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	s("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = T.accent,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Parent = h,
	})
	return h
end

-- ============================================================
-- CREATE ALL TABS
-- ============================================================
local statsTab = createTab("Stats", "\u25C9")
local musicTab = createTab("Music", "\u266B")
local gamesTab = createTab("Games", "\u2666")
local fxTab = createTab("FX", "\u2728")
local chatTab = createTab("Chat", "\u2702")
local utilTab = createTab("Util", "\u2691")
local settingsTab = createTab("Set", "\u2699")

-- ============================================================
-- OPEN / CLOSE
-- ============================================================
local function openPanel()
	if animating or killed then return end
	animating = true
	gui.Enabled = true
	tBtn.Visible = false
	frame.Size = UDim2.fromOffset(0, 0)
	local tw = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(340, 480),
	})
	tw:Play()
	conn(tw.Completed:Connect(function() animating = false end))
end

local function closePanel()
	if animating or killed then return end
	animating = true
	local tw = TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(0, 0),
	})
	tw:Play()
	conn(tw.Completed:Connect(function()
		if killed then return end
		gui.Enabled = false
		tBtn.Visible = true
		animating = false
	end))
end

conn(closeBtn.MouseButton1Click:Connect(function() closePanel() end))
conn(tBtn.MouseButton1Click:Connect(function()
	if gui.Enabled then closePanel() else openPanel() end
end))
conn(UserInputService.InputBegan:Connect(function(input, gP)
	if gP or killed then return end
	if input.KeyCode == Enum.KeyCode.J then
		if gui.Enabled then closePanel() else openPanel() end
	end
end))

-- ============================================================
-- DRAGGING
-- ============================================================
conn(titleBar.InputBegan:Connect(function(input)
	if killed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end))
conn(titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end))
conn(UserInputService.InputChanged:Connect(function(input)
	if killed then return end
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		pcall(function()
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end)
	end
end))

-- Default tab
if #tabs > 0 then
	tabs[1].button.BackgroundColor3 = T.accent
	tabs[1].button.TextColor3 = T.text
	tabs[1].page.Visible = true
end

notify("PlayerHub v2 loaded! Press J or tap the icon", T.green)

-- ============================================================
-- TAB: STATS
-- ============================================================
header(statsTab.page, "Live Stats")

local statLabels = {}
local function createStatRow(parent, labelText, icon)
	local row = s("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = T.bg2,
		BorderSizePixel = 0,
		Parent = parent,
	})
	s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
	s("TextLabel", {
		Size = UDim2.new(0.5, -12, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = (icon or "") .. " " .. labelText,
		TextColor3 = T.dim,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local val = s("TextLabel", {
		Size = UDim2.new(0.5, -12, 1, 0),
		Position = UDim2.new(0.5, 2, 0, 0),
		BackgroundTransparency = 1,
		Text = "...",
		TextColor3 = T.text,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
	return val
end

statLabels.fps = createStatRow(statsTab.page, "FPS", "\u25B6")
statLabels.ping = createStatRow(statsTab.page, "Ping (ms)", "\u21C4")
statLabels.playtime = createStatRow(statsTab.page, "Playtime", "\u23F1")
statLabels.players = createStatRow(statsTab.page, "Players Online", "\u2605")
statLabels.serverTime = createStatRow(statsTab.page, "Server Time", "\u23F0")
statLabels.jobId = createStatRow(statsTab.page, "Job ID", "\u25A0")
statLabels.placeId = createStatRow(statsTab.page, "Place ID", "\u25A0")
statLabels.gravity = createStatRow(statsTab.page, "Gravity", "\u2193")
statLabels.fps2 = createStatRow(statsTab.page, "Avg FPS", "\u25B6")
statLabels.memory = createStatRow(statsTab.page, "Memory (MB)", "\u25A8")
statLabels.device = createStatRow(statsTab.page, "Device", "\u25A0")
statLabels.fpsMax = createStatRow(statsTab.page, "Max FPS Cap", "\u25B6")

local startTime = tick()
local fpsAccum = 0
local fpsCount = 0
local fpsAvg = 0
local lastUpdate = tick()

conn(RunService.Heartbeat:Connect(function()
	if killed then return end
	local now = tick()
	local dt = now - lastUpdate
	if dt > 0 then
		local fps = 1 / dt
		fpsAccum = fpsAccum + fps
		fpsCount = fpsCount + 1
		if fpsCount >= 30 then
			fpsAvg = fpsAccum / fpsCount
			fpsAccum = 0
			fpsCount = 0
		end
	end
	lastUpdate = now
end))

task.spawn(function()
	while not killed do
		task.wait(0.5)
		if not killed then
			local currentFps = fpsAvg > 0 and math.floor(fpsAvg) or 0
			local playtimeSec = math.floor(tick() - startTime)
			local ph = math.floor(playtimeSec / 3600)
			local pm = math.floor((playtimeSec % 3600) / 60)
			local ps = playtimeSec % 60
			local playtimeStr = string.format("%02d:%02d:%02d", ph, pm, ps)
			local pingMs = 0
			pcall(function() pingMs = math.floor(Stats.PerformanceStats.PingMs.Value) end)
			local memMb = 0
			pcall(function() memMb = math.floor(Stats:GetTotalMemoryUsageMb()) end)
			local deviceType = "Unknown"
			if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
				deviceType = "Mobile"
			elseif UserInputService.GamepadEnabled and not UserInputService.MouseEnabled then
				deviceType = "Console"
			else
				deviceType = "PC"
			end
			pcall(function() statLabels.fps.Text = tostring(currentFps) end)
			pcall(function() statLabels.fps2.Text = tostring(currentFps) end)
			pcall(function() statLabels.ping.Text = tostring(pingMs) end)
			pcall(function() statLabels.playtime.Text = playtimeStr end)
			pcall(function() statLabels.players.Text = tostring(#Players:GetPlayers()) end)
			pcall(function() statLabels.serverTime.Text = os.date("%H:%M:%S") end)
			pcall(function() statLabels.jobId.Text = string.sub(tostring(game.JobId or "N/A"), 1, 12) .. "..." end)
			pcall(function() statLabels.placeId.Text = tostring(game.PlaceId) end)
			pcall(function() statLabels.gravity.Text = string.format("%.1f", Workspace.Gravity) end)
			pcall(function() statLabels.memory.Text = tostring(memMb) end)
			pcall(function() statLabels.device.Text = deviceType end)
			pcall(function() statLabels.fpsMax.Text = tostring(workspace:GetRealPhysicsFPS()) end)
		end
	end
end)

header(statsTab.page, "Quick Info")
button(statsTab.page, "Copy Job ID", function()
	if setclipboard then
		pcall(setclipboard, tostring(game.JobId or ""))
		notify("Job ID copied!", T.green)
	else
		notify(tostring(game.JobId or "N/A"), T.accent)
	end
end)
button(statsTab.page, "Copy Place ID", function()
	if setclipboard then
		pcall(setclipboard, tostring(game.PlaceId))
		notify("Place ID copied!", T.green)
	else
		notify(tostring(game.PlaceId), T.accent)
	end
end)
button(statsTab.page, "Copy Server Time", function()
	if setclipboard then
		pcall(setclipboard, os.date("%Y-%m-%d %H:%M:%S"))
		notify("Time copied!", T.green)
	else
		notify(os.date("%H:%M:%S"), T.accent)
	end
end)
button(statsTab.page, "Copy All Info", function()
	local info = string.format(
		"JobId: %s\nPlaceId: %s\nTime: %s\nPlayers: %d\nFPS: %d\nPing: %dms",
		tostring(game.JobId or "N/A"),
		tostring(game.PlaceId),
		os.date("%Y-%m-%d %H:%M:%S"),
		#Players:GetPlayers(),
		fpsAvg > 0 and math.floor(fpsAvg) or 0,
		select(2, pcall(function() return math.floor(Stats.PerformanceStats.PingMs.Value) end)) or 0
	)
	if setclipboard then
		pcall(setclipboard, info)
		notify("All info copied!", T.green)
	else
		notify(info, T.accent)
	end
end)

-- ============================================================
-- TAB: MUSIC
-- ============================================================
header(musicTab.page, "Now Playing")

local currentSongLabel = s("TextLabel", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundColor3 = T.bg2,
	BorderSizePixel = 0,
	Text = " \u266B Nothing playing",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = musicTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = currentSongLabel })
s("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = currentSongLabel })

-- Visualizer bars
local vizFrame = s("Frame", {
	Size = UDim2.new(1, 0, 0, 54),
	BackgroundColor3 = T.bg2,
	BorderSizePixel = 0,
	Parent = musicTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = vizFrame })
s("UIPadding", {
	PaddingLeft = UDim.new(0, 6),
	PaddingRight = UDim.new(0, 6),
	PaddingTop = UDim.new(0, 6),
	PaddingBottom = UDim.new(0, 6),
	Parent = vizFrame,
})
local vizBars = {}
for i = 1, 20 do
	local bar = s("Frame", {
		Size = UDim2.new(1/20, -1, 0, 5),
		Position = UDim2.new((i-1)/20, 0, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = T.accent,
		BorderSizePixel = 0,
		Parent = vizFrame,
	})
	s("UICorner", { CornerRadius = UDim.new(0, 2), Parent = bar })
	s("UIGradient", {
		Color = ColorSequence.new(T.accent, T.accent2),
		Rotation = 90,
		Parent = bar,
	})
	table.insert(vizBars, bar)
end

-- Sound object
local musicSound = s("Sound", { Name = "PHMusic", Volume = 0.5, Parent = SoundService })
local playlist = {}
local currentIdx = 1
local isPlaying = false

-- Controls
local controlsRow = s("Frame", {
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundTransparency = 1,
	Parent = musicTab.page,
})
s("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Parent = controlsRow,
})

local function ctrlBtn(text, cb)
	local b = s("TextButton", {
		Size = UDim2.new(0, 42, 1, 0),
		BackgroundColor3 = T.bg3,
		Text = text,
		TextColor3 = T.text,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		AutoButtonColor = false,
		Parent = controlsRow,
	})
	s("UICorner", { CornerRadius = UDim.new(1, 0), Parent = b })
	s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.6, Parent = b })
	conn(b.MouseButton1Click:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.1), { BackgroundColor3 = T.accent }):Play()
		task.wait(0.1)
		TweenService:Create(b, TweenInfo.new(0.1), { BackgroundColor3 = T.bg3 }):Play()
		pcall(cb)
	end))
	return b
end

local function playSong(idx)
	if #playlist == 0 then
		notify("Playlist empty! Add songs below", T.yellow)
		return
	end
	idx = ((idx - 1) % #playlist) + 1
	currentIdx = idx
	local song = playlist[idx]
	musicSound:Stop()
	musicSound.SoundId = "rbxassetid://" .. song.id
	musicSound:Play()
	isPlaying = true
	currentSongLabel.Text = " \u266B " .. song.name
	notify("Now playing: " .. song.name, T.accent)
end

ctrlBtn("\u23EE", function() playSong(currentIdx - 1) end)
ctrlBtn("\u23EF", function()
	if isPlaying then
		musicSound:Pause()
		isPlaying = false
		currentSongLabel.Text = " \u23F8 Paused"
	else
		if musicSound.SoundId ~= "" then
			musicSound:Resume()
			isPlaying = true
			currentSongLabel.Text = " \u266B " .. (playlist[currentIdx] and playlist[currentIdx].name or "")
		else
			playSong(1)
		end
	end
end)
ctrlBtn("\u23F9", function()
	musicSound:Stop()
	isPlaying = false
	currentSongLabel.Text = " \u266B Stopped"
end)
ctrlBtn("\u23ED", function() playSong(currentIdx + 1) end)

conn(musicSound.Ended:Connect(function() playSong(currentIdx + 1) end))

-- Volume
slider(musicTab.page, "Volume", 0, 100, 50, function(v)
	pcall(function() musicSound.Volume = v / 100 end)
end)

-- Add song by ID
header(musicTab.page, "Add Song")
local songIdInput = s("TextBox", {
	Size = UDim2.new(1, -100, 0, 32),
	BackgroundColor3 = T.bg3,
	Text = "",
	PlaceholderText = " Sound ID...",
	TextColor3 = T.text,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	ClearTextOnFocus = false,
	Parent = musicTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = songIdInput })
s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.7, Parent = songIdInput })
local addBtn = s("TextButton", {
	Size = UDim2.new(0, 90, 0, 32),
	Position = UDim2.new(1, -90, 0, 0),
	BackgroundColor3 = T.accent,
	Text = "+ Add",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	AutoButtonColor = false,
	Parent = musicTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = addBtn })
conn(addBtn.MouseButton1Click:Connect(function()
	local id = songIdInput.Text:gsub("%D", "")
	if id == "" then
		notify("Enter a Sound ID!", T.red)
		return
	end
	local name = "Song #" .. (#playlist + 1)
	table.insert(playlist, { id = id, name = name })
	songIdInput.Text = ""
	notify("Added song: " .. name, T.green)
	refreshPlaylist()
	if #playlist == 1 then playSong(1) end
end))

-- Playlist display
header(musicTab.page, "Playlist")
local playlistScroll = s("ScrollingFrame", {
	Size = UDim2.new(1, 0, 0, 120),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = T.dim,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = musicTab.page,
})
s("UIListLayout", { Padding = UDim.new(0, 4), Parent = playlistScroll })

function refreshPlaylist()
	for _, c in ipairs(playlistScroll:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for i, song in ipairs(playlist) do
		local b = s("TextButton", {
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = i == currentIdx and T.bg3 or T.bg2,
			Text = "  " .. i .. ". " .. song.name,
			TextColor3 = i == currentIdx and T.accent or T.text,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = playlistScroll,
		})
		s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = b })
		conn(b.MouseButton1Click:Connect(function() playSong(i) end))
	end
end

button(musicTab.page, "Refresh Playlist", function() refreshPlaylist() notify("Playlist refreshed", T.green) end)
button(musicTab.page, "Clear Playlist", function()
	playlist = {}
	musicSound:Stop()
	isPlaying = false
	currentSongLabel.Text = " \u266B Nothing playing"
	refreshPlaylist()
	notify("Playlist cleared", T.red)
end)

-- Visualizer update
conn(RunService.Heartbeat:Connect(function()
	if killed then return end
	if isPlaying and musicSound.IsPlaying then
		for i, bar in ipairs(vizBars) do
			local h = math.random(5, 42)
			TweenService:Create(bar, TweenInfo.new(0.1), {
				Size = UDim2.new(1/20, -1, 0, h),
				Position = UDim2.new((i-1)/20, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 1),
			}):Play()
		end
	else
		for i, bar in ipairs(vizBars) do
			TweenService:Create(bar, TweenInfo.new(0.2), {
				Size = UDim2.new(1/20, -1, 0, 3),
			}):Play()
		end
	end
end))

-- ============================================================
-- TAB: GAMES
-- ============================================================
header(gamesTab.page, "Clicker Game")
local clickerScore = 0
local clickerLabel = s("TextLabel", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = T.bg2,
	BorderSizePixel = 0,
	Text = "  Score: 0",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	Parent = gamesTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = clickerLabel })
s("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = clickerLabel })
local clickerBtn = s("TextButton", {
	Size = UDim2.new(1, 0, 0, 54),
	BackgroundColor3 = T.accent,
	Text = "CLICK ME!",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	AutoButtonColor = false,
	Parent = gamesTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = clickerBtn })
s("UIGradient", { Color = ColorSequence.new(T.accent, T.accent2), Rotation = 90, Parent = clickerBtn })
conn(clickerBtn.MouseButton1Click:Connect(function()
	clickerScore = clickerScore + 1
	clickerLabel.Text = "  Score: " .. clickerScore
	TweenService:Create(clickerBtn, TweenInfo.new(0.05), {
		Size = UDim2.new(1, -4, 0, 50),
		Position = UDim2.new(0, 2, 0, 2),
	}):Play()
	task.wait(0.05)
	TweenService:Create(clickerBtn, TweenInfo.new(0.05), {
		Size = UDim2.new(1, 0, 0, 54),
		Position = UDim2.new(0, 0, 0, 0),
	}):Play()
end))
button(gamesTab.page, "Reset Clicker", function()
	clickerScore = 0
	clickerLabel.Text = "  Score: 0"
	notify("Clicker reset", T.red)
end)

header(gamesTab.page, "Guess the Number (1-100)")
local guessInput = s("TextBox", {
	Size = UDim2.new(1, -100, 0, 32),
	BackgroundColor3 = T.bg3,
	Text = "",
	PlaceholderText = " Your guess...",
	TextColor3 = T.text,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	ClearTextOnFocus = false,
	Parent = gamesTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = guessInput })
s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.7, Parent = guessInput })
local guessTarget = math.random(1, 100)
local guessAttempts = 0
local guessBtn = s("TextButton", {
	Size = UDim2.new(0, 90, 0, 32),
	Position = UDim2.new(1, -90, 0, 0),
	BackgroundColor3 = T.accent,
	Text = "Guess",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	AutoButtonColor = false,
	Parent = gamesTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = guessBtn })
conn(guessBtn.MouseButton1Click:Connect(function()
	local n = tonumber(guessInput.Text)
	if not n then
		notify("Enter a number!", T.red)
		return
	end
	guessAttempts = guessAttempts + 1
	if n == guessTarget then
		notify("You got it in " .. guessAttempts .. " tries! New game!", T.green)
		guessTarget = math.random(1, 100)
		guessAttempts = 0
	elseif n < guessTarget then
		notify("Higher! (attempt " .. guessAttempts .. ")", T.yellow)
	else
		notify("Lower! (attempt " .. guessAttempts .. ")", T.yellow)
	end
	guessInput.Text = ""
end))
button(gamesTab.page, "New Number", function()
	guessTarget = math.random(1, 100)
	guessAttempts = 0
	notify("New number generated!", T.accent)
end)

header(gamesTab.page, "Roulette")
local rouletteLabel = s("TextLabel", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = T.bg2,
	BorderSizePixel = 0,
	Text = " Spin to win!",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Parent = gamesTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = rouletteLabel })
s("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = rouletteLabel })
button(gamesTab.page, "SPIN ROULETTE", function()
	local prizes = {"100 coins", "50 coins", "Nothing", "200 coins", "10 coins", "JACKPOT!", "Nothing", "75 coins", "500 coins", "Nothing"}
	local result = prizes[math.random(1, #prizes)]
	rouletteLabel.Text = " Spinning..."
	task.spawn(function()
		for i = 1, 12 do
			task.wait(0.07)
			rouletteLabel.Text = " " .. prizes[math.random(1, #prizes)]
		end
		rouletteLabel.Text = " You got: " .. result
		notify("Roulette: " .. result, result == "JACKPOT!" and T.yellow or T.accent)
	end)
end)

header(gamesTab.page, "Reaction Test")
local reactLabel = s("TextLabel", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundColor3 = T.bg2,
	BorderSizePixel = 0,
	Text = " Click Start to begin",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	Parent = gamesTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = reactLabel })
s("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = reactLabel })
local reactBtn = s("TextButton", {
	Size = UDim2.new(1, 0, 0, 50),
	BackgroundColor3 = T.bg3,
	Text = "Start Reaction Test",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	AutoButtonColor = false,
	Parent = gamesTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = reactBtn })
local reactState = "idle"
local reactStart = 0
conn(reactBtn.MouseButton1Click:Connect(function()
	if reactState == "idle" then
		reactState = "waiting"
		reactBtn.Text = "Wait for GREEN..."
		reactBtn.BackgroundColor3 = T.red
		reactLabel.Text = " Get ready..."
		task.wait(math.random(1, 3))
		if killed or reactState ~= "waiting" then return end
		reactState = "go"
		reactBtn.Text = "CLICK NOW!"
		reactBtn.BackgroundColor3 = T.green
		reactStart = tick()
	elseif reactState == "go" then
		local reaction = math.floor((tick() - reactStart) * 1000)
		reactLabel.Text = " Reaction: " .. reaction .. "ms"
		reactBtn.Text = "Try Again"
		reactBtn.BackgroundColor3 = T.bg3
		reactState = "idle"
		notify("Reaction: " .. reaction .. "ms", reaction < 300 and T.green or T.yellow)
	elseif reactState == "waiting" then
		reactLabel.Text = " Too early! Wait for green."
		reactBtn.Text = "Start Reaction Test"
		reactBtn.BackgroundColor3 = T.bg3
		reactState = "idle"
	end
end))

header(gamesTab.page, "Dice Roller")
local diceLabel = s("TextLabel", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = T.bg2,
	BorderSizePixel = 0,
	Text = " Roll the dice!",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	Parent = gamesTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = diceLabel })
s("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = diceLabel })
button(gamesTab.page, "ROLL DICE", function()
	local d1 = math.random(1, 6)
	local d2 = math.random(1, 6)
	diceLabel.Text = " \u2684" .. d1 .. " + \u2684" .. d2 .. " = " .. (d1 + d2)
	notify("Rolled " .. d1 .. " + " .. d2 .. " = " .. (d1 + d2), T.accent)
end)

-- ============================================================
-- TAB: FX
-- ============================================================
header(fxTab.page, "Character Effects")

local activeTrails = {}
local activeParticles = {}
local activeAuras = {}

local function clearTrails()
	for _, t in pairs(activeTrails) do pcall(function() t:Destroy() end) end
	activeTrails = {}
end
local function clearParticles()
	for _, p in pairs(activeParticles) do pcall(function() p:Destroy() end) end
	activeParticles = {}
end
local function clearAuras()
	for _, a in pairs(activeAuras) do pcall(function() a:Destroy() end) end
	activeAuras = {}
end

-- Trail effect
toggle(fxTab.page, "Rainbow Trail", false, function(state)
	if state then
		local hrp = getHRP()
		if not hrp then return end
		local a0 = s("Attachment", { Name = "TrailA0", Parent = hrp })
		local a1 = s("Attachment", { Name = "TrailA1", Position = Vector3.new(0, -3, 0), Parent = hrp })
		local trail = s("Trail", {
			Name = "RainbowTrail",
			Attachment0 = a0,
			Attachment1 = a1,
			Lifetime = 1,
			Color = ColorSequence.new(Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 255)),
			Transparency = NumberSequence.new(0, 1),
			WidthScale = NumberSequence.new(1, 0),
			Parent = hrp,
		})
		activeTrails[trail] = true
		task.spawn(function()
			while trail and trail.Parent and not killed do
				pcall(function()
					trail.Color = ColorSequence.new(
						Color3.fromHSV((tick() % 5) / 5, 1, 1),
						Color3.fromHSV(((tick() % 5) / 5 + 0.5) % 1, 1, 1)
					)
				end)
				task.wait(0.05)
			end
		end)
	else
		clearTrails()
	end
end)

-- Fire particles
toggle(fxTab.page, "Fire Aura", false, function(state)
	if state then
		local hrp = getHRP()
		if not hrp then return end
		local pe = s("ParticleEmitter", {
			Name = "FireAura",
			Texture = "rbxassetid://243660364",
			Rate = 50,
			Lifetime = NumberRange.new(0.5, 1),
			Speed = NumberRange.new(2, 5),
			SpreadAngle = Vector2.new(45, 45),
			Color = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 200, 0)),
			Size = NumberSequence.new(1, 0),
			Transparency = NumberSequence.new(0, 1),
			Parent = hrp,
		})
		activeParticles[pe] = true
	else
		clearParticles()
	end
end)

-- Sparkle particles
toggle(fxTab.page, "Sparkles", false, function(state)
	if state then
		local hrp = getHRP()
		if not hrp then return end
		local pe = s("ParticleEmitter", {
			Name = "SparkleFX",
			Texture = "rbxassetid://243660364",
			Rate = 30,
			Lifetime = NumberRange.new(0.3, 0.8),
			Speed = NumberRange.new(1, 3),
			SpreadAngle = Vector2.new(180, 180),
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 255)),
			Size = NumberSequence.new(0.5, 0),
			Transparency = NumberSequence.new(0, 1),
			Parent = hrp,
		})
		activeParticles[pe] = true
	else
		clearParticles()
	end
end)

-- Glow ring aura
toggle(fxTab.page, "Glow Ring", false, function(state)
	if state then
		local hrp = getHRP()
		if not hrp then return end
		local ring = s("Part", {
			Name = "GlowRing",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.2, 6, 6),
			CFrame = hrp.CFrame * CFrame.new(0, -3, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Anchored = true,
			CanCollide = false,
			Transparency = 0.5,
			Material = Enum.Material.Neon,
			Color = T.accent,
			Parent = Workspace,
		})
		activeAuras[ring] = true
		task.spawn(function()
			while ring and ring.Parent and not killed do
				pcall(function()
					local h = getHRP()
					if h then
						ring.CFrame = h.CFrame * CFrame.new(0, -3, 0) * CFrame.Angles(0, 0, math.rad(90))
						ring.Color = Color3.fromHSV((tick() * 0.3) % 1, 0.7, 1)
					end
				end)
				task.wait(0.03)
			end
		end)
	else
		clearAuras()
	end
end)

-- Rainbow character
toggle(fxTab.page, "Rainbow Body", false, function(state)
	if state then
		task.spawn(function()
			while not killed do
				local char = player.Character
				if char then
					local hue = (tick() * 0.5) % 1
					local color = Color3.fromHSV(hue, 1, 1)
					for _, p in ipairs(char:GetDescendants()) do
						if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
							pcall(function() p.Color = color end)
						end
					end
				end
				task.wait(0.05)
			end
		end)
	else
		local char = player.Character
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
					pcall(function() p.BrickColor = BrickColor.new("Medium stone grey") end)
				end
			end
		end
	end
end)

-- Neon body
toggle(fxTab.page, "Neon Body", false, function(state)
	local char = player.Character
	if not char then return end
	if state then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				pcall(function() p.Material = Enum.Material.Neon end)
			end
		end
	else
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				pcall(function() p.Material = Enum.Material.Plastic end)
			end
		end
	end
end)

-- Force field
toggle(fxTab.page, "Force Field", false, function(state)
	local char = player.Character
	if not char then return end
	if state then
		s("ForceField", { Name = "PHForceField", Parent = char })
	else
		local ff = char:FindFirstChild("PHForceField")
		if ff then pcall(function() ff:Destroy() end) end
	end
end)

-- Ghost mode (transparency)
toggle(fxTab.page, "Ghost Mode", false, function(state)
	local char = player.Character
	if not char then return end
	if state then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				pcall(function() p.Transparency = 0.5 end)
			end
		end
	else
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				pcall(function() p.Transparency = 0 end)
			end
		end
	end
end)

header(fxTab.page, "Lighting FX")
toggle(fxTab.page, "Disco Lights", false, function(state)
	if state then
		task.spawn(function()
			while not killed do
				pcall(function()
					Lighting.Ambient = Color3.fromHSV(math.random(), 1, 1)
					Lighting.OutdoorAmbient = Color3.fromHSV(math.random(), 1, 1)
				end)
				task.wait(0.1)
			end
		end)
	else
		pcall(function()
			Lighting.Ambient = Color3.fromRGB(128, 128, 128)
			Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		end)
	end
end)

toggle(fxTab.page, "Night Vision", false, function(state)
	if state then
		s("ColorCorrectionEffect", {
			Name = "PHNightVision",
			Brightness = 0.2,
			Contrast = 0.3,
			TintColor = Color3.fromRGB(100, 255, 100),
			Parent = Lighting,
		})
		pcall(function() Lighting.Brightness = 2 end)
	else
		local nv = Lighting:FindFirstChild("PHNightVision")
		if nv then pcall(function() nv:Destroy() end) end
		pcall(function() Lighting.Brightness = 2 end)
	end
end)

toggle(fxTab.page, "Fog Mode", false, function(state)
	if state then
		pcall(function()
			Lighting.FogEnd = 100
			Lighting.FogColor = T.accent
		end)
	else
		pcall(function()
			Lighting.FogEnd = 100000
			Lighting.FogColor = Color3.fromRGB(192, 192, 192)
		end)
	end
end)

button(fxTab.page, "Clear All FX", function()
	clearTrails()
	clearParticles()
	clearAuras()
	local char = player.Character
	if char then
		local ff = char:FindFirstChild("PHForceField")
		if ff then pcall(function() ff:Destroy() end) end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				pcall(function()
					p.Material = Enum.Material.Plastic
					p.BrickColor = BrickColor.new("Medium stone grey")
					p.Transparency = 0
				end)
			end
		end
	end
	pcall(function()
		Lighting.Ambient = Color3.fromRGB(128, 128, 128)
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		Lighting.FogEnd = 100000
		Lighting.FogColor = Color3.fromRGB(192, 192, 192)
	end)
	local nv = Lighting:FindFirstChild("PHNightVision")
	if nv then pcall(function() nv:Destroy() end) end
	notify("All FX cleared!", T.red)
end)

-- ============================================================
-- TAB: CHAT
-- ============================================================
header(chatTab.page, "Quick Phrases")

local function sendChat(msg)
	pcall(function()
		local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatRemoteEvents")
		if chatEvents then
			local sayMsg = chatEvents:FindFirstChild("SayMessageRequest")
			if sayMsg then
				sayMsg:FireServer(msg, "All")
				return
			end
		end
		if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			local window = TextChatService:FindFirstChild("ChatWindowApp")
			if window then
				local bar = window:FindFirstChild("ChatInputBar")
				if bar then
					bar:Send(msg)
					return
				end
			end
		end
		notify("Could not send chat in this game", T.red)
	end)
end

local quickPhrases = {
	"Hello!", "GG!", "Nice!", "LOL", "BRB", "GTG", "Yes", "No",
	"Thanks!", "Sorry", "Wanna be friends?", "Follow me!",
	"Good game everyone!", "Let's play again!", "That was fun!",
}

for _, phrase in ipairs(quickPhrases) do
	button(chatTab.page, phrase, function()
		sendChat(phrase)
		notify("Sent: " .. phrase, T.green)
	end)
end

header(chatTab.page, "Custom Message")
local customChatInput = s("TextBox", {
	Size = UDim2.new(1, -100, 0, 32),
	BackgroundColor3 = T.bg3,
	Text = "",
	PlaceholderText = " Type message...",
	TextColor3 = T.text,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	ClearTextOnFocus = false,
	Parent = chatTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = customChatInput })
s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.7, Parent = customChatInput })
local sendCustomBtn = s("TextButton", {
	Size = UDim2.new(0, 90, 0, 32),
	Position = UDim2.new(1, -90, 0, 0),
	BackgroundColor3 = T.accent,
	Text = "Send",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	AutoButtonColor = false,
	Parent = chatTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = sendCustomBtn })
conn(sendCustomBtn.MouseButton1Click:Connect(function()
	if customChatInput.Text ~= "" then
		sendChat(customChatInput.Text)
		notify("Sent: " .. customChatInput.Text, T.green)
		customChatInput.Text = ""
	end
end))

header(chatTab.page, "Auto Messages")
local autoMsgRunning = false
toggle(chatTab.page, "Auto GG (every 60s)", false, function(state)
	autoMsgRunning = state
	if state then
		task.spawn(function()
			while autoMsgRunning and not killed do
				sendChat("GG!")
				task.wait(60)
			end
		end)
		notify("Auto GG started", T.green)
	else
		notify("Auto GG stopped", T.red)
	end
end)

local autoMsgInput = s("TextBox", {
	Size = UDim2.new(1, -100, 0, 32),
	BackgroundColor3 = T.bg3,
	Text = "",
	PlaceholderText = " Custom auto message...",
	TextColor3 = T.text,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	ClearTextOnFocus = false,
	Parent = chatTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = autoMsgInput })
s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.7, Parent = autoMsgInput })
local autoCustomRunning = false
local autoCustomBtn = s("TextButton", {
	Size = UDim2.new(0, 90, 0, 32),
	Position = UDim2.new(1, -90, 0, 0),
	BackgroundColor3 = T.accent,
	Text = "Start",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	AutoButtonColor = false,
	Parent = chatTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = autoCustomBtn })
conn(autoCustomBtn.MouseButton1Click:Connect(function()
	if autoCustomRunning then
		autoCustomRunning = false
		autoCustomBtn.Text = "Start"
		autoCustomBtn.BackgroundColor3 = T.accent
		notify("Auto message stopped", T.red)
	else
		if autoMsgInput.Text ~= "" then
			autoCustomRunning = true
			autoCustomBtn.Text = "Stop"
			autoCustomBtn.BackgroundColor3 = T.red
			local msg = autoMsgInput.Text
			notify("Auto message started: " .. msg, T.green)
			task.spawn(function()
				while autoCustomRunning and not killed do
					sendChat(msg)
					task.wait(45)
				end
			end)
		else
			notify("Enter a message first!", T.red)
		end
	end
end))

-- ============================================================
-- TAB: UTIL
-- ============================================================
header(utilTab.page, "Camera")
slider(utilTab.page, "Field of View", 30, 120, 70, function(v)
	local cam = Workspace.CurrentCamera
	if cam then pcall(function() cam.FieldOfView = v end) end
end)
button(utilTab.page, "Reset FOV", function()
	local cam = Workspace.CurrentCamera
	if cam then
		pcall(function() cam.FieldOfView = 70 end)
		notify("FOV reset to 70", T.green)
	end
end)

toggle(utilTab.page, "Free Camera", false, function(state)
	local cam = Workspace.CurrentCamera
	if not cam then return end
	if state then
		pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
	else
		pcall(function() cam.CameraType = Enum.CameraType.Custom end)
	end
end)

header(utilTab.page, "Movement")
slider(utilTab.page, "Walk Speed", 1, 500, 16, function(v)
	local h = getHum()
	if h then pcall(function() h.WalkSpeed = v end) end
end)
slider(utilTab.page, "Jump Power", 0, 500, 50, function(v)
	local h = getHum()
	if h then pcall(function() h.UseJumpPower = true h.JumpPower = v end) end
end)
slider(utilTab.page, "Gravity", 0, 200, 196.2, function(v)
	pcall(function() Workspace.Gravity = v end)
end)
button(utilTab.page, "Reset Movement", function()
	local h = getHum()
	if h then
		pcall(function() h.WalkSpeed = 16 h.JumpPower = 50 h.UseJumpPower = true end)
	end
	pcall(function() Workspace.Gravity = 196.2 end)
	notify("Movement reset", T.green)
end)

toggle(utilTab.page, "Infinite Jump", false, function(state)
	if state then
		conn(UserInputService.JumpRequest:Connect(function()
			if not killed then
				local h = getHum()
				if h then
					pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
				end
			end
		end))
	end
end)

toggle(utilTab.page, "Noclip", false, function(state)
	if state then
		conn(RunService.Stepped:Connect(function()
			if killed then return end
			local char = player.Character
			if char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
						pcall(function() p.CanCollide = false end)
					end
				end
			end
		end))
	else
		local char = player.Character
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
					pcall(function() p.CanCollide = true end)
				end
			end
		end
	end
end)

header(utilTab.page, "Teleport")
button(utilTab.page, "TP Up 100", function()
	local hrp = getHRP()
	if hrp then
		pcall(function() hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 100, 0)) end)
		notify("TP'd up 100", T.accent)
	end
end)
button(utilTab.page, "TP Forward 50", function()
	local hrp = getHRP()
	local cam = Workspace.CurrentCamera
	if hrp and cam then
		pcall(function() hrp.CFrame = CFrame.new(hrp.Position + cam.CFrame.LookVector * 50) end)
		notify("TP'd forward", T.accent)
	end
end)
button(utilTab.page, "TP to Spawn", function()
	local hrp = getHRP()
	if hrp then
		local spawn = Workspace:FindFirstChild("SpawnLocation")
		if spawn then
			pcall(function() hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0) end)
			notify("TP'd to spawn", T.accent)
		else
			notify("No SpawnLocation found", T.red)
		end
	end
end)

local tpInput = s("TextBox", {
	Size = UDim2.new(1, -100, 0, 32),
	BackgroundColor3 = T.bg3,
	Text = "",
	PlaceholderText = " x,y,z (e.g. 100,50,200)",
	TextColor3 = T.text,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	ClearTextOnFocus = false,
	Parent = utilTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tpInput })
s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.7, Parent = tpInput })
local tpBtn = s("TextButton", {
	Size = UDim2.new(0, 90, 0, 32),
	Position = UDim2.new(1, -90, 0, 0),
	BackgroundColor3 = T.accent,
	Text = "TP",
	TextColor3 = T.text,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	AutoButtonColor = false,
	Parent = utilTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tpBtn })
conn(tpBtn.MouseButton1Click:Connect(function()
	local coords = {}
	for n in tpInput.Text:gmatch("%-?%d+%.?%d*") do
		table.insert(coords, tonumber(n))
	end
	if #coords >= 3 then
		local hrp = getHRP()
		if hrp then
			pcall(function() hrp.CFrame = CFrame.new(coords[1], coords[2], coords[3]) end)
			notify("TP'd to " .. coords[1] .. "," .. coords[2] .. "," .. coords[3], T.accent)
		end
	else
		notify("Enter x,y,z coordinates", T.red)
	end
end))

header(utilTab.page, "Player List")
local playerListScroll = s("ScrollingFrame", {
	Size = UDim2.new(1, 0, 0, 120),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = T.dim,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = utilTab.page,
})
s("UIListLayout", { Padding = UDim.new(0, 4), Parent = playerListScroll })

local function refreshPlayerList()
	for _, c in ipairs(playerListScroll:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local b = s("TextButton", {
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = T.bg2,
			Text = " " .. p.Name,
			TextColor3 = T.text,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = playerListScroll,
		})
		s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = b })
		conn(b.MouseButton1Click:Connect(function()
			local hrp = getHRP()
			local targetChar = p.Character
			local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
			if hrp and targetHrp then
				pcall(function()
					hrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0)
				end)
				notify("TP'd to " .. p.Name, T.accent)
			end
		end))
	end
end
button(utilTab.page, "Refresh Player List", function() refreshPlayerList() notify("Player list refreshed", T.green) end)
refreshPlayerList()

header(utilTab.page, "Server")
button(utilTab.page, "Rejoin Server", function()
	pcall(function()
		if game.JobId and game.JobId ~= "" then
			game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
		else
			game:GetService("TeleportService"):Teleport(game.PlaceId, player)
		end
	end)
end)
button(utilTab.page, "Server Hop", function()
	pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, player) end)
end)
button(utilTab.page, "Leave Game", function()
	pcall(function() player:Kick("Left via PlayerHub") end)
end)

-- ============================================================
-- TAB: SETTINGS
-- ============================================================
header(settingsTab.page, "Display")
slider(settingsTab.page, "Text Size", 8, 20, 12, function(v)
	for _, c in ipairs(gui:GetDescendants()) do
		if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") then
			pcall(function() c.TextSize = v end)
		end
	end
end)
slider(settingsTab.page, "Panel Opacity", 0, 100, 85, function(v)
	pcall(function() frame.BackgroundTransparency = 1 - (v / 100) end)
end)

header(settingsTab.page, "Accent Color")
local function updateAccent()
	pcall(function() frame:FindFirstChild("UIStroke").Color = T.accent end)
	for _, t in ipairs(tabs) do
		if t.page.Visible then
			pcall(function() t.button.BackgroundColor3 = T.accent end)
		end
	end
end
slider(settingsTab.page, "Accent R", 0, 255, 100, function(v)
	T.accent = Color3.fromRGB(v, math.floor(T.accent.G * 255), math.floor(T.accent.B * 255))
	updateAccent()
end)
slider(settingsTab.page, "Accent G", 0, 255, 200, function(v)
	T.accent = Color3.fromRGB(math.floor(T.accent.R * 255), v, math.floor(T.accent.B * 255))
	updateAccent()
end)
slider(settingsTab.page, "Accent B", 0, 255, 255, function(v)
	T.accent = Color3.fromRGB(math.floor(T.accent.R * 255), math.floor(T.accent.G * 255), v)
	updateAccent()
end)

header(settingsTab.page, "Keybind")
local keybindLabel = s("TextLabel", {
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundColor3 = T.bg2,
	BorderSizePixel = 0,
	Text = " Toggle key: J",
	TextColor3 = T.text,
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = settingsTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = keybindLabel })
s("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = keybindLabel })

header(settingsTab.page, "Actions")
button(settingsTab.page, "Reset All Features", function()
	clearTrails()
	clearParticles()
	clearAuras()
	local char = player.Character
	if char then
		local ff = char:FindFirstChild("PHForceField")
		if ff then pcall(function() ff:Destroy() end) end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				pcall(function()
					p.Material = Enum.Material.Plastic
					p.BrickColor = BrickColor.new("Medium stone grey")
					p.Transparency = 0
				end)
			end
		end
	end
	pcall(function()
		Lighting.Ambient = Color3.fromRGB(128, 128, 128)
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		Lighting.Brightness = 2
		Lighting.FogEnd = 100000
		Lighting.FogColor = Color3.fromRGB(192, 192, 192)
	end)
	local nv = Lighting:FindFirstChild("PHNightVision")
	if nv then pcall(function() nv:Destroy() end) end
	musicSound:Stop()
	isPlaying = false
	currentSongLabel.Text = " \u266B Nothing playing"
	pcall(function() Workspace.Gravity = 196.2 end)
	local cam = Workspace.CurrentCamera
	if cam then
		pcall(function()
			cam.FieldOfView = 70
			cam.CameraType = Enum.CameraType.Custom
		end)
	end
	notify("Everything reset!", T.red)
end)

local killBtn = s("TextButton", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = Color3.fromRGB(80, 20, 20),
	Text = "KILL SCRIPT",
	TextColor3 = Color3.fromRGB(255, 100, 100),
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	Parent = settingsTab.page,
})
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = killBtn })
s("UIStroke", { Color = T.red, Thickness = 1.5, Parent = killBtn })
conn(killBtn.MouseButton1Click:Connect(function()
	killed = true
	for _, c in ipairs(allConnections) do
		pcall(function() c:Disconnect() end)
	end
	pcall(function() if gui then gui:Destroy() end end)
	pcall(function() if nGui then nGui:Destroy() end end)
	pcall(function() if tGui then tGui:Destroy() end end)
	pcall(function() musicSound:Destroy() end)
end))
-- PlayerHub v1 — Massive Player Utility GUI
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local killed = false
local allConnections = {}

-- Safe parent
local safeParent
pcall(function() safeParent = game:GetService("CoreGui") end)
if not safeParent then safeParent = player:WaitForChild("PlayerGui") end

-- Theme
local T = {
	bg = Color3.fromRGB(12, 12, 18),
	bg2 = Color3.fromRGB(24, 24, 34),
	bg3 = Color3.fromRGB(38, 38, 52),
	accent = Color3.fromRGB(100, 200, 255),
	accent2 = Color3.fromRGB(180, 100, 255),
	text = Color3.fromRGB(240, 240, 245),
	dim = Color3.fromRGB(140, 140, 160),
	green = Color3.fromRGB(80, 200, 120),
	red = Color3.fromRGB(230, 70, 70),
	yellow = Color3.fromRGB(255, 210, 80),
	orange = Color3.fromRGB(255, 150, 60),
}

local function s(class, props)
	local obj
	local ok = pcall(function() obj = Instance.new(class) end)
	if not ok or not obj then return nil end
	if props then for k, v in pairs(props) do pcall(function() obj[k] = v end) end end
	return obj
end

local function conn(c)
	if killed then pcall(function() c:Disconnect() end) return nil end
	table.insert(allConnections, c)
	return c
end

local function getHum() local c = player.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP() local c = player.Character return c and c:FindFirstChild("HumanoidRootPart") end

-- Notification system
local nGui = s("ScreenGui", { Name = "PHN_" .. tostring(math.random(10000, 99999)), ResetOnSpawn = false, IgnoreGuiInset = true, Parent = safeParent })
local nContainer = s("Frame", { Name = "C", Size = UDim2.new(0.9, 0, 1, -20), Position = UDim2.new(0.5, 0, 0, 10), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, Parent = nGui })
s("UISizeConstraint", { MaxSize = Vector2.new(320, math.huge), Parent = nContainer })
s("UIListLayout", { Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Top, Parent = nContainer })

local function notify(text, color)
	if killed then return end
	color = color or T.accent
	local n = s("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = T.bg2, BorderSizePixel = 0, Parent = nContainer })
	s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = n })
	s("UIStroke", { Color = color, Thickness = 1, Transparency = 0.5, Parent = n })
	local bar = s("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = n })
	s("UICorner", { CornerRadius = UDim.new(0, 2), Parent = bar })
	local lbl = s("TextLabel", { Size = UDim2.new(1, -16, 1, -12), Position = UDim2.fromOffset(12, 6), BackgroundTransparency = 1, Text = text, TextColor3 = T.text, Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = n })
	n.BackgroundTransparency = 1 bar.BackgroundTransparency = 1 lbl.TextTransparency = 1
	local st = n:FindFirstChild("UIStroke") if st then st.Transparency = 1 end
	TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 0 }):Play()
	TweenService:Create(bar, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(lbl, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	if st then TweenService:Create(st, TweenInfo.new(0.3), { Transparency = 0.5 }):Play() end
	task.delay(3, function()
		if killed then return end
		TweenService:Create(n, TweenInfo.new(0.3), { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }):Play()
		TweenService:Create(bar, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(lbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		if st then TweenService:Create(st, TweenInfo.new(0.3), { Transparency = 1 }):Play() end
		task.wait(0.35) if n and n.Parent then n:Destroy() end
	end)
end

-- Main GUI
local gui = s("ScreenGui", { Name = "PHM_" .. tostring(math.random(10000, 99999)), ResetOnSpawn = false, IgnoreGuiInset = true, Enabled = false, Parent = safeParent })

local frame = s("Frame", { Size = UDim2.fromOffset(320, 440), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.bg, BorderSizePixel = 0, Parent = gui })
s("UICorner", { CornerRadius = UDim.new(0, 12), Parent = frame })
s("UIStroke", { Color = T.accent, Thickness = 1.5, Transparency = 0.4, Parent = frame })
s("UIGradient", { Color = ColorSequence.new(T.bg, Color3.fromRGB(18, 14, 26)), Rotation = 90, Parent = frame })

-- Title bar
local titleBar = s("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = frame })
s("TextLabel", { Size = UDim2.new(1, -80, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = "PlayerHub", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = titleBar })
local closeBtn = s("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -35, 0.5, -15), BackgroundColor3 = T.red, Text = "X", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 13, Parent = titleBar })
s("UICorner", { CornerRadius = UDim.new(1, 0), Parent = closeBtn })

-- Tab bar (horizontal scroll)
local tabBar = s("ScrollingFrame", { Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 42), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X, Parent = frame })
s("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = tabBar })

-- Content area
local content = s("Frame", { Size = UDim2.new(1, -16, 1, -82), Position = UDim2.fromOffset(8, 76), BackgroundTransparency = 1, Parent = frame })

-- Toggle button
local tGui = s("ScreenGui", { Name = "PHT_" .. tostring(math.random(10000, 99999)), ResetOnSpawn = false, IgnoreGuiInset = true, Parent = safeParent })
local tBtn = s("TextButton", { Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0, 8, 0.5, -22), BackgroundColor3 = T.accent, Text = "PH", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false, Parent = tGui })
s("UICorner", { CornerRadius = UDim.new(1, 0), Parent = tBtn })
s("UIGradient", { Color = ColorSequence.new(T.accent, T.accent2), Rotation = 90, Parent = tBtn })
s("UIStroke", { Color = Color3.new(1,1,1), Thickness = 1, Transparency = 0.6, Parent = tBtn })

-- State
local tabs = {}
local animating = false
local dragging = false local dragStart local startPos

-- Create tab
local function createTab(name)
	local btn = s("TextButton", { Size = UDim2.new(0, 58, 1, 0), BackgroundColor3 = T.bg2, Text = name, TextColor3 = T.dim, Font = Enum.Font.GothamMedium, TextSize = 10, AutoButtonColor = false, Parent = tabBar })
	s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
	local page = s("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.dim, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = content })
	s("UIListLayout", { Padding = UDim.new(0, 6), Parent = page })
	local td = { button = btn, page = page, name = name }
	table.insert(tabs, td)
	conn(btn.MouseButton1Click:Connect(function()
		for _, t in ipairs(tabs) do if t == td then t.page.Visible = true t.button.BackgroundColor3 = T.accent t.button.TextColor3 = T.text else t.page.Visible = false t.button.BackgroundColor3 = T.bg2 t.button.TextColor3 = T.dim end end
	end))
	return td
end

-- UI helpers
local function toggle(parent, label, default, cb)
	local row = s("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.bg2, BorderSizePixel = 0, Parent = parent })
	s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
	s("TextLabel", { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = label, TextColor3 = T.text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	local bg = s("Frame", { Size = UDim2.fromOffset(44, 24), Position = UDim2.new(1, -50, 0.5, -12), BackgroundColor3 = default and T.green or Color3.fromRGB(60,60,70), BorderSizePixel = 0, Parent = row })
	s("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bg })
	local knob = s("Frame", { Size = UDim2.fromOffset(18, 18), Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Parent = bg })
	s("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	local st = default
	local b = s("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", Parent = row })
	conn(b.MouseButton1Click:Connect(function() st = not st TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundColor3 = st and T.green or Color3.fromRGB(60,60,70) }):Play() TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = st and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9) }):Play() pcall(cb, st) end))
	return row
end

local function button(parent, label, cb)
	local b = s("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.accent, Text = label, TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, Parent = parent })
	s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = b })
	s("UIGradient", { Color = ColorSequence.new(T.accent, T.accent2), Rotation = 90, Parent = b })
	local d = false
	conn(b.MouseButton1Click:Connect(function() if d then return end d = true TweenService:Create(b, TweenInfo.new(0.08), { Size = UDim2.new(1,-4,0,32), Position = UDim2.new(0,2,0,2) }):Play() task.wait(0.08) TweenService:Create(b, TweenInfo.new(0.08), { Size = UDim2.new(1,0,0,36), Position = UDim2.new(0,0,0,0) }):Play() pcall(cb) d = false end))
	return b
end

local function slider(parent, label, min, max, default, cb)
	local row = s("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = T.bg2, BorderSizePixel = 0, Parent = parent })
	s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
	local lbl = s("TextLabel", { Size = UDim2.new(1, -12, 0, 18), Position = UDim2.fromOffset(8, 4), BackgroundTransparency = 1, Text = label .. ": " .. tostring(default), TextColor3 = T.text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	local input = s("TextBox", { Size = UDim2.new(1, -16, 0, 28), Position = UDim2.fromOffset(8, 24), BackgroundColor3 = T.bg3, Text = tostring(default), TextColor3 = T.text, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false, Parent = row })
	s("UICorner", { CornerRadius = UDim.new(0, 4), Parent = input })
	s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.7, Parent = input })
	conn(input.FocusLost:Connect(function() local v = tonumber(input.Text) if v then v = math.clamp(v, min, max) input.Text = tostring(v) lbl.Text = label .. ": " .. tostring(v) pcall(cb, v) else input.Text = tostring(default) end end))
	return row
end

local function header(parent, text)
	local h = s("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text, TextColor3 = T.accent, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent })
	s("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.accent, BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = h })
	return h
end

-- Create all tabs
local statsTab = createTab("Stats")
local musicTab = createTab("Music")
local gamesTab = createTab("Games")
local fxTab = createTab("FX")
local chatTab = createTab("Chat")
local utilTab = createTab("Util")
local settingsTab = createTab("Set")

-- Open/close
local function openPanel()
	if animating or killed then return end animating = true gui.Enabled = true tBtn.Visible = false
	frame.Size = UDim2.fromOffset(0, 0)
	local tw = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(320, 440) }) tw:Play()
	conn(tw.Completed:Connect(function() animating = false end))
end
local function closePanel()
	if animating or killed then return end animating = true
	local tw = TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.fromOffset(0, 0) }) tw:Play()
	conn(tw.Completed:Connect(function() if killed then return end gui.Enabled = false tBtn.Visible = true animating = false end))
end
conn(closeBtn.MouseButton1Click:Connect(function() closePanel() end))
conn(tBtn.MouseButton1Click:Connect(function() if gui.Enabled then closePanel() else openPanel() end end))
conn(UserInputService.InputBegan:Connect(function(input, gP) if gP or killed then return end if input.KeyCode == Enum.KeyCode.J then if gui.Enabled then closePanel() else openPanel() end end end))

-- Dragging
conn(titleBar.InputBegan:Connect(function(input) if killed then return end if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true dragStart = input.Position startPos = frame.Position end end))
conn(titleBar.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end))
conn(UserInputService.InputChanged:Connect(function(input) if killed then return end if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - dragStart pcall(function() frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end) end end))

-- Default tab
if #tabs > 0 then tabs[1].button.BackgroundColor3 = T.accent tabs[1].button.TextColor3 = T.text tabs[1].page.Visible = true end

notify("PlayerHub loaded! Press J or tap PH", T.green)

-- ============================================================
-- TAB: STATS
-- ============================================================
header(statsTab.page, "Live Stats")

local statLabels = {}
local function createStatRow(parent, labelText)
	local row = s("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.bg2, BorderSizePixel = 0, Parent = parent })
	s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
	s("TextLabel", { Size = UDim2.new(0.5, -12, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = T.dim, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	local val = s("TextLabel", { Size = UDim2.new(0.5, -12, 1, 0), Position = UDim2.new(0.5, 2, 0, 0), BackgroundTransparency = 1, Text = "...", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
	return val
end

statLabels.fps = createStatRow(statsTab.page, "FPS")
statLabels.ping = createStatRow(statsTab.page, "Ping (ms)")
statLabels.playtime = createStatRow(statsTab.page, "Playtime")
statLabels.players = createStatRow(statsTab.page, "Players Online")
statLabels.serverTime = createStatRow(statsTab.page, "Server Time")
statLabels.jobId = createStatRow(statsTab.page, "Job ID")
statLabels.placeId = createStatRow(statsTab.page, "Place ID")
statLabels.gravity = createStatRow(statsTab.page, "Gravity")
statLabels.fps2 = createStatRow(statsTab.page, "Avg FPS")
statLabels.memory = createStatRow(statsTab.page, "Memory (MB)")

local startTime = tick()
local fpsAccum = 0 local fpsCount = 0 local fpsAvg = 0
local lastUpdate = tick()

conn(RunService.Heartbeat:Connect(function()
	if killed then return end
	local now = tick()
	local dt = now - lastUpdate
	if dt > 0 then
		local fps = 1 / dt
		fpsAccum = fpsAccum + fps fpsCount = fpsCount + 1
		if fpsCount >= 30 then fpsAvg = fpsAccum / fpsCount fpsAccum = 0 fpsCount = 0 end
	end
	lastUpdate = now
end))

task.spawn(function()
	while not killed do
		task.wait(0.5)
		if not killed then
			local currentFps = fpsAvg > 0 and math.floor(fpsAvg) or 0
			local playtimeSec = math.floor(tick() - startTime)
			local ph = math.floor(playtimeSec / 3600) local pm = math.floor((playtimeSec % 3600) / 60) local ps = playtimeSec % 60
			local playtimeStr = string.format("%02d:%02d:%02d", ph, pm, ps)
			local pingMs = math.floor(Stats.PerformanceStats.PingMs.Value) if Stats and Stats.PerformanceStats and Stats.PerformanceStats.PingMs else 0
			local memMb = 0 pcall(function() memMb = math.floor(Stats:GetTotalMemoryUsageMb()) end)
			pcall(function() statLabels.fps.Text = tostring(currentFps) end)
			pcall(function() statLabels.fps2.Text = tostring(currentFps) end)
			pcall(function() statLabels.ping.Text = tostring(pingMs) end)
			pcall(function() statLabels.playtime.Text = playtimeStr end)
			pcall(function() statLabels.players.Text = tostring(#Players:GetPlayers()) end)
			pcall(function() statLabels.serverTime.Text = os.date("%H:%M:%S") end)
			pcall(function() statLabels.jobId.Text = string.sub(tostring(game.JobId or "N/A"), 1, 12) .. "..." end)
			pcall(function() statLabels.placeId.Text = tostring(game.PlaceId) end)
			pcall(function() statLabels.gravity.Text = string.format("%.1f", Workspace.Gravity) end)
			pcall(function() statLabels.memory.Text = tostring(memMb) end)
		end
	end
end)

header(statsTab.page, "Quick Info")
button(statsTab.page, "Copy Job ID", function() if setclipboard then pcall(setclipboard, tostring(game.JobId or "")) notify("Job ID copied!", T.green) else notify(tostring(game.JobId or "N/A"), T.accent) end end)
button(statsTab.page, "Copy Place ID", function() if setclipboard then pcall(setclipboard, tostring(game.PlaceId)) notify("Place ID copied!", T.green) else notify(tostring(game.PlaceId), T.accent) end end)
button(statsTab.page, "Copy Server Time", function() if setclipboard then pcall(setclipboard, os.date("%Y-%m-%d %H:%M:%S")) notify("Time copied!", T.green) else notify(os.date("%H:%M:%S"), T.accent) end end)

-- ============================================================
-- TAB: MUSIC
-- ============================================================
header(musicTab.page, "Now Playing")

local currentSongLabel = s("TextLabel", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.bg2, BorderSizePixel = 0, Text = " Nothing playing", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = musicTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = currentSongLabel })
s("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = currentSongLabel })

-- Visualizer bars
local vizFrame = s("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = T.bg2, BorderSizePixel = 0, Parent = musicTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = vizFrame })
s("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = vizFrame })
local vizBars = {}
for i = 1, 16 do
	local bar = s("Frame", { Size = UDim2.new(1/16, -2, 0, 5), Position = UDim2.new((i-1)/16, 0, 1, 0), AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = T.accent, BorderSizePixel = 0, Parent = vizFrame })
	s("UICorner", { CornerRadius = UDim.new(0, 2), Parent = bar })
	table.insert(vizBars, bar)
end

-- Sound object
local musicSound = s("Sound", { Name = "PHMusic", Volume = 0.5, Parent = SoundService })
local playlist = {}
local currentIdx = 1
local isPlaying = false

-- Controls
local controlsRow = s("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = musicTab.page })
s("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = controlsRow })

local function ctrlBtn(text, cb)
	local b = s("TextButton", { Size = UDim2.new(0, 40, 1, 0), BackgroundColor3 = T.bg3, Text = text, TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 16, AutoButtonColor = false, Parent = controlsRow })
	s("UICorner", { CornerRadius = UDim.new(1, 0), Parent = b })
	conn(b.MouseButton1Click:Connect(function() pcall(cb) end))
	return b
end

local function playSong(idx)
	if #playlist == 0 then notify("Playlist empty! Add songs below", T.yellow) return end
	idx = ((idx - 1) % #playlist) + 1
	currentIdx = idx
	local song = playlist[idx]
	musicSound:Stop()
	musicSound.SoundId = "rbxassetid://" .. song.id
	musicSound:Play()
	isPlaying = true
	currentSongLabel.Text = " ♪ " .. song.name
	notify("Now playing: " .. song.name, T.accent)
end

ctrlBtn("⏮", function() playSong(currentIdx - 1) end)
ctrlBtn("⏯", function() if isPlaying then musicSound:Pause() isPlaying = false currentSongLabel.Text = " Paused" else if musicSound.SoundId ~= "" then musicSound:Resume() isPlaying = true currentSongLabel.Text = " ♪ " .. (playlist[currentIdx] and playlist[currentIdx].name or "") else playSong(1) end end end)
ctrlBtn("⏹", function() musicSound:Stop() isPlaying = false currentSongLabel.Text = " Stopped" end)
ctrlBtn("⏭", function() playSong(currentIdx + 1) end)

conn(musicSound.Ended:Connect(function() playSong(currentIdx + 1) end))

-- Volume
slider(musicTab.page, "Volume", 0, 100, 50, function(v) pcall(function() musicSound.Volume = v / 100 end) end)

-- Add song by ID
header(musicTab.page, "Add Song")
local songIdInput = s("TextBox", { Size = UDim2.new(1, -100, 0, 32), BackgroundColor3 = T.bg3, Text = "", PlaceholderText = " Sound ID...", TextColor3 = T.text, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false, Parent = musicTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = songIdInput })
s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.7, Parent = songIdInput })
local addBtn = s("TextButton", { Size = UDim2.new(0, 90, 0, 32), Position = UDim2.new(1, -90, 0, 0), BackgroundColor3 = T.accent, Text = "Add", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, Parent = musicTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = addBtn })
conn(addBtn.MouseButton1Click:Connect(function()
	local id = songIdInput.Text:gsub("%D", "")
	if id == "" then notify("Enter a Sound ID!", T.red) return end
	local name = "Song #" .. (#playlist + 1)
	table.insert(playlist, { id = id, name = name })
	songIdInput.Text = ""
	notify("Added song: " .. name, T.green)
	if #playlist == 1 then playSong(1) end
end))

-- Playlist display
header(musicTab.page, "Playlist")
local playlistScroll = s("ScrollingFrame", { Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.dim, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = musicTab.page })
s("UIListLayout", { Padding = UDim.new(0, 4), Parent = playlistScroll })

local function refreshPlaylist()
	for _, c in ipairs(playlistScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	for i, song in ipairs(playlist) do
		local b = s("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = i == currentIdx and T.bg3 or T.bg2, Text = "  " .. i .. ". " .. song.name, TextColor3 = i == currentIdx and T.accent or T.text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = playlistScroll })
		s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = b })
		conn(b.MouseButton1Click:Connect(function() playSong(i) end))
	end
end

button(musicTab.page, "Refresh Playlist", function() refreshPlaylist() notify("Playlist refreshed", T.green) end)
button(musicTab.page, "Clear Playlist", function() playlist = {} musicSound:Stop() isPlaying = false currentSongLabel.Text = " Nothing playing" refreshPlaylist() notify("Playlist cleared", T.red) end)

-- ============================================================
-- TAB: GAMES
-- ============================================================
header(gamesTab.page, "Clicker Game")
local clickerScore = 0
local clickerLabel = s("TextLabel", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.bg2, BorderSizePixel = 0, Text = "Score: 0", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 16, Parent = gamesTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = clickerLabel })
local clickerBtn = s("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = T.accent, Text = "CLICK ME!", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false, Parent = gamesTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = clickerBtn })
s("UIGradient", { Color = ColorSequence.new(T.accent, T.accent2), Rotation = 90, Parent = clickerBtn })
conn(clickerBtn.MouseButton1Click:Connect(function()
	clickerScore = clickerScore + 1
	clickerLabel.Text = "Score: " .. clickerScore
	TweenService:Create(clickerBtn, TweenInfo.new(0.05), { Size = UDim2.new(1,-4,0,46), Position = UDim2.new(0,2,0,2) }):Play()
	task.wait(0.05)
	TweenService:Create(clickerBtn, TweenInfo.new(0.05), { Size = UDim2.new(1,0,0,50), Position = UDim2.new(0,0,0,0) }):Play()
end))
button(gamesTab.page, "Reset Clicker", function() clickerScore = 0 clickerLabel.Text = "Score: 0" notify("Clicker reset", T.red) end)

header(gamesTab.page, "Guess the Number (1-100)")
local guessInput = s("TextBox", { Size = UDim2.new(1, -100, 0, 32), BackgroundColor3 = T.bg3, Text = "", PlaceholderText = " Your guess...", TextColor3 = T.text, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false, Parent = gamesTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = guessInput })
s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.7, Parent = guessInput })
local guessTarget = math.random(1, 100)
local guessAttempts = 0
local guessBtn = s("TextButton", { Size = UDim2.new(0, 90, 0, 32), Position = UDim2.new(1, -90, 0, 0), BackgroundColor3 = T.accent, Text = "Guess", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, Parent = gamesTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = guessBtn })
conn(guessBtn.MouseButton1Click:Connect(function()
	local n = tonumber(guessInput.Text)
	if not n then notify("Enter a number!", T.red) return end
	guessAttempts = guessAttempts + 1
	if n == guessTarget then notify("You got it in " .. guessAttempts .. " tries! New game!", T.green) guessTarget = math.random(1, 100) guessAttempts = 0 guessInput.Text = "" elseif n < guessTarget then notify("Higher! (attempt " .. guessAttempts .. ")", T.yellow) else notify("Lower! (attempt " .. guessAttempts .. ")", T.yellow) end
	guessInput.Text = ""
end))
button(gamesTab.page, "New Number", function() guessTarget = math.random(1, 100) guessAttempts = 0 notify("New number generated!", T.accent) end)

header(gamesTab.page, "Roulette")
local rouletteLabel = s("TextLabel", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.bg2, BorderSizePixel = 0, Text = "Spin to win!", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 14, Parent = gamesTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = rouletteLabel })
button(gamesTab.page, "SPIN ROULETTE", function()
	local prizes = {"100 coins", "50 coins", "Nothing", "200 coins", "10 coins", "JACKPOT!", "Nothing", "75 coins"}
	local result = prizes[math.random(1, #prizes)]
	rouletteLabel.Text = "Spinning..."
	task.spawn(function()
		for i = 1, 10 do task.wait(0.08) rouletteLabel.Text = prizes[math.random(1, #prizes)] end
		rouletteLabel.Text = "You got: " .. result
		notify("Roulette: " .. result, result == "JACKPOT!" and T.yellow or T.accent)
	end)
end)

header(gamesTab.page, "Reaction Test")
local reactLabel = s("TextLabel", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.bg2, BorderSizePixel = 0, Text = "Click Start to begin", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12, Parent = gamesTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = reactLabel })
local reactBtn = s("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = T.bg3, Text = "Start Reaction Test", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false, Parent = gamesTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = reactBtn })
local reactState = "idle" local reactStart = 0
conn(reactBtn.MouseButton1Click:Connect(function()
	if reactState == "idle" then
		reactState = "waiting" reactBtn.Text = "Wait for GREEN..." reactBtn.BackgroundColor3 = T.red reactLabel.Text = "Get ready..."
		task.wait(math.random(1, 3))
		if killed or reactState ~= "waiting" then return end
		reactState = "go" reactBtn.Text = "CLICK NOW!" reactBtn.BackgroundColor3 = T.green reactStart = tick()
	elseif reactState == "go" then
		local reaction = math.floor((tick() - reactStart) * 1000)
		reactLabel.Text = "Reaction: " .. reaction .. "ms"
		reactBtn.Text = "Try Again" reactBtn.BackgroundColor3 = T.bg3 reactState = "idle"
		notify("Reaction: " .. reaction .. "ms", reaction < 300 and T.green or T.yellow)
	elseif reactState == "waiting" then
		reactLabel.Text = "Too early! Wait for green."
		reactBtn.Text = "Start Reaction Test" reactBtn.BackgroundColor3 = T.bg3 reactState = "idle"
	end
end))

-- ============================================================
-- TAB: FX
-- ============================================================
header(fxTab.page, "Character Effects")

local activeTrails = {}
local activeParticles = {}
local activeAuras = {}

local function clearTrails() for _, t in pairs(activeTrails) do pcall(function() t:Destroy() end) end activeTrails = {} end
local function clearParticles() for _, p in pairs(activeParticles) do pcall(function() p:Destroy() end) end activeParticles = {} end
local function clearAuras() for _, a in pairs(activeAuras) do pcall(function() a:Destroy() end) end activeAuras = {} end

-- Trail effect
toggle(fxTab.page, "Rainbow Trail", false, function(state)
	if state then
		local hrp = getHRP() if not hrp then return end
		local a0 = s("Attachment", { Name = "TrailA0", Parent = hrp })
		local a1 = s("Attachment", { Name = "TrailA1", Position = Vector3.new(0, -3, 0), Parent = hrp })
		local trail = s("Trail", { Name = "RainbowTrail", Attachment0 = a0, Attachment1 = a1, Lifetime = 1, Color = ColorSequence.new(Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,255)), Transparency = NumberSequence.new(0, 1), WidthScale = NumberSequence.new(1, 0), Parent = hrp })
		activeTrails[trail] = true
		task.spawn(function() while trail and trail.Parent and not killed do pcall(function() trail.Color = ColorSequence.new(Color3.fromHSV((tick() % 5) / 5, 1, 1), Color3.fromHSV(((tick() % 5) / 5 + 0.5) % 1, 1, 1)) end) task.wait(0.05) end end)
	else clearTrails() end
end)

-- Fire particles
toggle(fxTab.page, "Fire Aura", false, function(state)
	if state then
		local hrp = getHRP() if not hrp then return end
		local pe = s("ParticleEmitter", { Name = "FireAura", Texture = "rbxassetid://243660364", Rate = 50, Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(45, 45), Color = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 200, 0)), Size = NumberSequence.new(1, 0), Transparency = NumberSequence.new(0, 1), Parent = hrp })
		activeParticles[pe] = true
	else clearParticles() end
end)

-- Sparkle particles
toggle(fxTab.page, "Sparkles", false, function(state)
	if state then
		local hrp = getHRP() if not hrp then return end
		local pe = s("ParticleEmitter", { Name = "SparkleFX", Texture = "rbxassetid://243660364", Rate = 30, Lifetime = NumberRange.new(0.3, 0.8), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180), Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 255)), Size = NumberSequence.new(0.5, 0), Transparency = NumberSequence.new(0, 1), Parent = hrp })
		activeParticles[pe] = true
	else clearParticles() end
end)

-- Glow ring aura
toggle(fxTab.page, "Glow Ring", false, function(state)
	if state then
		local hrp = getHRP() if not hrp then return end
		local ring = s("Part", { Name = "GlowRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 6, 6), CFrame = hrp.CFrame * CFrame.new(0, -3, 0) * CFrame.Angles(0, 0, math.rad(90)), Anchored = true, CanCollide = false, Transparency = 0.5, Material = Enum.Material.Neon, Color = T.accent, Parent = Workspace })
		activeAuras[ring] = true
		task.spawn(function() while ring and ring.Parent and not killed do pcall(function() local h = getHRP() if h then ring.CFrame = h.CFrame * CFrame.new(0, -3, 0) * CFrame.Angles(0, 0, math.rad(90)) ring.Color = Color3.fromHSV((tick() * 0.3) % 1, 0.7, 1) end end) task.wait(0.03) end end)
	else clearAuras() end
end)

-- Rainbow character
toggle(fxTab.page, "Rainbow Body", false, function(state)
	if state then
		task.spawn(function() while not killed do local char = player.Character if char then local hue = (tick() * 0.5) % 1 local color = Color3.fromHSV(hue, 1, 1) for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then pcall(function() p.Color = color end) end end end task.wait(0.05) end end)
	else local char = player.Character if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then pcall(function() p.BrickColor = BrickColor.new("Medium stone grey") end) end end end end
end)

-- Neon body
toggle(fxTab.page, "Neon Body", false, function(state)
	local char = player.Character if not char then return end
	if state then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then pcall(function() p.Material = Enum.Material.Neon end) end end else for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then pcall(function() p.Material = Enum.Material.Plastic end) end end end
end)

-- Force field
toggle(fxTab.page, "Force Field", false, function(state)
	local char = player.Character if not char then return end
	if state then s("ForceField", { Name = "PHForceField", Parent = char }) else local ff = char:FindFirstChild("PHForceField") if ff then pcall(function() ff:Destroy() end) end end
end)

header(fxTab.page, "Lighting FX")
toggle(fxTab.page, "Disco Lights", false, function(state)
	if state then task.spawn(function() while not killed do pcall(function() Lighting.Ambient = Color3.fromHSV(math.random(), 1, 1) Lighting.OutdoorAmbient = Color3.fromHSV(math.random(), 1, 1) end) task.wait(0.1) end end) else pcall(function() Lighting.Ambient = Color3.fromRGB(128, 128, 128) Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128) end) end
end)

toggle(fxTab.page, "Night Vision", false, function(state)
	if state then s("ColorCorrectionEffect", { Name = "PHNightVision", Brightness = 0.2, Contrast = 0.3, TintColor = Color3.fromRGB(100, 255, 100), Parent = Lighting }) pcall(function() Lighting.Brightness = 2 end) else local nv = Lighting:FindFirstChild("PHNightVision") if nv then pcall(function() nv:Destroy() end) end pcall(function() Lighting.Brightness = 2 end) end
end)

button(fxTab.page, "Clear All FX", function() clearTrails() clearParticles() clearAuras() local char = player.Character if char then local ff = char:FindFirstChild("PHForceField") if ff then pcall(function() ff:Destroy() end) end for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then pcall(function() p.Material = Enum.Material.Plastic p.BrickColor = BrickColor.new("Medium stone grey") end) end end end pcall(function() Lighting.Ambient = Color3.fromRGB(128, 128, 128) Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128) end) local nv = Lighting:FindFirstChild("PHNightVision") if nv then pcall(function() nv:Destroy() end) end notify("All FX cleared!", T.red) end)

-- ============================================================
-- TAB: CHAT
-- ============================================================
header(chatTab.page, "Quick Phrases")

local function sendChat(msg)
	pcall(function()
		local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatRemoteEvents")
		if chatEvents then
			local sayMsg = chatEvents:FindFirstChild("SayMessageRequest")
			if sayMsg then sayMsg:FireServer(msg, "All") return end
		end
		local ts = game:GetService("TextChatService")
		if ts and ts.ChatVersion == Enum.ChatVersion.TextChatService then
			local window = ts:FindFirstChild("ChatWindowApp")
			if window then
				local bar = window:FindFirstChild("ChatInputBar")
				if bar then bar:Send(msg) return end
			end
		end
		notify("Could not send chat in this game", T.red)
	end)
end

local quickPhrases = {
	"Hello!", "GG!", "Nice!", "LOL", "BRB", "GTG", "Yes", "No", "Thanks!", "Sorry", "Wanna be friends?", "Follow me!", "Good game everyone!", "Let's play again!", "That was fun!"
}

for _, phrase in ipairs(quickPhrases) do
	button(chatTab.page, phrase, function() sendChat(phrase) notify("Sent: " .. phrase, T.green) end)
end

header(chatTab.page, "Custom Message")
local customChatInput = s("TextBox", { Size = UDim2.new(1, -100, 0, 32), BackgroundColor3 = T.bg3, Text = "", PlaceholderText = " Type message...", TextColor3 = T.text, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false, Parent = chatTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = customChatInput })
s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.7, Parent = customChatInput })
local sendCustomBtn = s("TextButton", { Size = UDim2.new(0, 90, 0, 32), Position = UDim2.new(1, -90, 0, 0), BackgroundColor3 = T.accent, Text = "Send", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, Parent = chatTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = sendCustomBtn })
conn(sendCustomBtn.MouseButton1Click:Connect(function()
	if customChatInput.Text ~= "" then sendChat(customChatInput.Text) notify("Sent: " .. customChatInput.Text, T.green) customChatInput.Text = "" end
end))

header(chatTab.page, "Auto Messages")
local autoMsgRunning = false
toggle(chatTab.page, "Auto GG (every 60s)", false, function(state)
	autoMsgRunning = state
	if state then task.spawn(function() while autoMsgRunning and not killed do sendChat("GG!") task.wait(60) end end) notify("Auto GG started", T.green) else notify("Auto GG stopped", T.red) end
end)

local autoMsgInput = s("TextBox", { Size = UDim2.new(1, -100, 0, 32), BackgroundColor3 = T.bg3, Text = "", PlaceholderText = " Custom auto message...", TextColor3 = T.text, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false, Parent = chatTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = autoMsgInput })
s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.7, Parent = autoMsgInput })
local autoCustomRunning = false
local autoCustomBtn = s("TextButton", { Size = UDim2.new(0, 90, 0, 32), Position = UDim2.new(1, -90, 0, 0), BackgroundColor3 = T.accent, Text = "Start", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, Parent = chatTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = autoCustomBtn })
conn(autoCustomBtn.MouseButton1Click:Connect(function()
	if autoCustomRunning then autoCustomRunning = false autoCustomBtn.Text = "Start" autoCustomBtn.BackgroundColor3 = T.accent notify("Auto message stopped", T.red) else if autoMsgInput.Text ~= "" then autoCustomRunning = true autoCustomBtn.Text = "Stop" autoCustomBtn.BackgroundColor3 = T.red local msg = autoMsgInput.Text notify("Auto message started: " .. msg, T.green) task.spawn(function() while autoCustomRunning and not killed do sendChat(msg) task.wait(45) end end) else notify("Enter a message first!", T.red) end end
end))

-- ============================================================
-- TAB: UTIL
-- ============================================================
header(utilTab.page, "Camera")
slider(utilTab.page, "Field of View", 30, 120, 70, function(v) local cam = Workspace.CurrentCamera if cam then pcall(function() cam.FieldOfView = v end) end end)
button(utilTab.page, "Reset FOV", function() local cam = Workspace.CurrentCamera if cam then pcall(function() cam.FieldOfView = 70 end) notify("FOV reset to 70", T.green) end end)

toggle(utilTab.page, "Free Camera", false, function(state)
	local cam = Workspace.CurrentCamera if not cam then return end
	if state then pcall(function() cam.CameraType = Enum.CameraType.Scriptable end) else pcall(function() cam.CameraType = Enum.CameraType.Custom end) end
end)

header(utilTab.page, "Movement")
slider(utilTab.page, "Walk Speed", 1, 500, 16, function(v) local h = getHum() if h then pcall(function() h.WalkSpeed = v end) end end)
slider(utilTab.page, "Jump Power", 0, 500, 50, function(v) local h = getHum() if h then pcall(function() h.UseJumpPower = true h.JumpPower = v end) end end)
slider(utilTab.page, "Gravity", 0, 200, 196.2, function(v) pcall(function() Workspace.Gravity = v end) end)
button(utilTab.page, "Reset Movement", function() local h = getHum() if h then pcall(function() h.WalkSpeed = 16 h.JumpPower = 50 h.UseJumpPower = true end) end pcall(function() Workspace.Gravity = 196.2 end) notify("Movement reset", T.green) end)

toggle(utilTab.page, "Infinite Jump", false, function(state)
	if state then conn(UserInputService.JumpRequest:Connect(function() if not killed then local h = getHum() if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end)) end
end)

toggle(utilTab.page, "Noclip", false, function(state)
	if state then conn(RunService.Stepped:Connect(function() if killed then return end local char = player.Character if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then pcall(function() p.CanCollide = false end) end end end end)) else local char = player.Character if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then pcall(function() p.CanCollide = true end) end end end end end
end)

header(utilTab.page, "Teleport")
button(utilTab.page, "TP Up 100", function() local hrp = getHRP() if hrp then pcall(function() hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 100, 0)) end) notify("TP'd up 100", T.accent) end end)
button(utilTab.page, "TP Forward 50", function() local hrp = getHRP() local cam = Workspace.CurrentCamera if hrp and cam then pcall(function() hrp.CFrame = CFrame.new(hrp.Position + cam.CFrame.LookVector * 50) end) notify("TP'd forward", T.accent) end end)
button(utilTab.page, "TP to Spawn", function() local hrp = getHRP() if hrp then local spawn = Workspace:FindFirstChild("SpawnLocation") if spawn then pcall(function() hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0) end) notify("TP'd to spawn", T.accent) else notify("No SpawnLocation found", T.red) end end end)

local tpInput = s("TextBox", { Size = UDim2.new(1, -100, 0, 32), BackgroundColor3 = T.bg3, Text = "", PlaceholderText = " x,y,z (e.g. 100,50,200)", TextColor3 = T.text, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false, Parent = utilTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tpInput })
s("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.7, Parent = tpInput })
local tpBtn = s("TextButton", { Size = UDim2.new(0, 90, 0, 32), Position = UDim2.new(1, -90, 0, 0), BackgroundColor3 = T.accent, Text = "TP", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, Parent = utilTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tpBtn })
conn(tpBtn.MouseButton1Click:Connect(function()
	local coords = {} for n in tpInput.Text:gmatch("%-?%d+%.?%d*") do table.insert(coords, tonumber(n)) end
	if #coords >= 3 then local hrp = getHRP() if hrp then pcall(function() hrp.CFrame = CFrame.new(coords[1], coords[2], coords[3]) end) notify("TP'd to " .. coords[1] .. "," .. coords[2] .. "," .. coords[3], T.accent) end else notify("Enter x,y,z coordinates", T.red) end
end))

header(utilTab.page, "Server")
button(utilTab.page, "Rejoin Server", function() pcall(function() if game.JobId and game.JobId ~= "" then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, player) else game:GetService("TeleportService"):Teleport(game.PlaceId, player) end end) end)
button(utilTab.page, "Server Hop", function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, player) end) end)
button(utilTab.page, "Leave Game", function() pcall(function() player:Kick("Left via PlayerHub") end) end)

-- Visualizer update
conn(RunService.Heartbeat:Connect(function()
	if killed then return end
	if isPlaying and musicSound.IsPlaying then
		for i, bar in ipairs(vizBars) do
			local h = math.random(5, 38)
			TweenService:Create(bar, TweenInfo.new(0.1), { Size = UDim2.new(1/16, -2, 0, h), Position = UDim2.new((i-1)/16, 0, 1, 0), AnchorPoint = Vector2.new(0, 1) }):Play()
		end
	else
		for i, bar in ipairs(vizBars) do
			TweenService:Create(bar, TweenInfo.new(0.2), { Size = UDim2.new(1/16, -2, 0, 3) }):Play()
		end
	end
end))

-- ============================================================
-- TAB: SETTINGS
-- ============================================================
header(settingsTab.page, "Display")
slider(settingsTab.page, "Text Size", 8, 20, 12, function(v) for _, c in ipairs(gui:GetDescendants()) do if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") then pcall(function() c.TextSize = v end) end end end)
slider(settingsTab.page, "Panel Opacity", 0, 100, 85, function(v) pcall(function() frame.BackgroundTransparency = 1 - (v / 100) end) end)

header(settingsTab.page, "Accent Color")
local function updateAccent() pcall(function() frame:FindFirstChild("UIStroke").Color = T.accent end) for _, t in ipairs(tabs) do if t.page.Visible then pcall(function() t.button.BackgroundColor3 = T.accent end) end end end
slider(settingsTab.page, "Accent R", 0, 255, 100, function(v) T.accent = Color3.fromRGB(v, math.floor(T.accent.G * 255), math.floor(T.accent.B * 255)) updateAccent() end)
slider(settingsTab.page, "Accent G", 0, 255, 200, function(v) T.accent = Color3.fromRGB(math.floor(T.accent.R * 255), v, math.floor(T.accent.B * 255)) updateAccent() end)
slider(settingsTab.page, "Accent B", 0, 255, 255, function(v) T.accent = Color3.fromRGB(math.floor(T.accent.R * 255), math.floor(T.accent.G * 255), v) updateAccent() end)

header(settingsTab.page, "Keybind")
local keybindLabel = s("TextLabel", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.bg2, BorderSizePixel = 0, Text = " Toggle key: J", TextColor3 = T.text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = settingsTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 6), Parent = keybindLabel })
s("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = keybindLabel })

header(settingsTab.page, "Actions")
button(settingsTab.page, "Reset All Features", function()
	clearTrails() clearParticles() clearAuras()
	local char = player.Character
	if char then local ff = char:FindFirstChild("PHForceField") if ff then pcall(function() ff:Destroy() end) end for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then pcall(function() p.Material = Enum.Material.Plastic p.BrickColor = BrickColor.new("Medium stone grey") end) end end end
	pcall(function() Lighting.Ambient = Color3.fromRGB(128, 128, 128) Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128) Lighting.Brightness = 2 end)
	local nv = Lighting:FindFirstChild("PHNightVision") if nv then pcall(function() nv:Destroy() end) end
	musicSound:Stop() isPlaying = false currentSongLabel.Text = " Nothing playing"
	pcall(function() Workspace.Gravity = 196.2 end)
	local cam = Workspace.CurrentCamera if cam then pcall(function() cam.FieldOfView = 70 cam.CameraType = Enum.CameraType.Custom end) end
	notify("Everything reset!", T.red)
end)

local killBtn = s("TextButton", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Color3.fromRGB(80, 20, 20), Text = "KILL SCRIPT", TextColor3 = Color3.fromRGB(255, 100, 100), Font = Enum.Font.GothamBold, TextSize = 12, Parent = settingsTab.page })
s("UICorner", { CornerRadius = UDim.new(0, 8), Parent = killBtn })
s("UIStroke", { Color = T.red, Thickness = 1.5, Parent = killBtn })
conn(killBtn.MouseButton1Click:Connect(function()
	killed = true
	for _, c in ipairs(allConnections) do pcall(function() c:Disconnect() end) end
	pcall(function() if gui then gui:Destroy() end end)
	pcall(function() if nGui then nGui:Destroy() end end)
	pcall(function() if tGui then tGui:Destroy() end end)
	pcall(function() musicSound:Destroy() end)
end))
