<#
=============================================================================================
Name:           New Machine Setup
Filepath:       N/A
Description:    Configures Windows to my liking
Prerequisites:  Must be ran as an Administrator

Script Tasks: 
~~~~~~~~~~~~~~~~~
1. Disables the Print Spooler service
2. Installs applications machine wide
3. Enabled Windows Sandbox
4. Disables Recall
5. Install PSWindowsUpdate Module and installs Windows updates
============================================================================================
#>

# Start transcript
Start-Transcript -Path "C:\NewMachine_Log.txt"

$service = Get-Service -DisplayName "Print Spooler"

# Get the status of the Print Spooler service and stop if it is running
switch ($service.Status) {
    "Running" {
        Write-Host "Stopping the Print Spooler service" -ForegroundColor Yellow
        Stop-Service -DisplayName "Print Spooler" -Force -ErrorAction Inquire
        Write-Host "Print Spooler has been stopped. Changing the automatic start behavior to 'Disabled'" -ForegroundColor Yellow
        Set-Service -Name "Spooler" -StartupType Disabled
    }
    "Stopped" { # Change the startup behavior to 'Disabled'
        Write-Host "Changing the automatic start behavior of the Print Spooler service to 'Disabled'" -ForegroundColor Yellow
        Set-Service -Name "Spooler" -StartupType Disabled
    }
}


<############ NOT WORKING CURRENTLY, NEEDS UPDATING##############
winget install --id Microsoft.VisualStudioCode -e -h --silent --accept-package-agreements --accept-source-agreements
winget install --id qBittorrent.qBittorrent -e -h --silent --accept-package-agreements --accept-source-agreements
winget install --id SumatraPDF.SumatraPDF -e -h --silent --accept-package-agreements --accept-source-agreements
winget install --id voidtools.Everything -e -h --silent --accept-package-agreements --accept-source-agreements
winget install --id Power.Toys -e -h --silent --accept-package-agreements --accept-source-agreements
winget install --id Mozilla.Firefox -e -h --silent --accept-package-agreements --accept-source-agreements
winget install --id Notion.Notion -e -h --silent --accept-package-agreements --accept-source-agreements
winget install --id VideoLAN.VLC -e -h --silent --accept-package-agreements --accept-source-agreements
winget install --id 7zip.7zip -e -h --silent --accept-package-agreements --accept-source-agreements

<# Create a list of apps you want installed via Winget
$applist = @{
    "Microsoft.VisualStudioCode" = "--id Microsoft.VisualStudioCode -e -h --silent --accept-package-agreements --accept-source-agreements";
    "qBittorrent.qBittorrent"    = "--id qBittorrent.qBittorrent -e -h --silent --accept-package-agreements --accept-source-agreements";
    "SumatraPDF.SumatraPDF"      = "--id SumatraPDF.SumatraPDF -e -h --silent --accept-package-agreements --accept-source-agreements";
    "voidtools.Everything"       = "--id voidtools.Everything -e -h --silent --accept-package-agreements --accept-source-agreements";
    "Microsoft.PowerToys"        = "--id Power.Toys -e -h --silent --accept-package-agreements --accept-source-agreements";
    "Mozilla.Firefox"            = "--id Mozilla.Firefox -e -h --silent --accept-package-agreements --accept-source-agreements";
    "Notion.Notion"              = "--id Notion.Notion -e -h --silent --accept-package-agreements --accept-source-agreements";
    "VideoLAN.VLC"               = "--id VideoLAN.VLC -e -h --silent --accept-package-agreements --accept-source-agreements";
    "7zip"                       = "--id 7zip.7zip -e -h --silent --accept-package-agreements --accept-source-agreements";
}

# Install applications
foreach ($app in $applist.Keys) {
    $params = $applist[$app]
    Write-Host "Installing $app with paramaters; $params" -ForegroundColor Green
    winget.exe install $params
}
#>

try {
    # Turn on the Windows Sandbox feature and verify install
    $feature1 = Get-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM"
    
    if ($feature1.State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -NoRestart
        Write-Host "Feature enabled successfully." -ForegroundColor Green
    } else {
        Write-Host "Feature is already enabled." -ForegroundColor Green
    }
}
catch {
    Write-Error "An error occurred: $_"
}


try {
    # Disable Optional Feature Recall and verify installed
    $feature2 = Get-WindowsOptionalFeature -Online -FeatureName "Recall"
    
    if ($feature2.State -ne "Disabled") {
        Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -NoRestart
        Write-Host "Feature disabled successfully." -ForegroundColor Green
    } else {
        Write-Host "Feature is already disabled." -ForegroundColor Green
    }
}
catch {
    Write-Error "An error occurred: $_"
}

# Install Nuget
Install-PackageProvider -Name Nuget -Force -Confirm:$false

# Install PSWindowsUpdate module and install all available updates with verbose output
Set-ExecutionPolicy Bypass
Install-Module -Name PSWindowsUpdate -AllowClobber -Force -Confirm:$false
Get-WindowsUpdate -AcceptAll -Download -Install -Verbose