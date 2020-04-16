---
global:
  scrape_interval: 15s

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

  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
    relabel_configs:
      - target_label: instance
        replacement: "{{ env "attr.unique.hostname" }}"

  - job_name: "traefik"
    static_configs:
      - targets: ["traefik.demo:8080"]
    relabel_configs:
      - target_label: instance
        replacement: "loadbalancer"
