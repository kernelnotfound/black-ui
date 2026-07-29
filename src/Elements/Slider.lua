--[[
    Black UI Library
    Elements/Slider.lua

    Slider moderno: track fino (4px), thumb circular, preenchimento
    (fill) branco indicando o progresso. Suporta mouse e touch.
]]

local UserInputService = game:GetService("UserInputService")

local Create = require(script.Parent.Parent.Utilities.Create)
local Tween = require(script.Parent.Parent.Utilities.Tween)
local Signal = require(script.Parent.Parent.Utilities.Signal)
local HelpButton = require(script.Parent.Parent.Utilities.HelpButton)
local Tab = require(script.Parent.Parent.Tab)
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
