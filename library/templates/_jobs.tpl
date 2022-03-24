{{/*
Wrapper Template for Deployment. Iterating map of jobs
*/}}
{{- define "serverapp.job.wrapper.tpl"}}
{{- $outer := .}}
  {{- range $k, $v := .Values.jobs }}
	{{ include "serverapp.job.tpl" (list $v $outer) }}
	initContainers:
	{{- include "serverapp.dependencyCheckers.tpl" (list $v $outer) | indent 6}}
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
Base Template for Job template. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "serverapp.job.header.tpl" }}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $this.name }}
  namespace: {{ $outer.Values.global.namespace}}
  labels:
    app.kubernetes.io/managed-by: {{ $outer.Release.Service | quote }}
    app.kubernetes.io/instance: {{ $outer.Release.Name | quote }}
    helm.sh/chart: "{{ $outer.Chart.Name }}-{{ $outer.Chart.Version }}"
    migrationId: "{{- include "serverapp.migrationId" (list $this $outer) }}"
  {{- if $this.labels }}
    {{- toYaml $this.labels | nindent 4 }}
  {{- else }}
    app: {{ $outer.Values.appName }}
    job: {{ $this.name }}
  {{- end }}
  annotations:
  {{- include "serverapp.helmhook.tpl" (list $this $outer) }}
spec:
  {{- if $this.ttlSecondsAfterFinished }}
  ttlSecondsAfterFinished: {{ $this.ttlSecondsAfterFinished }}
  {{- end }}
  backoffLimit: {{ $this.backoffLimit | default 6 }}
  parallelism: {{ $this.parallelism | default 1 }}
  completions: {{ $this.completions | default 1 }}
  template:
    metadata:
      labels:
  {{- if $this.labels }}
    {{- toYaml $this.labels | nindent 8 }}
  {{- else }}
        app: {{ $outer.Values.appName }}
        flavour: migration
        tag: mysql
  {{- end }}
{{- end }}

{{/*
Default Template for Job. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "serverapp.job.tpl" }}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
{{- include "serverapp.job.header.tpl" (list $this $outer) }}
    spec:
  {{- if $this.volumes }}
      volumes:
      {{- toYaml $this.volumes | nindent 6 }}
  {{- end }}
      restartPolicy: {{ $this.restartPolicy | default "Never" }}
{{- end }}