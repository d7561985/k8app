{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "chartName" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the release
*/}}
{{- define "name" -}}
{{- required "Please specify an app_name at .Values.appName" .Values.appName -}}
{{- end -}}

{{/*
Expand the environment of the release
*/}}
{{- define "environment" -}}
{{- required "Please specify an environment at .Values.environment" .Values.environment -}}
{{- end -}}

{{/*
Expand the vault project name of the release
*/}}
{{- define "vaultProjectName" -}}
{{- .Values.vaultProjectName | default .Values.appName -}}
{{- end -}}

{{- define "vaultNamespace" -}}
{{- .Values.vaultNamespace | default .Release.Namespace -}}
{{- end -}}

{{- define "fqdn" -}}
{{- .Values.fqdn | default .Values.ingress.fqdn -}}
{{- end -}}

{{- define "vaultCert" -}}
{{- .Values.vaultCert | default .Values.ingress.vaultCert -}}
{{- end -}}

{{- define "storageClass" -}}
{{- if and (not (empty .Values.volume.storageClass.create)) .Values.volume.enabled -}}
{{- printf "%s-%s" (include "name" .) (default "gp" .Values.volume.storageClass.name)  -}}
{{- else -}}
{{- default "gp2" .Values.volume.storageClass.name -}}
{{- end -}}
{{- end -}}

{{- define "persistantClaim" -}}
{{- printf "%s-claim" (include "name" .) -}}
{{- end -}}

{{/*
Selector labels for ServiceMonitor
*/}}
{{- define "app.selectorLabels" -}}
app: {{ include "name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
{{ include "app.selectorLabels" . }}
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{/*
Truncate image tag for use in labels (max 63 chars)
Takes last 63 characters if tag is too long (preserves timestamp suffix)
*/}}
{{- define "k8app.labelVersion" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion | default "latest" -}}
{{- $tag | trunc -63 -}}
{{- end -}}

{{/*
Resolve {env} placeholder in configmap value
Input: dict with "value" (from configmap value), "root" (root context)
Example: "https://api.{env}.example.com" with environment=dev → "https://api.dev.example.com"
*/}}
{{- define "configmap.resolveValue" -}}
{{- .value | toString | replace "{env}" .root.Values.environment -}}
{{- end -}}

{{/*
Generate envFrom block (configmap ref + vault secret refs)
Input: dict with "root" (root context), "appname" (app name)
*/}}
{{- define "k8app.envFrom" -}}
{{- $root := .root -}}
{{- $appname := .appname -}}
{{- if or $root.Values.secrets $root.Values.configmap }}
envFrom:
{{- if $root.Values.configmap }}
- configMapRef:
    name: {{ $appname }}
{{- end }}
{{- if and $root.Values.secrets (eq (include "secrets.isVaultEnabled" $root) "true") }}
{{- $secretsByPath := dict -}}
{{- range $envVar, $pathTemplate := $root.Values.secrets -}}
{{- $resolvedPath := include "secrets.resolvePath" (dict "path" $pathTemplate "root" $root) -}}
{{- $_ := set $secretsByPath $resolvedPath true -}}
{{- end -}}
{{- $sortedPaths := keys $secretsByPath | sortAlpha -}}
{{- range $pathIndex, $path := $sortedPaths }}
- secretRef:
    name: {{ $appname }}-vault-{{ $pathIndex }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Generate CSI volume for AWS/legacy secrets
Input: dict with "root" (root context), "appname" (app name)
*/}}
{{- define "k8app.secretVolumes" -}}
{{- $root := .root -}}
{{- $appname := .appname -}}
{{- if and $root.Values.secrets (or (not $root.Values.secretsProvider) (ne $root.Values.secretsProvider.provider "vault")) }}
- name: secrets-store-inline
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: {{ $appname }}-aws-secrets
{{- end }}
{{- end -}}

{{/*
Generate CSI volumeMount for secrets-store-inline
Input: dict with "root" (root context)
*/}}
{{- define "k8app.secretVolumeMounts" -}}
{{- $root := .root -}}
{{- if and $root.Values.secrets (or (not $root.Values.secretsProvider) (ne $root.Values.secretsProvider.provider "vault")) }}
- name: secrets-store-inline
  mountPath: "/mnt/secrets-store"
{{- end }}
{{- end -}}

{{/*
Generate imagePullSecrets block
Input: dict with "root" (root context)
*/}}
{{- define "k8app.imagePullSecrets" -}}
{{- $root := .root -}}
{{- if $root.Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml $root.Values.imagePullSecrets | nindent 2 }}
{{- /* Legacy support for deploySecretHarbor/deploySecretNexus */ -}}
{{- else if or $root.Values.deploySecretHarbor $root.Values.deploySecretNexus }}
imagePullSecrets:
- name: regsecret
{{- end }}
{{- end -}}