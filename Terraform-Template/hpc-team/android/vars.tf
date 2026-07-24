variable "base_instance_num" {
  description = "Workspace instance number"
  type        = number
}

variable "vsock_guest_cid" {
  description = "Cuttlefish VSOCK Guest CID"
  type        = number
}

variable "code_server_port" {
  description = "Code Server port"
  type        = number
}

variable "webrtc_port" {
  description = "WebRTC port"
  type        = number
}

variable "workspace_password" {
  description = "Workspace password"
  type        = string
  sensitive   = true
  default     = "wipro123"
}

variable "workspace_name" {
  description = "Optional workspace name"
  type        = string
  default     = null
}

variable "deployment_name" {
  description = "Optional deployment name"
  type        = string
  default     = null
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
}

variable "storage_class" {
  description = "Storage class for PVC"
  type        = string
  default     = "local-path"
}

variable "storage_size" {
  description = "PVC size"
  type        = string
  default     = "10Gi"
}

variable "pvc_name" {
  description = "Optional PVC name"
  type        = string
  default     = null
}

variable "image_name" {
  description = "Workspace image"
  type        = string
  default     = "hpc-workspace-dryrun:v1"
}

variable "replicas" {
  description = "Replica count"
  type        = number
  default     = 1
}
