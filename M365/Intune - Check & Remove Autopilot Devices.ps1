# Check of Graph Beta module is installed
$RequiredModule = Get-InstalledModule -Name Microsoft.Graph.Beta
if (!$RequiredModule) {
        Install-Module -Name Microsoft.Graph.Beta
        Import-Module
    }

# Connect to Graph
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All, DeviceManagementServiceConfig.ReadWrite.All,"

# Define CSV file
$CsvFile = Read-Host "Please enter the path to your CSV file"

$ImportedCsv = Import-Csv -Path $CsvFile

# Iterate over the serial numbers in the CSV file
foreach ($row in $ImportedCSV) {
    $serial = $row.Serial


    if ([string]::IsNullOrWhiteSpace($serial)) {
        Write-Host "Empty serial number - skipping..."
        continue
    }

    # Get the devices in the Autopilot service
    $autopilotdevices = Get-MgBetaDeviceManagementWindowsAutopilotDeviceIdentity | Where-Object {$_.SerialNumber -eq $serial}

    if ($autopilotdevices) {
        Write-Host "Serial number '$serial' FOUND in Autopilot." -ForegroundColor Green
    } else {
    Write-Host "Serial number(s) '$serial' NOT FOUND in Autopilot." -ForegroundColor Red
    }
} 

$question = Read-Host "Would you like to remove these serial numbers from Autopilot? (Y/N)"
if ($question -eq "Y") {
    foreach ($row in $ImportedCSV) {
        $serial = $row.Serial
        if ([string]::IsNullOrWhiteSpace($serial)) {
            continue
        }
        
        # Get the device identity object that matches the serial number
        $deviceToRemove = Get-MgBetaDeviceManagementWindowsAutopilotDeviceIdentity | Where-Object {$_.SerialNumber -eq $serial}
        
        # Then remove each matching device by its ID
        if ($deviceToRemove) {
            foreach ($device in $deviceToRemove) {
                Write-Host "Removing device with serial number '$serial'..." -ForegroundColor Yellow
                Remove-MgBetaDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $device.Id
                Write-Host "Device removed successfully." -ForegroundColor Green
            }
        } else {
            Write-Host "No serial numbers found with '$serial'. Skipping." -ForegroundColor Yellow
        }
    }
}

Write-Host "Don't forget to sign out of the graph! using 'Disconnect-MgGraph'" -ForegroundColor Cyan