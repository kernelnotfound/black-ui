--[[
    Black UI Library
    Components/MobileToggle.lua

    Botao flutuante arrastavel exibido apenas em dispositivos mobile
    (touch), usado para mostrar/esconder a janela principal sem
    depender de teclado (o keybind RightControl nao existe no celular).
    Reaproveita o componente FloatingBubble (compartilhado com o
    MinimizeStyle == "Bubble" do Window).
]]

local Platform = require(script.Parent.Parent.Utilities.Platform)
local FloatingBubble = require(script.Parent.FloatingBubble)

local MobileToggle = {}

function MobileToggle.Create(Black, window)
    if not Platform.IsMobile then
        return nil
    end

    return FloatingBubble.Create({
        Parent = Black.ScreenGui,
        Position = UDim2.fromOffset(16, 120),
        OnClick = function()
            window:SetVisible(not window.Toggled)
        end,
    }).Instance
end

return MobileToggle
