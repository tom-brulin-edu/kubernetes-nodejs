terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.48.0"
    }
  }

  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
}

# PostgreSQL
resource "azurerm_postgresql_server" "pgsql" {
  name                = "pgsql-${var.project_name}${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  administrator_login          = data.azurerm_key_vault_secret.db-login.value
  administrator_login_password = data.azurerm_key_vault_secret.db-password.value

  sku_name   = "GP_Gen5_4"
  version    = "11"
  storage_mb = 5120

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false

  public_network_access_enabled    = true
  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
}

resource "azurerm_postgresql_firewall_rule" "pgsql" {
  name                = "AllowAzureServices"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.pgsql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Webapp
resource "azurerm_service_plan" "app-plan" {
  name                = "plan-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_linux_web_app" "webapp" {
  name                = "web-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.app-plan.id

  site_config {
    application_stack {
      node_version = "16-lts"
    }
  }


  app_settings = {
    "PORT"                      = var.webapp_port
    "DB_HOST"                   = azurerm_postgresql_server.pgsql.fqdn
    "DB_USERNAME"               = "${data.azurerm_key_vault_secret.db-login.value}@${azurerm_postgresql_server.pgsql.name}"
    "DB_PASSWORD"               = data.azurerm_key_vault_secret.db-password.value
    "DB_DATABASE"               = "postgres"
    "DB_DAILECT"                = "postgres"
    "DB_PORT"                   = 5432
    "ACCESS_TOKEN_SECTET"       = data.azurerm_key_vault_secret.access-token-secret.value
    "REFRESH_TOKEN_SECTET"      = data.azurerm_key_vault_secret.refresh-token-secret.value
    "ACCESS_TOKEN_EXPIRY"       = "15m"
    "REFRESH_TOKEN_EXPIRY"      = "7d"
    "REFRESH_TOKEN_COOKIE_NAME" = "jid"
  }
}


# PgAdmin Container Instance
resource "azurerm_container_group" "pgadmin" {
  name                = "aci-pgadmin-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  ip_address_type     = "Public"
  dns_name_label      = "aci-pgadmin-${var.project_name}${var.environment_suffix}"
  os_type             = "Linux"

  container {
    name   = "pgadmin"
    image  = "dpage/pgadmin4:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 443
      protocol = "TCP"
    }

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      "PGADMIN_DEFAULT_EMAIL"    = var.default_email
      "PGADMIN_DEFAULT_PASSWORD" = data.azurerm_key_vault_secret.db-password.value
    }
  }
}
