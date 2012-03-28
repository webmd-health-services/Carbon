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

$useServerManager = ((Get-Command 'servermanagercmd.exe' -ErrorAction SilentlyContinue) -ne $null)
$useWmi = $false
$useOCSetup = $false
if( -not $useServerManager )
{
    $useWmi = ((Get-WmiObject -Class Win32_OptionalFeature -ErrorAction SilentlyContinue) -ne $null)
    $useOCSetup = ((Get-Command 'ocsetup.exe' -ErrorAction SilentlyContinue) -ne $null)
}

if( -not ($useServerManager -or ($useWmi -and $useOCSetup) ) )
{
    Write-Warning 'Unable to find support for installing Windows features.  Couldn''t find servermanagercmd.exe, ocsetup.exe, or WMI support.'
}
else
{
    function Install-WindowsFeatureIis
    {
        <#
        .SYNOPSIS
        Installs IIS.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Switch]
            # Install IIS's HTTP redirection feature.
            $HttpRedirection
        )
        
        $featureNames = @{ HttpRedirection = 'Web-Http-Redirect' }
        $features = @( 'Web-WebServer' )
        if( $useOCSetup )
        {
            $features = @( 'IIS-WebServer' )
            $featureNames = @{ HttpRedirection = 'IIS-HttpRedirect' }
        }
        
        if( $HttpRedirection )
        {
            $features += $featureNames.HttpRedirection
        }
        
        Install-WindowsFeatures -Features $features
    }

    function Install-WindowsFeatureMsmq
    {
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Switch]
            # Enable HTTP Support
            $HttpSupport,
            
            [Switch]
            # Enable Active Directory Integrations
            $ActiveDirectoryIntegration
        )
        
        $featureNames = @{ HttpSupport = 'MSMQ-HTTP-Support' ; ActiveDirectoryIntegration = 'MSMQ-Directory' }
        if( $useOCSetup )
        {
            $featureNames = @{ HttpSupport = 'MSMQ-HTTP' ; ActiveDirectoryIntegration = 'MSMQ-ADIntegration' }
        }
        
        $features = @( 'MSMQ-Server' )
        if( $HttpSupport )
        {
            $features += $featureNames.HttpSupport
        }
        
        if( $ActiveDirectoryIntegration )
        {
            $features += $featureNames.ActiveDirectoryIntegration
        }

        Install-WindowsFeatures -Features $features
    }

    function Install-WindowsFeatures
    {
        <#
        .SYNOPSIS
        Installs an optional Windows component/feature.
        .DESCRIPTION
        This function will install Windows features.  Note that the name of these features can differ between different versions of Windows.  
        If on Windows 2008, run `servermanagercmd.exe -q` for a list.  On Windows 7, run `Get-WmiObject -Class Win32_OptionalFeature`.
        
        This function should be considered an internal, private function.  It would be best to use one of the feature-specifc Install-WindowsFeature* 
        functions.  These are designed to be Windows-version agnostic.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string[]]
            # The components to enable/install.  If on Windows 2008, run `servermanagercmd.exe -q` for a list.  On Windows 7, run `Get-WmiObject -Class Win32_OptionalFeature`.
            $Features
        )
        
        $componentsToInstall = @()
        
        foreach( $name in $Features )
        {
            if( -not (Test-WindowsFeature -Name $name) )
            {
                $componentsToInstall += $name
            }
        }
        
        if( $componentsToInstall.Length -eq 0 )
        {
            return
        }
        
        if( $pscmdlet.ShouldProcess( "Windows feature(s) '$componentsToInstall'", "install" ) )
        {
            Write-Host "Installing Windows feature(s): '$componentsToInstall'."
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
                    throw "Unable to find process 'ocsetup'.  It looks like the Windows Optional Component setup program didn't start."
                }
                $ocsetup.WaitForExit()
            }
        }
    }

    function Test-WindowsFeature
    {
        <#
        .SYNOPSIS
        Tests if an optional Windows component is installed.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The 
            $Name
        )
        
        if( $useServerManager )
        {
            if( (servermanagercmd.exe -q | Where-Object { $_ -match "\[X\].+\[$Name\]" }) )
            {
                return $true
            }
            return $false
        }
        
        $component = Get-WmiObject -Query "select InstallState from Win32_OptionalFeature where Name='$Name'"
        if( -not $component )
        {
            return $false
        }
        
        return ( $component.InstallState -eq '1' )
    }

    function Uninstall-WindowsFeatures
    {
        <#
        .SYNOPSIS
        Uninstalls an optional Windows component. 
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string[]]
            # The components to uninstall/disable.  See http://technet.microsoft.com/en-us/library/cc722041(WS.10).aspx for a somewhat-complete list.
            $Features
        )
        
        $featuresToUninstall = @()
        
        foreach( $name in $Features )
        {
            if( Test-WindowsFeature -Name $name )
            {
                $featuresToUninstall += $name
            }
        }
        
        if( $featuresToUninstall.Length -eq 0 )
        {
            return
        }
            
        if( $pscmdlet.ShouldProcess( "Windows feature(s) '$featuresToUninstall'", "uninstall" ) )
        {
            Write-Host "Uninstalling Windows feature(s): '$featuresToUninstall'."
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
                    throw "Unable to find process 'ocsetup'.  It looks like the Windows Optional Component setup program didn't start."
                }
                $ocsetup.WaitForExit()
            }
        }
    }
}
