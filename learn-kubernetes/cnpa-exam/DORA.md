# DORA and Platform Measurement

## Four keys

1. **Deployment frequency** — how often you ship to prod (up).  
2. **Lead time for changes** — commit to prod (down).  
3. **Change failure rate** — % of deploys that cause failure (down).  
4. **Time to restore service** — MTTR (down).

## Platform levers (memorise one each)

| Key | Lever |
| --- | --- |
| Frequency | Self-service GitOps, small PRs |
| Lead time | Fast CI, no ticket wait, preview envs |
| Failures | Tests, scan, canary, policy, build-once |
| Restore | OTel, revert, abort, IR, status page |

## Not DORA

Tool count, YAML LOC, “installed Grafana.”

## SPACE

Satisfaction, Performance, Activity, Communication/collaboration, Efficiency. Broader **developer** productivity; DORA is **delivery** performance.

## Misuse

Ranking teams to punish. Gaming deploys. Ignoring that **your queue** is their lead time.
