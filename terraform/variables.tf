# Variables for Claude Code LXC Application Infrastructure

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "claude-code-app"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.app_name))
    error_message = "App name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "app_version" {
  description = "Application version tag"
  type        = string
  default     = "latest"
}

variable "port" {
  description = "Application port"
  type        = number
  default     = 3000
  
  validation {
    condition     = var.port > 1024 && var.port < 65536
    error_message = "Port must be between 1024 and 65535."
  }
}

variable "replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
  
  validation {
    condition     = var.replicas >= 1 && var.replicas <= 10
    error_message = "Replicas must be between 1 and 10."
  }
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus)"
  type        = bool
  default     = true
}

variable "enable_ssl" {
  description = "Enable SSL/TLS for load balancer"
  type        = bool
  default     = false
}

variable "resource_limits" {
  description = "Resource limits for containers"
  type = object({
    app_memory    = string
    app_cpu       = string
    db_memory     = string
    db_cpu        = string
    cache_memory  = string
  })
  default = {
    app_memory   = "512m"
    app_cpu      = "0.5"
    db_memory    = "1g"
    db_cpu       = "1.0"
    cache_memory = "256m"
  }
}

variable "backup_retention_days" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 1 and 365 days."
  }
}