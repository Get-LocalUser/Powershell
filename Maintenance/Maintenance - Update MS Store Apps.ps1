<#
=============================================================================================
Name:           Maintenance - Update MS Store Apps
Description:    This script will have the MS Store check for and update any apps from the MS Store that need it.
Prerequisites:  N/A

Script Tasks: 
~~~~~~~~~~~~~~~~~
1. Checks and updates apps
============================================================================================
#>

Get-CimInstance -Namespace "root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" -Verbose | Invoke-CimMethod -MethodName "UpdateScanMethod"