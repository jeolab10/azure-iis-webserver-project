locals {
  common_tags = {
    Environment = var.environment
    Project     = "Azure-IIS-Web-Hosting"
    Company     = var.company_name
    ManagedBy   = "Terraform"
  }

  iis_script_base64 = base64encode(
    file("${path.module}/../scripts/install-iis.ps1")
  )
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}
resource "azurerm_virtual_network" "main" {
  name                = "vnet-company-iis-dev-cac"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  address_space = ["10.20.0.0/16"]

  tags = local.common_tags
}
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name

  address_prefixes = ["10.20.1.0/24"]
}
resource "azurerm_network_security_group" "web" {
  name                = "nsg-company-web"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}
resource "azurerm_network_security_rule" "http" {
  name      = "Allow-HTTP"
  priority  = 100
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.web.name
}
resource "azurerm_public_ip" "web" {
  name                = "pip-company-web"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = local.common_tags
}
resource "azurerm_network_interface" "web" {
  name                = "nic-company-web"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }

  tags = local.common_tags
}
resource "azurerm_network_interface_security_group_association" "web" {
  network_interface_id      = azurerm_network_interface.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}
resource "azurerm_windows_virtual_machine" "web" {
  name                = var.vm_name
  computer_name       = "companyiis01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size

  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.web.id
  ]

  provision_vm_agent = true

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {}

  tags = local.common_tags

  depends_on = [
    azurerm_network_interface_security_group_association.web
  ]
}
resource "azurerm_network_security_rule" "rdp" {
  name      = "Allow-RDP-Trusted-IP"
  priority  = 110
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range          = "*"
  destination_port_range     = "3389"
  source_address_prefix      = var.allowed_rdp_source
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.web.name
}
resource "azurerm_virtual_machine_extension" "iis" {
  name                 = "install-iis"
  virtual_machine_id   = azurerm_windows_virtual_machine.web.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  auto_upgrade_minor_version = true

  protected_settings = jsonencode({
    commandToExecute = join(
      " ",
      [
        "powershell.exe",
        "-NoLogo",
        "-NonInteractive",
        "-ExecutionPolicy Bypass",
        "-Command",
        "\"$scriptContent = [System.Text.Encoding]::UTF8.GetString(",
        "[System.Convert]::FromBase64String('${local.iis_script_base64}'));",
        "$scriptPath = 'C:\\install-iis.ps1';",
        "[System.IO.File]::WriteAllText($scriptPath, $scriptContent);",
        "& $scriptPath\""
      ]
    )
  })

  tags = local.common_tags
}