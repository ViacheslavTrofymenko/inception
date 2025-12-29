# Developer Documentation

## Project Architecture

This Inception project implements a three-tier web infrastructure using Docker containers:

```
[Client] --HTTPS--> [NGINX:443] --FastCGI--> [WordPress] --MySQL--> [MariaDB]
                                      |                              |
                                      +--- wordpress_data volume ----+
                                                                     |
                                                          mariadb_data volume
```

### Services

1. **NGINX** (nginx:1.3)
   - TLSv1.2/TLSv1.3 web server
   - Reverse proxy for WordPress
   - Exposes port 443 to host

2. **WordPress** (wordpress:1.2)
   - PHP-FPM with WordPress CMS
   - Depends on MariaDB
   - Serves content via FastCGI

3. **MariaDB** (mariadb:1.1)
   - MySQL-compatible database
   - Stores WordPress data
   - No exposed ports (internal network only)

### Network Architecture

All services communicate through a Docker bridge network named `inception`. Services reference each other by container name (e.g., WordPress connects to `mariadb:3306`).

## Environment Setup from Scratch

### Prerequisites

**System Requirements:**
- Docker Engine 20.10+
- Docker Compose 2.0+
- Make
- Sudo privileges
- Linux environment (tested on Ubuntu/Debian)

**Install Docker:**
```bash
# Update package index
sudo apt update

# Install Docker
sudo apt install docker.io docker-compose-v2

# Add user to docker group (optional, to avoid sudo)
sudo usermod -aG docker $USER
newgrp docker
```

### Configuration Files

#### 1. Environment Variables

Create/modify `srcs/.env`:

```bash
# Domain Configuration
DOMAIN_NAME=

# Database Configuration
DB_NAME=
DB_USER_NAME=

# WordPress Configuration
WP_TITLE=
WP_ADMIN_NAME=
WP_ADMIN_EMAIL=
WP_AUTHOR_USER=
WP_AUTHOR_EMAIL=
```

**Note**: Passwords are stored separately in the `secrets/` directory, NOT in the `.env` file.

#### 2. Secrets Configuration

Create the `secrets/` directory and password files:

```bash
mkdir -p secrets

# Generate secure random passwords (or use your own)
openssl rand -base64 32 > secrets/db_root_password.txt
openssl rand -base64 32 > secrets/db_password.txt
openssl rand -base64 32 > secrets/wp_admin_password.txt
openssl rand -base64 32 > secrets/wp_user_password.txt

# Set proper permissions
chmod 600 secrets/*.txt
```

**Important**: Add `secrets/` to `.gitignore` to prevent committing sensitive data:

```bash
echo "secrets/" >> .gitignore
```

#### 3. SSL Certificates

SSL certificates are generated automatically during NGINX container build. For custom certificates, place them in `srcs/requirements/nginx/tools/`:

- `nginx.crt` - SSL certificate
- `nginx.key` - Private key

#### 4. Update Login Variable

Modify the `LOGIN` variable in the `Makefile` to match your username:

```makefile
LOGIN = your_username
```

This ensures volumes are created in the correct home directory.

## Building and Launching

### Initial Build

```bash
# From project root
make all
```

This performs:
1. Creates directories: `/home/$(LOGIN)/data/mariadb` and `/home/$(LOGIN)/data/wordpress`
2. Sets ownership (MariaDB: 100:101, WordPress: 82:82)
3. Builds all Docker images
4. Starts containers in detached mode

### Build Individual Services

```bash
# Build specific service
docker compose -f srcs/docker-compose.yml build nginx
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml build mariadb
```

### Rebuild After Changes

```bash
# Rebuild specific service
docker compose -f srcs/docker-compose.yml up -d --build nginx

# Rebuild everything
make re
```

## Container Management Commands

### Start/Stop Containers

```bash
# Start all services
docker compose -f srcs/docker-compose.yml up -d

# Stop all services
make stop
# or
docker compose -f srcs/docker-compose.yml stop

# Restart specific service
docker compose -f srcs/docker-compose.yml restart wordpress
```

### View Container Status

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View resource usage
docker stats
```

### Container Logs

```bash
# View logs (all services)
docker compose -f srcs/docker-compose.yml logs

# Follow logs in real-time
docker compose -f srcs/docker-compose.yml logs -f

# View specific service logs
docker logs nginx
docker logs wordpress
docker logs mariadb

# Follow specific service
docker logs -f mariadb
```

### Execute Commands in Containers

```bash
# MariaDB shell
docker exec -it mariadb mysql -u root -p

# WordPress container shell
docker exec -it wordpress /bin/sh

# NGINX container shell
docker exec -it nginx /bin/sh

# WordPress WP-CLI
docker exec -it wordpress wp --allow-root user list
```

### Network Inspection

```bash
# List networks
docker network ls

# Inspect inception network
docker network inspect srcs_inception

# Test connectivity between containers
docker exec wordpress ping mariadb
```

## Volume Management

### Volume Location

Volumes are bind-mounted to host directories:

- **MariaDB data**: `/home/vtrofyme/data/mariadb`
- **WordPress data**: `/home/vtrofyme/data/wordpress`

### Volume Commands

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect srcs_mariadb_data

# View volume data on host
ls -la /home/vtrofyme/data/mariadb/
ls -la /home/vtrofyme/data/wordpress/

# Backup volumes
sudo tar -czf backup.tar.gz /home/vtrofyme/data/
```

### Volume Permissions

```bash
# MariaDB volume (MySQL user/group: 100:101)
sudo chown -R 100:101 /home/vtrofyme/data/mariadb
sudo chmod -R 755 /home/vtrofyme/data/mariadb

# WordPress volume (www-data user/group: 82:82)
sudo chown -R 82:82 /home/vtrofyme/data/wordpress
sudo chmod -R 775 /home/vtrofyme/data/wordpress
```

## Data Persistence

### How Data Persists

1. **Database Data** (`/var/lib/mysql` in container)
   - Mounted to: `/home/vtrofyme/data/mariadb`
   - Contains: MySQL database files, schemas, tables

2. **WordPress Data** (`/var/www/html` in container)
   - Mounted to: `/home/vtrofyme/data/wordpress`
   - Contains: WordPress core files, themes, plugins, uploads

### Testing Persistence

```bash
# Create test data
docker exec -it mariadb mysql -u root -p -e "CREATE DATABASE test_db;"

# Stop containers
make down

# Restart containers
make all

# Verify data still exists
docker exec -it mariadb mysql -u root -p -e "SHOW DATABASES;"
```

Data should persist across container restarts and rebuilds.

### Data Recovery

If containers are removed but volumes remain:

```bash
make down    # Remove containers
make all     # Rebuild and mount existing volumes
```

Data will be automatically restored.

## Makefile Targets

```bash
make all      # Setup + build + start (default)
make setup    # Create volume directories with permissions
make stop     # Stop containers (keep containers)
make down     # Stop and remove containers (keep volumes)
make clean    # Remove containers, networks, and images
make fclean   # Full cleanup: everything including volumes and data
make re       # Equivalent to: make fclean && make all
```

### Target Dependencies

```
all → setup → docker compose up --build -d
clean → down → docker system prune -a
fclean → clean → remove volumes and data directories
re → fclean → all
```

## Development Workflow

### Making Changes to Services

1. **Modify Dockerfile or configuration**:
   ```bash
   # Edit files in srcs/requirements/<service>/
   vim srcs/requirements/nginx/conf/nginx.conf
   ```

2. **Rebuild specific service**:
   ```bash
   docker compose -f srcs/docker-compose.yml up -d --build nginx
   ```

3. **Test changes**:
   ```bash
   docker logs -f nginx
   curl -k https://vtrofyme.42.fr
   ```

4. **Rollback if needed**:
   ```bash
   git checkout srcs/requirements/nginx/conf/nginx.conf
   docker compose -f srcs/docker-compose.yml up -d --build nginx
   ```

### Debugging Containers

```bash
# Check container status
docker ps -a

# View full logs
docker logs mariadb --tail 100

# Enter container for debugging
docker exec -it wordpress /bin/sh

# Inspect container configuration
docker inspect wordpress

# Check environment variables
docker exec wordpress env

# Check processes in container
docker exec wordpress ps aux
```

### Testing Database Connection

```bash
# From WordPress container
docker exec -it wordpress mysql -h mariadb -u wpuser -p

# Test from host (requires mariadb-client)
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"
```

## Project Structure

```
inception/
├── Makefile                        # Build automation
├── secrets/                        # Sensitive credentials (gitignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                        # Environment variables
    ├── docker-compose.yml          # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile          # MariaDB image definition
        │   ├── conf/
        │   │   └── mariadb-server.cnf
        │   └── tools/
        │       └── mariadb_init.sh # Database initialization script
        ├── nginx/
        │   ├── Dockerfile          # NGINX image definition
        │   ├── conf/
        │   │   └── nginx.conf      # NGINX configuration
        │   └── tools/              # SSL certificate generation
        └── wordpress/
            ├── Dockerfile          # WordPress image definition
            └── tools/
                └── setup.sh        # WordPress setup script
```

## Common Development Tasks

### Adding a New Environment Variable

1. Add to `srcs/.env`:
   ```bash
   NEW_VARIABLE=value
   ```

2. Reference in Dockerfile or scripts:
   ```dockerfile
   ENV NEW_VAR=${NEW_VARIABLE}
   ```

3. Rebuild affected services:
   ```bash
   docker compose -f srcs/docker-compose.yml up -d --build
   ```

### Adding a New Secret

1. Create secret file:
   ```bash
   echo "secret_value" > secrets/new_secret.txt
   chmod 600 secrets/new_secret.txt
   ```

2. Add to `docker-compose.yml`:
   ```yaml
   secrets:
     new_secret:
       file: ../secrets/new_secret.txt
   ```

3. Mount in service:
   ```yaml
   services:
     service_name:
       secrets:
         - new_secret
   ```

4. Access in container at `/run/secrets/new_secret`

### Changing Domain Name

1. Update `srcs/.env`:
   ```bash
   DOMAIN_NAME=newdomain.42.fr
   ```

2. Update `/etc/hosts`:
   ```bash
   127.0.0.1    newdomain.42.fr
   ```

3. Rebuild NGINX (if domain is in SSL cert):
   ```bash
   make re
   ```

## Performance Optimization

### Build Cache

Docker uses layer caching. Order Dockerfile commands from least to most frequently changed:

```dockerfile
# Good: Install dependencies first (cached)
RUN apk add --no-cache package1 package2

# Then copy application files (changes frequently)
COPY . /app
```

### Reduce Build Time

```bash
# Build without cache (clean build)
docker compose -f srcs/docker-compose.yml build --no-cache

# Parallel builds
docker compose -f srcs/docker-compose.yml build --parallel
```

## Security Considerations

1. **Secrets Management**: Never commit `secrets/` directory
2. **File Permissions**: Secrets should be `600`, configs `644`
3. **Container Isolation**: Services communicate only through defined networks
4. **TLS Encryption**: All external traffic over HTTPS
5. **Least Privilege**: Containers run as non-root where possible
6. **No Default Passwords**: All passwords stored in separate files

## Troubleshooting

### Build Failures

```bash
# Clear build cache
docker builder prune -a

# Remove all and rebuild
make fclean
make all
```

### Network Issues

```bash
# Remove and recreate network
docker network rm srcs_inception
docker compose -f srcs/docker-compose.yml up -d
```

### Volume Permission Issues

```bash
# Fix permissions
make setup

# Or manually
sudo chown -R 100:101 /home/vtrofyme/data/mariadb
sudo chown -R 82:82 /home/vtrofyme/data/wordpress
```

### Port Conflicts

```bash
# Check what's using port 443
sudo lsof -i :443

# Kill process or change docker-compose.yml port mapping
```
