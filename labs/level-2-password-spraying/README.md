# ATLAS Project: Olympus Lab

This lab provides a domain controller for Active Directory security testing.

## Status

The lab runs on a Windows 11 workstation with RDP access to a Server Core domain controller (no GUI). Honestly, this part isn't automated yet — you'll be setting up AD by hand, step by step. Not glamorous, but it does mean you actually see how the DC gets built instead of trusting a script you never read.

The steps below cover connecting, standing up the AD forest, and seeding the domain with test users — including the intentional Password Spraying weakness used in this exercise. Yeah, the weak passwords are deliberate — that's kind of the whole point of the lab.

## Step 1. Connect to the Domain Controller

From the Windows 11 workstation, connect via RDP, open PowerShell as Administrator, and open a remote session to the Server Core DC:

```
$cred = Get-Credential -UserName "atlas_admin" -Message "Enter DC Password"
Enter-PSSession -ComputerName 10.0.0.4 -Credential $cred
```

(Password: `HoldUpTheSky2026!`)

## Step 2. Stand Up the Active Directory Role

From inside that session, install the AD role and create the `olympus.local` forest:

```
# Install the directory role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Create the new forest (will prompt for a Safe Mode password — reuse the same one)
$pass = ConvertTo-SecureString "HoldUpTheSky2026!" -AsPlainText -Force
Install-ADDSForest -DomainName "olympus.local" -SafeModeAdministratorPassword $pass -Force:$true
```

> ⚠️ **Heads up:** This command kicks off a reboot on the DC automatically. Just sit tight for 3–5 minutes while domain services come back up — don't try to reconnect too early, you'll just get connection errors and waste time.

## Step 3. Load the User-Generation Script

Once the server is back up, reconnect with `Enter-PSSession` (see Step 1) and run the following script. It creates 100 lab users and seeds the intentional Password Spraying vulnerability:

```
Import-Module ActiveDirectory

for ($i = 1; $i -le 100; $i++) {
    $username = "user$i"

    # Random password for most users
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

Write-Host "[+] 100 Users successfully created in olympus.local!" -ForegroundColor Green
```

That's it — once the script finishes, you've got a working domain with 100 users, two of which (`user25` and `user77`) share the same predictable password. Go find them.
