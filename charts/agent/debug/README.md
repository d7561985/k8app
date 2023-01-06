# debug

```bash
kubectl delete configmap demo;kubectl create configmap demo --from-file=./otel-collector-config_test.yaml;kubectl delete pod -l app.kubernetes.io/name=agent-demo;

kubectl apply -f roles.yaml -f deployment.yaml
```

INVESTIGATE:
```bash
kubectl logs  -l app.kubernetes.io/name=agent-demo -f
kubectl port-forward deploy/agent-demo 9000:9000
```

CLEANUP:
```bash
kubectl delete -f roles.yaml -f deployment.yaml;kubectl delete configmap demo;
```