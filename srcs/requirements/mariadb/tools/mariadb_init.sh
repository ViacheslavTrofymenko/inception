#!/bin/sh

# Initialize data directory if empty
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Read secrets from Docker secrets
    DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    DB_PASS=$(cat /run/secrets/db_password)

    # Create the init file
    cat << EOF > /tmp/init.sql
USE mysql;
FLUSH PRIVILEGES;
DELETE FROM mysql.user WHERE User='';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER_NAME}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER_NAME}'@'%';
FLUSH PRIVILEGES;
EOF

    # Bootstrap
    /usr/bin/mariadbd --user=mysql --bootstrap < /tmp/init.sql
    rm -f /tmp/init.sql
fi

# Final launch
exec mariadbd --user=mysql
