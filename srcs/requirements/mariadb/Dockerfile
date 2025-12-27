# Use the penultimate stable version of Alpine
FROM alpine:3.19

# Install packages and create essential directories
RUN apk update && \
	apk add  --no-cache mariadb mariadb-client && \
    mkdir -p /var/lib/mysql /run/mysqld && \
    # Set permissions so the 'mysql' user can manage these folders
    chown -R mysql:mysql /var/lib/mysql /run/mysqld

# Set the working directory
WORKDIR /usr/local/bin

# Copy your tools and config
COPY ./tools/mariadb_init.sh .
COPY ./conf/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf

RUN chmod +x mariadb_init.sh

# Expose the default MariaDB port
EXPOSE 3306

ENTRYPOINT [ "/usr/local/bin/mariadb_init.sh" ]