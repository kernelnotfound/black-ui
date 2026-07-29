const fs = require("fs");
const luaparse = require("luaparse");

const files = process.argv.slice(2);

let hasError = false;

for (const file of files) {
    const source = fs.readFileSync(file, "utf8");
    try {
        luaparse.parse(source, { luaVersion: "5.3" });
        console.log(`OK: ${file}`);
    } catch (err) {
        hasError = true;
        console.log(`FAIL: ${file}`);
        console.log(`  ${err.message} (line ${err.line}, col ${err.column})`);
    }
}

process.exit(hasError ? 1 : 0);
