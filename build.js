/*
    Black UI Library — Build Script

    Concatena todos os modulos em src/ para um unico arquivo Lua
    (dist/Black.lua), distribuivel via loadstring(game:HttpGet(url))().

    Estrategia (v2 — sem "require" reimplementado):
    Bibliotecas de UI Roblox consolidadas (Rayfield, Obsidian, Fluent, ...)
    publicam como um UNICO arquivo monolitico, sem sistema de modulos
    proprio. Isso evita duas classes de bug reais que a v1 deste build
    tinha:
      1. `require` e tratado de forma especial pelo compilador Luau
         moderno quando chamado com um literal de string — nao pode
         ser "shadowed" por uma local com o mesmo nome.
      2. Resolucao de path relativo (`script.Parent...`) via string e
         fragil (upvalue scoping, caso especial de `init.lua`, etc).

    Por isso, cada modulo .lua em src/ e transformado numa variavel
    Lua local unica (baseada no path do arquivo), atribuida a partir de
    uma IIFE `(function() ... end)()`. Os modulos sao emitidos em ordem
    topologica (dependencias antes de quem depende delas), calculada a
    partir do grafo de `require(script...)` de cada arquivo. Toda
    ocorrencia de `require(script...)` no codigo-fonte e substituida
    pelo nome da variavel local do modulo referenciado — nao ha nenhuma
    tabela de modulos nem funcao "require" em tempo de execucao no
    arquivo final.

    Uso: node build.js
*/

const fs = require("fs");
const path = require("path");

const SRC_DIR = path.join(__dirname, "src");
const OUT_DIR = path.join(__dirname, "dist");
const OUT_FILE = path.join(OUT_DIR, "Black.lua");

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
    return relPath.replace(/\\/g, "/");
}

// Nome de variavel Lua valido e unico por modulo, ex: "Utilities/Create" -> "__mod_Utilities_Create"
function toVarName(moduleKey) {
    return "__mod_" + moduleKey.replace(/[\\/]/g, "_");
}

// Resolve o path de modulo referenciado por uma expressao `script...`
// (ja sem o prefixo "script"), relativo ao modulo `currentKey`.
function resolveRequirePath(expr, currentKey, moduleKeys) {
    const segments = currentKey.split("/");
    const isInit = segments[segments.length - 1] === "init";
    const currentPath = isInit ? segments.slice(0, -1) : segments;

    const parts = expr.split(".").slice(1); // remove "script"
    let dir = currentPath.slice();
    const segs = [];

    for (const part of parts) {
        if (part === "Parent") {
            dir.pop();
        } else {
            segs.push(part);
        }
    }

    let resolved = dir.concat(segs).join("/");
    if (!moduleKeys.has(resolved) && moduleKeys.has(resolved + "/init")) {
        resolved = resolved + "/init";
    }
    return resolved;
}

// Extrai as chaves de modulo que `source` (do modulo `currentKey`) requer,
// para montarmos o grafo de dependencias.
function extractDependencies(source, currentKey, moduleKeys) {
    const deps = new Set();
    const pattern = /require\(\s*(script(?:\.Parent|\.[A-Za-z_][A-Za-z0-9_]*)*)\s*\)/g;
    let match;
    while ((match = pattern.exec(source))) {
        const resolved = resolveRequirePath(match[1], currentKey, moduleKeys);
        deps.add(resolved);
    }
    return deps;
}

function rewriteRequires(source, currentKey, moduleKeys) {
    return source.replace(/require\(\s*(script(?:\.Parent|\.[A-Za-z_][A-Za-z0-9_]*)*)\s*\)/g, (match, expr) => {
        const resolved = resolveRequirePath(expr, currentKey, moduleKeys);
        if (!moduleKeys.has(resolved)) {
            throw new Error(`Modulo referenciado nao encontrado: "${resolved}" (a partir de "${currentKey}", expressao "${match}")`);
        }
        return toVarName(resolved);
    });
}

function topoSort(moduleKeys, depsByKey) {
    const visited = new Set();
    const visiting = new Set();
    const order = [];

    function visit(key) {
        if (visited.has(key)) return;
        if (visiting.has(key)) {
            throw new Error(`Dependencia circular detectada envolvendo "${key}"`);
        }
        visiting.add(key);
        for (const dep of depsByKey.get(key) || []) {
            visit(dep);
        }
        visiting.delete(key);
        visited.add(key);
        order.push(key);
    }

    for (const key of moduleKeys) {
        visit(key);
    }
    return order;
}

function build() {
    const files = walk(SRC_DIR);
    const moduleKeys = new Set(files.map((f) => toModuleKey(f.rel)));

    const sourceByKey = new Map();
    for (const file of files) {
        const key = toModuleKey(file.rel);
        sourceByKey.set(key, fs.readFileSync(file.full, "utf8"));
    }

    const depsByKey = new Map();
    for (const key of moduleKeys) {
        depsByKey.set(key, extractDependencies(sourceByKey.get(key), key, moduleKeys));
    }

    const order = topoSort(moduleKeys, depsByKey);

    // "init" precisa ser o ultimo (e o entry point / valor de retorno do bundle).
    const initIndex = order.indexOf("init");
    if (initIndex === -1) {
        throw new Error('Modulo "init" nao encontrado em src/init.lua');
    }
    order.splice(initIndex, 1);
    order.push("init");

    const blocks = [];
    for (const key of order) {
        const rewritten = rewriteRequires(sourceByKey.get(key), key, moduleKeys);
        const varName = toVarName(key);
        const indented = rewritten
            .split("\n")
            .map((line) => "    " + line)
            .join("\n");
        blocks.push(`-- module: ${key}\nlocal ${varName} = (function()\n${indented}\nend)()`);
    }

    const runtime = `--[[
    BLACK UI LIBRARY
    Bundled build — gerado automaticamente por build.js. NAO EDITE A MAO.
    Fonte: src/*.lua

    Arquivo unico monolitico (sem sistema de "require" em tempo de
    execucao), no mesmo padrao usado por libs de UI Roblox consolidadas.
]]

${blocks.join("\n\n")}

return ${toVarName("init")}
`;

    fs.mkdirSync(OUT_DIR, { recursive: true });
    fs.writeFileSync(OUT_FILE, runtime, "utf8");
    console.log(`Build ok -> ${OUT_FILE} (${order.length} modulos, ordem: ${order.join(", ")})`);
}

build();
