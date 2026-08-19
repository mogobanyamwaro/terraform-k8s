# TLS Reference (Edge)

Gateway `servers[].tls.mode`:

| Mode | Terminates | VS section |
| --- | --- | --- |
| SIMPLE | Server TLS | `http` |
| MUTUAL | + client cert | `http` |
| OPTIONAL_MUTUAL | client cert optional | `http` |
| PASSTHROUGH | no | `tls` + `sniHosts` |
| AUTO_PASSTHROUGH | multi-cluster | — |
| ISTIO_MUTUAL | mesh certs | egress hops |

```yaml
      tls:
        mode: SIMPLE
        credentialName: shop-tls
        minProtocolVersion: TLSV1_2
```

HTTP server sibling:

```yaml
      tls:
        httpsRedirect: true
```

Secret keys: `tls.crt` / `tls.key` (`kubectl create secret tls`). MUTUAL also `ca.crt`.

Secret namespace = **ingress pod ns** (`istio-system`), not the Gateway CR ns.

PASSTHROUGH: `protocol: TLS` on the server port.

Backend HTTPS after SIMPLE terminate: DestinationRule `tls.mode: SIMPLE` to avoid plaintext to the app or double-TLS mistakes.

File: `27.md`.
