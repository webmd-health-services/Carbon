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

function Write-File
{
    <#
    .SYNOPSIS
    Writes text to a file, retrying if the write fails.

    .DESCRIPTION
    The `Write-File` function writes text file to a file, and will retry if the write fails. Use this function if you need to write text files that can be intermittently locked, like the Windows hosts file. 
    
    By default, it will retry 30 times, waiting 100 milliseconds between each try. You can control the number of retries and the wait between retries with the `MaximumTries` and `RetryDelayMilliseconds` parameters, respectively.

    All errors raised while trying to write the file are ignored, except the error raised on the last try.

    This function was introduced in Carbon 2.2.0.

    .EXAMPLE
    $lines | Write-File -Path 'C:\Path\to\my\file'

    Demonstrates how to write lines to a text file using the pipeline.

    .EXAMPLE
    Write-File -Path 'C:\Path\to\my\file' -InputObject $lines

    Demonstrates how to write lines to a text file using a variable.

    .EXAMPLE
    $lines | Write-File -Path 'C:\Path\to\my\file' -MaximumRetries 10 -RetryDelayMilliseconds 1000

    Demonstrates how to control how long to retry writing the text file. In this case, `Write-File` will try 10 times, waiting one second between tries.

    .EXAMPLE
    $lines | Write-File -Path 'C:\Path\to\my\file' -ErrorVariable 'writeErrors'

    Demonstrates how to check if the write failed. In this case, errors are copied to a 'writeErrors' variable, so you would check if this error variable has any items.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The path to the file to read.
        $Path,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]
        # The contents of the file
        $InputObject,

        [int]
        # The number of tries before giving up reading the file. The default is 100.
        $MaximumTries = 30,

        [int]
        # The number of milliseconds to wait between tries. Default is 100 milliseconds.
        $RetryDelayMilliseconds = 100
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $Path = Resolve-Path -Path $Path
        if( -not $Path )
        {
            return
        }

        $content = New-Object -TypeName 'Collections.Generic.List[object]'
    }

    process
    {
        if( -not $Path )
        {
            return
        }

        $InputObject | ForEach-Object { $content.Add( $_ ) } | Out-Null
    }

    end
    {
        if( -not $Path )
        {
            return
        }

        $cmdErrors = @()
        $tryNum = 1
        $errorAction = @{ 'ErrorAction' = 'SilentlyContinue' }
        do
        {
            $exception = $false
            $lastTry = $tryNum -eq $MaximumTries
            if( $lastTry )
            {
                $errorAction = @{}
            }

            $numErrorsAtStart = $Global:Error.Count
            try
            {
                Set-Content -Path $Path -Value $content @errorAction -ErrorVariable 'cmdErrors'
            }
            catch
            {
                if( $lastTry )
                {
                    Write-Error -ErrorRecord $_
                }
            }

            $numErrors = $Global:Error.Count - $numErrorsAtStart
            if( $numErrors -and -not $lastTry )
            {
                for( $idx = 0; $idx -lt $numErrors; ++$idx )
                {
                    $Global:Error[0] | Out-String | Write-Debug
                    $Global:Error.RemoveAt(0)
                }
            }

            # If $Global:Error is full, $numErrors will be 0
            if( $cmdErrors -or $numErrors )
            {
                if( -not $lastTry )
                {
                    Write-Debug -Message ('Failed to write file ''{0}'' (attempt #{1}). Retrying in {2} milliseconds.' -f $Path,$tryNum,$RetryDelayMilliseconds)
                    Start-Sleep -Milliseconds $RetryDelayMilliseconds
                }
            }
            else
            {
                break
            }
        }
        while( $tryNum++ -le $MaximumTries )
    }
}