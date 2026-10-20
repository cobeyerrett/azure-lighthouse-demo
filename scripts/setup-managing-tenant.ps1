#Requires -Version 5.1
#Requires -Modules Az.Accounts, Az.ManagedServiceIdentity

<#
.SYNOPSIS
    Prepares a managing tenant (service provider) for Azure Lighthouse delegations.

.DESCRIPTION
    This script assists with preparing the managing tenant by:
    - Signing in to the managing tenant
    - Listing available users, groups, and service principals
    - Extracting principal IDs needed for Lighthouse delegation templates
    - Creating a reference file for template customization

.PARAMETER TenantId
    The tenant ID of the managing tenant (service provider)

.PARAMETER OutputFile
    Path to save principal IDs reference file (default: principals-managing-tenant.json)

.EXAMPLE
    .\setup-managing-tenant.ps1 -TenantId "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

.NOTES
    Run this from the managing tenant with Owner role.
    Requires: Az.Accounts module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Tenant ID of the managing tenant")]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [string]$OutputFile = "principals-managing-tenant.json"
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

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Get-PrincipalInfo {
    param([object]$Principal)
    
    return @{
        Id            = $Principal.Id
        DisplayName   = $Principal.DisplayName
        Type          = $Principal.GetType().Name
        UserPrincipalName = $Principal.UserPrincipalName
        AppId         = $Principal.AppId
    }
}
#endregion

try {
    Write-Header "Azure Lighthouse - Managing Tenant Setup"

    # Connect to managing tenant
    Write-Host "`nConnecting to managing tenant..." -ForegroundColor Yellow
    $context = Connect-AzAccount -TenantId $TenantId -ErrorAction Stop
    Write-Success "Connected to tenant: $($context.Context.Tenant.DisplayName) ($($context.Context.Tenant.Id))"

    # Verify we're in the right tenant
    if ($context.Context.Tenant.Id -ne $TenantId) {
        throw "Connected to different tenant than specified. Expected: $TenantId, Got: $($context.Context.Tenant.Id)"
    }

    # Get current user info
    Write-Header "Current Account Information"
    $currentUser = Get-AzContext
    Write-Host "User: $($currentUser.Account.Id)"
    Write-Host "Tenant: $($currentUser.Tenant.DisplayName)"
    Write-Host "Subscription: $($currentUser.Subscription.Name)" -ForegroundColor Yellow

    # Collect principals
    $principals = @{
        users                = @()
        groups               = @()
        servicePrincipals    = @()
        collectionTimestamp  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Get users
    Write-Header "Collecting Users"
    Write-Host "Retrieving users from tenant..." -ForegroundColor Yellow
    $users = Get-AzADUser -First 100
    Write-Success "Found $($users.Count) users"
    
    foreach ($user in $users) {
        $principals.users += @{
            Id                    = $user.Id
            DisplayName           = $user.DisplayName
            UserPrincipalName     = $user.UserPrincipalName
            Mail                  = $user.Mail
            ObjectType            = "User"
        }
    }

    # Display users
    Write-Host "`nTop 10 Users:" -ForegroundColor Cyan
    $users | Select-Object -First 10 @{Name="Id"; Expression={$_.Id}}, DisplayName, UserPrincipalName | Format-Table

    # Get groups
    Write-Header "Collecting Groups"
    Write-Host "Retrieving groups from tenant..." -ForegroundColor Yellow
    $groups = Get-AzADGroup -First 100
    Write-Success "Found $($groups.Count) groups"
    
    foreach ($group in $groups) {
        $principals.groups += @{
            Id          = $group.Id
            DisplayName = $group.DisplayName
            Mail        = $group.Mail
            ObjectType  = "Group"
        }
    }

    # Display groups
    Write-Host "`nTop 10 Groups:" -ForegroundColor Cyan
    $groups | Select-Object -First 10 @{Name="Id"; Expression={$_.Id}}, DisplayName, Mail | Format-Table

    # Get service principals
    Write-Header "Collecting Service Principals"
    Write-Host "Retrieving service principals from tenant..." -ForegroundColor Yellow
    $sps = Get-AzADServicePrincipal -First 100
    Write-Success "Found $($sps.Count) service principals"
    
    foreach ($sp in $sps) {
        $principals.servicePrincipals += @{
            Id          = $sp.Id
            DisplayName = $sp.DisplayName
            AppId       = $sp.AppId
            ObjectType  = "ServicePrincipal"
        }
    }

    # Display service principals
    Write-Host "`nTop 10 Service Principals:" -ForegroundColor Cyan
    $sps | Select-Object -First 10 @{Name="Id"; Expression={$_.Id}}, DisplayName, AppId | Format-Table

    # Save to file
    Write-Header "Saving Principal Reference"
    $principals | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputFile -Force
    Write-Success "Principals saved to: $(Get-Item $OutputFile | Select-Object -ExpandProperty FullName)"

    # Display summary
    Write-Header "Summary"
    Write-Host "Total Users: $($principals.users.Count)"
    Write-Host "Total Groups: $($principals.groups.Count)"
    Write-Host "Total Service Principals: $($principals.servicePrincipals.Count)"
    Write-Host "`nNext Steps:"
    Write-Host "1. Open $OutputFile to find the principal ID you want to use"
    Write-Host "2. Copy the principal ID (Id field)"
    Write-Host "3. Update templates/delegationTemplate.json with this ID"
    Write-Host "4. Run setup-customer-tenant.ps1 on the customer subscription"
    Write-Host "5. Deploy the template to complete delegation"

    Write-Success "`nManaging tenant setup complete!"

}
catch {
    Write-Error-Custom "Error: $_"
    exit 1
}
