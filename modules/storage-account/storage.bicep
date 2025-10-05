
@description('The name of the storage account')
param storage_account_name string = 'algostorageacct2024'
param location string = 'australiasoutheast'


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


output storageId string = storageAccount.id
output storageName string = storage_account_name
