# Local MicroK8s cluster (WSL)

This WSL Ubuntu box runs a **3-node MicroK8s** cluster:

| Kubernetes node | What it actually is | How you get a shell |
| --- | --- | --- |
| `ggt-pw0ml1f4` (name follows the WSL hostname) | This WSL distro — **control plane** | You are already on it |
| `worker-1` | LXD Ubuntu **VM** | `sudo lxc exec worker-1 -- bash` |
| `worker-2` | LXD Ubuntu **VM** | `sudo lxc exec worker-2 -- bash` |

`kubectl` on this machine talks to the whole cluster. You do **not** install a second Kubernetes on the workers; they joined this one with `microk8s join ... --worker`.

Start here next time: [CheatSheet.md](./CheatSheet.md). Rebuild from scratch: [Lab-Setup.md](./Lab-Setup.md).
