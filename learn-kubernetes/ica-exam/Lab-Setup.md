# ICA Lab Setup

You cannot pass a hands-on exam by reading. This file gets you a throwaway mesh you can break and rebuild in minutes.

Target: **Istio 1.26** on Kubernetes, matching the exam environment.

## What You Need

| Requirement | Minimum | Comfortable |
| --- | --- | --- |
| CPU | 4 cores | 8 cores |
| RAM | 8 GB | 16 GB |
| Disk | 20 GB free | 40 GB free |
| Container runtime | Docker or Podman | Docker |

A single-node `kind` cluster is enough for every task in this folder except the multi-cluster material in `Ambient.md`, which is out of ICA scope anyway.

## Option A: kind (recommended)

`kind` is fastest to create and destroy, and destroying is the point.

### Install the tools

```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
sudo install -o root -g root -m 0755 kind /usr/local/bin/kind

# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Install istioctl (pin the exam minor)

Pin the version. Do not use `latest`. The exam environment is currently Istio **1.29**; these labs work on 1.26+ with the v1 APIs.

```bash
# Pin a current 1.26+ minor. Exam hosts run ~1.29; 1.26+ is enough for these APIs.
export ISTIO_VERSION=1.29.0
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
cd istio-${ISTIO_VERSION}
export PATH=$PWD/bin:$PATH
echo "export PATH=$PWD/bin:\$PATH" >> ~/.bashrc

istioctl version
```

The extracted directory also contains `samples/`, which has Bookinfo, httpbin, and sleep. You will use those constantly. Keep the directory.

### Create the cluster

Two worker nodes so you can practise locality and scheduling behaviour, and a port mapping so the ingress gateway is reachable from your host.

```bash
cat <<'EOF' > kind-istio.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: istio-lab
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true,topology.kubernetes.io/region=us-west,topology.kubernetes.io/zone=us-west-1a"
    extraPortMappings:
      - containerPort: 30080
        hostPort: 80
        protocol: TCP
      - containerPort: 30443
        hostPort: 443
        protocol: TCP
  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "topology.kubernetes.io/region=us-west,topology.kubernetes.io/zone=us-west-1b"
  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "topology.kubernetes.io/region=us-east,topology.kubernetes.io/zone=us-east-1a"
EOF

kind create cluster --config kind-istio.yaml
kubectl get nodes --show-labels
```

The region and zone labels matter for `21.md` (locality failover). Set them now so you do not have to rebuild later.

## Option B: minikube

```bash
minikube start --profile istio-lab --cpus 4 --memory 8192 --nodes 3
minikube profile istio-lab

# For LoadBalancer services, run this in a second terminal and leave it running
minikube tunnel
```

## Option C: k3d

```bash
k3d cluster create istio-lab \
  --agents 2 \
  --k3s-arg "--disable=traefik@server:0" \
  -p "80:30080@server:0" \
  -p "443:30443@server:0"
```

Disabling Traefik matters. Otherwise it fights the Istio ingress gateway for ports 80 and 443.

## Install Istio (Sidecar Mode)

Start with sidecar mode. It is the older, more heavily tested path and most exam tasks assume it.

```bash
istioctl install --set profile=demo -y
```

The `demo` profile is the right choice for a lab: it enables both ingress and egress gateways and turns on full-fidelity tracing and access logs. The `default` profile has no egress gateway, which will block the `15.md` tasks.

```bash
kubectl -n istio-system get pods
kubectl -n istio-system get svc
```

Expected:

```text
NAME                                    READY   STATUS
istio-egressgateway-...                 1/1     Running
istio-ingressgateway-...                1/1     Running
istiod-...                              1/1     Running
```

### Make the ingress gateway reachable on kind

kind has no cloud load balancer, so the gateway Service stays `Pending`. Pin it to the NodePorts you mapped in the cluster config.

```bash
kubectl -n istio-system patch svc istio-ingressgateway --type merge -p '{
  "spec": {
    "type": "NodePort",
    "ports": [
      {"name":"http2","port":80,"targetPort":8080,"nodePort":30080},
      {"name":"https","port":443,"targetPort":8443,"nodePort":30443}
    ]
  }
}'
```

Now `http://localhost` reaches the gateway. Set the variables the Istio docs use, so you can copy-paste from `istio.io` directly:

```bash
export INGRESS_HOST=localhost
export INGRESS_PORT=80
export SECURE_INGRESS_PORT=443
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo "$GATEWAY_URL"
```

Alternatively install MetalLB and get real `LoadBalancer` behaviour, which is closer to the exam environment:

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml
kubectl -n metallb-system wait --for=condition=available deploy/controller --timeout=180s

# Pick a range inside the kind docker network subnet
docker network inspect kind -f '{{range .IPAM.Config}}{{.Subnet}} {{end}}'

kubectl apply -f - <<'EOF'
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: kind-pool
  namespace: metallb-system
spec:
  addresses:
    - 172.18.255.200-172.18.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: kind-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - kind-pool
EOF
```

## Deploy The Sample Applications

### Bookinfo

Bookinfo is the reference app for nearly every Istio doc page. Its four services with three `reviews` versions make it ideal for subsets, shifting, and mirroring.

```bash
cd istio-${ISTIO_VERSION}

kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled

kubectl -n bookinfo apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl -n bookinfo wait --for=condition=ready pod --all --timeout=180s

# Expose it
kubectl -n bookinfo apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

# The subsets v1/v2/v3 that most tasks reference
kubectl -n bookinfo apply -f samples/bookinfo/networking/destination-rule-all.yaml
```

Verify each pod has two containers, the app and `istio-proxy`:

```bash
kubectl -n bookinfo get pods
# READY should be 2/2 for every pod
```

Reach the product page:

```bash
curl -s "http://$GATEWAY_URL/productpage" | grep -o '<title>.*</title>'
# <title>Simple Bookstore App</title>
```

Refresh it repeatedly in a browser and the star ratings change, because `reviews` round-robins across v1 (no stars), v2 (black stars), and v3 (red stars). That visible difference is why Bookinfo is the canonical demo.

### httpbin and sleep

These two are the workhorses. `httpbin` echoes request details and can return arbitrary status codes and delays. `sleep` is a client with `curl` installed.

```bash
kubectl create namespace demo
kubectl label namespace demo istio-injection=enabled

kubectl -n demo apply -f samples/httpbin/httpbin.yaml
kubectl -n demo apply -f samples/sleep/sleep.yaml
kubectl -n demo wait --for=condition=ready pod --all --timeout=120s
```

Test east-west traffic:

```bash
kubectl -n demo exec deploy/sleep -c sleep -- curl -sS -o /dev/null -w "%{http_code}\n" http://httpbin:8000/get
# 200
```

Learn this command shape now. You will type it hundreds of times.

```bash
# The general form
kubectl -n <ns> exec deploy/sleep -c sleep -- curl -sS <flags> <url>

# Useful flags
#   -o /dev/null          discard body
#   -w "%{http_code}\n"   print only the status code
#   -I                    headers only
#   -H "key: value"       add a header for match testing
#   --max-time 10         do not hang forever
#   -v                    see TLS and connection detail
```

### A second client outside the mesh

Some security tasks need a caller with **no sidecar** to prove that `STRICT` mTLS or an `AuthorizationPolicy` actually blocks it.

```bash
kubectl create namespace nomesh
# Deliberately NOT labelled for injection
kubectl -n nomesh apply -f samples/sleep/sleep.yaml
kubectl -n nomesh wait --for=condition=ready pod --all --timeout=120s

kubectl -n nomesh get pods
# READY should be 1/1, no sidecar
```

Now you have both halves of every security test:

```bash
# In-mesh caller (has a sidecar, gets an identity, uses mTLS)
kubectl -n demo   exec deploy/sleep -c sleep -- curl -sS -o /dev/null -w "in-mesh: %{http_code}\n" http://httpbin.demo:8000/get

# Out-of-mesh caller (plaintext, no identity)
kubectl -n nomesh exec deploy/sleep -c sleep -- curl -sS -o /dev/null -w "no-mesh: %{http_code}\n" http://httpbin.demo:8000/get
```

## Install The Observability Addons

Kiali makes routing mistakes visible, which shortens the debugging loop enormously while you are learning.

```bash
cd istio-${ISTIO_VERSION}
kubectl apply -f samples/addons/
kubectl -n istio-system rollout status deploy/kiali --timeout=300s
```

This installs Prometheus, Grafana, Jaeger, and Kiali. Open them with:

```bash
istioctl dashboard kiali      # graph of your mesh
istioctl dashboard grafana    # the Istio dashboards
istioctl dashboard jaeger     # traces
istioctl dashboard envoy deploy/httpbin.demo   # raw Envoy admin UI
istioctl dashboard controlz deploy/istiod.istio-system  # istiod internals
```

Generate traffic so the graph has something to show:

```bash
for i in $(seq 1 200); do
  curl -s -o /dev/null "http://$GATEWAY_URL/productpage"
done
```

Note that the addons under `samples/addons/` are **demo-quality, not production**. They store nothing durably. That is fine here and it is also worth knowing as a concept.

## Snapshot And Reset Discipline

The single most valuable habit for hands-on exam prep is being able to return to a clean slate in under two minutes. Then you can break things fearlessly.

### Reset just the Istio config, keep the cluster

Most of the time this is all you need. It removes every routing and policy resource but leaves the mesh and apps running.

```bash
cat <<'EOF' > ~/istio-reset.sh
#!/usr/bin/env bash
# Delete all Istio config CRs across all namespaces, keep the install and the apps.
set -u

KINDS="virtualservices destinationrules gateways serviceentries sidecars \
workloadentries workloadgroups envoyfilters \
peerauthentications requestauthentications authorizationpolicies \
telemetries wasmplugins proxyconfigs"

for kind in $KINDS; do
  kubectl delete "$kind" --all -A --ignore-not-found >/dev/null 2>&1
done

# Gateway API resources too
kubectl delete gateways.gateway.networking.k8s.io --all -A --ignore-not-found >/dev/null 2>&1
kubectl delete httproutes.gateway.networking.k8s.io --all -A --ignore-not-found >/dev/null 2>&1

echo "Istio config cleared."
echo "Re-applying the Bookinfo baseline..."
kubectl -n bookinfo apply -f "$HOME/istio-1.26.0/samples/bookinfo/networking/bookinfo-gateway.yaml" >/dev/null
kubectl -n bookinfo apply -f "$HOME/istio-1.26.0/samples/bookinfo/networking/destination-rule-all.yaml" >/dev/null
echo "Done."
EOF

chmod +x ~/istio-reset.sh
```

Adjust the path to your `istio-1.26.0` directory. Then a reset is one command:

```bash
~/istio-reset.sh
```

### Rebuild the whole cluster

```bash
kind delete cluster --name istio-lab
kind create cluster --config kind-istio.yaml
# then re-run the install and sample app steps
```

Wrap the full build in a script so a rebuild costs you nothing mentally:

```bash
cat <<'EOF' > ~/istio-lab-build.sh
#!/usr/bin/env bash
set -euo pipefail
ISTIO_DIR="$HOME/istio-1.26.0"

kind delete cluster --name istio-lab 2>/dev/null || true
kind create cluster --config "$HOME/kind-istio.yaml"

istioctl install --set profile=demo -y

kubectl -n istio-system patch svc istio-ingressgateway --type merge -p '{
  "spec": {"type":"NodePort","ports":[
    {"name":"http2","port":80,"targetPort":8080,"nodePort":30080},
    {"name":"https","port":443,"targetPort":8443,"nodePort":30443}]}}'

for ns in bookinfo demo; do
  kubectl create namespace "$ns"
  kubectl label namespace "$ns" istio-injection=enabled
done
kubectl create namespace nomesh

kubectl -n bookinfo apply -f "$ISTIO_DIR/samples/bookinfo/platform/kube/bookinfo.yaml"
kubectl -n bookinfo apply -f "$ISTIO_DIR/samples/bookinfo/networking/bookinfo-gateway.yaml"
kubectl -n bookinfo apply -f "$ISTIO_DIR/samples/bookinfo/networking/destination-rule-all.yaml"

kubectl -n demo   apply -f "$ISTIO_DIR/samples/httpbin/httpbin.yaml"
kubectl -n demo   apply -f "$ISTIO_DIR/samples/sleep/sleep.yaml"
kubectl -n nomesh apply -f "$ISTIO_DIR/samples/sleep/sleep.yaml"

kubectl apply -f "$ISTIO_DIR/samples/addons/"

kubectl -n bookinfo wait --for=condition=ready pod --all --timeout=300s
kubectl -n demo     wait --for=condition=ready pod --all --timeout=300s

echo
echo "Lab ready. Try: curl -s http://localhost/productpage | grep -o '<title>.*</title>'"
EOF

chmod +x ~/istio-lab-build.sh
```

## A Second Cluster For Ambient Practice

Ambient and sidecar mode can coexist, but for learning it is cleaner to keep them separate. Build a second cluster when you reach `05.md`.

```bash
kind create cluster --name ambient-lab

# Ambient needs the Gateway API CRDs for waypoints
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

istioctl install --set profile=ambient --skip-confirmation
kubectl -n istio-system get pods
kubectl -n istio-system get daemonset ztunnel
```

Switch between clusters with:

```bash
kubectl config get-contexts
kubectl config use-context kind-istio-lab
kubectl config use-context kind-ambient-lab
```

## Install The Gateway API CRDs

Istio supports the Kubernetes Gateway API, and `20.md` needs it. On a cluster that does not ship the CRDs, install them explicitly:

```bash
kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1 || \
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

kubectl get crd | grep gateway.networking.k8s.io
kubectl get gatewayclass
```

`istioctl install` registers the `istio` GatewayClass automatically once the CRDs exist.

## Verify Your Environment

Run this before you start any study session. It catches a half-broken lab before it wastes an hour of your time.

```bash
cat <<'EOF' > ~/istio-lab-check.sh
#!/usr/bin/env bash
echo "=== Versions ==="
istioctl version
echo
echo "=== Nodes ==="
kubectl get nodes
echo
echo "=== Control plane ==="
kubectl -n istio-system get pods
echo
echo "=== Mesh membership ==="
kubectl get ns -L istio-injection -L istio.io/rev -L istio.io/dataplane-mode
echo
echo "=== Sidecar counts (want 2/2 in bookinfo and demo) ==="
kubectl -n bookinfo get pods
kubectl -n demo get pods
echo
echo "=== Proxy sync (want SYNCED everywhere) ==="
istioctl proxy-status
echo
echo "=== Config analysis (want no errors) ==="
istioctl analyze -A
echo
echo "=== Ingress reachable? ==="
curl -sS -o /dev/null -w "productpage: %{http_code}\n" http://localhost/productpage
echo
echo "=== East-west reachable? ==="
kubectl -n demo exec deploy/sleep -c sleep -- \
  curl -sS -o /dev/null -w "httpbin: %{http_code}\n" http://httpbin:8000/get
EOF

chmod +x ~/istio-lab-check.sh
~/istio-lab-check.sh
```

Everything healthy looks like this:

- `istioctl version` shows client and control plane on the **same minor** (lab: pin 1.26+; exam environment is currently **1.29** — APIs in this folder use `networking.istio.io/v1` / `security.istio.io/v1`, which both speak)
- every `istio-system` pod is `Running`
- `bookinfo` and `demo` pods are `2/2`
- `istioctl proxy-status` shows `SYNCED` in all four columns
- `istioctl analyze -A` reports no errors
- both curls return `200`

## Practice Discipline

Habits that translate directly into exam points.

- **Write YAML from the docs, not from memory, but know which doc page.** Docs are allowed. Speed comes from knowing that timeouts live on the VirtualService page and connection pools live on the DestinationRule page, so you land on the right page in one click.
- **Bookmark nothing you cannot find in two clicks.** The exam browser is slow. Practise navigating `istio.io/latest/docs/reference/config/networking/virtual-service/` by muscle memory.
- **`istioctl analyze` after every change.** Make it reflexive, like `git status`.
- **Always verify with real traffic.** A resource that exists is not a resource that works. Curl through the actual path.
- **Break things deliberately.** Delete a DestinationRule and watch the 503. Set a bad host and read the error. `35.md` is built for this.
- **Time yourself from the very first session.** Aim for 6 minutes per task. Slow-and-correct fails this exam.
- **Practise the `-n` flag until it is automatic.** Wrong namespace is the most common way to score zero on work that was otherwise perfect.

## Useful One-Liners To Keep Around

```bash
# Watch what a sidecar actually received
istioctl proxy-config route deploy/productpage-v1.bookinfo
istioctl proxy-config cluster deploy/productpage-v1.bookinfo
istioctl proxy-config endpoint deploy/productpage-v1.bookinfo
istioctl proxy-config listener deploy/productpage-v1.bookinfo
istioctl proxy-config secret deploy/productpage-v1.bookinfo

# Full effective config for one workload
istioctl proxy-config all deploy/httpbin.demo -o json > /tmp/envoy.json

# Live access logs from a sidecar
kubectl -n demo logs deploy/httpbin -c istio-proxy -f

# Turn on debug logging for one proxy, then put it back
istioctl proxy-config log deploy/httpbin.demo --level debug
istioctl proxy-config log deploy/httpbin.demo --level info

# What identity does this workload have?
istioctl proxy-config secret deploy/httpbin.demo -o json \
  | jq -r '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' \
  | base64 -d | openssl x509 -noout -text | grep -A2 'Subject Alternative Name'

# Is mTLS actually happening between two workloads?
istioctl x describe pod $(kubectl -n demo get pod -l app=httpbin -o jsonpath='{.items[0].metadata.name}') -n demo

# Generate continuous background traffic while you experiment
kubectl -n demo exec deploy/sleep -c sleep -- \
  sh -c 'while true; do curl -s -o /dev/null http://httpbin:8000/get; sleep 0.2; done' &
```

## Where To Go Next

Once `~/istio-lab-check.sh` is fully green, start at `01.md`. Every task in the numbered files assumes this lab, and names the namespace it expects (`demo`, `bookinfo`, or one it tells you to create).
