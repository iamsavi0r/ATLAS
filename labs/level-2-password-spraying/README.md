# ATLAS  level-2

This lab builds on the Level 1 domain controller, adding a fuller user base and a couple of quality-of-life tweaks so the environment behaves predictably during testing.

## 🎯 Mission Briefing: Initial Foothold

### The Scenario (OSINT & Leak)
During the external reconnaissance phase, you analyzed the target's public-facing infrastructure and social media footprints. You discovered a leaked message from an IT support group chat welcoming new interns for the current season. The message explicitly states:
> *"Welcome to the team! All temporary intern accounts have been provisioned. Your temporary password for the initial login is **Autumn2026!**. Please change it as soon as you access your workspace."*

Your job as a Red Teamer/Penetration Tester is to exploit this operational security (OpSec) failure.

### Objectives
1. **Enumerate Target Logins:** Use the generated `users.txt` file (which simulates the employee username list you gathered during OSINT).
2. **Execute Password Spraying:** Launch a password spraying attack using the single discovered password (`Autumn2026!`) across all 100 users. 
3. **Establish a Foothold:** Identify which lazy accounts failed to change their default credentials and use those valid domain tokens to gain your first legitimate access inside the `olympus.local` network.


## Status
Same deal as Level 1 - the domain stand-up is mostly hands-on right now. There are two phases here because the server has to reboot in between (installing the AD role forces a restart, no way around that). Just follow the steps in order and you'll be fine.
One honest note!!: the setup script below disables Windows Defender real-time monitoring and turns off the firewall on all profiles. That's only acceptable because this is an isolated lab DC - never do that on anything connected to a real network or production environment.

## Step 1. Deploy Active Directory (before the reboot)

On a DC Windows Server, open PowerShell as Administrator and run:

```
# 1. Import the server management module
Import-Module ServerManager

# 2. Install the AD DS role and management tools
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# 3. Prepare the DSRM recovery password
$pass = ConvertTo-SecureString "HoldUpTheSky2026!" -AsPlainText -Force

# 4. Create the new forest and domain (this triggers an automatic reboot)
Install-ADDSForest `
    -DomainName "olympus.local" `
    -DomainNetbiosName "OLYMPUS" `
    -SafeModeAdministratorPassword $pass `
    -Force:$true
```

> ⚠️ **Heads up:** the server reboots on its own right after this. Don't try to reconnect immediately - give it a few minutes to come all the way back up first.

## Step 2. Configure the Environment and Create 100 Users (after the reboot)

Once the server is back up, log in as the domain admin (`OLYMPUS\atlas_admin`), open PowerShell as Administrator, and run the block below. It writes a clean script to disk, runs it, and exports the results:

```
# 1. Build the lab generation script
$scriptContent = @'
Import-Module ActiveDirectory

# Disable Defender / firewall for lab convenience (isolated DC only — never do this elsewhere)
Set-MpPreference -DisableRealtimeMonitoring $true
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

Write-Host "[*] Domain active! Generating 100 users..." -ForegroundColor Cyan

for ($i = 1; $i -le 100; $i++) {
    $username = "user$i"

    # Random complex password by default
    $randomPassStr = [Guid]::NewGuid().ToString().Substring(0,12) + "A1!"

    # Seeded weak passwords for Password Spraying (users 25 and 77)
    if ($i -eq 25 -or $i -eq 77) {
        $randomPassStr = "Autumn2026!"
    }

    $securePass = ConvertTo-SecureString $randomPassStr -AsPlainText -Force

    New-ADUser -Name "Lab User $i" `
               -SamAccountName $username `
               -UserPrincipalName "$username@olympus.local" `
               -AccountPassword $securePass `
               -Enabled:$true
}

# Restart Kerberos so the ticket database picks up the new accounts
Restart-Service KDC -Force
Write-Host "[+] Success! 100 users created in olympus.local." -ForegroundColor Green
'@

# 2. Write the script to disk
Set-Content -Path .\users.ps1 -Value $scriptContent -Encoding UTF8

# 3. Run it
.\users.ps1

# 4. Export the usernames to users.txt for attack tooling
Get-ADUser -Filter "Name -like 'Lab User*'" | Select-Object -ExpandProperty SamAccountName | Out-File -FilePath .\users.txt -Encoding ascii

# 5. Sanity check — confirm the account count
Write-Host "[*] Checking AD database. Total lab users created:" -ForegroundColor Yellow
(Get-ADUser -Filter "Name -like 'Lab User*'").Count
```

## What you end up with

A working `olympus.local` domain, 100 lab users. That's your Password Spraying target.

If something doesn't look right (DC unresponsive, fewer than 100 users, `users.txt` missing), just re-run Step 2 from a fresh session — it's idempotent enough for lab purposes.
