param bastionName string
param subnetId string
param location string = 'eastus'

resource bastionIP 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: 'ip-${bastionName}'
  location: location
  properties:{
    publicIPAllocationMethod: 'Static'
  }
  sku:{
    name: 'Standard'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2020-11-01' = {
  name: bastionName
  location: location
  properties: {
   ipConfigurations: [
     {
        name: 'ipconfig1'
        properties:{
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: bastionIP.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }      
     }
   ] 
  }
}
