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
if( -not (Get-Command -Name 'Install-WindowsFeature*') )
{
    function Install-WindowsFeature
    {
        <#
        .SYNOPSIS
        Installs an optional Windows component/feature.

        .DESCRIPTION
        This function will install Windows features.  Note that the name of these features can differ between different versions of Windows. Use `Get-WindowsFeature` to get the list of features on your operating system.

        **This function is not available on Windows 8/2012.**
        
        .LINK
        Get-WindowsFeature
        
        .LINK
        Test-WindowsFeature
        
        .LINK
        Uninstall-WindowsFeature
        
        .EXAMPLE
        Install-WindowsFeature -Name TelnetClient

        Installs Telnet.

        .EXAMPLE
        Install-WindowsFeature -Name TelnetClient,TFTP

        Installs Telnet and TFTP

        .EXAMPLE
        Install-WindowsFeature -Iis

        Installs IIS.
        #>
        [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='ByName')]
        param(
            [Parameter(Mandatory=$true,ParameterSetName='ByName')]
            [string[]]
            # The components to enable/install.  Feature names are case-sensitive.
            [Alias('Features')]
            $Name,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Installs IIS.
            $Iis,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Installs IIS's HTTP redirection feature.
            $IisHttpRedirection,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Installs MSMQ.
            $Msmq,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Installs MSMQ HTTP support.
            $MsmqHttpSupport,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Installs MSMQ Active Directory Integration.
            $MsmqActiveDirectoryIntegration
        )
        
        if( -not (Assert-WindowsFeatureFunctionsSupported) )
        {
            return
        }
        
        if( $pscmdlet.ParameterSetName -eq 'ByFlag' )
        {
            $Name = Resolve-WindowsFeatureName -Name $PSBoundParameters.Keys
        }
        
        $componentsToInstall = $Name | 
                                    ForEach-Object {
                                        if( (Test-WindowsFeature -Name $_) )
                                        {
                                            $_
                                        }
                                        else
                                        {
                                            Write-Error ('Windows feature {0} not found.' -f $_)
                                        } 
                                    } |
                                    Where-Object { -not (Test-WindowsFeature -Name $_ -Installed) }
       
        if( -not $componentsToInstall -or $componentsToInstall.Length -eq 0 )
        {
            return
        }
        
        if( $pscmdlet.ShouldProcess( "Windows feature(s) '$componentsToInstall'", "install" ) )
        {
            if( $useServerManager )
            {
                servermanagercmd.exe -install $componentsToInstall
            }
            else
            {
                $featuresArg = $componentsToInstall -join ';'
                & ocsetup.exe $featuresArg
                $ocsetup = Get-Process 'ocsetup' -ErrorAction SilentlyContinue
                if( -not $ocsetup )
                {
                    Write-Error "Unable to find process 'ocsetup'.  It looks like the Windows Optional Component setup program didn't start."
                    return
                }
                $ocsetup.WaitForExit()
            }
        }
    }
    
    Set-Alias -Name 'Install-WindowsFeatures' -Value 'Install-WindowsFeature'
}