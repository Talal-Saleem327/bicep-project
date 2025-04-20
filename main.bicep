targetScope = 'resourceGroup'

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
