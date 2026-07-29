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

local Create = require(script.Parent.Parent.Utilities.Create)
local Tween = require(script.Parent.Parent.Utilities.Tween)
local Signal = require(script.Parent.Parent.Utilities.Signal)
local HelpButton = require(script.Parent.Parent.Utilities.HelpButton)
local Tab = require(script.Parent.Parent.Tab)
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
