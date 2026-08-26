# CKA: etcd Backup & Restore (Official Kubernetes procedure)

Source: [Operating etcd clusters for Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)

> Run all commands on the **control-plane node**.
> Verified on Multipass kubeadm v1.28.15 (`kubemaster` + `worker2`): backup → restore to a new data dir → cluster came back with nodes and workloads.

The Kubernetes docs prefer `etcdutl` for snapshot status/restore (`etcdctl snapshot status` and `etcdctl snapshot restore` are deprecated since etcd v3.5). CKA and this lab still work with `etcdctl`. Use `etcdutl` if it is installed.

---

## 0. Get certs and endpoint from the etcd Pod

Official backup section: _"`trusted-ca-file`, `cert-file` and `key-file` can be obtained from the description of the etcd Pod."_

```bash
kubectl -n kube-system describe pod etcd-$(hostname)
```

On this cluster:

| Official placeholder | Value                                             |
| -------------------- | ------------------------------------------------- |
| endpoint             | `https://127.0.0.1:2379` (`--listen-client-urls`) |
| trusted-ca-file      | `/etc/kubernetes/pki/etcd/ca.crt`                 |
| cert-file            | `/etc/kubernetes/pki/etcd/server.crt`             |
| key-file             | `/etc/kubernetes/pki/etcd/server.key`             |
| etcd Pod name        | `etcd-kubemaster`                                 |

---

## 1. Backup

From [Backing up an etcd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster):

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /opt/snapshot.db
```

Verify (`etcdctl` is deprecated; `etcdutl` if present):

```bash
sudo ETCDCTL_API=3 etcdctl --write-out=table snapshot status /opt/snapshot.db
# or: sudo etcdutl --write-out=table snapshot status /opt/snapshot.db
```

Expected:

```
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 6f2cead2 |  2731268 |       1330 |     5.4 MB |
+----------+----------+------------+------------+
```

---

## 2. Restore

From [Restoring an etcd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#restoring-an-etcd-cluster).

Official order:

1. Stop **all** API server instances
2. Restore etcd
3. Restart all API server instances

They also recommend restarting `kube-scheduler`, `kube-controller-manager`, and `kubelet` so those components do not keep stale data.

### 2a. Stop the API server (kubeadm)

On kubeadm the API server is a static Pod. Move its manifest out of `/etc/kubernetes/manifests/` so kubelet stops it:

```bash
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
```

Wait until it is gone (can take a minute):

```bash
sudo crictl ps | grep kube-apiserver
# empty = stopped
# kubectl will also show: connection to the server ... was refused
```

### 2b. Restore into a **new** data directory

Official command (docs recommend `etcdutl`; `etcdctl` still works):

```bash
sudo ETCDCTL_API=3 etcdctl --data-dir=/var/lib/etcd-from-backup \
  snapshot restore /opt/snapshot.db
```

If `etcdutl` is available:

```bash
sudo etcdutl --data-dir=/var/lib/etcd-from-backup snapshot restore /opt/snapshot.db
```

If the data dir is the **same** as before, the docs say: delete it and stop etcd first. If it is a **new** directory (this path), do **not** change `--data-dir` in the container command. Change only the host mount.

### 2c. Point etcd at the new directory

Official text: change `/etc/kubernetes/manifests/etcd.yaml` `volumes.hostPath.path` for `name: etcd-data` to the new directory.

```bash
sudo vi /etc/kubernetes/manifests/etcd.yaml
```

Edit that `hostPath` so it is:

```yaml
- hostPath:
    path: /var/lib/etcd-from-backup
    type: DirectoryOrCreate
  name: etcd-data
```

Leave `--data-dir=/var/lib/etcd` and `mountPath: /var/lib/etcd` unchanged.

### 2d. Restart etcd and the API server

Official options: delete the etcd Pod **or** restart kubelet, or both.

```bash
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sudo systemctl restart kubelet.service
```

If the API is already up and you only need etcd to pick up the new dir:

```bash
kubectl -n kube-system delete pod etcd-kubemaster
```

### 2e. Check

```bash
sudo crictl ps | grep -E "etcd|apiserver"
kubectl get nodes
kubectl get pods -A
```

---

## 3. The three paths (why hostPath is the only edit)

Official docs: change `volumes.hostPath.path` for `name: etcd-data`. They do **not** say to change `--data-dir` in the container command.

| Setting                      | Value                       | What it is                                       |
| ---------------------------- | --------------------------- | ------------------------------------------------ |
| `etcdctl restore --data-dir` | `/var/lib/etcd-from-backup` | Folder on the **host** where restore writes data |
| `hostPath.path`              | `/var/lib/etcd-from-backup` | Same host folder, mounted into the container     |
| `mountPath`                  | `/var/lib/etcd`             | Where the mount appears **inside** the container |
| `--data-dir` (in command)    | `/var/lib/etcd`             | Where etcd reads/writes **inside** the container |

```
HOST: /var/lib/etcd-from-backup  ──hostPath──►  CONTAINER: /var/lib/etcd
                                                      ↑
                                                 --data-dir
                                                 mountPath
```

**Rule:** container `--data-dir` must match `mountPath` (always `/var/lib/etcd` on kubeadm).
**Rule:** `hostPath` must match the restore `--data-dir` (the host folder).

---

## 4. Common mistakes

| Mistake                                               | Symptom                                                                  |
| ----------------------------------------------------- | ------------------------------------------------------------------------ |
| Restore while API server is still running             | Docs forbid this; wait until `crictl ps \| grep kube-apiserver` is empty |
| Changed container `--data-dir` to match the host path | etcd "Running" but empty cluster                                         |
| Forgot to change `hostPath` for `name: etcd-data`     | etcd still uses the old directory                                        |
| `hostPath` points at the wrong folder                 | Same — old or empty data                                                 |

---

## 5. CKA copy-paste template

```bash
# --- BACKUP ---
sudo ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /opt/snapshot.db
sudo ETCDCTL_API=3 etcdctl --write-out=table snapshot status /opt/snapshot.db

# --- RESTORE ---
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
# wait until: sudo crictl ps | grep kube-apiserver   is empty

sudo ETCDCTL_API=3 etcdctl --data-dir=/var/lib/etcd-from-backup \
  snapshot restore /opt/snapshot.db

# edit /etc/kubernetes/manifests/etcd.yaml
# volumes.hostPath.path for name: etcd-data  →  /var/lib/etcd-from-backup
# do NOT change --data-dir or mountPath

sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sudo systemctl restart kubelet.service

kubectl get nodes
kubectl get pods -A
```

---

## 6. Live test (2026-08-26, Multipass kubeadm v1.28.15)

This exact official procedure:

```
Snapshot saved at /opt/snapshot.db
HASH 6f2cead2  REVISION 2731268  TOTAL KEYS 1330  TOTAL SIZE 5.4 MB

sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
# waited until kube-apiserver gone, kubectl: connection refused

sudo ETCDCTL_API=3 etcdctl --data-dir=/var/lib/etcd-from-backup snapshot restore /opt/snapshot.db
# edited etcd.yaml hostPath → /var/lib/etcd-from-backup
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sudo systemctl restart kubelet.service

kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
app                           1/1     Running   0          90m
nginx-test-568599cf4d-qdrw8   1/1     Running   0          126m
nginx-test-568599cf4d-w6vtq   1/1     Running   0          126m
```

# 2.Complete Guide: Create Kubernetes User with Pod Permissions

## 📋 Table of Contents

1. [Setup User Certificates](#1-setup-user-certificates)
2. [Create & Approve CSR](#2-create--approve-csr)
3. [Create RBAC Permissions](#3-create-rbac-permissions)
4. [Configure kubeconfig](#4-configure-kubeconfig)
5. [Testing Permissions](#5-testing-permissions)
6. [Clean Up Everything](#6-clean-up-everything)

---

## 1. Setup User Certificates

```bash
# Ubuntu/Debian (16.04+)
sudo apt-get install yamllint
yamllint cert.yaml
# Create directory for user's keys
mkdir -p ~/ajeet
# Meaning: Creates folder structure /home/ubuntu/ajeet

# Generate private key (2048-bit RSA)
openssl genrsa -out ~/ajeet/.key 2048
# Meaning: Creates user's private key - keep this secret!

# Generate Certificate Signing Request (CSR)
openssl req -new -key ~/ajeet/.key -out ~/ajeet.csr -subj "/CN=ajeet"
# Meaning: Creates a request to get certificate signed
# - CN=ajeet: Common Name = username (Kubernetes uses this for authentication)
```

---

## 2. Create & Approve CSR

```bash
# Encode CSR to base64 (Kubernetes requirement)
BASE64_CSR=$(cat ~/ajeet.csr | base64 | tr -d "\n")
# Meaning: Converts CSR to single-line base64 string for YAML

# Create CertificateSigningRequest resource
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ajeet
spec:
  request: ${BASE64_CSR}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400   # 24 hours validity
  usages:
  - client auth
EOF
# Meaning: Submits certificate request to Kubernetes cluster

# Check CSR status
kubectl get csr
# Meaning: Lists all pending/approved certificate requests

# Approve the certificate (as cluster admin)
kubectl certificate approve ajeet
# Meaning: Signs the certificate, allowing user to authenticate

# Extract signed certificate
kubectl get csr ajeet -o jsonpath='{.status.certificate}' | base64 -d > ~/ajeet.crt
# Meaning: Downloads the signed certificate and decodes it
```

---

## 3. Create RBAC Permissions

```bash
# Create Role with pod permissions
kubectl create role developer \
  --verb=create,get,list,update,delete \
  --resource=pods
# Meaning: Creates role allowing all pod operations in current namespace



# Create RoleBinding (connects user to role)
kubectl create rolebinding developer-binding-ajeet \
  --role=developer \
  --user=ajeet
# Meaning: Grants 'developer' role permissions to user 'ajeet'
```

---

## 4. Configure kubeconfig

````bash
# ⚠️ IMPORTANT: Use ABSOLUTE PATH, not tilde (~)
# Get your home directory path
echo $HOME
# Output: /home/ubuntu

# Add user credentials to kubeconfig
```bash
kubectl config set-credentials ajeet \
  --client-key=/home/ubuntu/ajeet/.key \
  --client-certificate=/home/ubuntu/ajeet.crt \
  --embed-certs=true
````

# Meaning: Stores user's certificate and key in kubeconfig

# --embed-certs=true: Embeds certificate content (not just path)

# Create context for the user

kubectl config set-context ajeet-context \
 --cluster=kubernetes \
 --user=ajeet \
 --namespace=default

# Meaning: Defines a named configuration combination

# List all contexts

kubectl config get-contexts

# Meaning: Shows all available contexts with current marked by '\*'

# Switch to user's context

kubectl config use-context ajeet-context

# Meaning: Changes active user to ajeet

# Verify current context

kubectl config current-context

# Meaning: Shows which user you're currently using

````

---

## 5. Testing Permissions

```bash
# ✅ These commands should WORK:

# List pods
kubectl get pods
# Meaning: Read permission - should display pods

# Create a pod
kubectl run test-pod --image=nginx --restart=Never
# Meaning: Create permission

# Get pod details
kubectl get pod test-pod
# Meaning: Read specific pod

# Update pod (add label)
kubectl label pod test-pod environment=test
# Meaning: Update permission

# List pods with labels
kubectl get pods --show-labels
# Meaning: Verify update worked

# Delete pod
kubectl delete pod test-pod
# Meaning: Delete permission

# ❌ This command should FAIL:
kubectl get services
# Meaning: Accessing unauthorized resource (should return "forbidden")
````

---

## 6. Clean Up Everything

### Complete Cleanup Script

```bash
#!/bin/bash
# Save as: delete-ajeet-user.sh

echo "=== Cleaning Up User 'ajeet' ==="

# 1. Delete Kubernetes resources
echo "Deleting RBAC resources..."
kubectl delete rolebinding developer-binding-ajeet
kubectl delete role developer

# 2. Delete CertificateSigningRequest
echo "Deleting CSR..."
kubectl delete csr ajeet

# 3. Remove from kubeconfig
echo "Removing from kubeconfig..."
kubectl config delete-context ajeet-context
kubectl config delete-user ajeet

# 4. Delete certificate files
echo "Deleting certificate files..."
rm -rf ~/ajeet
rm -f ~/ajeet.csr
rm -f ~/ajeet.crt

# 5. Verify cleanup
echo -e "\n=== Verification ==="
echo "Remaining contexts:"
kubectl config get-contexts
echo -e "\nRemaining users in kubeconfig:"
kubectl config get-users

echo -e "\n✅ Cleanup complete! User 'ajeet' has been removed."
```

### Manual Cleanup Commands

```bash
# Delete RBAC
kubectl delete rolebinding developer-binding-ajeet
kubectl delete role developer

# Delete CSR
kubectl delete csr ajeet

# Remove from kubeconfig
kubectl config delete-context ajeet-context
kubectl config delete-user ajeet

# Delete files from filesystem
rm -rf ~/ajeet
rm -f ~/ajeet.csr ~/ajeet.crt

# Verify no resources remain
kubectl get role,rolebinding,csr | grep ajeet
```

---

## 📝 Quick Reference Card

| Component           | Command                                                                                              | Purpose                |
| ------------------- | ---------------------------------------------------------------------------------------------------- | ---------------------- | --------------- | --------------------- |
| **Key Generation**  | `openssl genrsa -out user.key 2048`                                                                  | Create private key     |
| **CSR Creation**    | `openssl req -new -key user.key -out user.csr -subj "/CN=username"`                                  | Create cert request    |
| **Base64 Encode**   | `cat user.csr                                                                                        | base64                 | tr -d "\n"`     | Encode for Kubernetes |
| **Submit CSR**      | `kubectl apply -f csr.yaml`                                                                          | Submit to cluster      |
| **Approve CSR**     | `kubectl certificate approve username`                                                               | Approve certificate    |
| **Download Cert**   | `kubectl get csr username -o jsonpath='{.status.certificate}'                                        | base64 -d > user.crt`  | Get signed cert |
| **Create Role**     | `kubectl create role name --verb=verbs --resource=resources`                                         | Define permissions     |
| **Create Binding**  | `kubectl create rolebinding name --role=role --user=user`                                            | Grant role to user     |
| **Set Credentials** | `kubectl config set-credentials user --client-key=path --client-certificate=path --embed-certs=true` | Add user to kubeconfig |
| **Create Context**  | `kubectl config set-context context --cluster=cluster --user=user`                                   | Create context         |
| **Switch User**     | `kubectl config use-context context`                                                                 | Change active user     |

---

## 🚨 Common Errors & Solutions

| Error                                                | Cause                   | Solution                                    |
| ---------------------------------------------------- | ----------------------- | ------------------------------------------- |
| `could not stat client-certificate file ~/ajeet.crt` | Tilde not expanded      | Use absolute path: `/home/ubuntu/ajeet.crt` |
| `Permission denied`                                  | Directory doesn't exist | Run `mkdir -p ~/ajeet` first                |
| `No such file or directory`                          | File not created yet    | Complete certificate generation steps       |
| `forbidden: User "ajeet" cannot list pods`           | Missing RBAC            | Create role and rolebinding                 |
| `certificate signed by unknown authority`            | Wrong cluster           | Use correct cluster name in context         |

---

## 📊 Permissions Matrix for User ajeet

| Resource    | Action | Permission |
| ----------- | ------ | ---------- |
| Pods        | create | ✅ Yes     |
| Pods        | get    | ✅ Yes     |
| Pods        | list   | ✅ Yes     |
| Pods        | update | ✅ Yes     |
| Pods        | delete | ✅ Yes     |
| Services    |        | ❌ No      |
| Deployments |        | ❌ No      |
| ConfigMaps  |        | ❌ No      |
| Namespaces  |        | ❌ No      |

---

## 🔄 Switch Between Users

```bash
# To admin (cluster administrator)
kubectl config use-context kubernetes-admin@kubernetes

# To ajeet (restricted user)
kubectl config use-context ajeet-context

# Check current user
kubectl auth can-i --list
```

---

## ✅ Verification Checklist

After setup, verify each:

- User ajeet can create pods (`kubectl run test --image=nginx`)
- User ajeet can list pods (`kubectl get pods`)
- User ajeet can get pod details (`kubectl describe pod test`)
- User ajeet can update pods (`kubectl label pod test env=test`)
- User ajeet can delete pods (`kubectl delete pod test`)
- User ajeet cannot list services (`kubectl get services` - should fail)

# 3. Handling Static Pods

1.SSH into the Node

```bash
kubectl get nodes -o wide
ssh <user>@<internal-ip-of-node01>
```

1. Find the Static Pod Path

```bash
grep staticPodPath /var/lib/kubelet/config.yaml
```

3.Create the Pod Definition

```bash
sudo tee /etc/kubernetes/manifests/static-pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: static-pod
spec:
  containers:
  - name: nginx-container
    image: nginx
    ports:
    - containerPort: 80
EOF
```

1. To remove run

```bash
sudo rm -rf /etc/kubernetes/manifests/static-pod.yaml
```

# 4.**KUBERNETES CLUSTER UPGRADE - CKA EXAM NOTES**

**PART 1: UPGRADE CONTROL PLANE (controlplane node)**

```bash
# 1. Check current version and upgrade plan
kubectl get nodes
kubeadm version
sudo kubeadm upgrade plan

# 2. Drain control plane node
kubectl drain controlplane --ignore-daemonsets --force

# 3. Update kubeadm (unhold → update → hold)
sudo apt-mark unhold kubeadm && \
sudo apt-get update && \
sudo apt-get install -y kubeadm=1.28.15-1.1 && \
sudo apt-mark hold kubeadm

# Verify kubeadm version
kubeadm version

# 4. Apply upgrade
sudo kubeadm upgrade apply v1.28.15 -y

# 5. Update kubelet & kubectl (unhold → update → hold)
sudo apt-mark unhold kubelet kubectl && \
sudo apt-get install -y kubelet=1.28.15-1.1 kubectl=1.28.15-1.1 && \
sudo apt-mark hold kubelet kubectl

# 6. Restart kubelet and uncordon
sudo systemctl restart kubelet
kubectl uncordon controlplane

# 7. Verify control plane upgraded
kubectl get nodes
kubectl version --short
```

---

### **PART 2: UPGRADE WORKER NODE (node01)**

**Open new terminal tab and SSH to worker node:**

```bash
ssh node01
```

```bash
# 1. Drain worker node (run from controlplane node first!)
# In controlplane terminal:
kubectl drain node01 --ignore-daemonsets --force

# 2. Update kubeadm on worker node (unhold → update → hold)
sudo apt-mark unhold kubeadm && \
sudo apt-get update && \
sudo apt-get install -y kubeadm=1.28.15-1.1 && \
sudo apt-mark hold kubeadm

# Verify kubeadm version
kubeadm version

# 3. Upgrade worker node
sudo kubeadm upgrade node

# 4. Update kubelet & kubectl on worker node (unhold → update → hold)
sudo apt-mark unhold kubelet kubectl && \
sudo apt-get install -y kubelet=1.28.15-1.1 kubectl=1.28.15-1.1 && \
sudo apt-mark hold kubelet kubectl

# 5. Restart kubelet
sudo systemctl restart kubelet

# 6. Uncordon worker node (run from controlplane node!)
# Back in controlplane terminal:
kubectl uncordon node01

# 7. Verify worker node upgraded
kubectl get nodes
```

---

### **QUICK REFERENCE CARD - KEY COMMANDS**

| Component           | Control Plane                                      | Worker Node                                  |
| ------------------- | -------------------------------------------------- | -------------------------------------------- |
| **Drain**           | `k drain controlplane --ignore-daemonsets --force` | `k drain node01 --ignore-daemonsets --force` |
| **kubeadm**         | unhold → update (1.28.15) → hold                   | unhold → update (1.28.15) → hold             |
| **Upgrade**         | `kubeadm upgrade apply v1.28.15 -y`                | `kubeadm upgrade node`                       |
| **kubelet/kubectl** | unhold → update (1.28.15) → hold                   | unhold → update (1.28.15) → hold             |
| **Restart**         | `systemctl restart kubelet`                        | `systemctl restart kubelet`                  |
| **Uncordon**        | `k uncordon controlplane`                          | `k uncordon node01`                          |

---

### **⚠️ CRITICAL CKA EXAM TIPS:**

1. **Always use `apt-mark unhold` before updating** and `apt-mark hold` after
2. **Same version number** for kubeadm, kubelet, and kubectl
3. **Drain before upgrade**, **uncordon after**
4. `**--ignore-daemonsets --force`\*\* when draining control plane
5. `**kubeadm upgrade node**` on workers (NOT `upgrade apply`)
6. **Check versions match** after upgrade: `kubelet --version` and `kubectl version`
7. **Multiple worker nodes?** Repeat PART 2 for each worker

---

### **VERSION CHECK COMMANDS (Post-Upgrade)**

```bash
# Check node status
kubectl get nodes

# Check kubeadm version
kubeadm version

# Check kubelet version
kubelet --version

# Check kubectl version
kubectl version --client

# Check API server version
kubectl version --short
```

---

### **SAMPLE EXAM SCENARIO COMMANDS (Quick Version)**

**Control plane:**

```bash
k drain controlplane --ignore-daemonsets --force
apt-mark unhold kubeadm && apt-get update && apt-get install -y kubeadm=v1.28.15 && apt-mark hold kubeadm
kubeadm upgrade apply v1.28.15 -y
apt-mark unhold kubelet kubectl && apt-get install -y kubelet=v1.28.15 kubectl=v1.28.15 && apt-mark hold kubelet kubectl
systemctl restart kubelet && k uncordon controlplane
```

**Worker node:**

```bash
k drain node01 --ignore-daemonsets --force   # from controlplane
# SSH to node01
apt-mark unhold kubeadm && apt-get update && apt-get install -y kubeadm=v1.28.15 && apt-mark hold kubeadm
kubeadm upgrade node
apt-mark unhold kubelet kubectl && apt-get install -y kubelet=v1.28.15 kubectl=v1.28.15 && apt-mark hold kubelet kubectl
systemctl restart kubelet
# back to controlplane
k uncordon node01
```

The error is because you haven't added the **metrics-server Helm repository** yet.

### 1. Add the repo

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
```

Verify:

```bash
helm search repo metrics-server
```

You should see something like:

```bash
NAME                           CHART VERSION   APP VERSION
metrics-server/metrics-server  x.x.x           0.8.1
```

### 2. Install Metrics Server

For kubeadm labs and CKA-style environments, this usually works:

```bash
helm upgrade --install metrics-server metrics-server/metrics-server \
  -n kube-system \
  --set args[0]=--kubelet-insecure-tls
```

If your nodes use InternalIP:

```bash
helm upgrade --install metrics-server metrics-server/metrics-server \
  -n kube-system \
  --set args[0]=--kubelet-insecure-tls \
  --set args[1]=--kubelet-preferred-address-types=InternalIP
```

### 3. Verify

```bash
kubectl get pods -n kube-system | grep metrics
```

Wait until it's Running, then:

```bash
kubectl top nodes
kubectl top pods -A
```

### Alternative (latest Kubernetes way)

Many people now simply install the official manifest instead of Helm:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Then patch it:

```bash
kubectl -n kube-system edit deployment metrics-server
```

Add:

```yaml
- --kubelet-insecure-tls
```

under the container args.

Since you're building a kubeadm homelab, I'd stick with **Helm** because it's easier to upgrade, rollback, and manage add-ons such as MetalLB, ingress-nginx, Prometheus, and Grafana.

Also run:

```bash
helm repo list
helm version
kubectl get nodes -o wide
```

if `kubectl top nodes` still fails after installation, and I can help diagnose the kubelet connection issue.

---

# Complete CKA Exam Drill Package

## Zero to Exam-Ready (Before Paying for killer.sh)

---

## 📋 **Phase 0: Environment Setup (5 minutes)**

```bash
# Create your practice environment
kubectl config view
kubectl config get-contexts
kubectl config set-context --current --namespace=default

# Create aliases (MANDATORY for speed)
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kgs='kubectl get svc'
alias kgd='kubectl get deploy'
alias kgi='kubectl get ingress'
alias kdel='kubectl delete'
```

---

## 🎯 **Drill 1: The CKA Speed Test (15 minutes)**

**Goal:** Complete ALL of these in under 15 minutes. Time yourself.

```bash
# --- START TIMER ---

# 1. Namespaces (30 seconds)
k create ns test
k config set-context --current --namespace=test

# 2. Pods (1 minute)
k run web --image=nginx --restart=Never
k run busybox --image=busybox -- sleep 3600

# 3. Deployment (1 minute)
k create deploy frontend --image=nginx --replicas=3
k scale deploy frontend --replicas=5

# 4. Service (30 seconds)
k expose deploy frontend --port=80 --target-port=80 --type=ClusterIP

# 5. ConfigMap (1 minute)
k create cm app-config --from-literal=APP_ENV=dev --from-literal=APP_COLOR=blue

# 6. Secret (1 minute)
k create secret generic db-secret --from-literal=username=admin --from-literal=password=supersecret

# 7. Persistent Storage (2 minutes)
k apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: test-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
EOF

# 8. ServiceAccount & RBAC (2 minutes)
k create sa developer
k create role dev-role --verb=get,list --resource=pods
k create rolebinding dev-binding --role=dev-role --serviceaccount=test:developer

# 9. NetworkPolicy (2 minutes)
k apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
EOF

# 10. Verify everything (2 minutes)
k get all
k get cm,secret
k get pv,pvc
k get sa,role,rolebinding
k get networkpolicy

# --- STOP TIMER ---
```

**✅ If under 15 minutes** - You're ready for speed
**❌ If over 15 minutes** - Repeat until you hit it

---

## 🔥 **Drill 2: The Troubleshooting Gauntlet (30 minutes)**

### Scenario A: Broken Image (5 minutes)

```bash
# Create broken deployment
k create deploy broken --image=nginx:notfound

# TROUBLESHOOT:
kgp                                    # See pod status
kd pod <pod-name>                      # Check events
kl <pod-name>                          # See error

# FIX:
k set image deployment/broken nginx=nginx
k rollout status deploy/broken
k rollout undo deploy/broken          # Practice rollback
```

### Scenario B: Network Policy Blocking (5 minutes)

```bash
# Create two pods
k run backend --image=nginx --labels app=backend
k run frontend --image=nginx --labels app=frontend

# Create restrictive network policy
k apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# TROUBLESHOOT:
# From frontend, try to curl backend
k exec frontend -- curl backend-service  # Should fail

# FIX:
k delete networkpolicy deny-all
k apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
EOF
```

### Scenario C: PVC Not Bound (5 minutes)

```bash
# Create PVC without PV
k create pvc orphan-pvc --access-modes=ReadWriteOnce --resources=requests:storage=5Gi

# TROUBLESHOOT:
kgpvc                                  # Check status
kd pvc orphan-pvc                      # See why

# FIX:
# Create matching PV
k apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: fix-pv
spec:
  capacity:
    storage: 6Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/fix-data
EOF
```

### Scenario D: CrashLoopBackOff (5 minutes)

```bash
# Create crashing pod
k run crash --image=busybox -- sleep 1

# TROUBLESHOOT:
kgp
kd pod crash
kl pod crash --previous

# FIX:
k delete pod crash
k run fixed --image=busybox -- sleep 3600
```

### Scenario E: Service Not Exposed (5 minutes)

```bash
# Create pod without service
k run nopod --image=nginx

# Create service pointing to wrong port
k expose pod nopod --port=8080 --target-port=8080

# TROUBLESHOOT:
kgs
kd svc nopod
kg endpoints nopod                    # Check if endpoints exist

# FIX:
k delete svc nopod
k expose pod nopod --port=80 --target-port=80

# Test:
k run test --image=busybox -- sleep 3600
k exec test -- wget -O- nopod:80
```

---

## 🔧 **Drill 3: ETCD Recovery (10 minutes)**

```bash
# 1. Backup ETCD
ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  snapshot save /tmp/etcd-backup.db

# 2. Verify backup
ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db

# 3. Create test object
k create cm test-config --from-literal=test=value

# 4. Delete everything
k delete cm test-config

# 5. Restore from backup
# STOP CONTROL PLANE FIRST!
# In real exam: need to stop kube-apiserver

# Restore command:
ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd-backup

# Then move restored data to actual ETCD location
```

**🚨 MEMORIZE this exact command pattern** - It WILL appear on exam

---

## 🌐 **Drill 4: CoreDNS & Networking (15 minutes)**

### Scenario: DNS Resolution Problems

```bash
# 1. Check CoreDNS status
k get pods -n kube-system | grep coredns
k logs -n kube-system coredns-xxx

# 2. Test DNS resolution
k run test --image=busybox -- sleep 3600
k exec test -- nslookup kubernetes.default.svc.cluster.local
k exec test -- nslookup google.com

# 3. Fix if broken
# Scale up CoreDNS
k scale deployment/coredns -n kube-system --replicas=2

# Or restart CoreDNS
k delete pods -n kube-system -l k8s-app=kube-dns

# 4. Check kube-proxy
k get pods -n kube-system | grep kube-proxy
k logs -n kube-system kube-proxy-xxx
```

### Gateway/Ingress Drill

```bash
# Create Ingress (traditional)
k create ingress test-ingress --rule="example.com/*=frontend:80"

# Create Gateway (new style)
k apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    protocol: HTTP
    port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route
spec:
  parentRefs:
  - name: my-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
    backendRefs:
    - name: frontend
      port: 80
EOF

# Verify
k get gateway
k get httproute
k describe gateway my-gateway
```

---

## 🔐 **Drill 5: Advanced RBAC Scenarios (10 minutes)**

```bash
# Scenario 1: ServiceAccount with limited permissions
k create sa limited-user
k create role pod-reader --verb=get,list,watch --resource=pods
k create rolebinding limited-binding --role=pod-reader --serviceaccount=default:limited-user

# Test
k auth can-i list pods --as=system:serviceaccount:default:limited-user
k auth can-i delete pods --as=system:serviceaccount:default:limited-user

# Scenario 2: Namespace-specific access
k create ns staging
k create role ns-pod-reader --verb=get,list --resource=pods -n staging
k create rolebinding ns-binding --role=ns-pod-reader --serviceaccount=default:limited-user -n staging

# Scenario 3: Cluster-wide access (ClusterRole)
k create clusterrole cluster-pod-reader --verb=get,list --resource=pods
k create clusterrolebinding cluster-binding --clusterrole=cluster-pod-reader --serviceaccount=default:limited-user

# Test across namespaces
k auth can-i list pods --as=system:serviceaccount:default:limited-user -n default
k auth can-i list pods --as=system:serviceaccount:default:limited-user -n staging
```

---

## 📦 **Drill 6: Complete Application Deployment (20 minutes)**

```bash
# Create production-like app with all components

# 1. Namespace
k create ns production

# 2. ConfigMap & Secret
k create cm app-config -n production --from-literal=DB_HOST=mysql-service
k create secret generic app-secret -n production --from-literal=DB_PASSWORD=securepass

# 3. MySQL (StatefulSet with PVC)
k apply -f - -n production <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:5.7
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: DB_PASSWORD
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
EOF

# 4. Web App (Deployment with Horizontal Scaling)
k create deploy web -n production --image=nginx --replicas=3

# 5. Service
k expose deploy web -n production --port=80 --target-port=80 --type=NodePort

# 6. Rolling Update
k set image deployment/web nginx=nginx:1.23 -n production
k rollout status deployment/web -n production
k rollout history deployment/web -n production

# 7. Rollback if needed
k rollout undo deployment/web -n production

# 8. Verify everything
k get all -n production
k get pvc -n production
```

---

## ⚡ **Drill 7: The Speed Marathon (45 minutes)**

**DO THIS EVERY DAY BEFORE EXAM**

```bash
# Full cleanup
k delete ns test --ignore-not-found
k delete ns staging --ignore-not-found
k delete ns production --ignore-not-found
k delete ns dev --ignore-not-found
k delete pv --all --ignore-not-found
k delete networkpolicy --all --ignore-not-found
k delete ingress --all --ignore-not-found
k delete gateway --all --ignore-not-found

# --- START TIMER: 45 MINUTES ---

# 1. Create 3 namespaces (1 min)
k create ns {dev,staging,prod}

# 2. Deploy 2 apps in each (5 min)
k -n dev create deploy app1 --image=nginx --replicas=2
k -n staging create deploy app2 --image=nginx --replicas=3
k -n prod create deploy app3 --image=nginx --replicas=4

# 3. Expose all services (2 min)
k -n dev expose deploy app1 --port=80
k -n staging expose deploy app2 --port=80 --type=NodePort
k -n prod expose deploy app3 --port=80

# 4. Create 3 ConfigMaps (2 min)
k -n dev create cm config --from-literal=env=dev
k -n staging create cm config --from-literal=env=staging
k -n prod create cm config --from-literal=env=prod

# 5. Create 3 Secrets (2 min)
k -n dev create secret generic secret --from-literal=password=devpass
k -n staging create secret generic secret --from-literal=password=stagepass
k -n prod create secret generic secret --from-literal=password=prodpass

# 6. Create PVC in prod (2 min)
k -n prod apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prod-pvc
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
EOF

# 7. Create RBAC for dev (3 min)
k -n dev create sa dev-user
k -n dev create role dev-role --verb=get,list --resource=pods,deploy,svc
k -n dev create rolebinding dev-binding --role=dev-role --serviceaccount=dev:dev-user

# 8. Create NetworkPolicy for prod (3 min)
k -n prod apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress
spec:
  podSelector:
    matchLabels:
      app: app3
  policyTypes:
  - Ingress
  ingress:
  - from: []
EOF

# 9. Update all deployments to new version (2 min)
k -n dev set image deploy/app1 nginx=nginx:1.23
k -n staging set image deploy/app2 nginx=nginx:1.23
k -n prod set image deploy/app3 nginx=nginx:1.23

# 10. Check rollout statuses (2 min)
k -n dev rollout status deploy/app1
k -n staging rollout status deploy/app2
k -n prod rollout status deploy/app3

# 11. Scale prod to 6 (1 min)
k -n prod scale deploy/app3 --replicas=6

# 12. Create static pod (5 min)
# SSH to control plane
# sudo vi /etc/kubernetes/manifests/static-nginx.yaml
cat <<EOF | sudo tee /etc/kubernetes/manifests/static-nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-nginx
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
EOF

# Wait and verify
k get pods -n kube-system | grep static

# 13. Backup ETCD (5 min)
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key

# 14. Verify all (5 min)
k get ns
k get all -A
k get cm -A
k get secret -A
k get pvc -A
k get networkpolicy -A
k get sa,role,rolebinding -A

# --- STOP TIMER ---
```

---

## 📝 **Drill 8: Quick-Fire Commands Test (10 minutes)**

**Write these commands WITHOUT LOOKING:**

```bash
# 1. Create a pod named 'web' with nginx image
# Answer: k run web --image=nginx

# 2. Create a deployment 'api' with 3 replicas
# Answer: k create deploy api --image=nginx --replicas=3

# 3. Expose deployment 'api' as NodePort service
# Answer: k expose deploy api --type=NodePort --port=80

# 4. Scale deployment to 5
# Answer: k scale deploy api --replicas=5

# 5. Update image to nginx:1.23 and rollout status
# Answer: k set image deploy/api nginx=nginx:1.23 && k rollout status deploy/api

# 6. Create configmap with two keys
# Answer: k create cm config --from-literal=key1=value1 --from-literal=key2=value2

# 7. Create secret with username/password
# Answer: k create secret generic secret --from-literal=username=admin --from-literal=password=pass

# 8. Check if you can delete pods
# Answer: k auth can-i delete pods

# 9. Get pod logs and events
# Answer: k logs pod-name && k get events

# 10. ETCD backup command
# Answer: ETCDCTL_API=3 etcdctl snapshot save /tmp/backup.db --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt --key=/etc/kubernetes/pki/etcd/healthcheck-client.key

# 11. Create static pod path
# Answer: /etc/kubernetes/manifests/

# 12. Create NetworkPolicy that allows all ingress
# Answer: kubectl create networkpolicy allow-all --pod-selector='' --ingress=''
```

---

## 🎯 **The 3-Day Pre-Exam Plan**

### **Day 1: Foundation**

- Complete **Drill 1** (Speed Test) - 5 times
- Complete **Drill 2** (Troubleshooting) - 3 times
- Complete **Drill 8** (Quick-Fire) - until you answer in < 2 seconds each

### **Day 2: Advanced**

- Complete **Drill 3** (ETCD) - 5 times
- Complete **Drill 4** (Networking) - 3 times
- Complete **Drill 5** (RBAC) - 3 times
- Complete **Drill 7** (Marathon) - 2 times

### **Day 3: Final Polish**

- Complete **Drill 7** - 1 time (under 45 minutes)
- Complete **Drill 6** - 2 times
- Review **Drill 8** commands
- Do **Drill 1** one last time (should be under 10 minutes now)

---

## 💡 **Pro Tips for Exam Day**

1. **Bookmark `kubectl explain`** - Your best friend
2. **Use `--dry-run=client -o yaml`** to generate YAML quickly
3. **Always check context** - `k config get-contexts`
4. **Remember namespace flags** - Most questions use specific namespaces
5. **ETCD commands must be memorized** - No `explain` help there
6. **For troubleshooting:** Always check `events` and `describe` first
7. **Never forget `restartPolicy`** for pods vs deployments

---

## ✅ **Success Metrics**

By the time you can:

- Complete Drill 7 in **< 35 minutes**
- Answer Drill 8 commands **in < 1 second**
- Troubleshoot ALL scenarios in Drill 2 **in < 20 minutes total**
- Recover ETCD **without looking at notes**

**You are 100% ready for the CKA exam.**

> **This drill package + 5-10 hours of practice = Ready for exam**
>
> **Killer.sh is still recommended**, but this drill gives you the foundation to crush it. When you take killer.sh, it will feel like practice, not panic.
