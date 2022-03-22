{{/*
Template for helm hook. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "serverapp.helmhook.tpl" }}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
  {{- if $this.hook }}
    "helm.sh/hook": {{ $this.hook.type | default "pre-install" }}
    "helm.sh/hook-weight": {{ $this.hook.weight | default "0" | quote }}
    "helm.sh/hook-delete-policy": {{ $this.hook.deletePolicy | default "hook-succeeded" }}
  {{- end }}
{{- end }}

{{- define "serverapp.deploymentId.tpl" -}}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
{{- $versions := $outer.Values.appName }}
  {{- range $k, $v := $outer.Values.deployments }}
    {{- range $kk, $vv := $v.containers }}
      {{- $versions = print $versions "." $vv.version }}
    {{- end }}
  {{- end }}
  {{- $versions }}
{{- end }}
{{- define "serverapp.dependencyCheckers.tpl" }}
{{- $deploymentOrJob := index . 0 }}
{{- $outer := index . 1 }}
  {{- range $deploymentOrJob.dependsOn }}
    {{- if .external }}
      {{- $appName := .external }}
      {{- $endpoints := get $outer.Values.global.externalHttpEndpoints $appName }}
      {{- range $i, $endpoint := $endpoints }}
        {{- include "serverapp.container.waitForService.tpl" (list $appName "" $endpoint $i) }}
      {{- end }}
    {{- else }}
      {{- $appName := .chart }}
      {{- $podName := .deployment | default "" }}
      {{- include "serverapp.container.waitForService.tpl" (list $appName $podName "" 0) }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
We will use it for waiting proper migrations in the deployment
*/}}
{{- define "serverapp.checksum" -}}
{{ tpl (toYaml .Values) . | sha256sum }}
{{- end -}}

{{/*
Helper function for migrationId.
index 0: job context
index 1: root context
*/}}
{{- define "serverapp.migrationId" -}}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
{{- $test := print $this.name "." $this.containers.mainContainer.version }}
{{- $test }}
{{- end -}}