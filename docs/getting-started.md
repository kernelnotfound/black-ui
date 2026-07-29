# Instalação e uso básico

Carregue a build via `loadstring`, apontando para o arquivo `dist/Black.lua` no branch principal:

```lua
local Black = loadstring(game:HttpGet("https://raw.githubusercontent.com/kernelnotfound/black-ui/main/dist/Black.lua"))()
```

## Criando a janela principal

```lua
local Window = Black:CreateWindow({
    Name = "Minha Hub",
    SubTitle = "build privada",
    Version = "1.0.0", -- opcional, aparece como "Minha Hub v1.0.0" no título
    ToggleKeybind = Enum.KeyCode.RightControl, -- default
})
```

Opções de `CreateWindow`:

| Campo | Tipo | Descrição |
|---|---|---|
| `Name` | `string` | Título exibido na topbar |
| `SubTitle` | `string?` | Subtítulo pequeno abaixo do título |
| `Version` | `string?` | Versão exibida ao lado do título. Se não for definida, o campo fica vazio (nenhum sufixo é exibido) |
| `Icon` | `string?` | Asset id (`rbxassetid://...`) exibido como ícone/logo na topbar, para branding whitelabel |
| `IconColor` | `Color3?` | Cor aplicada ao ícone (default: branco) |
| `Size` | `UDim2?` | Tamanho inicial da janela |
| `ToggleKeybind` | `Enum.KeyCode?` | Tecla que minimiza/restaura a janela |
| `MinimizeStyle` | `"Compact"` \| `"TopbarIcon"` \| `"Bubble"` | Comportamento ao clicar em minimizar. `"Compact"` (default) colapsa a janela numa barra pequena. `"TopbarIcon"` esconde a janela inteira e mostra um ícone fixo ao lado da barra nativa de ícones do Roblox (menu/chat/voz), que restaura a janela ao ser clicado. `"Bubble"` esconde a janela inteira e mostra uma bolha flutuante e arrastável livremente pela tela, que restaura a janela ao ser clicada (não arrastada) |
| `TopbarIconPosition` | `UDim2?` | Só usado com `MinimizeStyle = "TopbarIcon"`. Sobrescreve a posição do ícone fixo, caso o valor default fique sobreposto aos ícones nativos em algum jogo específico (o número de ícones nativos varia por jogo/plataforma) |
| `BubblePosition` | `UDim2?` | Só usado com `MinimizeStyle = "Bubble"`. Posição inicial da bolha (default: canto superior esquerdo) |

## Criando tabs

```lua
local MainTab = Window:CreateTab({ Name = "Main" })
local SettingsTab = Window:CreateTab({ Name = "Settings" })
```

A primeira tab criada é selecionada automaticamente.

## Fechando / destruindo

- Botão "×" na topbar esconde a janela (`SetVisible(false)`), sem destruir nada.
- Para remover a UI por completo (ex: ao descarregar o script): `Black:Destroy()`.

## Execução repetida (singleton)

Se o script for executado mais de uma vez (ex: colar o `loadstring` novamente no executor), a instância anterior da Black UI é destruída automaticamente antes de criar a nova — não há acúmulo de janelas duplicadas nem handlers de teclado duplicados.

Veja os demais arquivos em `docs/` para a referência de cada elemento, tema e os addons opcionais (SaveManager / ThemeManager).
