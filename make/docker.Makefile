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

docker-build: docker-builder-login ## Build docker image
	docker run -i $(DOCKER_TTY_ARG) --rm --net host \
		-v /var/run/docker.sock:/docker.sock \
		-e DOCKER_HOST=unix:///docker.sock \
		-v /tmp/makisu-storage:/makisu-storage \
		-v $$(pwd):/makisu-context \
		$(MAKISU_IMAGE) $(DOCKER_IMAGE_NAME_VERSION) $(DOCKER_BUILD_ARGS_OPTIONS)

docker-run: docker-build ## Build and run the docker container
	docker run --rm --name $(APP_NAME) $(DOCKER_PORT_OPTIONS) -it $(DOCKER_IMAGE_NAME_VERSION)

docker-console: docker-build ## Run a bash console in the docker container
	docker run --rm --name $(APP_NAME) $(DOCKER_PORT_OPTIONS) -it --entrypoint /bin/bash $(DOCKER_IMAGE_NAME_VERSION)

docker-clean: ## Delete the docker image
	docker image rm $(APP_NAME)

docker-push: docker-builder-login docker-push-login ## Push the docker image to the registry
	# GOOGLE_APPLICATION_CREDENTIALS env variable needs to be interpreted by Makefile and not shell, 
	# otherwise it won't work in Github Actions since it contains ${HOME} var from Github env
	docker run -i $(DOCKER_TTY_ARG) --rm \
		-v $$(pwd):/makisu-context \
		-v $$(dirname ${GOOGLE_APPLICATION_CREDENTIALS}):/secrets/gcp \
		-e GOOGLE_APPLICATION_CREDENTIALS_NAME=$$(basename ${GOOGLE_APPLICATION_CREDENTIALS}) \
		$(MAKISU_IMAGE) $(DOCKER_IMAGE_NAME_VERSION) \
			--replica ${DOCKER_TAG_BASE}:${DOCKER_TAG_LATEST} \
			$(DOCKER_BUILD_ARGS_OPTIONS)

define gcr_login
	@cat $(GOOGLE_APPLICATION_CREDENTIALS) | docker login -u _json_key --password-stdin https://$(1)
endef

define docker_login
	@echo $(DOCKER_TOKEN) | docker login -u $(DOCKER_USERNAME) --password-stdin
endef

# We need to determine how to login to the builder registry
# if it's GCP, etc.
ifneq (,$(findstring gcr.io,$(DOCKER_BUILDER_REGISTRY)))
DOCKER_BUILDER_REGISTRY_HAS_LOGIN=1
$(info Using GCR to retrieve the builder image from $(DOCKER_BUILDER_REGISTRY))
docker-builder-login: generate-gcp-credentials
	$(call gcr_login,$(DOCKER_BUILDER_REGISTRY))
endif

ifneq ($(DOCKER_BUILDER_REGISTRY_HAS_LOGIN),1)
$(error No valid login target for $(DOCKER_BUILDER_REGISTRY))
endif

ifneq (,$(findstring gcr.io,$(DOCKER_REGISTRY)))
DOCKER_REGISTRY_HAS_LOGIN=1
$(info Using GCR to push the image to $(DOCKER_REGISTRY))
docker-push-login: generate-gcp-credentials
	$(call gcr_login,$(DOCKER_REGISTRY))
endif

ifneq (,$(findstring docker.io,$(DOCKER_REGISTRY)))
DOCKER_REGISTRY_HAS_LOGIN=1
$(info Using docker.io to push the image to $(DOCKER_REGISTRY))
docker-push-login:
	$(call docker_login)
endif

ifneq ($(DOCKER_REGISTRY_HAS_LOGIN),1)
$(error No valid login target for $(DOCKER_REGISTRY))
endif

endif
