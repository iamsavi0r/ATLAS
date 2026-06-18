# 1. Отключаем всё лишнее
Set-MpPreference -DisableRealtimeMonitoring $true
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# 2. Установка AD (если еще не стоит)
if (!(Get-WindowsFeature -Name AD-Domain-Services).Installed) {
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    $pass = ConvertTo-SecureString "HoldUpTheSky2026!" -AsPlainText -Force
    Install-ADDSForest -DomainName "olympus.local" -SafeModeAdministratorPassword $pass -Force:$true
    # Ребут обязателен после установки леса
    Restart-Computer -Force
}

Start-Sleep -Seconds 120

# Принудительно запускаем Kerberos Key Distribution Center
$kdc = Get-Service -Name "KDC"
if ($kdc.Status -ne 'Running') {
    Start-Service -Name "KDC"
}
Set-Service -Name "KDC" -StartupType Automatic

# 4. Создаем уязвимых пользователей
Import-Module ActiveDirectory
$p_pass = ConvertTo-SecureString "StealTheFire2026!" -AsPlainText -Force
if (!(Get-ADUser -Filter "SamAccountName -eq 'prometheus'")) {
    New-ADUser -Name "Prometheus Titan" -SamAccountName "prometheus" -UserPrincipalName "prometheus@olympus.local" -AccountPassword $p_pass -Enabled:$true
    Set-ADUser -Identity "prometheus" -Replace @{useraccountcontrol=4194304}
}

$h_pass = ConvertTo-SecureString "MessengerOfGods123!" -AsPlainText -Force
if (!(Get-ADUser -Filter "SamAccountName -eq 'hermes.svc'")) {
    New-ADUser -Name "Hermes Service" -SamAccountName "hermes.svc" -UserPrincipalName "hermes.svc@olympus.local" -AccountPassword $h_pass -Enabled:$true
    setspn -A MSSQLSvc/kronos.olympus.local:1433 hermes.svc
}
