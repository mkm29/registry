#!/usr/bin/env bash
set -euo pipefail

# Media Server Setup Script
# This script creates the necessary directory structure for the media server stack

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DATA_ROOT="${DATA_ROOT:-/mnt/filestore/data}"
CONFIG_ROOT="${CONFIG_ROOT:-/mnt/filestore/config}"
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

# Function to print colored output
print_status() {
	echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
	echo -e "${RED}[✗]${NC} $1" >&2
}

print_info() {
	echo -e "${YELLOW}[i]${NC} $1"
}

# Function to create directory with proper permissions
create_directory() {
	local dir="$1"
	local description="$2"

	if [[ -d "$dir" ]]; then
		print_info "Directory already exists: $dir"
	else
		if sudo mkdir -p "$dir" 2>/dev/null; then
			print_status "Created $description: $dir"
		else
			print_error "Failed to create $description: $dir"
			exit 1
		fi
	fi
}

# Main setup
main() {
	print_info "Starting media server setup..."
	print_info "DATA_ROOT: $DATA_ROOT"
	print_info "CONFIG_ROOT: $CONFIG_ROOT"
	print_info "PUID: $PUID, PGID: $PGID"
	echo

	# Create config directories
	print_info "Creating configuration directories..."
	create_directory "$CONFIG_ROOT/radarr" "Radarr config"
	create_directory "$CONFIG_ROOT/sonarr" "Sonarr config"
	create_directory "$CONFIG_ROOT/bazarr" "Bazarr config"
	create_directory "$CONFIG_ROOT/prowlarr" "Prowlarr config"
	create_directory "$CONFIG_ROOT/qbittorrent" "qBittorrent config"
	create_directory "$CONFIG_ROOT/overseerr" "Overseerr config"
	create_directory "$CONFIG_ROOT/plex" "Plex config"
	echo

	# Create data directories
	print_info "Creating data directories..."

	# Media directories
	create_directory "$DATA_ROOT/media/movies" "Movies library"
	create_directory "$DATA_ROOT/media/tv" "TV shows library"

	# Download directories
	create_directory "$DATA_ROOT/torrents/movies" "Movie downloads"
	create_directory "$DATA_ROOT/torrents/tv" "TV downloads"
	create_directory "$DATA_ROOT/torrents/incomplete" "Incomplete downloads"
	echo

	# Set ownership
	print_info "Setting ownership to $PUID:$PGID..."

	if sudo chown -R "$PUID:$PGID" "$CONFIG_ROOT" 2>/dev/null; then
		print_status "Set ownership for config directories"
	else
		print_error "Failed to set ownership for config directories"
		exit 1
	fi

	if sudo chown -R "$PUID:$PGID" "$DATA_ROOT" 2>/dev/null; then
		print_status "Set ownership for data directories"
	else
		print_error "Failed to set ownership for data directories"
		exit 1
	fi
	echo

	# Create .env file if it doesn't exist
	if [[ ! -f .env ]]; then
		print_info "Creating .env file from template..."
		if [[ -f .env.example ]]; then
			cp .env.example .env
			print_status "Created .env file - please edit it with your settings"
		else
			print_error "No .env.example file found"
			print_info "Creating basic .env file..."
			cat >.env <<EOF
# Media Server Configuration
DATA_ROOT=$DATA_ROOT
CONFIG_ROOT=$CONFIG_ROOT

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
			print_status "Created basic .env file - please add your Plex claim token and NordVPN key"
		fi
	else
		print_info ".env file already exists"
	fi
	echo

	print_status "Setup complete!"
	print_info "Next steps:"
	echo "  1. Edit the .env file with your settings"
	echo "  2. Add your Plex claim token from https://www.plex.tv/claim/"
	echo "  3. Add your NordVPN private key if using NordLynx"
	echo "  4. Run: docker-compose up -d"
}

# Run main function
main "$@"
