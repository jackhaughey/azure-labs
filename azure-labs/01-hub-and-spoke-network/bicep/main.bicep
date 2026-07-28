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
      // -----------------------------
      // GatewaySubnet (required for VPN Gateway)
      // -----------------------------
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
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
// VPN Gateway Public IP
// -----------------------------
resource pipVpn 'Microsoft.Network/publicIPAddresses@2025‑07‑01' = {
  name: 'pip-vpn-hub'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// -----------------------------
// VPN Gateway (Route-Based)
// -----------------------------
resource vpnGw 'Microsoft.Network/virtualNetworkGateways@2025‑07‑01' = {
  name: 'vpngw-hub'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'gw-ipconfig'
        properties: {
          subnet: {
            id: vnetHub.properties.subnets[2].id // GatewaySubnet
          }
          publicIPAddress: {
            id: pipVpn.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
  }
}

// -----------------------------
// Local Network Gateway (Simulated On-Prem)
// -----------------------------
resource lng 'Microsoft.Network/localNetworkGateways@2025‑07‑01' = {
  name: 'lng-onprem'
  location: location
  properties: {
    gatewayIpAddress: '52.52.52.52' // fake on-prem public IP
    localNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.0.0/24' // fake on-prem LAN
      ]
    }
  }
}

// -----------------------------
// VPN Connection (IPsec)
// -----------------------------
resource vpnConnection 'Microsoft.Network/connections@2025‑07‑01' = {
  name: 'hub-to-onprem'
  location: location
  properties: {
    connectionType: 'IPsec'
    virtualNetworkGateway1: {
      id: vpnGw.id
    }
    localNetworkGateway2: {
      id: lng.id
    }
    sharedKey: 'MySecretKey123'
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
    allowGatewayTransit: true // IMPORTANT for VPN Gateway usage
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
    useRemoteGateways: true // IMPORTANT for VPN Gateway usage
  }
}