terraform {
  required_version = ">= 1.9.5"
}

provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "client_id" {
  description = "Azure Client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}

# Example resource to verify deployment
resource "azurerm_resource_group" "example" {
  name     = "example-resource-group"
  location = "East US"
}

output "resource_group_name" {
  value = azurerm_resource_group.example.name
}
