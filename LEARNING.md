# Learning Log

Notes after each week's milestone — what I built, what confused me, what I'd explain differently in an interview. Written in my own words, not polished documentation.

**Format for each week:** What I Built → What Confused Me → How I'd Explain It in an Interview

---

## Week 1 — Local foundation

**Draft — rewrite this in your own words before treating it as done.**

### What I built
- Set up local tooling: Docker Desktop (on WSL2), kubectl, Helm, kind
- Got Google's Online Boutique microservices demo running end-to-end on a local `kind` Kubernetes cluster
- Verified the frontend in a browser via `kubectl port-forward`
- Got the project into a proper Git repo and pushed it to GitHub

### What confused me
- The repo ships **three different sets of manifests** for the same app:
  - `kubernetes-manifests/` — placeholder image names (`image: adservice`), meant for local dev via **Skaffold**, which builds and injects real image tags at deploy time
  - `release/kubernetes-manifests.yaml` — the same manifests but with **real, publicly-hosted image tags baked in** — this is the one that actually works with plain `kubectl apply`
  - `helm-chart/` — a Helm-templated version, for later (Week 5)
- I initially applied the wrong one (`kubernetes-manifests/`) and got `ImagePullBackOff` errors, because Kubernetes tried to pull a nonexistent image called `adservice:latest` from Docker Hub
- I mixed up `kubectl apply -f <dir>` vs `kubectl apply -k <dir>`:
  - `-f` applies every file in the directory as a plain Kubernetes object
  - `-k` uses **Kustomize**, which reads `kustomization.yaml` as an entry point and knows how to process it
  - Plain `-f` errors out on `kustomization.yaml` because it isn't a real Kubernetes object — it's config for a separate tool

### How I'd explain it in an interview
- A `kind` cluster is a real (if small) Kubernetes cluster running inside a Docker container — useful for free, disposable local dev before touching cloud infra
- Raw manifest vs. Kustomize overlay vs. Helm chart are three different ways to manage "the same YAML," just parameterized/composed differently — which is exactly why one app repo can ship all three
- `LoadBalancer` services don't get a real external IP on local clusters like `kind` (no cloud load balancer exists locally) — that's why I used `kubectl port-forward` to reach the frontend instead

---

## Week 2 — Containerization + registry basics

**Draft — rewrite this in your own words before treating it as done.**

### What I built
- Reviewed all 11 services' Dockerfiles (multi-stage builds, digest-pinned base images, non-root user usage)
- Set up a Docker Hub account and pushed my first self-built image manually
- Built `currencyservice` locally, pushed it to `docker.io/shorya8699/currencyservice:v1`
- Repointed the live `currencyservice` Deployment at my own image with `kubectl set image`, watched Kubernetes do a rolling update, and verified the running pod was actually pulling from my registry (not Google's) via `kubectl get pods -o jsonpath`
- Confirmed the app still worked end-to-end afterward through the frontend

### What confused me
- Only 1 of 11 Dockerfiles (`cartservice`) explicitly drops to a non-root user (`USER 1000`) — the rest run as root inside their containers by default, including the ones built on `distroless/static`, which defaults to root unless you use the `:nonroot` tag
- The k8s manifests already apply some hardening at the pod level (`allowPrivilegeEscalation: false`, drop all Linux capabilities, `readOnlyRootFilesystem: true`) but don't set `runAsNonRoot` — so container-level and manifest-level hardening are two separate, only-partially-overlapping concerns

### How I'd explain it in an interview
- `kubectl set image` triggers a rolling update just like editing the manifest directly would — Kubernetes doesn't care how the Deployment's desired image changed, only that it did
- A multi-stage Dockerfile keeps the final runtime image small and free of build tools by copying only the compiled artifact from a `builder` stage into a clean final stage
- Pinning a base image by SHA256 digest instead of a mutable tag (e.g. `:alpine`) guarantees the exact same bytes get pulled every time, which matters for reproducible builds and supply-chain security

---

## Week 3 — Terraform for AKS

**Draft — rewrite this in your own words before treating it as done.**

### What I built
- Wrote Terraform for a resource group, VNet, subnet, and an AKS cluster from scratch
- Hit and fixed three real Azure errors in a row before it provisioned cleanly: a VM size not allowed on my subscription, a Service CIDR overlapping my own VNet's address space, and an in-place update ordering conflict between the VNet and subnet
- Actually provisioned a real AKS cluster on Azure, connected `kubectl` to it via `az aks get-credentials`, and explored it a bit (node labels, storage classes, resource allocation) before tearing it down
- Practiced the full "spin up → verify → tear down" cycle and confirmed via `az group show` that nothing was left running

### What confused me
- AKS has **three separate IP ranges** that can collide in non-obvious ways: the VNet/subnet's real range, kubenet's separate Pod CIDR, and a virtual, non-routable Service CIDR (defaults to `10.0.0.0/16`) used only for `ClusterIP` Services. My VNet's range happened to collide with the default Service CIDR even though the Service CIDR isn't "real" network space — Azure still rejects the overlap.
- Terraform doesn't guarantee ordering when updating two *already-existing, interdependent* resources in the same apply — trying to shrink the VNet's address space while the subnet still held its old (now out-of-bounds) range failed. Destroying and recreating from a corrected config sidestepped the issue entirely.
- A real AKS node runs way more system pods than a `kind` node — CSI storage drivers, a cloud-node-manager, a konnectivity-agent tunnel back to the control plane — none of which exist locally, because `kind` doesn't need real cloud-provider integration.

### How I'd explain it in an interview
- A node's `Capacity` (raw VM specs) and `Allocatable` (what's actually left for my workloads after the OS/kubelet reserve their share) are different numbers, and that gap is easy to forget when sizing a cluster
- Kubernetes resource `requests` are guaranteed, but `limits` can be — and routinely are — oversold across a node (I saw a node reporting 502% of its CPU capacity in allocated *limits*, which is normal, not a bug)
- The managed control plane (API server, etcd, scheduler) is free on AKS; only the node pool VMs are billed, which is why "spin up, verify, tear down fast" is the actual cost-control strategy, not a nice-to-have

---

## Week 4 — GitHub Actions CI pipeline

**Draft — rewrite this in your own words before treating it as done.**

### What I built
- A GitHub Actions pipeline for `currencyservice`: lint (Dockerfile via hadolint) → build → Trivy vulnerability scan → smoke test (container actually boots and stays up) → push to Docker Hub → Slack pass/fail notification
- Wired up a Slack incoming webhook and Docker Hub access token as GitHub repo secrets, so no credentials ever touch the workflow file or chat
- Found and fixed three real, unrelated bugs the pipeline surfaced before ever reaching production:
  1. A CRITICAL CVE (`protobufjs`, arbitrary code execution) pulled in transitively via an old, deprecated OpenTelemetry exporter — fixed with an `npm overrides` pin, verified with a real rebuild + boot test
  2. A separate CVE (`tar`, DoS) where the "real" fix broke the build entirely (incompatible with `node-pre-gyp`) — documented and formally accepted via `.trivyignore` instead, since the vulnerable code only runs at `npm install` time, never in the live service
  3. A completely unrelated Docker reproducibility bug: the final build stage installed Node.js unpinned (`apk add nodejs`), which had silently drifted to a newer major version than the pinned builder stage, breaking a native binary's ABI compatibility — invisible locally because Docker's build cache was hiding it, but would have broken on every single real CI run (CI always builds fresh, no cache)

### What confused me
- `npm audit` and Trivy scanning the actual built image can report *different* things, since they analyze different scopes — audit sees the full lockfile, Trivy sees what's actually installed in the final image layers
- Not every CVE fix is safe to apply blindly — forcing a transitive dependency to a newer major version can break things lower in the chain (`tar` v7's breaking changes vs. an old `node-pre-gyp` that never got updated for it). I had to actually test a fix, not just apply it and assume it worked.
- A bug can be real and 100% reproducible in CI while being completely invisible in local development, purely because of build caching — this is exactly why CI needs to build fresh, not trust a developer's cached image

### How I'd explain it in an interview
- A vulnerability's severity on paper (CRITICAL) and its actual exploitability in context (a build-time-only tool vs. code in the live request path) are two different questions — a good CVE triage separates them instead of treating every CRITICAL identically
- Multi-stage Docker builds need *every* stage's base image pinned consistently, not just the builder — pinning one stage and leaving another to float is a reproducibility bug waiting to happen
- CI's value isn't just "did it build" — the smoke test step (actually running the container, not just building it) is what caught two of the three bugs; a pipeline that only builds and pushes would have shipped a broken image straight to a registry

---

## Week 5 — Helm charts

**Draft — rewrite this in your own words before treating it as done.**

### What I built
- A Helm chart covering all 12 deployable objects (11 microservices + redis-cart), parameterizing replica counts, image repository/tag, and resource requests/limits through `values.yaml`
- `values.yaml` as the local-appropriate defaults (used automatically, no flag needed) plus a smaller `values-azure.yaml` override layer with just the deltas that differ for Azure — merged via `helm template -f values.yaml -f values-azure.yaml`, rather than duplicating the whole file for each environment
- Actually installed the chart into a real, separate namespace (`helm-test`) on the `kind` cluster to prove it deploys and boots correctly, not just that it lints/renders

### What confused me
- `helm lint` and `helm template` only check that a chart's *syntax* is valid and produces plausible YAML — neither one proves the resulting pods actually come up healthy. `helm install` reporting `STATUS: deployed` only means the API server accepted the manifests, not that anything inside them actually works. The real proof was `kubectl get pods` showing `1/1 Running`.
- I (Claude, doing the fast-tracked templating) dropped a required environment variable (`SHOPPING_ASSISTANT_SERVICE_ADDR`) from the `frontend` template, assuming it was only needed for an optional feature we don't use. It wasn't optional — the Go code reads it unconditionally at startup and panics if it's missing, regardless of whether the feature is actually invoked. This only surfaced because we deployed to a real namespace and checked pod status, not from lint/template/review alone.
- Using a separate Kubernetes **namespace** (`helm-test`) let us install the chart for real without touching or colliding with the already-running Week 1 deployment in `default` — two objects can share the exact same name as long as they're in different namespaces.

### How I'd explain it in an interview
- Helm's real value is separating a resource's *shape* (the template) from its *values* — one template, multiple values files, instead of maintaining full duplicate copies of manifests per environment
- A chart passing `helm lint`/`helm template` is a necessary but not sufficient check — the only real proof a chart works is deploying it and watching pods actually reach `Running`, same discipline as verifying any other change in this project
- Environment variables that look "just for an optional feature" can still be required at the code level even when the feature itself is unused — assuming otherwise without checking the actual startup code is exactly how this bug got introduced

