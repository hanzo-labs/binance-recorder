# Default to test environment
DOCKER_HOST		    := tcp://138.197.192.54:2376
DOCKER_CERT_PATH    := certs
DOCKER_MACHINE_NAME := binance-recorder

machine = binance-recorder

build-app:
	docker build --tag binance-recorder .

run-app: build-app
	@docker stop binance-recorder && echo stopping binance-recorder || echo binance-recorder not running
	@docker rm binance-recorder && echo removing binance-recorder || echo binance-recorder not found
	docker run --detach \
     --name binance-recorder \
     --network binance-recorder-net \
     --volume :/app:rw \
     binance-recorder

run-mongo:
	@docker stop binance-recorder-mongo && echo stopping binance-recorder || echo binance-recorder-mongo not running
	@docker rm binance-recorder-mongo && echo removing binance-recorder || echo binance-recorder-mongo not found
	docker run --detach \
     --name binance-recorder-mongo \
     --network binance-recorder-net \
     --volume mongo:/data/db:rw \
     mongo

mongo-shell:
	docker exec -it binance-recorder-mongo mongo

create-server:
	docker-machine create \
		--driver digitalocean \
		--digitalocean-access-token 9e94be3d10e09686bcb54d6fc6d74c1c8bbef5ca1ec2d24ddd3c9b385142b7b2 \
		--digitalocean-region sfo2 \
		--digitalocean-size 8gb \
		$(machine)

create-network:
	docker network create binance-recorder-net

run: run-app run-mongo
create: create-server create-network
