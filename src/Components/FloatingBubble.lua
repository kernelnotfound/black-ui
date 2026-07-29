--[[
    Black UI Library
    Components/FloatingBubble.lua

    Botao circular flutuante e arrastavel (livremente pela tela, com clamp),
    usado tanto pelo MobileToggle (automatico em dispositivos touch) quanto
    pelo MinimizeStyle == "Bubble" do Window (escolha explicita de quem
    codifica o script, disponivel em qualquer plataforma).
]]

local Create = require(script.Parent.Parent.Utilities.Create)
local Draggable = require(script.Parent.Parent.Utilities.Draggable)
local Tween = require(script.Parent.Parent.Utilities.Tween)
local Theme_ = Create.Theme

local FloatingBubble = {}

-- opts:
--   Parent (Instance)         - onde a bolha e parentada (ex: Black.ScreenGui)
--   Position (UDim2?)         - posicao inicial (default: canto superior esquerdo)
--   Icon (string?)            - rbxassetid:// do icone customizado (whitelabel)
--   IconColor (Color3?)
--   Glyph (string?)           - texto usado se nenhum Icon for fornecido (default: "B")
--   OnClick (function)        - chamado ao clicar (nao ao arrastar)
function FloatingBubble.Create(opts)
    opts = opts or {}
    local theme = Create.GetTheme()

    local Bubble = Create.New("Frame", {
        Name = "FloatingBubble",
        BackgroundColor3 = Theme_("Surface"),
        AnchorPoint = Vector2.new(0, 0),
        Position = opts.Position or UDim2.fromOffset(16, 120),
        Size = UDim2.fromOffset(48, 48),
        Parent = opts.Parent,
        Children = {
            Create.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Create.New("UIStroke", { Color = Theme_("BorderStrong"), Thickness = 1 }),
        },
    })

    if opts.Icon and opts.Icon ~= "" then
        Create.New("ImageLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(24, 24),
            Image = opts.Icon,
            ImageColor3 = opts.IconColor or Color3.fromRGB(255, 255, 255),
            Parent = Bubble,
        })
    else
        Create.New("TextLabel", {
            Name = "Glyph",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Font = theme.FontBold,
            Text = opts.Glyph or "B",
            TextColor3 = Theme_("Text"),
            TextSize = 18,
            Parent = Bubble,
        })
    end

    local HitButton = Create.New("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        Parent = Bubble,
    })

    local dragHandle = Draggable.Enable(Bubble, Bubble, { ClampToScreen = true })

    -- Evita que o "click" dispare apos um drag longo:
    -- so aciona o callback se o movimento total foi pequeno.
    local pressStart = nil

    HitButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressStart = input.Position
        end
    end)

    HitButton.InputEnded:Connect(function(input)
        if not pressStart then
            return
        end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local moved = (input.Position - pressStart).Magnitude
            if moved < 8 and opts.OnClick then
                Tween.Play(Bubble, theme.TweenFast, { Size = UDim2.fromOffset(42, 42) })
                task.delay(0.1, function()
                    Tween.Play(Bubble, theme.TweenFast, { Size = UDim2.fromOffset(48, 48) })
                end)
                opts.OnClick()
            end
            pressStart = nil
        end
    end)

    return {
        Instance = Bubble,
        Destroy = function()
            if dragHandle then
                dragHandle.Disconnect()
            end
            Bubble:Destroy()
        end,
    }
end

return FloatingBubble
