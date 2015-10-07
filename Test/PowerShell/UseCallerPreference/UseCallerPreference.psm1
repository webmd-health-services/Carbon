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

. (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\Carbon\Functions\Use-CallerPreference.ps1' -Resolve)

function Write-VerboseMessage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Message
    )

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Verbose -Message $Message
}

function Write-WarningMessage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Message
    )

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Warning -Message $Message
}

function Write-ErrorMessage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Message
    )

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Error -Message $Message
}

function Write-DebugMessage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Message
    )

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Debug -Message $Message
}

function Write-InfoMessage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Message
    )

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Information -Message $Message
}

function Invoke-WhatIfAction
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Message
    )

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $PSCmdlet.ShouldProcess($Message) )
    {
        $Message
    }
}

function Invoke-ConfirmedAction
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Message
    )

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $ConfirmPreference -ne 'None' )
    {
        $Message
    }
}