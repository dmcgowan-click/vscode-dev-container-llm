.PHONY: login login_gcp preview up preview_auto up_auto prepare state_backup docker_push

WORK_DIR := /home/ubuntu/workspace
PULUMI_DIR := $(WORK_DIR)/pulumi
PULUMI_STACK ?= org
export PULUMI_CONFIG_PASSPHRASE :=

# Docker image settings
IMAGE_NAME := vscode-dev-container-llm
DOCKERFILE_PATH := .devcontainer/Dockerfile
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
IMAGE_TAG := $(if $(filter main,$(GIT_BRANCH)),latest,$(subst /,-,$(GIT_BRANCH)))

#We do this due to performance issues with the filesystem mount to the host device
prepare:
	mkdir -p $(PULUMI_DIR)
	rsync -a --delete --exclude=node_modules pulumi/ $(PULUMI_DIR)/
	cd $(PULUMI_DIR) && npm install

login_local: prepare
	cd $(PULUMI_DIR) && pulumi login --local

login_gcp: prepare
	cd $(PULUMI_DIR) && pulumi login gs://$(PULUMI_GCP_BUCKET)

preview: prepare
	cd $(PULUMI_DIR) && pulumi preview -s $(PULUMI_STACK)

up: prepare
	cd $(PULUMI_DIR) && pulumi up -s $(PULUMI_STACK) --yes

preview_auto: prepare
	cd $(PULUMI_DIR) && pulumi preview -s $(PULUMI_STACK) --non-interactive

up_auto: prepare
	cd $(PULUMI_DIR) && pulumi up -s $(PULUMI_STACK) --yes --skip-preview --non-interactive

state_backup: prepare
	$(eval BUCKET := $(shell cd $(PULUMI_DIR) && pulumi stack output stateBucketName -s $(PULUMI_STACK)))
	gsutil cp $(HOME)/.pulumi/stacks/devops/$(PULUMI_STACK).json gs://$(BUCKET)/

build_push: prepare
	$(eval GCP_PROJECT := $(shell cd $(PULUMI_DIR) && pulumi stack output projectIdOutput -s $(PULUMI_STACK)))
	$(eval GCP_REGION := $(shell cd $(PULUMI_DIR) && pulumi config get devops:gcpRegion -s $(PULUMI_STACK)))
	$(eval REGISTRY := $(GCP_REGION)-docker.pkg.dev/$(GCP_PROJECT)/devtools)
	@echo "Verifying Artifact Registry 'devtools' exists..."
	@gcloud artifacts repositories describe devtools --project=$(GCP_PROJECT) --location=$(GCP_REGION) > /dev/null 2>&1 || \
		{ echo "ERROR: Artifact Registry 'devtools' not found in project '$(GCP_PROJECT)', region '$(GCP_REGION)'. Run 'make up' first."; exit 1; }
	@gcloud auth configure-docker $(GCP_REGION)-docker.pkg.dev --quiet
	@echo "Building $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)..."
	docker build -t $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) -f $(DOCKERFILE_PATH) --build-arg DEV_CONTAINER_PATH=.devcontainer .
	@echo "Pushing $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)..."
	docker push $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

