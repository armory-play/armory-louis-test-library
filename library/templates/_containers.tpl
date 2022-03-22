{{/*
Header Template for container. This chart will be included in the main container template.
*/}}
{{- define "serverapp.container.header.tpl"}}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
- name: {{ $this.name | default $outer.Values.appName }}
  image: {{$this.image}}:{{$this.version | default "latest" }}
  {{- if $this.securityContext }}
  securityContext:
  {{- toYaml $this.securityContext | nindent 4 }}
  {{- end }}
  {{- if $this.workingDir }}
  workingDir: {{ $this.workingDir }}
  {{- end }}
{{- end }}

{{/*
Body Template for container. This chart will be included in the main container template.
*/}}
{{- define "serverapp.container.body.tpl"}}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
  {{- if $this.volumeMounts }}
  volumeMounts:
    {{- toYaml $this.volumeMounts | nindent 2 }}
  {{- end }}
  {{- if $this.env }}
  env:
    {{- range $k,$v := $this.env }}
  - name: {{$k}}
    value: "{{$v}}"
    {{- end}}
  {{- end }}
  {{- if $this.resources }}
  resources:
    {{- toYaml $this.resources | nindent 4 }}
  {{- end }}
  {{- if $this.livenessProbe }}
  {{- if $this.ports }}
  ports:
    {{- range $this.ports }}
    {{- $defaultPortName := print "port-" .containerPort }}
  - containerPort: {{.containerPort}}
    name: {{.name | default $defaultPortName}}
    {{- end }}
  {{- end }}
  livenessProbe:
    {{- if $this.livenessProbe.httpGet }}
    httpGet:
      path: {{ $this.livenessProbe.httpGet.path }}
      port: {{ $this.livenessProbe.httpGet.port | default (index $outer.Values.services.service.ports 0).port }}
      scheme: {{ $this.livenessProbe.httpGet.scheme | default "HTTP" }}
    {{- end }}
    {{- if $this.livenessProbe.tcpSocket }}
    tcpSocket:
      {{ toYaml $this.livenessProbe.tcpSocket }}
    {{- end }}
    {{- if $this.livenessProbe.exec }}
    exec:
      command:
      {{- range $this.livenessProbe.exec.command }}
      - {{ . }}
      {{- end }}
    {{- end }}
    initialDelaySeconds: {{ $this.livenessProbe.initialDelaySeconds | default 20 }}
    periodSeconds: {{ $this.livenessProbe.periodSeconds | default 30 }}
    successThreshold: {{ $this.livenessProbe.successThreshold | default 1 }}
    timeoutSeconds: {{ $this.livenessProbe.timeoutSeconds | default 5 }}
    failureThreshold: {{ $this.livenessProbe.failureThreshold | default 3 }}
  {{- end }}
  {{- if $this.readinessProbe }}
  readinessProbe:
    {{- if $this.readinessProbe.httpGet }}
    httpGet:
      path: {{ $this.readinessProbe.httpGet.path }}
      port: {{ $this.readinessProbe.httpGet.port | default (index $outer.Values.services.service.ports 0).port }}
      scheme: {{ $this.readinessProbe.httpGet.scheme | default "HTTP" }}
    {{- end }}
    {{- if $this.readinessProbe.tcpSocket }}
    tcpSocket:
      {{ toYaml $this.readinessProbe.tcpSocket }}
    {{- end }}
    {{- if $this.readinessProbe.exec }}
    exec:
      {{- $commandType := typeOf $this.readinessProbe.exec.command}}
      {{- if eq $commandType "string" }}
      command: {{ $this.readinessProbe.exec.command }}
      {{- else }}
      command:
        {{- range $this.readinessProbe.exec.command }}
      - {{ . }}
        {{- end }}
      {{- end }}

    {{- end }}
    initialDelaySeconds: {{ $this.readinessProbe.initialDelaySeconds | default 20 }}
    periodSeconds: {{ $this.readinessProbe.periodSeconds | default 3 }}
    successThreshold: {{ $this.readinessProbe.successThreshold | default 1 }}
    timeoutSeconds: {{ $this.readinessProbe.timeoutSeconds | default 5 }}
    failureThreshold: {{ $this.readinessProbe.failureThreshold | default 3 }}
  {{- end }}
{{- end }}

{{/*
Container command and arg Template. This chart will be included in the main container template.
*/}}
{{- define "serverapp.container.command.tpl" }}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
  {{- if or $this.command $this.multilineScript }}
    {{- $commandType := typeOf $this.command}}
    {{- if eq $commandType "string" }}
  command: {{ $this.command }}
    {{- else }}
  command: 
      {{- range $this.command }}
  - {{ . | quote }}
      {{- end }}
    {{- end }}
    {{- if $this.multilineScript }}
  - | {{- $this.multilineScript | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- if $this.args }}
    {{- $argType := typeOf $this.args}}
    {{- if eq $argType "string" }}
  args: {{ $this.args }}
    {{- else }}
  args: 
      {{- range $this.args }}
  - {{ . | quote }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Main Template for container. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "serverapp.container.tpl" }}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
  {{- include "serverapp.container.header.tpl" (list $this $outer) }}
  {{- include "serverapp.container.command.tpl" (list $this $outer) }}
  {{- include "serverapp.container.body.tpl" (list $this $outer) }}
{{- end }}

{{- define "serverapp.container.waitForJob.tpl" }}
{{- $this := index . 0 }}
{{- $outer := index . 1 }}
  {{- $migrationId := include "serverapp.migrationId" (list $this $outer) }}
- name: wait-for-{{ $this.name }}-job
  image: "bitnami/kubectl:1.13.4"
  args:
    - "wait"
    - "--selector=migrationId={{ $migrationId }}"
    - "--for=condition=complete"
    - "--timeout=10m"
    - "jobs"
{{- end }}

{{- define "serverapp.container.waitForService.tpl" }}
{{- $appName := index . 0 }}
{{- $podName := index . 1 }}
{{- $endpoint := index . 2 }}
{{- $i := index . 3 }}
- name: wait-for-{{ $appName }}-service-{{ $i }}
  {{- if or (eq $endpoint "") }}
  image: "bitnami/kubectl:1.13.4"
  args:
    - "wait"
    {{- if (eq $podName "") }}
    - "--selector=helm.sh/deployed-by={{ $appName }}"
    {{- else }}
    - "--selector=helm.sh/deployed-by={{ $appName }},app={{ $podName }}"
    {{- end }}
    - "--for=condition=ready"
    - "--timeout=10m"
    - "pod"
  {{- else }}
  image: "curlimages/curl:7.82.0"
  command: ["sh", "-c"]
  args: ['while [`curl -Lk --write-out "%{http_code}\n" --silent --output /dev/null "{{ $endpoint }}"` -ne 200 ]; do sleep 3; done']
  {{- end }}
{{- end }}