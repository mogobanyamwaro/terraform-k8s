# Resilience Reference

| Feature | Resource | Field |
| --- | --- | --- |
| Timeout | VirtualService | `http[].timeout` |
| Retries | VirtualService | `http[].retries` |
| Faults | VirtualService | `http[].fault` |
| Connection pool / overflow | DestinationRule | `trafficPolicy.connectionPool` |
| Outlier ejection | DestinationRule | `trafficPolicy.outlierDetection` |
| Load balancer | DestinationRule | `trafficPolicy.loadBalancer` |
| Locality failover | DestinationRule | `localityLbSetting` + outlier |

## Defaults

- No route timeout
- **2** retries, retryOn **does not include 5xx**
- `LEAST_REQUEST`
- outlier `consecutive5xxErrors: 5`, `interval: 10s`, `baseEjectionTime: 30s`, `maxEjectionPercent: 10`

## Retry math

`total tries = 1 + attempts`. Parent `timeout` caps the whole budget. `perTryTimeout` caps one try.

`attempts: 0` disables default retries.

## Pool overflow

Flag **UO**, HTTP 503. Tiny `maxConnections` / `http1MaxPendingRequests` in exam tasks.

## Outlier + small services

Default `maxEjectionPercent: 10` cannot eject 1 of 2 pods. Set `100` and `minHealthPercent: 0` when the task wants ejection on a tiny Deployment.

## Failover

`localityLbSetting.failover` **without** outlier detection does not work.

Files: `18.md`, `19.md`, `21.md`, `20.md`.
