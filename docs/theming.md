# Tema

A paleta padrão é preta, com o contraste branco como destaque (`Accent`).

## Trocar cores em runtime

```lua
Black:SetTheme({
    Accent = Color3.fromRGB(90, 170, 255),
})
```

`SetTheme` faz um merge sobre o tema atual e reaplica automaticamente em todos os elementos já criados.

## Ler o tema atual

```lua
local theme = Black:GetTheme()
print(theme.Accent)
```

## Chaves disponíveis

| Chave | Uso |
|---|---|
| `Background` | Fundo da janela |
| `Surface` / `SurfaceElevated` / `SurfaceHover` | Cards, elementos, estados de hover |
| `Border` / `BorderStrong` | Bordas e divisórias |
| `Text` / `TextSecondary` / `TextDisabled` | Cores de texto |
| `Accent` / `AccentText` | Cor de destaque e texto sobre o destaque |
| `Success` / `Warning` / `Error` | Cores de estado (usadas em notificações) |
| `Font` / `FontBold` / `FontSemibold` | Fontes |
| `CornerRadius` / `CornerRadiusSmall` / `CornerRadiusPill` | Raios de borda |
| `PatternImage` / `PatternTransparency` | Textura de fundo sutil da janela |
| `ShadowImage` | Sombra externa da janela |
| `TweenFast` / `TweenNormal` / `TweenSlow` / `TweenSpring` | `TweenInfo` usados nas animações |

## Notificações

```lua
Black:Notify({
    Title = "Título",
    Description = "Descrição opcional",
    Type = "Info", -- Info | Success | Warning | Error
    Duration = 3,
})
```
