```bash
# Get your IP
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "My IP is: $IP_ADDR"

# Initialize cluster

sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=$IP_ADDR \
  --cri-socket=unix:///var/run/containerd/containerd.sock
```

This `kubeadm init` command is the **master switch** that actually creates your Kubernetes cluster. Let me break down exactly what each part does.

## The Command Breakdown

### `sudo kubeadm init`

- **What it does**: Bootstraps (creates) the entire control plane
- **Without it**: You just have a bunch of installed packages, no cluster exists
- **Analogy**: This is like pressing the "START" button after installing all parts

### The Three Critical Flags:

#### 1. `--pod-network-cidr=10.244.0.0/16`

```
Purpose: Tells Kubernetes what IP range to use for pods
Value:   10.244.0.0/16 means 65,536 possible pod IPs
Why:     Must match what your CNI (Flannel) expects
Match:   Flannel default is 10.244.0.0/16
```

- **If you change this**: Flannel won't work, pods can't communicate
- **If you omit it**: Some CNI plugins fail, network doesn't initialize

#### 2. `--apiserver-advertise-address=$IP_ADDR`

```
Purpose: Tells pods/nodes what IP to reach the API server
Value:   Your machine's actual IP (e.g., 192.168.64.5)
Why:     Other nodes need to know where the master is
Without: Other nodes can't join, kubectl might not work
```

#### 3. `--cri-socket=unix:///var/run/containerd/containerd.sock`

```
Purpose: Tells kubeadm "THIS is your container runtime"
Path:    Points to containerd's communication file
Why:     Kubernetes needs to know how to talk to containerd
Without: "CRI socket not found" error - cluster fails
```

## What Happens When You Run This Command:

```
Step 1:  [preflight]          → Checks if everything is ready
Step 2:  [certs]              → Creates all certificates
Step 3:  [kubeconfig]         → Creates admin/config files
Step 4:  [kubelet-start]      → Starts kubelet
Step 5:  [control-plane]      → Creates API server, scheduler, controller-manager
Step 6:  [etcd]               → Starts the database
Step 7:  [wait-control-plane] → Waits for everything to be healthy
Step 8:  [addons]             → Installs CoreDNS, kube-proxy
```

## Why All Three Are Necessary:

| Flag                     | What happens if missing                                                 |
| ------------------------ | ----------------------------------------------------------------------- |
| No `--pod-network-cidr`  | Flannel won't know what IPs to assign → pods stuck in ContainerCreating |
| No `--apiserver-address` | API server listens on wrong IP → `kubectl` can't connect                |
| No `--cri-socket`        | kubeadm guesses wrong runtime → "failed to connect to CRI" error        |

## The Output You'll See:

When successful, the last lines show:

```
Your Kubernetes control-plane has been initialized successfully!

To start using your cluster, you need to run:
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Then you can join any number of worker nodes by running:
kubeadm join 192.168.64.5:6443 --token ... --discovery-token-ca-cert-hash ...
```

## Simple Summary:

This single command:

1. **Creates** your entire control plane
2. **Tells** Kubernetes your network plan (10.244.0.0/16)
3. **Announces** your IP so others can find you (192.168.x.x)
4. **Connects** to containerd so it can run containers

**Without this command = No cluster exists.** Everything before was just preparation.
