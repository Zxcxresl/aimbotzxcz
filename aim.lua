-- Infinix Aimbot v3.0 (External, Minimal Dark UI)
-- Autor original base: Zxcxresl | Mejora: ALEX + GPT-5
-- Características: AimPart Head/Torso, Smooth, FOV, Predicción, TeamCheck, VisibleOnly, HoldKey, Hitmarker, Beam opcional.

-----------------------
-- Servicios & Estado
-----------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Esperas seguras
repeat task.wait() until LocalPlayer and LocalPlayer.Character and LocalPlayer:FindFirstChildOfClass("PlayerGui")

--------------------------------
-- Configuración (defaults)
--------------------------------
local Config = {
    Enabled = false,
    HoldToAim = false,         -- si true, solo apunta mientras mantienes RightMouse
    AimPart = "Head",          -- "Head" o "HumanoidRootPart"
    Smoothness = 0.25,         -- 0 = instantáneo, 1 = muy lento
    FOV = 140,                 -- radio en píxeles (círculo se dibuja en centro)
    ShowFOV = true,
    Prediction = true,
    TeamCheck = true,
    VisibleOnly = true,        -- raycast entre cámara y target
    ShowBeam = false,          -- línea roja al objetivo
    TargetRefresh = 0.25,      -- cada X segundos se calcula mejor target
}

--------------------------------
-- UI Minimalista (ScreenGui)
--------------------------------
local Gui = Instance.new("ScreenGui")
Gui.Name = "InfinixAimbotUI"
Gui.ResetOnSpawn = false
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Marco principal
local Frame = Instance.new("Frame")
Frame.Name = "Main"
Frame.Size = UDim2.new(0, 310, 0, 320)
Frame.Position = UDim2.new(0, 20, 0.5, -160)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
Frame.BackgroundTransparency = 0.08
Frame.Active = true
Frame.Draggable = true
Frame.Parent = Gui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 10)

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -16, 0, 28)
Title.Position = UDim2.new(0, 8, 0, 8)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextColor3 = Color3.fromRGB(230, 230, 255)
Title.Text = "Infinix Aimbot v3.0"
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

-- Línea separadora
local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(1, -16, 0, 1)
Sep.Position = UDim2.new(0, 8, 0, 40)
Sep.BackgroundColor3 = Color3.fromRGB(40, 40, 56)
Sep.BorderSizePixel = 0
Sep.Parent = Frame

-- Contenedor de controles
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -56)
Scroll.Position = UDim2.new(0, 8, 0, 48)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 160)
Scroll.Parent = Frame

local Layout = Instance.new("UIListLayout", Scroll)
Layout.Padding = UDim.new(0, 8)
Layout.SortOrder = Enum.SortOrder.LayoutOrder

local function addToggle(name, initial, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -6, 0, 30)
    holder.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    holder.BorderSizePixel = 0
    holder.Parent = Scroll
    local corner = Instance.new("UICorner", holder)
    corner.CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(210, 210, 230)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = name
    lbl.Parent = holder

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 22)
    btn.Position = UDim2.new(1, -56, 0.5, -11)
    btn.BackgroundColor3 = initial and Color3.fromRGB(32, 120, 255) or Color3.fromRGB(60, 60, 80)
    btn.Text = initial and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(245,245,255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = holder
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = initial
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(32, 120, 255) or Color3.fromRGB(60,60,80)
        callback(state)
    end)

    return {
        Set = function(v)
            state = v
            btn.Text = state and "ON" or "OFF"
            btn.BackgroundColor3 = state and Color3.fromRGB(32, 120, 255) or Color3.fromRGB(60,60,80)
            callback(state)
        end
    }
end

local function addOption(name, options, currentIndex, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -6, 0, 30)
    holder.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    holder.BorderSizePixel = 0
    holder.Parent = Scroll
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -130, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(210, 210, 230)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = name
    lbl.Parent = holder

    local left = Instance.new("TextButton")
    left.Size = UDim2.new(0, 24, 0, 22)
    left.Position = UDim2.new(1, -96, 0.5, -11)
    left.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    left.Text = "<"
    left.TextColor3 = Color3.fromRGB(230,230,255)
    left.TextSize = 14
    left.Font = Enum.Font.GothamBold
    left.Parent = holder
    Instance.new("UICorner", left).CornerRadius = UDim.new(0, 6)

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(0, 56, 0, 22)
    valueLbl.Position = UDim2.new(1, -68, 0.5, -11)
    valueLbl.BackgroundColor3 = Color3.fromRGB(36,36,50)
    valueLbl.TextColor3 = Color3.fromRGB(230,230,255)
    valueLbl.TextSize = 12
    valueLbl.Font = Enum.Font.Gotham
    valueLbl.Text = tostring(options[currentIndex])
    valueLbl.Parent = holder
    Instance.new("UICorner", valueLbl).CornerRadius = UDim.new(0, 6)

    local right = Instance.new("TextButton")
    right.Size = UDim2.new(0, 24, 0, 22)
    right.Position = UDim2.new(1, -8 - 24, 0.5, -11)
    right.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    right.Text = ">"
    right.TextColor3 = Color3.fromRGB(230,230,255)
    right.TextSize = 14
    right.Font = Enum.Font.GothamBold
    right.Parent = holder
    Instance.new("UICorner", right).CornerRadius = UDim.new(0, 6)

    local idx = currentIndex
    local function apply()
        valueLbl.Text = tostring(options[idx])
        callback(options[idx], idx)
    end
    left.MouseButton1Click:Connect(function()
        idx = idx - 1
        if idx < 1 then idx = #options end
        apply()
    end)
    right.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        apply()
    end)
    apply()
    return { SetIndex = function(i) idx = i; apply() end }
end

local function addStepper(name, min, max, step, default, callback, suffix)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -6, 0, 30)
    holder.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    holder.BorderSizePixel = 0
    holder.Parent = Scroll
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -130, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(210, 210, 230)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = name
    lbl.Parent = holder

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 24, 0, 22)
    minus.Position = UDim2.new(1, -96, 0.5, -11)
    minus.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    minus.Text = "-"
    minus.TextColor3 = Color3.fromRGB(230,230,255)
    minus.TextSize = 14
    minus.Font = Enum.Font.GothamBold
    minus.Parent = holder
    Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 6)

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(0, 56, 0, 22)
    valueLbl.Position = UDim2.new(1, -68, 0.5, -11)
    valueLbl.BackgroundColor3 = Color3.fromRGB(36,36,50)
    valueLbl.TextColor3 = Color3.fromRGB(230,230,255)
    valueLbl.TextSize = 12
    valueLbl.Font = Enum.Font.Gotham
    valueLbl.Text = tostring(default)..(suffix or "")
    valueLbl.Parent = holder
    Instance.new("UICorner", valueLbl).CornerRadius = UDim.new(0, 6)

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 24, 0, 22)
    plus.Position = UDim2.new(1, -8 - 24, 0.5, -11)
    plus.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(230,230,255)
    plus.TextSize = 14
    plus.Font = Enum.Font.GothamBold
    plus.Parent = holder
    Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 6)

    local value = default
    local function apply()
        value = math.clamp(value, min, max)
        valueLbl.Text = (math.floor((value/step)+0.5)*step)
        valueLbl.Text = tostring(valueLbl.Text) .. (suffix or "")
        callback(tonumber(valueLbl.Text:gsub(suffix or "", "")))
    end
    minus.MouseButton1Click:Connect(function()
        value = value - step
        apply()
    end)
    plus.MouseButton1Click:Connect(function()
        value = value + step
        apply()
    end)
    apply()
    return { Set = function(v) value = v; apply() end }
end

local function addButton(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(32, 120, 255)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(245,245,255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

--------------------------------
-- FOV Circle + Hitmarker + Beam
--------------------------------
local FOVCircle = Instance.new("Frame")
FOVCircle.Size = UDim2.fromOffset(Config.FOV*2, Config.FOV*2)
FOVCircle.Position = UDim2.new(0.5, -Config.FOV, 0.5, -Config.FOV)
FOVCircle.AnchorPoint = Vector2.new(0.0, 0.0) -- ya compensado arriba
FOVCircle.BackgroundColor3 = Color3.fromRGB(120, 120, 140)
FOVCircle.BackgroundTransparency = 0.8
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = Config.ShowFOV
FOVCircle.ZIndex = 999
FOVCircle.Parent = Gui
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(0.5, 0)

local Hitmarker = Instance.new("Frame")
Hitmarker.Size = UDim2.new(0, 18, 0, 18)
Hitmarker.Position = UDim2.new(0.5, -9, 0.5, -9)
Hitmarker.BackgroundColor3 = Color3.fromRGB(255,255,255)
Hitmarker.BackgroundTransparency = 1
Hitmarker.ZIndex = 1000
Hitmarker.Parent = Gui
Instance.new("UICorner", Hitmarker).CornerRadius = UDim.new(0.5, 0)

local function ShowHitmarker()
    Hitmarker.BackgroundTransparency = 0
    local tw = TweenService:Create(Hitmarker, TweenInfo.new(0.35), {BackgroundTransparency = 1})
    tw:Play()
end

-- Beam rojo (opcional)
local Beam = Instance.new("Beam")
Beam.Color = ColorSequence.new(Color3.fromRGB(255,0,0))
Beam.Width0, Beam.Width1 = 1, 1
Beam.Transparency = NumberSequence.new(0)
Beam.Enabled = false
Beam.Parent = workspace
local Attach0 = Instance.new("Attachment")
local Attach1 = Instance.new("Attachment")
Beam.Attachment0 = Attach0
Beam.Attachment1 = Attach1

local function UpdateBeam(target)
    if not Config.ShowBeam then
        Beam.Enabled = false
        Attach0.Parent = nil
        Attach1.Parent = nil
        return
    end
    if target and target.Character and target.Character:FindFirstChild(Config.AimPart) and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Attach0.Parent = LocalPlayer.Character.HumanoidRootPart
        Attach1.Parent = target.Character[Config.AimPart]
        Attach0.WorldPosition = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0,1.2,0)
        Attach1.WorldPosition = target.Character[Config.AimPart].Position
        Beam.Enabled = true
    else
        Beam.Enabled = false
        Attach0.Parent = nil
        Attach1.Parent = nil
    end
end

--------------------------------
-- Targeting helpers
--------------------------------
local CurrentTarget = nil
local RightMouseDown = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightMouseDown = true
    end
end)
UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightMouseDown = false
    end
end)

local function IsAlive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function IsTeammate(plr)
    if not Config.TeamCheck then return false end
    if LocalPlayer.Team and plr.Team then
        return plr.Team == LocalPlayer.Team
    end
    if LocalPlayer.TeamColor and plr.TeamColor then
        return plr.TeamColor == LocalPlayer.TeamColor
    end
    return false
end

local function InFOV(worldPos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen then return false end
    local cx, cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
    local dx, dy = screenPos.X - cx, screenPos.Y - cy
    local dist = math.sqrt(dx*dx + dy*dy)
    return dist <= Config.FOV, dist
end

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Blacklist

local function Visible(plr, targetPos)
    if not Config.VisibleOnly then return true end
    if not LocalPlayer.Character then return false end
    RayParams.FilterDescendantsInstances = {LocalPlayer.Character, plr.Character}
    local dir = (targetPos - Camera.CFrame.Position)
    local result = workspace:Raycast(Camera.CFrame.Position, dir.Unit * dir.Magnitude, RayParams)
    return (not result) or result.Instance:IsDescendantOf(plr.Character)
end

local function GetPingSeconds()
    local pingMs = 0
    local item = Stats.Network.ServerStatsItem["Ping"]
    if item then pingMs = item:GetValue() end
    return (pingMs / 1000)
end

local function GetBestTarget()
    local best, bestMetric = nil, 1/0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) and not IsTeammate(plr) then
            local char = plr.Character
            local part = char and char:FindFirstChild(Config.AimPart)
            if part then
                local inFov, pxDist = InFOV(part.Position)
                if inFov and Visible(plr, part.Position) then
                    -- Métrica: distancia en píxeles al centro (menor = mejor)
                    if pxDist < bestMetric then
                        bestMetric = pxDist
                        best = plr
                    end
                end
            end
        end
    end
    return best
end

--------------------------------
-- Loop de objetivo + aimbot
--------------------------------
-- Refresca objetivo cada X segundos
task.spawn(function()
    while task.wait(Config.TargetRefresh) do
        if not Config.Enabled then
            CurrentTarget = nil
        else
            if Config.HoldToAim and not RightMouseDown then
                CurrentTarget = nil
            else
                -- Si el target actual ya no sirve, busca otro
                if not (CurrentTarget and IsAlive(CurrentTarget) and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(Config.AimPart)) then
                    CurrentTarget = GetBestTarget()
                else
                    -- Si se salió del FOV o no es visible, buscar otro
                    local okFov = InFOV(CurrentTarget.Character[Config.AimPart].Position)
                    local okVis = Visible(CurrentTarget, CurrentTarget.Character[Config.AimPart].Position)
                    if not okFov or not okVis then
                        CurrentTarget = GetBestTarget()
                    end
                end
            end
        end
    end
end)

-- Suavizado/apuntado
RunService.RenderStepped:Connect(function()
    if not Config.Enabled then
        UpdateBeam(nil)
        return
    end
    if Config.HoldToAim and not RightMouseDown then
        UpdateBeam(nil)
        return
    end

    if CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(Config.AimPart) then
        local aimPos = CurrentTarget.Character[Config.AimPart].Position
        if Config.Prediction and CurrentTarget.Character:FindFirstChild("HumanoidRootPart") then
            local v = CurrentTarget.Character.HumanoidRootPart.Velocity
            local ping = GetPingSeconds()
            aimPos = aimPos + v * (ping + 0.12)
        end

        UpdateBeam(CurrentTarget)

        -- Apuntar con suavizado
        local curPos = Camera.CFrame.Position
        local curLook = Camera.CFrame.LookVector
        local tgtLook = (aimPos - curPos).Unit
        local newLook = curLook:Lerp(tgtLook, math.clamp(Config.Smoothness, 0, 1))
        Camera.CFrame = CFrame.new(curPos, curPos + newLook)
    else
        UpdateBeam(nil)
    end
end)

-- Hitmarker al morir el objetivo
local function HookDeath(plr)
    if not plr or not plr.Character then return end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.Died:Connect(function()
        if CurrentTarget and Players:GetPlayerFromCharacter(hum.Parent) == CurrentTarget then
            ShowHitmarker()
            CurrentTarget = nil
            UpdateBeam(nil)
        end
    end)
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.1)
        HookDeath(plr)
    end)
end)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer and plr.Character then
        HookDeath(plr)
    end
end

--------------------------------
-- Controles de la UI
--------------------------------
local togEnable = addToggle("Aimbot", false, function(v) Config.Enabled = v end)
local togHold   = addToggle("Hold (Right Click)", false, function(v) Config.HoldToAim = v end)
local optAimPart= addOption("Aim Part", {"Head", "HumanoidRootPart"}, (Config.AimPart=="Head") and 1 or 2, function(val) Config.AimPart = val end)
local stepSmooth= addStepper("Smoothness", 0, 1, 0.05, Config.Smoothness, function(v) Config.Smoothness = v end)
local stepFOV   = addStepper("FOV (px)", 40, 400, 10, Config.FOV, function(v)
    Config.FOV = v
    FOVCircle.Size = UDim2.fromOffset(v*2, v*2)
    FOVCircle.Position = UDim2.new(0.5, -v, 0.5, -v)
end, "")

local togFOV    = addToggle("Show FOV Circle", Config.ShowFOV, function(v)
    Config.ShowFOV = v
    FOVCircle.Visible = v
end)

local togPred   = addToggle("Prediction", Config.Prediction, function(v) Config.Prediction = v end)
local togTeam   = addToggle("Team Check", Config.TeamCheck, function(v) Config.TeamCheck = v end)
local togVis    = addToggle("Visible Only", Config.VisibleOnly, function(v) Config.VisibleOnly = v end)
local togBeam   = addToggle("Show Beam", Config.ShowBeam, function(v) Config.ShowBeam = v; if not v then UpdateBeam(nil) end)

-- Botón rápido de Toggle Aimbot
addButton("Toggle Aimbot", function()
    Config.Enabled = not Config.Enabled
    togEnable.Set(Config.Enabled)
end)

-- Mensaje inicial
do
    local temp = Instance.new("TextLabel")
    temp.Size = UDim2.new(0, 260, 0, 28)
    temp.Position = UDim2.new(0, 24, 1, -36)
    temp.BackgroundTransparency = 0.4
    temp.BackgroundColor3 = Color3.fromRGB(32, 120, 255)
    temp.Font = Enum.Font.GothamBold
    temp.TextSize = 13
    temp.TextColor3 = Color3.fromRGB(255,255,255)
    temp.Text = "Infinix Aimbot v3.0 cargado"
    temp.ZIndex = 999
    temp.Parent = Frame
    Instance.new("UICorner", temp).CornerRadius = UDim.new(0, 8)
    task.delay(2.5, function()
        TweenService:Create(temp, TweenInfo.new(0.4), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        task.delay(0.45, function() temp:Destroy() end)
    end)
end

-- Fin del script