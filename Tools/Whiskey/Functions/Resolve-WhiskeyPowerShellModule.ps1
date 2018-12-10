function Resolve-WhiskeyPowerShellModule
{
    <#
    .SYNOPSIS
    Searches for a PowerShell module using PowerShellGet to ensure it exists and returns the resulting object from PowerShellGet.

    .DESCRIPTION
    The `Resolve-WhiskeyPowerShellModule` function takes a `Name` of a PowerShell module and uses PowerShellGet's `Find-Module` cmdlet to search for the module. If the module is found, the object from `Find-Module` describing the module is returned. If no module is found, an error is written and nothing is returned. If the module is found in multiple PowerShellGet repositories, only the first one from `Find-Module` is returned.

    If a `Version` is specified then this function will search for that version of the module from all versions returned from `Find-Module`. If the version cannot be found, an error is written and nothing is returned.

    `Version` supports wildcard patterns.

    .EXAMPLE
    Resolve-WhiskeyPowerShellModule -Name 'Pester'

    Demonstrates getting the module info on the latest version of the Pester module.

    .EXAMPLE
    Resolve-WhiskeyPowerShellModule -Name 'Pester' -Version '4.*'

    Demonstrates getting the module info on the latest '4.X' version of the Pester module.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The name of the PowerShell module.
        $Name,

        [string]
        # The version of the PowerShell module to search for. Must be a three part number, i.e. it must have a MAJOR, MINOR, and BUILD number.
        $Version
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Import-WhiskeyPowerShellModule -Name 'PackageManagement', 'PowerShellGet'

    Get-PackageProvider -Name 'NuGet' -ForceBootstrap | Out-Null

    if( $Version )
    {
        $atVersionString = ' at version {0}' -f $Version

        if( -not [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($version) )
        {
            $tempVersion = [Version]$Version
            if( $TempVersion -and ($TempVersion.Build -lt 0) )
            {
                $Version = [version]('{0}.{1}.0' -f $TempVersion.Major, $TempVersion.Minor)
            }
        }

        $module = Find-Module -Name $Name -AllVersions |
            Where-Object { $_.Version.ToString() -like $Version } |
            Sort-Object -Property 'Version' -Descending
    }
    else
    {
        $atVersionString = ''
        $module = Find-Module -Name $Name -ErrorAction Ignore
    }

    if( -not $module )
    {
        Write-Error -Message ('Failed to find module {0}{1} module on the PowerShell Gallery. You can browse the PowerShell Gallery at https://www.powershellgallery.com/' -f $Name, $atVersionString)
        return
    }

    return $module | Select-Object -First 1
}
