# app

GitOps application optimized for AWS EKS

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

