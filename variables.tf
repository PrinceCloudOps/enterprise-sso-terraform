variable "app_display_name" {
  description = "Display name of the federated Enterprise Application"
  type        = string
  default     = "Salesforce-Enterprise-CRM-SSO"
}

variable "sales_group_name" {
  description = "Name of the synced AD Security Group granted access to the CRM app"
  type        = string
  default     = "SG-Sales"
}

variable "hr_group_name" {
  description = "Name of the synced AD Security Group for HR (used to demonstrate RBAC separation)"
  type        = string
  default     = "SG-HR"
}
