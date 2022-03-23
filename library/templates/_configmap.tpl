{{/*
Default Template for Deployment. Iterating map of configMaps
*/}}
{{- define "serverapp.configmap.wrapper.tpl"}}
{{- $outer := .}}
  {{- range $k, $v := .Values.configMaps }}
    {{ include "serverapp.configmap.tpl" (list $v $outer) }}
---
  {{- end }}
{{- end }}

{{- define "serverapp.configmap.tpl" }}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
{{- $defaultConfigName := print $outer.Values.appName "-config" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $this.name | default $defaultConfigName }}
  namespace: {{ $outer.Values.global.namespace}}
  labels:
    app.kubernetes.io/managed-by: {{ $outer.Release.Service | quote }}
    app.kubernetes.io/instance: {{ $outer.Release.Name | quote }}
    helm.sh/chart: "{{ $outer.Chart.Name }}-{{ $outer.Chart.Version }}"
  {{- if $this.labels }}
    {{- toYaml $this.labels | nindent 4 }}
  {{- else }}
    app: {{ $outer.Values.appName }}
  {{- end }}
data:
  {{- range $this.data}}
    {{- if .filepath }}
  {{ .key }}: |
{{ $outer.Files.Get .filepath | indent 4 }}
    {{- else }}
  {{ .key }}: {{ .value }}
    {{- end }}
  {{- end }}
{{- end }}