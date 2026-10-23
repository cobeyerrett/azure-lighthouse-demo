# Auto-Delegation of Subscriptions to Lighthouse Using Azure Policy

## Azure Policy Can Auto-Delegate Subscriptions

Azure Policy can **automatically delegate new subscriptions** to your managing tenant using the **`deployIfNotExists`** effect. This is a built-in Microsoft pattern for scaling Lighthouse across management groups.

---

## How It Works

### The Architecture

```
Management Group
├── Subscription 1 ✅ Auto-delegated by policy
├── Subscription 2 ✅ Auto-delegated by policy
├── Subscription 3 ✅ Auto-delegated by policy (NEW)
└── (Any new subscription added) ✅ Auto-delegated by policy
```

### The Process

1. **Azure Policy** is assigned at the management group level
2. **Policy Effect**: `deployIfNotExists`
3. **Policy Action**: Checks each subscription in the management group
4. **If NOT delegated**: Automatically creates the Lighthouse delegation
5. **If NEW subscription added**: Policy auto-delegates it on next evaluation

---

## Key Features

✅ **Automatic** - No manual intervention needed  
✅ **Scalable** - Works across entire management groups  
✅ **Consistent** - Same authorizations for all subscriptions  
✅ **Keeps Running** - New subscriptions added later are auto-delegated  
✅ **Hands-off** - Customer deploys once, managing tenant handles the rest  

---

## Limitations to Know

⚠️ **Same authorizations for all subscriptions** - Can't vary roles per subscription  
⚠️ **Subscriptions must be pre-registered** - Resource provider registration must happen first  
⚠️ **Management group delegation still not supported** - Only subscriptions are delegated  
⚠️ **Compliance only at subscription level** - Not management group level  

---

## Implementation Steps

### Step 1: Register Microsoft.ManagedServices Resource Provider

**In Customer Tenant:**

Before the policy can run, register the resource provider across all subscriptions in the management group.

**Option A: Using Logic App (Recommended)**

Microsoft provides an Azure Logic App that auto-registers the provider:

```
https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/register-managed-services-rp-customer
```

This Logic App:
- Deploys in customer's tenant
- Has limited permissions (just `/register/action`)
- Automatically registers across all subscriptions in the management group
- Safe and scoped

**Option B: Manual Registration (PowerShell)**

```powershell
# For each subscription in the management group
Select-AzSubscription -SubscriptionId "<SubscriptionId>"
Register-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"
```

**Option C: Using Microsoft's Provider Registration Logic App**

Microsoft also provides a Logic App for **service providers** that can register across multiple customer tenants:

```
https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/register-managed-services-rp-partner
```

**Note:** Requires tenant-wide admin consent (user must be authorized to consent on behalf of org)

---

### Step 2: Create Policy Definition & Parameters

**Microsoft provides ready-to-use templates:**

**Policy Template:**
```
https://github.com/Azure/Azure-Lighthouse-samples/blob/master/templates/policy-delegate-management-groups/deployLighthouseIfNotExistManagementGroup.json
```

**Parameters Template:**
```
https://github.com/Azure/Azure-Lighthouse-samples/blob/master/templates/policy-delegate-management-groups/deployLighthouseIfNotExistsManagementGroup.parameters.json
```

### Step 3: Customize Parameters File

Edit the parameters file with your values:

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "managedByName": {
            "value": "Your Company Managed Services"
        },
        "managedByDescription": {
            "value": "Your company provides managed services to customers"
        },
        "managedByTenantId": {
            "value": "YOUR_MANAGING_TENANT_ID_HERE"
        },
        "managedByAuthorizations": {
            "value": [
                {
                    "principalId": "PRINCIPAL_ID_1",
                    "principalIdDisplayName": "Tier 1 Support",
                    "roleDefinitionId": "b24988ac-6180-42a0-ab88-20f7382dd24c"
                },
                {
                    "principalId": "PRINCIPAL_ID_2",
                    "principalIdDisplayName": "Automation Account",
                    "roleDefinitionId": "18d7d88d-d35e-4fb5-a5c3-7773c20a72d9",
                    "delegatedRoleDefinitionIds": [
                        "b24988ac-6180-42a0-ab88-20f7382dd24c",
                        "92aaf0da-9dab-42b6-94a3-d43ce8d16293",
                        "91c1777a-f3dc-4fae-b103-61d183457e46"
                    ]
                }
            ]
        }
    }
}
```

---

### Step 4: Deploy Policy to Management Group

**Using PowerShell:**

```powershell
New-AzManagementGroupDeployment `
    -Name "LighthouseAutoDelegationPolicy" `
    -Location "eastus" `
    -ManagementGroupId "YourManagementGroupId" `
    -TemplateFile ".\deployLighthouseIfNotExistManagementGroup.json" `
    -TemplateParameterFile ".\deployLighthouseIfNotExistsManagementGroup.parameters.json" `
    -Verbose
```

**Using Azure CLI:**

```bash
az deployment mg create \
    --name "LighthouseAutoDelegationPolicy" \
    --location "eastus" \
    --management-group-id "YourManagementGroupId" \
    --template-file "deployLighthouseIfNotExistManagementGroup.json" \
    --parameters "@deployLighthouseIfNotExistsManagementGroup.parameters.json" \
    --verbose
```

---

### Step 5: Create Remediation Task for Existing Subscriptions

**For subscriptions that existed BEFORE policy assignment:**

The policy won't auto-apply to existing subscriptions. You must create a remediation task:

**Using PowerShell:**

```powershell
# Get the policy assignment
$policyAssignment = Get-AzPolicyAssignment `
    -ManagementGroupName "YourManagementGroupId" `
    -PolicyDefinitionName "deployLighthouseIfNotExists"

# Start remediation for existing subscriptions
Start-AzPolicyRemediation `
    -PolicyAssignmentId $policyAssignment.PolicyAssignmentId `
    -ManagementGroupName "YourManagementGroupId"
```

**Using Azure Portal:**

1. Go to **Policy** → **Assignments**
2. Find the Lighthouse delegation policy assignment
3. Click **Remediation**
4. Select **Create Remediation Task**
5. Review affected subscriptions
6. Click **Remediate**

---

### Step 6: Verify Policy is Working

**Check policy compliance:**

```powershell
Get-AzPolicyState `
    -ManagementGroupName "YourManagementGroupId" `
    -PolicyDefinitionName "deployLighthouseIfNotExists" | 
    Select-Object SubscriptionId, ComplianceState, Timestamp
```

**Expected output:**
```
SubscriptionId                       ComplianceState Timestamp
--------------                       --------------- ---------
aaaaaaaa-bbbb-cccc-dddd-111111111111 Compliant       2026-10-20
aaaaaaaa-bbbb-cccc-dddd-222222222222 Compliant       2026-10-20
aaaaaaaa-bbbb-cccc-dddd-333333333333 Compliant       2026-10-20
```

**Verify delegations in Lighthouse:**

From managing tenant, verify you see all delegated subscriptions:

```powershell
Connect-AzAccount -TenantId "MANAGING_TENANT_ID"
Get-AzManagedServicesAssignment | Select-Object Name, Properties
```

---

## Auto-Delegation of NEW Subscriptions

Once the policy is assigned and active:

✅ **When you add a new subscription to the management group:**
1. Azure Policy automatically evaluates the new subscription
2. Policy detects it's not delegated to your managing tenant
3. Policy creates the delegation automatically
4. New subscription appears in your Azure Lighthouse within minutes

**No additional work needed!**

---

## Comparison: Manual vs Auto-Delegation

| Aspect | Manual Delegation | Auto-Delegation (Policy) |
|--------|-------------------|-------------------------|
| **Per subscription** | Yes - manual for each | No - automatic for group |
| **New subscriptions** | Requires re-deployment | Automatic ✅ |
| **Different roles per sub** | Yes - customize each | No - same for all |
| **Time to scale** | Hours/Days | Minutes ✅ |
| **Ongoing management** | High - repeat per sub | Low - set once ✅ |
| **Ideal for** | Few customers | Many customers ✅ |

---

## Advanced: Multi-Tenant Auto-Delegation

**For service providers managing multiple customer tenants:**

Microsoft provides a Logic App that can auto-register and auto-delegate across **multiple customer tenants**:

```
https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/register-managed-services-rp-partner
```

**Requirements:**
- Requires tenant-wide admin consent
- Service provider tenant has elevated permissions
- Registers and delegates across multiple management groups

---

## Troubleshooting Auto-Delegation

### Policy not triggering?

```powershell
# Check policy assignment status
Get-AzPolicyAssignment -ManagementGroupName "YourMGId"

# Check compliance state
Get-AzPolicyState -ManagementGroupName "YourMGId" -Filter "policyDefinitionName eq 'deployLighthouseIfNotExists'"

# Check if resource provider is registered
Get-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices" | 
    Select-Object RegistrationState
```

### Subscriptions not delegating?

**Cause:** Resource provider not registered  
**Solution:** Run provider registration Logic App or PowerShell script

```powershell
Register-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"
```

### Only some subscriptions delegating?

**Cause:** Policy compliance evaluation hasn't run yet  
**Solution:** Wait 5-10 minutes for Azure Policy evaluation cycle

To force immediate evaluation:
```powershell
# Trigger policy compliance scan
$mgId = "YourManagementGroupId"
Get-AzSubscription -ManagementGroupName $mgId | 
    ForEach-Object { 
        Trigger-AzPolicyEvaluation -SubscriptionId $_.SubscriptionId 
    }
```

---

## Architecture Diagram

```
Customer Tenant (Customer Company)
│
├─ Management Group
│  │
│  ├─ Subscription 1 ──┐
│  ├─ Subscription 2 ──┤ Azure Policy
│  ├─ Subscription 3 ──┤ (deployIfNotExists)
│  └─ Subscription N ──┘
│
└─ Microsoft.ManagedServices Resource Provider
   (Registered in all subscriptions)
   │
   └─ Creates Lighthouse delegations automatically
      │
      ├─ registrationDefinition
      └─ registrationAssignment
         │
         └─ Points to Managing Tenant


Managing Tenant (Your Company)
│
└─ Azure Lighthouse
   │
   ├─ Sees Subscription 1 ✅
   ├─ Sees Subscription 2 ✅
   ├─ Sees Subscription 3 ✅
   └─ Sees Subscription N ✅
      │
      └─ Can manage all automatically!
```

---

## Real-World Example

**Scenario:** MSP managing 50 customer subscriptions across a management group

**Without Auto-Delegation:**
- Deploy template 50 times manually
- ~50 hours of work
- Risk of configuration errors
- Each new customer = more manual work

**With Auto-Delegation:**
- Deploy policy once ✅
- Covers all 50 subscriptions automatically ✅
- Add new subscriptions anytime - auto-delegated ✅
- ~1 hour setup + 5 minutes per deployment
- Error-free, consistent configuration ✅

---

## Microsoft Documentation

- **Official Guide:** https://learn.microsoft.com/azure/lighthouse/how-to/onboard-management-group
- **Policy Templates:** https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/policy-delegate-management-groups
- **Logic App for Registration:** https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/register-managed-services-rp-customer
- **Policy Concepts:** https://learn.microsoft.com/azure/governance/policy/

---

## Implementation Checklist

- [ ] **Plan:** Identify target management group(s)
- [ ] **Register:** Deploy provider registration Logic App or script
- [ ] **Configure:** Edit parameters with your tenant/principal IDs
- [ ] **Deploy:** Deploy policy to management group
- [ ] **Remediate:** Create remediation task for existing subscriptions
- [ ] **Verify:** Check policy compliance and delegations
- [ ] **Test:** Add a test subscription to verify auto-delegation
- [ ] **Monitor:** Check policy compliance regularly
- [ ] **Document:** Document policy in your runbooks

---

**Status:** ✅ Production-ready  
**Maintenance:** Minimal - policy handles everything  
**Scalability:** Unlimited - works with any number of subscriptions
