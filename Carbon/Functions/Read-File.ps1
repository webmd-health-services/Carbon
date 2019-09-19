
function Read-CFile
{
    <#
    .SYNOPSIS
    Reads the contents of a text file, retrying if the read fails.

    .DESCRIPTION
    The `Read-CFile` function reads the contents of a text file, and will retry if the read fails. Use this function if you need to read files that can be intermittently locked, like the Windows hosts file. The file is returned line-by-line. Use the `Raw` switch to return the entrie file as a single string.
    
    By default, it will retry 30 times, waiting 100 milliseconds between each try. YOu can control the number of retries and the wait between retries with the `MaximumTries` and `RetryDelayMilliseconds` parameters. 

    All errors raised while trying to read the file are ignored, except the error raised on the last try.

    This function was introduced in Carbon 2.2.0.

    .EXAMPLE
    Read-CFile -Path 'C:\Path\to\my\file'

    Demonstrates how to read each line from a text file.

    .EXAMPLE
    Read-CFile -Path 'C:\Path\to\my\file' -Raw

    Demonstrates how to read the entire contents of a text file into a single string.

    .EXAMPLE
    Read-CFile -Path 'C:\Path\to\my\file' -MaximumRetries 10 -RetryDelayMilliseconds 1000

    Demonstrates how to control how long to retry reading the text file. In this case, `Read-CFile` will try 10 times, waiting one second between tries.

    .EXAMPLE
    Read-CFile -Path 'C:\Path\to\my\file' -ErrorVariable 'readErrors'

    Demonstrates how to check if the read failed. In this case, errors are copied to a 'readErrors' variable, so you would check if this error variable has any items.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        # The path to the file to read.
        $Path,

        # The number of tries before giving up reading the file. The default is 30.
        [int]
        $MaximumTries = 30,

        # The number of milliseconds to wait between tries. Default is 100 milliseconds.
        [int]
        $RetryDelayMilliseconds = 100,

        [Switch]
        # Return the file as one string. Otherwise, by default, the file is returned line-by-line.
        $Raw
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Path = Resolve-Path -Path $Path
    if( -not $Path )
    {
        return
    }

    $tryNum = 1
    $output = @()
    do
    {
        $lastTry = $tryNum -eq $MaximumTries
        if( $lastTry )
        {
            $errorAction = @{}
        }

        $cmdErrors = @()
        $numErrorsAtStart = $Global:Error.Count
        try
        {

            if( $Raw )
            {
                $output = [IO.File]::ReadAllText($Path)
            }
            else
            {
                $output = Get-Content -Path $Path -ErrorAction SilentlyContinue -ErrorVariable 'cmdErrors'
                if( $cmdErrors -and $lastTry )
                {
                    foreach( $item in $cmdErrors )
                    {
                        $Global:Error.RemoveAt(0)
                    }
                    $cmdErrors | Write-Error 
                }
            }
        }
        catch
        {
            if( $lastTry )
            {
                Write-Error -ErrorRecord $_
            }
        }

        $numErrors = $Global:Error.Count - $numErrorsAtStart

        if( -not $lastTry )
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
                Write-Debug -Message ('Failed to read file ''{0}'' (attempt #{1}). Retrying in {2} milliseconds.' -f $Path,$tryNum,$RetryDelayMilliseconds)
                Start-Sleep -Milliseconds $RetryDelayMilliseconds
            }
        }
        else
        {
            return $output
        }
    }
    while( $tryNum++ -lt $MaximumTries )
}
