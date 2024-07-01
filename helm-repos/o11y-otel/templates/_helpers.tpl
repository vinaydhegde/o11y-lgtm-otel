
{{- define "o11y-otel.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 50 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
The components in this chart create additional resources that expand the longest created name strings.
The longest name that gets created adds and extra 37 characters, so truncation should be 63-35=26.
*/}}
{{- define "o11y-otel.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 26 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 26 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 26 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "o11y-otel.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "o11y-otel.chartref" -}}
{{- replace "+" "_" .Chart.Version | printf "%s-%s" .Chart.Name -}}
{{- end }}

{{/* Generate basic labels */}}
{{- define "o11y-otel.labels" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: "{{ replace "+" "_" .Chart.Version }}"
app.kubernetes.io/part-of: {{ template "o11y-otel.name" . }}
chart: {{ template "o11y-otel.chartref" . }}
release: {{ $.Release.Name | quote }}
heritage: {{ $.Release.Service | quote }}
{{- if .Values.commonLabels}}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/* Allow KubeVersion to be overridden. */}}
{{- define "o11y-otel.kubeVersion" -}}
  {{- default .Capabilities.KubeVersion.Version .Values.kubeVersionOverride -}}
{{- end -}}

{{/* Get value based on current Kubernetes version */}}
{{- define "o11y-otel.kubeVersionDefaultValue" -}}
  {{- $values := index . 0 -}}
  {{- $kubeVersion := index . 1 -}}
  {{- $old := index . 2 -}}
  {{- $new := index . 3 -}}
  {{- $default := index . 4 -}}
  {{- if kindIs "invalid" $default -}}
    {{- if semverCompare $kubeVersion (include "o11y-otel.kubeVersion" $values) -}}
      {{- print $new -}}
    {{- else -}}
      {{- print $old -}}
    {{- end -}}
  {{- else -}}
    {{- print $default }}
  {{- end -}}
{{- end -}}

{{/* Get value for kube-controller-manager depending on insecure scraping availability */}}
{{- define "o11y-otel.kubeControllerManager.insecureScrape" -}}
  {{- $values := index . 0 -}}
  {{- $insecure := index . 1 -}}
  {{- $secure := index . 2 -}}
  {{- $userValue := index . 3 -}}
  {{- include "o11y-otel.kubeVersionDefaultValue" (list $values ">= 1.22-0" $insecure $secure $userValue) -}}
{{- end -}}

{{/* Get value for kube-scheduler depending on insecure scraping availability */}}
{{- define "o11y-otel.kubeScheduler.insecureScrape" -}}
  {{- $values := index . 0 -}}
  {{- $insecure := index . 1 -}}
  {{- $secure := index . 2 -}}
  {{- $userValue := index . 3 -}}
  {{- include "o11y-otel.kubeVersionDefaultValue" (list $values ">= 1.23-0" $insecure $secure $userValue) -}}
{{- end -}}

{{/*
  This helper converts the input value of memory to Bytes.
  Input needs to be a valid value as supported by k8s memory resource field.
 */}}
{{- define "opentelemetry-collector.convertMemToBytes" }}
  {{- $mem := lower . -}}
  {{- if hasSuffix "e" $mem -}}
    {{- $mem = mulf (trimSuffix "e" $mem | float64) 1e18 -}}
  {{- else if hasSuffix "ei" $mem -}}
    {{- $mem = mulf (trimSuffix "e" $mem | float64) 0x1p60 -}}
  {{- else if hasSuffix "p" $mem -}}
    {{- $mem = mulf (trimSuffix "p" $mem | float64) 1e15 -}}
  {{- else if hasSuffix "pi" $mem -}}
    {{- $mem = mulf (trimSuffix "pi" $mem | float64) 0x1p50 -}}
  {{- else if hasSuffix "t" $mem -}}
    {{- $mem = mulf (trimSuffix "t" $mem | float64) 1e12 -}}
  {{- else if hasSuffix "ti" $mem -}}
    {{- $mem = mulf (trimSuffix "ti" $mem | float64) 0x1p40 -}}
  {{- else if hasSuffix "g" $mem -}}
    {{- $mem = mulf (trimSuffix "g" $mem | float64) 1e9 -}}
  {{- else if hasSuffix "gi" $mem -}}
    {{- $mem = mulf (trimSuffix "gi" $mem | float64) 0x1p30 -}}
  {{- else if hasSuffix "m" $mem -}}
    {{- $mem = mulf (trimSuffix "m" $mem | float64) 1e6 -}}
  {{- else if hasSuffix "mi" $mem -}}
    {{- $mem = mulf (trimSuffix "mi" $mem | float64) 0x1p20 -}}
  {{- else if hasSuffix "k" $mem -}}
    {{- $mem = mulf (trimSuffix "k" $mem | float64) 1e3 -}}
  {{- else if hasSuffix "ki" $mem -}}
    {{- $mem = mulf (trimSuffix "ki" $mem | float64) 0x1p10 -}}
  {{- end }}
{{- $mem }}
{{- end }}

{{- define "opentelemetry-collector.gomemlimit" }}
{{- $memlimitBytes := include "opentelemetry-collector.convertMemToBytes" . | mulf 0.8 -}}
{{- printf "%dMiB" (divf $memlimitBytes 0x1p20 | floor | int64) -}}
{{- end }}
