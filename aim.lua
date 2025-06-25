-- Infinix Aimbot v1.0 by Zxcx vence el 25/8/2025
local player = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")

-- Configuración
local aimbotEnabled = false
local aimPart = "Head" -- Puedes cambiar a "HumanoidRootPart" para torso
local smoothness = 0.2 -- Suavizado (0 = instantáneo, 1 = muy lento)
local predictionEnabled = true -- Predicción de movimiento
local showFOVCircle = true -- Círculo visual opcional
local fovRadius = 150 -- Tamaño del círculo (solo para guía visual)
local currentTarget = nil

-- ScreenGui para UI y efectos
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InfinixAimbot"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

-- Círculo de FOV (opcional)
local fovCircle = Instance.new("Frame")
fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundColor3 = Color3.fromRGB(128, 128, 128) -- Plomo
fovCircle.BackgroundTransparency = 0.7
fovCircle.BorderSizePixel = 0
fovCircle.ZIndex = 1000
fovCircle.Visible = false
local fovCircleCorner = Instance.new("UICorner")
fovCircleCorner.CornerRadius = UDim.new(0.5, 0)
fovCircleCorner.Parent = fovCircle
fovCircle.Parent = screenGui

-- Línea Roja (Beam)
local aimLine = Instance.new("Beam")
aimLine.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
aimLine.Width0 = 1 -- Gruesa para máxima visibilidad
aimLine.Width1 = 1
aimLine.Transparency = NumberSequence.new(0)
aimLine.Enabled = false
aimLine.Parent = workspace -- En workspace para renderizado 3D
local aimAttach0 = Instance.new("Attachment")
local aimAttach1 = Instance.new("Attachment")
aimLine.Attachment0 = aimAttach0
aimLine.Attachment1 = aimAttach1

-- Hitmarker (efecto visual al matar)
local hitmarker = Instance.new("Frame")
hitmarker.Size = UDim2.new(0, 20, 0, 20)
hitmarker.Position = UDim2.new(0.5, -10, 0.5, -10)
hitmarker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
hitmarker.BackgroundTransparency = 1
hitmarker.ZIndex = 1001
hitmarker.Parent = screenGui
local hitmarkerCorner = Instance.new("UICorner")
hitmarkerCorner.CornerRadius = UDim.new(0.5, 0)
hitmarkerCorner.Parent = hitmarker

local function showHitmarker()
    hitmarker.BackgroundTransparency = 0
    local tween = tweenService:Create(hitmarker, TweenInfo.new(0.5), {BackgroundTransparency = 1})
    tween:Play()
end

-- Mensaje temporal (solo para activar/desactivar)
local function showTempMessage(text)
    local tempLabel = Instance.new("TextLabel")
    tempLabel.Size = UDim2.new(0, 300, 0, 50)
    tempLabel.Position = UDim2.new(0.5, -150, 0.5, -25)
    tempLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
    tempLabel.BackgroundTransparency = 0.5
    tempLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    tempLabel.Font = Enum.Font.SourceSansBold
    tempLabel.TextSize = 16
    tempLabel.Text = text
    tempLabel.ZIndex = 1001
    tempLabel.Parent = screenGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = tempLabel
    spawn(function()
        wait(3)
        local tween = tweenService:Create(tempLabel, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1})
        tween:Play()
        tween.Completed:Wait()
        tempLabel:Destroy()
    end)
end

-- Actualizar círculo de FOV
local function updateFOVCircle()
    fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
    fovCircle.Visible = showFOVCircle and aimbotEnabled
end

-- Actualizar línea roja
local function updateAimLine(target)
    if target and target.Character and target.Character:FindFirstChild(aimPart) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        aimAttach0.Parent = player.Character.HumanoidRootPart
        aimAttach1.Parent = target.Character[aimPart]
        aimAttach0.WorldPosition = player.Character.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0) -- Ajuste para visibilidad
        aimAttach1.WorldPosition = target.Character[aimPart].Position
        aimLine.Enabled = true
    else
        aimLine.Enabled = false
        aimAttach0.Parent = nil
        aimAttach1.Parent = nil
    end
end

-- Obtener el mejor objetivo
local function getBestTarget()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, plr in ipairs(players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and 
           plr.Character:FindFirstChild(aimPart) and plr.Character:FindFirstChild("Humanoid") and 
           plr.Character.Humanoid.Health > 0 then
            local targetPart = plr.Character[aimPart]
            local worldDistance = (targetPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            local _, onScreen = camera:WorldToScreenPoint(targetPart.Position)

            if onScreen then -- Solo enemigos visibles en pantalla
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {player.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                local rayResult = workspace:Raycast(
                    camera.CFrame.Position,
                    (targetPart.Position - camera.CFrame.Position).Unit * worldDistance,
                    raycastParams
                )
                if not rayResult or rayResult.Instance:IsDescendantOf(plr.Character) then
                    if worldDistance < closestDistance then
                        closestPlayer = plr
                        closestDistance = worldDistance
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Lógica del Aimbot
local aimbotConnection
local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    showTempMessage("Aimbot " .. (aimbotEnabled and "Activado" or "Desactivado"))
    updateFOVCircle()

    if aimbotEnabled then
        if aimbotConnection then aimbotConnection:Disconnect() end
        aimbotConnection = runService.RenderStepped:Connect(function()
            if not aimbotEnabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                currentTarget = nil
                updateAimLine(nil)
                return
            end

            -- Verificar si el objetivo actual es válido
            if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid") and 
               currentTarget.Character.Humanoid.Health > 0 and currentTarget.Character:FindFirstChild(aimPart) then
                local _, onScreen = camera:WorldToScreenPoint(currentTarget.Character[aimPart].Position)
                if not onScreen then
                    currentTarget = nil
                end
            else
                currentTarget = nil
            end

            -- Buscar nuevo objetivo si no hay uno válido
            if not currentTarget then
                currentTarget = getBestTarget()
                if currentTarget then
                    local humanoid = currentTarget.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.Died:Connect(function()
                            if currentTarget == players:GetPlayerFromCharacter(humanoid.Parent) then
                                showHitmarker() -- Efecto al matar
                                currentTarget = nil
                                updateAimLine(nil)
                            end
                        end)
                    end
                end
            end

            -- Apuntar al objetivo
            if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild(aimPart) then
                local targetPos = currentTarget.Character[aimPart].Position
                if predictionEnabled then
                    local velocity = currentTarget.Character.HumanoidRootPart.Velocity
                    local ping = game:GetService("Stats").Network.ServerStatsItem["Ping"]:GetValue() / 1000
                    targetPos = targetPos + velocity * (ping + 0.15) -- Predicción ajustada
                end
                updateAimLine(currentTarget)

                -- Apuntado suave
                local currentLook = camera.CFrame.LookVector
                local targetLook = (targetPos - camera.CFrame.Position).Unit
                local newLook = currentLook:Lerp(targetLook, smoothness)
                camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + newLook)
            else
                updateAimLine(nil)
            end
        end)
    else
        fovCircle.Visible = false
        aimLine.Enabled = false
        currentTarget = nil
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end
end

-- UI Simple
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 250)
frame.Position = UDim2.new(0.5, -100, 0.5, -125)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
frame.BackgroundTransparency = 0.5
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true

local function addButton(parent, text, pos, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.8, 0, 0, 40)
    button.Position = pos
    button.BackgroundColor3 = Color3.fromRGB(20, 20, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text
    button.Font = Enum.Font.SourceSans
    button.TextSize = 16
    button.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    button.Activated:Connect(callback)
    return button
end

local function addLabel(parent, text, pos)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 0, 20)
    label.Position = pos
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.Parent = parent
    return label
end

addButton(frame, "Toggle Aimbot", UDim2.new(0.1, 0, 0, 0), toggleAimbot)
addButton(frame, aimPart == "Head" and "Aim Torso" or "Aim Head", UDim2.new(0.1, 0, 0.15, 0), function()
    aimPart = aimPart == "Head" and "HumanoidRootPart" or "Head"
    showTempMessage("Apuntando a: " .. (aimPart == "Head" and "Cabeza" or "Torso"))
end)
addButton(frame, predictionEnabled and "Disable Prediction" or "Enable Prediction", UDim2.new(0.1, 0, 0.3, 0), function()
    predictionEnabled = not predictionEnabled
    showTempMessage("Predicción: " .. (predictionEnabled and "Activada" or "Desactivada"))
end)
addButton(frame, showFOVCircle and "Hide FOV Circle" or "Show FOV Circle", UDim2.new(0.1, 0, 0.45, 0), function()
    showFOVCircle = not showFOVCircle
    updateFOVCircle()
    showTempMessage("Círculo FOV: " .. (showFOVCircle and "Visible" or "Oculto"))
end)
local smoothnessLabel = addLabel(frame, "Smoothness: " .. smoothness, UDim2.new(0.1, 0, 0.6, 0))
addButton(frame, "Smoothness +", UDim2.new(0.1, 0, 0.7, 0), function()
    smoothness = math.clamp(smoothness + 0.1, 0, 1)
    smoothnessLabel.Text = "Smoothness: " .. string.format("%.1f", smoothness)
end)
addButton(frame, "Smoothness -", UDim2.new(0.1, 0, 0.85, 0), function()
    smoothness = math.clamp(smoothness - 0.1, 0, 1)
    smoothnessLabel.Text = "Smoothness: " .. string.format("%.1f", smoothness)
end)

showTempMessage("Infinix Aimbot v2.0 cargado")