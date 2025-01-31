SHELL := /bin/bash
CONTAINER_NAME=khoaitaybeo86/kube-sidecar-injector
IMAGE_TAG?=$(shell git rev-parse HEAD)
KIND_REPO?="kindest/node"
KUBE_VERSION = v1.21.12
KIND_CLUSTER?=cluster1

SRC=$(shell find . -type f -name '*.go' -not -path "./vendor/*")

lint:
	go list ./... | xargs golint -min_confidence 1.0 

vet:
	go vet ./...

test:
	go test ./...

tidy:
	go mod tidy

imports:
	goimports -w ${SRC}

clean:
	go clean

build: clean vet lint
	go build -o kube-sidecar-injector

release: clean vet lint
	CGO_ENABLED=0 GOOS=linux go build -o kube-sidecar-injector

docker:
	docker build --no-cache -t ${CONTAINER_NAME}:${IMAGE_TAG} .

kind-load: docker
	kind load docker-image ${CONTAINER_NAME}:${IMAGE_TAG} --name ${KIND_CLUSTER}

helm-install:
	helm upgrade -i kube-sidecar-injector ./charts/kube-sidecar-injector/. --namespace=sidecar-injector --create-namespace --set image.tag=${IMAGE_TAG}

helm-template:
	helm template kube-sidecar-injector ./charts/kube-sidecar-injector

kind-create:
	-kind create cluster --image "${KIND_REPO}:${KUBE_VERSION}" --name ${KIND_CLUSTER}

kind-install: kind-load helm-install

kind: kind-create kind-install

follow-logs:
	kubectl logs -n sidecar-injector deployment/kube-sidecar-injector --follow

install-sample-container:
	helm upgrade -i inject-container ./sample/chart/echo-server/. --namespace=sample --create-namespace

install-sample-init-container:
	helm upgrade -i inject-init-container ./sample/chart/nginx/. --namespace=sample --create-namespace
