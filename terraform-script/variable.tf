variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-aks-prod"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "aks-prod"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "public_subnet_address_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

variable "aks_subnet_address_prefix" {
  type    = string
  default = "10.0.2.0/23"
}

variable "node_count" {
  type    = number
  default = 5
}

variable "vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}