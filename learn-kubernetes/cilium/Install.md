# Install Deep Dive

```bash
cilium install --set kubeProxyReplacement=true
cilium status --wait
cilium connectivity test
cilium uninstall
helm install cilium cilium/cilium -n kube-system
```

One CNI. kind: `disableDefaultCNI: true`. kube-proxy-free: `kubeProxyMode: none`.

Kernel + privileges + BPF fs.

See `17.md`–`18.md`, `Lab-Setup.md`.
