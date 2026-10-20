# Quick Start: Azure Lighthouse in 5 Minutes

Get Azure Lighthouse delegation running in 5 minutes without reading all the documentation.

## Prerequisites

- Two Azure subscriptions in different tenants
- PowerShell 7.0+ or Azure CLI
- Owner/Admin access to both tenants

## Step 1: Get Your IDs (1 min)

**Managing Tenant (Service Provider):**
```powershell
Connect-AzAccount
Get-AzContext | Select-Object TenantId  # Copy this
Get-AzADUser -UserPrincipalName "your-email@yourcompany.com" | Select-Object Id  # Copy this
```

**Customer Tenant:**
```powershell
Connect-AzAccount -TenantId "<customer-tenant-id>"
Get-AzSubscription | Select-Object SubscriptionId, TenantId  # Copy subscription ID
```

## Step 2: Customize Template (1 min)

Edit `templates/delegationTemplate.json`:

```json
"managedByTenantId": "YOUR_TENANT_A_ID",  // From Step 1
"principalId": "YOUR_PRINCIPAL_ID",       // From Step 1
```

## Step 3: Deploy (1 min)

**Customer Tenant runs:**
```powershell
Connect-AzAccount -TenantId "<customer-tenant-id>"

# Register resource provider
Register-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"

# Deploy template
New-AzSubscriptionDeployment `
    -Name "LighthouseDemo" `
    -Location "eastus" `
    -TemplateFile "templates\delegationTemplate.json"
```

## Step 4: Verify (1 min)

**Managing Tenant runs:**
```powershell
Connect-AzAccount -TenantId "<managing-tenant-id>"

# See customer subscription
Get-AzSubscription

# Access customer resources
Select-AzSubscription -SubscriptionId "<customer-sub-id>"
Get-AzResource
```

## Step 5: See in Portal (1 min)

**Managing Tenant Portal:**
1. Search for "Azure Lighthouse"
2. Click "Customers"
3. See customer subscription listed

**Customer Tenant Portal:**
1. Search for "Service providers"
2. See delegation listed

## ✅ Done! 

You now have:
- ✅ Delegation active
- ✅ Managing tenant can see customer resources
- ✅ Customer can revoke anytime

## Next Steps

- Read [SETUP.md](SETUP.md) for all 16 detailed steps
- Try [examples](../examples/) for policy, security, costs
- See [demo-playbooks](../demo-playbooks/) for presentations

## Troubleshooting

**Can't see customer subscription?**
- Ensure you're in the managing tenant
- Run `Get-AzSubscription` to list all

**Deployment failed?**
- Check template IDs are correct
- Verify customer tenant has resource provider registered

**Still stuck?**
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Review full [SETUP.md](SETUP.md)
