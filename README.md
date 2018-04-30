# docker-issue-tracking
Keeping track of status different components issues which we have seen with Linux + Windows hybrid Docker Swarm.

## Usage:
Install GitHub Issue Link Status to your favorite browser so you can see status of these items directly on here:
- [**Chrome** extension](https://chrome.google.com/webstore/detail/github-issue-link-status/nbiddhncecgemgccalnoanpnenalmkic)
- [**Firefox** add-on](https://addons.mozilla.org/en-US/firefox/addon/github-issue-link-status/)

# Current configuration
## Components:
| Role           | OS             | OS version | Docker version               |
| -------------- | -------------- | ---------- | ---------------------------- |
| Swarm manager  | Rancher OS     | v1.2.0     | 17.09.1-ce                   |
| Linux worker   | Rancher OS     | v1.2.0     | 17.09.1-ce                   |
| Windows worker | Windows Server | 2016       | 17.06.2-ee-6 / 17.06.2-ee-7  |


# Known issues and workarounds
| Description                                                                 | Upstream item          | Workaround / solution                                                                   |
| --------------------------------------------------------------------------- | ---------------------- | --------------------------------------------------------------------------------------- |
| docker service logs command stopped working | [moby/moby#35011](https://github.com/moby/moby/issues/35011) | Restart all Swarm managers one by one |
| Node reboot makes multiple copies of service running on same node | [moby/moby#26259](https://github.com/moby/moby/issues/26259) | Create service(s) on **--mode global** and use constraints to control which nodes containers will run |
| Cannot stop containers | [moby/moby#35933](https://github.com/moby/moby/issues/35933) | Do not updated docker version above of 17.09.1-ce until this issue is fixed |
| Windows container cannot be started because old endpoint is stuck | [moby/moby#36603](https://github.com/moby/moby/pull/36603) | Update docker version to 17.06.2-ee-8 or above |
| Cannot change default NAT IP on Windows node | [docker/for-win#726](https://github.com/docker/for-win/issues/726) | Update dockerd.exe start command to contain --fixed-cidr **before** start it first time on new server |
| hcsshim::PrepareLayer timeouts on docker build phase | [moby/moby#27588](https://github.com/moby/moby/issues/27588) | Use Core version of Windows Server |
