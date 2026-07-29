--[[
    Black UI Library
    Elements/Dropdown.lua

    Dropdown com lista animada (fade + tamanho), suporte a selecao
    unica ou multipla, fecha automaticamente ao clicar fora.
]]

local UserInputService = game:GetService("UserInputService")

local Create = require(script.Parent.Parent.Utilities.Create)
local Tween = require(script.Parent.Parent.Utilities.Tween)
local Signal = require(script.Parent.Parent.Utilities.Signal)
local HelpButton = require(script.Parent.Parent.Utilities.HelpButton)
local Tab = require(script.Parent.Parent.Tab)
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
        ZIndex = 4,
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
            Create.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
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

    for index, value in values do
        local Item = Create.New("TextButton", {
            Name = "Item",
            LayoutOrder = index,
            BackgroundColor3 = Theme_("SurfaceElevated"),
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, itemHeight),
            Text = "",
            ZIndex = 11,
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
