ifndef MK_VARS_DOCKER
MK_VARS_DOCKER=1

include make/env.Makefile
include make/vars.app.Makefile
include make/vars.docker.*Makefile

DOCKER_BUILDER_REGISTRY ?= eu.gcr.io
DOCKER_BUILDER_REPOSITORY ?= otc-registry-prod
DOCKER_BUILDER_IMAGE ?= makisu-builder:latest

DOCKER_CONTEXT_DIR ?= $(shell pwd)

ifeq ($(MAKISU_SELF_BUILD),1)
$(info Makisu is attempting a self-build)
MAKISU_IMAGE = $(DOCKER_IMAGE_NAME_VERSION)
else
MAKISU_IMAGE = $(DOCKER_BUILDER_REGISTRY)/$(DOCKER_BUILDER_REPOSITORY)/$(DOCKER_BUILDER_IMAGE)
endif

# The registry part is optional - without a registry, it defaults to docker hub
DOCKER_REGISTRY ?= docker.io
DOCKER_TAG_BASE = $(DOCKER_REGISTRY)/$(DOCKER_REPOSITORY)/$(APP_NAME)


ifeq ($(IN_GIT_MAIN),1)
DOCKER_TAG_LATEST = latest
DOCKER_TAG_VERSION = $(APP_VERSION)
else
DOCKER_TAG_LATEST = latest-$(GIT_BRANCH_NORMAL)
DOCKER_TAG_VERSION = $(APP_VERSION)-$(GIT_BRANCH_NORMAL)
endif

DOCKER_IMAGE_NAME_VERSION = $(APP_NAME):$(DOCKER_TAG_VERSION)
DOCKER_IMAGE_NAME_LATEST = $(APP_NAME):$(DOCKER_TAG_LATEST)

DOCKER_FULL_NAME_VERSION = $(DOCKER_REGISTRY)/$(DOCKER_REPOSITORY)/$(DOCKER_IMAGE_NAME_VERSION)
DOCKER_FULL_NAME_LATEST = $(DOCKER_REGISTRY)/$(DOCKER_REPOSITORY)/$(DOCKER_IMAGE_NAME_LATEST)

DOCKER_APP_BUILD_ARGS = APP_VERSION=$(DOCKER_TAG_VERSION) \
						APP_NAME=$(APP_NAME)

ifndef DOCKER_BUILD_ARGS
DOCKER_BUILD_ARGS = $(DOCKER_APP_BUILD_ARGS)
else
DOCKER_BUILD_ARGS += $(DOCKER_APP_BUILD_ARGS) + $(DOCKER_POETRY_BUILD_ARGS)
endif

ifdef APP_PORT
DOCKER_APP_BUILD_ARGS += APP_PORT=$(APP_PORT)
DOCKER_PORT_OPTIONS = -p $(APP_PORT):$(APP_PORT)
else
DOCKER_PORT_OPTIONS =
endif

DOCKER_BUILD_ARGS_OPTIONS = --build-arg $(subst $(space), --build-arg ,$(DOCKER_BUILD_ARGS))

endif
