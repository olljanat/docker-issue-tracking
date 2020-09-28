# This script will export overlay network configuration from both Windows Host Networking Service (HNS)
# and Docker and generalize network, etc IDs from those which simplify comparization
#
# Note! Currently this script excepts that you have you have created only one service
# and that it uses only one overlay network

$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False

## Docker
$DockerNetworks = docker network inspect $(docker network ls --filter driver=overlay -q) | ConvertFrom-Json
if ($DockerNetworks.count -ne 2) {
    throw "Incorrect number of Docker overlay networks found"
}
forEach($n in $DockerNetworks) {
    $n.Created = '2020-01-01T00:00:00.0000000+03:00'
    $containerPropertyNames = ($n.Containers | Get-Member -MemberType NoteProperty).Name
    if ($containerPropertyNames.count -ne 2) {
        throw "Incorrect number of container properties found"
    }
    $global:containerID = $containerPropertyNames | Where-Object {$_ -notlike "*-*"}
    $lbName = $containerPropertyNames | Where-Object {$_ -ne $containerID}
    $n.Containers | Add-Member -Type NoteProperty -Name "0000000000000000000000000000000000000000000000000000000000000000" -Value $n.Containers.$containerID
    $n.Containers.PSObject.Properties.Remove($containerID)
    if ($n.Name -eq "ingress") {
        $global:IngressId = $n.Id
        $global:IngressName = $n.Name

        $global:IngressHnsID = $n.Options[0].'com.docker.network.windowsshim.hnsid'
        $n.Options[0].'com.docker.network.windowsshim.hnsid' = '00000000-0000-0000-0000-000000000000'

        $global:IngressEndpointID = $n.Containers.'0000000000000000000000000000000000000000000000000000000000000000'.Name = 'app'
        $global:IngressEndpointID = $n.Containers.'0000000000000000000000000000000000000000000000000000000000000000'.EndpointID
        $n.Containers.'0000000000000000000000000000000000000000000000000000000000000000'.EndpointID = '1111111111111111111111111111111111111111111111111111111111111111'
        $n.Containers.'0000000000000000000000000000000000000000000000000000000000000000'.MacAddress = '00:00:00:00:00:00'

        $global:IngressLbEndpointID = $n.Containers.$lbName.EndpointID
        $n.Containers.$lbName.EndpointID = '2222222222222222222222222222222222222222222222222222222222222222'
        $n.Containers.$lbName.MacAddress = '11:11:11:11:11:11'
    } else {
        $global:AppNetId = $n.Id
        $global:AppNetName = $n.Name

        $global:AppNetHnsID = $n.Options[0].'com.docker.network.windowsshim.hnsid'
        $n.Options[0].'com.docker.network.windowsshim.hnsid' = '10000000-0000-0000-0000-000000000000'

        $global:AppEndpointID = $n.Containers.'0000000000000000000000000000000000000000000000000000000000000000'.EndpointID
        $n.Containers.'0000000000000000000000000000000000000000000000000000000000000000'.Name = 'app'
        $n.Containers.'0000000000000000000000000000000000000000000000000000000000000000'.EndpointID = '3333333333333333333333333333333333333333333333333333333333333333'
        $n.Containers.'0000000000000000000000000000000000000000000000000000000000000000'.MacAddress = '22:22:22:22:22:22'

        $global:AppLbEndpointID = $n.Containers.$lbName.EndpointID
        $n.Containers.$lbName.EndpointID = '4444444444444444444444444444444444444444444444444444444444444444'
        $n.Containers.$lbName.MacAddress = '33:33:33:33:33:33'
    }
    $n.Id = $n.Name
    $n.Peers[0].Name = "node"
    $n.Peers[0].IP = "192.168.100.100"
}
$DockerNetworksJSON = $DockerNetworks | ConvertTo-Json -Depth 100
[System.IO.File]::WriteAllLines("$PSScriptRoot\DockerNetworks.json", $DockerNetworksJSON, $Utf8NoBomEncoding)

## HNS
Import-Module HostNetworkingService

# Networks
$HnsNetworks = Get-HnsNetwork | Where-Object {$_.Name -ne "nat"}
if ($HnsNetworks.count -ne 2) {
    throw "Incorrect number of HNS overlay networks found"
}

$HnsIngress = $HnsNetworks | Where-Object {$_.Name -eq $IngressId}
$HnsIngress.ActivityId = '00000000-0000-0000-0000-000000000001'
$HnsIngress.ID = '00000000-0000-0000-0000-000000000000'
$HnsIngress.Name = $IngressName

$HnsAppNet = $HnsNetworks | Where-Object {$_.Name -eq $AppNetId}
$HnsAppNet.ActivityId = '00000000-0000-0000-0000-000000000002'
$HnsAppNet.ID = '10000000-0000-0000-0000-000000000000'
$HnsAppNet.Name = $AppNetName

$HnsNetworksJSON = $HnsNetworks | ConvertTo-Json -Depth 100
[System.IO.File]::WriteAllLines("$PSScriptRoot\HnsNetworks.json", $HnsNetworksJSON, $Utf8NoBomEncoding)

# Endpoints
$HnsEndpoints = Get-HnsEndpoint | Where-Object {$_.Type -eq "overlay"}
if ($HnsEndpoints.count -ne 4) {
    throw "Incorrect number of HNS endpoints found"
}
$endpointMapping = @{}
$HnsIngressEndpoints = $HnsEndpoints | Where-Object {$_.VirtualNetworkName -eq $IngressId}
forEach($endpoint in $HnsIngressEndpoints) {
    $endpoint.ActivityId = '00000000-0000-0000-0000-000000000001'
    $endpoint.VirtualNetworkName = $IngressName
    $endpoint.Name = $IngressName
    if ($endpoint.SharedContainers -eq $containerID) {
        $endpoint.SharedContainers = @("0000000000000000000000000000000000000000000000000000000000000000")
        $endpointMapping[$endpoint.ID] = "00000000-0000-0000-0000-100000000000"
        $endpoint.ID = "00000000-0000-0000-0000-100000000000"
    } else {
        $endpointMapping[$endpoint.ID] = "00000000-0000-0000-0000-200000000000"
        $endpoint.ID = "00000000-0000-0000-0000-200000000000"
    }
    $endpoint.DNSServerList = "10.0.1.1,192.168.100.1"
    $endpoint.CreateProcessingStartTime = "000000000000000000"
    $endpoint.Health.LastUpdateTime = "000000000000000000"
}

$HnsAppNetEndpoints = $HnsEndpoints | Where-Object {$_.VirtualNetworkName -eq $AppNetId}
forEach($endpoint in $HnsAppNetEndpoints) {
    $endpoint.ActivityId = '00000000-0000-0000-0000-000000000002'
    $endpoint.VirtualNetworkName = $AppNetName
    $endpoint.Name = $AppNetName
    if ($endpoint.SharedContainers -eq $containerID) {
        $endpoint.SharedContainers = @("0000000000000000000000000000000000000000000000000000000000000000")
        $endpointMapping[$endpoint.ID] = "00000000-0000-0000-0000-300000000000"
        $endpoint.ID = "00000000-0000-0000-0000-300000000000"
    } else {
        $endpointMapping[$endpoint.ID] = "00000000-0000-0000-0000-400000000000"
        $endpoint.ID = "00000000-0000-0000-0000-400000000000"
    }
    $endpoint.DNSServerList = "10.0.1.1,192.168.100.1"
    $endpoint.CreateProcessingStartTime = "000000000000000000"
    $endpoint.Health.LastUpdateTime = "000000000000000000"
}

$HnsEndpointsSorted = $HnsEndpoints | Sort-Object ActivityId
$HnsEndpointsJSON = $HnsEndpointsSorted | ConvertTo-Json -Depth 100
[System.IO.File]::WriteAllLines("$PSScriptRoot\HnsEndpoints.json", $HnsEndpointsJSON, $Utf8NoBomEncoding)

# Policies / Load Balancers
$HnsPolicies = Get-HnsPolicyList
forEach($policy in $HnsPolicies) {
    $endpoint = $policy.References[0] -replace "/endpoints/",""
    $newEndpoint = $endpointMapping[$endpoint]
    if (-not ($newEndpoint)) {
        $newEndpoint = "INVALID ENDPOINT ID"
    }
    $policy.References = @($newEndpoint)
}
$HnsPoliciesSorted = $HnsPolicies | Sort-Object References
$HnsPoliciesJSON = $HnsPoliciesSorted | ConvertTo-Json -Depth 100
[System.IO.File]::WriteAllLines("$PSScriptRoot\HnsPolicies.json", $HnsPoliciesJSON, $Utf8NoBomEncoding)
