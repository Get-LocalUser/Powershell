
# Enter comp name
$computer = Read-Host "Enter the name of the device you want to search for"
Write-Host "Retrieving devices that match $($computer)" -ForegroundColor Yellow

### put device findings in this hashtable
$devicetoshow = [ordered]@{}

# Get AD Computer
$Compresults = Get-ADComputer -Filter "Name -like '*$computer*'" -ErrorAction SilentlyContinue
if ($Compresults.Count -gt 1) {
    Write-Host "Multiple computers found in AD. Verify entries before deleting" -ForegroundColor DarkRed
    $compresults | ForEach-Object {"Write-Host Active Directory:$($_.Name)"} 
} else {
    $devicetoshow['Active Directory'] = $Compresults.Name
}

# Import the Configuration Manager module
$cmModulePath = "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
if (Test-Path $cmModulePath) {
    Import-Module $cmModulePath
    # Write-Host "Configuration Manager module imported." -ForegroundColor Cyan
} else {
    Write-Host "Configuration Manager module not found at path: $cmModulePath" -ForegroundColor Red
    exit
}

# Change drive for SCCM
$currentlocation = Get-Location 
Set-Location P02:

# Get SCCM Computer
$Compresults = Get-CMDevice -Name $computer -ErrorAction SilentlyContinue
if ($Compresults.Count -gt 1) {
    Write-Host "Multiple SCCM computers found. Verify entries before deleting" -ForegroundColor DarkRed
    $compresults | ForEach-Object {"Write-Host SCCM:$($_.Name)"} 
} else {
    $devicetoshow['SCCM'] = $Compresults.Name
}

Set-Location -Path $currentlocation

# Check of Graph Beta module is installed
if (-not (Get-InstalledModule -Name Microsoft.Graph.Beta)) {
    Install-Module -Name Microsoft.Graph.Beta
}
Import-Module Microsoft.Graph.Beta -ErrorAction Ignore

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Device.Read.All" -NoWelcome

# Retrieve all managed devices
$Compresults = Get-MgBetaDeviceManagementManagedDevice -Filter "deviceName eq '$computer'"
if ($Compresults.Count -gt 1) {
    Write-Host "Multiple Intune computers found. Verify entries before deleting" -ForegroundColor DarkRed
    $compresults | ForEach-Object {Write-Host "Intune: $($_.Name)"} 
} else {
    $devicetoshow['Intune'] = $Compresults.DeviceName
}

if ($devicetoshow.Values -gt 0) {
    Write-Host "Devices found in the following systems" -ForegroundColor Yellow
    $devicetoshow | Format-Table -AutoSize
} else {
    Write-Host "No devices found with that name" -ForegroundColor Red
}