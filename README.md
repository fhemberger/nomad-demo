# Consul/Nomad Demo

```sh
brew cask install vagrant
brew install ansible
git clone --depth=1 https://github.com/fhemberger/...
cd ...
vagrant up --no-provision
vagrant provision
```


## Java demo

Compile a "[Hello world](https://github.com/bjrbhre/hello-http-java)" Java app and serve the file locally.

## Remove dead/completed jobs

Dead/completed jobs are cleaned up in accordance to the garbage collection interval (default: `1h`). You can force garbage collection using the System API endpoint which will run the global garbage collector:

```sh
vagrant ssh consul-nomad-node1

# Inside the VM:
curl -X PUT http://localhost:4646/v1/system/gc
```

If you wish to lower the GC interval permanently for jobs, you can use the [job_gc_threshold][https://www.nomadproject.io/docs/agent/configuration/server.html#job_gc_threshold] configuration parameter within the server config stanza.


# TODO
> This means that this server will manage state and make scheduling decisions but will not run any tasks. Now we need some agents to run tasks!


- docker local build des images auf allen nodes
- fileserver starten
- alternativ: placement-condition, dass der container nur auf dem ersten node läuft?


dig @10.1.10.21 -p 8600 +short nomad.service.consul.
