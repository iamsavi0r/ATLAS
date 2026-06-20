# ATLAS level-1

This lab provides a domain controller for Active Directory security testing.

## 🎯 Mission Briefing: The Mythological Leak

### The Scenario (Internal Access)
Welcome to your first day as a Junior Penetration Tester. Your team has successfully gained initial network access to an internal subnet of **Olympus Corp**. You have performed basic scanning and located the primary Domain Controller running at `10.0.0.4`. 

Through previous open-source intelligence (OSINT), you managed to acquire a text file containing valid internal domain usernames (`users.txt`). (which is in this directory) However, you do not have a single valid password yet. 

Your objective is to exploit misconfigurations in the **Kerberos authentication protocol** to harvest password hashes directly from the Domain Controller without needing any prior credentials. Internal chatter suggests two high-value service accounts are heavily misconfigured: `prometheus` and `hermes`.

### Objectives
1. **AS-REP Roasting (Target: prometheus):** Identify if any accounts have Kerberos Pre-Authentication disabled. Request an AS-REP ticket for the user `prometheus`, export the hash, and crack it offline.
2. **Kerberoasting (Target: hermes):** Use your newly acquired domain foothold to request a service ticket (TGS) for the registered Service Principal Name (SPN) associated with `hermes`. Extract the ticket and crack the service account's password offline.

### Success Criteria
You have successfully completed Level 1 when you have recovered the plaintext passwords for both the `prometheus` and `hermes` accounts using your cracking environment (e.g., Hashcat or John the Ripper). 

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
