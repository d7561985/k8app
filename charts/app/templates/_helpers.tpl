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