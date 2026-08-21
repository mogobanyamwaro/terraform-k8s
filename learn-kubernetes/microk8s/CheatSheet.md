# MicroK8s + LXD cheat sheet

Open a **new terminal** after reboot so `microk8s` / `lxd` groups and `/snap/bin` are on PATH. If `lxc` says permission denied, prefix with `sudo`.

## Cluster health

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
microk8s status
```

`k` is aliased to `kubectl` in `~/.zshrc`.

## Enter a node

Control plane = this WSL session.

```bash
# workers (LXD VMs)
sudo lxc list
sudo lxc exec worker-1 -- bash
sudo lxc exec worker-2 -- bash
exit          # leave the VM, back to WSL
```

Inside a worker you are `root`. Useful there:

```bash
hostname
microk8s status
ip -4 addr
```

One-off command without an interactive shell:

```bash
sudo lxc exec worker-1 -- hostname
```

If `lxc` works without sudo, your session has the `lxd` group. `newgrp lxd` or a new login also fixes it.

## Start / stop workers

```bash
sudo lxc stop worker-1 worker-2
sudo lxc start worker-1 worker-2
sudo lxc list
```

VMs are set `boot.autostart=true`, so they should come back after WSL restarts. Give them a minute, then `kubectl get nodes`.

## Workloads

The control plane **is schedulable**. A 3-replica Deployment can land on all three nodes.

Workloads only on workers:

```bash
kubectl taint nodes ggt-pw0ml1f4 node-role.kubernetes.io/control-plane=:NoSchedule
# undo
kubectl taint nodes ggt-pw0ml1f4 node-role.kubernetes.io/control-plane=:NoSchedule-
```

Replace `ggt-pw0ml1f4` with whatever `kubectl get nodes` shows for the control-plane role.

## Addons

```bash
microk8s status
microk8s enable ingress
microk8s enable metrics-server
microk8s enable dashboard
```

Already on: `dns`, `helm`, `hostpath-storage`.

`hostpath-storage` only works on the node where it is enabled (the control plane). PVCs that bind here will not magically appear on workers.

## Networking notes (WSL + Docker + LXD)

Workers sit on LXD bridge `lxdbr0` (`10.66.172.0/24`). The control plane is reachable from them at `10.66.172.1`.

Docker sets `FORWARD` policy to **DROP**. If workers cannot pull images or reach the internet after a reboot:

```bash
sudo iptables -I DOCKER-USER -i lxdbr0 -j ACCEPT
sudo iptables -I DOCKER-USER -o lxdbr0 -j ACCEPT
```

ICMP to `8.8.8.8` may fail even when HTTPS works. Test with `curl -I https://api.snapcraft.io` from inside a VM.

## What the words mean

| Term | Here |
| --- | --- |
| MicroK8s | Kubernetes as a snap on each machine |
| LXD | Daemon that owns the extra machines |
| `lxc` | CLI for LXD (`list`, `exec`, `start`, `stop`) |
| LXC | Older name for Linux containers; our workers are **VMs**, still managed with `lxc` |
| `microk8s kubectl` | Same API as `kubectl` if kubeconfig is set |

## If a worker is NotReady

```bash
kubectl describe node worker-1
sudo lxc list
sudo lxc exec worker-1 -- microk8s status
sudo lxc exec worker-1 -- journalctl -u snap.microk8s.daemon-kubelite -n 50
```
