// ------------------------------------------------------------
// 03-storage-and-sas-security
// Secure storage account + SAS token generation
// ------------------------------------------------------------

param location string = resourceGroup().location
param storageAccountName string = 'st${uniqueString(resourceGroup().id)}'

// ------------------------------------------------------------
// Storage Account (secure defaults)
// ------------------------------------------------------------
resource stg 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: []
      ipRules: []
    }
    supportsHttpsTrafficOnly: true
  }
}

// ------------------------------------------------------------
// Blob Container
// ------------------------------------------------------------
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: '${stg.name}/default/appdata'
  properties: {
    publicAccess: 'None'
  }
}

// ------------------------------------------------------------
// Private Endpoint for Blob
// ------------------------------------------------------------
resource peBlob 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-blob-${stg.name}'
  location: location
  properties: {
    subnet: {
      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/shared-services-subnet'
    }
    privateLinkServiceConnections: [
      {
        name: 'blob-connection'
        properties: {
          privateLinkServiceId: stg.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

// ------------------------------------------------------------
// SAS Token Generation (Service SAS)
// ------------------------------------------------------------
var sasParams = {
  canonicalizedResource: '/blob/${stg.name}/appdata'
  signedResource: 'c' // container
  signedPermission: 'rwdl' // read, write, delete, list
  signedProtocol: 'https'
  signedExpiry: dateTimeAdd(utcNow(), 'P1D') // 1 day expiry
}

output serviceSasToken string = stg.listServiceSas(sasParams).serviceSasToken

// ------------------------------------------------------------
// Useful Outputs
// ------------------------------------------------------------
output storageAccountId string = stg.id
output blobEndpoint string = stg.properties.primaryEndpoints.blob
output containerName string = container.name
