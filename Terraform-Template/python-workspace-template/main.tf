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
  config_path = ".kube/config"
}



resource "kubernetes_service_account" "wcd_sa" {
  metadata {
    name      = "wcd-sa"
    namespace = data.kubernetes_namespace.dev.metadata[0].name
  }
}

resource "kubernetes_role" "wcd_sa_role" {
  metadata {
    name      = "wcd-sa-role"
    namespace = data.kubernetes_namespace.dev.metadata[0].name
  }

  # Allow discovering pods
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }

  # Allow exec into pods
  rule {
    api_groups = [""]
    resources  = ["pods/exec"]
    verbs      = ["create", "get"]
  }

  # Allow attaching to running container process
  rule {
    api_groups = [""]
    resources  = ["pods/attach"]
    verbs      = ["create"]
  }
}

resource "kubernetes_role_binding" "wcd_sa_rolebinding" {
  metadata {
    name      = "wcd-sa-rolebinding"
    namespace = data.kubernetes_namespace.dev.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.wcd_sa_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.wcd_sa.metadata[0].name
    namespace = data.kubernetes_namespace.dev.metadata[0].name
  }
}



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
  pod_name = "${local.safe_base}-${random_string.suffix.result}"
  app_label = substr(local.pod_name, 0, 63)
}

# Use existing namespace
data "kubernetes_namespace" "dev" {
  metadata { name = "dev-workspaces" }
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
      name  = "py-container"
      # image = "ghcr.io/yuvraj-bhupati/android-workspace:latest"
      image = "${{ values.imageName }}"
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