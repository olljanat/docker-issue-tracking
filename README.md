# docker-issue-tracking
Keeping track of status different components issues which we have seen with Linux + Windows hybrid Docker Swarm.

**NOTE!** I recommended to use Windows Server 2019 as it contains many improvements which are missing from Windows Server 2016.

I also recommended you to avoid Hyper-V isolation mode as it have very poor performance.

You might also be interested about [my custom pached version of Docker for Windows Server](https://github.com/olljanat/moby/releases/tag/19.03.5-olljanat2) which contains fixes which are not yet released as part of official version.


# Example of fully working stacks

These [docker stack](https://docs.docker.com/engine/reference/commandline/stack_deploy/) are tested to be fully working on Linux + Windows hybrid swarm and connections between all the containers are working just fine.

## Traefik
As a edge router/reverse proxy this example uses [Traefik](https://doc.traefik.io/traefik/) which runs on swarm manager roles and automatically generates rules based on Docker service labels.
```yaml
version: '3.8'

services:
  traefik:
    image: "traefik:v2.3.0"
    command:
      - "--api.dashboard=true"
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.swarmMode=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=traefik-internal"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.forwardedHeaders.insecure"
      - "--accesslog=true"
      - "--ping"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    networks:
      - traefik-public
      - traefik-internal
    ports:
     - target: 80
       published: 80
       protocol: tcp
       mode: host
     - target: 8080
       published: 8080
       protocol: tcp
       mode: host
    deploy:
      mode: replicated
      replicas: 2
      placement:
        max_replicas_per_node: 1
        constraints:
          - node.role == manager
          - node.platform.os == linux
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
networks:
  traefik-public:
    driver: bridge
    name: bridge
    external: true
  traefik-internal:
    driver: overlay
    name: traefik-internal
    internal: true
```

After you deploy Traefik you can find its dashboard from `http://<manager node IP>:8080/dashboard/`


## Whoami
This example will deploy [whoami](https://github.com/StefanScherer/whoami) service to each node which helps you with testing/troubleshooting.
That is always good way to start when you deploy new environment.

Note that we do not publish any ports from these services but instead of just connect them to **traefik-internal** network.
As additionally this example sets `endpoint_mode: dnsrr` for each service to make sure that connectivity inside of overlay networks between Linux and Windows containers is working correctly. 

```yaml
version: '3.7'

networks:
  test:
    driver: overlay

services:
  win1:
    image: stefanscherer/whoami
    networks:
      - bar
      - traefik-internal
    deploy:
      endpoint_mode: dnsrr
      placement:
        constraints:
          - node.platform.os==windows
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.win1.rule=PathPrefix(`/win1`)"
        - "traefik.http.services.win1.loadbalancer.server.port=8080"

  linux1:
    image: stefanscherer/whoami
    networks:
      - bar
      - traefik-internal
    deploy:
      endpoint_mode: dnsrr
      placement:
        constraints:
          - node.platform.os==linux
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.linux1.rule=PathPrefix(`/linux1`)"
        - "traefik.http.services.linux1.loadbalancer.server.port=8080"

  win2:
    image: stefanscherer/whoami
    networks:
      - foo
      - traefik-internal
    deploy:
      endpoint_mode: dnsrr
      placement:
        constraints:
          - node.platform.os==windows
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.win2.rule=PathPrefix(`/win2`)"
        - "traefik.http.services.win2.loadbalancer.server.port=8080"

  linux2:
    image: stefanscherer/whoami
    networks:
      - foo
      - traefik-internal
    deploy:
      endpoint_mode: dnsrr
      placement:
        constraints:
          - node.platform.os==linux
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.linux2.rule=PathPrefix(`/linux2`)"
        - "traefik.http.services.linux2.loadbalancer.server.port=8080"

networks:
    bar:
        driver: overlay
        name: bar
    foo:
        driver: overlay
        name: foo
    traefik-internal:
      external: true

```

After you are deployed this stack you can connect to each of your service using these URLs:
* `http://<manager node IP>/win1/`
* `http://<manager node IP>/linux1/`
* `http://<manager node IP>/win2/`
* `http://<manager node IP>/linux2/`

