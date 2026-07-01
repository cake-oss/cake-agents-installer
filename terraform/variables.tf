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
  description = "cake-agents chart version. Get the latest from Cake."
}

variable "install_key" {
  type        = string
  description = "Install key for Cake-hosted DNS automation."
  sensitive   = true
}

variable "cake_console_url" {
  type        = string
  default     = "https://console.cake.ai"
  description = "URL of the Cake console this installation reports to."
}

variable "cake_agents_chart_upstream_registry" {
  type        = string
  default     = "684117700585.dkr.ecr.us-east-2.amazonaws.com"
  description = "Upstream ECR registry hosting the cake-agents chart. Used as the pull-through cache upstream."
}
