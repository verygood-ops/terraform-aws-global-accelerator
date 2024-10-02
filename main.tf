locals {
  # Transform the new input structure into the format expected by the rest of the module
  listeners = {
    "main" = {
      protocol    = "TCP"
      port_ranges = [for from_port, to_port in var.listener_ports : { from_port = from_port, to_port = to_port }]
      endpoint_groups = {
        for region, group in var.endpoint_groups : region => {
          endpoint_group_region   = region
          traffic_dial_percentage = group.traffic_dial_percentage
          endpoint_configuration = [
            for endpoint in group.endpoints : {
              endpoint_id                    = endpoint.endpoint_id
              weight                         = endpoint.weight
              client_ip_preservation_enabled = coalesce(endpoint.client_ip_preservation_enabled, true) # Use coalesce to default to true if not specified
            }
          ]
        }
      }
    }
  }

  # Flatten the listeners and endpoint groups for use in the existing resources
  listener_endpoints = flatten([
    for lk, lv in local.listeners : [
      for ek, ev in lv.endpoint_groups : {
        listerner_name = lk
        endpoint_group = ek

        endpoint_group_region   = ev.endpoint_group_region
        traffic_dial_percentage = ev.traffic_dial_percentage
        endpoint_configuration  = ev.endpoint_configuration

        # Preserve existing fields with default values
        health_check_port             = try(ev.health_check_port, null)
        health_check_protocol         = try(ev.health_check_protocol, null)
        health_check_path             = try(ev.health_check_path, null)
        health_check_interval_seconds = try(ev.health_check_interval_seconds, null)
        threshold_count               = try(ev.threshold_count, null)
        port_override                 = try(ev.port_override, [])
      }
    ]
  ])
}

################################################################################
# Accelerator
################################################################################

resource "aws_globalaccelerator_accelerator" "this" {
  count = var.create ? 1 : 0

  name            = "${var.infra_environment}-${var.deployment_environment}-${var.data_environment}-${var.name}"
  ip_address_type = var.ip_address_type
  enabled         = var.enabled

  dynamic "attributes" {
    for_each = var.flow_logs_enabled ? [1] : []
    content {
      flow_logs_enabled   = var.flow_logs_enabled
      flow_logs_s3_bucket = var.flow_logs_s3_bucket
      flow_logs_s3_prefix = var.flow_logs_s3_prefix
    }
  }

  tags = {
    "vgs:service"     = var.service
    "vgs:product"     = var.product
    "vgs:team"        = var.team
    "vgs:environment" = "${var.infra_environment}/${var.deployment_environment}/${var.data_environment}"
    "vgs:tenant"      = var.tenant

  }
}

################################################################################
# Listener(s)
################################################################################

resource "aws_globalaccelerator_listener" "this" {
  for_each = { for k, v in local.listeners : k => v if var.create && var.create_listeners }

  accelerator_arn = aws_globalaccelerator_accelerator.this[0].id
  client_affinity = lookup(each.value, "client_affinity", null)
  protocol        = lookup(each.value, "protocol", null)

  dynamic "port_range" {
    for_each = try(each.value.port_ranges, null) != null ? each.value.port_ranges : []
    content {
      from_port = lookup(port_range.value, "from_port", null)
      to_port   = lookup(port_range.value, "to_port", null)
    }
  }

  timeouts {
    create = lookup(var.listeners_timeouts, "create", null)
    update = lookup(var.listeners_timeouts, "update", null)
    delete = lookup(var.listeners_timeouts, "delete", null)
  }
}

################################################################################
# Endpoint Group(s)
################################################################################

resource "aws_globalaccelerator_endpoint_group" "this" {
  for_each = { for v in local.listener_endpoints : "${v.listerner_name}-${v.endpoint_group}" => v if var.create && var.create_listeners }

  listener_arn = aws_globalaccelerator_listener.this[each.value.listerner_name].id

  endpoint_group_region         = each.value.endpoint_group_region
  health_check_interval_seconds = each.value.health_check_interval_seconds
  health_check_path             = each.value.health_check_path
  health_check_port             = each.value.health_check_port
  health_check_protocol         = each.value.health_check_protocol
  threshold_count               = each.value.threshold_count
  traffic_dial_percentage       = each.value.traffic_dial_percentage

  dynamic "endpoint_configuration" {
    for_each = [for e in each.value.endpoint_configuration : e if can(e.endpoint_id)]
    content {
      client_ip_preservation_enabled = coalesce(endpoint_configuration.value.client_ip_preservation_enabled, true) # Use coalesce to default to true if not specified
      endpoint_id                    = endpoint_configuration.value.endpoint_id
      weight                         = try(endpoint_configuration.value.weight, null)
    }
  }

  dynamic "port_override" {
    for_each = each.value.port_override
    content {
      endpoint_port = port_override.value.endpoint_port
      listener_port = port_override.value.listener_port
    }
  }

  timeouts {
    create = lookup(var.endpoint_groups_timeouts, "create", null)
    update = lookup(var.endpoint_groups_timeouts, "update", null)
    delete = lookup(var.endpoint_groups_timeouts, "delete", null)
  }
}
