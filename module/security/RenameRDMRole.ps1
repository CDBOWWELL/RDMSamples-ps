###########################################################################
#
# This function will rename the user group and change the permissions that contain it
#
###########################################################################

# Load RDM PowerShell module. 
# Adapt the folder's name if you are not using the default installation path.
if ( ! (Get-Module RemoteDesktopManager.PowerShellModule)) {
    Import-Module "${env:ProgramFiles(x86)}\Devolutions\Remote Desktop Manager\RemoteDesktopManager.PowerShellModule.psd1"
}

function Rename-Role
{
    param (
        [Parameter(Mandatory=$True,Position=1)]
        [string]$oldRoleName,
        [Parameter(Mandatory=$True,Position=2)]
        [string]$newRoleName,
        [Parameter(Mandatory=$True,Position=3)]
        [string]$dsName,
        [Parameter(Mandatory=$True,Position=4)]
        [bool]$chgRole		
    )

    $ds = Get-RDMDataSource -Name $dsName
    Set-RDMCurrentDataSource $ds
    Update-RDMUI

    # Renaming the role
    if ($chgRole)
    {
        Try
        {
            $role = Get-RDMRole -Name $oldRoleName -ErrorAction SilentlyContinue
            $errorOccured = $false
        }
        catch
        {
            $errorOccured = $True
        }
        if (!$errorOccured)
        {
            Set-RDMRoleProperty -Role $role -Property Name -Value $newRoleName
            Set-RDMRole $role
        }
    }

    $repositories = Get-RDMRepository

    foreach ($repository in $repositories)
    {
        Set-RDMCurrentRepository $repository
        Update-RDMUI

        $sessions = Get-RDMSession
        new-rdm
        New-RDMSession -Type RDP -


        foreach ($session in $sessions)
        {
            [bool]$updateView = $false
            [bool]$updatePerms = $false

            # Replace role name in View permission
            $roles = $session.Security.ViewRoles
            if ($roles -contains $oldRoleName)
            {
                $roles = $roles -replace [Regex]::Escape($oldRoleName), $newRoleName
                $session.Security.ViewRoles = $roles
                $updateView = $True
            }

            # Replace role name in other permissions
            $perms = $session.Security.Permissions
            $newPerms = @()
            foreach ($perm in $perms)
            {
                $roles = $perm.Roles
                if ($roles -contains $oldRoleName)
                {
                    $roles = $roles -replace [Regex]::Escape($oldRoleName), $newRoleName
                    $perm.Roles = $roles
                    $newPerms += $perm
                    $updatePerms = $True
                }
            }
            if ($updatePerms)
            {
                $session.Security.Permissions = $newPerms
            }

            if ($updateView -or $updatePerms)
            {
                Set-RDMSession $session -Refresh
            }
        }
    }

    Update-RDMUI
    Write-Output "Done!!!"
}