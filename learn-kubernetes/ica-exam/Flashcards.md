# ICA Flashcards

Cover answers. Say the command or YAML field out loud.

## Install / upgrade

**Q:** Default profile include egress gateway?  
**A:** No. `demo` does.

**Q:** Ambient mandatory components?  
**A:** CNI + ztunnel (`profile=ambient`).

**Q:** Canary migrate a namespace?  
**A:** `kubectl label ns X istio.io/rev=REV --overwrite`; remove `istio-injection`; `rollout restart`.

**Q:** Sidecar injection retroactive?  
**A:** No. Recreate pods.

**Q:** Two labels `istio-injection=enabled` and `istio.io/rev=1-29-0`?  
**A:** Conflict. Use one model.

## Traffic

**Q:** Where vs how?  
**A:** VirtualService vs DestinationRule.

**Q:** Missing subset?  
**A:** 503 NR. Not a webhook error.

**Q:** First-match?  
**A:** Yes. Catch-all last.

**Q:** Match list OR or AND?  
**A:** OR across entries, AND inside one.

**Q:** Mirror affects client response?  
**A:** No.

**Q:** Default timeout?  
**A:** None.

**Q:** Default retries?  
**A:** 2, not on 5xx.

**Q:** Circuit break resource?  
**A:** DestinationRule connectionPool + outlierDetection.

**Q:** Failover needs?  
**A:** outlierDetection.

**Q:** REGISTRY_ONLY unknown host?  
**A:** BlackHoleCluster.

**Q:** Gateway selector default?  
**A:** `istio: ingressgateway`.

**Q:** VS hosts vs Gateway hosts?  
**A:** Must intersect.

## Security

**Q:** Default mTLS?  
**A:** PERMISSIVE.

**Q:** Enforce mTLS?  
**A:** PeerAuthentication STRICT.

**Q:** Client TLS field?  
**A:** DestinationRule `trafficPolicy.tls.mode`.

**Q:** JWT require login?  
**A:** RequestAuthentication + AuthorizationPolicy requestPrincipals.

**Q:** Bad token code?  
**A:** 401.

**Q:** Missing token with ALLOW * requestPrincipals?  
**A:** 403.

**Q:** ALLOW no rules?  
**A:** Deny all.

**Q:** No AuthorizationPolicy?  
**A:** Allow all.

**Q:** Principal format?  
**A:** `cluster.local/ns/NS/sa/SA`.

**Q:** Edge cert Secret ns?  
**A:** Ingress pod namespace (`istio-system`).

**Q:** SIMPLE vs PASSTHROUGH VS?  
**A:** `http` vs `tls/sniHosts`.

## Troubleshooting

**Q:** First three commands?  
**A:** analyze, proxy-status, pc route/cluster/ep.

**Q:** NR / UH / UO / UT / UF?  
**A:** no route / no healthy upstream / overflow / timeout / connect fail.

**Q:** istiod down, existing traffic?  
**A:** Still flows on last config.

**Q:** Ambient HTTP timeout noop?  
**A:** Missing waypoint.

**Q:** 15020 / 15021 / 15012?  
**A:** metrics / ready / xDS+CA.

**Q:** Trust domain default?  
**A:** cluster.local.

**Q:** Workload cert TTL?  
**A:** 24h.

## Odds

**Q:** `exportTo: ["."]`?  
**A:** This namespace only.

**Q:** Sidecar must include?  
**A:** `istio-system/*`.

**Q:** LEAST_REQUEST vs ROUND_ROBIN?  
**A:** Default vs explicit simple LB.

**Q:** weight 90 and 10 vs 9 and 1?  
**A:** Same ratio.

**Q:** `mirrorPercentage` omitted?  
**A:** 100%.

**Q:** Authorization inbound or outbound?  
**A:** Inbound (destination).
