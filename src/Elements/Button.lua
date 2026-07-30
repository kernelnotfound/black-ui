--[[
    Black UI Library
    Elements/Button.lua

    Botao simples com nome + descricao opcional, feedback de hover/press.
]]

local Create = require(script.Parent.Parent.Utilities.Create)
local Tween = require(script.Parent.Parent.Utilities.Tween)
local HelpButton = require(script.Parent.Parent.Utilities.HelpButton)
local Tab = require(script.Parent.Parent.Tab)
local Theme_ = Create.Theme

Tab.RegisterElement("CreateButton", function(tab, opts)
    opts = opts or {}
    local theme = Create.GetTheme()

    local hasDescription = opts.Description ~= nil and opts.Description ~= ""
    local hasHelp = opts.Help ~= nil and opts.Help ~= ""
    local rightMargin = hasHelp and 46 or 20

    -- Holder usa AutomaticSize.Y (mesmo padrao do Paragraph em Label.lua) em
    -- vez de altura fixa: descricoes longas que quebram em multiplas linhas
    -- fazem o card crescer naturalmente, sem calculo manual de
    -- AbsoluteSize/TextBounds (que dependia do timing do layout e podia
    -- cortar o texto na primeira renderizacao).
    --
    -- NameLabel/DescriptionLabel ficam num sub-frame (TextHolder) com seu
    -- proprio UIListLayout, em vez do UIListLayout estar direto no Holder --
    -- assim o HelpButton (ancorado no canto via AnchorPoint/Position, sem
    -- LayoutOrder) nao e "capturado" e reposicionado pelo layout automatico.
    local Holder = Create.New("TextButton", {
        Name = "Button_" .. (opts.Name or "Button"),
        BackgroundColor3 = Theme_("Surface"),
        AutoButtonColor = false,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Text = "",
        Parent = tab.Page,
        Children = {
            Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
            Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1, Transparency = 0.5 }),
            Create.New("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, hasDescription and 8 or 10),
                PaddingBottom = UDim.new(0, hasDescription and 8 or 10),
            }),
        },
    })

    local TextHolder = Create.New("Frame", {
        Name = "TextHolder",
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = Holder,
        Children = {
            Create.New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2),
            }),
        },
    })

    local NameLabel = Create.New("TextLabel", {
        Name = "NameLabel",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -rightMargin, 0, 18),
        Font = theme.FontSemibold,
        Text = opts.Name or "Button",
        TextColor3 = theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        LayoutOrder = 1,
        Parent = TextHolder,
    })

    if hasDescription then
        Create.New("TextLabel", {
            Name = "DescriptionLabel",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -rightMargin, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = theme.Font,
            Text = opts.Description,
            TextColor3 = theme.TextSecondary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            LayoutOrder = 2,
            Parent = TextHolder,
        })
    end

    Tween.ApplyHoverPress(Holder, {
        Normal = theme.Surface,
        Hover = theme.SurfaceElevated,
        Press = theme.SurfaceHover,
    }, theme)

    HelpButton.Attach(Holder, opts.Help)

    Holder.MouseButton1Click:Connect(function()
        if opts.Callback then
            task.spawn(opts.Callback)
        end
    end)

    local api = {
        Instance = Holder,
        SetName = function(_, name)
            NameLabel.Text = name
        end,
    }

    return api
end)
