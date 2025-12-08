{{/* vim: set filetype=mustache: */}}
{{/*
Secrets Provider Helpers
Provides simple interface for developers while handling provider complexity internally
*/}}

{{/*
Check if Vault provider is enabled and secrets are defined
*/}}
{{- define "secrets.isVaultEnabled" -}}
{{- if and .Values.secretsProvider (eq .Values.secretsProvider.provider "vault") .Values.secrets -}}
true
{{- end -}}
{{- end -}}

{{/*
Check if AWS provider is enabled and secrets are defined
*/}}
{{- define "secrets.isAwsEnabled" -}}
{{- if and .Values.secretsProvider (eq .Values.secretsProvider.provider "aws") .Values.secrets -}}
true
{{- end -}}
{{- end -}}

{{/*
Check if any new provider is enabled (vault or aws with secretsProvider)
*/}}
{{- define "secrets.isProviderEnabled" -}}
{{- if and .Values.secretsProvider (ne .Values.secretsProvider.provider "none") .Values.secrets -}}
true
{{- end -}}
{{- end -}}

{{/*
Generate secret path based on convention or absolute path
Input: dict with "path" (from secrets map value), "root" (root context)
Convention: {namespace}/{appName}/{environment}/{path}
Absolute paths (starting with /) are used as-is without the leading slash
*/}}
{{- define "secrets.resolvePath" -}}
{{- $path := .path -}}
{{- $root := .root -}}
{{- if hasPrefix "/" $path -}}
{{- trimPrefix "/" $path -}}
{{- else -}}
{{- printf "%s/%s/%s/%s" $root.Release.Namespace $root.Values.appName $root.Values.environment $path -}}
{{- end -}}
{{- end -}}

{{/*
Get unique secret paths from secrets map
Returns deduplicated list of paths for creating VaultStaticSecret resources
*/}}
{{- define "secrets.uniquePaths" -}}
{{- $paths := dict -}}
{{- range $key, $value := .Values.secrets -}}
{{- $_ := set $paths $value true -}}
{{- end -}}
{{- keys $paths | sortAlpha | toJson -}}
{{- end -}}

{{/*
Generate K8s Secret name for the app
*/}}
{{- define "secrets.k8sSecretName" -}}
{{- include "name" . -}}
{{- end -}}
