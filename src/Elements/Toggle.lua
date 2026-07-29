--[[
    Black UI Library
    Elements/Toggle.lua

    Switch estilo "anel + ponto" (outside ring / inside dot), como usado
    no IceHub: um circulo vazado (UIStroke) com um ponto interno que
    aparece/desaparece via transparencia ao ativar/desativar.
]]

local Create = require(script.Parent.Parent.Utilities.Create)
local Tween = require(script.Parent.Parent.Utilities.Tween)
local Signal = require(script.Parent.Parent.Utilities.Signal)
local HelpButton = require(script.Parent.Parent.Utilities.HelpButton)
local Tab = require(script.Parent.Parent.Tab)
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
