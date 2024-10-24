$computerInfo = Get-WmiObject Win32_ComputerSystem
$osInfo = Get-WmiObject Win32_OperatingSystem
$biosInfo = Get-WmiObject Win32_BIOS
$diskInfo = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }

$inventory = [pscustomobject]@{
    ComputerName = $computerInfo.Name
    Manufacturer = $computerInfo.Manufacturer
    Model = $computerInfo.Model
    Serial = $biosInfo.SerialNumber
    TotalMemoryGB = [math]::round($computerInfo.TotalPhysicalMemory / 1GB, 2)
    OS = $osInfo.Caption
    OSVersion = $osInfo.Version
    BIOSVersion = $biosInfo.SMBIOSBIOSVersion
    DiskSpaceGB = [math]::round($diskInfo.Size / 1GB, 2)
    FreeSpaceGB = [math]::round($diskInfo.FreeSpace / 1GB, 2)
}

$inventory | Out-Default