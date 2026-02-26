# Kubernetes Learning Path (CKA Exam Focused)

Hands-on topics aligned with the Certified Kubernetes Administrator (CKA) exam.

## Prerequisites

- `kubectl` installed
- Cluster access (minikube, kind, EKS, GKE, or AKS)

```bash
# Quick local cluster (minikube)
minikube start

# Or kind
kind create cluster --name cka-practice
```

**microk8s users:** If `kubectl exec` fails with "is not supported anymore", use standalone kubectl with microk8s config: `microk8s config > ~/.kube/config` then use `/opt/homebrew/bin/kubectl` (or your system kubectl).

---

## Topics

| #   | Topic                                            | Folder                         | CKA Domain      |
| --- | ------------------------------------------------ | ------------------------------ | --------------- |
| 1   | **Pods** – Create, inspect, exec                 | topic-01-pods                  | Workloads       |
| 2   | **ReplicaSet & Deployment**                      | topic-02-replicaset-deployment | Workloads       |
| 3   | **Services** – ClusterIP, NodePort, LoadBalancer | topic-03-services              | Networking      |
| 4   | **ConfigMaps & Secrets**                         | topic-04-configmaps-secrets    | Workloads       |
| 5   | **Namespaces & Context**                         | topic-05-namespaces            | Cluster         |
| 6   | **Labels & Selectors**                           | topic-06-labels-selectors      | Workloads       |
| 7   | **Probes** – Liveness, Readiness                 | topic-07-probes                | Workloads       |
| 8   | **PersistentVolumes & Claims**                   | topic-08-storage               | Storage         |
| 9   | **Multi-container Pods**                         | topic-09-multi-container       | Workloads       |
| 10  | **Jobs & CronJobs**                              | topic-10-jobs-cronjobs         | Workloads       |
| 11  | **Networking** – Ingress, NetworkPolicy          | topic-11-networking            | Networking      |
| 12  | **kubectl & Debugging**                          | topic-12-kubectl-debugging     | Troubleshooting |
| 13  | **RBAC** – Role, ClusterRole, RoleBinding        | topic-13-rbac                  | Security        |
| 14  | **Scheduling** – Taints, Tolerations, Affinity   | topic-14-scheduling            | Workloads       |
| 15  | **Cluster Architecture** – kubeadm, etcd         | topic-15-cluster-architecture  | Cluster Arch    |

---

## How to Use

1. `cd` into each topic folder
2. Apply the YAML manifests: `kubectl apply -f .`
3. Run the commands in INSTRUCTIONS.md
4. Complete the practice exercise before moving on

---

## Commands You Must Know (CKA)

```bash
kubectl get pods -A
kubectl describe pod <name>
kubectl logs <pod> -c <container>
kubectl exec <pod> -it -- /bin/sh
kubectl run ... --image=... --restart=Never
kubectl expose ...
kubectl create deployment ...
kubectl scale deployment ...
kubectl edit / kubectl patch
kubectl create role ... --verb=get,list --resource=pods -n <ns>
kubectl create rolebinding ... --role=X --serviceaccount=ns:sa -n <ns>
kubectl taint nodes <node> key=value:NoSchedule
kubectl auth can-i get pods --as=system:serviceaccount:ns:sa
kubeadm init / kubeadm join / kubeadm upgrade
etcdctl snapshot save / restore
```
