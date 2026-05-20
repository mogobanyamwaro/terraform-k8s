Create a pod with a main container and a sidecar container that tails the main container's log file. This uses the v1.35 native sidecar container feature (`restartPolicy: Always` on an init container).

## Tasks

1. Create a namespace called `exercise-02`
2. Create a pod named `logger` in namespace `exercise-02` with:
   - An init container (sidecar) named `log-agent` using `busybox:1.36`
     - Set `restartPolicy: Always` on the init container to make it a native sidecar
     - Command: `tail -F /var/log/app/app.log` (capital F waits for file creation)
     - Mount a shared volume at `/var/log/app`
   - A main container named `app` using `busybox:1.36`
     - Command: write a line to `/var/log/app/app.log` every 3 seconds
     - Mount the same shared volume at `/var/log/app`
   - Use an `emptyDir` volume named `log-volume`
3. Verify both containers are running
4. Check the sidecar's logs to see the streamed output

---

Here’s how I’d tackle this **CKA native sidecar** question (v1.35+ feature) – efficient and exam-safe:

---

## 1. Create namespace

```bash
kubectl create namespace exercise-02
```

---

## 2. Create pod YAML with sidecar pattern

```bash
kubectl run logger --image=busybox:1.36 -n exercise-02 --dry-run=client -o yaml > logger.yaml
```

Edit `logger.yaml` completely to:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: logger
  namespace: exercise-02
spec:
  volumes:
    - name: log-volume
      emptyDir: {}

  initContainers:
    - name: log-agent
      image: busybox:1.36
      restartPolicy: Always # This makes it a native sidecar
      command: ["sh", "-c", "tail -F /var/log/app/app.log"]
      volumeMounts:
        - name: log-volume
          mountPath: /var/log/app

  containers:
    - name: app
      image: busybox:1.36
      command:
        [
          "sh",
          "-c",
          "while true; do echo 'Log entry at $(date)' >> /var/log/app/app.log; sleep 3; done",
        ]
      volumeMounts:
        - name: log-volume
          mountPath: /var/log/app
```

Apply:

```bash
kubectl apply -f logger.yaml
```

---

## 3. Verify both containers are running

```bash
kubectl get pod logger -n exercise-02
```

Check container statuses specifically:

```bash
kubectl get pod logger -n exercise-02 -o jsonpath='{.status.containerStatuses[*].name}' && echo
kubectl get pod logger -n exercise-02 -o jsonpath='{.status.initContainerStatuses[*].name}' && echo
```

Better yet:

```bash
kubectl describe pod logger -n exercise-02 | grep -A5 "Init Containers:" | grep State
kubectl describe pod logger -n exercise-02 | grep -A5 "Containers:" | grep State
```

Or quick status view:

```bash
kubectl get pod logger -n exercise-02 -o wide
```

---

## 4. Check sidecar logs (log-agent streaming output)

```bash
kubectl logs logger -n exercise-02 -c log-agent
```

You should see the tail output showing each log line from `app.log` as it's written.

Wait a few seconds and run again:

```bash
kubectl logs logger -n exercise-02 -c log-agent --tail=10
```

---

## 5. Optional – Verify sidecar lifecycle

Check that sidecar runs before main and continues after:

```bash
kubectl get pod logger -n exercise-02 -o json | jq '.status.initContainerStatuses[0].state'
kubectl get pod logger -n exercise-02 -o json | jq '.status.containerStatuses[0].state'
```

---

## Exam critical notes:

| Key point                                | Why it matters                                                                                         |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `restartPolicy: Always` on initContainer | This is the **native sidecar** feature (v1.35+), not a regular container                               |
| `tail -F` (capital F)                    | Waits for file to be created – crucial because app container creates the log file after sidecar starts |
| **Same volume mount** on both            | Sidecar reads what app writes                                                                          |
| EmptyDir                                 | Simple, ephemeral shared volume                                                                        |
| Sidecar logs via `-c`                    | Must specify container name                                                                            |

---

## Troubleshooting in exam:

If sidecar isn't streaming:

```bash
# Check if app is writing logs
kubectl exec -n exercise-02 logger -c app -- cat /var/log/app/app.log

# Check sidecar process
kubectl exec -n exercise-02 logger -c log-agent -- ps aux

# Verify volume mounts
kubectl exec -n exercise-02 logger -c app -- mount | grep log-volume
kubectl exec -n exercise-02 logger -c log-agent -- mount | grep log-volume
```

---

## Time-saving tips:

- **Don't memorize YAML** – start with `run --dry-run`, then heavily edit
- **`restartPolicy` only works on initContainers** (not regular containers) for this feature
- **Use `-F` flag** – common exam trick (many use `-f` and fail)
- **Verify logs quickly** – `kubectl logs -f` might hang, use `--tail=5` instead

Total time ~6-8 minutes for this pattern if you understand the native sidecar concept.
