--[[
    Black UI Library
    Utilities/Create.lua

    Wrapper para Instance.new que:
    - Aplica propriedades de uma tabela
    - Registra propriedades ligadas ao tema (para retema em runtime)
    - Suporta filhos aninhados via campo `Children`

    Inspirado no padrao "New()" do Obsidian, porem mais leve: em vez de
    reescrever TODAS as instancias sempre que o tema muda, guardamos uma
    lista de (instance, property, themeKey) e so atualizamos essas.
]]

local Create = {}

-- Registry global: { [Instance] = { [Property] = ThemeKey } }
Create.Registry = {}

local ThemeRef = nil -- setado por init.lua via Create.SetTheme

function Create.SetThemeTable(themeTable)
    ThemeRef = themeTable
end

function Create.GetTheme()
    return ThemeRef
end

-- Marca ums prop como "ligada ao tema": ThemeKey deve ser uma string chave
-- existente na tabela de tema (ex: "Background", "Text", ...)
local ThemeKeyMarker = {}
function Create.Theme(themeKey)
    return setmetatable({ key = themeKey }, ThemeKeyMarker)
end

local function isThemeMarker(v)
    return typeof(v) == "table" and getmetatable(v) == ThemeKeyMarker
end

-- A propriedade legada "Font" (Enum.Font) nao aceita objetos Font.new(...);
-- esses devem ser atribuidos via "FontFace". Para permitir usar `Font = ...`
-- na tabela de props (mais natural) com valores de qualquer um dos dois
-- tipos, detectamos e redirecionamos automaticamente.
local function setFontProperty(inst, value)
    if typeof(value) == "Font" then
        inst.FontFace = value
    else
        inst.Font = value
    end
end

function Create.New(className, props)
    local inst = Instance.new(className)
    local themeProps = nil

    if props then
        for key, value in props do
            if key == "Children" then
                continue
            elseif key == "Parent" then
                continue -- setado por ultimo
            elseif isThemeMarker(value) then
                themeProps = themeProps or {}
                themeProps[key] = value.key
                local resolved = ThemeRef and ThemeRef[value.key] or value.key
                if key == "Font" then
                    setFontProperty(inst, resolved)
                else
                    inst[key] = resolved
                end
            elseif key == "Font" then
                setFontProperty(inst, value)
            else
                inst[key] = value
            end
        end

        if props.Children then
            for _, child in props.Children do
                child.Parent = inst
            end
        end

        if props.Parent then
            inst.Parent = props.Parent
        end
    end

    if themeProps then
        Create.Registry[inst] = themeProps
    end

    return inst
end

-- Reaplica todas as props ligadas ao tema atual (chamar quando o tema mudar)
function Create.RefreshTheme()
    if not ThemeRef then
        return
    end
    for inst, themeProps in Create.Registry do
        if not inst.Parent and inst.Parent ~= game then
            -- ainda pode ser valido (root), nao remover por seguranca aqui
        end
        for prop, key in themeProps do
            local ok = pcall(function()
                if prop == "Font" then
                    setFontProperty(inst, ThemeRef[key])
                else
                    inst[prop] = ThemeRef[key]
                end
            end)
            if not ok then
                Create.Registry[inst] = nil
                break
            end
        end
    end
end

function Create.Untrack(inst)
    Create.Registry[inst] = nil
end

return Create
