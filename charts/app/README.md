# app

GitOps application optimized for AWS EKS

## Volume
We use dynamic provision approach.

Create `StorageClass` if `.Values.volume.storageClass.create` is provided
```yaml
volume:
  ...
    create:
      provisioner: "aws-ebs-csi-driver"
      parameters:
        type: gp3
        iops: "3000"
```

Create `PersistentVolumeClaim` for specific app and mount it.

### StorageClass
Default storage class provision `kubernetes.io/aws-ebs ` name: `gp2`

With addon `aws-ebs-csi-driver` we get provision: `ebs.csi.aws.com`
- [examples](https://github.com/kubernetes-sigs/aws-ebs-csi-driver/tree/master/examples)

`aws-ebs-csi-driver` allow provision `gp3` type volume with dynamic provision [parameters](https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/parameters.md) + [AWS EBS volume types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html)




