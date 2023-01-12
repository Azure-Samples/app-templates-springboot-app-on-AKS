targetScope='subscription'
//
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

// jumpbox parameters
param vmName string = 'aks-vm'
@secure()
param adminPassword string 

// aks parameters
param aksClusterName string = 'aks-cluster'
param k8sVersion string = '1.19.7'
param adminPublicKey string
param adminGroupObjectIDs array = []
@allowed([
  'Free'
  'Paid'
])
param aksSkuTier string = 'Free'
param aksVmSize string = 'Standard_D2s_v3'
param aksNodes int = 1

@allowed([
  'azure'
  'calico'
])
param aksNetworkPolicy string = 'calico'

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

module aks 'modules/aks-cluster.bicep' = {
  name: aksClusterName
  dependsOn: [
    fw
  ]
  scope: rg
  params: {    
    location: location
    aksClusterName: aksClusterName
    subnetId: vnet.outputs.aksSubnetId
    adminPublicKey: adminPublicKey

    aksSettings: {
      clusterName: aksClusterName
      identity: 'SystemAssigned'
      kubernetesVersion: k8sVersion
      networkPlugin: 'azure'
      networkPolicy: aksNetworkPolicy
      serviceCidr: '172.16.0.0/22' // can be reused in multiple clusters; no overlap with other IP ranges
      dnsServiceIP: '172.16.0.10'
      dockerBridgeCidr: '172.16.4.1/22'
      outboundType: 'loadBalancer'
      loadBalancerSku: 'standard'
      sku_tier: aksSkuTier			
      enableRBAC: true
      aadProfileManaged: true
      adminGroupObjectIDs: adminGroupObjectIDs 
    }

    defaultNodePool: {
      name: 'pool01'
      count: aksNodes
      vmSize: aksVmSize
      osDiskSizeGB: 50
      osDiskType: 'Ephemeral'
      vnetSubnetID: vnet.outputs.aksSubnetId
      osType: 'Linux'
      type: 'VirtualMachineScaleSets'
      mode: 'System'
    }    
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
//  Telemetry Deployment
@description('Enable usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = true
var telemetryId = '69ef933a-eff0-450b-8a46-331cf62e160f-javaaks-${location}'
resource telemetrydeployment 'Microsoft.Resources/deployments@2021-04-01' = if (enableTelemetry) {
  name: telemetryId
  location: location
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
      contentVersion: '1.0.0.0'
      resources: {}
    }
  }
}
