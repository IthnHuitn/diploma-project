# Основные переменные облака
variable "yandex_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  sensitive   = true
}

variable "yandex_folder_id" {
  description = "Yandex Folder ID"
  type        = string
  sensitive   = true
}

variable "yandex_zone" {
  description = "Yandex Cloud default zone"
  type        = string
  default     = "ru-central1-a"
}

variable "yandex_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
}

# Переменные для различных зон
variable "zones" {
  description = "Yandex Cloud zones for distribution"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b"]
}

# Переменные для ресурсов
variable "vm_username" {
  description = "Username for VM access"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# CIDR для сетей
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.0.1.0/24"
    "ru-central1-b" = "10.0.2.0/24"
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.0.10.0/24"
    "ru-central1-b" = "10.0.20.0/24"
  }
}

# Постоянные приватные IP-адреса для Ansible
variable "static_private_ips" {
  description = "Static private IP addresses for all VMs"
  type        = map(string)
  default = {
    # Публичные подсети (10.0.1.0/24, 10.0.2.0/24)
    "bastion"  = "10.0.1.10"    # ru-central1-a
    "grafana"  = "10.0.1.20"    # ru-central1-a
    "kibana"   = "10.0.1.30"    # ru-central1-a
    
    # Приватные подсети зона A (10.0.10.0/24)
    "web-server-1"   = "10.0.10.10"
    "prometheus"     = "10.0.10.20"
    "elasticsearch"  = "10.0.10.30"
    
    # Приватные подсети зона B (10.0.20.0/24)
    "web-server-2"   = "10.0.20.10"
  }
}

# SSH ключ из terraform.tfvars
variable "ssh_key" {
  description = "SSH public key for instances"
  type        = string
  sensitive   = true
}
