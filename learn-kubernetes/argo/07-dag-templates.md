# 07. DAG Templates

**Domain:** Argo Workflows (36%) — Work with DAG

## Concept Refresher

A **dag** template lists **tasks**. Each task has a `template` (or templateRef) and optional `dependencies`.

Rules:

- Tasks with **empty dependencies** start immediately (can be many in parallel).
- A task starts when **all** listed dependencies succeeded (default).
- **No cycles** (directed acyclic).
- Diamond: A → (B, C) → D is the exam picture.

```yaml
- name: diamond
  dag:
    tasks:
    - name: A
      template: echo
    - name: B
      dependencies: [A]
      template: echo
    - name: C
      dependencies: [A]
      template: echo
    - name: D
      dependencies: [B, C]
      template: echo
```

**failFast** (default true): if a task fails, the DAG fails and remaining tasks are not started (running ones may be stopped depending on version/settings). `failFast: false` lets independent branches continue.

**depends** (enhanced syntax) can express `A.Succeeded || B.Failed` etc. Know that **dependencies** is the basic list form.

`when:` still applies per task. Artifacts/parameters pass with `arguments` from `{{tasks.A.outputs...}}` (**tasks**, not `steps`).

## Question

**Q1.** A DAG in Workflows is:

- A. A Git branch graph
- B. A template invocator that runs tasks by declared dependencies
- C. An Argo CD ApplicationSet generator
- D. An EventBus topology

**Q2.** Tasks with no dependencies:

- A. Never run
- B. Run immediately (in parallel with each other)
- C. Run only after Cron
- D. Require suspend

**Q3.** Task D with `dependencies: [B, C]` starts when:

- A. Either B or C starts
- B. B and C have both succeeded (default)
- C. A fails
- D. Git is pushed

**Q4.** Cycles in a DAG:

- A. Required
- B. Forbidden (must be acyclic)
- C. Converted to blue-green
- D. Converted to canary

**Q5.** Default `failFast: true` means:

- A. Ignore failures
- B. A failure stops scheduling remaining DAG tasks
- C. Always retry forever
- D. Always prune

**Q6.** Referencing outputs in a DAG uses:

- A. `{{steps.x...}}` only
- B. `{{tasks.A.outputs...}}`
- C. `{{app.status...}}`
- D. `{{analysis.run...}}`

**Q7.** Why DAG instead of steps for a wide ETL:

- A. DAG cannot parallelise
- B. Dependencies maximise parallelism without nested step groups
- C. DAG is only for HTTP
- D. Steps cannot sequence

**Q8.** Independent branches B and C after A:

- A. Must be sequential
- B. Run in parallel once A completes
- C. Require two CronWorkflows
- D. Require two Applications

**Q9.** `failFast: false` is useful when:

- A. You want GitOps prune
- B. You want other branches to continue after one branch fails
- C. You want canary 10%
- D. You want EventBus Kafka

**Q10.** The diamond A→B,C→D is:

- A. A Rollout strategy
- B. The canonical DAG exam shape
- C. An AppProject
- D. A sync wave

## Answers

**Q1.** B  
**Q2.** B  
**Q3.** B  
**Q4.** B  
**Q5.** B  
**Q6.** B  
**Q7.** B  
**Q8.** B  
**Q9.** B  
**Q10.** B

## Hands-on

Implement the diamond with four `echo` tasks. Then add an artifact from A to D.

## Exam tips

- **dependencies = wait for those tasks.**
- DAG outputs: **`tasks.`** not `steps.`
- Diamond = parallel after a fork, join before D.
