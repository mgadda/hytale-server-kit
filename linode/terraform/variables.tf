variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for root access"
  type        = string
}

variable "root_password" {
  description = "Root password for the Linode instance"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Linode region for the server"
  type        = string
  default     = "us-west" # Los Angeles
}

variable "server_label" {
  description = "Label for the Linode instance"
  type        = string
  default     = "hytale-server"
}
