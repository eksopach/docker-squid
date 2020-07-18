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
		--mount type=bind,source="$(PWD)/squid.conf":/etc/squid/squid.conf \
		--mount type=bind,source="$(PWD)/squid/log":/var/log/squid \
		--mount type=bind,source="$(PWD)/squid/cache":/var/spool/squid \
		--name $(CONTAINER_NAME) \
		$(IMAGE_NAME)

stop:
	docker stop $(CONTAINER_NAME)
	docker rm $(CONTAINER_NAME)
	
