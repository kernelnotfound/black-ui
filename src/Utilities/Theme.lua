--[[
    Black UI Library
    Utilities/Theme.lua

    Sistema de temas. Paleta padrao: minimalista, preto e branco.
    Trocar de tema = trocar esta tabela e reaplicar via Registry (ver Utilities/Style.lua).
]]

local Theme = {}

Theme.Default = {
    -- Base (preto puro, estilo hub privado)
    Background       = Color3.fromRGB(0, 0, 0),      -- fundo da janela
    Surface          = Color3.fromRGB(12, 12, 12),    -- cards / containers internos
    SurfaceElevated  = Color3.fromRGB(18, 18, 18),    -- elementos (botoes, inputs, sliders track)
    SurfaceHover     = Color3.fromRGB(26, 26, 26),    -- hover state
    Border           = Color3.fromRGB(24, 24, 24),    -- bordas quase invisiveis
    BorderStrong     = Color3.fromRGB(36, 36, 36),    -- bordas com mais contraste (sidebar/topbar)

    -- Texto
    Text             = Color3.fromRGB(245, 245, 245),
    TextSecondary    = Color3.fromRGB(140, 140, 140),
    TextDisabled     = Color3.fromRGB(75, 75, 75),

    -- Accent (o contraste É o destaque)
    Accent           = Color3.fromRGB(255, 255, 255),
    AccentText       = Color3.fromRGB(0, 0, 0),   -- texto sobre o accent (preto)

    -- Estados
    Success          = Color3.fromRGB(80, 220, 130),
    Warning          = Color3.fromRGB(230, 190, 80),
    Error            = Color3.fromRGB(230, 90, 90),

    -- Fontes
    Font             = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
    FontBold         = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
    FontSemibold     = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),

    -- Geometria
    CornerRadius         = UDim.new(0, 6),   -- containers (mais reto, estilo IceHub)
    CornerRadiusSmall    = UDim.new(0, 4),   -- elementos (botoes, inputs)
    CornerRadiusPill     = UDim.new(1, 0),   -- toggles, tags

    -- Background pattern (textura sutil identica ao estilo IceHub)
    PatternImage         = "rbxassetid://2151741365",
    PatternTransparency   = 0.94,

    -- Sombra externa da janela
    ShadowImage          = "rbxassetid://6014261993",

    -- Animacao
    TweenFast     = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenNormal   = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenSlow     = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    TweenSpring   = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

-- Tema alternativo claro (opcional, caso queira suporte no futuro)
Theme.Light = {
    Background       = Color3.fromRGB(250, 250, 250),
    Surface          = Color3.fromRGB(255, 255, 255),
    SurfaceElevated  = Color3.fromRGB(240, 240, 240),
    SurfaceHover     = Color3.fromRGB(228, 228, 228),
    Border           = Color3.fromRGB(230, 230, 230),
    BorderStrong     = Color3.fromRGB(210, 210, 210),

    Text             = Color3.fromRGB(15, 15, 15),
    TextSecondary    = Color3.fromRGB(110, 110, 110),
    TextDisabled     = Color3.fromRGB(180, 180, 180),

    Accent           = Color3.fromRGB(10, 10, 10),
    AccentText       = Color3.fromRGB(255, 255, 255),

    Success          = Color3.fromRGB(50, 170, 90),
    Warning          = Color3.fromRGB(190, 140, 20),
    Error            = Color3.fromRGB(200, 60, 60),

    Font             = Theme.Default.Font,
    FontBold         = Theme.Default.FontBold,
    FontSemibold     = Theme.Default.FontSemibold,

    CornerRadius         = UDim.new(0, 6),
    CornerRadiusSmall    = UDim.new(0, 4),
    CornerRadiusPill     = UDim.new(1, 0),

    PatternImage         = Theme.Default.PatternImage,
    PatternTransparency  = 0.96,
    ShadowImage          = Theme.Default.ShadowImage,

    TweenFast     = Theme.Default.TweenFast,
    TweenNormal   = Theme.Default.TweenNormal,
    TweenSlow     = Theme.Default.TweenSlow,
    TweenSpring   = Theme.Default.TweenSpring,
}

return Theme
