# Resource Graph Queries - Quick Reference Card

## Basic Usage in Azure Portal

1. Open **Resource Graph Explorer** (search in portal)
2. Copy a query below → Paste → Click **Run query**
3. Click **Export** to save as CSV/Excel

---

## 🎯 Most Common Queries

### Find Production Resources
```kusto
Resources
| where tags['Environment'] == 'Production'
| project name, type, location, resourceGroup
```

### Find Untagged Resources
```kusto
Resources
| where isempty(tags['Owner'])
| project name, type, resourceGroup
```

### Count Resources by Environment
```kusto
Resources
| summarize Count = count() by tostring(tags['Environment'])
```

### All VMs by Owner
```kusto
Resources
| where type == 'Microsoft.Compute/virtualMachines'
| project name, Owner = tags['Owner'], resourceGroup, location
```

### Resources by Cost Center
```kusto
Resources
| project name, type, CostCenter = tags['CostCenter']
| summarize Count = count() by CostCenter
| sort by Count desc
```

---

## 💻 PowerShell Quick Start

### Load Helper Functions
```powershell
# Source the helper functions
. .\examples\resource-graph-queries\query-helper-functions.ps1

# Now you can run functions:
Get-ResourcesByTag -TagKey "Environment" -TagValue "Production"
```

### Find by Tag
```powershell
Get-ResourcesByTag -TagKey "Environment" -TagValue "Production"
```

### Find Untagged
```powershell
Find-UntaggedResources -TagKey "Owner"
```

### Export to CSV
```powershell
Export-ResourceInventory -Path "c:\resources.csv" `
    -IncludeTags @("Environment", "Owner", "CostCenter")
```

### Get Compliance Score
```powershell
Get-ResourceComplianceScore -RequiredTags @("Environment", "Owner", "CostCenter")
```

### Find Non-Compliant
```powershell
Get-NonCompliantResources -RequiredTags @("Environment", "Owner", "CostCenter")
```

---

## 🏷️ Tag Strategy Example

| Tag | Values | Used For |
|-----|--------|----------|
| Environment | Production, Staging, Dev, Test | Workload tier |
| Owner | user@company.com | Responsibility |
| CostCenter | 12345 | Cost allocation |
| Application | MyApp | Resource grouping |
| Department | Finance | Organizational unit |
| BackupRequired | Yes/No | Operational need |

---

## 📊 Key Query Patterns

### Pattern: Match Specific Value
```kusto
Resources
| where tags['TagName'] == 'Value'
```

### Pattern: Find Empty Tag
```kusto
Resources
| where isempty(tags['TagName'])
```

### Pattern: Multiple Conditions
```kusto
Resources
| where tags['Environment'] == 'Production'
   and tags['Owner'] == 'Finance'
```

### Pattern: Summarize Count
```kusto
Resources
| summarize Count = count() by tostring(tags['Environment'])
```

### Pattern: Sort Results
```kusto
Resources
| sort by name asc    # Ascending
| sort by name desc   # Descending
```

---

## 🔗 Go Deeper

- **Full KQL Guide:** [examples/resource-graph-queries/README.md](README.md)
- **20 Complete Queries:** See queries 1-20 in full guide
- **Helper Functions:** [query-helper-functions.ps1](query-helper-functions.ps1)
- **Microsoft Docs:** https://learn.microsoft.com/azure/governance/resource-graph/

---

## ⚡ Pro Tips

1. **Start simple** - Test with small queries first
2. **Filter early** - Add `where` before `project` for speed
3. **Use summarize** - Get counts without exporting all rows
4. **Export regularly** - CSV export is great for reports/audits
5. **Consistent tags** - Use same tag names everywhere
6. **Schedule queries** - Use Azure Automation for daily reports

---

**Status:** Production-ready | **Last Updated:** 2026-10-20
