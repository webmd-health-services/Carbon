
# This function should only be available if the Windows PowerShell v3.0 Server Manager cmdlets aren't already installed.
if( -not (Get-Command -Name 'Get-WindowsFeature*' | Where-Object { $_.ModuleName -ne 'Carbon' }) )
{
    function Get-CWindowsFeature
    {
        <#
        .SYNOPSIS
        Gets a list of available Windows features, or details on a specific windows feature.
        
        .DESCRIPTION
        Different versions of Windows use different names for installing Windows features.  Use this function to get the list of functions for your operating system.
        
        With no arguments, will return a list of all Windows features.  You can use the `Name` parameter to return a specific feature or a list of features that match a wildcard.
        
        **This function is not available on Windows 8/2012.**
        
        .OUTPUTS
        PsObject.  A generic PsObject with properties DisplayName, Name, and Installed.
        
        .LINK
        Install-CWindowsFeature
        
        .LINK
        Test-CWindowsFeature
        
        .LINK
        Uninstall-CWindowsFeature
        
        .EXAMPLE
        Get-CWindowsFeature
        
        Returns a list of all available Windows features.
        
        .EXAMPLE
        Get-CWindowsFeature -Name MSMQ
        
        Returns the MSMQ feature.
        
        .EXAMPLE
        Get-CWindowsFeature -Name *msmq*
        
        Returns any Windows feature whose name matches the wildcard `*msmq*`.
        #>
        [CmdletBinding()]
        param(
            [Parameter()]
            [string]
            # The feature name to return.  Can be a wildcard.
            $Name
        )
        
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                      -NewCommandName 'Get-WindowsFeature' `
                                      -NewModuleName 'ServerManager'

        if( -not (Assert-WindowsFeatureFunctionsSupported) )
        {
            return
        }
        
        if( $useOCSetup )
        {
            Get-WmiObject -Class Win32_OptionalFeature |
                Where-Object {
                    if( $Name )
                    {
                        return ($_.Name -like $Name)
                    }
                    else
                    {
                        return $true
                    }
                } |
                ForEach-Object {
                    $properties = @{
                        Installed = ($_.InstallState -eq 1);
                        Name = $_.Name;
                        DisplayName = $_.Caption;
                    }
                    New-Object PsObject -Property $properties
                }
        }
        elseif( $useServerManager )
        {
            servermanagercmd.exe -query | 
                Where-Object { 
                    if( $Name )
                    {
                        return ($_ -match ('\[{0}\]$' -f [Text.RegularExpressions.Regex]::Escape($Name)))
                    }
                    else
                    {
                        return $true
                    }
                } |
                Where-Object { $_ -match '\[(X| )\] ([^[]+) \[(.+)\]' } | 
                ForEach-Object { 
                    $properties = @{ 
                        Installed = ($matches[1] -eq 'X'); 
                        Name = $matches[3]
                        DisplayName = $matches[2]; 
                    }
                    New-Object PsObject -Property $properties
               }
        }
        else
        {
            Write-Error $supportNotFoundErrorMessage
        }        
    }

    Set-Alias -Name 'Get-WindowsFeature' -Value 'Get-CWindowsFeature'
}
