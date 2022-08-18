targetScope='subscription'

// resource group parameters
param rgName string = 'petclinicaks-rg'
param location string = 'eastus'

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

module acr 'modules/acr.bicep' = {
  name: acrName
  scope: rg
  params:{
    location: location
    acrName: acrName
    acrSku: acrSku
  }
}
