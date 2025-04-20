targetScope = 'resourceGroup'

// Deploy VNet1
module vnet1 'modules/vnet.bicep' = {
  name: 'vnet1Deployment'
  params: {
    name: 'VNet1'
    location: resourceGroup().location
    subnets: [
      {
        name: 'infra'
        prefix: '10.0.1.0/24'
      }
      {
        name: 'storage'
        prefix: '10.0.2.0/24'
      }
    ]
  }
}

// Deploy VNet2
module vnet2 'modules/vnet.bicep' = {
  name: 'vnet2Deployment'
  params: {
    name: 'VNet2'
    location: resourceGroup().location
    subnets: [
      {
        name: 'vm'
        prefix: '10.1.0.0/24'
      }
    ]
  }
}

// Peering between VNet1 and VNet2
resource vnet1ToVnet2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = {
  name: 'VNet1-to-VNet2'
  parent: vnet1.outputs.vnet
  properties: {
    remoteVirtualNetwork: {
      id: vnet2.outputs.vnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource vnet2ToVnet1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = {
  name: 'VNet2-to-VNet1'
  parent: vnet2.outputs.vnet
  properties: {
    remoteVirtualNetwork: {
      id: vnet1.outputs.vnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Deploy Storage Account in VNet1
module storage 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: 'uniquestorage12345'
    location: resourceGroup().location
    vnetName: 'VNet1'
    subnetName: 'storage'
  }
}

// Deploy VM in VNet2
module vm 'modules/vm.bicep' = {
  name: 'vmDeployment'
  params: {
    vmName: 'myVM'
    location: resourceGroup().location
    vnetName: 'VNet2'
    subnetName: 'vm'
  }
}

// Monitoring & Diagnostics
module monitor 'modules/monitor.bicep' = {
  name: 'monitorDeployment'
  params: {
    location: resourceGroup().location
  }
}
