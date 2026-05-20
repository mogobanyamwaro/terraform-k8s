Install and configure cri-dockerd as a container runtime for a Kubernetes node. This is common when upgrading clusters that need Docker support or when preparing a mixed-runtime cluster.

## Context

Kubernetes deprecated dockershim in v1.20 and removed it in v1.24. To continue using Docker as a container runtime, you must install CRI-dockerd explicitly. The exam may ask you to prepare a node to join a cluster using Docker via CRI-dockerd, or troubleshoot why a node can't join because the runtime isn't configured.

## Tasks

1. Load the required kernel modules: `overlay` and `br_netfilter`
2. Configure kernel networking parameters via sysctl
3. Install Docker (required dependency for CRI-dockerd)
4. Download and install CRI-dockerd binary from GitHub releases
5. Create systemd service files for cri-docker.service and cri-docker.socket
6. Enable and start the cri-docker services
7. Verify the CRI-dockerd socket is listening at `/run/cri-dockerd.sock`

---

Here is the best way to install and configure `cri-dockerd` for a Kubernetes node on the CKA exam, based on the official instructions. This configures Docker as a runtime via the CRI.

### 1. Load Required Kernel Modules

First, load the `overlay` and `br_netfilter` modules and make the change permanent.

```bash
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

### 2. Configure Kernel Networking Parameters

Set the required `sysctl` parameters for Kubernetes networking.

```bash
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system
```

### 3. Install Docker (CRI-Dockerd Dependency)

Install Docker Engine as the underlying runtime.

```bash
# Update package list
sudo apt-get update

# Install prerequisites
sudo apt-get install -y ca-certificates curl

# Install Docker
curl -fsSL https://get.docker.com | sudo sh
```

### 4. Download and Install CRI-Dockerd

Download the latest binary (v0.3.21 as of latest release) from GitHub.

```bash
# Download the binary for amd64
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.21/cri-dockerd-0.3.21.amd64.tgz

# Extract the archive
tar -xvf cri-dockerd-0.3.21.amd64.tgz

# Move binary to /usr/local/bin/
sudo mv cri-dockerd/cri-dockerd /usr/local/bin/
```

### 5. Create Systemd Service Files

Download the official service files from the Mirantis repository.

```bash
# Download service and socket files
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket

# Move them to systemd directory
sudo mv cri-docker.service cri-docker.socket /etc/systemd/system/

# Edit the service file to point to /usr/local/bin/
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
```

### 6. Enable and Start Services

Reload systemd, enable, and start the cri-dockerd service.

```bash
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
sudo systemctl start cri-docker.service
```

### 7. Verify the CRI-Dockerd Socket

Check that the service is active and listening on the expected socket path.

```bash
# Check service status
sudo systemctl status cri-docker.service

# Verify socket file exists
ls -l /run/cri-dockerd.sock

# Test endpoint (optional)
crictl --runtime-endpoint unix:///run/cri-dockerd.sock info
```

---

### Exam Checklist

- [x] Kernel modules (`overlay`, `br_netfilter`) are loaded
- [x] Sysctl parameters for bridging are configured
- [x] Docker Engine is installed
- [x] `cri-dockerd` binary is downloaded and placed in `/usr/local/bin/`
- [x] Systemd unit files (`service` and `socket`) are configured
- [x] Service is enabled and started
- [x] Socket file exists at `/run/cri-dockerd.sock`

### Pro Tip

If you are reconfiguring an existing node, remember to **drain** the node (`kubectl drain <node> --ignore-daemonsets`) before restarting the kubelet and **uncordon** it afterwards to prevent pod disruption.
