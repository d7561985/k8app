# Changelog

## app

### 3.10.5
* **Fix:** Added Vault secrets provider support to job.yaml and cronjob.yaml
  * Jobs and CronJobs now correctly receive secrets when using `secretsProvider.provider: vault`
  * Uses `envFrom` with `secretRef` matching vault-static-secret naming convention
  * CSI volumes only mounted for AWS provider or legacy mode

### 3.10.4
* **Feature:** Worker-specific image override
  * Each worker can now use a different image via `worker.spec.<name>.image`
  * Supports `repository`, `tag`, and `pullPolicy` overrides
  * Defaults to main `image` values if not specified

### 3.10.3
* **Fix:** Added missing `imagePullSecrets` support to worker.yaml
  * Workers now correctly use private registry credentials
  * Supports both new `imagePullSecrets` and legacy `deploySecretHarbor`/`deploySecretNexus`

### 3.10.2
* **Fix:** Numeric values in `commands` and `args` now properly quoted as strings
  * Fixes Kubernetes validation error when using port numbers in commands
  * Applied to: deployment, worker, job, cronjob templates

### 3.10.1
* **ArgoCD Sync-Wave Support** - Universal resource ordering for GitOps deployments
  * Added `argocd.argoproj.io/sync-wave` annotations to all resources
  * Wave -2: VaultStaticSecret (secrets first)
  * Wave -1: ConfigMap, configfiles (before deployments)
  * Wave 0: Deployment, Worker (main application)
  * Wave 1: Ingress, HTTPRoute, ServiceMonitor (after app ready)
  * Wave 2: HPA (after deployment stable)
  * Fixes `MountVolume.SetUp failed: configmap not found` in ArgoCD multi-source apps
  * Helm hooks preserved for standalone Helm usage

### 3.10.0
* **ConfigFiles subPath Support** - Mount individual files without overwriting directories
  * New `configfiles.files` array for per-file mount configuration
  * Uses Kubernetes `subPath` to inject files into existing directories
  * Preserves other files in the target directory (from Docker image)
  * Supports custom `mountPath` per file for different target locations
  * Works with extensions configfiles
  * Backward compatible - without `files`, behavior unchanged (mount entire directory)

### 3.9.2
* **Fix:** Label truncation now uses last 63 characters without prefix (labels must start with alphanumeric)

### 3.9.1
* **Long Image Tag Truncation** - Automatic label value truncation for Kubernetes compliance
  * Labels limited to 63 characters per Kubernetes spec
  * New `k8app.labelVersion` helper truncates long tags to last 63 characters
  * Preserves timestamp suffix which is typically unique and informative
  * Full tag preserved in `image:` and `VERSION` env var
  * Fixes: `metadata.labels: Invalid value: must be no more than 63 characters`

### 3.9.0
* **Multi-Source Secrets** - Support for multiple Vault paths with shared secrets
  * Explicit paths with `{env}` placeholder: `brand/shared/{env}/config`
  * Automatic grouping by Vault path - one VaultStaticSecret per unique path
  * `transformation.includes` filters only specified keys from each path
  * Shared secrets without duplication - one source for multiple services
  * Simplified secret rotation - update once, synced everywhere
* **envFrom injection** - Cleaner secret mounting
  * Replaced individual `secretKeyRef` with `envFrom` + `secretRef`
  * Less boilerplate in generated manifests
  * Automatic reference to all vault secrets
* **Stable path ordering** - Sorted paths prevent unnecessary ArgoCD diffs
* **Breaking change**: Path format changed from relative (`database`) to explicit (`brand/app/{env}/config`)

### 3.8.0
* **ServiceMonitor Support** - Native Prometheus Operator integration
  * New `serviceMonitor` configuration for automatic metrics discovery
  * Works with kube-prometheus-stack out of the box
  * Configurable scrape interval, timeout, path, and port
  * Support for relabelings and metricRelabelings
  * Graceful degradation - skipped if Prometheus Operator CRDs not installed
* **Cache Exporter ServiceMonitor** - Redis metrics via Prometheus Operator
  * Moved to `cache.exporter.serviceMonitor` (follows single responsibility)
  * Enabled by default when `cache.exporter.enabled=true`

### 3.7.0
* **In-Memory Cache (Redis)** - On-demand ephemeral Redis for your service
  * New `cache` configuration for dedicated Redis instance
  * Automatic `REDIS_URL` environment variable injection
  * Prometheus metrics exporter (oliver006/redis_exporter) as sidecar
  * Optimized redis.conf with LRU eviction, no persistence
  * Configurable resources, maxmemory, eviction policy

### 3.6.0
* **Gateway API HTTPRoute Support** - Modern alternative to Ingress
  * New `httpRoute` configuration for Kubernetes Gateway API
  * Supports path-based routing, header matching, traffic splitting (canary)
  * Cross-namespace backend references
  * Compatible with Cilium, Envoy Gateway, NGINX Gateway Fabric, Istio

### 3.5.2
* **VaultStaticSecret release-triggered sync** - Added `app.kubernetes.io/version` annotation
  * VSO immediately syncs secrets on new release (no waiting for `refreshAfter`)
  * ArgoCD detects annotation change when `image.tag` updates

### 3.5.1
* Fix: `serviceAccountName` default changed from `app` to empty (uses Kubernetes `default`)
* Fix: Template whitespace issue with `initContainers` block

### 3.5.0
* **Shared Volumes** - New `sharedVolumes` feature
  * Share volumes between main container, initContainers, and extensions
  * Supports `emptyDir`, `configMap`, and `secret` volume types
  * Automatic naming convention: `{appname}-{volumename}`

### 3.4.0
* **Secrets Management Overhaul** - Developer-friendly secrets interface
  * Simple `secrets` map works like `configmap` - just specify `ENV_VAR: "path"`
  * Automatic path generation: `{namespace}/{appName}/{environment}/{path}`
  * Absolute paths support (prefix with `/`)
* **HashiCorp Vault Secrets Operator (VSO) support**
  * New provider `secretsProvider.provider: "vault"`
  * Creates `VaultStaticSecret` resources automatically
  * No CSI driver needed - VSO syncs directly to K8s Secrets
* **AWS Secrets Manager improvements**
  * New provider `secretsProvider.provider: "aws"`
  * Unified interface with Vault provider
* **Universal imagePullSecrets**
  * New `imagePullSecrets` array for any container registry
  * Supports multiple registries (GitLab, Docker Hub, GHCR, etc.)
* **Deprecations**
  * `valult` parameter now fails with migration guide
  * `deploySecretHarbor`/`deploySecretNexus` deprecated (still works)
* **Documentation** - Comprehensive README with examples for developers and DevOps

### 3.1.31
* kubernetes-pods obtain cluster and component lables

### 3.1.12
* update obsolete version of Ingres kind up to networking.k8s.io/v1 (added pathType + fixed port notion)

### 3.1.10
* volume ReadOnly option required for EFS
* refactor value mountPath

### 3.1.9
* EFS implementation

### 3.1.6
* toleration for deployment
### 3.1.5
* fix resources with partial implementation

### 3.1.4
* tel variable VERSION support

### 3.1.3
* deployment: resources request/limits 


### 3.1.2
* deployment: lifecycle option moved to values. Because our distress doesn't have any sleep command we should consider dont use it as hardcode

### 3.1.1
* deployment: set `revisionHistoryLimit: 1` ToDo: move to values 

### 3.1.0
* trigger pods to restart when only config file or secrets was changed. Allow reconcile changes with already on-live services.

### 3.0.8, 3.0.9
* cronjob fix
* this crd appload when tag is number

### 3.0.6, 3.0.7
* documentation
* volume mounts
 
### 3.0.5
* worker bug fix

### 3.0.4
* `commands` and `args` commands 

### 3.0.3
* secrets should redeploy every new secret changes or when tag is changed
* example values, min working values 


## Agent
### 0.5.23-26
* kubernetes-kubelet finally

### 0.5.17
* scrap agent metrics from service discovery
* loki tags for correct processing
### 0.5.18
* not use prometheus reseiver
* tune otlp connection