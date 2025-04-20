targetScope = 'resourceGroup'

param location string = resourceGroup().location

// --- VNET 1 ---
module vnet1 'modules/vnet.bicep' = {
  name: 'vnet1Deploy'
  params: {
    name: 'VNet1'
    location: location
    addressPrefix: '10.0.0.0/16'
    subnets: [
      { name: 'infra', prefix: '10.0.1.0/24' }
      { name: 'storage', prefix: '10.0.2.0/24' }
    ]
  }
}

// --- VNET 2 ---
module vnet2 'modules/vnet.bicep' = {
  name: 'vnet2Deploy'
  params: {
    name: 'VNet2'
    location: location
    addressPrefix: '10.1.0.0/16'
    subnets: [
      { name: 'infra', prefix: '10.1.1.0/24' }
      { name: 'storage', prefix: '10.1.2.0/24' }
    ]
  }
}

// --- VNet Peering ---
module peer 'modules/vnet-peering.bicep' = {
  name: 'vnetPeering'
  params: {
    vnet1Name: 'VNet1'
    vnet2Name: 'VNet2'
  }
}

// --- Log Analytics Workspace ---
module monitor 'modules/monitor.bicep' = {
  name: 'monitorDeploy'
  params: {
    name: 'biceplogs${uniqueString(resourceGroup().id)}'
    location: location
  }
}

// --- VMs ---
module vm1 'modules/vm.bicep' = {
  name: 'vm1Deploy'
  params: {
    name: 'vmVNet1'
    location: location
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', 'VNet1', 'infra')
  }
}

module vm2 'modules/vm.bicep' = {
  name: 'vm2Deploy'
  params: {
    name: 'vmVNet2'
    location: location
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', 'VNet2', 'infra')
  }
}

// --- Storage Accounts ---
var storage1Name = 'storvnet1${uniqueString('prefix1${resourceGroup().id}')}'
var storage2Name = 'storvnet2${uniqueString('prefix2${resourceGroup().id}')}'

module storage1 'modules/storage.bicep' = {
  name: 'storage1Deploy'
  params: {
    name: storage1Name
    location: location
  }
}

module storage2 'modules/storage.bicep' = {
  name: 'storage2Deploy'
  params: {
    name: storage2Name
    location: location
  }
}

// --- Diagnostic Settings ---
module vm1Diag 'modules/diagnostic.bicep' = {
  name: 'diag-vm1'
  params: {
    name: 'vm1-ds'
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines', 'vmVNet1')
    logAnalyticsWorkspaceId: monitor.outputs.workspaceId
  }
}

module vm2Diag 'modules/diagnostic.bicep' = {
  name: 'diag-vm2'
  params: {
    name: 'vm2-ds'
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines', 'vmVNet2')
    logAnalyticsWorkspaceId: monitor.outputs.workspaceId
  }
}

module storage1Diag 'modules/diagnostic.bicep' = {
  name: 'diag-storage1'
  params: {
    name: 'stor1-ds'
    targetResourceId: resourceId('Microsoft.Storage/storageAccounts', storage1Name)
    logAnalyticsWorkspaceId: monitor.outputs.workspaceId
  }
}

module storage2Diag 'modules/diagnostic.bicep' = {
  name: 'diag-storage2'
  params: {
    name: 'stor2-ds'
    targetResourceId: resourceId('Microsoft.Storage/storageAccounts', storage2Name)
    logAnalyticsWorkspaceId: monitor.outputs.workspaceId
  }
}
