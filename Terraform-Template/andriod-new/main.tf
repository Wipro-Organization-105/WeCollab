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
  default = "andriod-workspace"
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

locals {
  base0 = lower(var.workspace_name)
  base1 = replace(local.base0, "/[^a-z0-9.-]+/", "-")
  base2 = replace(local.base1, "/-+/", "-")
  base3 = trim(local.base2, "-.")
  safe_base_pre = length(local.base3) > 0 ? local.base3 : "ws"
  safe_base = substr(local.safe_base_pre, 0, 56)
  pod_name = "${local.safe_base}-workspace"
  pvc_name = "${local.safe_base}-pvc"
  app_label = substr(local.pod_name, 0, 63)
}

# Use existing namespace
data "kubernetes_namespace" "dev" {
  metadata { name = "dev-workspaces" }
}

# Use default storage class for PVC
data "kubernetes_storage_class" "default" {
  metadata { name = "local-path" }
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
      image = "ghcr.io/kksinghwipro04/andriod-workspace:v1"
      image_pull_policy = "IfNotPresent"


      command = ["bash", "-lc"]
      args    = ["exec tail -f /dev/null"]
      lifecycle {
        post_start {
          exec {
            command = ["/bin/bash", "-c", "/usr/local/bin/install-vscode-extensions.sh > /tmp/vscode-setup.log 2>&1 &"]
          }
        }
      }
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
      volume_mount {
        mount_path = "/home/wcd"
        name       = "data"
      }
    }
    volume {
      name = "data"
      persistent_volume_claim {
        claim_name = local.pvc_name
      }
     }
    restart_policy = "Always"
  }
}

# PVC for workspace data persistence
resource "kubernetes_persistent_volume_claim" "app_pvc" {
  metadata {
    name      = local.pvc_name
    namespace = data.kubernetes_namespace.dev.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "2Gi"
      }
    }

    storage_class_name = data.kubernetes_storage_class.default.metadata[0].name
  }
}

output "pod_name" {
  value = local.pod_name
  description = "Pod name - "
}
