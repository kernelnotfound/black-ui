# Addons

Addons são arquivos standalone, carregados separadamente do bundle principal.

## SaveManager

```lua
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/kernelnotfound/black-ui/main/addons/SaveManager.lua"))()

SaveManager:SetLibrary(Black)
SaveManager:SetFolder("MinhaHub")
SaveManager:SetSubFolder("") -- opcional, subpasta (ex: por jogo)

-- Registrar elementos manualmente:
SaveManager:Register("meu_toggle", MyToggle)

-- Ou construir a UI padrão de configs (salvar/carregar/autoload) numa tab:
SaveManager:BuildConfigSection(SettingsTab)
```

Requer `writefile`/`readfile`/`listfiles`/`isfile`/`isfolder`/`makefolder`/`delfile` do executor.

## ThemeManager

```lua
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/kernelnotfound/black-ui/main/addons/ThemeManager.lua"))()

ThemeManager:SetLibrary(Black)
ThemeManager:ApplyToTab(SettingsTab)
```

Constrói um dropdown de temas predefinidos + color picker de accent customizado dentro da tab fornecida.

Temas predefinidos: `Black (default)`, `Ocean`, `Mint`, `Sunset`, `Violet`, `Crimson` — todos variam apenas a cor de destaque (`Accent`), mantendo a base preta.
