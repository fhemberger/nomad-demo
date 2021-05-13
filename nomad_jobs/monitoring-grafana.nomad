variable "datacenters" {
  type        = list(string)
  description = "List of datacenters to deploy to."
  default     = ["dc1"]
}

variable "image_tag" {
  type        = string
  description = "Docker image tag to deploy."
  default     = "latest"
}

variable "grafana_url" {
  type        = string
  description = "Public Grafana URL."
}

job "grafana" {
  datacenters = var.datacenters

  update {
    stagger      = "30s"
    max_parallel = 1
  }

  group "grafana" {
    count = 1

    ephemeral_disk {
      size    = 300
      migrate = true
    }

    restart {
      attempts = 3
      interval = "2m"
      delay    = "15s"
      mode     = "fail"
    }

    network {
      port "http" { to = 3000 }
    }

    task "grafana" {
      driver = "docker"

      artifact {
        # Double slash required to download just the specified subdirectory, see:
        # https://github.com/hashicorp/go-getter#subdirectories
        source = "git::https://github.com/fhemberger/nomad-demo.git//nomad_jobs/artifacts/grafana"
      }

      config {
        image = "grafana/grafana:${var.image_tag}"

        cap_drop = [
          "ALL",
        ]

        volumes = [
          "local:/etc/grafana:ro",
        ]

        ports = ["http"]
      }

      env {
        GF_INSTALL_PLUGINS           = "grafana-piechart-panel"
        GF_SERVER_ROOT_URL           = "${var.grafana_url}"
        GF_SECURITY_DISABLE_GRAVATAR = "true"
      }

      template {
        data = <<EOF
          {{ with secret "kv/monitoring/grafana" }}
          GF_SECURITY_ADMIN_USER="{{ .Data.username }}"
          GF_SECURITY_ADMIN_PASSWORD="{{ .Data.password }}"
          {{ end }}
        EOF

        destination = "secrets/vault.env"
        env         = true
      }

      vault {
        policies      = ["monitoring-grafana"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      resources {
        cpu    = 100
        memory = 50
      }

      service {
        name = "grafana"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.grafana.entrypoints=web"
        ]
        port = "http"

        check {
          type     = "http"
          path     = "/api/health"
          interval = "10s"
          timeout  = "2s"

          check_restart {
            limit           = 2
            grace           = "60s"
            ignore_warnings = false
          }
        }
      }
    }
  }
}
