# Project 1: GitOps CI/CD Pipeline for a Microservices App

**Portfolio context:** 1.5 yrs DevOps experience (prior background: software engineering), targeting MNC-level DevOps roles. Weak spot: Kubernetes depth (past exposure = monitoring only). This is project 1 of 3.

**Constraints**
- Near-zero budget — local dev on `kind`, Azure only for short verification bursts (use $200 free credit), then tear down immediately
- 5–10 hrs/week
- Comfortable with: Bash, Terraform, YAML
- Not comfortable with: Python, Go
- No GPUs — CPU only
- Must have explicit Slack notifications + provable auto-healing (not just "Kubernetes does it")

---

## What We're Building

A full GitOps CI/CD pipeline deploying **Google's Online Boutique** (open-source microservices demo app — you don't write the app, you build everything around it) onto **Azure AKS**.

### Architecture

```
 ┌─────────────┐
 │  Developer  │
 │  (You)      │
 └──────┬──────┘
        │ git push
        ▼
 ┌─────────────────────┐
 │   GitHub Repo         │
 │  (app + Helm charts)  │
 └──────┬────────────────┘
        │ triggers
        ▼
 ┌─────────────────────────────────────┐
 │        GitHub Actions (CI)            │
 │  Lint → Build → Trivy Scan → Test     │
 │  → Push image to ACR                  │
 └──────┬────────────────────────────────┘
        │ image pushed
        ▼
 ┌─────────────────────┐        ┌───────────────────┐
 │ Azure Container       │◄───────│  Slack (#pipeline)  │
 │ Registry (ACR)         │        │  pass/fail alert    │
 └──────┬─────────────────┘        └───────────────────┘
        │ watched by
        ▼
 ┌─────────────────────────────────────┐
 │            ArgoCD (GitOps)            │
 │  watches Git repo for desired state   │
 │  selfHeal: true → auto-revert drift   │
 └──────┬────────────────────────────────┘
        │ deploys via Helm
        ▼
 ┌─────────────────────────────────────┐
 │         AKS Cluster (Azure)           │
 │  Online Boutique microservices        │
 │  running as pods                      │
 └──────┬────────────────────────────────┘
        │ metrics scraped
        ▼
 ┌─────────────────────┐        ┌───────────────────┐
 │ Prometheus + Grafana  │        │ Slack (#deploys)    │
 │ dashboards, alerts     │        │ ArgoCD sync status  │
 └────────────────────────┘        └───────────────────┘
```

### Tech Stack & Why

| Component | Role | Why it's here |
|---|---|---|
| GitHub | Source of truth for app code + Helm charts | GitOps requires Git as the desired-state source |
| GitHub Actions | CI pipeline | Lint, build, scan, test, push image |
| Trivy | Vulnerability scanner | Catches risky base images/CVEs pre-deploy |
| Terraform | Provisions AKS + networking | IaC, no manual Azure portal clicking |
| Azure Container Registry | Image storage | Private registry integrated with AKS |
| ArgoCD | GitOps deployment engine | Watches Git, auto-deploys, self-heals drift |
| Helm | Templating | One chart, different values per environment |
| AKS | Runs the app | Managed Kubernetes, control plane is free |
| Prometheus | Metrics collection | Scrapes pod/node health |
| Grafana | Dashboards | Custom dashboard = interview talking point |
| Slack | Notifications | CI pass/fail + ArgoCD sync/deploy status |
| kind | Local dev cluster | Fast, disposable, mirrors AKS before real deploy |

**App:** Google's Online Boutique (`microservices-demo`) — ~10 services (frontend, cart, checkout, product catalog, currency, etc.), already containerized-friendly, actively maintained, widely recognized in interviews.

**Testing approach:** Since the app isn't hand-written, "test" = Trivy image scan + Helm lint/manifest validation + smoke test (curl against frontend health endpoint post-deploy) — not unit tests.

**Auto-healing proof:** Manually `kubectl edit` a live deployment to cause drift, then screen-record/screenshot ArgoCD detecting and reverting it via `selfHeal: true`. This is the artifact you show in interviews — not just a claim.

---

## Week-by-Week Execution Plan (5–10 hrs/week)

### Week 1 — Local foundation
- Install kind, kubectl, Helm, Docker
- Fork/clone Online Boutique repo
- Get it running locally on kind with default manifests (no customization yet)
- Reduce replica counts to 1/service for laptop resource limits
- **Goal:** app running end-to-end locally, understand what each service does

### Week 2 — Containerization + registry basics
- Review/adjust Dockerfiles for each service (mostly verifying, not rewriting)
- Set up a free/local registry alternative for now (Docker Hub free tier or local kind registry) to avoid burning Azure credit yet
- Push images manually once, confirm pull works into kind
- **Goal:** understand image build/push flow before automating it

### Week 3 — Terraform for AKS
- Write Terraform for: resource group, VNet/subnet, AKS cluster, node pool (small, e.g. 2x B-series nodes)
- Provision AKS, verify `kubectl` access — then **tear down immediately** after verifying
- **Goal:** repeatable, scriptable AKS provisioning; practice the "spin up, verify, tear down" discipline

### Week 4 — GitHub Actions CI pipeline
- Build pipeline: lint → build → Trivy scan → smoke test → push to ACR
- Wire GitHub Actions → Slack webhook for pass/fail notification
- Test against local registry first, then real ACR during a short Azure burst
- **Goal:** working CI pipeline with Slack alerts, independent of deployment

### Week 5 — Helm charts
- Convert raw Online Boutique manifests into a Helm chart
- Parameterize replica counts, resource limits, image tags via `values.yaml`
- Separate `values-local.yaml` and `values-azure.yaml`
- **Goal:** one chart, two environments

### Week 6 — ArgoCD + GitOps
- Install ArgoCD (on kind first, then AKS during a burst)
- Point ArgoCD at your Git repo, deploy via Helm chart
- Enable `selfHeal: true`, set up ArgoCD → Slack integration
- **Goal:** working GitOps deploy loop

### Week 7 — Prove auto-healing
- Deploy on AKS (short burst)
- Manually cause drift (`kubectl edit`, `kubectl delete pod`, scale deployment down)
- Capture ArgoCD detecting + reverting it (screenshots/recording)
- Tear down AKS immediately after
- **Goal:** concrete auto-healing proof artifact for portfolio/interviews

### Week 8 — Monitoring + polish
- Install Prometheus + Grafana (local first)
- Build one custom Grafana dashboard (e.g., pod restarts, request latency, CPU/memory per service)
- Write up README with architecture diagram, screenshots, and the auto-healing demo
- Final short Azure burst to validate everything end-to-end, then tear down
- **Goal:** portfolio-ready repo + writeup

---

## Suggested Way of Working (with Claude Code)

Since you're pairing this with Claude Code, the biggest risk isn't technical — it's letting Claude Code do too much silently, so you end up with a working repo you can't explain in an interview. To actually grow your Kubernetes depth (your stated weak spot), structure it like this:

1. **You plan, Claude Code executes narrow tasks.** Don't say "set up ArgoCD for me." Instead: "explain what an ArgoCD `Application` manifest needs for self-heal, then I'll write it, and you review it." Keep yourself in the authoring loop for anything Kubernetes-native (manifests, Helm templates, ArgoCD configs) — those are exactly the reps you need.
2. **Let Claude Code fully own the boilerplate you don't need reps on** — Terraform provider blocks, GitHub Actions YAML syntax, Dockerfile boilerplate you're just verifying, not learning.
3. **After each week, write a 3–5 sentence "what I learned" note** in the repo's README or a `LEARNING.md`. This becomes interview material and forces you to actually process what happened rather than just move to the next step.
4. **Break things on purpose.** After each major milestone (Week 6, 7), intentionally cause a failure — drift, a broken image, a bad Helm value — and fix it without just asking Claude Code for the fix first. Try yourself for 15–20 min, then get help. This is where the Kubernetes depth actually gets built.
5. **Keep a running cost log** — even trivial, just note when you spun up AKS and when you tore it down. This shows cost-discipline instinct in interviews, which MNCs care about.

Bring this file into Claude Code as the working spec — it can reference it each session so you don't have to re-explain context every time.
