<#
=============================================================================================
Name:           Entra - Get Users Without Licenses
Description:    Retrieves users in the tenant that have no licenses
Prerequisites:  EntraID Module
Other:          Slight adjustment from MS's script https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.entra/get-entrauser?view=entra-powershell

Script Tasks: 
~~~~~~~~~~~~~~~~~
============================================================================================
#>


Connect-Entra -Scopes 'User.Read.All'
$EntraUsers = Get-EntraUser -All
$EntraUsersWithLicenses = foreach ($user in $EntraUsers) {
    if ($user.AssignedLicenses.Count -lt 1) {
        [pscustomobject]@{
            Id                  = $user.Id
            DisplayName         = $user.DisplayName
            UserPrincipalName   = $user.UserPrincipalName
            AssignedLicenses    = ($user.AssignedLicenses | ForEach-Object { $_.SkuId }) -join ", "
        }
    }
}
$EntraUsersWithLicenses | Format-Table Id, DisplayName, UserPrincipalName, AssignedLicenses -AutoSize