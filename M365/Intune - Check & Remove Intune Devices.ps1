# Check of Graph Beta module is installed
$RequiredModule = Get-InstalledModule -Name Microsoft.Graph.Beta
if (!$RequiredModule) {
        Install-Module -Name Microsoft.Graph.Beta
        Import-Module -Name Microsoft.Graph.Beta
    }

# Connect to Graph
Connect-MgGraph -Scopes " Device.Read.All, Directory.ReadWrite.All, Directory.Read.All, Device.ReadWrite.All,"

# Define CSV file
$CsvFile = Read-Host "Please enter the path to your CSV file"

$ImportedCsv = Import-Csv -Path $CsvFile

# Iterate over the serial numbers in the CSV file
foreach ($row in $ImportedCSV) {
    $AssetTag = $row.AssetTag


    if ([string]::IsNullOrWhiteSpace($AssetTag)) {
        Write-Host "Empty asset tag - skipping..."
        continue
    }

    # Get the devices in the Autopilot service
    $Devices = Get-MgBetaDevice | Where-Object {$_.DisplayName -eq $AssetTag}

    if ($Devices) {
        Write-Host "Device '$AssetTag' FOUND in Intune." -ForegroundColor Green
    } else {
    Write-Host "Device(s) '$AssetTag' NOT FOUND in Intune." -ForegroundColor Red
    }
} 

$question = Read-Host "Would you like to remove the device(s) from Intune? (Y/N)"
if ($question -eq "Y") {
    foreach ($row in $ImportedCSV) {
        $AssetTag = $row.AssetTag
        if ([string]::IsNullOrWhiteSpace($AssetTag)) {
            continue
        }
        
        # Get the device identity object that matches the serial number
        $deviceToRemove = Get-MgBetaDevice | Where-Object {$_.DisplayName -eq $AssetTag}
        
        # Then remove each matching device by its ID
        if ($deviceToRemove) {
            foreach ($device in $deviceToRemove) {
                Write-Host "Removing device '$AssetTag'..." -ForegroundColor Yellow
                Remove-MgBetaDevice -DeviceId $device.Id
                Write-Host "Device removed successfully." -ForegroundColor Green
            }
        } else {
            Write-Host "No device found with name '$AssetTag'. Skipping." -ForegroundColor Yellow
        }
    }
}

Write-Host "Don't forget to sign out of the graph!." -ForegroundColor Cyan