resource "linode_firewall" "hytale" {
  label = "hytale-firewall"

  # Hytale game server - UDP only
  inbound {
    label    = "hytale-game"
    action   = "ACCEPT"
    protocol = "UDP"
    ports    = "5520"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  # SSH access - restricted to admin IP
  inbound {
    label    = "ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["99.46.181.141/32"]
  }

  # Default deny all other inbound
  inbound_policy = "DROP"

  # Allow all outbound (for package updates, etc.)
  outbound_policy = "ACCEPT"

  linodes = [linode_instance.hytale.id]
}
