// wasirun.mjs -- run a WASI WebAssembly program under Node.js (2026).
//    node wasirun.mjs csub.wasm 100 2000 10
// Node's built-in node:wasi gives the module its command-line arguments;
// V8 compiles the WebAssembly to native code. Used for Keith's C kernel
// (cmain.cpp + csub.cpp) built for wasm32-wasi; compare wasmtime.
import { readFile } from 'node:fs/promises';
import { WASI } from 'node:wasi';
import { argv } from 'node:process';

const wasi = new WASI({ version: 'preview1', args: argv.slice(2), env: {} });
const module = await WebAssembly.compile(await readFile(argv[2]));
const instance = await WebAssembly.instantiate(module, wasi.getImportObject());
wasi.start(instance);
