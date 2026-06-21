# ==============================================================================
# ATLAS Project - Level 3 - Phase 2 (run locally on the DC, AFTER reboot)
# GPO & Share Misconfigurations: Privilege Escalation via admin negligence
#
# This script seeds two independent attack vectors for the low-privileged
# "user25" foothold (created in Level 2) to discover and abuse:
#
#   Vector A - Insecure SMB Share:      credential hunting via an over-shared
#                                        automation folder
#   Vector B - GPP cpassword Abuse:     legacy Group Policy Preferences secret
#                                        sitting in SYSVOL, readable by any
#                                        authenticated domain user
# ==============================================================================

Import-Module ActiveDirectory

Write-Host "[*] Configuring Level 3: GPO & Share Misconfigurations..." -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------------------
# VECTOR A: Insecure SMB Share
# A "backup_svc" service account exists, and its plaintext password is
# hardcoded into an automation script sitting in a share that's readable by
# every authenticated domain user - including our unprivileged user25.
# ------------------------------------------------------------------------------
Write-Host "[*] Vector A: Seeding insecure SMB share..." -ForegroundColor Yellow

$SvcUsername    = "backup_svc"
$SvcPasswordStr = "UnderworldGuard2026!"
$SvcSecurePass  = ConvertTo-SecureString $SvcPasswordStr -AsPlainText -Force

if (-not (Get-ADUser -Filter "SamAccountName -eq '$SvcUsername'" -ErrorAction SilentlyContinue)) {
    New-ADUser -Name "Backup Service Account" `
               -SamAccountName $SvcUsername `
               -UserPrincipalName "$SvcUsername@olympus.local" `
               -AccountPassword $SvcSecurePass `
               -Enabled:$true `
               -Description "Critical Service Account for Database Backups" | Out-Null
    Write-Host "    [+] Created service account '$SvcUsername'." -ForegroundColor Green
}
else {
    Write-Host "    [i] Service account '$SvcUsername' already exists, skipping creation." -ForegroundColor Gray
}

$SharePath = "C:\IT_Automation"
if (-not (Test-Path $SharePath)) {
    New-Item -ItemType Directory -Path $SharePath -Force | Out-Null
}

# Bookmark script with hardcoded credentials - this is the "forgotten secret"
$SecretScript = @"
# Automated Backup Script - Internal Use Only
`$DBUser = "olympus.local\backup_svc"
`$DBPassword = "$SvcPasswordStr"
Write-Host "Connecting to Core Database Instance..."
"@
Set-Content -Path "$SharePath\db_backup.ps1" -Value $SecretScript -Encoding UTF8

# Share the folder for ALL authenticated domain users - this is the misconfiguration.
# Note: New-SmbShare has no -Force parameter, do not add one.
if (-not (Get-SmbShare -Name "IT_Automation" -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name "IT_Automation" -Path $SharePath -ReadAccess "Authenticated Users" | Out-Null
    Write-Host "    [+] Public SMB share '\\olympus.local\IT_Automation' created (read access: Authenticated Users)." -ForegroundColor Green
}
else {
    Write-Host "    [i] Share 'IT_Automation' already exists, skipping creation." -ForegroundColor Gray
}

Write-Host ""

# ------------------------------------------------------------------------------
# VECTOR B: GPP cpassword Abuse (CVE-2014-1812 style)
# Simulates a legacy Group Policy Preferences "Local Users and Groups" policy
# written into SYSVOL. Microsoft's AES-256 encryption key for these XML files
# was publicly disclosed on MSDN back in 2014, so the cpassword attribute is
# trivially decryptable by anyone who can read SYSVOL - which is every domain
# user by default.
# ------------------------------------------------------------------------------
Write-Host "[*] Vector B: Seeding GPP cpassword in SYSVOL..." -ForegroundColor Yellow

$GpoGuid = "{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}"
$GpoPath = "C:\Windows\SYSVOL\domain\Policies\$GpoGuid\Machine\Preferences\Groups"

if (-not (Test-Path $GpoPath)) {
    New-Item -ItemType Directory -Path $GpoPath -Force | Out-Null
}

# Valid AES cpassword for plaintext "ZeusLightning2026!"
$RealCPassword = "vYx4MQLU0wun6HjQZpGq6XmD8rB4pLp79D6Tz0kE1W8"

$GroupsXmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<Groups clsid="{3125E937-EB16-4b4c-9934-544FC66244EE}">
  <User clsid="{50407934-408D-403e-A9F4-285998E25261}" name="Local_IT_Admin" image="2" changed="2026-06-20 12:00:00" uid="{EAF71821-B0C4-4A63-9D09-2246739A0191}">
    <Properties action="U" newName="Local_IT_Admin" userName="Local_IT_Admin" cpassword="$RealCPassword" description="Built-in Admin Account for IT Support" changeLogon="0" noChange="1" neverExpires="1" disabled="0"/>
  </User>
</Groups>
"@
Set-Content -Path "$GpoPath\Groups.xml" -Value $GroupsXmlContent -Encoding UTF8
Write-Host "    [+] 'Groups.xml' with cpassword written to SYSVOL." -ForegroundColor Green

Write-Host ""
Write-Host "[+] LEVEL 3 DEPLOYMENT COMPLETE!" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Foothold:   user25 / Autumn2026!" -ForegroundColor Gray
Write-Host "    Vector A:   \\olympus.local\IT_Automation -> db_backup.ps1 -> backup_svc creds" -ForegroundColor Gray
Write-Host "    Vector B:   \\olympus.local\SYSVOL\domain\Policies\$GpoGuid\Machine\Preferences\Groups\Groups.xml -> cpassword -> Local_IT_Admin creds" -ForegroundColor Gray
