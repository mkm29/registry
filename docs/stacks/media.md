# Media Stack - Plex Automation

**Purpose**: Complete media server with automated content management

```mermaid
graph TB
    subgraph "Request Management"
        Overseerr[Overseerr<br/>:5055<br/>Request Interface]
    end

    subgraph "Content Automation"
        Sonarr[Sonarr<br/>:8989<br/>TV Series Manager]
        Radarr[Radarr<br/>:7878<br/>Movie Manager]
        Bazarr[Bazarr<br/>:6767<br/>Subtitle Manager]
    end

    subgraph "Indexing & Search"
        Prowlarr[Prowlarr<br/>:9696<br/>Indexer Manager]
        Indexers[External Indexers<br/>Torrent/Usenet]
    end

    subgraph "Download Management"
        qBittorrent[qBittorrent<br/>:8080<br/>Download Client]
        Downloads[Download Storage<br/>Temporary Files]
    end

    subgraph "Media Library"
        Plex[Plex Media Server<br/>:32400<br/>Streaming Service]
        Library[Media Library<br/>Organized Content]
    end

    Overseerr --> Sonarr
    Overseerr --> Radarr

    Sonarr --> Prowlarr
    Radarr --> Prowlarr
    Prowlarr --> Indexers

    Sonarr --> qBittorrent
    Radarr --> qBittorrent
    qBittorrent --> Downloads

    Sonarr --> Library
    Radarr --> Library
    Downloads --> Library

    Bazarr --> Sonarr
    Bazarr --> Radarr
    Bazarr --> Library

    Library --> Plex

    classDef request fill:#e1f5fe,stroke:#0277bd,stroke-width:3px,color:#424242
    classDef automation fill:#e8f5e8,stroke:#2e7d32,stroke-width:3px,color:#424242
    classDef indexing fill:#fff3e0,stroke:#ef6c00,stroke-width:2px,color:#424242
    classDef download fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#424242
    classDef media fill:#f3e5f5,stroke:#7b1fa2,stroke-width:3px,color:#424242

    class Overseerr request
    class Sonarr,Radarr,Bazarr automation
    class Prowlarr,Indexers indexing
    class qBittorrent,Downloads download
    class Plex,Library media
```

## Key Features

- Complete media automation pipeline
- Request management with approval workflows
- Multiple content source integration
- Automated subtitle management

## Services

- `plex`: Media server and streaming platform
- `sonarr`: TV series management and automation
- `radarr`: Movie management and automation
- `prowlarr`: Indexer and search management
- `qbittorrent`: Download client for torrents
- `overseerr`: User request management interface
- `bazarr`: Subtitle download and management

## Configuration

See [`mediaserver/docker-compose.yaml`](../../mediaserver/docker-compose.yaml) for the complete configuration.

## Management

```bash
# From the mediaserver/ directory
docker-compose up -d        # Start media stack
docker-compose down         # Stop media stack
docker-compose logs -f      # View logs
```

## Access Points

- **Plex**: <http://localhost:32400>
- **Sonarr**: <http://localhost:8989>
- **Radarr**: <http://localhost:7878>
- **Prowlarr**: <http://localhost:9696>
- **qBittorrent**: <http://localhost:8080>
- **Overseerr**: <http://localhost:5055>
- **Bazarr**: <http://localhost:6767>
