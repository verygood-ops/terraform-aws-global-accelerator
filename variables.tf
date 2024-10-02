
################################################################################
# VGS vars
################################################################################

variable "infra_environment" {
  description = "VGS infra environment: dev|prod etc"
  type        = string
}

variable "deployment_environment" {
  description = "VGS deployment environment: vault|genpop"
  type        = string
}

variable "data_environment" {
  description = "VGS data environment: sandbox|live etc"
  type        = string
}

variable "service" {
  type = string
}

variable "product" {
  type = string
}

variable "team" {
  type = string
}

variable "tenant" {
  type = string
}

variable "create" {
  description = "Controls if resources should be created (affects nearly all resources)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Accelerator
################################################################################

variable "name" {
  description = "The name of the accelerator"
  type        = string
  default     = ""
}

variable "ip_address_type" {
  description = "The value for the address type. Defaults to `IPV4`. Valid values: `IPV4`, `DUAL_STACK`"
  type        = string
  default     = "IPV4"
}

variable "ip_addresses" {
  description = "The IP addresses to use for BYOIP accelerators. If not specified, the service assigns IP addresses. Valid values: 1 or 2 IPv4 addresses"
  type        = list(string)
  default     = []
}

variable "enabled" {
  description = "Indicates whether the accelerator is enabled. Defaults to `true`. Valid values: `true`, `false`"
  type        = bool
  default     = true
}

variable "flow_logs_enabled" {
  description = "Indicates whether flow logs are enabled. Defaults to `false`"
  type        = bool
  default     = false
}

variable "flow_logs_s3_bucket" {
  description = "The name of the Amazon S3 bucket for the flow logs. Required if `flow_logs_enabled` is `true`"
  type        = string
  default     = null
}

variable "flow_logs_s3_prefix" {
  description = "The prefix for the location in the Amazon S3 bucket for the flow logs. Required if `flow_logs_enabled` is `true`"
  type        = string
  default     = null
}

################################################################################
# Listener(s)
################################################################################

variable "create_listeners" {
  description = "Controls if listeners should be created (affects only listeners)"
  type        = bool
  default     = true
}

variable "listeners_timeouts" {
  description = "Create, update, and delete timeout configurations for the listeners"
  type        = map(string)
  default     = {}
}

################################################################################
# Endpoing Group(s)
################################################################################

# Endpoint groups are nested with the listener defintion

variable "endpoint_groups_timeouts" {
  description = "Create, update, and delete timeout configurations for the endpoint groups"
  type        = map(string)
  default     = {}
}

variable "endpoint_groups" {
  description = "Map of endpoint groups configurations"
  type = map(object({
    endpoints = list(object({
      endpoint_id                    = string
      weight                         = number
      client_ip_preservation_enabled = optional(bool, true) # Set default to true
    }))
    traffic_dial_percentage = number
  }))
}

variable "listener_ports" {
  description = "Map of listener ports (from_port to to_port)"
  type        = map(number)
}
