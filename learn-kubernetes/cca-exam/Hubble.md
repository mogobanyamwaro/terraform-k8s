# Hubble Deep Dive

eBPF events → observer in **agent** → **Relay** → CLI/UI/metrics.

```bash
cilium hubble port-forward
hubble status
hubble observe --since 5m
hubble observe --verdict DROPPED
hubble observe --from-pod ns/pod --protocol http
```

L3/L4 always (if Hubble on). **L7 fields need L7 proxy/visibility.**

Metrics scrapeable by Prometheus. Not a log stack, not Jaeger.

See `15.md`–`16.md`.
