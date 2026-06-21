# ==============================================================================
# ATLAS Project - Level 3 - Phase 1 (run locally on the DC, BEFORE reboot)
# ==============================================================================
Import-Module ServerManager

Write-Host "[*] Installing AD DS role..." -ForegroundColor Cyan
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools | Out-Null

$pass = ConvertTo-SecureString "HoldUpTheSky2026!" -AsPlainText -Force

Write-Host "[*] Deploying olympus.local forest (this server will reboot automatically)..." -ForegroundColor Yellow
Install-ADDSForest `
    -DomainName "olympus.local" `
    -DomainNetbiosName "OLYMPUS" `
    -SafeModeAdministratorPassword $pass `
    -Force:$true

# Note: you will NOT see this message, the reboot happens before the script can print it.
# That's expected - just wait 3-5 minutes, then RDP back in and run phase2.ps1.
