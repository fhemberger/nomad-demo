job "prometheus" {
  datacenters = ["dc1"]

  update {
    stagger      = "30s"
    max_parallel = 1
  }

  group "core" {
    count = 1

    ephemeral_disk {
      size    = 600
      migrate = true
    }

    task "prometheus" {
      driver = "docker"

      artifact {
        # Double slash required to download just the specified subdirectory, see:
        # https://github.com/hashicorp/go-getter#subdirectories
        source = "git::https://github.com/fhemberger/nomad-demo.git//nomad_jobs/artifacts/prometheus"
      }

      config {
        image = "prom/prometheus:latest"

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml:ro",
        ]

        port_map {
          prometheus_ui = 9090
        }
      }

      resources {
        network {
          port "prometheus_ui" {}
        }
      }

      service {
        name = "prometheus"

        tags = [
          "http",
          # See: https://docs.traefik.io/routing/services/
          "traefik.http.services.prometheus.loadbalancer.sticky=true",
          "traefik.http.services.prometheus.loadbalancer.sticky.cookie.httponly=true",
          # "traefik.http.services.prometheus.loadbalancer.sticky.cookie.secure=true",
          "traefik.http.services.prometheus.loadbalancer.sticky.cookie.samesite=strict",
        ]

        port = "prometheus_ui"

        check {
          type     = "http"
          path     = "/"
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
    }

    task "alertmanager" {
      driver = "docker"

      artifact {
        source = "git::https://github.com/fhemberger/nomad-demo.git//nomad_jobs/artifacts/prometheus"
      }

      config {
        image = "prom/alertmanager:latest"

        volumes = [
          "local/alertmanager.yml:/etc/alertmanager/config.yml",
        ]

        port_map {
          alertmanager_ui = 9093
        }
      }

      resources {
        network {
          port "alertmanager_ui" {}
        }
      }

      service {
        name = "alertmanager"

        tags = [
          "http",
          "prometheus",
          # See: https://docs.traefik.io/routing/services/
          "traefik.http.services.alertmanager.loadbalancer.sticky=true",
          "traefik.http.services.alertmanager.loadbalancer.sticky.cookie.httponly=true",
          # "traefik.http.services.alertmanager.loadbalancer.sticky.cookie.secure=true",
          "traefik.http.services.alertmanager.loadbalancer.sticky.cookie.samesite=strict",
        ]

        port = "alertmanager_ui"

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }

  group "exporters" {
    count = 1

    task "consul-exporter" {
      driver = "docker"

      config {
        image = "prom/consul-exporter:latest"

        args = [
          "--consul.server",
          "consul.service.consul:8500",
        ]

        port_map {
          consul_exporter = 9107
        }
      }

      resources {
        network {
          port "consul_exporter" {}
        }
      }

      service {
        name = "${TASK}"
        tags = ["prometheus"]
        port = "consul_exporter"

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
