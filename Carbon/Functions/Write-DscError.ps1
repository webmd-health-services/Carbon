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

function Write-DscError
{
    <#
    .SYNOPSIS
    Writes DSC errors out as errors.

    .DESCRIPTION
    The Local Configuration Manager (LCM) applies configuration in a separate process space as a background service which writes its errors to the `Microsoft-Windows-DSC/Operational` event log. This function is intended to be used with `Get-DscError`, and will write errors returned by that function as PowerShell errors.

    `Write-DscError` is new in Carbon 2.0.

    .OUTPUTS
    System.Diagnostics.Eventing.Reader.EventLogRecord

    .LINK
    Get-DscError

    .EXAMPLE
    Get-DscError | Write-DscError

    Demonstrates how `Write-DscError` is intended to be used. `Get-DscError` gets the appropriate event objects that `Write-DscError` writes out.
    #>
    [CmdletBinding()]
    [OutputType([Diagnostics.Eventing.Reader.EventLogRecord])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Diagnostics.Eventing.Reader.EventLogRecord[]]
        # The error record to write out as an error.
        $EventLogRecord,

        [Switch]
        # Return the event log record after writing an error.
        $PassThru
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        foreach( $record in $EventLogRecord )
        {
            [string[]]$property = $record.Properties | Select-Object -ExpandProperty Value

            $message = $property[-1]

            Write-Error -Message ('[{0}] [{1}] [{2}] {3}' -f $record.TimeCreated,$record.MachineName,($property[0..($property.Count - 2)] -join '] ['),$message)

            if( $PassThru )
            {
                return $record
            }
        }
    }
}
