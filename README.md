# k8app

Modern Helm charts for Kubernetes applications, optimized for GitOps workflows and cloud-native deployments.

## 🚀 Quick Start

Add this repository to Helm:

```bash
helm repo add k8app https://d7561985.github.io/k8app
helm repo update
```

Install with minimal configuration:

```bash
helm install myapp k8app/app \
  --set appName=myapp \
  --set environment=dev \
  --set image.repository=myorg/myapp \
  --set image.tag=v1.0.0
```

## 📦 Available Charts

### [app](./charts/app/) - Main Application Chart

Full-featured Helm chart for deploying cloud-native applications with:

- **Deployments** - Main application containers with health checks, resources, scaling
- **Workers** - Background job processors with individual scaling and configuration  
- **Jobs** - One-time tasks like migrations and data imports
- **CronJobs** - Scheduled tasks like backups and cleanup
- **Services** - ClusterIP, NodePort, LoadBalancer, and Headless services
- **Ingress/Gateway API** - HTTP routing with TLS termination
- **Secrets Management** - AWS Secrets Manager, HashiCorp Vault integration
- **ConfigMaps** - Environment variables and configuration files
- **Storage** - Persistent volumes, shared volumes, EFS integration
- **Monitoring** - Prometheus ServiceMonitor, alerting rules
- **Autoscaling** - HPA with CPU, memory, and custom metrics
- **RBAC** - Service accounts with fine-grained permissions
- **Security** - Pod security contexts, network policies

[📖 **Full Documentation**](./charts/app/README.md)

### [tel](./charts/tel/) - Telemetry Stack

Observability stack with OpenTelemetry, Grafana, and Tempo for distributed tracing.

## 🛠 Development

### For Application Developers

Use the simplified developer configuration:

```yaml
# values.yaml - Minimal developer config  
appName: "myapp"
environment: "dev"

image:
  repository: "myorg/myapp"
  tag: "v1.2.3"

# Environment variables
configmap:
  LOG_LEVEL: "debug"
  API_URL: "https://api.dev.example.com"

# Secrets from your secret management system
secrets:
  DB_PASSWORD: "myapp/{env}/database"
  API_KEY: "shared/{env}/external-api"

# Expose your app
gateway:
  enabled: true
  hostname: "myapp-dev.company.com"
```

See [values.dev.example.yaml](./charts/app/values.dev.example.yaml) for a complete developer-friendly example.

### For DevOps/Infrastructure Teams

Use the full configuration with all features:

See [values.example.yaml](./charts/app/values.example.yaml) for enterprise-grade configuration covering:
- Multi-region deployments
- Advanced networking
- Security hardening  
- Observability integration
- Resource management
- Backup and disaster recovery

## 📚 Documentation

- **[Application Chart Guide](./charts/app/README.md)** - Complete usage guide
- **[Contributing Guide](./CONTRIBUTING.md)** - Development practices and guidelines
- **[Changelog](./CHANGELOG.md)** - Version history and breaking changes
- **[Examples](./charts/app/)** - Real-world configuration examples

## 🏗 Architecture Principles

- **Convention over Configuration** - Sensible defaults, minimal required config
- **DRY (Don't Repeat Yourself)** - Reusable templates and helpers
- **Zero-Config Defaults** - Works out of the box with just app name and image
- **Backward Compatibility** - Smooth upgrades without breaking changes
- **Cloud-Native First** - Optimized for Kubernetes and cloud platforms

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](./CONTRIBUTING.md) for:

- Development workflow
- Code style guidelines  
- Testing requirements
- Release process

## 📋 Requirements

- **Kubernetes**: 1.19+ 
- **Helm**: 3.8+
- **Gateway API** (optional): v0.5.0+ for advanced routing
- **Prometheus Operator** (optional): For ServiceMonitor CRDs

## ⚡ Features Comparison

| Feature | Basic Deploy | k8app |
|---------|--------------|-------|
| Single container deployment | ✅ | ✅ |
| Background workers | ❌ | ✅ |
| Scheduled jobs (cron) | ❌ | ✅ |
| One-time jobs (migrations) | ❌ | ✅ |
| Secrets management | Manual | ✅ Automated |
| Config file mounting | Manual | ✅ Built-in |
| Monitoring integration | Manual | ✅ Auto-configured |
| Autoscaling | Manual | ✅ Declarative |
| Security hardening | Manual | ✅ Best practices |
| Multi-environment support | Manual | ✅ Built-in |
| Rollback safety | Basic | ✅ Advanced |

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 