--[[
    Black UI Library
    Utilities/Tween.lua

    Wrapper fino sobre TweenService + helpers de micro-interacao
    (hover, press) usados por praticamente todos os elementos.
]]

local TweenService = game:GetService("TweenService")

local Tween = {}

function Tween.Play(instance, tweenInfo, props)
    local tw = TweenService:Create(instance, tweenInfo, props)
    tw:Play()
    return tw
end

-- Aplica hover (BackgroundColor3 muda) + press (scale sutil) num GuiButton/Frame
-- theme: tabela de tema atual (para pegar TweenFast)
function Tween.ApplyHoverPress(guiObject, colors, theme)
    -- colors = { Normal = Color3, Hover = Color3, Press = Color3? }
    local tweenInfo = theme and theme.TweenFast or TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    guiObject.MouseEnter:Connect(function()
        Tween.Play(guiObject, tweenInfo, { BackgroundColor3 = colors.Hover })
    end)

    guiObject.MouseLeave:Connect(function()
        Tween.Play(guiObject, tweenInfo, { BackgroundColor3 = colors.Normal })
    end)

    if guiObject:IsA("GuiButton") then
        guiObject.MouseButton1Down:Connect(function()
            Tween.Play(guiObject, tweenInfo, { BackgroundColor3 = colors.Press or colors.Hover })
        end)
        guiObject.MouseButton1Up:Connect(function()
            Tween.Play(guiObject, tweenInfo, { BackgroundColor3 = colors.Hover })
        end)
    end
end

-- Pequeno "squish" de escala ao clicar (via UIScale filho)
function Tween.PressScale(guiObject, uiScale, theme)
    local fast = theme and theme.TweenFast or TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Tween.Play(uiScale, fast, { Scale = 0.97 })
        end
    end)
    guiObject.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Tween.Play(uiScale, fast, { Scale = 1 })
        end
    end)
end

return Tween
