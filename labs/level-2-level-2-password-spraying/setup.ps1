# Проверяем, установлен ли Active Directory
$ADInstalled = (Get-WindowsFeature -Name AD-Domain-Services).Installed

if ($ADInstalled -ne $true) {
    # ШАГ 1: Если AD нет, устанавливаем роль и поднимаем Лес домена
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    $pass = ConvertTo-SecureString "HoldUpTheSky2026!" -AsPlainText -Force
    
    # Эта команда поднимет домен и принудительно отправит сервер в перезагрузку
    Install-ADDSForest -DomainName "olympus.local" -SafeModeAdministratorPassword $pass -Force:$true
} else {
    # ШАГ 2: Мы вернулись после перезагрузки, домен уже работает
    # Ждем 45 секунд, пока поднимутся все внутренние службы NTDS/ADDS
    Start-Sleep -Seconds 45
    Import-Module ActiveDirectory
    
    # Наш цикл генерации 100 пользователей для Password Spraying
    for ($i = 1; $i -le 100; $i++) {
        $username = "user$i"
        
        # Генерируем сложный случайный пароль (GUID), который невозможно угадать
        $randomPassStr = [Guid]::NewGuid().ToString().Substring(0,12) + "A1!"
        
        # ЗАКЛАДКА: Юзерам 25 и 77 ставим слабый сезонный пароль
        if ($i -eq 25 -or $i -eq 77) {
            $randomPassStr = "Autumn2026!"
        }
        
        $securePass = ConvertTo-SecureString $randomPassStr -AsPlainText -Force
        
        # Создаем пользователя в Active Directory
        New-ADUser -Name "Lab User $i" -SamAccountName $username -UserPrincipalName "$username@olympus.local" -AccountPassword $securePass -Enabled:$true
    }
    
    # Финал: Удаляем задачу из Планировщика Windows, чтобы она не крутилась вечно при каждом включении
    Unregister-ScheduledTask -TaskName "ATLAS_AD_Setup" -Confirm:$false -ErrorAction SilentlyContinue
    
    # Самоликвидация скрипта с диска
    Remove-Item -Path "C:\setup.ps1" -Force
}
