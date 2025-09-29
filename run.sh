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

# Function to create directory with proper permissions
create_directory() {
	local dir="$1"
	local description="$2"
	local owner="${3:-$(id -u):$(id -g)}"

	if [[ -d "$dir" ]]; then
		log_info "Directory already exists: $dir"
	else
		if sudo mkdir -p "$dir" 2>/dev/null; then
			log_success "Created $description: $dir"
		else
			log_error "Failed to create $description: $dir"
			return 1
		fi
	fi

	# Set ownership (defaults to current user if not specified)
	if sudo chown -R "$owner" "$dir" 2>/dev/null; then
		log_info "Set ownership for $description to $owner"
	else
		log_warning "Failed to set ownership for $description"
	fi
}

# Function to setup infrastructure directories
setup_infrastructure_directories() {
	log_info "Setting up infrastructure directories..."

	# Create base data directory
	create_directory "/mnt/data" "Base data directory"

	# Infrastructure service directories
	log_info "Creating infrastructure service directories..."
	create_directory "/mnt/data/logs/traefik" "Traefik logs"
	create_directory "/mnt/data/grafana/csv" "Grafana CSV exports"
	create_directory "/mnt/data/grafana/dashboards" "Grafana dashboards"
	create_directory "/mnt/data/grafana/pdf" "Grafana PDF exports"
	create_directory "/mnt/data/grafana/plugins" "Grafana plugins"
	create_directory "/mnt/data/grafana/png" "Grafana PNG exports"
	create_directory "/mnt/data/mimir-1" "Mimir instance 1"
	create_directory "/mnt/data/mimir-2" "Mimir instance 2"
	create_directory "/mnt/data/mimir-3" "Mimir instance 3"
	create_directory "/mnt/data/minio" "MinIO storage"
	create_directory "/mnt/data/postgres" "PostgreSQL data"
	create_directory "/mnt/data/redis" "Redis data"
	create_directory "/mnt/data/zot" "Zot registry data"

	log_success "Infrastructure directories setup complete"
}

# Function to setup mediaserver directories
setup_mediaserver_directories() {
	log_info "Setting up media server directories..."

	# Configuration from environment or defaults
	local data_root="${DATA_ROOT:-/mnt/filestore/data}"
	local config_root="${CONFIG_ROOT:-/mnt/filestore/config}"
	local puid="${PUID:-1000}"
	local pgid="${PGID:-1000}"
	local owner="$puid:$pgid"

	log_info "DATA_ROOT: $data_root"
	log_info "CONFIG_ROOT: $config_root"
	log_info "PUID: $puid, PGID: $pgid"

	# Create config directories
	log_info "Creating configuration directories..."
	create_directory "$config_root/radarr" "Radarr config"
	create_directory "$config_root/sonarr" "Sonarr config"
	create_directory "$config_root/bazarr" "Bazarr config"
	create_directory "$config_root/prowlarr" "Prowlarr config"
	create_directory "$config_root/qbittorrent" "qBittorrent config"
	create_directory "$config_root/overseerr" "Overseerr config"
	create_directory "$config_root/plex" "Plex config"

	# Create media data directories
	log_info "Creating media data directories..."
	create_directory "$data_root/media/movies" "Movies library"
	create_directory "$data_root/media/tv" "TV shows library"
	create_directory "$data_root/torrents/movies" "Movie downloads"
	create_directory "$data_root/torrents/tv" "TV downloads"
	create_directory "$data_root/torrents/incomplete" "Incomplete downloads"

	# Also create the infrastructure media directories
	create_directory "/mnt/data/media/media" "Infrastructure media storage"
	create_directory "/mnt/data/media/torrents" "Infrastructure torrent storage"

	# Set ownership for entire directory trees (more efficient than per-directory)
	log_info "Setting ownership to $owner..."
	if sudo chown -R "$owner" "$config_root" 2>/dev/null; then
		log_success "Set ownership for config directories"
	else
		log_warning "Failed to set ownership for config directories"
	fi

	if sudo chown -R "$owner" "$data_root" 2>/dev/null; then
		log_success "Set ownership for data directories"
	else
		log_warning "Failed to set ownership for data directories"
	fi

	# Create .env file if it doesn't exist in mediaserver directory
	if [[ ! -f "mediaserver/.env" ]]; then
		log_info "Creating mediaserver .env file..."
		cat >"mediaserver/.env" <<EOF
# Media Server Configuration
DATA_ROOT=$data_root
CONFIG_ROOT=$config_root

# Service Ports
RADARR_PORT=7878
SONARR_PORT=8989
BAZARR_PORT=6767
PROWLARR_PORT=9696
QBITTORRENT_WEB_PORT=8080
QBITTORRENT_TORRENTING_PORT=6881
OVERSEERR_PORT=5055

# Plex
PLEX_CLAIM=

# NordVPN (for NordLynx)
NORDLYNX_PRIVATE_KEY=
EOF
		log_success "Created mediaserver .env file - please edit with your settings"
		log_info "Add your Plex claim token from https://www.plex.tv/claim/"
		log_info "Add your NordVPN private key if using NordLynx"
	else
		log_info "mediaserver/.env file already exists"
	fi

	log_success "Media server directories setup complete"
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

	# Setup infrastructure directories
	setup_infrastructure_directories

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

	# 6. Setup Media Server directories
	setup_mediaserver_directories

	# 7. Start Media Server Stack
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
