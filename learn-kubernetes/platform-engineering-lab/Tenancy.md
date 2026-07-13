# Tenancy (Exam)

| Object | Job |
| --- | --- |
| Namespace | Boundary |
| ResourceQuota | Cap |
| LimitRange | Defaults/max |
| NetworkPolicy | East-west |
| PSS labels | Pod hardening |
| Role/RoleBinding | Human access |
| PriorityClass | Noisy neighbor (rare) |

Restricted PSS + stock `nginx` often fails. Use `runAsNonRoot` + non-root image or the task’s allowed image.

Quota without requests → pods may fail to schedule/count. Pair LimitRange.
