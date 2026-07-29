--[[
    Black UI Library — example.lua

    Script de demonstracao: carrega a build publicada e mostra todos os
    elementos disponiveis, organizados em tabs. Cole isso direto no seu
    executor pra visualizar a lib.
]]

local Black = loadstring(game:HttpGet("https://raw.githubusercontent.com/kernelnotfound/black-ui/main/dist/Black.lua"))()

-- Loading screen (opcional) ----------------------------------------------
-- Simula um carregamento de recursos com progresso determinado.
local Loading = Black:CreateLoadingScreen({
    Title = "Black UI",
    Subtitle = "Carregando exemplo...",
    -- Fullscreen = true, -- descomente para cobrir a tela inteira
})

task.spawn(function()
    for i = 1, 10 do
        task.wait(0.08)
        Loading:SetProgress(i / 10)
        Loading:SetStatus(("Carregando... %d%%"):format(i * 10))
    end
    Loading:Finish()
end)

-- Janela principal -----------------------------------------------------
local Window = Black:CreateWindow({
    Name = "Black UI",
    SubTitle = "example.lua",
    -- Version = "1.0.0",         -- descomente pra ver o sufixo "v1.0.0" no titulo
    -- Icon = "rbxassetid://0",   -- descomente e troque pelo seu asset id (whitelabel)
    ToggleKeybind = Enum.KeyCode.RightControl,
})

----------------------------------------------------------------------
-- Tab: Main
----------------------------------------------------------------------
local MainTab = Window:CreateTab({ Name = "Main" })

MainTab:CreateProfileCard({
    ShowCredit = true, -- exemplo: credito e opt-in, aqui ligamos de proposito
})

MainTab:CreateSection("Acoes")

MainTab:CreateButton({
    Name = "Notificar",
    Description = "Dispara uma notificacao de exemplo",
    Help = "Isso e um botao com descricao e ajuda.",
    Callback = function()
        Black:Notify({
            Title = "Black UI",
            Description = "Este e um exemplo de notificacao.",
            Type = "Success",
            Duration = 3,
        })
    end,
})

MainTab:CreateButton({
    Name = "Botao simples",
    Callback = function()
        print("Botao simples clicado")
    end,
})

MainTab:CreateDivider()

MainTab:CreateTitledDivider("Controles")

local ExampleToggle = MainTab:CreateToggle({
    Name = "Ativar recurso",
    Default = false,
    Help = "Alterna um estado booleano qualquer.",
    Callback = function(value)
        print("Toggle:", value)
    end,
})

local ExampleSlider = MainTab:CreateSlider({
    Name = "Velocidade",
    Min = 0,
    Max = 100,
    Default = 16,
    Suffix = "%",
    Help = "Arraste ou clique no valor pra digitar.",
    Callback = function(value)
        print("Slider:", value)
    end,
})

MainTab:CreateParagraph({
    Title = "Sobre",
    Text = "Este e um paragrafo de exemplo, util para instrucoes maiores ou avisos.",
})

----------------------------------------------------------------------
-- Tab: Inputs
----------------------------------------------------------------------
local InputsTab = Window:CreateTab({ Name = "Inputs" })

InputsTab:CreateInput({
    Name = "Nome",
    Placeholder = "Digite seu nome...",
    Default = "",
    Help = "Campo de texto livre.",
    Callback = function(text)
        print("Input texto:", text)
    end,
})

InputsTab:CreateInput({
    Name = "Numero (Min/Max)",
    Placeholder = "0 a 10",
    Default = "5",
    Numeric = true,
    Min = 0,
    Max = 10,
    Help = "Aceita apenas numeros, com clamp entre 0 e 10.",
    Callback = function(text)
        print("Input numerico:", text)
    end,
})

InputsTab:CreateDropdown({
    Name = "Modo",
    Options = { "Facil", "Normal", "Dificil" },
    Default = "Normal",
    Help = "Selecao unica.",
    Callback = function(value)
        print("Dropdown:", value)
    end,
})

InputsTab:CreateDropdown({
    Name = "Tags (multi)",
    Options = { "A", "B", "C", "D" },
    Multi = true,
    Help = "Selecao multipla.",
    Callback = function(value)
        print("Dropdown multi:", value)
    end,
})

InputsTab:CreateKeyBind({
    Name = "Atalho",
    Default = "None",
    Help = "Clique e pressione uma tecla ou botao do mouse.",
    Callback = function(key)
        print("KeyBind:", key)
    end,
})

InputsTab:CreateColorPicker({
    Name = "Cor de destaque",
    Default = Color3.fromRGB(255, 255, 255),
    Help = "Escolha uma cor.",
    Callback = function(color)
        print("Cor escolhida:", color)
    end,
})

----------------------------------------------------------------------
-- Tab: Settings (tema + configs, via addons)
----------------------------------------------------------------------
local SettingsTab = Window:CreateTab({ Name = "Settings" })

local ok1, ThemeManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/kernelnotfound/black-ui/main/addons/ThemeManager.lua"))()
end)
if ok1 and ThemeManager then
    ThemeManager:SetLibrary(Black)
    ThemeManager:ApplyToTab(SettingsTab)
end

SettingsTab:CreateDivider()

local ok2, SaveManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/kernelnotfound/black-ui/main/addons/SaveManager.lua"))()
end)
if ok2 and SaveManager then
    SaveManager:SetLibrary(Black)
    SaveManager:SetFolder("BlackUI-Example")
    SaveManager:Register("example_toggle", ExampleToggle)
    SaveManager:Register("example_slider", ExampleSlider)
    SaveManager:BuildConfigSection(SettingsTab)
end

SettingsTab:CreateCredit()

Black:Notify({
    Title = "Black UI",
    Description = "example.lua carregado com sucesso.",
    Type = "Info",
    Duration = 4,
})
