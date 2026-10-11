// OpenCode custom tools for SysML v2 models, backed by the SysML v2 VS Code extension's sysml-sim CLI
// (https://github.com/xgonzox729/sysmlextension) through tools/sysml.mjs and tools/sysml-check.mjs.
// Each named export becomes a tool called sysml_<export>. Works with any tool-calling model.
import { tool } from "@opencode-ai/plugin"
import { execFile } from "node:child_process"
import path from "node:path"

const MAX_OUTPUT = 30_000
const NOT_INSTALLED =
  "The SysML v2 extension (with its sysml-sim CLI) is not available here. For checking, fall back to " +
  "`sysml-validate <files> --format compact` if it is on PATH; otherwise tell the user the extension is needed " +
  "(see README) and rely on the self-check checklist. Do not claim results you could not compute."

const z = tool.schema
const paths = z
  .array(z.string())
  .default(["models"])
  .describe('Model files or folders relative to the project root, e.g. ["models"] or ["models/node-parts.sysml"]. Never the project root or sysml-ref/.')

type Context = { worktree: string; abort: AbortSignal }

async function run(context: Context, script: string, argv: string[], title: string) {
  const { code, stdout, stderr } = await new Promise<{ code: number; stdout: string; stderr: string }>((resolve) => {
    execFile(
      "node",
      [path.join(context.worktree, "tools", script), ...argv],
      { cwd: context.worktree, signal: context.abort, timeout: 300_000, maxBuffer: 64 << 20 },
      (err, out, errOut) => {
        const exit = err ? (typeof (err as { code?: unknown }).code === "number" ? (err as { code: number }).code : -1) : 0
        resolve({ code: exit, stdout: String(out ?? ""), stderr: String(errOut || (err && exit === -1 ? err.message : "")) })
      },
    )
  })
  let output = [stdout.trim(), stderr.trim()].filter(Boolean).join("\n")
  if (output.length > MAX_OUTPUT) {
    output = output.slice(0, MAX_OUTPUT) + `\n… output truncated (${output.length} characters); narrow the paths or filters.`
  }
  if (code === 3 || code === -1) return { title: `${title}: extension not available`, output: `${output}\n\n${NOT_INSTALLED}` }
  const status = code === 0 ? "ok" : code === 1 ? "failed checks" : `exit ${code}`
  return { title: `${title}: ${status}`, output: `${output || "(no output)"}\n\nexit code ${code}` }
}

export const check = tool({
  description:
    "Check SysML v2 files with the SysML v2 VS Code extension: syntax, name resolution, units, and the extension's " +
    "engineering checks (wiring, electronics, software budgets, requirement margins). One line per problem: " +
    "path:line:col: severity: message [code]. Run it on every file you change; fix all errors.",
  args: { paths, errorsOnly: z.boolean().default(false).describe("Report errors only, not warnings") },
  async execute(args, context) {
    return run(context, "sysml-check.mjs", [...args.paths, ...(args.errorsOnly ? ["--errors-only"] : [])], "sysml check")
  },
})

export const verify = tool({
  description:
    "Verify requirements: for every requirement bound with `satisfy`, evaluate its `require constraint` and report " +
    "pass/fail/unknown/unverified with the margin, plus failing assertions. A failing requirement is a design finding " +
    "to report to the user, not a reason to weaken the requirement.",
  args: {
    paths,
    worstCase: z.boolean().default(false).describe("Also evaluate at the worst-case corners of @Tolerance values"),
    monteCarlo: z.number().int().positive().optional().describe("Number of Monte Carlo samples for yield (uses @Tolerance)"),
  },
  async execute(args, context) {
    const argv = ["verify", ...args.paths]
    if (args.worstCase) argv.push("--worst-case")
    if (args.monteCarlo) argv.push("--monte-carlo", String(args.monteCarlo))
    return run(context, "sysml.mjs", argv, "sysml verify")
  },
})

export const query = tool({
  description:
    "Find elements in the user's model (resolved, across files): qualified id, kind, types and value. Use it to " +
    "understand an existing model before editing it. Filters combine.",
  args: {
    paths,
    kind: z.string().optional().describe('Metaclass or keyword, e.g. "part", "part def", "requirement", "port def", "action", "state"'),
    name: z.string().optional().describe("Name pattern with * and ? wildcards, case-insensitive, e.g. \"*Battery*\""),
    within: z.string().optional().describe("Qualified name; only that element and what it contains, e.g. NodeArchitecture::node"),
    type: z.string().optional().describe("Only elements typed by or specializing this type (end of its qualified name)"),
  },
  async execute(args, context) {
    const argv = ["query", ...args.paths]
    for (const k of ["kind", "name", "within", "type"] as const) if (args[k]) argv.push(`--${k}`, args[k]!)
    return run(context, "sysml.mjs", argv, "sysml query")
  },
})

export const analyze = tool({
  description:
    "Run the analysis cases in the model (calculations, @Sweep parameter sweeps, trade studies, SPICE runs) and report " +
    "results and objectives with margins.",
  args: { paths },
  async execute(args, context) {
    return run(context, "sysml.mjs", ["analyze", ...args.paths], "sysml analyze")
  },
})

export const simulate = tool({
  description:
    "Simulate a behavior (state machine or action flow) in one model file. mode=step feeds the given inputs; " +
    "mode=time runs the @Simulate timeline; mode=coverage lists reachable transitions and test vectors. " +
    "Call without behavior first to see the available behaviors in the error message if unsure.",
  args: {
    file: z.string().describe("One model file, e.g. models/node-behavior.sysml"),
    behavior: z.string().optional().describe("Name of the state def / action def; default: the first in the file"),
    mode: z.enum(["step", "time", "coverage"]).default("step"),
    inputs: z.array(z.string()).default([]).describe('For mode=step: event names, "part: EVENT", "step" or "run", in order'),
  },
  async execute(args, context) {
    const argv = ["simulate", args.file]
    if (args.behavior) argv.push("--behavior", args.behavior)
    if (args.mode === "time") argv.push("--time")
    if (args.mode === "coverage") argv.push("--coverage")
    for (const i of args.inputs) argv.push("--input", i)
    return run(context, "sysml.mjs", argv, "sysml simulate")
  },
})

export const docs = tool({
  description:
    "Generate the system documents from the model: requirements specification, interface control document (ICD), " +
    "verification report, bill of materials and traceability matrix. Markdown is merged into one set of documents " +
    "for the whole model. The documents are built from `doc` comments, requirement ids and values, so keep those complete.",
  args: {
    paths,
    out: z.string().default("docs/model").describe("Output folder relative to the project root"),
    format: z.enum(["md", "html"]).default("md"),
  },
  async execute(args, context) {
    const argv = ["docs", ...args.paths, "--out", args.out, "--format", args.format]
    if (args.format === "md") argv.push("--merge")
    return run(context, "sysml.mjs", argv, "sysml docs")
  },
})

export const gen = tool({
  description:
    "Generate implementation code from the model: C types plus JSON Schema/protobuf from @Encoding (types), register " +
    "headers from Registers (registers), Kconfig/headers from variants (variants), C state machines with *_actions.c " +
    "stubs (state-machines). Never hand-edit generated files except the *_actions.c stubs, which are written only once.",
  args: {
    paths,
    out: z.string().default("generated").describe("Output folder relative to the project root"),
    targets: z.array(z.enum(["types", "registers", "variants", "state-machines"])).optional().describe("Default: all"),
    check: z.boolean().default(false).describe("Write nothing; fail if the output folder is out of date with the model"),
  },
  async execute(args, context) {
    const argv = ["gen", ...args.paths, "--out", args.out]
    if (args.targets?.length) argv.push("--target", args.targets.join(","))
    if (args.check) argv.push("--check")
    return run(context, "sysml.mjs", argv, "sysml gen")
  },
})
