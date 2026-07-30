--[[
    Black UI Library
    Elements/ListItem.lua

    Card de item de lista, para listas dinâmicas (itens adicionados/removidos
    em tempo real) que precisam de mais estrutura visual do que um
    CreateButton genérico oferece: barra de destaque lateral (accent),
    título + subtítulo, badge opcional (contagem/status), e múltiplas ações
    (ícone + tooltip) em vez de um único clique.

    Inspirado na organização visual de listas de itens de scripts de
    customização (cards com accent bar + badge + ações rápidas), mas usando
    integralmente o tema/tokens da Black UI (Theme.Default) — não introduz
    nenhuma paleta de cor própria.

    Este componente é de uso geral: não é específico de nenhum domínio
    (meshes, jogadores, inventário, logs, etc.) — qualquer lista dinâmica de
    itens com título/ação pode usá-lo.

    Como listas dinâmicas não têm um método nativo de "atualizar item N" na
    Tab (Tab.RegisterElement só sabe criar, nunca remover), o padrão de uso
    esperado é: quando a lista de dados mudar, o consumidor chama
    `:Destroy()` em cada ListItem antigo e cria novos via
    `tab:CreateListItem({...})` — o mesmo padrão já usado para outras listas
    dinâmicas no restante da lib.

    Uso:
        local item = tab:CreateListItem({
            Title = "Mesh #1",
            Subtitle = "ID 123456 • Tex 789",
            AccentColor = Color3.fromRGB(255, 140, 60), -- opcional
            Badge = "3",                                 -- opcional (texto/número)
            Actions = {
                { Icon = "✏️", Tooltip = "Editar", Callback = function() ... end },
                { Icon = "✕", Tooltip = "Remover", Callback = function() ... end, Style = "Danger" },
            },
        })

        item:SetTitle("Novo nome")
        item:SetSubtitle("...")
        item:SetBadge("5")
        item:Destroy()
]]

local Create = require(script.Parent.Parent.Utilities.Create)
local Tween = require(script.Parent.Parent.Utilities.Tween)
local Tab = require(script.Parent.Parent.Tab)
local Theme_ = Create.Theme

local ACTION_SIZE = 30
local ACTION_GAP = 6

Tab.RegisterElement("CreateListItem", function(tab, opts)
    opts = opts or {}
    local theme = Create.GetTheme()

    local hasAccent = opts.AccentColor ~= nil
    local hasBadge = opts.Badge ~= nil and tostring(opts.Badge) ~= ""
    local actions = opts.Actions or {}
    local actionsWidth = (#actions > 0) and (#actions * ACTION_SIZE + math.max(0, #actions - 1) * ACTION_GAP) or 0

    -- Reserva espaço à direita para badge + ações, para os textos nunca
    -- ficarem por baixo desses elementos.
    local rightReserved = actionsWidth
    if hasBadge then
        rightReserved += 34
    end
    if rightReserved > 0 then
        rightReserved += 12 -- respiro entre o texto e a primeira coisa reservada
    end

    local Holder = Create.New("Frame", {
        Name = "ListItem_" .. (opts.Title or "Item"),
        BackgroundColor3 = Theme_("Surface"),
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = tab.Page,
        Children = {
            Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
            Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1, Transparency = 0.5 }),
        },
    })

    -- Barra de destaque lateral (accent), opcional — mesmo espírito de
    -- indicador visual rápido (ex: cor do item) usado em listas de scripts
    -- de customização, aqui via um Frame simples ligado ao tema/valor
    -- fornecido (não é um token fixo do tema, é uma cor por item).
    if hasAccent then
        Create.New("Frame", {
            Name = "Accent",
            BackgroundColor3 = opts.AccentColor,
            Size = UDim2.new(0, 3, 1, -12),
            Position = UDim2.fromOffset(0, 6),
            Parent = Holder,
            Children = {
                Create.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
            },
        })
    end

    local textLeftOffset = hasAccent and 16 or 12

    local TextHolder = Create.New("Frame", {
        Name = "TextHolder",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(textLeftOffset, 0),
        Size = UDim2.new(1, -(textLeftOffset + 12 + rightReserved), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Holder,
        Children = {
            Create.New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2),
            }),
            Create.New("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
            }),
        },
    })

    local TitleLabel = Create.New("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Font = theme.FontSemibold,
        Text = opts.Title or "",
        TextColor3 = theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = 1,
        Parent = TextHolder,
    })

    local SubtitleLabel = nil
    if opts.Subtitle and opts.Subtitle ~= "" then
        SubtitleLabel = Create.New("TextLabel", {
            Name = "Subtitle",
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            Font = theme.Font,
            Text = opts.Subtitle,
            TextColor3 = theme.TextSecondary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = 2,
            Parent = TextHolder,
        })
    end

    -- Badge (contagem/status), ancorado no canto superior direito.
    local BadgeHolder = nil
    if hasBadge then
        BadgeHolder = Create.New("Frame", {
            Name = "Badge",
            BackgroundColor3 = Theme_("SurfaceElevated"),
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -(actionsWidth + (actionsWidth > 0 and ACTION_GAP or 0) + 10), 0, 10),
            Size = UDim2.fromOffset(0, 22),
            AutomaticSize = Enum.AutomaticSize.X,
            Parent = Holder,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusPill }),
                Create.New("UIStroke", { Color = Theme_("BorderStrong"), Thickness = 1, Transparency = 0.4 }),
                Create.New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
            },
        })

        Create.New("TextLabel", {
            Name = "BadgeLabel",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = theme.FontSemibold,
            Text = tostring(opts.Badge),
            TextColor3 = theme.TextSecondary,
            TextSize = 12,
            Parent = BadgeHolder,
        })
    end

    -- Ações (ícone + tooltip), alinhadas à direita, uma ao lado da outra.
    local actionButtons = {}
    if #actions > 0 then
        local ActionsHolder = Create.New("Frame", {
            Name = "Actions",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(actionsWidth, ACTION_SIZE),
            Parent = Holder,
            Children = {
                Create.New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, ACTION_GAP),
                }),
            },
        })

        for index, action in ipairs(actions) do
            local isDanger = action.Style == "Danger"
            local normalColor = theme.SurfaceElevated
            local hoverColor = isDanger and theme.Error or theme.SurfaceHover

            local ActionButton = Create.New("TextButton", {
                Name = "Action_" .. index,
                BackgroundColor3 = normalColor,
                AutoButtonColor = false,
                Size = UDim2.fromOffset(ACTION_SIZE, ACTION_SIZE),
                LayoutOrder = index,
                Font = theme.FontSemibold,
                Text = action.Icon or "•",
                TextColor3 = isDanger and theme.Text or theme.TextSecondary,
                TextSize = 14,
                Parent = ActionsHolder,
                Children = {
                    Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                },
            })

            Tween.ApplyHoverPress(ActionButton, {
                Normal = normalColor,
                Hover = hoverColor,
            }, theme)

            if action.Callback then
                ActionButton.MouseButton1Click:Connect(function()
                    task.spawn(action.Callback)
                end)
            end

            table.insert(actionButtons, ActionButton)
        end
    end

    Tween.ApplyHoverPress(Holder, {
        Normal = theme.Surface,
        Hover = theme.Surface, -- ListItem não é clicável por si só; hover fica só nas ações
    }, theme)

    local api = {
        Instance = Holder,
        SetTitle = function(_, text)
            TitleLabel.Text = text or ""
        end,
        SetSubtitle = function(_, text)
            if SubtitleLabel then
                SubtitleLabel.Text = text or ""
            end
        end,
        SetBadge = function(_, value)
            if BadgeHolder then
                local label = BadgeHolder:FindFirstChild("BadgeLabel")
                if label then
                    label.Text = tostring(value)
                end
            end
        end,
        Destroy = function()
            Holder:Destroy()
        end,
    }

    return api
end)
