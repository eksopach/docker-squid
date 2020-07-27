SHELL := /bin/bash

CONTAINER_NAME ?= squid
IMAGE_NAME ?= eksopach/squid:latest

.PHONY: all clean image test stop

all: image

clean:
	docker rmi $(IMAGE_NAME)

image: Dockerfile
	docker build -t $(IMAGE_NAME) \
	.

server:
	docker run \
		-i \
		-t \
		-d \
		-p 3128:3128 \
		--mount type=bind,source="$(PWD)/squid4.conf",target=/etc/squid4/squid.conf \
		--mount type=bind,source="${HOME}/Volumes/squid4/tls",target=/etc/squid4/tls \
		--mount type=bind,source="${HOME}/Volumes/squid4/log",target=/var/log/squid4 \
		--mount type=bind,source="${HOME}/Volumes/squid4/cache",target=/var/spool/squid4 \
		--name $(CONTAINER_NAME) \
		$(IMAGE_NAME)

stop:
	docker stop $(CONTAINER_NAME)
	docker rm $(CONTAINER_NAME)
	
