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

$windowsFeaturesNotSupported = (-not ($useServerManager -or ($useWmi -and $useOCSetup) ))
$supportNotFoundErrorMessage = 'Unable to find support for managing Windows features.  Couldn''t find servermanagercmd.exe, ocsetup.exe, or WMI support.'

function Assert-WindowsFeatureFunctionsSupported
{
    <#
    .SYNOPSIS
    Asserts if Windows feature functions are supported.  If not, writes a warning and returns false.
    #>
    [CmdletBinding()]
    param(
    )
    
    if( $windowsFeaturesNotSupported )
    {
        Write-Warning $supportNotFoundErrorMessage
        return $false
    }
    return $true
}

function Get-WindowsFeature
{
    <#
    .SYNOPSIS
    Gets a list of available Windows features, or details on a specific windows feature.
    
    .DESCRIPTION
    Different versions of Windows use different names for installing Windows features.  Use this function to get the list of functions for your operating system.
    
    With no arguments, will return a list of all Windows features.  You can use the `Name` parameter to return a specific feature or a list of features that match a wildcard.
    
    .OUTPUTS
    [PsObject].  A generic PsObject with properties DisplayName, Name, and Installed.
    
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
    elseif( $useSetupManager )
    {
        servermanagercmd.exe -query | 
            Where-Object { $_ -like ('*[{0}]*' -f $Name) } |
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

if( (Assert-WindowsFeatureFunctionsSupported) )
{
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

    function Install-WindowsFeature
    {
        <#
        .SYNOPSIS
        Installs an optional Windows component/feature.

        .DESCRIPTION
        This function will install Windows features.  Note that the name of these features can differ between different versions of Windows. Use `Get-WindowsFeature` to get the list of features on your operating system.

        .LINK
        Get-WindowsFeature
        
        .LINK
        Test-WindowsFeature
        
        .LINK
        Uninstall-WindowsFeature
        
        .EXAMPLE
        Install-WindowsFeatures -Name MSMQ-Server

        Installs MSMQ.

        .EXAMPLE
        Install-WindowsFeatures -Name IIS-WebServer

        Installs IIS on Windows 7.

        .EXAMPLE
        Install-WindowsFeatures -Name Web-WebServer

        Installs IIS on Windows 2008.
        #>
        [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='ByName')]
        param(
            [Parameter(Mandatory=$true,ParameterSetName='ByName')]
            [string[]]
            # The components to enable/install.  Feature names are case-sensitive.
            $Name,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Installs IIS.
            $Iis,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Installs IIS's HTTP redirection feature.
            $IisHttpRedirection
        )
        
        if( $pscmdlet.ParameterSetName -eq 'ByFlag' )
        {
            $featureMap = @{
                                Iis = 'Web-WebServer';
                                IisHttpRedirection = 'Web-Http-Redirect';
                           }
            if( $useOCSetup )
            {
                $featureMap = @{
                                    Iis = 'IIS-WebServer';
                                    IisHttpRedirection = 'IIS-HttpRedirect';
                               }
            }
            
            $Name = $PSBoundParameters.Keys | 
                        Where-Object { $featureMap.ContainsKey( $_ ) } |
                        ForEach-Object { $featureMap[$_] }
        }
        
        $componentsToInstall = $Name | 
                                    ForEach-Object {
                                        if( -not (Test-WindowsFeature -Name $_) )
                                        {
                                            Write-Error ('Windows feature {0} not found.' -f $_)
                                        }
                                        else
                                        {
                                            $_
                                        } 
                                    } |
                                    Where-Object { -not (Test-WindowsFeature -Name $_ -Installed) }
       
        if( -not $componentsToInstall -or $componentsToInstall.Length -eq 0 )
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
                    Write-Error "Unable to find process 'ocsetup'.  It looks like the Windows Optional Component setup program didn't start."
                    return
                }
                $ocsetup.WaitForExit()
            }
        }
    }

    function Test-WindowsFeature
    {
        <#
        .SYNOPSIS
        Tests if an optional Windows component exists and, optionally, if it is installed.

        .DESCRIPTION
        Feature names are different across different versions of Windows.  This function tests if a given feature exists.  You can also test if a feature is installed by setting the `Installed` switch.

        .LINK
        Get-WindowsFeature
        
        .LINK
        Install-WindowsFeature
        
        .LINK
        Uninstall-WindowsFeature
        
        .EXAMPLE
        Test-WindowsFeature -Name MSMQ-Server

        Tests if the MSMQ-Server feature exists on the current computer.

        .EXAMPLE
        Test-WindowsFeature -Name IIS-WebServer -Installed

        Tests if the IIS-WebServer features exists and is installed/enabled.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The name of the feature to test.  Feature names are case-sensitive and are different between different versions of Windows.  For a list, on Windows 2008, run `serveramanagercmd.exe -q`; on Windows 7, run `Get-WmiObject -Class Win32_OptionalFeature | Select-Object Name`.
            $Name,
            
            [Switch]
            # Test if the service is installed in addition to if it exists.
            $Installed
        )
        
        $feature = Get-WindowsFeature -Name $Name 
        
        if( $feature )
        {
            if( $Installed )
            {
                return $feature.Installed
            }
            return $true
        }
        else
        {
            return $false
        }
    }

    function Uninstall-WindowsFeatures
    {
        <#
        .SYNOPSIS
        Uninstalls optional Windows components/features.

        .DESCRIPTION
        The names of the features are different on different versions of Windows.  For a list, run `Get-WindowsService`.

        Feature names are case-sensitive.  If a feature is already uninstalled, nothing happens.
        
        .LINK
        Get-WindowsFeature
        
        .LINK
        Install-WindowsService
        
        .LINK
        Test-WindowsService

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
            # The names of the components to uninstall/disable.  Feature names are case-sensitive.  To get a list, run `Get-WindowsFeature`.
            $Features
        )
        
        $featuresToUninstall = @()
        
        foreach( $name in $Features )
        {
            if( (Test-WindowsFeature -Name $name -Installed) )
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
