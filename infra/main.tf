terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # --- REMOTE BACKEND CONFIGURATION ---
  # This configures Terraform to store the state file in Azure Blob Storage.
  # This allows multiple developers to work on the same infrastructure without conflicts.
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "statfstatejustino"
    container_name       = "tfstate-jenkins"
    key                  = "jenkins.terraform.tfstate"

    # NOTE: We are NOT hardcoding the 'access_key' here for security.
    # Terraform will use your 'az login' credentials to authenticate.
  }
}

provider "azurerm" {
  features {}
}

# --- VARIABLES (To make it collaborative) ---

variable "ssh_public_key_path" {
  description = "Path to the SSH public key to be used for VM authentication"
  type        = string
  default     = "~/.ssh/id_rsa_azure.pub"
  # Collaborator note: If your key is in a different path, 
  # create a 'terraform.tfvars' file and override this variable.
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-jenkins-lab"
  location = "East US 2"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-jenkins"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-jenkins"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Allow SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Jenkins UI Access
  security_rule {
    name                       = "Jenkins-UI"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
      name                       = "App-Python-Port"
      priority                   = 1010
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5000"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  security_rule {
      name                       = "Reddit-Clone-Port"
      priority                   = 1020
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3000-3001"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  security_rule {
      name                       = "Sonarqube-Port"
      priority                   = 1030
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "9000"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
}

# Public IP of Master
resource "azurerm_public_ip" "master_ip" {
  name                = "pip-jenkins-master"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "Standard" 
  allocation_method = "Static"
}

# Master NIC
resource "azurerm_network_interface" "master_nic" {
  name                = "nic-jenkins-master"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.master_ip.id
  }
}

# VM Master
resource "azurerm_linux_virtual_machine" "master_vm" {
  name                  = "vm-jenkins-master"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B2s" # 2 vCPU, 4GB RAM
  admin_username        = "ubuntu"
  network_interface_ids = [azurerm_network_interface.master_nic.id]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = filebase64("master-init.sh")
}

# --- Agent definition ---

# Public Ip of Agent
resource "azurerm_public_ip" "agent_ip" {
  name                = "pip-jenkins-agent"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "Standard"
  allocation_method = "Static"
}

resource "azurerm_network_interface" "agent_nic" {
  name                = "nic-jenkins-agent"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.agent_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "agent_vm" {
  name                  = "vm-jenkins-agent"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B2ms" # 2 vCPU, 8GB RAM
  admin_username        = "ubuntu"
  network_interface_ids = [azurerm_network_interface.agent_nic.id]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = file("~/.ssh/id_rsa_azure.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = filebase64("agent-init.sh")
}

# --- NSG ASSOCIATION (CRITICAL for Standard IPs) ---
# This associates the Security Group with the Subnet to allow traffic
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# --- OUTPUTS ---
output "jenkins_master_url" {
  value = "http://${azurerm_public_ip.master_ip.ip_address}:8080"
}

output "agent_public_ip" {
  value = azurerm_public_ip.agent_ip.ip_address
}