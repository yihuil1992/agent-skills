$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillRoots = @(
    (Join-Path $repoRoot "skills"),
    (Join-Path $repoRoot "dist\agents\.agents\skills"),
    (Join-Path $repoRoot "dist\claude\.claude\skills"),
    (Join-Path $repoRoot "dist\github\.github\skills")
)

foreach ($skillsRoot in $skillRoots) {
    if (-not (Test-Path $skillsRoot)) {
        throw "Missing skills directory: $skillsRoot. Run scripts/build-dist first."
    }

    $skillDirs = Get-ChildItem -Directory $skillsRoot
    if ($skillDirs.Count -eq 0) {
        throw "No skill directories found in $skillsRoot."
    }

    foreach ($skillDir in $skillDirs) {
    $skillMd = Join-Path $skillDir.FullName "SKILL.md"
    if (-not (Test-Path $skillMd)) {
        throw "Missing SKILL.md in $($skillDir.Name)"
    }

    $content = Get-Content -Raw -Encoding UTF8 $skillMd
    if ($content -notmatch "(?s)^---\s*\r?\n(.+?)\r?\n---") {
        throw "Missing YAML frontmatter in $skillMd"
    }

    $frontmatter = $Matches[1]
    if ($frontmatter -notmatch "(?m)^name:\s*$($skillDir.Name)\s*$") {
        throw "Frontmatter name must match folder name in $skillMd"
    }
    if ($frontmatter -notmatch "(?m)^description:\s*.+") {
        throw "Missing description in $skillMd"
    }
    if ($content -match "\[TODO|TODO:") {
        throw "Placeholder TODO remains in $skillMd"
    }

    $psScripts = Get-ChildItem -Path $skillDir.FullName -Recurse -Filter "*.ps1" -File
    foreach ($script in $psScripts) {
        $errors = $null
        [void][System.Management.Automation.PSParser]::Tokenize((Get-Content -Raw -Encoding UTF8 $script.FullName), [ref]$errors)
        if ($errors -and $errors.Count -gt 0) {
            throw "PowerShell parse error in $($script.FullName): $($errors[0].Message)"
        }
    }

        Write-Host "Valid: $($skillDir.Name) [$skillsRoot]"
    }
}

Write-Host "All skills valid."
