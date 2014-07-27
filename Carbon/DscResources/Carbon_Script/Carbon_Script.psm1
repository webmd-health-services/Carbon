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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonDscResource.ps1' -Resolve)

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $GetScript,
        
        [string[]]
        # The path to the service.
        $GetArgumentList,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $SetScript,
        
        [string[]]
        # The path to the service.
        $SetArgumentList,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $TestScript,
        
        [string[]]
        # The path to the service.
        $TestArgumentList
    )

    Set-StrictMode -Version 'Latest'

    $scriptBlock = [ScriptBlock]::Create($GetScript)
    $result = Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $GetArgumentList -ErrorVariable CmdError
    if( $CmdError )
    {
        return
    }

    if( $result -isnot [hashtable] )
    {
        Write-Error ('GetScript failed to return a Hashtable.')
        return
    }
    return $result
}


function Set-TargetResource
{
    <#
    .SYNOPSIS
    Runs custom PowerShell script.

    .DESCRIPTION

    This resource exists because the native PowerShell `Script` resource doesn't allow you to pass arguments to your script block. This resource provides that capability.

    The `GetScript` script must return a hashtable. 

    The `TestScript` script must return a bool. If you want to call the GetScript from your `TestScript`, simply add a call to `Get-TargetResource`:

        TestScript = {
            $resource = Get-TargetResource @PSBoundParameters
        }

    In fact, you can call any of the `*-TargetResource` functions from your scripts.

    All arguments are passed as strings, so if you need them converted to other types, you'll have to do the converting. Be careful!
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $GetScript,
        
        [string[]]
        # The path to the service.
        $GetArgumentList,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $SetScript,
        
        [string[]]
        # The path to the service.
        $SetArgumentList,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $TestScript,
        
        [string[]]
        # The path to the service.
        $TestArgumentList
    )

    Set-StrictMode -Version 'Latest'

    $scriptBlock = [ScriptBlock]::Create($SetScript)
    Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $SetArgumentList
}


function Test-TargetResource
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $GetScript,
        
        [string[]]
        # The path to the service.
        $GetArgumentList,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $SetScript,
        
        [string[]]
        # The path to the service.
        $SetArgumentList,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $TestScript,
        
        [string[]]
        # The path to the service.
        $TestArgumentList
    )

    Set-StrictMode -Version 'Latest'

    $scriptBlock = [ScriptBlock]::Create($TestScript)
    $result = Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $TestArgumentList -ErrorVariable 'CmdError'
    if( $CmdError )
    {
        return
    }

    if( $result -isnot [bool] )
    {
        Write-Error ('TestScript failed to return a bool.')
        return
    }

    return $result
}

