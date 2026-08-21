Install a full CNI plugin using the Tigera Operator for Calico, including networking and security policies. Essential for multi-node clusters.

## Tasks

1. Verify cluster CIDR from kube-controller-manager
2. Install Tigera Operator:
   - Apply operator manifest
   - Wait for operator deployment
3. Create custom resource for Calico configuration:
   - Set cluster CIDR matching kube-controller-manager
   - Configure networking mode (VXLAN or BGP)
4. Apply Calico installation manifest
5. Wait for calico-system pods to be Ready
6. Verify node networking is operational:
   - Nodes can ping each other
   - Pods on different nodes can communicate
7. Test NetworkPolicy blocking works

## Key Learning

- CNI is required for pod networking between nodes
- Tigera Operator is production-grade Calico installation
- Cluster CIDR alignment is critical — mismatch breaks networking
- Exam provides the Tigera installation link
- Installation can take 2-3 minutes

---

Here is the best way to install Calico using the Tigera Operator for the CKA exam. This method installs a full CNI plugin that supports both pod networking and NetworkPolicy enforcement.

---

### 1. Verify the Cluster CIDR from kube-controller-manager

Before installing Calico, you must find the Pod CIDR range used by your cluster's controller manager so that Calico's IP pool matches it.

```bash
# Check the kube-controller-manager pod's command-line arguments
kubectl describe pod -n kube-system kube-controller-manager-<node-name> | grep cluster-cidr
```

**Note**: The pod name suffix varies depending on your node's hostname. Alternatively, check the pod's specification directly:

```bash
kubectl get pod -n kube-system kube-controller-manager-<node-name> -o yaml | grep cluster-cidr
```

If this returns no output, check the static pod manifest on the control plane node:

```bash
sudo cat /etc/kubernetes/manifests/kube-controller-manager.yaml | grep cluster-cidr
```

The `--cluster-cidr` value (e.g., `192.168.0.0/16` or `10.244.0.0/16`) must be used in your Calico configuration.

---

### 2. Install the Tigera Operator

The operator manages the Calico installation lifecycle.

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/tigera-operator.yaml
```

**Wait for the operator deployment to be ready**:

```bash
kubectl get pods -n tigera-operator --watch
```

Press `Ctrl+C` when the operator pod shows `Running`.

---

### 3. Create the Calico Installation Custom Resource

Create a `custom-resources.yaml` file that defines your Calico configuration. The critical fields are the IP pool CIDR and the encapsulation mode.

```bash
cat <<EOF > custom-resources.yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - name: default-ipv4-ippool
      cidr: <YOUR-CLUSTER-CIDR>   # Replace with the CIDR from step 1
      encapsulation: VXLAN        # Use VXLAN (common for exam environments)
      natOutgoing: Enabled
      nodeSelector: all()
    # optional: configure node interface detection
    nodeAddressAutodetectionV4:
      interface: "eth.*|en.*"
  # Enable the Calico API server (required for advanced policy features)
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF
```

Replace `<YOUR-CLUSTER-CIDR>` with the actual CIDR (e.g., `10.244.0.0/16`). If you are unsure which encapsulation to use, **VXLAN** is a safe, cross-subnet choice. If you are in a flat L2 network and prefer BGP, you can use `encapsulation: IPIP` or disable it completely.

Apply the configuration:

```bash
kubectl create -f custom-resources.yaml
```

---

### 4. Apply the Calico Installation Manifest

The command above creates the `Installation` and `APIServer` custom resources. The operator will then deploy all necessary Calico components into the `calico-system` namespace.

---

### 5. Wait for Calico System Pods to be Ready

Monitor the Calico pods until they all show `Running` and the `calico-system` namespace is fully populated.

```bash
watch kubectl get pods -n calico-system
```

Ensure you see pods like `calico-node-*` (one per node), `calico-kube-controllers`, and `calico-typha`. This process typically takes 2-3 minutes.

Verify the overall installation status:

```bash
kubectl get tigerastatus
```

All components should show `AVAILABLE: True`.

---

### 6. Verify Node Networking is Operational

**Check that Pods on different nodes can communicate**:

First, label your nodes to identify their names:

```bash
kubectl get nodes
```

Create a test pod on node-1 and node-2 (replace `<node-1>` and `<node-2>` with actual node names):

```bash
# On Node 1
kubectl run test-pod-1 --image=busybox:1.36 --restart=Never -it --rm --overrides='{"spec":{"nodeName":"<node-1>"}}' -- sh -c "ip addr show eth0; sleep 3600"
```

```bash
# On Node 2 (in another terminal)
kubectl run test-pod-2 --image=busybox:1.36 --restart=Never -it --rm --overrides='{"spec":{"nodeName":"<node-2>"}}' -- sh -c "ip addr show eth0; sleep 3600"
```

Get the IP address of `test-pod-1`:

```bash
kubectl get pod test-pod-1 -o wide
```

Ping that IP from `test-pod-2`:

```bash
kubectl exec -it test-pod-2 -- ping <test-pod-1-ip> -c 3
```

Success indicates cross-node pod communication works.

---

### 7. Test NetworkPolicy Blocking Works

To confirm that the CNI supports security policies, create a simple `deny-all` NetworkPolicy and test it.

```bash
kubectl create namespace test-policy
kubectl run web --image=nginx:1.28 --namespace test-policy --labels app=web
kubectl run test --image=busybox:1.36 --namespace test-policy -it --rm --restart=Never -- wget --spider --timeout=2 web
```

_Expected_: Access works (no policies applied yet).

Now apply a `deny-all` policy:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: test-policy
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```

Test access again:

```bash
kubectl run test --image=busybox:1.36 --namespace test-policy -it --rm --restart=Never -- wget --spider --timeout=2 web
```

_Expected_: Access **fails** (wget exits with error), confirming NetworkPolicy is enforced.

Clean up:

```bash
kubectl delete namespace test-policy
```

---

### Exam Checklist

- [x] Cluster CIDR verified from kube-controller-manager
- [x] Tigera Operator installed and pod is running
- [x] `custom-resources.yaml` created with correct CIDR and encapsulation
- [x] Calico Installation and APIServer custom resources created
- [x] `calico-system` pods are all `Running`
- [x] Cross-node pod communication verified
- [x] NetworkPolicy blocking test succeeds

---

### Pro Tips for the CKA Exam

- **Operator URL is provided**: The exam environment will give you the exact URL for the `tigera-operator.yaml` manifest. Use it.
- **Custom resources URL is NOT provided**: You must either know the structure of `custom-resources.yaml` or how to create it from memory. The `cidr` and `encapsulation` fields are the most critical to get right.
- **Default VXLAN is safe**: If you are unsure about BGP or network topology, setting `encapsulation: VXLAN` is the most portable and likely to work.
- **Restarting kubelet**: If Calico pods do not come up, try restarting `containerd` and `kubelet` on the nodes.
- **Check firewall**: Ensure `firewalld` is disabled on all nodes if you encounter network issues.

This procedure installs a production-grade CNI that supports both pod networking and the NetworkPolicy API, fulfilling the exam requirements for a multi-node cluster setup.
