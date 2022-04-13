terraform {

  required_version = ">=0.12"
  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
      
    }
  }
}

provider "azurerm" {
  features {}
  # 測試用，不要把正式環境的資訊放在這裡
  subscription_id   = ""
  tenant_id         = ""
  client_id         = ""
  client_secret     = ""
}

# Create virtual network
resource "azurerm_resource_group" "rg" {
  name      = "terraform-rg"
  location = var.location_define
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "vnet"
    address_space       = ["172.16.0.0/16"]
    resource_group_name = azurerm_resource_group.rg.name
    location = var.location_define
}

# Create subnet
resource "azurerm_subnet" "subnet" {
    name                 = "workload-subnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes       = ["172.16.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "pip" {
    name                         = "pip"
    location                     = var.location_define
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Static"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
    name                = "nsg"
    location            = var.location_define
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name                       = "AllowRDPInbount"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
    name                      = "nic"
    location                  = var.location_define
    resource_group_name       = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "Configuration"
        subnet_id                     = azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.pip.id
    }
}

# Connect the security group to the network interface
resource "azurerm_subnet_network_security_group_association" "nsg_association_vnet" {
    subnet_id = azurerm_subnet.subnet.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "win_vm" {
  name                = "winvm0329"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "brian"
  admin_password      = "brian@123"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
