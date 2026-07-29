--[[
    Black UI Library
    Utilities/Draggable.lua

    Logica de arrastar (mouse + touch) com clamp dentro do viewport,
    para que a janela nunca saia completamente da tela.
]]

local UserInputService = game:GetService("UserInputService")

local Draggable = {}

local function isDragInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

-- Calcula a Position (relativa ao AnchorPoint de `target`) que mantem a
-- instancia inteiramente dentro do viewport, a partir de uma Position
-- candidata (currentPos). Retorna um novo UDim2.
local function clampPositionToScreen(target, currentPos)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local absSize = target.AbsoluteSize
    local anchor = target.AnchorPoint

    -- Limites em termos do canto top-left real da instancia (independente
    -- do AnchorPoint), permitindo toda a janela ser arrastada pela tela.
    local minLeft, maxLeft = 0, viewport.X - absSize.X
    local minTop, maxTop = 0, viewport.Y - absSize.Y

    -- Converte de volta para o espaco de "Position" (que e relativo ao
    -- AnchorPoint), somando o deslocamento do anchor.
    local anchorOffsetX = anchor.X * absSize.X
    local anchorOffsetY = anchor.Y * absSize.Y

    local scaleX, scaleY = currentPos.X.Scale, currentPos.Y.Scale
    local absScaleX = scaleX * viewport.X
    local absScaleY = scaleY * viewport.Y

    local minX = minLeft - absScaleX + anchorOffsetX
    local maxX = maxLeft - absScaleX + anchorOffsetX
    local minY = minTop - absScaleY + anchorOffsetY
    local maxY = maxTop - absScaleY + anchorOffsetY

    local clampedX = math.clamp(currentPos.X.Offset, minX, maxX)
    local clampedY = math.clamp(currentPos.Y.Offset, minY, maxY)

    return UDim2.new(scaleX, clampedX, scaleY, clampedY)
end

-- Reclampa a posicao ATUAL de `target` dentro do viewport, sem precisar de
-- um evento de drag em andamento. Util apos redimensionar a janela (ex:
-- minimizar/maximizar), garantindo que ela nunca fique fora da tela e
-- inacessivel.
function Draggable.ClampToScreen(target)
    target.Position = clampPositionToScreen(target, target.Position)
end

-- target: GuiObject que sera movido (Position)
-- handle: GuiObject que recebe o input (pode ser o mesmo que target)
-- options: { ClampToScreen: boolean }
function Draggable.Enable(target, handle, options)
    options = options or {}
    local clamp = options.ClampToScreen ~= false

    local dragging = false
    local dragStart = nil
    local startPos = nil
    local inputChangedConn = nil

    local function update(input)
        local delta = input.Position - dragStart
        local newX = startPos.X.Offset + delta.X
        local newY = startPos.Y.Offset + delta.Y
        local candidate = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)

        if clamp then
            candidate = clampPositionToScreen(target, candidate)
        end

        target.Position = candidate
    end

    handle.InputBegan:Connect(function(input)
        if not isDragInput(input) then
            return
        end
        dragging = true
        dragStart = input.Position
        startPos = target.Position

        local changedConn
        changedConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if changedConn then
                    changedConn:Disconnect()
                end
            end
        end)
    end)

    inputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update(input)
        end
    end)

    return {
        Disconnect = function()
            if inputChangedConn then
                inputChangedConn:Disconnect()
            end
        end,
    }
end

return Draggable
