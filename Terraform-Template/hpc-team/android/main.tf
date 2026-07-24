terraform {
  required_version = ">= 1.5"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/resource-server-config"
}

##################################################
# Locals
##################################################

locals {

  workspace_name = (
    var.workspace_name != null
    ? var.workspace_name
    : format("ws-%02d", var.base_instance_num)
  )

  deployment_name = (
    var.deployment_name != null
    ? var.deployment_name
    : local.workspace_name
  )

  pvc_name = (
    var.pvc_name != null
    ? var.pvc_name
    : "${local.workspace_name}-pvc"
  )

  secret_name = "${local.workspace_name}-pass"
}

##################################################
# Secret
##################################################

resource "kubernetes_secret" "workspace_secret" {

  metadata {
    name      = local.secret_name
    namespace = var.namespace
  }

  type = "Opaque"

  data = {
    key = var.workspace_password
  }
}

##################################################
# PVC
##################################################

resource "kubernetes_persistent_volume_claim" "workspace_pvc" {

  wait_until_bound = false 
  metadata {
    name      = local.pvc_name
    namespace = var.namespace
  }

  spec {

    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.storage_size
      }
    }

    storage_class_name = var.storage_class
  }
}

##################################################
# Deployment
##################################################

resource "kubernetes_deployment" "workspace" {

  metadata {
    name      = local.deployment_name
    namespace = var.namespace

    labels = {
      app = local.workspace_name
    }
  }

  spec {

    replicas                  = var.replicas
    revision_history_limit    = 10
    progress_deadline_seconds = 600

    selector {
      match_labels = {
        app = local.workspace_name
      }
    }

    strategy {

      type = "RollingUpdate"

      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {

      metadata {
        labels = {
          app = local.workspace_name
        }
      }

      spec {

        host_network = true

        container {

          name              = "hpc-ws"
          image             = var.image_name
          image_pull_policy = "Never"

          command = [
            "code-server"
          ]

          args = [
            "--bind-addr",
            "0.0.0.0:${var.code_server_port}",
            "--cert",
            "--auth",
            "password",
            "/workspace"
          ]

          env {
            name  = "BASE_INSTANCE_NUM"
            value = tostring(var.base_instance_num)
          }

          env {
            name  = "VSOCK_GUEST_CID"
            value = tostring(var.vsock_guest_cid)
          }

          env {
            name  = "CODE_SERVER_PORT"
            value = tostring(var.code_server_port)
          }

          env {
            name  = "WEBRTC_PORT"
            value = tostring(var.webrtc_port)
          }

          port {
            name           = "vscode"
            container_port = var.code_server_port
            protocol       = "TCP"
          }

          port {
            name           = "webrtc"
            container_port = var.webrtc_port
            protocol       = "TCP"
          }

          security_context {
            privileged = true
          }

          volume_mount {
            name       = "kvm"
            mount_path = "/dev/kvm"
          }

          volume_mount {
            name       = "tun"
            mount_path = "/dev/net/tun"
          }

          volume_mount {
            name       = "workspace"
            mount_path = "/workspace"
          }
        }

        volume {
          name = "kvm"

          host_path {
            path = "/dev/kvm"
          }
        }

        volume {
          name = "tun"

          host_path {
            path = "/dev/net/tun"
          }
        }

        volume {
          name = "workspace"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.workspace_pvc.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim.workspace_pvc,
    kubernetes_secret.workspace_secret
  ]
}
