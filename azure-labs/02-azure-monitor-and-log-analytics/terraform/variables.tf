variable "resource_group_name" {
  description = "Name of the resource group to deploy into"
  type        = string
}

variable "workspace_name" {
  description = "Name of the Log Analytics Workspace"
  type        = string
  default     = "law-analytics"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "retention_in_days" {
  description = "Retention period for logs"
  type        = number
  default     = 30
}

variable "public_network_access" {
  description = "Enable public network access"
  type        = string
  default     = "Enabled"
}

variable "solutions" {
  description = "Solutions to deploy"
  type        = list(string)
  default     = ["VMInsights", "ContainerInsights"]
}

variable "deploy_vm_dcr" {
  description = "Deploy VM Insights Data Collection Rule"
  type        = bool
  default     = true
}