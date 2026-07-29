--[[
    Black UI Library
    Elements/KeyBind.lua

    Captura de tecla/botao do mouse para atalhos. Clique no campo entra
    em modo "escutando" (visual destacado) e a proxima tecla pressionada
    e capturada como novo bind.
]]

local UserInputService = game:GetService("UserInputService")

local Create = require(script.Parent.Parent.Utilities.Create)
local Tween = require(script.Parent.Parent.Utilities.Tween)
local Signal = require(script.Parent.Parent.Utilities.Signal)
local HelpButton = require(script.Parent.Parent.Utilities.HelpButton)
local Tab = require(script.Parent.Parent.Tab)
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
