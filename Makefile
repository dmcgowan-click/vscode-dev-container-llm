.PHONY: help prepare-infra login-local login-gcp preview-infra up-infra state-backup build deploy-gcp-artifact deploy-docker-hub

.DEFAULT_GOAL := help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

WORK_DIR := /home/ubuntu/workspace
PULUMI_DIR := $(WORK_DIR)/pulumi
PULUMI_STACK ?= organization/devops/org
export PULUMI_CONFIG_PASSPHRASE :=

# Docker image settings
IMAGE_NAME := vscode-dev-container-llm
DOCKERFILE_PATH := .devcontainer/Dockerfile
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
IMAGE_TAG := $(if $(filter main,$(GIT_BRANCH)),latest,$(subst /,-,$(GIT_BRANCH)))

# Docker Hub settings
DOCKER_HUB_REPO := dmcgowan3e7a/vscode-dev-container-llm

prepare-infra: ## [auto] Prepare Pulumi dir (called by login-local, login-gcp, preview-infra, up-infra, state-backup, deploy-gcp-artifact)
	mkdir -p $(PULUMI_DIR)
	rsync -a --delete --exclude=node_modules pulumi/ $(PULUMI_DIR)/
	cd $(PULUMI_DIR) && npm install

login-local: prepare-infra ## Login to Pulumi locally
	cd $(PULUMI_DIR) && pulumi login --local

login-gcp: prepare-infra ## Login to Pulumi via GCP bucket
	cd $(PULUMI_DIR) && pulumi login gs://$(PULUMI_GCP_BUCKET)

preview-infra: prepare-infra ## Preview infrastructure changes
	cd $(PULUMI_DIR) && pulumi preview -s $(PULUMI_STACK)

up-infra: prepare-infra ## Deploy infrastructure changes
	cd $(PULUMI_DIR) && pulumi up -s $(PULUMI_STACK) --yes

state-backup: prepare-infra ## Backup Pulumi state to GCS
	$(eval BUCKET := $(shell cd $(PULUMI_DIR) && pulumi stack output stateBucketName -s $(PULUMI_STACK)))
	gsutil cp $(HOME)/.pulumi/stacks/devops/$(PULUMI_STACK).json gs://$(BUCKET)/

build: ## Build Docker image locally
	@echo "Building $(IMAGE_NAME):$(IMAGE_TAG)..."
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) -f $(DOCKERFILE_PATH) --build-arg DEV_CONTAINER_PATH=.devcontainer .

deploy-gcp-artifact: build prepare-infra ## Push Docker image to GCP Artifact Registry
	$(eval GCP_PROJECT := $(shell cd $(PULUMI_DIR) && pulumi stack output projectIdOutput -s $(PULUMI_STACK)))
	$(eval GCP_REGION := $(shell cd $(PULUMI_DIR) && pulumi config get devops:gcpRegion -s $(PULUMI_STACK)))
	$(eval REPO_NAME := $(shell cd $(PULUMI_DIR) && pulumi stack output devtoolsRepository -s $(PULUMI_STACK) | awk -F/ '{print $$NF}'))
	$(eval REGISTRY := $(GCP_REGION)-docker.pkg.dev/$(GCP_PROJECT)/$(REPO_NAME))
	@echo "Verifying Artifact Registry '$(REPO_NAME)' exists..."
	@gcloud artifacts repositories describe $(REPO_NAME) --project=$(GCP_PROJECT) --location=$(GCP_REGION) > /dev/null 2>&1 || \
		{ echo "ERROR: Artifact Registry '$(REPO_NAME)' not found in project '$(GCP_PROJECT)', region '$(GCP_REGION)'. Run 'make up-infra' first."; exit 1; }
	@gcloud auth configure-docker $(GCP_REGION)-docker.pkg.dev --quiet
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
	@echo "Pushing $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)..."
	docker push $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

deploy-docker-hub: build ## Push Docker image to Docker Hub
	@echo "Logging in to Docker Hub..."
	@echo "$(DOCKER_HUB_TOKEN)" | docker login -u "$(DOCKER_HUB_USER)" --password-stdin
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(DOCKER_HUB_REPO):$(IMAGE_TAG)
	@echo "Pushing $(DOCKER_HUB_REPO):$(IMAGE_TAG)..."
	docker push $(DOCKER_HUB_REPO):$(IMAGE_TAG)

