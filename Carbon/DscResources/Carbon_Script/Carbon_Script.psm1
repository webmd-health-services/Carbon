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
    DSC resource for running PowerShell script blocks, including the ability to pass arguments to those blocks.

    .DESCRIPTION
    The `Carbon_Script` resource runs custom PowerShell script blocks, with support for passing arguments to those blocks. Passing arguments is optional.

    This is useful if you want to run custom code on multiple computers, but the code needs to vary slightly between those computers.

    The `GetScript` script must return a hashtable. 

    The `TestScript` script must return a bool. If you want to call the GetScript from your `TestScript`, simply add a call to `Get-TargetResource`:

        TestScript = {
            $resource = Get-TargetResource @PSBoundParameters
        }

    In fact, you can call any of the `*-TargetResource` functions from your scripts.

    All arguments are passed as strings, so if you need them converted to other types, you'll have to do the converting. Be careful!

    .EXAMPLE
    >
    Demonstrates how to use the `Carbon_Script` resource.

        Carbon_Script CustomizeIt
        {
            GetScript = {
                param(
                    $Name
                )

                if( Get-Service -Name $Name -ErrorACtion Ignore )
                {
                    return @{
                        Ensure = 'Present'
                    }
                }
                else
                {
                    return @{
                        Ensure = 'Absent';
                    }
                }
            }
            GetArgumentList = @( 'CarbonNoOpService' ;
            SetScript = {
                param(
                    $Name
                )

                $resource = Get-TargetResource -Name $Name
                if( $resource.Ensure -eq 'Present' )
                {
                    Restart-Service -Name $Name
                }
            }
            SetARgumentList = @( 'CarbonNoOpService' );
            TestScript = {
                param(
                    $Name
                )

                $resource = Get-TargetResource -Name $Name
                return ($resource -eq 'Absent')
            }
            TestArgumentList = @( 'CarbonNoOpService' );
        }

    In this example, we are restarting a service, if it is present, and passing the name of that service into our script blocks, which is really useful if the name of the service changes between computers.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The script block to run when getting resource information.
        $GetScript,
        
        [string[]]
        # The arguments to pass to the `GetScript` script block.
        $GetArgumentList,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The script block to run to set/remove your resource.
        $SetScript,
        
        [string[]]
        # The arguments to pass to the `SetScript` script block.
        $SetArgumentList,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The script block to run when testing your resource. Must return `$true` or `$false`.
        $TestScript,
        
        [string[]]
        # The arguments to pass to the `TestScrtip` script block.
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

