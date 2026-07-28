# Deploy the hub-and-spoke network

# 1. Create the resource group
az group create -n rg-hubspoke-lab -l uksouth

# 2. Deploy the Bicep template
az deployment group create \
  --resource-group rg-hubspoke-lab \
  --template-file main.bicep

# 3. Validate deployment
az network vnet list -g rg-hubspoke-lab -o table
az network firewall list -g rg-hubspoke-lab -o table
