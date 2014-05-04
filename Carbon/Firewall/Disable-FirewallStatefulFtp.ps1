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

function Disable-FirewallStatefulFtp
{
    <#
    .SYNOPSIS
    Disables the `StatefulFtp` Windows firewall setting.

    .DESCRIPTION
    Uses the `netsh` command to disable the `StatefulFtp` Windows firewall setting.

    If the firewall isn't configurable, writes an error and returns without making any changes.

    .LINK
    Assert-FirewallConfigurable

    .EXAMPLE
    Disable-FirewallStatefulFtp

    Disables the `StatefulFtp` Windows firewall setting.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )

    Set-StrictMode -Version 'Latest'

    $commonParams = @{
                        ErrorAction = $ErrorActionPreference;
                        Verbose = $VerbosePreference;
                    }
    
    if( -not (Assert-FirewallConfigurable @commonParams) )
    {
        return
    }
    
    if( $PSCmdlet.ShouldProcess( 'firewall', 'disable stateful FTP' ) )
    {
        netsh advfirewall set global StatefulFtp disable
        if( $LASTEXITCODE )
        {
            Write-Error ('Failed disabling stateful FTP (exit code {0}).' -f $LASTEXITCODE)
        }
    }
}
