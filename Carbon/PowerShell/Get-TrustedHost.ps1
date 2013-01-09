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

function Get-TrustedHost
{
    <#
    .SYNOPSIS
    Returns the current computer's trusted hosts list.

    .DESCRIPTION
    PowerShell stores its trusted hosts list as a comma-separated list of hostnames in the `WSMan` drive.  That's not very useful.  This function reads that list, splits it, and returns each item.

    .OUTPUTS
    System.String.

    .EXAMPLE
    Get-TrustedHost

    If the trusted hosts lists contains `example.com`, `api.example.com`, and `docs.example.com`, returns the following:

        example.com
        api.example.com
        docs.example.com
    #>
    $trustedHosts = (Get-Item $TrustedHostsPath -Force).Value 
    if( $trustedHosts )
    {
        return $trustedHosts -split ','
    }
}

Set-Alias -Name 'Get-TrustedHosts' -Value 'Get-TrustedHost'