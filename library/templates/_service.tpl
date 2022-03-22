{{/*
Default Template for Deployment. Iterating map of services
*/}}
{{- define "serverapp.service.wrapper.tpl"}}
{{- $outer := .}}
  {{- range $k, $v := .Values.services }}
    {{ include "serverapp.service.tpl" (list $v $outer) }}
---
  {{- end }}
{{- end }}

{{/*
Default Template for Service. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "serverapp.service.tpl" }}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
apiVersion: v1
kind: Service
metadata:
  name: {{$this.name | default $outer.Values.appName}}
  namespace: {{$outer.Values.global.namespace}}
  labels:
    app.kubernetes.io/managed-by: {{ $outer.Release.Service | quote }}
    app.kubernetes.io/instance: {{ $outer.Release.Name | quote }}
    helm.sh/chart: "{{ $outer.Chart.Name }}-{{ $outer.Chart.Version }}"
spec:
  type: {{$this.type | default (printf "ClusterIP")}}
  ports:
  {{- range $this.ports }}
  {{- $defaultPortName := print $outer.Values.appName "-" .port }}
  - port: {{.port}}
    targetPort: {{.targetPort | default .port }}
    name: {{.name | default $defaultPortName}}
    protocol: {{.protocol | default "TCP" }}
    {{- if and $this.type "NodePort" .nodePort }}
    nodePort: {{.nodePort}}
    {{- end }}
  {{- end}}
  selector:
  {{- if $this.selector}}
    {{- toYaml $this.selector | nindent 4 }}
  {{- else }}
    app: {{$outer.Values.appName}}
  {{- end }}
{{- end }}