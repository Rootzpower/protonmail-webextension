<#
.SYNOPSIS
    Builds the Firefox extension and prepares the files to upload to addons.mozilla.org.

.DESCRIPTION
    Everything stays inside the repository folder:
      .tools\node-12.22.12\            portable Node.js 12 (downloaded once, ignored by git)
      release\<version>\firefox-<version>.zip   extension package to upload
      release\<version>\source-<version>.zip    source code package (git archive of HEAD)

    Requirements:
      - git
      - web-ext installed globally (npm i -g web-ext) with a recent Node.js
      - a clean git working tree (the source zip is created from HEAD)

    Usage (from any folder):
      powershell -ExecutionPolicy Bypass -File .\scripts\Build-Release.ps1
      powershell -ExecutionPolicy Bypass -File .\scripts\Build-Release.ps1 -SkipInstall
#>
[CmdletBinding()]
param(
    # Skip "npm ci" when node_modules is already installed with Node 12
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

$NodeVersion = "12.22.12"
$NodeSha256  = "09639bac66d4dc4dd52179968209413ad4b7360e917dcbe8834052a4b936a087"
$NodeUrl     = "https://nodejs.org/dist/v$NodeVersion/node-v$NodeVersion-win-x64.zip"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ToolsDir = Join-Path $RepoRoot ".tools"
$NodeDir  = Join-Path $ToolsDir "node-$NodeVersion"

function Assert-LastExitCode([string]$what) {
    if ($LASTEXITCODE -ne 0) { throw "$what failed (exit code $LASTEXITCODE)" }
}

Set-Location $RepoRoot

# --- 1. Preconditions ---------------------------------------------------------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "git was not found in PATH" }
if (-not (Get-Command web-ext -ErrorAction SilentlyContinue)) {
    throw "web-ext was not found in PATH. Install it with: npm i -g web-ext"
}
$dirty = git status --porcelain
Assert-LastExitCode "git status"
if ($dirty) {
    throw "The working tree has uncommitted changes. Commit them first (the source zip is created from HEAD):`n$dirty"
}

# --- 2. Portable Node 12 (inside .tools) --------------------------------------
if (-not (Test-Path (Join-Path $NodeDir "node.exe"))) {
    Write-Host "Downloading Node.js $NodeVersion ..."
    New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null
    $zip = Join-Path $ToolsDir "node-$NodeVersion.zip"
    Invoke-WebRequest -Uri $NodeUrl -OutFile $zip -UseBasicParsing
    $hash = (Get-FileHash -Path $zip -Algorithm SHA256).Hash.ToLower()
    if ($hash -ne $NodeSha256) {
        Remove-Item $zip -Force
        throw "SHA256 mismatch for the Node.js download (got $hash)"
    }
    Expand-Archive -Path $zip -DestinationPath $ToolsDir -Force
    Rename-Item -Path (Join-Path $ToolsDir "node-v$NodeVersion-win-x64") -NewName "node-$NodeVersion"
    Remove-Item $zip -Force
}

# --- 3. Build with Node 12 (PATH is restored afterwards for web-ext) ----------
$version = (Get-Content (Join-Path $RepoRoot "package.json") -Raw | ConvertFrom-Json).version
Write-Host "Building version $version ..."

$originalPath = $env:PATH
$env:PATH = "$NodeDir;$originalPath"
try {
    Write-Host "Node: $(node -v)"
    if (-not $SkipInstall) {
        npm ci
        Assert-LastExitCode "npm ci"
    }
    npm run build:firefox
    Assert-LastExitCode "npm run build:firefox"
}
finally {
    $env:PATH = $originalPath
}

# --- 4. Package ---------------------------------------------------------------
$out = Join-Path $RepoRoot "release\$version"
New-Item -ItemType Directory -Force -Path $out | Out-Null
# Only remove old zips; keep subfolders such as release\<version>\signed
Get-ChildItem -Path $out -Filter "*.zip" -File | Remove-Item -Force

web-ext build --source-dir (Join-Path $RepoRoot "build") --artifacts-dir $out
Assert-LastExitCode "web-ext build"
$built = Get-ChildItem -Path $out -Filter "*.zip" | Select-Object -First 1
Rename-Item -Path $built.FullName -NewName "firefox-$version.zip"

git archive --format=zip -o (Join-Path $out "source-$version.zip") HEAD
Assert-LastExitCode "git archive"

Write-Host ""
Write-Host "Done. Files in $out :"
Get-ChildItem $out | ForEach-Object { Write-Host ("  {0}  ({1:N0} bytes)" -f $_.Name, $_.Length) }
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. (Optional) test: about:debugging > Load Temporary Add-on > build\manifest.json"
Write-Host "  2. addons.mozilla.org Developer Hub > your add-on > Upload New Version (On your own)"
Write-Host "  3. Answer Yes to the source code question and upload source-$version.zip"
Write-Host "  4. Save the signed .xpi in $out\signed\ and install it from about:addons"
