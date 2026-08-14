variable "location" {
  type    = string
  default = "uksouth"
}

variable "resource_group_name" {
  type    = string
  default = "rg-storage-sas-lab"
}

variable "vnet_name" {
  type    = string
  default = "vnet-hub"
}

variable "subnet_name" {
  type    = string
  default = "shared-services-subnet"
}