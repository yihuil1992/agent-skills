$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillsRoot = Join-Path $repoRoot "skills"
$distRoot = Join-Path $repoRoot "dist"

if (-not (Test-Path $skillsRoot)) {
    throw "Missing skills directory: $skillsRoot"
}

$layouts = @(
    @{ Name = "agents"; Path = ".agents\skills" },
    @{ Name = "claude"; Path = ".claude\skills" },
    @{ Name = "github"; Path = ".github\skills" }
)

if (Test-Path $distRoot) {
    Remove-Item -Recurse -Force $distRoot
}

foreach ($layout in $layouts) {
    $targetRoot = Join-Path (Join-Path $distRoot $layout.Name) $layout.Path
    New-Item -ItemType Directory -Force $targetRoot | Out-Null

    foreach ($skillDir in Get-ChildItem -Directory $skillsRoot) {
        Copy-Item -Recurse -Force $skillDir.FullName (Join-Path $targetRoot $skillDir.Name)
    }
}

Write-Host "Built dist layouts in $distRoot"
