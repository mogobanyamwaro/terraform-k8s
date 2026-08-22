# MicroK8s 3-node lab (WSL)

This machine already has the cluster. Use this file only to **rebuild** or to remember how it was wired.

Layout: **1 control plane (this WSL Ubuntu) + 2 LXD VMs as workers**.

Needs: Ubuntu 24.04 WSL2 with `systemd=true` in `/etc/wsl.conf`, ~8 GB RAM free for two 2 GiB VMs, `kubectl`, Docker optional ( FORWARD rules below if Docker is installed).

## 1. Control plane (this WSL distro)

```bash
sudo snap install microk8s --classic --channel=1.35/stable
sudo usermod -aG microk8s "$USER"
mkdir -p ~/.kube
sudo microk8s status --wait-ready
sudo microk8s config > ~/.kube/config
sudo chown "$USER:$USER" ~/.kube/config
chmod 600 ~/.kube/config
sudo microk8s enable dns hostpath-storage helm
```

Put `/snap/bin` on PATH (already in `~/.zshrc`):

```bash
export PATH="$PATH:/snap/bin"
```

New terminal, then:

```bash
kubectl get nodes
```

## 2. LXD for the two workers

```bash
sudo snap install lxd
sudo lxd init --auto
sudo usermod -aG lxd "$USER"
```

Let Docker forward LXD traffic (needed on this box):

```bash
sudo iptables -I DOCKER-USER -i lxdbr0 -j ACCEPT
sudo iptables -I DOCKER-USER -o lxdbr0 -j ACCEPT
```

Launch two Ubuntu VMs (image download is slow the first time):

```bash
sudo lxc launch ubuntu:24.04 worker-1 --vm -c limits.cpu=2 -c limits.memory=2GiB
sudo lxc launch ubuntu:24.04 worker-2 --vm -c limits.cpu=2 -c limits.memory=2GiB
sudo lxc config set worker-1 boot.autostart true
sudo lxc config set worker-2 boot.autostart true
```

Wait until each has IPv4 (`sudo lxc list`), then:

```bash
sudo lxc exec worker-1 -- cloud-init status --wait
sudo lxc exec worker-2 -- cloud-init status --wait
sudo lxc exec worker-1 -- snap install microk8s --classic --channel=1.35/stable
sudo lxc exec worker-2 -- snap install microk8s --classic --channel=1.35/stable
```

## 3. Join as workers

On the **control plane**, generate a token and join from each VM. Use the LXD bridge IP `10.66.172.1` so the VMs can reach cluster-agent port `25000`.

```bash
sudo microk8s add-node
# copy the line that looks like:
#   microk8s join 10.66.172.1:25000/<token> --worker
sudo lxc exec worker-1 -- bash -lc 'microk8s join 10.66.172.1:25000/<token> --worker'
```

Repeat `add-node` for `worker-2` (tokens are one-shot).

```bash
kubectl get nodes -o wide
kubectl label node "$(hostname)" node-role.kubernetes.io/control-plane= --overwrite
kubectl label node worker-1 node-role.kubernetes.io/worker= --overwrite
kubectl label node worker-2 node-role.kubernetes.io/worker= --overwrite
```

Smoke test (delete when done):

```bash
kubectl create deployment ping --image=nginx:1.27-alpine --replicas=3
kubectl get pods -o wide
kubectl delete deployment ping
```

## Tear down workers (control plane stays)

```bash
sudo lxc exec worker-1 -- microk8s leave || true
sudo lxc exec worker-2 -- microk8s leave || true
sudo microk8s remove-node worker-1 || true
sudo microk8s remove-node worker-2 || true
sudo lxc delete --force worker-1 worker-2
```

## Remove MicroK8s entirely

```bash
sudo snap remove microk8s --purge
sudo snap remove lxd --purge
```
