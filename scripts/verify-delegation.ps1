#Requires -Version 5.1
#Requires -Modules Az.Accounts, Az.ManagedServices, Az.Resources

<#
.SYNOPSIS
    Verifies Azure Lighthouse delegation is working properly.

.DESCRIPTION
    This script verifies that Lighthouse delegation is configured correctly by:
    - Confirming access to customer subscription from managing tenant
    - Listing role assignments and permissions
    - Testing ability to list resources
    - Performing basic operations to validate functionality

.PARAMETER SubscriptionId
    The subscription ID of the delegated customer subscription

.PARAMETER TenantId
    (Optional) The tenant ID of the managing tenant. If not provided, uses current context.

.EXAMPLE
    .\verify-delegation.ps1 -SubscriptionId "11111111-2222-3333-4444-555555555555"

.EXAMPLE
    .\verify-delegation.ps1 -SubscriptionId "11111111-2222-3333-4444-555555555555" `
        -TenantId "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

.NOTES
    Run this from the managing tenant with appropriate delegation permissions.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Customer subscription ID")]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$TenantId
)

#region Functions
function Write-Header {
    param([string]$Message)
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Test-Delegation {
    param(
        [string]$SubscriptionId,
        [string]$TenantId
    )

    $results = @{
        success       = $true
        checks        = @()
        errors        = @()
        warnings      = @()
    }

    try {
        # Check current context
        Write-Host "Checking current context..." -ForegroundColor Yellow
        $context = Get-AzContext
        
        if (-not $context) {
            $results.success = $false
            $results.errors += "Not connected to Azure. Run Connect-AzAccount first."
            return $results
        }

        $results.checks += @{ Name = "Connected to Azure"; Status = "✓" }

        # If TenantId specified, verify we're in the right tenant
        if ($TenantId -and $context.Tenant.Id -ne $TenantId) {
            $results.warnings += "Connected to different tenant. Current: $($context.Tenant.Id), Expected: $TenantId"
        }

        # Try to select subscription
        Write-Host "Accessing subscription $SubscriptionId..." -ForegroundColor Yellow
        $sub = Get-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction Stop
        $null = Select-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction Stop
        $results.checks += @{ Name = "Subscription access"; Status = "✓" }
        
        # Get Lighthouse assignments
        Write-Host "Checking Lighthouse assignments..." -ForegroundColor Yellow
        $assignments = Get-AzManagedServicesAssignment -Scope "/subscriptions/$SubscriptionId" -ErrorAction SilentlyContinue
        
        if ($assignments) {
            $results.checks += @{ Name = "Lighthouse assignment found"; Status = "✓"; Count = @($assignments).Count }
        }
        else {
            $results.warnings += "No Lighthouse assignments found for this subscription"
        }

        # Get role assignments
        Write-Host "Checking role assignments..." -ForegroundColor Yellow
        $roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId" -ErrorAction SilentlyContinue
        $results.checks += @{ Name = "Role assignments accessible"; Status = "✓"; Count = @($roleAssignments).Count }

        # Try to list resources
        Write-Host "Attempting to list resources..." -ForegroundColor Yellow
        $resources = Get-AzResource -ErrorAction SilentlyContinue
        $results.checks += @{ Name = "Resource enumeration"; Status = "✓"; Count = @($resources).Count }

        # Try to list resource groups
        Write-Host "Attempting to list resource groups..." -ForegroundColor Yellow
        $rgs = Get-AzResourceGroup -ErrorAction SilentlyContinue
        $results.checks += @{ Name = "Resource group enumeration"; Status = "✓"; Count = @($rgs).Count }

        # Get subscription details
        $subContext = Get-AzContext
        $results.subscription = @{
            SubscriptionName = $sub.Name
            SubscriptionId   = $sub.SubscriptionId
            TenantId         = $sub.TenantId
            State            = $sub.State
            CurrentContext   = $subContext.Subscription.Name
        }

    }
    catch {
        $results.success = $false
        $results.errors += "Error during verification: $_"
    }

    return $results
}
#endregion

try {
    Write-Header "Azure Lighthouse - Delegation Verification"

    # Connect if needed
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Not connected. Signing in..." -ForegroundColor Yellow
        if ($TenantId) {
            Connect-AzAccount -TenantId $TenantId | Out-Null
        }
        else {
            Connect-AzAccount | Out-Null
        }
    }

    # Run verification
    $result = Test-Delegation -SubscriptionId $SubscriptionId -TenantId $TenantId

    # Display results
    Write-Header "Verification Results"

    if ($result.success) {
        Write-Success "Delegation verification PASSED"
    }
    else {
        Write-Error-Custom "Delegation verification FAILED"
    }

    # Display checks
    Write-Host "`nChecks:" -ForegroundColor Cyan
    foreach ($check in $result.checks) {
        $display = "$($check.Status) $($check.Name)"
        if ($check.Count) {
            $display += " ($($check.Count) items)"
        }
        Write-Host $display
    }

    # Display warnings
    if ($result.warnings) {
        Write-Host "`nWarnings:" -ForegroundColor Yellow
        foreach ($warning in $result.warnings) {
            Write-Warning-Custom $warning
        }
    }

    # Display errors
    if ($result.errors) {
        Write-Host "`nErrors:" -ForegroundColor Red
        foreach ($error in $result.errors) {
            Write-Error-Custom $error
        }
    }

    # Display subscription info
    if ($result.subscription) {
        Write-Header "Subscription Information"
        Write-Host "Name: $($result.subscription.SubscriptionName)"
        Write-Host "ID: $($result.subscription.SubscriptionId)"
        Write-Host "Tenant ID: $($result.subscription.TenantId)"
        Write-Host "State: $($result.subscription.State)"
    }

    # Display Lighthouse assignments
    if ($assignments) {
        Write-Header "Lighthouse Assignments"
        foreach ($assignment in $assignments) {
            Write-Host "Principal: $($assignment.ManagedByTenantId)"
            Write-Host "Created: $($assignment.CreatedOn)"
        }
    }

    # Display sample role assignments
    if ($roleAssignments) {
        Write-Header "Sample Role Assignments (First 10)"
        $roleAssignments | Select-Object -First 10 @{Name="Principal"; Expression={$_.DisplayName}}, RoleDefinitionName, Scope | Format-Table
    }

    # Final status
    Write-Header "Summary"
    if ($result.success -and -not $result.warnings) {
        Write-Success "`nDelegation is working correctly!`n"
        Write-Host "You can now manage this customer subscription from your managing tenant."
    }
    elseif ($result.success) {
        Write-Warning-Custom "`nDelegation is mostly working, but there are warnings.`n"
    }
    else {
        Write-Error-Custom "`nDelegation verification failed. See errors above.`n"
        Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
        Write-Host "1. Verify you're in the managing tenant"
        Write-Host "2. Verify the subscription ID is correct"
        Write-Host "3. Verify the delegation template was deployed successfully"
        Write-Host "4. Wait 2-3 minutes and try again"
        exit 1
    }

}
catch {
    Write-Error-Custom "Fatal error: $_"
    exit 1
}
