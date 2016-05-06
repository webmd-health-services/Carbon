<#
.SYNOPSIS
Bootstraps a server so it can run Carbon's tests.
#>

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

[CmdletBinding()]
param(
)

Invoke-Expression -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))"

choco install tortoisehg -y

$projectsDir = 'C:\Projects'
if( -not (Test-Path -Path $projectsDir) )
{
    mkdir C:\Projects
}

$carbonDir = Join-Path -Path $projectsDir -ChildPath 'Carbon'

Set-Alias -Name 'hg' -Value 'C:\Program Files\TortoiseHg\hg.exe'
if( -not (Test-Path -Path $carbonDir -PathType Container) )
{
    hg clone 'https://bitbucket.org/splatteredbits/carbon' $carbonDir
}

Push-Location -Path $carbonDir
try
{
    hg pull
    hg update

    & 'C:\Projects\Carbon\Initialize-Server.ps1'
}
finally
{
    Pop-Location
}