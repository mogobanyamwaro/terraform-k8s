# istioctl Command Reference

Autocomplete on the exam: `source <(istioctl completion bash)`.

## Install / upgrade

```bash
istioctl install -y
istioctl install --set profile=demo -y
istioctl install --set revision=1-29-0 -y
istioctl install -f iop.yaml
istioctl uninstall --revision 1-24-0 -y
istioctl verify-install
istioctl manifest generate -f iop.yaml
istioctl profile list|dump|diff
istioctl tag list
istioctl tag set prod-stable --revision 1-29-0
istioctl tag unset prod-stable
```

## Inject

```bash
istioctl kube-inject -f deploy.yaml | kubectl apply -f -
```

Prefer namespace labels in real tasks.

## Analyze / validate

```bash
istioctl analyze
istioctl analyze -A
istioctl analyze -n demo
istioctl analyze -f file.yaml
istioctl validate -f file.yaml
istioctl experimental precheck
```

## Proxies

```bash
istioctl proxy-status
istioctl ps
istioctl proxy-status deploy/httpbin.demo
istioctl version
istioctl version -o yaml
```

## proxy-config (pc)

```bash
istioctl pc cluster  deploy/sleep.demo
istioctl pc listener deploy/sleep.demo
istioctl pc route    deploy/sleep.demo
istioctl pc endpoint deploy/sleep.demo
istioctl pc secret   deploy/sleep.demo
istioctl pc bootstrap deploy/sleep.demo
istioctl pc log      deploy/sleep.demo --level debug
istioctl pc all      deploy/sleep.demo -o json
istioctl pc c deploy/sleep.demo --fqdn httpbin.demo.svc.cluster.local
istioctl pc ep deploy/sleep.demo --cluster "outbound|8000||httpbin.demo.svc.cluster.local"
```

## Describe / authz / dashboards (lab)

```bash
istioctl x describe pod POD -n NS
istioctl experimental authz check POD.NS
istioctl dashboard kiali|grafana|jaeger|prometheus|envoy POD.NS
```

Dashboards need port-forward; exam may lack addons.

## Ambient / waypoint

```bash
istioctl ztunnel-config all|workload|certificate|services
istioctl waypoint apply -n shop
istioctl waypoint apply -n shop --for service
istioctl waypoint delete -n shop
istioctl waypoint list
```

## Bug / admin

```bash
istioctl bug-report          # too slow for exam
istioctl admin log           # istiod logging
istioctl proxy-config log
```

Workload identifier: `deploy/name.ns`, `name.ns` (pod), or `-n ns name`.
