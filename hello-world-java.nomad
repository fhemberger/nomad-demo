job "hello-world-java" {
  datacenters = ["dc1"]
  type = "service"

  # Specify this job to have rolling updates, with 30 second intervals.
  update {
    stagger = "30s"
    max_parallel = 1
  }

  # A group defines a series of tasks that should be co-located
  # on the same client (host). All tasks within a group will be
  # placed on the same host.
  group "web" {
    # Specify the number of these tasks we want.
    count = 1

    task "frontend" {
      driver = "java"

      # https://github.com/bjrbhre/hello-http-java
      artifact {
        source = "http://jar-server.demo/HelloWorld.jar"
      }

      config {
        jar_path = "local/HelloWorld.jar"
        jvm_options = ["-Dhelloworld.port=${NOMAD_PORT_http}"]
      }

      resources {
        cpu = 100
        memory = 100
        network {
          mbits = 1
          port "http" {
            static = "8000"
          }
        }
      }

      service {
        name = "hello-java"
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
