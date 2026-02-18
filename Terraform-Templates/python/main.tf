terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

variable "namespace" {
  type    = string
  default = "dev-workspaces"
}

variable "workspace_name" {
  type    = string
  default = "yuvraj-workspace"
}

# Simple password instead of SSH key
#variable "ssh_password" {
#  type      = string
#  sensitive = true
#}

resource "kubernetes_namespace" "ns" {
  metadata { name = var.namespace }
}

resource "kubernetes_pod" "workspace" {
  metadata {
    name      = var.workspace_name
    namespace = var.namespace
  }

  spec {
    container {
      name  = "ssh"
      image = "ghcr.io/yuvraj-bhupati/python-workspace:latest"

      port { container_port = 2222 }

      #env { name = "PUID"               value = "1000" }
      #env { name = "PGID"               value = "1000" }
      #env { name = "TZ"                 value = "UTC" }

      # ---- IMPORTANT -----
      # Password-only login enabled
      env {
        name = "PASSWORD_ACCESS"
        value = "true"
        }
      env {
        name = "USER_NAME"
        value = "coder"
        }
      env {
        name = "USER_PASSWORD"
        value = "Wipro@123"
        }


    }
    restart_policy = "Always"
  }
}
