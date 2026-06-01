param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("spec-driven-workflow", "pr-land")]
    [string]$Skill,

    [Parameter(Mandatory = $true)]
    [ValidateSet("codex", "claude")]
    [string]$Target,

    [string]$DestinationRoot,

    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot "skills\$Skill"
if (-not (Test-Path $source)) {
    throw "Skill not found: $source"
}

if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
    switch ($Target) {
        "codex" { $DestinationRoot = Join-Path $HOME ".codex\skills" }
        "claude" { $DestinationRoot = Join-Path $HOME ".claude\skills" }
    }
}

$destination = Join-Path $DestinationRoot $Skill
if ((Test-Path $destination) -and -not $Force) {
    throw "Destination already exists: $destination. Re-run with -Force to replace it."
}

New-Item -ItemType Directory -Force $DestinationRoot | Out-Null
if (Test-Path $destination) {
    Remove-Item -Recurse -Force $destination
}

Copy-Item -Recurse -Force $source $destination
Write-Host "Installed $Skill to $destination"

