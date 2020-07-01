ifndef MK_DOCKER
MK_DOCKER=1

include make/vars*.Makefile

# DOCKER

.PHONY: docker-build docker-run docker-stop docker-clean docker-info docker-console docker-login docker-push

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

DOCKER_REMOTE_NAME_VERSION = $(DOCKER_REGISTRY)/$(DOCKER_REPOSITORY)/$(APP_NAME):$(DOCKER_TAG_VERSION)
DOCKER_REMOTE_NAME_LATEST = $(DOCKER_REGISTRY)/$(DOCKER_REPOSITORY)/$(APP_NAME):$(DOCKER_TAG_LATEST)

DOCKER_BUILD_ARGS = --build-arg APP_VERSION=$(DOCKER_TAG_VERSION) 

docker-build:
	docker build $(DOCKER_BUILD_ARGS) -t $(DOCKER_IMAGE_NAME_VERSION) .
	docker tag $(DOCKER_IMAGE_NAME_VERSION) $(DOCKER_IMAGE_NAME_LATEST)

docker-run: docker-build ## Build and run the docker container
	docker run --rm --name $(APP_NAME) -it $(DOCKER_IMAGE_NAME_VERSION)

docker-console: docker-build ## Run a bash console in the docker container
	docker run --rm --name $(APP_NAME) -it --entrypoint /bin/bash $(DOCKER_IMAGE_NAME_VERSION)

docker-clean: ## Delete the docker image
	docker image rm $(APP_NAME)

docker-push: docker-build ## Push the docker image to the registry
	docker tag $(DOCKER_IMAGE_NAME_VERSION) $(DOCKER_REMOTE_NAME_VERSION)
	docker tag $(DOCKER_IMAGE_NAME_VERSION) $(DOCKER_REMOTE_NAME_LATEST)
	docker push $(DOCKER_REMOTE_NAME_VERSION)
	docker push $(DOCKER_REMOTE_NAME_LATEST)

docker-info: ## Print useful info on the docker image
	$(info ::set-output name=docker_registry::$(DOCKER_REGISTRY))
	$(info ::set-output name=docker_repository::$(DOCKER_REPOSITORY))
	$(info ::set-output name=docker_tag::$(DOCKER_TAG_VERSION))
	$(info ::set-output name=docker_build_args::)
	@#

endif
