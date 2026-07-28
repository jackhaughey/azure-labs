// -----------------------------
// Resource Group is created, then applying this bicep file into it
// > azure-labs/01-hub-and-spoke-network/bicep/README.md
// -----------------------------
param location string = resourceGroup().location

// -----------------------------
// Hub VNet
// -----------------------------
resource vnetHub 'Microsoft.Network/virtualNetworks@2025‑07‑01' = {
  name: 'vnet-hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'shared-services-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

// -----------------------------
// Spoke VNet
// -----------------------------
resource vnetSpoke 'Microsoft.Network/virtualNetworks@2025‑07‑01' = {
  name: 'vnet-spoke-web'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'web-subnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
    ]
  }
}

// -----------------------------
// Azure Firewall
// -----------------------------
resource pipFirewall 'Microsoft.Network/publicIPAddresses@2025‑07‑01' = {
  name: 'pip-azfw-hub'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2025‑07‑01' = {
  name: 'azfw-hub'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'fw-ipconfig'
        properties: {
          subnet: {
            id: vnetHub.properties.subnets[0].id
          }
          publicIPAddress: {
            id: pipFirewall.id
          }
        }
      }
    ]
  }
}

// -----------------------------
// Route table for spoke
// -----------------------------
resource rtSpoke 'Microsoft.Network/routeTables@2025‑07‑01' = {
  name: 'rt-web-spoke'
  location: location
  properties: {
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

// Associate route table with spoke subnet
resource rtAssoc 'Microsoft.Network/virtualNetworks/subnets/routeTables@2025‑07‑01' = {
  name: 'vnet-spoke-web/web-subnet/rt-web-spoke'
  parent: vnetSpoke
  properties: {
    routeTable: {
      id: rtSpoke.id
    }
  }
}

// -----------------------------
// NSG for spoke subnet
// -----------------------------
resource nsgSpoke 'Microsoft.Network/networkSecurityGroups@2025‑07‑01' = {
  name: 'nsg-web-subnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nsgAssoc 'Microsoft.Network/virtualNetworks/subnets/networkSecurityGroups@2025‑07‑01' = {
  name: 'vnet-spoke-web/web-subnet/nsg-web-subnet'
  parent: vnetSpoke
  properties: {
    id: nsgSpoke.id
  }
}

// -----------------------------
// VNet Peering (Hub → Spoke)
// -----------------------------
resource hubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025‑07‑01' = {
  name: 'vnet-hub/peer-hub-to-spoke'
  parent: vnetHub
  properties: {
    remoteVirtualNetwork: {
      id: vnetSpoke.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
  }
}

// -----------------------------
// VNet Peering (Spoke → Hub)
// -----------------------------
resource spokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025‑07‑01' = {
  name: 'vnet-spoke-web/peer-spoke-to-hub'
  parent: vnetSpoke
  properties: {
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
    allowVirtualNetworkAccess: true
  }
}
