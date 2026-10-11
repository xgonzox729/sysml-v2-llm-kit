// OpenCode custom tool: checks .sysml/.kerml files with the SysML v2 VS Code extension's language server
// (syntax, name resolution, Wiring checks) by running tools/sysml-check.mjs. Works with any tool-calling model.
import { tool } from "@opencode-ai/plugin"
import { execFile } from "node:child_process"
import path from "node:path"

const NOT_INSTALLED =
  "The SysML v2 extension checker is not available here. Fall back to `sysml-validate <files> --format compact` " +
  "if it is on PATH; otherwise say no validator is installed and rely on the self-check checklist."

export default tool({
  description:
    "Check SysML v2 model files with the SysML v2 VS Code extension (parser, name resolution, electrical Wiring checks). " +
    "Returns one line per problem as path:line:col: severity: message [code], then a summary. " +
    "Pass the files you changed, or the models/ folder. Never pass the project root or sysml-ref/.",
  args: {
    paths: tool.schema
      .array(tool.schema.string())
      .describe("Files or folders to check, relative to the project root, e.g. [\"models/Drone.sysml\"] or [\"models\"]")
      .default(["models"]),
    errorsOnly: tool.schema.boolean().describe("Report errors only, not warnings").default(false),
  },
  async execute(args, context) {
    const script = path.join(context.worktree, "tools", "sysml-check.mjs")
    const argv = [script, ...args.paths, ...(args.errorsOnly ? ["--errors-only"] : [])]
    const { code, stdout, stderr } = await new Promise<{ code: number; stdout: string; stderr: string }>((resolve) => {
      execFile("node", argv, { cwd: context.worktree, signal: context.abort, timeout: 180_000, maxBuffer: 8 << 20 }, (err, out, errOut) => {
        const exit = err ? (typeof (err as { code?: unknown }).code === "number" ? (err as { code: number }).code : -1) : 0
        resolve({ code: exit, stdout: String(out), stderr: String(errOut || (err && exit === -1 ? err.message : "")) })
      })
    })
    const output = [stdout.trim(), stderr.trim()].filter(Boolean).join("\n")
    if (code === 3) return { title: "SysML checker not installed", output: `${output}\n\n${NOT_INSTALLED}` }
    if (code === -1) return { title: "SysML checker failed to run", output: `${output}\n\n${NOT_INSTALLED}` }
    const summary = stdout.trim().split("\n").pop() ?? ""
    return { title: `sysml-check: ${summary}`, output: output || summary }
  },
})
