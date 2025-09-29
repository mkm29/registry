# VM Setup Guide

This guide provides comprehensive instructions for setting up a virtual machine environment on Proxmox to host the container infrastructure.

## VM Specifications

- **OS**: Ubuntu 24.04 Server
- **CPU**: 4 cores
- **RAM**: 16 GB
- **Disk**: 32 GB (system) + 10 TB (data from ZFS pool)
- **Network**: Bridged (default bridge)
  - Get a DHCP address initially
  - Set static IP later
- **Hostname**: `mediaserver`
- **Storage**: Local LVM
- **User**: `madmin`
  - Password: `SuperSecret1`

## Initial VM Setup

### 1. Update and Upgrade System

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Required Packages

```bash
sudo apt install -y build-essential openssh-server curl git vim htop net-tools dnsutils iputils-ping ca-certificates unzip gpg
```

### 3. Configure Sudo Access

```bash
sudo usermod -aG sudo `whoami`
echo "madmin ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/madmin
mkdir -p ~/.ssh
chmod 700 -R ~/.ssh
```

### 4. Generate SSH Key Pair

```bash
ssh-keygen -t ed25519 -C "madmin@mediaserver" -f ~/.ssh/id_mediaserver
ssh-copy-id -i ~/.ssh/id_mediaserver.pub madmin@<VM_IP_ADDRESS>
```

### 5. Assign Static IP Address

SSH into the VM, and first remove the cloud-init generated file:

```bash
sudo rm /etc/netplan/50-cloud-init.yaml
```

Then create the static network configuration:

```bash
sudo tee /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: no
      addresses:
        - <STATIC_IP_ADDRESS>/24
      routes:
        - to: default
          via: <GATEWAY_IP_ADDRESS>
      nameservers:
        addresses:
          - 1.1.1.1
          - 1.0.0.1
          - 192.168.1.1 # my proxmox DNS server
EOF
sudo chmod 600 /etc/netplan/01-netcfg.yaml
```

**Example Configuration:**

- `<STATIC_IP_ADDRESS>` to `192.168.1.66`
- `<GATEWAY_IP_ADDRESS>` to `192.168.1.1`

Apply the network configuration:

```bash
sudo netplan try
sudo netplan apply
```

Create an SSH config entry for easy access:

```bash
echo -e "Host mediaserver\\n\\tHostName 192.168.1.66\\n\\tUser madmin\\n\\tIdentityFile ~/.ssh/id_mediaserver\\n\\tStrictHostKeyChecking no\\n\\tIdentitiesOnly yes" | tee -a ~/.ssh/config
```

### 6. Secure SSH Access

Edit the SSH configuration file:

```bash
sudo vim /etc/ssh/sshd_config
```

Change or add the following lines:

```bash
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
AllowUsers madmin
```

Restart the SSH service:

```bash
sudo systemctl restart sshd
```

## Docker Installation

### 7. Install Docker

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

Add your user to the Docker group:

```bash
sudo usermod -aG docker madmin
```

### 8. Configure Rootless Docker

Install required packages for rootless Docker:

```bash
sudo apt-get install uidmap -y
```

Enable privileged port access:

```bash
sudo setcap cap_net_bind_service=ep $(which rootlesskit)
```

Configure systemd for cgroup delegation:

```bash
sudo mkdir -p /etc/systemd/system/user@.service.d
sudo cat <<EOF > /etc/systemd/system/user@.service.d/delegate.conf
[Service]
Delegate=cpu cpuset io memory pids
EOF
sudo systemctl daemon-reload
```

Disable system Docker service:

```bash
sudo systemctl disable --now docker.service docker.socket
sudo rm /var/run/docker.sock
```

Install rootless Docker service:

```bash
sudo sh -eux <<EOF
# Load nf_tables module
modprobe nf_tables
EOF
dockerd-rootless-setuptool.sh install
```

Enable Docker service on system startup:

```bash
sudo loginctl enable-linger madmin
```

> **Note**: For full rootless Docker functionality, particularly resource limiting features, you may need to enable cgroup v2 by editing `/etc/default/grub` to include `systemd.unified_cgroup_hierarchy=1` in the `GRUB_CMDLINE_LINUX` variable, then run `sudo update-grub` and reboot.

### 9. Configure Docker Daemon

Create the Docker daemon configuration:

```bash
mkdir -p ~/.config/docker
```

```bash
cat <<EOF > ~/.config/docker/daemon.json
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-level": "info",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "insecure-registries": [
    "localhost:5000"
  ]
}
EOF
systemctl --user restart docker
```

> **Note**: The `data-root` defaults to `~/.local/share/docker` for rootless Docker. This can be changed by setting the `data-root` option in the `daemon.json` file.

## Development Tools

### 10. Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# Add to ~/.bashrc
echo 'source $HOME/.cargo/env' >> ~/.bashrc
source ~/.bashrc
```

#### 10.a Install Rust-based Tools

```bash
sudo apt-get install -y ripgrep fd-find
```

#### 10.b Install Node.js

```bash
sudo apt install -y nodejs npm
```

#### 10.c Install Nerd Fonts

```bash
mkdir -p ~/.local/share/fonts
cat <<EOF > ~/fonts.sh
#!/bin/bash

declare -a fonts=(
    BitstreamVeraSansMono
    CodeNewRoman
    DroidSansMono
    FiraCode
    FiraMono
    Go-Mono
    Hack
    Hermit
    JetBrainsMono
    Meslo
    Noto
    Overpass
    ProggyClean
    RobotoMono
    SourceCodePro
    SpaceMono
    Ubuntu
    UbuntuMono
)

version='2.1.0'
fonts_dir="${HOME}/.local/share/fonts"

if [[ ! -d "$fonts_dir" ]]; then
    mkdir -p "$fonts_dir"
fi

for font in "${fonts[@]}"; do
    zip_file="${font}.zip"
    download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${zip_file}"
    echo "Downloading $download_url"
    wget "$download_url"
    unzip "$zip_file" -d "$fonts_dir"
    rm "$zip_file"
done

find "$fonts_dir" -name '*Windows Compatible*' -delete

fc-cache -fv
EOF

chmod +x ~/fonts.sh
~/fonts.sh
```

#### 10.d Install Neovim

```bash
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar xzf nvim-linux-x86_64.tar.gz -C /opt
sudo ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz
git clone https://github.com/nvim-lua/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

#### 10.e Install eza

```bash
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza
```

## Storage Configuration

### 11. Add Data Disk

Find the additional disk:

```bash
lsblk
```

Assuming the disk is `/dev/sdb`, partition it:

```bash
sudo fdisk /dev/sdb
```

In fdisk:

- Type `n` for new partition
- Press Enter to accept default (primary)
- Press Enter to accept default partition number (1)
- Press Enter to accept default first sector
- Press Enter to accept default last sector (uses entire disk)
- Type `w` to write changes and exit

Format the disk:

```bash
sudo mkfs.ext4 /dev/sdb1
```

Create mount points and mount the disk:

```bash
sudo mkdir -p /mnt/data/{filestore,faststore,logstore,cache}
sudo mount /dev/sdb1 /mnt/data
```

Make the mount permanent:

```bash
# Get the UUID
sudo blkid /dev/sdb1

# Edit fstab
sudo vim /etc/fstab

# Add this line (replace UUID with actual value):
UUID=e45ed3dc-5544-49f6-9447-919b470a8b81 /mnt/data ext4 defaults 0 2
```

## Additional Tools

### 12. Install McFly (Enhanced History)

```bash
curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sudo sh -s -- --git cantino/mcfly
```

### 13. Install zinit (Zsh Plugin Manager)

```bash
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
```

## System Optimization

### Proxmox Memory Optimization

For better memory management in the VM environment, adjust kernel parameters:

```bash
echo "vm.vfs_cache_pressure=200" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_ratio=5" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_background_ratio=3" | sudo tee -a /etc/sysctl.conf
```

Optional: Add a cron job to periodically clear caches:

```bash
# Add to crontab (uncomment if needed):
# */30 * * * * sync; echo 3 > /proc/sys/vm/drop_caches
```

## Next Steps

After completing this VM setup, you can proceed with deploying the container infrastructure:

1. Clone the infrastructure repository
2. Configure SOPS and AGE for secret management
3. Set up encrypted secrets in the `secrets/` directory
4. Run the orchestrated infrastructure deployment with `./run.sh`

See the main [Quick Start Guide](quick-start.md) for infrastructure deployment instructions.

## Notes

- The VM is configured for development and testing environments
- For production use, consider additional security hardening
- Memory settings may need adjustment based on workload requirements
- The 10 TB data disk provides ample storage for media files and container volumes
