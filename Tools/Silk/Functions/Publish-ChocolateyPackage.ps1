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
function Publish-ChocolateyPackage
{
    <#
    .SYNOPSIS
    Publishes a Chocolatey package to chocolatey.org.

    .DESCRIPTION
    The `Publish-ChocolateyPackage` functin publishes a NuGet package to chocolatey.org. If the package already exists, the publish will fail, and you'll probably get an error.

    This function requires that Chocolatey be installed and that `choco.exe` be in the PATH somewhere.

    If you don't provide an API key, you'll be prompted to enter one.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the nupkg file to publish.
        $FilePath,

        [string]
        # The API key to use.
        $ApiKey
    )

    Set-StrictMode -Version 'Latest'

    if( -not (Get-Command -Name 'choco.exe') )
    {
        return
    }

    if( -not (Test-Path -Path $FilePath -PathType Leaf) )
    {
        Write-Error ('Chocolatey package ''{0}'' not found.' -f $FilePath)
        return
    }

    if( -not $ApiKey )
    {
        $ApiKey = Read-Host -Prompt ('Please enter your chocolatey.org API key')
    }

    choco.exe push $FilePath --source=https://chocolatey.org --apikey $ApiKey

}