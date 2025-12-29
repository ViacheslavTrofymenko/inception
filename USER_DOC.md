# User Documentation

## Overview

This Inception project provides a complete web infrastructure stack consisting of three main services:

- **NGINX**: Secure web server with TLSv1.2/TLSv1.3 encryption (port 443)
- **WordPress**: Content management system and website platform
- **MariaDB**: Database server for storing WordPress data

All services run in isolated Docker containers and communicate through a private network. Data is persisted to ensure it survives container restarts.

## Starting the Project

### Prerequisites

Before starting, ensure:
- Docker and Docker Compose are installed
- You have sudo privileges (required for volume setup)
- Port 443 is available on your system

### Start the Stack

From the project root directory, run:

```bash
make
```

Or explicitly:

```bash
make all
```

This command will:
1. Create necessary data directories with proper permissions
2. Build all Docker images
3. Start all containers in detached mode

The first build may take several minutes. Subsequent starts will be faster.

### Verify Services are Running

Check that all containers are running:

```bash
docker ps
```

You should see three containers:
- `nginx`
- `wordpress`
- `mariadb`

All should show status "Up" with no restarts.

## Accessing the Website

### Main Website

Access the website via HTTPS:

```
https://vtrofyme.42.fr
```

**Note**: If you're not using DNS, you may need to add this to your `/etc/hosts` file:

```bash
sudo nano /etc/hosts
```

Add the line:
```
127.0.0.1    vtrofyme.42.fr
```

### WordPress Administration Panel

Access the WordPress admin dashboard at:

```
https://vtrofyme.42.fr/wp-admin
```

## Credentials

All sensitive credentials are stored securely in the `secrets/` directory as separate files.

### Credential Files Location

```
secrets/
├── db_password.txt          # WordPress database user password
├── db_root_password.txt     # MariaDB root password
├── wp_admin_password.txt    # WordPress administrator password
└── wp_user_password.txt     # WordPress author user password
```

### WordPress Login

**Administrator Account:**
- Username: `vtrofyme_admin`
- Password: Found in `secrets/wp_admin_password.txt`

**Author Account:**
- Username: `author_vtrofyme`
- Password: Found in `secrets/wp_user_password.txt`

### Database Access

**Database Root User:**
- Username: `root`
- Password: Found in `secrets/db_root_password.txt`

**Database WordPress User:**
- Username: `wpuser`
- Password: Found in `secrets/db_password.txt`
- Database: `wordpress`

### Viewing Credentials

To view a password:

```bash
cat secrets/wp_admin_password.txt
```

**Security Note**: Never commit the `secrets/` directory to version control. Keep these files protected with appropriate file permissions.

## Managing the Stack

### Stop Services

To stop all containers without removing them:

```bash
make stop
```

Containers can be restarted later without data loss.

### Restart Services

To stop and restart:

```bash
make stop
make all
```

Or rebuild from scratch:

```bash
make re
```

### Stop and Remove Containers

To stop containers and remove them (data persists):

```bash
make down
```

## Health Checks

### Check Container Status

```bash
docker ps
```

Look for:
- All three containers running
- "Up" status with uptime
- No constant restarts

### Check Container Logs

**NGINX logs:**
```bash
docker logs nginx
```

**WordPress logs:**
```bash
docker logs wordpress
```

**MariaDB logs:**
```bash
docker logs mariadb
```

### Test Website Connectivity

```bash
curl -k https://vtrofyme.42.fr
```

You should see HTML content from WordPress.

### Verify Database Connection

Connect to MariaDB container:

```bash
docker exec -it mariadb mysql -u root -p
```

Enter the root password from `secrets/db_root_password.txt`, then:

```sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
EXIT;
```

You should see WordPress tables.

### Check Data Persistence

Verify data directories exist and contain data:

```bash
ls -la /home/vtrofyme/data/mariadb/
ls -la /home/vtrofyme/data/wordpress/
```

## Troubleshooting

### Website Not Accessible

1. Check containers are running: `docker ps`
2. Check NGINX logs: `docker logs nginx`
3. Verify port 443 is not blocked by firewall
4. Ensure `/etc/hosts` entry is correct

### WordPress Shows Database Connection Error

1. Check MariaDB container is running: `docker ps`
2. View MariaDB logs: `docker logs mariadb`
3. Verify database credentials in `secrets/` directory
4. Ensure MariaDB had time to initialize (30-60 seconds on first start)

### Permission Errors

If you see permission errors:

```bash
make fclean
make all
```

This rebuilds with proper permissions.

### Services Keep Restarting

Check logs for the problematic container:

```bash
docker logs <container_name>
```

Common issues:
- Missing or incorrect credentials in `secrets/` directory
- Port 443 already in use
- Insufficient disk space

## Data Backup

### Backup WordPress Data

```bash
sudo tar -czf wordpress-backup-$(date +%Y%m%d).tar.gz /home/vtrofyme/data/wordpress/
```

### Backup Database Data

```bash
sudo tar -czf mariadb-backup-$(date +%Y%m%d).tar.gz /home/vtrofyme/data/mariadb/
```

### Database Export (Alternative)

```bash
docker exec mariadb mysqldump -u root -p wordpress > wordpress-backup.sql
```

Enter the root password when prompted.

## Complete Shutdown and Cleanup

### Remove Everything (Containers and Images)

```bash
make clean
```

This removes containers, networks, and images but preserves volumes and data.

### Full Cleanup (Including Data)

**WARNING**: This deletes all data permanently!

```bash
make fclean
```

This removes:
- All containers
- All images
- All volumes
- All persistent data

Use this only when you want to start completely fresh.
