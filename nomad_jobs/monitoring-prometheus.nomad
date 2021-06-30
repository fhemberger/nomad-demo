variable "datacenters" {
  type        = list(string)
  description = "List of datacenters to deploy to."
  default     = ["dc1"]
}

variable "domain" {
  type        = string
  description = "Base domain name."
}

variable "prometheus_image_tag" {
  type        = string
  description = "Prometheus Docker image tag to deploy."
  default     = "latest"
}

variable "alertmanager_image_tag" {
  type        = string
  description = "Alertmanager Docker image tag to deploy."
  default     = "latest"
}

variable "consul_exporter_image_tag" {
  type        = string
  description = "consul_exporter Docker image tag to deploy."
  default     = "latest"
}

job "prometheus" {
  datacenters = var.datacenters

  update {
    stagger      = "30s"
    max_parallel = 1
  }

  group "prometheus" {
    count = 1

    ephemeral_disk {
      size    = 600
      migrate = true
    }

    network {
      port "prometheus_ui" { to = 9090 }
    }

    task "prometheus" {
      driver = "docker"

      artifact {
        # Double slash required to download just the specified subdirectory, see:
        # https://github.com/hashicorp/go-getter#subdirectories
        source = "git::https://github.com/fhemberger/nomad-demo.git//nomad_jobs/artifacts/prometheus"
      }

      config {
        image = "prom/prometheus:${var.prometheus_image_tag}"

        cap_drop = [
          "ALL",
        ]

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml:ro",
        ]

        ports = ["prometheus_ui"]
      }

      resources {
        cpu    = 100
        memory = 100
      }

      service {
        name = "prometheus"

        tags = [
          "prometheus",
          "traefik.enable=true",
          "traefik.http.routers.prometheus.entrypoints=web",
          # See: https://docs.traefik.io/routing/services/
          "traefik.http.services.prometheus.loadbalancer.sticky=true",
          "traefik.http.services.prometheus.loadbalancer.sticky.cookie.httponly=true",
          # "traefik.http.services.prometheus.loadbalancer.sticky.cookie.secure=true",
          "traefik.http.services.prometheus.loadbalancer.sticky.cookie.samesite=strict",
        ]

        port = "prometheus_ui"

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }

      template {
        source        = "local/prometheus.yml.tpl"
        destination   = "local/prometheus.yml"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      vault {
        policies      = ["monitoring-prometheus"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }

  group "alertmanager" {
    count = 2

    spread {
      attribute = "${node.unique.name}"
      weight    = 100
    }

    network {
      port "alertmanager_ui" { to = 9093 }
      port "alertmanager_cluster" { to = 9094 }
    }

    task "alertmanager" {
      driver = "docker"

      artifact {
        source = "git::https://github.com/fhemberger/nomad-demo.git//nomad_jobs/artifacts/prometheus"
      }

      config {
        image = "prom/alertmanager:${var.alertmanager_image_tag}"

        cap_drop = [
          "ALL",
        ]

        args = [
          "--cluster.peer",
          "${ALERTMANAGER_CLUSTER_PEER}",
        ]

        volumes = [
          "secret/alertmanager.yml:/etc/alertmanager/config.yml",
        ]

        ports = ["alertmanager_ui", "alertmanager_cluster"]
      }

      env {
        DOMAIN = "${var.domain}"
      }

      resources {
        cpu    = 100
        memory = 50
      }

      service {
        name = "alertmanager"

        tags = [
          "prometheus",
          "traefik.enable=true",
          "traefik.http.routers.alertmanager.entrypoints=web",
          # See: https://docs.traefik.io/routing/services/
          "traefik.http.services.alertmanager.loadbalancer.sticky=true",
          "traefik.http.services.alertmanager.loadbalancer.sticky.cookie.httponly=true",
          # "traefik.http.services.alertmanager.loadbalancer.sticky.cookie.secure=true",
          "traefik.http.services.alertmanager.loadbalancer.sticky.cookie.samesite=strict",
        ]

        port = "alertmanager_ui"

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }

      template {
        data = <<EOF
        ALERTMANAGER_CLUSTER_PEER = {{ range service "alertmanager" -}}
          {{- ne (env "NOMAD_IP_alertmanager_cluster") .Address }}{{ .Address }}:{{ .Port }}{{ end -}}
        {{- end }}
        EOF

        destination = "local/alertmanager.env"
        env         = true
      }

      template {
        source        = "local/alertmanager.yml.tpl"
        destination   = "secret/alertmanager.yml"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      vault {
        policies      = ["monitoring-alertmanager"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }

  group "exporters" {
    count = 1

    network {
      port "consul_exporter" { to = 9107 }
    }

    task "consul-exporter" {
      driver = "docker"

      config {
        image = "prom/consul-exporter:${var.consul_exporter_image_tag}"

        cap_drop = [
          "ALL",
        ]

        args = [
          "--consul.server",
          "consul.service.consul:8500",
        ]

        ports = ["consul_exporter"]
      }

      resources {
        cpu    = 100
        memory = 50
      }

      service {
        name = "${TASK}"
        tags = ["prometheus"]
        port = "consul_exporter"

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
