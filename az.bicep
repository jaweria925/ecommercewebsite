@description('Virtual network name')
param vnet_name string = 'Algo_App'

@description('Location for creating Resources')
param location string = 'australiasoutheast'

@description('Public subnet name')
param public_subnet_name string = 'Public_subnet01'

@description('Private subnet name')
param private_subnet_name string = 'Private_subnet01'

@description('bastion name')
param bastion_name string = 'AzureBastionSubnet'

var vnetAddressPrefix   = '10.0.0.0/16'
var publicSubnetPrefix  = '10.0.1.0/24'
var privateSubnetPrefix = '10.0.2.0/24'
var bastionSubnetPrefix = '10.0.3.0/27' // Required for Bastion

@description('The name of the storage account')
param storage_account_name string = 'algostorageacct2024'

// Virtual Network with subnets
resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: vnet_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: public_subnet_name
        properties: {
          addressPrefix: publicSubnetPrefix
          networkSecurityGroup: {
            id: public_Nsg.id
          }
        }
      }
      {
        name: private_subnet_name
        properties: {
          addressPrefix: privateSubnetPrefix
          networkSecurityGroup: {
            id: privateNsg.id
          }
        }
      }
    ]
  }
}

// Public NSG
resource public_Nsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: '${public_subnet_name}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-Internet-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Private NSG
resource privateNsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: '${private_subnet_name}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Deny-Internet-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Public IP for Bastion & NAT
resource az_public_ip 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: '${public_subnet_name}-pip'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// NAT Gateway
resource az_nat_gateway 'Microsoft.Network/natGateways@2024-07-01' = {
  name: '${public_subnet_name}-nat-gateway'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIpAddresses: [
      { id: az_public_ip.id }
    ]
  }
}

// Associate NAT Gateway with private subnet
resource privateSubnetWithNat 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  parent: vnet
  name: private_subnet_name
  properties: {
    addressPrefix: privateSubnetPrefix
    networkSecurityGroup: {
      id: privateNsg.id
    }
    natGateway: {
      id: az_nat_gateway.id
    }
  }
}
// createa Bastion Subnet
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  parent: vnet
  name: bastion_name
  properties: {
    addressPrefix: bastionSubnetPrefix
  }
}

// Bastion
resource bastion 'Microsoft.Network/bastionHosts@2024-07-01' = {
  name: '${vnet_name}-bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ip-config'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: az_public_ip.id
          }
        }
      }
    ]
  }
}

// create storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storage_account_name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    
  }
}

// Create a logAnalytics workspace

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'log-analytics-workspace'
  location: location
  properties: {
    retentionInDays: 30
  }
}




output storageId string = storageAccount.id
output storageName string = storage_account_name
output publicnsg_id string  = public_Nsg.id
output privatensg_id string = privateNsg.id
output vnet_id string       = vnet.id
output natgateway_id string = az_nat_gateway.id
output LogAnayticID string = logAnalytics.id

