---
global:
  scrape_interval: 15s

alerting:
  alertmanagers:
    - consul_sd_configs:
        - server: "consul.service.consul:8500"
          services: ["alertmanager"]

scrape_configs:
  - job_name: "consul"
    consul_sd_configs:
      - server: "consul.service.consul:8500"
        tags: ["prometheus"]
    relabel_configs:
      - source_labels: [__meta_consul_tags]
        separator: ','
        regex: label:([^=]+)=([^,]+)
        target_label: ${1}
        replacement: ${2}
      - source_labels: [__meta_consul_node]
        target_label: instance
      - source_labels: [__meta_consul_service]
        target_label: service

  - job_name: "nomad"
    consul_sd_configs:
      - server: "consul.service.consul:8500"
        services: ["nomad-client", "nomad"]
    metrics_path: /v1/metrics
    params:
      format: ["prometheus"]
    relabel_configs:
      - source_labels: [__meta_consul_service_port]
        regex: '4646'
        action: keep
      - source_labels: [__meta_consul_node]
        target_label: instance
      - source_labels: [__meta_consul_service]
        target_label: service

  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
    relabel_configs:
      - target_label: instance
        replacement: "{{ env "attr.unique.hostname" }}"
      - target_label: service
        replacement: "prometheus"

  - job_name: "traefik"
    static_configs:
      - targets: ["traefik.demo:8080"]
    relabel_configs:
      - target_label: instance
        replacement: "loadbalancer"

  - job_name: 'vault'
    metrics_path: "/v1/sys/metrics"
    params:
      format: ['prometheus']
    # scheme: https
    # tls_config:
    #   ca_file: your_ca_here.pem
    # bearer_token: "your_vault_token_here"
    static_configs:
      - targets: ["active.vault.service.consul:8200"]
    relabel_configs:
      - source_labels: [__meta_consul_node]
        target_label: instance
