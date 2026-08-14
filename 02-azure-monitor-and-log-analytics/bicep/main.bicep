// ============================================================================
// SECTION 1: Parameters
// Description: User‑configurable inputs for workspace, retention, solutions, etc.
// ============================================================================

@description('Name of the Log Analytics Workspace')
param workspaceName string = 'law-analytics'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Retention period in days')
param retentionInDays int = 30

@description('Enable public network access for ingestion/query')
param publicNetworkAccess string = 'Enabled' // Allowed values: Enabled | Disabled

@description('Solutions to deploy into the workspace')
param solutions array = [
  'VMInsights'
  'ContainerInsights'
]

@description('Deploy a Data Collection Rule for VM Insights')
param deployVmDcr bool = true


// ============================================================================
// SECTION 2: Log Analytics Workspace
// Description: Workspace used by Azure Monitor.
// ============================================================================

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  sku: {
    name: 'PerGB2018'
  }
  properties: {
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: publicNetworkAccess
    publicNetworkAccessForQuery: publicNetworkAccess
  }
}


// ============================================================================
// SECTION 3: Monitoring Solutions
// Description: Deploys optional solutions such as VMInsights or ContainerInsights.
// ============================================================================

resource workspaceSolutions 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = [
  for solution in solutions: {
    name: '${solution}(${workspaceName})'
    location: location
    properties: {
      workspaceResourceId: logAnalytics.id
    }
    plan: {
      name: solution
      publisher: 'Microsoft'
      product: solution
    }
  }
]


// ============================================================================
// SECTION 4: Data Collection Rule (VM Insights)
// Description: Optional Data Collection Rules for gathering VM performance counters.
// ============================================================================

resource vmDcr 'Microsoft.Insights/dataCollectionRules@2022-06-01' = if (deployVmDcr) {
  name: '${workspaceName}-vm-dcr'
  location: location
  properties: {
    dataSources: {
      performanceCounters: [
        {
          name: 'vm-default-counters'
          streams: [
            'Microsoft-Perf'
          ]
          counterSpecifiers: [
            '\\Processor(_Total)\\% Processor Time'
            '\\Memory\\Available MBytes'
            '\\LogicalDisk(_Total)\\% Free Space'
          ]
          samplingFrequencyInSeconds: 60
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceId: logAnalytics.id
          name: 'law-destination'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Perf'
        ]
        destinations: [
          'law-destination'
        ]
      }
    ]
  }
}


// ============================================================================
// SECTION 5: Outputs
// Description: Useful identifiers for downstream deployments or scripts.
// ============================================================================

output workspaceId string = logAnalytics.id
output workspaceNameOut string = logAnalytics.name
output workspaceCustomerId string = logAnalytics.properties.customerId