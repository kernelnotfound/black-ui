# Tela de carregamento

Opcional, controlada inteiramente por quem usa a lib. Não é criada automaticamente — só existe se você chamar `Black:CreateLoadingScreen(...)`.

```lua
local Loading = Black:CreateLoadingScreen({
    Title = "Carregando",
    Subtitle = "Preparando recursos...",
    Image = "rbxassetid://0", -- opcional, logo/imagem central (whitelabel)
    Size = UDim2.fromOffset(280, 280), -- ignorado se Fullscreen = true
    Fullscreen = false, -- true para cobrir a tela inteira
})
```

Por padrão é um card compacto (quadrado, com sombra e cantos arredondados, no mesmo estilo visual da janela principal). Passe `Fullscreen = true` para cobrir a tela inteira em vez disso — a escolha é sua.

A barra de progresso é branca com um efeito de brilho ("neon"), na parte inferior do card.

## Modo indeterminado (padrão)

Sem chamar `:SetProgress`, a barra fica em loop indefinidamente — útil para uma espera temporária sem etapas conhecidas.

## Modo determinado

Chame `:SetProgress(alpha)` (0 a 1) para controlar a barra manualmente — por exemplo, ao carregar N de M recursos:

```lua
for i, assetId in ipairs(assetsToPreload) do
    -- ... carregar asset ...
    Loading:SetProgress(i / #assetsToPreload)
    Loading:SetStatus(("Carregando %d/%d"):format(i, #assetsToPreload))
end

Loading:Finish()
```

A primeira chamada a `:SetProgress` desliga automaticamente o modo indeterminado.

## API

| Método | Descrição |
|---|---|
| `:SetProgress(alpha)` | `alpha` entre 0 e 1. Desliga o loop indeterminado na primeira chamada |
| `:SetStatus(text)` | Atualiza o texto de status abaixo do título |
| `:SetTitle(text)` | Atualiza o título |
| `:Finish(onComplete?)` | Faz fade-out e remove a tela. `onComplete` (opcional) é chamado quando o fade termina |
