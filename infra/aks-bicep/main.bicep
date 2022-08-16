targetScope='subscription'

// resource group parameters
param rgName string = 'petclinicaks-rg'
param location string = 'eastus'

// vnet parameters
param vnetName string = 'vnet-aks'
param vnetPrefix string = '10.50.0.0/16'
param aksSubnetPrefix string = '10.50.1.0/24'
param ilbSubnetPrefix string = '10.50.2.0/24'
param bastionSubnetPrefix string = '10.50.3.0/24'
param fwSubnetPrefix string = '10.50.4.0/24'
param mgmtSubnetPrefix string = '10.50.5.0/24'

// bastion parameters
param bastionName string = 'aks-bastion'

// jumpbox parameters
param vmName string = 'aks-vm'
@secure()
param adminPassword string 

// fw parameters
param fwName string = 'aks-fw'
var applicationRuleCollections = [
  {
    name: 'aksFirewallRules'
    properties: {
      priority: 100
      action: {
        type: 'allow'
      }
      rules: [
        {
          name: 'aksFirewallRules'
          description: 'Rules needed for AKS to operate'
          sourceAddresses: [
            aksSubnetPrefix
          ]
          protocols: [
            {
              protocolType: 'Https'
              port: 443
            }
            {
              protocolType: 'Http'
              port: 80
            }
          ]
          targetFqdns: [
            //'*.hcp.${rg.location}.azmk8s.io'
            '*.hcp.eastus.azmk8s.io'
            'mcr.microsoft.com'
            '*.cdn.mcr.io'
            '*.data.mcr.microsoft.com'
            'management.azure.com'
            'login.microsoftonline.com'
            'dc.services.visualstudio.com'
            '*.ods.opinsights.azure.com'
            '*.oms.opinsights.azure.com'
            '*.monitoring.azure.com'
            'packages.microsoft.com'
            'acs-mirror.azureedge.net'
            'azure.archive.ubuntu.com'
            'security.ubuntu.com'
            'changelogs.ubuntu.com'
            'launchpad.net'
            'ppa.launchpad.net'
            'keyserver.ubuntu.com'
          ]
        }
      ]
    }
  }
]

var networkRuleCollections = [
  {
    name: 'ntpRule'
    properties: {
      priority: 100
      action: {
        type: 'allow'
      }
      rules: [
        {
          name: 'ntpRule'
          description: 'Allow Ubuntu NTP for AKS'
          protocols: [
            'UDP'
          ]
          sourceAddresses: [
            aksSubnetPrefix
          ]
          destinationAddresses: [
            '*'
          ]
          destinationPorts: [
            '123'
          ]
        }
      ]
    }
  }
]

// acr parameters
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'
param acrName string = 'petclinicaksacraz'


// create resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rgName
  location: location
}

module vnet 'modules/aks-vnet.bicep' = {
  name: vnetName
  scope: rg
  params: {
    location: location
    vnetName: vnetName
    vnetPrefix: vnetPrefix
    aksSubnetPrefix: aksSubnetPrefix
    ilbSubnetPrefix: ilbSubnetPrefix
    bastionSubnetPrefix: bastionSubnetPrefix
    fwSubnetPrefix: fwSubnetPrefix
    mgmtSubnetPrefix: mgmtSubnetPrefix
  }
}

module bastion 'modules/bastion.bicep' = {
  name: bastionName
  scope: rg
  params: {
    location: location
    bastionName: bastionName
    subnetId: vnet.outputs.bastionSubnetId
  }
}

module vm 'modules/jump-box.bicep' = {
  name: vmName
  scope: rg
  params:{
    location: location
    vmName: vmName
    subnetId: vnet.outputs.mgmtSubnetId
   adminPassword: adminPassword
  }
}

module fw 'modules/azfw.bicep' = {
  name: fwName
  scope: rg
  params: {
    location: location
    fwName: fwName
    fwSubnetId: vnet.outputs.fwSubnetId
    applicationRuleCollections: applicationRuleCollections
    networkRuleCollections: networkRuleCollections
  }
}

module acr 'modules/acr.bicep' = {
  name: acrName
  scope: rg
  params:{
    location: location
    acrName: acrName
    acrSku: acrSku
  }
}
