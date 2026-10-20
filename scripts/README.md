# PowerShell Scripts for Azure Lighthouse

Ready-to-use scripts for setup, validation, and management of Azure Lighthouse delegations.

## Scripts Included

### setup-managing-tenant.ps1
Prepare managing tenant (service provider) for delegations.

**Usage:**
```powershell
.\scripts\setup-managing-tenant.ps1 -TenantId "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
```

**What it does:**
- Signs in to managing tenant
- Lists all users, groups, and service principals
- Extracts principal IDs for template customization
- Creates output file with usable IDs

---

### setup-customer-tenant.ps1
Prepare customer tenant for receiving delegation.

**Usage:**
```powershell
.\scripts\setup-customer-tenant.ps1 -TenantId "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" -SubscriptionId "11111111-2222-3333-4444-555555555555"
```

**What it does:**
- Signs in to customer tenant
- Registers Microsoft.ManagedServices resource provider
- Verifies registration succeeded
- Ready for template deployment

---

### verify-delegation.ps1
Verify delegation is working properly.

**Usage:**
```powershell
.\scripts\verify-delegation.ps1 -SubscriptionId "11111111-2222-3333-4444-555555555555" -TenantId "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
```

**What it does:**
- Verifies can access customer resources
- Lists role assignments
- Confirms managing tenant permissions
- Tests basic operations

**Expected output:**
```
✓ Connected to managing tenant
✓ Resource provider registered
✓ Delegation found
✓ Role assignments: [list]
✓ Can list resources: [count]
```

---

### remove-delegation.ps1
Safely remove a delegation.

**Usage:**
```powershell
.\scripts\remove-delegation.ps1 -SubscriptionId "11111111-2222-3333-4444-555555555555"
```

**What it does:**
- Identifies delegation
- Prompts for confirmation
- Removes registration assignment
- Verifies removal

**Note:** Requires "Managed Services Registration Assignment Delete" role.

---

## Quick Reference

### Get Principal IDs for Template

```powershell
# User
Get-AzADUser -UserPrincipalName "admin@company.onmicrosoft.com" | Select-Object Id, DisplayName, UserPrincipalName

# Group
Get-AzADGroup -DisplayName "Lighthouse Admins" | Select-Object Id, DisplayName

# Service Principal
Get-AzADServicePrincipal -DisplayName "MyAutomationAccount" | Select-Object Id, DisplayName, AppId
```

### List All Delegations

```powershell
# From managing tenant
Get-AzSubscription | Where-Object { $_.TenantId -ne (Get-AzContext).Tenant.Id }
```

### Check Delegation Status

```powershell
# From customer tenant
Get-AzManagedServicesAssignment -Scope "/subscriptions/<SUB_ID>"

# From managing tenant
Get-AzManagedServicesAssignment -Scope "/subscriptions/<CUSTOMER_SUB_ID>"
```

### Test Access to Customer Resources

```powershell
# From managing tenant
Select-AzSubscription -SubscriptionId "<CUSTOMER_SUB_ID>"
Get-AzResource
Get-AzResourceGroup
Get-AzVM
```

---

## Error Handling

All scripts include:
- ✅ Error checking
- ✅ Verbose logging
- ✅ Graceful failure messages
- ✅ Remediation suggestions

### Common Errors

| Error | Solution |
|-------|----------|
| "Resource provider not registered" | Run setup-customer-tenant.ps1 |
| "Not authorized" | Verify you have Owner role in tenant |
| "Subscription not found" | Verify subscription ID and tenant |
| "Can't see resources" | Verify delegation deployed and TenantId correct |

---

## Customization

Scripts are designed for easy modification:

```powershell
# Change default location
$location = "westus2"  # Change to your region

# Change logging level
$DebugPreference = "Continue"  # Enable debug output

# Batch operations
foreach ($sub in $subscriptions) {
    .\scripts\verify-delegation.ps1 -SubscriptionId $sub.SubscriptionId
}
```

---

## Best Practices

✅ **Always verify** before and after operations  
✅ **Keep logs** for audit trail  
✅ **Test in non-prod** first  
✅ **Use service principals** for automation  
✅ **Document all delegations**  

---

**Need help?** Run script with `-Verbose` flag for detailed output.
