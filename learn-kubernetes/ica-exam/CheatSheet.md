# ICA CheatSheet

Exam: 2h, 15–20 tasks, pass **68%**, Istio **~1.29**, docs **istio.io/docs**, Istio Blog, **kubernetes.io/docs**. SSH to the task host from `base`. `k` and `istioctl` aliased.

## First 60 seconds

```bash
alias k=kubectl ic=istioctl
export do="--dry-run=client -o yaml"
kubectl config get-contexts
istioctl version
kubectl -n istio-system get po,svc
kubectl get ns --show-labels | grep -E 'istio-injection|istio.io/rev|dataplane-mode'
source <(istioctl completion bash)
source <(kubectl completion bash)
```

## Resource cheat

| Want | Apply |
| --- | --- |
| Route / match / weight / timeout / retry / fault / mirror | VirtualService |
| Subset / LB / pool / outlier / client TLS | DestinationRule |
| External host | ServiceEntry |
| Open edge ports | Gateway |
| mTLS accept | PeerAuthentication |
| JWT validate | RequestAuthentication |
| Who can call | AuthorizationPolicy |
| Shrink proxy config | Sidecar |
| Logs/traces | Telemetry |

## Persistence / grader checks

```bash
istioctl analyze -A
istioctl proxy-status
curl through the real path
kubectl get vs,dr,gw,se,peerauthentication,requestauthentication,authorizationpolicy -A
```

## Defaults

PERMISSIVE mTLS · ALLOW_ANY egress · 2 retries without 5xx · no timeout · LEAST_REQUEST · subset missing = 503 NR · first ALLOW = default deny · JWT RA does not require token

## Labels

`istio-injection=enabled` · `istio.io/rev=REV` · `istio.io/dataplane-mode=ambient` · Gateway selector `istio: ingressgateway`

## Ports

15000 admin · 15001 out · 15006 in · 15008 HBONE · 15012 xDS · 15020 metrics · 15021 ready · 15017 webhook

## Flags

NR route · UH endpoints · UO pool · UT timeout · UF connect/mTLS

## Canary upgrade

`istioctl install --set revision=X` → label ns `istio.io/rev=X` → remove `istio-injection` → rollout restart → uninstall old revision

## Ambient L7

waypoint `gatewayClassName: istio-waypoint` + `istio.io/use-waypoint=`

## Principal

`cluster.local/ns/NS/sa/SA`

## Docs pages to type from muscle memory

- `/docs/reference/config/networking/virtual-service/`
- `/docs/reference/config/networking/destination-rule/`
- `/docs/reference/config/networking/gateway/`
- `/docs/reference/config/security/authorization-policy/`
- `/docs/tasks/traffic-management/egress/egress-gateway/`
- `/docs/tasks/security/authorization/authz-jwt/`
- `/docs/setup/upgrade/canary/`
