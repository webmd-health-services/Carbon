# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This function should only be available if the Windows PowerShell v3.0 Server Manager cmdlets aren't already installed.
if( -not (Get-Command -Name 'Get-WindowsFeature*') )
{
    function Get-WindowsFeature
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
        Install-WindowsFeature
        
        .LINK
        Test-WindowsFeature
        
        .LINK
        Uninstall-WindowsFeature
        
        .EXAMPLE
        Get-WindowsFeature
        
        Returns a list of all available Windows features.
        
        .EXAMPLE
        Get-WindowsFeature -Name MSMQ
        
        Returns the MSMQ feature.
        
        .EXAMPLE
        Get-WindowsFeature -Name *msmq*
        
        Returns any Windows feature whose name matches the wildcard `*msmq*`.
        #>
        [CmdletBinding()]
        param(
            [Parameter()]
            [string]
            # The feature name to return.  Can be a wildcard.
            $Name
        )
        
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
}