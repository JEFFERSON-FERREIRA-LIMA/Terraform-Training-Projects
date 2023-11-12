resource "azurerm_resource_group" "rg-cloudshoes-prd" {
  location = var.vnet-hub_location
  name     = "rg-cloudshoes-prd"
  tags = {
    "Ambiente" = "prd"
    "Cenario"  = "IaaS"
  }
}

resource "azurerm_virtual_network" "vnet-hub" {
  name                = "vnet-hub"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name
  address_space       = ["10.10.0.0/16"]

  tags = {
    "Ambiente" = "prd"
  }
}

resource "azurerm_subnet" "sub-app" {
  name                 = "sub-app"
  resource_group_name  = azurerm_resource_group.rg-cloudshoes-prd.name
  virtual_network_name = azurerm_virtual_network.vnet-hub.name
  address_prefixes     = ["10.10.1.0/24"]  
}

resource "azurerm_subnet" "sub-adds" {
  name                 = "sub-adds"
  resource_group_name  = azurerm_resource_group.rg-cloudshoes-prd.name
  virtual_network_name = azurerm_virtual_network.vnet-hub.name
  address_prefixes     = ["10.10.2.0/24"]
}


resource "azurerm_virtual_network" "vnet-spoke01" {
  name                = "vnet-spoke01"
  location            = "centralus"
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name
  address_space       = ["10.20.0.0/16"]

  tags = {
    "Ambiente" = "prd"
  }
}

resource "azurerm_subnet" "sub-db" {
  name                 = "sub-db"
  resource_group_name  = azurerm_resource_group.rg-cloudshoes-prd.name
  virtual_network_name = azurerm_virtual_network.vnet-spoke01.name
  address_prefixes     = ["10.20.1.0/24"]
}

# Create 2 Network Security Groups and rule
resource "azurerm_network_security_group" "nsg-hub-01" {
  name                = "nsg-hub-01"
  location            = var.vnet-hub_location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name

  #    security_rule {
  #        name                       = "SSH"
  #        priority                   = 1001
  #        direction                  = "Inbound"
  #        access                     = "Allow"
  #        protocol                   = "Tcp"
  #        source_port_range          = "*"
  #        destination_port_range     = "22"
  #        source_address_prefix      = "*"
  #        destination_address_prefix = "*"
  #    }

  tags = {
    "Ambiente" = "prd"
  }
}

resource "azurerm_network_security_group" "nsg-spoke01" {
  name                = "nsg-spoke01"
  location            = var.vnet-spoke01_location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name

  #    security_rule {
  #        name                       = "SSH"
  #        priority                   = 1001
  #        direction                  = "Inbound"
  #        access                     = "Allow"
  #        protocol                   = "Tcp"
  #        source_port_range          = "*"
  #        destination_port_range     = "22"
  #        source_address_prefix      = "*"
  #        destination_address_prefix = "*"
  #    }

  tags = {
    "Ambiente" = "prd"
  }
}


#association nsgs to subnets
resource "azurerm_subnet_network_security_group_association" "app-nsg-association" {
  subnet_id                 = azurerm_subnet.sub-app.id
  network_security_group_id = azurerm_network_security_group.nsg-hub-01.id
}

resource "azurerm_subnet_network_security_group_association" "adds-nsg-association" {
  subnet_id                 = azurerm_subnet.sub-adds.id
  network_security_group_id = azurerm_network_security_group.nsg-hub-01.id
}

resource "azurerm_subnet_network_security_group_association" "db-nsg-association" {
  subnet_id                 = azurerm_subnet.sub-db.id
  network_security_group_id = azurerm_network_security_group.nsg-spoke01.id
}