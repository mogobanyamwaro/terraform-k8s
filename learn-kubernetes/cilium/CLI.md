# Cilium CLI Cheat

```bash
cilium install | uninstall | upgrade
cilium status [--wait]
cilium connectivity test
cilium version
cilium config view | get | set
cilium hubble enable | port-forward | ui
cilium clustermesh enable | status | connect
```

In-agent:

```bash
cilium-dbg status
cilium-dbg endpoint list
cilium-dbg identity list
cilium-dbg bpf lb list
cilium-dbg policy get
```

Hubble:

```bash
hubble status | observe
```

ConfigMap: `kube-system/cilium-config`.
