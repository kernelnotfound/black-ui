--[[
    Black UI Library — Addon: ThemeManager
    (arquivo standalone, igual ao SaveManager)

    Permite trocar entre temas pre-definidos e customizar cores
    individualmente, com uma UI pronta pra encaixar em uma tab.
]]

local ThemeManager = {}
ThemeManager.Library = nil

-- Temas pre-definidos (todos derivados da paleta preto/branco da Black,
-- trocando apenas o Accent para variar a "personalidade" sem perder a
-- identidade minimalista).
ThemeManager.BuiltInThemes = {
    ["Black (default)"] = { Accent = Color3.fromRGB(255, 255, 255) },
    ["Ocean"] = { Accent = Color3.fromRGB(90, 170, 255) },
    ["Mint"] = { Accent = Color3.fromRGB(80, 220, 160) },
    ["Sunset"] = { Accent = Color3.fromRGB(255, 140, 90) },
    ["Violet"] = { Accent = Color3.fromRGB(170, 120, 255) },
    ["Crimson"] = { Accent = Color3.fromRGB(230, 90, 110) },
}

function ThemeManager:SetLibrary(library)
    self.Library = library
end

function ThemeManager:ApplyTheme(themeName)
    local theme = self.BuiltInThemes[themeName]
    if not theme then
        return false
    end
    self.Library:SetTheme(theme)
    return true
end

--[[
    ThemeManager:ApplyToTab(tab)
    Constroi um dropdown de selecao de tema + color picker de accent
    customizado dentro da tab fornecida.
]]
function ThemeManager:ApplyToTab(tab)
    if not self.Library then
        error("Black UI ThemeManager: SetLibrary deve ser chamado antes de ApplyToTab.")
    end

    local names = {}
    for name in self.BuiltInThemes do
        table.insert(names, name)
    end
    table.sort(names)

    tab:CreateSection("Tema")

    tab:CreateDropdown({
        Name = "Tema predefinido",
        Options = names,
        Default = names[1],
        Callback = function(value)
            self:ApplyTheme(value)
        end,
    })

    tab:CreateColorPicker({
        Name = "Cor de destaque (accent)",
        Default = self.Library:GetTheme().Accent,
        Callback = function(color)
            self.Library:SetTheme({ Accent = color })
        end,
    })
end

return ThemeManager
