# HELP
# This will output the help for each task
.PHONY: help certs cert-ca cert-intermediate cert-registry up down restart logs clean trust-cert test-pull test-push status health gc quickstart verify-certs test-tls metrics

# Tasks
help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# Certificate generation
cert-ca: ## Generate root CA certificate
	@echo "Generating root CA..."
	@mkdir -p certs
	cfssl gencert -initca cfssl/ca.json | cfssljson -bare certs/ca

cert-intermediate: cert-ca ## Generate intermediate CA certificate
	@echo "Generating intermediate CA..."
	cfssl gencert -initca cfssl/intermediate-ca.json | cfssljson -bare certs/intermediate_ca
	@echo "Signing intermediate CA with root CA..."
	cfssl sign -ca certs/ca.pem -ca-key certs/ca-key.pem -config cfssl/cfssl.json -profile intermediate_ca certs/intermediate_ca.csr | cfssljson -bare certs/intermediate_ca

cert-registry: cert-intermediate ## Generate registry certificates (peer, server, client)
	@echo "Generating registry certificates..."
	cfssl gencert -ca certs/intermediate_ca.pem -ca-key certs/intermediate_ca-key.pem -config cfssl/cfssl.json -profile=peer cfssl/registry.json | cfssljson -bare certs/registry-peer
	cfssl gencert -ca certs/intermediate_ca.pem -ca-key certs/intermediate_ca-key.pem -config cfssl/cfssl.json -profile=server cfssl/registry.json | cfssljson -bare certs/registry-server
	cfssl gencert -ca certs/intermediate_ca.pem -ca-key certs/intermediate_ca-key.pem -config cfssl/cfssl.json -profile=client cfssl/registry.json | cfssljson -bare certs/registry-client
	@echo "Creating certificate chain..."
	cat certs/registry-server.pem certs/intermediate_ca.pem > certs/registry.crt
	cp certs/registry-server-key.pem certs/registry.key

certs: cert-registry ## Generate all certificates

# Docker Compose operations
up: check-env ## Start all services with docker-compose
	@echo "Starting all services..."
	docker-compose up -d

down: ## Stop all services
	@echo "Stopping all services..."
	docker-compose down

restart: ## Restart all services
	@echo "Restarting all services..."
	docker-compose restart

clean: ## Stop services and remove volumes
	@echo "Stopping services and removing volumes..."
	docker-compose down -v

# Logging
logs: ## View logs from all services
	docker-compose logs -f

logs-registry: ## View registry logs
	docker-compose logs -f registry

logs-mimir: ## View Mimir logs
	docker-compose logs -f mimir

logs-grafana: ## View Grafana logs
	docker-compose logs -f grafana

logs-jaeger: ## View Jaeger logs
	docker-compose logs -f jaeger

# Status and health
status: ## Check status of all services
	@echo "Service status:"
	@docker-compose ps
	@echo ""
	@echo "Service URLs:"
	@echo "  Registry:   https://localhost:6000"
	@echo "  Mimir:      http://localhost:9009"
	@echo "  Grafana:    http://localhost:3000"
	@echo "  Jaeger:     http://localhost:16686"

health: ## Check registry health
	@echo "Checking registry health..."
	@curl -k https://localhost:6000/v2/ || echo "Registry not responding"

# Testing
test-pull: ## Test pulling an image through the registry
	@echo "Testing image pull through registry..."
	docker pull localhost:6000/library/alpine:latest

test-push: test-pull ## Test pushing an image to the registry
	@echo "Testing image push to registry..."
	docker tag localhost:6000/library/alpine:latest localhost:6000/test/alpine:latest
	docker push localhost:6000/test/alpine:latest

# TLS Configuration
trust-cert: ## Trust CA certificate (macOS only)
	@echo "Adding CA certificate to system trust store (requires sudo)..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain certs/ca.pem; \
		echo "CA certificate trusted successfully"; \
	else \
		echo "This command is only for macOS. For other systems, please manually trust certs/ca.pem"; \
	fi

configure-docker-tls: ## Configure Docker to trust the registry certificates
	@echo "Configuring Docker to trust registry certificates..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		echo "Configuring for macOS..."; \
		mkdir -p $$HOME/.docker/certs.d/localhost:6000; \
		cp certs/ca.pem $$HOME/.docker/certs.d/localhost:6000/ca.crt; \
		chmod 644 $$HOME/.docker/certs.d/localhost:6000/ca.crt; \
		echo "Docker Desktop will reload automatically."; \
	else \
		echo "Configuring for Linux..."; \
		sudo mkdir -p /etc/docker/certs.d/localhost:6000; \
		sudo cp certs/ca.pem /etc/docker/certs.d/localhost:6000/ca.crt; \
		sudo chmod 644 /etc/docker/certs.d/localhost:6000/ca.crt; \
		echo "Restart Docker with: sudo systemctl restart docker"; \
	fi
	@echo "Docker TLS configuration complete."

# Maintenance
gc: ## Run garbage collection on registry
	@echo "Running garbage collection on registry..."
	docker exec registry registry garbage-collect /etc/distribution/config.yml

# Quick setup
quickstart: certs up status ## Generate certs and start all services
	@echo ""
	@echo "Quick start complete! Services are running."
	@echo ""
	@echo "IMPORTANT: To use the registry with Docker, you must configure TLS trust:"
	@echo "  make configure-docker-tls  # Configure Docker daemon (required)"
	@echo "  make trust-cert           # Add to system keychain (optional, macOS only)"

# Certificate verification
verify-certs: ## Verify certificate chain
	@echo "Verifying certificate chain..."
	openssl verify -CAfile certs/ca.pem -untrusted certs/intermediate_ca.pem certs/registry.crt

test-tls: ## Test TLS connection to registry
	@echo "Testing TLS connection to registry..."
	openssl s_client -connect localhost:6000 -CAfile certs/ca.pem -showcerts </dev/null

# Mimir
mimir-status: ## Open Mimir status page
	@echo "Opening Mimir status page..."
	@open http://localhost:9009/ready 2>/dev/null || xdg-open http://localhost:9009/ready 2>/dev/null || echo "Please open http://localhost:9009/ready in your browser"

# Metrics
metrics: ## View registry metrics
	@echo "Fetching registry metrics..."
	@docker exec registry wget -O- --no-check-certificate https://localhost:5001/metrics 2>/dev/null | grep -E '^registry_' | head -20

# Registry API
list-repos: ## List all repositories in the registry
	@echo "Listing repositories..."
	@curl -sk https://localhost:6000/v2/_catalog | jq . 2>/dev/null || curl -sk https://localhost:6000/v2/_catalog

list-tags: ## List tags for a repository (usage: make list-tags REPO=library/alpine)
	@if [ -z "$(REPO)" ]; then \
		echo "Usage: make list-tags REPO=library/alpine"; \
		exit 1; \
	fi
	@echo "Listing tags for $(REPO)..."
	@curl -sk https://localhost:6000/v2/$(REPO)/tags/list | jq . 2>/dev/null || curl -sk https://localhost:6000/v2/$(REPO)/tags/list

get-manifest: ## Get manifest for a repository tag (usage: make get-manifest REPO=library/alpine TAG=latest)
	@if [ -z "$(REPO)" ] || [ -z "$(TAG)" ]; then \
		echo "Usage: make get-manifest REPO=library/alpine TAG=latest"; \
		exit 1; \
	fi
	@echo "Getting manifest for $(REPO):$(TAG)..."
	@curl -sk -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
		https://localhost:6000/v2/$(REPO)/manifests/$(TAG) | jq . 2>/dev/null || \
		curl -sk -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
		https://localhost:6000/v2/$(REPO)/manifests/$(TAG)

# Helpers
check-env:
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found. Creating from template..."; \
		cp .env.example .env; \
		echo "Please edit .env with your Docker Hub credentials before proceeding."; \
		exit 1; \
	fi
	@if [ ! -f certs/registry.crt ]; then \
		echo "Error: Certificates not found. Run 'make certs' first."; \
		exit 1; \
	fi