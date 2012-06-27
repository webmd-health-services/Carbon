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

function Disable-IEEnhancedSecurityConfiguration
{
 	<#
    .SYNOPSIS
    Disables Internet Explorer's Enhanced Security Configuration. 
    .DESCRIPTION
    By default, Windows locks down Internet Explorer so that users can't visit certain sites.  This function disables that enhanced security.  This is necessary if you have automated processes that need to run and interact with Internet Explorer.
    
    You may also need to call Enable-IEActivationPermissions, so that processes have permission to start Internet Explorer.
    
    .EXAMPLE
    Disable-IEEnhancedSecurityConfiguration
    .LINK
    http://technet.microsoft.com/en-us/library/dd883248(v=WS.10).aspx
    .LINK
    Enable-IEActivationPermissions
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
 	param()
    $regPathAdmin = "HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $regPathUser = "HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    
    if(-not (Test-Path -Path $regPathAdmin))
    {
        Write-Warning "Could not find the registry path for admins $regPathAdmin). Aborting"
        return
         
	}
	
    if(-not (Test-Path -Path $regPathUser))
    {
        Write-Warning "Could not find the registry path for users ($regPathUser). Aborting"
        return
         
	}
    if( $pscmdlet.ShouldProcess( "Set Registry Information" ) )
    {
        Set-ItemProperty  $regPathAdmin -name "IsInstalled" -value 0 
        Set-ItemProperty  $regPathUser -name "IsInstalled" -value 0
    }
    if( $pscmdlet.ShouldProcess("iesetup.dll", "Call dll reg methods" ) )
    {
    
        Rundll32 iesetup.dll, IEHardenLMSettings
        Rundll32 iesetup.dll, IEHardenUser
        Rundll32 iesetup.dll, IEHardenAdmin 
    }
}

function Enable-IEActivationPermissions
{
    <#
    .SYNOPSIS
    Grants all users permission to start/launch Internet Explorer.
    
    .DESCRIPTION
    By default, unprivileged users can't launch/start Internet Explorer. This prevents those users from using Internet Explorer to run automated, browser-based tests.  This function modifies Windows so that all users can launch Internet Explorer.
    
    You may also need to call Disable-IEEnhancedSecurityConfiguration, so that Internet Explorer is allowed to visit all websites.
    
    .EXAMPLE
    Enable-IEActivationPermissions

    .LINK
    Disable-IEEnhancedSecurityConfiguration
    #>
    [CmdletBinding()]
    param(
    )
    
    $sddlForIe =   "O:BAG:BAD:(A;;CCDCSW;;;SY)(A;;CCDCLCSWRP;;;BA)(A;;CCDCSW;;;IU)(A;;CCDCLCSWRP;;;S-1-5-21-762517215-2652837481-3023104750-5681)"
    $binarySD = ([wmiclass]"Win32_SecurityDescriptorHelper").SDDLToBinarySD($sddlForIE)
    $ieRegPath = "hkcr:\AppID\{0002DF01-0000-0000-C000-000000000046}"
    $ieRegPath64 = "hkcr:\Wow6432Node\AppID\{0002DF01-0000-0000-C000-000000000046}"

    if(-not (Test-Path "HKCR:\AppID"))
    {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    }

    if(-not (Test-Path $ieRegPath))
    {
       New-Item $ieRegPath
       New-ItemProperty $ieRegpath "(default)" -value "Internet Explorer(Ver 1.0)" -PropertyType Binary
    }

    if(-not (Test-Path $ieRegPath64))
    {
       New-Item $ieRegPath64
       New-ItemProperty $ieRegPath64 "(default)" -value "Internet Explorer(Ver 1.0)" -PropertyType Binary
    }
 
    Set-ItemProperty $ieRegPath "LaunchPermission" ([byte[]]$binarySD.binarySD)
    Set-ItemProperty $ieRegPath64 "LaunchPermission" ([byte[]]$binarySD.binarySD)

}