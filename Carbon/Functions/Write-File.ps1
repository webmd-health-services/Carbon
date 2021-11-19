
function Write-CFile
{
    <#
    .SYNOPSIS
    Writes text to a file, retrying if the write fails.

    .DESCRIPTION
    The `Write-CFile` function writes text file to a file, and will retry if the write fails. Use this function if you need to write text files that can be intermittently locked, like the Windows hosts file. 
    
    By default, it will retry 30 times, waiting 100 milliseconds between each try. You can control the number of retries and the wait between retries with the `MaximumTries` and `RetryDelayMilliseconds` parameters, respectively.

    All errors raised while trying to write the file are ignored, except the error raised on the last try.

    This function was introduced in Carbon 2.2.0.

    .EXAMPLE
    $lines | Write-CFile -Path 'C:\Path\to\my\file'

    Demonstrates how to write lines to a text file using the pipeline.

    .EXAMPLE
    Write-CFile -Path 'C:\Path\to\my\file' -InputObject $lines

    Demonstrates how to write lines to a text file using a variable.

    .EXAMPLE
    $lines | Write-CFile -Path 'C:\Path\to\my\file' -MaximumRetries 10 -RetryDelayMilliseconds 1000

    Demonstrates how to control how long to retry writing the text file. In this case, `Write-CFile` will try 10 times, waiting one second between tries.

    .EXAMPLE
    $lines | Write-CFile -Path 'C:\Path\to\my\file' -ErrorVariable 'writeErrors'

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
        # The contents of the file
        [string[]]$InputObject,

        # The number of tries before giving up reading the file. The default is 100.
        [int]$MaximumTries = 100,

        # The number of milliseconds to wait between tries. Default is 100 milliseconds.
        [int]$RetryDelayMilliseconds = 100
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        Write-Timing ('Write-CFile  BEGIN')

        $Path = Resolve-Path -Path $Path
        if( -not $Path )
        {
            return
        }

        $tryNum = 0
        $newLineBytes = [Text.Encoding]::UTF8.GetBytes([Environment]::NewLine)

        [IO.FileStream]$fileWriter = $null

        if( -not $PSCmdlet.ShouldProcess($Path,'write') )
        {
            return
        }

        while( $tryNum++ -lt $MaximumTries )
        {
            $lastTry = $tryNum -eq $MaximumTries

            $numErrorsBefore = $Global:Error.Count
            try
            {
                $fileWriter = New-Object 'IO.FileStream' ($Path,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::None,4096,$false)
                break
            }
            catch 
            {
                $numErrorsAfter = $Global:Error.Count
                $numErrors = $numErrorsAfter - $numErrorsBefore
                for( $idx = 0; $idx -lt $numErrors; ++$idx )
                {
                    $Global:Error.RemoveAt(0)
                }

                if( $lastTry )
                {
                    Write-Error -ErrorRecord $_
                }
                else
                {
                    Write-Timing ('Attempt {0,4} to open file "{1}" failed. Sleeping {2} milliseconds.' -f $tryNum,$Path,$RetryDelayMilliseconds)
                    Start-Sleep -Milliseconds $RetryDelayMilliseconds
                }
            }
        }
    }

    process
    {
        Write-Timing ('Write-CFile  PROCESS')
        if( -not $fileWriter )
        {
            return
        }

        foreach( $item in $InputObject )
        {
            [byte[]]$bytes = [Text.Encoding]::UTF8.GetBytes($item)
            $fileWriter.Write($bytes,0,$bytes.Length)
            $fileWriter.Write($newLineBytes,0,$newLineBytes.Length)
        }
    }

    end
    {
        if( $fileWriter )
        {
            $fileWriter.Close()
            $fileWriter.Dispose()
        }
        Write-Timing ('Write-CFile  END')
    }
}

function Write-File
{
     [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The path to the file to read.
        $Path,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        # The contents of the file
        [string[]]$InputObject,

        # The number of tries before giving up reading the file. The default is 100.
        [int]$MaximumTries = 100,

        # The number of milliseconds to wait between tries. Default is 100 milliseconds.
        [int]$RetryDelayMilliseconds = 100
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        Write-CRenamedCommandWarning -CommandName $MyInvocation.MyCommand.Name -NewCommandName 'Write-CFile'

        $stuffToPipe = New-Object 'Collections.ArrayList'
    }

    process
    {
        $stuffToPipe.AddRange( $InputObject )
    }

    end
    {
        [void]$PSBoundParameters.Remove('InputObject')
        $stuffToPipe | Write-CFile @PSBoundParameters
    }
}