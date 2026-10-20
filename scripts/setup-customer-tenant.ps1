#Requires -Version 5.1
#Requires -Modules Az.Accounts, Az.Resources

<#
.SYNOPSIS
    Prepares a customer tenant to receive Azure Lighthouse delegations.

.DESCRIPTION
    This script prepares the customer tenant by:
    - Signing in to the customer tenant
    - Registering Microsoft.ManagedServices resource provider
    - Verifying the subscription is ready for delegation
    - Providing next steps for template deployment

.PARAMETER TenantId
    The tenant ID of the customer tenant

.PARAMETER SubscriptionId
    The subscription ID to prepare for delegation

.EXAMPLE
    .\setup-customer-tenant.ps1 -TenantId "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" `
        -SubscriptionId "11111111-2222-3333-4444-555555555555"

.NOTES
    Run this from the customer tenant with Owner role on the subscription.
    Requires: Az.Accounts, Az.Resources modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Tenant ID of the customer tenant")]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$TenantId,

    [Parameter(Mandatory = $true, HelpMessage = "Subscription ID to prepare")]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$SubscriptionId
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
#endregion

try {
    Write-Header "Azure Lighthouse - Customer Tenant Setup"

    # Connect to customer tenant
    Write-Host "`nConnecting to customer tenant..." -ForegroundColor Yellow
    $context = Connect-AzAccount -TenantId $TenantId -SubscriptionId $SubscriptionId -ErrorAction Stop
    Write-Success "Connected to tenant: $($context.Context.Tenant.DisplayName)"

    # Verify connection
    if ($context.Context.Tenant.Id -ne $TenantId) {
        throw "Connected to different tenant. Expected: $TenantId, Got: $($context.Context.Tenant.Id)"
    }

    # Display subscription info
    Write-Header "Subscription Information"
    $sub = Get-AzSubscription -SubscriptionId $SubscriptionId
    Write-Host "Subscription Name: $($sub.Name)"
    Write-Host "Subscription ID: $($sub.SubscriptionId)"
    Write-Host "Tenant ID: $($sub.TenantId)"
    Write-Host "State: $($sub.State)"

    # Verify Owner role
    Write-Header "Verifying Permissions"
    $assignments = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId"
    $currentUser = Get-AzContext
    $userAssignments = $assignments | Where-Object { $_.ObjectId -eq (Get-AzADUser -UserPrincipalName $currentUser.Account.Id | Select-Object -ExpandProperty Id) -or $_.ObjectId -eq $currentUser.Account.ObjectId }
    
    if ($userAssignments | Where-Object { $_.RoleDefinitionName -eq "Owner" }) {
        Write-Success "Owner role verified"
    }
    else {
        Write-Warning-Custom "Could not verify Owner role. Continuing, but operations may fail..."
    }

    # Register resource provider
    Write-Header "Registering Microsoft.ManagedServices Provider"
    Write-Host "Current registration state..." -ForegroundColor Yellow
    
    $provider = Get-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"
    Write-Host "Registration State: $($provider.RegistrationState)"

    if ($provider.RegistrationState -ne "Registered") {
        Write-Host "Registering provider..." -ForegroundColor Yellow
        $null = Register-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"
        
        # Wait for registration
        $maxAttempts = 12
        $attempt = 0
        $registered = $false
        
        do {
            Start-Sleep -Seconds 5
            $provider = Get-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"
            $attempt++
            Write-Host "Check $attempt/$maxAttempts - State: $($provider.RegistrationState)" -ForegroundColor Yellow
            
            if ($provider.RegistrationState -eq "Registered") {
                $registered = $true
                break
            }
        } while ($attempt -lt $maxAttempts)

        if ($registered) {
            Write-Success "Microsoft.ManagedServices provider registered"
        }
        else {
            Write-Error-Custom "Provider registration timed out. Try again in a few moments."
            exit 1
        }
    }
    else {
        Write-Success "Microsoft.ManagedServices provider already registered"
    }

    # Verify subscription ready
    Write-Header "Verifying Subscription Readiness"
    
    $checks = @(
        @{ Name = "Subscription accessible"; Check = { $null -ne (Get-AzSubscription -SubscriptionId $SubscriptionId) } }
        @{ Name = "Resource provider registered"; Check = { (Get-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices").RegistrationState -eq "Registered" } }
        @{ Name = "Owner role available"; Check = { $null -ne ($assignments | Where-Object { $_.RoleDefinitionName -eq "Owner" }) } }
    )

    foreach ($check in $checks) {
        try {
            if (& $check.Check) {
                Write-Success $check.Name
            }
            else {
                Write-Warning-Custom $check.Name
            }
        }
        catch {
            Write-Error-Custom "$($check.Name): $_"
        }
    }

    # Display next steps
    Write-Header "Next Steps"
    Write-Host @"
1. In your MANAGING TENANT:
   - Edit templates/delegationTemplate.json
   - Replace managedByTenantId with: $TenantId
   - Replace principalId with the ID of user/group/SP from managing tenant

2. In your CUSTOMER TENANT (this one):
   - Go to Azure Portal
   - Search for "Deployments"
   - Click "Deploy a custom template"
   - Upload or paste templates/delegationTemplate.json
   - Provide the subscription ID: $SubscriptionId

3. Monitor deployment status

4. Verify in managing tenant:
   - Azure Lighthouse > Customers > Delegations
   - Should see this subscription listed

5. To complete verification:
   - Run: .\scripts\verify-delegation.ps1 -SubscriptionId $SubscriptionId
"@

    Write-Success "`nCustomer tenant setup complete!"
    Write-Host "`nSubscription is ready for Lighthouse delegation.`n" -ForegroundColor Green

}
catch {
    Write-Error-Custom "Setup failed: $_"
    Write-Host "`nTroubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Verify you have Owner role on the subscription"
    Write-Host "2. Verify tenant ID and subscription ID are correct"
    Write-Host "3. Try running: Register-AzResourceProvider -ProviderNamespace 'Microsoft.ManagedServices'"
    Write-Host "4. Wait 5-10 minutes and try again"
    exit 1
}
