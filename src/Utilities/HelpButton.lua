--[[
    Black UI Library
    Utilities/HelpButton.lua

    Botao de ajuda (?) opcional, anexavel no canto de qualquer elemento
    (Button, Toggle, Input, Slider, Dropdown, KeyBind, ColorPicker...).
    Ao clicar, mostra um tooltip flutuante com o texto de ajuda.

    O tooltip NAO e filho do botao: ele e parenteado no ScreenGui raiz e
    posicionado em coordenadas absolutas. Isso e necessario porque a janela
    (Root/Content) e a pagina de cada tab (ScrollingFrame) usam
    ClipsDescendants — um tooltip filho do botao seria cortado ao passar
    dos limites do card/pagina.
]]

local GuiService = game:GetService("GuiService")

local Create = require(script.Parent.Create)
local Tween = require(script.Parent.Tween)
local Theme_ = Create.Theme

local HelpButton = {}

local TOOLTIP_WIDTH = 220
local TOOLTIP_GAP = 6

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

    local Tooltip = nil

    local function ensureTooltip()
        if Tooltip then
            return Tooltip
        end

        local screenGui = Button:FindFirstAncestorOfClass("ScreenGui")
        if not screenGui then
            return nil
        end

        Tooltip = Create.New("TextLabel", {
            Name = "HelpTooltip",
            BackgroundColor3 = Theme_("SurfaceElevated"),
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.fromOffset(TOOLTIP_WIDTH, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = theme.Font,
            Text = helpText,
            TextColor3 = theme.Text,
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Visible = false,
            ZIndex = 500,
            Parent = screenGui,
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

        return Tooltip
    end

    -- Posiciona o tooltip logo abaixo do botao, convertendo AbsolutePosition
    -- para o espaco de Position do ScreenGui. Com IgnoreGuiInset = true, o
    -- motor reporta AbsolutePosition deslocado por -inset, entao somamos o
    -- inset de volta. Tambem mantemos o tooltip dentro da tela.
    local function reposition()
        if not Tooltip then
            return
        end

        local insetTop = select(1, GuiService:GetGuiInset()).Y
        local buttonAbs = Button.AbsolutePosition
        local buttonSize = Button.AbsoluteSize

        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)

        -- Ancora no canto superior direito, alinhado a direita do botao.
        local targetRight = buttonAbs.X + buttonSize.X
        local targetTop = buttonAbs.Y + buttonSize.Y + TOOLTIP_GAP + insetTop

        -- Clamp horizontal: com AnchorPoint (1,0) a borda esquerda fica em
        -- (targetRight - TOOLTIP_WIDTH), entao garantimos que ela nao saia
        -- da tela pela esquerda nem pela direita.
        targetRight = math.clamp(targetRight, TOOLTIP_WIDTH + 8, viewport.X - 8)

        Tooltip.Position = UDim2.fromOffset(targetRight, targetTop)
    end

    local visible = false
    local hideTask = nil

    local function show()
        if hideTask then
            task.cancel(hideTask)
            hideTask = nil
        end
        if not ensureTooltip() then
            return
        end
        visible = true
        reposition()
        Tooltip.Visible = true
    end

    local function hide()
        visible = false
        hideTask = task.delay(0.1, function()
            if not visible and Tooltip then
                Tooltip.Visible = false
            end
        end)
    end

    Button.MouseButton1Click:Connect(function()
        if visible then
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

    -- Se a janela for arrastada/redimensionada enquanto o tooltip esta
    -- aberto, reposiciona para continuar colado no botao.
    Button:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        if visible then
            reposition()
        end
    end)

    -- O tooltip agora e irmao no ScreenGui (nao filho do botao), entao nao
    -- desaparece sozinho quando o elemento sai de vista. Enquanto estiver
    -- aberto, verificamos se o botao continua visivel (AbsoluteSize zera
    -- quando algum ancestral fica invisivel: troca de tab, janela oculta).
    task.spawn(function()
        while Button.Parent do
            if visible and Button.AbsoluteSize.X == 0 then
                visible = false
                if Tooltip then
                    Tooltip.Visible = false
                end
            end
            task.wait(0.25)
        end
    end)

    -- Limpa a instancia do tooltip quando o botao e destruido.
    Button.AncestryChanged:Connect(function(_, newParent)
        if not newParent and Tooltip then
            Tooltip:Destroy()
            Tooltip = nil
            visible = false
        end
    end)

    return Button
end

return HelpButton
