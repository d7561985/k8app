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

ca.crt
```yaml
-----BEGIN CERTIFICATE-----
MIIDMjCCAhoCCQDaitqLMMYFXzANBgkqhkiG9w0BAQsFADBbMQswCQYDVQQGEwJV
QTEQMA4GA1UECAwHVWtyYWluZTENMAsGA1UEBwwES2lldjEUMBIGA1UECgwLUGlu
LVVwLnRlY2gxFTATBgNVBAMMDE15Q29tbW9uTmFtZTAeFw0yMjEyMTEwOTA3NTFa
Fw0zMjEyMDgwOTA3NTFaMFsxCzAJBgNVBAYTAlVBMRAwDgYDVQQIDAdVa3JhaW5l
MQ0wCwYDVQQHDARLaWV2MRQwEgYDVQQKDAtQaW4tVXAudGVjaDEVMBMGA1UEAwwM
TXlDb21tb25OYW1lMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6vFe
ctoMHwUKIv4ts9wr6DY2nag5SkTtBl2y+eo3AcGOh4Gp+OJTg6MSuG7O6lzVhuTe
m8EeMEGX8eFjKGW3kAt1ma9IUuy7YkbAD7QVwWiUxKd2X64/YTgxGMtWZq8pyi20
0D8AlKDidFZGjjjGJ+S/FmHSAAU4zssk66N34V17FDpFKu8qafdj9W56lnXd2Ivs
xUCqUiwJ1AIHhfMEgnFTdWCrzWCnmIVMQMnHpZVAxEMymgsp8XkLhGkhFCpH8bNw
BPXBFQHtL6oc10vlZXcXLDB5k9rnuZIdJXZyJtYCdvDkJMl5aYOeHgx2OVsv8hID
SUBunyewTvUo5Ll3NwIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQBT3AXpjfC2R539
L5E7/whwyiW37599I74BscmoHFEkf9Alqe8M+/TMOaNhLu9T80Acr4G9N78imGJd
Z5o+u+jFklD3eBTgye3vMzrLseTjMNrNU3q3kQEAbKRqaTVm/zuvy/AKF08R5yUg
LuWAqMnEo5d86pQnxxUnK75fFPg6V2/fjjlMbQKBGK1Np2gmpzcf/SPV3rH+R436
6NbElNbaY/qMXnV2E8EeG+OGO+9q085XG/jxQNMzglhzXRXXP79c0pTbEXaJu6yT
dEICByJKJpIf/5h+1HIBvJ0H2GjBsZjciaMovdEzZbb/GbSGA1sFrt5f9J0+vM9N
8hI3fhPx
-----END CERTIFICATE-----
```

client.crt
```yaml
-----BEGIN CERTIFICATE-----
MIIDUjCCAjqgAwIBAgIJAKXlY2G50f8vMA0GCSqGSIb3DQEBCwUAMFsxCzAJBgNV
BAYTAlVBMRAwDgYDVQQIDAdVa3JhaW5lMQ0wCwYDVQQHDARLaWV2MRQwEgYDVQQK
DAtQaW4tVXAudGVjaDEVMBMGA1UEAwwMTXlDb21tb25OYW1lMB4XDTIyMTIxMTA5
MDc1MloXDTMyMTIwODA5MDc1MlowWzELMAkGA1UEBhMCVUExEDAOBgNVBAgMB1Vr
cmFpbmUxDTALBgNVBAcMBEtpZXYxFDASBgNVBAoMC1Bpbi1VcC50ZWNoMRUwEwYD
VQQDDAxNeUNvbW1vbk5hbWUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
AQDAVudG4kh8cxT0CjMhXfIoqL+DeFJSGLbIMPx+2Oza1QkdqT6UkQnWM6S0xRgS
JDpwovJa3QcUgb7GCyGzinj80K2wcZ3FAa2xVg+XOLstfGoJVXWlR2VEp4lpnKEu
EtqqMQXurdAeGNlS0tzFBveVLQFkVeqGCNynP/EKhMyZ4mIW8KwcSgvnEzV2VMNN
e1Qz/IIPSlJAQxIr5uoaWdaqy8v3eOBG3Mp09vC7IPoAH9SZR8/hoTiCjZ6CPYER
gZ2HyKdtKQRuXFQcBTEtYAvjPqPOnG/JUdn6Klftx7gcpNKLymfZ8U+CVnly2DzF
Ny1XHEKFzS8xH8YuoNcZxFrRAgMBAAGjGTAXMBUGA1UdEQQOMAyCCnBpbi11cC5k
ZXYwDQYJKoZIhvcNAQELBQADggEBANUvnz/nNatAS90t3pdw9ZKC42Tjy2ewf6Di
UbXT1P/0EQh9/q5L/5E3Oc5W2l1qagRiuCtTNj6dEqSJQ0/ZnDNMcGs9Z62XvFYc
DJW3yVrXgzG2KqgECmwwC0gtFiRUb8ofWOCwD660I0tYoTs4lJrvkgYjR+D5NFGD
hnBxcjz2MfqOXK8YJ11FYNItSziHeVbsM7ZX66EWm1c6Ep8wXk01/3YeVR9iBpxr
DlF30u8e4bYucSpWFxrxeUyhWz6r53w3yS1GP0BobsPS+rG5Y8eK19g+tvxnSMYB
CaOd/FFq1sXAbFLidI9B2Cakf05v3hOtF+toofFDETtzG+rAq4I=
-----END CERTIFICATE-----
```
client.key
```yaml
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAwFbnRuJIfHMU9AozIV3yKKi/g3hSUhi2yDD8ftjs2tUJHak+
lJEJ1jOktMUYEiQ6cKLyWt0HFIG+xgshs4p4/NCtsHGdxQGtsVYPlzi7LXxqCVV1
pUdlRKeJaZyhLhLaqjEF7q3QHhjZUtLcxQb3lS0BZFXqhgjcpz/xCoTMmeJiFvCs
HEoL5xM1dlTDTXtUM/yCD0pSQEMSK+bqGlnWqsvL93jgRtzKdPbwuyD6AB/UmUfP
4aE4go2egj2BEYGdh8inbSkEblxUHAUxLWAL4z6jzpxvyVHZ+ipX7ce4HKTSi8pn
2fFPglZ5ctg8xTctVxxChc0vMR/GLqDXGcRa0QIDAQABAoIBAQCS34m6Yj9R8Rs2
A7fpqfCqRboA7deG42JoWqflQUcVEArnAH9OObcWP9dtRvhLmiiaLIP/CLtIWI9S
cdupW3tqKvwHOattbgux2HMNWf/tCw151S2CKZPWKk1PPZEDOtiJj+fkzAuZgAYs
LeLx/ZD/9B8U/FqbQZcljDlHfAM1GgtePIZA0B4iKMTnPFwclwBE5LqgvRk7WS/F
N0wvSIVJ5f/5weYENa9152nlK5W+kjNtp0GXQGtd5/Y4jSmKx5+F72PaJkdIqmaB
ZES9ehvYlGe6MAwC6cepnx1TQ/cJQ7njmcEaRrIAnvKLMgfaRsk5/qgnMGLX4cY2
7PWmwwZBAoGBAO6UdNwxwS4T7SrmfzJkWwh5CY6i3gx1pnq4AlaqSZdJTdexA7pu
4dvM+ruJ2gDEsBVJn6m4qUbZ8YfQp4nkrz1umZ8yI3SoGraKZS2QeeJIdCe6BDSi
I9JPPlQtZd2HSMmo6jDRNDE+oAbPUuWmNhhet1Eek29fmfos2HlTW7IZAoGBAM5i
HnwAYB9lzBofc+gAIncpF/+/zifnr3ofw8TS7NStOAcCUOlZM6X5P79Ura5Q/4k2
I0KSzleocHGFIYyCVxKD8pWohB/ha7Gh6zMUd5TTL9mNEYlbgEr1adk6+fF5Qbm2
rO9FJHKi3+mQ3LDJjapwLAIDgicGequgx03xvjV5AoGAEg5qSb/6PuKDMJwBRG8T
9LA0aPcqlwbQcrk6dBSvPSPvIEPlZFbAAUKiN09XkHdSXEoWK2IubY5RGVZRV75X
BO858TJ6PHn8i5Qt1CT7FIUnRVputw0OaPxWW0iUTQ/QEnMWRluO96slsV4/h+Hs
diu09A68WdGCdcyvFX+ZkQECgYBpCERtZR+GOx9xV/p74r2nmTFOhgXcBywl4c6W
96Vx4yn1XzdgWnZPjJblv6mYYj56TSQKuH3s3JtFGrTlNlwr3xzxD08WjnlpcHcr
isoE4qmidQmstvWGsHkLBdm4C7boVdCTAMQ41y1PR9sY2aqQSAANkk2FoOWDPRLR
VysvOQKBgQDrbtTZqX2Ikj2fv+XiDpdKNf+TfWeOkuXzj38hNitsgnOMUKCbN664
2tjKakugdmg/D3ORKl4GlOgPPNXklJaYNtoFgeXpEQ2eRkCyEDALzBZiPxNvXFME
FjpxKfqsj4LL8uf1FA+U3wbD9Vcm9O+vYdKAtMEiuQiwSNeV6rPJTA==
-----END RSA PRIVATE KEY-----
```