<#
.SYNOPSIS
Imports the Carbon module.

.DESCRIPTION
Intelligently imports the Carbon module, re-importing it if needed. Carbon will be re-imported if:

 * a different version is currently loaded
 * any of Carbon's files were modified since it was last imported with this script
 * the `Force` switch is set

.EXAMPLE
Import-Carbon.ps1

Imports the Carbon module, re-loading it if its already loaded.
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

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    # The prefix to use on all the module's functions, cmdlets, etc.
    [string]$Prefix,

    # Reload the module no matter what.
    [Switch]$Force
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

$carbonPsd1Path = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.psd1' -Resolve

& {
    $originalVerbosePref = $Global:VerbosePreference
    $originalWhatIfPref = $Global:WhatIfPreference

    $Global:VerbosePreference = $VerbosePreference = 'SilentlyContinue'
    $Global:WhatIfPreference = $WhatIfPreference = $false

    try
    {
        $module = Get-Module -Name 'Carbon'
        if( $module )
        {
            $expectedPath = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.psm1'
            if( $Force -or $module.Path -ne $expectedPath )
            {
                Remove-Module -Name 'Carbon' -Force
            } 
        }

        $optionalParams = @{ }
        if( $Prefix )
        {
            $optionalParams['Prefix'] = $Prefix
        }

        Import-Module -Name $carbonPsd1Path @optionalParams
    }
    finally
    {
        $Global:VerbosePreference = $originalVerbosePref
        $Global:WhatIfPreference = $originalWhatIfPref
    }
}