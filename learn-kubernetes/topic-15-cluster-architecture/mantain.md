Excellent question! You've successfully built a cluster, but now you need to learn how to **manage** it. Here's the comprehensive guide for the operational tasks CKA-certified administrators do daily:

# Kubernetes Cluster Management & Operations

## 1. Cluster Upgrades (kubeadm)

### Understanding Version Skew

- **kubeadm** can only upgrade one minor version at a time (e.g., 1.27 → 1.28, not 1.27 → 1.29)
- Control plane components can be one version ahead of worker nodes
- **kubelet** can be up to two versions behind the API server

### Complete Upgrade Process (1.28 → 1.29)

#### Step 1: Upgrade kubeadm on Master Node

```bash
# Drain the master node (move workloads off)
kubectl drain kubemaster --ignore-daemonsets --delete-emptydir-data

# Update the Kubernetes repository for new version
sudo sed -i 's/1.28/1.29/g' /etc/apt/sources.list.d/kubernetes.list
# OR manually edit: sudo nano /etc/apt/sources.list.d/kubernetes.list

# Check available versions
kubeadm version
sudo apt update
sudo apt-cache madison kubeadm

# Install new kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.29.x-1.1
sudo apt-mark hold kubeadm

# Verify upgrade plan
sudo kubeadm upgrade plan

# Apply the upgrade
sudo kubeadm upgrade apply v1.29.x
```

#### Step 2: Upgrade kubelet and kubectl on Master

```bash
# Upgrade kubelet and kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.29.x-1.1 kubectl=1.29.x-1.1
sudo apt-mark hold kubelet kubectl

# Restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Uncordon the master node
kubectl uncordon kubemaster
```

#### Step 3: Upgrade Worker Nodes (Repeat for each)

```bash
# From master, drain the worker
kubectl drain worker1 --ignore-daemonsets --force

# On worker node, upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.29.x-1.1
sudo apt-mark hold kubeadm

# Upgrade node configuration
sudo kubeadm upgrade node

# Upgrade kubelet and kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.29.x-1.1 kubectl=1.29.x-1.1
sudo apt-mark hold kubelet kubectl
sudo systemctl restart kubelet

# Back on master, uncordon the worker
kubectl uncordon worker1
```

### Rollback/Downgrade (Emergency Only!)

```bash
# If upgrade fails catastrophically
sudo kubeadm upgrade apply v1.28.x --force
# Then reinstall older kubelet/kubectl
```

## 2. etcd Backup and Restore (CRITICAL FOR CKA)

### Understanding etcd

- Stores ALL cluster data (secrets, configmaps, deployments, etcd itself)
- **Single point of failure** if not backed up
- Located at `/var/lib/etcd` on control plane

### Set up etcdctl

```bash
# Download etcdctl (matches your cluster version)
ETCD_VERSION=$(kubectl exec -n kube-system etcd-kubemaster -- etcdctl version | head -1 | cut -d' ' -f3)
wget https://github.com/etcd-io/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-arm64.tar.gz
tar xzf etcd-v${ETCD_VERSION}-linux-arm64.tar.gz
sudo cp etcd-v${ETCD_VERSION}-linux-arm64/etcdctl /usr/local/bin/
```

### Method 1: Backup using etcdctl (CKA Way)

```bash
# Check etcd endpoint
kubectl -n kube-system describe pod etcd-kubemaster | grep -- --listen-client-urls

# Set up etcdctl connection parameters
export ETCDCTL_API=3
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379

# Create snapshot (run on control plane with sudo)
sudo etcdctl snapshot save /opt/cluster-backup.db

# Verify snapshot
sudo etcdctl --write-out=table snapshot status /opt/cluster-backup.db
```

### Method 2: Backup via kubeadm (Simpler)

```bash
# Create backup of all certificates and etcd
sudo kubeadm reset phase etcd   # NO! Don't run this - just for illustration
# Instead, manually backup:
sudo cp -r /etc/kubernetes/pki /backup/pki
sudo cp -r /var/lib/etcd /backup/etcd
```

### Restore etcd from Backup

```bash
# STOP ALL CONTROL PLANE COMPONENTS (CRITICAL!)
sudo systemctl stop kubelet
sudo mv /etc/kubernetes/manifests /etc/kubernetes/manifests.bak
sudo mv /var/lib/etcd /var/lib/etcd.bak

# Restore from snapshot
sudo etcdctl snapshot restore /opt/cluster-backup.db \
  --data-dir /var/lib/etcd \
  --name kubemaster \
  --initial-cluster kubemaster=https://127.0.0.1:2380 \
  --initial-cluster-token etcd-cluster-1

# Set permissions
sudo chown -R etcd:etcd /var/lib/etcd

# Restore manifests and restart
sudo mv /etc/kubernetes/manifests.bak /etc/kubernetes/manifests
sudo systemctl start kubelet

# Verify cluster state
kubectl get nodes
kubectl get all --all-namespaces
```

## 3. Certificate Management

### Check Certificate Expiry

```bash
# Using kubeadm
kubeadm certs check-expiration

# Manual check for specific certs
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep Not
```

### Renew Certificates

```bash
# Renew all certificates
sudo kubeadm certs renew all

# Renew specific certificate
sudo kubeadm certs renew apiserver

# After renewal, restart control plane components
sudo systemctl restart kubelet
# Static pods will auto-restart, but you can force:
sudo kill -SIGHUP $(pidof kube-apiserver)
```

### Manual Certificate Generation

```bash
# Generate new key and CSR
openssl genrsa -out admin-new.key 2048
openssl req -new -key admin-new.key -out admin-new.csr -subj "/CN=admin/O=system:masters"

# Sign with CA (CA cert is on control plane)
sudo openssl x509 -req -in admin-new.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out admin-new.crt -days 365
```

## 4. Node Maintenance Operations

### Drain a Node (Safely remove workloads)

```bash
# Gracefully evict pods
kubectl drain worker1 --ignore-daemonsets --delete-emptydir-data --force

# If node is offline/unreachable
kubectl drain worker1 --ignore-daemonsets --delete-emptydir-data --force --grace-period=0

# Make node schedulable again after maintenance
kubectl uncordon worker1
```

### Cordon (Prevent new scheduling without evicting existing)

```bash
# Mark node unschedulable but keep running pods
kubectl cordon worker1

# Check node status
kubectl get nodes -o wide
```

### Node Labels and Taints

```bash
# Add labels
kubectl label node worker1 disktype=ssd zone=us-east

# Add taint (NoSchedule, PreferNoSchedule, NoExecute)
kubectl taint nodes worker1 gpu=true:NoSchedule

# Remove taint (add - at end)
kubectl taint nodes worker1 gpu=true:NoSchedule-

# View all labels and taints
kubectl describe node worker1 | grep -A5 Labels
kubectl describe node worker1 | grep -A1 Taints
```

## 5. Disaster Recovery Scenarios

### Scenario 1: Master Node Failure

```bash
# On surviving master or new VM
# Restore etcd from backup
sudo etcdctl snapshot restore /backup/snapshot.db --data-dir /var/lib/etcd

# Reinitialize control plane (CAREFUL!)
sudo kubeadm init --ignore-preflight-errors=DirAvailable--var-lib-etcd --skip-certificate-key-print

# Restore certificates from backup
sudo cp -r /backup/pki/* /etc/kubernetes/pki/
```

### Scenario 2: API Server Down

```bash
# Check API server logs
sudo crictl ps | grep kube-apiserver
sudo crictl logs $(sudo crictl ps | grep kube-apiserver | awk '{print $1}')

# If static pod manifest issue
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
# Wait for pod to stop, then restore
sudo cp /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
```

## 6. Resource Management and Troubleshooting

### Monitor Resource Usage

```bash
# If metrics-server is installed
kubectl top nodes
kubectl top pods --all-namespaces

# Without metrics-server
kubectl describe node kubemaster | grep -A5 "Allocated resources"
```

### Check Component Health

```bash
# Check all system pods
kubectl get pods -n kube-system -o wide

# Check component status (deprecated but still useful)
kubectl get componentstatuses

# Check kubelet health on node
sudo systemctl status kubelet
sudo journalctl -u kubelet -f --tail=50

# Check container runtime
sudo crictl ps
sudo crictl images
```

## 7. Network Policy Management

```bash
# Create NetworkPolicy (allow only specific pods)
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: api
    ports:
    - protocol: TCP
      port: 3306
EOF
```

## 8. ConfigMap and Secret Management

### Create ConfigMap from file

```bash
# From literal values
kubectl create configmap app-config --from-literal=color=blue --from-literal=size=large

# From file
kubectl create configmap app-config --from-file=nginx.conf

# From .env file
kubectl create configmap app-config --from-env-file=config.env
```

### Manage Secrets

```bash
# Create generic secret
kubectl create secret generic db-secret --from-literal=username=admin --from-literal=password='S!B\*d$zDsb='

# Encode/decode secrets (for inspection only)
echo -n "admin" | base64
echo "YWRtaW4=" | base64 --decode

# Mount secret in pod (example)
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: username
```

## 9. CKA Exam Critical Commands Cheat Sheet

```bash
# ALWAYS USE THESE FLAGS FOR QUICK LOOKUPS
kubectl get pods -A -o wide --show-labels
kubectl get all --all-namespaces | grep -v Running

# Debugging pod issues
kubectl describe pod <pod>
kubectl logs <pod> --previous
kubectl exec -it <pod> -- /bin/sh

# Quick etcd backup (CKA lifesaver)
sudo ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=127.0.0.1:2379

# Force delete stuck pod
kubectl delete pod <pod> --grace-period=0 --force

# Get node internal IP
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'

# Format wide output with custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

## 10. Production Best Practices

### Regular Maintenance Tasks

- **Daily**: Check node status, pod health
- **Weekly**: Certificate expiry check (`kubeadm certs check-expiration`)
- **Monthly**: etcd backup, cluster upgrade planning
- **Quarterly**: Full disaster recovery drill

### Important Configuration Locations

```bash
# Static pod manifests
/etc/kubernetes/manifests/

# Certificates
/etc/kubernetes/pki/

# kubelet config
/var/lib/kubelet/config.yaml

# Admin kubeconfig
/etc/kubernetes/admin.conf
```

### Useful Aliases for Your .bashrc

```bash
alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kgs='kubectl get services'
alias kd='kubectl describe'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias kube-system='kubectl -n kube-system'
alias klogs='kubectl logs'
alias kexec='kubectl exec -it'
```

This covers the majority of cluster management tasks you'll need for the CKA exam and real-world Kubernetes administration. Practice these regularly!
