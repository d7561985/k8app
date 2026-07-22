# Changelog

## [3.16.0] - 2026-07-22

### Added
- **Extensions** — extension (sidecar) containers in the main `Deployment` now render `ports`. Set `extensions.<name>.ports` (a standard container `ports` list) and it appears on the sidecar

### Fixed
- **Extensions** — `resources` declared on an extension were silently dropped by `deployment.yaml` (rendered only for `worker` pods), so every sidecar ran unbounded even though `extensions.<name>.resources` is documented and honored elsewhere. The Deployment's extension container now renders `resources`, matching `worker.yaml`
- **Extensions** — an extension's `volumeMounts` (from `configfiles` / `sharedVolumes`) were nested inside `{{ if $spec.readinessProbe }}` because the readiness-probe block was missing a closing `{{ end }}`. A sidecar with `configfiles` but no probe therefore silently kept the image's default config (nothing mounted). The block is now closed correctly, so mounts render regardless of whether a probe is set

### Notes
- Backward compatible where the chart already produced correct output. Rendered output changes only in the cases these fixes target: extensions that declared `resources` (now applied), `ports` (now applied), or `configfiles` / `sharedVolumes` without a probe (now mounted)

## [3.15.0] - 2026-07-04

### Added
- **Job** — optional `job.argocd` block (`hook`, `hookDeletePolicy`, `syncWave`) to control the ArgoCD lifecycle annotations of Jobs. Defaults preserve the historical behavior (`PreSync` / `BeforeHookCreation` / no sync-wave)
- **Secrets (Vault)** — opt-in `secretsProvider.vault.rolloutRestart` (default `false`): each `VaultStaticSecret` lists the chart's own workloads (main Deployment + every worker Deployment) in `spec.rolloutRestartTargets`, so VSO rollout-restarts them when a synced secret changes
- Unit tests: 2 new suites (job, vault-static-secret), 10 tests

### Fixed
- **ArgoCD PreSync deadlock on a fresh cluster** (via the new `job.argocd` knobs): with `secretsProvider.provider: vault` the Job's `envFrom` references a Secret created by a `VaultStaticSecret` — a Sync-phase resource. A `PreSync` hook waits for a Secret that only appears in the Sync phase, so the very first sync never completes. Setting `job.argocd.hook: Sync` + `syncWave: "-1"` runs the Job after the `VaultStaticSecret` while still gating the sync-wave `0` workloads
- **Stale env after Vault secret rotation** (via `rolloutRestart`): secrets are injected through `envFrom` and read once at pod startup; without restart targets pods kept old values until the next deploy or a manual `kubectl rollout restart`

### Notes
- Fully backward compatible: with no new keys set, rendered output is byte-for-byte unchanged

## [3.14.0] - 2026-06-05

### Added
- **CronJob** — per-cron tuning knobs, all optional with backward-compatible defaults:
  - `backoffLimit` (default `6`) — retries before a Job is marked Failed; set `0` for a single Pod per run
  - `ttlSecondsAfterFinished` — opt-in auto-deletion of finished Jobs (and their Pods)
  - `concurrencyPolicy` (default `Forbid`), `failedJobsHistoryLimit` (default `10`) and `successfulJobsHistoryLimit` (default `3`) are now read from each cron spec instead of being hardcoded (matches what the README already documented)

### Fixed
- **CronJob** — with `restartPolicy: Never` the default `backoffLimit` (6) makes a failing Job spawn up to 7 Pods; combined with `failedJobsHistoryLimit` (10) a continuously failing cron piled up dozens of `Error` Pods that could not be tuned from values. Now controllable per-cron.
- **Cache** — `cache-deployment.yaml` did not set `revisionHistoryLimit`, so it fell back to the Kubernetes default of 10 and accumulated ~10 stale (0-replica) ReplicaSets per service. Pinned to `1` to match the main Deployment template.

### Notes
- Fully backward compatible: with no new keys set, rendered output is byte-for-byte unchanged. Numeric keys use `dig` (not `default`) so `0` is honored (e.g. `backoffLimit: 0`, which `default` would wrongly turn back into `6`).

## [3.13.0] - 2026-02-24

### Added
- **Unit tests** — 9 test suites, 46 tests via helm-unittest
  - deployment, service, httproute, worker, cronjob, pdb, hpa, configmap, cache
- Test coverage for: probe modes, strategies, tolerations, resources, image pull secrets, gateway API routes with URLRewrite filters, HPA/PDB configs, cache Redis stack

### Fixed
- Nothing (test-only release)

### Notes
- Discovered: `nodeSelector` missing from `deployment.yaml` (present in worker/cronjob/job) — tracked as known gap
- Warning: `tolerations: {}` (map) in values.yaml conflicts with list override — cosmetic, no functional impact

## [3.12.1] - 2026-02-23

### Added
- 6 bugfixes (PDB apiVersion, filename typo, jaeger unification, worker serviceAccount, examples)
- 4 named templates in `_helpers.tpl` (envFrom, secretVolumes, secretVolumeMounts, imagePullSecrets)
- 8 new features (worker: configfiles/sharedVolumes/tolerations/cache/extensions; cronjob: imagePullSecrets/resources/configfiles)
- CONTRIBUTING.md, enhanced README, NOTES.txt
- HTTPRoute template for Gateway API
