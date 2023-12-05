# nats

Install NATS infrastructure with `NACK` K8S operator and `suveyor` observe system

## INSTALL

NOTE: we use `nats` name for chart installation


1. Generate nkey users keys for all our users in all accounts (look into accounts reference)
2. Create secret `nats-sys-nkey` in target namespace
3. Create gitops repo with brand new helm chart base on this one and provide required values
4. Install helm chart in ArgoCD from you repo
5. Configure Leaf inside hidden configuration values

###  Accounts reference

| account | user            | secret path                       |
|---------|-----------------|-----------------------------------|
| SYS     | sys_admin       | /global/nats/nkey/sys_admin       |
| ACC     | jetstream_admin | /global/nats/nkey/jetstream_admin |
| ACC     | admin           | /global/nats/nkey/admin           |
| ACC     | client          | /global/nats/nkey/client          |

### 1. Generate nkey
`NK` our main auth system for accounts - https://docs.nats.io/using-nats/nats-tools/nk

Information about https://docs.nats.io/using-nats/nats-tools/nk

```bash
nk -gen user -pubout
```

### 2. Secret
```bash
kubectl create -n nats secret generic nats-sys-nkey --from-literal=sys.nkey=<SYS_SNKEY_VALUE> --from-literal=js.admin.cnkey=<JS_ADMIN_SNKEY_VALUE>
```

### 3. GitOps repo
INFO: you can use `helm init` command for handy create new repo but remember that it would be better to store our repo in the root.


You helm chart should look like:

`Chart.yaml`
```yaml
apiVersion: v2
name: <CHART_NAME>
description: A Helm chart for Kubernetes

type: application

version: 0.1.0

appVersion: "1.16.0"

dependencies:
  - name: nats
    repository: https://pin-up-global.github.io/k8app
    version: 1.0.3
```

We strongly recommend separate values files from different environments
`values.dev.yaml`
```yaml
nats:
   secrets: null
   nats:
      cluster:
         name: "CURRENT_CORE"
      nats:
         serviceAccount:
            name: nats-server
            create: true
         jetstream:
            domain: "CURRENT_JS"
            fileStorage:
               size: 500Gi
      auth:
         basic:
            accounts:
               SYS:
                  users:
                     # sys_admin
                     - nkey: UDOXLZBK6KJ66BGWNHX7CWA3SFVXTUJLGAX6EB4P7XSEXS24J2DCT3FR
               ACC:
                  users:
                     # jetstream_admin
                     - nkey: UBAXTID4IRSI6CJHZZ5524P35AUGEYG5ODIMUMBUNPVNZLDJM3YX4NB
                       permissions:
                          publish: [ "$JS.API.STREAM.CREATE.*", "$JS.API.STREAM.UPDATE.*", "$JS.API.STREAM.DELETE.*",
                                     "$JS.API.STREAM.INFO.*", "$JS.API.STREAM.LIST", "$JS.API.STREAM.NAMES", "$JS.API.CONSUMER.DURABLE.CREATE.*.*",
                                     "$JS.API.CONSUMER.DELETE.*.*", "$JS.API.CONSUMER.INFO.*.*","$JS.API.CONSUMER.LIST.*","$JS.API.CONSUMER.NAMES.*",
                                     "$JS.API.STREAM.TEMPLATE.>" ]
                          subscribe: "_INBOX.>"
                     # admin
                     - nkey: UAIXSBF3723DZH5WXOWTLLUFDE6MDDRNE7RX254HB2J62W3PO2U4CJ4I
                     # client
                     - nkey: UCOSJD7KJJRF6LO44QQ66RTPK3S6457UPOARVJSRFNBMYYKPPHW5BMOO
                       permissions:
                          publish:
                             deny: [ "$JS.API.STREAM.CREATE.*", "$JS.API.STREAM.UPDATE.*", "$JS.API.STREAM.DELETE.*",
                                     "$JS.API.CONSUMER.DURABLE.CREATE.*.*", "$JS.API.CONSUMER.DELETE.*.*", "$JS.API.STREAM.TEMPLATE.>", "$JS.API.CONSUMER.CREATE.>" ]
                  imports:
                     - stream:
                          account: TARGET_LEAF_ACCOUNT
                          subject: "corporate.target.com.>"
                  exports:
                     - stream: "corporate.current.com.>"

                  jetstream: enabled
               TARGET_LEAF_ACCOUNT:
                  users: []
                  imports:
                     - stream:
                          account: ACC
                          subject: "corporate.current.com.>"
                  exports:
                     - stream: "corporate.target.com.>"  # stream to cluster
```
### 4. ArgoCD installation
Strongly recommend create different project for installation accessible only for DevOps operator.

For example, infra project with no access for developer.


## 5. Leaf configuration

You can hide pwd configuration via ARGOCD configuration values like this:

```yaml
nats:
  nats:
    leafnodes:
      remotes:
        - account: TARGET_LEAF_ACCOUNT
          urls:
            - nats-leaf://{{LEAF_USER_A}}:{{PWD}}@{{IP_A_1}}:4224
            - nats-leaf://{{LEAF_USER_A}}:{{PWD}}@{{IP_A_2}}:4224
            - nats-leaf://{{LEAF_USER_A}}:{{PWD}}@{{IP_A_3}}:4224
```


# In development

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

## accounts.conf

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

# APPENDIX

* https://docs.nats.io/using-nats/nats-tools/nk - nkey instalation and usage
* https://github.com/nats-io/nsc
* https://github.com/nats-io/k8s
* https://github.com/nats-io/nats-surveyor
