# 30. Investigate Secret Access In Audit Logs

**Domain:** Monitoring, Logging, and Runtime Security

## Question

Find who accessed Secret `db-password` in namespace `prod` using API server audit logs.

## Answer

Find the audit log path from the API server manifest:

```bash
sudo grep audit-log-path /etc/kubernetes/manifests/kube-apiserver.yaml
```

Common path:

```text
/var/log/kubernetes/audit/audit.log
```

Search for the Secret:

```bash
sudo grep '"resource":"secrets"' /var/log/kubernetes/audit/audit.log | grep '"name":"db-password"'
```

If `jq` is available:

```bash
sudo grep '"name":"db-password"' /var/log/kubernetes/audit/audit.log | jq '.user.username, .verb, .objectRef.namespace, .objectRef.name, .stageTimestamp'
```

Look for fields:

```text
user.username
verb
objectRef.resource
objectRef.namespace
objectRef.name
sourceIPs
userAgent
stageTimestamp
```

If the task asks you to write the answer:

```bash
sudo grep '"name":"db-password"' /var/log/kubernetes/audit/audit.log > /opt/secret-access.log
```

## Verify

Open the saved output:

```bash
sudo head /opt/secret-access.log
```

Confirm it contains:

```text
"namespace":"prod"
"resource":"secrets"
"name":"db-password"
```

## Exam tips

- Audit events are JSON lines.
- `get`, `list`, and `watch` can all expose Secret data depending on policy level and access pattern.
- The username may be a human, ServiceAccount, or kubelet identity.

