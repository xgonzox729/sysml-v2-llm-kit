# Optional: refresh the bundled official references, check for the SysML v2 VS Code extension (the checker),
# and install the fallback validator.
# Run from the kit folder:  powershell -ExecutionPolicy Bypass -File .\setup.ps1 [-RefreshWiring] [-InstallValidator]
param([switch]$RefreshWiring, [switch]$InstallValidator)
$ErrorActionPreference = "Stop"

$tmp = Join-Path $env:TEMP "sysml-v2-release"
if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
git clone --depth 1 https://github.com/Systems-Modeling/SysML-v2-Release.git $tmp

$ref = Join-Path $PSScriptRoot "sysml-ref"
Remove-Item -Recurse -Force (Join-Path $ref "examples"), (Join-Path $ref "grammar") -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force (Join-Path $ref "examples"), (Join-Path $ref "grammar") | Out-Null
Copy-Item -Recurse (Join-Path $tmp "sysml\src\training\*") (Join-Path $ref "examples")
Copy-Item (Join-Path $tmp "bnf\SysML-textual-bnf.kebnf"), (Join-Path $tmp "bnf\KerML-textual-bnf.kebnf") (Join-Path $ref "grammar")
Copy-Item (Join-Path $tmp "LICENSE") (Join-Path $ref "examples\LICENSE-EPL-2.0.txt")
Copy-Item (Join-Path $tmp "LICENSE") (Join-Path $ref "grammar\LICENSE-EPL-2.0.txt")
Write-Host "References refreshed from the official SysML v2 Release repo."

# The checker: the SysML v2 VS Code extension's language server, run by tools/sysml-check.mjs.
$checker = Join-Path $PSScriptRoot "tools\sysml-check.mjs"
$server = $null
if (Get-Command node -ErrorAction SilentlyContinue) {
    $server = & node $checker --probe 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SysML v2 extension checker found: $server"
    } else {
        $server = $null
        Write-Host "SysML v2 extension not found. Install it from https://github.com/xgonzox729/sysmlextension"
        Write-Host "(Extensions: Install from VSIX...), or set SYSML_LSP_SERVER to its out\language\main.cjs."
    }
} else {
    Write-Host "Node.js is not on PATH; install Node.js 18+ to use the extension checker (tools\sysml-check.mjs)."
}

if ($RefreshWiring) {
    if (-not $server) { throw "-RefreshWiring needs the SysML v2 extension (see above)." }
    # main.cjs lives in <extension>\out\language\; the library and example sit at the extension root.
    $extRoot = Split-Path (Split-Path (Split-Path $server -Parent) -Parent) -Parent
    $wiring = Join-Path $ref "wiring"
    New-Item -ItemType Directory -Force $wiring | Out-Null
    Copy-Item (Join-Path $extRoot "library\Wiring.sysml") $wiring
    $example = Join-Path $extRoot "examples\wiring\avionics.sysml"
    if (Test-Path $example) { Copy-Item $example $wiring }
    else { Write-Host "avionics.sysml is not shipped in the installed extension; kept the existing copy." }
    Write-Host "Wiring library refreshed from $extRoot."
}

if ($InstallValidator) {
    # Fallback: third-party headless validator (npm). Not the OMG reference parser; slightly more lenient,
    # and it does not know the extension's Wiring library.
    npm install -g sysml-validate
    sysml-validate (Join-Path $ref "GoldExample_BatteryCharger.sysml") --format compact
}
