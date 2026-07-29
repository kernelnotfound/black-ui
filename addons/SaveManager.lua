--[[
    Black UI Library — Addon: SaveManager
    (arquivo standalone, carregado separadamente do bundle principal,
    igual ao padrao Obsidian: loadstring(...HttpGet(".../addons/SaveManager.lua"))())

    Salva/carrega valores de Toggles, Sliders, Inputs, Dropdowns, etc.
    em arquivo JSON local (writefile/readfile), organizados por pasta e
    subpasta (ex: por jogo/servidor).
]]

local httpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.Library = nil
SaveManager.Folder = "BlackUI"
SaveManager.SubFolder = ""
SaveManager.Ignored = {}
SaveManager.Elements = {} -- [id] = { Type = "Toggle"|"Slider"|..., Instance = api }

function SaveManager:SetLibrary(library)
    self.Library = library
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
end

function SaveManager:SetSubFolder(subfolder)
    self.SubFolder = subfolder
end

function SaveManager:SetIgnoreIndexes(list)
    for _, id in list do
        self.Ignored[id] = true
    end
end

-- Registra um elemento com id unico para ser incluido no save.
-- element precisa expor .Value e :SetValue(value)
function SaveManager:Register(id, element)
    self.Elements[id] = element
end

function SaveManager:GetFolderPath()
    local base = self.Folder
    if self.SubFolder ~= "" then
        base = base .. "/" .. self.SubFolder
    end
    return base
end

local function ensureFolder(path)
    if not isfolder or not makefolder then
        return
    end
    local segments = path:split("/")
    local current = ""
    for _, seg in segments do
        current = current == "" and seg or (current .. "/" .. seg)
        if not isfolder(current) then
            makefolder(current)
        end
    end
end

function SaveManager:Save(name)
    if not writefile then
        warn("Black UI SaveManager: writefile indisponivel neste executor.")
        return false
    end

    local folder = self:GetFolderPath()
    ensureFolder(folder)

    local data = {}
    for id, element in self.Elements do
        if self.Ignored[id] then
            continue
        end
        local ok, value = pcall(function()
            return element.Value
        end)
        if ok then
            data[id] = value
        end
    end

    local ok, encoded = pcall(httpService.JSONEncode, httpService, data)
    if not ok then
        warn("Black UI SaveManager: falha ao encodar config:", encoded)
        return false
    end

    writefile(folder .. "/" .. name .. ".json", encoded)
    return true
end

function SaveManager:Load(name)
    if not readfile or not isfile then
        warn("Black UI SaveManager: readfile indisponivel neste executor.")
        return false
    end

    local folder = self:GetFolderPath()
    local filePath = folder .. "/" .. name .. ".json"

    if not isfile(filePath) then
        return false
    end

    local ok, content = pcall(readfile, filePath)
    if not ok then
        return false
    end

    local decodeOk, data = pcall(httpService.JSONDecode, httpService, content)
    if not decodeOk then
        warn("Black UI SaveManager: config corrompida:", name)
        return false
    end

    for id, value in data do
        local element = self.Elements[id]
        if element and element.SetValue then
            pcall(function()
                element:SetValue(value)
            end)
        end
    end

    return true
end

function SaveManager:ListConfigs()
    if not listfiles or not isfolder then
        return {}
    end
    local folder = self:GetFolderPath()
    if not isfolder(folder) then
        return {}
    end
    local configs = {}
    for _, file in listfiles(folder) do
        local name = file:match("([^/\\]+)%.json$")
        if name then
            table.insert(configs, name)
        end
    end
    return configs
end

function SaveManager:Delete(name)
    if not delfile or not isfile then
        return false
    end
    local filePath = self:GetFolderPath() .. "/" .. name .. ".json"
    if isfile(filePath) then
        delfile(filePath)
        return true
    end
    return false
end

-- Autoload: salva o nome do ultimo config carregado num arquivo separado
-- e recarrega automaticamente na proxima execucao.
function SaveManager:SetAutoloadConfig(name)
    if not writefile then
        return
    end
    local folder = self:GetFolderPath()
    ensureFolder(folder)
    writefile(folder .. "/autoload.txt", name)
end

function SaveManager:LoadAutoloadConfig()
    if not readfile or not isfile then
        return false
    end
    local filePath = self:GetFolderPath() .. "/autoload.txt"
    if not isfile(filePath) then
        return false
    end
    local ok, name = pcall(readfile, filePath)
    if not ok or name == "" then
        return false
    end
    return self:Load(name)
end

--[[
    SaveManager:BuildConfigSection(tab)
    Constroi uma UI padrao (dropdown de configs + input de nome + botoes
    de salvar/carregar/deletar/autoload) dentro da tab fornecida.
]]
function SaveManager:BuildConfigSection(tab)
    if not self.Library then
        error("Black UI SaveManager: SetLibrary deve ser chamado antes de BuildConfigSection.")
    end

    local section = tab:CreateSection("Configuracoes")
    local configs = self:ListConfigs()

    local nameInput = tab:CreateInput({
        Name = "Nome da config",
        Placeholder = "minha-config",
        Default = "",
    })

    local configDropdown = tab:CreateDropdown({
        Name = "Configs salvas",
        Options = configs,
        Placeholder = "Nenhuma config",
    })

    tab:CreateButton({
        Name = "Salvar",
        Description = "Salva o estado atual dos elementos com este nome",
        Callback = function()
            local name = nameInput.Value
            if not name or name == "" then
                self.Library:Notify({ Title = "Black UI", Description = "Digite um nome para salvar.", Type = "Warning" })
                return
            end
            local ok = self:Save(name)
            self.Library:Notify({
                Title = "Black UI",
                Description = ok and ("Config salva: " .. name) or "Falha ao salvar config.",
                Type = ok and "Success" or "Error",
            })
        end,
    })

    tab:CreateButton({
        Name = "Carregar",
        Description = "Carrega a config selecionada no dropdown",
        Callback = function()
            local name = configDropdown.GetValue and configDropdown.GetValue()
            if not name then
                return
            end
            local ok = self:Load(name)
            self.Library:Notify({
                Title = "Black UI",
                Description = ok and ("Config carregada: " .. name) or "Falha ao carregar config.",
                Type = ok and "Success" or "Error",
            })
        end,
    })

    tab:CreateButton({
        Name = "Autoload",
        Description = "Define a config selecionada para carregar automaticamente",
        Callback = function()
            local name = configDropdown.GetValue and configDropdown.GetValue()
            if not name then
                return
            end
            self:SetAutoloadConfig(name)
            self.Library:Notify({ Title = "Black UI", Description = "Autoload definido: " .. name, Type = "Success" })
        end,
    })

    return section
end

return SaveManager
