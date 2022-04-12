SHELL := /bin/bash
CONTAINER_NAME=expediagroup/kubernetes-sidecar-injector
IMAGE_TAG?=$(shell git rev-parse HEAD)
KIND_CLUSTER?=cluster1

SRC=$(shell find . -type f -name '*.go' -not -path "./vendor/*")

lint:
	go list ./... | xargs golint -min_confidence 1.0 

vet:
	go vet ./...

imports:
	goimports -w ${SRC}

clean:
	go clean

build: clean vet lint
	go build -o kubernetes-sidecar-injector

release: clean vet lint
	CGO_ENABLED=0 GOOS=linux go build -o kubernetes-sidecar-injector

docker:
	docker build --no-cache -t ${CONTAINER_NAME}:${IMAGE_TAG} .

kind-load: docker
	kind load docker-image ${CONTAINER_NAME}:${IMAGE_TAG} --name ${KIND_CLUSTER}

helm-install:
	helm upgrade -i kubernetes-sidecar-injector ./charts/kubernetes-sidecar-injector/. --namespace=sidecar-injector --create-namespace --set image.tag=${IMAGE_TAG}

helm-template:
	helm template kubernetes-sidecar-injector ./charts/kubernetes-sidecar-injector

kind-install: kind-load helm-install

install-sample-container:
	helm upgrade -i inject-container ./sample/chart/echo-server/. --namespace=sample --create-namespace

install-sample-init-container:
	helm upgrade -i inject-init-container ./sample/chart/nginx/. --namespace=sample --create-namespace