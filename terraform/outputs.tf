# Outputs for Claude Code LXC Application Infrastructure

output "application_urls" {
  description = "Application access URLs"
  value = {
    load_balancer = "http://localhost:8080"
    instances = [
      for i in range(var.replicas) : "http://localhost:${var.port + i}"
    ]
    health_check = "http://localhost:8080/health"
  }
}

output "database_connection" {
  description = "Database connection details (non-sensitive)"
  value = {
    host     = "localhost"
    port     = 5432
    database = "claude_${var.environment}"
    user     = "claude_code"
  }
}

output "cache_connection" {
  description = "Cache connection details"
  value = {
    host = "localhost"
    port = 6379
    url  = "redis://localhost:6379"
  }
}

output "monitoring_urls" {
  description = "Monitoring service URLs"
  value = var.enable_monitoring ? {
    prometheus = "http://localhost:9090"
    metrics    = "http://localhost:8080/metrics"
  } : {}
}

output "docker_networks" {
  description = "Created Docker networks"
  value = {
    app_network = "${var.app_name}-network-${var.environment}"
    db_network  = "${var.app_name}-db-network-${var.environment}"
  }
}

output "container_names" {
  description = "Names of created containers"
  value = {
    application = [
      for i in range(var.replicas) : "${var.app_name}-${i + 1}-${var.environment}"
    ]
    database     = "${var.app_name}-postgres-${var.environment}"
    cache        = "${var.app_name}-redis-${var.environment}"
    load_balancer = "${var.app_name}-nginx-${var.environment}"
    monitoring   = var.enable_monitoring ? "${var.app_name}-prometheus-${var.environment}" : null
  }
}

output "environment_info" {
  description = "Environment configuration summary"
  value = {
    name             = var.environment
    app_version      = var.app_version
    replicas         = var.replicas
    monitoring       = var.enable_monitoring
    ssl_enabled      = var.enable_ssl
    backup_retention = var.backup_retention_days
  }
}

# Sensitive outputs (use with caution)
output "database_password" {
  description = "Database password (sensitive)"
  value       = var.postgres_password != "" ? var.postgres_password : "dev_password_${var.environment}"
  sensitive   = true
}

output "connection_strings" {
  description = "Full connection strings (sensitive)"
  value = {
    database = "postgresql://claude_code:${var.postgres_password != "" ? var.postgres_password : "dev_password_${var.environment}"}@localhost:5432/claude_${var.environment}"
    cache    = "redis://localhost:6379"
  }
  sensitive = true
}