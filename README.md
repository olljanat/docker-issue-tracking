# docker-issue-tracking
Keeping track of status different components issues which we have seen with Linux + Windows hybrid Docker Swarm.

Note! I recommended to use [Semi-Annual Channel](https://docs.microsoft.com/en-us/windows-server/get-started/semi-annual-channel-overview) version of Windows Server as it contains many improvements which are missing from Windows Server 2016.
I also recommended you to avoid Hyper-V isolation mode as it have very poor performance.

## Usage:
Install GitHub Issue Link Status to your favorite browser so you can see status of these items directly on here:
- [**Chrome** extension](https://chrome.google.com/webstore/detail/github-issue-link-status/nbiddhncecgemgccalnoanpnenalmkic)
- [**Firefox** add-on](https://addons.mozilla.org/en-US/firefox/addon/github-issue-link-status/)

# Current configuration
## Components:
| Role           | OS             | OS version   | Docker version               |
| -------------- | -------------- | ------------ | ---------------------------- |
| Swarm manager  | Rancher OS     | v1.2.0       | 17.09.1-ce                   |
| Linux worker   | Rancher OS     | v1.2.0       | 17.09.1-ce                   |
| Windows worker | Windows Server | version 1806 | 17.06.2-ee-11                |

## Example of fully working stack

This [docker stack](https://docs.docker.com/engine/reference/commandline/stack_deploy/) is tested to be fully working on Linux + Windows hybrid swarm and connections between all the containers are working just fine.
**NOTE!** All the services are **endpoint_mode=dnsrr** that is trick to make connections working.
```
version: '3.3'

networks:
  test:
    driver: overlay

services:
  win1:
    image: microsoft/nanoserver:1803_KB4103721
    networks:
      - test
    deploy:
      endpoint_mode: dnsrr
      placement:
        constraints:
          - node.platform.os==windows
    command: ping -t 127.0.0.1
  win2:
    image: microsoft/nanoserver:1803_KB4103721
    networks:
      - test
    deploy:
      endpoint_mode: dnsrr
      placement:
        constraints:
          - node.platform.os==windows
    command: ping -t 127.0.0.1
  linux1:
    image: alpine:3.7
    networks:
      - test
    deploy:
      endpoint_mode: dnsrr
      placement:
        constraints:
          - node.platform.os==linux
    command: sh -c "ping 127.0.0.1"
  linux2:
    image: alpine:3.7
    networks:
      - test
    deploy:
      endpoint_mode: dnsrr
      placement:
        constraints:
          - node.platform.os==linux
    command: sh -c "ping 127.0.0.1"
```


# Known issues and workarounds
| OS      | Description                                                                 | Upstream item          | Workaround / solution                                                                   |
| ------- | --------------------------------------------------------------------------- | ---------------------- | --------------------------------------------------------------------------------------- |
| Linux   | docker service logs command stopped working | [moby/moby#35011](https://github.com/moby/moby/issues/35011) | Restart all Swarm managers one by one |
| Both    | Node reboot makes multiple copies of service running on same node | [moby/moby#26259](https://github.com/moby/moby/issues/26259) | Create service(s) on **--mode global** and use constraints to control which nodes containers will run |
| Both    | Cannot stop containers | [moby/moby#35933](https://github.com/moby/moby/issues/35933) | Do not update docker version above of 17.09.1-ce until this issue is fixed |
| Windows | Container cannot be started because old endpoint is stuck | [moby/moby#36603](https://github.com/moby/moby/pull/36603) | Update docker version to 17.06.2-ee-8 or above |
| Windows | Cannot change default NAT IP on Windows node | [docker/for-win#726](https://github.com/docker/for-win/issues/726) | Update dockerd.exe start command to contain --fixed-cidr **before** start it first time on new server |
| Windows | hcsshim::PrepareLayer timeouts on docker build phase | [moby/moby#27588](https://github.com/moby/moby/issues/27588) | Use Core version of Windows Server |
| Windows | Cannot start container because directory mount fails | [moby/moby#30556](https://github.com/moby/moby/issues/30556) | Make sure that folder is empty on docker image / Use Windows Server build 1803 or above |
| Both    | {{.Node.Hostname}} cannot be used on environment variables | [docker/swarmkit#](https://github.com/docker/swarmkit/issues/1951) | Update docker version to 17.10.0-ce or above / None as you cannot go over 17.09.1-ce because of [moby/moby#35933](https://github.com/moby/moby/issues/35933) |
| Windows | Networks stops working / containers fails to start | Multiple | Clear networks with [this](https://github.com/MicrosoftDocs/Virtualization-Documentation/tree/master/windows-server-container-tools/CleanupContainerHostNetworking) script and join node back to Swarm |
| Windows | Connections from Windows node to service(s) on Linux or another Windows node fails | [docker/for-win#1476](https://github.com/docker/for-win/issues/1476) | Use DNS routing mode ( *--endpoint-mode dnsrr* ) for all services (both Linux and Windows) where you want connect from Windows |
| Windows | Cannot docker inside of docker (needed example with [microsoft/vsts-agent](https://hub.docker.com/r/microsoft/vsts-agent/)) | [moby/moby#34795](https://github.com/moby/moby/issues/34795) | - |


