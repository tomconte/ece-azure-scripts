provider "azurerm" {}

resource "azurerm_resource_group" "ece" {
  name     = "ece"
  location = "West Europe"
}

resource "azurerm_network_security_group" "ece" {
  name                = "nsg-ece"
  location            = "${azurerm_resource_group.ece.location}"
  resource_group_name = "${azurerm_resource_group.ece.name}"

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "12443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ece-frontend"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9243"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "admin-ui"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "12400"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "ece" {
  name                = "vnet-ece"
  location            = "${azurerm_resource_group.ece.location}"
  resource_group_name = "${azurerm_resource_group.ece.name}"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "ece" {
  name                 = "subnet-1"
  resource_group_name  = "${azurerm_resource_group.ece.name}"
  virtual_network_name = "${azurerm_virtual_network.ece.name}"
  address_prefix       = "10.0.0.0/24"
}

variable "node_count" {
  default = 3
}

variable "ADMIN_USER" {
  default = "azureuser"
}

variable "ADMIN_PASSWORD" {
  default = "Password1234!"
}

resource "azurerm_public_ip" "ece" {
  count                        = "${var.node_count}"
  name                         = "public-ip-${format("%02d", count.index+1)}"
  location                     = "${azurerm_resource_group.ece.location}"
  resource_group_name          = "${azurerm_resource_group.ece.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "ece" {
  count               = "${var.node_count}"
  name                = "nic-${format("%02d", count.index+1)}"
  location            = "${azurerm_resource_group.ece.location}"
  resource_group_name = "${azurerm_resource_group.ece.name}"

  ip_configuration {
    name                          = "ip-config-${format("%02d", count.index+1)}"
    subnet_id                     = "${azurerm_subnet.ece.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.ece.*.id, count.index)}"
  }
}

resource "azurerm_virtual_machine" "test" {
  count                 = "${var.node_count}"
  name                  = "vm-${format("%02d", count.index+1)}"
  location              = "${azurerm_resource_group.ece.location}"
  resource_group_name   = "${azurerm_resource_group.ece.name}"
  network_interface_ids = ["${element(azurerm_network_interface.ece.*.id, count.index)}"]
  vm_size               = "Standard_DS11_v2"

  storage_image_reference {
    id = "/subscriptions/252281c3-8a06-4af8-8f3f-d6af13e4fde3/resourceGroups/ece-base-image/providers/Microsoft.Compute/images/ece-base-image"
  }

  storage_os_disk {
    name              = "os-disk-${format("%02d", count.index+1)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_data_disk {
    name              = "data-disk-${format("%02d", count.index+1)}"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "512"
  }

  os_profile {
    computer_name  = "ece-vm-${format("%02d", count.index+1)}"
    admin_username = "${var.ADMIN_USER}"
    admin_password = "${var.ADMIN_PASSWORD}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  connection {
    type     = "ssh"
    host     = "${element(azurerm_public_ip.ece.*.ip_address, count.index)}"
    user     = "${var.ADMIN_USER}"
    password = "${var.ADMIN_PASSWORD}"
  }

  provisioner "file" {
    source      = "disk_setup.sh"
    destination = "/tmp/disk_setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/disk_setup.sh",
      "sudo /tmp/disk_setup.sh",
    ]
  }
}

output "addresses" {
  value = ["${azurerm_public_ip.ece.*.ip_address}"]
}
