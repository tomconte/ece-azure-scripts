variable "vm_size" {
  default = "Standard_DS11_v2"
}

variable "disk_size" {
  default = "512"
}

variable "node_count" {
  default = 3
}

variable "image_id" {
  default = "/subscriptions/252281c3-8a06-4af8-8f3f-d6af13e4fde3/resourceGroups/ece-base-image/providers/Microsoft.Compute/images/ece-base-image"
}

variable "ADMIN_USER" {
  default = "azureuser"
}

variable "ADMIN_PASSWORD" {
  default = "Password1234!"
}
