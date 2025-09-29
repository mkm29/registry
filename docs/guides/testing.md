# Testing the Registry

## Using Zot Registry

Zot uses prefix-based routing for different registries. Unlike a traditional Docker registry mirror, you need to specify the registry prefix when pulling images:

### Pull Images from Different Registries

```bash
# Docker Hub images
docker pull localhost:5000/docker/nginx:latest
docker pull localhost:5000/docker/alpine:latest
docker pull localhost:5000/docker/redis:7

# GitHub Container Registry
docker pull localhost:5000/ghcr/project-zot/zot-linux-amd64:v2.1.5

# Google Container Registry
docker pull localhost:5000/gcr/cadvisor/cadvisor:v0.52.0
docker pull localhost:5000/gcr/kaniko-project/executor:latest

# Quay.io
docker pull localhost:5000/quay/coreos/etcd:latest

# Kubernetes Registry
docker pull localhost:5000/k8s/pause:3.9
docker pull localhost:5000/k8s/coredns/coredns:v1.11.1
```

### Configure Docker for Insecure Registry

Since Zot runs on HTTP (not HTTPS) by default, configure Docker to allow insecure access:

#### Rootless Docker

```bash
# Edit daemon configuration
nano ~/.config/docker/daemon.json

# Add localhost:5000 to insecure registries:
{
  "insecure-registries": ["localhost:5000"]
}

# Restart Docker
systemctl --user restart docker
```

#### Regular Docker

```bash
# Edit daemon configuration
sudo nano /etc/docker/daemon.json

# Add configuration:
{
  "insecure-registries": ["localhost:5000"]
}

# Restart Docker
sudo systemctl restart docker
```

## Test Registry Access

1. **Access the Zot Web UI**:

   Navigate to <http://localhost:5000/home> to access the Zot web interface where you can:

   - Search for images
   - View repository details
   - Check image tags and manifests
   - Monitor sync status

2. **Test pulling images**:

   ```bash
   # Pull nginx from Docker Hub through Zot
   docker pull localhost:5000/docker/nginx:latest

   # Pull from other registries
   docker pull localhost:5000/ghcr/project-zot/zot-linux-amd64:v2.1.5
   docker pull localhost:5000/gcr/cadvisor/cadvisor:v0.52.0

   # Check cached repositories
   curl http://localhost:5000/v2/_catalog
   # Should show: {"repositories":["docker/nginx","ghcr/project-zot/zot-linux-amd64","gcr/cadvisor/cadvisor"]}
   ```

3. **Push your own images**:

   ```bash
   # Tag and push to Zot
   docker tag myapp:latest localhost:5000/myapp:latest
   docker push localhost:5000/myapp:latest
   ```

4. **Access the Registry API**:

   Zot implements the [OCI Distribution Specification](https://github.com/opencontainers/distribution-spec). Common endpoints:

   ```bash
   # Check registry availability
   curl http://localhost:5000/v2/

   # List all repositories
   curl http://localhost:5000/v2/_catalog

   # List tags for a repository
   curl http://localhost:5000/v2/docker/nginx/tags/list

   # Search for images (Zot-specific)
   curl -X POST http://localhost:5000/v2/_zot/ext/search \
        -H "Content-Type: application/json" \
        -d '{"query": "nginx"}'

   # Get image manifest
   curl http://localhost:5000/v2/docker/nginx/manifests/latest
   ```
