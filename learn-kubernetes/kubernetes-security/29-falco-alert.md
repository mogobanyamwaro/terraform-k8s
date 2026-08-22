# 29. Investigate A Falco Runtime Alert

**Domain:** Monitoring, Logging, and Runtime Security

## Question

Falco reports that a shell was spawned in a container. Identify the pod, inspect the activity, and stop the workload.

## Answer

Find Falco pods:

```bash
kubectl get pods -A | grep falco
```

Check Falco logs:

```bash
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100
```

If labels differ:

```bash
kubectl get pods -A | grep -i falco
kubectl logs -n <falco-namespace> <falco-pod> --tail=100
```

Example alert fields to capture:

```text
user.name
k8s.ns.name
k8s.pod.name
container.image.repository
proc.cmdline
```

Inspect the pod:

```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --all-containers
kubectl get pod <pod-name> -n <namespace> -o yaml
```

If the pod is suspicious, scale down its controller:

```bash
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.metadata.ownerReferences[0].kind}{" "}{.metadata.ownerReferences[0].name}{"\n"}'
kubectl scale deployment <deployment-name> -n <namespace> --replicas=0
```

If it is a standalone pod:

```bash
kubectl delete pod <pod-name> -n <namespace>
```

## Verify

```bash
kubectl get pods -n <namespace>
kubectl logs -n <falco-namespace> <falco-pod> --tail=20
```

## Exam tips

- Read the exact Falco log line; it usually contains namespace and pod name.
- Stop the controller, not only the pod, or the pod may be recreated.
- Capture evidence before deleting if the task asks for investigation output.
---
Absolutely. Here is the complete process we followed, including how to add custom Falco rules.

# Falco Runtime Security Testing on Kubernetes

## 1. Environment

Our setup was:

```text
WSL2
  │
  ▼
Docker
  │
  ▼
k3d Kubernetes Cluster
  │
  ├── Kubernetes Nodes
  │      │
  │      └── Falco DaemonSet
  │
  └── test/app Pod
          │
          └── nginx:1.28
```

The test pod was:

```bash
k get pods -n test
```

Example:

```text
NAME   READY   STATUS    RESTARTS   AGE
app    1/1     Running   0          7m
```

The pod was running on:

```text
k3d-dev-cluster-agent-0
```

---

# 2. Install Falco

Add the Falco Helm repository:

```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
```

Install Falco:

```bash
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace
```

Check the Falco pods:

```bash
k get pods -n falco
```

Initially, the Falco pods were failing with:

```text
CrashLoopBackOff
```

Checking the logs showed:

```bash
k logs -n falco <falco-pod-name>
```

The important error was:

```text
Error: could not initialize inotify handler
```

---

# 3. Fix the inotify issue

Check the current limits:

```bash
cat /proc/sys/fs/inotify/max_user_instances
cat /proc/sys/fs/inotify/max_user_watches
```

Increase them temporarily:

```bash
sudo sysctl -w fs.inotify.max_user_instances=1024
sudo sysctl -w fs.inotify.max_user_watches=524288
```

To make the configuration persistent, create:

```bash
sudo tee /etc/sysctl.d/99-inotify.conf > /dev/null <<'EOF'
fs.inotify.max_user_instances=1024
fs.inotify.max_user_watches=524288
EOF
```

Apply the configuration:

```bash
sudo sysctl --system
```

Verify:

```bash
sysctl fs.inotify.max_user_instances
sysctl fs.inotify.max_user_watches
```

Expected:

```text
fs.inotify.max_user_instances = 1024
fs.inotify.max_user_watches = 524288
```

After this, Falco was running successfully:

```bash
k get pods -n falco
```

Example:

```text
NAME          READY   STATUS    RESTARTS
falco-kmr5j   2/2     Running   0
falco-qw86q   2/2     Running   0
falco-xbggq   2/2     Running   0
falco-z79mk   2/2     Running   0
```

---

# 4. Understand why there are multiple Falco pods

Falco runs as a **DaemonSet**.

That means Kubernetes runs one Falco pod on each node.

Check:

```bash
k get nodes
```

Then:

```bash
k get pods -n falco -o wide
```

Example:

```text
FALCO POD       NODE
falco-kmr5j     k3d-dev-cluster-agent-0
falco-qw86q     k3d-dev-cluster-agent-1
falco-xbggq     k3d-dev-cluster-agent-2
falco-z79mk     k3d-dev-cluster-server-0
```

Your application pod was running on:

```text
k3d-dev-cluster-agent-0
```

Therefore, the important Falco pod was the one running on the same node.

---

# 5. Watch Falco runtime events

First, identify the Falco pod running on the same node as your application:

```bash
k get pods -n falco -o wide
```

Then watch its logs:

```bash
k logs -n falco <falco-pod-name> -c falco -f
```

For example:

```bash
k logs -n falco falco-kmr5j -c falco -f
```

Leave this terminal running.

---

# 6. Trigger a runtime event

In another terminal, execute a shell inside the application container:

```bash
k exec -n test -it app -- /bin/sh
```

This causes a process to be spawned inside the container.

Falco observes this runtime behavior:

```text
kubectl exec
     │
     ▼
Kubernetes API
     │
     ▼
Kubelet
     │
     ▼
containerd
     │
     ▼
/bin/sh starts inside container
     │
     ▼
Kernel event
     │
     ▼
Falco captures event
     │
     ▼
Falco rule matches
     │
     ▼
🚨 ALERT
```

Falco successfully detected the shell being spawned inside the container.

---

# 7. How to add custom Falco rules

The best practice is **not to modify the default Falco rules directly**.

Instead, add your own rules in a custom rules file.

With the Helm installation, you can provide custom rules through the Helm values.

First, see your current Helm values:

```bash
helm get values falco -n falco
```

Create a file called:

```text
falco-values.yaml
```

Add custom rules:

```yaml
customRules:
  custom-rules.yaml: |-
    - rule: Detect Write To Falco Test Directory
      desc: Detect a process writing to /tmp/falco-test
      condition: >
        evt.type in (open, openat, openat2) and
        evt.is_open_write=true and
        fd.name startswith /tmp/falco-test
      output: >
        Falco test directory was modified
        (user=%user.name
        command=%proc.cmdline
        file=%fd.name
        container=%container.name
        pod=%k8s.pod.name
        namespace=%k8s.ns.name)
      priority: WARNING
```

Then upgrade the Falco release:

```bash
helm upgrade falco falcosecurity/falco \
  -n falco \
  -f falco-values.yaml
```

Check whether the Falco pods restart:

```bash
k get pods -n falco -w
```

---

# 8. Trigger your custom rule

Create the test directory inside your application pod:

```bash
k exec -n test app -- mkdir -p /tmp/falco-test
```

Then write a file:

```bash
k exec -n test app -- sh -c 'echo "hello" > /tmp/falco-test/test.txt'
```

Falco should generate an alert similar to:

```text
Warning Falco test directory was modified
```

The alert should include information such as:

```text
user=root
command=sh -c echo "hello" > /tmp/falco-test/test.txt
file=/tmp/falco-test/test.txt
container=app
pod=app
namespace=test
```

---

# 9. Understanding a Falco rule

A Falco rule has these main parts:

```yaml
- rule: Detect Write To Falco Test Directory
```

The rule name.

```yaml
desc: Detect a process writing to /tmp/falco-test
```

A description explaining what the rule does.

```yaml
condition: >
  evt.type in (open, openat, openat2) and
  evt.is_open_write=true and
  fd.name startswith /tmp/falco-test
```

This is the detection logic.

In simple English:

> If a process opens a file for writing, and the file is inside `/tmp/falco-test`, trigger the rule.

```yaml
output: >
  Falco test directory was modified
```

This defines the alert message.

You can include Falco fields such as:

```text
%user.name
%proc.cmdline
%fd.name
%container.name
%k8s.pod.name
%k8s.ns.name
```

Finally:

```yaml
priority: WARNING
```

This defines the severity.

Common priorities include:

```text
EMERGENCY
ALERT
CRITICAL
ERROR
WARNING
NOTICE
INFORMATIONAL
DEBUG
```

---

# 10. The complete Falco rule lifecycle

```text
Application Pod
      │
      │ Process performs an action
      │
      ▼
Linux Kernel Event
      │
      ▼
Falco Event Source
      │
      ▼
Falco receives event
      │
      ▼
Evaluate condition
      │
      ├── Condition false
      │       └── Ignore event
      │
      └── Condition true
              │
              ▼
          Generate alert
              │
              ▼
        stdout / logs / webhook / SIEM
```

## Important takeaway

Falco is primarily a **detection tool**, not a prevention tool.

For example:

```text
AppArmor / Seccomp
        ↓
Can restrict or block an action

Falco
        ↓
Observes the action and generates an alert
```

So your Kubernetes security layers can look like:

```text
Image scanning
     ↓
Trivy
     ↓
Admission control
     ↓
Kyverno
     ↓
Runtime restrictions
     ↓
AppArmor + Seccomp
     ↓
Runtime detection
     ↓
Falco
     ↓
Alerts / Monitoring / SIEM
```

This gives you a complete hands-on workflow: **deploy Falco → monitor the node → trigger an event in a pod → see the alert → add your own rule → trigger the custom alert**.


