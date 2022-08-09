
function Get-CProgramInstallInfo
{
    <#
    .SYNOPSIS
    Gets information about the programs installed on the computer.
    
    .DESCRIPTION
    The `Get-CProgramInstallInfo` function is the PowerShell equivalent of the Programs and Features UI in the Control Panel. It inspects the registry to determine what programs are installed. It will return programs installed for *all* users, not just the current user. 
    
    `Get-CProgramInstallInfo` tries its best to get accurate data. The following properties either isn't stored consistently, is in strange formats, can't be parsed, etc.

     * The `ProductCode` property is set to `[Guid]::Empty` if the software doesn't have a product code.
     * The `User` property will only be set for software installed for specific users. For global software, the `User` property will be `[String]::Empty`.
     * The `InstallDate` property is set to `[DateTime]::MinValue` if the install date can't be determined.
     * The `Version` property is `$null` if the version can't be parsed

    .OUTPUTS
    Carbon.Computer.ProgramInstallInfo.

    .EXAMPLE
    Get-CProgramInstallInfo

    Demonstrates how to get a list of all the installed programs, similar to what the Programs and Features UI shows.

    .EXAMPLE
    Get-CProgramInstallInfo -Name 'Google Chrome'

    Demonstrates how to get a specific program. If the specific program isn't found, `$null` is returned.

    .EXAMPLE
    Get-CProgramInstallInfo -Name 'Microsoft*'

    Demonstrates how to use wildcards to search for multiple programs.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.Computer.ProgramInstallInfo])]
    param(
        # The name of a specific program to get. Wildcards supported.
        [string] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.Windows.Installer' `
                                    -NewCommandName 'Get-CInstalledProgram'

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
                Write-Debug ('Skipping {0}: DisplayName not found.' -f $_.Name)
                return $false
            }

            $displayName = $_.GetValue( 'DisplayName' )

            if( $valueNames -contains 'ParentKeyName' )
            {
                Write-Debug ('Skipping {0} ({1}): found ParentKeyName property.' -f $displayName,$_.Name)
                return $false
            }

            if( $valueNames -contains 'SystemComponent' -and $_.GetValue( 'SystemComponent' ) -eq 1 )
            {
                Write-Debug ('Skipping {0} ({1}): SystemComponent property is 1.' -f $displayName,$_.Name)
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
