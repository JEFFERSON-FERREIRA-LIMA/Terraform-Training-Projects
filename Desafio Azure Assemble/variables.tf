#locations
variable "vnet-hub_location" {
  type    = string
  default = "eastus"
}

variable "vnet-spoke01_location" {
  type    = string
  default = "westus3"
}

variable "use_for_each" {
  type    = bool
  default = true
}

variable "vm_admin_username" {
  type    = string
  default = "admin.user"
}

variable "vm_admin_password" {
  type    = string
  default = "Partiunuvem2023"
}