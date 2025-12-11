# app

GitOps application optimized for AWS EKS

## Table of Contents

- [Quick Start](#quick-start)
- [Secrets](#secrets)
  - [For Developers](#for-developers)
  - [Path Convention](#path-convention)
  - [For DevOps/Infrastructure](#for-devopsinfrastructure)
- [ConfigMap](#configmap)
- [Image Pull Secrets](#image-pull-secrets)
- [Volume](#volume)
- [Shared Volumes](#shared-volumes)

---

## Quick Start

Minimal configuration for a new application:

```yaml
appName: "myapp"
environment: "dev"

# Environment variables from secrets (just like configmap!)
secrets:
  DB_PASSWORD: "database"
  DB_USER: "database"
  API_KEY: "api"

# Environment variables from configmap
configmap:
  LOG_LEVEL: "info"
  API_URL: "https://api.example.com"
```

That's it! The chart handles everything else automatically.

---

## Secrets

### For Developers

Secrets work exactly like `configmap` - just define your environment variables:

```yaml
secrets:
  DB_PASSWORD: "database"      # Will be available as $DB_PASSWORD in your app
  DB_USER: "database"          # Same Vault path, different key
  API_KEY: "external/api"      # Different path
```

The chart automatically:
1. Fetches secrets from Vault/AWS
2. Creates a Kubernetes Secret
3. Injects all keys as environment variables into your pods

**You don't need to know about VaultStaticSecret, SecretProviderClass, or any Kubernetes internals.**

### Path Convention

Secrets are organized using a standardized path:

```
{namespace}/{appName}/{environment}/{your-path}
```

| You specify | Full path (auto-generated) |
|-------------|----------------------------|
| `database` | `myns/myapp/dev/database` |
| `external/api` | `myns/myapp/dev/external/api` |
| `/shared/global` | `shared/global` (absolute path) |

**Absolute paths** (starting with `/`) bypass the convention and use the exact path.

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

**Vault provider** creates `VaultStaticSecret`:

```yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: myapp
spec:
  type: kv-v2
  mount: secret
  path: myns/myapp/dev/database
  vaultAuthRef: vault-auth
  destination:
    name: myapp
    create: true
```

**AWS provider** creates `SecretProviderClass`:

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: myapp-aws-secrets
spec:
  provider: aws
  secretObjects:
    - secretName: myapp
      type: Opaque
      data:
        - objectName: "DB_PASSWORD"
          key: "DB_PASSWORD"
```

### Migration from Legacy

If you're using the old `valult: true` configuration, it will fail with an error.

**Old (deprecated):**
```yaml
valult: true
secrets:
  DB_PASSWORD: "/ssm/prod/db/password"
```

**New:**
```yaml
secretsProvider:
  provider: "vault"  # or "aws"

secrets:
  DB_PASSWORD: "database"
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

## HTTPRoute (Gateway API)

Modern alternative to Ingress. Gateway API is the successor to Ingress API with better expressiveness, header-based routing, traffic splitting, and cross-namespace routing.

**Prerequisites:**
```bash
# Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
```

### Simple Frontend

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: gateway-prod
      namespace: gateway-prod
  hostnames:
    - app.example.com
```

### Path-Based Routing

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: gateway-prod
      namespace: gateway-prod
  hostnames:
    - app.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: api-gateway-sv
          port: 8080
    - matches:
        - path:
            type: PathPrefix
            value: /
```

### Traffic Splitting (Canary)

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: gateway-prod
      namespace: gateway-prod
  hostnames:
    - app.example.com
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
httpRoute:
  enabled: true
  parentRefs:
    - name: gateway-prod
      namespace: gateway-prod
  hostnames:
    - app.example.com
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

**References:**
- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [HTTPRoute API Reference](https://gateway-api.sigs.k8s.io/api-types/httproute/)
- [Migrating from Ingress](https://gateway-api.sigs.k8s.io/guides/migrating-from-ingress/)

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

