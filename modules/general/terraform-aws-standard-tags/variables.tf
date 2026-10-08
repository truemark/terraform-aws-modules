variable "automation_component" {
  description = "Automation component tags"
  default     = null
  type = object({
    id     = string
    url    = optional(string)
    vendor = optional(string)
  })
}

variable "automation" {
  description = "Automation tags"
  default     = null
  type = object({
    id  = string
    url = optional(string)
  })
}

variable "cost_center" {
  description = "Cost center tags"
  default     = null
  type = object({
    business_unit_name = string
    business_unit_id   = optional(string)
    project_name       = string
    project_id         = optional(string)
    environment        = optional(string)
    contact_name       = optional(string)
    contact_email      = optional(string)
    contact_phone      = optional(string)
  })
}

variable "security" {
  description = "Security tags"
  default     = null
  type = object({
    data_classification = string
    data_sensitivity    = optional(string)
  })
  validation {
    condition     = var.security == null ? true : var.security.data_classification == null ? true : contains(["export-restricted", "restricted", "controlled", "public"], var.security.data_classification)
    error_message = "Allowed values for data_classification are \"export-restricted\", \"restricted\", \"controlled\" and \"public\""
  }
  validation {
    condition     = var.security == null ? true : var.security.data_sensitivity == null ? true : contains(["pci", "pii", "phi"], var.security.data_sensitivity)
    error_message = "Allowed values for data_sensitivity are \"pci\", \"pii\" and \"phi\""
  }
}

variable "team" {
  description = "Team tags"
  default     = null
  type = object({
    name          = string
    id            = optional(string)
    contact_name  = optional(string)
    contact_email = optional(string)
    contact_phone = optional(string)
    business_unit = optional(string)
    department    = optional(string)
  })
}
