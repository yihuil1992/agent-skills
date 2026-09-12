param(
    [string]$Pr,
    [ValidateSet("merge", "squash", "rebase")]
    [string]$MergeMethod = "squash",
    [int]$TimeoutMinutes = 60,
    [int]$PollSeconds = 30,
    [switch]$RequiredOnly,
    [switch]$SkipReviewGate,
    [switch]$KeepRemoteBranch,
    [switch]$KeepLocalBranch,
    [switch]$NoPull,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

function Invoke-Logged {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    Write-Host ("> {0} {1}" -f $Command, ($Arguments -join " "))
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Command $($Arguments -join ' ')"
    }
}

function Invoke-Captured {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [int[]]$AllowedExitCodes = @(0)
    )

    $output = & $Command @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    if ($AllowedExitCodes -notcontains $exitCode) {
        $text = ($output | Out-String).Trim()
        throw "Command failed with exit code ${exitCode}: $Command $($Arguments -join ' ')`n$text"
    }
    return (($output | Out-String).Trim())
}

function Test-LocalBranchExists {
    param([Parameter(Mandatory = $true)][string]$Branch)

    $branches = Invoke-Captured "git" @("branch", "--list", $Branch)
    return -not [string]::IsNullOrWhiteSpace($branches)
}

function Get-RefSha {
    param([Parameter(Mandatory = $true)][string]$Ref)

    return Invoke-Captured "git" @("rev-parse", $Ref)
}

function Get-StagedIgnoredPaths {
    $staged = Invoke-Captured "git" @("diff", "--cached", "--name-only")
    if ([string]::IsNullOrWhiteSpace($staged)) {
        return @()
    }

    $ignored = New-Object System.Collections.Generic.List[string]
    foreach ($path in ($staged -split "`r?`n")) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        & git check-ignore --quiet --no-index -- $path
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) {
            $ignored.Add($path)
        } elseif ($exitCode -ne 1) {
            throw "git check-ignore failed with exit code ${exitCode} for path: $path"
        }
    }

    return @($ignored)
}

function Unstage-IgnoredPaths {
    $ignored = @(Get-StagedIgnoredPaths)
    if ($ignored.Count -eq 0) {
        return
    }

    Write-Host "Unstaging ignored path(s):"
    foreach ($path in $ignored) {
        Write-Host ("- {0}" -f $path)
    }

    Invoke-Logged "git" (@("restore", "--staged", "--") + $ignored)
}

function Wait-ForChecks {
    param(
        [Parameter(Mandatory = $true)][string]$Selector,
        [Parameter(Mandatory = $true)][datetime]$Deadline
    )

    while ($true) {
        $args = @("pr", "checks", $Selector, "--json", "bucket,name,state,link,workflow")
        if ($RequiredOnly) {
            $args += "--required"
        }

        $rawOutput = & gh @args 2>&1
        $exitCode = $LASTEXITCODE
        $raw = (($rawOutput | Out-String).Trim())
        if ($exitCode -ne 0 -and $exitCode -ne 8) {
            if ($raw -match "(?i)\bno\b.*\b(checks?|status checks?|check runs?)\b|\bchecks?\b.*\bnot found\b") {
                Write-Host "No CI checks reported for PR $Selector."
                return
            }
            throw "Command failed with exit code ${exitCode}: gh $($args -join ' ')`n$raw"
        }
        if ([string]::IsNullOrWhiteSpace($raw)) {
            Write-Host "No CI checks reported for PR $Selector."
            return
        }

        $checks = @($raw | ConvertFrom-Json)
        if ($checks.Count -eq 0) {
            Write-Host "No CI checks reported for PR $Selector."
            return
        }

        $failed = @($checks | Where-Object { $_.bucket -in @("fail", "cancel") })
        if ($failed.Count -gt 0) {
            $summary = ($failed | ForEach-Object { "- $($_.name): $($_.state) $($_.link)" }) -join "`n"
            throw "CI did not pass:`n$summary"
        }

        $pending = @($checks | Where-Object { $_.bucket -eq "pending" })
        if ($pending.Count -eq 0) {
            Write-Host "CI checks passed for PR $Selector."
            return
        }

        if ((Get-Date) -ge $Deadline) {
            $summary = ($pending | ForEach-Object { "- $($_.name): $($_.state)" }) -join "`n"
            throw "Timed out after $TimeoutMinutes minute(s) waiting for CI:`n$summary"
        }

        Write-Host ("Waiting for {0} pending check(s). Next poll in {1}s." -f $pending.Count, $PollSeconds)
        Start-Sleep -Seconds $PollSeconds
    }
}

Get-Command git | Out-Null
Get-Command gh | Out-Null

$repoRoot = Invoke-Captured "git" @("rev-parse", "--show-toplevel")
$currentBranch = Invoke-Captured "git" @("branch", "--show-current")
Unstage-IgnoredPaths
$status = Invoke-Captured "git" @("status", "--porcelain")
if (-not [string]::IsNullOrWhiteSpace($status)) {
    throw "Working tree has uncommitted changes. Commit, stash, or confirm a narrower cleanup before landing the PR."
}

$viewArgs = @("pr", "view")
if (-not [string]::IsNullOrWhiteSpace($Pr)) {
    $viewArgs += $Pr
}
$viewArgs += @("--json", "number,title,url,headRefName,headRefOid,baseRefName,isDraft,reviewDecision,mergeStateStatus")
$prInfo = Invoke-Captured "gh" $viewArgs | ConvertFrom-Json

$selector = [string]$prInfo.number
$headBranch = [string]$prInfo.headRefName
$baseBranch = [string]$prInfo.baseRefName
$headOid = [string]$prInfo.headRefOid

Write-Host ("PR #{0}: {1}" -f $prInfo.number, $prInfo.title)
Write-Host $prInfo.url
Write-Host ("Head: {0} ({1})" -f $headBranch, $headOid)
Write-Host ("Base: {0}" -f $baseBranch)
Write-Host ("Merge method: {0}" -f $MergeMethod)

if ($prInfo.isDraft) {
    throw "PR #$($prInfo.number) is still a draft."
}

if (-not $SkipReviewGate) {
    if ($prInfo.reviewDecision -eq "CHANGES_REQUESTED") {
        throw "PR #$($prInfo.number) has requested changes."
    }
    if ($prInfo.reviewDecision -eq "REVIEW_REQUIRED") {
        throw "PR #$($prInfo.number) still requires review approval."
    }
}

$branchToDelete = $headBranch
$localBranchMatchesPrHead = $false
if ((Test-LocalBranchExists $headBranch)) {
    $localHead = Get-RefSha $headBranch
    if ($localHead -eq $headOid) {
        $localBranchMatchesPrHead = $true
    } elseif ($currentBranch -eq $headBranch) {
        throw "Local branch '$headBranch' is at $localHead, but the PR head is $headOid. Push, pull, or reconcile before landing."
    } else {
        Write-Warning "Local branch '$headBranch' does not match the PR head; local branch cleanup will be skipped."
    }
}

if (-not $Yes) {
    Write-Host "Dry run only. Re-run with -Yes to wait for checks, merge, and clean up."
    exit 0
}

$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
Wait-ForChecks $selector $deadline

$mergeArgs = @("pr", "merge", $selector, "--$MergeMethod")
if (-not $KeepRemoteBranch) {
    $mergeArgs += "--delete-branch"
}
Invoke-Logged "gh" $mergeArgs

Invoke-Logged "git" @("fetch", "origin", $baseBranch)
if (Test-LocalBranchExists $baseBranch) {
    Invoke-Logged "git" @("checkout", $baseBranch)
} else {
    Invoke-Logged "git" @("checkout", "-b", $baseBranch, "origin/$baseBranch")
}

if (-not $NoPull) {
    Invoke-Logged "git" @("pull", "--ff-only", "origin", $baseBranch)
}

if (-not $KeepLocalBranch -and $branchToDelete -ne $baseBranch -and (Test-LocalBranchExists $branchToDelete)) {
    if ($localBranchMatchesPrHead) {
        Invoke-Logged "git" @("branch", "-D", $branchToDelete)
    } else {
        Write-Warning "Skipped local branch deletion for '$branchToDelete' because it did not match the PR head SHA."
    }
}

Write-Host ("Landed PR #{0} and returned to {1} in {2}." -f $prInfo.number, $baseBranch, $repoRoot)
