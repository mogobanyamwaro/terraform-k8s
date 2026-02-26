# Topic 17: Conditional Expressions

## What You'll Learn

- **Ternary operator** – `condition ? true_val : false_val`
- **try()** – safe evaluation; return default on error
- **Same type** – both ternary branches must return same type
- **Short-circuit** – only evaluated branch runs

## Steps

### 1. Apply with default

```bash
cd topic-17-conditionals
terraform init
terraform apply -auto-approve
```

### 2. Try prod

```bash
terraform apply -auto-approve -var="environment=prod"
terraform output ternary_size   # "large"
```

### 3. Inspect try()

```bash
terraform output try_example       # "default-when-null"
terraform output try_map_lookup    # "key-not-found"
```

---

## Exam Tips

| Concept                | Key Point                                                |
| ---------------------- | -------------------------------------------------------- |
| **Ternary**            | `cond ? a : b` – both a and b same type                  |
| **try(expr, default)** | Returns default if expr errors (null, missing key, etc.) |
| **try with multiple**  | `try(a, b, c)` – first successful, else last             |
| **can()**              | Like try but returns true/false; doesn't return value    |

## try() vs coalesce()

|              | try()                                     | coalesce()                 |
| ------------ | ----------------------------------------- | -------------------------- |
| **Handles**  | Any error (null, missing key, type error) | Only null/empty            |
| **Use when** | Unsure if expr is valid                   | Dealing with optional vars |

## Practice

1. Add `count = var.environment == "prod" ? 1 : 0` to create a resource only in prod.
2. Use `try(jsondecode(var.json_string).key, "fallback")` with a variable containing invalid JSON.
