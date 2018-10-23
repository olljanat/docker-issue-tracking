# docker-issue-tracking
Keeping track of status different components issues which we have seen with Linux + Windows hybrid Docker Swarm.

**NOTE!** I recommended to use [Semi-Annual Channel](https://docs.microsoft.com/en-us/windows-server/get-started/semi-annual-channel-overview) version of Windows Server as it contains many improvements which are missing from Windows Server 2016.

I also recommended you to avoid Hyper-V isolation mode as it have very poor performance.

## Usage:
Install GitHub Issue Link Status to your favorite browser so you can see status of these items directly on here:
- [**Chrome** extension](https://chrome.google.com/webstore/detail/github-issue-link-status/nbiddhncecgemgccalnoanpnenalmkic)
- [**Firefox** add-on](https://addons.mozilla.org/en-US/firefox/addon/github-issue-link-status/)

# Current configuration
## Components:
| Role           | OS             | OS version   | Docker version               |
| -------------- | -------------- | ------------ | ---------------------------- |
| Swarm manager  | Rancher OS     | v1.4.2       | 18.03.1-ce                   |
| Linux worker   | Rancher OS     | v1.4.2       | 18.03.1-ce                   |
| Windows worker | Windows Server | version 1803 | 18.03.1-ee-3                 |

## Example of fully working stack

This [docker stack](https://docs.docker.com/engine/reference/commandline/stack_deploy/) is tested to be fully working on Linux + Windows hybrid swarm and connections between all the containers are working just fine.

~~NOTE! All the services are using **endpoint_mode=dnsrr** that is trick to make connections working.~~
Not needed anymore on 18.03.xx
```
version: '3.3'

networks:
  test:
    driver: overlay

services:
  win1:
    image: microsoft/nanoserver:1803
    networks:
      - test
    deploy:
      placement:
        constraints:
          - node.platform.os==windows
    command: ping -t 127.0.0.1
  win2:
    image: microsoft/nanoserver:1803
    networks:
      - test
    deploy:
      placement:
        constraints:
          - node.platform.os==windows
    command: ping -t 127.0.0.1
  linux1:
    image: alpine:3.7
    networks:
      - test
    deploy:
      placement:
        constraints:
          - node.platform.os==linux
    command: sh -c "ping 127.0.0.1"
  linux2:
    image: alpine:3.7
    networks:
      - test
    deploy:
      placement:
        constraints:
          - node.platform.os==linux
    command: sh -c "ping 127.0.0.1"
```


# Known issues and workarounds
| OS      | Description                                                                 | Upstream item          | Workaround / solution                                                                   |
| ------- | --------------------------------------------------------------------------- | ---------------------- | --------------------------------------------------------------------------------------- |
| Linux   | docker service logs command stopped working | [moby/moby#35011](https://github.com/moby/moby/issues/35011) | Restart all Swarm managers one by one |
| Windows | Cannot change default NAT IP on Windows node | [docker/for-win#726](https://github.com/docker/for-win/issues/726) | Update dockerd.exe start command to contain --fixed-cidr **before** start it first time on new server |
| Windows | hcsshim::PrepareLayer timeouts on docker build phase | [moby/moby#27588](https://github.com/moby/moby/issues/27588) | Use Core version of Windows Server |
| Windows | Cannot start container because directory mount fails | [moby/moby#30556](https://github.com/moby/moby/issues/30556) | Make sure that folder is empty on docker image / Use Windows Server build 1803 or above |
| Windows | Networks stops working / containers fails to start | Multiple | Clear networks with [this](https://github.com/MicrosoftDocs/Virtualization-Documentation/tree/master/windows-server-container-tools/CleanupContainerHostNetworking) script and join node back to Swarm |
| Windows | Date / time is wrong inside of container with Hyper-V isolation mode | [moby/moby#37283](https://github.com/moby/moby/issues/37283) | Use process isolation mode |
| Windows | Printer spooler crashes inside of container | [stackoverflow](https://stackoverflow.com/questions/41565459/windows-2016-docker-container-error/) | https://stackoverflow.com/a/50748146/9529640 |
| Windows | Cannot install all features to container because of they are [removed from image](https://docs.microsoft.com/en-us/windows-server/administration/server-core/server-core-container-removed-roles) | - | Copy needed packages from host machine C:\Windows\WinSxs and install using dism | 
| Windows | net use command fails inside of container | - | Install File-Services feature to host *and* to container |
| Both    | Two or more containers on the same overlay network can't communicate with each other | [How to recover from a split gossip cluster](https://success.docker.com/article/how-to-recover-from-split-gossip-cluster) or use at least version 18.06 | 


# Waiting for release
| OS      | Description                                                                 | Upstream item          | Target version |
| ------- | --------------------------------------------------------------------------- | ---------------------- | -------------- |
| Windows | Cannot connect to docker from inside of container (needed example with [microsoft/vsts-agent](https://hub.docker.com/r/microsoft/vsts-agent/)) | [moby/moby#34795](https://github.com/moby/moby/issues/34795) | 19.03 |
| Both    | Node reboot makes multiple copies of service running on same node | [moby/moby#26259](https://github.com/moby/moby/issues/26259) | 19.03 |


# Fixed issues
| OS      | Description                                                                 | Upstream item          | 
| ------- | --------------------------------------------------------------------------- | ---------------------- | 
| Both    | Cannot stop containers | [moby/moby#35933](https://github.com/moby/moby/issues/35933) |
| Windows | Container cannot be started because old endpoint is stuck | [moby/moby#36603](https://github.com/moby/moby/pull/36603) |
| Both    | {{.Node.Hostname}} cannot be used on environment variables | [docker/swarmkit#](https://github.com/docker/swarmkit/issues/1951) | 
| Windows | Connections from Windows node to service(s) on Linux or another Windows node fails | [docker/for-win#1476](https://github.com/docker/for-win/issues/1476) |