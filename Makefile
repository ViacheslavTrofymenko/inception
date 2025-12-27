# Variables
NAME = inception
SRCS = ./srcs/docker-compose.yml
LOGIN = vtrofyme

# Default target: build and start the containers
all: setup
	docker compose -f $(SRCS) up --build -d

# Create local directories for volumes
setup:
	sudo mkdir -p /home/$(LOGIN)/data/mariadb
	sudo mkdir -p /home/$(LOGIN)/data/wordpress
	sudo chown -R 100:101 /home/$(LOGIN)/data/mariadb
	sudo chmod -R 755 /home/$(LOGIN)/data/mariadb
	sudo chown -R 82:82 /home/$(LOGIN)/data/wordpress
	sudo chmod -R 775 /home/$(LOGIN)/data/wordpress

# Stop containers
stop:
	docker compose -f $(SRCS) stop

# Down: stop and remove containers and networks
down:
	docker compose -f $(SRCS) down

# Clean: remove containers, networks, and images
clean: down
	docker system prune -a

# Full clean: everything + volumes
fclean: clean
	docker volume rm $$(docker volume ls -q)
	rm -rf /home/$(LOGIN)/data

re: fclean all

.PHONY: all setup stop down clean fclean re
