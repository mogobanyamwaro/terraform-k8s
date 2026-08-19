# Install Reference

## istioctl

```bash
istioctl install -y
istioctl install --set profile=demo -y
istioctl install -f iop.yaml -y
istioctl install --set revision=1-29-0 -y
istioctl uninstall --purge -y          # lab only
istioctl verify-install
istioctl manifest generate -f iop.yaml
istioctl profile list
istioctl profile dump default
istioctl profile diff default demo
istioctl tag list
istioctl tag set prod-stable --revision 1-29-0
```

## Profiles

| Profile | Ingress | Egress | ztunnel+CNI |
| --- | :---: | :---: | :---: |
| default | yes | no | no |
| demo | yes | yes | no |
| minimal | no | no | no |
| ambient | yes | no | yes |
| empty | no | no | no |
| remote | — | — | multi-cluster |

## IstioOperator skeleton

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: default
  revision: 1-29-0
  meshConfig:
    outboundTrafficPolicy: { mode: REGISTRY_ONLY }
    accessLogFile: /dev/stdout
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
    egressGateways:
      - name: istio-egressgateway
        enabled: true
    pilot:
      k8s:
        replicaCount: 2
  values:
    global:
      trustDomain: cluster.local
```

`--set meshConfig.accessLogFile=/dev/stdout` maps into `spec.meshConfig`.

## Helm

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
kubectl create ns istio-system
helm install istio-base istio/base -n istio-system --set defaultRevision=default
helm install istiod istio/istiod -n istio-system --wait
helm install istio-ingress istio/gateway -n istio-system
```

Upgrade: bump chart version, `helm upgrade istiod ...`. Canary: install a second istiod with `--set revision=1-29-0`.

## MeshConfig hot spots

```yaml
meshConfig:
  outboundTrafficPolicy:
    mode: ALLOW_ANY | REGISTRY_ONLY
  defaultConfig:
    holdApplicationUntilProxyStarts: true
  accessLogFile: /dev/stdout
  enableTracing: true
  extensionProviders: [...]
```

## Customization exam patterns

- Enable egress: `components.egressGateways[0].enabled=true`
- Resources: `components.pilot.k8s.resources.requests.cpu`
- `meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY`
- Revision for canary: `--set revision=...`

Files: `02.md`, `03.md`, `06.md`, `07.md`.
