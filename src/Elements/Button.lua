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

    local Holder = Create.New("TextButton", {
        Name = "Button_" .. (opts.Name or "Button"),
        BackgroundColor3 = Theme_("Surface"),
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, hasDescription and 52 or 38),
        Text = "",
        Parent = tab.Page,
        Children = {
            Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
            Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1, Transparency = 0.5 }),
            Create.New("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
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
        Parent = Holder,
    })

    if hasDescription then
        NameLabel.AnchorPoint = Vector2.new(0, 0)
        NameLabel.Position = UDim2.fromOffset(0, 0)

        local DescriptionLabel = Create.New("TextLabel", {
            Name = "DescriptionLabel",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 20),
            Size = UDim2.new(1, -rightMargin, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = theme.Font,
            Text = opts.Description,
            TextColor3 = theme.TextSecondary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Parent = Holder,
        })

        -- Ajusta a altura do card ao numero real de linhas da descricao.
        -- DescriptionLabel usa AutomaticSize.Y (a label em si cresce para
        -- caber o texto, evitando o corte que ocorria com uma altura fixa);
        -- aqui so propagamos essa altura para o card (Holder) que a contem,
        -- ja que o UIListLayout da Tab.Page precisa do Holder com o tamanho
        -- final correto para nao sobrepor o proximo elemento.
        local function resizeToFitDescription()
            local descHeight = DescriptionLabel.AbsoluteSize.Y
            -- PaddingTop(8) + NameLabel/gap(20) + descHeight + PaddingBottom(8)
            local totalHeight = 8 + 20 + descHeight + 8
            Holder.Size = UDim2.new(1, 0, 0, math.max(52, totalHeight))
        end
        DescriptionLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeToFitDescription)
        resizeToFitDescription()
    else
        NameLabel.AnchorPoint = Vector2.new(0, 0.5)
        NameLabel.Position = UDim2.new(0, 0, 0.5, 0)
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
