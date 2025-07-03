<#
.SYNOPSIS
    Device Lookup Script - Searches for computer records across Active Directory, SCCM, Intune, & Autopilot.

.DESCRIPTION
    This script allows you to search for computers using a single name or a bulk list (via CSV).
    It checks if the device exists in:
      - Active Directory (AD)
      - Microsoft Endpoint Configuration Manager (MECM/SCCM)
      - Microsoft Intune (via Microsoft Graph API)
      - Autopilot (via Microsoft Graph API)

    Results are shown in the console and optionally exported to a CSV file in your Downloads folder.

.FUNCTIONALITY
    - Imports and verifies required modules (ActiveDirectory, ConfigurationManager, Microsoft.Graph.Beta).
    - Connects to Microsoft Graph (Device.Read.All scope required).
    - Searches for devices across AD, SCCM, Intune, & Autopilot.
    - Supports both interactive and automated use.
    - Outputs results with ✓ markers or 'False'.
    - Exports bulk results to CSV in the user's Downloads folder.
    - Asks whether to disconnect from Microsoft Graph after completion.

.EXAMPLE
    # Single device (prompted interactively)
    .\Find-Device.ps1

    # Single device via parameter
    .\Find-Device.ps1 -ComputerName "P250101"

    # Bulk mode via CSV
    .\Find-Device.ps1 -CsvPath "C:\path\to\computers.csv"

.NOTES
    - Requires RSAT: Active Directory tools installed.
    - Requires Configuration Manager console installed.
    - Requires Microsoft.Graph.Beta module installed (will auto-install if missing).
    - CSV must contain a column named "Asset Tag".
#>



# Computer Search Script - Single and Bulk Mode
param(
    [Parameter(Mandatory=$false)]
    [string]$ComputerName,
    
    [Parameter(Mandatory=$false)]
    [string]$CsvPath
)


# ------------------------------ Install & Import Modules ------------------------------

function Initialize-Modules {
    if ($Global:DeviceScriptInitialized) {
        Write-Host "Modules already initialized. Skipping module checks." -ForegroundColor Green
        return
    }

    # ------------------------ Module Initialization ------------------------

    # Active Directory
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Host "ActiveDirectory module not found. Please install RSAT: Active Directory." -ForegroundColor Red
        exit
    }
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Host "ActiveDirectory module imported successfully." -ForegroundColor Yellow

    # Configuration Manager
    $cmModulePath = "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
    if (Test-Path $cmModulePath) {
        Import-Module $cmModulePath -ErrorAction Stop
        Write-Host "ConfigurationManager module imported successfully." -ForegroundColor Yellow
    } else {
        Write-Host "Configuration Manager module not found at path: $cmModulePath, exiting.." -ForegroundColor Red
        exit
    }

    # Microsoft Graph Beta
    if (-not (Get-InstalledModule -Name Microsoft.Graph.Beta -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Graph module. This will take a few minutes..." -ForegroundColor Yellow
        Install-Module -Name Microsoft.Graph.Beta -Scope CurrentUser -Force
    }
    Import-Module Microsoft.Graph.Beta -ErrorAction Ignore
    Write-Host "Graph module imported successfully." -ForegroundColor Yellow

    Connect-MgGraph -Scopes "Device.Read.All" -NoWelcome

    # Mark as initialized for the session
    $Global:DeviceScriptInitialized = $true
    Write-Host "Modules initialized." -ForegroundColor Yellow
}

# ------------------------------ End of Modules ------------------------------

# Load required modules 
Initialize-Modules

function Search-SingleComputer {
    param([string]$Computer)

    # Define the PSCustomObject for output
    $deviceresult = [PSCustomObject]@{
        InputName = $Computer

        # Active Directory
        AD_ComputerFound        = $false
        AD_ComputerName         = $null

        # SCCM
        SCCM_ComputerFound      = $false
        SCCM_ComputerName       = $null

        # Intune
        Intune_ComputerFound    = $false
        Intune_ComputerName     = $null
        Intune_SerialNumber     = $null

        # Autopilot
        Autopilot_ComputerFound = $false
        Autopilot_SerialNumber  = $null
    }
    

    # Enter computer name
    if (-not $Computer) {
        $Computer = Read-Host "Enter the name of the device you want to search for"
    }

    Write-Host "Searching for computer.." -ForegroundColor Yellow

    # Get AD Computer
    $Compresults = Get-ADComputer -Filter "Name -like '*$Computer*'" -ErrorAction SilentlyContinue
    if ($Compresults.Count -gt 1) {
        Write-Host "Multiple computers found in AD. Verify entries before deleting" -ForegroundColor Red
        $compresults | ForEach-Object {"Write-Host Active Directory:$($_.Name)"} 
    } elseif ($Compresults) {
        $deviceresult.AD_ComputerFound       = $true
        $deviceresult.AD_ComputerName        = $Compresults.Name
    }

    # Change drive for SCCM
    $currentlocation = Get-Location 
    Set-Location P02:

    # Get SCCM Computer
    $Compresults = Get-CMDevice -Name $Computer -ErrorAction SilentlyContinue
    if ($Compresults.Count -gt 1) {
        Write-Host "Multiple SCCM computers found. Verify entries before deleting" -ForegroundColor Red
        $compresults | ForEach-Object {"Write-Host SCCM:$($_.Name)"} 
    } elseif ($Compresults) {
        $deviceresult.SCCM_ComputerFound     = $true
        $deviceresult.SCCM_ComputerName      = $Compresults.Name
    }

    # Set working dirtectory back to the starting directory    
    Set-Location -Path $currentlocation

    # Get Intune computer
    $Compresults = Get-MgBetaDeviceManagementManagedDevice -Filter "deviceName eq '$Computer'"
    if ($Compresults.Count -gt 1) {
        Write-Host "Multiple Intune computers found. Verify entries before deleting" -ForegroundColor Red
        $compresults | ForEach-Object {Write-Host "Intune: $($_.DeviceName)"} 
    } elseif ($Compresults) {
        $deviceresult.Intune_ComputerFound   = $true
        $deviceresult.Intune_ComputerName    = $Compresults.DeviceName
        $deviceresult.Intune_SerialNumber    = $Compresults.SerialNumber
    }

    # Get Autopilot enrollment
    if ($deviceresult.Intune_SerialNumber) {
        $Compresults = Get-MgBetaDeviceManagementWindowsAutopilotDeviceIdentity -ErrorAction SilentlyContinue | Where-Object { $_.SerialNumber -eq $deviceresult.Intune_SerialNumber }
    }
    
    if ($Compresults.Count -gt 1) {
        Write-Host "Multiple Autopilot devices found. Verify entries before deleting" -ForegroundColor Red
        $compresults | ForEach-Object {Write-Host "Autopilot: $($_.DisplayName)"} 
    } elseif ($Compresults) {
        $deviceresult.Autopilot_ComputerFound = $true
        $deviceresult.Autopilot_SerialNumber  = $Compresults.SerialNumber
    }


    # Display results of previous checks
    if ($deviceresult.AD_ComputerFound -or $deviceresult.SCCM_ComputerFound -or $deviceresult.Intune_ComputerFound -or $deviceresult.Autopilot_ComputerFound) {
        Write-Host "Device found in one or more systems." -ForegroundColor Yellow
    } else { 
        Write-Host "No devices found in any system." -ForegroundColor Red
    }

    $Check = "✓"
    $output = [PSCustomObject]@{
        ComputerName    = $deviceresult.InputName
        ActiveDirectory = if ($deviceresult.AD_ComputerFound)       { $Check } else { "False" }
        SCCM            = if ($deviceresult.SCCM_ComputerFound)     { $Check } else { "False" }
        Intune          = if ($deviceresult.Intune_ComputerFound)   { $Check } else { "False" }
        Autopilot       = if ($deviceresult.Autopilot_ComputerFound){ $Check } else { "False" }
    }

    $output | Format-Table -AutoSize

    return $deviceresult

}


function Search-BulkComputers {
    param([string]$CsvPath)

    # Load required modules 
    Initialize-Modules

    if (-not (Test-Path $CsvPath)) {
        Write-Host "CSV file not found: $CsvPath" -ForegroundColor Red
        return
    }

    try {
        $computers = Import-Csv $CsvPath
        Write-Host "`nProcessing $($computers.Count) computers from CSV..." -ForegroundColor Yellow

        $results = @()
        $counter = 0

        foreach ($row in $computers) {
            $counter++
            $ComputerName = $row.'Asset Tag'

            if ([string]::IsNullOrWhiteSpace($computerName)) {
                Write-Host "[$counter/$($computers.Count)] Skipping empty computer name" -ForegroundColor Yellow
                continue
        }

        # Show progress
        Write-Host "[$counter/$($computers.Count)] $computerName" -ForegroundColor Cyan

        $deviceInfo = Search-SingleComputer -Computer $computerName

        $Check = "✓"
        $result = [PSCustomObject]@{
            ComputerName     = $computerName
            ActiveDirectory  = if ($deviceInfo.AD_ComputerFound)       { $check } else { "False" }
            SCCM             = if ($deviceInfo.SCCM_ComputerFound)     { $check } else { "False" }
            Intune           = if ($deviceInfo.Intune_ComputerFound)   { $check } else { "False" }
            Autopilot        = if ($deviceInfo.Autopilot_ComputerFound){ $check } else { "False" }
        }

            $results += $result
        }

    }
    catch {
        Write-Host "Error processing CSV: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Print results and export to a CSV in the user's Downloads folder
    $Pathway = "C:\Users\$env:USERNAME\Downloads\"
    $ExportFile = Join-Path -Path $Pathway -ChildPath "Computersfound.csv"

    if ($results) { 
        $Utf8WithBom = New-Object System.Text.UTF8Encoding $true
        $csvContent = $results | ConvertTo-Csv -NoTypeInformation | Out-String
        [System.IO.File]::WriteAllText($ExportFile, $csvContent, $Utf8WithBom)
        Write-Host "`nResults exported to: $ExportFile" -ForegroundColor Yellow
        Write-Host "`nOpen in Excel for best visual." -ForegroundColor Magenta
    }
    else {
        Write-Host "Not exported" -ForegroundColor Yellow
    }

    return $results
    Write-Host "`nOpen in Excel for best visual." -ForegroundColor Magenta
}


# Main script logic
if ($CsvPath) {
    # Bulk mode
    $allResults = Search-BulkComputers -CsvPath $CsvPath
    $allResults | Format-Table -AutoSize
}
elseif ($ComputerName) {
    # Single mode with parameter
    Search-SingleComputer -Computer $ComputerName
}
else {
    # Interactive single mode
    $computer = Read-Host "Enter the name of the device you want to search for"
    if ([string]::IsNullOrWhiteSpace($computer)) {
        Write-Host "No computer name provided. Exiting." -ForegroundColor Red
        exit
    }
    Search-SingleComputer -Computer $computer
}

$disconnect = Read-Host "Do you want to disconnect from the Graph? If you plan on running this again type 'No' else 'Yes'"
if ($disconnect -match '^[nN]') {
    return
} else {
    Disconnect-MgGraph
}
