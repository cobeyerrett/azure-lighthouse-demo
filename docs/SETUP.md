# Azure Lighthouse Setup: Complete Step-by-Step Guide

## Overview
This guide covers the complete Azure Lighthouse onboarding process from both the **Managing Tenant (Service Provider)** and **Customer Tenant** perspectives.

---

## PHASE 1: PRE-REQUISITE SETUP (Managing Tenant)

### Step 1: Gather Information from Customer

**Information needed from Tenant B (Customer):**
- Subscription ID(s) to delegate
- Tenant ID (Directory ID)
- Names of resource groups (if delegating RGs only, not full subscription)

**Example:**
```
Customer Tenant ID: aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
Subscription ID: 11111111-2222-3333-4444-555555555555
Resource Groups: rg-prod, rg-dev (or leave empty for full subscription)
```

---

### Step 2: Identify Managing Tenant Users/Groups (Tenant A)

**Sign in to Managing Tenant (Tenant A):**

```powershell
Connect-AzAccount -TenantId "<MANAGING_TENANT_ID>"

# Get current context
Get-AzContext

# Get your user/group IDs who need access
# Example: Get a user
Get-AzADUser -UserPrincipalName "admin@yourtenant.onmicrosoft.com" | Select-Object Id, DisplayName

# Example: Get a group
Get-AzADGroup -DisplayName "Lighthouse Admins" | Select-Object Id, DisplayName

# Example: Get a service principal
Get-AzADServicePrincipal -DisplayName "LighthouseAutomation" | Select-Object Id, DisplayName
```

**Document these values:**
- Principal ID (Object ID)
- Display Name
- Type (User/Group/Service Principal)
- Roles needed (see role definitions below)

---

### Step 3: Define Role Definitions

**Common roles and their IDs:**

| Role | ID | Use Case |
|------|----|---------| 
| Owner | `8e3af657-a8ff-443c-a75c-2fe8c4bcb635` | ❌ NOT supported in Lighthouse |
| Contributor | `b24988ac-6180-42a0-ab88-20f7382dd24c` | General management, deployments |
| Reader | `acdd72a7-3385-48ef-bd42-f606fba81ae7` | Read-only access |
| Resource Policy Contributor | `36243c78-bf99-498c-9df9-86d9f8d28608` | Policy management |
| Managed Services Registration Assignment Delete | `91c1777a-f3dc-4fae-b103-61d183457e46` | Remove delegation |
| User Access Administrator | `18d7d88d-d35e-4fb5-a5c3-7773c20a72d9` | Limited: assign roles to managed identities |

---

### Step 4: Create ARM Template (delegationTemplate.json)

**Location:** Create in Managing Tenant

**File: delegationTemplate.json**

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "variables": {
        "mspOfferName": "Demo Lighthouse - Contoso Customer",
        "mspOfferDescription": "Manages Contoso subscription resources",
        "managedByTenantId": "<TENANT_A_ID>",
        "authorizations": [
            {
                "principalId": "<PRINCIPAL_ID_1>",
                "principalIdDisplayName": "Demo Admin User",
                "roleDefinitionId": "b24988ac-6180-42a0-ab88-20f7382dd24c"
            },
            {
                "principalId": "<PRINCIPAL_ID_2>",
                "principalIdDisplayName": "MSP Operators",
                "roleDefinitionId": "36243c78-bf99-498c-9df9-86d9f8d28608"
            },
            {
                "principalId": "<PRINCIPAL_ID_3>",
                "principalIdDisplayName": "MSP Support Team",
                "roleDefinitionId": "91c1777a-f3dc-4fae-b103-61d183457e46"
            }
        ]
    },
    "resources": [
        {
            "type": "Microsoft.ManagedServices/registrationDefinitions",
            "apiVersion": "2022-10-01",
            "name": "[guid(variables('mspOfferName'), 'definition')]",
            "properties": {
                "registrationDefinitionName": "[variables('mspOfferName')]",
                "description": "[variables('mspOfferDescription')]",
                "managedByTenantId": "[variables('managedByTenantId')]",
                "authorizations": "[variables('authorizations')]"
            }
        },
        {
            "type": "Microsoft.ManagedServices/registrationAssignments",
            "apiVersion": "2022-10-01",
            "name": "[guid(variables('mspOfferName'), 'assignment')]",
            "dependsOn": [
                "[resourceId('Microsoft.ManagedServices/registrationDefinitions', guid(variables('mspOfferName'), 'definition'))]"
            ],
            "properties": {
                "registrationDefinitionId": "[resourceId('Microsoft.ManagedServices/registrationDefinitions', guid(variables('mspOfferName'), 'definition'))]"
            }
        }
    ]
}
```

**Key parameters to customize:**
- `managedByTenantId`: Your Tenant A ID
- `mspOfferName`: Give it a meaningful name
- `authorizations[].principalId`: Object IDs from Step 2
- `authorizations[].roleDefinitionId`: Roles needed

---

### Step 5: Create Parameters File (delegationTemplate.parameters.json)

**File: delegationTemplate.parameters.json**

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {}
}
```

This file is simple (parameters defined in template), but required for deployment.

---

### Step 6: Share Template with Customer

**Provide to Customer Tenant:**
- ✅ delegationTemplate.json (completed with your values)
- ✅ delegationTemplate.parameters.json
- ✅ Clear deployment instructions
- ✅ PowerShell script to execute

**Secure delivery:**
- GitHub private repo
- Azure DevOps
- Secure email/transfer method
- DO NOT commit credentials or sensitive values to public repos

---

## PHASE 2: CUSTOMER TENANT PREPARATION (Tenant B)

### Step 7: Customer Registers Resource Provider

**Customer Tenant (Tenant B) - Run as Owner:**

```powershell
# Sign in to customer tenant
Connect-AzAccount -TenantId "<CUSTOMER_TENANT_ID>"

# Get subscriptions to delegate
Get-AzSubscription

# Select the subscription to delegate
Select-AzSubscription -SubscriptionId "<SUBSCRIPTION_ID>"

# Register the Microsoft.ManagedServices resource provider
Register-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"

# Verify registration (should show "Registered")
Get-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices" | Select-Object ProviderNamespace, RegistrationState
```

**Expected output:**
```
ProviderNamespace RegistrationState
----------------- -----------------
Microsoft.ManagedServices Registered
```

---

### Step 8: Customer Reviews Delegation Requirements

**Customer reviews:**
- ✅ Who is the managing tenant (Tenant A)?
- ✅ What permissions are being granted?
- ✅ For what resources (subscription or RGs)?
- ✅ Role definitions and their implications
- ✅ Support/escalation contacts

**Customer should verify:**
- Are the principal IDs correct?
- Are the roles appropriate?
- Is the offer name clear?

---

## PHASE 3: DEPLOYMENT (Customer Tenant)

### Step 9: Customer Deploys ARM Template

**Customer Tenant - Execute deployment:**

```powershell
# Sign in to customer tenant
Connect-AzAccount -TenantId "<CUSTOMER_TENANT_ID>"

# Select subscription to delegate
Select-AzSubscription -SubscriptionId "<SUBSCRIPTION_ID>"

# Deploy the template
New-AzSubscriptionDeployment `
    -Name "LighthouseOnboarding" `
    -Location "eastus" `
    -TemplateFile "C:\path\to\delegationTemplate.json" `
    -TemplateParameterFile "C:\path\to\delegationTemplate.parameters.json" `
    -Verbose

# Monitor deployment
Get-AzSubscriptionDeployment -Name "LighthouseOnboarding"
```

**Expected output:**
```
ProvisioningState : Succeeded
DeploymentId      : /subscriptions/.../deployments/LighthouseOnboarding
```

---

### Step 10: Verify Delegation in Customer Tenant

**Customer Tenant - Verify deployment:**

```powershell
# List all managed services assignments
Get-AzManagedServicesAssignment

# Get details of specific assignment
Get-AzManagedServicesAssignment -Scope "/subscriptions/<SUBSCRIPTION_ID>" | Select-Object Id, Name, Properties
```

**Expected:**
- Registration Definition should exist
- Registration Assignment should exist
- Properties show managing tenant ID

---

## PHASE 4: MANAGING TENANT VALIDATION (Tenant A)

### Step 11: Managing Tenant Verifies Delegation

**Managing Tenant (Tenant A) - Verify access:**

```powershell
# Sign in to managing tenant
Connect-AzAccount -TenantId "<MANAGING_TENANT_ID>"

# List all delegated subscriptions
Get-AzSubscription

# Should see the customer subscription listed
# Note: TenantId will show your managing tenant ID
# HomeTenantId will show customer tenant ID for delegated subs

# Get detailed subscription info
$delegatedSub = Get-AzSubscription -SubscriptionId "<CUSTOMER_SUBSCRIPTION_ID>"
$delegatedSub | Select-Object Name, SubscriptionId, TenantId, HomeTenantId

# List managed services assignments for the delegated subscription
Get-AzManagedServicesAssignment -Scope "/subscriptions/<CUSTOMER_SUBSCRIPTION_ID>"
```

---

### Step 12: Test Access to Customer Resources

**Managing Tenant - Verify you can access resources:**

```powershell
# Sign in to managing tenant
Connect-AzAccount -TenantId "<MANAGING_TENANT_ID>"

# Select the delegated subscription
Select-AzSubscription -SubscriptionId "<CUSTOMER_SUBSCRIPTION_ID>"

# List resources in customer subscription
Get-AzResource

# List resource groups
Get-AzResourceGroup

# Try a specific operation (e.g., list VMs)
Get-AzVM

# List current role assignments in delegated subscription
Get-AzRoleAssignment -Scope "/subscriptions/<CUSTOMER_SUBSCRIPTION_ID>"
```

**Success criteria:**
- ✅ Can list resources
- ✅ Can see resource groups
- ✅ Can perform actions based on assigned roles
- ✅ Cannot perform actions outside assigned roles

---

### Step 13: View in Azure Portal (Managing Tenant)

**Managing Tenant - Navigate in Portal:**

1. Sign in to Azure Portal
2. Go to **Azure Lighthouse** (search at top)
3. Select **Customers** → **Delegations**
4. Should see:
   - Delegation name (mspOfferName)
   - Customer subscription ID
   - Customer tenant ID
   - Authorization list with roles

---

## PHASE 5: CUSTOMER TENANT VIEW

### Step 14: Customer Views Delegation in Portal

**Customer Tenant - Navigate in Portal:**

1. Sign in to Customer Tenant Azure Portal
2. Search for **Service providers** (or go to All services → Management)
3. Click **Service provider offers**
4. Should see:
   - Offer name
   - Managing tenant name
   - Delegated scope
   - Manage link

---

## PHASE 6: POST-DEPLOYMENT VALIDATION

### Step 15: Confirm Access Across Both Portals

**Managing Tenant Checklist:**
- ✅ Customer subscription visible in subscriptions list
- ✅ Can deploy resources to customer subscription
- ✅ Can assign policies
- ✅ Can create resource groups
- ✅ Can view costs (if Cost Management role granted)
- ✅ Can view compliance (if Security Admin role granted)

**Customer Tenant Checklist:**
- ✅ Service provider offer visible
- ✅ Can see who has access (via Service providers)
- ✅ Can remove delegation anytime
- ✅ Activity log shows delegation events

---

### Step 16: Test Specific Scenarios

**Test delegated operations:**

```powershell
# From Managing Tenant

# Create resource group in customer subscription
New-AzResourceGroup -Name "ManagedRG" `
    -Location "eastus" `
    -SubscriptionId "<CUSTOMER_SUBSCRIPTION_ID>"

# Deploy resources (e.g., storage account)
New-AzStorageAccount -ResourceGroupName "ManagedRG" `
    -Name "custmanagedsa$(Get-Random)" `
    -Location "eastus" `
    -SkuName Standard_LRS `
    -SubscriptionId "<CUSTOMER_SUBSCRIPTION_ID>"

# Assign policy
New-AzPolicyAssignment -Name "RequireHttps" `
    -PolicyDefinition (Get-AzPolicyDefinition -Name "RequireHttpsStorage") `
    -Scope "/subscriptions/<CUSTOMER_SUBSCRIPTION_ID>"
```

---

## COMPLETE WORKFLOW SUMMARY

| Phase | Actor | Steps | Outcome |
|-------|-------|-------|---------|
| **1** | Managing Tenant | 1-6 | ARM template ready for customer |
| **2** | Customer Tenant | 7-8 | Preparation complete, resource provider registered |
| **3** | Customer Tenant | 9-10 | Template deployed, delegation active |
| **4** | Managing Tenant | 11-13 | Access verified, customer resources visible |
| **5** | Customer Tenant | 14 | Service provider offer visible |
| **6** | Both | 15-16 | Full validation and testing |

---

## Quick Reference: Command Cheat Sheet

### Managing Tenant
```powershell
# List delegated subscriptions
Get-AzSubscription

# Get delegation details
Get-AzManagedServicesAssignment -Scope "/subscriptions/<id>"

# Access customer resources
Select-AzSubscription -SubscriptionId "<customer-sub>"
Get-AzResource
```

### Customer Tenant
```powershell
# Register resource provider
Register-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"

# Deploy template
New-AzSubscriptionDeployment -Name "LighthouseOnboarding" `
    -Location "eastus" `
    -TemplateFile "delegationTemplate.json"

# Verify delegation
Get-AzManagedServicesAssignment
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Resource provider not registered | Run `Register-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"` |
| Deployment fails | Check template syntax, verify IDs are correct (tenant, subscription, principal) |
| Can't see delegated subscription | Ensure you're in managing tenant, check role assignments |
| Access denied to resources | Verify your user/group has the role in the delegation |
| Can't remove delegation | Ensure you have "Managed Services Registration Assignment Delete" role |

---

## Next Steps After Onboarding

Once delegation is complete:
1. ✅ Deploy policies
2. ✅ Setup monitoring/alerts
3. ✅ Configure Defender for Cloud
4. ✅ Enable Sentinel
5. ✅ Setup cost management
6. ✅ Document handover procedures
