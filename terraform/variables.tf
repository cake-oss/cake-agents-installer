variable "name" {
  type        = string
  description = "Cluster name (e.g. \"prod\")."
}

variable "region" {
  type        = string
  description = "AWS region to deploy into."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the new VPC. Change this if you intend to peer this VPC with another one that uses a conflicting range."
}

variable "cake_agents_chart_version" {
  type        = string
  default     = "0.11.2"
  description = "cake-agents chart version. Get the latest from Cake."
}

variable "install_key" {
  type        = string
  description = "Install key for Cake-hosted DNS automation."
  sensitive   = true
}
