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
Resolve {env} placeholder in secret path
Input: dict with "path" (from secrets map value), "root" (root context)
Example: "brand/shared/{env}/config" with environment=dev → "brand/shared/dev/config"
*/}}
{{- define "secrets.resolvePath" -}}
{{- $path := .path -}}
{{- $environment := .root.Values.environment -}}
{{- $path | replace "{env}" $environment -}}
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
