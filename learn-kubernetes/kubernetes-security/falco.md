# Falco CKS Notes

Falco detects suspicious runtime behavior from containers and hosts.

Common exam patterns:

- Read Falco alerts.
- Identify namespace, pod, container, and command.
- Stop or isolate the offending workload.
- Adjust a rule or output path if asked.

## Find Falco

```bash
kubectl get pods -A | grep -i falco
kubectl get daemonset -A | grep -i falco
```

Logs:

```bash
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100
```

If labels differ:

```bash
kubectl logs -n <namespace> <falco-pod> --tail=100
```

## Important Alert Fields

Look for:

```text
rule
priority
proc.cmdline
proc.name
user.name
container.id
container.image.repository
k8s.ns.name
k8s.pod.name
k8s.container.name
```

## Scenario: Shell Spawned In Container

Search:

```bash
kubectl logs -n falco -l app.kubernetes.io/name=falco | grep -i "shell"
```

Extract the namespace and pod from the alert, then inspect:

```bash
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --all-containers
kubectl get pod <pod> -n <namespace> -o yaml
```

Scale down owner:

```bash
kubectl get pod <pod> -n <namespace> -o jsonpath='{.metadata.ownerReferences[0].kind}{" "}{.metadata.ownerReferences[0].name}{"\n"}'
kubectl scale deployment <deployment> -n <namespace> --replicas=0
```

## Scenario: Write Below /etc

Search:

```bash
kubectl logs -n falco -l app.kubernetes.io/name=falco | grep -i "/etc"
```

Fix the workload:

```yaml
securityContext:
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
```

Add writable temp storage only where needed:

```yaml
volumes:
- name: tmp
  emptyDir: {}
containers:
- name: app
  volumeMounts:
  - name: tmp
    mountPath: /tmp
```

## Scenario: Unexpected Network Tool

Alerts may mention commands like:

```text
nc
ncat
curl
wget
ssh
```

Contain:

```bash
kubectl scale deployment <deployment> -n <namespace> --replicas=0
```

Or isolate with NetworkPolicy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-suspect
  namespace: <namespace>
spec:
  podSelector:
    matchLabels:
      app: <app>
  policyTypes:
  - Ingress
  - Egress
```

## Exam tips

- Falco alert text usually contains the answer. Read it slowly.
- Preserve logs before deleting pods if the task asks for investigation.
- Stop the controller, not only the pod.
- If Falco runs as a DaemonSet, logs may be on the node where the event happened.

