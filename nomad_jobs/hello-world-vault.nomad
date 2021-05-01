job "hello-world-vault" {
  datacenters = ["dc1"]

  group "web" {
    count = 1

    restart {
      attempts = 3
      interval = "2m"
      delay    = "15s"
      mode     = "fail"
    }

    network {
      port "http" {}
    }

    task "frontend" {
      driver = "docker"

      config {
        image = "ghcr.io/fhemberger/nomad-demo-hello-world-vault"

        cap_drop = [
          "ALL",
        ]

        port_map {
          http = 8080
        }
      }

      service {
        name = "hello-vault"
        tags = ["http"]
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
