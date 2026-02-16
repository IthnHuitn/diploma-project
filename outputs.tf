output "bastion_public_ip" {
  description = "Public IP address of Bastion host"
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

output "grafana_public_ip" {
  description = "Public IP address of Grafana"
  value       = yandex_compute_instance.grafana.network_interface.0.nat_ip_address
}

output "kibana_public_ip" {
  description = "Public IP address of Kibana"
  value       = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}

output "all_private_ips" {
  description = "All private IP addresses for Ansible inventory"
  value = {
    "bastion"      = yandex_compute_instance.bastion.network_interface.0.ip_address
    "web-server-1" = yandex_compute_instance.web-server-1.network_interface.0.ip_address
    "web-server-2" = yandex_compute_instance.web-server-2.network_interface.0.ip_address
    "prometheus"   = yandex_compute_instance.prometheus.network_interface.0.ip_address
    "elasticsearch" = yandex_compute_instance.elasticsearch.network_interface.0.ip_address
    "grafana"      = yandex_compute_instance.grafana.network_interface.0.ip_address
    "kibana"       = yandex_compute_instance.kibana.network_interface.0.ip_address
  }
}

output "network_info" {
  description = "Network configuration information"
  value = {
    vpc_id     = yandex_vpc_network.diploma-vpc.id
    vpc_name   = yandex_vpc_network.diploma-vpc.name
    public_subnets = {
      for zone, subnet in yandex_vpc_subnet.public-subnets : zone => subnet.id
    }
    private_subnets = {
      for zone, subnet in yandex_vpc_subnet.private-subnets : zone => subnet.id
    }
  }
}