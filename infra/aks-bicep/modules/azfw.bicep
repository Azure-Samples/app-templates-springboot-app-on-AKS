param fwName string
param fwSubnetId string
param applicationRuleCollections array
param networkRuleCollections array
param location string = 'eastus'

resource fw_ip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: '${fwName}-ip'
  location: location
  sku:{
    name: 'Standard'
  }
  properties:{
    publicIPAllocationMethod:'Static'
    publicIPAddressVersion:'IPv4'
  }
}

resource fw 'Microsoft.Network/azureFirewalls@2020-11-01' = {
  name: fwName
  location: location
  properties:{
    sku:{
      tier:'Standard'
    }
    ipConfigurations:[
      {
        name: 'ipConfig1'
        properties:{
          publicIPAddress:{
            id: fw_ip.id
          }
          subnet:{
            id: fwSubnetId
          }
        }
      }
    ]
    applicationRuleCollections: applicationRuleCollections
    networkRuleCollections: networkRuleCollections
    
  }
}
