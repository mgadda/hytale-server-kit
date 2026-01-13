output "server_ip" {
  description = "Public IP address of the Hytale server"
  value       = linode_instance.hytale.ip_address
}

output "server_id" {
  description = "Linode instance ID"
  value       = linode_instance.hytale.id
}

output "connect_address" {
  description = "Address to connect from Hytale client"
  value       = "${linode_instance.hytale.ip_address}:5520"
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh root@${linode_instance.hytale.ip_address}"
}
