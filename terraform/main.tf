terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Mirrors cake-oss/terraform-cake-agents//examples/basic, but sources the module
# by git ref so the installer is self-contained. install.sh rewrites the ?ref=
# pin when CAKE_AGENTS_REF is set.
module "cake_agents" {
  source = "git::https://github.com/cake-oss/terraform-cake-agents.git?ref=main"

  name     = var.name
  vpc_cidr = var.vpc_cidr

  install_key      = var.install_key
  cake_console_url = var.cake_console_url

  cake_agents_chart_version = var.cake_agents_chart_version
}

output "cluster_name" {
  value = module.cake_agents.cluster_name
}
