# openclaw Backup

This repository is a mirror backup of `C:\Users\Administrator\.openclaw` on Windows.

## Quick Start

### Step 1 — Prerequisites

- [Git for Windows](https://git-scm.com/download/win) installed
- A GitHub [Personal Access Token (PAT)](https://github.com/settings/tokens/new)
  with **`repo`** scope (or an SSH key added to your GitHub account)

### Step 2 — One-time Setup (run once)

Copy `setup-backup.ps1` and `backup-now.ps1` into `C:\Users\Administrator\.openclaw\`,
then open **PowerShell as Administrator** and run:

```powershell
# Option A: HTTPS with a Personal Access Token
cd C:\Users\Administrator\.openclaw
.\setup-backup.ps1 -Token "ghp_xxxxxxxxxxxxxxxxxxxx"

# Option B: SSH (if you have an SSH key configured for GitHub)
cd C:\Users\Administrator\.openclaw
.\setup-backup.ps1 -UseSSH
```

This will:
- Initialize git in `C:\Users\Administrator\.openclaw`
- Create a `.gitignore` to exclude sensitive files
- Add `https://github.com/admeta1025-jpg/openclaw` as the remote
- Make the first commit and push

### Step 3 — Back Up Anytime

```powershell
cd C:\Users\Administrator\.openclaw
.\backup-now.ps1

# With an optional annotation:
.\backup-now.ps1 -Message "before reinstall"
```

## Automated Backups (Optional)

You can schedule `backup-now.ps1` to run automatically using Windows Task Scheduler.

### Using Task Scheduler (GUI)

1. Open **Task Scheduler** (`taskschd.msc`)
2. Click **Create Basic Task**
3. Name it `openclaw Backup`
4. Set trigger to **Daily** (or your preferred interval)
5. Action: **Start a program**
   - Program: `powershell.exe`
   - Arguments: `-NonInteractive -File "C:\Users\Administrator\.openclaw\backup-now.ps1"`
6. Finish

### Using Task Scheduler (PowerShell, one command)

```powershell
$Action  = New-ScheduledTaskAction -Execute "powershell.exe" `
             -Argument '-NonInteractive -File "C:\Users\Administrator\.openclaw\backup-now.ps1"'
$Trigger = New-ScheduledTaskTrigger -Daily -At "02:00AM"
Register-ScheduledTask -TaskName "openclaw Backup" -Action $Action -Trigger $Trigger -RunLevel Highest
```

## GitHub Actions: Backup Status

The workflow at `.github/workflows/backup.yml` provides:

| Feature | Details |
|---------|---------|
| Manual health check | Go to **Actions → Backup Status → Run workflow** |
| Weekly freshness alert | Runs every Monday; emails you if no backup in 7 days |

To view your last backup status: navigate to the [Actions tab](../../actions/workflows/backup.yml).

## File Structure

```
C:\Users\Administrator\.openclaw\   <- your data lives here
  setup-backup.ps1                  <- run once
  backup-now.ps1                    <- run anytime
  .gitignore                        <- created by setup-backup.ps1
  ... your other files ...
```

```
admeta1025-jpg/openclaw  (this repo)
  .github/
    workflows/
      backup.yml
  README.md
  setup-backup.ps1
  backup-now.ps1
```

## Security Notes

- **Never commit** `.pem`, `.key`, `.p12`, or `.pfx` files — the `.gitignore` blocks these.
- Your PAT is stored in the git remote URL inside `.git/config` on your Windows machine.
  That file is local-only and is **not** pushed to GitHub.
- If your PAT expires, run `setup-backup.ps1 -Token "new_token"` again — it will update
  the remote URL without re-initializing the repository.
- Consider using a PAT with **expiry** (e.g., 1 year) and the minimum required scope (`repo`).
