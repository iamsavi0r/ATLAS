# ATLAS Project: Olympus Lab

This lab environment provides a domain controller for Active Directory security testing (AS-REP Roasting, Kerberoasting).

## Status
The infrastructure is 90% automated using Terraform. However, due to occasional cloud provider latency during Active Directory role installation, some final configuration steps may require manual intervention via RDP/PSSession.

## Deployment
1. Initialize and apply Terraform:
   terraform init
   terraform apply -auto-approve

2. If the domain is not reachable, connect to the DC and finalize AD configuration manually:
   - Connect via RDP or Enter-PSSession using the admin credentials defined in main.tf.
   - Run the manual configuration commands listed in the "Manual Setup" section below.

## Manual Setup
If AD services are not active, run these commands inside the DC:

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
