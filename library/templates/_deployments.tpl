{{/*
Wrapper Template for Deployment. Iterating map of deployments
*/}}
{{- define "serverapp.deployment.wrapper.tpl"}}
{{- $outer := .}}
  {{- range $k, $v := .Values.deployments }}
    {{ include "serverapp.deployment.tpl" (list $v $outer) }}
      initContainers:
      {{- include "serverapp.dependencyCheckers.tpl" (list $v $outer) | indent 6}}
      {{- range $kk, $vv := $outer.Values.jobs }}
        {{- if (not (eq $vv.isMigration false)) }}
          {{- include "serverapp.container.waitForJob.tpl" (list $vv $outer) | indent 6 }}
        {{- end}}
      {{- end }}
      {{- range $kk, $vv := $v.initContainers }}
        {{- include "serverapp.container.tpl" (list $vv $outer) | indent 6 }}
      {{- end }}
      containers:
    {{- range $kk, $vv := $v.containers }}
      {{- include "serverapp.container.tpl" (list $vv $outer) | indent 6 }}
    {{- end }}
---
  {{- end }}
{{- end }}


{{/*
Template for Deployment. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "serverapp.deployment.tpl" }}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $this.name }}
  namespace: {{ $outer.Values.global.namespace}}
  labels:
    app.kubernetes.io/managed-by: {{ $outer.Release.Service | quote }}
    app.kubernetes.io/instance: {{ $outer.Release.Name | quote }}
    helm.sh/chart: "{{ $outer.Chart.Name }}-{{ $outer.Chart.Version }}"
  {{- if $this.labels }}
    {{- toYaml $this.labels | nindent 4 }}
  {{- else }}
    app: {{ $this.name }}
  {{- end }}
  annotations:
  {{- include "serverapp.helmhook.tpl" (list $this $outer) }}
spec:
  replicas: {{ $this.replicas }}
  selector:
    matchLabels:
      app: {{ $this.name }}
  strategy:
    {{- if $this.strategy }}
      {{- toYaml $this.strategy | nindent 4 }}
    {{- else }}
    type: Recreate
    {{- end }}
  template:
    metadata:
      labels:
        helm.sh/deployed-by: {{ $outer.Values.appName}}
      {{- if $this.labels }}
        {{- toYaml $this.labels | nindent 8 }}
      {{- else }}
        app: {{ $this.name }}
      {{- end }}
      annotations:
        checksum/apps: {{ include "serverapp.checksum" $outer }}
    spec:
    {{- if $outer.Values.global.nodeType }}
      nodeSelector:
        node_type: {{$outer.Values.global.nodeType}}
    {{- end }}
      restartPolicy: {{ $this.restartPolicy | default "Always" }}
  {{- if $this.securityContext }}
      securityContext:
    {{- toYaml $this.securityContext | nindent 8 }}
  {{- end }}
  {{- if $this.serviceAccountName }}
      serviceAccountName: {{ $this.serviceAccountName }}
  {{- end }}
  {{- if $this.hostAliases }}
      hostAliases:
    {{- toYaml $this.hostAliases | nindent 6 }}
  {{- end }}
  {{- if $this.volumes }}
      volumes:
    {{- toYaml $this.volumes | nindent 6 }}
  {{- end }}
{{- end }}