# Propagation (Deep Dive)

W3C Trace Context + Baggage. Spec: [w3.org/TR/trace-context](https://www.w3.org/TR/trace-context/).

```text
traceparent: 00-<32 hex trace>-<16 hex span>-<2 hex flags>
             version  trace-id              parent-id      01 = sampled
tracestate:  vendor=value,...
baggage:     key=value,key2=value2
```

`OTEL_PROPAGATORS=tracecontext,baggage` (add `b3` / `jaeger` for legacy).

**Inject** outbound. **Extract** inbound. In-process: attach context to async/threads.

**Baggage** is not auto-copied to spans. No secrets. Small values.

**Broken traces:** missing middleware, wrong propagator, overwriting headers, new roots in workers.

ParentBased sampling reads the **sampled flag** from `traceparent`.
