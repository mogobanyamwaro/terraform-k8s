# 31. Contain A Compromised Workload

**Domain:** Monitoring, Logging, and Runtime Security

## Question

A pod `api-5f8d7c` in namespace `prod` is suspected compromised. Contain it quickly, preserve basic evidence, and prevent the controller from starting new replicas.

## Answer

Record current state:

```bash
kubectl get pod api-5f8d7c -n prod -o wide
kubectl describe pod api-5f8d7c -n prod | sudo tee  /opt/api-5f8d7c-describe.txt
kubectl logs api-5f8d7c -n prod --all-containers | sudo tee  /opt/api-5f8d7c-logs.txt
kubectl get pod api-5f8d7c -n prod -o yaml | sudo tee /opt/api-5f8d7c.yaml
```

Identify owner:

```bash
kubectl get pod api-5f8d7c -n prod -o jsonpath='{.metadata.ownerReferences[0].kind}{" "}{.metadata.ownerReferences[0].name}{"\n"}'
```

Scale down the controller if it is a Deployment:

```bash
kubectl scale deployment api -n prod --replicas=0
```

If the task asks for network containment instead of deletion, apply a deny-all policy to pods with the compromised label:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-api
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress
```

Apply:

```bash
kubectl apply -f isolate-api.yaml
```

If the node itself is suspicious, cordon it:

```bash
NODE=$(kubectl get pod api-5f8d7c -n prod -o jsonpath='{.spec.nodeName}')
kubectl cordon $NODE
```

Delete the pod only if the task asks you to terminate it:

```bash
kubectl delete pod api-5f8d7c -n prod
```

## Verify

```bash
kubectl get deployment api -n prod
kubectl get networkpolicy isolate-api -n prod
kubectl get nodes
ls -l /opt/api-5f8d7c*
```

## Exam tips

- Preserve evidence before deleting.
- Scale down controllers or pods return immediately.
- NetworkPolicy isolation is useful when you need containment without losing runtime state.
- Cordon stops new scheduling on a node; it does not evict existing pods.

