# Optional: refresh the bundled official references and install the optional validator.
# Run from the kit folder:  powershell -ExecutionPolicy Bypass -File .\setup.ps1 [-InstallValidator]
param([switch]$InstallValidator)
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

if ($InstallValidator) {
    # Third-party headless validator (npm). Not the OMG reference parser; slightly more lenient.
    npm install -g sysml-validate
    sysml-validate (Join-Path $ref "GoldExample_BatteryCharger.sysml") --format compact
}
