# Terraform configuration for Claude Code LXC Application Infrastructure
# Focus: Container-based application deployment and infrastructure automation
# This demonstrates Infrastructure as Code for applications developed in LXC environment

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Variables for environment configuration
variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "claude-code-app"
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
}

variable "replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

# Docker provider configuration
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Application network
resource "docker_network" "app_network" {
  name = "${var.app_name}-network-${var.environment}"
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "managed_by"
    value = "terraform"
  }
}

# Database network (separate for security)
resource "docker_network" "db_network" {
  name = "${var.app_name}-db-network-${var.environment}"
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "tier"
    value = "database"
  }
}

# PostgreSQL database
resource "docker_container" "postgres" {
  name  = "${var.app_name}-postgres-${var.environment}"
  image = "postgres:15-alpine"
  
  env = [
    "POSTGRES_DB=claude_${var.environment}",
    "POSTGRES_USER=claude_code",
    "POSTGRES_PASSWORD=dev_password_${var.environment}",
    "POSTGRES_INITDB_ARGS=--encoding=UTF8 --lc-collate=C --lc-ctype=C"
  ]
  
  ports {
    internal = 5432
    external = var.environment == "development" ? 5432 : null
  }
  
  volumes {
    container_path = "/var/lib/postgresql/data"
    host_path      = "${path.cwd}/data/postgres-${var.environment}"
  }
  
  networks_advanced {
    name = docker_network.db_network.name
  }
  
  restart = "unless-stopped"
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "service"
    value = "database"
  }
}

# Redis cache
resource "docker_container" "redis" {
  name  = "${var.app_name}-redis-${var.environment}"
  image = "redis:7-alpine"
  
  command = [
    "redis-server",
    "--appendonly", "yes",
    "--maxmemory", "256mb",
    "--maxmemory-policy", "allkeys-lru"
  ]
  
  ports {
    internal = 6379
    external = var.environment == "development" ? 6379 : null
  }
  
  volumes {
    container_path = "/data"
    host_path      = "${path.cwd}/data/redis-${var.environment}"
  }
  
  networks_advanced {
    name = docker_network.db_network.name
  }
  
  restart = "unless-stopped"
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "service"
    value = "cache"
  }
}

# Application containers
resource "docker_container" "app" {
  count = var.replicas
  
  name  = "${var.app_name}-${count.index + 1}-${var.environment}"
  image = "${var.app_name}:${var.app_version}"
  
  env = [
    "NODE_ENV=${var.environment}",
    "PORT=${var.port}",
    "DATABASE_URL=postgresql://claude_code:dev_password_${var.environment}@${docker_container.postgres.name}:5432/claude_${var.environment}",
    "REDIS_URL=redis://${docker_container.redis.name}:6379",
    "LOG_LEVEL=${var.environment == "production" ? "info" : "debug"}",
    "INSTANCE_ID=${count.index + 1}"
  ]
  
  ports {
    internal = var.port
    external = var.port + count.index
  }
  
  networks_advanced {
    name = docker_network.app_network.name
  }
  
  networks_advanced {
    name = docker_network.db_network.name
  }
  
  restart = "unless-stopped"
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "service"
    value = "application"
  }
  
  labels {
    label = "instance"
    value = tostring(count.index + 1)
  }
  
  # Health check
  healthcheck {
    test     = ["CMD", "curl", "-f", "http://localhost:${var.port}/health"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
  }
  
  depends_on = [
    docker_container.postgres,
    docker_container.redis
  ]
}

# Load balancer (nginx)
resource "docker_container" "nginx" {
  name  = "${var.app_name}-nginx-${var.environment}"
  image = "nginx:alpine"
  
  ports {
    internal = 80
    external = 8080
  }
  
  volumes {
    container_path = "/etc/nginx/nginx.conf"
    host_path      = local_file.nginx_config.filename
    read_only      = true
  }
  
  networks_advanced {
    name = docker_network.app_network.name
  }
  
  restart = "unless-stopped"
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "service"
    value = "load_balancer"
  }
  
  depends_on = [docker_container.app]
}

# Nginx configuration
resource "local_file" "nginx_config" {
  filename = "${path.cwd}/config/nginx-${var.environment}.conf"
  
  content = templatefile("${path.module}/templates/nginx.conf.tpl", {
    app_name    = var.app_name
    environment = var.environment
    port        = var.port
    replicas    = var.replicas
  })
}

# Monitoring (Prometheus - basic setup)
resource "docker_container" "prometheus" {
  count = var.environment != "production" ? 1 : 0
  
  name  = "${var.app_name}-prometheus-${var.environment}"
  image = "prom/prometheus:latest"
  
  ports {
    internal = 9090
    external = 9090
  }
  
  volumes {
    container_path = "/etc/prometheus/prometheus.yml"
    host_path      = local_file.prometheus_config[0].filename
    read_only      = true
  }
  
  networks_advanced {
    name = docker_network.app_network.name
  }
  
  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--web.console.libraries=/etc/prometheus/console_libraries",
    "--web.console.templates=/etc/prometheus/consoles",
    "--web.enable-lifecycle"
  ]
  
  restart = "unless-stopped"
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "service"
    value = "monitoring"
  }
}

# Prometheus configuration
resource "local_file" "prometheus_config" {
  count = var.environment != "production" ? 1 : 0
  
  filename = "${path.cwd}/config/prometheus-${var.environment}.yml"
  
  content = templatefile("${path.module}/templates/prometheus.yml.tpl", {
    app_name    = var.app_name
    environment = var.environment
    port        = var.port
    replicas    = var.replicas
  })
}

# Output values
output "application_urls" {
  description = "Application access URLs"
  value = {
    load_balancer = "http://localhost:8080"
    instances = [
      for i in range(var.replicas) : "http://localhost:${var.port + i}"
    ]
  }
}

output "database_connection" {
  description = "Database connection details"
  value = {
    host     = "localhost"
    port     = 5432
    database = "claude_${var.environment}"
    user     = "claude_code"
  }
  sensitive = false
}

output "monitoring_urls" {
  description = "Monitoring service URLs"
  value = var.environment != "production" ? {
    prometheus = "http://localhost:9090"
  } : {}
}

output "docker_networks" {
  description = "Created Docker networks"
  value = {
    app_network = docker_network.app_network.name
    db_network  = docker_network.db_network.name
  }
}