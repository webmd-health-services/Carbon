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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'UseCallerPreference' -Resolve) -Force

$message = ''

function Start-Test
{
    $message = [Guid]::NewGuid().ToString()
}

function Test-ShouldWriteVerboseMessage
{
    function DoIt
    {
        [CmdletBinding()]
        param(
        )

        Write-VerboseMessage -Message $message
        
    }

    DoIt -Verbose 4>&1 | Assert-Message
}

function Test-ShouldWriteErrorMessage
{
    function DoIt
    {
        [CmdletBinding()]
        param(
        )

        Write-ErrorMessage -Message $message
    }

    # Ignore isn't fully supported as a passed-in preference variable, so convert it to SilentlyContinue.
    $output = DoIt -ErrorAction SilentlyContinue 2>&1
    Assert-Null $output
    Assert-Error -Last -Regex $message
}

function Test-ShouldWriteDebugMessage
{
    function DoIt
    {
        [CmdletBinding()]
        param(
        )

        Write-DebugMessage -Message $message
    }

    $DebugPreference = 'Continue'
    # Ignore isn't fully supported as a passed-in preference variable, so convert it to SilentlyContinue.
    DoIt 5>&1 | Assert-Message
}

function Test-ShouldWriteInfoMessage
{
    function DoIt
    {
        [CmdletBinding()]
        param(
        )

        Write-InfoMessage -Message $message
    }

    # Ignore isn't fully supported as a passed-in preference variable, so convert it to SilentlyContinue.
    $output = DoIt -InformationAction SilentlyContinue 6>&1
    Assert-Null $output
    Assert-NoError
}

function Test-ShouldWriteWarningMessage
{
    function DoIt
    {
        [CmdletBinding()]
        param(
        )

        Write-WarningMessage -Message $message
    }

    # Ignore isn't fully supported as a passed-in preference variable, so convert it to SilentlyContinue.
    $output = DoIt -WarningAction SilentlyContinue 3>&1
    Assert-Null $output
    Assert-NoError
}

function Test-ShouldSupportWhatIfPreference
{
    function DoIt
    {
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
        )

        Invoke-WhatIfAction -Message $message
    }

    # Ignore isn't fully supported as a passed-in preference variable, so convert it to SilentlyContinue.
    $output = DoIt -WhatIf
    Assert-Null $output
}

function Test-ShouldSupportConfirmPreference
{
    function DoIt
    {
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
        )

        Invoke-ConfirmedAction -Message $message
    }

    # Ignore isn't fully supported as a passed-in preference variable, so convert it to SilentlyContinue.
    $output = DoIt -Confirm:$false
    Assert-Null $output
}

function Assert-Message
{
    param(
        [Parameter(ValueFromPipeline=$true)]
        $ActualMessage
    )

    Assert-Equal $message $ActualMessage
}