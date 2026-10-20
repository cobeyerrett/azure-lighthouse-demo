# Troubleshooting Guide

Common issues and solutions when using Azure Lighthouse.

## Deployment Issues

### Resource Provider Not Registered

**Error:** `InvalidOperationException: The subscription doesn't have the 'Microsoft.ManagedServices' resource provider registered`

**Solution:**
```powershell
Register-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"
Get-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices" | Select-Object RegistrationState
```

**Wait:** 1-2 minutes for registration to complete.

---

### Template Deployment Failed

**Error:** `DeploymentFailed: The template deployment failed`

**Check:**
1. Verify managing tenant ID is correct
   ```powershell
   Connect-AzAccount
   Get-AzContext | Select-Object TenantId
   ```

2. Verify principal ID exists in managing tenant
   ```powershell
   Connect-AzAccount -TenantId "<managing-tenant-id>"
   Get-AzADUser -ObjectId "<principal-id>"
   ```

3. Verify subscription ID is correct
   ```powershell
   Get-AzSubscription
   ```

4. Check deployment status
   ```powershell
   Get-AzSubscriptionDeployment -Name "LighthouseOnboarding" | Select-Object ProvisioningState, StatusMessage
   ```

---

## Access Issues

### Can't See Customer Subscription

**Problem:** After deployment, customer subscription doesn't appear in managing tenant

**Solution:**
1. Verify you're in managing tenant
   ```powershell
   Get-AzContext | Select-Object Tenant
   ```

2. Refresh subscriptions
   ```powershell
   Get-AzSubscription -Force
   ```

3. Wait 2-3 minutes for replication

4. Clear PowerShell cache
   ```powershell
   Get-AzSubscription -Force | Clear-AzContext
   Connect-AzAccount
   ```

---

### Access Denied to Resources

**Error:** `Insufficient privileges to complete the operation`

**Cause:** Your role doesn't include required permissions

**Solution:**
1. Check your assigned role
   ```powershell
   Get-AzRoleAssignment -Scope "/subscriptions/<customer-sub-id>"
   ```

2. Verify the role has needed permissions
   ```powershell
   Get-AzRoleDefinition -Name "Contributor" | Select-Object -ExpandProperty Actions
   ```

3. Update delegation with higher role (if needed)
   - Redeploy template with higher roleDefinitionId
   - Or remove and re-onboard

---

### Can't Remove Delegation

**Error:** `Not authorized to perform 'Microsoft.ManagedServices/registrationAssignments/delete'`

**Solution:**
Your user needs the "Managed Services Registration Assignment Delete" role.

Either:
1. **Managing tenant removes** (with correct role)
   ```powershell
   Get-AzManagedServicesAssignment -Scope "/subscriptions/<sub-id>" | Remove-AzManagedServicesAssignment
   ```

2. **Customer tenant removes** (no special role needed)
   - Portal → Service providers → Service provider offers → Delete

---

## Portal Issues

### Delegations Not Showing in Azure Lighthouse

**Problem:** Can't see "Delegations" under Azure Lighthouse

**Solution:**
1. Ensure you're in managing tenant
2. Verify your role includes "Microsoft.ManagedServices/*/read"
3. Try different browser / clear cache
4. Portal may take 5-10 minutes to update

---

### Customer Subscription Doesn't Appear in Dropdown

**Problem:** When trying to deploy to customer subscription, it's not listed

**Solution:**
1. Verify resource provider is registered
   ```powershell
   Get-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices" | Select-Object RegistrationState
   ```

2. Verify subscription ID matches
   ```powershell
   Get-AzSubscription | Select-Object SubscriptionId
   ```

3. Try explicit selection
   ```powershell
   Select-AzSubscription -SubscriptionId "<exact-id>"
   ```

---

## Policy & Compliance Issues

### Can't View Policy Compliance

**Problem:** Policy deployed, but can't see compliance state in customer tenant from managing tenant

**Limitation:** Azure Lighthouse doesn't support cross-tenant compliance details view

**Workaround:**
- Log into customer tenant directly to see compliance
- Use Resource Graph to query compliance state
- Use Azure Monitor to track policy compliance events

---

### Policy Enforcement Not Working

**Problem:** Policy deployed, but resources still non-compliant

**Check:**
1. Verify policy assignment is active
   ```powershell
   Get-AzPolicyAssignment -Scope "/subscriptions/<sub-id>"
   ```

2. Check if policy supports remediation
   ```powershell
   Get-AzPolicyDefinition -Name "<policy-name>" | Select-Object Properties
   ```

3. If using deployIfNotExists, run remediation
   ```powershell
   Start-AzPolicyRemediation -PolicyAssignmentId "<assignment-id>" `
       -ResourceGroupName "<rg-name>"
   ```

---

## Role Assignment Issues

### Can't Assign Roles to Managed Identities

**Problem:** User Access Administrator role doesn't work as expected

**Note:** User Access Administrator in Lighthouse is limited to assigning roles to managed identities ONLY

**Solution:**
1. Only use User Access Administrator with delegatedRoleDefinitionIds
   ```json
   {
       "principalId": "service-principal-id",
       "roleDefinitionId": "18d7d88d-d35e-4fb5-a5c3-7773c20a72d9",
       "delegatedRoleDefinitionIds": [
           "b24988ac-6180-42a0-ab88-20f7382dd24c"
       ]
   }
   ```

2. For general role assignment needs, use Contributor instead

---

## Network/Connectivity Issues

### Can't Connect with Service Principal

**Error:** `Error: AADSTS50013: Assertion failed to validate credentials`

**Solution:**
1. Verify service principal credentials
   ```powershell
   $credential = New-Object -TypeName System.Management.Automation.PSCredential `
       -ArgumentList "<app-id>", (ConvertTo-SecureString "<secret>" -AsPlainText -Force)
   ```

2. Verify service principal has needed role
   ```powershell
   Get-AzRoleAssignment -ObjectId "<sp-object-id>"
   ```

3. Verify service principal is in managing tenant, not customer

---

## Data & Residency Issues

### Data is in Wrong Region

**Problem:** Delegated resources not in expected region

**Note:** Lighthouse doesn't move data, it just grants access. Resources stay where they are.

**Solution:**
- Verify original deployment region
- Create new resources in desired region
- Migrate existing resources (out of scope for Lighthouse)

---

## Scale/Performance Issues

### Slow Delegation of Multiple Subscriptions

**Problem:** Deploying to many customer subscriptions takes time

**Solution:**
Use PowerShell automation with parallel deployment

```powershell
$subscriptions | ForEach-Object -Parallel {
    New-AzSubscriptionDeployment -SubscriptionId $_.SubscriptionId `
        -TemplateFile "delegationTemplate.json" `
        -AsJob
} -ThrottleLimit 5
```

---

## Still Stuck?

1. Check all logs
   ```powershell
   Get-AzActivityLog -MaxRecord 50 | Select-Object EventName, ResourceId, Status, Timestamp
   ```

2. Review [Microsoft Lighthouse docs](https://learn.microsoft.com/azure/lighthouse/)

3. Try [setup-customer-tenant.ps1](../scripts/setup-customer-tenant.ps1) to reset resource provider

4. Open GitHub issue with:
   - Exact error message
   - Command you ran
   - Tenant and subscription IDs (anonymized)
   - Steps to reproduce

---

**Pro tip:** Always run with `-Verbose` for more details
```powershell
New-AzSubscriptionDeployment ... -Verbose
```
