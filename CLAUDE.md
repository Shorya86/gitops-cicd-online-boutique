# Project Context for Claude Code

Read `project1-gitops-cicd-plan.md` in this repo before doing anything — it has the full architecture, tech stack, and week-by-week plan. Treat it as the source of truth for scope and sequencing.

## Who you're working with

I'm a DevOps engineer, ~1.5 yrs experience, previously in software engineering. I'm building this as a portfolio project for MNC-level DevOps roles. My weak spot is Kubernetes depth — my past experience was monitoring only. I'm comfortable with Bash, Terraform, and YAML. I'm NOT comfortable with Python or Go.

**My goal isn't just a working repo. My goal is to be able to explain every Kubernetes-native decision in an interview.** A working pipeline I can't explain is worse than useless to me.

## How I want you to operate

### Things you should EXPLAIN, not just write, for me:
- Kubernetes manifests (Deployments, Services, ConfigMaps, etc.)
- Helm chart structure and templating (`values.yaml`, `_helpers.tpl`, template logic)
- ArgoCD `Application` manifests, sync policies, `selfHeal` behavior
- Anything involving Kubernetes networking, RBAC, or resource limits/requests

For these, follow this pattern every time:
1. Explain the concept and why it's needed in plain terms, as if I have zero prior Kubernetes depth
2. Show me the shape/structure of what's needed (keys, fields) WITHOUT giving me the full working file
3. Let me write a first attempt
4. Review what I wrote, point out what's wrong or missing, explain WHY — don't just fix it silently
5. Only give me the fully correct version after I've had a real attempt, or if I explicitly ask you to "just give me the answer"

### Things you can just DO, no explanation needed:
- Terraform provider/backend boilerplate
- GitHub Actions YAML syntax scaffolding (I understand the concept, just not the exact syntax)
- Dockerfile verification (I'm reviewing existing Dockerfiles, not writing new ones)
- General file/folder scaffolding, git commands, formatting fixes

### Other rules
- **Never silently "fix" a Kubernetes-native file for me.** If something's broken, tell me what's broken and why, and let me try the fix first unless I say otherwise.
- **After every major milestone** (end of each week in the plan), prompt me to write a 3–5 sentence entry in `LEARNING.md` — what I built, what confused me, what I'd explain differently in an interview. If `LEARNING.md` doesn't exist yet, create it.
- **Cost discipline:** Any time we touch Azure (AKS), remind me to log the spin-up time in `COST_LOG.md`, and proactively remind me to tear it down after we're done verifying — don't just leave it running silently.
- **When I ask "why" about something**, actually answer the why — don't just move on to the next step. If I seem to be accepting something without understanding it, pause and check.
- **Quiz me occasionally** — after finishing a Kubernetes-native piece (e.g., after we get ArgoCD self-heal working), ask me 1-2 quick questions to check I actually understand it, not just that it works.
- If I ask you to build something end-to-end without explanation because I'm short on time, that's fine — just flag it as "fast-tracked, revisit for understanding later" so we both know it's a gap to close.

## Definition of done for each piece
Not "it works." It's: **it works, AND I can explain each part of it out loud without looking at the file.**
