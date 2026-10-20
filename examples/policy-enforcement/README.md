# Policy Enforcement Examples

Deploy Azure Policies across delegated customer subscriptions.

## Examples Included

1. **enforce-https-storage.json** - Require HTTPS for storage accounts
2. **require-encryption.json** - Require encryption at rest
3. **require-tagging.json** - Enforce mandatory tags

## Quick Start

### Deploy Policy to Customer Subscription

```powershell
# From managing tenant
Connect-AzAccount -TenantId "<MANAGING_TENANT_ID>"
Select-AzSubscription -SubscriptionId "<CUSTOMER_SUBSCRIPTION_ID>"

# Deploy policy
$policy = New-AzPolicyDefinition -Name "RequireHttpsStorage" `
    -Policy (Get-Content "enforce-https-storage.json" | ConvertFrom-Json)

New-AzPolicyAssignment -Name "RequireHttpsStorageAssignment" `
    -PolicyDefinition $policy `
    -Scope "/subscriptions/<CUSTOMER_SUBSCRIPTION_ID>"
```

### Check Compliance

```powershell
# Get compliance data
$compliance = Get-AzPolicyState `
    -SubscriptionId "<CUSTOMER_SUBSCRIPTION_ID>" `
    -PolicyDefinitionName "RequireHttpsStorage"

$compliance | Select-Object ResourceId, ComplianceState, Timestamp
```

### Remediate Non-Compliant Resources

```powershell
# Auto-remediate (if policy supports it)
Start-AzPolicyRemediation `
    -PolicyAssignmentId "<assignment-id>" `
    -ResourceGroupName "<rg-name>"
```

## Limitations

⚠️ Cannot view compliance details in customer tenant from managing tenant  
✅ Compliance IS visible if you log into customer tenant directly

## Use Cases

✅ Enforce security standards  
✅ Ensure consistent tagging  
✅ Require encryption  
✅ Prevent data residency violations  
✅ Enforce compliance requirements  

---

See [examples/](../) for more scenarios.
