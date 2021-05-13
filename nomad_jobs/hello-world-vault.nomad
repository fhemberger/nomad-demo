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

job "hello-world-vault" {
  datacenters = var.datacenters

  group "web" {
    count = 1

    restart {
      attempts = 3
      interval = "2m"
      delay    = "15s"
      mode     = "fail"
    }

    network {
      port "http" { to = 8080 }
    }

    task "frontend" {
      driver = "docker"

      config {
        image = "ghcr.io/fhemberger/nomad-demo-hello-world-vault:${var.image_tag}"

        cap_drop = [
          "ALL",
        ]

        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 50
      }

      service {
        name = "hello-vault"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.hello-vault.entrypoints=web"
        ]
        port = "http"

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }

      template {
        data = <<EOF
          {{ with secret "kv/hello-world-vault" }}
          VAULT_SECRET_URL="{{ .Data.url }}"
          VAULT_SECRET_USERNAME="{{ .Data.username }}"
          VAULT_SECRET_PASSWORD="{{ .Data.password }}"
          {{ end }}
        EOF

        destination = "secrets/vault.env"
        env         = true
      }

      vault {
        policies      = ["hello-world-vault"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}
