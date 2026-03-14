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

### Trust the Local CA for TLS

Zot now runs with TLS using cfssl-generated certificates. To pull images without certificate errors, install the local CA certificate:

```bash
# Install the CA cert into the local trust store
task trust-ca

# This copies ca.pem to ~/.config/containers/certs.d/ so that
# both Podman and Docker trust the self-signed registry certificate.
```

After running `task trust-ca`, you can pull from `localhost:5000` over TLS without any insecure registry configuration.

## Test Registry Access

1. **Access the Zot Web UI**:

   Navigate to <https://127.0.0.1:5000/home> to access the Zot web interface where you can:

   - Search for images
   - View repository details
   - Check image tags and manifests
   - Monitor sync status

1. **Test pulling images**:

   ```bash
   # Pull nginx from Docker Hub through Zot
   docker pull localhost:5000/docker/nginx:latest

   # Pull from other registries
   docker pull localhost:5000/ghcr/project-zot/zot-linux-amd64:v2.1.5
   docker pull localhost:5000/gcr/cadvisor/cadvisor:v0.52.0

   # Check cached repositories
   curl -sk https://127.0.0.1:5000/v2/_catalog
   # Should show: {"repositories":["docker/nginx","ghcr/project-zot/zot-linux-amd64","gcr/cadvisor/cadvisor"]}
   ```

1. **Push your own images**:

   ```bash
   # Tag and push to Zot
   docker tag myapp:latest localhost:5000/myapp:latest
   docker push localhost:5000/myapp:latest
   ```

1. **Access the Registry API**:

   Zot implements the [OCI Distribution Specification](https://github.com/opencontainers/distribution-spec). Common endpoints:

   ```bash
   # Check registry availability
   curl -sk https://127.0.0.1:5000/v2/

   # List all repositories
   curl -sk https://127.0.0.1:5000/v2/_catalog

   # List tags for a repository
   curl -sk https://127.0.0.1:5000/v2/docker/nginx/tags/list

   # Search for images (Zot-specific)
   curl -sk -X POST https://127.0.0.1:5000/v2/_zot/ext/search \
        -H "Content-Type: application/json" \
        -d '{"query": "nginx"}'

   # Get image manifest
   curl -sk https://127.0.0.1:5000/v2/docker/nginx/manifests/latest
   ```
