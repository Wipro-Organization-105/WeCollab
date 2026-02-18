terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      # version = ">= 2.4.0" # uncomment if you want Dynamic Parameters UX
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "kubernetes" {
  config_path = "/home/coder/.kube/config"
}

data "coder_workspace" "me" {}

# Parameter exposed in Coder's Create Workspace form.
data "coder_parameter" "workspace_image" {
  name        = "Workspace image"
  description = "Container image to run in the workspace Pod (e.g., ghcr.io/org/dev:latest)"
  type        = "string"
  default     = "codercom/enterprise-base:ubuntu"
}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"
}

resource "kubernetes_pod" "workspace" {
  metadata {
    name      = "coder-${data.coder_workspace.me.name}"
    namespace = "coder"
    labels    = { app = "coder-workspace" }
  }

  spec {
    container {
      name  = "dev"
      image = data.coder_parameter.workspace_image.value

      command = ["/bin/sh", "-c"]
      args    = [coder_agent.main.init_script]

      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.main.token
      }

      volume_mount {
        name       = "workspace"
        mount_path = "/home/coder"
      }
    }

    volume {
      name = "workspace"
      empty_dir {}
    }
  }
}

resource "coder_app" "vscode" {
  agent_id     = coder_agent.main.id
  slug         = "vscode"
  display_name = "VS Code"
  url          = "http://localhost:13337/?folder=/home/coder/"
  icon         = "https://raw.githubusercontent.com/coder/coder/main/site/static/icon/code.svg"
}
