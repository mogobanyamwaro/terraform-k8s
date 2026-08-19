# Crossplane (Exam)

```text
Claim (namespaced)  -->  XR (composite)  -->  composed resources
                         Composition
XRD defines the API
```

```bash
kubectl get xrd,composition,provider,providerconfig
kubectl explain <claim-kind>.spec
kubectl describe <claim> -n <ns>
```

Ready/Synced False → events on the Claim **and** XR. ProviderConfig credentials are the usual miss.

Kubernetes provider = create Namespace/objects without AWS. Cloud providers need secrets — exam will have ProviderConfig already.

Do not edit XRD unless asked. Fill the **Claim**.
