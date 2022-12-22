# agent

NOTE:
```yaml
certs:
  "ca.crt": "ca.crt"
  "client.crt": "client.crt"
  "client.key": "client.key"
```


required installed "AWS Secrets Manager and Config Provider for Secret Store CSI Driver"
https://github.com/aws/secrets-store-csi-driver-provider-aws

EKS scraping based on: https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus
boards: https://github.com/prometheus-community/helm-charts/tree/eba5b198f597a39f2d40d3edd209dfa09429623e/charts/kube-prometheus-stack/templates/grafana


scrapers from https://github.com/prometheus-community/helm-charts/tree/f4957381b36c4b6e3e5e69a5bb320f2ebb4baf01/charts/kube-prometheus-stack

info:
* https://medium.com/htc-research-engineering-blog/monitoring-kubernetes-clusters-with-grafana-e2a413febefd

```yaml
 Source: kube-prometheus-stack/charts/grafana/templates/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-grafana
  namespace: default
  labels:
    helm.sh/chart: grafana-6.48.0
    app.kubernetes.io/name: grafana
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "9.3.1"
    app.kubernetes.io/managed-by: Helm
spec:
  endpoints:
  - port: http-web
    scrapeTimeout: 30s
    honorLabels: true
    path: /metrics
    scheme: http
  jobLabel: "qqq"
  selector:
    matchLabels:
      app.kubernetes.io/name: grafana
      app.kubernetes.io/instance: qqq
  namespaceSelector:
    matchNames:
      - default
---
# Source: kube-prometheus-stack/charts/kube-state-metrics/templates/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-kube-state-metrics
  namespace: default
  labels:    
    helm.sh/chart: kube-state-metrics-4.24.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: metrics
    app.kubernetes.io/part-of: kube-state-metrics
    app.kubernetes.io/name: kube-state-metrics
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "2.7.0"
    release: qqq
spec:
  jobLabel: app.kubernetes.io/name  
  selector:
    matchLabels:      
      app.kubernetes.io/name: kube-state-metrics
      app.kubernetes.io/instance: qqq
  endpoints:
    - port: http
      honorLabels: true
---
# Source: kube-prometheus-stack/charts/prometheus-node-exporter/templates/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-prometheus-node-exporter
  namespace: default
  labels:
    helm.sh/chart: prometheus-node-exporter-4.8.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: metrics
    app.kubernetes.io/part-of: prometheus-node-exporter
    app.kubernetes.io/name: prometheus-node-exporter
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "1.5.0"
    jobLabel: node-exporter
    release: qqq
spec:
  jobLabel: jobLabel
  
  selector:
    matchLabels:
      app.kubernetes.io/name: prometheus-node-exporter
      app.kubernetes.io/instance: qqq
  endpoints:
    - port: http-metrics
      scheme: http
---
# Source: kube-prometheus-stack/templates/alertmanager/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-kube-prometheus-stack-alertmanager
  namespace: default
  labels:
    app: kube-prometheus-stack-alertmanager
    
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "43.1.1"
    app.kubernetes.io/part-of: kube-prometheus-stack
    chart: kube-prometheus-stack-43.1.1
    release: "qqq"
    heritage: "Helm"
spec:
  selector:
    matchLabels:
      app: kube-prometheus-stack-alertmanager
      release: "qqq"
      self-monitor: "true"
  namespaceSelector:
    matchNames:
      - "default"
  endpoints:
  - port: http-web
    enableHttp2: true
    path: "/metrics"
---
# Source: kube-prometheus-stack/templates/exporters/core-dns/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-kube-prometheus-stack-coredns
  namespace: default
  labels:
    app: kube-prometheus-stack-coredns
    
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "43.1.1"
    app.kubernetes.io/part-of: kube-prometheus-stack
    chart: kube-prometheus-stack-43.1.1
    release: "qqq"
    heritage: "Helm"
spec:
  jobLabel: jobLabel
  selector:
    matchLabels:
      app: kube-prometheus-stack-coredns
      release: "qqq"
  namespaceSelector:
    matchNames:
      - "kube-system"
  endpoints:
  - port: http-metrics
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
---
# Source: kube-prometheus-stack/templates/exporters/kube-api-server/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-kube-prometheus-stack-apiserver
  namespace: default
  labels:
    app: kube-prometheus-stack-apiserver
    
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "43.1.1"
    app.kubernetes.io/part-of: kube-prometheus-stack
    chart: kube-prometheus-stack-43.1.1
    release: "qqq"
    heritage: "Helm"
spec:
  endpoints:
  - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    port: https
    scheme: https
    metricRelabelings:
      - action: drop
        regex: apiserver_request_duration_seconds_bucket;(0.15|0.2|0.3|0.35|0.4|0.45|0.6|0.7|0.8|0.9|1.25|1.5|1.75|2|3|3.5|4|4.5|6|7|8|9|15|25|40|50)
        sourceLabels:
        - __name__
        - le
    tlsConfig:
      caFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      serverName: kubernetes
      insecureSkipVerify: false
  jobLabel: component
  namespaceSelector:
    matchNames:
    - default
  selector:
    matchLabels:
      component: apiserver
      provider: kubernetes
---
# Source: kube-prometheus-stack/templates/exporters/kube-controller-manager/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-kube-prometheus-stack-kube-controller-manager
  namespace: default
  labels:
    app: kube-prometheus-stack-kube-controller-manager
    
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "43.1.1"
    app.kubernetes.io/part-of: kube-prometheus-stack
    chart: kube-prometheus-stack-43.1.1
    release: "qqq"
    heritage: "Helm"
spec:
  jobLabel: jobLabel
  selector:
    matchLabels:
      app: kube-prometheus-stack-kube-controller-manager
      release: "qqq"
  namespaceSelector:
    matchNames:
      - "kube-system"
  endpoints:
  - port: http-metrics
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    scheme: https
    tlsConfig:
      caFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      insecureSkipVerify: true
---
# Source: kube-prometheus-stack/templates/exporters/kube-etcd/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-kube-prometheus-stack-kube-etcd
  namespace: default
  labels:
    app: kube-prometheus-stack-kube-etcd
    
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "43.1.1"
    app.kubernetes.io/part-of: kube-prometheus-stack
    chart: kube-prometheus-stack-43.1.1
    release: "qqq"
    heritage: "Helm"
spec:
  jobLabel: jobLabel
  selector:
    matchLabels:
      app: kube-prometheus-stack-kube-etcd
      release: "qqq"
  namespaceSelector:
    matchNames:
      - "kube-system"
  endpoints:
  - port: http-metrics
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
---
# Source: kube-prometheus-stack/templates/exporters/kube-proxy/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-kube-prometheus-stack-kube-proxy
  namespace: default
  labels:
    app: kube-prometheus-stack-kube-proxy
    
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "43.1.1"
    app.kubernetes.io/part-of: kube-prometheus-stack
    chart: kube-prometheus-stack-43.1.1
    release: "qqq"
    heritage: "Helm"
spec:
  jobLabel: jobLabel
  selector:
    matchLabels:
      app: kube-prometheus-stack-kube-proxy
      release: "qqq"
  namespaceSelector:
    matchNames:
      - "kube-system"
  endpoints:
  - port: http-metrics
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
---
# Source: kube-prometheus-stack/templates/exporters/kube-scheduler/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-kube-prometheus-stack-kube-scheduler
  namespace: default
  labels:
    app: kube-prometheus-stack-kube-scheduler
    
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "43.1.1"
    app.kubernetes.io/part-of: kube-prometheus-stack
    chart: kube-prometheus-stack-43.1.1
    release: "qqq"
    heritage: "Helm"
spec:
  jobLabel: jobLabel
  selector:
    matchLabels:
      app: kube-prometheus-stack-kube-scheduler
      release: "qqq"
  namespaceSelector:
    matchNames:
      - "kube-system"
  endpoints:
  - port: http-metrics
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    scheme: https
    tlsConfig:
      caFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      insecureSkipVerify: true
---
# Source: kube-prometheus-stack/templates/exporters/kubelet/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-kube-prometheus-stack-kubelet
  namespace: default
  labels:
    app: kube-prometheus-stack-kubelet    
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "43.1.1"
    app.kubernetes.io/part-of: kube-prometheus-stack
    chart: kube-prometheus-stack-43.1.1
    release: "qqq"
    heritage: "Helm"
spec:
  endpoints:
  - port: https-metrics
    scheme: https
    tlsConfig:
      caFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      insecureSkipVerify: true
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    honorLabels: true
    relabelings:
    - action: replace
      sourceLabels:
      - __metrics_path__
      targetLabel: metrics_path
  - port: https-metrics
    scheme: https
    path: /metrics/cadvisor
    honorLabels: true
    tlsConfig:
      caFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      insecureSkipVerify: true
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    metricRelabelings:
    - action: drop
      regex: container_cpu_(cfs_throttled_seconds_total|load_average_10s|system_seconds_total|user_seconds_total)
      sourceLabels:
      - __name__
    - action: drop
      regex: container_fs_(io_current|io_time_seconds_total|io_time_weighted_seconds_total|reads_merged_total|sector_reads_total|sector_writes_total|writes_merged_total)
      sourceLabels:
      - __name__
    - action: drop
      regex: container_memory_(mapped_file|swap)
      sourceLabels:
      - __name__
    - action: drop
      regex: container_(file_descriptors|tasks_state|threads_max)
      sourceLabels:
      - __name__
    - action: drop
      regex: container_spec.*
      sourceLabels:
      - __name__
    - action: drop
      regex: .+;
      sourceLabels:
      - id
      - pod
    relabelings:
    - action: replace
      sourceLabels:
      - __metrics_path__
      targetLabel: metrics_path
  - port: https-metrics
    scheme: https
    path: /metrics/probes
    honorLabels: true
    tlsConfig:
      caFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      insecureSkipVerify: true
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabelings:
    - action: replace
      sourceLabels:
      - __metrics_path__
      targetLabel: metrics_path
  jobLabel: k8s-app
  namespaceSelector:
    matchNames:
    - kube-system
  selector:
    matchLabels:
      app.kubernetes.io/name: kubelet
      k8s-app: kubelet
---
# Source: kube-prometheus-stack/templates/prometheus-operator/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-kube-prometheus-stack-operator
  namespace: default
  labels:
    app: kube-prometheus-stack-operator
    
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "43.1.1"
    app.kubernetes.io/part-of: kube-prometheus-stack
    chart: kube-prometheus-stack-43.1.1
    release: "qqq"
    heritage: "Helm"
spec:
  endpoints:
  - port: https
    scheme: https
    tlsConfig:
      serverName: qqq-kube-prometheus-stack-operator
      ca:
        secret:
          name: qqq-kube-prometheus-stack-admission
          key: ca
          optional: false
    honorLabels: true
  selector:
    matchLabels:
      app: kube-prometheus-stack-operator
      release: "qqq"
  namespaceSelector:
    matchNames:
      - "default"
---
# Source: kube-prometheus-stack/templates/prometheus/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qqq-kube-prometheus-stack-prometheus
  namespace: default
  labels:
    app: kube-prometheus-stack-prometheus
    
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: qqq
    app.kubernetes.io/version: "43.1.1"
    app.kubernetes.io/part-of: kube-prometheus-stack
    chart: kube-prometheus-stack-43.1.1
    release: "qqq"
    heritage: "Helm"
spec:
  selector:
    matchLabels:
      app: kube-prometheus-stack-prometheus
      release: "qqq"
      self-monitor: "true"
  namespaceSelector:
    matchNames:
      - "default"
  endpoints:
  - port: http-web
    path: "/metrics"
```