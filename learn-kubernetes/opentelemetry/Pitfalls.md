# OTCA Pitfalls

1. Treating OTCA as **PCA** — PromQL is not the syllabus; **OTel + Collector** is.
2. Treating OTCA as **CKA** — closed-book MCQ, no cluster tasks.
3. **API vs SDK** swapped — API is no-op; SDK exports.
4. **Collector vs SDK** as the same process.
5. **Javaagent vs Collector agent** — instrument vs pipeline.
6. **`yarn start` thinking** — this is not Backstage/CBA.
7. `service.name` as a span name or Sampler.
8. **Labels vs attributes vs resource** mixed.
9. **Baggage automatically on spans** — it is not.
10. Secrets in baggage.
11. **Counter for latency** instead of Histogram.
12. **UpDownCounter** vs Counter.
13. **SimpleSpanProcessor in production**.
14. Head vs **tail** sampling swapped.
15. **`traceidratio` without ParentBased** → partial traces.
16. Tail sampling on **sidecars** / random replicas.
17. **4317 vs 4318** / grpc vs http mismatch.
18. Component in YAML **not wired** into `service.pipelines`.
19. Processor **order** ignored (`batch` first).
20. Metrics exporter on a **traces** pipeline.
21. Expecting signals to mix **without a connector**.
22. **OTTL in the application API**.
23. Debugging ingestion in Grafana first — check **console/debug exporter**.
24. Many roots blamed on Collector YAML — often **propagation**.
25. **Blocking the request** until OTLP succeeds.
26. High-cardinality `user_id` on metrics.
27. One **span per log line**.
28. `filelog` receiver = Logs SDK.
29. `zpages` = production backend.
30. `debug` verbosity detailed left in prod.
31. Old `http.method` vs new `http.request.method` as a “Collector crash”.
32. `schema_url` as `app.baseUrl`.
33. contrib component on a **core** image.
34. Operator Instrumentation CR confused with Collector pipeline YAML.
35. Closed book: drill **where the knob lives** (env vs YAML vs header).
