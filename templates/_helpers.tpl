{{/*
Expand the name of the chart.
*/}}
{{- define "base.name" -}}
{{- default .Chart.Name .Values.service.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "base.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.service.name }}
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
{{- define "base.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels - Applied to all resources
*/}}
{{- define "base.labels" -}}
helm.sh/chart: {{ include "base.chart" . }}
{{ include "base.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.global.environment }}
environment: {{ .Values.global.environment }}
{{- end }}
{{- if .Values.global.team }}
team: {{ .Values.global.team }}
{{- end }}
{{- if .Values.global.businessUnit }}
business-unit: {{ .Values.global.businessUnit }}
{{- end }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels - Used for pod selection
*/}}
{{- define "base.selectorLabels" -}}
app.kubernetes.io/name: {{ include "base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Values.service.name }}
app: {{ .Values.service.name }}
service: {{ .Values.service.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "base.serviceAccountName" -}}
{{- if .Values.deployment.serviceAccount.create }}
{{- default (include "base.fullname" .) .Values.deployment.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.deployment.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Datadog unified service tagging
https://docs.datadoghq.com/getting_started/tagging/unified_service_tagging/
*/}}
{{- define "base.datadogTags" -}}
{{- if .Values.global.datadog.enabled }}
tags.datadoghq.com/env: {{ .Values.global.environment | quote }}
tags.datadoghq.com/service: {{ .Values.service.name | quote }}
tags.datadoghq.com/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
{{- end }}
{{- end }}

{{/*
Datadog pod annotations for APM
*/}}
{{- define "base.datadogPodAnnotations" -}}
{{- if and .Values.global.datadog.enabled .Values.global.datadog.apm.enabled }}
ad.datadoghq.com/{{ .Values.service.name }}.logs: '[{"source":"{{ .Values.service.name }}","service":"{{ .Values.service.name }}"}]'
ad.datadoghq.com/{{ .Values.service.name }}.tags: >-
  {
    "env":"{{ .Values.global.environment }}",
    "service":"{{ .Values.service.name }}",
    "version":"{{ .Values.image.tag | default .Chart.AppVersion }}",
    "team":"{{ .Values.global.team }}"
  }
{{- end }}
{{- end }}

{{/*
Standard environment variables for Datadog APM
*/}}
{{- define "base.datadogEnvVars" -}}
{{- if and .Values.global.datadog.enabled .Values.global.datadog.apm.enabled }}
- name: DD_ENV
  value: {{ .Values.global.environment | quote }}
- name: DD_SERVICE
  value: {{ .Values.service.name | quote }}
- name: DD_VERSION
  value: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
- name: DD_AGENT_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
- name: DD_TRACE_AGENT_PORT
  value: "8126"
- name: DD_LOGS_INJECTION
  value: "true"
{{- if .Values.global.datadog.profiling.enabled }}
- name: DD_PROFILING_ENABLED
  value: "true"
{{- end }}
{{- end }}
{{- end }}

{{/*
Image pull policy helper
*/}}
{{- define "base.imagePullPolicy" -}}
{{- if .Values.image.pullPolicy }}
{{- .Values.image.pullPolicy }}
{{- else if eq .Values.global.environment "prod" }}
IfNotPresent
{{- else }}
Always
{{- end }}
{{- end }}

{{/*
Compute the image tag to use
*/}}
{{- define "base.imageTag" -}}
{{- .Values.image.tag | default .Chart.AppVersion | default "latest" }}
{{- end }}

{{/*
Create resource name with environment suffix
*/}}
{{- define "base.resourceName" -}}
{{- $base := include "base.fullname" . }}
{{- if .Values.global.environment }}
{{- printf "%s-%s" $base .Values.global.environment | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $base }}
{{- end }}
{{- end }}

{{/*
Generate backend config for Ingress
*/}}
{{- define "base.ingressBackend" -}}
service:
  name: {{ include "base.fullname" . }}
  port:
    {{- if .Values.service.port }}
    number: {{ .Values.service.port }}
    {{- else }}
    name: http
    {{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for HPA
*/}}
{{- define "base.hpa.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "autoscaling/v2" }}
{{- print "autoscaling/v2" }}
{{- else }}
{{- print "autoscaling/v2beta2" }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for PodDisruptionBudget
*/}}
{{- define "base.pdb.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "policy/v1" }}
{{- print "policy/v1" }}
{{- else }}
{{- print "policy/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for NetworkPolicy
*/}}
{{- define "base.networkPolicy.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1" }}
{{- print "networking.k8s.io/v1" }}
{{- else }}
{{- print "networking.k8s.io/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Merge deployment pod annotations
*/}}
{{- define "base.deploymentPodAnnotations" -}}
{{- $datadogAnnotations := include "base.datadogPodAnnotations" . | fromYaml }}
{{- $customAnnotations := .Values.deployment.podAnnotations | default dict }}
{{- $merged := merge $customAnnotations $datadogAnnotations }}
{{- toYaml $merged }}
{{- end }}

{{/*
Merge deployment pod labels
*/}}
{{- define "base.deploymentPodLabels" -}}
{{- $selectorLabels := include "base.selectorLabels" . | fromYaml }}
{{- $datadogTags := include "base.datadogTags" . | fromYaml }}
{{- $customLabels := .Values.deployment.podLabels | default dict }}
{{- $merged := merge $customLabels $datadogTags $selectorLabels }}
{{- toYaml $merged }}
{{- end }}

{{/*
Generate ConfigMap name
*/}}
{{- define "base.configMapName" -}}
{{- if .cmName }}
{{- printf "%s-%s" (include "base.fullname" .context) .cmName | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- include "base.fullname" .context }}
{{- end }}
{{- end }}

{{/*
Generate Secret name
*/}}
{{- define "base.secretName" -}}
{{- if .secretName }}
{{- printf "%s-%s" (include "base.fullname" .context) .secretName | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- include "base.fullname" .context }}
{{- end }}
{{- end }}

{{/*
Datadog monitor naming convention
*/}}
{{- define "base.datadogMonitorName" -}}
{{- $service := .Values.service.name }}
{{- $monitorType := .monitorType }}
{{- $env := .Values.global.environment }}
{{- printf "%s-%s-%s" $service $monitorType $env | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Alert severity priority based on environment
*/}}
{{- define "base.alertPriority" -}}
{{- if eq .Values.global.environment "prod" }}
{{- .prodPriority | default 1 }}
{{- else if eq .Values.global.environment "staging" }}
{{- .stagingPriority | default 2 }}
{{- else }}
{{- .testPriority | default 3 }}
{{- end }}
{{- end }}

{{/*
Generate security context with defaults
*/}}
{{- define "base.securityContext" -}}
{{- $defaults := dict "allowPrivilegeEscalation" false "capabilities" (dict "drop" (list "ALL")) "readOnlyRootFilesystem" true }}
{{- $merged := merge (.Values.deployment.securityContext | default dict) $defaults }}
{{- toYaml $merged }}
{{- end }}

{{/*
Check if running on OpenShift
*/}}
{{- define "base.isOpenShift" -}}
{{- if .Capabilities.APIVersions.Has "security.openshift.io/v1" }}
{{- true }}
{{- else }}
{{- false }}
{{- end }}
{{- end }}

{{/*
Return OpenShift-compatible security context
*/}}
{{- define "base.openShiftSecurityContext" -}}
{{- if include "base.isOpenShift" . }}
runAsNonRoot: true
{{- else }}
{{- toYaml .Values.deployment.podSecurityContext }}
{{- end }}
{{- end }}
