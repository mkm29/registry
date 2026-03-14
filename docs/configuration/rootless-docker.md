# Rootless Container Runtime Setup

> **Note:** This project defaults to **Podman 5.0+** as the container runtime. **Docker CE 28.3+** is also supported. Choose the section below that matches your runtime.

______________________________________________________________________

## Podman (Default)

Podman runs rootless by default -- no additional setup is required beyond installing the package.

```bash
# Arch / CachyOS
sudo pacman -S podman podman-compose

# Ubuntu / Debian
sudo apt install podman podman-compose

# Verify installation
podman version
podman info
```

Registry certificate trust is handled automatically by the project:

```bash
task trust-ca
```

Container configuration lives under `~/.config/containers/`. The relevant files are:

- `~/.config/containers/registries.conf` -- registry mirrors and insecure registries
- `~/.config/containers/storage.conf` -- storage driver and paths
- `~/.config/containers/policy.json` -- image signature verification policy

______________________________________________________________________

## Docker CE (Alternative)

The instructions below set up Docker CE in rootless mode, which is required when using Docker with this project.

### 1. Remove Regular Docker (if installed)

```bash
sudo systemctl stop docker
sudo systemctl disable docker
sudo apt remove docker docker-engine docker.io containerd runc
```

### 2. Install Docker CE

```bash
# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 3. Install Rootless Docker

```bash
# Install rootless Docker
dockerd-rootless-setuptool.sh install

# Add to shell profile
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
echo 'export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock' >> ~/.bashrc
source ~/.bashrc
```

### 4. Start Rootless Docker

```bash
systemctl --user enable --now docker

# Verify installation
docker version
docker info
```

### 5. Configure Docker Daemon

For Docker, the daemon configuration lives at `~/.config/docker/daemon.json`. For Podman, the equivalent configuration is split across files in `~/.config/containers/` and `task trust-ca` handles registry certificate trust automatically.

```bash
# Create Docker configuration directory
mkdir -p ~/.config/docker

# Create daemon.json configuration
tee ~/.config/docker/daemon.json << 'EOF'
{
  "data-root": "/home/madmin/.config/containers/storage",
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false,
  "insecure-registries": [ "localhost:5000" ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "compress": "true"
  },
  "features": {
    "buildkit": true
  },
  "registry-mirrors": ["http://localhost:5000"]
}
EOF

# Restart Docker to apply configuration
systemctl --user restart docker
docker info  # Verify configuration
```

______________________________________________________________________

## Benefits of Rootless Containers

- Better security isolation with user-namespace separation
- No need for sudo privileges
- Reduced attack surface
- Compatible with all container features used in this project
- Podman is rootless by default; Docker requires explicit rootless setup
