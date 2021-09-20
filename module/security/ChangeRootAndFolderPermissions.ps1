###########################################################################
#
# This script will modify root vault permissions and top level folders (view rights in this example)
#
###########################################################################

#load the RDM module
if ( ! (Get-module RemoteDesktopManager.PowerShellModule )) {
    Import-Module "${env:ProgramFiles(x86)}\Devolutions\Remote Desktop Manager\RemoteDesktopManager.PowerShellModule.psd1" 
}

#refresh the connection to RDM to prevent errors and to select the data source
Update-RDMUI

#set the vault you want to modify
$vault = Get-RDMVault "vault_name"

#name of group you want to change role
$group = "group_name"

#set rights at top level and save changea
$RDMroot = Get-RDMRootSession
$RDMroot.Security.RoleOverride = "Custom"
$RDMroot.Security.ViewOverride = "Custom"
$RDMroot.Security.ViewRoles = $group
$RDMroot | Set-RDMRootSession

#retrieve only top level folders
$entries = Get-RDMSession | where {$_.group -eq $_.name}

foreach($entry in $entries){
    $entry.Security.RoleOverride = "Custom"
    $entry.Security.ViewOverride = "Custom"
    $entry.Security.ViewRoles = $group
    Set-RDMSession -Refresh -Session $entry
}

#refresh the connection to RDM to prevent errors
Update-RDMUI