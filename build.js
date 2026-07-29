/*
    Black UI Library — Build Script

    Concatena todos os modulos em src/ para um unico arquivo Lua
    (dist/Black.lua), distribuivel via loadstring(game:HttpGet(url))().

    Estrategia: cada arquivo .lua em src/ se torna uma entrada num bundle
    table { [path] = function(require) ... return Module end }.
    Um runtime "require" minimo resolve dependencias por path relativo,
    simulando o comportamento de `require(script.Parent.X)` do Roblox
    dentro de um unico arquivo (sem precisar de ModuleScripts reais).

    Uso: node build.js
*/

const fs = require("fs");
const path = require("path");

const SRC_DIR = path.join(__dirname, "src");
const OUT_DIR = path.join(__dirname, "dist");
const OUT_FILE = path.join(OUT_DIR, "Black.lua");

// Ordem não importa para a resolução (é feita via grafo de require),
// mas mantemos uma ordem legível para debug do bundle gerado.
function walk(dir, base = "") {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    let files = [];
    for (const entry of entries) {
        const full = path.join(dir, entry.name);
        const rel = base ? `${base}/${entry.name}` : entry.name;
        if (entry.isDirectory()) {
            files = files.concat(walk(full, rel));
        } else if (entry.name.endsWith(".lua")) {
            files.push({ full, rel: rel.replace(/\.lua$/, "") });
        }
    }
    return files;
}

function toModuleKey(relPath) {
    // "Elements/Button" -> "Elements/Button"
    // "init" -> "init"
    return relPath.replace(/\\/g, "/");
}

function rewriteRequires(source, currentKey) {
    // Reescreve `require(script.X.Y)` e `require(script.Parent.X.Y)` para
    // `require("<modulekey>")` resolvendo o caminho relativo ao modulo atual.
    const currentDir = currentKey.includes("/") ? currentKey.split("/").slice(0, -1) : [];

    return source.replace(/require\(\s*(script(?:\.Parent|\.[A-Za-z_][A-Za-z0-9_]*)*)\s*\)/g, (match, expr) => {
        const parts = expr.split(".").slice(1); // remove "script"
        let dir = currentDir.slice();
        const segs = [];

        for (const part of parts) {
            if (part === "Parent") {
                dir.pop();
            } else {
                segs.push(part);
            }
        }

        const resolvedParts = dir.concat(segs);
        let resolved = resolvedParts.join("/");

        // Se resolveu para um diretorio (modulo tipo pasta), tenta "/init"
        if (!MODULE_KEYS.has(resolved) && MODULE_KEYS.has(resolved + "/init")) {
            resolved = resolved + "/init";
        }

        return `__require("${resolved}")`;
    });
}

let MODULE_KEYS = new Set();

function build() {
    const files = walk(SRC_DIR);
    const modules = [];

    for (const file of files) {
        const key = toModuleKey(file.rel);
        MODULE_KEYS.add(key);
        modules.push({ key, full: file.full });
    }

    const entries = [];
    for (const mod of modules) {
        let source = fs.readFileSync(mod.full, "utf8");
        source = rewriteRequires(source, mod.key);
        entries.push(`["${mod.key}"] = function()\n${source}\nend,`);
    }

    const runtime = `--[[
    BLACK UI LIBRARY
    Bundled build — gerado automaticamente por build.js. NAO EDITE A MAO.
    Fonte: src/*.lua
]]

local __cache = {}
local __modules
local __require

local function __require_impl(path)
    if __cache[path] ~= nil then
        return __cache[path]
    end
    local loader = __modules[path]
    if not loader then
        error("Black UI: modulo nao encontrado: " .. tostring(path), 2)
    end
    local result = loader()
    __cache[path] = result
    return result
end
__require = __require_impl

__modules = {
${entries.map((e) => "    " + e.replace(/\n/g, "\n    ")).join("\n")}
}

return __require("init")
`;

    fs.mkdirSync(OUT_DIR, { recursive: true });
    fs.writeFileSync(OUT_FILE, runtime, "utf8");
    console.log(`Build ok -> ${OUT_FILE} (${modules.length} modulos)`);
}

build();
