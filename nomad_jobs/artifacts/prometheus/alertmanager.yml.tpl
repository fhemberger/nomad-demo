---
global:
{{ with secret "kv/monitoring/alertmanager/smtp" }}
{{ if .Data.smarthost }}
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
  receiver: webhook

receivers:
{{ with secret "kv/monitoring/alertmanager/pagerduty" }}
{{ if .Data.service_key }}
password = "{{ .Data.service_key }}"
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
