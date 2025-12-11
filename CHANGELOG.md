# Changelog

## app

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