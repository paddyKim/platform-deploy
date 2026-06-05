{{- define "platform-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "platform-app.labels" -}}
app.kubernetes.io/name: {{ include "platform-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "platform-app.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "platform-app.componentLabels" -}}
{{ include "platform-app.labels" . }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "platform-app.componentSelectorLabels" -}}
{{ include "platform-app.selectorLabels" . }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}
