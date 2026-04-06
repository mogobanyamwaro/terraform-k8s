# Topic 15: Cluster Architecture & Installation

## The 4 Components Explained Clearly

| Component                   | One-sentence job                   | What it actually does                                                                              |
| --------------------------- | ---------------------------------- | -------------------------------------------------------------------------------------------------- |
| **kube-apiserver**          | "The only gateway to the cluster"  | Authenticates, validates, and processes all requests. Nothing else talks directly to etcd.         |
| **etcd**                    | "The cluster's brain/memory"       | Stores the entire cluster state (Pod specs, secrets, configs) as key-value data.                   |
| **kube-scheduler**          | "The pod placement decision maker" | Watches for new Pods with no assigned node, picks the best worker node for each.                   |
| **kube-controller-manager** | "The self-healing engine"          | Runs controllers (Node, ReplicaSet, etc.) that constantly push current state toward desired state. |

| Component             | One-sentence job                        | What it actually does                                                                                                                                       |
| --------------------- | --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **kubelet**           | "The node's manager and pod babysitter" | Communicates with API server, receives Pod specifications, ensures containers are running and healthy. Reports node and Pod status back to control plane.   |
| **kube-proxy**        | "The network traffic rule enforcer"     | Maintains network rules (iptables, IPVS, etc.) on each node. Enables service discovery and load balancing across Pods, both inside and outside the cluster. |
| **container runtime** | "The container engine driver"           | Actually pulls images and runs containers (e.g., containerd, CRI-O, Docker). Follows instructions from kubelet via CRI (Container Runtime Interface).       |

## What You'll Learn

- **Control plane components** – kube-apiserver, etcd, kube-scheduler, kube-controller-manager
- **kubeadm** – init cluster, join nodes, upgrade
- **etcd** – backup and restore
- **Worker node** – kubelet, kube-proxy, container runtime
- **Cluster DNS** – CoreDNS, service discovery

## **Control Plane Components**

### **kube-apiserver**

- **Primary management interface** for the entire cluster
- It validates and processes requests to update etcd
- Only component that **communicates directly with etcd**

### **etcd**

- **Distributed key-value store** that holds the cluster's state and configuration
- **Single source of truth** for cluster data
- Stores all manifests, configurations, and current state
- Uses **RAFT consensus algorithm** for consistency
- Critical for cluster recovery and disaster scenarios

### **kube-scheduler**

- **Assigns newly created pods** to appropriate nodes
- Evaluates pod requirements (CPU, memory, affinity rules)
- Considers **node health, capacity, and constraints**
- Makes scheduling decisions based on:
  - Resource requirements
  - Hardware/software constraints
  - Data locality
  - Deadline requirements

### **kube-controller-manager**

- Runs **controller processes** that regulate cluster state
- Watches for changes and **reconciles desired vs actual state**
- Includes multiple controllers:
  - Node Controller (node health monitoring)
  - Replication Controller (maintains pod count)
  - Endpoint Controller (connects services to pods)
  - Service Account Controller (manages service accounts)

## **kubeadm Tools**

### **kubeadm init**

- **Bootstraps a new cluster** from scratch
- Sets up control plane components
- Generates certificates and configuration
- Creates the initial cluster state

### **kubeadm join**

- **Adds worker nodes** to an existing cluster
- Establishes secure communication with control plane
- Configures the node for cluster membership

### **kubeadm upgrade**

- **Manages cluster version upgrades**
- Updates control plane components safely
- Maintains cluster availability during upgrades
- Handles version compatibility

## **Worker Node Components**

### **kubelet**

- **Primary node agent** running on every node
- **Registers nodes** with the cluster
- **Monitors pods** assigned to its node
- Reports node and pod status to control plane
- Ensures containers are running and healthy

### **kube-proxy**

- **Manages network rules** on each node
- **Load balances** traffic to pods
- Implements **service discovery** through iptables/IPVS
- Handles **network routing** for cluster services
- Supports TCP, UDP, and SCTP protocols

### **Container Runtime**

- **Runs containers** (Docker, containerd, CRI-O, etc.)
- Pulls images from registries
- Manages container lifecycle (start, stop, restart)
- Isolates containers using kernel features

## **Cluster DNS**

### **CoreDNS**

- **Provides service discovery** within the cluster
- **Resolves service names** to IP addresses
- Allows pods to find each other by name
- Supports **custom DNS entries** and configurations
- Handles external DNS resolution

### **Service Discovery**

- Enables **pods to find services** via DNS names
- Uses format: `service-name.namespace.svc.cluster.local`
- **Automatically updates** as services/pods change
- Provides **load balancing** across multiple pod instances
- Works with **headless services** for direct pod access

Here is a diagrammatic representation of a standard Kubernetes cluster architecture, showing where **kubelet**, **kubectl**, and **kubeadm** fit into the picture.

### High-Level Kubernetes Architecture Diagram

```text
+-----------------------------------------------------------------------------------+
|                                                                                   |
|                         YOUR LOCAL MACHINE (Admin)                               |
|                                                                                   |
|    +-------------------------+                                                    |
|    |      KUBECTL            |  (The Commander)                                  |
|    |  (Your CLI Tool)        |  Sends commands via HTTPS                         |
|    +------------^------------+                                                    |
|                 |                                                                 |
|                 |  "kubectl get pods"                                            |
|                 |                                                                 |
+-----------------|-----------------------------------------------------------------+
                  |
                  v
+-----------------------------------------------------------------------------------+
|                            CONTROL PLANE NODE(S)                                 |
|                                                                                   |
|    +----------------------------------------------------+                        |
|    |               API Server (kube-apiserver)         | <------+ (kubeadm sets |
|    |  *The Front Door of the Cluster*                   |        |   this up)    |
|    |  - Authenticates kubectl requests                  |        |               |
|    |  - Validates configurations                         |        |               |
|    +------------------------^----------------------------+        |               |
|                             |                                     |               |
|          +------------------+------------------+                  |               |
|          |                  |                  |                  |               |
|          v                  v                  v                  |               |
|    +-----------+     +-------------+    +---------------+         |               |
|    | Scheduler |     | Controller  |    |   etcd        |         |               |
|    |           |     | Manager     |    | (Cluster DB)  |         |               |
|    +-----------+     +-------------+    +---------------+         |               |
|          |                  |                  ^                  |               |
|          |                  |                  |                  |               |
|          +------------------+------------------+                  |               |
|                             |                                     |               |
|                             v                                     |               |
|    +----------------------------------------------------+         |               |
|    |              API Server (again)                     |         |               |
|    |  *Forwards instructions to Nodes*                   |---------+               |
|    +----------------------------------------------------+                         |
|                                                                                   |
+-----------------------------------|-----------------------------------------------+
                                    |
                                    | "Please run this container"
                                    | (Instructions via API)
                                    |
+-----------------------------------|-----------------------------------------------+
|                                   |                                               |
|                            WORKER NODE 1                                          |
|                                                                                   |
|    +---------------------------------------------+                               |
|    |                                             |                               |
|    |   +-------------------------------------+   |                               |
|    |   |           KUBELET                   |   | <----+  (The Doer)           |
|    |   |  *The Node Agent*                    |   |      |                       |
|    |   |  - Listens to API Server            |   |      |                       |
|    |   |  - Reports back to API Server       |   |      |                       |
|    |   |  - Manages Pods                     |   |      |                       |
|    |   +------------------^------------------+   |      |                       |
|    |                      |                      |      |                       |
|    |                      | "Start/Stop"         |      |                       |
|    |                      |                      |      |                       |
|    |   +------------------v------------------+   |      |                       |
|    |   |    Container Runtime                 |   |      |                       |
|    |   |  (e.g., Docker, containerd)          |   |      |                       |
|    |   +------------------^------------------+   |      |                       |
|    |                      |                      |      |                       |
|    |                      v                      |      |                       |
|    |   +------------------+------------------+   |      |                       |
|    |   |                                      |   |      |                       |
|    |   |   POD                                 |   |      |                       |
|    |   |  +-------------------+                |   |      |                       |
|    |   |  |   Container A    |                |   |      |                       |
|    |   |  +-------------------+                |   |      |                       |
|    |   |  |   Container B    |                |   |      |                       |
|    |   |  +-------------------+                |   |      |                       |
|    |   |                                      |   |      |                       |
|    |   +--------------------------------------+   |      |                       |
|    |                                             |      |                       |
|    +---------------------------------------------+      |                       |
|                                                          |                       |
+----------------------------------------------------------+-----------------------+
```

---

### How the Tools Fit In

Based on the diagram above, here is the role of each component in the visual context:

#### 1. Kubeadm (The "Setup" Tool)

- **Location:** Run on the **Control Plane Node(s)** during initial setup.
- **Function in Diagram:** Kubeadm is the tool that **creates the entire "Control Plane" box** in the diagram. If you run `kubeadm init`, it will automatically install and configure the API Server, Scheduler, Controller Manager, and etcd. It also configures the `kubelet` on the control plane node to run in a special way. Think of it as the **wiring** that connects all those boxes together.

#### 2. Kubectl (The "Remote Control")

- **Location:** Runs on your **Local Machine** (or a jump server).
- **Function in Diagram:** It is the **arrow** pointing from "Your Local Machine" to the "API Server." It is the only tool that talks directly to the API Server. It does not touch the worker nodes or the `kubelet` directly. It sends commands via YAML/JSON.

#### 3. Kubelet (The "Node Agent")

- **Location:** Runs on **every Node** in the cluster (both Control Plane and Worker Nodes).
- **Function in Diagram:** It is the **bridge** inside the Worker Node. It sits **between** the API Server and the Container Runtime.
  - It receives the instructions (via the API Server).
  - It tells the Container Runtime what to do.
  - It constantly **watches** the Pods and reports their status back to the API Server.

  Perfect! Now that everything is working, let's document the **complete bug-free process** that worked for you. I'll provide both the cleanup steps and the complete working procedure.

  <!--###############################################  ADDING THE CONTROL PLANE ##################################################################################################################### -->

## Step 1: Clean Up Everything

```bash
# Delete the VM completely from your Mac terminal (not inside the VM)
exit  # Exit the VM if you're still inside

# From your Mac terminal:
multipass delete kubemaster
multipass purge

# Verify it's gone
multipass list
```

## Step 2: Complete Bug-Free Process (Copy & Paste Ready)

### A. Create Fresh Ubuntu VM

```bash
# From Mac terminal:
multipass launch 22.04 --name kubemaster --cpus 2 --memory 4G --disk 20G
multipass shell kubemaster
```

### B. System Preparation (Inside VM)

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab # prevents swap from turning back on after reboot

# Load kernel modules
sudo modprobe overlay  # for the container run times to sue to make container start quickly and use less disk space
sudo modprobe br_netfilter # for network filtering module

# Configure sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### C. Install containerd

```bash
# Download and install containerd
wget https://github.com/containerd/containerd/releases/download/v1.7.13/containerd-1.7.13-linux-arm64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.7.13-linux-arm64.tar.gz

# Download systemd service
sudo wget -O /usr/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

# Create containerd config
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Start containerd
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
```

### D. Install runc (CRITICAL STEP that was missing)

```bash
# Download and install runc for ARM64
wget https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.arm64
chmod +x runc.arm64
sudo mv runc.arm64 /usr/local/bin/runc

# Verify runc is installed
runc --version
```

### E. Install CNI plugins

```bash
# Download and install CNI plugins
# CNI plugins are the "network cables" for your containers. They connect pods to each other and to the outside world
# When you create a pod, it starts with NO network - it's completely isolated. CNI plugins give it:

# An IP address

# A way to talk to other pods

# A way to receive traffic from services


wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-arm64-v1.3.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins-linux-arm64-v1.3.0.tgz

# Verify CNI plugins
ls -la /opt/cni/bin/ | head
```

### F. Install kubeadm, kubelet, kubectl

```bash
# Install dependencies
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Add Kubernetes repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes components
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl # prevents package manager to "pin" this three from being automatically updated
```

### G. Initialize the Cluster

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

### H. Set Up kubeconfig

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### I. Install Flannel CNI

```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

### J. Verify Everything

```bash
# Watch nodes become ready (takes 1-2 minutes)
kubectl get nodes -w

# Check all pods
kubectl get pods -A
```

## Key Lessons Learned (Why Previous Attempts Failed)

1. **Missing runc**: The error `exec: "runc": not found` was the main issue. runc is essential for containerd to create containers.

2. **Missing CNI plugins**: The Flannel init container was stuck because CNI binaries weren't installed on the host.

3. **Correct order matters**:
   - First install containerd
   - THEN install runc
   - THEN install CNI plugins
   - THEN install kubeadm
   - THEN initialize

4. **ARM64-specific binaries**: All downloads must be for `arm64`, not `amd64`.

## Quick One-Liner Test After Setup

```bash
kubectl run test --image=nginx --restart=Never && kubectl wait --for=condition=ready pod/test --timeout=60s && kubectl delete pod/test
```

This complete process is now **bug-free** and tested to work on your M1 Mac with Multipass!

<!--###############################################  ADDING THE WORKER NODE ##################################################################################################################### -->

Yes, you can definitely add another node to your Kubernetes cluster! This is a great way to make your setup more realistic for CKA practice. Let me walk you through the process.

## What You'll Need

Since you're using Multipass on your M1 Mac, you'll need to **create a second Ubuntu VM** to serve as your worker node. The worker node needs:

- The same Kubernetes components installed (kubeadm, kubelet, kubectl)
- The same container runtime (containerd) with runc and CNI plugins
- Network connectivity to your master node

## Step-by-Step: Adding a Worker Node

### 1. Create a Second VM (from your Mac terminal)

```bash
# Create a new VM for the worker node
multipass launch 22.04 --name worker1 --cpus 2 --memory 4G --disk 20G

# Shell into it
multipass shell worker1
```

### 2. Install All Prerequisites on the Worker Node (Inside worker1 VM)

Run **exactly the same installation steps** you did on the master node :

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Install containerd
wget https://github.com/containerd/containerd/releases/download/v1.7.13/containerd-1.7.13-linux-arm64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.7.13-linux-arm64.tar.gz
sudo wget -O /usr/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# Install runc (CRITICAL!)
wget https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.arm64
chmod +x runc.arm64
sudo mv runc.arm64 /usr/local/bin/runc

# Install CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-arm64-v1.3.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins-linux-arm64-v1.3.0.tgz

# Install kubeadm, kubelet, kubectl
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### 3. Get the Join Command from Your Master Node

On your **master node** (kubemaster), run :

```bash
# Generate a new join command with token
sudo kubeadm token create --print-join-command
```

This will output something like:

```
kubeadm join 192.168.64.5:6443 --token abc123.def456 --discovery-token-ca-cert-hash sha256:789...
```

**Copy this entire command** - you'll run it on the worker node.

> **Note**: Tokens expire after 24 hours by default . If your master node was set up more than 24 hours ago, you must generate a new token as shown above.

### 4. Join the Worker Node to the Cluster

Back in your **worker1 VM**, run the join command with `sudo` :

```bash
# Paste the command from your master node with sudo
sudo kubeadm join 192.168.64.5:6443 --token abc123.def456 --discovery-token-ca-cert-hash sha256:789...
```

You should see output similar to:

```
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[check-etcd] Checking that the etcd cluster is healthy

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

### 5. Verify from Master Node

On your **master node**, verify the node joined successfully :

```bash
kubectl get nodes
```

You should see both nodes:

```
NAME         STATUS   ROLES           AGE   VERSION
kubemaster   Ready    control-plane   2d    v1.28.15
worker1      Ready    <none>          1m    v1.28.15
```

The new worker node will initially show as `NotReady` for a minute or two while it starts necessary pods (kube-proxy, etc.). This is normal.

## Important: Taints and Scheduling

Now that you have a dedicated worker node, you have options:

### Option A: Keep Master Node Tainted (Production Style)

Your master node still has the control plane taint. With a worker node available, you should **keep this taint** to reserve the master for system components :

```bash
# Verify the taint is still there
kubectl describe node kubemaster | grep Taints
# Should show: node-role.kubernetes.io/control-plane:NoSchedule
```

## Test Your Multi-Node Cluster

Deploy something and see which node it lands on:

```bash
# Create a deployment
kubectl create deployment multi-test --image=nginx --replicas=3

# Check which nodes the pods are running on
kubectl get pods -o wide
```

You should see pods distributed across your nodes.

## Troubleshooting Common Issues

| Problem                                       | Likely Solution                                                                                |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `kubeadm join` fails with connection refused  | Check firewall/network between VMs. Both VMs should be able to ping each other.                |
| Node shows `NotReady` for more than 5 minutes | Check kubelet logs: `sudo journalctl -u kubelet -f` on worker node                             |
| Token expired error                           | Generate a new token on master: `sudo kubeadm token create --print-join-command`               |
| Pods stuck on master node after adding worker | The scheduler will automatically distribute new pods. Existing pods won't move unless deleted. |

## What You've Learned

By adding a worker node, you've:

- Created a more realistic multi-node cluster
- Learned how node registration works with bootstrap tokens
- Understood the difference between control plane and worker nodes
- Practiced a key skill for the CKA exam

Your cluster now better resembles what you'll encounter in the exam environment!

<!--############################################### SET UP KUBECTL FROM MULTIPASS TO MAC on every new terminal  ##################################################################################################################### -->

# From Mac terminal - copy kubeconfig from VM

multipass transfer kubemaster:/home/ubuntu/.kube/config ~/.kube/config-multipass

# Set the config

export KUBECONFIG=~/.kube/config-multipass

# Test it works

kubectl get pods

# Now run port-forward from your Mac

kubectl port-forward pod/multi-test-74fbf5454f-6lbhp 8080:80
