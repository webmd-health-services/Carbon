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
    Enables or disables Windows authentication for all or part of a website.

    .DESCRIPTION
    By default, enables Windows authentication on a website.  You can enable Windows authentication at a specific path under a website by passing the virtual path (*not* the physical path) to that directory.

    To disable Windows authentication, set the `Disabled` flag.

    .LINK
    http://blogs.msdn.com/b/webtopics/archive/2009/01/19/service-principal-name-spn-checklist-for-kerberos-authentication-with-iis-7-0.aspx

    .EXAMPLE
    Set-IisWindowsAuthentication -SiteName Peanuts

    Turns on Windows authentication for the `Peanuts` website.

    .EXAMPLE
    Set-IisWindowsAuthentication -SiteName Peanuts Snoopy/DogHouse

    Turns on Windows authentication for the `Snoopy/DogHouse` directory under the `Peanuts` website.

    .EXAMPLE
    Set-IisWindowsAuthentication -SiteName Peanuts -Disabled

    Turns off Windows authentication for the `Peanuts` website.

    .EXAMPLE
    Set-IisWindowsAuthentication -SiteName Peanuts -UseKernelMode

    Turns on Windows authentication for the `Peanuts` website.

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
        # Disable Windows authentication.  Otherwise, it is enabled.
        $Disabled,
        
        [Switch]
        # Turn on kernel mode.  Default is false.  [More information about Kerndel Mode authentication.](http://blogs.msdn.com/b/webtopics/archive/2009/01/19/service-principal-name-spn-checklist-for-kerberos-authentication-with-iis-7-0.aspx)
        $UseKernelMode
    )
    
    $enabledArg = 'true'
    if( $Disabled )
    {
        $enabledArg = 'false'
    }
    
    $useKernelModeArg = 'false'
    if( $UseKernelMode )
    {
        $useKernelModeArg = 'true'
    }
    
    if( $pscmdlet.ShouldProcess( "$SiteName/$Path", "set Windows authentication" ) )
    {
        Invoke-AppCmd set config "$SiteName/$Path" '-section:windowsAuthentication' /enabled:$enabledArg /useKernelMode:$useKernelModeArg /commit:apphost
    }
}

