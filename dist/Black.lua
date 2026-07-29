--[[
    BLACK UI LIBRARY
    Bundled build — gerado automaticamente por build.js. NAO EDITE A MAO.
    Fonte: src/*.lua

    Arquivo unico monolitico (sem sistema de "require" em tempo de
    execucao), no mesmo padrao usado por libs de UI Roblox consolidadas.
]]

-- module: Utilities/Create
local __mod_Utilities_Create = (function()
    --[[
        Black UI Library
        Utilities/Create.lua
    
        Wrapper para Instance.new que:
        - Aplica propriedades de uma tabela
        - Registra propriedades ligadas ao tema (para retema em runtime)
        - Suporta filhos aninhados via campo `Children`
    
        Inspirado no padrao "New()" do Obsidian, porem mais leve: em vez de
        reescrever TODAS as instancias sempre que o tema muda, guardamos uma
        lista de (instance, property, themeKey) e so atualizamos essas.
    ]]
    
    local Create = {}
    
    -- Registry global: { [Instance] = { [Property] = ThemeKey } }
    Create.Registry = {}
    
    local ThemeRef = nil -- setado por init.lua via Create.SetTheme
    
    function Create.SetThemeTable(themeTable)
        ThemeRef = themeTable
    end
    
    function Create.GetTheme()
        return ThemeRef
    end
    
    -- Marca ums prop como "ligada ao tema": ThemeKey deve ser uma string chave
    -- existente na tabela de tema (ex: "Background", "Text", ...)
    local ThemeKeyMarker = {}
    function Create.Theme(themeKey)
        return setmetatable({ key = themeKey }, ThemeKeyMarker)
    end
    
    local function isThemeMarker(v)
        return typeof(v) == "table" and getmetatable(v) == ThemeKeyMarker
    end
    
    -- A propriedade legada "Font" (Enum.Font) nao aceita objetos Font.new(...);
    -- esses devem ser atribuidos via "FontFace". Para permitir usar `Font = ...`
    -- na tabela de props (mais natural) com valores de qualquer um dos dois
    -- tipos, detectamos e redirecionamos automaticamente.
    local function setFontProperty(inst, value)
        if typeof(value) == "Font" then
            inst.FontFace = value
        else
            inst.Font = value
        end
    end
    
    function Create.New(className, props)
        local inst = Instance.new(className)
        local themeProps = nil
    
        if props then
            for key, value in props do
                if key == "Children" then
                    continue
                elseif key == "Parent" then
                    continue -- setado por ultimo
                elseif isThemeMarker(value) then
                    themeProps = themeProps or {}
                    themeProps[key] = value.key
                    local resolved = ThemeRef and ThemeRef[value.key] or value.key
                    if key == "Font" then
                        setFontProperty(inst, resolved)
                    else
                        inst[key] = resolved
                    end
                elseif key == "Font" then
                    setFontProperty(inst, value)
                else
                    inst[key] = value
                end
            end
    
            if props.Children then
                for _, child in props.Children do
                    child.Parent = inst
                end
            end
    
            if props.Parent then
                inst.Parent = props.Parent
            end
        end
    
        if themeProps then
            Create.Registry[inst] = themeProps
        end
    
        return inst
    end
    
    -- Reaplica todas as props ligadas ao tema atual (chamar quando o tema mudar)
    function Create.RefreshTheme()
        if not ThemeRef then
            return
        end
        for inst, themeProps in Create.Registry do
            if not inst.Parent and inst.Parent ~= game then
                -- ainda pode ser valido (root), nao remover por seguranca aqui
            end
            for prop, key in themeProps do
                local ok = pcall(function()
                    if prop == "Font" then
                        setFontProperty(inst, ThemeRef[key])
                    else
                        inst[prop] = ThemeRef[key]
                    end
                end)
                if not ok then
                    Create.Registry[inst] = nil
                    break
                end
            end
        end
    end
    
    function Create.Untrack(inst)
        Create.Registry[inst] = nil
    end
    
    return Create
    
end)()

-- module: Utilities/Draggable
local __mod_Utilities_Draggable = (function()
    --[[
        Black UI Library
        Utilities/Draggable.lua
    
        Logica de arrastar (mouse + touch) com clamp dentro do viewport,
        para que a janela nunca saia completamente da tela.
    ]]
    
    local UserInputService = game:GetService("UserInputService")
    
    local Draggable = {}
    
    local function isDragInput(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
    end
    
    -- target: GuiObject que sera movido (Position)
    -- handle: GuiObject que recebe o input (pode ser o mesmo que target)
    -- options: { ClampToScreen: boolean }
    function Draggable.Enable(target, handle, options)
        options = options or {}
        local clamp = options.ClampToScreen ~= false
    
        local dragging = false
        local dragStart = nil
        local startPos = nil
        local inputChangedConn = nil
    
        local function update(input)
            local delta = input.Position - dragStart
            local newX = startPos.X.Offset + delta.X
            local newY = startPos.Y.Offset + delta.Y
    
            if clamp then
                local camera = workspace.CurrentCamera
                local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
                local absSize = target.AbsoluteSize
                local anchor = target.AnchorPoint
    
                -- Limites em termos do canto top-left real da instancia (independente
                -- do AnchorPoint), permitindo toda a janela ser arrastada pela tela.
                local minLeft, maxLeft = 0, viewport.X - absSize.X
                local minTop, maxTop = 0, viewport.Y - absSize.Y
    
                -- Converte de volta para o espaco de "Position" (que e relativo ao
                -- AnchorPoint), somando o deslocamento do anchor.
                local anchorOffsetX = anchor.X * absSize.X
                local anchorOffsetY = anchor.Y * absSize.Y
    
                local scaleX, scaleY = startPos.X.Scale, startPos.Y.Scale
                local absScaleX = scaleX * viewport.X
                local absScaleY = scaleY * viewport.Y
    
                local minX = minLeft - absScaleX + anchorOffsetX
                local maxX = maxLeft - absScaleX + anchorOffsetX
                local minY = minTop - absScaleY + anchorOffsetY
                local maxY = maxTop - absScaleY + anchorOffsetY
    
                newX = math.clamp(newX, minX, maxX)
                newY = math.clamp(newY, minY, maxY)
            end
    
            target.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        end
    
        handle.InputBegan:Connect(function(input)
            if not isDragInput(input) then
                return
            end
            dragging = true
            dragStart = input.Position
            startPos = target.Position
    
            local changedConn
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if changedConn then
                        changedConn:Disconnect()
                    end
                end
            end)
        end)
    
        inputChangedConn = UserInputService.InputChanged:Connect(function(input)
            if not dragging then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                update(input)
            end
        end)
    
        return {
            Disconnect = function()
                if inputChangedConn then
                    inputChangedConn:Disconnect()
                end
            end,
        }
    end
    
    return Draggable
    
end)()

-- module: Utilities/Tween
local __mod_Utilities_Tween = (function()
    --[[
        Black UI Library
        Utilities/Tween.lua
    
        Wrapper fino sobre TweenService + helpers de micro-interacao
        (hover, press) usados por praticamente todos os elementos.
    ]]
    
    local TweenService = game:GetService("TweenService")
    
    local Tween = {}
    
    function Tween.Play(instance, tweenInfo, props)
        local tw = TweenService:Create(instance, tweenInfo, props)
        tw:Play()
        return tw
    end
    
    -- Aplica hover (BackgroundColor3 muda) + press (scale sutil) num GuiButton/Frame
    -- theme: tabela de tema atual (para pegar TweenFast)
    function Tween.ApplyHoverPress(guiObject, colors, theme)
        -- colors = { Normal = Color3, Hover = Color3, Press = Color3? }
        local tweenInfo = theme and theme.TweenFast or TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
        guiObject.MouseEnter:Connect(function()
            Tween.Play(guiObject, tweenInfo, { BackgroundColor3 = colors.Hover })
        end)
    
        guiObject.MouseLeave:Connect(function()
            Tween.Play(guiObject, tweenInfo, { BackgroundColor3 = colors.Normal })
        end)
    
        if guiObject:IsA("GuiButton") then
            guiObject.MouseButton1Down:Connect(function()
                Tween.Play(guiObject, tweenInfo, { BackgroundColor3 = colors.Press or colors.Hover })
            end)
            guiObject.MouseButton1Up:Connect(function()
                Tween.Play(guiObject, tweenInfo, { BackgroundColor3 = colors.Hover })
            end)
        end
    end
    
    -- Pequeno "squish" de escala ao clicar (via UIScale filho)
    function Tween.PressScale(guiObject, uiScale, theme)
        local fast = theme and theme.TweenFast or TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        guiObject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Tween.Play(uiScale, fast, { Scale = 0.97 })
            end
        end)
        guiObject.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Tween.Play(uiScale, fast, { Scale = 1 })
            end
        end)
    end
    
    return Tween
    
end)()

-- module: Utilities/Platform
local __mod_Utilities_Platform = (function()
    --[[
        Black UI Library
        Utilities/Platform.lua
    
        Deteccao de plataforma (PC / Mobile) e helpers de adaptacao de tamanho
        para telas de toque.
    ]]
    
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    
    local Platform = {}
    
    local function DetectMobile()
        if RunService:IsStudio() then
            return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
        end
    
        local ok, platform = pcall(function()
            return UserInputService:GetPlatform()
        end)
    
        if ok then
            return platform == Enum.Platform.Android or platform == Enum.Platform.IOS
        end
    
        return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    end
    
    Platform.IsMobile = DetectMobile()
    Platform.IsTouch = UserInputService.TouchEnabled
    
    -- Tamanhos base adaptados por plataforma (hit area maior no mobile)
    function Platform.Scale(pcValue, mobileValue)
        if Platform.IsMobile then
            return mobileValue
        end
        return pcValue
    end
    
    -- Padding/altura minima recomendada para elementos interativos
    Platform.MinTouchTarget = Platform.IsMobile and 40 or 30
    
    -- Atualiza dinamicamente se o input method mudar em runtime (ex: emulador)
    UserInputService.LastInputTypeChanged:Connect(function(inputType)
        if inputType == Enum.UserInputType.Touch then
            Platform.IsTouch = true
        elseif inputType == Enum.UserInputType.MouseMovement or inputType == Enum.UserInputType.MouseButton1 then
            Platform.IsTouch = false
        end
    end)
    
    return Platform
    
end)()

-- module: Components/MobileToggle
local __mod_Components_MobileToggle = (function()
    --[[
        Black UI Library
        Components/MobileToggle.lua
    
        Botao flutuante arrastavel exibido apenas em dispositivos mobile
        (touch), usado para mostrar/esconder a janela principal sem
        depender de teclado (o keybind RightControl nao existe no celular).
    ]]
    
    local Create = __mod_Utilities_Create
    local Draggable = __mod_Utilities_Draggable
    local Tween = __mod_Utilities_Tween
    local Platform = __mod_Utilities_Platform
    local Theme_ = Create.Theme
    
    local MobileToggle = {}
    
    function MobileToggle.Create(Black, window)
        if not Platform.IsMobile then
            return nil
        end
    
        local theme = Create.GetTheme()
    
        local Bubble = Create.New("Frame", {
            Name = "MobileToggle",
            BackgroundColor3 = Theme_("Surface"),
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.fromOffset(16, 120),
            Size = UDim2.fromOffset(48, 48),
            Parent = Black.ScreenGui,
            Children = {
                Create.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                Create.New("UIStroke", { Color = Theme_("BorderStrong"), Thickness = 1 }),
            },
        })
    
        local Glyph = Create.New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Font = theme.FontBold,
            Text = "B",
            TextColor3 = Theme_("Text"),
            TextSize = 18,
            Parent = Bubble,
        })
    
        local HitButton = Create.New("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Parent = Bubble,
        })
    
        Draggable.Enable(Bubble, Bubble, { ClampToScreen = true })
    
        -- Evita que o "click" dispare apos um drag longo:
        -- so alterna se o movimento total foi pequeno.
        local pressStart = nil
        local startPos = nil
    
        HitButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                pressStart = input.Position
                startPos = Bubble.Position
            end
        end)
    
        HitButton.InputEnded:Connect(function(input)
            if not pressStart then
                return
            end
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                local moved = (input.Position - pressStart).Magnitude
                if moved < 8 then
                    window:SetVisible(not window.Toggled)
                    Tween.Play(Bubble, theme.TweenFast, { Size = UDim2.fromOffset(42, 42) })
                    task.delay(0.1, function()
                        Tween.Play(Bubble, theme.TweenFast, { Size = UDim2.fromOffset(48, 48) })
                    end)
                end
                pressStart = nil
            end
        end)
    
        return Bubble
    end
    
    return MobileToggle
    
end)()

-- module: Components/Notification
local __mod_Components_Notification = (function()
    --[[
        Black UI Library
        Components/Notification.lua
    
        Toast de notificacao no canto da tela. Slide-in + fade-out, com
        barra de progresso indicando o tempo restante. Tipos: info (default),
        success, warning, error - cada um muda a cor da barra lateral.
    ]]
    
    local Create = __mod_Utilities_Create
    local Tween = __mod_Utilities_Tween
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
                    Padding = UDim.new(0, 8),
                }),
            },
        })
    
        function Black:Notify(opts)
            opts = opts or {}
            local duration = opts.Duration or opts.Time or 3
            local typeKey = TypeColors[opts.Type or "Info"] or "Accent"
    
            local Toast = Create.New("Frame", {
                Name = "Toast",
                BackgroundColor3 = Theme_("Surface"),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = true,
                Parent = Area,
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
                Parent = Toast,
                Children = {
                    Create.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                },
            })
    
            local TextHolder = Create.New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(14, 10),
                Size = UDim2.new(1, -24, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = Toast,
                Children = {
                    Create.New("UIListLayout", { Padding = UDim.new(0, 2) }),
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
    
            -- padding inferior (compensa o AutomaticSize do TextHolder)
            Create.New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 10),
                LayoutOrder = 99,
                Parent = TextHolder,
            })
    
            -- Barra de progresso (tempo restante)
            local ProgressTrack = Create.New("Frame", {
                Name = "ProgressTrack",
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 2),
                BackgroundColor3 = Theme_("Border"),
                Parent = Toast,
            })
            local ProgressFill = Create.New("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Theme_(typeKey),
                Parent = ProgressTrack,
            })
    
            -- Animacao de entrada: slide + fade
            Toast.Position = UDim2.fromOffset(40, 0)
            local groupTransparency = Instance.new("NumberValue")
    
            for _, descendant in Toast:GetDescendants() do
                if descendant:IsA("GuiObject") then
                    if descendant:IsA("TextLabel") then
                        descendant.TextTransparency = 1
                    else
                        descendant.BackgroundTransparency = (descendant.BackgroundTransparency or 0)
                    end
                end
            end
    
            Toast.BackgroundTransparency = 1
            Tween.Play(Toast, theme.TweenNormal, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0 })
    
            for _, descendant in Toast:GetDescendants() do
                if descendant:IsA("TextLabel") then
                    Tween.Play(descendant, theme.TweenNormal, { TextTransparency = 0 })
                end
            end
    
            Tween.Play(ProgressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                Size = UDim2.new(0, 0, 1, 0),
            })
    
            local function dismiss()
                Tween.Play(Toast, theme.TweenFast, { Position = UDim2.fromOffset(40, 0), BackgroundTransparency = 1 })
                for _, descendant in Toast:GetDescendants() do
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
    
end)()

-- module: Tab
local __mod_Tab = (function()
    --[[
        Black UI Library
        Tab.lua
    
        Cada tab tem um botao na sidebar e uma "Page" (ScrollingFrame) no
        content. Elementos (Button, Toggle, Slider, ...) sao criados dentro
        da page via metodos :CreateX().
    ]]
    
    local Create = __mod_Utilities_Create
    local Tween = __mod_Utilities_Tween
    local Theme_ = Create.Theme
    
    local Tab = {}
    Tab.__index = Tab
    
    function Tab.new(window, opts)
        opts = opts or {}
        local theme = Create.GetTheme()
    
        local self = setmetatable({}, Tab)
        self.Window = window
        self.Name = opts.Name or "Tab"
        self.Elements = {}
    
        -- Botao na sidebar
        self.Button = Create.New("TextButton", {
            Name = self.Name .. "Button",
            BackgroundColor3 = Theme_("Surface"),
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 34),
            Text = "",
            Parent = window.TabList,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
            },
        })
    
        self.ButtonLabel = Create.New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -20, 1, 0),
            Font = theme.Font,
            Text = self.Name,
            TextColor3 = theme.TextSecondary,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.Button,
        })
    
        Tween.ApplyHoverPress(self.Button, {
            Normal = theme.Surface,
            Hover = theme.SurfaceElevated,
        }, theme)
    
        self.Button.MouseButton1Click:Connect(function()
            window:SelectTab(self)
        end)
    
        -- Page (conteudo)
        self.Page = Create.New("ScrollingFrame", {
            Name = self.Name .. "Page",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.fromOffset(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Border,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            Parent = window.Content,
            Children = {
                Create.New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                }),
                Create.New("UIPadding", {
                    PaddingLeft = UDim.new(0, 16),
                    PaddingRight = UDim.new(0, 16),
                    PaddingTop = UDim.new(0, 16),
                    PaddingBottom = UDim.new(0, 16),
                }),
            },
        })
    
        return self
    end
    
    -- Os metodos CreateButton/CreateToggle/etc sao anexados em Elements/*.lua
    -- via Tab.RegisterElement, para manter cada componente isolado no seu
    -- proprio arquivo (evita um Tab.lua gigante).
    function Tab.RegisterElement(name, factoryFn)
        Tab[name] = function(self, opts)
            local element = factoryFn(self, opts)
            table.insert(self.Elements, element)
            return element
        end
    end
    
    return Tab
    
end)()

-- module: Components/ProfileCard
local __mod_Components_ProfileCard = (function()
    --[[
        Black UI Library
        Components/ProfileCard.lua
    
        Card de perfil (avatar do jogador + saudacao), no estilo da tela
        "Menu" de hubs privados como o IceHub. Pensado pra ser usado como
        primeiro elemento de uma tab (ex: Window:CreateTab -> Tab:CreateProfileCard()).
    
        O credito do desenvolvedor e OPCIONAL (opt-in): so aparece se
        ShowCredit=true ou se um texto de Credit for passado explicitamente.
        Por padrao nenhum credito e exibido.
    ]]
    
    local Players = game:GetService("Players")
    
    local Create = __mod_Utilities_Create
    local Tween = __mod_Utilities_Tween
    local Tab = __mod_Tab
    local Theme_ = Create.Theme
    
    local DEVELOPER_CREDIT = "Discord: @falsocrime"
    
    Tab.RegisterElement("CreateProfileCard", function(tab, opts)
        opts = opts or {}
        local theme = Create.GetTheme()
        local localPlayer = Players.LocalPlayer
    
        local hideAvatar = opts.HideAvatar == true
        local hideUsername = opts.HideUsername == true
        -- O credito do desenvolvedor e opt-in: so aparece se ShowCredit=true ou
        -- se um texto de Credit for explicitamente fornecido.
        local showCredit = opts.ShowCredit == true or opts.Credit ~= nil
    
        local Holder = Create.New("Frame", {
            Name = "ProfileCard",
            BackgroundColor3 = Theme_("Surface"),
            Size = UDim2.new(1, 0, 0, 96),
            Parent = tab.Page,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("BorderStrong"), Thickness = 1, Transparency = 0.4 }),
                Create.New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingTop = UDim.new(0, 12),
                    PaddingBottom = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                }),
            },
        })
    
        local Avatar = Create.New("ImageLabel", {
            Name = "Avatar",
            BackgroundColor3 = Theme_("SurfaceElevated"),
            Size = UDim2.fromOffset(72, 72),
            Image = "",
            Parent = Holder,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("BorderStrong"), Thickness = 1, Transparency = 0.3 }),
            },
        })
    
        local function loadAvatar()
            if hideAvatar then
                Avatar.Image = ""
                return
            end
            task.spawn(function()
                local ok, content = pcall(function()
                    return Players:GetUserThumbnailAsync(
                        localPlayer.UserId,
                        Enum.ThumbnailType.AvatarBust,
                        Enum.ThumbnailSize.Size420x420
                    )
                end)
                Avatar.Image = (ok and content) or "rbxasset://textures/ui/GuiImagePlaceholder.png"
            end)
        end
        loadAvatar()
    
        local TextHolder = Create.New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(84, 0),
            Size = UDim2.new(1, -84, 1, 0),
            Parent = Holder,
        })
    
        local Greeting = Create.New("TextLabel", {
            Name = "Greeting",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 4),
            Size = UDim2.new(1, 0, 0, 20),
            Font = theme.FontSemibold,
            Text = hideUsername and "Hey, [hidden] !" or ("Hey, " .. localPlayer.DisplayName .. " !"),
            TextColor3 = theme.Text,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TextHolder,
        })
    
        Create.New("TextLabel", {
            Name = "UserId",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 26),
            Size = UDim2.new(1, 0, 0, 16),
            Font = theme.Font,
            Text = "@" .. localPlayer.Name,
            TextColor3 = theme.TextSecondary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TextHolder,
        })
    
        -- Credito do desenvolvedor: opcional (opt-in via ShowCredit=true ou Credit=texto).
        -- Nao e exibido por padrao — quem usa a lib decide se quer por.
        if showCredit then
            Create.New("TextLabel", {
                Name = "DeveloperCredit",
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 16),
                Font = theme.Font,
                Text = opts.Credit or DEVELOPER_CREDIT,
                TextColor3 = theme.TextDisabled,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = TextHolder,
            })
        end
    
        local api = {
            Instance = Holder,
            SetHideAvatar = function(_, value)
                hideAvatar = value
                loadAvatar()
            end,
            SetHideUsername = function(_, value)
                hideUsername = value
                Greeting.Text = hideUsername and "Hey, [hidden] !" or ("Hey, " .. localPlayer.DisplayName .. " !")
            end,
        }
    
        return api
    end)
    
    -- Registra tambem um pequeno rodape de credito isolado, para quem quiser
    -- so o texto (sem o card de avatar), ex: no fim de uma pagina de "Sobre".
    Tab.RegisterElement("CreateCredit", function(tab, opts)
        opts = opts or {}
        local theme = Create.GetTheme()
    
        local Label = Create.New("TextLabel", {
            Name = "Credit",
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            Font = theme.Font,
            Text = opts.Text or DEVELOPER_CREDIT,
            TextColor3 = Theme_("TextDisabled"),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = tab.Page,
        })
    
        return { Instance = Label }
    end)
    
end)()

-- module: Utilities/HelpButton
local __mod_Utilities_HelpButton = (function()
    --[[
        Black UI Library
        Utilities/HelpButton.lua
    
        Botao de ajuda (?) opcional, anexavel no canto de qualquer elemento
        (Button, Toggle, Input, Slider, Dropdown, KeyBind, ColorPicker...).
        Ao clicar, mostra um tooltip flutuante logo abaixo do elemento com o
        texto de ajuda — inspirado no botao "Help" da IceHub, porem sem
        depender de um BlurFrame global fixo.
    ]]
    
    local Create = __mod_Utilities_Create
    local Tween = __mod_Utilities_Tween
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
    
end)()

-- module: Elements/Button
local __mod_Elements_Button = (function()
    --[[
        Black UI Library
        Elements/Button.lua
    
        Botao simples com nome + descricao opcional, feedback de hover/press.
    ]]
    
    local Create = __mod_Utilities_Create
    local Tween = __mod_Utilities_Tween
    local HelpButton = __mod_Utilities_HelpButton
    local Tab = __mod_Tab
    local Theme_ = Create.Theme
    
    Tab.RegisterElement("CreateButton", function(tab, opts)
        opts = opts or {}
        local theme = Create.GetTheme()
    
        local hasDescription = opts.Description ~= nil and opts.Description ~= ""
        local hasHelp = opts.Help ~= nil and opts.Help ~= ""
        local height = hasDescription and 52 or 38
        local rightMargin = hasHelp and 46 or 20
    
        local Holder = Create.New("TextButton", {
            Name = "Button_" .. (opts.Name or "Button"),
            BackgroundColor3 = Theme_("Surface"),
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, height),
            Text = "",
            Parent = tab.Page,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1, Transparency = 0.5 }),
                Create.New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
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
            NameLabel.Position = UDim2.fromOffset(0, 8)
    
            Create.New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 28),
                Size = UDim2.new(1, -rightMargin, 0, 16),
                Font = theme.Font,
                Text = opts.Description,
                TextColor3 = theme.TextSecondary,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                Parent = Holder,
            })
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
    
end)()

-- module: Utilities/Signal
local __mod_Utilities_Signal = (function()
    --[[
        Black UI Library
        Utilities/Signal.lua
    
        Mini event system (pub/sub) usado internamente pelos componentes
        para expor eventos como :OnChanged(), :OnClick(), etc.
    ]]
    
    local Signal = {}
    Signal.__index = Signal
    
    function Signal.new()
        return setmetatable({
            _handlers = {},
        }, Signal)
    end
    
    function Signal:Connect(fn)
        local handler = { fn = fn }
        table.insert(self._handlers, handler)
    
        local connection = {}
        function connection:Disconnect()
            local idx = table.find(self._handlers, handler)
            if idx then
                table.remove(self._handlers, idx)
            end
        end
        setmetatable(connection, { __index = function(_, k)
            if k == "Disconnect" then
                return connection.Disconnect
            end
        end })
    
        return connection
    end
    
    function Signal:Fire(...)
        -- copia pra evitar problema se um handler se desconectar durante o Fire
        local handlers = table.clone(self._handlers)
        for _, handler in handlers do
            task.spawn(handler.fn, ...)
        end
    end
    
    function Signal:DisconnectAll()
        table.clear(self._handlers)
    end
    
    return Signal
    
end)()

-- module: Elements/ColorPicker
local __mod_Elements_ColorPicker = (function()
    --[[
        Black UI Library
        Elements/ColorPicker.lua
    
        Seletor de cor: preview clicavel que abre um popup com
        - area SV (saturation/value) arrastavel
        - slider de Hue
        Nao depende de nenhuma imagem/asset externo (tudo desenhado com
        UIGradient, ficando 100% compativel com qualquer executor).
    ]]
    
    local UserInputService = game:GetService("UserInputService")
    
    local Create = __mod_Utilities_Create
    local Tween = __mod_Utilities_Tween
    local Signal = __mod_Utilities_Signal
    local HelpButton = __mod_Utilities_HelpButton
    local Tab = __mod_Tab
    local Theme_ = Create.Theme
    
    Tab.RegisterElement("CreateColorPicker", function(tab, opts)
        opts = opts or {}
        local theme = Create.GetTheme()
    
        local color = opts.Default or Color3.new(1, 1, 1)
        local h, s, v = color:ToHSV()
        local isOpen = false
    
        local Holder = Create.New("Frame", {
            Name = "ColorPicker_" .. (opts.Name or "ColorPicker"),
            BackgroundColor3 = Theme_("Surface"),
            Size = UDim2.new(1, 0, 0, 42),
            ZIndex = 5,
            ClipsDescendants = false,
            Parent = tab.Page,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1, Transparency = 0.5 }),
                Create.New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                }),
            },
        })
    
        local hasHelp = opts.Help ~= nil and opts.Help ~= ""
        local previewOffset = hasHelp and -26 or 0
    
        Create.New("TextLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, -50, 1, 0),
            Font = theme.FontSemibold,
            Text = opts.Name or "Color",
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })
    
        HelpButton.Attach(Holder, opts.Help)
    
        local Preview = Create.New("TextButton", {
            Name = "Preview",
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, previewOffset, 0.5, 0),
            Size = UDim2.fromOffset(28, 28),
            BackgroundColor3 = color,
            Text = "",
            Parent = Holder,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1 }),
            },
        })
    
        -- Popup
        local Popup = Create.New("Frame", {
            Name = "Popup",
            BackgroundColor3 = Theme_("SurfaceElevated"),
            Position = UDim2.new(1, 0, 1, 6),
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.fromOffset(180, 0),
            ClipsDescendants = true,
            Visible = false,
            ZIndex = 20,
            Parent = Holder,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1 }),
                Create.New("UIPadding", {
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10),
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 10),
                }),
            },
        })
    
        -- SV box
        local SVBox = Create.New("Frame", {
            Name = "SVBox",
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 0, 100),
            BackgroundColor3 = Color3.fromHSV(h, 1, 1),
            ClipsDescendants = true,
            Parent = Popup,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
            },
        })
    
        -- gradiente branco->transparente (saturation) da esquerda pra direita
        Create.New("UIGradient", {
            Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = SVBox,
        })
    
        local BlackOverlay = Create.New("Frame", {
            Name = "BlackOverlay",
            BackgroundColor3 = Color3.new(0, 0, 0),
            Size = UDim2.fromScale(1, 1),
            Parent = SVBox,
            Children = {
                Create.New("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    }),
                }),
            },
        })
    
        local SVCursor = Create.New("Frame", {
            Name = "Cursor",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(10, 10),
            BackgroundColor3 = Color3.new(1, 1, 1),
            ZIndex = 21,
            Parent = SVBox,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusPill }),
                Create.New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5 }),
            },
        })
    
        -- Hue slider
        local HueTrack = Create.New("Frame", {
            Name = "HueTrack",
            Position = UDim2.fromOffset(0, 112),
            Size = UDim2.new(1, 0, 0, 14),
            Parent = Popup,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusPill }),
                Create.New("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                        ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
                        ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
                        ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
                        ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
                        ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
                    }),
                }),
            },
        })
    
        local HueCursor = Create.New("Frame", {
            Name = "HueCursor",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(h, 0, 0.5, 0),
            Size = UDim2.fromOffset(6, 18),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Parent = HueTrack,
            Children = {
                Create.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
                Create.New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }),
            },
        })
    
        local changedSignal = Signal.new()
    
        local function updateColor(fire)
            color = Color3.fromHSV(h, s, v)
            Preview.BackgroundColor3 = color
            SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            if fire ~= false then
                if opts.Callback then
                    task.spawn(opts.Callback, color)
                end
                changedSignal:Fire(color)
            end
        end
    
        local function positionCursors()
            SVCursor.Position = UDim2.new(s, 0, 1 - v, 0)
            HueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        end
        positionCursors()
    
        local api = {
            Instance = Holder,
            Value = color,
            OnChanged = function(_, fn)
                return changedSignal:Connect(fn)
            end,
        }
    
        api.SetValue = function(_, newColor)
            color = newColor
            h, s, v = color:ToHSV()
            positionCursors()
            updateColor(false)
        end
    
        -- Toggle popup
        Preview.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            Popup.Visible = true
            Tween.Play(Popup, theme.TweenNormal, { Size = isOpen and UDim2.fromOffset(180, 140) or UDim2.fromOffset(180, 0) })
            if not isOpen then
                task.delay(0.2, function()
                    if not isOpen then
                        Popup.Visible = false
                    end
                end)
            end
        end)
    
        -- Drag SV
        local draggingSV, draggingHue = false, false
    
        local function isPointerInput(input)
            return input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
        end
    
        local function updateSVFromInput(pos)
            local absPos, absSize = SVBox.AbsolutePosition, SVBox.AbsoluteSize
            s = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
            v = 1 - math.clamp((pos.Y - absPos.Y) / absSize.Y, 0, 1)
            positionCursors()
            updateColor(true)
        end
    
        local function updateHueFromInput(pos)
            local absPos, absSize = HueTrack.AbsolutePosition, HueTrack.AbsoluteSize
            h = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
            positionCursors()
            updateColor(true)
        end
    
        SVBox.InputBegan:Connect(function(input)
            if not isPointerInput(input) then return end
            draggingSV = true
            updateSVFromInput(input.Position)
        end)
        SVBox.InputEnded:Connect(function(input)
            if isPointerInput(input) then draggingSV = false end
        end)
    
        HueTrack.InputBegan:Connect(function(input)
            if not isPointerInput(input) then return end
            draggingHue = true
            updateHueFromInput(input.Position)
        end)
        HueTrack.InputEnded:Connect(function(input)
            if isPointerInput(input) then draggingHue = false end
        end)
    
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            if draggingSV then
                updateSVFromInput(input.Position)
            elseif draggingHue then
                updateHueFromInput(input.Position)
            end
        end)
    
        return api
    end)
    
end)()

-- module: Elements/Dropdown
local __mod_Elements_Dropdown = (function()
    --[[
        Black UI Library
        Elements/Dropdown.lua
    
        Dropdown com lista animada (fade + tamanho), suporte a selecao
        unica ou multipla, fecha automaticamente ao clicar fora.
    ]]
    
    local UserInputService = game:GetService("UserInputService")
    
    local Create = __mod_Utilities_Create
    local Tween = __mod_Utilities_Tween
    local Signal = __mod_Utilities_Signal
    local HelpButton = __mod_Utilities_HelpButton
    local Tab = __mod_Tab
    local Theme_ = Create.Theme
    
    -- Rastreia o dropdown aberto atualmente (so um pode estar aberto por vez)
    local OpenDropdown = nil
    
    Tab.RegisterElement("CreateDropdown", function(tab, opts)
        opts = opts or {}
        local theme = Create.GetTheme()
        local values = opts.Options or opts.Values or {}
        local multi = opts.Multi == true
        local isOpen = false
        local hasHelp = opts.Help ~= nil and opts.Help ~= ""
        local labelRightMargin = hasHelp and 44 or 24
    
        local selected = {}
        if multi then
            if typeof(opts.Default) == "table" then
                for _, v in opts.Default do
                    selected[v] = true
                end
            end
        else
            selected.single = opts.Default or values[1]
        end
    
        local function displayText()
            if multi then
                local names = {}
                for _, v in values do
                    if selected[v] then
                        table.insert(names, v)
                    end
                end
                if #names == 0 then
                    return opts.Placeholder or "None selected"
                end
                return table.concat(names, ", ")
            end
            return selected.single or opts.Placeholder or "Select..."
        end
    
        local Holder = Create.New("Frame", {
            Name = "Dropdown_" .. (opts.Name or "Dropdown"),
            BackgroundColor3 = Theme_("Surface"),
            Size = UDim2.new(1, 0, 0, 42),
            ClipsDescendants = false,
            ZIndex = 5,
            Parent = tab.Page,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1, Transparency = 0.5 }),
            },
        })
    
        Create.New("TextLabel", {
            Name = "NameLabel",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 4),
            Size = UDim2.new(1, -24, 0, 14),
            Font = theme.Font,
            Text = opts.Name or "Dropdown",
            TextColor3 = theme.TextSecondary,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })
    
        local SelectedLabel = Create.New("TextLabel", {
            Name = "SelectedLabel",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 18),
            Size = UDim2.new(1, -(labelRightMargin + 10), 0, 18),
            Font = theme.FontSemibold,
            Text = displayText(),
            TextColor3 = theme.Text,
            TextSize = 13,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })
    
        local Chevron = Create.New("TextLabel", {
            Name = "Chevron",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -labelRightMargin, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            Font = theme.FontBold,
            Text = "v",
            TextColor3 = theme.TextSecondary,
            TextSize = 11,
            Parent = Holder,
        })
    
        HelpButton.Attach(Holder, opts.Help, UDim2.new(1, -6, 0, 12))
    
        local HitArea = Create.New("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Parent = Holder,
        })
    
        -- Lista (fica por cima, parented na mesma page pra clip nao cortar)
        local itemHeight = 30
        local maxVisible = opts.MaxVisibleItems or 6
        local listHeight = math.min(#values, maxVisible) * itemHeight
    
        local List = Create.New("ScrollingFrame", {
            Name = "List",
            BackgroundColor3 = Theme_("SurfaceElevated"),
            Position = UDim2.new(0, 0, 1, 4),
            Size = UDim2.new(1, 0, 0, 0),
            ClipsDescendants = true,
            CanvasSize = UDim2.fromOffset(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Border,
            Visible = false,
            ZIndex = 10,
            Parent = Holder,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1 }),
                Create.New("UIListLayout", {}),
            },
        })
    
        local changedSignal = Signal.new()
        local itemButtons = {}
    
        local function refreshItemVisuals()
            for value, btn in itemButtons do
                local isSelected = multi and selected[value] or (not multi and selected.single == value)
                btn.BackgroundColor3 = isSelected and theme.SurfaceHover or theme.SurfaceElevated
                local check = btn:FindFirstChild("Check")
                if check then
                    check.Visible = isSelected
                end
            end
        end
    
        local function fireChange()
            local value
            if multi then
                value = table.clone(selected)
            else
                value = selected.single
            end
            if opts.Callback then
                task.spawn(opts.Callback, value)
            end
            changedSignal:Fire(value)
        end
    
        local function selectValue(value)
            if multi then
                if selected[value] then
                    selected[value] = nil
                else
                    selected[value] = true
                end
            else
                selected.single = value
            end
            SelectedLabel.Text = displayText()
            refreshItemVisuals()
            fireChange()
        end
    
        for _, value in values do
            local Item = Create.New("TextButton", {
                Name = "Item",
                BackgroundColor3 = Theme_("SurfaceElevated"),
                AutoButtonColor = false,
                Size = UDim2.new(1, 0, 0, itemHeight),
                Text = "",
                Parent = List,
            })
    
            Create.New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -30, 1, 0),
                Font = theme.Font,
                Text = tostring(value),
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Item,
            })
    
            Create.New("TextLabel", {
                Name = "Check",
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Font = theme.FontBold,
                Text = "✓",
                TextColor3 = theme.Accent,
                TextSize = 13,
                Visible = false,
                Parent = Item,
            })
    
            Tween.ApplyHoverPress(Item, {
                Normal = theme.SurfaceElevated,
                Hover = theme.SurfaceHover,
            }, theme)
    
            itemButtons[value] = Item
        end
    
        refreshItemVisuals()
    
        local open, close
    
        function close()
            isOpen = false
            Tween.Play(List, theme.TweenFast, { Size = UDim2.new(1, 0, 0, 0) })
            Tween.Play(Chevron, theme.TweenFast, { Rotation = 0 })
            task.delay(0.15, function()
                if not isOpen then
                    List.Visible = false
                end
            end)
            OpenDropdown = nil
        end
    
        function open()
            if OpenDropdown then
                OpenDropdown()
            end
            isOpen = true
            List.Visible = true
            Tween.Play(List, theme.TweenNormal, { Size = UDim2.new(1, 0, 0, listHeight) })
            Tween.Play(Chevron, theme.TweenFast, { Rotation = 180 })
            OpenDropdown = close
        end
    
        for value, Item in itemButtons do
            Item.MouseButton1Click:Connect(function()
                selectValue(value)
                if not multi then
                    close()
                end
            end)
        end
    
        HitArea.MouseButton1Click:Connect(function()
            if isOpen then
                close()
            else
                open()
            end
        end)
    
        UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            if not isOpen then
                return
            end
            task.defer(function()
                local mousePos = UserInputService:GetMouseLocation()
                local overHolder = mousePos.X >= Holder.AbsolutePosition.X
                    and mousePos.X <= Holder.AbsolutePosition.X + Holder.AbsoluteSize.X
                    and mousePos.Y >= Holder.AbsolutePosition.Y
                    and mousePos.Y <= Holder.AbsolutePosition.Y + Holder.AbsoluteSize.Y + listHeight + 8
                if not overHolder then
                    close()
                end
            end)
        end)
    
        local api = {
            Instance = Holder,
            OnChanged = function(_, fn)
                return changedSignal:Connect(fn)
            end,
        }
    
        api.SetValue = function(_, value)
            if multi and typeof(value) == "table" then
                selected = {}
                for _, v in value do
                    selected[v] = true
                end
            else
                selected.single = value
            end
            SelectedLabel.Text = displayText()
            refreshItemVisuals()
        end
    
        api.GetValue = function()
            if multi then
                return table.clone(selected)
            end
            return selected.single
        end
    
        return api
    end)
    
end)()

-- module: Elements/Input
local __mod_Elements_Input = (function()
    --[[
        Black UI Library
        Elements/Input.lua
    
        Campo de texto (TextBox) com placeholder, callback em FocusLost e
        suporte a Numeric (filtra apenas digitos).
    ]]
    
    local Create = __mod_Utilities_Create
    local Signal = __mod_Utilities_Signal
    local HelpButton = __mod_Utilities_HelpButton
    local Tab = __mod_Tab
    local Theme_ = Create.Theme
    
    Tab.RegisterElement("CreateInput", function(tab, opts)
        opts = opts or {}
        local theme = Create.GetTheme()
    
        local Holder = Create.New("Frame", {
            Name = "Input_" .. (opts.Name or "Input"),
            BackgroundColor3 = Theme_("Surface"),
            Size = UDim2.new(1, 0, 0, 42),
            Parent = tab.Page,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1, Transparency = 0.5 }),
                Create.New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                }),
            },
        })
    
        HelpButton.Attach(Holder, opts.Help)
    
        Create.New("TextLabel", {
            Name = "NameLabel",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0.4, 0, 1, 0),
            Font = theme.FontSemibold,
            Text = opts.Name or "Input",
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })
    
        local hasHelp = opts.Help ~= nil and opts.Help ~= ""
        local boxWidthScale = hasHelp and 0.47 or 0.55
        local boxOffset = hasHelp and -26 or 0
    
        local Box = Create.New("TextBox", {
            Name = "Box",
            BackgroundColor3 = Theme_("SurfaceElevated"),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, boxOffset, 0.5, 0),
            Size = UDim2.new(boxWidthScale, 0, 0, 28),
            Font = theme.Font,
            Text = tostring(opts.Default or ""),
            PlaceholderText = opts.Placeholder or "",
            PlaceholderColor3 = theme.TextDisabled,
            TextColor3 = theme.Text,
            TextSize = 13,
            ClearTextOnFocus = opts.ClearTextOnFocus == true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
            },
        })
    
        local changedSignal = Signal.new()
    
        if opts.Numeric then
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                local filtered = Box.Text:gsub("[^%d%.%-]", "")
                if filtered ~= Box.Text then
                    Box.Text = filtered
                end
            end)
        end
    
        local api = {
            Instance = Holder,
            Value = opts.Default or "",
            OnChanged = function(_, fn)
                return changedSignal:Connect(fn)
            end,
        }
    
        local function commit()
            local text = Box.Text
            if text == "" and opts.AllowEmpty == false then
                text = tostring(opts.Default or "")
                Box.Text = text
            end
            if opts.Numeric and text ~= "" then
                local num = tonumber(text)
                if num then
                    if opts.Min then
                        num = math.max(num, opts.Min)
                    end
                    if opts.Max then
                        num = math.min(num, opts.Max)
                    end
                    text = tostring(num)
                    Box.Text = text
                elseif opts.AllowEmpty == false or opts.Default ~= nil then
                    text = tostring(opts.Default or 0)
                    Box.Text = text
                end
            end
            api.Value = text
            if opts.Callback then
                task.spawn(opts.Callback, text)
            end
            changedSignal:Fire(text)
        end
    
        Box.FocusLost:Connect(function(enterPressed)
            if opts.Finished and not enterPressed then
                return
            end
            commit()
        end)
    
        api.SetValue = function(_, text)
            Box.Text = tostring(text)
            commit()
        end
    
        return api
    end)
    
end)()

-- module: Elements/KeyBind
local __mod_Elements_KeyBind = (function()
    --[[
        Black UI Library
        Elements/KeyBind.lua
    
        Captura de tecla/botao do mouse para atalhos. Clique no campo entra
        em modo "escutando" (visual destacado) e a proxima tecla pressionada
        e capturada como novo bind.
    ]]
    
    local UserInputService = game:GetService("UserInputService")
    
    local Create = __mod_Utilities_Create
    local Tween = __mod_Utilities_Tween
    local Signal = __mod_Utilities_Signal
    local HelpButton = __mod_Utilities_HelpButton
    local Tab = __mod_Tab
    local Theme_ = Create.Theme
    
    local MouseButtonNames = {
        [Enum.UserInputType.MouseButton1] = "MB1",
        [Enum.UserInputType.MouseButton2] = "MB2",
        [Enum.UserInputType.MouseButton3] = "MB3",
    }
    
    local function inputToLabel(input)
        if MouseButtonNames[input.UserInputType] then
            return MouseButtonNames[input.UserInputType]
        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            return input.KeyCode.Name
        end
        return nil
    end
    
    Tab.RegisterElement("CreateKeyBind", function(tab, opts)
        opts = opts or {}
        local theme = Create.GetTheme()
    
        local currentKey = opts.Default or "None"
        local listening = false
    
        local Holder = Create.New("Frame", {
            Name = "KeyBind_" .. (opts.Name or "KeyBind"),
            BackgroundColor3 = Theme_("Surface"),
            Size = UDim2.new(1, 0, 0, 42),
            Parent = tab.Page,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1, Transparency = 0.5 }),
                Create.New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                }),
            },
        })
    
        local hasHelp = opts.Help ~= nil and opts.Help ~= ""
        local keyButtonOffset = hasHelp and -26 or 0
    
        Create.New("TextLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0.5, 0, 1, 0),
            Font = theme.FontSemibold,
            Text = opts.Name or "KeyBind",
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })
    
        HelpButton.Attach(Holder, opts.Help)
    
        local KeyButton = Create.New("TextButton", {
            Name = "KeyButton",
            BackgroundColor3 = Theme_("SurfaceElevated"),
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, keyButtonOffset, 0.5, 0),
            Size = UDim2.fromOffset(90, 28),
            Font = theme.Font,
            Text = tostring(currentKey),
            TextColor3 = theme.Text,
            TextSize = 12,
            Parent = Holder,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
            },
        })
    
        Tween.ApplyHoverPress(KeyButton, {
            Normal = theme.SurfaceElevated,
            Hover = theme.SurfaceHover,
        }, theme)
    
        local changedSignal = Signal.new()
    
        local api = {
            Instance = Holder,
            Value = currentKey,
            OnChanged = function(_, fn)
                return changedSignal:Connect(fn)
            end,
        }
    
        local function setKey(newKey, fire)
            currentKey = newKey
            api.Value = newKey
            KeyButton.Text = tostring(newKey)
            if fire ~= false then
                if opts.Callback then
                    task.spawn(opts.Callback, newKey)
                end
                changedSignal:Fire(newKey)
            end
        end
    
        api.SetValue = function(_, newKey)
            setKey(newKey, true)
        end
    
        local inputConn = nil
    
        local function startListening()
            listening = true
            KeyButton.Text = "..."
            KeyButton.TextColor3 = theme.Accent
    
            inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if input.UserInputType ~= Enum.UserInputType.Keyboard
                    and not MouseButtonNames[input.UserInputType] then
                    return
                end
                local label = inputToLabel(input)
                if not label then
                    return
                end
                listening = false
                KeyButton.TextColor3 = theme.Text
                setKey(label, true)
                if inputConn then
                    inputConn:Disconnect()
                    inputConn = nil
                end
            end)
        end
    
        KeyButton.MouseButton1Click:Connect(function()
            if listening then
                return
            end
            startListening()
        end)
    
        return api
    end)
    
end)()

-- module: Elements/Label
local __mod_Elements_Label = (function()
    --[[
        Black UI Library
        Elements/Label.lua
    
        Label simples (texto informativo) e Paragraph (bloco maior com wrap).
    ]]
    
    local Create = __mod_Utilities_Create
    local Tab = __mod_Tab
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
    
end)()

-- module: Elements/Slider
local __mod_Elements_Slider = (function()
    --[[
        Black UI Library
        Elements/Slider.lua
    
        Slider moderno: track fino (4px), thumb circular, preenchimento
        (fill) branco indicando o progresso. Suporta mouse e touch.
    ]]
    
    local UserInputService = game:GetService("UserInputService")
    
    local Create = __mod_Utilities_Create
    local Tween = __mod_Utilities_Tween
    local Signal = __mod_Utilities_Signal
    local HelpButton = __mod_Utilities_HelpButton
    local Tab = __mod_Tab
    local Theme_ = Create.Theme
    
    Tab.RegisterElement("CreateSlider", function(tab, opts)
        opts = opts or {}
        local theme = Create.GetTheme()
    
        local min = opts.Min or 0
        local max = opts.Max or 100
        local rounding = opts.Rounding or 0
        local suffix = opts.Suffix or ""
        local value = math.clamp(opts.Default or min, min, max)
    
        local function fmt(v)
            if rounding <= 0 then
                v = math.floor(v + 0.5)
            else
                v = tonumber(string.format("%." .. rounding .. "f", v))
            end
            return v
        end
        value = fmt(value)
    
        local Holder = Create.New("Frame", {
            Name = "Slider_" .. (opts.Name or "Slider"),
            BackgroundColor3 = Theme_("Surface"),
            Size = UDim2.new(1, 0, 0, 56),
            Parent = tab.Page,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1, Transparency = 0.5 }),
                Create.New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                }),
            },
        })
    
        Create.New("TextLabel", {
            Name = "NameLabel",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 8),
            Size = UDim2.new(1, -60, 0, 16),
            Font = theme.FontSemibold,
            Text = opts.Name or "Slider",
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })
    
        HelpButton.Attach(Holder, opts.Help, UDim2.new(1, -6, 0, 16))
    
        local hasHelp = opts.Help ~= nil and opts.Help ~= ""
        local valueRightOffset = hasHelp and -26 or 0
    
        local ValueBox = Create.New("TextBox", {
            Name = "ValueBox",
            BackgroundColor3 = Theme_("SurfaceElevated"),
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, valueRightOffset, 0, 6),
            Size = UDim2.fromOffset(52, 18),
            Font = theme.Font,
            Text = tostring(value) .. suffix,
            TextColor3 = theme.TextSecondary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
            ClearTextOnFocus = false,
            Parent = Holder,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
            },
        })
    
        -- Track
        local Track = Create.New("Frame", {
            Name = "Track",
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, -12),
            Size = UDim2.new(1, 0, 0, 4),
            BackgroundColor3 = Theme_("SurfaceElevated"),
            Parent = Holder,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusPill }),
            },
        })
    
        local Fill = Create.New("Frame", {
            Name = "Fill",
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Theme_("Accent"),
            Parent = Track,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusPill }),
            },
        })
    
        local Thumb = Create.New("Frame", {
            Name = "Thumb",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            BackgroundColor3 = Theme_("Accent"),
            ZIndex = 2,
            Parent = Track,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusPill }),
                Create.New("UIStroke", { Color = Theme_("Background"), Thickness = 2 }),
            },
        })
    
        -- Hit area maior pra facilitar drag/touch
        local HitArea = Create.New("TextButton", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 24),
            Text = "",
            Parent = Track,
        })
    
        local changedSignal = Signal.new()
    
        local function updateVisual(v, animate)
            local alpha = (v - min) / (max - min)
            alpha = math.clamp(alpha, 0, 1)
            local tweenInfo = animate and theme.TweenFast or TweenInfo.new(0)
    
            if animate then
                Tween.Play(Fill, tweenInfo, { Size = UDim2.new(alpha, 0, 1, 0) })
                Tween.Play(Thumb, tweenInfo, { Position = UDim2.new(alpha, 0, 0.5, 0) })
            else
                Fill.Size = UDim2.new(alpha, 0, 1, 0)
                Thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
            end
            ValueBox.Text = tostring(v) .. suffix
        end
    
        updateVisual(value, false)
    
        local api = {
            Instance = Holder,
            Value = value,
            Min = min,
            Max = max,
            OnChanged = function(_, fn)
                return changedSignal:Connect(fn)
            end,
        }
    
        local function setValue(newValue, fireCallback, animate)
            newValue = fmt(math.clamp(newValue, min, max))
            if newValue == value and fireCallback == false then
                return
            end
            value = newValue
            api.Value = value
            updateVisual(value, animate ~= false)
            if fireCallback ~= false then
                if opts.Callback then
                    task.spawn(opts.Callback, value)
                end
                changedSignal:Fire(value)
            end
        end
    
        api.SetValue = function(_, newValue)
            setValue(newValue, true, true)
        end
    
        -- Permite digitar o valor diretamente na caixa (alem de arrastar o track)
        local escapedSuffix = suffix:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
        ValueBox.FocusLost:Connect(function()
            local parsed = tonumber((ValueBox.Text:gsub(escapedSuffix, ""):gsub("%s", "")))
            if parsed then
                setValue(parsed, true, true)
            else
                -- texto invalido: restaura o valor atual
                updateVisual(value, false)
            end
        end)
    
        -- Drag logic
        local dragging = false
    
        local function inputToValue(inputPosition)
            local trackAbsPos = Track.AbsolutePosition.X
            local trackAbsSize = Track.AbsoluteSize.X
            local alpha = math.clamp((inputPosition - trackAbsPos) / trackAbsSize, 0, 1)
            return min + (max - min) * alpha
        end
    
        local function isPointerInput(input)
            return input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
        end
    
        HitArea.InputBegan:Connect(function(input)
            if not isPointerInput(input) then
                return
            end
            dragging = true
            setValue(inputToValue(input.Position.X), true, false)
        end)
    
        HitArea.InputEnded:Connect(function(input)
            if isPointerInput(input) then
                dragging = false
            end
        end)
    
        UserInputService.InputChanged:Connect(function(input)
            if not dragging then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                setValue(inputToValue(input.Position.X), true, false)
            end
        end)
    
        return api
    end)
    
end)()

-- module: Elements/Toggle
local __mod_Elements_Toggle = (function()
    --[[
        Black UI Library
        Elements/Toggle.lua
    
        Switch estilo "anel + ponto" (outside ring / inside dot), como usado
        no IceHub: um circulo vazado (UIStroke) com um ponto interno que
        aparece/desaparece via transparencia ao ativar/desativar.
    ]]
    
    local Create = __mod_Utilities_Create
    local Tween = __mod_Utilities_Tween
    local Signal = __mod_Utilities_Signal
    local HelpButton = __mod_Utilities_HelpButton
    local Tab = __mod_Tab
    local Theme_ = Create.Theme
    
    Tab.RegisterElement("CreateToggle", function(tab, opts)
        opts = opts or {}
        local theme = Create.GetTheme()
        local state = opts.Default == true
        local hasHelp = opts.Help ~= nil and opts.Help ~= ""
        local rightMargin = hasHelp and 66 or 40
    
        local Holder = Create.New("Frame", {
            Name = "Toggle_" .. (opts.Name or "Toggle"),
            BackgroundColor3 = Theme_("Surface"),
            Size = UDim2.new(1, 0, 0, 42),
            Parent = tab.Page,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusSmall }),
                Create.New("UIStroke", { Color = Theme_("Border"), Thickness = 1, Transparency = 0.5 }),
                Create.New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                }),
            },
        })
    
        Create.New("TextLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, -rightMargin, 1, 0),
            Font = theme.FontSemibold,
            Text = opts.Name or "Toggle",
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })
    
        HelpButton.Attach(Holder, opts.Help)
    
        -- Anel externo (outside ring)
        local OutsideRing = Create.New("Frame", {
            Name = "OutsideRing",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, hasHelp and -26 or 0, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            BackgroundTransparency = 1,
            Parent = Holder,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusPill }),
                Create.New("UIStroke", {
                    Color = Theme_("BorderStrong"),
                    Thickness = 1.7,
                    Transparency = 0,
                }),
            },
        })
    
        -- Ponto interno (inside dot), some/aparece via transparencia
        local InsideDot = Create.New("Frame", {
            Name = "InsideDot",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(12, 12),
            BackgroundColor3 = Theme_("Accent"),
            BackgroundTransparency = state and 0 or 1,
            Parent = OutsideRing,
            Children = {
                Create.New("UICorner", { CornerRadius = theme.CornerRadiusPill }),
            },
        })
    
        -- Hit area maior (facilita toque no mobile) via botao invisivel cobrindo tudo
        local HitArea = Create.New("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Parent = Holder,
        })
    
        local changedSignal = Signal.new()
    
        local function render(newState, animate)
            if animate then
                Tween.Play(InsideDot, theme.TweenFast, {
                    BackgroundTransparency = newState and 0 or 1,
                })
            else
                InsideDot.BackgroundTransparency = newState and 0 or 1
            end
        end
    
        local api = {
            Instance = Holder,
            Value = state,
            OnChanged = function(_, fn)
                return changedSignal:Connect(fn)
            end,
        }
    
        local function setValue(newState, fireCallback)
            state = newState
            api.Value = state
            render(state, true)
            if fireCallback ~= false then
                if opts.Callback then
                    task.spawn(opts.Callback, state)
                end
                changedSignal:Fire(state)
            end
        end
    
        api.SetValue = function(_, newState)
            setValue(newState, true)
        end
    
        HitArea.MouseButton1Click:Connect(function()
            setValue(not state, true)
        end)
    
        return api
    end)
    
end)()

-- module: Utilities/Theme
local __mod_Utilities_Theme = (function()
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
    
end)()

-- module: Window
local __mod_Window = (function()
    --[[
        Black UI Library
        Window.lua
    
        Janela principal: topbar (titulo + minimize/close), sidebar de tabs,
        container de conteudo. Drag habilitado pela topbar, com clamp de tela.
        Suporta minimizar (colapsa pra uma pill pequena) e um keybind global
        de toggle (default: RightControl).
    ]]
    
    local UserInputService = game:GetService("UserInputService")
    
    local Create = __mod_Utilities_Create
    local Draggable = __mod_Utilities_Draggable
    local Tween = __mod_Utilities_Tween
    local Platform = __mod_Utilities_Platform
    local Signal = __mod_Utilities_Signal
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
        self._dragConn = Draggable.Enable(self.Shadow, self.Topbar, { ClampToScreen = true })
    
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
        self._inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
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
        local Tab = __mod_Tab
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
        if self._inputConn then
            self._inputConn:Disconnect()
            self._inputConn = nil
        end
        if self._dragConn then
            self._dragConn:Disconnect()
            self._dragConn = nil
        end
        self.Shadow:Destroy()
    end
    
    return Window
    
end)()

-- module: init
local __mod_init = (function()
    --[[
        Black UI Library
        init.lua — Entry point
    
        Uso tipico (apos build, via loadstring):
            local Black = loadstring(game:HttpGet("URL"))()
            local Window = Black:CreateWindow({ Name = "My Hub" })
            local Tab = Window:CreateTab({ Name = "Main" })
            Tab:CreateButton({ Name = "Click me", Callback = function() end })
    
        Este arquivo:
        - Cria o ScreenGui raiz (protegido via protectgui/gethui quando disponivel)
        - Inicializa o sistema de tema (Utilities/Create + Theme)
        - Expoe Black:CreateWindow(), Black:Notify(), Black:SetTheme()
        - Inicializa Notification e MobileToggle
    ]]
    
    local cloneref = (cloneref or clonereference or function(instance)
        return instance
    end)
    
    local CoreGui = cloneref(game:GetService("CoreGui"))
    local Players = cloneref(game:GetService("Players"))
    
    local protectgui = protectgui or (syn and syn.protect_gui) or function() end
    local gethui = gethui or function()
        return CoreGui
    end
    local getgenv = getgenv or function()
        return shared
    end
    
    -- Execucao unica (singleton): se o script for executado de novo (ex: colar
    -- o loadstring outra vez no executor), a instancia anterior da Black UI e
    -- destruida por completo antes de criar a nova, evitando duas janelas/
    -- ScreenGuis coexistindo e handlers de input duplicados.
    do
        local env = getgenv()
        local previous = env.__BlackUIActiveInstance
        if previous then
            pcall(function()
                previous:Destroy()
            end)
            env.__BlackUIActiveInstance = nil
        end
    end
    
    local Create = __mod_Utilities_Create
    local Theme = __mod_Utilities_Theme
    local Window = __mod_Window
    local Notification = __mod_Components_Notification
    local MobileToggle = __mod_Components_MobileToggle
    -- (modulo "Components/ProfileCard" ja carregado acima)
    
    -- Carrega todos os elementos (eles se auto-registram em Tab via Tab.RegisterElement)
    -- (modulo "Elements/Button" ja carregado acima)
    -- (modulo "Elements/Toggle" ja carregado acima)
    -- (modulo "Elements/Slider" ja carregado acima)
    -- (modulo "Elements/Input" ja carregado acima)
    -- (modulo "Elements/Dropdown" ja carregado acima)
    -- (modulo "Elements/Label" ja carregado acima)
    -- (modulo "Elements/KeyBind" ja carregado acima)
    -- (modulo "Elements/ColorPicker" ja carregado acima)
    
    local Black = {
        _VERSION = "1.0.0", -- versao interna da lib (nao exibida na UI)
        Version = nil, -- versao exibida no titulo da janela; fica vazio se nao definida via CreateWindow({ Version = ... })
        Windows = {},
    }
    
    -- Tema atual (mutavel via Black:SetTheme)
    local CurrentTheme = table.clone(Theme.Default)
    Create.SetThemeTable(CurrentTheme)
    Black.Theme = CurrentTheme
    
    -- ScreenGui raiz
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BlackUI"
    ScreenGui.DisplayOrder = 999
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    do
        local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
        local ok = pcall(function()
            protectgui(ScreenGui)
            ScreenGui.Parent = gethui()
        end)
        if not ok or not ScreenGui.Parent then
            ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")
        end
    end
    
    Black.ScreenGui = ScreenGui
    
    do
        local env = getgenv()
        env.__BlackUIActiveInstance = Black
    end
    
    --[[
        Black:CreateWindow(opts)
        opts:
            Name (string)         - titulo da janela
            SubTitle (string?)    - subtitulo pequeno abaixo do titulo
            Version (string?)     - versao exibida ao lado do titulo (default: Black.Version)
            Size (UDim2?)         - tamanho inicial
            ToggleKeybind (Enum.KeyCode?) - tecla que abre/fecha (default RightControl)
    ]]
    function Black:CreateWindow(opts)
        opts = opts or {}
        if opts.Version then
            self.Version = opts.Version
        end
        local window = Window.new(self, opts)
        table.insert(self.Windows, window)
    
        -- Botao flutuante mobile (nulo em PC)
        MobileToggle.Create(self, window)
    
        return window
    end
    
    -- Sistema de notificacao (Black:Notify(...)) e injetado por Notification.Init
    Notification.Init(Black)
    
    --[[
        Black:SetTheme(themeTable)
        Mescla themeTable sobre o tema atual e reaplica em todos os elementos
        ja criados (via Create.RefreshTheme).
    ]]
    function Black:SetTheme(themeTable)
        for key, value in themeTable do
            CurrentTheme[key] = value
        end
        Create.RefreshTheme()
    end
    
    function Black:GetTheme()
        return CurrentTheme
    end
    
    --[[
        Black:Destroy()
        Remove toda a UI da tela e desconecta todos os handlers globais
        (keybinds, etc). Chamar ao descarregar o script — tambem e chamado
        automaticamente se o script for executado de novo (ver topo do arquivo).
    ]]
    function Black:Destroy()
        for _, window in self.Windows do
            window:Destroy()
        end
        self.Windows = {}
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end
    
    return Black
    
end)()

return __mod_init
