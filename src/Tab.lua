--[[
    Black UI Library
    Tab.lua

    Cada tab tem um botao na sidebar e uma "Page" (ScrollingFrame) no
    content. Elementos (Button, Toggle, Slider, ...) sao criados dentro
    da page via metodos :CreateX().
]]

local Create = require(script.Parent.Utilities.Create)
local Tween = require(script.Parent.Utilities.Tween)
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
                SortOrder = Enum.SortOrder.LayoutOrder,
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
--
-- Cada elemento recebe um LayoutOrder incremental (ordem de criacao), pois
-- o UIListLayout da Page usa SortOrder.LayoutOrder — sem isso todos ficariam
-- com LayoutOrder 0 e a ordem visual seria indefinida.
function Tab.RegisterElement(name, factoryFn)
    Tab[name] = function(self, opts)
        local element = factoryFn(self, opts)
        table.insert(self.Elements, element)

        if element and element.Instance then
            element.Instance.LayoutOrder = #self.Elements
        end

        return element
    end
end

return Tab
