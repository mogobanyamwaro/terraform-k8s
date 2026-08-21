# 10. Encrypt Secrets At Rest

**Domain:** Cluster Hardening

## Question

Configure Kubernetes to encrypt Secret resources at rest using an `aescbc` encryption provider.

## Answer

Generate a 32-byte key:

```bash
head -c 32 /dev/urandom | base64
```

Create the encryption configuration on the control plane:

```bash
sudo mkdir -p /etc/kubernetes/enc
sudo vi /etc/kubernetes/enc/encryption-config.yaml
```

Example:

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: REPLACE_WITH_BASE64_KEY
  - identity: {}
```

Backup API server manifest:

```bash
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml.bak
```

Edit API server:

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Add command flag:

```yaml
- --encryption-provider-config=/etc/kubernetes/enc/encryption-config.yaml
```

Add volume mount:

```yaml
volumeMounts:
- mountPath: /etc/kubernetes/enc
  name: encryption-config
  readOnly: true
```

Add volume:

```yaml
volumes:
- hostPath:
    path: /etc/kubernetes/enc
    type: DirectoryOrCreate
  name: encryption-config
```

Wait for the API server to restart:

```bash
kubectl get nodes
```

Rewrite existing Secrets so they are encrypted with the new provider:

```bash
kubectl get secrets -A -o json | kubectl replace -f -
```

## Verify

Create a test Secret:

```bash
kubectl create namespace cks-10
kubectl create secret generic topsecret -n cks-10 --from-literal=password=supersecret
```

Check etcd directly on the control plane:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/cks-10/topsecret
```

Expected: the output should include an encrypted prefix like `k8s:enc:aescbc:v1:key1` and should not show plaintext `supersecret`.

## Exam tips

- The `identity` provider should be last so Kubernetes can still read unencrypted old data.
- New writes are encrypted after the API server flag is active.
- Existing objects need to be rewritten.

