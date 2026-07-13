# Which Layer? (Ticket Ops vs Platform Product)

CNPA’s first filter. Same Kubernetes, opposite jobs.

## Three operating models

| Model | How developers get stuff | Exam verdict |
| --- | --- | --- |
| **Ticket ops** | Open Jira; wait for a human to `kubectl` | Not a platform. Cognitive load stays on the platform team; does not scale |
| **DIY / wiki** | 40-page runbook; every team invents a cluster | High cognitive load; snowflake estates |
| **Platform as a product** | Self-service APIs, golden paths, docs, SLOs | CNPA default |

## Golden path (paved road)

The **recommended** way to ship: template + CI + GitOps + defaults (security, obs, networking). It should be the **easiest** path, not the only legal path. An **escape hatch** exists for valid exceptions (with extra cost/review).

Forcing one framework with no hatch is a **mandate**, not a golden path.

## Thinnest viable platform (TVP)

Ship the smallest set of capabilities that reduce the biggest developer toil **now**. Do not start with a 30-tool “IDP.” Add capabilities when adoption and tickets prove the need.

## Customers

The platform’s users are **application teams** (and sometimes other platforms). The platform team is **not** the customer of the platform. Success = those users ship faster and safer **without** waiting on you.

## Exam stems

- “Every namespace needs a 3-day ticket” → add a **self-service API** / template, not more staff on the queue.
- “Teams copy-paste 12 YAML files wrong” → **golden path** + policy defaults.
- “We installed Backstage but nobody uses it” → portal without **valuable APIs/templates** is wallpaper; measure adoption.
- “Developers must learn Crossplane composites, OPA, and Istio to deploy hello-world” → leaky abstraction; hide it behind a **higher-level API**.
