# Default to test environment
DOCKER_HOST		    := tcp://138.68.48.73:2376
DOCKER_CERT_PATH    := certs
DOCKER_MACHINE_NAME := binance-recorder

machine = binance-recorder

create-server:
	docker-machine create \
		--driver digitalocean \
		--digitalocean-access-token 9e94be3d10e09686bcb54d6fc6d74c1c8bbef5ca1ec2d24ddd3c9b385142b7b2 \
		--digitalocean-region sfo2 \
		--digitalocean-size 8gb \
		$(machine)
