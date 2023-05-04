{{/*
Expand the name of the chart.
*/}}
{{- define "infoblox-dns-webhook.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "infoblox-dns-webhook.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "infoblox-dns-webhook.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "infoblox-dns-webhook.labels" -}}
helm.sh/chart: {{ include "infoblox-dns-webhook.chart" . }}
{{ include "infoblox-dns-webhook.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "infoblox-dns-webhook.selectorLabels" -}}
app.kubernetes.io/name: {{ include "infoblox-dns-webhook.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "infoblox-dns-webhook.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "infoblox-dns-webhook.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
{{/*
Create a CA
*/}}
{{- define "infoblox-dns-webhook.ca" }}
{{ $ca := genCA "{{ .Values.tls.certCommonName }}.{{ .Release.Namespace }}-ca" 365 }}
{{- end }}
{{/*
Generate Self-signed certificate and create TLS secret
*/}}
{{- define "infoblox-dns-webhook.gen-cert" }}
{{- $tlscert := genSelfSignedCert "{{ .Values.tls.certCommonName }}.{{ .Release.Namespace }}.svc" (list "127.0.0.1") (list "") 365 }}
crt: {{ $tlscert.Cert | b64enc }}
key: {{ $tlscert.Key | b64enc }}
{{- end }}

{{/*
Add environment variables from a configMap - valueFrom
*/}}
{{- define "helpers.list-env-variables" }}
{{- range $key, $val := .Values.env.configMap.data }}
- name: {{ $key }}
  valueFrom:
    configMapKeyRef:
      name: infoblox-server-info
      key: {{ $key }}
{{- end }}
{{- end }}
{{/* 
Add secret to deployment
*/}}
{{- define "helpers.list-secret-variables" }}
{{- range $key, $val := .Values.infobloxInfo.secret }}
- name: INFOBLOX_{{ $key | upper }}
  valueFrom:
    secretKeyRef:
      name: infoblox-server-credentials
      key: INFOBLOX_{{ $key | upper }}
{{- end }}
{{- end }}
{{/*
Add volumeMounts
*/}}
{{- define "helpers.list-volumeMounts" }}
{{- range $key,$val := .Values.volumeMounts }}
- name: $key
  mountPath: $val
{{- end }}
{{- end }}
