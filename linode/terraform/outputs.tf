locals {
  server_ip = tolist(linode_instance.hytale.ipv4)[0]
}

output "server_ip" {
  description = "Public IP address of the Hytale server"
  value       = local.server_ip
}

output "server_id" {
  description = "Linode instance ID"
  value       = linode_instance.hytale.id
}

output "connect_address" {
  description = "Address to connect from Hytale client"
  value       = "${local.server_ip}:5520"
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh root@${local.server_ip}"
}
