// ------------------------------------------------------------
// 04-vmss-autoscaling
// VM Scale Set + Load Balancer + Autoscale Rules
// ------------------------------------------------------------

param location string = resourceGroup().location
param vmssName string = 'vmss-web'
param adminUsername string = 'azureuser'
@secure() // Marks the parameter as secure
param adminPassword string

// ------------------------------------------------------------
// Virtual Network
// ------------------------------------------------------------
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-vmss'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'vmss-subnet'
        properties: {
          addressPrefix: '10.20.1.0/24'
        }
      }
    ]
  }
}

var vmssSubnetId = vnet.properties.subnets[0].id

// ------------------------------------------------------------
// Public IP for Load Balancer
// ------------------------------------------------------------
resource pipLb 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'pip-lb'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// ------------------------------------------------------------
// Load Balancer
// ------------------------------------------------------------
resource lb 'Microsoft.Network/loadBalancers@2023-05-01' = {
  name: 'lb-web'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'feip'
        properties: {
          publicIPAddress: {
            id: pipLb.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'bepool'
      }
    ]
    probes: [
      {
        name: 'tcp-probe'
        properties: {
          protocol: 'Tcp'
          port: 80
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'http-rule'
        properties: {
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          frontendIPConfiguration: {
            id: lb.properties.frontendIPConfigurations[0].id
          }
          backendAddressPool: {
            id: lb.properties.backendAddressPools[0].id
          }
          probe: {
            id: lb.properties.probes[0].id
          }
        }
      }
    ]
  }
}

var backendPoolId = lb.properties.backendAddressPools[0].id

// ------------------------------------------------------------
// VM Scale Set
// ------------------------------------------------------------
resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
  name: vmssName
  location: location
  sku: {
    name: 'Standard_B2s'
    capacity: 2
  }
  properties: {
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: '0001-com-ubuntu-server-jammy'
          sku: '22_04-lts'
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: 'vmss'
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nicconfig'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: vmssSubnetId
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: backendPoolId
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}

// ------------------------------------------------------------
// Autoscale Settings
// ------------------------------------------------------------
resource autoscale 'Microsoft.Insights/autoscaleSettings@2022-10-01' = {
  name: 'autoscale-vmss'
  location: location
  properties: {
    name: 'autoscale-vmss'
    targetResourceUri: vmss.id
    enabled: true
    profiles: [
      {
        name: 'cpu-autoscale'
        capacity: {
          minimum: '1'
          maximum: '5'
          default: '2'
        }
        rules: [
          // Scale Out Rule
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: 'microsoft.compute/virtualmachines'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          // Scale In Rule
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: 'microsoft.compute/virtualmachines'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}

// ------------------------------------------------------------
// Outputs
// ------------------------------------------------------------
output vmssId string = vmss.id
output loadBalancerPublicIp string = pipLb.properties.ipAddress
output backendPool string = backendPoolId
