# Referência de elementos

Todos os elementos são criados a partir de uma tab: `Tab:CreateX({ ... })`.
Elementos que expõem estado retornam uma tabela com `.Value`, `:SetValue(v)` e, quando aplicável, `:OnChanged(fn)`.

Em quase todos os elementos, o campo opcional `Help` (string) adiciona um botão "?" que mostra um tooltip com o texto informado.

## CreateButton

```lua
Tab:CreateButton({
    Name = "Executar",
    Description = "Descrição opcional, deixa o botão mais alto",
    Help = "Texto de ajuda opcional",
    Callback = function() end,
})
```

## CreateToggle

```lua
local MyToggle = Tab:CreateToggle({
    Name = "Ativar recurso",
    Default = false,
    Help = "Texto de ajuda opcional",
    Callback = function(value) end,
})

MyToggle:OnChanged(function(value) end)
MyToggle:SetValue(true)
```

Visual: anel externo + ponto interno que aparece/desaparece (estilo IceHub), não é um switch deslizante.

## CreateSlider

```lua
local MySlider = Tab:CreateSlider({
    Name = "Velocidade",
    Min = 0,
    Max = 100,
    Default = 16,
    Rounding = 0, -- casas decimais
    Suffix = "%",
    Help = "Texto de ajuda opcional",
    Callback = function(value) end,
})
```

## CreateInput

```lua
Tab:CreateInput({
    Name = "Nome",
    Placeholder = "Digite aqui...",
    Default = "",
    Numeric = false, -- filtra apenas dígitos quando true
    ClearTextOnFocus = false,
    Help = "Texto de ajuda opcional",
    Callback = function(text) end,
})
```

## CreateDropdown

```lua
local MyDropdown = Tab:CreateDropdown({
    Name = "Modo",
    Options = { "A", "B", "C" },
    Default = "A",
    Multi = false, -- seleção múltipla
    MaxVisibleItems = 6,
    Help = "Texto de ajuda opcional",
    Callback = function(value) end,
})

MyDropdown:SetValue("B")
MyDropdown.GetValue()
```

## CreateKeyBind

```lua
Tab:CreateKeyBind({
    Name = "Atalho",
    Default = "None",
    Help = "Texto de ajuda opcional",
    Callback = function(key) end,
})
```

Clique no campo e pressione a tecla/botão do mouse desejado para capturar.

## CreateColorPicker

```lua
Tab:CreateColorPicker({
    Name = "Cor",
    Default = Color3.new(1, 1, 1),
    Help = "Texto de ajuda opcional",
    Callback = function(color) end,
})
```

Não depende de nenhuma imagem externa — desenhado com `UIGradient`.

## CreateLabel / CreateParagraph / CreateDivider / CreateTitledDivider / CreateSection

```lua
Tab:CreateLabel("Texto simples")
Tab:CreateParagraph({ Title = "Título", Text = "Corpo do texto." })
Tab:CreateDivider()
Tab:CreateTitledDivider("Categoria") -- linha divisória com texto centralizado
Tab:CreateSection("Nome da seção")
```

## CreateProfileCard / CreateCredit

```lua
Tab:CreateProfileCard({
    HideAvatar = false,
    HideUsername = false,
    ShowCredit = false, -- opcional; por padrão nenhum crédito é exibido
    Credit = "Discord: @seu_usuario", -- opcional; se definido, ShowCredit é implícito
})

Tab:CreateCredit({ Text = "Discord: @seu_usuario" }) -- elemento isolado, totalmente opcional
```

`CreateProfileCard` mostra o avatar do jogador local e uma saudação. O crédito do desenvolvedor é opt-in — não aparece a menos que `ShowCredit = true` ou `Credit` seja definido explicitamente.
