# ATLAS Project: Olympus Lab

This lab provides a domain controller for Active Directory security testing.

## Status
The infrastructure is 90% automated with Terraform. To be honest, I hit a wall with cloud automation—sometimes the AD role installation hangs or acts up due to latency. I’m still working on a "perfect" fix, but for now, you might need to finish the last 10% of the setup manually. 

Don't worry, it's actually good practice: you'll see exactly how the DC is built from the inside.

## Deployment
1. Initialize and apply Terraform:
   terraform init
   terraform apply -auto-approve

2. If the domain isn't fully ready (like if the ports aren't open), just hop into the server and run the manual setup below. It’s a quick fix.

## Manual Setup
If you need to finish the config, connect to the DC via RDP or Enter-PSSession using your admin credentials and run these:

# 1. Install AD Domain Services
```
Import-Module ServerManager
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
$pass = ConvertTo-SecureString "HoldUpTheSky2026!" -AsPlainText -Force
Install-ADDSForest -DomainName "olympus.local" -SafeModeAdministratorPassword $pass -Force:$true
```

# 2. Create Users and Configure Kerberos (run after server reboot)
```
Import-Module ActiveDirectory
$p_pass = ConvertTo-SecureString "StealTheFire2026!" -AsPlainText -Force
$h_pass = ConvertTo-SecureString "MessengerOfGods123!" -AsPlainText -Force
New-ADUser -Name "Prometheus Titan" -SamAccountName "prometheus" -UserPrincipalName "prometheus@olympus.local" -AccountPassword $p_pass -Enabled:$true | Set-ADUser -Replace @{useraccountcontrol=4194304}
New-ADUser -Name "Hermes Service" -SamAccountName "hermes.svc" -UserPrincipalName "hermes.svc@olympus.local" -AccountPassword $h_pass -Enabled:$true | ForEach-Object { setspn -A MSSQLSvc/kronos.olympus.local:1433 $_.SamAccountName }

Restart-Service KDC -Force
```
