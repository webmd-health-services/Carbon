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

function Enable-IEActivationPermission
{
    <#
    .SYNOPSIS
    Grants all users permission to start/launch Internet Explorer.
    
    .DESCRIPTION
    By default, unprivileged users can't launch/start Internet Explorer. This prevents those users from using Internet Explorer to run automated, browser-based tests.  This function modifies Windows so that all users can launch Internet Explorer.
    
    You may also need to call Disable-IEEnhancedSecurityConfiguration, so that Internet Explorer is allowed to visit all websites.
    
    .EXAMPLE
    Enable-IEActivationPermission

    .LINK
    Disable-IEEnhancedSecurityConfiguration
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )

    Set-StrictMode -Version 'Latest'

    $commonParams = @{
                        ErrorAction = $ErrorActionPreference;
                        Verbose = $VerbosePreference;
                        WhatIf = $WhatIfPreference;
                    }
    
    $sddlForIe =   "O:BAG:BAD:(A;;CCDCSW;;;SY)(A;;CCDCLCSWRP;;;BA)(A;;CCDCSW;;;IU)(A;;CCDCLCSWRP;;;S-1-5-21-762517215-2652837481-3023104750-5681)"
    $binarySD = ([wmiclass]"Win32_SecurityDescriptorHelper").SDDLToBinarySD($sddlForIE)
    $ieRegPath = "hkcr:\AppID\{0002DF01-0000-0000-C000-000000000046}"
    $ieRegPath64 = "hkcr:\Wow6432Node\AppID\{0002DF01-0000-0000-C000-000000000046}"

    if(-not (Test-Path "HKCR:\"))
    {
        $null = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    }

    if( $PSCmdlet.ShouldProcess( 'Internet Explorer', 'enabling launch and activation permission' ) )
    {
        Set-RegistryKeyValue -Path $ieRegPath -Name '(Default)' -String "Internet Explorer(Ver 1.0)" @commonParams
        Set-RegistryKeyValue -Path $ieRegPath64 -Name '(Default)' -String "Internet Explorer(Ver 1.0)" @commonParams

        Set-RegistryKeyValue -Path $ieRegPath -Name 'LaunchPermission' -Binary $binarySD.binarySD @commonParams
        Set-RegistryKeyValue -Path $ieRegPath64 -Name 'LaunchPermission' -Binary $binarySD.binarySD @commonParams
    }
}

Set-Alias -Name 'Enable-IEActivationPermissions' -Value 'Enable-IEActivationPermission'