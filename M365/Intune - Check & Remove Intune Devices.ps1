

# Check if Graph Beta module is installed
$RequiredModule = Get-InstalledModule -Name Microsoft.Graph.Beta
if (!$RequiredModule) {
    Install-Module -Name Microsoft.Graph.Beta
}
Import-Module -Name Microsoft.Graph.Beta

# Connect to Graph
Connect-MgGraph -Scopes "Device.Read.All, Directory.ReadWrite.All, Directory.Read.All, Device.ReadWrite.All,"

# Define CSV file
$CsvFile = Read-Host "Please enter the path to your CSV file"
$ImportedCsv = Import-Csv -Path $CsvFile

# Create a hashtable to store lookup results
$deviceLookup = @{}

# Iterate over the asset tags in the CSV file
foreach ($row in $ImportedCSV) {
    $assetTag = $row.AssetTag

    if ([string]::IsNullOrWhiteSpace($assetTag)) {
        Write-Host "Empty asset tag - skipping..."
        continue
    }

    # Get the devices in Intune
    $devices = Get-MgBetaDeviceManagementManagedDevice | Where-Object {$_.DeviceName -eq $assetTag}
    $deviceLookup[$assetTag] = $devices

    if ($devices) {
        Write-Host "Device '$assetTag' FOUND in Intune." -ForegroundColor Green
    } else {
        Write-Host "Device '$assetTag' NOT FOUND in Intune." -ForegroundColor Red
    }
}

$question = Read-Host "Would you like to remove these devices from Intune? (Y/N)"
if ($question -eq "Y") {
    foreach ($assetTag in $deviceLookup.Keys) {
        $devices = $deviceLookup[$assetTag]
        
        # Then remove each matching device by its ID
        if ($devices) {
            foreach ($device in $devices) {
                Write-Host "Removing device with asset tag '$assetTag'..." -ForegroundColor Yellow
                Remove-MgBetaDeviceManagementManagedDevice -ManagedDeviceId $device.Id
                Write-Host "Device with asset tag '$assetTag' removed successfully." -ForegroundColor Green
            }
        } else {
            Write-Host "No devices found with asset tag '$assetTag'. Skipping." -ForegroundColor Yellow
        }
    }
}

Write-Host "Don't forget to sign out of the graph! using 'Disconnect-MgGraph'" -ForegroundColor Cyan