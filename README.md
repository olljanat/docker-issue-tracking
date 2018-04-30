# docker-issue-tracking
Keeping track of status different components issues which we have seen with Linux + Windows hybrid Docker Swarm.

# Current configuration
## Components:
| Role           | OS             | OS version | Docker version |
| -------------- | -------------- | ---------- | -------------- |
| Swarm manager  | Rancher OS     | v1.2.0     | 17.09.1-ce     |
| Linux worker   | Rancher OS     | v1.2.0     | 17.09.1-ce     |
| Windows worker | Windows Server | 2016       | 17.06.2-ee-6   |


# Known issues and workaround
| Description                                                                 | Upstream item          | Workaround                                                                              |
| --------------------------------------------------------------------------- | ---------------------- | --------------------------------------------------------------------------------------- |
| docker service logs command stopped working                                 | @moby/moby#35011        | Restart all Swarm managers one by one                                                   |