Jobs run one or more pods to completion. Unlike Deployments (which keep pods running indefinitely), Jobs don't restart failed pods by default — they just retry. CronJobs schedule Jobs to run on a schedule, like cron in Linux.

On the exam, you'll create both and understand backoff limits, completions, and restart policies. The questions are straightforward: create a job that runs a script to completion, handle failures, maybe schedule it for later.

---

## Tasks

1. Create a Job named `cleanup-job` that runs the image `busybox:1.37` with command `echo "Cleanup complete"`. Set it to run 3 times (completions=3) serially (parallelism=1).

2. Verify the Job runs to completion (status should show 3/3). Check the pod logs.

3. Create a CronJob named `hourly-backup` that runs `backup-script.sh` every hour. Use the same busybox image. Let it keep 3 successful job histories (successfulJobsHistoryLimit=3).

4. List CronJobs and check the next scheduled time.

5. Manually trigger the CronJob once (create a Job from it).

6. Verify the manual Job ran and logged output.

---

Here's the **best way** to tackle Jobs and CronJobs on the CKA exam – this tests run-to-completion workloads.

---

## Part 1: Job

### 1. Create Job named cleanup-job

**Create Job with completions=3, parallelism=1:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: cleanup-job
spec:
  completions: 3
  parallelism: 1
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: cleanup
        image: busybox:1.37
        command: ["echo", "Cleanup complete"]
EOF
```

**Verify Job creation:**

```bash
kubectl get jobs
```

**Watch Job progress:**

```bash
kubectl get jobs --watch
```

**Describe Job:**

```bash
kubectl describe job cleanup-job
```

---

### 2. Verify Job runs to completion (3/3) and check logs

**Check Job status:**

```bash
kubectl get job cleanup-job
```

**Expected output:** `COMPLETIONS` shows `3/3`

**List pods created by the Job:**

```bash
kubectl get pods -l job-name=cleanup-job
```

**Check logs of each pod:**

```bash
# Get all pods from the job and show logs
for pod in $(kubectl get pods -l job-name=cleanup-job -o name); do
  echo "=== $pod ==="
  kubectl logs $pod
done
```

**Expected output:** Each pod logs `Cleanup complete`

**Alternative – check specific pod:**

```bash
kubectl logs $(kubectl get pods -l job-name=cleanup-job -o name | head -1)
```

**Check Job details:**

```bash
kubectl describe job cleanup-job | grep -A5 "Status"
```

---

## Part 2: CronJob

### 3. Create CronJob named hourly-backup

```bash
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hourly-backup
spec:
  schedule: "0 * * * *"
  successfulJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: backup
            image: busybox:1.37
            command: ["/bin/sh", "-c", "echo 'Backup completed at $(date)'"]
EOF
```

**Verify CronJob creation:**

```bash
kubectl get cronjob
```

**Check CronJob details:**

```bash
kubectl describe cronjob hourly-backup
```

---

### 4. List CronJobs and check next scheduled time

**List CronJobs:**

```bash
kubectl get cronjobs
```

**Check next scheduled time:**

```bash
kubectl get cronjob hourly-backup -o jsonpath='{.status.nextScheduleTime}'
```

**Detailed CronJob info:**

```bash
kubectl describe cronjob hourly-backup | grep -E "Schedule|Next Scheduled"
```

**View CronJob YAML:**

```bash
kubectl get cronjob hourly-backup -o yaml | grep -A5 schedule
```

---

### 5. Manually trigger the CronJob once

**Create a Job from the CronJob:**

```bash
kubectl create job --from=cronjob/hourly-backup manual-backup
```

**Alternative syntax:**

```bash
kubectl create job manual-backup --from=cronjob/hourly-backup
```

**Verify manual Job was created:**

```bash
kubectl get jobs | grep manual-backup
```

---

### 6. Verify the manual Job ran and logged output

**Check Job status:**

```bash
kubectl get job manual-backup
```

**Expected:** `COMPLETIONS` shows `1/1`

**Get pod from manual Job:**

```bash
kubectl get pods -l job-name=manual-backup
```

**Check logs:**

```bash
kubectl logs job/manual-backup
```

**Expected output:** `Backup completed at (current date/time)`

**Alternative – get logs directly:**

```bash
kubectl logs $(kubectl get pods -l job-name=manual-backup -o name)
```

**Verify both Jobs exist:**

```bash
kubectl get jobs
```

---

## Quick Verification Commands

```bash
echo "=== Jobs ==="
kubectl get jobs

echo -e "\n=== CronJobs ==="
kubectl get cronjobs

echo -e "\n=== Job Pods and Logs ==="
for pod in $(kubectl get pods -l job-name=cleanup-job -o name); do
  echo "--- $(basename $pod) ---"
  kubectl logs $pod 2>/dev/null || echo "Pod not ready yet"
done

echo -e "\n=== Manual Job Logs ==="
kubectl logs job/manual-backup 2>/dev/null || echo "Job not completed yet"

echo -e "\n=== Next CronJob Schedule ==="
kubectl get cronjob hourly-backup -o jsonpath='{.status.nextScheduleTime}'
echo ""

echo -e "\n=== Job History ==="
kubectl get cronjob hourly-backup -o yaml | grep -A5 "status:"
```

---

## Job Parameters Explained

| Parameter                 | Purpose                          | Example                      |
| ------------------------- | -------------------------------- | ---------------------------- |
| `completions`             | Number of successful pods        | `3`                          |
| `parallelism`             | How many pods run simultaneously | `1` (serial), `3` (parallel) |
| `backoffLimit`            | Number of retry attempts         | `6` (default)                |
| `activeDeadlineSeconds`   | Max runtime for Job              | `100` seconds                |
| `ttlSecondsAfterFinished` | Auto-cleanup after completion    | `3600` seconds               |

---

## Job Examples for Exam

### Parallel Job (multiple completions at once)

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-job
spec:
  completions: 5
  parallelism: 3
  template:
    spec:
      containers:
        - name: worker
          image: busybox:1.37
          command: ["sh", "-c", "sleep 2; echo Done"]
      restartPolicy: Never
```

### Indexed Job (each pod gets unique index)

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: indexed-job
spec:
  completions: 3
  parallelism: 1
  completionMode: Indexed
  template:
    spec:
      containers:
        - name: worker
          image: busybox:1.37
          command: ["sh", "-c", "echo 'Pod index: $JOB_COMPLETION_INDEX'"]
      restartPolicy: Never
```

### Job with backoff limit

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: retry-job
spec:
  backoffLimit: 3
  template:
    spec:
      containers:
        - name: tester
          image: busybox:1.37
          command: ["sh", "-c", "exit 1"] # Will fail, retry 3 times
      restartPolicy: Never
```

### Job that runs a script

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: script-job
spec:
  template:
    spec:
      containers:
        - name: runner
          image: busybox:1.37
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "Starting script"
              for i in 1 2 3; do
                echo "Iteration $i"
                sleep 1
              done
              echo "Script complete"
      restartPolicy: OnFailure
```

---

## CronJob Schedule Syntax

| Schedule       | Meaning                  |
| -------------- | ------------------------ |
| `0 * * * *`    | Every hour at minute 0   |
| `*/5 * * * *`  | Every 5 minutes          |
| `0 2 * * *`    | Daily at 2 AM            |
| `0 0 * * 0`    | Weekly on Sunday         |
| `30 3 * * 1-5` | Monday-Friday at 3:30 AM |
| `0 0 1 * *`    | First day of every month |

**Schedule format:**

```
minute (0-59)
|  hour (0-23)
|  |  day of month (1-31)
|  |  |  month (1-12)
|  |  |  |  day of week (0-6, Sunday=0)
*  *  *  *  *
```

---

## CronJob Parameters

| Parameter                    | Purpose                       | Default  |
| ---------------------------- | ----------------------------- | -------- |
| `schedule`                   | Cron schedule string          | Required |
| `successfulJobsHistoryLimit` | Successful Jobs to retain     | 3        |
| `failedJobsHistoryLimit`     | Failed Jobs to retain         | 1        |
| `startingDeadlineSeconds`    | Max delay for missed schedule | None     |
| `concurrencyPolicy`          | Allow/Forbid/Replace          | Allow    |
| `suspend`                    | Pause scheduling              | false    |

**Concurrency policies:**

- `Allow` – Run concurrently (default)
- `Forbid` – Skip if previous still running
- `Replace` – Kill previous, start new

---

## Common Exam Traps

| Trap                                     | Consequence             | Fix                                  |
| ---------------------------------------- | ----------------------- | ------------------------------------ |
| No `restartPolicy: Never` or `OnFailure` | Pod stays in error      | Always set restartPolicy             |
| Missing completions                      | Only 1 pod runs         | Set completions if you need multiple |
| Wrong schedule format                    | CronJob never triggers  | Use proper cron syntax               |
| Forgetting `--from=cronjob/`             | Can't create manual Job | Use correct syntax                   |
| No logs command                          | Can't verify success    | `kubectl logs job/<job-name>`        |
| `parallelism > completions`              | Wasted resources        | Keep parallelism ≤ completions       |

---

## Job Lifecycle

```
Create Job
    ↓
Job creates pod(s)
    ↓
Pod runs to completion
    ↓
Pod status = Completed
    ↓
Job counts completion
    ↓
Status = completions/N
    ↓
All completions done → Job finished
```

---

## Pro Tips for CKA

1. **Always set `restartPolicy: Never`** – Jobs aren't Deployments
2. **Use `kubectl logs job/<name>`** – Works even after pod removed
3. **Test CronJob schedule with `--dry-run=client`** – Validate syntax
4. **Manual trigger is a Job** – `kubectl create job --from=cronjob/...`
5. **Jobs auto-cleanup with TTL** – `ttlSecondsAfterFinished: 3600`
6. **Check pod logs even after completion** – Pods persist unless deleted
7. **`completions` vs `parallelism`** – Completions = total, parallelism = simultaneous

---

## Troubleshooting

**Job stuck in progress:**

```bash
kubectl describe job cleanup-job
kubectl get pods -l job-name=cleanup-job
kubectl logs <pod-name>
```

**CronJob not running:**

```bash
kubectl describe cronjob hourly-backup
kubectl get jobs --selector=job-name=hourly-backup
# Check if suspended
kubectl get cronjob hourly-backup -o yaml | grep suspend
```

**Manual Job creation fails:**

```bash
# Ensure CronJob exists
kubectl get cronjob hourly-backup

# Use correct syntax
kubectl create job manual-backup --from=cronjob/hourly-backup
```

**Pod restarts constantly:**

```bash
# Check restartPolicy
kubectl get job cleanup-job -o yaml | grep restartPolicy
# Should be Never or OnFailure, not Always
```

---

**Total exam time for this task:** ~4-5 minutes

**Most likely exam scenario:** Create a Job that runs multiple times, create a CronJob on a schedule, then manually trigger it. They may also test understanding of backoff limits and restart policies.
