# resource group
resource "azurerm_resource_group" "rg-cloudshoes-prd" {
  location = var.vnet-hub_location
  name     = "rg-cloudshoes-prd"
  tags = {
    "Ambiente" = "prd"
    "Cenario"  = "IaaS"
    "ManagedBy" = "terraform"
  }
}

resource "azurerm_virtual_network" "vnet-hub" {
  name                = "vnet-hub"
  location            = var.vnet-hub_location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name
  address_space       = ["10.10.0.0/16"]

  tags = {
    "Ambiente" = "prd"
    "ManagedBy" = "terraform"
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
  location            = var.vnet-spoke01_location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name
  address_space       = ["10.20.0.0/16"]

  tags = {
    "Ambiente" = "prd"
    "ManagedBy" = "terraform"
  }
}

resource "azurerm_subnet" "sub-db" {
  name                 = "sub-db"
  resource_group_name  = azurerm_resource_group.rg-cloudshoes-prd.name
  virtual_network_name = azurerm_virtual_network.vnet-spoke01.name
  address_prefixes     = ["10.20.1.0/24"]
}

# 2 Network Security Groups and rules
resource "azurerm_network_security_group" "nsg-hub01" {
  name                = "nsg-hub01"
  location            = var.vnet-hub_location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name

  tags = {
    "Ambiente" = "prd"
    "ManagedBy" = "terraform"
  }

  #Inbound Rules
  security_rule {
    name                       = "AllowAnyRDPInBound"
    description                = "Liberação de acesso às VMs"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "10.10.1.4-10.10.2.4"

  }


  #  security_rule {
  #    name                       = "AllowVnetInBoundRDP"
  #    priority                   = 1001
  #    direction                  = "Inbound"
  #    access                     = "Allow"
  #    protocol                   = "Tcp"
  #    source_port_range          = "*"
  #    destination_port_range     = "3389"
  #    source_address_prefix      = "*"
  #    destination_address_prefix = "*"
  #
  #  }

  #security_rule {
  #  name                       = "AllowAzureLoadBalancer"
  #  priority                   = 1002
  #  direction                  = "Inbound"
  #  access                     = "Allow"
  #  protocol                   = "Tcp"
  #  source_port_range          = "*"
  #  destination_port_range     = "3389"
  #  source_address_prefix = "*"
  #  destination_address_prefix = "*"
  #
  #}
  #security_rule {
  #  name                       = "AllowVnetInBoundRDP"
  #  priority                   = 1001
  #  direction                  = "Inbound"
  #  access                     = "Allow"
  #  protocol                   = "Tcp"
  #  source_port_range          = "*"
  #  destination_port_range     = "3389"
  #  source_address_prefix = "*"
  #  destination_address_prefix = "*"
  #}
  #security_rule {
  #  name                       = "AllowVnetInBoundRDP"
  #  priority                   = 1001
  #  direction                  = "Inbound"
  #  access                     = "Allow"
  #  protocol                   = "Tcp"
  #  source_port_range          = "*"
  #  destination_port_range     = "3389"
  #  source_address_prefix = "*"
  #  destination_address_prefix = "*"
  #}

  #Outbound Rules

}

resource "azurerm_network_security_group" "nsg-spoke01" {
  name                = "nsg-spoke01"
  location            = var.vnet-spoke01_location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name

  tags = {
    "Ambiente" = "prd"
    "ManagedBy" = "terraform"
  }

 #Inbound Rules
  security_rule {
    name                       = "AllowAnyRDPInBound"
    description                = "Liberação de acesso às VMs"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433-3389"
    source_address_prefix      = "*"
    destination_address_prefix = "10.20.1.4"

  }
}

#association nsgs to subnets
resource "azurerm_subnet_network_security_group_association" "app-nsg-association" {
  subnet_id                 = azurerm_subnet.sub-app.id
  network_security_group_id = azurerm_network_security_group.nsg-hub01.id
}

resource "azurerm_subnet_network_security_group_association" "adds-nsg-association" {
  subnet_id                 = azurerm_subnet.sub-adds.id
  network_security_group_id = azurerm_network_security_group.nsg-hub01.id
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
  name                         = "hub-to-spoke01"
  resource_group_name          = azurerm_resource_group.rg-cloudshoes-prd.name
  virtual_network_name         = azurerm_virtual_network.vnet-hub.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-spoke01.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "vnet-spoke01_to_vnet-hub" {
  name                         = "spoke01-to-hub"
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

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "app-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name  = "vm-app"
    admin_username = var.vm_admin_username
    admin_password = var.vm_admin_password
  }

  os_profile_windows_config {
    timezone           = "E. South America Standard Time"
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

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "adds-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name  = "vm-adds"
    admin_username = var.vm_admin_username
    admin_password = var.vm_admin_password
  }

  os_profile_windows_config {
    timezone           = "E. South America Standard Time"
    provision_vm_agent = true
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

resource "azurerm_private_endpoint" "vm-db-private-endpoint" {
  name                = "vm-db-private-endpoint"
  location            = azurerm_resource_group.rg-cloudshoes-prd.location
  resource_group_name = azurerm_resource_group.rg-cloudshoes-prd.name
  subnet_id           = azurerm_subnet.sub-db.id

  private_service_connection {
    name                           = "vm-db-privateserviceconnection"
    private_connection_resource_id = azurerm_virtual_machine.vm-db.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

#vm-db
resource "azurerm_virtual_machine" "vm-db" {
  name                  = "vm-db"
  location              = var.vnet-spoke01_location
  resource_group_name   = azurerm_resource_group.rg-cloudshoes-prd.name
  network_interface_ids = [azurerm_network_interface.nic-db.id]
  vm_size               = "Standard_D2s_v3"
  tags = {
    "Ambiente" = "prd"
    "Cenario"  = "IaaS"
    "ManagedBy" = "terraform"
  }

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  # storage_image_reference {
  #   publisher = "MicrosoftSQLServer"
  #   offer     = "WS2022"
  #   sku       = "SQLDEV"
  #   version   = "latest"
  # }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "db-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "vm-db"
    admin_username = var.vm_admin_username
    admin_password = var.vm_admin_password
  }

  os_profile_windows_config {
    timezone           = "E. South America Standard Time"
    provision_vm_agent = true
  }

  #  diagnostics_profile {
  #    boot_diagnostics {
  #      enabled     = true
  #      storage_uri = azurerm_storage_account.sa-bootdiag.primary_blob_endpoint
  #    }
  #  }

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
}

resource "azurerm_mssql_server" "ms-sql-server" {
  name                         = "cloudshoes-sql-server"
  resource_group_name          = azurerm_resource_group.rg-cloudshoes-prd.name
  location                     = azurerm_resource_group.rg-cloudshoes-prd.location
  version                      = "12.0"
  administrator_login          = "admsql"
  administrator_login_password = "Partiunuvem@2023"
  minimum_tls_version          = "1.2"

  # Integração ao AD, consultar: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server

  #  azuread_administrator {
  #    login_username = azurerm_user_assigned_identity.example.name
  #    object_id      = azurerm_user_assigned_identity.example.principal_id
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
