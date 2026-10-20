# Azure Lighthouse Templates

## delegationTemplate.json

Main ARM template for delegating customer subscription to managing tenant.

### Prerequisites

Before using this template, gather:

1. **Managing Tenant ID** (Tenant A)
   ```powershell
   Connect-AzAccount
   Get-AzContext | Select-Object TenantId
   ```

2. **Principal ID** (User/Group/Service Principal in managing tenant)
   ```powershell
   Get-AzADUser -UserPrincipalName "user@yourtenant.onmicrosoft.com" | Select-Object Id
   # OR
   Get-AzADGroup -DisplayName "GroupName" | Select-Object Id
   # OR
   Get-AzADServicePrincipal -DisplayName "SPName" | Select-Object Id
   ```

3. **Customer Subscription ID** (Tenant B)
   ```powershell
   Connect-AzAccount -TenantId "<customer-tenant-id>"
   Get-AzSubscription | Select-Object SubscriptionId
   ```

### Customization

Edit the `variables` section in `delegationTemplate.json`:

```json
"managedByTenantId": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
"authorizations": [
    {
        "principalId": "11111111-2222-3333-4444-555555555555",
        "principalIdDisplayName": "Admin Name",
        "roleDefinitionId": "b24988ac-6180-42a0-ab88-20f7382dd24c"  // Contributor
    }
]
```

### Multiple Authorizations

To grant access to multiple users/groups with different roles:

```json
"authorizations": [
    {
        "principalId": "user-principal-id",
        "principalIdDisplayName": "Admin User",
        "roleDefinitionId": "b24988ac-6180-42a0-ab88-20f7382dd24c"  // Contributor
    },
    {
        "principalId": "group-principal-id",
        "principalIdDisplayName": "Operators Group",
        "roleDefinitionId": "36243c78-bf99-498c-9df9-86d9f8d28608"  // Resource Policy Contributor
    },
    {
        "principalId": "sp-principal-id",
        "principalIdDisplayName": "Automation Service Principal",
        "roleDefinitionId": "91c1777a-f3dc-4fae-b103-61d183457e46"  // Managed Services Registration Assignment Delete
    }
]
```

### Common Role Definition IDs

| Role | ID | Use Case |
|------|----|---------| 
| Contributor | `b24988ac-6180-42a0-ab88-20f7382dd24c` | General management, deployments |
| Reader | `acdd72a7-3385-48ef-bd42-f606fba81ae7` | Read-only access |
| Resource Policy Contributor | `36243c78-bf99-498c-9df9-86d9f8d28608` | Policy management |
| Managed Services Registration Assignment Delete | `91c1777a-f3dc-4fae-b103-61d183457e46` | Remove delegation |
| User Access Administrator | `18d7d88d-d35e-4fb5-a5c3-7773c20a72d9` | Assign roles to managed identities |
| Cost Management Contributor | `b24988ac-6180-42a0-ab88-20f7382dd24c` | Cost analysis |

### Deployment

**Customer Tenant (who owns the subscription being delegated):**

```powershell
# 1. Sign in to customer tenant
Connect-AzAccount -TenantId "<CUSTOMER_TENANT_ID>"

# 2. Register resource provider
Register-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"

# 3. Deploy template
New-AzSubscriptionDeployment `
    -Name "LighthouseOnboarding" `
    -Location "eastus" `
    -TemplateFile "delegationTemplate.json" `
    -TemplateParameterFile "delegationTemplate.parameters.json" `
    -Verbose

# 4. Verify deployment
Get-AzSubscriptionDeployment -Name "LighthouseOnboarding"
Get-AzManagedServicesAssignment -Scope "/subscriptions/<SUBSCRIPTION_ID>"
```

### Verification

**Managing Tenant (service provider):**

```powershell
# 1. Sign in to managing tenant
Connect-AzAccount -TenantId "<MANAGING_TENANT_ID>"

# 2. List delegated subscriptions
Get-AzSubscription

# 3. Select customer subscription
Select-AzSubscription -SubscriptionId "<CUSTOMER_SUBSCRIPTION_ID>"

# 4. See resources
Get-AzResource

# 5. List role assignments
Get-AzRoleAssignment -Scope "/subscriptions/<CUSTOMER_SUBSCRIPTION_ID>"
```

### Troubleshooting

**Deployment fails: "Resource provider not registered"**
```powershell
Register-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"
Get-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices" | Select-Object ProviderNamespace, RegistrationState
```

**Deployment fails: "Invalid principal ID"**
- Verify principal ID exists in managing tenant
- Ensure principal ID is in correct format (GUID)

**Can't see customer subscription after deployment**
- Ensure you're in managing tenant
- Wait a few minutes for replication
- Clear PowerShell cache: `Get-AzSubscription -Force`

### Removal

To remove delegation, see [scripts/remove-delegation.ps1](../scripts/remove-delegation.ps1)

---

## Customization Examples

### Template for Multiple Roles

See [examples/policy-enforcement/](../examples/policy-enforcement/) for policies that work across delegations.

### Template with Just-In-Time Access

For elevated permissions, see Azure Lighthouse documentation on Privileged Identity Management (PIM) integration.

### Template for Resource Groups Only

To delegate specific resource groups instead of entire subscription, add scope to registrationAssignments:

```json
"properties": {
    "registrationDefinitionId": "[resourceId('Microsoft.ManagedServices/registrationDefinitions', guid(variables('mspOfferName'), 'definition'))]",
    "scope": "/subscriptions/<SUB_ID>/resourceGroups/<RG_NAME>"
}
```

---

**Need help?** See [docs/SETUP.md](../docs/SETUP.md) for detailed setup guide.
