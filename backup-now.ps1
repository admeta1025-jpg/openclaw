# backup-now.ps1
# Run anytime to snapshot and push C:\Users\Administrator\.openclaw to GitHub.
#
# Usage:
#   .\backup-now.ps1
#   .\backup-now.ps1 -Message "before major config change"

param(
    [string]$Message = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$LocalDir = "C:\Users\Administrator\.openclaw"
$Branch   = "main"

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-Step([string]$Msg) {
    Write-Host "`n[BACKUP] $Msg" -ForegroundColor Cyan
}

function Write-OK([string]$Msg) {
    Write-Host "  OK  $Msg" -ForegroundColor Green
}

# ── Validate environment ──────────────────────────────────────────────────────

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git not found. Run setup-backup.ps1 first."
    exit 1
}

if (-not (Test-Path (Join-Path $LocalDir ".git"))) {
    Write-Error "$LocalDir is not a git repository. Run setup-backup.ps1 first."
    exit 1
}

# ── Run backup ────────────────────────────────────────────────────────────────

Set-Location $LocalDir

Write-Step "Staging all changes ..."
git add --all

$Status = git status --porcelain
if (-not $Status) {
    Write-Host "`n[BACKUP] Nothing changed since last backup. Nothing to push." -ForegroundColor Yellow
    exit 0
}

Write-Step "Committing ..."
$Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
if ($Message) {
    $CommitMsg = "backup: $Message [$Timestamp]"
} else {
    $CommitMsg = "backup: $Timestamp"
}
git commit -m $CommitMsg
Write-OK "Committed: $CommitMsg"

Write-Step "Pushing to origin/$Branch ..."
git push origin $Branch
Write-OK "Push complete"

Write-Host "`n[DONE] Backup pushed to GitHub." -ForegroundColor Green
