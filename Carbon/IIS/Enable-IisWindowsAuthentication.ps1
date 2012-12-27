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

function Set-IisWindowsAuthentication
{
    <#
    .SYNOPSIS
    Configures the settings for Windows authentication.

    .DESCRIPTION
    By default, configures Windows authentication on a website.  You can configure Windows authentication at a specific path under a website by passing the virtual path (*not* the physical path) to that directory.
    
    The changes only take effect if Windows authentication is enabled (see `Enable-IisSecurityAuthentication`).

    .LINK
    http://blogs.msdn.com/b/webtopics/archive/2009/01/19/service-principal-name-spn-checklist-for-kerberos-authentication-with-iis-7-0.aspx
    
    .LINK
    Disable-IisSecurityAuthentication
    
    .LINK
    Enable-IisSecurityAuthentication

    .EXAMPLE
    Set-IisWindowsAuthentication -SiteName Peanuts

    Configures Windows authentication on the `Peanuts` site to use kernel mode.

    .EXAMPLE
    Set-IisWindowsAuthentication -SiteName Peanuts Snoopy/DogHouse -DisableKernelMode

    Configures Windows authentication on the `Doghouse` directory of the `Peanuts` site to not use kernel mode.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where Windows authentication should be set.
        $SiteName,
        
        [string]
        # The optional path where Windows authentication should be set.
        $Path = '',
        
        [Switch]
        # Turn on kernel mode.  Default is false.  [More information about Kerndel Mode authentication.](http://blogs.msdn.com/b/webtopics/archive/2009/01/19/service-principal-name-spn-checklist-for-kerberos-authentication-with-iis-7-0.aspx)
        $DisableKernelMode
    )
    
    $useKernelMode = 'True'
    if( $DisableKernelMode )
    {
        $useKernelMode = 'False'
    }
    
    $authSettings = Get-IisSecurityAuthentication -SiteName $SiteName -Path $Path -Windows
    $authSettings.SetAttributeValue( 'useKernelMode', $useKernelMode )
    if( $pscmdlet.ShouldProcess( "$SiteName/$Path", "set Windows authentication" ) )
    {
        Write-Host ('IIS:{0}/{1}: configuring Windows authentication: useKernelMode: {2}' -f $SiteName,$Path,$useKernelMode)
        $authSettings.CommitChanges()
    }
}

