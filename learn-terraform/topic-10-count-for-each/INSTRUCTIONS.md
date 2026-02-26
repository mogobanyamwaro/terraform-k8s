# Topic 10: count and for_each

## What You'll Learn

- **count** – create N instances; use `count.index` (0 to N-1)
- **for_each** – create one instance per map key or set element; use `each.key`, `each.value`
- Referencing: `resource.name[0]` or `resource.name["key"]`
- Splat: `resource.name[*]` to get all instances

## Steps

### 1. Apply

```bash
cd topic-10-count-for-each
terraform init
terraform apply -auto-approve
```

Creates:

- `count-file-0.txt`, `count-file-1.txt`, `count-file-2.txt`
- `env-dev.txt`, `env-prod.txt`, `env-staging.txt`

### 2. Inspect outputs

```bash
terraform output
```

### 3. Reference a single instance

```bash
terraform console
> local_file.count_demo[1].filename
> local_file.for_each_demo["prod"].content
> exit
```

---

## count vs for_each (Exam)

|                 | count                        | for_each                                             |
| --------------- | ---------------------------- | ---------------------------------------------------- |
| **Input**       | Number (e.g. 3)              | Map or set                                           |
| **Index**       | `count.index` (0, 1, 2...)   | `each.key`, `each.value`                             |
| **Reference**   | `resource[0]`, `resource[1]` | `resource["key"]`                                    |
| **Splat**       | `resource[*]`                | `[for x in resource : x.attr]`                       |
| **When to use** | Simple numbered list         | Named instances; avoid recreating when order changes |

**Important:** Changing `count` from 3 to 4 adds one; changing order can force replace. `for_each` with stable keys is safer for adds/removes.

## Exam Tips

| Concept                   | Key Point                                                       |
| ------------------------- | --------------------------------------------------------------- |
| **count.index**           | 0-based index in count loop                                     |
| **each.key / each.value** | Current key and value in for_each                               |
| **toset()**               | Convert list to set for for_each: `for_each = toset(["a","b"])` |
| **resource[*]**           | List of all instances (splat)                                   |
| **Cannot use both**       | A resource cannot have count and for_each together              |

## Practice

1. Change `count = 3` to `count = 5` and run plan – see 2 to add.
2. Add a new key to the for_each map – run plan – see 1 to add (others unchanged).
