# 17. Remove Dangerous HostPath Runtime Socket Mounts

**Domain:** System Hardening

## Question

A pod in namespace `cks-17` mounts `/var/run/containerd/containerd.sock` from the host. Remove the hostPath mount and redeploy the workload safely.

## Answer

Find pods using hostPath:

```bash
kubectl get pods -n cks-17 -o yaml | grep -n "hostPath\\|containerd.sock\\|docker.sock"
```

Inspect the workload owner:

```bash
kubectl get pod -n cks-17 -o wide
kubectl describe pod <pod-name> -n cks-17
```

If the pod is managed by a Deployment:

```bash
kubectl get pod <pod-name> -n cks-17 -o jsonpath='{.metadata.ownerReferences[0].name}'; echo
kubectl get deployment <deployment-name> -n cks-17 -o yaml > workload.yaml
```

Remove the dangerous volume:

```yaml
volumes:
- name: runtime-sock
  hostPath:
    path: /var/run/containerd/containerd.sock
```

Remove the matching mount:

```yaml
volumeMounts:
- name: runtime-sock
  mountPath: /var/run/containerd/containerd.sock
```

Add a safer container security context:

```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
  seccompProfile:
    type: RuntimeDefault
```

Apply:

```bash
kubectl apply -f workload.yaml
kubectl rollout status deployment/<deployment-name> -n cks-17
```

## Verify

```bash
kubectl get deployment <deployment-name> -n cks-17 -o yaml | grep -n "hostPath\\|containerd.sock\\|docker.sock"
```

Expected: no output.

## Exam tips

- Mounting the container runtime socket can allow container escape or host control.
- Fix the controller template, not only the live pod.
- HostPath mounts are usually blocked by the Restricted Pod Security Standard.

