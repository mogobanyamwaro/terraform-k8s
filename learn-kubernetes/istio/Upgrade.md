# Upgrade Reference

Two supported methods: **canary (revisioned)** and **in-place**. Canary is the production/exam-preferred path.

## Canary

```bash
# current
istioctl version
kubectl -n istio-system get po -l app=istiod

# install NEW control plane beside the old
istioctl install --set revision=1-29-0 -y

# optional stable tags
istioctl tag set prod-stable --revision default     # or old rev
istioctl tag set prod-canary --revision 1-29-0

# migrate one namespace
kubectl label ns bookinfo istio.io/rev=1-29-0 --overwrite
kubectl label ns bookinfo istio-injection-          # cannot keep both
kubectl -n bookinfo rollout restart deploy

istioctl proxy-status   # proxies should pin to new istiod

# when done
istioctl uninstall --revision default -y
```

Injection: namespaces with `istio-injection=enabled` follow the **default tag**. Revisioned ns use `istio.io/rev`.

Data plane version = sidecar binary injected at **pod creation**. Restart is mandatory to move proxies.

## In-place

```bash
istioctl install -y    # same profile, new binaries, one istiod
kubectl -n istio-system rollout restart deploy/istio-ingressgateway
# still restart workload sidecars to update Envoy
```

Faster, no side-by-side rollback. If new istiod is bad, the mesh control plane is bad.

## Rollback canary

Relabel ns to old revision, restart, uninstall new revision.

## Helm canary

Second `helm install istiod-1-29-0 istio/istiod --set revision=1-29-0`.

## Checks

```bash
istioctl version -o json
kubectl get mutatingwebhookconfiguration | grep istio
istioctl analyze -A
istioctl verify-install --revision 1-29-0
```

Do not `--purge` unless the task is a full uninstall in a lab.

File: `07.md`.
