# setup-backup.ps1
# Run this ONCE to configure C:\Users\Administrator\.openclaw as a git-backed folder
# that mirrors to https://github.com/admeta1025-jpg/openclaw
#
# Requirements:
#   - Git for Windows installed (https://git-scm.com/download/win)
#   - A GitHub Personal Access Token (PAT) with repo scope
#     OR an SSH key configured for GitHub
#
# Usage:
#   .\setup-backup.ps1 -Token "ghp_xxxxxxxxxxxxxxxxxxxx"
#   .\setup-backup.ps1 -UseSSH

param(
    [string]$Token,
    [switch]$UseSSH
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$LocalDir  = "C:\Users\Administrator\.openclaw"
$RepoOwner = "admeta1025-jpg"
$RepoName  = "openclaw"
$Branch    = "main"

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-Step([string]$Msg) {
    Write-Host "`n[SETUP] $Msg" -ForegroundColor Cyan
}

function Write-OK([string]$Msg) {
    Write-Host "  OK  $Msg" -ForegroundColor Green
}

function Write-Warn([string]$Msg) {
    Write-Host "  WARN $Msg" -ForegroundColor Yellow
}

# ── Pre-flight checks ─────────────────────────────────────────────────────────

Write-Step "Checking prerequisites..."

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is not installed or not in PATH. Download from https://git-scm.com/download/win"
    exit 1
}
Write-OK "Git found: $(git --version)"

if (-not (Test-Path $LocalDir)) {
    Write-Error "Directory not found: $LocalDir"
    exit 1
}
Write-OK "Local directory exists: $LocalDir"

if (-not $UseSSH -and -not $Token) {
    Write-Error "You must provide either -Token <PAT> or -UseSSH. See README.md for details."
    exit 1
}

# ── Build remote URL ──────────────────────────────────────────────────────────

if ($UseSSH) {
    $RemoteURL = "git@github.com:$RepoOwner/$RepoName.git"
    Write-OK "Using SSH remote: $RemoteURL"
} else {
    # Embed token in HTTPS URL so git does not prompt for credentials
    $RemoteURL = "https://$Token@github.com/$RepoOwner/$RepoName.git"
    Write-OK "Using HTTPS remote with PAT"
}

# ── Git init ──────────────────────────────────────────────────────────────────

Set-Location $LocalDir

Write-Step "Initializing git repository in $LocalDir ..."

if (Test-Path (Join-Path $LocalDir ".git")) {
    Write-Warn ".git directory already exists — skipping git init"
} else {
    git init --initial-branch=$Branch | Out-Null
    Write-OK "git init complete"
}

# ── Git config (local, non-destructive) ───────────────────────────────────────

Write-Step "Configuring local git identity (if not already set)..."

$UserName  = git config --local user.name  2>$null
$UserEmail = git config --local user.email 2>$null

if (-not $UserName) {
    git config --local user.name "openclaw-backup"
    Write-OK "Set user.name = openclaw-backup"
} else {
    Write-OK "user.name already set: $UserName"
}

if (-not $UserEmail) {
    git config --local user.email "backup@localhost"
    Write-OK "Set user.email = backup@localhost"
} else {
    Write-OK "user.email already set: $UserEmail"
}

# ── .gitignore ────────────────────────────────────────────────────────────────

Write-Step "Creating .gitignore ..."

$GitignorePath = Join-Path $LocalDir ".gitignore"
$GitignoreContent = @"
# Temporary / OS files
Thumbs.db
desktop.ini
.DS_Store
*.tmp
*.log

# Sensitive -- never commit these
*.pem
*.key
*.p12
*.pfx
"@

if (-not (Test-Path $GitignorePath)) {
    Set-Content -Path $GitignorePath -Value $GitignoreContent -Encoding UTF8
    Write-OK ".gitignore created"
} else {
    Write-Warn ".gitignore already exists — not overwriting"
}

# ── Remote origin ─────────────────────────────────────────────────────────────

Write-Step "Configuring remote 'origin' ..."

$ExistingRemote = git remote get-url origin 2>$null
if ($ExistingRemote) {
    Write-Warn "Remote 'origin' already set — updating to new URL..."
    git remote set-url origin $RemoteURL
} else {
    git remote add origin $RemoteURL
}
Write-OK "Remote 'origin' -> $RepoOwner/$RepoName"

# ── Branch rename ─────────────────────────────────────────────────────────────

$CurrentBranch = git branch --show-current 2>$null
if ($CurrentBranch -and $CurrentBranch -ne $Branch) {
    Write-Step "Renaming branch '$CurrentBranch' -> '$Branch' ..."
    git branch -m $Branch
    Write-OK "Branch renamed"
}

# ── Initial commit + push ─────────────────────────────────────────────────────

Write-Step "Staging all files for initial commit ..."

git add --all
$Status = git status --porcelain
if (-not $Status) {
    Write-Warn "Nothing to commit. Directory may be empty."
} else {
    $Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    git commit -m "chore: initial backup [$Timestamp]"
    Write-OK "Committed: initial backup"
}

Write-Step "Pushing to GitHub ($Branch) ..."

git push --set-upstream origin $Branch

Write-Host "`n[DONE] Setup complete!" -ForegroundColor Green
Write-Host "  Repo : https://github.com/$RepoOwner/$RepoName" -ForegroundColor White
Write-Host "  Run backup-now.ps1 anytime to push future changes." -ForegroundColor White
