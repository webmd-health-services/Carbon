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

function Set-IisBasicAuthentication
{
    <#
    .SYNOPSIS
    Enables or disables basic authentication for all or part of a website.

    .DESCRIPTION
    By default, enables basic authentication on a website.  You can enable basic authentication at a specific path under a website by passing the virtual path (*not* the physical path) to that directory.

    To disable basic authentication, set the `Disabled` flag.

    .EXAMPLE
    Set-IisBasicAuthentication -SiteName Peanuts

    Turns on basic authentication for the `Peanuts` website.

    .EXAMPLE
    Set-IisBasicAuthentication -SiteName Peanuts Snoopy/DogHouse

    Turns on basic authentication for the `Snoopy/DogHouse` directory under the `Peanuts` website.

    .EXAMPLE
    Set-IisBasicAuthentication -SiteName Peanuts -Disabled

    Turns off basic authentication for the `Peanuts` website.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where basic authentication should be set.
        $SiteName,
        
        [string]
        # The optional virtual path (*not* a physical path) where basic authentication should be set.
        $Path = '',
        
        [Switch]
        # Disable basic authentication.  Otherwise, it is enabled.
        $Disabled
    )
    
    $enabledArg = 'true'
    if( $Disabled )
    {
        $enabledArg = 'false'
    }
    
    if( $pscmdlet.ShouldProcess( "$SiteName/$Path", "set basic authentication" ) )
    {
        Invoke-AppCmd set config "$SiteName/$Path" '-section:basicAuthentication' /enabled:$enabledArg /commit:apphost
    }
}

