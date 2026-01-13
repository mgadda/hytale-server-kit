terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.0"
}

provider "linode" {
  token = var.linode_token
}

resource "linode_instance" "hytale" {
  label  = var.server_label
  region = var.region
  type   = "g6-standard-1" # 4GB shared CPU

  image = "linode/ubuntu24.04"

  authorized_keys = [var.ssh_public_key]

  root_pass = var.root_password

  # Run setup script on first boot
  stackscript_id = linode_stackscript.hytale_setup.id

  firewall_id = linode_firewall.hytale.id

  tags = ["hytale", "game-server"]
}

resource "linode_stackscript" "hytale_setup" {
  label       = "hytale-server-setup"
  description = "Setup script for Hytale game server"
  script      = file("${path.module}/../scripts/setup.sh")
  images      = ["linode/ubuntu24.04"]
}
