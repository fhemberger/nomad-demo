job "hello-world-docker" {
  datacenters = ["dc1"]
  type        = "service"

  # Specify this job to have rolling updates, with 30 second intervals.
  update {
    stagger      = "30s"
    max_parallel = 1
  }

  # A group defines a series of tasks that should be co-located
  # on the same client (host). All tasks within a group will be
  # placed on the same host.
  group "web" {
    # Specify the number of these tasks we want.
    count = 1

    restart {
      attempts = 3
      interval = "2m"
      delay    = "15s"
      mode     = "fail"
    }

    task "frontend" {
      driver = "docker"

      config {
        image = "rancher/hello-world"

        port_map {
          http = 80
        }
      }

      resources {
        cpu    = 100
        memory = 100

        network {
          port "http" {}
        }
      }

      service {
        name = "hello-docker"
        tags = ["http"]
        port = "http"

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
