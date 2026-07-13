# VerifyImages (Deep Dive)

Sigstore/Cosign on **workload** images (not policy-as-OCI).

```yaml
verifyImages:
  - imageReferences: ["registry.example.com/prod/*"]
    attestors:
      - entries:
          - keys: { publicKeys: | ... }
          # or keyless: fulcio / issuer / subject
    attestations:
      - predicateType: https://slsa.dev/provenance/v1
        attestors: [...]
    mutateDigest: true
    required: true
```

Signature vs attestation. Air-gap needs keyed keys or mirrored TUF. Slow → webhook timeout.
