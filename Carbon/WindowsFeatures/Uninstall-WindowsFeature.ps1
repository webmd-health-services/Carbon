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
if( -not (Get-Command -Name 'Uninstall-WindowsFeature*') )
{
    function Uninstall-WindowsFeature
    {
        <#
        .SYNOPSIS
        Uninstalls optional Windows components/features.

        .DESCRIPTION
        The names of the features are different on different versions of Windows.  For a list, run `Get-WindowsService`.

        Feature names are case-sensitive.  If a feature is already uninstalled, nothing happens.
        
        **This function is not available on Windows 8/2012.**
        
        .LINK
        Get-WindowsFeature
        
        .LINK
        Install-WindowsService
        
        .LINK
        Test-WindowsService

        .EXAMPLE
        Uninstall-WindowsFeature -Name TelnetClient,TFTP

        Uninstalls Telnet and TFTP.

        .EXAMPLE
        Uninstall-WindowsFeature -Iis

        Uninstalls IIS.
        #>
        [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='ByName')]
        param(
            [Parameter(Mandatory=$true,ParameterSetName='ByName')]
            [string[]]
            # The names of the components to uninstall/disable.  Feature names are case-sensitive.  To get a list, run `Get-WindowsFeature`.
            [Alias('Features')]
            $Name,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Uninstalls IIS.
            $Iis,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Uninstalls IIS's HTTP redirection feature.
            $IisHttpRedirection,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Uninstalls MSMQ.
            $Msmq,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Uninstalls MSMQ HTTP support.
            $MsmqHttpSupport,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Uninstalls MSMQ Active Directory Integration.
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
        
        $featuresToUninstall = $Name | 
                                    ForEach-Object {
                                        if( (Test-WindowsFeature -Name $_) )
                                        {
                                            $_
                                        }
                                        else
                                        {
                                            Write-Error ('Windows feature ''{0}'' not found.' -f $_)
                                        }
                                    } |
                                    Where-Object { Test-WindowsFeature -Name $_ -Installed }
        
        if( -not $featuresToUninstall -or $featuresToUninstall.Length -eq 0 )
        {
            return
        }
            
        if( $pscmdlet.ShouldProcess( "Windows feature(s) '$featuresToUninstall'", "uninstall" ) )
        {
            if( $useServerManager )
            {
                & servermanagercmd.exe -remove $featuresToUninstall
            }
            else
            {
                $featuresArg = $featuresToUninstall -join ';'
                & ocsetup.exe $featuresArg /uninstall
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

    Set-Alias -Name 'Uninstall-WindowsFeatures' -Value 'Uninstall-WindowsFeature'
}