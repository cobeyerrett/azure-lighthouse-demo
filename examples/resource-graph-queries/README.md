# Resource Graph Queries for Lighthouse Management

Collection of Azure Resource Graph (KQL) queries to assess and manage resources across delegated subscriptions in your managed tenant. These queries help with compliance, cost analysis, inventory, and operational oversight.

## Quick Start

### Run a Query

**Using Azure Portal:**
1. Go to **Resource Graph Explorer** (search in portal)
2. Copy a query below
3. Click **Run query**
4. Export results to CSV/Excel

**Using PowerShell:**

```powershell
$query = @"
Resources
| where tags['Environment'] == 'Production'
| summarize count() by type
"@

Search-AzGraph -Query $query
```

**Using Azure CLI:**

```bash
az graph query -q "Resources | where tags['Environment'] == 'Production' | summarize count() by type"
```

---

## Basic Tag Queries

### 1. Find All Resources with Specific Tag and Value

```kusto
Resources
| where tags['Environment'] == 'Production'
| project name, type, location, tags
```

**Use case:** Find all production resources across all delegated subscriptions

**Output columns:**
- `name` - Resource name
- `type` - Resource type (e.g., Microsoft.Compute/virtualMachines)
- `location` - Azure region
- `tags` - All tags for the resource

---

### 2. Find Resources Missing a Specific Tag

```kusto
Resources
| where isempty(tags['CostCenter'])
| project name, type, resourceGroup, subscriptionId, tags
| sort by name asc
```

**Use case:** Identify untagged resources for compliance

**Output columns:**
- `name` - Resource name
- `type` - Resource type
- `resourceGroup` - Resource group name
- `subscriptionId` - Subscription ID
- `tags` - Current tags (if any)

---

### 3. Find Resources with Multiple Tag Conditions

```kusto
Resources
| where tags['Environment'] == 'Production' 
   and tags['Owner'] == 'Finance'
   and tags['CostCenter'] == '12345'
| project name, type, location, resourceGroup
```

**Use case:** Find Finance department's production resources

**Operators:**
- `==` - Exact match
- `!= ` - Not equal
- `contains` - String contains
- `startswith` - Starts with a value

---

### 4. Find Resources with Specific Tag (Any Value)

```kusto
Resources
| where tags has 'Environment'
| project name, type, tags['Environment'], resourceGroup
```

**Use case:** Find all resources that have been tagged with 'Environment' key

---

## Compliance & Audit Queries

### 5. Count Resources by Tag Value

```kusto
Resources
| summarize Count = count() by tostring(tags['Environment'])
| sort by Count desc
```

**Use case:** Get overview of resource distribution by environment

**Output example:**
```
Environment    | Count
Production     | 124
Development    | 45
Staging        | 23
Test           | 8
```

---

### 6. Find Resources Older Than 30 Days Without Recent Tag Update

```kusto
Resources
| where todatetime(tags['LastReviewDate']) < now(-30d) 
   or isempty(tags['LastReviewDate'])
| project name, type, resourceGroup, tags['LastReviewDate']
| sort by name asc
```

**Use case:** Find resources that haven't been reviewed recently

---

### 7. Audit: All Resources by Owner and Environment

```kusto
Resources
| project name, type, resourceGroup, subscriptionId, Owner=tags['Owner'], Environment=tags['Environment']
| sort by Owner asc, Environment asc
```

**Use case:** Generate audit report of ownership and environment assignments

---

### 8. Find Untagged Production Resources (Risk)

```kusto
Resources
| where resourceGroup !contains 'test' 
   and resourceGroup !contains 'dev'
   and (isempty(tags['Environment']) or tags['Environment'] != 'Production')
| project name, type, resourceGroup, tags
```

**Use case:** Find potentially production resources that aren't properly tagged

---

## Cost Management Queries

### 9. Group Resources by Cost Center Tag

```kusto
Resources
| where isnotempty(tags['CostCenter'])
| project name, type, subscriptionId, CostCenter=tags['CostCenter'], Environment=tags['Environment']
| summarize ResourceCount = count() by CostCenter, Environment
| sort by CostCenter asc
```

**Use case:** Understand resource distribution across cost centers

---

### 10. Find Expensive Resource Types by Department

```kusto
Resources
| where type in ('Microsoft.Compute/virtualMachines', 
                  'Microsoft.Sql/servers/databases',
                  'Microsoft.DBforPostgreSQL/servers')
| project name, type, subscriptionId, Department=tags['Department'], Location=location
| summarize Count = count() by Department, type
| sort by Count desc
```

**Use case:** Identify high-cost resource types per department

---

### 11. Resources by Subscription and Tag

```kusto
Resources
| project subscriptionId, Environment=tags['Environment'], Department=tags['Department'], type
| summarize ResourceCount = count() by subscriptionId, Environment, Department
| sort by subscriptionId asc
```

**Use case:** Cross-tenant visibility of tag-based resource allocation

---

## Inventory Queries

### 12. Complete Resource Inventory with Key Tags

```kusto
Resources
| project 
    ResourceName = name,
    ResourceType = type,
    ResourceGroup = resourceGroup,
    Subscription = subscriptionId,
    Location = location,
    Environment = tags['Environment'],
    Owner = tags['Owner'],
    CostCenter = tags['CostCenter'],
    LastModified = todatetime(tags['LastModified'])
| sort by ResourceType asc, Environment asc
```

**Use case:** Export complete inventory for compliance/auditing

---

### 13. Virtual Machines by Environment and Owner

```kusto
Resources
| where type == 'Microsoft.Compute/virtualMachines'
| project 
    VMName = name,
    Environment = tags['Environment'],
    Owner = tags['Owner'],
    ResourceGroup = resourceGroup,
    Location = location
| sort by Environment asc, Owner asc
```

**Use case:** Find all VMs and who's responsible for each

---

### 14. Databases by Application and Owner

```kusto
Resources
| where type in (
    'Microsoft.Sql/servers/databases',
    'Microsoft.DBforPostgreSQL/servers',
    'Microsoft.DBforMySQL/servers',
    'Microsoft.DocumentDB/databaseAccounts'
)
| project
    DatabaseName = name,
    DatabaseType = type,
    Application = tags['Application'],
    Owner = tags['Owner'],
    Location = location,
    ResourceGroup = resourceGroup
| sort by Application asc
```

**Use case:** Inventory of all databases and ownership

---

## Governance & Security Queries

### 15. Find All Resources in Specific Subscriptions

```kusto
Resources
| where subscriptionId in ('aaaaaaaa-bbbb-cccc-dddd-111111111111', 
                           'aaaaaaaa-bbbb-cccc-dddd-222222222222')
| project name, type, resourceGroup, tags
| summarize Count = count() by tostring(type)
```

**Use case:** Audit specific customer subscriptions in your managed tenant

---

### 16. Resources Without Required Tags (Compliance)

```kusto
let requiredTags = pack('Environment', '', 'Owner', '', 'CostCenter', '');
Resources
| where 
    (isempty(tags['Environment']) or tags['Environment'] == '') or
    (isempty(tags['Owner']) or tags['Owner'] == '') or
    (isempty(tags['CostCenter']) or tags['CostCenter'] == '')
| project name, type, resourceGroup, tags
| sort by name asc
```

**Use case:** Find non-compliant resources missing required tags

---

### 17. High-Risk: Resources with Overly Permissive Tags

```kusto
Resources
| where tags['Access'] == 'Public' or tags['Access'] == 'Everyone'
| project name, type, location, resourceGroup, tags['Access']
```

**Use case:** Security audit - find overly permissive access tags

---

## Advanced Queries

### 18. Tag Compliance Scoring

```kusto
Resources
| extend 
    hasEnvironment = iff(isnotempty(tags['Environment']), 1, 0),
    hasOwner = iff(isnotempty(tags['Owner']), 1, 0),
    hasCostCenter = iff(isnotempty(tags['CostCenter']), 1, 0),
    ComplianceScore = (hasEnvironment + hasOwner + hasCostCenter) * 100 / 3
| project name, type, ComplianceScore
| summarize 
    AverageCompliance = avg(ComplianceScore),
    FullyCompliant = countif(ComplianceScore == 100),
    PartiallyCompliant = countif(ComplianceScore > 0 and ComplianceScore < 100),
    NonCompliant = countif(ComplianceScore == 0)
```

**Use case:** Generate compliance metrics across all resources

---

### 19. Resources Created in Last 30 Days

```kusto
Resources
| where tostring(tags['CreatedDate']) > tostring(now(-30d))
| project 
    name, 
    type, 
    resourceGroup, 
    CreatedDate = tags['CreatedDate'],
    CreatedBy = tags['CreatedBy']
| sort by CreatedDate desc
```

**Use case:** Monitor new resource creation for governance

---

### 20. Tag Value Statistics

```kusto
Resources
| project Environment = tags['Environment']
| where isnotempty(Environment)
| summarize 
    Total = count(),
    UniqueValues = dcount(Environment),
    Values = make_set(Environment)
by Environment
```

**Use case:** Understand tag value usage patterns

---

## PowerShell Integration Examples

### Run Query and Export to CSV

```powershell
$query = @"
Resources
| where tags['Environment'] == 'Production'
| project name, type, resourceGroup, location
"@

$results = Search-AzGraph -Query $query
$results | Export-Csv -Path "c:\exports\production-resources.csv" -NoTypeInformation
```

### Query All Delegated Subscriptions

```powershell
# First, get all delegated subscriptions
$delegated = Get-AzManagedServicesAssignment

# For each delegation, run a resource graph query
foreach ($assignment in $delegated) {
    $subscriptionId = $assignment.Properties.SourceSubscriptionId
    
    $query = @"
    Resources
    | where subscriptionId == '$subscriptionId'
    | where tags['Environment'] == 'Production'
    | project name, type, resourceGroup
    "@
    
    Write-Host "Resources in $subscriptionId:"
    Search-AzGraph -Query $query
}
```

### Create Custom Function

```powershell
function Get-ResourcesByTag {
    param(
        [string]$TagKey,
        [string]$TagValue
    )
    
    $query = @"
    Resources
    | where tags['$TagKey'] == '$TagValue'
    | project name, type, resourceGroup, subscriptionId
    "@
    
    Search-AzGraph -Query $query
}

# Usage:
Get-ResourcesByTag -TagKey "Environment" -TagValue "Production" | Export-Csv -Path "prod-resources.csv"
```

---

## Tag Naming Conventions (Recommended)

For best results with these queries, use consistent tagging:

| Tag Key | Values | Example | Purpose |
|---------|--------|---------|---------|
| `Environment` | Production, Staging, Development, Test | Production | Classify workload tier |
| `Owner` | User UPN or team name | john@contoso.com | Identify responsibility |
| `CostCenter` | Cost center code | 12345 | Allocate costs |
| `Application` | App name | WebApp-Sales | Group by application |
| `Department` | Department name | Finance | Organizational grouping |
| `CreatedDate` | ISO date format | 2026-10-20 | Track age |
| `LastReviewDate` | ISO date format | 2026-10-15 | Compliance tracking |
| `Access` | Public, Internal, Private | Private | Security classification |
| `BackupRequired` | Yes, No | Yes | Operational requirement |

---

## Tips for Effective Queries

1. **Use consistent tag names** - Avoid `env` vs `Environment` confusion
2. **Filter early** - Add `where` clauses before `project` for performance
3. **Use summarize** - Get counts and aggregations with `summarize`
4. **Sort results** - Add `sort by` for readability
5. **Export regularly** - Use queries for compliance/audit trails
6. **Combine with PowerShell** - Automate queries for scheduled reports

---

## Troubleshooting

### "Query limit exceeded"
- Reduce time range or add more specific filters
- Limit results with `| limit 10000`

### "Empty results"
- Check tag name spelling (case-sensitive: `tags['Environment']` not `tags['environment']`)
- Verify tag exists with simpler query: `Resources | where tags has 'Environment'`

### "Slow query"
- Add more `where` filters to narrow scope
- Use `project` to select only needed columns
- Filter by subscriptionId or resourceGroup first

---

## Resources

- **Azure Resource Graph Docs:** https://learn.microsoft.com/azure/governance/resource-graph/overview
- **KQL Quick Reference:** https://learn.microsoft.com/azure/data-explorer/kql-quick-reference
- **Resource Graph Explorer:** Search "Resource Graph Explorer" in Azure Portal
- **Graph Samples:** https://learn.microsoft.com/azure/governance/resource-graph/samples/

---

## Next Steps

1. **Customize tag names** - Update queries to match your tagging strategy
2. **Test in Portal** - Run queries in Resource Graph Explorer first
3. **Create scheduled reports** - Use PowerShell + Azure Automation
4. **Integrate with dashboards** - Send results to Power BI or Excel
5. **Combine with policies** - Use with Azure Policy for remediation

---

**Status:** Production-ready  
**Last Updated:** 2026-10-20  
**Compatibility:** All Azure subscriptions in Lighthouse delegations
