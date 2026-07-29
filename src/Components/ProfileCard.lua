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

local Create = require(script.Parent.Parent.Utilities.Create)
local Tween = require(script.Parent.Parent.Utilities.Tween)
local Tab = require(script.Parent.Parent.Tab)
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
