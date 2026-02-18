# Домашнее задание к занятию "`Курсовая работа на профессии "DevOps-инженер с нуля"`" - `Ефимов Вячеслав`


### Инструкция по выполнению домашнего задания

   1. Сделайте `fork` данного репозитория к себе в Github и переименуйте его по названию или номеру занятия, например, https://github.com/имя-вашего-репозитория/git-hw или  https://github.com/имя-вашего-репозитория/7-1-ansible-hw).
   2. Выполните клонирование данного репозитория к себе на ПК с помощью команды `git clone`.
   3. Выполните домашнее задание и заполните у себя локально этот файл README.md:
      - впишите вверху название занятия и вашу фамилию и имя
      - в каждом задании добавьте решение в требуемом виде (текст/код/скриншоты/ссылка)
      - для корректного добавления скриншотов воспользуйтесь [инструкцией "Как вставить скриншот в шаблон с решением](https://github.com/netology-code/sys-pattern-homework/blob/main/screen-instruction.md)
      - при оформлении используйте возможности языка разметки md (коротко об этом можно посмотреть в [инструкции  по MarkDown](https://github.com/netology-code/sys-pattern-homework/blob/main/md-instruction.md))
   4. После завершения работы над домашним заданием сделайте коммит (`git commit -m "comment"`) и отправьте его на Github (`git push origin`);
   5. Для проверки домашнего задания преподавателем в личном кабинете прикрепите и отправьте ссылку на решение в виде md-файла в вашем Github.
   6. Любые вопросы по выполнению заданий спрашивайте в чате учебной группы и/или в разделе “Вопросы по заданию” в личном кабинете.
   
Желаем успехов в выполнении домашнего задания!
   
### Дополнительные материалы, которые могут быть полезны для выполнения задания

1. [Руководство по оформлению Markdown файлов](https://gist.github.com/Jekins/2bf2d0638163f1294637#Code)

---

## 1.1 Схема инфраструктуры


```text
┌─────────────────────────────────────────────────────────────────┐
│                         Yandex Cloud                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Публичная подсеть (10.0.1.0/24)    Публичная подсеть (10.0.2.0/24)
│  ┌────────────────────────────┐    ┌──────────────────────────┐
│  │ Bastion: 10.0.1.10         │    │                          │
│  │ Grafana: 10.0.1.20         │    │                          │
│  │ Kibana:  10.0.1.30         │    │                          │
│  └────────────────────────────┘    └──────────────────────────┘
│                                                                  │
│  Приватная подсеть (10.0.10.0/24)  Приватная подсеть (10.0.20.0/24)
│  ┌────────────────────────────┐    ┌──────────────────────────┐
│  │ Web-1:    10.0.10.10       │    │ Web-2:    10.0.20.10     │
│  │ Prometheus:10.0.10.20      │    │                          │
│  │ Elastic:   10.0.10.30      │    │                          │
│  └────────────────────────────┘    └──────────────────────────┘
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Application Load Balancer: 158.160.221.213              │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```
![diploma-network1](https://github.com/IthnHuitn/diploma-project/blob/main/screens/diploma-network1.jpg)
![diploma-network2](https://github.com/IthnHuitn/diploma-project/blob/main/screens/diploma-network2.jpg)
![diploma-network3](https://github.com/IthnHuitn/diploma-project/blob/main/screens/diploma-network3.jpg)
![diploma-network4](https://github.com/IthnHuitn/diploma-project/blob/main/screens/diploma-network4.jpg)
![loadbalancer](https://github.com/IthnHuitn/diploma-project/blob/main/screens/loadbalancer.jpg)

## 1.2 Компоненты инфраструктуры

```text
Компонент	Назначение	IP адрес	Доступ
Bastion	SSH-доступ к внутренним ресурсам	10.0.1.10 (pub: 93.77.190.81)	SSH только по ключу
Web-сервер 1	Nginx	10.0.10.10	Через bastion
Web-сервер 2	Nginx	10.0.20.10	Через bastion
Application LB	Балансировщик	158.160.221.213	Публичный HTTP
Prometheus	Сбор метрик	10.0.10.20	Через bastion
Grafana	Визуализация	10.0.1.20 (pub: 51.250.7.12)	HTTP:3000
Elasticsearch	Хранение логов	10.0.10.30	Через bastion
Kibana	Просмотр логов	10.0.1.30 (pub: 93.77.189.209)	HTTP:5601
```
![VM](https://github.com/IthnHuitn/diploma-project/blob/main/screens/VM.jpg)

## 2.1 Terraform код

```hcl
# Основные компоненты:
- Создание VPC и подсетей
- Security Groups с принципом минимальных привилегий
- Создание ВМ с статическими приватными IP
- Настройка Application Load Balancer
```
#### netwqork.tf
```hcl
# Создание VPC
resource "yandex_vpc_network" "diploma-vpc" {
  name        = "diploma-network"
  description = "VPC for diploma project infrastructure"
}

# Создание публичных подсетей с прямой привязкой route_table_id
resource "yandex_vpc_subnet" "public-subnets" {
  for_each = var.public_subnet_cidrs

  name           = "public-subnet-${each.key}"
  description    = "Public subnet in ${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.diploma-vpc.id
  v4_cidr_blocks = [each.value]
  route_table_id = yandex_vpc_route_table.public-route-table.id  # ← Прямо здесь
}

# Создание приватных подсетей с прямой привязкой route_table_id
resource "yandex_vpc_subnet" "private-subnets" {
  for_each = var.private_subnet_cidrs

  name           = "private-subnet-${each.key}"
  description    = "Private subnet in ${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.diploma-vpc.id
  v4_cidr_blocks = [each.value]
  route_table_id = yandex_vpc_route_table.private-route-table.id  # ← Прямо здесь
}

# Таблица маршрутизации для приватных подсетей
resource "yandex_vpc_route_table" "private-route-table" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.diploma-vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat-gateway.id
  }
}

# Таблица маршрутизации для публичных подсетей
resource "yandex_vpc_route_table" "public-route-table" {
  name       = "public-route-table"
  network_id = yandex_vpc_network.diploma-vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat-gateway.id
  }
}

# NAT Gateway для выхода в интернет из приватных сетей
resource "yandex_vpc_gateway" "nat-gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}
```
#### secutiy_groups.tf
```hcl
# Security Group для Bastion хоста 
resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "bastion-security-group"
  description = "Security group for Bastion host with SSH access"
  network_id  = yandex_vpc_network.diploma-vpc.id

  ingress {
    protocol       = "TCP"
    description    = "SSH from my home IP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    description    = "SSH to internal networks"
    port           = 22
    v4_cidr_blocks = ["10.0.0.0/8"]
  }
  
  egress {
    protocol       = "UDP"
    description    = "DNS requests"
    port           = 53
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    protocol       = "ICMP"
    description    = "ICMP for connectivity checks"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    protocol       = "TCP"
    description    = "HTTP for package updates"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    description    = "HTTPS for package updates"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Internet access"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Security Group для веб-серверов
resource "yandex_vpc_security_group" "web-servers-sg" {
  name        = "web-servers-security-group"
  description = "Security group for web servers"
  network_id  = yandex_vpc_network.diploma-vpc.id

  # HTTP от балансировщика
  ingress {
    protocol       = "TCP"
    description    = "HTTP from Load Balancer"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]  
  }

  # SSH только из Bastion по IP с /32
  ingress {
    protocol       = "TCP"
    description    = "SSH from Bastion"
    port           = 22
    v4_cidr_blocks = ["${var.static_private_ips["bastion"]}/32"] 
  }

  # Node Exporter для мониторинга по IP с /32
  ingress {
    protocol       = "TCP"
    description    = "Node Exporter from Prometheus"
    port           = 9100
    v4_cidr_blocks = ["${var.static_private_ips["prometheus"]}/32"] 
  }

  # Filebeat для логов по IP с /32
  egress {
    protocol       = "TCP"
    description    = "Filebeat to Elasticsearch"
    port           = 9200
    v4_cidr_blocks = ["${var.static_private_ips["elasticsearch"]}/32"]  
  }

  egress {
    protocol       = "ANY"
    description    = "OUT from any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Security Group для балансировщика 
resource "yandex_vpc_security_group" "alb-healthcheck-sg" {
  name        = "alb-healthcheck-sg"
  description = "Security group for ALB health checks"
  network_id  = yandex_vpc_network.diploma-vpc.id

  # 1. Разрешаем health checks от Yandex Cloud
  ingress {
    protocol       = "TCP"
    description    = "Health checks from Yandex Cloud"
    port           = 80
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"] 
  }

  # 2. Разрешаем health checks от балансировщика к веб-серверам
  egress {
    protocol       = "ANY"                #####
    description    = "Health checks to web servers"
    v4_cidr_blocks = [
      "${var.static_private_ips["web-server-1"]}/32",
      "${var.static_private_ips["web-server-2"]}/32"
    ]
    from_port	= 0		#####
    to_port		= 65535		#####
  }

  # 3. Разрешаем входящий HTTP трафик из интернета
  ingress {
    protocol       = "TCP"
    description    = "HTTP from Internet"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # 4. Разрешаем исходящий трафик для health checks и ответов
  egress {
    protocol       = "ANY"
    description    = "Internet access"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Prometheus 
resource "yandex_vpc_security_group" "monitoring-sg" {
  name        = "monitoring-security-group"
  description = "Security group for monitoring services"
  network_id  = yandex_vpc_network.diploma-vpc.id

  # SSH только из Bastion по IP с /32
  ingress {
    protocol       = "TCP"
    description    = "SSH from Bastion"
    port           = 22
    v4_cidr_blocks = ["${var.static_private_ips["bastion"]}/32"]  
  }

  # Prometheus UI доступен только изнутри
  ingress {
    protocol       = "TCP"
    description    = "Prometheus UI from internal network"
    port           = 9090
    v4_cidr_blocks = ["10.0.0.0/8"]
  }

  # Разрешаем сбор метрик 
  egress {
    protocol       = "TCP"
    description    = "Metrics collection"
    port           = 9100
    v4_cidr_blocks = [
      "${var.static_private_ips["web-server-1"]}/32",
      "${var.static_private_ips["web-server-2"]}/32",
      "${var.static_private_ips["bastion"]}/32",
      "${var.static_private_ips["grafana"]}/32",
      "${var.static_private_ips["kibana"]}/32",
      "${var.static_private_ips["elasticsearch"]}/32"
    ]
  }

  # Исходящий интернет для обновлений
  egress {
    protocol       = "ANY"
    description    = "Internet access"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Elasticsearch 
resource "yandex_vpc_security_group" "elasticsearch-sg" {
  name        = "elasticsearch-security-group"
  description = "Security group for Elasticsearch"
  network_id  = yandex_vpc_network.diploma-vpc.id

  # Elasticsearch REST API только изнутри
  ingress {
    protocol       = "TCP"
    description    = "Elasticsearch API from internal network"
    port           = 9200
    v4_cidr_blocks = ["10.0.0.0/8"]
  }
  ####
  ingress {
    protocol       = "TCP"
    description    = "Node Exporter from Prometheus"
    port           = 9100
    v4_cidr_blocks = ["10.0.10.20/32"]  # IP Prometheus
  }

  # SSH только из Bastion по IP 
  ingress {
    protocol       = "TCP"
    description    = "SSH from Bastion"
    port           = 22
    v4_cidr_blocks = ["${var.static_private_ips["bastion"]}/32"]  
  }

  egress {
    protocol       = "ANY"
    description    = "Internet access"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Grafana 
resource "yandex_vpc_security_group" "grafana-sg" {
  name        = "grafana-security-group"
  description = "Security group for Grafana"
  network_id  = yandex_vpc_network.diploma-vpc.id

  # Grafana UI из интернета
  ingress {
    protocol       = "TCP"
    description    = "Grafana UI from Internet"
    port           = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH только из Bastion по IP 
  ingress {
    protocol       = "TCP"
    description    = "SSH from Bastion"
    port           = 22
    v4_cidr_blocks = ["${var.static_private_ips["bastion"]}/32"] 
  }

  ####
  ingress {
    protocol       = "TCP"
    description    = "Node Exporter from Prometheus"
    port           = 9100
    v4_cidr_blocks = ["${var.static_private_ips["prometheus"]}/32"] 
  }

  # Исходящий доступ к Prometheus по IP 
  egress {
    protocol       = "TCP"
    description    = "Access to Prometheus"
    port           = 9090
    v4_cidr_blocks = ["${var.static_private_ips["prometheus"]}/32"] 
  }

  egress {
    protocol       = "ANY"
    description    = "Internet access"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Kibana 
resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana-security-group"
  description = "Security group for Kibana"
  network_id  = yandex_vpc_network.diploma-vpc.id

  # Kibana UI из интернета
  ingress {
    protocol       = "TCP"
    description    = "Kibana UI from Internet"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

 ####
  ingress {
    protocol       = "TCP"
    description    = "Node Exporter from Prometheus"
    port           = 9100
    v4_cidr_blocks = ["${var.static_private_ips["prometheus"]}/32"]  # 10.0.10.20/32
  }
 
  # SSH только из Bastion по IP 
  ingress {
    protocol       = "TCP"
    description    = "SSH from Bastion"
    port           = 22
    v4_cidr_blocks = ["${var.static_private_ips["bastion"]}/32"] 
  }

  # Исходящий доступ к Elasticsearch по IP 
  egress {
    protocol       = "TCP"
    description    = "Access to Elasticsearch"
    port           = 9200
    v4_cidr_blocks = ["${var.static_private_ips["elasticsearch"]}/32"] 
  }

  egress {
    protocol       = "ANY"
    description    = "Internet access"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
```
#### compute.tf
```hcl
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
```
#### loadbalancer.tf
```hcl
# loadbalancer.tf - Application Load Balancer для веб-серверов

# 1. Target Group - группа целевых серверов с явными IP
resource "yandex_alb_target_group" "web-target-group" {
  name = "web-target-group"

  target {
    subnet_id  = yandex_vpc_subnet.private-subnets["ru-central1-a"].id
    ip_address = var.static_private_ips["web-server-1"]  # ← СТАТИЧЕСКИЙ IP
  }

  target {
    subnet_id  = yandex_vpc_subnet.private-subnets["ru-central1-b"].id
    ip_address = var.static_private_ips["web-server-2"]  # ← СТАТИЧЕСКИЙ IP
  }
}

# 2. Backend Group - настройка бэкендов
resource "yandex_alb_backend_group" "web-backend-group" {
  name = "web-backend-group"

  http_backend {
    name             = "web-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web-target-group.id]

    healthcheck {
      timeout  = "1s"
      interval = "2s"
      healthy_threshold   = 2
      unhealthy_threshold = 3

      http_healthcheck {
        path = "/"
      }
    }
  }
}

# 3. HTTP Router - маршрутизатор
resource "yandex_alb_http_router" "web-router" {
  name = "web-router"
}

# 4. Virtual Host + Route
resource "yandex_alb_virtual_host" "web-virtual-host" {
  name           = "web-virtual-host"
  http_router_id = yandex_alb_http_router.web-router.id

  route {
    name = "web-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web-backend-group.id
        timeout          = "3s"
      }
    }
  }
}

# 5. Application Load Balancer
resource "yandex_alb_load_balancer" "web-balancer" {
  name               = "web-balancer"
  network_id         = yandex_vpc_network.diploma-vpc.id
 ##### security_group_ids = [yandex_vpc_security_group.alb-healthcheck-sg.id] 

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public-subnets["ru-central1-a"].id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.public-subnets["ru-central1-b"].id
    }
  }

  listener {
    name = "web-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web-router.id
      }
    }
  }
}

# Outputs для балансировщика
output "load_balancer_ip" {
  description = "Public IP address of Load Balancer"
  value       = try(yandex_alb_load_balancer.web-balancer.listener[0].endpoint[0].address[0].external_ipv4_address[0].address, "not created yet")
}

output "load_balancer_url" {
  description = "URL for accessing the website"
  value       = "http://${try(yandex_alb_load_balancer.web-balancer.listener[0].endpoint[0].address[0].external_ipv4_address[0].address, "not_available")}"
}

output "target_group_info" {
  description = "Target group information"
  value = {
    name        = yandex_alb_target_group.web-target-group.name
    target_ips  = [
      var.static_private_ips["web-server-1"],
      var.static_private_ips["web-server-2"]
    ]
  }
}
```


## 2.2 Ansible плейбуки

```yaml
Роли:
- common: базовая настройка ОС
- nginx: установка и конфигурация веб-сервера
- node_exporter: сбор метрик для Prometheus
- filebeat: отправка логов в Elasticsearch
- prometheus: сбор и хранение метрик
- grafana: визуализация метрик
- elasticsearch: хранение логов
- kibana: просмотр логов
```
[Ansible](https://github.com/IthnHuitn/diploma-project/tree/main/ansible)

## 3.1 Доступные ресурсы

Веб-сайт через балансировщик

```bash
curl -v 158.160.221.213:80
```
![Balancer_Console](https://github.com/IthnHuitn/diploma-project/blob/main/screens/Balancer_Console.jpg)
![Balancer_Inet](https://github.com/IthnHuitn/diploma-project/blob/main/screens/Balancer_Inet.jpg)


### Grafana

```text
URL: http://51.250.7.12:3000
Login: admin
Password: admin
```
![Grafana_Inet](https://github.com/IthnHuitn/diploma-project/blob/main/screens/Grafana_Inet.jpg)

### Kibana

```text
URL: http://93.77.189.209:5601
```
![Kibana_Inet](https://github.com/IthnHuitn/diploma-project/blob/main/screens/Kibana_Inet.jpg)

## 3.2 Проверка работы компонентов

```bash
yc application-load-balancer target-group get ds7nf5lis2n96kjus6nu
```
![Balancer_Nods](https://github.com/IthnHuitn/diploma-project/blob/main/screens/Balancer_Nods.jpg)

### Сбор метрик Prometheus

```bash
curl -s -X GET "http://10.0.10.20:9090/api/v1/targets" | jq '.'
```
![Prometeus_metrics](https://github.com/IthnHuitn/diploma-project/blob/main/screens/Prometeus_metrics.jpg)
![Prometeus_metrics2](https://github.com/IthnHuitn/diploma-project/blob/main/screens/Prometeus_metrics2.jpg)

### Отправка логов в Elasticsearch

```bash
curl -X GET "http://10.0.10.30:9200/_cat/indices?v"
```
![Elastic_logs](https://github.com/IthnHuitn/diploma-project/blob/main/screens/Elastic_logs.jpg)

## 3.3 SSH доступ через bastion

```bash
# SSH config
cat ~/.ssh/config
```

```bash
# Бастион хост
Host bastion
    HostName 51.250.83.70  # Public IP бастиона
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_diploma
    Port 22
    ForwardAgent yes
    StrictHostKeyChecking accept-new
    
# Графана (прямое подключение через бастион если нужен приватный доступ)
Host grafana-private
    HostName 10.0.1.20
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_diploma
    ProxyJump bastion

# Кибанна (прямое подключение через бастион если нужен приватный доступ)
Host kibana-private
    HostName 10.0.1.30
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_diploma
    ProxyJump bastion

# Веб сервера через бастион
Host web1
    HostName 10.0.10.10
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_diploma
    ForwardAgent yes
    ProxyJump bastion

Host web2
    HostName 10.0.20.10
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_diploma
    ForwardAgent yes
    ProxyJump bastion

# Прометеус через бастион
Host prometheus
    HostName 10.0.10.20
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_diploma
    ProxyJump bastion

# Elasticsearch через бастион
Host elasticsearch
    HostName 10.0.10.30
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_diploma
    ProxyJump bastion
    
    # Для всех приватных IP через бастион
 Host 10.0.*
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_diploma
    ForwardAgent yes
    ProxyJump bastion
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

## 3.4 BackUp

![BackUp1](https://github.com/IthnHuitn/diploma-project/blob/main/screens/backup1.png)
![BackUp2](https://github.com/IthnHuitn/diploma-project/blob/main/screens/backup2.png)

## 4. Безопасность

### Принципы реализации

 1. Минимальные привилегии: Каждый ресурс имеет доступ только к необходимым портам

 2. Bastion host: Единая точка входа для SSH

 3. Приватные подсети: Основные сервисы изолированы от интернета

 4. Security Groups: Детальная настройка правил

 ## 5. Компромиссы и решения

 ### 5.1 Принятые решения

 1. Статические приватные IP - для удобства настройки Ansible

 2. HTTP без HTTPS - для упрощения

 3. Один балансировщик - для экономии ресурсов

 4. Ubuntu 20.04 - стабильная версия с длительной поддержкой

 ### 5.2 Возможные улучшения

 1. Добавить SSL-сертификаты (Let's Encrypt)

 2. Добавить мониторинг самого балансировщика

 3. Внедрить CI/CD для автоматического деплоя

---

## 6. Инструкция по развертыванию

### 6.1 Предварительные требования

```bash
# Установить необходимое ПО
sudo apt update
sudo apt install -y terraform ansible yandex-cloud-cli

# Настроить YC CLI
yc init
```

### 6.2 Развертывание

```bash
# Клонировать репозиторий
git clone https://github.com/your-repo/diploma-project
cd diploma-project

# Создать terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
# Отредактировать файл, добавить токены и ключи

# Развернуть инфраструктуру
terraform init
terraform plan
terraform apply

# Настроить серверы через Ansible, применяю последовательную установку сервисов, 
# чтобы избежать ошибок зависимых сервисов
cd ansible
ansible-playbook -i inventory.ini playbooks/01-elasticsearch.yml
ansible-playbook -i inventory.ini playbooks/02-prometheus.yml
ansible-playbook -i inventory.ini playbooks/03-kibana.yml
ansible-playbook -i inventory.ini playbooks/04-grafana.yml
ansible-playbook -i inventory.ini playbooks/05-web-servers.yml

```

## 7. Заключение

Разработанная инфраструктура полностью соответствует требованиям курсовой работы:

 -   ✅ Отказоустойчивая конфигурация с балансировкой нагрузки

 -   ✅ Централизованный сбор метрик (Prometheus + Grafana)

 -   ✅ Централизованный сбор логов (Elasticsearch + Kibana)

 -   ✅ Безопасный доступ через bastion host

 -   ✅ Инфраструктура как код (Terraform + Ansible)

 -   ✅ Документирование всех решений

