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



# resource "kubernetes_service_account" "wcd_sa" {
#  metadata {
#    name      = "wcd-sa"
#    namespace = data.kubernetes_namespace.dev.metadata[0].name
#  }
# }

# resource "kubernetes_role" "wcd_sa_role" {
#  metadata {
#    name      = "wcd-sa-role"
#    namespace = data.kubernetes_namespace.dev.metadata[0].name
#  }

#  rule {
#    api_groups = [""]
#    resources  = ["pods"]
#    verbs      = ["get", "list", "watch"]
#  }

#  rule {
#    api_groups = [""]
#    resources  = ["pods/exec"]
#    verbs      = ["create", "get"]
#  }

#   Allow attaching to running container process
#  rule {
#    api_groups = [""]
#    resources  = ["pods/attach"]
#    verbs      = ["create"]
#  }
# }

# resource "kubernetes_role_binding" "wcd_sa_rolebinding" {
#  metadata {
#    name      = "wcd-sa-rolebinding"
#    namespace = data.kubernetes_namespace.dev.metadata[0].name
#  }

#  role_ref {
#    api_group = "rbac.authorization.k8s.io"
#    kind      = "Role"
#    name      = kubernetes_role.wcd_sa_role.metadata[0].name
#  }

#  subject {
#    kind      = "ServiceAccount"
#    name      = kubernetes_service_account.wcd_sa.metadata[0].name
#    namespace = data.kubernetes_namespace.dev.metadata[0].name
#  }
# }



variable "workspace_name" {
  type    = string
  default = "dev-workspace"
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

# Pod resource specification
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
      name  = "py-container"
      # image = "ghcr.io/yuvraj-bhupati/android-workspace:latest"
      image = "${{ values.imageName }}"
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