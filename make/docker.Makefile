ifndef MK_DOCKER
MK_DOCKER=1

include make/env.Makefile
include make/vars.app.Makefile
include make/vars.docker.Makefile

# DOCKER

.PHONY: docker-build docker-run docker-console docker-clean docker-push docker-gcr-login

ifndef INSIDE_CI
# This overrides the previous value
# This TTY arg is used for local build, that way we can cancel build with ctrl+c
DOCKER_TTY_ARG=-t
endif

docker-build: docker-setup-builder ## Build docker image
	docker run -i $(DOCKER_TTY_ARG) --rm --net host \
		-v /var/run/docker.sock:/docker.sock \
		-e DOCKER_HOST=unix:///docker.sock \
		-v /tmp/makisu-storage:/makisu-storage \
		-v $(DOCKER_CONTEXT_DIR):/makisu-context \
		$(MAKISU_IMAGE) $(DOCKER_IMAGE_NAME_VERSION) $(DOCKER_BUILD_ARGS_OPTIONS)

docker-run: docker-build ## Build and run the docker container
	docker run --rm --name $(APP_NAME) $(DOCKER_PORT_OPTIONS) -it $(DOCKER_IMAGE_NAME_VERSION)

docker-console: docker-build ## Run a bash console in the docker container
	docker run --rm --name $(APP_NAME) $(DOCKER_PORT_OPTIONS) -it --entrypoint /bin/bash $(DOCKER_IMAGE_NAME_VERSION)

docker-clean: ## Delete the docker image
	docker image rm $(APP_NAME)

# GOOGLE_APPLICATION_CREDENTIALS env variable needs to be interpreted my Makefile and not shell, 
# otherwise it won't work in Github Actions since it contains ${HOME} var from Github env
docker-push: docker-setup-builder ## Push the docker image to the registry
	docker run -i $(DOCKER_TTY_ARG) --rm \
		-v $(DOCKER_CONTEXT_DIR):/makisu-context \
		-v $$(dirname ${GOOGLE_APPLICATION_CREDENTIALS}):/secrets/gcp \
		-e DOCKER_USERNAME=$(DOCKER_USERNAME) \
		-e DOCKER_TOKEN=$(DOCKER_TOKEN) \
		-e DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
		-e DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) \
		-e GOOGLE_APPLICATION_CREDENTIALS_NAME=$$(basename ${GOOGLE_APPLICATION_CREDENTIALS}) \
		$(MAKISU_IMAGE) $(DOCKER_IMAGE_NAME_VERSION) \
		--push $(DOCKER_REGISTRY) \
		--replica $(DOCKER_FULL_NAME_LATEST) \
		$(DOCKER_BUILD_ARGS_OPTIONS)

ifeq ($(MAKISU_SELF_BUILD),1)
docker-setup-builder: docker-gcr-login
else
docker-setup-builder: docker-gcr-login
	docker pull $(MAKISU_IMAGE)
endif

docker-gcr-login: generate-gcp-credentials ## Log to GCR docker registry for pulling builder image, and possibly pushing image
	@cat $(GOOGLE_APPLICATION_CREDENTIALS) | docker login -u _json_key --password-stdin https://$(DOCKER_BUILDER_REGISTRY)

endif
