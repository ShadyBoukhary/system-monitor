# Docker Monitoring Stack

A comprehensive Docker-based monitoring solution for servers, containers, and system resources. This stack includes Prometheus for metrics collection, Grafana for visualization, and various exporters for detailed system monitoring.

## Features

- **System Monitoring**: CPU, memory, disk, and network metrics via Node Exporter
- **Container Monitoring**: Docker container metrics via cAdvisor
- **Process Monitoring**: Detailed process-level monitoring via Process Exporter
- **ZFS Monitoring**: ZFS pool and dataset metrics (if ZFS is available)
- **Uptime Monitoring**: Website and service uptime monitoring via Uptime Kuma
- **Container Management**: Docker container management via Portainer
- **Custom Dashboards**: Pre-configured Grafana dashboards for comprehensive monitoring

## Components

| Service | Port | Description |
|---------|------|-------------|
| Grafana | 3000 | Visualization and dashboards |
| Prometheus | 9090 | Metrics collection and storage |
| Node Exporter | 9100 | System metrics |
| Process Exporter | 9256 | Process-level metrics |
| cAdvisor | 8081 | Container metrics |
| Uptime Kuma | 3001 | Uptime monitoring |
| Portainer | 9443 | Container management |

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd docker-monitoring-stack
   ```

2. **Configure environment variables**:
   ```bash
   cp .env.example .env
   nano .env  # Edit with your settings
   ```

3. **Start the monitoring stack**:
   ```bash
   docker compose up -d
   ```

4. **Access the services**:
   - Grafana: http://localhost:3000 (admin/your_password)
   - Prometheus: http://localhost:9090
   - Uptime Kuma: http://localhost:3001
   - Portainer: https://localhost:9443
   ```bash
   cd /home/weaver/apps/monitor
   cp .env.example .env
   # Edit .env with your settings
   ```

5. **Start the monitoring stack:**
   ```bash
   docker-compose up -d
   ```

6. **Access services:**
   - Main Dashboard: https://localhost/grafana/
   - Uptime Monitoring: https://localhost/uptime/
   - Container Management: https://localhost/portainer/
   - Raw Metrics: https://localhost/prometheus/

## Default Credentials

- **Grafana**: admin / admin123 (change in .env)
- **Portainer**: Setup on first visit
- **Uptime Kuma**: Setup on first visit

## What You'll Monitor

### System Health
- CPU usage, load average
- Memory usage and swap
- Disk space and I/O
- Network traffic
- System uptime

### Docker Containers
- Container resource usage (CPU, RAM)
- Container status and health
- Image information
- Network usage per container

### ZFS (if enabled)
- Pool health and status
- Dataset usage
- ARC statistics
- Scrub status

### Services
- Website/service uptime
- Response times
- SSL certificate expiry
- Custom health checks

## Configuration

### Enable ZFS Monitoring
Uncomment the `zfs-exporter` service in `docker-compose.yml` if you have ZFS pools.

### SSL Certificate
The Caddy configuration snippet includes automatic HTTPS. If you're using Cloudflare, make sure your Caddy installation has the Cloudflare DNS plugin and add your API token to the environment.

### Adding to existing Caddyfile
Simply append the contents of `caddy-config-snippet.txt` to your existing `/etc/caddy/Caddyfile` and reload Caddy.

### Custom Dashboards
- Import community dashboards from grafana.com
- Popular dashboard IDs:
  - Node Exporter Full: 1860
  - Docker and System Monitoring: 893
  - Cadvisor exporter: 14282

## Maintenance

### Update containers:
```bash
docker-compose pull
docker-compose up -d
```

### View logs:
```bash
docker-compose logs -f [service_name]
```

### Backup data:
```bash
docker-compose down
sudo tar -czf monitoring-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/docker/volumes/monitor_*
```

## Troubleshooting

### Common Issues
1. **Permission denied for ZFS**: Run ZFS exporter with `privileged: true`
2. **Caddy certificate issues**: Check DNS settings and Cloudflare token
3. **High resource usage**: Adjust Prometheus retention time in docker-compose.yml

### Useful Commands
```bash
# Check service status
docker-compose ps

# Restart specific service
docker-compose restart grafana

# Check/reload Caddy config
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```
