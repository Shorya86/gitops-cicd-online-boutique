# Azure Cost Log

Every time we spin up billable Azure resources (AKS node pool VMs, etc.), log it here — start time, what was provisioned, end time, and roughly how long it ran. Discipline over precision: the point is proving you tore things down promptly, not exact-to-the-second billing math.

| Date | Resource(s) | Spin-up time | Torn down time | Duration | Notes |
|---|---|---|---|---|---|
| 2026-09-03 | AKS cluster (`project1-kc`, 1x Standard_D2as_v7 node, resource group `project1-rg`) | ~12:36 AM | ~12:53 AM | ~17 min | Week 3 — verified Terraform provisioning + real `kubectl` access to AKS. Two failed `apply` attempts before success (VM size not allowed in subscription, then Service CIDR overlap) added extra time but created nothing billable. Confirmed teardown via `az group show` returning `ResourceGroupNotFound`. |

