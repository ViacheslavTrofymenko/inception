*This project has been created as part of the 42 curriculum by vtrofyme.*

# Inception

## Description

Inception is a system administration and Docker infrastructure project that demonstrates the deployment of a complete web application stack using Docker containers. The goal is to set up a small infrastructure composed of different services following specific rules and best practices for containerization.

The project creates a WordPress website with NGINX as a reverse proxy and MariaDB as the database, all running in separate Docker containers. Each service is isolated, secured, and communicates through a dedicated Docker network.

### Key Objectives:
- Build custom Docker images from scratch (no pre-made images from DockerHub)
- Implement proper container orchestration using docker-compose
- Follow security best practices (TLS encryption, secrets management)
- Understand the differences between various Docker concepts (volumes, networks, secrets)

## Instructions

### Prerequisites
- Docker and Docker Compose installed on your system
- `make` utility
- Root or sudo privileges (for volume creation)

### Configuration

Before running the project, you must configure your environment:

1. **Update `/etc/hosts`** to point your domain to localhost:
   ```bash
   sudo echo "127.0.0.1 vtrofyme.42.fr" >> /etc/hosts
   ```

2. **Configure secrets** in the `secrets/` directory:
   - Edit `secrets/db_password.txt` - database user password
   - Edit `secrets/db_root_password.txt` - database root password
   - Edit `secrets/wp_admin_password.txt` - WordPress admin password
   - Edit `secrets/wp_user_password.txt` - WordPress additional user password

   **IMPORTANT:** Replace the placeholder values with strong passwords!

3. **Review environment variables** in `srcs/.env`:
   - Verify domain name matches your setup
   - Ensure admin username doesn't contain "admin" or "administrator"
   - Update email addresses as needed

### Building and Running

```bash
# Build and start all containers
make

# Stop containers (without removing them)
make stop

# Stop and remove containers and networks
make down

# Clean everything (containers, networks, images)
make clean

# Full clean including volumes and data
make fclean

# Rebuild from scratch
make re
```

### Accessing the Services

Once running, access the WordPress site at:
- **HTTPS:** https://vtrofyme.42.fr

The site will use a self-signed SSL certificate, so you'll need to accept the browser security warning.

### Verifying the Setup

Check that all containers are running:
```bash
docker ps
```

You should see three containers:
- `nginx` - Web server (port 443)
- `wordpress` - PHP-FPM application
- `mariadb` - Database server

Check logs if needed:
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

## Project Structure

```
inception/
├── Makefile                    # Build automation
├── secrets/                    # Sensitive credentials (gitignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                    # Environment variables (gitignored)
    ├── docker-compose.yml      # Container orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile      # MariaDB image definition
        │   ├── conf/
        │   │   └──mariadb-server.cnf
        │   └── tools/
        │       └── mariadb_init.sh
        ├── nginx/
        │   ├── Dockerfile      # NGINX image definition
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        └── wordpress/
            ├── Dockerfile      # WordPress image definition
            ├── conf/
            │   └── www.conf
            └── tools/
                └── setup.sh
```

## Technical Choices

### Base Operating System
All containers use **Alpine Linux 3.19** (penultimate stable version) for:
- Minimal image size (~5MB base)
- Reduced attack surface
- Faster build and deployment times
- Lower resource consumption

### Service Architecture

#### NGINX (Reverse Proxy)
- Acts as the single entry point to the infrastructure
- Terminates TLS connections (TLSv1.3 only)
- Proxies PHP requests to WordPress container via FastCGI
- Serves static files directly

#### WordPress (Application)
- Runs PHP-FPM 8.2 in listen mode (port 9000)
- No web server included (separation of concerns)
- Uses WP-CLI for automated installation and configuration
- Connects to MariaDB for database operations

#### MariaDB (Database)
- Isolated database server
- Automated initialization with secure defaults
- Creates WordPress database and users on first run
- Persists data through Docker volumes

### Docker Concepts Comparison

#### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|-----------------|-------------------|
| **Isolation** | Full OS isolation with hypervisor | Process-level isolation using Linux namespaces |
| **Resource Usage** | Heavy (GBs of RAM, full OS) | Lightweight (MBs of RAM, shared kernel) |
| **Boot Time** | Minutes | Seconds |
| **Portability** | Limited (large image files) | Excellent (small, layered images) |
| **Performance** | Overhead from virtualization | Near-native performance |
| **Use Case** | Full OS simulation, different kernels | Application isolation, microservices |

**Why Docker for Inception:**
- Faster deployment and iteration
- Efficient resource utilization
- Easy to version control infrastructure
- Industry standard for containerized applications

#### Secrets vs Environment Variables

| Aspect | Docker Secrets | Environment Variables |
|--------|---------------|----------------------|
| **Storage** | Encrypted at rest, in-memory in container | Plain text in process environment |
| **Security** | High - not visible in `docker inspect` | Low - visible in process listing |
| **Distribution** | Distributed via encrypted channels | Passed directly or via .env files |
| **Rotation** | Can be rotated without rebuilding | Requires container restart |
| **Best For** | Passwords, API keys, certificates | Non-sensitive configuration |

**Our Implementation:**
- Passwords → Docker Secrets (mounted at `/run/secrets/`)
- Configuration → Environment Variables (domain, database name, usernames)

#### Docker Network vs Host Network

| Aspect | Docker Network (Bridge) | Host Network |
|--------|------------------------|--------------|
| **Isolation** | Containers have separate network namespace | Container shares host's network stack |
| **Port Mapping** | Explicit port publishing required | Direct access to all ports |
| **Security** | Better - isolated network segments | Lower - full host network access |
| **DNS** | Automatic service discovery by name | Manual IP management |
| **Performance** | Slight overhead from NAT | Native performance |

**Why Bridge Network:**
- Containers communicate by service name (`wordpress:9000`, `mariadb:3306`)
- Network isolation prevents unauthorized access
- Only NGINX exposes port 443 to the host
- Follows principle of least privilege

#### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|---------------|-------------|
| **Management** | Managed by Docker daemon | Direct host filesystem path |
| **Location** | Docker-controlled location | User-specified path |
| **Portability** | Portable across environments | Tied to host directory structure |
| **Permissions** | Docker manages permissions | Must manage manually |
| **Backup** | `docker volume backup` commands | Standard filesystem tools |

**Our Choice: Bind Mounts**
- Project requirement: volumes in `/home/vtrofyme/data/`
- Easy backup with standard Linux tools
- Direct access for debugging and maintenance
- Explicit about data location

**Implementation:**
```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/vtrofyme/data/mariadb
```

### Security Implementations

1. **TLS Encryption**: All traffic encrypted with TLSv1.3
2. **Secrets Management**: Passwords stored in Docker secrets (not in environment variables or Dockerfiles)
3. **Network Isolation**: Internal services not exposed to host network
4. **Non-Root Users**: Services run as dedicated users (mysql, www-data)
5. **Minimal Images**: Alpine Linux reduces attack surface

## Resources

### Official Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [Alpine Linux Wiki](https://wiki.alpinelinux.org/)

### Tutorials and Guides
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [NGINX as Reverse Proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [WP-CLI Documentation](https://wp-cli.org/)

### Security Resources
- [Docker Security Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [SSL/TLS Configuration](https://ssl-config.mozilla.org/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

## Additional Notes

### Important Security Reminders

⚠️ **Never commit the following to Git:**
- `secrets/` directory
- `srcs/.env` file
- Any files containing passwords or API keys

✅ **The .gitignore file is configured to prevent accidental commits**

### Common Issues

**Issue:** Container fails to start with "bind: address already in use"
- **Solution:** Another service is using port 443. Stop it or change the port mapping.

**Issue:** WordPress shows "Error establishing database connection"
- **Solution:** Check MariaDB logs. Ensure secrets are properly configured and the database is initialized.

**Issue:** Browser shows SSL certificate warning
- **Solution:** This is expected with self-signed certificates. Click "Advanced" and proceed.

**Issue:** Permission denied when creating volumes
- **Solution:** Ensure `/home/vtrofyme/data/` directories exist and have proper permissions.

### Testing Two Users

To verify the WordPress database has two users:

```bash
# Access MariaDB container
docker exec -it mariadb mariadb -u root -p$(cat secrets/db_root_password.txt)

# In MariaDB prompt:
USE wordpress;
SELECT user_login, user_email FROM wp_users;
```

You should see:
1. Admin user (vtrofyme)
2. Author user (author_vtrofyme)

---

**Project Status:** ✅ Fully functional and compliant with 42 Inception requirements

For questions or issues, refer to the official 42 Inception subject PDF or consult with peers.
