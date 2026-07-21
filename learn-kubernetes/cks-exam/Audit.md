# Audit Logging CKS Notes

Audit logs answer security questions like:

- Who accessed a Secret?
- Who deleted a pod?
- Which ServiceAccount created a Deployment?
- What source IP or user agent made the request?

## Common API Server Flags

```yaml
- --audit-policy-file=/etc/kubernetes/audit/policy.yaml
- --audit-log-path=/var/log/kubernetes/audit/audit.log
- --audit-log-maxage=30
- --audit-log-maxbackup=10
- --audit-log-maxsize=100
```

The policy file and log directory must be mounted into the API server static pod.

## Minimal Policy

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  resources:
  - group: ""
    resources: ["secrets"]
- level: Request
  verbs: ["create", "update", "patch", "delete"]
- level: Metadata
```

## Levels

| Level | Meaning |
| --- | --- |
| `None` | Do not log matching events |
| `Metadata` | Log user, verb, resource, namespace, timestamp |
| `Request` | Include request object |
| `RequestResponse` | Include request and response object |

Use `Metadata` for Secrets unless a task explicitly asks for more. Higher levels can expose sensitive data.

## Find Secret Access

```bash
sudo grep '"resource":"secrets"' /var/log/kubernetes/audit/audit.log
sudo grep '"name":"db-password"' /var/log/kubernetes/audit/audit.log
```

With `jq`:

```bash
sudo grep '"name":"db-password"' /var/log/kubernetes/audit/audit.log | jq '.user.username, .verb, .objectRef, .sourceIPs, .stageTimestamp'
```

## Find Deletes

```bash
sudo grep '"verb":"delete"' /var/log/kubernetes/audit/audit.log
```

Filter pods:

```bash
sudo grep '"verb":"delete"' /var/log/kubernetes/audit/audit.log | grep '"resource":"pods"'
```

## Find A ServiceAccount

ServiceAccount usernames look like:

```text
system:serviceaccount:<namespace>:<serviceaccount>
```

Search:

```bash
sudo grep 'system:serviceaccount:prod:api' /var/log/kubernetes/audit/audit.log
```

## Static Pod Volume Mounts

API server container:

```yaml
volumeMounts:
- mountPath: /etc/kubernetes/audit
  name: audit-policy
  readOnly: true
- mountPath: /var/log/kubernetes/audit
  name: audit-log
```

Pod volumes:

```yaml
volumes:
- name: audit-policy
  hostPath:
    path: /etc/kubernetes/audit
    type: DirectoryOrCreate
- name: audit-log
  hostPath:
    path: /var/log/kubernetes/audit
    type: DirectoryOrCreate
```

## Exam tips

- Audit log entries are JSON lines.
- Always check the API server manifest for the real path.
- If the API server fails after editing, use `sudo crictl ps` and restore the backup manifest.

