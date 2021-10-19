<#
.SYNOPSIS
*Internal*.  Use `Set-CDotNetAppSetting` function instead.
.LINK
Set-CDotNetAppSetting
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
    [Parameter(Mandatory=$true,Position=0)]
    [string]
    $Name,

    [Parameter(Mandatory=$true,Position=1)]
    [string]
    $Value
)

Set-StrictMode -Version 'Latest'

$Name = [Text.Encoding]::Unicode.GetString( [Convert]::FromBase64String($Name) )
$Value = [Text.Encoding]::Unicode.GetString( [Convert]::FromBase64String($Value) )

Add-Type -AssemblyName System.Configuration

$config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
$appSettings = $config.AppSettings.Settings
if( $appSettings[$Name] )
{
    $appSettings[$Name].Value = $Value
}
else
{
    $appSettings.Add( $Name, $Value )
}
$config.Save()

