# 02. Artifacts

**Domain:** Argo Workflows (36%) — Generating and Consuming Artifacts

## Concept Refresher

**Parameters** = small values (strings, numbers, JSON) passed between templates (`inputs.parameters` / `outputs.parameters`).

**Artifacts** = **files or directories**. A step **produces** an artifact (output path in the container); a later step **consumes** it (input mounted/downloaded).

Default archive format is often **tar+gzip**. Backends: **S3 / MinIO**, GCS, Azure Blob, Artifactory, HTTP, Git, raw, OSS, Plugin. Artifact repository is configured cluster-wide (`artifactRepository` in the workflow-controller ConfigMap) or per workflow (`archiveLocation`).

```yaml
- name: generate
  container:
    image: busybox
    command: [sh, -c, "echo hello > /tmp/out.txt"]
  outputs:
    artifacts:
    - name: result
      path: /tmp/out.txt
- name: consume
  inputs:
    artifacts:
    - name: result
      path: /tmp/in.txt
```

In **steps/DAG**, pass with `arguments.artifacts` from `{{steps.generate.outputs.artifacts.result}}`.

Exam traps:

- Passing a 2 GB dataset as a **parameter** — use an artifact (or a PVC).
- Artifacts are **not** GitOps desired state (that is Argo CD).
- `volumeClaimTemplates` / existing PVCs are another way to share files **on cluster disk** without an object store.

## Question

**Q1.** An artifact in Workflows is:

- A. A Git commit SHA only
- B. A file or directory produced or consumed by templates
- C. An Argo CD Application
- D. A Service mesh identity

**Q2.** Parameters vs artifacts:

- A. Identical
- B. Parameters are small values; artifacts are files/directories
- C. Artifacts cannot leave the pod
- D. Parameters are only S3 buckets

**Q3.** Default packaging of artifacts is commonly:

- A. ISO 9660
- B. tar + gzip
- C. Only uncompressed XML
- D. eBPF maps

**Q4.** MinIO/S3 in Workflows is typically:

- A. The GitOps state store for Argo CD
- B. An artifact repository backend
- C. The EventBus
- D. The Rollout analysis provider only

**Q5.** To pass a trained model file from step A to B:

- A. Put it in a parameter string
- B. Declare output/input artifacts (or a shared PVC)
- C. Use Argo CD prune
- D. Use a blue-green preview Service

**Q6.** `outputs.artifacts[].path` is:

- A. A Git URL
- B. The path **inside the container** to pack/upload
- C. An Ingress host
- D. A Prometheus query

**Q7.** Cluster-wide artifact repo is usually set in:

- A. Hubble
- B. Workflow controller ConfigMap (`artifactRepository`)
- C. Istio PeerAuthentication
- D. Cilium BGP

**Q8.** A later DAG task consumes an earlier artifact via:

- A. `destination.namespace` only
- B. `arguments.artifacts` referencing the prior task’s outputs
- C. `syncPolicy.automated`
- D. `setWeight: 10`

**Q9.** Git artifact input:

- A. Replaces Argo CD
- B. Can clone a repo **into a workflow step** as files
- C. Is EventBus
- D. Is AnalysisRun

**Q10.** Huge intermediate data without object storage:

- A. Impossible
- B. Often a PVC / `volumeClaimTemplates` on the workflow
- C. Must use Argo CD
- D. Must use Rollouts

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

Run an example that writes `/tmp/hello` as an artifact and cats it in the next step (official `artifacts` examples).

## Exam tips

- **Parameter = value. Artifact = blob.**
- S3/MinIO = **artifact store**, not GitOps store.
