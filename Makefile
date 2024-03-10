.PHONY: help ps build build-prod start fresh fresh-prod stop restart destroy \
	cache cache-clear migrate migrate migrate-fresh tests tests-html

CONTAINER_NGINX=docker-compose-laravel-app-1
CONTAINER_PHP=docker-compose-laravel-php-1
CONTAINER_REDIS=docker-compose-laravel-redis-1
CONTAINER_DATABASE=docker-compose-laravel-mysql-1

help: ## Print help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

ps: ## Show containers.
	@docker compose ps

# build: ## Build all containers for DEV
# 	@docker build --no-cache . -f ./dockerfiles/php.local.dockerfile --build-arg GID=1000 --build-arg UID=1000

# build-prod: ## Build all containers for PROD
# 	@docker build --no-cache . -f ./Dockerfile

build-compose: ## Docker compose build Dev Env --no-cache
	@docker-compose build --no-cache

build-compose-prod: ## Docker compose build Prod Env --no-cache
	@docker-compose -f docker-compose.prod.yml up -d --build

cup: ## Compose up local environment
	@docker-compose -f docker-compose.yml up

cubp: ## Compose up build prod environment
	@UID=$(shell id -u) GID=$(shell id -g) docker-compose -f docker-compose.prod.yml up --build
## UID=$(id -u) GID=$(id -g) docker-compose -f docker-compose.prod.yml up --build

up-prod: ## Compose up prod environment
	@UID=$(shell id -u) GID=$(shell id -g) docker-compose -f docker-compose.prod.yml up -d --build

start-dev: ## Start all containers
	@docker compose up --force-recreate -d

start-compose-prod: ## Start Docker containers defined in the
	@docker compose -f docker-compose.prod.yml up --detach

fresh:  ## Destroy & recreate all uing dev containers.
	make stop
	make destroy
	make build
	make start

fresh-prod: ## Destroy & recreate all using prod containers.
	make stop
	make destroy
	make build-prod
	make start

stop-dev: ## Stop all Dev containers
	@docker compose stop

restart: stop-dev start-dev ## Restart all dev containers

destroy: stop ## Destroy all containers

# destroy-compose: ## stop and remove containers created by docker-compose along with associated volumes
#     @docker-compose down --volumes

ssh-app: ## SSH into APP container
	docker exec -it ${CONTAINER_NGINX} sh

ssh-php: ## SSH into PHP container
	docker exec -it ${CONTAINER_PHP} sh

php-ini: ## Check loaded php configurations in PHP container
	docker exec -it ${CONTAINER_PHP} php -i | grep "Loaded Configuration File"

php-opcache: ## Check opcahe in PHP container
	docker exec ${CONTAINER_PHP} php -i | grep "opcache"

php-ps: ## List Processes in PHP container
	docker exec ${CONTAINER_PHP} ps

php-reset: ## Kill master PHP process, clear the OPcache completely by forcing PHP-FPM to reload all PHP files and recompile them
	docker exec ${CONTAINER_PHP} kill -USR2 1

ssh-db: ## SSH into DB container
	docker exec -it ${CONTAINER_DATABASE} sh
	
install: ## Run composer install
	docker exec ${CONTAINER_PHP} composer install

migrate: ## Run migration files
	docker exec ${CONTAINER_PHP} php artisan migrate

migrate-fresh: ## Clear database and run all migrations
	docker exec ${CONTAINER_PHP} php artisan migrate:fresh

tests: ## Run all tests
	docker exec ${CONTAINER_PHP} ./vendor/bin/phpunit

tests-html: ## Run tests and generate coverage. Report found in reports/index.html
	docker exec ${CONTAINER_PHP} php -d zend_extension=xdebug.so -d xdebug.mode=coverage ./vendor/bin/phpunit --coverage-html reports

scale: ## Scale up 3 php cotnainers
	@docker compose up --scale php=3 -d