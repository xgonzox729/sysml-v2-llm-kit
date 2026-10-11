// Locates the SysML v2 VS Code extension (https://github.com/xgonzox729/sysmlextension): its root folder,
// the sysml-sim CLI (out/cli/sysml-sim.cjs, extension versions with the CLI) and the language server
// (out/language/main.cjs, every version).
import { existsSync, readdirSync } from 'node:fs';
import { homedir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const EXTENSION_ID = 'xgonzox729.sysml-vscode';
export const KIT_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const CLI_REL = path.join('out', 'cli', 'sysml-sim.cjs');
const SERVER_REL = path.join('out', 'language', 'main.cjs');
const EDITOR_DIRS = ['.vscode', '.vscode-insiders', '.vscode-oss', '.cursor', '.windsurf', '.vscode-server'];

function compareVersions(a, b) {
    const pa = a.split(/[.-]/).map(Number), pb = b.split(/[.-]/).map(Number);
    for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
        const d = (pa[i] || 0) - (pb[i] || 0);
        if (d) return d;
    }
    return 0;
}

function describe(root) {
    const cli = path.join(root, CLI_REL), server = path.join(root, SERVER_REL);
    return { root, cli: existsSync(cli) ? cli : undefined, server: existsSync(server) ? server : undefined };
}

/**
 * Finds the extension. `explicit` is a path given on the command line: the extension root, its
 * out/cli/sysml-sim.cjs or its out/language/main.cjs. Then SYSML_EXTENSION (root), SYSML_SIM (CLI) and
 * SYSML_LSP_SERVER (server), then the newest installed copy, then a built clone next to the kit.
 * Returns { root, cli, server, looked }; root is undefined when nothing usable was found.
 */
export function findExtension(explicit) {
    const looked = [];
    const fromPath = p => {
        const abs = path.resolve(p);
        looked.push(abs);
        if (!existsSync(abs)) return undefined;
        // A file inside out/cli or out/language: the root is two levels above its folder.
        const root = /\.c?js$/.test(abs) ? path.resolve(path.dirname(abs), '..', '..') : abs;
        const found = describe(root);
        return found.cli || found.server ? found : undefined;
    };
    const given = explicit ?? process.env.SYSML_EXTENSION ?? process.env.SYSML_SIM ?? process.env.SYSML_LSP_SERVER;
    if (given) return { ...(fromPath(given) ?? {}), looked };

    const installed = [];
    for (const editor of EDITOR_DIRS) {
        const dir = path.join(homedir(), editor, 'extensions');
        looked.push(path.join(dir, `${EXTENSION_ID}-*`));
        let entries = [];
        try { entries = readdirSync(dir); } catch { continue; }
        for (const e of entries) {
            if (!e.toLowerCase().startsWith(EXTENSION_ID + '-')) continue;
            const found = describe(path.join(dir, e));
            if (found.cli || found.server) installed.push({ ...found, version: e.slice(EXTENSION_ID.length + 1) });
        }
    }
    if (installed.length) {
        installed.sort((x, y) => compareVersions(y.version, x.version));
        const { version, ...best } = installed[0];
        return { ...best, looked };
    }
    for (const name of ['sysmlextension', 'sysMLextension', 'SysMLExtension']) {
        const found = fromPath(path.join(KIT_ROOT, '..', name));
        if (found) return { ...found, looked };
    }
    return { looked };
}

export function notFoundMessage(looked) {
    return `SysML v2 extension not found. Looked in:\n${looked.map(l => '  ' + l).join('\n')}\n` +
        `Install the extension (VS Code: Extensions: Install from VSIX...), or build a clone of\n` +
        `https://github.com/xgonzox729/sysmlextension next to this kit (npm ci && npm run build),\n` +
        `or pass --extension <extension folder> (or set SYSML_EXTENSION).`;
}

/** True when `p` is the kit root or inside sysml-ref/ (reference material the tools must not run on). */
export function isReservedTarget(p) {
    const abs = path.resolve(p);
    const ref = path.join(KIT_ROOT, 'sysml-ref');
    return abs === KIT_ROOT || abs === ref || abs.startsWith(ref + path.sep);
}
