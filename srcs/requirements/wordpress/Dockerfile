FROM alpine:3.19

# Install PHP and extensions required by WordPress
RUN apk update && apk add --no-cache \
    php82 \
    php82-fpm \
    php82-mysqli \
    php82-phar \
    php82-json \
    php82-curl \
    php82-dom \
    php82-exif \
    php82-fileinfo \
    php82-mbstring \
    php82-openssl \
    php82-xml \
    php82-zip \
    mariadb-client \
    curl

# Install WP-CLI (Command line interface for WordPress)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp && \
    echo "memory_limit = 256M" >> /etc/php82/php.ini

# Create www-data user/group if they don't exist
RUN addgroup -g 82 -S www-data 2>/dev/null || true && \
    adduser -u 82 -D -S -G www-data www-data 2>/dev/null || true

# Copy our PHP-FPM config
COPY ./conf/www.conf /etc/php82/php-fpm.d/www.conf

# Set up the working directory (This will be our Volume)
WORKDIR /var/www/html

# Copy the setup script
COPY ./tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Port 9000 for PHP-FPM
EXPOSE 9000

# Start with our setup script
ENTRYPOINT ["/usr/local/bin/setup.sh"]
