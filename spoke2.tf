locals {
  Spoke2-location       = "CentralUS"
  Spoke2-resource-group = "test-network-rg"
  prefix-Spoke2         = "test"
}

resource "azurerm_resource_group" "Spoke2-vnet-rg" {
  name     = "${local.Spoke2-resource-group}"
  location = "${local.Spoke2-location}"
}

resource "azurerm_virtual_network" "Spoke2-vnet" {
  name                = "test-vnet"
  location            = "${azurerm_resource_group.Spoke2-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.Spoke2-vnet-rg.name}"
  address_space       = ["10.1.0.0/22"]

  tags {
    environment = "${local.prefix-Spoke2 }"
  }
}

resource "azurerm_subnet" "Spoke2-exter" {
  name                 = "test-external-subnet"
  resource_group_name  = "${azurerm_resource_group.Spoke2-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.Spoke2-vnet.name}"
  address_prefix       = "10.1.0.64/27"
}

resource "azurerm_subnet" "Spoke2-inter" {
  name                 = "test-internal-subnet"
  resource_group_name  = "${azurerm_resource_group.Spoke2-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.Spoke2-vnet.name}"
  address_prefix       = "10.1.1.0/24"
}
resource "azurerm_subnet" "Spoke2-gateway" {
  name                 = "test-gateway-subnet"
  resource_group_name  = "${azurerm_resource_group.Spoke2-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.Spoke2-vnet.name}"
  address_prefix       = "10.1.1.0/27"
}
resource "azurerm_subnet" "Spoke2-mgmt" {
  name                 = "test-management-subnet"
  resource_group_name  = "${azurerm_resource_group.Spoke2-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.Spoke2-vnet.name}"
  address_prefix       = "10.1.1.0/27"
}
resource "azurerm_subnet" "Spoke2-app" {
  name                 = "test-application-subnet"
  resource_group_name  = "${azurerm_resource_group.Spoke2-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.Spoke2-vnet.name}"
  address_prefix       = "10.1.1.0/27"
}

resource "azurerm_virtual_network_peering" "Spoke2-hub-peer" {
  name                      = "test-shared-peer"
  resource_group_name       = "${azurerm_resource_group.Spoke2-vnet-rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.Spoke2-vnet.name}"
  remote_virtual_network_id = "${azurerm_virtual_network.hub-vnet.id}"

  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = true
  depends_on = ["azurerm_virtual_network.Spoke2-vnet", "azurerm_virtual_network.hub-vnet" , "azurerm_virtual_network_gateway.hub-vnet-gateway"]
}

resource "azurerm_network_interface" "Spoke2-nic" {
  name                 = "${local.prefix-Spoke2}-nic"
  location             = "${azurerm_resource_group.Spoke2-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.Spoke2-vnet-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-Spoke2}"
    subnet_id                     = "${azurerm_subnet.Spoke2-mgmt.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "Spoke2-vm" {
  name                  = "${local.prefix-Spoke2}-vm"
  location              = "${azurerm_resource_group.Spoke2-vnet-rg.location}"
  resource_group_name   = "${azurerm_resource_group.Spoke2-vnet-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.Spoke2-nic.id}"]
  vm_size               = "${var.vmsize}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.prefix-Spoke2}-vm"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${local.prefix-Spoke2}"
  }
}

resource "azurerm_virtual_network_peering" "hub-Spoke2-peer" {
  name                      = "shared-test-peer"
  resource_group_name       = "${azurerm_resource_group.hub-vnet-rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.hub-vnet.name}"
  remote_virtual_network_id = "${azurerm_virtual_network.Spoke2-vnet.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
  depends_on = ["azurerm_virtual_network.Spoke2-vnet", "azurerm_virtual_network.hub-vnet", "azurerm_virtual_network_gateway.hub-vnet-gateway"]
}