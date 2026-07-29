--[[
    Black UI Library
    Window.lua

    Janela principal: topbar (titulo + minimize/close), sidebar de tabs,
    container de conteudo. Drag habilitado pela topbar, com clamp de tela.
    Suporta minimizar (colapsa pra uma pill pequena) e um keybind global
    de toggle (default: RightControl).
]]

local UserInputService = game:GetService("UserInputService")

local Create = require(script.Parent.Utilities.Create)
local Draggable = require(script.Parent.Utilities.Draggable)
local Tween = require(script.Parent.Utilities.Tween)
local Platform = require(script.Parent.Utilities.Platform)
local Signal = require(script.Parent.Utilities.Signal)
local Theme_ = Create.Theme

local Window = {}
Window.__index = Window

local SIDEBAR_WIDTH = Platform.Scale(150, 130)
local TOPBAR_HEIGHT = Platform.Scale(44, 52)

function Window.new(Black, opts)
    opts = opts or {}
    local theme = Create.GetTheme()

    local self = setmetatable({}, Window)
    self.Black = Black
    self.Name = opts.Name or "Black UI"
    self.SubTitle = opts.SubTitle
    self.Tabs = {}
    self.TabButtons = {}
    self.ActiveTab = nil
    self.Toggled = true
    self.MinimizeKey = opts.ToggleKeybind or Enum.KeyCode.RightControl
    self.Minimized = false

    self.Destroying = Signal.new()

    local size = opts.Size or UDim2.fromOffset(Platform.Scale(560, 340), Platform.Scale(420, 440))

    -- Sombra externa (drop shadow), identica ao estilo IceHub: uma ImageLabel
    -- ligeiramente maior que a janela, atras de tudo (ZIndex baixo).
    self.Shadow = Create.New("ImageLabel", {
        Name = "WindowShadow",
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

    -- Root
    self.Root = Create.New("Frame", {
        Name = "Window",
        BackgroundColor3 = Theme_("Background"),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = size,
        ClipsDescendants = true,
        ZIndex = 1,
        Parent = self.Shadow,
        Children = {
            Create.New("UICorner", { CornerRadius = theme.CornerRadius }),
            Create.New("UIStroke", {
                Color = Theme_("BorderStrong"),
                Thickness = 1,
                Transparency = 0.2,
            }),
        },
    })

    -- Pattern de fundo bem sutil (textura quase imperceptivel, estilo IceHub)
    Create.New("ImageLabel", {
        Name = "Pattern",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 0,
        Image = theme.PatternImage,
        ImageTransparency = theme.PatternTransparency,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.fromOffset(250, 250),
        Parent = self.Root,
    })

    -- Topbar
    self.Topbar = Create.New("Frame", {
        Name = "Topbar",
        BackgroundColor3 = Theme_("Surface"),
        Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
        Parent = self.Root,
    })
    -- topbar so tem corner no topo — cobrir o corner inferior do topbar com um retangulo
    Create.New("UICorner", { CornerRadius = theme.CornerRadius, Parent = self.Topbar })

    -- Linha divisoria fina abaixo do topbar (estilo "Li" da IceHub)
    self.TopbarDivider = Create.New("Frame", {
        Name = "Divider",
        BackgroundColor3 = Theme_("BorderStrong"),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 2,
        Parent = self.Root,
        Children = {
            Create.New("UIStroke", {
                Color = Theme_("BorderStrong"),
                Thickness = 0.5,
                Transparency = 0.2,
                LineJoinMode = Enum.LineJoinMode.Bevel,
            }),
        },
    })

    -- Se a versao nao foi definida (Black.Version == nil), o campo fica vazio na UI.
    local titleVersion = (Black.Version and Black.Version ~= "" and (" v" .. Black.Version)) or ""

    -- Icone/logo customizavel (whitelabel): opts.Icon = "rbxassetid://..."
    local hasIcon = opts.Icon ~= nil and opts.Icon ~= ""
    local titleLeftOffset = hasIcon and 42 or 16

    if hasIcon then
        Create.New("ImageLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(14, TOPBAR_HEIGHT / 2),
            Size = UDim2.fromOffset(20, 20),
            Image = opts.Icon,
            ImageColor3 = opts.IconColor or Color3.fromRGB(255, 255, 255),
            Parent = self.Topbar,
        })
    end

    local TitleLabel = Create.New("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(titleLeftOffset, 0),
        Size = UDim2.new(1, -(titleLeftOffset + 84), 1, 0),
        Font = Theme_("FontSemibold"),
        Text = self.Name .. titleVersion,
        TextColor3 = Theme_("Text"),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Topbar,
    })

    if self.SubTitle then
        Create.New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(titleLeftOffset, 15),
            Size = UDim2.new(1, -(titleLeftOffset + 84), 0, 14),
            Font = Theme_("Font"),
            Text = self.SubTitle,
            TextColor3 = Theme_("TextSecondary"),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.Topbar,
        })
    end

    -- Botoes de controle (minimize / close)
    local Controls = Create.New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(64, 28),
        Parent = self.Topbar,
        Children = {
            Create.New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
            }),
        },
    })

    local function makeControlButton(glyph)
        local btn = Create.New("TextButton", {
            BackgroundColor3 = Theme_("SurfaceElevated"),
            Size = UDim2.fromOffset(26, 26),
            AutoButtonColor = false,
            Font = Theme_("FontBold"),
            Text = glyph,
            TextColor3 = Theme_("TextSecondary"),
            TextSize = 13,
            Parent = Controls,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
            },
        })
        Tween.ApplyHoverPress(btn, {
            Normal = theme.SurfaceElevated,
            Hover = theme.SurfaceHover,
        }, theme)
        return btn
    end

    local MinimizeBtn = makeControlButton("–")
    local CloseBtn = makeControlButton("×")

    -- Body: sidebar + content
    self.Body = Create.New("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, TOPBAR_HEIGHT),
        Size = UDim2.new(1, 0, 1, -TOPBAR_HEIGHT),
        Parent = self.Root,
    })

    self.Sidebar = Create.New("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme_("Surface"),
        Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0),
        Parent = self.Body,
        Children = {
            Create.New("Frame", { -- right border (linha divisoria vertical, estilo IceHub)
                Name = "Divider",
                BackgroundColor3 = Theme_("BorderStrong"),
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0, 1, 1, 0),
                BorderSizePixel = 0,
                Children = {
                    Create.New("UIStroke", {
                        Color = Theme_("BorderStrong"),
                        Thickness = 0.5,
                        Transparency = 0.2,
                        LineJoinMode = Enum.LineJoinMode.Bevel,
                    }),
                },
            }),
        },
    })

    self.TabList = Create.New("ScrollingFrame", {
        Name = "TabList",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.new(1, 0, 1, -16),
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Border,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self.Sidebar,
        Children = {
            Create.New("UIListLayout", {
                Padding = UDim.new(0, 4),
            }),
            Create.New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
            }),
        },
    })

    self.Content = Create.New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(SIDEBAR_WIDTH, 0),
        Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, 0),
        ClipsDescendants = true,
        Parent = self.Body,
    })

    -- Drag pela topbar (arrasta a sombra, que e o container externo; o Root acompanha por ser filho)
    Draggable.Enable(self.Shadow, self.Topbar, { ClampToScreen = true })

    -- Minimize
    local expandedSize = size
    local shadowPadding = UDim2.fromOffset(56, 56)
    MinimizeBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)

    -- Close (esconde a UI, nao destroi)
    CloseBtn.MouseButton1Click:Connect(function()
        self:SetVisible(false)
    end)

    -- Keybind global de toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode == self.MinimizeKey then
            self:SetVisible(not self.Toggled)
        end
    end)

    self._expandedSize = expandedSize
    self._minimizedSize = UDim2.fromOffset(220, TOPBAR_HEIGHT)
    self._shadowPadding = shadowPadding

    return self
end

function Window:ToggleMinimize()
    local theme = Create.GetTheme()
    self.Minimized = not self.Minimized

    if self.Minimized then
        self.Body.Visible = false
        Tween.Play(self.Root, theme.TweenNormal, { Size = self._minimizedSize })
        Tween.Play(self.Shadow, theme.TweenNormal, { Size = self._minimizedSize + self._shadowPadding })
    else
        self.Body.Visible = true
        Tween.Play(self.Root, theme.TweenNormal, { Size = self._expandedSize })
        Tween.Play(self.Shadow, theme.TweenNormal, { Size = self._expandedSize + self._shadowPadding })
    end
end

function Window:SetVisible(visible)
    self.Toggled = visible
    self.Shadow.Visible = visible
end

function Window:CreateTab(opts)
    local Tab = require(script.Parent.Tab)
    local tab = Tab.new(self, opts)
    table.insert(self.Tabs, tab)

    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end

    return tab
end

function Window:SelectTab(tab)
    local theme = Create.GetTheme()

    if self.ActiveTab then
        self.ActiveTab.Page.Visible = false
        Tween.Play(self.ActiveTab.Button, theme.TweenFast, {
            BackgroundColor3 = theme.Surface,
        })
        self.ActiveTab.ButtonLabel.TextColor3 = theme.TextSecondary
    end

    self.ActiveTab = tab
    tab.Page.Visible = true
    Tween.Play(tab.Button, theme.TweenFast, {
        BackgroundColor3 = theme.SurfaceElevated,
    })
    tab.ButtonLabel.TextColor3 = theme.Text
end

function Window:Destroy()
    self.Destroying:Fire()
    self.Shadow:Destroy()
end

return Window
