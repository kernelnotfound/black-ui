--[[
    Black UI Library
    Elements/Input.lua

    Campo de texto (TextBox) com placeholder, callback em FocusLost e
    suporte a Numeric (filtra apenas digitos).
]]

local Create = require(script.Parent.Parent.Utilities.Create)
local Signal = require(script.Parent.Parent.Utilities.Signal)
local HelpButton = require(script.Parent.Parent.Utilities.HelpButton)
local Tab = require(script.Parent.Parent.Tab)
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
        TextTruncate = Enum.TextTruncate.AtEnd,
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
