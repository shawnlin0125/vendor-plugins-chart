{{- define "vendor-plugins.labels" -}}
app.kubernetes.io/managed-by: Helm
app.kubernetes.io/part-of: vendor-plugins
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "vendor-plugins.name" -}}
{{ .name }}
{{- end -}}

{{- define "vendor-plugins.fullname" -}}
vendor-plugin-{{ .name }}
{{- end -}}
