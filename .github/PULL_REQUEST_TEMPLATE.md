## What changed and why

<!-- Summarize the infrastructure change and the reason for it. -->

## Scope

- [ ] New/changed leaf module (`modules/<cloud>/<service>/`)
- [ ] New/changed region-stack composition (`modules/<cloud>/region-stack/`)
- [ ] New/changed environment or region (`environments/<env>/<cloud>/<region>/`)
- [ ] Pipeline/workflow change (`.github/workflows/`)
- [ ] `.github/region-matrix.json` updated (required when adding/removing a region)

## Checklist

- [ ] `terraform fmt -recursive` run
- [ ] `terraform validate` passes for every affected root
- [ ] Terraform Plan pipeline comment reviewed on this PR for every affected environment/cloud/region cell
- [ ] If a new region was added: `region_index` in `region-matrix.json` is unique repo-wide (never reused)
- [ ] If this touches `staging` or `production`: aware that apply requires a manual approval in the corresponding GitHub Environment after merge

## Rollback plan

<!-- How to revert if the applied change causes problems (e.g. revert commit + re-apply, or targeted `terraform apply -target=...`). -->
