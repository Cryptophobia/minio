SHORT_NAME := minio

# dockerized development environment variables
REPO_PATH := github.com/teamhephy/${SHORT_NAME}
DEV_ENV_IMAGE := hephy/go-dev:v1.28.3
DEV_ENV_WORK_DIR := /go/src/${REPO_PATH}
DEV_ENV_PREFIX := docker run --env CGO_ENABLED=0 --rm -v ${CURDIR}:${DEV_ENV_WORK_DIR} -w ${DEV_ENV_WORK_DIR}
DEV_ENV_CMD := ${DEV_ENV_PREFIX} ${DEV_ENV_IMAGE}

LDFLAGS := "-s -X main.version=${VERSION}"
BINDIR := ./rootfs/bin
DEV_REGISTRY ?= hephy/
HEPHY_REGISTRY ?= ${DEV_REGISTRY}

IMAGE_PREFIX ?= hephy

include versioning.mk

all: build docker-build docker-push

bootstrap:
	${DEV_ENV_CMD} go mod vendor

glideup:
	${DEV_ENV_CMD} glide up

build:
	mkdir -p ${BINDIR}
	${DEV_ENV_CMD} go build -ldflags '-s' -o $(BINDIR)/boot boot.go || exit 1

test: test-style
	${DEV_ENV_CMD} go test ./...

test-style:
	${DEV_ENV_CMD} lint --deadline

test-cover:
	${DEV_ENV_CMD} test-cover.sh

docker-build: build
	# build the main image
	docker build ${DOCKER_BUILD_FLAGS} -t ${IMAGE} rootfs
	docker tag ${IMAGE} ${MUTABLE_IMAGE}

deploy: build docker-build docker-push

.PHONY: all bootstrap build test docker-build deploy
