global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Application instances
  - job_name: '${app_name}-${environment}'
    static_configs:
      - targets:
        %{ for i in range(replicas) ~}
        - '${app_name}-${i + 1}-${environment}:${port}'
        %{ endfor ~}
    metrics_path: '/metrics'
    scrape_interval: 30s
    
  # Load balancer
  - job_name: 'nginx-${environment}'
    static_configs:
      - targets: ['${app_name}-nginx-${environment}:80']
    metrics_path: '/nginx_status'
    scrape_interval: 30s
    
  # Database
  - job_name: 'postgres-${environment}'
    static_configs:
      - targets: ['${app_name}-postgres-${environment}:5432']
    scrape_interval: 60s
    
  # Redis
  - job_name: 'redis-${environment}'
    static_configs:
      - targets: ['${app_name}-redis-${environment}:6379']
    scrape_interval: 60s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093