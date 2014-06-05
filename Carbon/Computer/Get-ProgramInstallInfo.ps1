
function Get-ProgramInstallInfo
{
    <#
    .SYNOPSIS
    Gets information about the programs installed on the computer.
    
    .DESCRIPTION
    This function is the PowerShell equivalent of the Programs and Features UI.

    .OUTPUTS
    Carbon.Computer.ProgramInstallInfo.

    .EXAMPLE
    Get-ProgramInstallInfo

    Demonstrates how to get a list of all the installed programs, similar to what the Programs and Features UI shows.

    .EXAMPLE
    Get-ProgramInstallInfo -Name 'Google Chrome'

    Demonstrates how to get a specific program. If the specific program isn't found, `$null` is returned.

    .EXAMPLE
    Get-ProgramInstallInfo -Name 'Microsoft*'

    Demonstrates how to use wildcards to search for multiple programs.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The name of a specific program to get. Wildcards supported.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    if( -not (Test-Path -Path 'hku:\') )
    {
        $null = New-PSDrive -Name 'HKU' -PSProvider Registry -Root 'HKEY_USERS'
    }

    ('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall','hku:\*\Software\Microsoft\Windows\CurrentVersion\Uninstall\*') |
        Where-Object { Test-Path -Path $_ -PathType Container } | 
        Get-ChildItem | 
        Where-Object { 
            $valueNames = $_.GetValueNames()

            [Microsoft.Win32.RegistryKey]$key = $_

            if( $valueNames -notcontains 'DisplayName' )
            {
                Write-Verbose ('Skipping {0}: DisplayName not found.' -f $_.Name)
                return $false
            }

            $displayName = $_.GetValue( 'DisplayName' )

            if( $valueNames -contains 'ParentKeyName' )
            {
                Write-Verbose ('Skipping {0} ({1}): found ParentKeyName property.' -f $displayName,$_.Name)
                return $false
            }

            if( $valueNames -contains 'SystemComponent' -and $_.GetValue( 'SystemComponent' ) -eq 1 )
            {
                Write-Verbose ('Skipping {0} ({1}): SystemComponent property is 1.' -f $displayName,$_.Name)
                return $false
            }

            return $true
        } |
        Where-Object { 
                if( $Name ) 
                { 
                    return $_.GetValue('DisplayName') -like $Name 
                } 
                return $true
            } | 
        ForEach-Object { New-Object 'Carbon.Computer.ProgramInstallInfo' $_ }
}