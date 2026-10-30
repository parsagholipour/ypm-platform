{{- define "service.selectorLabels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- end }}

{{- define "service.labels" -}}
{{ include "service.selectorLabels" . }}
app.kubernetes.io/part-of: ypm
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
helm.sh/chart: {{ .root.Chart.Name }}-{{ .root.Chart.Version }}
{{- end }}

{{/* repository:tag@digest of a component (or CronJob), else of the release. */}}
{{- define "service.image" -}}
{{- $img := .component.image | default .root.Values.image -}}
{{- if not (and $img.repository $img.tag) -}}
{{- fail "image.repository and image.tag are required (the tag comes from the release branch's image.yaml)" -}}
{{- end -}}
{{ $img.repository }}:{{ $img.tag }}{{ with $img.digest }}@{{ . }}{{ end }}
{{- end }}

{{/* Substitute ${RDS_HOST} and ${RDS_PORT}. */}}
{{- define "service.subst" -}}
{{- $s := toString .value -}}
{{- $s = replace "${RDS_HOST}" (toString .root.Values.rds.host) $s -}}
{{- replace "${RDS_PORT}" (toString .root.Values.rds.port) $s -}}
{{- end }}

{{- define "service.probe" -}}
{{- if .http -}}
httpGet:
  path: {{ .http.path }}
  port: {{ .http.port }}
{{- else if .exec -}}
exec:
  command: {{ toJson .exec }}
{{- else if .tcp -}}
tcpSocket:
  port: {{ .tcp }}
{{- else -}}
{{- fail "probe needs http, tcp or exec" -}}
{{- end -}}
{{- end }}
