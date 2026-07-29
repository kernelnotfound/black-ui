--[[
    Black UI Library
    Elements/Label.lua

    Label simples (texto informativo) e Paragraph (bloco maior com wrap).
]]

local Create = require(script.Parent.Parent.Utilities.Create)
local Tab = require(script.Parent.Parent.Tab)
local Theme_ = Create.Theme

Tab.RegisterElement("CreateLabel", function(tab, opts)
    if typeof(opts) == "string" then
        opts = { Text = opts }
    end
    opts = opts or {}
    local theme = Create.GetTheme()

    local Label = Create.New("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Font = theme.Font,
        Text = opts.Text or "",
        TextColor3 = Theme_("TextSecondary"),
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tab.Page,
    })

    return {
        Instance = Label,
        SetText = function(_, text)
            Label.Text = text
        end,
    }
end)

Tab.RegisterElement("CreateParagraph", function(tab, opts)
    opts = opts or {}
    local theme = Create.GetTheme()

    local Holder = Create.New("Frame", {
        Name = "Paragraph_" .. (opts.Title or "Paragraph"),
        BackgroundColor3 = Theme_("Surface"),
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = tab.Page,
        Children = {
            Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
            Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1, Transparency = 0.5 }),
            Create.New("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
            }),
            Create.New("UIListLayout", {
                Padding = UDim.new(0, 4),
            }),
        },
    })

    if opts.Title then
        Create.New("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            Font = theme.FontSemibold,
            Text = opts.Title,
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = 1,
            Parent = Holder,
        })
    end

    local BodyLabel = Create.New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Font = theme.Font,
        Text = opts.Text or "",
        TextColor3 = theme.TextSecondary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = 2,
        Parent = Holder,
    })

    return {
        Instance = Holder,
        SetText = function(_, text)
            BodyLabel.Text = text
        end,
    }
end)

Tab.RegisterElement("CreateDivider", function(tab, _opts)
    local theme = Create.GetTheme()

    local Divider = Create.New("Frame", {
        Name = "Divider",
        BackgroundColor3 = Theme_("Border"),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = tab.Page,
    })

    return { Instance = Divider }
end)

Tab.RegisterElement("CreateSection", function(tab, opts)
    if typeof(opts) == "string" then
        opts = { Name = opts }
    end
    opts = opts or {}
    local theme = Create.GetTheme()

    local Holder = Create.New("Frame", {
        Name = "Section_" .. (opts.Name or "Section"),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = tab.Page,
    })

    Create.New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = theme.FontSemibold,
        Text = (opts.Name or "Section"):upper(),
        TextColor3 = Theme_("TextSecondary"),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    return { Instance = Holder }
end)

-- Separador com titulo: uma linha divisoria com um texto centralizado
-- sobreposto (estilo "--- Titulo ---"), util para quebrar visualmente
-- grupos de elementos dentro da mesma tab sem precisar de uma nova Section.
Tab.RegisterElement("CreateTitledDivider", function(tab, opts)
    if typeof(opts) == "string" then
        opts = { Text = opts }
    end
    opts = opts or {}
    local theme = Create.GetTheme()

    local Holder = Create.New("Frame", {
        Name = "TitledDivider_" .. (opts.Text or "Divider"),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = tab.Page,
    })

    local LeftLine = Create.New("Frame", {
        Name = "LeftLine",
        BackgroundColor3 = Theme_("Border"),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0.5, -8, 0, 1),
        Parent = Holder,
    })

    Create.New("TextLabel", {
        Name = "Text",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = theme.FontSemibold,
        Text = opts.Text or "",
        TextColor3 = Theme_("TextSecondary"),
        TextSize = 11,
        Parent = Holder,
    })

    Create.New("Frame", {
        Name = "RightLine",
        BackgroundColor3 = Theme_("Border"),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0.5, -8, 0, 1),
        Parent = Holder,
    })

    return { Instance = Holder }
end)
