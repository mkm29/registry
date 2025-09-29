#!/bin/bash
# Multi-Stack Container Infrastructure Orchestrated Startup Script
# This script decrypts secrets and starts all components in the correct order

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
	if ! docker info >/dev/null 2>&1; then
		log_error "Docker is not running or not accessible"
		exit 1
	fi
	log_success "Docker is running"
}

# Function to check if required directories exist
check_directories() {
	local required_dirs=("zot" "traefik" "auth" "minio" "monitoring" "mediaserver" "secrets")

	for dir in "${required_dirs[@]}"; do
		if [[ ! -d "$dir" ]]; then
			log_error "Required directory '$dir' not found"
			exit 1
		fi
	done
	log_success "All required directories found"
}

# Function to decrypt and collect secrets
prepare_secrets() {
	log_info "Preparing secrets..."

	# Check if sops-helper.sh exists and is executable
	if [[ ! -x "./sops-helper.sh" ]]; then
		log_error "sops-helper.sh not found or not executable"
		exit 1
	fi

	# Decrypt all secrets
	log_info "Decrypting all encrypted secrets..."
	./sops-helper.sh decrypt secrets

	# Collect all .env files
	log_info "Collecting all .env files..."
	./sops-helper.sh collect

	log_success "Secrets prepared successfully"
}

# Function to create external networks if they don't exist
create_networks() {
	log_info "Creating external Docker networks..."

	local networks=("registry" "traefik" "auth" "monitoring" "mediaserver")

	for network in "${networks[@]}"; do
		if ! docker network inspect "$network" >/dev/null 2>&1; then
			log_info "Creating network: $network"
			docker network create "$network"
		else
			log_info "Network '$network' already exists"
		fi
	done

	log_success "All networks ready"
}

# Function to wait for service health
wait_for_service() {
	local service_name="$1"
	local max_attempts="${2:-30}"
	local attempt=1

	log_info "Waiting for $service_name to be healthy..."

	while [[ $attempt -le $max_attempts ]]; do
		if docker ps --filter "name=$service_name" --filter "health=healthy" --format "table {{.Names}}" | grep -q "$service_name"; then
			log_success "$service_name is healthy"
			return 0
		fi

		log_info "Attempt $attempt/$max_attempts: $service_name not healthy yet, waiting 10s..."
		sleep 10
		((attempt++))
	done

	log_error "$service_name did not become healthy within expected time"
	return 1
}

# Function to wait for service to be running (for services without health checks)
wait_for_running() {
	local service_name="$1"
	local max_attempts="${2:-15}"
	local attempt=1

	log_info "Waiting for $service_name to be running..."

	while [[ $attempt -le $max_attempts ]]; do
		if docker ps --filter "name=$service_name" --filter "status=running" --format "table {{.Names}}" | grep -q "$service_name"; then
			log_success "$service_name is running"
			return 0
		fi

		log_info "Attempt $attempt/$max_attempts: $service_name not running yet, waiting 5s..."
		sleep 5
		((attempt++))
	done

	log_error "$service_name did not start within expected time"
	return 1
}

# Function to start a stack
start_stack() {
	local stack_name="$1"
	local stack_dir="$2"
	shift 2
	local services=("$@")

	log_info "Starting $stack_name stack..."

	cd "$stack_dir"
	docker compose up -d
	cd - >/dev/null

	# Wait for services to be ready
	for service in "${services[@]}"; do
		if [[ "$service" == *":health" ]]; then
			# Service with health check
			service_name="${service%:health}"
			wait_for_service "$service_name"
		else
			# Service without health check
			wait_for_running "$service"
		fi
	done

	log_success "$stack_name stack started successfully"
}

# Function to display service status
show_status() {
	log_info "Current service status:"
	echo ""
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(registry|traefik|authentik|minio|mimir|grafana|loki|tempo|alloy|plex|radarr|sonarr)"
	echo ""
}

# Main execution
main() {
	log_info "Starting Multi-Stack Container Infrastructure..."
	log_info "Startup order: secrets → zot → traefik → auth → minio → monitoring → mediaserver"
	echo ""

	# Pre-flight checks
	check_docker
	check_directories

	# Prepare secrets
	prepare_secrets

	# Create networks
	create_networks

	echo ""
	log_info "=========================================="
	log_info "Starting services in dependency order..."
	log_info "=========================================="
	echo ""

	# 1. Start Zot Registry
	start_stack "Zot Registry" "zot" "registry:health"

	# 2. Start Traefik
	start_stack "Traefik Reverse Proxy" "traefik" "traefik"

	# 3. Start Authentication (Authentik)
	start_stack "Authentication (Authentik)" "auth" "postgresql" "redis" "authentik-server" "authentik-worker"

	# 4. Start MinIO Storage
	start_stack "MinIO Storage" "minio" "minio:health" "minio-mc"

	# 5. Start Monitoring Stack
	start_stack "Monitoring Stack" "monitoring" "mimir-1" "mimir-2" "mimir-3" "mimir-lb" "loki:health" "grafana" "tempo" "alloy" "cadvisor"

	# 6. Start Media Server Stack
	start_stack "Media Server" "mediaserver" "plex" "radarr" "sonarr" "bazarr" "prowlarr" "qbittorrent" "overseerr"

	echo ""
	log_success "=========================================="
	log_success "All stacks started successfully!"
	log_success "=========================================="
	echo ""

	# Show final status
	show_status

	echo ""
	log_info "Access points:"
	log_info "• Traefik Dashboard: http://localhost:8080"
	log_info "• Zot Registry: http://localhost:5000"
	log_info "• Grafana: http://localhost:3000"
	log_info "• MinIO Console: http://localhost:9001"
	log_info "• Plex: http://localhost:32400/web"
	log_info "• Authentik: http://localhost:9008"
	echo ""
	log_success "Infrastructure startup complete!"
}

# Handle script interruption
cleanup() {
	log_warning "Script interrupted. You may need to manually stop services if they were partially started."
	exit 1
}

trap cleanup INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
