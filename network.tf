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
