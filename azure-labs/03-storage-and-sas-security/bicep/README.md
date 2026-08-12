# Deployment of storage lab

```
az group create -n rg-storage-sas-lab -l uksouth
```
```
az deployment group create \
  --resource-group rg-storage-sas-lab \
  --template-file main.bicep
```

# Details

1. Secure Storage Account

    - No public blob access

    - TLS 1.2 enforced

    - HTTPS only

    - Shared key access allowed (needed for SAS generation)

    - Network ACL default deny

2. Blob Container

   -  Private

    - No anonymous access

3. Private Endpoint

    - Connects Blob service to your hub VNet

    - Uses your existing shared-services-subnet

    - Ensures all blob access stays inside your virtual network

4. SAS Token Generation

Uses the ARM function:
```
listServiceSas()
```
