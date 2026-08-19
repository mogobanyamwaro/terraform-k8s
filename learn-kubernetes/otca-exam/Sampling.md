# Sampling (Deep Dive)

Head (SDK) vs tail (Collector).

## Head (span start)

| Name | Env |
| --- | --- |
| AlwaysOn | `always_on` |
| AlwaysOff | `always_off` |
| TraceIdRatio | `traceidratio` + `OTEL_TRACES_SAMPLER_ARG` |
| ParentBased(*) | `parentbased_always_on`, `parentbased_traceidratio`, … |

**ParentBased** keeps a trace consistent across services.

`always_off` can still **propagate** IDs.

## Tail (Collector)

`tail_sampling` after the trace is complete: sample errors, latency > N, `service.name` rules.

Requires **gateway** + **trace-ID affinity** if replicated.

## Collector probabilistic_sampler

Not tail: drops in-pipeline like extra head sampling.

## Analysis trade-off

1% head sample **misses rare 500s** unless you tail-sample errors or use error-biased policies.
