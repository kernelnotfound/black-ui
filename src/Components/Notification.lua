--[[
    Black UI Library
    Components/Notification.lua

    Toast de notificacao no canto da tela. Slide-in + fade-out, com
    barra de progresso indicando o tempo restante. Tipos: info (default),
    success, warning, error - cada um muda a cor da barra lateral.
]]

local Create = require(script.Parent.Parent.Utilities.Create)
local Tween = require(script.Parent.Parent.Utilities.Tween)
local Theme_ = Create.Theme

local Notification = {}

local TypeColors = {
    Info = "Accent",
    Success = "Success",
    Warning = "Warning",
    Error = "Error",
}

function Notification.Init(Black)
    local theme = Create.GetTheme()

    local Area = Create.New("Frame", {
        Name = "NotificationArea",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.fromOffset(300, 1),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Black.ScreenGui,
        Children = {
            Create.New("UIListLayout", {
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
            }),
        },
    })

    local toastCounter = 0

    function Black:Notify(opts)
        opts = opts or {}
        local duration = opts.Duration or opts.Time or 3
        local typeKey = TypeColors[opts.Type or "Info"] or "Accent"
        toastCounter = toastCounter + 1

        -- Toast: sua posicao dentro de "Area" e controlada inteiramente pelo
        -- UIListLayout do pai (empilha de baixo para cima). Nao definimos
        -- Position no Toast em si — a animacao de entrada (slide) e feita
        -- numa sub-frame interna "Slider", preservando o layout automatico.
        local Toast = Create.New("Frame", {
            Name = "Toast",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = toastCounter,
            ClipsDescendants = true,
            Parent = Area,
        })

        local Slider = Create.New("Frame", {
            Name = "Slider",
            BackgroundColor3 = Theme_("Surface"),
            Position = UDim2.fromOffset(40, 0),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = Toast,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1 }),
            },
        })

        -- barra de destaque lateral
        Create.New("Frame", {
            Name = "AccentBar",
            BackgroundColor3 = Theme_(typeKey),
            Size = UDim2.new(0, 3, 1, 0),
            Parent = Slider,
            Children = {
                Create.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
            },
        })

        local TextHolder = Create.New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = Slider,
            Children = {
                Create.New("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2),
                }),
                Create.New("UIPadding", {
                    PaddingLeft = UDim.new(0, 14),
                    PaddingRight = UDim.new(0, 10),
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 10),
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
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = TextHolder,
            })
        end

        if opts.Description then
            Create.New("TextLabel", {
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Size = UDim2.new(1, 0, 0, 0),
                Font = theme.Font,
                Text = opts.Description,
                TextColor3 = theme.TextSecondary,
                TextSize = 12,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = TextHolder,
            })
        end

        -- espaco entre o texto e a barra de progresso
        Create.New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 8),
            LayoutOrder = 98,
            Parent = TextHolder,
        })

        -- Barra de progresso (tempo restante) — incluida no fluxo do
        -- UIListLayout (nao ancorada/absoluta), para que o AutomaticSize.Y
        -- do Slider contabilize sua altura corretamente e ela nunca seja
        -- cortada pelo ClipsDescendants do Toast.
        local ProgressTrack = Create.New("Frame", {
            Name = "ProgressTrack",
            Size = UDim2.new(1, 0, 0, 2),
            LayoutOrder = 99,
            BackgroundColor3 = Theme_("Border"),
            Parent = TextHolder,
        })
        local ProgressFill = Create.New("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Theme_(typeKey),
            Parent = ProgressTrack,
        })

        -- Animacao de entrada: slide (na sub-frame "Slider") + fade
        for _, descendant in Slider:GetDescendants() do
            if descendant:IsA("GuiObject") then
                if descendant:IsA("TextLabel") then
                    descendant.TextTransparency = 1
                else
                    descendant.BackgroundTransparency = (descendant.BackgroundTransparency or 0)
                end
            end
        end

        Slider.BackgroundTransparency = 1
        Tween.Play(Slider, theme.TweenNormal, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0 })

        for _, descendant in Slider:GetDescendants() do
            if descendant:IsA("TextLabel") then
                Tween.Play(descendant, theme.TweenNormal, { TextTransparency = 0 })
            end
        end

        Tween.Play(ProgressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 1, 0),
        })

        local function dismiss()
            Tween.Play(Slider, theme.TweenFast, { Position = UDim2.fromOffset(40, 0), BackgroundTransparency = 1 })
            for _, descendant in Slider:GetDescendants() do
                if descendant:IsA("TextLabel") then
                    Tween.Play(descendant, theme.TweenFast, { TextTransparency = 1 })
                elseif descendant:IsA("Frame") or descendant:IsA("UICorner") then
                    if descendant:IsA("Frame") then
                        Tween.Play(descendant, theme.TweenFast, { BackgroundTransparency = 1 })
                    end
                end
            end
            task.delay(0.15, function()
                Toast:Destroy()
            end)
        end

        task.delay(duration, dismiss)

        return {
            Instance = Toast,
            Dismiss = dismiss,
        }
    end
end

return Notification
