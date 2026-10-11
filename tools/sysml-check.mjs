#!/usr/bin/env node
// Headless SysML v2 checker. Drives the language server of the SysML v2 VS Code extension
// (https://github.com/xgonzox729/sysmlextension) over stdio and prints its diagnostics:
// syntax errors, unresolved names and the Wiring library's electrical checks.
// Zero dependencies; Node 18+.
//
//   node tools/sysml-check.mjs <file-or-dir>... [--server <main.cjs>] [--root <dir>] [--errors-only] [--timeout <s>]
//   node tools/sysml-check.mjs --probe
//
// Exit codes: 0 no errors, 1 errors found, 2 usage, 3 extension server not found, 4 timeout.
import { spawn } from 'node:child_process';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const EXTENSION_ID = 'xgonzox729.sysml-vscode';
const SERVER_REL = path.join('out', 'language', 'main.cjs');
const EDITOR_DIRS = ['.vscode', '.vscode-insiders', '.vscode-oss', '.cursor', '.windsurf', '.vscode-server'];
const KIT_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const USAGE = `usage: node tools/sysml-check.mjs <file-or-dir>... [options]
       node tools/sysml-check.mjs --probe

Checks .sysml/.kerml files with the SysML v2 VS Code extension's language server.

options:
  --server <path>   the extension's out/language/main.cjs (or set SYSML_LSP_SERVER)
  --root <dir>      workspace folder used to resolve cross-file references
                    (default: the common directory of the targets)
  --errors-only     print errors only, not warnings
  --timeout <s>     give up after this many seconds (default 120)
  --probe           only print where the extension server was found`;

function fail(code, message) {
    console.error(message);
    process.exit(code);
}

// ---------- arguments ----------
const opts = { targets: [], server: undefined, root: undefined, errorsOnly: false, probe: false, timeout: 120 };
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const value = () => argv[++i] ?? fail(2, `${a} needs a value\n\n${USAGE}`);
    if (a === '--server') opts.server = value();
    else if (a === '--root') opts.root = value();
    else if (a === '--timeout') opts.timeout = Number(value());
    else if (a === '--errors-only') opts.errorsOnly = true;
    else if (a === '--probe') opts.probe = true;
    else if (a === '-h' || a === '--help') { console.log(USAGE); process.exit(0); }
    else if (a.startsWith('--')) fail(2, `unknown option ${a}\n\n${USAGE}`);
    else opts.targets.push(a);
}
if (!opts.probe && opts.targets.length === 0) fail(2, USAGE);
if (!(opts.timeout > 0)) fail(2, '--timeout must be a positive number of seconds');

// ---------- locating the server ----------
function compareVersions(a, b) {
    const pa = a.split(/[.-]/).map(Number), pb = b.split(/[.-]/).map(Number);
    for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
        const d = (pa[i] || 0) - (pb[i] || 0);
        if (d) return d;
    }
    return 0;
}

function findServer() {
    const looked = [];
    const check = p => { looked.push(p); return existsSync(p) ? p : undefined; };
    if (opts.server) return { server: check(path.resolve(opts.server)), looked };
    if (process.env.SYSML_LSP_SERVER) return { server: check(path.resolve(process.env.SYSML_LSP_SERVER)), looked };
    const installed = [];
    for (const editor of EDITOR_DIRS) {
        const dir = path.join(homedir(), editor, 'extensions');
        looked.push(path.join(dir, `${EXTENSION_ID}-*`, SERVER_REL));
        let entries = [];
        try { entries = readdirSync(dir); } catch { continue; }
        for (const e of entries) {
            if (!e.toLowerCase().startsWith(EXTENSION_ID + '-')) continue;
            const p = path.join(dir, e, SERVER_REL);
            if (existsSync(p)) installed.push({ p, version: e.slice(EXTENSION_ID.length + 1) });
        }
    }
    if (installed.length) {
        installed.sort((x, y) => compareVersions(y.version, x.version));
        return { server: installed[0].p, looked };
    }
    // A source checkout next to the kit, after `npm run build`.
    for (const name of ['sysmlextension', 'sysMLextension', 'SysMLExtension']) {
        const s = check(path.join(KIT_ROOT, '..', name, SERVER_REL));
        if (s) return { server: s, looked };
    }
    return { server: undefined, looked };
}

const { server, looked } = findServer();
if (!server) {
    fail(3, `SysML v2 extension server not found. Looked in:\n${looked.map(l => '  ' + l).join('\n')}\n` +
        `Install the extension (VS Code: Extensions: Install from VSIX...), or build a clone of\n` +
        `https://github.com/xgonzox729/sysmlextension next to this kit (npm ci && npm run build),\n` +
        `or pass --server <path to out/language/main.cjs>.`);
}
if (opts.probe) {
    console.log(server);
    process.exit(0);
}

// ---------- collecting targets ----------
const SKIP_DIRS = new Set(['node_modules', 'out', 'dist']);
function collect(p, out) {
    let st;
    try { st = statSync(p); } catch { fail(2, `not found: ${p}`); }
    if (st.isDirectory()) {
        for (const e of readdirSync(p, { withFileTypes: true })) {
            if (e.name.startsWith('.') || SKIP_DIRS.has(e.name)) continue;
            const child = path.join(p, e.name);
            if (e.isDirectory()) collect(child, out);
            else if (/\.(sysml|kerml)$/i.test(e.name)) out.push(child);
        }
    } else if (/\.(sysml|kerml)$/i.test(p)) {
        out.push(p);
    } else {
        fail(2, `not a .sysml or .kerml file: ${p}`);
    }
}
const files = [];
for (const t of opts.targets) collect(path.resolve(t), files);
if (files.length === 0) {
    console.log('0 errors, 0 warnings in 0 files (no .sysml or .kerml files found)');
    process.exit(0);
}

function commonDir(paths) {
    let dir = path.dirname(paths[0]);
    for (const p of paths) {
        while (!(p + path.sep).startsWith(dir.endsWith(path.sep) ? dir : dir + path.sep)) {
            const up = path.dirname(dir);
            if (up === dir) return dir;
            dir = up;
        }
    }
    return dir;
}
const root = path.resolve(opts.root ?? commonDir(files));

// Paths are compared case-insensitively on Windows; URIs from the server may be encoded differently.
const key = p => (process.platform === 'win32' ? p.toLowerCase() : p);
const keyOfUri = uri => { try { return key(path.resolve(fileURLToPath(uri))); } catch { return undefined; } };
const wanted = new Map(files.map(f => [key(f), f]));

// ---------- LSP over stdio ----------
const child = spawn(process.execPath, [server, '--stdio'], { stdio: ['pipe', 'pipe', 'pipe'] });
let stderr = '';
child.stderr.on('data', d => { stderr += d; });
child.on('exit', code => {
    if (!finished) fail(4, `the language server exited early (code ${code})\n${stderr}`);
});

let buf = Buffer.alloc(0);
let nextId = 1;
const pending = new Map();
const diagnostics = new Map(); // file key -> Diagnostic[]
let lastPublish = 0;
let finished = false;

function write(msg) {
    const s = JSON.stringify({ jsonrpc: '2.0', ...msg });
    child.stdin.write(`Content-Length: ${Buffer.byteLength(s)}\r\n\r\n${s}`);
}
function request(method, params) {
    const id = nextId++;
    write({ id, method, params });
    return new Promise(resolve => pending.set(id, resolve));
}
const notify = (method, params) => write({ method, params });

child.stdout.on('data', d => {
    buf = Buffer.concat([buf, d]);
    for (;;) {
        const h = buf.indexOf('\r\n\r\n');
        if (h < 0) return;
        const m = /Content-Length: (\d+)/i.exec(buf.subarray(0, h).toString());
        if (!m) { buf = buf.subarray(h + 4); continue; }
        const len = Number(m[1]);
        if (buf.length < h + 4 + len) return;
        const msg = JSON.parse(buf.subarray(h + 4, h + 4 + len).toString());
        buf = buf.subarray(h + 4 + len);
        if (msg.id !== undefined && msg.method === undefined) {
            pending.get(msg.id)?.(msg.result);
            pending.delete(msg.id);
        } else if (msg.id !== undefined) {
            // Server -> client requests (configuration, capability registration, progress).
            const items = msg.params?.items;
            write({ id: msg.id, result: msg.method === 'workspace/configuration' && Array.isArray(items) ? items.map(() => null) : null });
        } else if (msg.method === 'textDocument/publishDiagnostics') {
            const k = keyOfUri(msg.params.uri);
            if (k && wanted.has(k)) {
                diagnostics.set(k, msg.params.diagnostics);
                lastPublish = Date.now();
            }
        }
    }
});

const rootUri = pathToFileURL(root).href;
await request('initialize', {
    processId: process.pid,
    rootUri,
    workspaceFolders: [{ uri: rootUri, name: path.basename(root) }],
    capabilities: { textDocument: { publishDiagnostics: { relatedInformation: true } }, workspace: { workspaceFolders: true, configuration: true } },
});
notify('initialized', {});
for (const f of files) {
    notify('textDocument/didOpen', {
        textDocument: { uri: pathToFileURL(f).href, languageId: /\.kerml$/i.test(f) ? 'kerml' : 'sysml', version: 1, text: readFileSync(f, 'utf8') },
    });
}

// Done when every file has reported and the server has been quiet for a moment.
const QUIET_MS = 1500;
const deadline = Date.now() + opts.timeout * 1000;
let timedOut = false;
await new Promise(resolve => {
    const tick = setInterval(() => {
        const all = diagnostics.size === wanted.size;
        if ((all && Date.now() - lastPublish >= QUIET_MS) || Date.now() > deadline) {
            timedOut = !all;
            clearInterval(tick);
            resolve();
        }
    }, 100);
});
finished = true;
try {
    await Promise.race([request('shutdown', null), new Promise(r => setTimeout(r, 2000))]);
    notify('exit', null);
} catch { /* server already gone */ }
setTimeout(() => child.kill(), 500).unref();

// ---------- report ----------
const SEVERITY = { 1: 'error', 2: 'warning', 3: 'info' };
const rel = f => path.relative(process.cwd(), f).split(path.sep).join('/') || f;
let errors = 0, warnings = 0;
for (const f of [...files].sort()) {
    const ds = (diagnostics.get(key(f)) ?? []).slice()
        .sort((a, b) => a.range.start.line - b.range.start.line || a.range.start.character - b.range.start.character);
    for (const d of ds) {
        const sev = SEVERITY[d.severity ?? 1];
        if (!sev) continue; // hints
        if (sev === 'error') errors++;
        else if (sev === 'warning') warnings++;
        if (opts.errorsOnly && sev !== 'error') continue;
        const code = d.code !== undefined ? ` [${d.code}]` : '';
        console.log(`${rel(f)}:${d.range.start.line + 1}:${d.range.start.character + 1}: ${sev}: ${d.message.replace(/\s*\n\s*/g, ' ')}${code}`);
    }
}
if (timedOut) {
    const missing = files.filter(f => !diagnostics.has(key(f))).map(rel);
    console.log(`timeout: no result after ${opts.timeout}s for ${missing.join(', ')}`);
    process.exit(4);
}
console.log(`${errors} error${errors === 1 ? '' : 's'}, ${warnings} warning${warnings === 1 ? '' : 's'} in ${files.length} file${files.length === 1 ? '' : 's'}`);
process.exit(errors ? 1 : 0);
