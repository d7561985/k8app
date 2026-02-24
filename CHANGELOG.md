# Changelog

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
