# app

GitOps application optimized for AWS EKS

## Table of Contents

- [Quick Start](#quick-start)
- [Gateway API](#gateway-api)
- [Secrets](#secrets)
  - [For Developers](#for-developers)
  - [Path Convention](#path-convention)
  - [For DevOps/Infrastructure](#for-devopsinfrastructure)
- [ConfigMap](#configmap)
- [Image Pull Secrets](#image-pull-secrets)
- [Volume](#volume)
- [Shared Volumes](#shared-volumes)
- [In-Memory Cache (Redis)](#in-memory-cache-redis)
- [ServiceMonitor](#servicemonitor)

---

## Quick Start

Minimal configuration for a new application:

```yaml
appName: "myapp"
environment: "dev"

# Expose via Gateway API
gateway:
  enabled: true
  hostname: myapp.example.com

# Environment variables from secrets
secrets:
  DB_PASSWORD: "brand/myapp/{env}/config"
  SHARED_SECRET: "brand/shared/{env}/config"

# Environment variables from configmap
configmap:
  LOG_LEVEL: "info"
  API_URL: "https://api.example.com"
```

That's it! The chart handles everything else automatically.

---

## Secrets

### For Developers

Define environment variables with explicit Vault paths. Use `{env}` placeholder for environment substitution:

```yaml
secrets:
  # Shared secrets (one source for all services)
  RABBITMQ_PASSWORD: "brand/shared/{env}/config"
  RABBITMQ_USER: "brand/shared/{env}/config"

  # Service-specific secrets
  DB_PASSWORD: "brand/myapp/{env}/config"
  API_KEY: "brand/myapp/{env}/config"

  # Static path (no {env} substitution)
  MONGO_CERT: "brand/mongodb/client-cert"
```

The chart automatically:
1. Replaces `{env}` with your environment (dev/staging/prod)
2. Groups secrets by Vault path
3. Creates VaultStaticSecret for each unique path
4. Filters only specified keys via `transformation.includes`
5. Injects secrets as environment variables via `envFrom`

### Path Convention

```
{brand}/{app-or-shared}/{env}/config
```

| You specify | Result (environment=dev) |
|-------------|--------------------------|
| `brand/myapp/{env}/config` | `brand/myapp/dev/config` |
| `brand/shared/{env}/config` | `brand/shared/dev/config` |
| `brand/mongodb/client-cert` | `brand/mongodb/client-cert` (no substitution) |

### Benefits of Shared Secrets

**Before (duplication):**
```bash
# Same password in 5 places
vault kv put secret/brand/finance/dev/config RABBITMQ_PASSWORD="xxx"
vault kv put secret/brand/messaging/dev/config RABBITMQ_PASSWORD="xxx"
vault kv put secret/brand/payments/dev/config RABBITMQ_PASSWORD="xxx"
# ...rotation = 5 operations
```

**After (single source):**
```bash
# One place for all services
vault kv put secret/brand/shared/dev/config RABBITMQ_PASSWORD="xxx"
# rotation = 1 operation, auto-synced to all services
```

### For DevOps/Infrastructure

The `secretsProvider` section configures which backend to use:

```yaml
secretsProvider:
  provider: "vault"  # or "aws" or "none"

  vault:
    authRef: "vault-auth"     # VaultAuth resource (create once per namespace)
    mount: "secret"           # KV engine mount
    type: "kv-v2"             # kv-v2 recommended
    refreshAfter: "1h"        # Sync interval

  aws:
    provider: "aws"           # For AWS SSM/Secrets Manager
```

#### Supported Providers

| Provider | Backend | Requirements |
|----------|---------|--------------|
| `vault` | HashiCorp Vault | [Vault Secrets Operator](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/vso) |
| `aws` | AWS SSM/Secrets Manager | [Secrets Store CSI Driver](https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html) |
| `none` | Legacy AWS CSI (default) | Secrets Store CSI Driver |

#### Generated Resources

**Vault provider** creates `VaultStaticSecret` for each unique path:

```yaml
# Input:
# secrets:
#   RABBITMQ_PASSWORD: "brand/shared/{env}/config"
#   RABBITMQ_USER: "brand/shared/{env}/config"
#   DB_PASSWORD: "brand/myapp/{env}/config"

# Output: 2 VaultStaticSecrets

# 1. Shared secrets
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: myapp-vault-0
spec:
  type: kv-v2
  mount: secret
  path: brand/shared/dev/config
  vaultAuthRef: vault-auth
  destination:
    name: myapp-vault-0
    create: true
    transformation:
      excludeRaw: true
      includes:
        - RABBITMQ_PASSWORD
        - RABBITMQ_USER
---
# 2. Service-specific secrets
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: myapp-vault-1
spec:
  type: kv-v2
  mount: secret
  path: brand/myapp/dev/config
  vaultAuthRef: vault-auth
  destination:
    name: myapp-vault-1
    create: true
    transformation:
      excludeRaw: true
      includes:
        - DB_PASSWORD
```

**Deployment** automatically references all secrets:

```yaml
spec:
  containers:
    - name: myapp
      envFrom:
        - secretRef:
            name: myapp-vault-0  # RABBITMQ_PASSWORD, RABBITMQ_USER
        - secretRef:
            name: myapp-vault-1  # DB_PASSWORD
```

---

## ConfigMap

Define non-sensitive environment variables:

```yaml
configmap:
  LOG_LEVEL: "info"
  API_URL: "https://api.example.com"
  FEATURE_FLAG: "true"
```

All keys are automatically injected as environment variables.

---

## Image Pull Secrets

Universal support for any container registry.

### New Configuration (Recommended)

```yaml
imagePullSecrets:
  - name: gitlab-registry
  - name: docker-hub
  - name: ghcr-secret
```

### Legacy Configuration (Deprecated)

```yaml
# DEPRECATED - Still works but not recommended
deploySecretHarbor: true   # Uses hardcoded "regsecret" name
deploySecretNexus: true    # Uses hardcoded "regsecret" name
```

### Creating Registry Secrets

```bash
# GitLab Container Registry
kubectl create secret docker-registry gitlab-registry \
  --docker-server=registry.gitlab.com \
  --docker-username=<deploy-token-user> \
  --docker-password=<deploy-token> \
  -n <namespace>

# Docker Hub
kubectl create secret docker-registry docker-hub \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<username> \
  --docker-password=<token> \
  -n <namespace>

# GitHub Container Registry
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<username> \
  --docker-password=<github-pat> \
  -n <namespace>
```

---

## Volume
Mount shared volume between pods and worker including init containers 
We use dynamic provision approach.

Create `StorageClass` if `.Values.volume.storageClass.create` is provided
```yaml
volume:
  ...
    create:
      provisioner: "ebs.csi.aws.com"
      parameters:
        type: gp3
        iops: "3000"
```
otherwise is assumed that StorageClass already exists and will use it name - `.volume.storageClass.name`. Note: gp2 - default EKS StorageClass available by default via provision: `kubernetes.io/aws-ebs`

Create `PersistentVolumeClaim` for specific app and mount it. Service mount `readOnly` mode only

example:
```yaml
volume:
  enabled: true
  mountPath: "/my-path"
  resources:
    requests:
      storage: 2Gi
  storageClass:
    name: sc
    create:
      provisioner: "ebs.csi.aws.com"
      parameters:
        type: gp3
        iops: "3000"
```

### StorageClass
Default storage class provision `kubernetes.io/aws-ebs` name: `gp2`

With addon `aws-ebs-csi-driver` we get provision: `ebs.csi.aws.com`
- [examples](https://github.com/kubernetes-sigs/aws-ebs-csi-driver/tree/master/examples)

`ebs.csi.aws.com` allow provision `gp3` type volume with dynamic provision [parameters](https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/parameters.md) + [AWS EBS volume types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html)

### EFS

StorageClass:
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
mountOptions:
  - tls
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-0c0dcd94ecc6637aa
  directoryPerms: "777"
  gidRangeStart: "1000"
  gidRangeEnd: "2000"
  basePath: "/app"
```

PersistentVolumeClaim:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
```

---

## Shared Volumes

Share volumes between main container, initContainers, and extensions (sidecars).

### Supported Volume Types

| Type | Description |
|------|-------------|
| `emptyDir` | Temporary storage, deleted when pod terminates |
| `configMap` | Mount ConfigMap as volume |
| `secret` | Mount Secret as volume |

### Examples

```yaml
sharedVolumes:
  # Temporary shared storage (disk-backed)
  temp-data:
    type: emptyDir
    mountPath: /tmp/shared

  # In-memory cache (faster, limited by RAM)
  cache:
    type: emptyDir
    medium: Memory
    mountPath: /cache

  # ConfigMap volume
  app-config:
    type: configMap
    name: my-configmap      # Optional: defaults to {appname}-{volumename}
    mountPath: /etc/config
    readOnly: true

  # Secret volume
  tls-certs:
    type: secret
    name: my-tls-secret     # Optional: defaults to {appname}-{volumename}
    mountPath: /etc/ssl/certs
    readOnly: true
```

### Use Cases

- **Init data sharing**: initContainer prepares data, main container uses it
- **Sidecar communication**: Main app and sidecar share files via emptyDir
- **Config injection**: Mount ConfigMaps/Secrets as files instead of env vars
- **Caching**: In-memory tmpfs for fast temporary storage

---

## Gateway API

Modern alternative to Ingress. Multiple HTTPRoutes can attach to the same Gateway — each service defines its own path, Gateway merges them automatically.

**Prerequisites:**
```bash
# Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
```

### Simple Frontend (Minimal Config)

```yaml
gateway:
  enabled: true
  hostname: site.example.com
```

That's it! Everything else is auto-derived:
- `parentRef.name`: `gateway` (platform default)
- `parentRef.namespace`: from `Release.Namespace`
- `parentRef.sectionName`: `http-app` (platform default)
- `path`: `/`
- `backendRefs.name`: `{appName}-sv`
- `backendRefs.port`: from `service.ports.http.externalPort`

### Multi-Service Routing (Same Hostname, Different Paths)

Multiple services can share the same hostname. Each service deploys its own HTTPRoute with a different path:

```yaml
# site/values.yaml (main frontend)
gateway:
  enabled: true
  hostname: site.example.com
  # path: /  (default)

# api/values.yaml
gateway:
  enabled: true
  hostname: site.example.com
  path: /api

# bonus/values.yaml
gateway:
  enabled: true
  hostname: site.example.com
  path: /bonus
```

**Result:** Gateway merges all routes:
| Path | Service |
|------|---------|
| `/` | site-sv |
| `/api` | api-sv |
| `/bonus` | bonus-sv |

### Custom Gateway Reference

```yaml
gateway:
  enabled: true
  hostname: site.example.com
  parentRef:
    name: external-gateway
    namespace: gateway-system
    sectionName: https
```

### Multiple Hostnames

```yaml
gateway:
  enabled: true
  hostnames:
    - site.example.com
    - www.example.com
```

### Traffic Splitting (Canary)

Use `rules` escape hatch for advanced routing:

```yaml
gateway:
  enabled: true
  hostname: app.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: frontend-sv
          port: 80
          weight: 90
        - name: frontend-canary-sv
          port: 80
          weight: 10
```

### Header-Based Routing (A/B Testing)

```yaml
gateway:
  enabled: true
  hostname: app.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
          headers:
            - name: X-Version
              value: beta
      backendRefs:
        - name: frontend-beta-sv
          port: 80
    - matches:
        - path:
            type: PathPrefix
            value: /
```

### Configuration Reference

| Field | Default | Description |
|-------|---------|-------------|
| `enabled` | `false` | Enable HTTPRoute creation |
| `hostname` | - | Single hostname (shorthand) |
| `hostnames` | `[]` | Multiple hostnames |
| `path` | `/` | Path prefix for this service |
| `pathType` | `PathPrefix` | `PathPrefix` or `Exact` |
| `parentRef.name` | `gateway` | Gateway resource name |
| `parentRef.namespace` | `Release.Namespace` | Gateway namespace |
| `parentRef.sectionName` | `http-app` | Gateway listener name |
| `backend.service` | `{appName}-sv` | Backend service name |
| `backend.port` | `service.ports.http.externalPort` | Backend port |
| `parentRefs` | `[]` | Advanced: full parentRefs array |
| `rules` | `[]` | Advanced: full rules array |

**References:**
- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [HTTPRoute API Reference](https://gateway-api.sigs.k8s.io/api-types/httproute/)
- [Cross-Namespace Routing](https://gateway-api.sigs.k8s.io/guides/multiple-ns/)

---

## In-Memory Cache (Redis)

On-demand ephemeral Redis instance dedicated to your service. Perfect for session storage, API caching, rate limiting.

**Features:**
- Dedicated Redis per service (no shared state)
- Ephemeral by design (no persistence)
- Auto-eviction with LRU policy
- Prometheus metrics exporter included
- Automatic `REDIS_URL` environment variable

### Basic Usage

```yaml
cache:
  enabled: true
```

This creates:
- Redis deployment (`{appname}-cache`)
- Service (`{appname}-cache-sv:6379`)
- ConfigMap with optimized redis.conf
- `REDIS_URL` env var in your app

### Custom Resources

```yaml
cache:
  enabled: true
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  maxmemory: "400mb"  # Must be < limits.memory
```

### Full Configuration

```yaml
cache:
  enabled: true
  image:
    repository: redis
    tag: "7-alpine"
  port: 6379
  resources:
    requests:
      memory: "64Mi"
      cpu: "50m"
    limits:
      memory: "256Mi"
      cpu: "200m"
  maxmemory: "200mb"
  maxmemoryPolicy: "allkeys-lru"  # or volatile-lru, allkeys-lfu, etc.
  extraConfig: |
    # Additional redis.conf options
    tcp-keepalive 60
  exporter:
    enabled: true  # Prometheus metrics on :9121/metrics
    image:
      repository: oliver006/redis_exporter
      tag: "v1.66.0"
```

### Connecting from Your App

The `REDIS_URL` environment variable is automatically set:

```go
// Go
redisURL := os.Getenv("REDIS_URL")  // redis://myapp-cache-sv:6379
```

```python
# Python
import os
redis_url = os.environ["REDIS_URL"]
```

```javascript
// Node.js
const redisUrl = process.env.REDIS_URL;
```

### Eviction Policies

| Policy | Description | Use Case |
|--------|-------------|----------|
| `allkeys-lru` | Evict least recently used keys | General caching (default) |
| `allkeys-lfu` | Evict least frequently used keys | Hot data caching |
| `volatile-lru` | Evict LRU keys with TTL set | Mixed cache + persistent |
| `volatile-ttl` | Evict keys with shortest TTL | TTL-based caching |

### Important Notes

- **Ephemeral**: Data is lost on pod restart (by design)
- **Single replica**: Not for HA, use managed Redis for that
- **maxmemory**: Always set lower than `resources.limits.memory`
- **Dangerous commands disabled**: FLUSHDB, FLUSHALL, DEBUG

---

## ServiceMonitor

Native Prometheus Operator integration for automatic metrics discovery. Works with kube-prometheus-stack out of the box.

**Prerequisites:**
- Prometheus Operator or kube-prometheus-stack installed
- ServiceMonitor CRD (`monitoring.coreos.com/v1`) available in cluster

### Basic Usage

```yaml
service:
  enabled: true
  ports:
    http:
      externalPort: 8080
      internalPort: 8080

serviceMonitor:
  enabled: true
  labels:
    release: prometheus  # Match your Prometheus selector
```

This creates a ServiceMonitor that:
- Scrapes `/metrics` on port `http`
- Uses 30s scrape interval
- Auto-discovered by Prometheus Operator

### Dedicated Metrics Port

```yaml
service:
  enabled: true
  ports:
    http:
      externalPort: 8080
      internalPort: 8080
    metrics:
      externalPort: 9090
      internalPort: 9090

serviceMonitor:
  enabled: true
  port: "metrics"
  path: "/metrics"
  labels:
    release: prometheus
```

### Full Configuration

```yaml
serviceMonitor:
  enabled: true
  interval: 30s          # Scrape interval
  scrapeTimeout: 10s     # Must be less than interval
  path: "/metrics"       # Metrics endpoint path
  port: "http"           # Service port name (from service.ports)
  labels:                # Labels for Prometheus selector
    release: prometheus
  relabelings: []        # Relabeling rules
  metricRelabelings: []  # Metric relabeling rules
```

### With Redis Cache Monitoring

```yaml
cache:
  enabled: true
  exporter:
    enabled: true
    # ServiceMonitor auto-enabled when exporter is enabled
    serviceMonitor:
      enabled: true  # default: true
      labels:
        release: prometheus

serviceMonitor:
  enabled: true
  labels:
    release: prometheus
```

Cache exporter ServiceMonitor is enabled by default when `cache.exporter.enabled=true` - no extra configuration needed.

### Graceful Degradation

If Prometheus Operator CRDs are not installed, ServiceMonitor creation is silently skipped. This allows the same chart to work in clusters with and without Prometheus Operator.

### Migration from Annotations

**Old approach (annotations-based):**
```yaml
prometheus:
  enabled: true
  port: "8011"
  path: "/metrics"
```

**New approach (ServiceMonitor):**
```yaml
serviceMonitor:
  enabled: true
  port: "http"
  path: "/metrics"
```

Both approaches can coexist. ServiceMonitor is preferred for Prometheus Operator deployments.

