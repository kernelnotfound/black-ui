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

        if clamp then
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
            local absSize = target.AbsoluteSize

            local minX, maxX = 0, viewport.X - absSize.X
            local minY, maxY = 0, viewport.Y - absSize.Y

            -- calcula offset absoluto considerando a escala atual
            local scaleX, scaleY = startPos.X.Scale, startPos.Y.Scale
            local absStartX = scaleX * viewport.X
            local absStartY = scaleY * viewport.Y

            newX = math.clamp(newX, minX - absStartX, maxX - absStartX)
            newY = math.clamp(newY, minY - absStartY, maxY - absStartY)
        end

        target.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
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
