# Mutate and Generate (Deep Dive)

## Mutate

- **patchStrategicMerge** — K8s overlay, container merge key `name`
- **patchesJson6902** — `op` / `path` / `value`
- **targets** — mutate other/existing objects
- Prefer CREATE; Pod spec is mostly immutable

## Generate

| Mode | Source |
| --- | --- |
| `data` | Inline YAML |
| `clone` | Existing object |

`synchronize: true` — Kyverno owns child (revert drift).  
`generateExisting` — backfill.  
RBAC to **create** the generated kind.

Trigger example: Namespace → default-deny NetworkPolicy.
