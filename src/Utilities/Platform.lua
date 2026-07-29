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
