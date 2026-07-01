terraform {
  required_version = ">= 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    restful = {
      source  = "magodo/restful"
      version = ">= 0.25.0"
    }
  }
}

# Mirrors cake-oss/terraform-cake-agents//examples/basic, but sources the module
# by git ref so the installer is self-contained. install.sh rewrites the ?ref=
# pin when CAKE_TF_GIT_REF is set.
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
