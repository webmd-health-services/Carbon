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
    
    You may also need to call `Enable-IEActivationPermission`, so that processes have permission to start Internet Explorer.
    
    .EXAMPLE
    Disable-IEEnhancedSecurityConfiguration
    .LINK
    http://technet.microsoft.com/en-us/library/dd883248(v=WS.10).aspx
    .LINK
    Enable-IEActivationPermission
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )
    
    $regPathAdmin = "HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $regPathUser = "HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    
    Write-Host "Disabling Internet Explorer Enhanced Security Configuration."
    
    if(-not (Test-Path -Path $regPathAdmin))
    {
        Write-Warning "Could not find the registry path for admins ($regPathAdmin). Aborting."
        return
         
    }

    if(-not (Test-Path -Path $regPathUser))
    {
        Write-Warning "Could not find the registry path for users ($regPathUser). Aborting."
        return
    }

    if( $pscmdlet.ShouldProcess( "Set Registry Information." ) )
    {
        Write-Verbose "Setting registry information."
        Set-ItemProperty  $regPathAdmin -name "IsInstalled" -value 0 
        Set-ItemProperty  $regPathUser -name "IsInstalled" -value 0
    }

    if( $pscmdlet.ShouldProcess("iesetup.dll", "Call dll reg methods" ) )
    {
        Write-Verbose "Calling DLL methods."
        Rundll32 iesetup.dll, IEHardenLMSettings
        Rundll32 iesetup.dll, IEHardenUser
        Rundll32 iesetup.dll, IEHardenAdmin 
        
    }

    if( $pscmdlet.ShouldProcess( "Delete HKCU keys." ) )
    {
        Write-Verbose "Deleting HKCU keys."
        
        $deleteKey1 = "HKCU:SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
        if(Test-Path -Path $deleteKey1)
        {
            Write-Host "$deleteKey1"
            Remove-Item -Path $deleteKey1
        }

        $deleteKey2 = "HKCU:SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
        if(Test-Path -Path $deleteKey2)
        {
            Write-Host "$deleteKey2"
            Remove-Item -Path $deleteKey2
        }
    }
}
