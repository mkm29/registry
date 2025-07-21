#!/usr/bin/env bash

# This script checks for the existence of Docker networks and creates them if they do not exist.
networks=(
    traefik
    registry
    mediaserver
    monitoring
    auth
)
for network in "${networks[@]}"; do
    if ! docker network inspect "$network" &>/dev/null; then
        echo "Creating network: $network"
        docker network create "$network"
    else
        echo "Network $network already exists."
    fi
done

stacks=(
    traefik
    mediaserver
    zot
    monitoring
    auth
)

for stack in "${stacks[@]}"; do
    echo "Deploying stack: $stack"
    # if stack is mediaserver, source its .env file
    if [ "$stack" == "mediaserver" ]; then
        source "$stack/.env"
        # decrypt the secrets file
        if [ -f "$stack/.secrets.env.enc" ]; then
            source <(sops -d "$stack/.secrets.env.enc")
        else
            echo "No secrets file found for $stack."
        fi
    fi
    docker compose -f "$stack/docker-compose.yaml" up -d
done

# Check if the Zot registry is running
if docker ps | grep -q 'zot'; then
    echo "Zot registry is running."
else
    echo "Zot registry is not running. Please check the logs."
    docker compose -f registry/docker-compose.yaml logs registry
fi

# Check if the Traefik dashboard is accessible
if curl -s http://localhost:8080/dashboard/ &>/dev/null; then
    echo "Traefik dashboard is accessible."
else
    echo "Traefik dashboard is not accessible. Please check the logs: /mnt/data/logs/traefk/{access,trafik}.log"
    tail -n 20 /mnt/data/logs/traefik/access.log
    tail -n 20 /mnt/data/logs/traefik/traefik.log
fi

# Check if the monitoring stack is running
if docker ps | grep -q 'monitoring'; then
    echo "Monitoring stack is running."
else
    echo "Monitoring stack is not running. Please check the logs."
    docker compose -f monitoring/docker-compose.yaml logs
fi

# Check if the mediaserver stack is running
if docker ps | grep -q 'mediaserver'; then
    echo "Mediaserver stack is running."
    if curl -s http://grafana.smigula.io &>/dev/null; then
        echo "Grafana is accessible."
    fi
else
    echo "Mediaserver stack is not running. Please check the logs."
    docker compose -f mediaserver/docker-compose.yaml logs
fi
