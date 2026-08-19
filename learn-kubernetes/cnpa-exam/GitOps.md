# GitOps as a Platform Capability

CNPA is not CGOA. Remember the **product** framing.

## What the platform offers

- A GitOps engine (Argo CD, Flux, Config Sync) as a **paved CD**
- Self-service: Application/Kustomization via portal template or CR
- Env promotion: PRs + CODEOWNERS
- Credentials on the **agent**, not in CI
- Health of Applications as a platform SLO

## Four ideas (enough)

1. Declarative desired state  
2. Versioned/immutable store (Git)  
3. Agent **pulls**  
4. Continuously **reconciles** drift  

Rollback = Git. Webhooks accelerate pull.

## Env mapping

`dev/` auto-sync; `prod/` PR + CODEOWNERS. Same digest.

## Not GitOps

CI kubectl, wiki, ClickOps, one-shot apply.

Full glossary: `../cgoa-exam/OpenGitOps.md`.
