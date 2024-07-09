local fov = 20  -- Cambiado a 15
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Cam = game.Workspace.CurrentCamera

local FOVring = Drawing.new("Circle")
FOVring.Visible = false
FOVring.Thickness = 2
FOVring.Filled = false
FOVring.Radius = fov
FOVring.Position = Cam.ViewportSize / 2

local lastSwitchTime = 0
local switchInterval = 0.5  -- Intervalo de cambio en segundos
local targetPart = "Head"  -- Parte objetivo inicial

local function updateDrawings()
    local camViewportSize = Cam.ViewportSize
    FOVring.Position = camViewportSize / 2
    FOVring.Radius = fov -- Asegúrese de que el radio se actualice en cada cuadro
end

local function onKeyDown(input)
    if input.KeyCode == Enum.KeyCode.Delete then
        RunService:UnbindFromRenderStep("FOVUpdate")
        FOVring:Remove()
    end
end

UserInputService.InputBegan:Connect(onKeyDown)

local function lookAt(target)
    local lookVector = (target - Cam.CFrame.Position).unit
    local newCFrame = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + lookVector)
    Cam.CFrame = newCFrame
end

local function isEnemy(player)
    local localPlayer = Players.LocalPlayer
    return player.Team ~= localPlayer.Team
end

local function isAlive(player)
    return player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

local function getClosestPlayerInFOV(trg_part)
    local nearest = nil
    local last = math.huge
    local playerMousePos = Cam.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and isEnemy(player) and isAlive(player) then
            local part = player.Character and player.Character:FindFirstChild(trg_part)
            if part then
                local ePos, isVisible = Cam:WorldToViewportPoint(part.Position)
                local distance = (Vector2.new(ePos.x, ePos.y) - playerMousePos).Magnitude

                if distance < last and isVisible and distance < fov then
                    last = distance
                    nearest = player
                end
            end
        end
    end

    return nearest
end

RunService.RenderStepped:Connect(function()
    updateDrawings()
    
    -- Cambiar la parte objetivo cada cierto intervalo
    if tick() - lastSwitchTime > switchInterval then
        if targetPart == "Head" then
            targetPart = "Torso"
        else
            targetPart = "Head"
        end
        lastSwitchTime = tick()
    end

    local closest = getClosestPlayerInFOV(targetPart)
    -- Verificar tanto "Torso" como "UpperTorso" para asegurarnos de que funcione en ambos tipos de personajes
    if closest and (closest.Character:FindFirstChild("Head") or closest.Character:FindFirstChild("Torso") or closest.Character:FindFirstChild("UpperTorso")) then
        local targetPosition
        if targetPart == "Head" then
            targetPosition = closest.Character.Head.Position
        else
            targetPosition = closest.Character:FindFirstChild("Torso") and closest.Character.Torso.Position or closest.Character.UpperTorso.Position
        end
        lookAt(targetPosition)
    end
end)
