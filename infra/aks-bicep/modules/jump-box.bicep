param vmName string
@secure()
param adminPassword string 
param adminUsername string = 'azureuser'
param subnetId string
param location string = 'eastus'
param cloudInit string = '''
#cloud-config

packages:
 - build-essential
 - procps
 - file
 - linuxbrew-wrapper
 - docker.io

runcmd:
 - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
 - az aks install-cli
 - systemctl start docker
 - systemctl enable docker
 
final_message: "cloud init was here"

'''

resource nic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: '${vmName}-nic'
  location: location
  properties:{
    ipConfigurations:[
      {
        name: 'ipConfig'
        properties:{
          subnet:{
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}



resource jumpbox 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile:{
      vmSize: 'Standard_B1ms'
    }
    storageProfile:{
      imageReference:{
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk:{
        createOption: 'FromImage'
        managedDisk:{
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration:{
        disablePasswordAuthentication: false
      }
      customData: base64(cloudInit)
    }
    networkProfile:{
      networkInterfaces:[
        {
          id: nic.id
          properties:{
            primary: true
          }
        }
      ]
    }
  }
}

