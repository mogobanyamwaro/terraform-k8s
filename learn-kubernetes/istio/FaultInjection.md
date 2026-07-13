# Fault Injection Reference

VirtualService only, HTTP only, client proxy / waypoint.

```yaml
      fault:
        delay:
          percentage: { value: 100.0 }
          fixedDelay: 5s
        abort:
          percentage: { value: 10.0 }
          httpStatus: 500
          # grpcStatus: UNAVAILABLE
```

- Delay then abort if both set
- `percentage.value` float 0-100
- Still need `route.destination`
- Delay ≥ timeout → client **UT/504**, upstream may never see traffic
- Abort 500 + `retryOn: 5xx` retries until attempts exhaust

Match-scoped faults for one user/path.

Ambient: waypoint required.

File: `20.md`.
