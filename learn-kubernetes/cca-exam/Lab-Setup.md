# CCA Lab Setup

The exam is closed-book multiple choice. A lab still pays: Hubble flows and `cilium status` make architecture questions obvious.

## Requirements

| | Minimum |
| --- | --- |
| CPU | 2 cores (4 better) |
| RAM | 8 GB |
| Disk | 20 GB |
| Tools | Docker or Podman, `kubectl`, `kind` or `minikube`, Cilium CLI |

Do **not** install a second CNI. kind's default CNI must be disabled so Cilium owns the datapath.

## Install Cilium CLI

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
GOOS=$(go env GOOS 2>/dev/null || echo linux)
GOARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -L --fail --remote-name-all \
  "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${GOARCH}.tar.gz"{,.sha256sum}
sha256sum --check cilium-linux-${GOARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${GOARCH}.tar.gz /usr/local/bin
cilium version
```

Hubble CLI (for `15.md`–`16.md`):

```bash
HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
curl -L --fail --remote-name-all \
  "https://github.com/cilium/hubble/releases/download/${HUBBLE_VERSION}/hubble-linux-amd64.tar.gz"{,.sha256sum}
sha256sum --check hubble-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-amd64.tar.gz /usr/local/bin
```

## kind cluster without default CNI

```bash
cat <<'EOF' > kind-cilium.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: cca-lab
networking:
  disableDefaultCNI: true
  kubeProxyMode: none
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF

kind create cluster --config kind-cilium.yaml
```

`kubeProxyMode: none` lets you practise **kube-proxy replacement**. If kube-proxy-free install fails on your machine, drop that line and install Cilium with kube-proxy still present.

## Install Cilium

```bash
cilium install --version 1.17.4 \
  --set kubeProxyReplacement=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

cilium status --wait
```

Helm equivalent (know both for the exam):

```bash
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true
```

## Connectivity test

```bash
cilium connectivity test
```

This spins up namespaces and pods, then checks L3/L4/L7 and policy. It is slow the first time; that is normal. A green test is the best proof the datapath works.

## Hubble

```bash
cilium hubble port-forward &
hubble status
hubble observe --since 5m
```

UI (lab only):

```bash
cilium hubble ui
```

## Sample workloads

```bash
kubectl create ns shop
kubectl -n shop run client --image=curlimages/curl --command -- sleep infinity
kubectl -n shop run httpbin --image=kennethreitz/httpbin --port=80
kubectl -n shop expose pod httpbin --port=80
kubectl -n shop wait --for=condition=ready pod --all --timeout=120s
kubectl -n shop exec client -- curl -sS -o /dev/null -w "%{http_code}\n" http://httpbin
```

## Verify

```bash
cilium version
cilium status
kubectl -n kube-system get ds cilium
kubectl -n kube-system get deploy cilium-operator hubble-relay hubble-ui
kubectl -n kube-system get pods -l k8s-app=cilium
```

Healthy: agent pods `Running` on every node, operator Ready, `cilium status` shows OK / Green.

## Reset

```bash
kind delete cluster --name cca-lab
```

## Exam note

You will **not** have this cluster in the exam. Use it so answers are memories, not guesses. After `cilium connectivity test` once, you will never forget what the CLI is for.
