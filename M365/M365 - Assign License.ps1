<#
=============================================================================================
Name:           M365 - Assign Licenses
Description:    Assigns licenses to a user.
Prerequisites:  MgGraph Module

Script Tasks: 
~~~~~~~~~~~~~~~~~
============================================================================================
#>
Connect-Graph -Scopes User.ReadWrite.All, Organization.Read.All

$UserID = Read-Host "Enter the user ID you'd like to assign a license to"

$E5Sku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'SPE_E5'
$E3Sku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'SPE_E3'
$ThreatProtectSku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'IDENTITY_THREAT_PROTECTION'
$addLicenses = @(
  @{SkuId = $E5Sku.SkuId},
  @{SkuId = $E3Sku.SkuId},
  @{SkuId = $ThreatProtectSku.SkuId}
  )

try {
    Set-MgUserLicense -UserId $UserID -AddLicenses $addLicenses -RemoveLicenses @()
    Write-Host "Licenses assigned successfully" -ForegroundColor Green 
} catch {
    Write-Host "Failed to assign license: $_" -ForegroundColor Red
}