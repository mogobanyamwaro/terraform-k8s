# Topic 10: Jobs & CronJobs

## What You'll Learn

- **Job** – run to completion (not continuously)
- **CronJob** – schedule Jobs (cron syntax)
- `restartPolicy: OnFailure` for Jobs

## Steps

### 1. Apply Job

```bash
kubectl apply -f job.yaml
kubectl get jobs
kubectl get pods
kubectl logs job/my-job
```

### 2. Apply CronJob

```bash
kubectl apply -f cronjob.yaml
kubectl get cronjobs
# Wait ~1 min, then:
kubectl get jobs
```

---

## Exam Tips

| restartPolicy | Job use            |
| ------------- | ------------------ |
| Never         | Don't restart      |
| OnFailure     | Restart on failure |

## Practice

1. Create a Job that runs 3 completions with parallelism 2.
