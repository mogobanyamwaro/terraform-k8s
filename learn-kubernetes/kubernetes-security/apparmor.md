# AppArmor CKS Notes

AppArmor confines what a process can do at the Linux kernel level. In CKS tasks, it usually appears as:

- Load a profile on a node.
- Make a pod use that profile.
- Verify that the profile blocks a specific action.

## Quick Commands

Check if AppArmor is enabled:

```bash
sudo aa-status
```

Load a profile:

```bash
sudo apparmor_parser -q /etc/apparmor.d/<profile-name>
```

Reload a profile:

```bash
sudo apparmor_parser -r /etc/apparmor.d/<profile-name>
```

Check loaded profile:

```bash
sudo aa-status | grep <profile-name>
```

## Example: Deny Writes

Create:

```bash
sudo vi /etc/apparmor.d/deny-write
```

Profile:

```text
#include <tunables/global>

profile deny-write flags=(attach_disconnected) {
  #include <abstractions/base>
  file,
  deny /** w,
}
```

Load:

```bash
sudo apparmor_parser -q /etc/apparmor.d/deny-write
```

Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: apparmor-deny-write
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
    securityContext:
      appArmorProfile:
        type: Localhost
        localhostProfile: deny-write
```

Verify:

```bash
kubectl apply -f pod.yaml
kubectl wait --for=condition=Ready pod/apparmor-deny-write --timeout=60s
kubectl exec apparmor-deny-write -- touch /tmp/test
```

Expected: permission denied.

## Example: Runtime Default AppArmor

```yaml
securityContext:
  appArmorProfile:
    type: RuntimeDefault
```

## Older Annotation Style

Some older examples use annotations:

```yaml
metadata:
  annotations:
    container.apparmor.security.beta.kubernetes.io/app: localhost/deny-write
```

Use `securityContext.appArmorProfile` when available.

## Troubleshooting

Pod stuck because profile is missing:

```bash
kubectl describe pod <pod>
```

Fix:

```bash
sudo apparmor_parser -q /etc/apparmor.d/<profile-name>
kubectl delete pod <pod>
kubectl apply -f pod.yaml
```

Pod scheduled to the wrong node:

```bash
kubectl get pod <pod> -o wide
```

Fix by loading the profile on that node, or use `nodeSelector` if the task allows it.

## Exam tips

- AppArmor profiles are node-local.
- A pod cannot use a localhost profile that is not loaded on its node.
- AppArmor is Linux-only.
- Use `kubectl describe pod` for admission and runtime errors.

