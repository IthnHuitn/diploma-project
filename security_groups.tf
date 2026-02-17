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
