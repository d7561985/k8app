# nats

# NKEY usage

Information about https://docs.nats.io/using-nats/nats-tools/nk

```bash
nk -gen user -pubout
```

You should generate keys for all users save seed + set nkey in values:

| user            | secret path                       |
|-----------------|-----------------------------------|
| sys_admin       | /global/nats/nkey/sys_admin       |
| jetstream_admin | /global/nats/nkey/jetstream_admin |
| admin           | /global/nats/nkey/admin           |
| client          | /global/nats/nkey/client          |


## NACK
There is problem with SSM Parameter Store

For now, you should manually create secret:
```bash
kubectl create -n nats secret generic nats-sys-nkey --from-literal=sys.nkey=<NK SALT>
```

## Leaf configuration

You can hide pwd configuration via ARGOCD configuration values like this:
```yaml
nats:
  nats:
    leafnodes:
      remotes:
        - account: LEAF_A
          urls:
            - nats-leaf://{{LEAF_USER_A}}:{{PWD}}@{{IP_A_1}}:4224
            - nats-leaf://{{LEAF_USER_A}}:{{PWD}}@{{IP_A_2}}:4224
            - nats-leaf://{{LEAF_USER_A}}:{{PWD}}@{{IP_A_3}}:4224
        - account: LEAF_B
          urls:
            - nats-leaf://{{LEAF_USER_B}}:{{PWD}}@{{IP_B_1}}:4224
            - nats-leaf://{{LEAF_USER_B}}:{{PWD}}@{{IP_B_2}}:4224
            - nats-leaf://{{LEAF_USER_B}}:{{PWD}}@{{IP_B_3}}:4224
```


## In development
nsc generate config --mem-resolver --config-file ./sxx.conf

nsc generate config --sys-account SYS --nats-resolver

nsc edit operator --account-jwt-server-url nats://localhost:4223

nsc push --all

This solution doesn't worked because of service account creation which should be IRSA attachable

```yaml
secrets:
   "jetstream_admin.nk": "/global/nats/nkey/jetstream_admin"

nack:
  additionalVolumeMounts:
    - name: jetstream-admin
      mountPath: "/etc/jsc-nkey"
  additionalVolumes:
    - name: jetstream-admin
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: nats-secrets # this name hardcode from "accounts_configmap" template
  jetstream:
    additionalArgs:
      - --nkey=/etc/jsc-nkey/jetstream_admin.nk
```



# accounts.conf

Main idea this file should be stored inside SSM ParameterStore

To inject Secret Store CSI driver volume into NATS i use: `.Values.nats.config`

1. SSM Parameter Store should contain account.config and reference should be configured in `.Values.secrets[]`
2. During star-up would be created volume for NATS per ReplicaSet because of `.Values.nats.nats.comfig[0].name` ==
   secrets linked with SSP from 1 step.
3. NATS pod would get mount volume to configuration place

Explanation:

secrets: "accounts.conf": "nats/accounts.conf" mean that in SSM path nats/accounts.conf would be presented
file  `accounts.conf`

```plantuml
actor xx 

package AWS_SSP_PARAMETER_STORE {
    usecase "accounts configuration"
    usecase "leaf passwords"
}

package NATS {
 
}

AWS_SSP_PARAMETER_STORE -> NATS
```