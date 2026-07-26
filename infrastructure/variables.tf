variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "location" {
  default = "Canada Central"
}

variable "resource_group_name" {
  default = "rg-company-iis-dev-cac"
}

variable "company_name" {
  default = "CloudNorth Technologies"
}

variable "environment" {
  default = "Development"
}

variable "vm_name" {
  default = "vm-company-iis-dev"
}

variable "vm_size" {
  default = "Standard_B2s"
}

variable "admin_username" {
  default = "azureadmin"
}

variable "admin_password" {
  sensitive = true
}

variable "allowed_rdp_source" {
  type = string
}