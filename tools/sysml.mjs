#!/usr/bin/env node
// Runs the sysml-sim CLI of the SysML v2 VS Code extension (https://github.com/xgonzox729/sysmlextension),
// wherever the extension is installed. Zero dependencies; Node 20+.
//
//   node tools/sysml.mjs <command> [options] <files or folders...>
//   node tools/sysml.mjs --probe
//
// Commands (passed through to sysml-sim): check, verify, analyze, simulate, export, query, docs, gen, diff.
// Kit additions:
//   --extension <dir>     the extension folder (or set SYSML_EXTENSION)
//   --allow-reference     allow running on sysml-ref/ or the project root (refused by default)
//   docs ... --merge      one set of documents for the whole model instead of one set per file
//
// Exit codes: those of sysml-sim (0 ok, 1 a check, requirement or assertion failed, 2 usage or load error),
// plus 3 when the extension (or a version of it with the CLI) is not found.
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { findExtension, isReservedTarget, notFoundMessage } from './lib/find-extension.mjs';

const VALUE_OPTIONS = new Set(['format', 'out', 'library', 'behavior', 'input', 'kind', 'name', 'within', 'type',
    'monte-carlo', 'seed', 'spice-engine', 'target']);

const major = Number(process.versions.node.split('.')[0]);
if (major < 20) {
    console.error(`sysml: Node.js 20 or later is needed (this is ${process.versions.node}).`);
    process.exit(2);
}

// ---------- kit options ----------
let explicit, allowReference = false, merge = false, probe = false;
const args = [];
const raw = process.argv.slice(2);
for (let i = 0; i < raw.length; i++) {
    const a = raw[i];
    if (a === '--extension') explicit = raw[++i];
    else if (a.startsWith('--extension=')) explicit = a.slice('--extension='.length);
    else if (a === '--allow-reference') allowReference = true;
    else if (a === '--merge') merge = true;
    else if (a === '--probe') probe = true;
    else args.push(a);
}

const ext = findExtension(explicit);
if (probe) {
    if (!ext.root) { console.error(notFoundMessage(ext.looked)); process.exit(3); }
    console.log(`extension: ${ext.root}`);
    console.log(`sysml-sim: ${ext.cli ?? 'not in this version (update the extension)'}`);
    console.log(`language server: ${ext.server ?? 'not found'}`);
    process.exit(ext.cli ? 0 : 3);
}
if (!ext.cli) {
    console.error(ext.root
        ? `The SysML v2 extension at ${ext.root} has no sysml-sim CLI; update it to a version that ships out/cli/sysml-sim.cjs.`
        : notFoundMessage(ext.looked));
    process.exit(3);
}

// ---------- the command line ----------
const command = args[0];
const split = args.indexOf('--');
let before = split < 0 ? args : args.slice(0, split);
let after = split < 0 ? [] : args.slice(split + 1);
// sysml-sim treats everything after `--` as paths; move options that landed there in front of it.
if (after.length) {
    const kept = [];
    for (let i = 0; i < after.length; i++) {
        const name = after[i].startsWith('--') ? after[i].slice(2).split('=')[0] : undefined;
        if (name && VALUE_OPTIONS.has(name) && !after[i].includes('=')) before = [...before, after[i], after[++i]];
        else if (name) before = [...before, after[i]];
        else kept.push(after[i]);
    }
    after = kept;
}

function positionals(list) {
    const out = [];
    for (let i = 1; i < list.length; i++) {
        const a = list[i];
        if (a.startsWith('--')) { if (VALUE_OPTIONS.has(a.slice(2)) ) i++; continue; }
        out.push(a);
    }
    return out;
}
// For diff the positionals are git revisions; the paths come after `--`.
const targets = command === 'diff' ? after : positionals(before);
if (!allowReference) {
    for (const t of targets) {
        if (isReservedTarget(t)) {
            console.error(`sysml: refusing to run on ${t}: that would include the reference examples in sysml-ref/. ` +
                'Pass your model files or the models/ folder.');
            process.exit(2);
        }
    }
}

const run = (argv, quiet = false) => {
    const r = spawnSync(process.execPath, [ext.cli, ...argv], { stdio: ['inherit', 'inherit', quiet ? 'pipe' : 'inherit'], encoding: 'utf8' });
    // Keep real messages, drop the "wrote <temporary file>" progress lines.
    if (quiet && r.stderr) process.stderr.write(r.stderr.split('\n').filter(l => l && !l.startsWith('wrote ')).map(l => l + '\n').join(''));
    return r.status ?? 2;
};

if (command === 'docs' && merge) process.exit(mergedDocs());
if (command === 'query') process.exit(queryCommand());
process.exit(run(after.length ? [...before, '--', ...after] : before));

// ---------- docs --merge ----------
// sysml-sim writes the five documents per model file (DIR/<file>/<doc>.md when given several files). This merges
// them into DIR/<doc>.md, one section per file, leaving out files with nothing to say for that document.
function mergedDocs() {
    const outIndex = before.indexOf('--out');
    const formatIndex = before.indexOf('--format');
    if (outIndex < 0 || !before[outIndex + 1]) { console.error('sysml: docs needs --out DIR'); return 2; }
    if (formatIndex >= 0 && before[formatIndex + 1] !== 'md') { console.error('sysml: docs --merge supports --format md only'); return 2; }
    const outDir = path.resolve(before[outIndex + 1]);
    const tmp = mkdtempSync(path.join(tmpdir(), 'sysml-docs-'));
    try {
        const argv = before.slice();
        argv[outIndex + 1] = tmp;
        const status = run(after.length ? [...argv, '--', ...after] : argv, true);
        if (status !== 0) return status;
        // One file gives DIR/<doc>.md, several give DIR/<file>/<doc>.md.
        const groups = new Map(); // doc name -> [{ file, text }]
        const add = (file, dir) => {
            for (const f of readdirSync(dir)) {
                if (!f.endsWith('.md')) continue;
                if (!groups.has(f)) groups.set(f, []);
                groups.get(f).push({ file, text: readFileSync(path.join(dir, f), 'utf8') });
            }
        };
        for (const e of readdirSync(tmp)) {
            const p = path.join(tmp, e);
            if (statSync(p).isDirectory()) add(e, p);
        }
        if (groups.size === 0) add(undefined, tmp);
        mkdirSync(outDir, { recursive: true });
        for (const [name, parts] of groups) {
            parts.sort((a, b) => (a.file ?? '').localeCompare(b.file ?? ''));
            const title = (parts[0].text.match(/^# ([^:\n]+)/m)?.[1] ?? name.replace(/\.md$/, '')).trim();
            const sections = [];
            const seen = new Set();
            for (const { file, text } of parts) {
                const body = text.replace(/^# .*\n/, '').replace(/^_Generated from the SysML model; do not edit by hand\._\s*/m, '');
                const kept = meaningful(body).filter(b => !seen.has(b));
                kept.forEach(b => seen.add(b));
                if (!kept.length) continue;
                const joined = kept.join('\n\n');
                sections.push(file ? `## ${file}\n\n${joined.replace(/^(#+) /gm, '#$1 ')}` : joined);
            }
            const content = `# ${title}\n\n_Generated from the SysML model; do not edit by hand._\n\n` +
                (sections.length ? sections.join('\n\n') : `_Nothing to report._`) + '\n';
            writeFileSync(path.join(outDir, name), content);
            console.error(`wrote ${path.relative(process.cwd(), path.join(outDir, name))}`);
        }
        return 0;
    } finally {
        rmSync(tmp, { recursive: true, force: true });
    }
}

/** The blocks of a generated document that say something: placeholders ("_None._", "0 requirement(s): none.") dropped. */
function meaningful(body) {
    const placeholder = t => !t || /^_[^\n]*_$/.test(t) || /^0 \w+\(s\): none\.$/.test(t);
    const blocks = [];
    const chunks = body.split(/^(?=## )/m);
    for (const chunk of chunks) {
        const heading = chunk.startsWith('## ') ? chunk.slice(0, chunk.indexOf('\n') + 1 || chunk.length).trim() : '';
        const content = (heading ? chunk.slice(heading.length) : chunk).trim();
        if (placeholder(content)) continue;
        blocks.push(heading ? `${heading}\n\n${content}` : content);
    }
    return blocks;
}

// ---------- query ----------
// sysml-sim knows some keywords for --kind (part, part def, port, …) and otherwise needs the metaclass name; an
// unknown kind silently matches nothing. Translate every SysML keyword, and say so when nothing matches.
function metaclassOf(kind) {
    const KIND_WORDS = { enum: 'Enumeration', calc: 'Calculation', analysis: 'AnalysisCase', verification: 'VerificationCase', 'use case': 'UseCase' };
    const k = kind.trim().toLowerCase().replace(/\s+/g, ' ');
    if (k === 'package') return 'Package';
    if (k === 'satisfy') return 'SatisfyRequirementUsage';
    if (/[A-Z]/.test(kind) || !/^[a-z][a-z ]*$/.test(k)) return kind; // a metaclass name
    const isDef = k.endsWith(' def');
    const base = isDef ? k.slice(0, -4) : k;
    const word = KIND_WORDS[base] ?? base.split(' ').map(w => w[0].toUpperCase() + w.slice(1)).join('');
    return word + (isDef ? 'Definition' : 'Usage');
}
function queryCommand() {
    const argv = before.slice();
    const i = argv.indexOf('--kind');
    if (i >= 0 && argv[i + 1]) argv[i + 1] = metaclassOf(argv[i + 1]);
    const r = spawnSync(process.execPath, [ext.cli, ...argv], { stdio: ['inherit', 'pipe', 'inherit'], encoding: 'utf8', maxBuffer: 64 << 20 });
    const out = (r.stdout ?? '').trim();
    if (out && out !== '[]') console.log(out);
    else console.log('No elements match. --kind takes a keyword (part, part def, port def, interface def, requirement, ' +
        'state def, action def, enum def, use case, …) or a metaclass name (PartDefinition, …); --name takes * and ? wildcards.');
    return r.status ?? 2;
}
