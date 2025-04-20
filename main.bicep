targetScope = 'resourceGroup'

param location string = resourceGroup().location

// Create first virtual network with two subnets
module vnet1 'modules/vnet.bicep' = {
  name: 'vnet1Deploy'
  params: {
    name: 'VNet1'
    location: location
    addressPrefix: '10.0.0.0/16'
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


// Create second virtual network with one subnet
module vnet2 'modules/vnet.bicep' = {
  name: 'vnet2Deploy'
  params: {
    name: 'VNet2'
    location: location
    addressPrefix: '10.1.0.0/16'
    subnets: [
      {
        name: 'web'
        prefix: '10.1.0.0/24'
      }
    ]
  }
}


// Storage Account
module storage 'modules/storage.bicep' = {
  name: 'storageDeploy'
  params: {
    name: 'bistorage${uniqueString(resourceGroup().id)}'
    location: location
  }
}

// Log Analytics Workspace
module monitor 'modules/monitor.bicep' = {
  name: 'monitorDeploy'
  params: {
    name: 'biceplogs${uniqueString(resourceGroup().id)}'
    location: location
  }
}

// VM in subnet of VNet1
module vm 'modules/vm.bicep' = {
  name: 'vmDeploy'
  params: {
    name: 'bicepVM'
    location: location
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', 'VNet1', 'infra')
  }
}
