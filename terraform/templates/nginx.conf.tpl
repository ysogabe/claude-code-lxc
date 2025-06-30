events {
    worker_connections 1024;
}

http {
    upstream ${app_name}_backend {
        %{ for i in range(replicas) ~}
        server ${app_name}-${i + 1}-${environment}:${port};
        %{ endfor ~}
    }
    
    server {
        listen 80;
        server_name localhost;
        
        # Health check endpoint
        location /health {
            access_log off;
            proxy_pass http://${app_name}_backend/health;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
        
        # Main application
        location / {
            proxy_pass http://${app_name}_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
        
        # Static assets (if serving from nginx)
        location /static/ {
            alias /var/www/static/;
            expires 30d;
        }
    }
    
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}