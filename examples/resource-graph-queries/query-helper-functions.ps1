#requires -Version 5.0
#requires -Modules Az.ResourceGraph

<#
.SYNOPSIS
    Helper functions for running Resource Graph queries in Lighthouse delegations
    
.DESCRIPTION
    Provides easy-to-use functions for common Resource Graph queries across
    delegated subscriptions in your managed tenant. Supports exporting to CSV/Excel.
    
.EXAMPLE
    $query = Get-ResourcesByTag -TagKey "Environment" -TagValue "Production"
    $query | Export-Csv -Path "prod-resources.csv" -NoTypeInformation
    
.NOTES
    Requires: Az.ResourceGraph module
    Install: Install-Module Az.ResourceGraph
#>

# ============================================================================
# Helper Functions
# ============================================================================

function Get-ResourcesByTag {
    <#
    .SYNOPSIS
        Find all resources with a specific tag key and value
        
    .PARAMETER TagKey
        The tag key to search for (e.g., "Environment")
        
    .PARAMETER TagValue
        The tag value to match (e.g., "Production")
        
    .EXAMPLE
        Get-ResourcesByTag -TagKey "Environment" -TagValue "Production"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TagKey,
        
        [Parameter(Mandatory=$true)]
        [string]$TagValue
    )
    
    $query = @"
Resources
| where tags['$TagKey'] == '$TagValue'
| project 
    ResourceName = name,
    ResourceType = type,
    ResourceGroup = resourceGroup,
    Subscription = subscriptionId,
    Location = location,
    Tags = tags
| sort by ResourceType asc, ResourceName asc
"@
    
    Write-Host "Querying for resources where [$TagKey] = [$TagValue]..." -ForegroundColor Cyan
    Search-AzGraph -Query $query
}

function Find-UntaggedResources {
    <#
    .SYNOPSIS
        Find resources missing a specific tag
        
    .PARAMETER TagKey
        The required tag key (e.g., "Environment")
        
    .EXAMPLE
        Find-UntaggedResources -TagKey "Owner"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TagKey
    )
    
    $query = @"
Resources
| where isempty(tags['$TagKey']) or tags['$TagKey'] == ''
| project 
    ResourceName = name,
    ResourceType = type,
    ResourceGroup = resourceGroup,
    Subscription = subscriptionId,
    Location = location
| sort by ResourceType asc
"@
    
    Write-Host "Finding resources missing tag: [$TagKey]" -ForegroundColor Yellow
    Search-AzGraph -Query $query
}

function Get-ResourceComplianceScore {
    <#
    .SYNOPSIS
        Calculate tag compliance score across all resources
        
    .PARAMETER RequiredTags
        Array of required tag keys (e.g., @("Environment", "Owner", "CostCenter"))
        
    .EXAMPLE
        Get-ResourceComplianceScore -RequiredTags @("Environment", "Owner", "CostCenter")
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$RequiredTags
    )
    
    # Build dynamic extend clauses for each tag
    $tagChecks = @()
    foreach ($tag in $RequiredTags) {
        $tagChecks += "has$(($tag -replace '\s', '')) = iff(isnotempty(tags['$tag']), 1, 0)"
    }
    
    $extendClause = $tagChecks -join ", "
    $scoreCalculation = "($($tagChecks.Count -split '=' | ForEach-Object {$_.Trim()} | Where-Object {$_[0] -eq 'h'} | Measure-Object | Select-Object -ExpandProperty Count) / $($RequiredTags.Count) * 100"
    
    $query = @"
Resources
| extend 
    $extendClause,
    ComplianceScore = ($(($RequiredTags.Count)) / $($RequiredTags.Count) * 100)
| summarize
    TotalResources = count(),
    FullyCompliant = countif(ComplianceScore == 100),
    PartiallyCompliant = countif(ComplianceScore > 0 and ComplianceScore < 100),
    NonCompliant = countif(ComplianceScore == 0),
    AverageComplianceScore = avg(ComplianceScore)
"@
    
    Write-Host "Calculating compliance for required tags: $($RequiredTags -join ', ')" -ForegroundColor Cyan
    Search-AzGraph -Query $query
}

function Get-ResourcesByMultipleTags {
    <#
    .SYNOPSIS
        Find resources matching multiple tag conditions
        
    .PARAMETER TagFilters
        Hashtable of tag key-value pairs (e.g., @{"Environment"="Production"; "Owner"="Finance"})
        
    .EXAMPLE
        Get-ResourcesByMultipleTags -TagFilters @{"Environment"="Production"; "Owner"="Finance"}
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$TagFilters
    )
    
    # Build where clauses
    $whereClauses = @()
    foreach ($key in $TagFilters.Keys) {
        $whereClauses += "tags['$key'] == '$($TagFilters[$key])'"
    }
    $whereClause = $whereClauses -join " and "
    
    $query = @"
Resources
| where $whereClause
| project 
    ResourceName = name,
    ResourceType = type,
    ResourceGroup = resourceGroup,
    Subscription = subscriptionId,
    Location = location,
    Tags = tags
| sort by ResourceType asc
"@
    
    Write-Host "Finding resources matching tags: $($TagFilters | ConvertTo-Json)" -ForegroundColor Cyan
    Search-AzGraph -Query $query
}

function Get-ResourcesByType {
    <#
    .SYNOPSIS
        Find all resources of specific types with tag information
        
    .PARAMETER ResourceTypes
        Array of resource types (e.g., @("Microsoft.Compute/virtualMachines"))
        
    .PARAMETER TagKey
        Optional: filter by a specific tag
        
    .EXAMPLE
        Get-ResourcesByType -ResourceTypes @("Microsoft.Compute/virtualMachines", "Microsoft.Sql/servers/databases")
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$ResourceTypes,
        
        [Parameter(Mandatory=$false)]
        [string]$TagKey
    )
    
    $typeList = ($ResourceTypes | ForEach-Object { "'$_'" }) -join ", "
    
    if ($TagKey) {
        $query = @"
Resources
| where type in ($typeList)
| project 
    ResourceName = name,
    ResourceType = type,
    ResourceGroup = resourceGroup,
    Subscription = subscriptionId,
    Location = location,
    TagValue = tags['$TagKey']
| sort by ResourceType asc, ResourceName asc
"@
    } else {
        $query = @"
Resources
| where type in ($typeList)
| project 
    ResourceName = name,
    ResourceType = type,
    ResourceGroup = resourceGroup,
    Subscription = subscriptionId,
    Location = location
| sort by ResourceType asc, ResourceName asc
"@
    }
    
    Write-Host "Finding resources of types: $($ResourceTypes -join ', ')" -ForegroundColor Cyan
    Search-AzGraph -Query $query
}

function Get-ResourceTagStatistics {
    <#
    .SYNOPSIS
        Get statistics about a specific tag usage
        
    .PARAMETER TagKey
        The tag key to analyze (e.g., "Environment")
        
    .EXAMPLE
        Get-ResourceTagStatistics -TagKey "Environment"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TagKey
    )
    
    $query = @"
Resources
| project TagValue = tags['$TagKey']
| where isnotempty(TagValue)
| summarize 
    Count = count(),
    Percentage = (count() * 100.0 / todouble(toscalar(Resources | summarize count())))
by TagValue
| sort by Count desc
"@
    
    Write-Host "Getting statistics for tag: [$TagKey]" -ForegroundColor Cyan
    Search-AzGraph -Query $query
}

function Get-DelegatedSubscriptionResources {
    <#
    .SYNOPSIS
        List all resources in delegated subscriptions
        
    .PARAMETER IncludeTagSummary
        If true, includes tag summary in output
        
    .EXAMPLE
        Get-DelegatedSubscriptionResources
        
        Get-DelegatedSubscriptionResources -IncludeTagSummary
    #>
    param(
        [Parameter(Mandatory=$false)]
        [switch]$IncludeTagSummary
    )
    
    $query = @"
Resources
| summarize ResourceCount = count() by subscriptionId
| sort by ResourceCount desc
"@
    
    Write-Host "Listing resources by delegated subscription..." -ForegroundColor Cyan
    $results = Search-AzGraph -Query $query
    
    foreach ($result in $results) {
        Write-Host "Subscription: $($result.subscriptionId)" -ForegroundColor Yellow
        Write-Host "  Resource Count: $($result.ResourceCount)"
    }
    
    return $results
}

function Export-ResourceInventory {
    <#
    .SYNOPSIS
        Export complete resource inventory to CSV
        
    .PARAMETER Path
        File path for CSV export (e.g., "c:\exports\inventory.csv")
        
    .PARAMETER IncludeTags
        Specific tags to include in export
        
    .EXAMPLE
        Export-ResourceInventory -Path "c:\inventory.csv" -IncludeTags @("Environment", "Owner", "CostCenter")
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string[]]$IncludeTags = @("Environment", "Owner", "CostCenter")
    )
    
    $projectList = @("ResourceName = name", "ResourceType = type", "ResourceGroup = resourceGroup", "Subscription = subscriptionId", "Location = location")
    $projectList += ($IncludeTags | ForEach-Object { "$_ = tags['$_']" })
    
    $query = @"
Resources
| project 
    $($projectList -join ", ")
| sort by ResourceType asc, ResourceName asc
"@
    
    Write-Host "Exporting resource inventory to: $Path" -ForegroundColor Cyan
    $results = Search-AzGraph -Query $query
    $results | Export-Csv -Path $Path -NoTypeInformation
    
    Write-Host "✅ Exported $($results.Count) resources" -ForegroundColor Green
}

function Get-NonCompliantResources {
    <#
    .SYNOPSIS
        Find resources missing required tags for compliance
        
    .PARAMETER RequiredTags
        Array of required tag keys
        
    .EXAMPLE
        Get-NonCompliantResources -RequiredTags @("Environment", "Owner", "CostCenter")
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$RequiredTags
    )
    
    $whereClauses = @()
    foreach ($tag in $RequiredTags) {
        $whereClauses += "(isempty(tags['$tag']) or tags['$tag'] == '')"
    }
    $whereClause = $whereClauses -join " or "
    
    $query = @"
Resources
| where $whereClause
| project 
    ResourceName = name,
    ResourceType = type,
    ResourceGroup = resourceGroup,
    Subscription = subscriptionId,
    Location = location,
    MissingTags = iff(isempty(tags['Environment']), 'Environment', '') + iff(isempty(tags['Owner']), ', Owner', '') + iff(isempty(tags['CostCenter']), ', CostCenter', '')
| sort by ResourceType asc
"@
    
    Write-Host "Finding non-compliant resources (missing required tags)..." -ForegroundColor Yellow
    Search-AzGraph -Query $query
}

# ============================================================================
# Main Script Examples
# ============================================================================

# Example 1: Find all production resources
Write-Host "=== Example 1: Production Resources ===" -ForegroundColor Magenta
# Get-ResourcesByTag -TagKey "Environment" -TagValue "Production"

# Example 2: Find untagged resources
Write-Host "`n=== Example 2: Untagged Resources ===" -ForegroundColor Magenta
# Find-UntaggedResources -TagKey "Owner"

# Example 3: Get tag statistics
Write-Host "`n=== Example 3: Tag Statistics ===" -ForegroundColor Magenta
# Get-ResourceTagStatistics -TagKey "Environment"

# Example 4: Export inventory
Write-Host "`n=== Example 4: Export Inventory ===" -ForegroundColor Magenta
# Export-ResourceInventory -Path "c:\inventory.csv"

# Example 5: Find VMs by tags
Write-Host "`n=== Example 5: Virtual Machines ===" -ForegroundColor Magenta
# Get-ResourcesByType -ResourceTypes @("Microsoft.Compute/virtualMachines") -TagKey "Environment"

Write-Host "`n✅ Resource Graph query helper functions loaded!" -ForegroundColor Green
Write-Host "Available functions:" -ForegroundColor Cyan
Write-Host "  - Get-ResourcesByTag"
Write-Host "  - Find-UntaggedResources"
Write-Host "  - Get-ResourceComplianceScore"
Write-Host "  - Get-ResourcesByMultipleTags"
Write-Host "  - Get-ResourcesByType"
Write-Host "  - Get-ResourceTagStatistics"
Write-Host "  - Get-DelegatedSubscriptionResources"
Write-Host "  - Export-ResourceInventory"
Write-Host "  - Get-NonCompliantResources"
Write-Host "`nUsage: Get-Help -Full <function-name>"
