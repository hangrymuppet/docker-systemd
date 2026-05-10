include .env
export

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: install-binfmt
install-binfmt: ## Install multi-arch build support (binfmt) into the Docker engine
	docker run --privileged --rm tonistiigi/binfmt --install all

.PHONY: runner-start
runner-start: ## Start the GitHub Actions runner in Docker (injects secret from 1Password)
	@if [ $$(docker ps -aq -f name=$(CONTAINER_NAME)) ]; then \
		if [ $$(docker ps -q -f name=$(CONTAINER_NAME)) ]; then \
			echo "Runner is already running."; \
		else \
			echo "Starting existing runner container..."; \
			docker start $(CONTAINER_NAME); \
		fi \
	else \
		echo "Creating and starting new runner container..."; \
		op run --env-file .env -- docker run -d \
			--name $(CONTAINER_NAME) \
			-e REPO_URL \
			-e RUNNER_NAME \
			-e RUNNER_TOKEN \
			-v /var/run/docker.sock:/var/run/docker.sock \
			$(IMAGE_REPO):$(IMAGE_TAG); \
	fi

.PHONY: runner-stop
runner-stop: ## Stop the runner container
	docker stop $(CONTAINER_NAME)

.PHONY: runner-status
runner-status: ## Show the status of the runner container
	docker ps -f name=$(CONTAINER_NAME)

.PHONY: runner-logs
runner-logs: ## Follow the runner logs
	docker logs -f $(CONTAINER_NAME)

.PHONY: runner-clean
runner-clean: ## Remove the runner container
	docker rm -f $(CONTAINER_NAME)
