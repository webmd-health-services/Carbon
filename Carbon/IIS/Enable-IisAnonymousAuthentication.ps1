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

function Set-IisAnonymousAuthentication
{
    <#
    .SYNOPSIS
    Enables or disables anonymous authentication for all or part of a website.

    .DESCRIPTION
    By default, enables anonymous authentication on a website.  You can enable anonymous authentication at a specific path under a website by passing the virtual path (*not* the physical path) to that directory.

    To disable anonymouse authentication, set the `Disabled` flag.

    .EXAMPLE
    Set-IisAnonymousAuthentication -SiteName Peanuts

    Turns on anonymous authentication for the `Peanuts` website.

    .EXAMPLE
    Set-IisAnonymouseAuthentication -SiteName Peanuts Snoopy/DogHouse

    Turns on anonymous authentication for the `Snoopy/DogHouse` directory under the `Peanuts` website.

    .EXAMPLE
    Set-IisAnonymousAuthentication -SiteName Peanuts -Disabled

    Turns off anonymous authentication for the `Peanuts` website.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where anonymous authentication should be set.
        $SiteName,
        
        [string]
        # The optional path where anonymous authentication should be set.
        $Path = '',
        
        [Switch]
        # Disable anonymous authentication.  Otherwise, it is enabled.
        $Disabled
    )
    
    $enabledArg = 'true'
    if( $Disabled )
    {
        $enabledArg = 'false'
    }
    
    if( $pscmdlet.ShouldProcess( "$SiteName/$Path", "set anonymous authentication" ) )
    {
        Invoke-AppCmd set config "$SiteName/$Path" '-section:anonymousAuthentication' /enabled:$enabledArg /username: /commit:apphost
    }
}

