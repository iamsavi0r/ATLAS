# ==============================================================================
# ATLAS Project - Level 2 (Compute Configuration)
# Domain: olympus.local | Author: savi0r
# ==============================================================================

# 1. КОНТРОЛЛЕР ДОМЕНА (ATLAS-LVL2-DC)
resource "azurerm_windows_virtual_machine" "atlas_dc" {
  name                = "${var.project_name}-dc"
  resource_group_name = "${var.project_name}-rg"
  location            = var.location
  size                = var.vm_size_dc
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.dc_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-core-g2"
    version   = "latest"
  }

  # 🔥 МАГИЯ АВТОМАТИЗАЦИИ LEVEL 2: Настройка AD, создание 100+ юзеров и скрытой уязвимости
  user_data = base64encode(<<-EOF
    <powershell>
    Set-MpPreference -DisableRealtimeMonitoring $true
    $ScriptPath = "C:\atlas_lvl2_bootstrap.ps1"

    $BootstrapperCode = @"
    # Проверяем, настроен ли уже домен
    `$DomainCheck = Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty PartOfDomain
    if (`$DomainCheck -ne "${var.domain_name}") {
        # Шаг 1: Установка роли AD DS
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
        
        # Создаем задачу в планировщике, чтобы скрипт продолжил работу после перезагрузки
        `$Action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-ExecutionPolicy Bypass -File C:\atlas_lvl2_bootstrap.ps1"
        `$Trigger = New-ScheduledTaskTrigger -AtStartup
        `$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        `$Task = New-ScheduledTask -Action `$Action -Trigger `$Trigger -Principal `$Principal
        Register-ScheduledTask -TaskName "ATLAS_Lvl2_PostReboot" -InputObject `$Task -Force

        # Поднимаем Лес AD
        `$ADPassword = ConvertTo-SecureString "${var.admin_password}" -AsPlainText -Force
        Install-ADDSForest -DomainName "${var.domain_name}" -SafeModeAdministratorPassword `$ADPassword -Force:`$true
    } else {
        # Шаг 2: Домен готов, генерируем базу пользователей
        Start-Sleep -Seconds 45
        Import-Module ActiveDirectory

        # Массив имен для генерации 100+ реалистичных учетных записей (Формат: Имя.Фамилия)
        `$FirstNames = @("john","jane","alex","mary","david","linda","james","patricia","robert","barbara","michael","elizabeth","william","jennifer","david","maria","richard","susan","joseph","margaret")
        `$LastNames = @("smith","johnson","williams","brown","jones","garcia","miller","davis","rodriguez","martinez","hernandez","lopez","gonzalez","wilson","anderson","thomas","taylor","moore","jackson","martin")

        # Дефолтный сложный пароль для обычных юзеров, который никто не угадает брутом
        `$DefaultPass = ConvertTo-SecureString "Secure_Default_AD_Pass_2026!" -AsPlainText -Force

        # Циклом создаем около 100+ уникальных учетных записей
        foreach (`$first in `$FirstNames) {
            foreach (`$last in `$LastNames) {
                `$samAccount = "`$first.`$last"
                `$upn = "`$samAccount@${var.domain_name}"
                `$name = "`$first `$last"
                
                # Защита от дубликатов (создаем, если такого нет)
                if (-not (Get-ADUser -Filter "SamAccountName -eq '`$samAccount'")) {
                    New-ADUser -Name `$name -SamAccountName `$samAccount -UserPrincipalName `$upn -AccountPassword `$DefaultPass -Enabled `$true
                }
            }
        }

        # Наш "слабый элемент" — пользователь, попавшийся на Password Spraying
        # Даем ему сезонный пароль, который студент сможет угадать перебором
        `$TargetUser = "harrison.wells"
        `$TargetPass = ConvertTo-SecureString "Autumn2026!" -AsPlainText -Force
        
        New-ADUser -Name "Harrison Wells" -SamAccountName `$TargetUser -UserPrincipalName "`$TargetUser@${var.domain_name}" -AccountPassword `$TargetPass -Enabled `$true

        # Подчищаем за собой следы автоматизации
        Unregister-ScheduledTask -TaskName "ATLAS_Lvl2_PostReboot" -Confirm:`$false
        Remove-Item -Path "C:\atlas_lvl2_bootstrap.ps1" -Force
    }
    "@

    Set-Content -Path $ScriptPath -Value $BootstrapperCode
    powershell -ExecutionPolicy Bypass -File $ScriptPath
    </powershell>
  EOF
  )
}

# 2. РАБОЧАЯ СТАНЦИЯ СОТРУДНИКА (ATLAS-LVL2-PC)
resource "azurerm_windows_virtual_machine" "atlas_client" {
  name                = "${var.project_name}-pc"
  resource_group_name = "${var.project_name}-rg"
  location            = var.location
  size                = var.vm_size_client
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.client_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # Экономим бюджет, берем обычный HDD/SSD для клиента
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-23h2-pro" # Полноценная Windows 11 Pro для имитации рабочего места
    version   = "latest"
  }

  # Для экономии оперативки на клиенте (всего 2 ГБ) мы просто выключаем защитник при старте
  user_data = base64encode(<<-EOF
    <powershell>
    Set-MpPreference -DisableRealtimeMonitoring $true
    </powershell>
  EOF
  )
}
