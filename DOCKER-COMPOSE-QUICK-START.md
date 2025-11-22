# Docker Compose Quick Start Guide

## Prerequisites

- Docker Engine 20.10+ installed
- Docker Compose v2.0+ installed (or docker-compose v1.29+)
- Ports 3306, 4200, 8080 available on your machine

## Quick Start

### 1. Build and Start All Services

```bash
# From project root directory
docker-compose up --build
```

This will:
- Build backend Docker image from `node-js-server/Dockerfile`
- Build frontend Docker image from `angular-14-client/Dockerfile`
- Pull MySQL 8.0 image
- Start all three services with proper dependency order
- Show logs from all services in terminal

### 2. Access the Application

- **Frontend (Angular):** http://localhost:4200
- **Backend API:** http://localhost:8080/api/tutorials
- **MySQL Database:**
  ```bash
  mysql -h 127.0.0.1 -u root -p123456 testdb
  ```

### 3. Stop Services

```bash
# Stop and remove containers (keeps volumes)
docker-compose down

# Stop and remove containers AND volumes (deletes database data)
docker-compose down -v
```

## Common Commands

### Development Workflow

```bash
# Start services in background (detached mode)
docker-compose up -d

# View logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View logs for specific service
docker-compose logs backend
docker-compose logs -f mysql

# Check service status
docker-compose ps

# Restart specific service
docker-compose restart backend

# Stop all services
docker-compose stop

# Start stopped services
docker-compose start
```

### Rebuilding After Code Changes

```bash
# Rebuild and restart specific service
docker-compose up -d --build backend

# Rebuild and restart all services
docker-compose up -d --build
```

### Database Operations

```bash
# Connect to MySQL from host
mysql -h 127.0.0.1 -u root -p123456 testdb

# Execute SQL via docker
docker-compose exec mysql mysql -u root -p123456 testdb -e "SELECT * FROM tutorials;"

# Access MySQL shell in container
docker-compose exec mysql bash
```

### Debugging

```bash
# Execute command in running container
docker-compose exec backend sh
docker-compose exec frontend sh

# View full configuration
docker-compose config

# View environment variables
docker-compose exec backend env

# Inspect volumes
docker volume ls
docker volume inspect <volume-name>
```

## Service Architecture

```
┌─────────────────────────────────────────┐
│          Host Machine (Your PC)          │
│                                          │
│  Browser ──> http://localhost:4200      │
│         │                                │
│         └──> http://localhost:8080/api  │
└─────────────────────────────────────────┘
         │                    │
         │                    │
    Port 4200             Port 8080
         │                    │
         ▼                    ▼
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   Frontend   │      │   Backend    │      │    MySQL     │
│              │      │              │──────▶│              │
│ nginx:alpine │      │ node:18      │      │  mysql:8.0   │
│              │      │              │      │              │
│ Port: 80     │      │ Port: 8080   │      │ Port: 3306   │
└──────────────┘      └──────────────┘      └──────────────┘
         │                    │                    │
         └────────────────────┴────────────────────┘
                    crud-network (bridge)
```

## Configuration Files

### docker-compose.yml
Main orchestration file defining:
- Services (mysql, backend, frontend)
- Networks (crud-network)
- Volumes (mysql-data)
- Port mappings
- Environment variables
- Dependencies

### Backend Configuration
- **Dockerfile:** `node-js-server/Dockerfile`
- **Environment Variables:**
  - `DB_HOST=mysql` (MySQL service name)
  - `DB_USER=root`
  - `DB_PASSWORD=123456`
  - `DB_NAME=testdb`

### Frontend Configuration
- **Dockerfile:** `angular-14-client/Dockerfile`
- **No environment variables needed** (API calls are client-side from browser)

## Data Persistence

MySQL data is stored in named volume `mysql-data`:

```bash
# View volumes
docker volume ls

# Inspect volume
docker volume inspect crud_mysql-data

# Backup volume
docker run --rm -v crud_mysql-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/mysql-backup.tar.gz -C /data .

# Restore volume
docker run --rm -v crud_mysql-data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/mysql-backup.tar.gz -C /data
```

## Troubleshooting

### Port Conflicts

If ports are already in use:

```bash
# Check what's using a port
lsof -i :8080
lsof -i :4200
lsof -i :3306

# Kill process or change port in docker-compose.yml
```

### Backend Can't Connect to MySQL

```bash
# Check MySQL is healthy
docker-compose ps

# View MySQL logs
docker-compose logs mysql

# Verify environment variables
docker-compose exec backend env | grep DB_

# Test connection from backend container
docker-compose exec backend sh
apk add mysql-client
mysql -h mysql -u root -p123456 testdb
```

### Frontend Shows Empty Page

```bash
# Check nginx is serving files
docker-compose logs frontend

# Verify build artifacts exist
docker-compose exec frontend ls -la /usr/share/nginx/html

# Check browser console for API errors
# Open DevTools in browser and check Console + Network tabs
```

### Services Start in Wrong Order

```bash
# Verify health check passes
docker-compose ps

# Check depends_on configuration
docker-compose config | grep -A5 depends_on

# Increase health check retries in docker-compose.yml if needed
```

### Clean Restart

```bash
# Stop everything
docker-compose down

# Remove volumes (deletes database data!)
docker-compose down -v

# Remove all images
docker-compose down --rmi all

# Clean build and start
docker-compose up --build
```

## Environment-Specific Configuration

### Local Development vs Docker

The application works in both environments:

**Local Development:**
- MySQL on `localhost:3306`
- Backend on `localhost:8080`
- Frontend dev server on `localhost:8081`
- Run: `node server.js` and `ng serve`

**Docker:**
- MySQL in container (service name: `mysql`)
- Backend in container (port mapped to `8080`)
- Frontend in nginx container (port mapped to `4200`)
- Run: `docker-compose up`

The codebase adapts automatically using environment variable fallbacks.

## CI/CD Integration

Use in GitHub Actions or other CI/CD:

```yaml
- name: Start services
  run: docker-compose up -d

- name: Wait for services
  run: |
    timeout 60 sh -c 'until docker-compose ps | grep healthy; do sleep 2; done'

- name: Run tests
  run: |
    curl http://localhost:8080/api/tutorials
    curl http://localhost:4200

- name: Stop services
  run: docker-compose down
```

## Production Considerations

For production deployment, consider:

1. **Security:**
   - Use secrets management (not hardcoded passwords)
   - Run containers as non-root user
   - Enable TLS/SSL for MySQL connections
   - Configure nginx with security headers

2. **Performance:**
   - Adjust MySQL pool size in db.config.js
   - Configure nginx caching
   - Use production-grade MySQL configuration

3. **Monitoring:**
   - Add health check endpoints
   - Configure logging aggregation
   - Set up monitoring and alerts

4. **Scaling:**
   - Use docker-compose scale or Kubernetes for orchestration
   - Add load balancer for multiple backend instances
   - Configure MySQL replication

## Getting Help

- Docker Compose docs: https://docs.docker.com/compose/
- Troubleshooting: Check `docker-compose logs -f`
- MySQL connection issues: Verify service names and environment variables
- Port conflicts: Use `lsof -i` to find conflicting processes

---

**Happy Dockerizing! 🐳**
