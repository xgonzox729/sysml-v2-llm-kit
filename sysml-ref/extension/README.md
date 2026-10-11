# Material from the SysML v2 VS Code extension

Copied from [xgonzox729/sysmlextension](https://github.com/xgonzox729/sysmlextension) at commit `1828817`
(MIT license, Copyright (c) 2026 Gonzalo Milian). Read-only reference for the agent; refresh with
`.\setup.ps1 -RefreshExtension -ExtensionPath <clone of the extension>`.

| Folder | From | What |
|---|---|---|
| `library/` | `library/` | the extension's libraries: EngineeringUnits, Simulation, Electronics, Software, Registers, Wiring |
| `guide/` | `docs/guide/` | the modeling guide (chapters 00–21, appendices A–F). Images are not copied, so image links are broken |
| `example/sensor-node/` | `docs/guide/example/sensor-node/` | the EnviroNode: a complete multi-file model (`model/`) and its firmware stubs (generated code and CI not copied) |
| `examples/` | `examples/` | small focused models: simulation, software, wiring |
| `wiring.md`, `model-json.md` | `docs/` | the Wiring reference and the model JSON format |

The libraries here are copies for reading. The extension loads its own bundled copies; never copy these
files into `models/`.

MIT License — Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction, including without
limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of
the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
