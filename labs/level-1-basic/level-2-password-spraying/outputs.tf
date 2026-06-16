# ==============================================================================
# ATLAS Project - Level 2 (Outputs Configuration)
# Domain: olympus.local | Author: savi0r
# ==============================================================================

output "domain_controller_public_ip" {
  value       = azurerm_public_ip.dc_pip.ip_address
  description = "Публичный IP-адрес Контроллера Домена (ATLAS-LVL2-DC)"
}

output "client_pc_public_ip" {
  value       = azurerm_public_ip.client_pip.ip_address
  description = "Публичный IP-адрес рабочей станции сотрудника (ATLAS-LVL2-PC)"
}

output "lab_summary" {
  value = <<EOF

======================================================================
🚀 ATLAS LEVEL 2: SMART RECON & PASSWORD SPRAYING SUCCESSFULLY DEPLOYED!
======================================================================

Active Directory Domain: ${var.domain_name}
Domain Controller IP:   10.0.0.4 (Internal)
Client Workstation IP:  10.0.0.5 (Internal)

Credentials for Lab Management (RDP):
- Username: ${var.admin_username}
- Password: ${var.admin_password}

🎯 PENTEST OBJECTIVE:
1. Connect to the network or attack from your machine.
2. Perform Smart Reconnaissance to gather the list of 100+ domain users.
3. Execute a Password Spraying attack using common/seasonal passwords.
4. Find the vulnerable account without triggering account lockout policies!

======================================================================
EOF
  description = "Краткая сводка по лабе и боевая задача для студента"
}
