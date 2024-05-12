terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.103.1"
    }
  }
}


provider "azurerm" {
  features {}
  subscription_id = "27d13b5e-2698-472d-a869-93da20c061d5"
  tenant_id       = "bce8dd2e-d150-45ed-95fc-3ab94970431d"
}

resource "azurerm_resource_group" "rg_yazure_online_events" {
  name     = "rg-yazure-online-events"
  location = "australiaeast"
}

# Eventgrid Topic

resource "azurerm_eventgrid_topic" "eg_topic_yazure" {
  name                = "eg-topic-yazure-onnline"
  location            = azurerm_resource_group.rg_yazure_online_events.location
  resource_group_name = azurerm_resource_group.rg_yazure_online_events.name
  input_schema  = "EventGridSchema"  
}

# Azure Service Bus for Event Handling

resource "azurerm_servicebus_namespace" "sb_namespace_eg_sub" {
  name                = "sb-yazure-online"
  location            = azurerm_resource_group.rg_yazure_online_events.location
  resource_group_name = azurerm_resource_group.rg_yazure_online_events.name
  sku                 = "Standard"  
  
}

resource "azurerm_servicebus_queue" "sbq_sub_eg" {
  name         = "eg-subscription-queue"
  namespace_id = azurerm_servicebus_namespace.sb_namespace_eg_sub.id
  enable_partitioning = true
  requires_duplicate_detection = true
}

# Event Subscription
resource "azurerm_eventgrid_event_subscription" "event_sub" {
  name  = "event-sub-yazure-online-events"
  scope = azurerm_eventgrid_topic.eg_topic_yazure.id
  service_bus_queue_endpoint_id = azurerm_servicebus_queue.sbq_sub_eg.id
  included_event_types = var.event_type
  delivery_property {
    header_name = "MessageId"
    type = "Dynamic"
    source_field = "id"
  }
}

# Permissions
resource "azurerm_role_assignment" "rbac_eg_data_sender_yashika" {
  scope                = azurerm_eventgrid_topic.eg_topic_yazure.id
  role_definition_name = "EventGrid Data Sender"
  principal_id         = data.azuread_user.yashika_user.object_id
}


resource "azurerm_role_assignment" "rbac_sb_data_owner_yashika" {
  scope                = azurerm_servicebus_namespace.sb_namespace_eg_sub.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = data.azuread_user.yashika_user.object_id
}


output "eventgrid_topic_endpoint" {
  value = azurerm_eventgrid_topic.eg_topic_yazure.endpoint
  description = "EventGrid Endpoint To send Events"
}

output "servicebus_namespace_endpoint" {
  value = azurerm_servicebus_namespace.sb_namespace_eg_sub.endpoint
  description = "Servicebus Namespace Endpoint To receive messages"
}
