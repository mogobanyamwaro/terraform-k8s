# Topic 15: Built-in Functions

## What You'll Learn

- **Built-in functions** – no imports; use directly in expressions
- Common categories: string, collection, type conversion, file
- **locals** – named values for reuse
- Function syntax: `function_name(arg1, arg2)`

## Key Functions (Exam)

| Function         | Example                           | Purpose                 |
| ---------------- | --------------------------------- | ----------------------- |
| **join**         | `join(", ", ["a","b"])`           | List → string           |
| **split**        | `split(",", "a,b,c")`             | String → list           |
| **length**       | `length(list)`                    | Count elements          |
| **element**      | `element(list, index)`            | Get by index (wraps)    |
| **lookup**       | `lookup(map, key)`                | Get map value           |
| **coalesce**     | `coalesce(a, b, c)`               | First non-null          |
| **try**          | `try(expr, default)`              | Return default on error |
| **substr**       | `substr("hi", 0, 1)`              | Substring               |
| **upper/lower**  | `upper("x")`                      | Case change             |
| **cidrsubnet**   | `cidrsubnet("10.0.0.0/16", 8, 1)` | Subnet CIDR             |
| **file**         | `file("path")`                    | Read file contents      |
| **templatefile** | `templatefile("tpl", vars)`       | Render template         |

## Steps

### 1. Apply

```bash
cd topic-15-functions
terraform init
terraform apply -auto-approve
```

### 2. Inspect

```bash
cat functions-demo.txt
terraform output
```

### 3. Try in console

```bash
terraform console
> join("-", ["a","b","c"])
> length(["x","y"])
> lookup({a=1,b=2}, "a")
> exit
```

---

## Exam Tips

| Concept        | Key Point                                         |
| -------------- | ------------------------------------------------- |
| **locals**     | `locals { x = "value" }` – reference as `local.x` |
| **try()**      | Avoid errors; return default if expression fails  |
| **coalesce()** | First non-null value; good for optional vars      |
| **element()**  | Index wraps: element([a,b], 5) → b                |
| **toset()**    | List → set; removes duplicates                    |
| **tomap()**    | Object → map                                      |

## Practice

1. Add `split(",", "one,two,three")` to an output.
2. Use `try(var.maybe_null, "fallback")` with a variable that has no default.
