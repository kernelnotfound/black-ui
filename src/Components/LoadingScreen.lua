--[[
    Black UI Library
    Components/LoadingScreen.lua

    Tela de carregamento opcional, totalmente controlada pelo dev que usa a
    lib: Black:CreateLoadingScreen(opts) retorna um objeto com metodos para
    atualizar progresso/status e fechar quando quiser.

    Por padrao e um quadrado compacto (estilo card, igual a janela principal
    da lib: sombra, cantos arredondados, pattern sutil), mas pode ser
    expandido para cobrir a tela inteira via opts.Fullscreen = true.

    Barra de progresso: branca "neon" (glow via ImageLabel), na parte
    inferior do card. Pode ser:
    - Determinada: dev chama :SetProgress(0..1) para controlar manualmente
      (ex: carregando N de M recursos)
    - Indeterminada: sem chamadas a :SetProgress, a barra fica em loop
      (idade visual de "carregando", sem progresso conhecido)
]]

local Create = require(script.Parent.Parent.Utilities.Create)
local Tween = require(script.Parent.Parent.Utilities.Tween)
local Theme_ = Create.Theme

local LoadingScreen = {}

function LoadingScreen.Create(Black, opts)
    opts = opts or {}
    local theme = Create.GetTheme()

    local fullscreen = opts.Fullscreen == true
    local size = opts.Size or UDim2.fromOffset(280, 280)

    -- Sombra externa (mesmo estilo da Window), omitida em fullscreen
    -- (nao faz sentido sombra atras de algo que cobre a tela toda).
    local Shadow
    if not fullscreen then
        Shadow = Create.New("ImageLabel", {
            Name = "LoadingShadow",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = size + UDim2.fromOffset(56, 56),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 0,
            Image = theme.ShadowImage,
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = 0.45,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            Parent = Black.ScreenGui,
        })
    end

    -- Card (ou tela cheia)
    local Card = Create.New("Frame", {
        Name = "LoadingCard",
        BackgroundColor3 = Theme_("Background"),
        Position = fullscreen and UDim2.fromScale(0, 0) or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = fullscreen and Vector2.new(0, 0) or Vector2.new(0.5, 0.5),
        Size = fullscreen and UDim2.fromScale(1, 1) or size,
        ClipsDescendants = true,
        ZIndex = 1,
        Parent = fullscreen and Black.ScreenGui or Shadow,
        Children = fullscreen and {} or {
            Create.New("UICorner", { CornerRadius = theme.CornerRadius }),
            Create.New("UIStroke", { Color = Theme_("BorderStrong"), Thickness = 1, Transparency = 0.2 }),
        },
    })

    -- Pattern de fundo sutil (mesmo estilo da Window)
    Create.New("ImageLabel", {
        Name = "Pattern",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 0,
        Image = theme.PatternImage,
        ImageTransparency = theme.PatternTransparency,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.fromOffset(250, 250),
        Parent = Card,
    })

    -- Conteudo central: imagem/logo (opcional) + titulo + subtitulo/status
    local Content = Create.New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -32, 1, -72),
        Parent = Card,
        Children = {
            Create.New("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
            }),
        },
    })

    if opts.Image and opts.Image ~= "" then
        Create.New("ImageLabel", {
            Name = "Image",
            BackgroundTransparency = 1,
            Size = opts.ImageSize or UDim2.fromOffset(72, 72),
            Image = opts.Image,
            ImageColor3 = opts.ImageColor or Color3.fromRGB(255, 255, 255),
            LayoutOrder = 1,
            Parent = Content,
        })
    end

    local TitleLabel
    if opts.Title and opts.Title ~= "" then
        TitleLabel = Create.New("TextLabel", {
            Name = "Title",
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            Font = theme.FontSemibold,
            Text = opts.Title,
            TextColor3 = theme.Text,
            TextSize = 18,
            TextWrapped = true,
            LayoutOrder = 2,
            Parent = Content,
        })
    end

    local StatusLabel = Create.New("TextLabel", {
        Name = "Status",
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Font = theme.Font,
        Text = opts.Subtitle or "",
        TextColor3 = theme.TextSecondary,
        TextSize = 13,
        TextWrapped = true,
        LayoutOrder = 3,
        Parent = Content,
    })

    -- Barra de progresso "neon branca", fixa na parte inferior do card.
    local BarWidth = fullscreen and 320 or (size.X.Offset - 64)
    local BarHeight = 6
    local Track = Create.New("Frame", {
        Name = "ProgressTrack",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -24),
        Size = UDim2.fromOffset(BarWidth, BarHeight),
        BackgroundColor3 = Theme_("SurfaceElevated"),
        Parent = Card,
        Children = {
            Create.New("UICorner", { CornerRadius = theme.CornerRadiusPill }),
            Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1, Transparency = 0.4 }),
        },
    })

    local Fill = Create.New("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = Track,
        Children = {
            Create.New("UICorner", { CornerRadius = theme.CornerRadiusPill }),
            -- Efeito "neon": UIStroke branco levemente transparente ao redor
            -- do preenchimento, criando um halo de brilho sem depender de
            -- nenhum asset de imagem externo.
            Create.New("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 2.5,
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
        },
    })

    local api = {
        Instance = Card,
        Progress = 0,
        Finished = false,
    }

    local indeterminateThread = nil

    local function stopIndeterminate()
        if indeterminateThread then
            task.cancel(indeterminateThread)
            indeterminateThread = nil
        end
    end

    -- Loop indeterminado: a barra "quica" de um lado a outro enquanto
    -- nenhum :SetProgress() explicito for chamado. Comeca automaticamente.
    local function startIndeterminate()
        stopIndeterminate()
        indeterminateThread = task.spawn(function()
            local segmentWidth = BarWidth * 0.35
            while true do
                Fill.Size = UDim2.fromOffset(segmentWidth, BarHeight)
                Tween.Play(Fill, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = UDim2.fromOffset(BarWidth - segmentWidth, 0),
                })
                task.wait(0.9)
                Fill.Position = UDim2.fromOffset(0, 0)
                task.wait(0.05)
            end
        end)
    end
    startIndeterminate()

    -- :SetProgress(alpha) — alpha entre 0 e 1. Desliga o modo indeterminado
    -- na primeira chamada (a barra passa a refletir o valor informado).
    function api:SetProgress(alpha)
        stopIndeterminate()
        alpha = math.clamp(alpha, 0, 1)
        self.Progress = alpha
        Fill.Position = UDim2.fromOffset(0, 0)
        Tween.Play(Fill, theme.TweenFast, { Size = UDim2.fromOffset(BarWidth * alpha, BarHeight) })
    end

    -- :SetStatus(text) — atualiza o texto abaixo do titulo (ex: "Baixando X...").
    function api:SetStatus(text)
        StatusLabel.Text = text or ""
    end

    function api:SetTitle(text)
        if TitleLabel then
            TitleLabel.Text = text or ""
        end
    end

    -- :Finish() — fade-out e destroi. Se um callback for passado, e chamado
    -- apos o fade terminar.
    function api:Finish(onComplete)
        if self.Finished then
            return
        end
        self.Finished = true
        stopIndeterminate()

        local fadeInfo = theme.TweenNormal
        Tween.Play(Card, fadeInfo, { BackgroundTransparency = 1 })
        if Shadow then
            Tween.Play(Shadow, fadeInfo, { ImageTransparency = 1 })
        end
        for _, descendant in Card:GetDescendants() do
            if descendant:IsA("TextLabel") then
                Tween.Play(descendant, fadeInfo, { TextTransparency = 1 })
            elseif descendant:IsA("Frame") or descendant:IsA("ImageLabel") then
                local prop = descendant:IsA("ImageLabel") and "ImageTransparency" or "BackgroundTransparency"
                Tween.Play(descendant, fadeInfo, { [prop] = 1 })
            end
        end

        task.delay(fadeInfo.Time + 0.05, function()
            Card:Destroy()
            if Shadow then
                Shadow:Destroy()
            end
            if onComplete then
                onComplete()
            end
        end)
    end

    return api
end

return LoadingScreen
