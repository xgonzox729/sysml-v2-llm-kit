# Optional: refresh the bundled references, check for the SysML v2 VS Code extension (its sysml-sim CLI is the
# checker), and install the fallback validator.
# Run from the kit folder:
#   powershell -ExecutionPolicy Bypass -File .\setup.ps1 [-RefreshExtension [-ExtensionPath <clone>]] [-InstallValidator]
# -RefreshExtension copies the extension's libraries into sysml-ref\extension\library from the installed extension; with
# -ExtensionPath <a clone of github.com/xgonzox729/sysmlextension> it also refreshes the guide and examples.
param([switch]$RefreshExtension, [string]$ExtensionPath, [switch]$RefreshWiring, [switch]$InstallValidator)
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

# The checker: the SysML v2 VS Code extension's sysml-sim CLI, run by tools\sysml.mjs.
$extRoot = $null
if (Get-Command node -ErrorAction SilentlyContinue) {
    # Windows PowerShell 5.1 turns native stderr into errors under "Stop"; the probe reports on stderr when it fails.
    $ErrorActionPreference = "Continue"
    $probe = & node (Join-Path $PSScriptRoot "tools\sysml.mjs") --probe 2>&1
    $probeExit = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    $probe | ForEach-Object { Write-Host $_ }
    $line = $probe | Where-Object { "$_" -like "extension: *" } | Select-Object -First 1
    if ($line) { $extRoot = "$line".Substring("extension: ".Length) }
    if ($probeExit -ne 0) {
        Write-Host "Install the SysML v2 extension (Extensions: Install from VSIX...) from https://github.com/xgonzox729/sysmlextension,"
        Write-Host "or set SYSML_EXTENSION to its folder. Node.js 20+ is needed for its sysml-sim CLI."
    }
} else {
    Write-Host "Node.js is not on PATH; install Node.js 20+ to use the extension's tools (tools\sysml.mjs)."
}

if ($RefreshExtension -or $RefreshWiring) {
    $dest = Join-Path $ref "extension"
    if ($ExtensionPath) {
        # A clone of the extension repository: libraries, guide, the EnviroNode example and the small examples.
        $src = Resolve-Path $ExtensionPath
        Remove-Item -Recurse -Force (Join-Path $dest "library"), (Join-Path $dest "guide"), (Join-Path $dest "example"), (Join-Path $dest "examples") -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force (Join-Path $dest "library"), (Join-Path $dest "guide"), (Join-Path $dest "example") | Out-Null
        Copy-Item (Join-Path $src "library\*.sysml") (Join-Path $dest "library")
        Copy-Item (Join-Path $src "docs\guide\*.md") (Join-Path $dest "guide")
        Copy-Item -Recurse (Join-Path $src "docs\guide\example\sensor-node") (Join-Path $dest "example")
        Remove-Item -Recurse -Force (Join-Path $dest "example\sensor-node\generated"), (Join-Path $dest "example\sensor-node\ci") -ErrorAction SilentlyContinue
        Copy-Item -Recurse (Join-Path $src "examples") $dest
        Copy-Item (Join-Path $src "docs\wiring.md"), (Join-Path $src "docs\model-json.md") $dest
        Write-Host "sysml-ref\extension refreshed from $src. Update the commit named in sysml-ref\extension\README.md."
    } else {
        # The installed extension ships its libraries but not the guide or examples.
        if (-not $extRoot) { throw "-RefreshExtension needs the installed SysML v2 extension (see above) or -ExtensionPath <clone>." }
        New-Item -ItemType Directory -Force (Join-Path $dest "library") | Out-Null
        Copy-Item (Join-Path $extRoot "library\*.sysml") (Join-Path $dest "library")
        Write-Host "Extension libraries refreshed from $extRoot (guide and examples need -ExtensionPath <clone>)."
    }
}

if ($InstallValidator) {
    # Fallback: third-party headless validator (npm). Not the OMG reference parser; slightly more lenient,
    # and it does not know the extension's libraries.
    npm install -g sysml-validate
    sysml-validate (Join-Path $ref "GoldExample_BatteryCharger.sysml") --format compact
}
