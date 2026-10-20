# Azure Lighthouse: Managing Tenant Operations Outline

## Overview
This document outlines how a managing tenant (Tenant A - Service Provider) can centralize operations for delegated customer subscriptions (Tenant B) across key governance, security, and modernization domains.

---

## 1. POLICY ENFORCEMENT

### Architecture
- **Policy Definition**: Created in managing tenant
- **Policy Assignment**: Deployed to customer delegated subscriptions
- **Compliance**: Enforced across customer tenant at scale

### Implementation Steps

#### Required Roles in Lighthouse Delegation
```
Role: Resource Policy Contributor
Role ID: 36243c78-bf99-498c-9df9-86d9f8d28608
Permissions: Create/update/delete policies, view compliance
```

#### Workflow

1. **Query customer subscriptions**
```powershell
# Tenant A: Sign in
Connect-AzAccount -TenantId "<TENANT_A_ID>"

# Get all delegated subscriptions
$ManagedSubscriptions = Search-AzGraph -Query "ResourceContainers | where type == 'microsoft.resources/subscriptions' | where tenantId == '<TENANT_B_ID>'" -subscription $subscriptions.subscriptionId
```

2. **Define policies** (in Tenant A)
   - Require HTTPS for storage
   - Enforce encryption
   - Enforce tagging standards
   - Restrict resource types
   - Require managed identities

3. **Deploy policies at scale**
```powershell
foreach ($ManagedSub in $ManagedSubscriptions) {
    Select-AzSubscription -SubscriptionId $ManagedSub.subscriptionId
    
    New-AzSubscriptionDeployment -Name "PolicyDeploy" `
        -Location eastus `
        -TemplateUri "https://raw.githubusercontent.com/Azure/Azure-Lighthouse-samples/master/templates/policy-enforce-https-storage/enforceHttpsStorage.json" `
        -AsJob
}
```

4. **Remediate non-compliant resources**
```powershell
# Trigger auto-remediation for deployIfNotExists policies
Start-AzPolicyRemediation -Name "remediate-https-storage" `
    -PolicyAssignmentId "/subscriptions/{subscriptionId}/providers/Microsoft.Authorization/policyAssignments/{assignmentName}"
```

### Limitations & Workarounds
- ❌ Can't view compliance details in customer tenant
- ✅ Compliance visible in Tenant B's portal locally
- ✅ Use Resource Graph to query compliance state across multiple subscriptions

### Demo Points
✅ Deploy policy to customer subscription without customer login  
✅ Show real-time remediation  
✅ Query compliance across all delegated subscriptions  

---

## 2. DEFENDER & SENTINEL (SecOps Centralization)

### Architecture
- **Tenant A**: Central security operations center (SOC)
- **Tenant B**: Delegated resources monitored from Tenant A
- **Workflow**: Remove Defender/Sentinel from Tenant B, centralize in Tenant A

### Required Roles
```
Role: Security Admin / Contributor
Minimum: Contributor
Role ID: b24988ac-6180-42a0-ab88-20f7382dd24c
```

### Implementation

#### A. Microsoft Defender for Cloud (Cross-Tenant)

1. **Prerequisites in Tenant A**
   - Defender for Cloud enabled
   - Log Analytics workspace created
   - Azure Activity Log retention configured

2. **Onboard Tenant B subscriptions to Defender**
```powershell
# Tenant A: Enable Defender on delegated subscriptions
Connect-AzAccount -TenantId "<TENANT_A_ID>"

foreach ($ManagedSub in $ManagedSubscriptions) {
    Set-AzSecurityPricing -PricingTier "Standard" `
        -SubscriptionId $ManagedSub.subscriptionId
    
    Set-AzSecurityAutoProvisioningSetting -AutoProvision "On" `
        -SubscriptionId $ManagedSub.subscriptionId
}
```

3. **Stream alerts to Tenant A workspace**
   - Enable continuous export of Defender alerts
   - Route to Log Analytics in managing tenant
   - Configure webhooks for automation

4. **Centralized dashboard**
   - Secure score aggregation across all customers
   - Compliance violations consolidated
   - Remediation tracking

#### B. Microsoft Sentinel (Multi-Workspace)

1. **Workspace Structure in Tenant A**
```
- Central Sentinel Workspace (Tenant A)
  └─ Data Connectors for each delegated subscription (Tenant B)
  └─ Unified incident management
  └─ Cross-workspace analytics
```

2. **Configure data connectors**
```powershell
# Tenant A: Connect to Tenant B resources
Connect-AzAccount -TenantId "<TENANT_A_ID>"

# Configure Azure Activity Logs data connector
New-AzSentinelDataConnector -ResourceGroupName "SecOps-RG" `
    -WorkspaceName "Central-Sentinel" `
    -Kind "AzureActivity" `
    -SubscriptionId "<TENANT_B_SUBSCRIPTION>"
```

3. **Enable multi-workspace capabilities**
   - Unified incident view
   - Cross-workspace hunting
   - Centralized threat response

4. **Remove redundant sensors from Tenant B**
   - Disable local Defender agents where centralized
   - Decommission local Sentinel workspace (if separate)
   - Reduce cost and operational overhead

### Demo Points
✅ Show Defender alerts from Tenant B appearing in Tenant A dashboard  
✅ Demonstrate unified incident management across tenants  
✅ Show cost savings from consolidation  
✅ Incident response workflow (detect → investigate → remediate)  

---

## 3. RESOURCE GRAPH FOR IaC WITH GITHUB COPILOT

### Architecture
- **Resource Graph**: Query customer infrastructure
- **IaC Generation**: Convert queries to Bicep/Terraform
- **GitHub Copilot**: Assist in code generation

### Implementation

#### A. Query delegated resources

```powershell
# Tenant A: Get all VMs in Tenant B
Connect-AzAccount -TenantId "<TENANT_A_ID>"

$query = @"
Resources
| where type =~ 'microsoft.compute/virtualmachines'
| where tenantId == '<TENANT_B_ID>'
| project name, location, resourceGroup, subscriptionId, 
          vmSize=properties.hardwareProfile.vmSize,
          os=properties.storageProfile.osDisk.osType,
          tags
| order by location
"@

Search-AzGraph -Query $query -Subscription $ManagedSubscriptions.subscriptionId
```

#### B. Inventory patterns for IaC

1. **Network topology**
```powershell
$query = @"
Resources
| where type =~ 'microsoft.network/virtualnetworks' or type =~ 'microsoft.network/networksecuritygroups'
| project type, name, location, resourceGroup, properties
"@
```

2. **Storage & databases**
```powershell
$query = @"
Resources
| where type =~ 'microsoft.storage/storageaccounts' or type =~ 'microsoft.sql/servers'
| project type, name, location, resourceGroup, sku=properties.accessTier, replication=properties.redundancy
"@
```

3. **App services & containers**
```powershell
$query = @"
Resources
| where type =~ 'microsoft.web/sites' or type =~ 'microsoft.containerregistry/registries'
| project type, name, location, resourceGroup, tier=properties.sku.tier, plan=properties.appServicePlanId
"@
```

#### C. Convert to IaC with GitHub Copilot

1. **Export Resource Graph output to JSON**
```powershell
$output = Search-AzGraph -Query $query -Subscription $subs.subscriptionId | ConvertTo-Json -Depth 10
$output | Out-File inventory.json
```

2. **Use GitHub Copilot in VS Code**
   - Paste Resource Graph JSON into editor
   - Prompt: "Generate Bicep template from this resource inventory"
   - Copilot generates parameterized Bicep
   - Refine with additional prompts

3. **Example Copilot prompts**
   - "Convert these storage accounts to Bicep with replication across regions"
   - "Create a Terraform module for this VNet and NSGs with variables"
   - "Generate Bicep for these App Services with auto-scaling"

4. **Validate & deploy**
   - Test IaC in lower environment
   - Use `az deployment` or `terraform plan` to validate
   - Deploy to refresh/standardize infrastructure

### Demo Points
✅ Query customer infrastructure without portal access  
✅ Show Resource Graph JSON  
✅ Generate Bicep/Terraform with Copilot  
✅ Demonstrate infrastructure-as-code benefits (versioning, repeatability)  

---

## 4. ENTERPRISE FABRIC WITH GATEWAY IDEA

### Architecture
- **Tenant A**: Central Fabric workspace
- **Tenant B**: Data sources (SQL, Datalake, Dynamics)
- **On-premises Gateway**: Securely connects to customer data
- **Fabric**: Unified analytics platform

### Implementation

#### A. Setup Fabric workspace in Tenant A

1. **Create Fabric capacity**
```
- Dedicated Fabric capacity in managing tenant
- Supports 50-100+ customer connections
```

2. **Create workspace**
```
- Central Analytics Workspace
- Service Principal for Lighthouse authentication
```

#### B. Deploy gateway in customer environment (Tenant B)

1. **On-premises Data Gateway**
   - Installed in customer network
   - Managed from Tenant A via service principal
   - Requires: Resource Policy Contributor or Contributor role

2. **Gateway deployment**
```powershell
# Tenant B: Customer deploys gateway
# Gateway registration in Tenant A

# Tenant A: Register gateway
Connect-AzAccount -TenantId "<TENANT_A_ID>"

$gateway = Get-AzDataFactoryV2IntegrationRuntime `
    -ResourceGroupName "<TENANT_B_RG>" `
    -DataFactoryName "<GATEWAY_NAME>" `
    -Name "<GATEWAY_CLUSTER>"
```

#### C. Data connections

1. **SQL Server connection**
   - Gateway → SQL Server (on-premises or IaaS)
   - Connection string via secret in Tenant A Key Vault
   - Refresh schedule: hourly/daily

2. **Data Lake connection**
   - Gateway → ADLS Gen2 (Tenant B storage)
   - Service principal credentials
   - Incremental refresh policy

3. **Dynamics 365 / Dataverse**
   - Service principal auth
   - Direct API connection

#### D. Semantic models & reports

1. **Semantic models in Tenant A**
```
Central Workspace (Tenant A)
├── Semantic Model 1 (SQL + ADLS)
├── Semantic Model 2 (Dynamics)
└── Reports & Dashboards
```

2. **Customer-specific views**
   - Row-level security (RLS) on semantic models
   - Each customer sees only their data
   - Shared reports across customers

### Demo Points
✅ Show gateway connection health  
✅ Real-time data refresh from customer environment  
✅ Cross-tenant data integration  
✅ Centralized semantic model serving multiple customers  
✅ Cost efficiency: single Fabric capacity vs. per-customer instances  

### Considerations
- Gateway requires customer network access
- Service principal must have Contributor role
- Data residency: confirm data stays in customer regions

---

## 5. COST MANAGEMENT

### Architecture
- **Tenant A**: Central cost aggregation
- **Tenant B**: Delegated subscriptions tracked
- **Azure Cost Management**: Cross-tenant visibility

### Required Roles
```
Role: Cost Management Contributor
OR: Reader (for view-only)
Role ID: b24988ac-6180-42a0-ab88-20f7382dd24c (Contributor)
```

### Implementation

#### A. Query costs across delegated subscriptions

```powershell
# Tenant A: Get costs for all delegated subscriptions
Connect-AzAccount -TenantId "<TENANT_A_ID>"

foreach ($ManagedSub in $ManagedSubscriptions) {
    $costs = Get-AzConsumptionUsageDetail `
        -SubscriptionId $ManagedSub.subscriptionId `
        -StartDate (Get-Date).AddMonths(-1) `
        -EndDate (Get-Date)
    
    $costs | Export-Csv -Path "cost_$($ManagedSub.subscriptionId).csv"
}
```

#### B. Resource Graph for cost analysis

```powershell
$query = @"
Resources
| where tenantId == '<TENANT_B_ID>'
| summarize count() by type, location
| join kind=inner (
    where sku != '' | project type, sku
) on type
"@

Search-AzGraph -Query $query -Subscription $subs.subscriptionId
```

#### C. Establish chargeback model

1. **Cost allocation by department**
   - Tag resources with cost center
   - Roll-up costs by tag
   - Generate customer-facing invoices

2. **Reserved Instance (RI) optimization**
   - Analyze usage patterns across customers
   - Recommend shared RIs
   - Negotiate volume discounts

3. **Automation account for cost optimization**
```powershell
# Auto-shutdown unused VMs
# Scale down non-prod after hours
# Delete old snapshots/backups
```

#### D. Billing alerts

```powershell
# Set anomaly detection
New-AzAlert -Name "Cost-Anomaly-CustomerA" `
    -SubscriptionId $ManagedSub.subscriptionId `
    -Threshold 10000 `
    -AlertAction "Email,Webhook"
```

### Demo Points
✅ Show aggregated costs across all customers  
✅ Cost trends and anomaly alerts  
✅ Cost optimization recommendations  
✅ Demonstrate ROI of Lighthouse (shared infra vs. per-customer)  

---

## 6. SPECSUITE FOR APP MODERNIZATION

### Architecture
- **AppSpecial Suite**: Assessment & modernization framework
- **Tenant A**: Central assessment coordination
- **Tenant B**: Target applications for modernization
- **Outputs**: Migration roadmaps, resource estimates

### Implementation

#### A. Discovery & Assessment (in Tenant B)

1. **App Inventory**
   - Query application metadata via Resource Graph
   - Identify .NET, Java, Node.js apps
   - Assess containerization readiness

```powershell
$query = @"
Resources
| where type =~ 'microsoft.web/sites' or type =~ 'microsoft.web/serverfarms'
| project name, location, resourceGroup, kind, properties.reserved
"@
```

2. **Dependencies scanning**
   - Database connections
   - External integrations
   - Network dependencies

#### B. Containerization pathway

1. **Azure Container Registry (ACR) in Tenant A**
   - Central registry for all customer images
   - Shared storage with per-customer namespaces
   - RBAC per customer via service principals

2. **App Service → Container Apps migration**
```bicep
param appName string
param containerImage string
param customerTenantId string

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: '${appName}-ca'
  location: location
  properties: {
    managedEnvironmentId: managedEnv.id
    template: {
      containers: [
        {
          image: containerImage
          name: appName
        }
      ]
    }
  }
}
```

#### C. Database modernization

1. **SQL Server → Azure SQL**
   - Azure Data Migration Service (DMS) for lift-and-shift
   - Managed identity for cross-tenant connectivity

2. **Cosmos DB for scale**
   - Geo-replication across regions
   - Multi-tenant database design

#### D. Modernization governance

1. **Policy-driven modernization**
   - Enforce deprecation timelines
   - Require container readiness assessments
   - Audit app versions

```json
{
  "policyName": "Deprecate-Legacy-AppServices",
  "description": "Move apps from Windows Web App (v2) to Container Apps",
  "effect": "deny",
  "condition": "kind == 'app' AND runtime < 'net6'"
}
```

2. **Cost model**
   - Container Apps: ~40% cheaper than App Service (same perf)
   - AKS for high-scale scenarios
   - Serverless Functions for event-driven

### Demo Points
✅ Scan customer applications for modernization candidates  
✅ Show containerization readiness report  
✅ Demonstrate cost savings (App Service → Container Apps)  
✅ Show migration path with Lighthouse enabling hands-off deployment  

---

## Summary Table: Roles Required

| Operation | Required Role | Role ID |
|-----------|---------------|---------|
| Policy Enforcement | Resource Policy Contributor | `36243c78-bf99-498c-9df9-86d9f8d28608` |
| Defender / Sentinel | Contributor / Security Admin | `b24988ac-6180-42a0-ab88-20f7382dd24c` |
| Resource Graph | Reader | `acdd72a7-3385-48ef-bd42-f606fba81ae7` |
| Fabric / Data Gateway | Contributor | `b24988ac-6180-42a0-ab88-20f7382dd24c` |
| Cost Management | Cost Management Contributor | `b24988ac-6180-42a0-ab88-20f7382dd24c` |
| App Modernization | Contributor | `b24988ac-6180-42a0-ab88-20f7382dd24c` |

---

## Key Success Factors

✅ **Single Sign-On**: Tenant A users never sign into Tenant B  
✅ **Centralized Control**: All operations from Tenant A  
✅ **Compliance**: Audit trails in both tenants  
✅ **Cost Efficiency**: Shared infrastructure vs. per-customer  
✅ **Security**: Least privilege roles, just-in-time access  

---

## Common Gotchas

❌ Delegations require **entire subscription** (not just RG) for Defender  
❌ Can't view policy compliance details in Tenant B portal  
❌ Gateway requires network connectivity (on-premises or hybrid)  
❌ Data residency rules may restrict cross-region Fabric  
❌ Service principals must have explicit role assignments  

---

## Next Steps for Demo

1. Set up test Lighthouse delegation (both tenants)
2. Deploy sample policy and show enforcement
3. Enable Defender/Sentinel with test data
4. Run Resource Graph query and show outputs
5. Deploy Fabric workspace with test data connector
6. Show cost aggregation and alerts
7. Run AppSpecial assessment on test app
