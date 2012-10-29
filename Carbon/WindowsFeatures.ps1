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

$useServerManager = ((Get-Command -CommandType 'Application' -Name 'servermanagercmd*.exe' | Where-Object { $_.Name -eq 'servermanagercmd.exe' }) -ne $null)
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
        Installs IIS if it isn't already installed.

        .DESCRIPTION
        This function installs IIS and, optionally, the IIS HTTP redirection feature.  If a feature is already installed, nothing happens.

        **NOTE: This function is only available on operating systems that have `servermanagercmd.exe` *or* `ocsetup.exe` and WMI support for the Win32_OptionalFeature class.**

        .EXAMPLE
        Install-WindowsFeatureIis

        Installs IIS if it isn't already installed.

        .EXAMPLE
        Install-WindowsFeatureIis

        Installs IIS and its HTTP redirection feature, if they aren't already installed.
        #>
        [CmdletBinding()]
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
        <#
        .SYNOPSIS
        Installs MSMQ and, optionally, some of its sub-features, if they aren't already installed.

        .DESCRIPTION
        This function installs MSMQ and, optionally, MSMQ's HTTP support and Active Directory integration.  If any of the selected features are already installed, they are not re-installed; nothing happens.

        **NOTE: This function is only available on operating systems that have `servermanagercmd.exe` *or* `ocsetup.exe` and WMI support for the Win32_OptionalFeature class.**

        .EXAMPLE
        Install-WindowsFeatureMsmq

        Installs MSMQ, if it isn't already installed.

        .EXAMPLE
        Install-WindowsFeatureMsmq -HttpSupport -ActiveDirectoryIntegration

        Installs MSMQ and its HTTP support and Active Directory integration features, if they aren't already installed.
        #>
        [CmdletBinding()]
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

        On Windows 2008, run the following for a list:

            servermanagercmd.exe -q  

        On Windows7, run:

            Get-WmiObject -Class Win32_OptionalFeature | Select-Object Name

        This function should be considered an internal, private function.  It would be best to use one of the feature-specifc `Install-WindowsFeature*` 
        functions.  These are designed to be Windows-version agnostic.

        .EXAMPLE
        Install-WindowsFeatures -Features MSMQ-Server

        Installs MSMQ.

        .EXAMPLE
        Install-WindowsFeatures -Features IIS-WebServer

        Installs IIS on Windows 7.

        .EXAMPLE
        Install-WindowsFeatures -Features Web-WebServer

        Installs IIS on Windows 2008.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string[]]
            # The components to enable/install.  Feature names are case-sensitive.  If on Windows 2008, run `servermanagercmd.exe -q` for a list.  On Windows 7, run `Get-WmiObject -Class Win32_OptionalFeature | Select-Object Name`.
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

        .DESCRIPTION
        The names of the features are different on different versions of Windows.  You can get a list by running the following commands.

        On Windows 2008:

            serveramanagercmd.exe -q

        One Windows 7:

            Get-WmiObject -Class Win32_OptionalFeature | Select-Object Name

        .EXAMPLE
        Test-WindowsFeature -Name MSMQ-Server

        Tests if MSMQ is installed.

        .EXAMPLE
        Test-WindowsFeature -Name IIS-WebServer

        Tests if IIS is installed on Windows 7.

        .EXAMPLE
        Test-WindowsFeature -Name Web-WebServer

        Tests if IIS is installed on Windows Server 2008.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The name of the feature to test.  Feature names are case-sensitive and are different between different versions of Windows.  For a list, on Windows 2008, run `serveramanagercmd.exe -q`; on Windows 7, run `Get-WmiObject -Class Win32_OptionalFeature | Select-Object Name`.
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
        Uninstalls optional Windows components/features.

        .DESCRIPTION
        The names of the features are different on different versions of Windows.  For a list, run the following commands:

        On Windows 2008:

            serveramanagercmd.exe -q

        One Windows 7:

            Get-WmiObject -Class Win32_OptionalFeature | Select-Object Name

        Feature names are case-sensitive.  If a feature is already uninstalled, nothing happens.

        .EXAMPLE
        Uninstall-WindowsFeatures -Features MSMQ-Server

        Uninstalls MSMQ.

        .EXAMPLE
        Uninstall-WindowsFeatures -Features IIS-WebServer

        Uninstalls IIS on Windows 7.

        .EXAMPLE
        Uninstall-WindowsFeatures -Features Web-WebServer

        Uninstalls IIS on Windows 2008.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string[]]
            # The names of the components to uninstall/disable.  Feature names are case-sensitive.  The names are different between Windows versions.  For a list, on Windows 2008, run `serveramanagercmd.exe -q`; on Windows 7, run `Get-WmiObject -Class Win32_OptionalFeature | Select-Object Name`.
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
