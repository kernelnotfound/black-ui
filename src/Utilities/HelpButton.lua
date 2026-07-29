--[[
    Black UI Library
    Utilities/HelpButton.lua

    Botao de ajuda (?) opcional, anexavel no canto de qualquer elemento
    (Button, Toggle, Input, Slider, Dropdown, KeyBind, ColorPicker...).
    Ao clicar, mostra um tooltip flutuante logo abaixo do elemento com o
    texto de ajuda — inspirado no botao "Help" da IceHub, porem sem
    depender de um BlurFrame global fixo.
]]

local Create = require(script.Parent.Create)
local Tween = require(script.Parent.Tween)
local Theme_ = Create.Theme

local HelpButton = {}

-- Adiciona um botao "?" ancorado no canto superior direito de `parent`.
-- `position` (opcional) permite customizar o UDim2 de ancoragem, util para
-- elementos altos (Slider, Dropdown) onde o botao nao deve ficar centralizado
-- verticalmente. Retorna a instancia do botao (ou nil se `helpText` nao foi fornecido).
function HelpButton.Attach(parent, helpText, position)
    if not helpText or helpText == "" then
        return nil
    end

    local theme = Create.GetTheme()

    local Button = Create.New("TextButton", {
        Name = "Help",
        BackgroundColor3 = Theme_("SurfaceElevated"),
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = position or UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        Font = theme.FontBold,
        Text = "?",
        TextColor3 = theme.TextSecondary,
        TextSize = 11,
        ZIndex = 6,
        Parent = parent,
        Children = {
            Create.New("UICorner", { CornerRadius = theme.CornerRadiusPill }),
        },
    })

    Tween.ApplyHoverPress(Button, {
        Normal = theme.SurfaceElevated,
        Hover = theme.SurfaceHover,
    }, theme)

    local Tooltip = Create.New("TextLabel", {
        Name = "HelpTooltip",
        BackgroundColor3 = Theme_("SurfaceElevated"),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 1, 6),
        Size = UDim2.fromOffset(220, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = theme.Font,
        Text = helpText,
        TextColor3 = theme.Text,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Visible = false,
        ZIndex = 20,
        Parent = Button,
        Children = {
            Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
            Create.New("UIStroke", { Color = Theme_("BorderStrong"), Thickness = 1, Transparency = 0.2 }),
            Create.New("UIPadding", {
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
            }),
        },
    })

    local visible = false
    local hideTask = nil

    local function show()
        if hideTask then
            task.cancel(hideTask)
            hideTask = nil
        end
        visible = true
        Tooltip.Visible = true
    end

    local function hide()
        visible = false
        hideTask = task.delay(0.1, function()
            if not visible then
                Tooltip.Visible = false
            end
        end)
    end

    Button.MouseButton1Click:Connect(function()
        if Tooltip.Visible then
            hide()
        else
            show()
        end
    end)

    Button.MouseLeave:Connect(function()
        task.delay(1.5, function()
            if visible then
                hide()
            end
        end)
    end)

    return Button
end

return HelpButton
