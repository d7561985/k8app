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

Define non-sensitive environment variables. Use `{env}` placeholder for environment substitution:

```yaml
configmap:
  # Static values
  LOG_LEVEL: "info"
  FEATURE_FLAG: "true"
  
  # Dynamic values with {env} substitution
  API_URL: "https://api.{env}.example.com"      # → api.dev.example.com
  REDIS_URL: "redis.{env}.internal:6379"        # → redis.dev.internal:6379
  DATABASE_NAME: "myapp_{env}"                  # → myapp_dev
```

The chart automatically:
1. Replaces `{env}` with your environment (dev/staging/prod)
2. Injects all values as environment variables via `envFrom`

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

---

## Worker

Deploy background worker processes alongside your main application.

### Basic Configuration

```yaml
worker:
  enabled: true
  spec:
    default:
      replicas: 2
      command: ["python", "worker.py"]
      args: ["--queue", "default"]
    priority:
      replicas: 1
      command: ["python", "worker.py"]  
      args: ["--queue", "priority"]
```

### Advanced Configuration

Workers support all the same features as the main deployment:

```yaml
worker:
  enabled: true
  spec:
    background:
      replicas: 3
      command: ["./worker"]
      args: ["--type", "background"]
      resources:
        limits:
          memory: "512Mi"
          cpu: "200m"
        requests:
          memory: "256Mi"  
          cpu: "100m"
      image:
        repository: "myorg/worker"
        tag: "v1.2.3"
      readinessProbe:
        httpGet:
          path: "/health"
          port: 8080
        initialDelaySeconds: 10
      livenessProbe:
        httpGet:
          path: "/health"
          port: 8080
        initialDelaySeconds: 30
```

Workers automatically inherit:
- Environment variables from secrets and configmap
- Volumes and volume mounts (including configfiles and shared volumes)
- Service account configuration
- Node selectors and tolerations
- Image pull secrets
- Extension/sidecar containers

---

## Job

Run one-time jobs for database migrations, data imports, etc.

### Basic Configuration

```yaml
job:
  enabled: true
  spec:
    migrate:
      command: ["python", "manage.py", "migrate"]
      backoffLimit: 2
    seed-data:
      command: ["python", "manage.py", "loaddata", "initial.json"]
      backoffLimit: 1
      resources:
        limits:
          memory: "1Gi"
          cpu: "500m"
```

### Full Configuration

```yaml
job:
  enabled: true
  spec:
    data-import:
      command: ["./import-script.sh"]
      args: ["--batch-size", "1000"]
      backoffLimit: 3
      activeDeadlineSeconds: 3600  # 1 hour timeout
      ttlSecondsAfterFinished: 86400  # Clean up after 24h
      resources:
        limits:
          memory: "2Gi"
          cpu: "1000m"
        requests:
          memory: "512Mi"
          cpu: "250m"
      env:
        IMPORT_MODE: "production"
        BATCH_SIZE: "1000"
```

Jobs automatically inherit:
- Environment variables from secrets and configmap
- Volumes and volume mounts (including configfiles)
- Service account configuration
- Node selectors and tolerations
- Image pull secrets

---

## CronJob

Schedule recurring tasks like backups, cleanup jobs, reports, etc.

### Basic Configuration

```yaml
cronjob:
  enabled: true
  spec:
    backup:
      schedule: "0 2 * * *"  # Daily at 2 AM
      command: ["./backup.sh"]
    cleanup:
      schedule: "0 4 * * 0"  # Weekly on Sunday at 4 AM
      command: ["./cleanup.sh"]
      args: ["--days", "30"]
```

### Advanced Configuration

```yaml
cronjob:
  enabled: true
  spec:
    report-generator:
      schedule: "0 9 * * 1"  # Weekly on Monday at 9 AM
      command: ["python", "generate_report.py"]
      args: ["--format", "pdf", "--email"]
      resources:
        limits:
          memory: "1Gi"
          cpu: "500m"
        requests:
          memory: "256Mi"
          cpu: "100m"
      concurrencyPolicy: "Forbid"
      successfulJobsHistoryLimit: 5
      failedJobsHistoryLimit: 3
      startingDeadlineSeconds: 600  # 10 minutes
      activeDeadlineSeconds: 1800   # 30 minutes
      suspend: false
```

CronJobs automatically inherit:
- Environment variables from secrets and configmap
- Volumes and volume mounts (including configfiles)
- Service account configuration  
- Node selectors and tolerations
- Image pull secrets

---

## HPA (Horizontal Pod Autoscaler)

Automatically scale your application based on CPU, memory, or custom metrics.

### Basic Configuration

```yaml
hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### Advanced Configuration

```yaml
hpa:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 60
  targetMemoryUtilizationPercentage: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent  
        value: 100
        periodSeconds: 15
```

### With Custom Metrics

```yaml
hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 15
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: queue_length
      target:
        type: AverageValue
        averageValue: "50"
```

**Note:** When HPA is enabled, the `replicas` field in deployment is ignored.

---

## PDB (Pod Disruption Budget)

Ensure high availability during node maintenance and cluster updates.

### Basic Configuration

```yaml
pdb:
  enabled: true
  minAvailable: 1
```

### Advanced Configuration

```yaml
pdb:
  enabled: true
  minAvailable: 2                # Keep at least 2 pods available
  # OR
  maxUnavailable: "25%"          # Allow max 25% of pods to be unavailable
  
  # Custom API version (defaults to policy/v1)
  apiVersion: "policy/v1"
  
  # Custom annotations
  annotations:
    description: "Ensure high availability during deployments"
```

**Best Practices:**
- Use `minAvailable` for critical services
- Use `maxUnavailable` as percentage for scalable services
- Don't set both `minAvailable` and `maxUnavailable`

---

## Alerting Rules

Define Prometheus alerting rules specific to your application.

### Basic Configuration

```yaml
alertRules:
  enabled: true
  groups:
    - name: myapp.rules
      rules:
        - alert: HighErrorRate
          expr: rate(http_requests_total{job="myapp",status=~"5.."}[5m]) > 0.1
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High error rate detected"
            description: "Error rate is {{ $value }} req/sec"
```

### Advanced Configuration

```yaml
alertRules:
  enabled: true
  additionalLabels:
    team: backend
    environment: production
  groups:
    - name: myapp.performance
      interval: 30s
      rules:
        - alert: HighLatency
          expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="myapp"}[5m])) > 0.5
          for: 2m
          labels:
            severity: warning
            service: myapp
          annotations:
            summary: "High latency on {{ $labels.instance }}"
            description: "95th percentile latency is {{ $value }}s"
            runbook_url: "https://docs.company.com/runbooks/high-latency"
            
        - alert: HighMemoryUsage
          expr: (container_memory_usage_bytes{container="myapp"} / container_spec_memory_limit_bytes{container="myapp"}) * 100 > 85
          for: 10m
          labels:
            severity: critical
            service: myapp
          annotations:
            summary: "High memory usage"
            description: "Memory usage is {{ $value }}% of limit"
```

---

## RBAC

Configure Role-Based Access Control for your application.

### Basic Configuration

```yaml
rbac:
  create: true  # Creates ServiceAccount, Role, and RoleBinding
```

### Advanced Configuration

```yaml
rbac:
  create: true
  serviceAccountName: "custom-service-account"  # Use existing SA instead
  
  # Custom annotations for ServiceAccount
  serviceAccountAnnotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT:role/myapp-role"
  
  # Additional rules for the Role
  rules:
    - apiGroups: [""]
      resources: ["secrets", "configmaps"]
      verbs: ["get", "list"]
    - apiGroups: ["apps"]
      resources: ["deployments"]
      verbs: ["get", "list", "patch"]
    
  # Additional ClusterRole (optional)
  clusterRole:
    create: true
    rules:
      - apiGroups: [""]
        resources: ["nodes"]
        verbs: ["get", "list"]
```

### AWS EKS IAM Integration

```yaml
rbac:
  create: true
  serviceAccountAnnotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/myapp-role"
    
# This allows your pods to assume AWS IAM roles
```

---

## ConfigFiles

Mount configuration files from ConfigMaps into your containers.

### Basic Configuration

```yaml
configfiles:
  enabled: true
  mountPath: "/etc/config"
  data:
    app.yaml: |
      database:
        host: postgres.example.com
        port: 5432
      logging:
        level: info
    nginx.conf: |
      server {
        listen 80;
        location / {
          proxy_pass http://localhost:8080;
        }
      }
```

### Advanced Configuration

```yaml
configfiles:
  enabled: true
  mountPath: "/etc/myapp"
  
  # Fine-grained file mounting
  files:
    - key: "database.yaml"
      path: "db/config.yaml" 
      mountPath: "/etc/myapp/database.yaml"  # Override per-file
    - key: "redis.conf"
      path: "cache/redis.conf"
  
  # File contents
  data:
    database.yaml: |
      host: {env}-db.example.com  # {env} replaced with environment
      port: 5432
      ssl: true
    redis.conf: |
      maxmemory 256mb
      maxmemory-policy allkeys-lru
      
  # Set custom ConfigMap name
  configMapName: "myapp-configs"
```

ConfigFiles are automatically available in:
- Main deployment containers
- Worker containers  
- Job containers
- CronJob containers
- InitContainer containers

---

## Extensions/Sidecars

Add sidecar containers to your pods for logging, monitoring, proxies, etc.

### Basic Configuration

```yaml
extensions:
  nginx-proxy:
    image:
      repository: nginx
      name: nginx
      tag: "1.21-alpine"
    command: ["nginx", "-g", "daemon off;"]
    
  log-shipper:
    image:
      repository: fluent
      name: fluent-bit  
      tag: "1.9"
    env:
      OUTPUT_HOST: "elasticsearch.logging.svc.cluster.local"
      OUTPUT_PORT: "9200"
```

### Advanced Configuration

```yaml
extensions:
  istio-proxy:
    image:
      repository: docker.io/istio
      name: proxyv2
      tag: "1.15.0"
    command: ["istio-proxy"]
    args: ["proxy", "sidecar"]
    resources:
      limits:
        memory: "256Mi"
        cpu: "200m"
      requests:
        memory: "128Mi"
        cpu: "100m"
    env:
      PILOT_AGENT_PORT: "15020"
      ISTIO_BOOTSTRAP: "/etc/istio-proxy/bootstrap.yaml"
    volumeMounts:
      - name: istio-proxy-config
        mountPath: /etc/istio-proxy
    livenessProbe:
      httpGet:
        path: /healthz/ready
        port: 15021
      initialDelaySeconds: 30
    readinessProbe:
      httpGet:
        path: /healthz/ready  
        port: 15021
      initialDelaySeconds: 10
      
  vault-agent:
    image:
      repository: vault
      name: vault
      tag: "1.12"
    command: ["vault", "agent"]
    args: ["-config", "/vault/config/agent.hcl"]
    configfiles:
      enabled: true
      mountPath: "/vault/config"
      data:
        agent.hcl: |
          vault {
            address = "https://vault.company.com"
          }
          auth {
            method "kubernetes" {
              config = {
                role = "myapp"
              }
            }
          }
```

### Extension Features

Extensions support most container features:
- Custom images, commands, and arguments
- Resource limits and requests
- Environment variables
- Health checks (liveness/readiness probes)
- Config files (separate ConfigMap per extension)
- Volume mounts from shared volumes

Extensions are available in:
- Main deployment pods
- Worker pods (when `extensions` is configured for workers)

### Use Cases

Common sidecar patterns:
- **Service Mesh:** Istio proxy, Linkerd proxy
- **Logging:** Fluentd, Fluent Bit, Filebeat
- **Monitoring:** Prometheus exporters, StatsD
- **Security:** Vault agent, secret rotation
- **Networking:** Ambassador, Nginx proxy
- **Caching:** Redis sidecar, Memcached

