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

  safe_base = substr(local.safe_base_pre, 0, 56)

  pod_name = "${local.safe_base}-${random_string.suffix.result}"
}

# Use existing namespace
data "kubernetes_namespace" "dev" {
  metadata { name = "android-workspaces" }
}

resource "kubernetes_pod" "workspace" {
  metadata {
    name      = local.pod_name
    namespace = data.kubernetes_namespace.dev.metadata[0].name
    labels = {
      app = local.pod_name
    }
  }

  spec {
    container {
      name  = "android"
      image = "ghcr.io/yuvraj-bhupati/android-workspace:latest"
      image_pull_policy = "IfNotPresent"


      command = ["bash", "-lc"]
      args    = ["exec tail -f /dev/null"]

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

output "pod_name" {
  value = local.pod_name
  description = "Pod name - "
}
