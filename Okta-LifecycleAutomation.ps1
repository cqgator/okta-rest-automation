<#
.SYNOPSIS
    Automates Okta user queries, dynamic group resolution, and lifecycle state changes via REST API.
.DESCRIPTION
    Interacts with Okta /api/v1 endpoints using native PowerShell 7 Invoke-RestMethod.
    Demonstrates identity querying, inherited group app scoping, and atomic deactivation.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$OktaDomain,

    [Parameter(Mandatory = $false)]
    [string]$ApiToken = $env:OKTA_API_TOKEN
)

if (-not $ApiToken) {
    $ApiToken = Read-Host -Prompt "Enter Okta SSWS API Token" -AsSecureString | 
                ConvertFrom-SecureString -AsPlainText
}

# Standardize Okta REST API headers
$Headers = @{
    "Authorization" = "SSWS $ApiToken"
    "Accept"        = "application/json"
    "Content-Type"  = "application/json"
}

Write-Host "[+] Querying users from $OktaDomain..." -ForegroundColor Cyan
$Users = Invoke-RestMethod -Uri "$OktaDomain/api/v1/users?limit=25" -Headers $Headers -Method Get
$Users | Select-Object id, status, 
    @{N='Login';E={$_.profile.login}}, 
    @{N='Email';E={$_.profile.email}}, 
    @{N='Department';E={$_.profile.department}} | Format-Table -AutoSize

Write-Host "[+] Locating 'Engineering-Access' group..." -ForegroundColor Cyan
$Groups = Invoke-RestMethod -Uri "$OktaDomain/api/v1/groups" -Headers $Headers -Method Get
$TargetGroup = $Groups | Where-Object { $_.profile.name -eq "Engineering-Access" }

if ($TargetGroup) {
    Write-Host "[+] Found group: $($TargetGroup.id) - Querying members resolved by Group Rules..." -ForegroundColor Cyan
    $Members = Invoke-RestMethod -Uri "$OktaDomain/api/v1/groups/$($TargetGroup.id)/users" -Headers $Headers -Method Get
    $Members | Select-Object id, @{N='Login';E={$_.profile.login}}, status | Format-Table -AutoSize
}

Write-Host "[+] Locating assigned applications..." -ForegroundColor Cyan
$Apps = Invoke-RestMethod -Uri "$OktaDomain/api/v1/apps" -Headers $Headers -Method Get
$App = $Apps | Where-Object { $_.label -like "*Web App*" -or $_.label -like "*Internal IT Portal*" }

if ($App) {
    Write-Host "[+] App found: $($App.label) ($($App.id))" -ForegroundColor Cyan
    Write-Host "[+] Querying effective user entitlements..." -ForegroundColor Cyan
    $AppUsers = Invoke-RestMethod -Uri "$OktaDomain/api/v1/apps/$($App.id)/users" -Headers $Headers -Method Get
    $AppUsers | Select-Object id, scope, status, syncState | Format-Table -AutoSize
}