terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
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
  default = "workspace"
}


resource "random_string" "suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

locals {
  safe_base_pre = lower(
    replace(
      replace(
        replace(
          replace(var.workspace_name, " ", "-"),
        "_", "-"),
      ".", "-"),
    "/", "-")
  )

  # Ensure final name <= 63 chars: 56 + '-' + 6 = 63
  safe_base = substr(local.safe_base_pre, 0, 56)

  pod_name = "${local.safe_base}-${random_string.suffix.result}"
}


resource "kubernetes_namespace" "ns" {
  metadata { name = var.namespace }
}


resource "kubernetes_pod" "workspace" {
  metadata {
    name      = local.pod_name
    namespace = var.namespace
    labels = {
      app = local.pod_name
    }
  }

  spec {
    container {
      name  = "ssh"
      image = "ghcr.io/yuvraj-bhupati/python-workspace:latest"
      image_pull_policy = "IfNotPresent"

      # Your image should expose SSH on 2222
      port { container_port = 2222 }

  
      env {
        name = "PASSWORD_ACCESS"
        value = "true"
      }
      env {
        name = "USER_NAME"
        value = "dev"
      }
      env {
        name = "USER_PASSWORD"
        value = "Wipro@123"
      }


      # Optional: basic resources (safe to remove)
      resources {
        requests = {
          cpu    = "200m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }
    }

    restart_policy = "Always"
  }
}


output "namespace" {
  value = var.namespace
}

output "pod_name" {
  value = local.pod_name
  description = "Actual Pod name including the random 6-char suffix."
}
