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
module vm1Mod 'modules/vm.bicep' = {
  name: 'vm1Deploy'
  params: {
    name: 'vmVNet1'
    location: location
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', 'VNet1', 'infra')
  }
}

module vm2Mod 'modules/vm.bicep' = {
  name: 'vm2Deploy'
  params: {
    name: 'vmVNet2'
    location: location
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', 'VNet2', 'infra')
  }
}

// --- Storage Accounts ---
var storage1Name = 'stor1${uniqueString(resourceGroup().id)}'
var storage2Name = 'stor2${uniqueString(resourceGroup().id)}'

module storage1Mod 'modules/storage.bicep' = {
  name: 'storage1Deploy'
  params: {
    name: storage1Name
    location: location
  }
}

module storage2Mod 'modules/storage.bicep' = {
  name: 'storage2Deploy'
  params: {
    name: storage2Name
    location: location
  }
}

// --- Declare existing resources for diagnostics ---
resource vmVNet1 'Microsoft.Compute/virtualMachines@2021-07-01' existing = {
  name: 'vmVNet1'
}

resource vmVNet2 'Microsoft.Compute/virtualMachines@2021-07-01' existing = {
  name: 'vmVNet2'
}

resource stor1 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storage1Name
}

resource stor2 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storage2Name
}

// --- Diagnostic Settings for VM1 ---
resource vm1Diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vm1-ds'
  scope: vmVNet1
  properties: {
    workspaceId: monitor.outputs.workspaceId
    logs: [
      {
        category: 'GuestOS'
        enabled: true
        retentionPolicy: { enabled: false, days: 0 }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: { enabled: false, days: 0 }
      }
    ]
  }
}

// --- Diagnostic Settings for VM2 ---
resource vm2Diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vm2-ds'
  scope: vmVNet2
  properties: {
    workspaceId: monitor.outputs.workspaceId
    logs: [
      {
        category: 'GuestOS'
        enabled: true
        retentionPolicy: { enabled: false, days: 0 }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: { enabled: false, days: 0 }
      }
    ]
  }
}

// --- Diagnostic Settings for Storage1 ---
resource storage1Diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'stor1-ds'
  scope: stor1
  properties: {
    workspaceId: monitor.outputs.workspaceId
    logs: [
      {
        category: 'StorageBlobLogs'
        enabled: true
        retentionPolicy: { enabled: false, days: 0 }
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
        retentionPolicy: { enabled: false, days: 0 }
      }
    ]
  }
}

// --- Diagnostic Settings for Storage2 ---
resource storage2Diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'stor2-ds'
  scope: stor2
  properties: {
    workspaceId: monitor.outputs.workspaceId
    logs: [
      {
        category: 'StorageBlobLogs'
        enabled: true
        retentionPolicy: { enabled: false, days: 0 }
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
        retentionPolicy: { enabled: false, days: 0 }
      }
    ]
  }
}
