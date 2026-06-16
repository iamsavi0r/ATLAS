# ==============================================================================
# ATLAS Project - Level 2 (Variables Configuration)
# Domain: olympus.local | Author: savi0r
# ==============================================================================

variable "project_name" {
  type        = string
  default     = "atlas-lvl2"
  description = "Префикс для именования всех ресурсов этой лабораторной работы"
}

variable "location" {
  type        = string
  default     = "South Africa North" # Твой регион из проверенного конфига MVP
  description = "Регион Azure, где будет развернута инфраструктура ATLAS"
}

variable "domain_name" {
  type        = string
  default     = "olympus.local"
  description = "Имя поднимаемого домена Active Directory"
}

variable "admin_username" {
  type        = string
  default     = "atlas_admin"
  description = "Локальный администратор виртуалки (до настройки AD)"
}

variable "admin_password" {
  type        = string
  default     = "HoldUpTheSky2026!" # Твой сложный пароль из первого уровня
  description = "Пароль для учетной записи администратора"
}

variable "vm_size_dc" {
  type        = string
  default     = "Standard_B2as_v2" # Твой размер из MVP: 2 vCPU / 8 GiB RAM
  description = "Размер виртуалки для Контроллера Домена (Server Core)"
}

variable "vm_size_client" {
  type        = string
  default     = "Standard_B1ms" # Оставляем легкую плашку (1 vCPU / 2 GiB RAM) для экономии ресурсов
  description = "Размер виртуалки для клиентской рабочей станции"
}

variable "allowed_ip" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Белый IP-адрес студента, которому разрешено подключаться к лабе"
}
