# compute.tf - виртуальные машины с оптимизированными ресурсами

# 1. BASTION HOST (минимальные ресурсы, только для SSH)
resource "yandex_compute_instance" "bastion" {
  name        = "bastion-host"
  description = "Bastion host for SSH access to internal servers"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"  # Ubuntu 22.04 LTS
      type     = "network-ssd"
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public-subnets["ru-central1-a"].id
    nat       = true
    ip_address = var.static_private_ips["bastion"]  # ← ЯВНЫЙ IP
    security_group_ids = [yandex_vpc_security_group.bastion-sg.id]
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_key}"
  }
}

# 2. WEB SERVER 1 (средние ресурсы, отдача статики)
resource "yandex_compute_instance" "web-server-1" {
  name        = "web-server-1"
  description = "First nginx web server"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      type     = "network-ssd"
      size     = 30
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private-subnets["ru-central1-a"].id
    nat       = false
    ip_address = var.static_private_ips["web-server-1"]  # ← ЯВНЫЙ IP
    security_group_ids = [yandex_vpc_security_group.web-servers-sg.id]
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_key}"
  }
}

# 3. WEB SERVER 2 (аналогично первому)
resource "yandex_compute_instance" "web-server-2" {
  name        = "web-server-2"
  description = "Second nginx web server"
  zone        = "ru-central1-b"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      type     = "network-ssd"
      size     = 30
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private-subnets["ru-central1-b"].id
    nat       = false
    ip_address = var.static_private_ips["web-server-2"]  # ← ЯВНЫЙ IP
    security_group_ids = [yandex_vpc_security_group.web-servers-sg.id]
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_key}"
  }
}

# 4. PROMETHEUS SERVER (больше памяти для метрик)
resource "yandex_compute_instance" "prometheus" {
  name        = "prometheus-server"
  description = "Prometheus monitoring server"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 50
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      type     = "network-ssd"
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private-subnets["ru-central1-a"].id
    nat       = false
    ip_address = var.static_private_ips["prometheus"]  # ← ЯВНЫЙ IP
    security_group_ids = [yandex_vpc_security_group.monitoring-sg.id]
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_key}"
  }
}

# 5. ELASTICSEARCH SERVER (больше ресурсов для логов)
resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch-server"
  description = "Elasticsearch for logs storage"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      type     = "network-ssd"
      size     = 30
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private-subnets["ru-central1-a"].id
    nat       = false
    ip_address = var.static_private_ips["elasticsearch"]  # ← ЯВНЫЙ IP
    security_group_ids = [yandex_vpc_security_group.elasticsearch-sg.id]
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_key}"
  }
}

# 6. GRAFANA SERVER (публичный доступ)
resource "yandex_compute_instance" "grafana" {
  name        = "grafana-server"
  description = "Grafana monitoring dashboard"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      type     = "network-ssd"
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public-subnets["ru-central1-a"].id
    nat       = true
    ip_address = var.static_private_ips["grafana"]  # ← ЯВНЫЙ IP
    security_group_ids = [yandex_vpc_security_group.grafana-sg.id]
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_key}"
  }
}

# 7. KIBANA SERVER (публичный доступ)
resource "yandex_compute_instance" "kibana" {
  name        = "kibana-server"
  description = "Kibana for logs visualization"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      type     = "network-ssd"
      size     = 30
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public-subnets["ru-central1-a"].id
    nat       = true
    ip_address = var.static_private_ips["kibana"]  # ← ЯВНЫЙ IP
    security_group_ids = [yandex_vpc_security_group.kibana-sg.id]
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_key}"
  }
}


#######

# Snapshot schedule for daily backups
resource "yandex_compute_snapshot_schedule" "daily-backup" {
  name = "daily-snapshot-schedule"

  schedule_policy {
    expression = "0 0 * * *"  # Каждый день в 00:00
  }

  retention_period = "168h"  # 7 дней (24*7)

  snapshot_spec {
    description = "Daily automatic backup"
    labels = {
      environment = "diploma"
      managed_by  = "terraform"
    }
  }

  disk_ids = [
    yandex_compute_instance.web-server-1.boot_disk.0.disk_id,
    yandex_compute_instance.web-server-2.boot_disk.0.disk_id,
    yandex_compute_instance.prometheus.boot_disk.0.disk_id,
    yandex_compute_instance.grafana.boot_disk.0.disk_id,
    yandex_compute_instance.elasticsearch.boot_disk.0.disk_id,
    yandex_compute_instance.kibana.boot_disk.0.disk_id,
    yandex_compute_instance.bastion.boot_disk.0.disk_id,
  ]
}
