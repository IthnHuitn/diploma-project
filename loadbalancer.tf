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
