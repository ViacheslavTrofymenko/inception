#!/bin/sh

# Read database password from Docker secret
DB_PASS=$(cat /run/secrets/db_password)

echo "Checking MariaDB connection..."
while ! mariadb-client -h mariadb -u "$DB_USER_NAME" -p"$DB_PASS" "$DB_NAME" &>/dev/null; do
    sleep 2
done

# Only install if WordPress is not already there (Idempotency)
if [ ! -f wp-config.php ]; then
    echo "Installing WordPress..."

    wp core download --allow-root

    # Using your secrets logic to create config
    wp config create --allow-root \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER_NAME" \
        --dbpass="$DB_PASS" \
        --dbhost=mariadb:3306

    # Read WordPress passwords from Docker secrets
    WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
    WP_AUTHOR_PASSWORD=$(cat /run/secrets/wp_user_password)

    wp core install --allow-root \
        --url=${DOMAIN_NAME} \
        --title="${WP_TITLE}" \
        --admin_user=${WP_ADMIN_NAME} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --skip-email

    wp user create --allow-root \
        ${WP_AUTHOR_USER} ${WP_AUTHOR_EMAIL} \
        --user_pass=${WP_AUTHOR_PASSWORD} \
        --role=author
fi

echo "WordPress is ready!"
# Start PHP-FPM as PID 1
exec php-fpm82 -F
