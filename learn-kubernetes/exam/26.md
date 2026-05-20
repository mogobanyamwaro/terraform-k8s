Install and configure cri-dockerd as a container runtime alternative to containerd. Essential for clusters using Docker as the container runtime.

## Tasks

1. SSH into a worker node
2. Install cri-dockerd using the `.deb` package:
   - Download from GitHub releases
   - Install the package
3. Configure system for cri-dockerd:
   - Enable IP forwarding using `sysctl`
   - Add required kernel modules (`overlay`, `br_netfilter`)
4. Enable and start cri-dockerd service:
   - `systemctl enable cri-dockerd`
   - `systemctl start cri-dockerd`
5. Verify cri-dockerd socket is available
6. Configure kubelet to use cri-dockerd
7. Restart kubelet and verify node is Ready

## Key Learning

- cri-dockerd is a CRI adapter for Docker
- Kubernetes v1.35 dropped built-in dockershim — must use cri-dockerd
- IP forwarding and kernel modules are prerequisites
- Socket location: `/run/cri-dockerd.sock`
- Exam tests installation procedure and troubleshooting

---

Here is the best way to install and configure cri-dockerd on a worker node for the CKA exam. This converts Docker into a Kubernetes-compatible container runtime interface (CRI) .

### 1. SSH into the Worker Node

First, connect to the target worker node from the control plane:

```bash
ssh <worker-node-name>
```

### 2. Install cri-dockerd using the .deb Package

Download the latest `.deb` package (v0.3.21) from the official GitHub releases page :

```bash
# Download the package (adjust URL for arm64 if needed)
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.21/cri-dockerd_0.3.21.3-0.ubuntu-jammy_amd64.deb
```

Install the package using `dpkg`:

```bash
sudo dpkg -i cri-dockerd_0.3.21.3-0.ubuntu-jammy_amd64.deb
```

> **Note**: If you are using a different operating system, browse the [releases page](https://github.com/Mirantis/cri-dockerd/releases) to find the matching package for your distribution.

### 3. Configure System for cri-dockerd

Configure the necessary kernel modules and networking parameters .

**Load Required Kernel Modules:**

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

**Enable IP Forwarding and Bridge Filtering:**

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### 4. Enable and Start cri-dockerd Service

The `.deb` package installs systemd service files automatically. Enable and start the service to ensure it runs on boot :

```bash
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
sudo systemctl start cri-docker.service
```

### 5. Verify cri-dockerd Socket is Available

Check that the service is active and the socket file exists:

```bash
sudo systemctl status cri-docker.service
ls -l /run/cri-dockerd.sock
```

You can also use `crictl` to verify connectivity :

```bash
sudo crictl --runtime-endpoint unix:///run/cri-dockerd.sock info
```

### 6. Configure kubelet to Use cri-dockerd

Tell the kubelet to use the cri-dockerd socket instead of containerd . The most common method is to create a drop-in systemd configuration file:

```bash
sudo mkdir -p /etc/systemd/system/kubelet.service.d
```

```bash
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service.d/0-cri-dockerd.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=unix:///run/cri-dockerd.sock"
EOF
```

### 7. Restart kubelet and Verify Node is Ready

Reload systemd, restart kubelet, and then switch back to the control plane to check the node status:

```bash
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

Return to the control plane node (`exit` from the worker SSH session) and verify the node becomes `Ready`:

```bash
kubectl get nodes
```

---

### Exam Checklist

- [x] SSH into worker node
- [x] Download and install cri-dockerd `.deb` package
- [x] Load `overlay` and `br_netfilter` kernel modules
- [x] Apply sysctl parameters for IP forwarding
- [x] Enable and start cri-docker service and socket
- [x] Verify `/run/cri-dockerd.sock` exists
- [x] Configure kubelet with `--container-runtime-endpoint`
- [x] Restart kubelet and validate node `Ready` status

### Pro Tip

If you are joining a new node to the cluster, remember to specify the cri-dockerd socket during `kubeadm join`:

```bash
sudo kubeadm join <control-plane-host>:<port> --token <token> --cri-socket unix:///run/cri-dockerd.sock
```

If the node already exists, you may need to drain it (`kubectl drain <node> --ignore-daemonsets`) before restarting kubelet to avoid pod disruption.
