--[[ ASTRI HUB v4.9 (animated) ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local SETTINGS_FILE = "astri_hub_settings.json"
local DEFAULT_SETTINGS = {
    accentColor = "PINK", windowTransparency = 0, hideProfile = false,
    fovValue = 90, flySpeed = 1, followDist = 3, followMode = "behind",
    tpKey = "Z", espEnabled = false,
}
local Settings = {}
local function saveSettings() pcall(function() if writefile then writefile(SETTINGS_FILE, HttpService:JSONEncode(Settings)) end end) end
local function loadSettings()
    Settings = {}
    for k, v in pairs(DEFAULT_SETTINGS) do Settings[k] = v end
    pcall(function()
        if readfile and isfile and isfile(SETTINGS_FILE) then
            local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
            for k, v in pairs(data) do Settings[k] = v end
        end
    end)
end
loadSettings()

local ACCENTS = {
    PINK = Color3.fromRGB(255, 70, 140), PURPLE = Color3.fromRGB(160, 70, 255),
    CYAN = Color3.fromRGB(70, 200, 255), GREEN = Color3.fromRGB(50, 200, 90),
    ORANGE = Color3.fromRGB(255, 140, 60), RED = Color3.fromRGB(220, 60, 60),
}
local C = {
    BG = Color3.fromRGB(15, 15, 15), BG_DARK = Color3.fromRGB(10, 10, 10),
    BG_IN = Color3.fromRGB(25, 25, 25), BTN = Color3.fromRGB(30, 30, 35),
    PINK = ACCENTS[Settings.accentColor] or ACCENTS.PINK,
    TEXT = Color3.fromRGB(255, 255, 255), DIM = Color3.fromRGB(160, 160, 160),
    GREEN = Color3.fromRGB(50, 200, 90), RED = Color3.fromRGB(220, 60, 60),
    YELLOW = Color3.fromRGB(240, 190, 60),
}

local parent = (function()
    local okH, h = pcall(function() return gethui and gethui() end)
    if okH and h then return h end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end)()

local function corner(o, r) local c = Instance.new("UICorner", o); c.CornerRadius = UDim.new(0, r or 5); return c end

--============================================================
-- ANIMATION HELPERS
--============================================================
local function tw(o, t, props, style, dir)
    local tween = TweenService:Create(
        o,
        TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end

local function darker(c, f) return c:Lerp(Color3.new(0, 0, 0), f or 0.35) end
local function lighter(c, f) return c:Lerp(Color3.new(1, 1, 1), f or 0.25) end
local function addGrad(o, c0, c1, rot)
    local g = Instance.new("UIGradient", o)
    g.Color = ColorSequence.new(c0, c1); g.Rotation = rot or 90
    return g
end
local function addStroke(o, col, th, tr)
    local st = Instance.new("UIStroke", o)
    st.Color = col; st.Thickness = th or 1; st.Transparency = tr or 0.9
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return st
end
local function addKnob(fill)
    addGrad(fill, Color3.new(1, 1, 1), Color3.fromRGB(175, 175, 185), 90)
    local k = Instance.new("Frame", fill)
    k.Size = UDim2.new(0, 14, 0, 14); k.Position = UDim2.new(1, -7, 0.5, -7)
    k.BackgroundColor3 = Color3.new(1, 1, 1); k.BorderSizePixel = 0; corner(k, 7)
    addStroke(k, C.PINK, 2, 0)
    return k
end

local function polishBtn(b, r)
    if b:GetAttribute("polished") then return end
    b:SetAttribute("polished", true)

    local scale = Instance.new("UIScale", b)

    addGrad(b, Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 212), 90)
    local st = addStroke(b, Color3.new(1, 1, 1), 1, 0.92)
    local function updStroke()
        local bg = b.BackgroundColor3
        if bg == C.PINK or bg == C.RED then
            tw(st, 0.25, {Color = lighter(bg, 0.35), Transparency = 0.35})
        else
            tw(st, 0.25, {Color = Color3.new(1, 1, 1), Transparency = 0.92})
        end
    end
    updStroke()

    local hov = Instance.new("Frame", b)
    hov.Name = "Hover"; hov.Size = UDim2.new(1, 0, 1, 0)
    hov.BackgroundColor3 = Color3.new(1, 1, 1); hov.BackgroundTransparency = 1
    hov.BorderSizePixel = 0; hov.Active = false; corner(hov, r or 5)

    local fade = Instance.new("Frame", b)
    fade.Name = "Fade"; fade.Size = UDim2.new(1, 0, 1, 0)
    fade.BackgroundColor3 = b.BackgroundColor3; fade.BackgroundTransparency = 1
    fade.BorderSizePixel = 0; fade.Active = false; corner(fade, r or 5)

    local last = b.BackgroundColor3
    b:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
        local nc = b.BackgroundColor3
        if nc == last then return end
        fade.BackgroundColor3 = last
        fade.BackgroundTransparency = 0.3
        tw(fade, 0.3, {BackgroundTransparency = 1})
        last = nc
        updStroke()
    end)

    b.MouseEnter:Connect(function() tw(hov, 0.15, {BackgroundTransparency = 0.9}) end)
    b.MouseLeave:Connect(function()
        tw(hov, 0.2, {BackgroundTransparency = 1})
        tw(scale, 0.2, {Scale = 1}, Enum.EasingStyle.Back)
    end)
    b.MouseButton1Down:Connect(function() tw(scale, 0.08, {Scale = 0.95}) end)
    b.MouseButton1Up:Connect(function() tw(scale, 0.25, {Scale = 1}, Enum.EasingStyle.Back) end)
end

local function mkBtn(par, text, pos, size, bg)
    local b = Instance.new("TextButton", par); b.Text = text; b.Position = pos
    b.Size = size or UDim2.new(1, -10, 0, 30); b.BackgroundColor3 = bg or C.BTN
    b.TextColor3 = C.TEXT; b.Font = Enum.Font.GothamBold; b.TextSize = 11
    b.BorderSizePixel = 0; b.AutoButtonColor = false; corner(b)
    polishBtn(b)
    return b
end
local function mkLbl(par, text, pos, size, col)
    local l = Instance.new("TextLabel", par); l.Text = text; l.Position = pos
    l.Size = size or UDim2.new(1, -10, 0, 20); l.BackgroundTransparency = 1
    l.TextColor3 = col or C.TEXT; l.Font = Enum.Font.Gotham; l.TextSize = 11
    l.TextWrapped = true; l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Top; return l
end
local function mkBox(par, ph, pos, size)
    local t = Instance.new("TextBox", par); t.PlaceholderText = ph; t.Text = ""
    t.Position = pos; t.Size = size or UDim2.new(1, -10, 0, 26)
    t.BackgroundColor3 = C.BG_IN; t.TextColor3 = C.TEXT; t.PlaceholderColor3 = C.DIM
    t.Font = Enum.Font.Gotham; t.TextSize = 11; t.BorderSizePixel = 0
    t.ClearTextOnFocus = false; corner(t)
    local tst = addStroke(t, Color3.new(1, 1, 1), 1, 0.93)
    t.Focused:Connect(function() tw(tst, 0.2, {Color = C.PINK, Transparency = 0.15}) end)
    t.FocusLost:Connect(function() tw(tst, 0.25, {Color = Color3.new(1, 1, 1), Transparency = 0.93}) end)
    return t
end

local function mkSlider(par, y, text, minV, maxV, val, onChange, fmt)
    fmt = fmt or function(v) return tostring(v) end
    local lbl = mkLbl(par, text .. ": " .. fmt(val), UDim2.new(0, 5, 0, y), UDim2.new(1, -10, 0, 18), C.PINK)
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    local bar = Instance.new("Frame", par)
    bar.Size = UDim2.new(1, -10, 0, 10); bar.Position = UDim2.new(0, 5, 0, y + 24)
    bar.BackgroundColor3 = C.BG_IN; bar.BorderSizePixel = 0; corner(bar, 5)
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((val - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = C.PINK; fill.BorderSizePixel = 0; corner(fill, 5)
    addKnob(fill)
    local current = val
    local S = {}
    function S.set(v, silent)
        v = math.clamp(math.floor(v + 0.5), minV, maxV)
        current = v
        lbl.Text = text .. ": " .. fmt(v)
        tw(fill, 0.08, {Size = UDim2.new((v - minV) / (maxV - minV), 0, 1, 0)})
        if not silent then onChange(v) end
    end
    function S.get() return current end
    local dragging = false
    local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
    local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
    local function fromInput(i)
        local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        S.set(minV + (maxV - minV) * rel)
    end
    bar.InputBegan:Connect(function(i) if isPress(i) then dragging = true; fromInput(i) end end)
    UIS.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end)
    UIS.InputChanged:Connect(function(i) if dragging and isMove(i) then fromInput(i) end end)
    return S
end

local gui = Instance.new("ScreenGui")
gui.Name = "AstriHubV49"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local okParent = pcall(function() gui.Parent = parent end)
if not okParent or not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local W = 360
local H = 320
local MAX_H = 520

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, W, 0, H)
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Position = UDim2.new(0.5, 0, 0.5, -H/2)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0; frame.Active = true
frame.ClipsDescendants = true
corner(frame, 8)
addGrad(frame, Color3.new(1, 1, 1), Color3.fromRGB(130, 130, 145), 90)

local frameScale = Instance.new("UIScale", frame); frameScale.Scale = 0.88

local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.new(1, 1, 1); stroke.Thickness = 1.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Transparency = 1
local strokeGrad = Instance.new("UIGradient", stroke)
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.PINK),
    ColorSequenceKeypoint.new(0.5, darker(C.PINK, 0.65)),
    ColorSequenceKeypoint.new(1, C.PINK),
})
local rotConn = RunService.Heartbeat:Connect(function() strokeGrad.Rotation = (tick() * 45) % 360 end)
gui.Destroying:Connect(function() rotConn:Disconnect() end)

local tb = Instance.new("Frame", frame); tb.Size = UDim2.new(1, 0, 0, 30)
tb.BackgroundColor3 = C.BG_DARK; tb.BorderSizePixel = 0; tb.ClipsDescendants = true
tb.Active = true; corner(tb, 8)

local tl = Instance.new("TextLabel", tb); tl.Size = UDim2.new(1, -100, 1, 0)
tl.Position = UDim2.new(0, 12, 0, 0); tl.BackgroundTransparency = 1
tl.Name = "AstriTitle"; tl.RichText = true; tl.Text = 'Astri Hub  <font size="11" color="rgb(150,150,160)">v4.9</font>'; tl.TextColor3 = C.PINK; tl.Font = Enum.Font.GothamBold
tl.TextSize = 18; tl.TextXAlignment = Enum.TextXAlignment.Left

local accentLine = Instance.new("Frame", frame)
accentLine.Size = UDim2.new(1, 0, 0, 2); accentLine.Position = UDim2.new(0, 0, 0, 30)
accentLine.BackgroundColor3 = C.PINK; accentLine.BorderSizePixel = 0
local alg = Instance.new("UIGradient", accentLine)
alg.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1),
})

local tabBar, pages
local isMin, maxed = false, false
local fitH = H
local curTab = "FF"
local tps = {}

local function resizeToTab(tabName, delay)
    local pg = tps[tabName]
    if not pg then return end
    task.spawn(function()
        task.wait(delay or 0.03)
        local s = frameScale.Scale
        local maxY = 0
        for _, child in ipairs(pg:GetChildren()) do
            if child:IsA("GuiObject") and child.Visible then
                local bottom = (child.AbsolutePosition.Y - pg.AbsolutePosition.Y + child.AbsoluteSize.Y) / s
                if bottom > maxY then maxY = bottom end
            end
        end
        if maxY < 50 then maxY = 100 end
        fitH = math.clamp(maxY + 105, 200, MAX_H)
        if fitH ~= fitH then fitH = H end
        if isMin or maxed then return end
        tw(frame, 0.4, {Size = UDim2.new(0, W, 0, fitH)})
    end)
end

local function resizeToHeight(h)
    if h ~= h then h = H end
    fitH = math.clamp(h, 200, MAX_H)
    if isMin or maxed then return end
    tw(frame, 0.4, {Size = UDim2.new(0, W, 0, fitH)})
end

local function wb(icon, x, col, cb)
    local b = Instance.new("TextButton", tb); b.Size = UDim2.new(0, 24, 0, 22)
    b.Position = UDim2.new(1, x, 0.5, -11); b.BackgroundColor3 = C.BTN
    b.Text = icon; b.TextColor3 = col; b.Font = Enum.Font.GothamBold
    b.TextSize = 13; b.BorderSizePixel = 0; b.AutoButtonColor = false; corner(b, 4)
    local sc = Instance.new("UIScale", b)
    b.MouseEnter:Connect(function()
        tw(b, 0.15, {BackgroundColor3 = col, TextColor3 = C.BG_DARK})
        tw(sc, 0.15, {Scale = 1.1}, Enum.EasingStyle.Back)
    end)
    b.MouseLeave:Connect(function()
        tw(b, 0.2, {BackgroundColor3 = C.BTN, TextColor3 = col})
        tw(sc, 0.2, {Scale = 1})
    end)
    b.MouseButton1Down:Connect(function() tw(sc, 0.08, {Scale = 0.9}) end)
    b.MouseButton1Up:Connect(function() tw(sc, 0.2, {Scale = 1.1}, Enum.EasingStyle.Back) end)
    b.MouseButton1Click:Connect(cb)
    return b
end

wb("×", -30, C.RED, function()
    tw(frameScale, 0.28, {Scale = 0.8}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    tw(frame, 0.25, {BackgroundTransparency = 1})
    tw(stroke, 0.25, {Transparency = 1})
    task.delay(0.3, function() gui:Destroy() end)
end)

wb("–", -58, C.YELLOW, function()
    isMin = not isMin
    if isMin then
        tw(frame, 0.35, {Size = UDim2.new(0, W, 0, 30)})
    else
        maxed = false
        tw(frame, 0.45, {Size = UDim2.new(0, W, 0, fitH)}, Enum.EasingStyle.Back)
    end
end)

-- Drag
local drag, dStart, sPos = false, nil, nil
tb.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true; dStart = i.Position; sPos = frame.Position
        tw(frameScale, 0.2, {Scale = 1.02})
    end
end)
tb.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        if drag then
            drag = false
            tw(frameScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
        end
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dStart
        tw(frame, 0.08, {
            Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
        }, Enum.EasingStyle.Quad)
    end
end)

local names = {"FF", "FLY", "TP", "FOLLOW", "FOV", "FLING", "ESP", "SET", "INFO"}
local idx = {}
for i, n in ipairs(names) do idx[n] = i end

tabBar = Instance.new("Frame", frame); tabBar.Size = UDim2.new(1, -20, 0, 24)
tabBar.Position = UDim2.new(0, 10, 0, 36); tabBar.BackgroundColor3 = C.BG_DARK
tabBar.BorderSizePixel = 0; corner(tabBar, 5)
addStroke(tabBar, Color3.new(1, 1, 1), 1, 0.93)

local indicator = Instance.new("Frame", tabBar)
indicator.Size = UDim2.new(1/#names, 0, 1, 0); indicator.Position = UDim2.new(0, 0, 0, 0)
indicator.BackgroundColor3 = C.PINK; indicator.BorderSizePixel = 0
indicator.ZIndex = 1; corner(indicator, 4)
addGrad(indicator, Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 180), 90)

pages = Instance.new("Frame", frame); pages.Size = UDim2.new(1, -20, 0, H - 100)
pages.Position = UDim2.new(0, 10, 0, 66); pages.BackgroundTransparency = 1; pages.ClipsDescendants = true

-- высота страниц НИКОГДА не уходит в минус (из-за этого сворачивание рисовалось криво)
local function syncPages()
    local h = frame.Size.Y.Offset
    pages.Size = UDim2.new(1, -20, 0, math.max(0, h - 100))
    pages.Visible = h > 110
    tabBar.Visible = h > 66
end
frame:GetPropertyChangedSignal("Size"):Connect(syncPages)
syncPages()

local tbs = {}

local function switchTab(name)
    if curTab == name then return end
    local dir = idx[name] >= idx[curTab] and 1 or -1
    for n, bb in pairs(tbs) do
        tw(bb, 0.2, {TextColor3 = (n == name) and C.TEXT or C.DIM})
        if n ~= name then tps[n].Visible = false end
    end
    tw(indicator, 0.4, {Position = UDim2.new((idx[name] - 1) / #names, 0, 0, 0)}, Enum.EasingStyle.Back)
    local pg = tps[name]
    pg.Position = UDim2.new(0, 30 * dir, 0, 0)
    pg.Visible = true
    tw(pg, 0.4, {Position = UDim2.new(0, 0, 0, 0)})
    curTab = name
    resizeToTab(name)
end

for i, name in ipairs(names) do
    local b = Instance.new("TextButton", tabBar); b.Size = UDim2.new(1/#names, 0, 1, 0)
    b.Position = UDim2.new((i-1)/#names, 0, 0, 0)
    b.BackgroundTransparency = 1; b.ZIndex = 2
    b.Text = name; b.TextColor3 = i == 1 and C.TEXT or C.DIM
    b.Font = Enum.Font.GothamBold; b.TextSize = 8; b.BorderSizePixel = 0
    b.AutoButtonColor = false; tbs[name] = b

    local pg = Instance.new("ScrollingFrame", pages); pg.Size = UDim2.new(1, 0, 1, 0)
    pg.BackgroundTransparency = 1; pg.BorderSizePixel = 0; pg.ClipsDescendants = true
    pg.ScrollBarThickness = 4; pg.ScrollBarImageColor3 = C.PINK
    pg.CanvasSize = UDim2.new(0, 0, 0, 0); pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pg.Visible = i == 1; tps[name] = pg

    b.MouseEnter:Connect(function()
        if curTab ~= name then tw(b, 0.15, {TextColor3 = C.TEXT}) end
    end)
    b.MouseLeave:Connect(function()
        if curTab ~= name then tw(b, 0.2, {TextColor3 = C.DIM}) end
    end)
    b.MouseButton1Click:Connect(function() switchTab(name) end)
end

local function notify(title, text) pcall(function() StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 3}) end) end

--============================================================
-- FF
--============================================================
do
    local p = tps["FF"]
    local boostOn, wrapOn = false, false
    local origs = setmetatable({}, {__mode = "k"})   -- исходные значения, чтобы вернуть всё обратно
    local wrapStore = setmetatable({}, {__mode = "k"})
    local lightOrig, oldQuality, oldCap
    local addedConn, wrapConn
    local boostToken, wrapToken = 0, 0
    local Lighting = game:GetService("Lighting")

    local btn = mkBtn(p, "Ускорение FPS: Выкл", UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 0, 32))
    local wrapBtn = mkBtn(p, "Убрать 3D-одежду: Выкл", UDim2.new(0, 5, 0, 42), UDim2.new(1, -10, 0, 32), C.BTN)
    local fpsLbl = mkLbl(p, "FPS: ...", UDim2.new(0, 5, 0, 80), UDim2.new(1, -10, 0, 20), C.PINK)
    local infoLbl = mkLbl(p, "Ускорение упрощает материалы, тени, частицы и эффекты. При выключении всё возвращается как было.",
        UDim2.new(0, 5, 0, 102), UDim2.new(1, -10, 0, 44), C.DIM)
    infoLbl.TextSize = 10

    -- счётчик FPS
    local frames, lastT = 0, tick()
    local fpsConn = RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - lastT >= 0.5 then
            fpsLbl.Text = "FPS: " .. math.floor(frames / (now - lastT) + 0.5)
            frames = 0; lastT = now
        end
    end)

    local function simplify(o)
        if o:IsA("Terrain") or o:IsDescendantOf(gui) then return end
        if o:IsA("BasePart") then
            if not origs[o] then origs[o] = {Material = o.Material, Reflectance = o.Reflectance, CastShadow = o.CastShadow} end
            o.Material = Enum.Material.SmoothPlastic; o.Reflectance = 0; o.CastShadow = false
        elseif o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Fire")
            or o:IsA("Sparkles") or o:IsA("Beam") or o:IsA("PostEffect") then
            if not origs[o] then origs[o] = {Enabled = o.Enabled} end
            o.Enabled = false
        elseif o:IsA("Atmosphere") then
            if not origs[o] then origs[o] = {Density = o.Density, Haze = o.Haze} end
            o.Density = 0; o.Haze = 0
        end
    end

    local function setBoost(state)
        boostOn = state
        boostToken = boostToken + 1
        local token = boostToken
        if state then
            pcall(function()
                lightOrig = {GlobalShadows = Lighting.GlobalShadows}
                Lighting.GlobalShadows = false
            end)
            pcall(function()
                local t = workspace.Terrain
                origs[t] = {WaterWaveSize = t.WaterWaveSize, WaterWaveSpeed = t.WaterWaveSpeed, WaterReflectance = t.WaterReflectance}
                t.WaterWaveSize = 0; t.WaterWaveSpeed = 0; t.WaterReflectance = 0
            end)
            pcall(function()
                if setfpscap then
                    oldCap = (getfpscap and getfpscap()) or 240
                    setfpscap(999)
                end
            end)
            addedConn = workspace.DescendantAdded:Connect(function(o)
                if boostOn then task.defer(function() pcall(simplify, o) end) end
            end)
            for _, o in ipairs(Lighting:GetChildren()) do pcall(simplify, o) end
            task.spawn(function()
                local n = 0
                for _, o in ipairs(workspace:GetDescendants()) do
                    if token ~= boostToken then return end
                    pcall(simplify, o)
                    n = n + 1
                    if n % 400 == 0 then task.wait() end   -- чтобы игра не зависала на больших картах
                end
            end)
        else
            if addedConn then addedConn:Disconnect(); addedConn = nil end
            pcall(function() if lightOrig then Lighting.GlobalShadows = lightOrig.GlobalShadows end end)
            pcall(function() if setfpscap and oldCap then setfpscap(oldCap) end end)
            task.spawn(function()
                local list = {}
                for o in pairs(origs) do list[#list + 1] = o end
                for n, o in ipairs(list) do
                    if token ~= boostToken then return end
                    local props = origs[o]
                    if props then
                        pcall(function() for k, v in pairs(props) do o[k] = v end end)
                        origs[o] = nil
                    end
                    if n % 400 == 0 then task.wait() end
                end
            end)
        end
    end

    local function disableWrap(o)
        if not o:IsA("WrapLayer") then return end
        local ok = pcall(function() o.Enabled = false end)
        if ok then wrapStore[o] = true else pcall(function() o:Destroy() end) end
    end

    local function setWrap(state)
        wrapOn = state
        wrapToken = wrapToken + 1
        local token = wrapToken
        if state then
            wrapConn = workspace.DescendantAdded:Connect(function(o)
                if wrapOn then task.defer(function() disableWrap(o) end) end
            end)
            task.spawn(function()
                local n = 0
                for _, o in ipairs(workspace:GetDescendants()) do
                    if token ~= wrapToken then return end
                    disableWrap(o)
                    n = n + 1
                    if n % 600 == 0 then task.wait() end
                end
            end)
        else
            if wrapConn then wrapConn:Disconnect(); wrapConn = nil end
            for o in pairs(wrapStore) do
                pcall(function() o.Enabled = true end)
                wrapStore[o] = nil
            end
        end
    end

    btn.MouseButton1Click:Connect(function()
        setBoost(not boostOn)
        btn.Text = "Ускорение FPS: " .. (boostOn and "Вкл" or "Выкл")
        btn.BackgroundColor3 = boostOn and C.PINK or C.BTN
    end)
    wrapBtn.MouseButton1Click:Connect(function()
        setWrap(not wrapOn)
        wrapBtn.Text = "Убрать 3D-одежду: " .. (wrapOn and "Вкл" or "Выкл")
        wrapBtn.BackgroundColor3 = wrapOn and C.PINK or C.BTN
    end)

    gui.Destroying:Connect(function()
        fpsConn:Disconnect()
        if boostOn then setBoost(false) end
        if wrapOn then setWrap(false) end
    end)
end

--============================================================
-- FLY
--============================================================
do
    local p = tps["FLY"]
    local flyOn = false
    local speeds = Settings.flySpeed or 1
    local bv, bg, conn

    local btn = mkBtn(p, "Полёт: Выкл", UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 0, 32))
    local minus = mkBtn(p, "-", UDim2.new(0, 5, 0, 42), UDim2.new(0, 50, 0, 30))
    local sLbl = mkLbl(p, tostring(speeds), UDim2.new(0, 60, 0, 42), UDim2.new(0, 60, 0, 30), C.PINK)
    sLbl.BackgroundColor3 = C.BG_IN; sLbl.BackgroundTransparency = 0
    sLbl.TextXAlignment = Enum.TextXAlignment.Center; sLbl.TextYAlignment = Enum.TextYAlignment.Center
    corner(sLbl)
    local plus = mkBtn(p, "+", UDim2.new(0, 125, 0, 42), UDim2.new(0, 50, 0, 30))
    local hint = mkLbl(p, "Летишь туда, куда смотрит камера. Пробел — вверх, Shift или Ctrl — вниз.",
        UDim2.new(0, 5, 0, 80), UDim2.new(1, -10, 0, 40), C.DIM)
    hint.TextSize = 10

    plus.MouseButton1Click:Connect(function()
        speeds = math.clamp(speeds + 1, 1, 50); sLbl.Text = tostring(speeds)
        Settings.flySpeed = speeds; saveSettings()
    end)
    minus.MouseButton1Click:Connect(function()
        speeds = math.clamp(speeds - 1, 1, 50); sLbl.Text = tostring(speeds)
        Settings.flySpeed = speeds; saveSettings()
    end)

    local function getParts()
        local char = LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChildOfClass("Humanoid")
    end

    local function stopFly()
        if conn then conn:Disconnect(); conn = nil end
        if bv then bv:Destroy(); bv = nil end
        if bg then bg:Destroy(); bg = nil end
        local _, hum = getParts()
        if hum then hum.PlatformStand = false end
    end

    local function startFly()
        stopFly()
        local hrp, hum = getParts()
        if not hrp or not hum then return end
        hum.PlatformStand = true
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.zero; bv.Parent = hrp
        bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.P = 2e4; bg.D = 1e3
        bg.CFrame = hrp.CFrame; bg.Parent = hrp

        conn = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            if not (hrp.Parent and cam and bv and bg) then return end
            if UIS:GetFocusedTextBox() then bv.Velocity = Vector3.zero; return end

            local f = (UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
            local r = (UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
            if f == 0 and r == 0 and hum.MoveDirection.Magnitude > 0 then   -- джойстик / телефон
                local rel = cam.CFrame:VectorToObjectSpace(hum.MoveDirection)
                f = -rel.Z; r = rel.X
            end
            local up = (UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0)
                - ((UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl)) and 1 or 0)

            local v = cam.CFrame.LookVector * f + cam.CFrame.RightVector * r + Vector3.new(0, up, 0)
            local speed = 12 + speeds * 8
            bv.Velocity = v.Magnitude > 0.01 and v.Unit * speed or Vector3.zero
            bg.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
        end)
    end

    btn.MouseButton1Click:Connect(function()
        flyOn = not flyOn
        btn.Text = "Полёт: " .. (flyOn and "Вкл" or "Выкл")
        btn.BackgroundColor3 = flyOn and C.PINK or C.BTN
        if flyOn then startFly() else stopFly() end
    end)

    -- после респавна полёт включается заново
    LocalPlayer.CharacterAdded:Connect(function()
        if flyOn then task.wait(0.6); if flyOn then startFly() end end
    end)

    gui.Destroying:Connect(function() flyOn = false; stopFly() end)
end

--============================================================
-- TP (Teleport to cursor)
--============================================================
do
    local p = tps["TP"]
    local on = false
    local keyName = Settings.tpKey or "Z"
    local key = Enum.KeyCode[keyName] or Enum.KeyCode.Z
    local btn = mkBtn(p, "Телепорт: Выкл", UDim2.new(0, 5, 0, 5), UDim2.new(0.5, -7, 0, 32), C.BTN)
    local keyLabel = mkLbl(p, "Клавиша: " .. keyName, UDim2.new(0.5, 2, 0, 5), UDim2.new(0.5, -7, 0, 32), C.PINK)
    keyLabel.TextXAlignment = Enum.TextXAlignment.Center
    keyLabel.TextYAlignment = Enum.TextYAlignment.Center
    keyLabel.BackgroundColor3 = C.BG_IN; keyLabel.BackgroundTransparency = 0; corner(keyLabel, 5)
    local keyRow = Instance.new("Frame", p)
    keyRow.Size = UDim2.new(1, -10, 0, 60); keyRow.Position = UDim2.new(0, 5, 0, 42)
    keyRow.BackgroundTransparency = 1
    local keys = {
        {Enum.KeyCode.Z, "Z"}, {Enum.KeyCode.X, "X"}, {Enum.KeyCode.C, "C"}, {Enum.KeyCode.V, "V"},
        {Enum.KeyCode.B, "B"}, {Enum.KeyCode.E, "E"}, {Enum.KeyCode.Q, "Q"}, {Enum.KeyCode.F, "F"}
    }
    local keyBtns = {}
    for i, data in ipairs(keys) do
        local kc, txt = data[1], data[2]
        local col = (i-1) % 4
        local row = math.floor((i-1) / 4)
        local b = mkBtn(keyRow, txt, UDim2.new(col * 0.25, 2, row * 0.5, 1), UDim2.new(0.25, -4, 0.5, -2), C.BTN)
        b.TextSize = 10
        b.MouseButton1Click:Connect(function()
            key = kc; keyName = txt; Settings.tpKey = txt; saveSettings()
            keyLabel.Text = "Клавиша: " .. txt
            for _, other in ipairs(keyBtns) do other.BackgroundColor3 = C.BTN end
            b.BackgroundColor3 = C.PINK
        end)
        table.insert(keyBtns, b)
        if kc == key then b.BackgroundColor3 = C.PINK end
    end
    local hint = mkLbl(p, "Включи и нажми выбранную клавишу — телепорт туда, куда смотрит курсор.",
        UDim2.new(0, 5, 0, 108), UDim2.new(1, -10, 0, 30), C.DIM)
    hint.TextSize = 10

    btn.MouseButton1Click:Connect(function()
        on = not on; btn.Text = "Телепорт: " .. (on and "Вкл" or "Выкл")
        btn.BackgroundColor3 = on and C.PINK or C.BTN
    end)

    UIS.InputBegan:Connect(function(i, gp)
        if gp or not on or i.KeyCode ~= key then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera
        if not (root and cam) then return end

        -- луч от курсора через камеру (свой персонаж игнорируется)
        local loc = UIS:GetMouseLocation()
        local ray = cam:ViewportPointToRay(loc.X, loc.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {char}
        local res = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
        if not res then return end

        local h = (hum and hum.HipHeight or 2) + root.Size.Y / 2 + 0.5
        local offset = Vector3.new(0, h, 0)
        if res.Normal.Y <= 0.5 then offset = offset + res.Normal * 2 end   -- у стены не застревать внутри
        pcall(function()
            root.CFrame = CFrame.new(res.Position + offset) * (root.CFrame - root.CFrame.Position)
            root.AssemblyLinearVelocity = Vector3.zero
        end)
    end)
end

--============================================================
-- FOLLOW
--============================================================
do
    local p = tps["FOLLOW"]
    local on = false
    local targetPlr
    local dist = Settings.followDist or 3
    local mode = Settings.followMode or "behind"
    local conn

    local nBox = mkBox(p, "Ник игрока", UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 0, 26))
    local distBox = mkBox(p, "Дистанция", UDim2.new(0, 5, 0, 37), UDim2.new(0.5, -7, 0, 26))
    distBox.Text = tostring(dist)
    distBox.FocusLost:Connect(function()
        local v = tonumber(distBox.Text)
        if v then dist = math.clamp(v, 1, 30); Settings.followDist = dist; saveSettings() end
        distBox.Text = tostring(dist)
    end)

    local modes = {"behind", "front", "above", "overlap"}
    local mNames = {behind = "Сзади", front = "Спереди", above = "Сверху", overlap = "Вплотную"}
    local mi = 1
    for k, v in ipairs(modes) do if v == mode then mi = k end end

    local mBtn = mkBtn(p, mNames[mode], UDim2.new(0.5, 2, 0, 37), UDim2.new(0.5, -7, 0, 26))
    local fBtn = mkBtn(p, "Следовать: Старт", UDim2.new(0, 5, 0, 70), UDim2.new(1, -10, 0, 32))

    mBtn.MouseButton1Click:Connect(function()
        mi = mi % #modes + 1; mode = modes[mi]; mBtn.Text = mNames[mode]
        Settings.followMode = mode; saveSettings()
    end)

    -- сначала точное совпадение ника, потом частичное
    local function findPlayer(q)
        if not q or q == "" then return nil end
        q = q:gsub("@", ""):lower()
        local partial
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local n, d = plr.Name:lower(), plr.DisplayName:lower()
                if n == q or d == q then return plr end
                if not partial and (n:find(q, 1, true) or d:find(q, 1, true)) then partial = plr end
            end
        end
        return partial
    end

    local function stopFollow(msg)
        on = false; targetPlr = nil
        if conn then conn:Disconnect(); conn = nil end
        fBtn.BackgroundColor3 = C.BTN
        fBtn.Text = msg or "Следовать: Старт"
        if msg then
            task.delay(1.2, function() if not on then fBtn.Text = "Следовать: Старт" end end)
        end
    end

    fBtn.MouseButton1Click:Connect(function()
        if on then stopFollow(); return end
        targetPlr = findPlayer(nBox.Text)
        if not targetPlr then stopFollow("Игрок не найден"); return end
        on = true
        fBtn.Text = "Следовать: Стоп"; fBtn.BackgroundColor3 = C.PINK
        conn = RunService.RenderStepped:Connect(function()
            local t = targetPlr
            if not (t and t.Parent) then stopFollow("Игрок вышел"); return end
            local tChar, mChar = t.Character, LocalPlayer.Character
            local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local mHRP = mChar and mChar:FindFirstChild("HumanoidRootPart")
            if not (tHRP and mHRP) then return end
            local mSize, tSize = mChar:GetExtentsSize(), tChar:GetExtentsSize()
            local cf
            if mode == "overlap" then
                cf = tHRP.CFrame
            elseif mode == "behind" then
                cf = tHRP.CFrame * CFrame.new(0, 0, (mSize.Z / 2) + (tSize.Z / 2) + dist)
            elseif mode == "front" then
                local pos = (tHRP.CFrame * CFrame.new(0, 0, -((mSize.Z / 2) + (tSize.Z / 2) + dist))).Position
                cf = CFrame.new(pos, tHRP.Position)
            else -- above
                cf = tHRP.CFrame + Vector3.new(0, (mSize.Y / 2) + (tSize.Y / 2) + dist, 0)
            end
            pcall(function()
                mHRP.CFrame = cf
                mHRP.AssemblyLinearVelocity = Vector3.zero
                mHRP.AssemblyAngularVelocity = Vector3.zero
            end)
        end)
    end)

    gui.Destroying:Connect(function() if conn then conn:Disconnect() end end)
end

--============================================================
-- FOV + ЗУМ
--============================================================
do
    local p = tps["FOV"]
    local fov = Settings.fovValue or 90
    local fMin, fMax = 70, 120
    local fovOn = false
    local zoomActive = false      -- зум сейчас управляет камерой
    local lbl = mkLbl(p, "Поле зрения (FOV): " .. fov, UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 0, 22), C.PINK)
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    local inputBox = mkBox(p, "FOV", UDim2.new(0, 5, 0, 31), UDim2.new(0.5, -7, 0, 26))
    local applyBtn = mkBtn(p, "Применить", UDim2.new(0.5, 2, 0, 31), UDim2.new(0.5, -7, 0, 26), C.PINK)
    local bar = Instance.new("Frame", p); bar.Size = UDim2.new(1, -10, 0, 10)
    bar.Position = UDim2.new(0, 5, 0, 67); bar.BackgroundColor3 = C.BG_IN
    bar.BorderSizePixel = 0; corner(bar, 5)
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((fov - fMin) / (fMax - fMin), 0, 1, 0)
    fill.BackgroundColor3 = C.PINK; fill.BorderSizePixel = 0; corner(fill, 5)
    addKnob(fill)
    local resetBtn = mkBtn(p, "Сбросить (70)", UDim2.new(0, 5, 0, 90), UDim2.new(1, -10, 0, 26))

    -- держим FOV: сразу перебиваем, если игра пытается его поменять (пока не идёт зум)
    local function applyFov()
        if zoomActive then return end
        local cam = workspace.CurrentCamera
        if cam and fovOn and cam.FieldOfView ~= fov then cam.FieldOfView = fov end
    end
    local camConn
    local function hookCam()
        if camConn then camConn:Disconnect(); camConn = nil end
        local cam = workspace.CurrentCamera
        if cam then
            camConn = cam:GetPropertyChangedSignal("FieldOfView"):Connect(applyFov)
            applyFov()
        end
    end
    hookCam()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCam)
    local rsConn = RunService.RenderStepped:Connect(applyFov)

    local function setFov(val)
        val = math.clamp(tonumber(val) or fov, fMin, fMax)
        fov = math.floor(val)
        Settings.fovValue = fov; saveSettings()
        tw(fill, 0.1, {Size = UDim2.new((fov - fMin) / (fMax - fMin), 0, 1, 0)})
        lbl.Text = "Поле зрения (FOV): " .. fov
        applyFov()
    end
    applyBtn.MouseButton1Click:Connect(function()
        local v = tonumber(inputBox.Text)
        if v then fovOn = true; setFov(v) end
    end)
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local v = tonumber(inputBox.Text)
            if v then fovOn = true; setFov(v) end
        end
    end)
    resetBtn.MouseButton1Click:Connect(function()
        fovOn = false
        setFov(70)
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = 70 end
    end)

    local dr = false
    local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
    local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
    local function sliderSet(i)
        local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        fovOn = true
        setFov(fMin + (fMax - fMin) * rel)
    end
    bar.InputBegan:Connect(function(i) if isPress(i) then dr = true; sliderSet(i) end end)
    UIS.InputEnded:Connect(function(i) if isPress(i) then dr = false end end)
    UIS.InputChanged:Connect(function(i) if dr and isMove(i) then sliderSet(i) end end)

    --========================== ЗУМ (как Zoomify) ==========================
    mkLbl(p, "Зум (как Zoomify)", UDim2.new(0, 5, 0, 128), UDim2.new(1, -10, 0, 18), C.PINK)

    local zoomEnabled = false
    local zoomKeyName = Settings.zoomKey or "C"
    local zoomKey = Enum.KeyCode[zoomKeyName] or Enum.KeyCode.C
    local zoomFov = Settings.zoomFov or 20
    local zoomSpeed = Settings.zoomSmooth or 10
    local zoomMode = Settings.zoomMode or "hold"
    local lowerSens = Settings.zoomSens ~= false
    local zooming, savedBase = false, 70
    local origSens
    local zoomSlider
    local UGS
    pcall(function() UGS = UserSettings():GetService("UserGameSettings") end)
    local CAS = game:GetService("ContextActionService")

    local zoomBtn = mkBtn(p, "Зум: Выкл", UDim2.new(0, 5, 0, 150), UDim2.new(1, -10, 0, 30))
    local keyLbl = mkLbl(p, "Клавиша: " .. zoomKeyName, UDim2.new(0, 5, 0, 186), UDim2.new(0.5, -7, 0, 26), C.PINK)
    keyLbl.TextXAlignment = Enum.TextXAlignment.Center; keyLbl.TextYAlignment = Enum.TextYAlignment.Center
    keyLbl.BackgroundColor3 = C.BG_IN; keyLbl.BackgroundTransparency = 0; corner(keyLbl, 5)
    local modeBtn = mkBtn(p, "", UDim2.new(0.5, 2, 0, 186), UDim2.new(0.5, -7, 0, 26))
    local function refreshMode()
        modeBtn.Text = "Режим: " .. (zoomMode == "hold" and "Удержание" or "Переключ.")
    end
    refreshMode()

    local zKeys = {{Enum.KeyCode.C, "C"}, {Enum.KeyCode.Z, "Z"}, {Enum.KeyCode.X, "X"}, {Enum.KeyCode.V, "V"}, {Enum.KeyCode.B, "B"}}
    local zKeyBtns = {}
    for i, data in ipairs(zKeys) do
        local kc, txt = data[1], data[2]
        local b = mkBtn(p, txt, UDim2.new((i - 1) * 0.2, 5 + (i == 1 and 0 or 2), 0, 218), UDim2.new(0.2, -4, 0, 24),
            kc == zoomKey and C.PINK or C.BTN)
        b.TextSize = 10
        b.MouseButton1Click:Connect(function()
            zoomKey = kc; zoomKeyName = txt; Settings.zoomKey = txt; saveSettings()
            keyLbl.Text = "Клавиша: " .. txt
            for _, o in ipairs(zKeyBtns) do o.BackgroundColor3 = C.BTN end
            b.BackgroundColor3 = C.PINK
        end)
        table.insert(zKeyBtns, b)
    end

    local function baseFov() return fovOn and fov or savedBase end

    local function applySens()
        if not (lowerSens and UGS) then return end
        pcall(function()
            if not origSens then origSens = UGS.MouseSensitivity end
            UGS.MouseSensitivity = origSens * math.clamp(zoomFov / baseFov(), 0.08, 1)
        end)
    end
    local function restoreSens()
        if origSens and UGS then pcall(function() UGS.MouseSensitivity = origSens end) end
        origSens = nil
    end

    zoomSlider = mkSlider(p, 250, "Сила зума (FOV)", 5, 60, zoomFov, function(v)
        zoomFov = v; Settings.zoomFov = v
        if zooming then applySens() end
    end)
    local smoothSlider = mkSlider(p, 292, "Плавность", 2, 20, zoomSpeed, function(v)
        zoomSpeed = v; Settings.zoomSmooth = v
    end)
    local sensBtn = mkBtn(p, "", UDim2.new(0, 5, 0, 336), UDim2.new(1, -10, 0, 28))
    local function refreshSens()
        sensBtn.Text = "Снижать чувствительность: " .. (lowerSens and "Вкл" or "Выкл")
        sensBtn.BackgroundColor3 = lowerSens and C.PINK or C.BTN
    end
    refreshSens()
    local zHint = mkLbl(p, "Удерживай клавишу — камера приближается. Колёсико мыши во время зума меняет силу.",
        UDim2.new(0, 5, 0, 370), UDim2.new(1, -10, 0, 40), C.DIM)
    zHint.TextSize = 10

    -- колёсико во время зума: меняем силу и не даём Roblox менять дистанцию камеры
    local function bindScroll()
        pcall(function()
            CAS:BindActionAtPriority("AstriZoomScroll", function(_, state, input)
                if state == Enum.UserInputState.Change then
                    zoomSlider.set(zoomFov - input.Position.Z * 2)
                end
                return Enum.ContextActionResult.Sink
            end, false, 3000, Enum.UserInputType.MouseWheel)
        end)
    end
    local function unbindScroll() pcall(function() CAS:UnbindAction("AstriZoomScroll") end) end

    local function startZoom()
        if not zoomEnabled or zooming then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        if not zoomActive then savedBase = cam.FieldOfView end
        zooming = true; zoomActive = true
        applySens(); bindScroll()
    end
    local function stopZoom()
        if not zooming then return end
        zooming = false
        restoreSens(); unbindScroll()
        saveSettings()
    end

    -- плавное приближение / возврат
    local zoomConn = RunService.RenderStepped:Connect(function(dt)
        if not zoomActive then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local target = zooming and zoomFov or baseFov()
        local a = 1 - math.exp(-zoomSpeed * dt)
        cam.FieldOfView = cam.FieldOfView + (target - cam.FieldOfView) * a
        if not zooming and math.abs(cam.FieldOfView - target) < 0.25 then
            cam.FieldOfView = target
            zoomActive = false
        end
    end)

    UIS.InputBegan:Connect(function(i, gp)
        if gp or not zoomEnabled or i.KeyCode ~= zoomKey then return end
        if zoomMode == "hold" then startZoom()
        else if zooming then stopZoom() else startZoom() end end
    end)
    UIS.InputEnded:Connect(function(i)
        if zoomMode == "hold" and i.KeyCode == zoomKey then stopZoom() end
    end)

    zoomBtn.MouseButton1Click:Connect(function()
        zoomEnabled = not zoomEnabled
        zoomBtn.Text = "Зум: " .. (zoomEnabled and "Вкл" or "Выкл")
        zoomBtn.BackgroundColor3 = zoomEnabled and C.PINK or C.BTN
        if not zoomEnabled then stopZoom() end
    end)
    modeBtn.MouseButton1Click:Connect(function()
        stopZoom()
        zoomMode = (zoomMode == "hold") and "toggle" or "hold"
        Settings.zoomMode = zoomMode; saveSettings(); refreshMode()
    end)
    sensBtn.MouseButton1Click:Connect(function()
        lowerSens = not lowerSens
        Settings.zoomSens = lowerSens; saveSettings(); refreshSens()
        if zooming then if lowerSens then applySens() else restoreSens() end end
    end)

    gui.Destroying:Connect(function()
        stopZoom(); restoreSens(); unbindScroll()
        zoomConn:Disconnect(); rsConn:Disconnect()
        if camConn then camConn:Disconnect() end
    end)
end

--============================================================
-- FLING
--============================================================
do
    local p = tps["FLING"]
    local Selected = {}
    local Checkboxes = {}
    local Active = false
    local OldPos = nil
    local FPDH = workspace.FallenPartsDestroyHeight
    local dropdownOpen = false

    local flingBtn = mkBtn(p, "Флинг: Выкл", UDim2.new(0, 5, 0, 5), UDim2.new(0.5, -7, 0, 32), C.BTN)
    local afBtn = mkBtn(p, "Анти-флинг: Выкл", UDim2.new(0.5, 2, 0, 5), UDim2.new(0.5, -7, 0, 32), C.BTN)
    local targetBtn = mkBtn(p, "Выбрать цель", UDim2.new(0, 5, 0, 43), UDim2.new(1, -10, 0, 34), C.PINK)
    local targetStatus = mkLbl(p, "Выбрано: 0", UDim2.new(0, 5, 0, 81), UDim2.new(1, -10, 0, 20), C.DIM)

    local dropdown = Instance.new("Frame", p)
    dropdown.Size = UDim2.new(1, -10, 0, 250); dropdown.Position = UDim2.new(0, 5, 0, 105)
    dropdown.BackgroundColor3 = C.BG_DARK; dropdown.BorderSizePixel = 0
    dropdown.Visible = false; corner(dropdown, 6)
    dropdown.ClipsDescendants = true

    local manualBox = mkBox(dropdown, "Ник", UDim2.new(0, 5, 0, 5), UDim2.new(1, -60, 0, 26))
    local manualBtn = mkBtn(dropdown, "Флинг", UDim2.new(1, -52, 0, 5), UDim2.new(0, 47, 0, 26), C.PINK)
    manualBtn.TextSize = 10
    local selAll = mkBtn(dropdown, "Все", UDim2.new(0, 5, 0, 42), UDim2.new(0.5, -7, 0, 22), C.BTN)
    local deselAll = mkBtn(dropdown, "Никого", UDim2.new(0.5, 2, 0, 42), UDim2.new(0.5, -7, 0, 22), C.BTN)
    selAll.TextSize = 10; deselAll.TextSize = 10

    local listF = Instance.new("Frame", dropdown)
    listF.Size = UDim2.new(1, -10, 1, -75); listF.Position = UDim2.new(0, 5, 0, 68)
    listF.BackgroundColor3 = C.BG_IN; listF.BorderSizePixel = 0; corner(listF, 5)

    local scroll = Instance.new("ScrollingFrame", listF)
    scroll.Size = UDim2.new(1, -6, 1, -6); scroll.Position = UDim2.new(0, 3, 0, 3)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = C.PINK
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

    local layout = Instance.new("UIListLayout", scroll)
    layout.SortOrder = Enum.SortOrder.Name; layout.Padding = UDim.new(0, 3)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    local function updateStatus()
        local count = 0
        for _ in pairs(Selected) do count = count + 1 end
        targetStatus.Text = "Выбрано: " .. count
        targetStatus.TextColor3 = count > 0 and C.GREEN or C.DIM
    end

    local function Refresh()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        Checkboxes = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local row = Instance.new("Frame", scroll)
                row.Size = UDim2.new(1, -5, 0, 26); row.BackgroundColor3 = C.BTN
                row.BorderSizePixel = 0; corner(row, 4)
                local cb = Instance.new("TextButton", row)
                cb.Size = UDim2.new(0, 20, 0, 20); cb.Position = UDim2.new(0, 3, 0.5, -10)
                cb.BackgroundColor3 = C.BG_IN; cb.Text = ""; cb.BorderSizePixel = 0; corner(cb, 3)
                local chk = Instance.new("TextLabel", cb)
                chk.Size = UDim2.new(1, 0, 1, 0); chk.BackgroundTransparency = 1
                chk.Text = "X"; chk.TextColor3 = C.PINK
                chk.Font = Enum.Font.GothamBold; chk.TextSize = 14
                chk.Visible = Selected[plr.Name] ~= nil
                local nl = Instance.new("TextLabel", row)
                nl.Size = UDim2.new(1, -30, 1, 0); nl.Position = UDim2.new(0, 28, 0, 0)
                nl.BackgroundTransparency = 1; nl.Text = plr.Name
                nl.TextColor3 = C.TEXT; nl.Font = Enum.Font.Gotham
                nl.TextSize = 11; nl.TextXAlignment = Enum.TextXAlignment.Left
                local click = Instance.new("TextButton", row)
                click.Size = UDim2.new(1, 0, 1, 0); click.BackgroundTransparency = 1
                click.Text = ""; click.ZIndex = 2
                click.MouseEnter:Connect(function() tw(row, 0.15, {BackgroundColor3 = Color3.fromRGB(42, 42, 50)}) end)
                click.MouseLeave:Connect(function() tw(row, 0.2, {BackgroundColor3 = C.BTN}) end)
                click.MouseButton1Click:Connect(function()
                    if Selected[plr.Name] then Selected[plr.Name] = nil; chk.Visible = false
                    else Selected[plr.Name] = plr; chk.Visible = true end
                    updateStatus()
                end)
                Checkboxes[plr.Name] = {row = row, check = chk}
            end
        end
        updateStatus()
    end
    Refresh()
    Players.PlayerAdded:Connect(Refresh)
    Players.PlayerRemoving:Connect(function(plr) Selected[plr.Name] = nil; Refresh() end)

    targetBtn.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        targetBtn.Text = dropdownOpen and "Скрыть" or "Выбрать цель"
        if dropdownOpen then
            Refresh()
            dropdown.Size = UDim2.new(1, -10, 0, 0)
            dropdown.Visible = true
            tw(dropdown, 0.4, {Size = UDim2.new(1, -10, 0, 250)})
            resizeToHeight(460)
        else
            local t = tw(dropdown, 0.4, {Size = UDim2.new(1, -10, 0, 0)})
            t.Completed:Connect(function() if not dropdownOpen then dropdown.Visible = false end end)
            resizeToHeight(206)
        end
    end)
    selAll.MouseButton1Click:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                Selected[plr.Name] = plr
                local cb = Checkboxes[plr.Name]; if cb then cb.check.Visible = true end
            end
        end
        updateStatus()
    end)
    deselAll.MouseButton1Click:Connect(function()
        Selected = {}
        for _, cb in pairs(Checkboxes) do cb.check.Visible = false end
        updateStatus()
    end)

    local function SkidFling(TargetPlayer)
        local Character = LocalPlayer.Character
        if not Character then return end
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart
        local TCharacter = TargetPlayer.Character
        if not TCharacter then return end
        local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
        local TRootPart = THumanoid and THumanoid.RootPart
        local THead = TCharacter:FindFirstChild("Head")
        if Character and Humanoid and RootPart then
            if RootPart.Velocity.Magnitude < 50 then OldPos = RootPart.CFrame end
            if THumanoid and THumanoid.Sit then return end
            if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
            local FPos = function(BasePart, Pos, Ang)
                RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
                Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
                RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
                RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
            end
            local SFBasePart = function(BasePart)
                local TimeToWait = 2; local Time = tick(); local Angle = 0
                repeat
                    if RootPart and THumanoid then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    end
                until Time + TimeToWait < tick() or not Active
            end
            workspace.FallenPartsDestroyHeight = 0/0
            local BV = Instance.new("BodyVelocity"); BV.Parent = RootPart
            BV.Velocity = Vector3.new(0, 0, 0); BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            if TRootPart then SFBasePart(TRootPart) elseif THead then SFBasePart(THead) end
            BV:Destroy()
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            if OldPos then
                repeat
                    RootPart.CFrame = OldPos * CFrame.new(0, .5, 0)
                    Character:SetPrimaryPartCFrame(OldPos * CFrame.new(0, .5, 0))
                    Humanoid:ChangeState("GettingUp")
                    for _, part in pairs(Character:GetChildren()) do
                        if part:IsA("BasePart") then part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new() end
                    end
                    task.wait()
                until (RootPart.Position - OldPos.p).Magnitude < 25
                workspace.FallenPartsDestroyHeight = FPDH
            end
        end
    end

    manualBtn.MouseButton1Click:Connect(function()
        local q = manualBox.Text
        if q == "" then manualBtn.Text = "Введи ник"; task.wait(1); manualBtn.Text = "Флинг"; return end
        q = q:gsub("@", ""):lower()
        local found = nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and (plr.Name:lower():find(q, 1, true) or plr.DisplayName:lower():find(q, 1, true)) then
                found = plr; break
            end
        end
        if not found then manualBtn.Text = "Не найден"; task.wait(1); manualBtn.Text = "Флинг"; return end
        manualBtn.Text = "Флинг..."; manualBtn.BackgroundColor3 = C.RED
        Active = true; pcall(SkidFling, found); Active = false
        manualBtn.Text = "Готово"; manualBtn.BackgroundColor3 = C.PINK
        task.wait(1); manualBtn.Text = "Флинг"; manualBtn.BackgroundColor3 = C.PINK
    end)

    flingBtn.MouseButton1Click:Connect(function()
        local count = 0
        for _ in pairs(Selected) do count = count + 1 end
        if not Active and count == 0 then
            flingBtn.Text = "Сначала выбери цель"; task.wait(1); flingBtn.Text = "Флинг: Выкл"; return
        end
        Active = not Active
        flingBtn.Text = Active and "Флинг: Вкл" or "Флинг: Выкл"
        flingBtn.BackgroundColor3 = Active and C.RED or C.BTN
        if Active then
            task.spawn(function()
                while Active do
                    for _, plr in pairs(Selected) do
                        if Active and plr and plr.Parent then pcall(SkidFling, plr); task.wait(0.1) end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end)

    local afOn = false
    local afConn, afStepConn
    local lastSafe
    local function stopAF()
        if afConn then afConn:Disconnect(); afConn = nil end
        if afStepConn then afStepConn:Disconnect(); afStepConn = nil end
        lastSafe = nil
    end
    afBtn.MouseButton1Click:Connect(function()
        afOn = not afOn
        afBtn.Text = "Анти-флинг: " .. (afOn and "Вкл" or "Выкл")
        afBtn.BackgroundColor3 = afOn and C.PINK or C.BTN
        stopAF()
        if afOn then
            -- 1) другие игроки перестают с тобой сталкиваться (так тебя нельзя «выстрелить»)
            afStepConn = RunService.Stepped:Connect(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    local ch = plr ~= LocalPlayer and plr.Character
                    if ch then
                        for _, part in ipairs(ch:GetChildren()) do
                            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                        end
                    end
                end
            end)
            -- 2) запасной вариант: если скорость нереальная — гасим её и возвращаем на безопасное место
            afConn = RunService.Heartbeat:Connect(function()
                local ch = LocalPlayer.Character
                local root = ch and ch:FindFirstChild("HumanoidRootPart")
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if not (root and hum) or hum.Health <= 0 then return end
                local lv = root.AssemblyLinearVelocity.Magnitude
                local av = root.AssemblyAngularVelocity.Magnitude
                if lv > 700 or av > 250 then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    if lastSafe then root.CFrame = lastSafe end
                elseif not hum.Sit then
                    lastSafe = root.CFrame
                end
            end)
        end
    end)
    gui.Destroying:Connect(stopAF)
end

--============================================================
-- ESP (отдельный таб)
--============================================================
do
    local p = tps["ESP"]
    local espEnabled = false
    local espObjects = {}

    local O = {
        names    = Settings.espNames ~= false,
        hp       = Settings.espHp ~= false,
        dist     = Settings.espDist ~= false,
        fill     = Settings.espFill ~= false,
        box      = Settings.espBox == true,
        tracers  = Settings.espTracers == true,
        teamOnly = Settings.espEnemiesOnly == true,
        colorMode = Settings.espColorMode or "accent",
        maxDist  = Settings.espMaxDist or 3000,
        fillT    = Settings.espFillT or 60,
    }
    local colorModes = {"accent", "team", "health"}
    local colorNames = {accent = "Акцент", team = "Команда", health = "Здоровье"}

    local function saveO()
        Settings.espNames, Settings.espHp, Settings.espDist, Settings.espFill = O.names, O.hp, O.dist, O.fill
        Settings.espBox, Settings.espTracers, Settings.espEnemiesOnly = O.box, O.tracers, O.teamOnly
        Settings.espColorMode, Settings.espMaxDist, Settings.espFillT = O.colorMode, O.maxDist, O.fillT
        saveSettings()
    end

    -- ---------- линии (трейсеры) в отдельном ScreenGui
    local tracerGui
    local function ensureTracerGui()
        if tracerGui and tracerGui.Parent then return end
        tracerGui = Instance.new("ScreenGui")
        tracerGui.Name = "AstriESPLines"; tracerGui.ResetOnSpawn = false
        tracerGui.IgnoreGuiInset = true; tracerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local ok = pcall(function() tracerGui.Parent = gui.Parent end)
        if not ok or not tracerGui.Parent then tracerGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    end

    local function removeESP(plr)
        local o = espObjects[plr]
        if o then
            for _, k in ipairs({"hl", "bb", "box", "line"}) do
                pcall(function() if o[k] then o[k]:Destroy() end end)
            end
            espObjects[plr] = nil
        end
    end

    local function createESP(plr, char)
        removeESP(plr)
        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not head then return end
        local hl = Instance.new("Highlight")
        hl.Name = "AstriESP"
        hl.FillColor = C.PINK; hl.OutlineColor = C.PINK
        hl.FillTransparency = 0.6; hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char; hl.Parent = char

        local box = Instance.new("SelectionBox")
        box.Name = "AstriESPBox"; box.Adornee = char
        box.LineThickness = 0.04; box.SurfaceTransparency = 1
        box.Color3 = C.PINK; box.Visible = false; box.Parent = char

        local bb = Instance.new("BillboardGui")
        bb.Name = "AstriESPName"
        bb.Size = UDim2.new(0, 200, 0, 40)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = head; bb.Parent = char
        local nameLbl = Instance.new("TextLabel", bb)
        nameLbl.Size = UDim2.new(1, 0, 0, 20)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = plr.DisplayName
        nameLbl.TextColor3 = C.PINK
        nameLbl.TextStrokeTransparency = 0.5
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 12
        local infoLbl = Instance.new("TextLabel", bb)
        infoLbl.Size = UDim2.new(1, 0, 0, 18); infoLbl.Position = UDim2.new(0, 0, 0, 20)
        infoLbl.BackgroundTransparency = 1
        infoLbl.Text = ""; infoLbl.TextColor3 = C.GREEN
        infoLbl.TextStrokeTransparency = 0.5
        infoLbl.Font = Enum.Font.Gotham; infoLbl.TextSize = 10
        espObjects[plr] = {char = char, hl = hl, box = box, bb = bb, nameLbl = nameLbl, info = infoLbl, col = C.PINK}
    end

    local function healthColor(ratio) return Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0) end
    local function mainColor(plr, ratio)
        if O.colorMode == "team" then
            local ok, c = pcall(function() return plr.Team and plr.TeamColor.Color end)
            if ok and c then return c end
            return C.PINK
        elseif O.colorMode == "health" then
            return healthColor(ratio)
        end
        return C.PINK
    end

    local function updateESP()
        if not espEnabled then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                local obj = espObjects[plr]
                -- после респавна персонаж новый — пересоздаём подсветку
                if char and (not obj or obj.char ~= char or not obj.hl.Parent) then
                    createESP(plr, char)
                    obj = espObjects[plr]
                end
                if obj and char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local ratio = hum and math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1) or 1
                    local d = (myRoot and root) and (myRoot.Position - root.Position).Magnitude or 0

                    local hide = false
                    if O.teamOnly and LocalPlayer.Team and plr.Team == LocalPlayer.Team then hide = true end
                    if O.maxDist < 3000 and d > O.maxDist then hide = true end
                    obj.hidden = hide

                    local col = mainColor(plr, ratio)
                    obj.col = col
                    obj.hl.Enabled = not hide
                    obj.hl.FillColor = col; obj.hl.OutlineColor = col
                    obj.hl.FillTransparency = O.fill and (O.fillT / 100) or 1
                    obj.box.Visible = O.box and not hide
                    obj.box.Color3 = col

                    obj.bb.Enabled = (O.names or O.hp or O.dist) and not hide
                    obj.nameLbl.Visible = O.names
                    obj.nameLbl.TextColor3 = col
                    local parts = {}
                    if O.hp and hum then parts[#parts + 1] = math.floor(hum.Health) .. " HP" end
                    if O.dist then parts[#parts + 1] = math.floor(d) .. " m" end
                    obj.info.Text = table.concat(parts, "  |  ")
                    obj.info.TextColor3 = healthColor(ratio)
                    obj.info.Position = UDim2.new(0, 0, 0, O.names and 20 or 0)
                elseif obj and not char then
                    removeESP(plr)
                end
            end
        end
    end

    -- линии рисуем каждый кадр, чтобы не дёргались
    local lineConn = RunService.RenderStepped:Connect(function()
        if not (espEnabled and O.tracers) then
            if tracerGui then tracerGui.Enabled = false end
            return
        end
        ensureTracerGui(); tracerGui.Enabled = true
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        local a = Vector2.new(vp.X / 2, vp.Y)
        for plr, obj in pairs(espObjects) do
            if not obj.line then
                local ln = Instance.new("Frame")
                ln.Name = "Line"; ln.AnchorPoint = Vector2.new(0.5, 0.5)
                ln.BorderSizePixel = 0; ln.Visible = false; ln.Parent = tracerGui
                obj.line = ln
            end
            local root = obj.char and obj.char:FindFirstChild("HumanoidRootPart")
            if root and not obj.hidden then
                local pt = cam:WorldToViewportPoint(root.Position)
                if pt.Z > 0 then
                    local b = Vector2.new(pt.X, pt.Y)
                    local dv = b - a
                    obj.line.Size = UDim2.new(0, dv.Magnitude, 0, 1.5)
                    obj.line.Position = UDim2.new(0, (a.X + b.X) / 2, 0, (a.Y + b.Y) / 2)
                    obj.line.Rotation = math.deg(math.atan2(dv.Y, dv.X))
                    obj.line.BackgroundColor3 = obj.col
                    obj.line.Visible = true
                else
                    obj.line.Visible = false
                end
            else
                obj.line.Visible = false
            end
        end
    end)

    task.spawn(function()
        while gui.Parent do
            task.wait(0.25)
            if espEnabled then pcall(updateESP) end
        end
    end)

    -- ---------- интерфейс
    local espBtn = mkBtn(p, "ESP: Выкл", UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 0, 32))
    espBtn.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        Settings.espEnabled = espEnabled
        espBtn.Text = "ESP: " .. (espEnabled and "Вкл" or "Выкл")
        espBtn.BackgroundColor3 = espEnabled and C.PINK or C.BTN
        saveSettings()
        if espEnabled then pcall(updateESP)
        else
            for plr in pairs(espObjects) do removeESP(plr) end
            if tracerGui then tracerGui.Enabled = false end
        end
    end)

    local function mkToggle(text, pos, key)
        local b = mkBtn(p, "", pos, UDim2.new(0.5, -7, 0, 26), C.BTN)
        b.TextSize = 10
        local function refresh()
            b.Text = text .. ": " .. (O[key] and "Вкл" or "Выкл")
            b.BackgroundColor3 = O[key] and C.PINK or C.BTN
        end
        refresh()
        b.MouseButton1Click:Connect(function()
            O[key] = not O[key]; refresh(); saveO()
            if espEnabled then pcall(updateESP) end
        end)
        return b
    end

    mkToggle("Имена",       UDim2.new(0, 5, 0, 44),   "names")
    mkToggle("Здоровье",    UDim2.new(0.5, 2, 0, 44), "hp")
    mkToggle("Дистанция",   UDim2.new(0, 5, 0, 74),   "dist")
    mkToggle("Заливка",     UDim2.new(0.5, 2, 0, 74), "fill")
    mkToggle("Рамка",       UDim2.new(0, 5, 0, 104),  "box")
    mkToggle("Линии",       UDim2.new(0.5, 2, 0, 104), "tracers")
    mkToggle("Только враги", UDim2.new(0, 5, 0, 134), "teamOnly")

    local colorBtn = mkBtn(p, "", UDim2.new(0.5, 2, 0, 134), UDim2.new(0.5, -7, 0, 26), C.BTN)
    colorBtn.TextSize = 10
    local function refreshColor() colorBtn.Text = "Цвет: " .. colorNames[O.colorMode] end
    refreshColor()
    colorBtn.MouseButton1Click:Connect(function()
        local idx = 1
        for k, v in ipairs(colorModes) do if v == O.colorMode then idx = k end end
        O.colorMode = colorModes[idx % #colorModes + 1]
        refreshColor(); saveO()
        if espEnabled then pcall(updateESP) end
    end)

    mkSlider(p, 168, "Макс. дистанция", 100, 3000, O.maxDist, function(v)
        O.maxDist = v; saveO()
        if espEnabled then pcall(updateESP) end
    end, function(v) return v >= 3000 and "без лимита" or tostring(v) end)

    mkSlider(p, 210, "Прозрачность заливки", 0, 100, O.fillT, function(v)
        O.fillT = v; saveO()
        if espEnabled then pcall(updateESP) end
    end, function(v) return v .. "%" end)

    local espHint = mkLbl(p, "Подсвечивает игроков сквозь стены. «Только враги» работает в играх с командами.",
        UDim2.new(0, 5, 0, 252), UDim2.new(1, -10, 0, 30), C.DIM)
    espHint.TextSize = 10

    Players.PlayerRemoving:Connect(function(plr) removeESP(plr) end)
    gui.Destroying:Connect(function()
        espEnabled = false
        lineConn:Disconnect()
        for plr in pairs(espObjects) do removeESP(plr) end
        if tracerGui then tracerGui:Destroy() end
    end)

    -- Автовключение если было включено
    task.spawn(function()
        task.wait(1)
        if Settings.espEnabled then
            espEnabled = true
            espBtn.Text = "ESP: Вкл"; espBtn.BackgroundColor3 = C.PINK
            pcall(updateESP)
        end
    end)
end

--============================================================
-- SET
--============================================================
do
    local p = tps["SET"]
    local profileF = Instance.new("Frame", p)
    profileF.Size = UDim2.new(1, -10, 0, 70); profileF.Position = UDim2.new(0, 5, 0, 5)
    profileF.BackgroundColor3 = C.BG_IN; profileF.BorderSizePixel = 0
    profileF.ClipsDescendants = true; corner(profileF, 6)
    local avatar = Instance.new("ImageLabel", profileF)
    avatar.Size = UDim2.new(0, 56, 0, 56); avatar.Position = UDim2.new(0, 7, 0.5, -28)
    avatar.BackgroundColor3 = C.BTN; avatar.BorderSizePixel = 0; avatar.Image = ""; corner(avatar, 28)
    pcall(function()
        local thumb = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        avatar.Image = thumb
    end)
    local nameLbl = mkLbl(profileF, LocalPlayer.DisplayName, UDim2.new(0, 72, 0, 12), UDim2.new(1, -80, 0, 22), C.PINK)
    nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 14
    nameLbl.TextYAlignment = Enum.TextYAlignment.Center
    local tagLbl = mkLbl(profileF, "@" .. LocalPlayer.Name, UDim2.new(0, 72, 0, 36), UDim2.new(1, -80, 0, 22), C.DIM)
    tagLbl.TextSize = 11
    tagLbl.TextYAlignment = Enum.TextYAlignment.Center

    local hideBtn = mkBtn(p, "", UDim2.new(0, 5, 0, 83), UDim2.new(1, -10, 0, 28), C.BTN)
    local function refreshHideBtn()
        local hide = Settings.hideProfile
        hideBtn.Text = "Скрыть профиль: " .. (hide and "Да" or "Нет")
        hideBtn.BackgroundColor3 = hide and C.PINK or C.BTN
        tw(profileF, 0.35, {Size = UDim2.new(1, -10, 0, hide and 0 or 70)})
        tw(hideBtn, 0.35, {Position = UDim2.new(0, 5, 0, hide and 5 or 83)})
        resizeToTab("SET", 0.4)
    end
    refreshHideBtn()
    hideBtn.MouseButton1Click:Connect(function()
        Settings.hideProfile = not Settings.hideProfile; refreshHideBtn(); saveSettings()
    end)

    mkLbl(p, "Цвет акцента:", UDim2.new(0, 5, 0, 120), UDim2.new(1, -10, 0, 20), C.PINK)
    local colorF = Instance.new("Frame", p)
    colorF.Size = UDim2.new(1, -10, 0, 34); colorF.Position = UDim2.new(0, 5, 0, 143)
    colorF.BackgroundTransparency = 1
    local colorBtns = {}
    local colorNames = {"PINK", "PURPLE", "CYAN", "GREEN", "ORANGE", "RED"}
    for i, cname in ipairs(colorNames) do
        local b = Instance.new("TextButton", colorF)
        b.Size = UDim2.new(1/6, -4, 1, 0); b.Position = UDim2.new((i-1)/6, 2, 0, 0)
        b.BackgroundColor3 = ACCENTS[cname]; b.Text = ""
        b.BorderSizePixel = 0; b.AutoButtonColor = false; corner(b, 5)
        local csc = Instance.new("UIScale", b)
        b.MouseEnter:Connect(function() tw(csc, 0.15, {Scale = 1.08}, Enum.EasingStyle.Back) end)
        b.MouseLeave:Connect(function() tw(csc, 0.2, {Scale = 1}) end)
        table.insert(colorBtns, {btn = b, name = cname})
        if Settings.accentColor == cname then
            local s2 = Instance.new("UIStroke", b); s2.Color = Color3.fromRGB(255, 255, 255); s2.Thickness = 2
        end
        b.MouseButton1Click:Connect(function()
            Settings.accentColor = cname; saveSettings()
            for _, data in ipairs(colorBtns) do
                local s = data.btn:FindFirstChildOfClass("UIStroke")
                if s then s:Destroy() end
                if data.name == cname then
                    local ns = Instance.new("UIStroke", data.btn)
                    ns.Color = Color3.fromRGB(255, 255, 255); ns.Thickness = 2
                end
            end
            notify("Настройки", "Цвет: " .. cname .. " (перезапусти скрипт, чтобы цвет применился везде)")
        end)
    end

    mkLbl(p, "Прозрачность окна:", UDim2.new(0, 5, 0, 185), UDim2.new(1, -10, 0, 20), C.PINK)
    local transBar = Instance.new("Frame", p)
    transBar.Size = UDim2.new(1, -10, 0, 10); transBar.Position = UDim2.new(0, 5, 0, 210)
    transBar.BackgroundColor3 = C.BG_IN; transBar.BorderSizePixel = 0; corner(transBar, 5)
    local transFill = Instance.new("Frame", transBar)
    transFill.Size = UDim2.new(1 - Settings.windowTransparency, 0, 1, 0)
    transFill.BackgroundColor3 = C.PINK; transFill.BorderSizePixel = 0; corner(transFill, 5)
    addKnob(transFill)
    local transDrag = false
    transBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            transDrag = true
            local rel = math.clamp((i.Position.X - transBar.AbsolutePosition.X) / transBar.AbsoluteSize.X, 0, 1)
            Settings.windowTransparency = 1 - rel
            tw(transFill, 0.08, {Size = UDim2.new(rel, 0, 1, 0)})
            frame.BackgroundTransparency = Settings.windowTransparency
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 and transDrag then transDrag = false; saveSettings() end
    end)
    UIS.InputChanged:Connect(function(i)
        if transDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((i.Position.X - transBar.AbsolutePosition.X) / transBar.AbsoluteSize.X, 0, 1)
            Settings.windowTransparency = 1 - rel
            tw(transFill, 0.08, {Size = UDim2.new(rel, 0, 1, 0)})
            frame.BackgroundTransparency = Settings.windowTransparency
        end
    end)

    local saveBtn = mkBtn(p, "Сохранить", UDim2.new(0, 5, 0, 235), UDim2.new(0.5, -7, 0, 32), C.PINK)
    local resetBtn = mkBtn(p, "Сброс", UDim2.new(0.5, 2, 0, 235), UDim2.new(0.5, -7, 0, 32), C.RED)
    saveBtn.MouseButton1Click:Connect(function()
        saveSettings(); saveBtn.Text = "Сохранено"
        task.wait(1.5); saveBtn.Text = "Сохранить"
    end)
    resetBtn.MouseButton1Click:Connect(function()
        Settings = {}; for k, v in pairs(DEFAULT_SETTINGS) do Settings[k] = v end
        saveSettings(); resetBtn.Text = "Сброшено"; task.wait(1.5); resetBtn.Text = "Сброс"
    end)
end

--============================================================
-- INFO
--============================================================
do
    local p = tps["INFO"]
    local t1 = mkLbl(p, "Astri Hub", UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 0, 30), C.PINK)
    t1.TextSize = 24; t1.Font = Enum.Font.GothamBold; t1.Name = "AstriTitle"
    t1.TextYAlignment = Enum.TextYAlignment.Center
    local t2 = mkLbl(p, "Ускорение FPS, полёт, телепорт к курсору,\nследование за игроком, поле зрения и зум,\nфлинг, ESP и настройки.", UDim2.new(0, 5, 0, 45), UDim2.new(1, -10, 0, 60), C.DIM)
    t2.TextYAlignment = Enum.TextYAlignment.Top
end

--============================================================
-- ШРИФТЫ (меняй тут)
--============================================================
local FONT_FAMILY = "rbxasset://fonts/families/Montserrat.json" -- кириллица поддерживается
local USE_ITALIC = true                                         -- false = обычный наклон выключен
local function styleText(o)
    if not (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) then return end
    if o:GetAttribute("fontSet") then return end
    o:SetAttribute("fontSet", true)
    pcall(function()
        local bold = (o.Font == Enum.Font.GothamBold)
        if o.Name == "AstriTitle" then
            o.FontFace = Font.fromEnum(Enum.Font.Fondamento)
        else
            o.FontFace = Font.new(
                FONT_FAMILY,
                bold and Enum.FontWeight.Bold or Enum.FontWeight.Regular,
                USE_ITALIC and Enum.FontStyle.Italic or Enum.FontStyle.Normal
            )
        end
    end)
end
for _, d in ipairs(gui:GetDescendants()) do styleText(d) end
gui.DescendantAdded:Connect(function(d) task.defer(styleText, d) end)

-- Анимация появления окна
tw(frameScale, 0.55, {Scale = 1}, Enum.EasingStyle.Back)
tw(frame, 0.4, {BackgroundTransparency = Settings.windowTransparency})
tw(stroke, 0.5, {Transparency = 0})
resizeToTab("FF", 0.6)

notify("ASTRI HUB v4.9", "Загружено")
