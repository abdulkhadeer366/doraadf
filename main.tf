provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "rg" {
  name     = "testrgshiva"
  location = "Central US"
}

resource "azurerm_data_factory" "adf" {
  name                = "testadfshiva"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_data_factory_dataset_azure_blob" "dataset1" {
  name                = "dataset1"
  resource_group_name = azurerm_resource_group.rg.name
  data_factory_name   = azurerm_data_factory.adf.name
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.linkedsource.name

  path     = "foo"
  filename = "bar.png"
}
resource "azurerm_data_factory_dataset_azure_blob" "dataset2" {
  name                = "dataset2"
  resource_group_name = azurerm_resource_group.rg.name
  data_factory_name   = azurerm_data_factory.adf.name
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.linkeddest.name

  path     = "xyz"
  filename = "xyz.png"
}


resource "azurerm_data_factory_pipeline" "pipeline_test" {
  name                = "pipelinetestshiva"
  resource_group_name = azurerm_resource_group.rg.name
  data_factory_name   = azurerm_data_factory.adf.name
  variables = {
    "bob" = "item1"
  }
  activities_json = <<JSON
 [
     {
        "name": "CopyActivityTemplate",
        "type": "Copy",
        "inputs": [ 
          {
                "referenceName": "dataset1",
                "type": "DatasetReference"
            }
        ],
        "outputs": [
            {
                "referenceName": "dataset2",
                "type": "DatasetReference"
            }

        ]
    }
 ]
   JSON
}
resource "azurerm_storage_account" "storage" {
  #count = 2
  name                     = "testshivastorageone"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_account" "storage2" {
  #count = 2
  name                     = "testshivastoragetwo"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "source" {
  name = "sourcecontainer"
  #resource_group_name   = azurerm_resource_group.rg.name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "target" {
  name                  = "targetcontainer"
  storage_account_name  = azurerm_storage_account.storage2.name
  container_access_type = "private"
}
resource "azurerm_data_factory_linked_service_azure_blob_storage" "linkedsource" {
  name                = "linkedservicesource"
  resource_group_name = azurerm_resource_group.rg.name
  data_factory_name   = azurerm_data_factory.adf.name
  connection_string   = azurerm_storage_account.storage.primary_connection_string
}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "linkeddest" {
  name                = "linkedservicedest"
  resource_group_name = azurerm_resource_group.rg.name
  data_factory_name   = azurerm_data_factory.adf.name
  connection_string   = azurerm_storage_account.storage2.primary_connection_string
}
resource "azurerm_data_factory_trigger_schedule" "testtrigger" {
  name                = "copytrigger"
  data_factory_name   = azurerm_data_factory.adf.name
  resource_group_name = azurerm_resource_group.rg.name
  pipeline_name       = azurerm_data_factory_pipeline.pipeline_test.name

  interval  = 1
  frequency = "Minute"
}
