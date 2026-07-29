--[[
    Black UI Library
    Components/MobileToggle.lua

    Botao flutuante arrastavel exibido apenas em dispositivos mobile
    (touch), usado para mostrar/esconder a janela principal sem
    depender de teclado (o keybind RightControl nao existe no celular).
]]

local Create = require(script.Parent.Parent.Utilities.Create)
local Draggable = require(script.Parent.Parent.Utilities.Draggable)
local Tween = require(script.Parent.Parent.Utilities.Tween)
local Platform = require(script.Parent.Parent.Utilities.Platform)
local Theme_ = Create.Theme

local MobileToggle = {}

function MobileToggle.Create(Black, window)
    if not Platform.IsMobile then
        return nil
    end

    local theme = Create.GetTheme()

    local Bubble = Create.New("Frame", {
        Name = "MobileToggle",
        BackgroundColor3 = Theme_("Surface"),
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(16, 120),
        Size = UDim2.fromOffset(48, 48),
        Parent = Black.ScreenGui,
        Children = {
            Create.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Create.New("UIStroke", { Color = Theme_("BorderStrong"), Thickness = 1 }),
        },
    })

    local Glyph = Create.New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = theme.FontBold,
        Text = "B",
        TextColor3 = Theme_("Text"),
        TextSize = 18,
        Parent = Bubble,
    })

    local HitButton = Create.New("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        Parent = Bubble,
    })

    Draggable.Enable(Bubble, Bubble, { ClampToScreen = true })

    -- Evita que o "click" dispare apos um drag longo:
    -- so alterna se o movimento total foi pequeno.
    local pressStart = nil
    local startPos = nil

    HitButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressStart = input.Position
            startPos = Bubble.Position
        end
    end)

    HitButton.InputEnded:Connect(function(input)
        if not pressStart then
            return
        end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local moved = (input.Position - pressStart).Magnitude
            if moved < 8 then
                window:SetVisible(not window.Toggled)
                Tween.Play(Bubble, theme.TweenFast, { Size = UDim2.fromOffset(42, 42) })
                task.delay(0.1, function()
                    Tween.Play(Bubble, theme.TweenFast, { Size = UDim2.fromOffset(48, 48) })
                end)
            end
            pressStart = nil
        end
    end)

    return Bubble
end

return MobileToggle
