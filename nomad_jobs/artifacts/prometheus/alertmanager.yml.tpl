{{ define "pagerdutyCheck" }}{{ with secret "kv/monitoring/alertmanager/pagerduty" }}{{ if .Data.service_key }}yes{{ end }}{{ end }}{{ end }}
{{ define "emailCheck" }}{{ with secret "kv/monitoring/alertmanager/smtp" }}{{ if .Data.smarthost }}yes{{ end }}{{ end }}{{ end }}
{{ $isPagerduty := executeTemplate "pagerdutyCheck" }}
{{ $isEmail := executeTemplate "emailCheck" }}
---
global:
{{ with secret "kv/monitoring/alertmanager/smtp" }}
{{ if .Data.smarthost }}
  smtp_from: "Alertmanager <noreply@{{ or (env "DOMAIN") "example.com" }}>"
  smtp_smarthost: "{{ .Data.smarthost }}"
  smtp_auth_username: "{{ .Data.username }}"
  smtp_auth_password: "{{ .Data.password }}"
{{ end }}
{{ end }}

route:
  group_by: ["instance"]
  group_wait: 2m
  group_interval: 1h
  repeat_interval: 1d
  receiver: {{ if eq isPagerduty "yes" }}pagerduty{{ else if eq isEmail "yes" }}email{{ else }}webhook{{ end }}

receivers:
{{ if eq isEmail "yes" }}
{{/* Check for email address in Consul KV */}}
{{ if keyExists "service/alertmanager/email" }}
  - name: email
    email_configs:
      - to: {{ key "service/alertmanager/email" }}
{{ end }}
{{ end }}

{{ with secret "kv/monitoring/alertmanager/pagerduty" }}
{{ if .Data.service_key }}
  - name: pagerduty
    pagerduty_configs:
      - service_key: "{{ .Data.service_key }}"
{{ end }}
{{ end }}

  - name: webhook
    webhook_configs:
      # FIXME: Sorry, processing alerts is not part of this demo, hence the stub
      - url: http://invalid

inhibit_rules:
  - source_match:
      severity: "critical"
    target_match:
      severity: "warning"
    equal: ["alertname"]
