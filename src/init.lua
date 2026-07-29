--[[
    Black UI Library
    init.lua — Entry point

    Uso tipico (apos build, via loadstring):
        local Black = loadstring(game:HttpGet("URL"))()
        local Window = Black:CreateWindow({ Name = "My Hub" })
        local Tab = Window:CreateTab({ Name = "Main" })
        Tab:CreateButton({ Name = "Click me", Callback = function() end })

    Este arquivo:
    - Cria o ScreenGui raiz (protegido via protectgui/gethui quando disponivel)
    - Inicializa o sistema de tema (Utilities/Create + Theme)
    - Expoe Black:CreateWindow(), Black:Notify(), Black:SetTheme()
    - Inicializa Notification e MobileToggle
]]

local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)

local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))

local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
    return CoreGui
end

local Create = require(script.Utilities.Create)
local Theme = require(script.Utilities.Theme)
local Window = require(script.Window)
local Notification = require(script.Components.Notification)
local MobileToggle = require(script.Components.MobileToggle)
require(script.Components.ProfileCard)

-- Carrega todos os elementos (eles se auto-registram em Tab via Tab.RegisterElement)
require(script.Elements.Button)
require(script.Elements.Toggle)
require(script.Elements.Slider)
require(script.Elements.Input)
require(script.Elements.Dropdown)
require(script.Elements.Label)
require(script.Elements.KeyBind)
require(script.Elements.ColorPicker)

local Black = {
    _VERSION = "1.0.0", -- versao interna da lib (nao exibida na UI)
    Version = nil, -- versao exibida no titulo da janela; fica vazio se nao definida via CreateWindow({ Version = ... })
    Windows = {},
}

-- Tema atual (mutavel via Black:SetTheme)
local CurrentTheme = table.clone(Theme.Default)
Create.SetThemeTable(CurrentTheme)
Black.Theme = CurrentTheme

-- ScreenGui raiz
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BlackUI"
ScreenGui.DisplayOrder = 999
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

do
    local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
    local ok = pcall(function()
        protectgui(ScreenGui)
        ScreenGui.Parent = gethui()
    end)
    if not ok or not ScreenGui.Parent then
        ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    end
end

Black.ScreenGui = ScreenGui

--[[
    Black:CreateWindow(opts)
    opts:
        Name (string)         - titulo da janela
        SubTitle (string?)    - subtitulo pequeno abaixo do titulo
        Version (string?)     - versao exibida ao lado do titulo (default: Black.Version)
        Size (UDim2?)         - tamanho inicial
        ToggleKeybind (Enum.KeyCode?) - tecla que abre/fecha (default RightControl)
]]
function Black:CreateWindow(opts)
    opts = opts or {}
    if opts.Version then
        self.Version = opts.Version
    end
    local window = Window.new(self, opts)
    table.insert(self.Windows, window)

    -- Botao flutuante mobile (nulo em PC)
    MobileToggle.Create(self, window)

    return window
end

-- Sistema de notificacao (Black:Notify(...)) e injetado por Notification.Init
Notification.Init(Black)

--[[
    Black:SetTheme(themeTable)
    Mescla themeTable sobre o tema atual e reaplica em todos os elementos
    ja criados (via Create.RefreshTheme).
]]
function Black:SetTheme(themeTable)
    for key, value in themeTable do
        CurrentTheme[key] = value
    end
    Create.RefreshTheme()
end

function Black:GetTheme()
    return CurrentTheme
end

--[[
    Black:Destroy()
    Remove toda a UI da tela. Chamar ao descarregar o script.
]]
function Black:Destroy()
    for _, window in self.Windows do
        window:Destroy()
    end
    self.Windows = {}
    if ScreenGui then
        ScreenGui:Destroy()
    end
end

return Black
