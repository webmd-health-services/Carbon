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

function New-BBServerConnection
{
    <#
    .SYNOPSIS
    Creates an object that represents a connection to an instance of Bitbucket Server.

    .DESCRIPTION
    The `New-BBServerConnection` function creates a connection object that is used by most Bitbucket Server Automation functions to connect to Bitbucket Server. You pass it credentials and the URI to the Bitbucket Server you want to connect to. It returns an object that is then passed to additional functions that require it.

    .EXAMPLE
    $conn = New-BBServerConnection -Credential (Get-Credential) -Uri 'https://bitbucketserver.example.com/'

    Demonstrates how to create a connection.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [pscredential]
        # The credential to use when connecting to Bitbucket Server. The credential is passed in plaintext, so make sure your Bitbucket Server connection is over HTTPS.
        $Credential,

        [Parameter(Mandatory=$true)]
        [uri]
        # The URI to the Bitbucket Server to connect to. The path to the API to use is appended to this URI. Typically, you'll just pass the protocol and hostname, e.g. `https://bitbucket.example.com`.
        $Uri,

        [string]
        # The version of the API to use. The default is `1.0`.
        $ApiVersion = '1.0'
    )

    Set-StrictMode -Version 'Latest'

    [pscustomobject]@{
                        'Credential' = $Credential;
                        'Uri' = $Uri;
                        'ApiVersion' = '1.0';
                     }
}