 <#
        .DESCRIPTION
        Checks if machine is in local AD
        Renames the machine
        Installs Sysmon, Zoom, Chrome, Auotmate, VIP Access
        Turns on System Protection 
        Adds the user to the Power Users group
#>

# Check to make sure machine is domain joined
$ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
if ($ComputerSystem.PartOfDomain) {
    Write-Host "Computer added to local AD"
} else {
    Write-Host "Computer not in AD...oof!"
}

# Rename Machine
$NewName = Read-Host "Enter the name for this machine"
Rename-Computer -NewName $NewName

# Install the latest version of Sysmon
Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/Sysmon.zip' -OutFile "$env:USERPROFILE\Downloads\Sysmon.zip"
Start-Sleep -Seconds 2
Set-Location -Path $env:USERPROFILE\Downloads\
Expand-Archive -Path 'Sysmon.zip' -DestinationPath 'Sysmon'
Set-Location "Sysmon"
Start-Process -FilePath ".\sysmon64.exe" -ArgumentList '-accepteula -i' -Verb RunAs
Start-Sleep 5

# Install Zoom 64bit MSI from ccmapp01
#Invoke-Item "\\ccmapp01\SW_Deploy\NewMachineScriptsandApps\Zoominstallerfull.msi"
#Read-Host "Press enter when installation of Zoom is finished"
Read-Host "Installing Zoom..please wait"
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `\\ccmapp01\SW_Deploy\NewMachineScriptsandApps\Zoominstallerfull.msi` /qn" -Wait

# Install Google Chrome from ccmapp01
Invoke-Item "\\ccmapp01\SW_Deploy\NewMachineScriptsandApps\ChromeSetup.exe"
Read-Host "Press enter when installation of Google Chrome is finished"

# Turn on System Protection
Enable-ComputerRestore -Drive "C:"

# Set the maximum disk space usage for System Restore to 10 percent
$percentage = 10
$driveLetter = "C:"

# Get the total size of the drive
$driveSize = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$driveLetter'").Size

# Calculate the maximum size in MB that System Restore should use
$maxSize = ($driveSize * $percentage / 100) / 1MB

# Run vssadmin to resize the shadowstorage
Invoke-Expression -Command "vssadmin Resize ShadowStorage /On=$driveLetter /For=$driveLetter /MaxSize=${maxSize}MB"

# Add the user to the Power Users and Remote Desktop groups
$groupuser = Read-Host "Enter the username you want added to the Power Users group using this convention 'firstname.lastname' "
Add-LocalGroupMember -Group 'Power Users' -Member $groupuser

# Install ConnetWise Automate from SW_Deploy
Set-Location "\\ccmapp01\SW_Deploy\Automate\All Installers"
$File = Get-ChildItem -Recurse | Out-GridView -PassThru
Invoke-Item $File.FullName
Read-Host "Press enter when installation is finished"

# Install Symantic VIP Access from SW_Deploy
Set-Location "\\ccmapp01\SW_Deploy\Symantec VIP Access"
$File = Get-ChildItem -Recurse | Out-GridView -PassThru
Invoke-Item $File.FullName
Read-Host "Press enter when installation is finished"

#Restart the machine 
$choice = Read-Host "Some changes require the machine to reboot. Do you want to restart the computer? (Y/N)"
    if ($choice -eq 'Y') {
        Restart-Computer
    } else {
        Write-Host "Script is finished, you may exit."
    }