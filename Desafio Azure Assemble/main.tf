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

# 2 Network Security Groups and rules
resource "azurerm_network_security_group" "nsg-hub-01" {
  name                = "nsg-hub-01"
  location            = var.vnet-hub_location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    "Ambiente" = "prd"
  }
}

resource "azurerm_network_security_group" "nsg-spoke01" {
  name                = "nsg-spoke01"
  location            = var.vnet-spoke01_location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name

  security_rule {
    name                       = "RDP_SQL"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = ["1433", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

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

#nsgs network interface configuration
resource "azurerm_public_ip" "public-ip-app" {
  name                = "public-ip-app"
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name
  location            = var.vnet-hub_location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic-app" {
  name                = "nic-app"
  location            = var.vnet-hub_location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name

  ip_configuration {
    name                          = "ip-config-app"
    subnet_id                     = azurerm_subnet.sub-app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip-app.id
  }
}

resource "azurerm_public_ip" "public-ip-adds" {
  name                = "public-ip-adds"
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name
  location            = var.vnet-hub_location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic-adds" {
  name                = "nic-adds"
  location            = var.vnet-hub_location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name

  ip_configuration {
    name                          = "ip-config-adds"
    subnet_id                     = azurerm_subnet.sub-adds.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip-adds.id
  }
}

resource "azurerm_public_ip" "public-ip-db" {
  name                = "public-ip-db"
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name
  location            = var.vnet-spoke01_location
  allocation_method   = "Dynamic"
}
resource "azurerm_network_interface" "nic-db" {
  name                = "nic-db"
  location            = var.vnet-spoke01_location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name

  ip_configuration {
    name                          = "ip-config-db"
    subnet_id                     = azurerm_subnet.sub-db.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip-db.id
  }
}

#vnets peering
resource "azurerm_virtual_network_peering" "vnet-hub_to_vnet-spoke01" {
  name                         = "vnet-hub_to_vnet-spoke01"
  resource_group_name          = azurerm_resource_group.rg-cloudshoes-prd.name
  virtual_network_name         = azurerm_virtual_network.vnet-hub.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-spoke01.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "vnet-spoke01_to_vnet-hub" {
  name                         = "vnet-spoke01_to_vnet-hub"
  resource_group_name          = azurerm_resource_group.rg-cloudshoes-prd.name
  virtual_network_name         = azurerm_virtual_network.vnet-spoke01.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-hub.id
  allow_virtual_network_access = true
}

#vm-app
resource "azurerm_virtual_machine" "vm-app" {
  name                  = "vm-app"
  location              = var.vnet-hub_location
  resource_group_name   = azurerm_resource_group.rg-cloudshoes-prd.name
  network_interface_ids = [azurerm_network_interface.nic-app.id]
  vm_size               = "Standard_B2s"
  tags = {
    "Cenario" = "IaaS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-app"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name  = "vm-app"
    admin_username = "admin-jefferson"
    admin_password = "Partiunuvem2023"
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  #  diagnostics_profile {
  #    boot_diagnostics {
  #      enabled     = true
  #      storage_uri = azurerm_storage_account.sa-bootdiag.primary_blob_endpoint
  #    }
  #  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown-app" {
  virtual_machine_id = azurerm_virtual_machine.vm-app.id
  location           = azurerm_resource_group.rg-cloudshoes-prd.location
  enabled            = true

  daily_recurrence_time = "1700"
  timezone              = "E. South America Standard Time"

  notification_settings {
    enabled         = true
    time_in_minutes = "60"
    email           = "valeriaom17@outlook.com"
  }
}

#vm-adds
resource "azurerm_virtual_machine" "vm-adds" {
  name                  = "vm-adds"
  location              = var.vnet-hub_location
  resource_group_name   = azurerm_resource_group.rg-cloudshoes-prd.name
  network_interface_ids = [azurerm_network_interface.nic-adds.id]
  vm_size               = "Standard_B2s"
  tags = {
    "Cenario" = "IaaS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-adds"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name  = "vm-adds"
    admin_username = "admin-jefferson"
    admin_password = "Partiunuvem2023"
  }


  #  diagnostics_profile {
  #    boot_diagnostics {
  #      enabled     = true
  #      storage_uri = azurerm_storage_account.sa-bootdiag.primary_blob_endpoint
  #    }
  #  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown-adds" {
  virtual_machine_id = azurerm_virtual_machine.vm-app.id
  location           = azurerm_resource_group.rg-cloudshoes-prd.location
  enabled            = true

  daily_recurrence_time = "1700"
  timezone              = "E. South America Standard Time"

  notification_settings {
    enabled         = true
    time_in_minutes = "60"
    email           = "valeriaom17@outlook.com"
  }
}

#vm-db

#
resource "azurerm_private_endpoint" "vm-sql-private-endpoint" {
  name                = "vm-sql-private-endpoint"
  location            = azurerm_resource_group.rg-cloudshoes-prd.location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name
  subnet_id           = azurerm_subnet.sub-db.id

  private_service_connection {
    name                           = "vm-sql-privateserviceconnection"
    private_connection_resource_id = azurerm_virtual_machine.vm-db.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_virtual_machine" "vm-db" {
  name                  = "vm-db"
  location              = var.vnet-spoke01_location
  resource_group_name   = azurerm_resource_group.rg-cloudshoes-prd.name
  network_interface_ids = [azurerm_network_interface.nic-db.id]
  vm_size               = "Standard_D2s_v3"
  tags = {
    "Ambiente" = "prd"
    "Cenario"  = "IaaS"
  }

  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2022-WS2022"
    sku       = "SQLDEV"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-db"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_data_disk {
    name              = "data"
    caching           = "ReadWrite"
    create_option     = "Empty"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 8
    lun               = 1
  }

  storage_data_disk {
    name              = "log"
    caching           = "ReadWrite"
    create_option     = "Empty"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 8
    lun               = 2
  }

  os_profile {
    computer_name  = "vm-db"
    admin_username = "admsql"
    admin_password = "Partiunuvem@2023"
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  #  diagnostics_profile {
  #    boot_diagnostics {
  #      enabled     = true
  #      storage_uri = azurerm_storage_account.sa-bootdiag.primary_blob_endpoint
  #    }
  #  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown-db" {
  virtual_machine_id = azurerm_virtual_machine.vm-adds.id
  location           = azurerm_resource_group.rg-cloudshoes-prd.location
  enabled            = true

  daily_recurrence_time = "1700"
  timezone              = "E. South America Standard Time"

  notification_settings {
    enabled         = true
    time_in_minutes = "60"
    email           = "valeriaom17@outlook.com"
  }
}
