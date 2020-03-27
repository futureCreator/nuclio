GOPATH ?= $(shell go env GOPATH)
NUCLIO_DEFAULT_OS := $(shell go env GOOS)
NUCLIO_DEFAULT_ARCH := $(shell go env GOARCH)
NUCLIO_OS := $(shell go env GOOS)
NUCLIO_ARCH := $(shell go env GOARCH)
NUCLIO_LABEL := $(if $(NUCLIO_LABEL),$(NUCLIO_LABEL),latest)
NUCLIO_VERSION_GIT_COMMIT = $(shell git rev-parse HEAD)
NUCLIO_VERSION_INFO = {\"git_commit\": \"$(NUCLIO_VERSION_GIT_COMMIT)\",  \
\"label\": \"$(NUCLIO_LABEL)\",  \
\"os\": \"$(NUCLIO_OS)\",  \
\"arch\": \"$(NUCLIO_ARCH)\"}
NUCLIO_DOCKER_REPO := futurecreator
NUCLIO_BUILD_ARGS_VERSION_INFO_FILE = --build-arg NUCLIO_VERSION_INFO_FILE_CONTENTS="$(NUCLIO_VERSION_INFO)"
NUCLIO_DOCKER_LABELS = --label nuclio.version_info="$(NUCLIO_VERSION_INFO)"
NUCLIO_DOCKER_IMAGE_TAG=$(NUCLIO_LABEL)-$(NUCLIO_ARCH)

PIP_REQUIRE_VIRTUALENV=false

NUCLIO_DOCKER_CONTROLLER_IMAGE_NAME=$(NUCLIO_DOCKER_REPO)/nuclio-controller:$(NUCLIO_DOCKER_IMAGE_TAG)
NUCLIO_DOCKER_PROCESSOR_IMAGE_NAME=$(NUCLIO_DOCKER_REPO)/nuclio-processor:$(NUCLIO_DOCKER_IMAGE_TAG)
NUCLIO_DOCKER_DASHBOARD_IMAGE_NAME=$(NUCLIO_DOCKER_REPO)/nuclio-dashboard:$(NUCLIO_DOCKER_IMAGE_TAG)
NUCLIO_DOCKER_SCALER_IMAGE_NAME=$(NUCLIO_DOCKER_REPO)/nuclio-autoscaler:$(NUCLIO_DOCKER_IMAGE_TAG)
NUCLIO_DOCKER_DLX_IMAGE_NAME=$(NUCLIO_DOCKER_REPO)/nuclio-dlx:$(NUCLIO_DOCKER_IMAGE_TAG)
NUCLIO_DOCKER_HANDLER_BUILDER_PYTHON_ONBUILD_IMAGE_NAME=\
$(NUCLIO_DOCKER_REPO)/handler-builder-python-onbuild:$(NUCLIO_DOCKER_IMAGE_TAG)
NUCLIO_DOCKER_HANDLER_BUILDER_NODEJS_ONBUILD_IMAGE_NAME=\
$(NUCLIO_DOCKER_REPO)/handler-builder-nodejs-onbuild:$(NUCLIO_DOCKER_IMAGE_TAG)
NUCLIO_DOCKER_HANDLER_BUILDER_JAVA_ONBUILD_IMAGE_NAME=\
$(NUCLIO_DOCKER_REPO)/handler-builder-java-onbuild:$(NUCLIO_DOCKER_IMAGE_TAG)

.PHONY: all ensure-gopath targets

all:
	$(error Please pick a target (run "make targets" to view targets))

BUILD_IMAGES = \
	controller \
	dashboard \
	processor \
	autoscaler \
	dlx \
	handler-builder-java-onbuild \
	handler-builder-python-onbuild \
	handler-builder-nodejs-onbuild

build: ensure-gopath $(BUILD_IMAGES)
	@echo Done.

PUSH_IMAGES = \
	controller-push \
	dashboard-push \
	processor-push \
	autoscaler-push \
	dlx-push \
	onbuild-push

push: ensure-gopath $(PUSH_IMAGES)
	@echo Done.

#
# Build
#

controller: ensure-gopath
	docker build $(NUCLIO_BUILD_ARGS_VERSION_INFO_FILE) \
		--file cmd/controller/Dockerfile \
		--tag $(NUCLIO_DOCKER_CONTROLLER_IMAGE_NAME) \
		$(NUCLIO_DOCKER_LABELS) .

dashboard: ensure-gopath
	docker build $(NUCLIO_BUILD_ARGS_VERSION_INFO_FILE) \
		--file cmd/dashboard/docker/Dockerfile \
		--tag $(NUCLIO_DOCKER_DASHBOARD_IMAGE_NAME) \
		$(NUCLIO_DOCKER_LABELS) .

processor: ensure-gopath
	docker build --file cmd/processor/Dockerfile --tag $(NUCLIO_DOCKER_PROCESSOR_IMAGE_NAME) .

autoscaler: ensure-gopath
	docker build $(NUCLIO_BUILD_ARGS_VERSION_INFO_FILE) \
		--file cmd/autoscaler/Dockerfile \
		--tag $(NUCLIO_DOCKER_SCALER_IMAGE_NAME) \
		$(NUCLIO_DOCKER_LABELS) .

dlx: ensure-gopath
	docker build $(NUCLIO_BUILD_ARGS_VERSION_INFO_FILE) \
		--file cmd/dlx/Dockerfile \
		--tag $(NUCLIO_DOCKER_DLX_IMAGE_NAME) \
		$(NUCLIO_DOCKER_LABELS) .

handler-builder-python-onbuild:
	docker build --build-arg NUCLIO_ARCH=$(NUCLIO_ARCH) --build-arg NUCLIO_LABEL=$(NUCLIO_LABEL) \
		--file pkg/processor/build/runtime/python/docker/onbuild/Dockerfile \
		--tag $(NUCLIO_DOCKER_HANDLER_BUILDER_PYTHON_ONBUILD_IMAGE_NAME) .

handler-builder-nodejs-onbuild:
	docker build --build-arg NUCLIO_ARCH=$(NUCLIO_ARCH) --build-arg NUCLIO_LABEL=$(NUCLIO_LABEL) \
		--file pkg/processor/build/runtime/nodejs/docker/onbuild/Dockerfile \
		--tag $(NUCLIO_DOCKER_HANDLER_BUILDER_NODEJS_ONBUILD_IMAGE_NAME) .

handler-builder-java-onbuild:
	docker build --build-arg NUCLIO_ARCH=$(NUCLIO_ARCH) --build-arg NUCLIO_LABEL=$(NUCLIO_LABEL) \
		--file pkg/processor/build/runtime/java/docker/onbuild/Dockerfile \
		--tag $(NUCLIO_DOCKER_HANDLER_BUILDER_JAVA_ONBUILD_IMAGE_NAME) .

#
# Build & Push
#

controller-push: controller
	docker push $(NUCLIO_DOCKER_CONTROLLER_IMAGE_NAME)

dashboard-push: dashboard
	docker push $(NUCLIO_DOCKER_DASHBOARD_IMAGE_NAME)

autoscaler-push: autoscaler
	docker push $(NUCLIO_DOCKER_SCALER_IMAGE_NAME)

dlx-push: dlx
	docker push $(NUCLIO_DOCKER_DLX_IMAGE_NAME)

processor-push: processor
	docker push $(NUCLIO_DOCKER_PROCESSOR_IMAGE_NAME)

onbuild-push: handler-builder-python-onbuild handler-builder-nodejs-onbuild handler-builder-java-onbuild
	docker push $(NUCLIO_DOCKER_HANDLER_BUILDER_PYTHON_ONBUILD_IMAGE_NAME)
	docker push $(NUCLIO_DOCKER_HANDLER_BUILDER_NODEJS_ONBUILD_IMAGE_NAME)
	docker push $(NUCLIO_DOCKER_HANDLER_BUILDER_JAVA_ONBUILD_IMAGE_NAME)

#
# Etc.
#

ensure-gopath:
ifndef GOPATH
	$(error GOPATH must be set)
endif

targets:
	awk -F: '/^[^ \t="]+:/ && !/PHONY/ {print $$1}' Makefile | sort -u