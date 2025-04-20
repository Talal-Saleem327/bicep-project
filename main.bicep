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
module storage1 'modules/storage.bicep' = {
  name: 'storage1Deploy'
  params: {
    name: 'storvnet1${uniqueString('prefix1${resourceGroup().id}')}' 
    location: location
  }
}

module storage2 'modules/storage.bicep' = {
  name: 'storage2Deploy'
  params: {
    name: 'storvnet2${uniqueString('prefix2${resourceGroup().id}')}' 
    location: location
  }
}

// --- Existing resource references for diagnostics ---
resource vm1res 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: 'vmVNet1'
}

resource vm2res 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: 'vmVNet2'
}

resource stor1res 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storage1.params.name
}

resource stor2res 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storage2.params.name
}

// --- Diagnostic Settings ---
module vm1Diag 'modules/diagnostic.bicep' = {
  name: 'diag-vm1'
  scope: vm1res
  params: {
    name: 'vm1-ds'
    logAnalyticsWorkspaceId: monitor.outputs.workspaceId
  }
}

module vm2Diag 'modules/diagnostic.bicep' = {
  name: 'diag-vm2'
  scope: vm2res
  params: {
    name: 'vm2-ds'
    logAnalyticsWorkspaceId: monitor.outputs.workspaceId
  }
}

module storage1Diag 'modules/diagnostic.bicep' = {
  name: 'diag-storage1'
  scope: stor1res
  params: {
    name: 'stor1-ds'
    logAnalyticsWorkspaceId: monitor.outputs.workspaceId
  }
}

module storage2Diag 'modules/diagnostic.bicep' = {
  name: 'diag-storage2'
  scope: stor2res
  params: {
    name: 'stor2-ds'
    logAnalyticsWorkspaceId: monitor.outputs.workspaceId
  }
}
