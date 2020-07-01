ifndef MK_VARS_DOCKER
MK_VARS_DOCKER=1


APP_NAME ?= $(shell node -p -e 'require("./docker.json").app.name')
APP_VERSION ?= $(shell node -p -e 'require("./docker.json").app.version')

DOCKER_REGISTRY = $(shell node -p -e 'require("./docker.json").docker.registry')
DOCKER_REPOSITORY = $(shell node -p -e 'require("./docker.json").docker.repository')


endif 
